## The Final wash in co-op (core/96): two houses in one process, each a machine of its own, real ENet over 127.0.0.1
## (tests/coop_first_wash_test.gd's frame). The Host's last bin starts the Final wash: both machines play it, hold
## black at its end (nobody respawns) and open the Final screen together. A Guest who joins after the run ended goes
## straight to the Final screen.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const NET_WAIT_S := 30.0
const FPS := 60

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "both_machines", "method": "case_both_machines", "world": false,
				"title": "the Host's last bin starts the Final wash on both machines; at the Host's end both open the Final screen with the cutscene's black let go and nobody respawned"},
		{"name": "join_after_the_end", "method": "case_join_after_the_end", "world": false,
				"title": "a Guest joining after the run ended goes straight to the Final screen"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(CutscenePlayer.SKIP)
	SockGenerator.start_all = false
	_drop_branches()


func _host_up() -> Node3D:
	var host := _branch("Host")
	await _frames(2)
	var hs := _rt(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(_rt(host).net.start(["--host"]) == OK, "the host house hosts")
	await _wait(func() -> bool: return _rt(host).loading.is_lifted() and _stages(host).stage == 0 and _day(host).drawn and _stages(host).due.is_empty(),
			"the Host's run to start", FPS * 40)
	return host


func _join(host: Node3D) -> Node3D:
	var guest := _branch("Guest")
	await _frames(2)
	var gs := _rt(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(_rt(guest).net.start(["--join=127.0.0.1:%d" % _rt(host).session.port]) == OK, "the guest joins")
	await _wait(func() -> bool: return _rt(guest).net.mode_text().begins_with("Joined"), "the Guest to be welcomed", FPS * 40)
	return guest


## Every drawn bin but the one by the washer loaded, the last Fix and the First wash done, that bin in the Host's Hands.
func _one_bin_left(host: Node3D) -> void:
	var day := _day(host)
	var changes := {day.id: {"first_wash": LaundryDay.FirstWash.DONE, "loaded_bins": day.total() - 1}, _stages(host).id: {"phase": Stages.Phase.FIXED}}
	var last: LaundryBin = null
	for bin in day.used_bins():
		if bin.always:
			last = bin
		else:
			changes[bin.id] = {"full": false}
	changes[last.carriable.id] = {"holder": 1}
	_rt(host).parts.apply({"ok": true, "changes": changes})
	_rt(host).player.global_position = (Washer.of_level(host).get_parent() as Node3D).global_position + Vector3(1.9, 0.0, 0.0)


func case_both_machines() -> void:
	var host := await _host_up()
	var guest := await _join(host)
	await _wait(func() -> bool: return _day(guest).drawn and _day(guest).first_wash == LaundryDay.FirstWash.PENDING, "the Guest to see the Laundry day", FPS * 10)
	_one_bin_left(host)
	var stood := _rt(host).player.global_position
	var guest_stood := _rt(guest).player.global_position
	_rt(host).parts.ask(Command.new(LaundryDay.LOAD, 1, _day(host).id))
	await _wait(func() -> bool: return _cp(host).phase == CutscenePlayer.Phase.PLAYING and _cp(guest).phase == CutscenePlayer.Phase.PLAYING,
			"both machines to play the Final wash", FPS * 15)
	_check(_cs(guest).playing == LaundryDay.FINAL_WASH_SCRIPT and _day(guest).final_started and not _day(guest).ended, "the Guest sees it begin")
	_check(not _rt(guest).final_screen.is_open(), "no screen yet")
	_rt(host).parts.ask(Command.new(Cutscenes.SKIP, Parts.HOST, _cs(host).id))
	await _wait(func() -> bool: return _rt(host).final_screen.is_open() and _rt(guest).final_screen.is_open(), "the Final screen to open on both machines", FPS * 15)
	_check(_day(host).ended and _day(guest).ended, "the run ended on both")
	_check(_cp(host).phase == CutscenePlayer.Phase.IDLE and _cp(guest).phase == CutscenePlayer.Phase.IDLE, "the cutscene's black let go on both")
	_check(_rt(host).final_screen.columns.size() == 2 and _rt(guest).final_screen.columns.size() == 2, "a column per player on both (%d, %d)" % [_rt(host).final_screen.columns.size(), _rt(guest).final_screen.columns.size()])
	await _paced_ticks(3)
	var moved := [_rt(host).player.global_position.distance_to(stood), _rt(guest).player.global_position.distance_to(guest_stood)]
	_check(moved[0] < 1.0 and moved[1] < 1.0, "nobody respawned (moved %s)" % [moved])
	_drop_branches()


func case_join_after_the_end() -> void:
	var host := await _host_up()
	_day(host).cutscene = false
	_one_bin_left(host)
	_rt(host).parts.ask(Command.new(LaundryDay.LOAD, 1, _day(host).id))
	await _wait(func() -> bool: return _day(host).ended and _rt(host).final_screen.is_open(), "the Host's run to end", FPS * 20)
	var guest := await _join(host)
	await _wait(func() -> bool: return _day(guest).ended and _rt(guest).final_screen.is_open(), "the Guest's Final screen to open at once", FPS * 15)
	_drop_branches()


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced_ticks(n: int) -> void:
	for i in n:
		await _paced()


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _rt(house: Node3D) -> LevelRuntime:
	return LevelRuntime.of(house)


func _cs(house: Node3D) -> Cutscenes:
	return _rt(house).cutscenes


func _cp(house: Node3D) -> CutscenePlayer:
	return _rt(house).cutscene_player


func _stages(house: Node3D) -> Stages:
	return house.get_node("Run/Stages") as Stages


func _day(house: Node3D) -> LaundryDay:
	return house.get_node("LaundryDay/Day") as LaundryDay


## A house in a machine of its own (its own MultiplayerAPI and 3D world).
func _branch(label: String) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	view.add_child(house)
	_branches.append(node)
	return house


func _drop_branches() -> void:
	for node in _branches:
		var view := node.get_node_or_null("View")
		var house: Node = view.get_child(0) if view != null and view.get_child_count() > 0 else null
		var session := LevelRuntime.of(house).session if house != null else null
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
