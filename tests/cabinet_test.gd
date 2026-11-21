## One Cabinet (core/04): Pairs shelved into its drawers by a click and by a Throw, Doors and drawers
## opened by a click. One case per line of the approved behaviour list (C01-C05, C08, C11, C14,
## T05-T07, D02, D05, D08), the invariants I.5 and I.12, a snapshot round trip (C12) and the real
## path. Every case plays the station scene game/zoo/stations/cabinet.tscn on a floor, with the
## game's player and a Parts (a Host of one), as the zoo does.
extends TestSuite

const STATION := "res://game/zoo/stations/cabinet.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's Socks, by id (the order of its SockSpots): Simple Pairs of mates, an uncommon and a
## rare Simple Pair, a Patterns Pair and a loose Patterns Sock.
const S0 := 0
const S0_MATE := 1
const S1 := 2
const S1_MATE := 3
const S4 := 4
const S4_MATE := 5
const UNCOMMON := 6
const UNCOMMON_MATE := 7
const RARE := 8
const RARE_MATE := 9
const PATTERNS := 10
const PATTERNS_MATE := 11
const LOOSE := 12
const SOCKS := 13
## Where the player stands (station space): before the Socks, before the drawers, and throwing.
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
const BY_DRAWERS := Vector3(-1.0, 0.0, -0.4)
const THROW_FROM := Vector3(-1.0, 0.0, 0.6)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _coins: Coins = null
var _cabinet: Cabinet = null
var _parts: Parts = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the station the real actions pair two Socks, click a drawer and see the Pair in its slot and the Coins; a second Pair thrown at the Cabinet shelves itself"},
		{"name": "c01_click", "method": "case_c01", "world": false,
				"title": "C01: a click on a drawer shelves every held Pair of its Collection into it in the order held; another Collection's Pair stays; the drawer slides open"},
		{"name": "c02_wrong", "method": "case_c02", "world": false,
				"title": "C02: holding only another Collection's Pairs, a click says \"Wrong Cabinet\" and nothing moves"},
		{"name": "c03_overflow", "method": "case_c03", "world": false,
				"title": "C03: a full drawer passes the next Pair to the nearest drawer with room, the lower of two as near; each drawer used opens; a drawer never holds more than its capacity"},
		{"name": "c04_open_shut", "method": "case_c04", "world": false,
				"title": "C04: with empty Hands or only loose Socks a click opens or shuts the drawer; the click carries the state it asks for"},
		{"name": "c05_coins", "method": "case_c05", "world": false,
				"title": "C05, I.12: a shelving pays 10 x rarity (1, 2, 5) a Pair to the shelver alone, once per drawer used, never doubled"},
		{"name": "c08_wrong_before_locked", "method": "case_c08_order", "world": false,
				"title": "C08: holding only another Collection's Pairs at a locked Cabinet says \"Wrong Cabinet\", the old game's order (Q2285)"},
		{"name": "c08_locked_full", "method": "case_c08", "world": false,
				"title": "C08: a locked Cabinet says \"Cabinet locked\" and its drawers stay shut; full Rows say \"Cabinet full\"; the Pairs stay; far away a shelve is refused"},
		{"name": "c11_no_icon", "method": "case_c11", "world": false,
				"title": "C11: the Cabinet shows no icon or text of its Collection"},
		{"name": "c14_built", "method": "case_c14", "world": false,
				"title": "C14: the Cabinet is built from the model's parts (base, 3 segments, top, a drawer each with 25 slots, a handle within 4 cm) and stands against the wall facing out"},
		{"name": "t05_thrown_shelves", "method": "case_t05", "world": false,
				"title": "T05: a thrown Pair touching its own Cabinet shelves itself into the lowest drawer with room, which pops open, pays the thrower, and nothing lies on the floor"},
		{"name": "r06_top_no_shelve", "method": "case_r06", "world": false,
				"title": "R06: a thrown Pair shelves only on touching a drawer front; landing on the Cabinet's top does not shelve it"},
		{"name": "r07_frame_click", "method": "case_r07", "world": false,
				"title": "R07: with Pairs held, a click or the use button on the Cabinet's frame shelves nothing; a drawer's does"},
		{"name": "t06_bounces", "method": "case_t06", "world": false,
				"title": "T06: a thrown Pair touching another Collection's Cabinet, or a locked one, bounces off and lies as a sock ball, with no message"},
		{"name": "t07_loose", "method": "case_t07", "world": false,
				"title": "T07: a loose Sock thrown at the Cabinet bounces off and lies loose, never shelved"},
		{"name": "d02_door", "method": "case_d02", "world": false,
				"title": "D02: a click opens a shut Door in 0.6 s and shuts an open one; a click asking the state it is in does nothing; a Door never moves by itself"},
		{"name": "d05_door_blocks", "method": "case_d05", "world": false,
				"title": "D05: a shut Door stops the player and the crosshair like a wall; open, the doorway is clear"},
		{"name": "d08_click_opens", "method": "case_d08", "world": false,
				"title": "D08: a left click on a drawer or a Door opens or shuts it, and so does the use button"},
		{"name": "i5_invariant", "method": "case_i5", "world": false,
				"title": "I.5: only a Pair of the Cabinet's Collection is ever shelved, never a loose Sock, never into a locked Cabinet or past a Row's capacity"},
		{"name": "c12_snapshot", "method": "case_c12", "world": false,
				"title": "C12: shelved Pairs stay in the same drawer and slot through a snapshot and load"},
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
	_stand(BY_SOCKS)
	await _aim(_player, _centre(S0))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == S0, "the first Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(S0_MATE))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(S0), "the mate to fuse into a Pair")
	_stand(BY_DRAWERS)
	await _aim(_player, _drawer_front(0))
	await _press(&"pick")
	await _until(func() -> bool: return _cabinet.contents(0) == PackedInt32Array([S0]), "the Pair to be shelved in the bottom drawer")
	_check(_hands.items_of(1).is_empty(), "the Hands are empty")
	_check(_mess.state_of(S0) == Mess.State.SHELVED, "the Pair's record is shelved")
	_check(_ball_in(0, 1) == S0, "the Pair's sock ball shows in the drawer's first slot")
	_check(_coins.of_player(1) == 10, "10 Coins are the player's (%d)" % _coins.of_player(1))
	_check(_cabinet.drawer(0).open, "the drawer slid open")
	_check(_mess.looks_of(S0) == null and _mess.flight_of(S0) == null, "nothing of it lies or flies")
	# A second Pair, thrown with a full charge from a step back.
	_stand(BY_SOCKS)
	await _aim(_player, _centre(S1))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == S1, "the second Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(S1_MATE))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(S1), "the second Pair to fuse")
	_stand(THROW_FROM)
	await _aim(_player, _drawer_front(1))  # core/23: a Throw lands where the crosshair is
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(S1) != Mess.State.HELD, "the Pair to leave the Hands")
	await _until(func() -> bool: return _mess.state_of(S1) != Mess.State.FLYING, "the thrown Pair to land or shelve")
	_check(_mess.state_of(S1) == Mess.State.SHELVED, "the thrown Pair shelved itself (state %d)" % _mess.state_of(S1))
	_check(_cabinet.contents(0) == PackedInt32Array([S0, S1]), "into the lowest drawer with room (%s)" % [_cabinet.contents(0)])
	_check(_coins.of_player(1) == 20, "the thrower is paid again (%d)" % _coins.of_player(1))
	await _frames(2)
	_check(_ball_in(0, 2) == S1, "its ball shows in the second slot")


# --- Shelving by click ---------------------------------------------------------------------------

func case_c01() -> void:
	await _build()
	_capacity(4)
	await _pair(S0, S0_MATE)
	await _pair(PATTERNS, PATTERNS_MATE)
	await _pair(S1, S1_MATE)
	await _take(LOOSE)
	_check(_hands.items_of(1) == PackedInt32Array([S0, PATTERNS, S1, LOOSE]), "three Pairs and a loose Sock held (%s)" % _hands.items_of(1))
	await _click_drawer(1)
	await _until(func() -> bool: return not _cabinet.contents(1).is_empty(), "the Pairs to be shelved")
	_check(_cabinet.contents(1) == PackedInt32Array([S0, S1]), "both Simple Pairs went into the clicked drawer, in the order held (%s)" % [_cabinet.contents(1)])
	_check(_cabinet.contents(0).is_empty(), "nothing went into another drawer")
	_check(_hands.items_of(1) == PackedInt32Array([PATTERNS, LOOSE]), "the Patterns Pair and the loose Sock stay in the Hands (%s)" % _hands.items_of(1))
	_check(_cabinet.drawer(1).open and not _cabinet.drawer(0).open, "only the drawer used slides open")
	_check(_player.message() == "", "no refusal shows")
	await _frames(2)
	_check(_ball_in(1, 1) == S0 and _ball_in(1, 2) == S1 and _ball_in(1, 3) == -1, "the balls show in the first two slots")


func case_c02() -> void:
	await _build()
	await _pair(PATTERNS, PATTERNS_MATE)
	await _click_drawer(0)
	await _until(func() -> bool: return _player.message() != "", "a refusal to show")
	_check(_player.message() == "Wrong Cabinet", "it says \"Wrong Cabinet\" (%s)" % _player.message())
	_check(_hands.items_of(1) == PackedInt32Array([PATTERNS]), "the Pair stays in the Hands")
	_check(_cabinet.shelved().is_empty() and not _cabinet.drawer(0).open, "nothing is shelved and the drawer stays shut")
	_check(_coins.of_player(1) == 0, "nothing is paid")


func case_c03() -> void:
	await _build()
	_capacity(4)
	_tune_capacity(1)
	_parts.load_snapshot({_cabinet.id: {"rows": 3}})
	await _pair(S0, S0_MATE)
	await _pair(S1, S1_MATE)
	await _pair(S4, S4_MATE)
	await _click_drawer(1)
	await _until(func() -> bool: return _cabinet.shelved().size() == 3, "the three Pairs to be shelved")
	_check(_cabinet.contents(1) == PackedInt32Array([S0]), "the first fills the clicked drawer (%s)" % [_cabinet.contents(1)])
	_check(_cabinet.contents(0) == PackedInt32Array([S1]), "the next goes to the lower of the two nearest (%s)" % [_cabinet.contents(0)])
	_check(_cabinet.contents(2) == PackedInt32Array([S4]), "the last to the one above (%s)" % [_cabinet.contents(2)])
	for i in 3:
		_check(_cabinet.drawer(i).open, "drawer %d used slides open" % (i + 1))
		_check(_cabinet.contents(i).size() <= 1, "drawer %d holds no more than its capacity" % (i + 1))


func case_c04() -> void:
	await _build()
	var drawer := _cabinet.drawer(0)
	await _click_drawer(0)
	await _until(func() -> bool: return drawer.open, "the drawer to open")
	await _physics_ticks(25)
	await _click_drawer(0)
	await _until(func() -> bool: return not drawer.open, "the drawer to shut")
	var again := _parts.answer(Command.new(&"open", 1, drawer.id, {"open": false}))
	_check(not again["ok"] and again["reason"] == "already", "a click asking for shut on a shut drawer is refused \"already\"")
	await _take(LOOSE)
	await _physics_ticks(25)
	await _click_drawer(0)
	await _until(func() -> bool: return drawer.open, "with a loose Sock held the click opens the drawer")
	_check(_hands.items_of(1) == PackedInt32Array([LOOSE]), "the loose Sock stays held")
	_check(_cabinet.shelved().is_empty(), "nothing is shelved")


func case_c05() -> void:
	await _build()
	_capacity(4)
	_tune_capacity(1)
	_parts.load_snapshot({_cabinet.id: {"rows": 3}})
	await _pair(S0, S0_MATE)
	await _pair(UNCOMMON, UNCOMMON_MATE)
	await _pair(RARE, RARE_MATE)
	var payments: Array = []
	_parts.applied.connect(func(ev: Dictionary) -> void:
		if ev.get("ok", false) and ev.get("kind", &"") == &"shelve":
			payments.append_array(ev["paid"]))
	await _click_drawer(0)
	await _until(func() -> bool: return _cabinet.shelved().size() == 3, "the three Pairs to be shelved")
	_check(_coins.of_player(1) == 10 + 20 + 50, "common 10, uncommon 20, rare 50: 80 Coins (%d)" % _coins.of_player(1))
	_check(payments.size() == 3, "one payment per drawer used (%s)" % [payments])
	var total := 0
	for p: Dictionary in payments:
		total += int(p["coins"])
	_check(total == _coins.of_player(1), "the payments add up to the Coins, nothing doubled")
	_check(_coins.coins.keys() == [1], "only the shelver is paid (%s)" % _coins.coins)
	await _physics_ticks(25)
	await _click_drawer(0)
	await _physics_ticks(4)
	_check(_coins.of_player(1) == 80, "a click with nothing to shelve pays nothing")


func case_c08_order() -> void:
	await _build()
	_parts.load_snapshot({_cabinet.id: {"locked": true}})
	await _pair(PATTERNS, PATTERNS_MATE)
	await _click_drawer(0)
	await _until(func() -> bool: return _player.message() != "", "a refusal to show")
	_check(_player.message() == "Wrong Cabinet", "it says \"Wrong Cabinet\", not \"Cabinet locked\" (%s)" % _player.message())


func case_c08() -> void:
	await _build()
	_parts.load_snapshot({_cabinet.id: {"locked": true}})
	await _click_drawer(0)
	await _until(func() -> bool: return _player.message() != "", "a refusal to show")
	_check(_player.message() == "Cabinet locked" and not _cabinet.drawer(0).open, "with empty Hands it says \"Cabinet locked\" and the drawer stays shut")
	await _pair(S0, S0_MATE)
	await _click_drawer(0)
	await _physics_ticks(4)
	_check(_player.message() == "Cabinet locked", "with a Pair it says \"Cabinet locked\" (%s)" % _player.message())
	_check(_hands.items_of(1) == PackedInt32Array([S0]) and _cabinet.shelved().is_empty(), "the Pair stays")
	# Full Rows.
	_parts.load_snapshot({_cabinet.id: {"locked": false}})
	_tune_capacity(1)
	_capacity(4)
	await _pair(S1, S1_MATE)
	await _pair(S4, S4_MATE)
	await _click_drawer(0)
	await _until(func() -> bool: return _cabinet.shelved().size() == 2, "two Pairs to fill the two Rows")
	_check(_hands.items_of(1) == PackedInt32Array([S4]), "what did not fit stays in the Hands (%s)" % _hands.items_of(1))
	await _physics_ticks(25)
	await _click_drawer(1)
	await _until(func() -> bool: return _player.message() == "Cabinet full", "\"Cabinet full\" to show")
	_check(_hands.items_of(1) == PackedInt32Array([S4]), "the Pair stays")
	# Far away.
	_parts.where = func(_by: int) -> Vector3: return _station.to_global(Vector3(0.0, 0.0, 20.0))
	var far := _parts.answer(Command.new(&"shelve", 1, _cabinet.id, {"drawer": 0}))
	_check(not far["ok"] and far["reason"] == "far", "a shelve from far away is refused \"far\"")


func case_c11() -> void:
	await _build()
	var cabinet := _cabinet.get_parent()
	var signs := cabinet.find_children("*", "Label3D", true, false) + cabinet.find_children("*", "Sprite3D", true, false) \
			+ cabinet.find_children("*", "Decal", true, false)
	_check(signs.is_empty(), "no label, sprite or decal on the Cabinet (%s)" % [signs])


func case_c14() -> void:
	await _build()
	var cabinet := _cabinet.get_parent() as Node3D
	var looks := cabinet.get_node("Looks")
	for n: String in ["Base", "Segment1", "Segment2", "Segment3", "Top"]:
		_check(looks.get_node_or_null(NodePath(n)) is MeshInstance3D, "the Looks has its %s" % n)
	_check(_cabinet.drawer_count() == 3, "one drawer per segment (%d)" % _cabinet.drawer_count())
	for i in 3:
		var dlooks := cabinet.get_node("Drawer%d/Looks" % (i + 1))
		var slots := 0
		while dlooks.find_child(Cabinet.SLOT % (slots + 1), true, false) != null:
			slots += 1
		_check(slots == 25, "drawer %d has 25 slots (%d)" % [i + 1, slots])
	var mesh := (cabinet.get_node("Drawer1/Looks/Slide/Mesh") as MeshInstance3D).get_aabb()
	var front := cabinet.get_node("Drawer1/Looks/Slide/Front") as CollisionShape3D
	var face := front.position.z + (front.shape as BoxShape3D).size.z * 0.5
	_check(mesh.end.z - face <= 0.04 + 0.001, "the handle stands out within 4 cm (%.3f m)" % (mesh.end.z - face))
	_check(cabinet.global_basis.z.dot(Vector3(0.0, 0.0, 1.0)) > 0.99, "it faces out, along the station's +Z")
	var behind := PhysicsQueries.ray(_cabinet, cabinet.global_position + Vector3(0.0, 0.5, -0.2), cabinet.global_position + Vector3(0.0, 0.5, -0.5), Mess.LAYER_HOUSE)
	_check(not behind.is_empty() and (behind["collider"] as Node).name == &"BackWall", "its back stands against the wall")


# --- Shelving by Throw ---------------------------------------------------------------------------

func case_t05() -> void:
	await _build()
	_tune_capacity(1)
	_parts.load_snapshot({_cabinet.id: {"shelf": [PackedInt32Array([S4])]}})
	await _pair(S0, S0_MATE)
	await _throw_at_cabinet()
	await _until(func() -> bool: return _mess.state_of(S0) != Mess.State.FLYING, "the thrown Pair to land or shelve")
	_check(_mess.state_of(S0) == Mess.State.SHELVED, "it shelved itself (state %d)" % _mess.state_of(S0))
	_check(_cabinet.contents(1) == PackedInt32Array([S0]), "into the lowest drawer with room (%s)" % [_cabinet.contents(1)])
	_check(_cabinet.drawer(1).open, "that drawer pops open")
	_check(_coins.of_player(1) == 10, "the thrower is paid as for a click (%d)" % _coins.of_player(1))
	await _physics_ticks(2)
	_check(_mess.looks_of(S0) == null and _mess.flight_of(S0) == null, "nothing of it lies on the floor or flies")


func case_t06() -> void:
	await _build()
	await _pair(PATTERNS, PATTERNS_MATE)
	await _throw_at_cabinet()
	await _until(func() -> bool: return _mess.state_of(PATTERNS) == Mess.State.LYING, "the Patterns Pair to come to rest")
	_check(_mess.is_pair(PATTERNS) and _mess.looks_of(PATTERNS) != null, "it lies as a sock ball")
	_check(_cabinet.shelved().is_empty(), "nothing is shelved")
	_check(_player.message() == "", "no message shows")
	_parts.load_snapshot({_cabinet.id: {"locked": true}})
	await _pair(S0, S0_MATE)
	await _throw_at_cabinet()
	await _until(func() -> bool: return _mess.state_of(S0) == Mess.State.LYING, "the Simple Pair to bounce off the locked Cabinet")
	_check(_cabinet.shelved().is_empty() and _player.message() == "", "a locked Cabinet takes nothing and says nothing")


func case_t07() -> void:
	await _build()
	await _take(S0)
	await _throw_at_cabinet()
	await _until(func() -> bool: return _mess.state_of(S0) == Mess.State.LYING, "the loose Sock to come to rest")
	_check(not _mess.is_pair(S0) and _mess.looks_of(S0) != null, "it lies loose")
	_check(_cabinet.shelved().is_empty(), "nothing is shelved")


func case_r06() -> void:
	await _build()
	await _pair(S0, S0_MATE)
	var top := (_cabinet.get_parent() as Node3D).to_global(Vector3(0.0, 1.05, 0.0))
	_player.global_position = top + Vector3(0.0, 0.8, 0.0)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.rotation = Vector3.ZERO
	(_player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-85.0)
	await _physics_ticks(1)
	_hands.throw(1, _player.aim_dir(), 0.0)
	await _until(func() -> bool: return _mess.state_of(S0) == Mess.State.FLYING and _mess.flight_of(S0) != null, "the Pair to fly")
	await _until(func() -> bool: return _mess.state_of(S0) != Mess.State.FLYING, "the thrown Pair to land or shelve", 600)
	_check(_mess.state_of(S0) != Mess.State.SHELVED and _cabinet.shelved().is_empty(), "landing on the top shelves nothing (state %d)" % _mess.state_of(S0))


func case_r07() -> void:
	await _build()
	await _pair(S0, S0_MATE)
	_stand(BY_DRAWERS)
	var frame := (_cabinet.get_parent() as Node3D).to_global(Vector3(0.3, 1.05, 0.0))
	await _aim(_player, frame)
	await _press(&"pick")
	await _press(&"interact")
	await _physics_ticks(5)
	_check(_cabinet.shelved().is_empty() and _hands.items_of(1) == PackedInt32Array([S0]), "a click and the use button on the frame shelve nothing")
	await _aim(_player, _drawer_front(0))
	await _press(&"interact")
	await _until(func() -> bool: return _cabinet.contents(0) == PackedInt32Array([S0]), "the use button on a drawer front to shelve")


# --- Doors and openables -------------------------------------------------------------------------

func case_d02() -> void:
	await _build()
	var door := _door()
	var swing := door.animator().get_animation(Openable.ANIMATION).length
	_near(swing, 0.6, 0.001, "the Door swings in 0.6 s")
	await _click_door()
	await _until(func() -> bool: return door.open, "the shut Door to open")
	await _until(func() -> bool: return not door.animator().is_playing(), "the swing to end", 120)
	await _physics_ticks(25)
	await _click_door()
	await _until(func() -> bool: return not door.open, "the open Door to shut")
	var again := _parts.answer(Command.new(&"open", 1, door.id, {"open": false}))
	_check(not again["ok"] and again["reason"] == "already", "asking a shut Door to shut does nothing")
	await _until(func() -> bool: return not door.animator().is_playing(), "the swing to end", 120)
	await _physics_ticks(5)
	var hinge := door.get_node("../Looks/Hinge") as Node3D
	var at := hinge.rotation
	await _physics_ticks(60)
	_check(not door.open and hinge.rotation.is_equal_approx(at), "a Door never moves by itself (%s, %s)" % [at, hinge.rotation])


func case_d05() -> void:
	await _build()
	var door := _door()
	_stand(Vector3(1.55, 0.0, 0.4))
	_face(Vector3(0.0, 0.0, -1.0), 0.0)
	await _physics_ticks(2)
	var aimed := _player.get_node("Head/Aim") as RayCast3D
	(_player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-10.0)
	await _physics_ticks(2)
	aimed.force_raycast_update()
	_check(Parts.part_of(aimed.get_collider() as Node) == door, "the crosshair rests on the shut Door")
	(_player.get_node("Head") as Node3D).rotation.x = 0.0
	Input.action_press(&"move_forward")
	await _physics_ticks(90)
	Input.action_release(&"move_forward")
	var stopped := _station.to_local(_player.global_position).z
	_check(stopped > -0.8, "the shut Door stops the player (z %.2f)" % stopped)
	_parts.ask(Command.new(&"open", 1, door.id, {"open": true}))
	await _until(func() -> bool: return not door.animator().is_playing(), "the swing to end", 120)
	Input.action_press(&"move_forward")
	await _physics_ticks(90)
	Input.action_release(&"move_forward")
	var through := _station.to_local(_player.global_position).z
	_check(through < -1.2, "open, the player walks through the doorway (z %.2f)" % through)


func case_d08() -> void:
	await _build()
	var drawer := _cabinet.drawer(1)
	await _click_drawer(1)
	await _until(func() -> bool: return drawer.open, "a left click to open the drawer")
	await _physics_ticks(25)
	await _aim(_player, _drawer_front(1))
	await _press(&"interact")
	await _until(func() -> bool: return not drawer.open, "the use button to shut it")
	var door := _door()
	await _click_door()
	await _until(func() -> bool: return door.open, "a left click to open the Door")


# --- Invariants and saves ------------------------------------------------------------------------

func case_i5() -> void:
	await _build()
	_capacity(5)
	_tune_capacity(1)
	await _take(LOOSE)
	await _pair(PATTERNS, PATTERNS_MATE)
	await _pair(S0, S0_MATE)
	await _pair(S1, S1_MATE)
	await _pair(S4, S4_MATE)
	await _click_drawer(0)
	await _until(func() -> bool: return _cabinet.shelved().size() == 2, "the two Rows to fill")
	var direct := _parts.answer(Command.new(&"thrown_shelve", Parts.HOST, _cabinet.id, {"sock": LOOSE, "thrower": 1}))
	_check(not direct["ok"], "the Host's thrown_shelve never takes a loose Sock")
	var guest := _parts.answer(Command.new(&"thrown_shelve", 2, _cabinet.id, {"sock": S4, "thrower": 2}))
	_check(not guest["ok"], "nobody but the Host may ask thrown_shelve")
	_parts.load_snapshot({_cabinet.id: {"locked": true, "rows": 3}})
	await _physics_ticks(25)
	await _click_drawer(2)
	await _physics_ticks(4)
	_check(_cabinet.contents(2).is_empty(), "a locked Cabinet takes nothing")
	for lead in _cabinet.shelved():
		_check(_mess.is_pair(lead) and _cabinet.takes(lead) and _mess.state_of(lead) == Mess.State.SHELVED,
				"shelved %d is a Simple Pair, shelved in the Mess" % lead)
	for i in _cabinet.drawer_count():
		_check(_cabinet.contents(i).size() <= 1, "drawer %d holds no more than its capacity" % (i + 1))
	var shelved_records := 0
	for sock in _mess.count():
		if _mess.state_of(sock) == Mess.State.SHELVED:
			shelved_records += 1
			_check(_cabinet.shelved().has(sock), "every SHELVED record is on the shelf (%d)" % sock)
	_check(shelved_records == _cabinet.shelved().size(), "the Mess and the shelf agree")


func case_c12() -> void:
	await _build()
	_capacity(4)
	await _pair(S0, S0_MATE)
	await _pair(RARE, RARE_MATE)
	await _click_drawer(1)
	await _until(func() -> bool: return _cabinet.shelved().size() == 2, "two Pairs shelved")
	var snap := _roundtrip(_parts.snapshot())
	var coins_before := _coins.of_player(1)
	_level.free()
	_level = null
	await _build()
	_parts.load_snapshot(snap)
	await _frames(2)
	_check(_cabinet.contents(1) == PackedInt32Array([S0, RARE]), "the same drawer holds the same Pairs (%s)" % [_cabinet.contents(1)])
	_check(_ball_in(1, 1) == S0 and _ball_in(1, 2) == RARE, "in the same slots")
	_check(_mess.state_of(S0) == Mess.State.SHELVED and _mess.state_of(S0_MATE) == Mess.State.IN_PAIR, "the records are shelved again")
	_check(_mess.looks_of(S0) == null and _mess.looks_of(RARE) == null, "nothing of them lies on the floor")
	_check(_cabinet.drawer(1).open, "the drawer is open as it was")
	_check(_coins.of_player(1) == coins_before, "the Coins are kept (%d)" % _coins.of_player(1))


# --- Helpers -------------------------------------------------------------------------------------

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
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = _station.position + BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()   # the mouse is the player's: buttons act (R01)
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_coins = _station.get_node("Socks/Coins") as Coins
	_cabinet = _station.get_node("Cabinet/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


## Puts the player at `spot` in station space.
func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _face(dir: Vector3, pitch: float) -> void:
	_player.rotation.y = atan2(-dir.x, -dir.z)
	(_player.get_node("Head") as Node3D).rotation.x = deg_to_rad(pitch)


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Presses an action for two physics ticks, then lets it go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## Takes Sock `sock` into the Hands by the Hands' own Command, past the grab interval.
func _take(sock: int) -> void:
	_hands.clock += 10.0
	_hands.pick(1, sock)
	await _physics_ticks(1)
	_check(_hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d is taken" % sock)


## Takes a Sock and its mate: one Pair in the Hands.
func _pair(sock: int, mate: int) -> void:
	await _take(sock)
	await _take(mate)
	_check(_mess.is_pair(sock), "Socks %d and %d fused into a Pair" % [sock, mate])


## Stands before the drawers, aims at drawer `index`'s front and left-clicks.
func _click_drawer(index: int) -> void:
	_stand(BY_DRAWERS)
	await _aim(_player, _drawer_front(index))
	await _press(&"pick")


## Stands before the Door and left-clicks it.
func _click_door() -> void:
	_stand(Vector3(1.55, 0.0, 0.6))
	var hinge := _station.get_node("Door/Looks/Hinge") as Node3D
	await _aim(_player, hinge.global_transform * Vector3(0.45, 1.2, 0.0))
	await _press(&"pick")


## Throws the active item at the Cabinet's front with a full charge, by the Hands' Command.
func _throw_at_cabinet() -> void:
	_stand(THROW_FROM)
	await _aim(_player, _drawer_front(1))  # core/23: a Throw lands where the crosshair is
	_hands.throw(1, _player.aim_dir(), 1.0)
	await _physics_ticks(1)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


func _tune_capacity(n: int) -> void:
	_cabinet.tuning = _cabinet.tuning.duplicate() as CabinetTuning
	_cabinet.tuning.drawer_capacity = n


func _door() -> Openable:
	return _station.get_node("Door/Openable") as Openable


## The middle of drawer `index`'s front, in the level (the drawer shut).
func _drawer_front(index: int) -> Vector3:
	var front := _cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


## The Sock whose ball shows in slot `slot` (1 is the first) of drawer `index`, or -1.
func _ball_in(index: int, slot: int) -> int:
	var looks := _cabinet.get_parent().get_node("Drawer%d/Looks" % (index + 1))
	var point := looks.find_child(Cabinet.SLOT % slot, true, false)
	var ball := point.get_node_or_null(NodePath(Cabinet.BALL)) if point != null else null
	if ball == null or ball.is_queued_for_deletion():
		return -1
	return int(ball.get_meta(Mess.SOCK_META, -1))


## The middle of a lying Sock, or of a lying Pair's ball.
func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
