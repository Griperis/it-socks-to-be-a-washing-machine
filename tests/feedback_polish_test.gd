## The core's small feedback and motions (core/16): the refusal's wobble (P01), the "Paired!" pop
## (P02), the ball's landing (P04), the cloth tuned to flap less (P06, P07), a lost Sock's return
## scatter and its pop (P12, P12b) and a sunk one pushed up (P13), one case per line built, and the
## real path. Every case plays the station scene game/zoo/stations/handling.tscn on a floor, with
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
const TOE := 4

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _heard: Array[Dictionary] = []
var _bends: Dictionary[int, float] = {}


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the handling station the player picks a Sock that pairs (\"Paired!\" pops), is refused with full Hands (the red line wobbles), drops the Pair (the ball squashes and hops) and loses Socks with the station's button (they come back scattered, with a pop each)"},
		{"name": "p01_wobble", "method": "case_p01", "world": false,
				"title": "P01: a refusal's red line turns to and fro 0.45 s, 5 swings a second, up to 0.07 rad, dying down, and stays 2 s"},
		{"name": "p02_paired", "method": "case_p02", "world": false,
				"title": "P02: a pick that completes a Pair shows \"Paired!\" in white for 2 s, popping in (Q2370)"},
		{"name": "p04_landing", "method": "case_p04", "world": false,
				"title": "P04: a dropped Pair's ball squashes 0.28 about its bottom as it touches down, hops 4 cm, squashes again, and is round at rest"},
		{"name": "p06_steady_walk", "method": "case_p06", "world": false,
				"title": "P06 (Q2366): a held Sock sways little at a steady walk, tuned stiffer than core/09"},
		{"name": "p07_ground", "method": "case_p07", "world": false,
				"title": "P07 (Q2366): near the ground a flying Sock's whole bend straightens, none at the surface"},
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
	_bends.clear()
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
	var peak := 0.0
	for i in 20:
		peak = maxf(peak, hud.message_size())
		await _frames(1)
	_check(peak > 1.1, "it pops in (%.2f)" % peak)
	_near(hud.message_size(), 1.0, 0.001, "and settles to its own size")
	# Full Hands: one Pair held, room for one.
	_capacity(1)
	await _physics_ticks(25)
	await _aim(_player, _centre(UNDER))
	await _press(&"pick")
	await _until(func() -> bool: return _player.message() == Player.HANDS_FULL, "the refusal to show")
	_check(hud.message_colour() == Hud.MESSAGE_REFUSAL, "the refusal is red")
	var most := 0.0
	for i in 20:
		most = maxf(most, absf(hud.message_turn()))
		await _frames(1)
	_check(most > 0.02, "its line wobbles (%.3f rad)" % most)
	# The Pair dropped on the floor lands with its squash and hop.
	await _aim(_player, Vector3(0.3, 0.0, 0.4))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null and _mess.flight_of(ON_FLOOR).has_node(^"Looks"), "the Pair to fall with its Looks")
	var landing := _mess.flight_of(ON_FLOOR).get_node(^"Looks/BallLanding") as BallLanding
	await _until(func() -> bool: return not is_instance_valid(landing) or landing.landings > 0, "the ball to touch down")
	_check(is_instance_valid(landing) and landing.landings == 1, "the falling ball touched down once")
	await _until(func() -> bool: return not is_instance_valid(landing) or not landing.playing(), "the landing to end")
	_check(is_instance_valid(landing) and landing.deepest > 0.2, "it squashed (%.3f)" % (landing.deepest if is_instance_valid(landing) else 0.0))
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

func case_p01() -> void:
	await _build()
	var hud := _player.hud()
	var t := hud.tuning
	_player.say(Player.HANDS_FULL)
	_check(hud.message_colour() == Hud.MESSAGE_REFUSAL and _player.message() == Player.HANDS_FULL, "the red line shows")
	var at := 0.0
	var most := 0.0
	var flips := 0
	var last := 0.0
	var late_most := 0.0
	while hud.wobbling():
		await _frames(1)
		at += get_process_delta_time()
		var turn := hud.message_turn()
		most = maxf(most, absf(turn))
		if at > t.wobble_time * 0.75:
			late_most = maxf(late_most, absf(turn))
		if signf(turn) != 0.0 and signf(turn) != signf(last) and last != 0.0:
			flips += 1
		if turn != 0.0:
			last = turn
	var took := at
	_check(most > t.wobble_turn * 0.5 and most <= t.wobble_turn + 0.0001, "it turns up to 0.07 rad (%.3f)" % most)
	_check(flips >= 3, "to and fro, 5 swings a second (%d turns of side)" % flips)
	_check(late_most < most * 0.5, "dying down (%.3f at the end, %.3f at most)" % [late_most, most])
	_check(took >= t.wobble_time - 0.05 and took < t.wobble_time + 0.3, "for 0.45 s (%.2f s)" % took)
	_near(hud.message_turn(), 0.0, 0.0001, "then it stands still")
	_near(_player.hands_tuning.refusal_time, 2.0, 0.001, "it stays 2 s")
	await _physics_ticks(int(Engine.physics_ticks_per_second * 1.8) - int(took * Engine.physics_ticks_per_second))
	_check(_player.message() == Player.HANDS_FULL, "still showing near 2 s")
	await _physics_ticks(int(Engine.physics_ticks_per_second * 0.4))
	_check(_player.message() == "", "gone after 2 s")


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

func case_p04() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	await _pick(MATE_FLOOR)
	await _until(func() -> bool: return _mess.is_pair(ON_FLOOR), "the mate to fuse")
	await _physics_ticks(40)
	await _aim(_player, Vector3(0.3, 0.0, 0.4))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null and _mess.flight_of(ON_FLOOR).has_node(^"Looks"), "the Pair to fall with its Looks")
	var flight := _mess.flight_of(ON_FLOOR)
	var looks := flight.get_node(^"Looks") as Node3D
	var landing := looks.get_node(^"BallLanding") as BallLanding
	var body := looks.get_node(^"Body") as Node3D
	var t := landing.tuning
	_check(landing.landings == 0, "falling, it has not landed")
	await _until(func() -> bool: return not is_instance_valid(landing) or landing.landings > 0, "the ball to touch down")
	if not is_instance_valid(landing):
		_check(false, "the ball rested before it landed")
		return
	var bottom_drift := 0.0
	while is_instance_valid(landing) and landing.playing():
		await _physics_ticks(1)
		if not is_instance_valid(landing):
			break
		if landing.squash > 0.05:
			# Squashed about its bottom along world up: the round ball's lowest point is drawn where
			# it was, lifted only by the hop.
			var frame := looks.global_transform
			var drawn := frame * body.transform * landing.rest.affine_inverse() * frame.affine_inverse()
			var bottom := frame.origin + Vector3.DOWN * landing.radius
			var size := frame.basis.get_scale().x
			bottom_drift = maxf(bottom_drift, (drawn * bottom).distance_to(bottom + Vector3.UP * landing.hop * size))
	_check(is_instance_valid(landing), "the landing played out before the Pair rested")
	if not is_instance_valid(landing):
		return
	_near(landing.deepest, t.squash, 0.02, "it squashed 0.28 (%.3f)" % landing.deepest)
	_near(landing.highest, t.bounce_height, 0.005, "it hopped 4 cm (%.3f)" % landing.highest)
	# The squash is put on at each tick from the ball's turn then; a ball still spinning 10 rad/s
	# as it lands has turned a little more by the time it is read (a few mm at most).
	_check(bottom_drift < 0.006, "about its bottom, along world up (%.4f m off)" % bottom_drift)
	_check(landing.landings == 1, "once")
	_check(is_zero_approx(landing.squash) and is_zero_approx(landing.hop), "round again after")
	_near(BallLanding.landing(t).length, t.bounce_time + t.squash_time, 0.0001, "the landing lasts the hop and a squash (0.36 s)")


# --- Cloth ---------------------------------------------------------------------------------------

func case_p06() -> void:
	await _build()
	_check(_cloth_tuning().stiffness > 2.0, "stiffer than core/09's 2 (%.2f)" % _cloth_tuning().stiffness)
	await _pick(ON_FLOOR)
	var view := _player.held_view()
	var held := view.looks_of(ON_FLOOR)
	_watch(held)
	await _until(view.settled, "the fly-up to end")
	await _physics_ticks(40)
	var still := _bend(held)
	Input.action_press(&"move_forward")
	await _physics_ticks(40)
	var steady := 0.0
	for i in 30:
		await _physics_ticks(1)
		steady = maxf(steady, absf(_bend(held) - still))
	Input.action_release(&"move_forward")
	_check(steady < 0.02, "a steady walk sways it little (%.4f m at the toe)" % steady)
	await _physics_ticks(60)
	_near(_bend(held), still, 0.002, "stopped, it settles")


func case_p07() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, _player.global_position + Vector3(0.0, 1.0, -2.0))
	await _throw_full()
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the thrown Sock to fly")
	var looks := _mess.flight_of(ON_FLOOR).get_node(^"Looks") as Node3D
	var cloth := looks.find_child("Cloth", true, false) as SockCloth
	var near := false
	var kept := true
	for i in 600:
		await _physics_ticks(1)
		if _mess.state_of(ON_FLOOR) != Mess.State.FLYING or not is_instance_valid(cloth):
			break
		var size := (cloth.get_skeleton().global_transform.basis.get_scale().x)
		if cloth.ground_gap < cloth.tuning.ground_room * size:
			near = true
			kept = kept and cloth.influence <= cloth.ground_room_share(size) + 0.0001
	_check(near, "it came near the ground in flight")
	_check(kept, "near it, its bend never exceeded the room left")
	_check(SockCloth.new().ground_room_share(1.0) == 1.0, "held (no ground under it), the bend is whole")


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


func _cloth_tuning() -> SockClothTuning:
	return preload("res://game/sock/sock_cloth_tuning.tres") as SockClothTuning


func _pops() -> int:
	var n := 0
	for h in _heard:
		if h["event"] == &"lost_pop":
			n += 1
	return n


## Reads `looks`' bend (its Toe from its rest place) each time its skeleton is drawn.
func _watch(looks: Node3D) -> void:
	var skeleton := looks.find_child("Skeleton3D", true, false) as Skeleton3D
	var key := looks.get_instance_id()
	skeleton.skeleton_updated.connect(func() -> void:
		_bends[key] = skeleton.get_bone_global_pose(TOE).origin.distance_to(skeleton.get_bone_global_rest(TOE).origin))


func _bend(looks: Node3D) -> float:
	return _bends.get(looks.get_instance_id(), 0.0)


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
