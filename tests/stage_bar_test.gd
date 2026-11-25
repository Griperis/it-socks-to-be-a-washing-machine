## The Stage bar (core/82): the HUD's bar in the Stages station's mini run. The player clicks a Pair
## into Cabinet A and the bar reads "Stage 1: Basement  1/4" and moves its fill; "Fit now" drains and
## refills it with Stage 2's icons; the three phases (goal, Stage, the Laundry day's fold) are set by a
## test-side stand-in provider; the bar draws only on a change and is hidden in a level with no run.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const STAND_IN := preload("res://tests/fixtures/stage_bar_stand_in.gd")
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's Socks, by id: Simple Pairs of Designs 0..5, then Sport.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
const BY_SWITCHES := Vector3(0.25, 0.0, 2.8)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _stages: Stages = null
var _a: Cabinet = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player clicks a Pair into Cabinet A, the bar reads \"Stage 1: Basement  1/4\" and its fill moves; full it stays full; after Fit now it drains and refills with Stage 2's icons"},
		{"name": "phases", "method": "case_phases", "world": false,
				"title": "set to each phase the bar shows \"Wash the laundry\" with no track, then the Stage, then folds into \"Wash clothes 0/3\" with the bin icon"},
		{"name": "redraws", "method": "case_redraws", "world": false,
				"title": "the bar is drawn again only when what it shows changed"},
		{"name": "no_run", "method": "case_no_run", "world": false,
				"title": "the bar is hidden in a level with no run"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- Cases ---------------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var bar := _bar()
	await _until(func() -> bool: return bar.text() == "Stage 1: Basement  0/4", "the bar to read the new Stage (%s)" % bar.text())
	_check(bar.visible and bar.track_shown() and bar.phase() == _stages.plan.stage_phase, "the Stage phase shows its track")
	_check(bar.icon_keys() == ["simple"], "Cabinet A's Collection icon (%s)" % [bar.icon_keys()])
	_check(is_zero_approx(bar.ratio()), "the fill is empty")
	# One Pair by the player's own input: both Socks picked, then the click on the drawer.
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
	await _aim(_player, _drawer_front(_a, 0))
	await _press(&"pick")
	await _until(func() -> bool: return bar.text() == "Stage 1: Basement  1/4", "the bar to read 1/4 (%s)" % bar.text())
	await _until(func() -> bool: return is_equal_approx(_fill_share(bar), 0.25), "the fill to move to a quarter (%s)" % _fill_share(bar))
	_check(is_equal_approx(bar.ratio(), 0.25), "its share is a quarter")
	# The rest fills the bar: it stays full while the Part lies.
	for i in 3:
		await _shelve_pair(SIMPLE[i], 0 if i < 1 else 1)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	await _until(func() -> bool: return bar.text() == "Stage 1: Basement  4/4", "the bar to read 4/4 (%s)" % bar.text())
	await _physics_ticks(30)
	_check(is_equal_approx(bar.ratio(), 1.0) and bar.text() == "Stage 1: Basement  4/4", "full between the completion and the Fix")
	# E on "Fit now": the new Stage drains and refills, with Stage 2's icons.
	var resets := bar.resets
	_stand(BY_SWITCHES)
	await _aim(_player, _button("FitNow"))
	await _press(&"interact")
	await _until(func() -> bool: return bar.text() == "Stage 2: Ground  0/6", "the bar to read Stage 2 (%s)" % bar.text())
	_check(bar.resets == resets + 1, "the bar reset once")
	_check(bar.icon_keys() == ["simple", "sport"], "Stage 2's icons (%s)" % [bar.icon_keys()])
	await _until(func() -> bool: return _icons_popped(bar), "the icons to have popped in")


func case_phases() -> void:
	await _build()
	var bar := _bar()
	var stand_in := STAND_IN.new() as Node
	stand_in.pending = true
	_station.add_child(stand_in)
	await _until(func() -> bool: return bar.text() == "Wash the laundry", "the goal phase (%s)" % bar.text())
	_check(not bar.track_shown() and bar.icon_keys().is_empty() and bar.phase() == _stages.plan.goal_phase, "no track and no icons before the First wash")
	stand_in.pending = false
	await _until(func() -> bool: return bar.text() == "Stage 1: Basement  0/4", "the bar to change to the Stage (%s)" % bar.text())
	_check(bar.track_shown(), "the Stage shows its track")
	await _until(func() -> bool: return is_equal_approx(bar.scale.x, 1.0) and not bar.folding(), "the bar to have popped in")
	var folded := [0]
	bar.folded.connect(func() -> void: folded[0] += 1)
	await _fit_now()
	await _fit_now()
	await _until(func() -> bool: return bar.text() == "Wash clothes 0/3", "the fold into the Laundry day (%s)" % bar.text())
	_check(bar.folds == 1 and folded[0] == 1, "one fold, with its sound")
	_check(bar.icon_keys() == ["laundry_bin"], "the bin icon (%s)" % [bar.icon_keys()])
	await _until(func() -> bool: return not bar.folding() and is_equal_approx(bar.scale.x, 1.0), "the new phase to have popped in")
	stand_in.set_numbers(Vector2i(2, 3))
	await _until(func() -> bool: return bar.text() == "Wash clothes 2/3", "the tally to move (%s)" % bar.text())


func case_redraws() -> void:
	await _build()
	var bar := _bar()
	await _until(func() -> bool: return bar.text() == "Stage 1: Basement  0/4", "the bar to show the Stage")
	await _physics_ticks(10)
	var n := bar.redraws
	await _physics_ticks(60)
	_check(bar.redraws == n, "nothing changed, nothing drawn again (%d to %d)" % [n, bar.redraws])
	_parts.applied.emit({"ok": false})
	_check(bar.redraws == n, "an answer that changed nothing draws nothing")
	await _shelve_pair(SIMPLE[0], 0)
	await _until(func() -> bool: return bar.text() == "Stage 1: Basement  1/4", "the bar to move")
	_check(bar.redraws > n, "a shelved Pair draws it again")


func case_no_run() -> void:
	_level = Node3D.new()
	add_child(_level)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_level.add_child(_player)
	await _physics_ticks(20)
	_check(not _bar().visible and _bar().text() == "", "no run, no bar")


# --- Helpers -------------------------------------------------------------------------------------

func _bar() -> StageBar:
	return _player.get_node("Hud/StageBar") as StageBar


## The fill's share of the track as drawn now.
func _fill_share(bar: StageBar) -> float:
	var fill := bar.get_node("%Fill") as Control
	return fill.size.x / (bar.tuning.track_size.x - 2.0 * bar.tuning.fill_inset)


func _icons_popped(bar: StageBar) -> bool:
	for icon: Control in (bar.get_node("%Icons") as Control).get_children():
		if not is_equal_approx(icon.scale.x, 1.0):
			return false
	return true


## The station on a floor with the player and a Parts; waits for the run to start.
func _build() -> void:
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
