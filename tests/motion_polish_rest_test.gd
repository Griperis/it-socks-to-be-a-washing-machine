## The rest of the core's motion polish (core/27, core/16's lines): a Pair thrown at a drawer front
## flying on to its slot (P11), and the real path (pair, shelve, ball shows). The look-only sway,
## bend, squash, curl and swing cases are gone (Q2429). Every case plays the Cabinet station scene on
## a floor with the game's player and a Parts (a Host of one), through the player's own input.
extends TestSuite

const CABINET_STATION := "res://game/zoo/stations/cabinet.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward", &"move_back", &"jump", &"hands_next"]
## The Cabinet station's Socks, by id (as sound_wiring_test.gd): a Sock and its mate, a loose Sock.
const S0 := 0
const S0_MATE := 1
const S1 := 2
const LOOSE := 12
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
const BY_DRAWERS := Vector3(-1.0, 0.0, -0.4)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _cabinet: Cabinet = null
var _parts: Parts = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Cabinet station the player pairs two Socks and shelves the Pair by a click: it lands once in its slot and its ball shows"},
		{"name": "p11_thrown_shelve", "method": "case_p11", "world": false,
				"title": "P11 (Q2316): a Pair thrown at a drawer front flies on from where it hit to its slot and lands there"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build(CABINET_STATION)
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	var moment := _player.held_view().moment_of(S0) as PairMoment
	_check(moment != null, "the pairing moment plays")
	await _until(func() -> bool: return _player.held_view().moment_of(S0) == null, "the moment to end", 300)
	_stand(BY_DRAWERS)
	await _aim(_player, _drawer_front(0))
	await _press(&"pick")
	var landing := await _flight_landing(S0)
	_check(landing["landings"] == 1, "the shelved Pair landed once in its slot")
	_check(_ball(0, 0).visible, "and its ball shows in the drawer")


# --- P03 -----------------------------------------------------------------------------------------

# --- P08 -----------------------------------------------------------------------------------------

# --- P10 -----------------------------------------------------------------------------------------

# --- P11 -----------------------------------------------------------------------------------------

func case_p11() -> void:
	await _build(CABINET_STATION)
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	await _until(func() -> bool: return _player.held_view().moment_of(S0) == null, "the moment to end")
	_stand(BY_DRAWERS + Vector3(0.0, 0.0, 1.0))
	await _aim(_player, _drawer_front(1))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "the charge")
	await _physics_ticks(5)
	Input.action_release(&"drop_throw")
	var last := Vector3.INF
	var flier: Node3D = null
	for i in 600:
		await get_tree().process_frame
		flier = _cabinet.get_parent().get_node_or_null("Flight%d" % S0) as Node3D
		if flier != null:
			break
		var body := _mess.moving_body(S0)
		if body != null:
			last = body.global_position
	_check(_mess.state_of(S0) == Mess.State.SHELVED, "the thrown Pair was shelved by the drawer front")
	_check(flier != null, "and flies on to its slot")
	if flier == null:
		return
	_check(last != Vector3.INF and flier.global_position.distance_to(last) < 0.25,
			"from where it hit (%.3f m from the body's last place)" % flier.global_position.distance_to(last))
	var landing := await _flight_landing(S0)
	_check(landing["landings"] == 1, "it lands in its slot")
	var index := -1
	for d in _cabinet.drawer_count():
		if _cabinet.contents(d).has(S0):
			index = d
	_check(index >= 0 and _ball(index, 0).visible, "and its ball shows there")


# --- P14 -----------------------------------------------------------------------------------------

# --- P15 -----------------------------------------------------------------------------------------

# --- Helpers -------------------------------------------------------------------------------------

func _build(station: String) -> void:
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
	_station = (load(station) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = _station.position + Vector3(0.0, 0.0, 2.0)
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node_or_null("Socks/Mess") as Mess
	_hands = _station.get_node_or_null("Socks/Hands") as Hands
	_cabinet = _station.get_node_or_null("Cabinet/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and (_mess == null or _mess.looks_of(0) != null), "the player to stand and the Socks to lie")


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


func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d to be picked" % sock)


func _repick(sock: int) -> void:
	await _physics_ticks(25)
	await _pick(sock)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


func _drawer_front(index: int) -> Vector3:
	var front := _cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


## The drawn ball in slot `slot` of drawer `index`.
func _ball(index: int, slot: int) -> Node3D:
	var looks := _cabinet.get_parent().get_node("Drawer%d/Looks" % (index + 1))
	var point := looks.find_child(Cabinet.SLOT % (slot + 1), true, false) as Node3D
	return point.get_node_or_null(NodePath(Cabinet.BALL)) as Node3D


## Follows the shelving flight of Pair `sock` until it is gone, each frame: its landing's numbers,
## how far short of its rest it touched down, how far off its rest it ended, how often it squashed,
## and whether the drawer's own ball showed before it was over.
func _flight_landing(sock: int) -> Dictionary:
	var out := {"landings": 0, "deepest": 0.0, "highest": 0.0, "short": -1.0, "way": 0.0, "squashes": 0,
			"end": INF, "shown_early": false}
	var name := "Flight%d" % sock
	await _until(func() -> bool: return _cabinet.get_parent().has_node(name), "the shelving flight to start")
	var flier := _cabinet.get_parent().get_node_or_null(name) as Node3D
	if flier == null:
		return out
	var landing := flier.get_node("BallLanding") as BallLanding
	var start := flier.global_position
	var ball: Node3D = null
	var was_squashed := false
	while is_instance_valid(flier) and flier.is_inside_tree():
		if ball == null:
			for d in _cabinet.drawer_count():
				var j := _cabinet.contents(d).find(sock)
				if j >= 0:
					ball = _ball(d, j)
		var rest := ball.global_position if ball != null else Vector3.INF
		if ball != null and ball.visible:
			out["shown_early"] = true
		if landing.landings > 0 and out["short"] < 0.0 and ball != null:
			out["short"] = Vector2(flier.global_position.x - rest.x, flier.global_position.z - rest.z).length()
			out["way"] = Vector2(start.x - rest.x, start.z - rest.z).length()
		var squashed := landing.squash > 0.01
		if squashed and not was_squashed:
			out["squashes"] = int(out["squashes"]) + 1
		was_squashed = squashed
		out["landings"] = landing.landings
		out["deepest"] = landing.deepest
		out["highest"] = landing.highest
		if ball != null:
			out["end"] = flier.global_position.distance_to(rest)
		await get_tree().process_frame
	return out
