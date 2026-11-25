## The First wash in co-op (core/94): two houses in one process, each a machine of its own, real ENet over
## 127.0.0.1 (tests/coop_fix_scene_test.gd's frame). The Host's bin starts the First wash; a Guest who joins while it
## plays holds black and sees the end state (the Mess lying, the machine broken, the First wash under way), no
## cutscene of its own, and at the Host's end it spawns by the washer with the First wash DONE on both.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const NET_WAIT_S := 30.0
const FPS := 60

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "late_joiner_sees_the_end", "method": "case_late_joiner_sees_the_end", "world": false,
				"title": "a Guest joining during the First wash holds black, sees the Socks lying and the machine broken, and after the Host's end spawns by the washer with the First wash DONE"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(CutscenePlayer.SKIP)
	SockGenerator.start_all = false
	_drop_branches()


func case_late_joiner_sees_the_end() -> void:
	var host := _branch("Host")
	await _frames(2)
	var hs := _rt(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(_rt(host).net.start(["--host"]) == OK, "the host house hosts")
	await _wait(func() -> bool: return _rt(host).loading.is_lifted() and _stages(host).stage == 0 and _day(host).drawn and _stages(host).due.is_empty(),
			"the Host's run to start", FPS * 40)
	_check(_day(host).first_wash == LaundryDay.FirstWash.PENDING and _rt(host).mess.count() == 0, "the Host waits for the First wash, no Socks lying")
	# The Host's bin into the washing machine (the Command its click asks).
	var bin := host.get_node("LaundryBins/Laundry/LaundryBin") as LaundryBin
	_rt(host).parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 1}}})
	var washer := Washer.of_level(host)
	_rt(host).player.global_position = (washer.get_parent() as Node3D).global_position + Vector3(1.9, 0.0, 0.0)
	_rt(host).parts.ask(Command.new(LaundryDay.LOAD, 1, _day(host).id))
	await _wait(func() -> bool: return _cp(host).phase == CutscenePlayer.Phase.PLAYING, "the Host to play the First wash", FPS * 5)
	var guest := _branch("Guest")
	await _frames(2)
	var gs := _rt(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(_rt(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the guest joins")
	await _wait(func() -> bool: return _rt(guest).net.mode_text().begins_with("Joined"), "the Guest to be welcomed", FPS * 40)
	await _wait(func() -> bool: return _cp(guest).phase == CutscenePlayer.Phase.LATE, "the Guest to hold black", FPS * 10)
	_check(_cs(host).is_playing(), "the Host still plays it")
	_check(_cp(guest).black() == 1.0 and not _cp(guest).voiced, "the Guest holds black and plays no cutscene of its own")
	_check(_day(guest).first_wash == LaundryDay.FirstWash.PLAYING, "the Guest sees the First wash under way")
	_check(_rt(guest).mess.count() == _rt(host).mess.count() and _rt(guest).mess.count() > 0, "the Guest's Mess holds the Socks (%d)" % _rt(guest).mess.count())
	_check(Washer.of_level(guest).is_broken(), "the Guest's washer is broken")
	_rt(host).parts.ask(Command.new(Cutscenes.SKIP, Parts.HOST, _cs(host).id))
	await _wait(func() -> bool: return _cp(guest).phase == CutscenePlayer.Phase.IDLE and _day(guest).first_wash == LaundryDay.FirstWash.DONE,
			"the Host's end to reach the Guest", FPS * 10)
	_check(_day(host).first_wash == LaundryDay.FirstWash.DONE, "DONE on the Host")
	await _paced_ticks(3)
	var spawns := Washer.of_level(guest).get_parent().get_node("Spawns")
	var feet := _rt(guest).player.global_position
	var near := false
	for spot in spawns.get_children():
		var at := (spot as Node3D).global_position
		near = near or Vector2(feet.x - at.x, feet.z - at.z).length() < 1.0
	_check(near, "the Guest spawns by the washer (%s)" % feet)
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
