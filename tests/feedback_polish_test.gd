## The core's small feedback and motions (core/16): the "Paired!" message (P02), a lost Sock's return
## scatter and its pop (P12, P12b) and a sunk one pushed up (P13), one case per line built, and the
## real path. The look-only wobble, squash and cloth cases are gone (Q2429). Every case plays the station scene game/zoo/stations/handling.tscn on a floor, with
## the game's player and a Parts (a Host of one), as the zoo does.
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward", &"hands_next", &"hands_prev"]
## The station's Socks, by id (the order of its SockSpots).
const ON_FLOOR := 0
const UNDER := 1
const ON_TABLE := 3
const BEHIND_WALL := 4
const IN_CUPBOARD := 5
const MATE_FLOOR := 6
const MATE_UNDER := 7
## A small crew Sock's Design (patterns), as hand_details_test.gd uses for the cloth.
const CREW_DESIGN := 135
## Where the player stands for most cases: in front of the Socks on the floor, facing -Z.
const FRONT := Vector3(0.0, 0.0, 1.5)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _heard: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the handling station the player picks a Sock that pairs (\"Paired!\" shows), is refused with full Hands, drops the Pair and loses Socks with the station's button (they come back scattered, with a pop each)"},
		{"name": "p02_paired", "method": "case_p02", "world": false,
				"title": "P02: a pick that completes a Pair shows \"Paired!\" in white for 2 s, popping in (Q2370)"},
		{"name": "r6_landing_idle", "method": "case_r6", "world": false,
				"title": "R6: a ball's BallLanding watches the physics step only while it falls and has not landed, and its Animation is built once per tuning"},
		{"name": "p12_lost", "method": "case_p12", "world": false,
				"title": "P12, P12b: lost Socks come back at the return spot scattered within 0.2 m, a pop in 3D at each"},
		{"name": "p12_flight_lost", "method": "case_p12_flight", "world": false,
				"title": "P12b: a thrown Sock that leaves the playable space comes back scattered, with a pop there"},
		{"name": "p13_sunk", "method": "case_p13", "world": false,
				"title": "P13: a Sock sunk 0.02 m or more into the floor is pushed up onto it where it lay, with no pop"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_heard.clear()
	if not Sounds.played.is_connected(_on_played):
		Sounds.played.connect(_on_played)


func _on_played(event: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append({"event": event, "spatial": spatial, "at": at})


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var hud := _player.hud()
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	await _pick(MATE_FLOOR)
	await _until(func() -> bool: return _mess.is_pair(ON_FLOOR), "the mate to fuse")
	_check(hud.message_text() == Player.PAIRED and hud.message_colour() == Hud.MESSAGE_PLAIN, "\"Paired!\" shows in white (%s)" % hud.message_text())
	# Full Hands: one Pair held, room for one.
	_capacity(1)
	await _physics_ticks(25)
	await _aim(_player, _centre(UNDER))
	await _press(&"pick")
	await _until(func() -> bool: return _player.message() == Player.HANDS_FULL, "the refusal to show")
	_check(hud.message_colour() == Hud.MESSAGE_REFUSAL, "the refusal is red")
	# The Pair dropped on the floor lands with its squash and hop.
	await _aim(_player, Vector3(0.3, 0.0, 0.4))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null and _mess.flight_of(ON_FLOOR).has_node(^"Looks"), "the Pair to fall with its Looks")
	var landing := _mess.flight_of(ON_FLOOR).get_node(^"Looks/BallLanding") as BallLanding
	await _until(func() -> bool: return not is_instance_valid(landing) or landing.landings > 0, "the ball to touch down")
	_check(is_instance_valid(landing) and landing.landings == 1, "the falling ball touched down once")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the Pair to rest")
	# The station's Lose button, used with the real key, from beside it.
	_player.global_position = Vector3(-1.4, 0.0, 1.4)
	await _aim(_player, (_station.get_node("Lose") as Node3D).global_position + Vector3(0.0, 0.3, 0.0))
	_heard.clear()
	await _press(&"interact")
	await _until(func() -> bool: return _pops() == 3, "three pops")
	var spot := (_station.get_node("ReturnSpot") as Marker3D).global_position
	for sock: int in [ON_TABLE, BEHIND_WALL, IN_CUPBOARD]:
		_check(_mess.state_of(sock) == Mess.State.LYING and _mess.pose_of(sock).origin.distance_to(spot) <= 0.2 + 0.001,
				"Sock %d lies scattered round the return spot (%.3f m)" % [sock, _mess.pose_of(sock).origin.distance_to(spot)])
	await _frames(2)
	_check(_mess.is_drawn(ON_TABLE), "and is drawn there")


# --- The message ---------------------------------------------------------------------------------

func case_p02() -> void:
	await _build()
	var hud := _player.hud()
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	_check(hud.message_text() == "", "a plain pick says nothing")
	await _pick(MATE_FLOOR)
	_check(hud.message_text() == Player.PAIRED, "the pick that pairs says \"Paired!\" (%s)" % hud.message_text())
	_check(hud.message_colour() == Hud.MESSAGE_PLAIN, "in white")
	_check(not hud.wobbling(), "it does not wobble")
	var peak := 0.0
	var spent := 0.0
	for i in 30:
		peak = maxf(peak, hud.message_size())
		await _frames(1)
		spent += get_process_delta_time()
	_check(peak >= hud.tuning.pop_peak - 0.05, "it pops past its size (%.2f)" % peak)
	_near(hud.message_size(), 1.0, 0.001, "and settles")
	_near(hud.tuning.pop_from, 0.6, 0.001, "from 0.6 of it")
	await _physics_ticks(maxi(int(Engine.physics_ticks_per_second * (1.7 - spent)), 0))
	_check(hud.message_text() == Player.PAIRED, "still showing near 2 s")
	await _physics_ticks(int(Engine.physics_ticks_per_second * 0.5))
	_check(hud.message_text() == "", "gone after 2 s")


# --- The ball's landing --------------------------------------------------------------------------

# --- Cloth ---------------------------------------------------------------------------------------

# --- Lost and sunk -------------------------------------------------------------------------------

func case_p12() -> void:
	await _build()
	var button := _station.get_node("Lose/LoseButton") as LoseButton
	var spot := (_station.get_node("ReturnSpot") as Marker3D).global_position
	_heard.clear()
	button.use(_player.player_id())
	await _physics_ticks(1)
	var places: Array[Vector3] = []
	for sock: int in [ON_TABLE, BEHIND_WALL, IN_CUPBOARD]:
		var at := _mess.pose_of(sock).origin
		places.append(at)
		_check(_mess.state_of(sock) == Mess.State.LYING and at.distance_to(spot) <= _mess.bodies_tuning().return_scatter + 0.001,
				"Sock %d lies within 0.2 m of the return spot (%.3f)" % [sock, at.distance_to(spot)])
	_check(places[0].distance_to(places[1]) > 0.001 or places[1].distance_to(places[2]) > 0.001, "scattered, not on one point")
	_check(_pops() == 3, "a pop at each (%d)" % _pops())
	for h in _heard:
		if h["event"] == &"lost_pop":
			_check(h["spatial"] and places.any(func(p: Vector3) -> bool: return p.distance_to(h["at"]) < 0.001), "the pop is in 3D where one came back")
	_near(_mess.bodies_tuning().return_scatter, 0.2, 0.0001, "the scatter is the old 0.2 m")


func case_r6() -> void:
	var t := BallLandingTuning.new()
	var make := func(parent: Node) -> BallLanding:
		var looks := Node3D.new()
		var landing := BallLanding.new()
		landing.tuning = t
		landing.name = "BallLanding"
		looks.add_child(landing)
		parent.add_child(looks)
		return landing
	var holder := Node3D.new()
	add_child(holder)
	var free_flier := make.call(holder) as BallLanding
	_check(not free_flier.is_physics_processing(), "with no RigidBody parent it never watches the physics step")
	var body := RigidBody3D.new()
	holder.add_child(body)
	var on_body := make.call(body) as BallLanding
	_check(on_body.is_physics_processing(), "on a falling body it watches")
	on_body.land()
	_check(not on_body.is_physics_processing(), "after its one landing it stops")
	var second := make.call(body) as BallLanding
	_check(second._player.get_animation(BallLanding.LAND) == on_body._player.get_animation(BallLanding.LAND),
			"two balls of one tuning share one landing Animation")
	holder.free()


func case_p12_flight() -> void:
	await _build()
	_mess.bounds = AABB(Vector3(-4.0, -2.0, -4.0), Vector3(8.0, 8.0, 7.0))
	await _pick(ON_FLOOR)
	_player.rotation.y = PI
	(_player.get_node("Head") as Node3D).rotation.x = deg_to_rad(15.0)
	await _physics_ticks(2)
	_heard.clear()
	await _throw_full()
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the lost Sock to come back")
	var spot := (_station.get_node("ReturnSpot") as Marker3D).global_position
	_check(_mess.pose_of(ON_FLOOR).origin.distance_to(spot) <= 0.2 + 0.001, "it lies scattered round the return spot")
	_check(_pops() == 1, "one pop (%d)" % _pops())


func case_p13() -> void:
	await _build()
	var before := _mess.pose_of(MATE_UNDER)
	# The Host's rule itself: sunk 5 cm, pushed up; sunk 1 cm, it lies as it is; deeper than a slab, lost.
	var sunk := _mess.put_down(MATE_UNDER, before.translated(Vector3.DOWN * 0.05))
	_check(not sunk["returned"] and (sunk["pose"] as Transform3D).origin.distance_to(before.origin) < 0.001,
			"sunk 5 cm it is pushed up onto the floor where it lay (%s)" % (sunk["pose"] as Transform3D).origin)
	var shallow := _mess.put_down(MATE_UNDER, before.translated(Vector3.DOWN * 0.005))
	_check(not shallow["returned"] and (shallow["pose"] as Transform3D).origin.distance_to(before.origin + Vector3.DOWN * 0.005) < 0.001,
			"sunk under 0.02 m it lies as it is")
	var deep := _mess.put_down(MATE_UNDER, before.translated(Vector3.DOWN * 0.18))
	_check(not deep["returned"], "a Sock in the floor slab is pushed up, not lost")
	# The station's Sink button, used with the real key, from beside it.
	_player.global_position = Vector3(-1.4, 0.0, 1.0)
	await _aim(_player, (_station.get_node("Sink") as Node3D).global_position + Vector3(0.0, 0.3, 0.0))
	_heard.clear()
	var answered := [false]
	_parts.applied.connect(func(ev: Dictionary) -> void:
		if StringName(ev.get("kind", &"")) == &"sink" and ev.get("ok", false):
			answered[0] = true)
	await _press(&"interact")
	await _until(func() -> bool: return answered[0], "the sink to be answered")
	_check(_mess.state_of(MATE_UNDER) == Mess.State.LYING and _mess.pose_of(MATE_UNDER).origin.distance_to(before.origin) < 0.001,
			"it lies on the floor where it lay")
	_check(_pops() == 0, "with no pop")


# --- Helpers -------------------------------------------------------------------------------------

## A floor, the station, a Parts and the player standing at FRONT facing -Z.
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
	(_station.get_node("Spots/Floor") as SockSpot).design = CREW_DESIGN
	(_station.get_node("Spots/MateFloor") as SockSpot).design = CREW_DESIGN
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = FRONT
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


func _pops() -> int:
	var n := 0
	for h in _heard:
		if h["event"] == &"lost_pop":
			n += 1
	return n


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


## Holds the drop button until the ring is full, then lets it go: the Sock flies.
func _throw_full() -> void:
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _hands.items_of(1).is_empty(), "the Sock to leave the Hands", 5)


## Aims at Sock `sock` and picks it with the real action.
func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d to be picked" % sock)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


## The middle of a lying Sock.
func _centre(sock: int) -> Vector3:
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
