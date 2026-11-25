## The Cabinets grow (core/81): a Cabinet stands at its `rows` of six Drawer modules (the rest hidden, out
## of reach), and when a floor opens each new Drawer falls in on top with the old timings, a `drawer_thunk`
## and a dust puff at its seam, at once whether seen or not; a load shows the grown height with no drop.
## The real path plays the Stages station's mini run: the player completes Stage 1, presses E on "Fit now",
## Cabinet A's third Drawer drops in, and the player clicks a Pair into it.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
const BY_SWITCHES := Vector3(0.25, 0.0, 2.8)
## The old stacking (BASE_H, SEGMENT_H).
const BASE_H := 0.10
const SEGMENT_H := 0.30

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _stages: Stages = null
var _a: Cabinet = null
var _b: Cabinet = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player completes Stage 1 and presses E on \"Fit now\"; Cabinet A's third Drawer drops in (thunk, dust), and the player clicks a Pair into it"},
		{"name": "stands_at_rows", "method": "case_stands_at_rows", "world": false,
				"title": "a Cabinet shows its Rows' Drawers and segments, the top on them, the rest hidden with collision off and the shell as tall; a locked one shows the Rows it unlocks with"},
		{"name": "drop_timing", "method": "case_drop_timing", "world": false,
				"title": "the drop: the shell is full height at once, each new module waits its delay, falls in order a gap apart, a thunk and a dust puff at each seam, seen or not"},
		{"name": "load_no_drop", "method": "case_load_no_drop", "world": false,
				"title": "a load or a join shows the grown Cabinet at its height with no drop"},
		{"name": "tuning", "method": "case_tuning", "world": false,
				"title": "the Drawer drop group holds the old numbers (0.8 s, 0.35 s, 0.8 m, 0.25 s, #cbbfa8, 24) and drawer_thunk is in the catalogue"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	_quick(_a)
	var thunks: Array = []
	Sounds.played.connect(func(e: StringName, _s: bool, at: Vector3, _b: StringName) -> void:
		if e == &"drawer_thunk":
			thunks.append(at))
	for i in 3:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	_stand(BY_SOCKS)
	await _aim(_player, _centre(SIMPLE[3]))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == SIMPLE[3], "the Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(SIMPLE[3] + 1))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair")
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 1))
	await _press(&"pick")
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	_check(not _drawer_root(_a, 2).visible, "before the floor opens the third Drawer is not there")
	_stand(BY_SWITCHES)
	await _aim(_player, _button("FitNow"))
	await _press(&"interact")
	await _until(func() -> bool: return _stages.stage == 1, "the next floor to open")
	_check(_a.rows == 3, "Cabinet A has 3 Rows")
	await _until(func() -> bool: return _a.growth.drops == 1 and not _a.growth.growing(), "the third Drawer to land")
	_check(_drawer_root(_a, 2).visible and thunks.size() == 1, "it landed with one thunk (%d)" % thunks.size())
	_check(is_equal_approx(_drawer_root(_a, 2).position.y, BASE_H + 2 * SEGMENT_H + 0.01), "in its place")
	_check(_has_puff(_a), "a dust puff burst from its seam")
	# The player clicks a Pair into the new Drawer.
	_stand(BY_SOCKS)
	var sock: int = SIMPLE[4]
	for s: int in [sock, sock + 1]:
		_hands.clock += 10.0
		_hands.pick(1, s)
		await _physics_ticks(1)
	_check(_mess.is_pair(sock), "a Pair in the Hands")
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 2))
	await _press(&"pick")
	await _until(func() -> bool: return _a.contents(2).size() == 1, "the Pair to go into the third Drawer")


# --- Rules ---------------------------------------------------------------------------------------

func case_stands_at_rows() -> void:
	await _build()
	_check(_a.growth.shown() == 2 and not _a.growth.growing(), "Cabinet A stands at its 2 Rows")
	_check(_stands_at(_a, 2), "two segments and Drawers shown, the top on them, the rest hidden")
	_check(_stands_at(_b, 2), "a locked Cabinet shows the Rows it unlocks with")
	for i in 6:
		var slide := _drawer_root(_a, i).get_node("Looks/Slide") as CollisionObject3D
		_check((slide.collision_layer != 0) == (i < 2), "Drawer %d's collision is %s" % [i + 1, "on" if i < 2 else "off"])
	var shell := _a.get_parent().get_node("Shape") as CollisionShape3D
	_check(is_equal_approx((shell.shape as BoxShape3D).size.y, BASE_H + 2 * SEGMENT_H + 0.05), "the shell is as tall as the Rows")
	_check((_b.get_parent().get_node("Shape") as CollisionShape3D).shape != shell.shape, "each Cabinet has its own shell shape")
	_parts.load_snapshot({_a.id: {"rows": 6}})
	_check(_stands_at(_a, 6), "six Rows stand: every segment and Drawer, the top above them")
	var slide6 := _drawer_root(_a, 5).get_node("Looks/Slide") as CollisionObject3D
	_check(slide6.collision_layer != 0, "the sixth Drawer is in reach again")
	_parts.load_snapshot({_a.id: {"rows": 0}})
	_check(_stands_at(_a, 0), "no Rows: no segment, the top on the base")


func case_drop_timing() -> void:
	await _build()
	var t := _a.tuning.duplicate() as CabinetTuning
	t.drop_delay = 0.3
	t.drop_gap = 0.2
	t.drop_time = 0.1
	_a.tuning = t
	var thunks: Array = []
	Sounds.played.connect(func(e: StringName, _s: bool, at: Vector3, _b: StringName) -> void:
		if e == &"drawer_thunk":
			thunks.append(at))
	# Nobody is near: the player stays at the far end of the station.
	_parts.apply({"ok": true, "changes": _a.lock_patch(false, 4)})
	_check(_a.rows == 4 and _a.growth.growing(), "rows 4 and a drop under way at once")
	var shell := _a.get_parent().get_node("Shape") as CollisionShape3D
	_check(is_equal_approx((shell.shape as BoxShape3D).size.y, BASE_H + 4 * SEGMENT_H + 0.05), "the shell is the full new height at once")
	_check(not _drawer_root(_a, 2).visible and not _drawer_root(_a, 3).visible, "no new Drawer shows during the delay")
	await _until(func() -> bool: return _drawer_root(_a, 2).visible, "the first new Drawer to fall in")
	_check(not _drawer_root(_a, 3).visible, "the second waits its gap")
	await _until(func() -> bool: return _a.growth.drops == 2 and not _a.growth.growing(), "both to land")
	_check(thunks.size() == 2, "two landings, two thunks (%d)" % thunks.size())
	if thunks.size() == 2:
		_check(thunks[0].y < thunks[1].y, "the lower first")
		_check(is_equal_approx(thunks[0].y - _a.get_parent().global_position.y, BASE_H + 3 * SEGMENT_H), "a thunk at its Drawer's top seam")
	_check(_stands_at(_a, 4), "it stands at 4 Rows")
	_check(not _a.drawer(2).locked and not _a.drawer(3).locked, "its Drawers are open to a click")


func case_load_no_drop() -> void:
	await _build()
	_parts.load_snapshot({_a.id: {"rows": 4}})
	_check(not _a.growth.growing() and _a.growth.drops == 0, "a load starts no drop")
	_check(_stands_at(_a, 4), "the grown Cabinet stands at its height")
	await _physics_ticks(5)
	_check(not _has_puff(_a), "no dust")


func case_tuning() -> void:
	var t := load("res://game/entities/cabinet/cabinet_tuning.tres") as CabinetTuning
	_check(t.drop_delay == 0.8 and t.drop_time == 0.35 and t.drop_height == 0.8 and t.drop_gap == 0.25, "the old timings")
	_check(t.dust_colour == Color("#cbbfa8") and t.dust_amount == 24, "the old dust")
	var cat := load("res://game/audio/sound_catalogue.tres") as SoundCatalogue
	var found := false
	for e in cat.events:
		found = found or e.event == &"drawer_thunk"
	_check(found, "drawer_thunk is in the catalogue")


# --- Helpers -------------------------------------------------------------------------------------

## The station on a floor with the player and a Parts; `plan` replaces the mini run's plan. Waits for
## the run to start.
func _build(plan: StagePlan = null) -> void:
	if _level != null:
		_level.free()
		_level = null
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_station.position = Vector3.ZERO
	if plan != null:
		(_station.get_node("Run/Stages") as Stages).plan = plan
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_stages = _station.get_node("Run/Stages") as Stages
	_a = _station.get_node("CabinetA/Cabinet") as Cabinet
	_b = _station.get_node("CabinetB/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and _stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")


## Pairs Sock `sock` with its mate (the next id) by the Hands' Command and shelves the Pair into
## Cabinet A's drawer `drawer` by the Cabinet's click.
func _shelve_pair(sock: int, drawer: int) -> void:
	for s: int in [sock, sock + 1]:
		_hands.clock += 10.0
		_hands.pick(1, s)
		await _physics_ticks(1)
	_check(_mess.is_pair(sock), "Socks %d and %d fused into a Pair" % [sock, sock + 1])
	var before := _a.shelved().size()
	_a.click(1, drawer)
	await _until(func() -> bool: return _a.shelved().size() == before + 1, "the Pair %d to be shelved" % sock)
	await _physics_ticks(1)


## Asks the "Fit now" switch by its own Command.
func _fit_now() -> void:
	(_station.get_node("FitNow/StagesSwitch") as StagesSwitch).use(1)
	await _physics_ticks(1)


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _button(switch: String) -> Vector3:
	return (_station.get_node("%s/Looks/Button" % switch) as Node3D).global_position


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)

## Whether Cabinet `cab` stands at `rows`: the Drawers and segments below shown, the rest hidden, the top on them.
func _stands_at(cab: Cabinet, rows: int) -> bool:
	var looks := cab.get_parent().get_node("Looks")
	for i in 6:
		if _drawer_root(cab, i).visible != (i < rows) or (looks.get_node("Segment%d" % (i + 1)) as Node3D).visible != (i < rows):
			return false
	return is_equal_approx((looks.get_node("Top") as Node3D).position.y, BASE_H + rows * SEGMENT_H)


func _drawer_root(cab: Cabinet, index: int) -> Node3D:
	return cab.get_parent().get_node("Drawer%d" % (index + 1)) as Node3D


func _has_puff(cab: Cabinet) -> bool:
	for c in cab.get_parent().get_children():
		if c is GPUParticles3D:
			return true
	return false


## Short drop times, so a case does not wait for the old ones.
func _quick(cab: Cabinet) -> void:
	var t := cab.tuning.duplicate() as CabinetTuning
	t.drop_delay = 0.1
	t.drop_gap = 0.05
	t.drop_time = 0.1
	cab.tuning = t
