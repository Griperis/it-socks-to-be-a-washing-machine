## The Cutscene frame in co-op (core/88): zoos in one process, each a machine of its own, real ENet over
## 127.0.0.1 with tests/support/lag_peer.gd on both ends, frames paced to 60 a second of wall time
## (tests/coop_carry_test.gd). The Host plays cutscene_fix_1 at the washer station: the Guest sees the same
## cutscene (same serial and takes, its camera at the wide shot, its input off), shows no skip hint and its
## skip is dropped; the Host's skip ends it on both and each respawns at its own washer spawn. A Guest whose
## timeline runs out first holds black until the Host's end. A late joiner during it holds black and spawns
## after it at the laundry.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["WasherStation"]
const WASHER := "Stations/WasherStation/Washer"
const SILENT := "res://tests/fixtures/cutscene_silent.tres"
const NET_WAIT_S := 20.0
const FPS := 60

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "same_0ms", "method": "case_same_0ms", "world": false,
				"title": "0 ms: the Guest sees the Host's cutscene (same serial and takes, wide shot, input off), no skip hint, its skip dropped; the Host's skip ends it on both, each at its own washer spawn"},
		{"name": "same_50ms", "method": "case_same_50ms", "world": false,
				"title": "50 ms one way: the same"},
		{"name": "guest_holds_black", "method": "case_guest_holds_black", "world": false,
				"title": "a Guest whose timeline runs out first holds black until the Host's end, then respawns"},
		{"name": "late_joiner", "method": "case_late_joiner", "world": false,
				"title": "a Guest that joins during a cutscene holds black with input off, and spawns at the laundry after the Host's end"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(CutscenePlayer.SKIP)
	_drop_branches()


func case_same_0ms() -> void:
	await _round(0)


func case_same_50ms() -> void:
	await _round(50)


func _round(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	_play(host, "cutscene_fix_1")
	await _wait(func() -> bool: return _cp(host).phase == CutscenePlayer.Phase.PLAYING and _cp(guest).phase == CutscenePlayer.Phase.PLAYING,
			"both machines to play it", FPS * 3)
	_check(_cs(host).serial == _cs(guest).serial and _cs(host).takes == _cs(guest).takes and _cs(guest).playing == _cs(host).playing,
			"the same cutscene, serial and takes on both")
	_check(_rt(guest).player.in_cutscene() and not _rt(guest).player.hud().visible, "the Guest's input is off and its HUD hidden")
	_check(_cp(guest).camera.current and _cp(guest).shot == CutscenePlayer.WIDE, "the Guest's view is the wide shot")
	_check(_cp(host).skip_text() != "" and _cp(guest).skip_text() == "", "the skip hint shows on the Host's screen only")
	var g := _rt(guest).player.player_id()
	_rt(guest).parts.ask(Command.new(Cutscenes.SKIP, g, _cs(guest).id))
	await _paced_ticks(int(lag_ms * 3 * FPS / 1000.0) + 10)
	_check(_cs(host).is_playing() and _cs(guest).is_playing(), "the Guest's skip changes nothing")
	_rt(host).parts.ask(Command.new(Cutscenes.SKIP, Parts.HOST, _cs(host).id))
	await _wait(func() -> bool: return _cp(host).phase == CutscenePlayer.Phase.IDLE and _cp(guest).phase == CutscenePlayer.Phase.IDLE,
			"the Host's skip to end it on both", FPS * 3)
	await _paced_ticks(3)
	_check(_spawn_of(host, _rt(host).player.global_position) == 0, "the Host stands at spawn 1")
	_check(_spawn_of(guest, _rt(guest).player.global_position) == 1, "the Guest stands at spawn 2, beside it")
	_check(not _rt(guest).player.in_cutscene() and _rt(guest).player.hud().visible, "the Guest's input and HUD are back")
	_drop_branches()


func case_guest_holds_black() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	# A sequence's answer, as core/92's Fix will give it.
	_rt(host).parts.apply(_cs(host).start(SILENT))
	await _wait(func() -> bool: return _cp(guest).phase == CutscenePlayer.Phase.PLAYING, "the Guest to play it", FPS * 3)
	# The Guest's clock runs ahead: its timeline runs out while the Host's still plays.
	_cp(guest).elapsed = _cp(guest).length - 0.05
	_cp(host).elapsed = 0.0
	await _wait(func() -> bool: return _cp(guest).phase == CutscenePlayer.Phase.HOLDING, "the Guest's timeline to run out", FPS)
	await _paced_ticks(10)
	_check(_cp(guest).phase == CutscenePlayer.Phase.HOLDING and _cp(guest).black() == 1.0 and _cs(guest).is_playing(),
			"the Guest holds black while the Host's plays")
	_check(_rt(guest).player.in_cutscene(), "its input stays off")
	await _wait(func() -> bool: return _cp(guest).phase == CutscenePlayer.Phase.IDLE, "the Host's timeline to end it", FPS * 5)
	await _paced_ticks(3)
	_check(_spawn_of(guest, _rt(guest).player.global_position) == 1, "the Guest respawns at spawn 2")
	_drop_branches()


func case_late_joiner() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	_play(host, "cutscene_fix_1")
	await _wait(func() -> bool: return _cp(host).phase == CutscenePlayer.Phase.PLAYING, "the Host to play it", FPS * 3)
	var late := await _join("Late")
	await _wait(func() -> bool: return _cp(late).phase == CutscenePlayer.Phase.LATE, "the late joiner to hold", FPS * 3)
	_check(_cp(late).black() == 1.0 and _rt(late).player.in_cutscene() and not _rt(late).player.hud().visible,
			"it holds black with input off and the HUD hidden")
	_check(not _cp(late).voiced, "it plays no cutscene of its own")
	_rt(host).parts.ask(Command.new(Cutscenes.SKIP, Parts.HOST, _cs(host).id))
	await _wait(func() -> bool: return _cp(late).phase == CutscenePlayer.Phase.IDLE, "the Host's end to reach it", FPS * 3)
	await _paced_ticks(3)
	_check(_spawn_of(late, _rt(late).player.global_position) >= 0, "it spawns at a washer spawn (%s)" % _rt(late).player.global_position)
	_check(not _rt(late).player.in_cutscene() and _rt(late).player.hud().visible, "its input and HUD are back")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## The Host's washer station pillar's Command (the real path's press is cutscene_test's).
func _play(host: Node3D, trigger: String) -> void:
	var run := host.get_node("Stations/WasherStation/Run") as WasherRun
	_rt(host).parts.ask(Command.new(WasherRun.CUTSCENE, Parts.HOST, run.id, {"trigger": trigger}))


func _spawn_of(zoo: Node3D, feet: Vector3) -> int:
	var spawns := zoo.get_node(WASHER + "/Spawns").get_children()
	for i in spawns.size():
		var spot := (spawns[i] as Node3D).global_position
		if Vector2(feet.x - spot.x, feet.z - spot.z).length() < 0.05:
			return i
	return -1


func _pair(lag_ms: int) -> Array[Node3D]:
	var host := _branch("Host")
	await _frames(2)
	var hs := _rt(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(_rt(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	var guest := await _join("Guest", lag_ms)
	return [host, guest]


func _join(label: String, lag_ms := 0) -> Node3D:
	var host := (_branches[0] as Node).get_node("View/Zoo") as Node3D
	var zoo := _branch(label)
	await _frames(2)
	var gs := _rt(zoo).session
	gs.profile = PlayerProfile.fresh()
	_check(_rt(zoo).net.start(["--join=127.0.0.1:%d" % _rt(host).session.port]) == OK, "%s joins" % label)
	_lag(zoo, lag_ms)
	await _wait(func() -> bool: return _rt(zoo).net.mode_text().begins_with("Joined"), "%s to be welcomed" % label, FPS * 10)
	return zoo


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced_ticks(n: int) -> void:
	for _i in n:
		await _paced()


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _rt(zoo: Node3D) -> LevelRuntime:
	return LevelRuntime.of(zoo)


func _cs(zoo: Node3D) -> Cutscenes:
	return _rt(zoo).cutscenes


func _cp(zoo: Node3D) -> CutscenePlayer:
	return _rt(zoo).cutscene_player


func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## A zoo in a machine of its own (its own MultiplayerAPI and 3D world), with only the KEEP stations.
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
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var zoo := node.get_node_or_null("View/Zoo")
		var session := LevelRuntime.of(zoo).session if zoo != null else null
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
