## The room Doors (house/08, Q2568-Q2571, docs/migration/m06-lists/06-room-doors.md): eight Doors in the
## old house's doorways (none in the ground floor's two open ones), each an Openable Part on the Door
## entity (one of two hands) with the old leaf as its Looks; about a third start shut from the level's seed,
## the laundry-to-garage pair always open; a click opens one, with its sound, and its swing pushes the Socks in
## its way on every machine; a late joiner gets it as it stands. The real path runs in the zoo's Doors station
## (game/zoo/stations/doors.tscn), one Door and two lying Socks, as the player's own buttons.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const HOUSE := "res://game/house/house.tscn"
const STATION := "Stations/Doors"
const PLAIN := STATION + "/Plain/Openable"
const FLIPPED := STATION + "/Flipped/Openable"
const FPS := 60
const NET_WAIT_S := 20.0
## The doorways of the old Doors (test of house_test DOORWAYS): name, storey floor, axis of the wall line, line,
## centre along it, the side the room is on (-1 or 1 along the line's normal), the hinge end (-1 low, 1 high).
const DOORS: Array[Array] = [
	["WorkshopLobby", -3.0, "x", 4.0, 2.75, -1, 1], ["LaundryLobby", -3.0, "x", 4.0, 4.1, -1, -1],
	["BoilerLobby", -3.0, "z", 2.0, 5.25, -1, -1], ["LobbyGarage", -3.0, "x", 6.5, 4.75, -1, 1],
	["OfficeLanding", 3.0, "x", 4.0, 2.75, -1, 1], ["BedroomLanding", 3.0, "x", 4.0, 4.1, -1, -1],
	["BathroomLanding", 3.0, "x", 6.5, 2.75, 1, 1], ["KidsLanding", 3.0, "x", 6.5, 4.75, 1, 1],
]
## The wall's thickness and the leaf's: the leaf lies flush with its room's face (make_house.py PART, LEAF_T).
const WALL := 0.12
const LEAF := 0.04
const OPENING := 0.9
const GAP := 0.017
## The old Doors that always start open (the old TREE_PATH).
const KEPT: Array[String] = ["LaundryLobby", "LobbyGarage"]

var _zoo: Node3D = null
var _house: Node3D = null
var _branches: Array[Node] = []
## The game clock runs this many times faster than the wall clock, one frame per physics tick (runner.gd puts it back after each case).
const PACE_SPEED := 2.0
var _pace_next := 0
## The sounds heard since the case started: {"event", "at", "bus"}.
var _heard: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "d01_placed", "method": "case_d01_placed", "world": false,
				"title": "D01: the house has the old eight Doors, none on the ground floor, each in its doorway with the leaf of the old size, hinged at the old jamb, flush with its room's face, and open it stands against the wall in its room"},
		{"name": "d02_shut_share", "method": "case_d02_shut_share", "world": false,
				"title": "D02: a third of the Doors (3 of 8) start shut from the seed, never the laundry-garage pair, the same each start, and the picks differ with the seed; the house starts with exactly those shut"},
		{"name": "d03_real_path", "method": "case_d03_real_path", "world": false,
				"title": "D03 real path: in the Doors station the player aims at a shut Door (the prompt reads \"Open the Door\"), presses the use button, it swings 0.6 s with its sound, pushes the Sock in its way out of the leaf, muffles what is behind it only while shut, and shuts again with its sound"},
		{"name": "d04_both_hands", "method": "case_d04_both_hands", "world": false,
				"title": "D04: the other hand swings the same way: its leaf ends standing against the wall in the room, the hinge at the other jamb"},
		{"name": "d05_late_joiner", "method": "case_d05_late_joiner", "world": false,
				"title": "D05: a snapshot of a zoo with an open Door loaded into a fresh zoo gives the open Door at once, no swing, no sound"},
		{"name": "d06_coop", "method": "case_d06_coop", "world": false,
				"title": "D06 real path, co-op: the Host's player opens the Door; the Guest shows it swing and the Socks in its way moving, both end equal; a Guest joining afterwards gets the Door open at once"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Engine.time_scale = PACE_SPEED
	Input.action_release(Player.INTERACT)
	_heard.clear()
	_drop_branches()
	for node: Node in [_zoo, _house]:
		if node != null and is_instance_valid(node):
			node.free()
	_zoo = null
	_house = null


# --- Placement -----------------------------------------------------------------------------------

func case_d01_placed() -> void:
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var doors := house.get_node("Doors")
	var names: Array[String] = []
	for child in doors.get_children():
		if child.get_node_or_null("Openable") is Openable:
			names.append(String(child.name))
	_same(names.size(), 8, "eight room Doors stand under Doors (%s)" % [names])
	for d: Array in DOORS:
		var door := doors.get_node_or_null(String(d[0])) as Node3D
		_check(door != null, "%s has its Door" % d[0])
		if door == null:
			continue
		_check((door.get_node("Openable") as Openable).open, "%s is placed open (the level shuts its share)" % d[0])
		var along_x: bool = d[2] == "x"
		var line: float = d[3]
		var centre: float = d[4]
		var room: int = d[5]
		var end: int = d[6]
		var origin := door.position
		# Along the wall: the leaf is centred in the doorway; across: flush with the room's face.
		var s := origin.z if along_x else origin.x
		var n := origin.x if along_x else origin.z
		_near(s, centre, 0.001, "%s: the leaf's middle is the doorway's middle" % d[0])
		_near(n, line + room * (WALL / 2.0 - LEAF / 2.0), 0.001, "%s: the leaf lies flush with its room's face" % d[0])
		_near(origin.y, float(d[1]), 0.001, "%s: stands on its storey's floor" % d[0])
		var hinge := door.get_node("Looks/Hinge") as AnimatableBody3D
		var shape := hinge.get_node("LeafShape") as CollisionShape3D
		var size := (shape.shape as BoxShape3D).size
		_near(size.x, OPENING - 2.0 * GAP, 0.001, "%s: the leaf is the old width, 0.017 m short of each jamb" % d[0])
		_near(size.y, 2.075, 0.001, "%s: the leaf is the old height" % d[0])
		_near(size.z, LEAF, 0.001, "%s: and thickness" % d[0])
		# The hinge point in the house's frame, and where the leaf's far end goes open.
		var hinge_at := door.transform * hinge.position
		var hs := hinge_at.z if along_x else hinge_at.x
		var want := centre + end * (OPENING / 2.0 - GAP)
		_near(hs, want, 0.001, "%s: the hinge is at the old jamb (%s)" % [d[0], "high" if end > 0 else "low"])
		var anim := door.get_node("Looks/AnimationPlayer") as AnimationPlayer
		var turn := _open_turn(anim)
		var far := door.transform * (hinge.position + Basis(Vector3.UP, turn) * (shape.position * 2.0))
		var fn := far.x if along_x else far.z
		var side := signf(fn - line)
		_check(side == float(room), "%s: opened, the leaf's far end stands in the room (%.2f from the wall's line)" % [d[0], fn - line])
		_check(absf(absf(fn - line) - (OPENING - 2.0 * GAP) - LEAF / 2.0) < 0.1, "%s: and stands a leaf's width out from the wall" % d[0])
		# Its swing keeps in its room: nothing of the leaf is past the wall's line at any key of the turn.
		for t: float in [0.25, 0.5, 0.75, 1.0]:
			var at := door.transform * (hinge.position + Basis(Vector3.UP, turn * t) * (shape.position * 2.0))
			var an := at.x if along_x else at.z
			_check(signf(an - line) == float(room) or absf(an - line) < WALL, "%s: at %.2f of its swing the leaf's end is on the room's side" % [d[0], t])
	for child in doors.get_children():
		if child.get_node_or_null("Openable") is Openable:
			_check(absf((child as Node3D).position.y) > 2.5, "%s is not on the ground floor (y %s)" % [child.name, (child as Node3D).position.y])
	house.free()


## The turn (radians about up) the open animation ends at.
func _open_turn(anim: AnimationPlayer) -> float:
	var open := anim.get_animation(&"open")
	return (open.track_get_key_value(0, open.track_get_key_count(0) - 1) as Vector3).y


# --- The shut share ------------------------------------------------------------------------------

func case_d02_shut_share() -> void:
	var rules := load("res://game/house/door_shut_rules.tres") as DoorShutRules
	var names: Array = []
	for d: Array in DOORS:
		names.append(d[0])
	var shut := DoorShuts.pick(names, rules.seed, rules)
	_same(shut.size(), 3, "3 of the 8 Doors start shut (a third, rounded): %s" % [shut])
	for kept in KEPT:
		_check(not shut.has(kept), "%s always starts open" % kept)
	_same(DoorShuts.pick(names, rules.seed, rules), shut, "the same seed shuts the same Doors")
	var others := {}
	for seed_value in range(1, 40):
		others[",".join(DoorShuts.pick(names, seed_value, rules))] = true
	_check(others.size() > 5, "other seeds shut other Doors (%d different picks in 39 seeds)" % others.size())
	var all := rules.duplicate() as DoorShutRules
	all.share = 1.0
	_same(DoorShuts.pick(names, 5, all).size(), 6, "every Door but the two kept can be shut")
	var none := rules.duplicate() as DoorShutRules
	none.share = 0.0
	_same(DoorShuts.pick(names, 5, none).size(), 0, "a share of 0 shuts none (the tests' setting)")
	# The house starts so.
	_house = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_house)
	await _frames(2)
	var node := _house.get_node("Doors/DoorShuts") as DoorShuts
	_same(node.shut, shut, "the house shuts the picked Doors at its start")
	for d: Array in DOORS:
		var openable := _house.get_node("Doors/%s/Openable" % d[0]) as Openable
		_same(openable.open, not shut.has(d[0]), "%s starts %s" % [d[0], "shut" if shut.has(d[0]) else "open"])
		_check(not openable.is_moving(), "%s stands at its pose with no swing" % d[0])
	_check(_heard.is_empty(), "nothing was heard")


# --- The real path -------------------------------------------------------------------------------

func case_d03_real_path() -> void:
	await _zoo_up()
	Sounds.played.connect(_on_played)
	var openable := _zoo.get_node(PLAIN) as Openable
	var mess := LevelRuntime.of(_zoo).mess
	var socks := _arc_socks(mess)
	_same(socks.size(), 2, "two Socks lie in the Door's way")
	var before: Array[Vector3] = []
	for s in socks:
		before.append(mess.pose_of(s).origin)
	# The player stands in the room, aims at the leaf and presses use.
	var leaf := _leaf_point(openable)
	await _aim(Vector3(-1.7, 0.0, 0.0), leaf)
	var player := LevelRuntime.of(_zoo).player
	var hud := player.hud()
	await _until(func() -> bool: return hud.prompt_text() == "[E] Open the Door", "the prompt reads Open the Door (%s)" % hud.prompt_text())
	_check(player.aimed_outline != null, "the leaf is outlined")
	# Behind the shut Door a sound is muffled, in the room it is not.
	var behind := _station_point(Vector3(1.0, 1.0, -1.0))
	var in_room := _station_point(Vector3(-1.0, 1.0, -1.0))
	_check(Sounds.is_muffled(behind), "a sound behind the shut Door is muffled")
	_check(not Sounds.is_muffled(in_room), "a sound in the player's room is not")
	Input.action_press(Player.INTERACT)
	await _physics_ticks(2)
	Input.action_release(Player.INTERACT)
	await _until(func() -> bool: return openable.open, "the Door to open")
	_check(openable.is_moving(), "it swings, not jumps")
	var played := _heard.filter(func(h: Dictionary) -> bool: return h["event"] == &"door_open")
	_same(played.size(), 1, "door_open plays once")
	if not played.is_empty():
		var foot := (openable.get_parent() as Node3D).global_position
		_check(((played[0]["at"] as Vector3) - foot).is_equal_approx(Vector3.UP * 1.0), "from 1 m over where the Door stands (the old game's)")
	await _until(func() -> bool: return not openable.is_moving() and mess.moving_count() == 0, "the swing and the Socks to end")
	var box := _leaf_box(openable)
	for i in socks.size():
		var now := mess.pose_of(socks[i]).origin
		_check(now.distance_to(before[i]) > 0.1, "Sock %d was pushed (%.2f m)" % [i, now.distance_to(before[i])])
		_check(mess.state_of(socks[i]) == Mess.State.LYING, "Sock %d lies again" % i)
		_check(not box.grow(0.02).has_point(now), "Sock %d lies out of the open leaf" % i)
	_check(not Sounds.is_muffled(behind), "open, the Door muffles nothing")
	# Shut it again: the player aims at the open leaf, the close sound.
	await _aim(Vector3(-1.0, 0.0, -2.5), _leaf_box(openable).get_center())
	Input.action_press(Player.INTERACT)
	await _physics_ticks(2)
	Input.action_release(Player.INTERACT)
	await _until(func() -> bool: return not openable.open and not openable.is_moving(), "the Door to shut")
	var closed := _heard.filter(func(h: Dictionary) -> bool: return h["event"] == &"door_close")
	_same(closed.size(), 1, "door_close plays once")
	await _aim(Vector3(-1.7, 0.0, 0.0), _leaf_point(openable))
	_check(Sounds.is_muffled(behind), "shut again, it muffles")
	Sounds.played.disconnect(_on_played)


func case_d04_both_hands() -> void:
	await _zoo_up()
	for path: String in [PLAIN, FLIPPED]:
		var openable := _zoo.get_node(path) as Openable
		await _aim(Vector3(-1.7, 0.0, 0.0), _leaf_point(openable))
		openable.parts.ask(Command.new(&"open", Parts.HOST, openable.id, {"open": true}))
		await _until(func() -> bool: return openable.open and not openable.is_moving(), "%s to open" % path)
		var box := _leaf_box(openable)
		var wall_x: float = (_zoo.get_node(STATION) as Node3D).global_position.x
		_check(box.end.x <= wall_x - 0.015 and box.position.x < wall_x - 0.8, "%s: open, the leaf stands out in the room (x %.2f to %.2f, wall at %.2f)" % [path, box.position.x, box.end.x, wall_x])
		_check(box.size.z < 0.1 and box.size.x > 0.8, "%s: its face along the room's depth, a leaf wide" % path)
		var hinge := openable.get_node("../Looks/Hinge") as Node3D
		var door_z: float = (openable.get_parent() as Node3D).global_position.z
		var near_edge := absf(box.get_center().z - door_z)
		_check(near_edge > 0.3, "%s: standing at a jamb, not in the doorway's middle (%.2f off)" % [path, near_edge])
		_check(hinge != null, "%s has its hinge" % path)
	var plain := _leaf_box(_zoo.get_node(PLAIN) as Openable).get_center().z
	var flipped := _leaf_box(_zoo.get_node(FLIPPED) as Openable).get_center().z
	var plain_door: float = ((_zoo.get_node(PLAIN) as Openable).get_parent() as Node3D).global_position.z
	var flipped_door: float = ((_zoo.get_node(FLIPPED) as Openable).get_parent() as Node3D).global_position.z
	_check(plain < plain_door and flipped > flipped_door, "the hands stand at opposite jambs (%.2f, %.2f)" % [plain - plain_door, flipped - flipped_door])


func case_d05_late_joiner() -> void:
	await _zoo_up()
	var openable := _zoo.get_node(PLAIN) as Openable
	await _aim(Vector3(-1.7, 0.0, 0.0), _leaf_point(openable))
	openable.parts.ask(Command.new(&"open", Parts.HOST, openable.id, {"open": true}))
	await _until(func() -> bool: return openable.open and not openable.is_moving(), "the Door to open")
	var snapshot := _roundtrip(openable.parts.snapshot())
	_zoo.free()
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	await _frames(3)
	Sounds.played.connect(_on_played)
	var fresh := _zoo.get_node(PLAIN) as Openable
	_check(not fresh.open, "a fresh zoo's Door starts shut")
	fresh.parts.load_snapshot(snapshot)
	await _frames(3)
	_check(fresh.open and not fresh.is_moving(), "a joiner's Door stands open at once")
	var anim := fresh.animator()
	_near(anim.current_animation_position, anim.get_animation(&"open").length, 0.01, "at the end pose of the swing")
	_check(_heard.is_empty(), "and no sound plays")
	Sounds.played.disconnect(_on_played)


# --- Co-op ---------------------------------------------------------------------------------------

func case_d06_coop() -> void:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	var hm := LevelRuntime.of(host).mess
	var gm := LevelRuntime.of(guest).mess
	await _until(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") and gm.count() == hm.count(),
			"the guest zoo to be welcomed with the Host's Mess")
	var hd := host.get_node(PLAIN) as Openable
	var gd := guest.get_node(PLAIN) as Openable
	var socks := _arc_socks(hm)
	_same(socks.size(), 2, "two Socks lie in the Door's way")
	await _until(func() -> bool: return gm.pose_of(socks[0]).is_equal_approx(hm.pose_of(socks[0])), "the Guest to lie them there too")
	# The Host's player aims at the Door and presses use.
	_zoo = host
	await _aim(Vector3(-1.7, 0.0, 0.0), _leaf_point(hd))
	_zoo = null
	Input.action_press(Player.INTERACT)
	await _physics_ticks(2)
	Input.action_release(Player.INTERACT)
	var shown: Dictionary[int, bool] = {}
	var swung := false
	var frames := 0
	while frames < FPS * 20 and (frames < 10 or hd.is_moving() or gd.is_moving() or hm.moving_count() > 0 or gm.moving_count() > 0):
		await _paced()
		frames += 1
		swung = swung or gd.is_moving()
		for s in socks:
			if gm.moving_body(s) != null:
				shown[s] = true
	_check(hd.open and gd.open, "the Door is open on both machines")
	_check(swung, "the Guest showed the Door swinging")
	_check(shown.size() == socks.size(), "the Guest showed each Sock in the way moving (%d of %d)" % [shown.size(), socks.size()])
	_same(gm.state(), hm.state(), "the Guest's Socks end where the Host's lie")
	# A late joiner: a third machine joins after the Door opened.
	var late := _branch("Late")
	await _frames(2)
	var ls := LevelRuntime.of(late).session
	ls.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(late).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "a third zoo joins later")
	var lm := LevelRuntime.of(late).mess
	await _until(func() -> bool: return LevelRuntime.of(late).net.mode_text().begins_with("Joined") and lm.count() == hm.count(),
			"the late zoo to be welcomed")
	var ld := late.get_node(PLAIN) as Openable
	_check(ld.open and not ld.is_moving(), "the late joiner's Door stands open")
	_same(lm.state(), hm.state(), "and the Socks lie where the Host's do")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := LevelRuntime.of(_zoo).player
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand in the zoo")


func _on_played(event: StringName, _spatial: bool, at: Vector3, bus: StringName) -> void:
	_heard.append({"event": event, "at": at, "bus": bus})


## The lying Socks near the station's first Door's swing (the station's two Spots), by id.
func _arc_socks(mess: Mess) -> PackedInt32Array:
	var out := PackedInt32Array()
	var door := (_zoo if _zoo != null else _branches_zoo(mess)).get_node(STATION + "/Plain") as Node3D
	for s in mess.count():
		if mess.state_of(s) == Mess.State.LYING and mess.pose_of(s).origin.distance_to(door.global_position + Vector3(-0.45, 0.0, 0.0)) < 0.7:
			out.append(s)
	return out


## The zoo whose Mess is `mess`, among the branches.
func _branches_zoo(mess: Mess) -> Node3D:
	for node in _branches:
		var zoo := node.get_node_or_null("View/Zoo") as Node3D
		if zoo != null and LevelRuntime.of(zoo).mess == mess:
			return zoo
	return null


func _station_point(local: Vector3) -> Vector3:
	return (_zoo.get_node(STATION) as Node3D).global_transform * local


## A point on the shut leaf at the height of the crosshair's aim.
func _leaf_point(openable: Openable) -> Vector3:
	return openable.get_parent().global_position + Vector3(0.0, 1.2, 0.0)


## The world box of the leaf's collision now.
func _leaf_box(openable: Openable) -> AABB:
	var shape := openable.get_node("../Looks/Hinge/LeafShape") as CollisionShape3D
	return shape.global_transform * shape.shape.get_debug_mesh().get_aabb()


## The player stands at `local` (the station's space) and looks at world point `target`.
func _aim(local: Vector3, target: Vector3) -> void:
	var zoo := _zoo
	var station := zoo.get_node(STATION) as Node3D
	var player := LevelRuntime.of(zoo).player
	player.capture_mouse()
	var at := station.global_transform * local
	player.global_position = Vector3(at.x, station.global_position.y, at.z)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(4)


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += int(1000000 / (FPS * PACE_SPEED))
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


## A whole zoo in a machine of its own: its own MultiplayerAPI and 3D world.
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
