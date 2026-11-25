## The Fix scene in co-op (core/92): two houses in one process, each a machine of its own, real ENet over
## 127.0.0.1 (tests/coop_cutscene_test.gd's frame). The Host's Part fitted into the washing machine (the answer
## of the slot's fit): the Guest sees the same Fix scene (same cutscene, serial and takes) and the same phase; the
## floor opens at the Host's scene end and the Guest sees the ground floor's door open and Stage 2 current.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const DOOR := "FloorLocks/Ground/Padlock/FloorLock"
const NET_WAIT_S := 30.0
const FPS := 60

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "guest_sees_the_fix", "method": "case_guest_sees_the_fix", "world": false,
				"title": "a Guest sees the Host's Fix scene (same cutscene, serial and takes, the Stage FIXING) and, at its end, the same floor: the ground floor's door open, Stage 2 current"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(CutscenePlayer.SKIP)
	SockGenerator.start_all = false
	_drop_branches()


func case_guest_sees_the_fix() -> void:
	var host := _branch("Host")
	await _frames(2)
	var hs := _rt(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(_rt(host).net.start(["--host"]) == OK, "the host house hosts")
	await _wait(func() -> bool: return _rt(host).loading.is_lifted() and _stages(host).stage == 0, "the Host's run to start", FPS * 40)
	var guest := _branch("Guest")
	await _frames(2)
	var gs := _rt(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(_rt(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the guest joins")
	await _wait(func() -> bool: return _rt(guest).net.mode_text().begins_with("Joined"), "the Guest to be welcomed", FPS * 40)
	await _wait(func() -> bool: return _stages(guest).stage == 0, "the Guest to hold the run", FPS * 10)
	# The Host's Stage completes and its Part is fitted (the slot's answer, as the click gives it).
	_rt(host).parts.ask(Command.new(&"complete_now", Parts.HOST, _stages(host).id))
	await _wait(func() -> bool: return _stages(host).phase == Stages.Phase.PART_OUT and _stages(guest).phase == Stages.Phase.PART_OUT,
			"both machines to see the Part out", FPS * 5)
	_rt(host).parts.apply(_stages(host).fit_answer())
	await _wait(func() -> bool: return _cp(host).phase == CutscenePlayer.Phase.PLAYING and _cp(guest).phase == CutscenePlayer.Phase.PLAYING,
			"both machines to play the Fix scene", FPS * 5)
	_check(_stages(guest).phase == Stages.Phase.FIXING and _stages(host).phase == Stages.Phase.FIXING, "both see the Stage FIXING")
	_check(_cs(host).serial == _cs(guest).serial and _cs(host).takes == _cs(guest).takes and _cs(guest).playing.ends_with("fix_scene_1.tres"),
			"the same cutscene, serial and takes (%s)" % _cs(guest).playing)
	_check(_door(guest).is_locked(), "the ground floor's door is still shut on the Guest")
	await _wait(func() -> bool: return not _cs(host).is_playing() and not _cs(guest).is_playing(), "the scene to end on both", FPS * 90)
	await _wait(func() -> bool: return _stages(guest).stage == 1 and _stages(host).stage == 1, "both to see Stage 2", FPS * 5)
	_check(not _door(guest).is_locked() and not _door(host).is_locked(), "the ground floor's door is open on both")
	_check(_stages(guest).phase == Stages.Phase.PLAYING, "the Guest's Stage counts")
	_drop_branches()


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


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


func _door(house: Node3D) -> FloorLock:
	return house.get_node(DOOR) as FloorLock


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
