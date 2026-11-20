## Handling Socks (core/02): the Hands pick, hold and drop Socks of the Mess. One case per line of
## the approved behaviour list (ids M12-M15, H01-H28, T13), the invariants (I.1 every Sock in exactly
## one place after each step, I.3, the Commands) and the real path. Every case plays the station
## scene game/zoo/stations/handling.tscn on a floor, with the game's player and a Parts (a Host of
## one), as the zoo does.
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"zoom", &"turn", &"interact", &"move_forward", &"hands_next", &"hands_prev"]
## The station's Socks, by id (the order of its SockSpots).
const ON_FLOOR := 0
const UNDER := 1
const OVER := 2
const ON_TABLE := 3
const BEHIND_WALL := 4
const IN_CUPBOARD := 5
## Where the player stands for most cases: in front of the Socks on the floor, facing -Z.
const FRONT := Vector3(0.0, 0.0, 1.5)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the station the real actions pick a Sock, drop it on the table, pick it again, open the cupboard and drop it inside"},
		{"name": "m12_aim_pick", "method": "case_m12", "world": false,
				"title": "M12: a Sock in reach under the crosshair is outlined and a click picks it; the floor beside it, or one out of reach, picks nothing"},
		{"name": "m13_tip", "method": "case_m13", "world": false,
				"title": "M13: aiming at the tip of a Sock under another picks the lower one; the one on top stays"},
		{"name": "m14_wall", "method": "case_m14", "world": false,
				"title": "M14: a Sock behind a wall is not outlined and cannot be picked"},
		{"name": "m15_cupboard", "method": "case_m15", "world": false,
				"title": "M15: a Sock inside a shut cupboard cannot be aimed at; open, it can"},
		{"name": "h01_pick", "method": "case_h01", "world": false,
				"title": "H01: a click on an aimed Sock with room puts it into the Hands as the active item"},
		{"name": "h02_interval", "method": "case_h02", "world": false,
				"title": "H02: a click sooner than 0.35 s after a pick does nothing, with no message"},
		{"name": "h03_capacity", "method": "case_h03", "world": false,
				"title": "H03: the Hands hold 1 item to start; the zoo's player holds 3"},
		{"name": "h04_full", "method": "case_h04", "world": false,
				"title": "H04: with full Hands the clicked Sock stays and \"Hands full\" shows"},
		{"name": "h06_several", "method": "case_h06", "world": false,
				"title": "H06: the newest is active, big right of centre, the others small to the left; the wheel steps and wraps; one item stays"},
		{"name": "h21_zoom", "method": "case_h21", "world": false,
				"title": "H21: G eases the view to 50 degrees in 0.15 s, the look slows, the active item comes close and large, tucked ones keep their screen size"},
		{"name": "h22_turn", "method": "case_h22", "world": false,
				"title": "H22: R turns the active Sock about its long axis, one turn in 2 s, and it keeps the angle; walking and the wheel still work"},
		{"name": "h23_size", "method": "case_h23", "world": false,
				"title": "H23: a held Sock's Size letter shows"},
		{"name": "h28_right_empty", "method": "case_h28", "world": false,
				"title": "H28: the right button with empty Hands does nothing"},
		{"name": "h07_drop", "method": "case_h07", "world": false,
				"title": "H07: a tap with the crosshair white drops the active Sock where the crosshair is: the floor, the table, the shelf, a Heap; a long press does not"},
		{"name": "h08_refused", "method": "case_h08", "world": false,
				"title": "H08: with the crosshair red (too far, a wall, a narrow gap) nothing drops and \"Can't drop there\" shows; empty Hands keep it white"},
		{"name": "h09_into_cupboard", "method": "case_h09", "world": false,
				"title": "H09: aimed into the open cupboard, a drop lands inside"},
		{"name": "h10_flick_fall", "method": "case_h10", "world": false,
				"title": "H10: a dropped Sock flicks for 0.1 s, is let go 3 cm over the spot, falls as one body that cannot be picked, and lies where it settles"},
		{"name": "h11_settles", "method": "case_h11", "world": false,
				"title": "H11: dropped on a Sock or half over the table's edge it settles or falls, never floating or sinking"},
		{"name": "t13_settle_limit", "method": "case_t13", "world": false,
				"title": "T13: a fall that never settles is put down where it is after 6 s"},
		{"name": "i3_commands", "method": "case_i3", "world": false,
				"title": "I.3 and the Commands: every Hands change is a Command the Host answers; a held or falling Sock is refused to anyone else, a far one is refused"},
		{"name": "looks_contract", "method": "case_looks", "world": false,
				"title": "the Sock's Looks has the contract's nodes and states; the Designs are typed and complete"},
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
	await _aim(_player, _centre(ON_FLOOR))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == ON_FLOOR, "the Sock to be in the Hands")
	_check(_player.held_view().looks_of(ON_FLOOR) != null, "the Hands show it")
	_places("after the pick")
	_player.global_position = Vector3(-1.5, 0.0, 0.8)
	await _physics_ticks(2)
	var spot := Vector3(-1.3, 0.75, -0.4)
	await _aim(_player, spot)
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK, "the crosshair is white on the table")
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the Sock to come to rest")
	_places("after the drop on the table")
	_near(_mess.pose_of(ON_FLOOR).origin.y, 0.75, 0.03, "it lies on the table top")
	await _physics_ticks(30)
	await _aim(_player, _centre(ON_FLOOR))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == ON_FLOOR, "the Sock to be in the Hands again")
	_places("after the second pick")
	_player.global_position = Vector3(1.6, 0.0, 0.3)
	await _physics_ticks(2)
	await _aim(_player, Vector3(1.6, 1.0, -1.2))
	await _press(&"interact")
	var door := _station.get_node("Cupboard/Openable") as Openable
	await _until(func() -> bool: return door.open, "the cupboard to open")
	await _physics_ticks(40)
	await _aim(_player, Vector3(1.75, 1.015, -1.36))
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK, "the crosshair is white inside the open cupboard")
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the Sock to come to rest inside")
	_places("after the drop into the cupboard")
	_check(_inside_cupboard(_mess.pose_of(ON_FLOOR).origin), "it lies inside the cupboard (%s)" % _mess.pose_of(ON_FLOOR).origin)


# --- Aim and pick --------------------------------------------------------------------------------

func case_m12() -> void:
	await _build()
	await _aim(_player, _centre(ON_FLOOR))
	_check(_player.aimed_sock == ON_FLOOR, "the crosshair rests on the Sock (%d)" % _player.aimed_sock)
	_check(SockDress.state_of(_mess.looks_of(ON_FLOOR)) == SockDress.AIMED, "it is outlined")
	await _aim(_player, Vector3(-0.4, 0.0, 0.4))
	_check(_player.aimed_sock == -1, "the floor beside it is no Sock")
	_check(SockDress.state_of(_mess.looks_of(ON_FLOOR)) == SockDress.LYING, "and the outline goes")
	await _press(&"pick")
	_check(_hands.items_of(1).is_empty(), "a click on the floor picks nothing")
	_player.global_position = Vector3(0.0, 0.0, 2.6)
	await _physics_ticks(2)
	await _aim(_player, _centre(ON_FLOOR))
	_check(_player.aimed_sock == -1, "a Sock out of reach (%.2f m) is not aimed at" % _player.get_node("Head").global_position.distance_to(_centre(ON_FLOOR)))
	await _press(&"pick")
	_check(_hands.items_of(1).is_empty() and _mess.state_of(ON_FLOOR) == Mess.State.LYING, "and a click does not pick it")
	_places("after the clicks")


func case_m13() -> void:
	await _build()
	var under := _mess.pose_of(UNDER).origin
	var over := _mess.pose_of(OVER).origin
	var under_left := under.x - SockDress.box(_mess.design_of(UNDER)).x * 0.5
	var over_left := over.x - SockDress.box(_mess.design_of(OVER)).x * 0.5
	_check(under_left < over_left - 0.03, "the station's lower Sock sticks out from under the upper one")
	await _aim(_player, Vector3((under_left + over_left) * 0.5, 0.02, under.z))
	_check(_player.aimed_sock == UNDER, "aiming at the tip finds the lower Sock (%d)" % _player.aimed_sock)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == UNDER, "the lower Sock to be picked")
	_check(_mess.state_of(OVER) == Mess.State.LYING, "the Sock on top stays")
	_places("after picking the lower Sock")


func case_m14() -> void:
	await _build()
	_player.global_position = Vector3(0.0, 0.0, -0.3)
	await _physics_ticks(2)
	await _aim(_player, _centre(BEHIND_WALL))
	_check(_player.aimed_sock == -1, "the Sock behind the wall is not aimed at")
	_check(SockDress.state_of(_mess.looks_of(BEHIND_WALL)) == SockDress.LYING, "nor outlined")
	await _press(&"pick")
	_check(_mess.state_of(BEHIND_WALL) == Mess.State.LYING, "and a click does not pick it")


func case_m15() -> void:
	await _build()
	_player.global_position = Vector3(1.6, 0.0, 0.3)
	await _physics_ticks(2)
	await _aim(_player, _centre(IN_CUPBOARD))
	_check(_player.aimed_sock == -1, "a Sock in the shut cupboard is not aimed at")
	await _press(&"pick")
	_check(_mess.state_of(IN_CUPBOARD) == Mess.State.LYING, "nor picked")
	await _press(&"interact")
	var door := _station.get_node("Cupboard/Openable") as Openable
	await _until(func() -> bool: return door.open, "the cupboard to open")
	await _physics_ticks(40)
	await _aim(_player, _centre(IN_CUPBOARD))
	_check(_player.aimed_sock == IN_CUPBOARD, "open, the Sock inside is aimed at (%d)" % _player.aimed_sock)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == IN_CUPBOARD, "the Sock inside to be picked")


func case_h01() -> void:
	await _build()
	await _pick(ON_FLOOR)
	_check(_hands.items_of(1) == PackedInt32Array([ON_FLOOR]) and _hands.active_of(1) == ON_FLOOR, "the Sock is in the Hands and active")
	_check(_mess.state_of(ON_FLOOR) == Mess.State.HELD, "its record says held")
	_check(_mess.looks_of(ON_FLOOR) == null, "it no longer lies on the floor")
	_places("after the pick")


func case_h02() -> void:
	await _build()
	_capacity(3)
	await _pick(ON_FLOOR)
	await _aim(_player, _centre(OVER))
	await _press(&"pick")
	_check(_mess.state_of(OVER) == Mess.State.LYING, "a second click within 0.35 s picks nothing")
	_check(_player.message() == "", "and shows no message")
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == OVER, "a click after the interval to pick")
	_places("after both picks")


func case_h03() -> void:
	await _build()
	_check(_player.hands_tuning.capacity == 1, "the Hands hold 1 to start (%d)" % _player.hands_tuning.capacity)
	var zoo := (load(ZOO) as PackedScene).instantiate()
	var zoo_player := zoo.get_node("Player") as Player
	_check(zoo_player.hands_tuning != null and zoo_player.hands_tuning.capacity == 3, "the zoo's player holds 3")
	zoo.free()


func case_h04() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	await _aim(_player, _centre(OVER))
	await _press(&"pick")
	_check(_mess.state_of(OVER) == Mess.State.LYING and _hands.items_of(1).size() == 1, "the clicked Sock stays")
	_check(_player.message() == Player.HANDS_FULL, "\"Hands full\" shows (%s)" % _player.message())
	_places("after the refused pick")


# --- Holding -------------------------------------------------------------------------------------

func case_h06() -> void:
	await _build()
	_capacity(3)
	await _pick(ON_FLOOR)
	await _physics_ticks(1)
	await _wheel(&"hands_next")
	_check(_hands.active_index(1) == 0, "with one item the wheel changes nothing")
	await _physics_ticks(25)
	await _pick(OVER)
	await _physics_ticks(25)
	await _pick(UNDER)
	_check(_hands.active_of(1) == UNDER, "the newest is active")
	await _frames(2)
	var view := _player.held_view()
	var active := view.looks_of(UNDER)
	var tucked := view.looks_of(ON_FLOOR)
	_check(active.position.x > 0.0 and tucked.position.x < 0.0, "the active one right of centre, the tucked left (%.3f, %.3f)" % [active.position.x, tucked.position.x])
	_check(active.scale.x > tucked.scale.x * 1.5, "the active one big, the tucked small (%.3f, %.3f)" % [active.scale.x, tucked.scale.x])
	await _wheel(&"hands_next")
	_check(_hands.active_index(1) == 0, "the wheel wraps to the first (%d)" % _hands.active_index(1))
	await _wheel(&"hands_prev")
	_check(_hands.active_index(1) == 2, "and back (%d)" % _hands.active_index(1))
	_places("after the wheel")


func case_h21() -> void:
	await _build()
	_capacity(3)
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	await _pick(OVER)
	await _frames(2)
	var view := _player.held_view()
	var camera := _player.camera()
	var active_before := view.looks_of(OVER).transform
	var tucked_before := view.looks_of(ON_FLOOR).transform
	_near(camera.fov, 75.0, 0.01, "unzoomed, 75 degrees")
	Input.action_press(&"zoom")
	await _frames(int(0.15 * 60.0) + 2)
	_near(camera.fov, 50.0, 0.01, "after 0.15 s the view is 50 degrees")
	_near(_player.zoom_slow(), tan(deg_to_rad(25.0)) / tan(deg_to_rad(37.5)), 0.001, "the look slows with it")
	await _frames(1)
	var active := view.looks_of(OVER).transform
	var tucked := view.looks_of(ON_FLOOR).transform
	_check(active.basis.get_scale().x > active_before.basis.get_scale().x and absf(active.origin.z) < absf(active_before.origin.z),
			"the active item comes closer and larger")
	var k := view.zoom_factor()
	_near(tucked.basis.get_scale().x, tucked_before.basis.get_scale().x * k, 0.0001, "a tucked item is drawn smaller by the zoom")
	_near(tucked.origin.z, tucked_before.origin.z, 0.0001, "at its depth")
	_near(tucked.origin.x / tan(deg_to_rad(camera.fov) * 0.5), tucked_before.origin.x / tan(deg_to_rad(37.5)), 0.0001,
			"so it keeps its place and size on screen")
	Input.action_release(&"zoom")
	await _until(func() -> bool: return is_equal_approx(camera.fov, 75.0), "letting go to put the view back")


func case_h22() -> void:
	await _build()
	_capacity(3)
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	await _pick(OVER)
	var view := _player.held_view()
	Input.action_press(&"turn")
	Input.action_press(&"move_forward")
	var start := _player.global_position
	await _frames(30)
	var angle := view.spin_of(OVER)
	_near(absf(angle), PI * 0.5, 0.08, "half a second turns it a quarter turn (%.3f)" % angle)
	_check(start.distance_to(_player.global_position) > 0.5, "walking still works while turning")
	await _wheel(&"hands_next")
	_check(_hands.active_index(1) == 0, "the wheel still works while turning")
	await _wheel(&"hands_next")
	Input.action_release(&"turn")
	Input.action_release(&"move_forward")
	await _frames(1)
	var kept := view.spin_of(OVER)
	await _frames(20)
	_near(view.spin_of(OVER), kept, 0.0001, "let go, it keeps its angle")
	_check(not is_zero_approx(kept), "turned, not put back")


func case_h23() -> void:
	await _build()
	_check(_player.size_shown() == "", "nothing shows with empty Hands")
	await _pick(ON_FLOOR)
	await _physics_ticks(2)
	var design := _mess.design_of(ON_FLOOR)
	_check(_player.size_shown() == design.size_letter() and design.size_letter() in ["S", "M", "L"],
			"the held Sock's Size letter shows (%s)" % _player.size_shown())


func case_h28() -> void:
	await _build()
	await _aim(_player, Vector3(0.0, 0.0, 0.5))
	var before := _mess.state()
	await _press(&"drop_throw")
	await _physics_ticks(5)
	_same(_mess.state(), before, "the right button with empty Hands changes no Sock")
	_check(_player.message() == "", "and says nothing")


# --- Drop ----------------------------------------------------------------------------------------

func case_h07() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var spot := Vector3(0.3, 0.0, 0.4)
	await _aim(_player, spot)
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK, "the crosshair is white on the floor")
	Input.action_press(&"drop_throw")
	await _physics_ticks(int(0.4 * 60.0))
	Input.action_release(&"drop_throw")
	await _physics_ticks(2)
	_check(_hands.active_of(1) == ON_FLOOR, "a long press (0.4 s) does not drop")
	await _drop_at(spot, ON_FLOOR, "the floor")
	_near(_mess.pose_of(ON_FLOOR).origin.y, 0.0, 0.03, "it lies on the floor")
	_player.global_position = Vector3(-1.5, 0.0, 0.8)
	await _physics_ticks(2)
	for target: Array in [[Vector3(-1.3, 0.75, -0.3), 0.75, "the table"]]:
		await _repick(ON_FLOOR)
		await _drop_at(target[0], ON_FLOOR, target[2])
		_near(_mess.pose_of(ON_FLOOR).origin.y, target[1], 0.03, "it lies on %s" % target[2])
	await _repick(ON_FLOOR)
	await _drop_at(_centre(ON_TABLE) + Vector3(0.0, 0.013, 0.0), ON_FLOOR, "a Heap (the Sock on the table)")
	_check(_mess.pose_of(ON_FLOOR).origin.y > 0.75 - 0.01, "it rests on the table or the Sock there, not under")
	_player.global_position = Vector3(0.0, 0.0, 0.0)
	await _physics_ticks(2)
	await _repick(ON_FLOOR)
	await _drop_at(Vector3(0.1, 1.015, -1.0), ON_FLOOR, "the shelf")
	_near(_mess.pose_of(ON_FLOOR).origin.y, 1.015, 0.03, "it lies on the shelf")
	_places("after the drops")


func case_h08() -> void:
	await _build()
	_player.global_position = Vector3(0.0, 0.0, 0.0)
	await _physics_ticks(2)
	await _aim(_player, Vector3(0.0, 1.2, -1.15))
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK, "with empty Hands the crosshair is white, even on a wall")
	_player.global_position = FRONT
	await _physics_ticks(2)
	await _pick(ON_FLOOR)
	_player.global_position = Vector3(0.0, 0.0, 0.0)
	await _physics_ticks(2)
	for target: Array in [[Vector3(0.0, 1.4, -1.15), "a wall"], [Vector3(0.0, 1.6, -20.0), "too far"]]:
		await _aim(_player, target[0])
		_check(_player.crosshair_colour() == Player.CROSSHAIR_NO, "the crosshair is red on %s" % target[1])
		await _press(&"drop_throw")
		await _physics_ticks(3)
		_check(_hands.active_of(1) == ON_FLOOR, "nothing drops on %s" % target[1])
		_check(_player.message() == Player.CANT_DROP, "\"Can't drop there\" shows (%s)" % _player.message())
	_player.global_position = Vector3(1.6, 0.0, 1.3)
	await _physics_ticks(2)
	await _aim(_player, Vector3(1.6, 0.3, 0.6))
	_check(_player.crosshair_colour() == Player.CROSSHAIR_NO, "the crosshair is red on a gap narrower than 8 cm")
	await _press(&"drop_throw")
	await _physics_ticks(3)
	_check(_hands.active_of(1) == ON_FLOOR, "nothing drops into the gap")
	_places("after the refusals")


func case_h09() -> void:
	await _build()
	await _pick(ON_FLOOR)
	_player.global_position = Vector3(1.6, 0.0, 0.3)
	await _physics_ticks(2)
	await _aim(_player, Vector3(1.6, 1.0, -1.2))
	await _press(&"interact")
	var door := _station.get_node("Cupboard/Openable") as Openable
	await _until(func() -> bool: return door.open, "the cupboard to open")
	await _physics_ticks(40)
	await _drop_at(Vector3(1.45, 1.015, -1.36), ON_FLOOR, "the open cupboard's shelf")
	_check(_inside_cupboard(_mess.pose_of(ON_FLOOR).origin), "it lies inside (%s)" % _mess.pose_of(ON_FLOOR).origin)


func case_h10() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var spot := Vector3(0.3, 0.0, 0.4)
	await _aim(_player, spot)
	await _press(&"drop_throw")
	_check(_mess.state_of(ON_FLOOR) == Mess.State.FLYING and _hands.items_of(1).is_empty(), "the Sock leaves the Hands")
	_check(_mess.flight_of(ON_FLOOR) == null, "during the flick it has no body yet")
	_places("during the flick")
	var flick_ticks := 0
	while _mess.flight_of(ON_FLOOR) == null and flick_ticks < 60:
		await _physics_ticks(1)
		flick_ticks += 1
	_near(flick_ticks / 60.0, 0.1, 0.04, "it is let go after the 0.1 s flick (%d ticks)" % flick_ticks)
	var body := _mess.flight_of(ON_FLOOR)
	_check(body != null and body.global_position.y > 0.015 and body.global_position.y < 0.06,
			"3 cm over the spot (%s)" % (body.global_position if body != null else Vector3.INF))
	_check(_hands.pick_refusal(1, ON_FLOOR) == Hands.GONE and _mess.looks_of(ON_FLOOR) == null, "while it falls it cannot be picked or aimed at")
	_places("while it falls")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to come to rest")
	var rest := _mess.pose_of(ON_FLOOR).origin
	_check(Vector2(rest.x, rest.z).distance_to(Vector2(spot.x, spot.z)) < 0.2, "it lies where it fell (%s)" % rest)
	_check(_mess.looks_of(ON_FLOOR) != null and _mess.flight_of(ON_FLOOR) == null, "lying again: drawn, its body gone")
	_places("after it rests")


func case_h11() -> void:
	await _build()
	_player.global_position = Vector3(-1.5, 0.0, 0.8)
	await _physics_ticks(2)
	await _pick(ON_TABLE)
	await _drop_at(Vector3(-1.5, 0.75, -0.3), ON_TABLE, "the table's front edge")
	var low := _lowest(ON_TABLE)
	_check(absf(low) < 0.02 or absf(low - 0.75) < 0.02, "half over the edge it settles on the table or the floor (%.3f)" % low)
	_player.global_position = FRONT
	await _physics_ticks(2)
	await _repick(ON_TABLE)
	await _drop_at(_centre(ON_FLOOR) + Vector3(0.0, 0.013, 0.0), ON_TABLE, "the Sock on the floor")
	low = _lowest(ON_TABLE)
	_check(low > -0.01 and low < 0.04, "on or beside a Sock it neither sinks nor floats (%.3f)" % low)
	_places("after the settles")


func case_t13() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, Vector3(0.3, 0.0, 0.4))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the body to be let go")
	var body := _mess.flight_of(ON_FLOOR)
	body.can_sleep = false
	await _physics_ticks(int(5.5 * 60.0))
	_check(_mess.state_of(ON_FLOOR) == Mess.State.FLYING, "a body that never sleeps still falls at 5.5 s")
	await _physics_ticks(int(0.6 * 60.0))
	_check(_mess.state_of(ON_FLOOR) == Mess.State.LYING, "after 6 s it is put down")
	_places("after the settle limit")


# --- Invariants and Commands ---------------------------------------------------------------------

func case_i3() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var ev := _parts.answer(Command.new(&"pick", 2, _hands.id, {"sock": ON_FLOOR}))
	_check(not ev["ok"] and ev["reason"] == Hands.GONE, "a held Sock is refused to another player (%s)" % ev)
	_check(_parts.answer(Command.new(&"drop", 2, _hands.id, {"point": Vector3.ZERO, "normal": Vector3.UP}))["reason"] == Hands.NOTHING,
			"another player cannot drop what they do not hold")
	_parts.where = func(by: int) -> Variant: return Vector3(0.0, 0.0, 20.0) if by == 2 else _player.global_position
	ev = _parts.answer(Command.new(&"pick", 2, _hands.id, {"sock": OVER}))
	_check(not ev["ok"] and ev["reason"] == Hands.FAR, "a Sock far from the player is refused (%s)" % ev)
	_parts.apply(_parts.answer(Command.new(&"pick", 2, _hands.id, {"sock": ON_TABLE})))
	_check(_hands.items_of(2).is_empty(), "nothing was given to the far player")
	_parts.where = Callable()
	_check(_hands.accepts().has(&"pick") and _hands.accepts().has(&"drop") and _hands.accepts().has(&"cycle"), "a Guest may ask pick, cycle and drop")
	_check(_mess.accepts().is_empty(), "no Guest may ask the Mess anything")
	_check(not _parts.answer(Command.new(&"rest", 2, _mess.id, {"sock": ON_FLOOR, "at": Vector3.ZERO, "rot": Vector3.ZERO}))["ok"],
			"only the Host writes a Sock at rest")
	var snap := _parts.snapshot()
	var back := _roundtrip(snap)
	var saved: Dictionary = back[String(_hands.id)]
	_same([saved["held"], saved["active"]], [snap[_hands.id]["held"], snap[_hands.id]["active"]], "the Hands survive a save")
	_places("after the refused Commands")


func case_looks() -> void:
	var catalogue := load("res://game/sock/designs.tres") as DesignCatalogue
	_check(catalogue != null and catalogue.size() > 600, "the Designs load (%d)" % (catalogue.size() if catalogue != null else 0))
	var ok := true
	for i in catalogue.size():
		ok = ok and catalogue.design(i) != null and catalogue.design(i).id == i
	_check(ok, "every Design is found by its id")
	var looks := SockDress.make(catalogue.design(0))
	add_child(looks)
	for n: String in ["Body", "Outline", "AnimationPlayer"]:
		_check(looks.has_node(n), "the Looks has %s" % n)
	for state: StringName in [SockDress.LYING, SockDress.HELD, SockDress.AIMED]:
		SockDress.play(looks, state)
		_check(SockDress.state_of(looks) == state, "the Looks plays %s" % state)
		_check((looks.get_node("Outline") as Node3D).visible == (state == SockDress.AIMED), "the outline shows only while aimed (%s)" % state)
	_near(looks.scale.x, catalogue.design(0).size_scale(), 0.0001, "it is scaled by its Size")
	looks.free()


# --- Helpers -------------------------------------------------------------------------------------

## A floor, the station, a Parts and the player standing at FRONT facing -Z.
func _build() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = FRONT
	_level.add_child(_player)
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Presses an action for one physics tick, then lets it go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## A wheel step through the viewport, as the mouse wheel's event comes.
func _wheel(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	await _physics_ticks(2)


## Aims at Sock `sock` and picks it with the real action.
func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock), "Sock %d to be picked" % sock)


## Waits out the grab interval and picks `sock` where it lies now.
func _repick(sock: int) -> void:
	await _physics_ticks(25)
	await _pick(sock)


## Aims at `spot`, taps the drop button and waits for `sock` to come to rest.
func _drop_at(spot: Vector3, sock: int, what: String) -> void:
	await _aim(_player, spot)
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK, "the crosshair is white on %s" % what)
	await _press(&"drop_throw")
	_check(not _hands.items_of(1).has(sock), "a tap drops it on %s" % what)
	await _until(func() -> bool: return _mess.state_of(sock) == Mess.State.LYING, "it to come to rest on %s" % what)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


## The middle of a lying Sock.
func _centre(sock: int) -> Vector3:
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


## The lowest corner of a lying Sock's box.
func _lowest(sock: int) -> float:
	var t := _mess.pose_of(sock)
	var b := SockDress.box(_mess.design_of(sock))
	var low := INF
	for x: float in [-0.5, 0.5]:
		for y: float in [0.0, 1.0]:
			for z: float in [-0.5, 0.5]:
				low = minf(low, (t * Vector3(b.x * x, b.y * y, b.z * z)).y)
	return low


func _inside_cupboard(p: Vector3) -> bool:
	var local := (_station.get_node("Cupboard") as Node3D).global_transform.affine_inverse() * p
	return absf(local.x) < 0.47 and local.z > -0.22 and local.z < 0.2 and local.y > 0.05 and local.y < 1.97


## I.1: every Sock is in exactly one place: lying (drawn), in exactly one player's Hands, or falling.
func _places(when: String) -> void:
	var counts := {"lying": 0, "held": 0, "flying": 0}
	var ok := true
	for sock in _mess.count():
		var holders := 0
		for by: Variant in _hands.held:
			holders += (_hands.held[by] as PackedInt32Array).count(sock)
		match _mess.state_of(sock):
			Mess.State.LYING:
				ok = ok and holders == 0 and _mess.looks_of(sock) != null and _mess.flight_of(sock) == null
				counts["lying"] += 1
			Mess.State.HELD:
				ok = ok and holders == 1 and _mess.looks_of(sock) == null and _mess.flight_of(sock) == null
				counts["held"] += 1
			Mess.State.FLYING:
				ok = ok and holders == 0 and _mess.looks_of(sock) == null
				counts["flying"] += 1
	_check(ok and _mess.count() == 6, "%s every Sock is in exactly one place (%s)" % [when, counts])
