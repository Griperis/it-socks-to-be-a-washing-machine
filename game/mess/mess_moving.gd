## The Host's moving Socks (core/13, M05-M10): each a falling body (`flight.tscn`, a Pair's
## `ball_flight.tscn`) counted against the moving budget (MessTuning). Woken Socks wait their turn
## nearest the players first and start a few a tick as a `wake` or `fall` Command; drops and Throws
## never wait. A flight rests once it has stayed still for the rest time (no total time limit,
## Q2308); under pressure the slowest farthest from the players rest first. A pick, a fast hit and a
## moving Door or drawer wake the lying Socks they meet. It writes no state: it asks the Mess's
## Host-only Commands, and the Mess says when a Sock starts or stops flying.
class_name MessMoving
extends RefCounted

const FLIGHT_SCENE := preload("res://game/sock/flight.tscn")
const BALL_FLIGHT_SCENE := preload("res://game/sock/ball_flight.tscn")
## A body this fast (m/s) sweeps its way; under CCD_OFF it no longer does (the old SockWorld's).
const CCD_ON := 1.0
const CCD_OFF := 0.5

var _mess: Mess
## The falling bodies, by Sock id.
var _flights: Dictionary[int, RigidBody3D] = {}
## A body's time in the air and its time still (under the rest speed and spin).
var _airborne: Dictionary[int, float] = {}
var _still: Dictionary[int, float] = {}
## Each body's speed before this physics step (what its hits are judged by).
var _speeds: Dictionary[int, float] = {}
## The boxes lying things were taken from by a pick, looked over at the next tick for what rested on
## them (M07).
var _taken: Array[AABB] = []
## The falling Pairs that drag as Pairs do (P07).
var _damped: Dictionary[int, bool] = {}
## The dropped bodies: let go, they wake nothing they fall on (as before Q2367, when a drop fell 3 cm).
var _dropped: Dictionary[int, bool] = {}
## The lying Socks waiting to move, with the Command that starts them (&"wake" or &"fall"), and
## their order (nearest the players first), sorted again when one is added.
var _waiting: Dictionary[int, StringName] = {}
var _order := PackedInt32Array()
var _sorted := true


func _init(mess: Mess) -> void:
	_mess = mess


## The falling body of Sock `sock`, or null.
func flight_of(sock: int) -> RigidBody3D:
	return _flights.get(sock)


## How many Socks move now, and how many wait to.
func moving_count() -> int:
	return _flights.size()


func waiting_count() -> int:
	return _waiting.size()


func is_waiting(sock: int) -> bool:
	return _waiting.has(sock)


## Lying Socks `socks` wait their turn to move, started by Command `kind` (&"wake" or &"fall"),
## nearest the players first.
func queue_wake(socks: PackedInt32Array, kind: StringName) -> void:
	for sock in socks:
		if _mess.state_of(sock) == Mess.State.LYING and not _waiting.has(sock):
			_waiting[sock] = kind
			_order.append(sock)
			_sorted = false


## A pick took a lying thing from box `place`: what rested on it wakes at the next tick (M07).
func note_taken(place: AABB) -> void:
	_taken.append(place)


## The Mess shows Sock `sock`'s new record: no longer lying, it waits no more; no longer flying, its
## body goes.
func forget(sock: int) -> void:
	if _mess.state_of(sock) != Mess.State.LYING:
		_waiting.erase(sock)
	if _flights.has(sock) and _mess.state_of(sock) != Mess.State.FLYING:
		_drop_flight(sock)


## The Mess shows Sock `sock` FLYING with no body yet: it starts now (woken, dropped or thrown:
## Q2367 took the drop's flick away).
func start(sock: int, woken: bool, _now: bool) -> void:
	if _flights.has(sock):
		return
	_launch(sock, woken)


## Every body freed (a whole new state, or the Mess leaves).
func clear() -> void:
	for sock: int in _flights.keys():
		_drop_flight(sock)
	_waiting.clear()
	_order = PackedInt32Array()
	_taken.clear()


## Once a physics tick: hits and picks and movers wake, still flights rest (at most
## the stop cap), pressure frees room, and the waiting start.
func tick(delta: float) -> void:
	var t := _mess.bodies_tuning()
	_hits()
	var taken := _taken
	_taken = []
	for place in taken:
		queue_wake(_mess.resting_on(place), &"fall")
	_sweep_movers()
	var ready: Array[int] = []
	for sock: int in _flights.keys():
		var body := _flights[sock]
		_airborne[sock] += delta
		_speeds[sock] = body.linear_velocity.length()
		_switch_ccd(body)
		if not _mess.in_bounds(body.global_position):
			_rest(sock, _return_pose(body))
			continue
		var pair := _mess.is_pair(sock)
		var slow := body.linear_velocity.length() < (t.pair_rest_speed if pair else t.rest_speed) \
				and body.angular_velocity.length() < (t.pair_rest_spin if pair else t.rest_spin)
		_still[sock] = float(_still.get(sock, 0.0)) + delta if slow else 0.0
		if _still[sock] >= t.rest_time or (body.sleeping and _airborne[sock] > 0.1):
			ready.append(sock)
	var stops := t.stop_cap
	for sock in ready:
		if stops == 0:
			break
		_settle(sock)
		stops -= 1
	if stops > 0:
		_relieve(stops)
	_start_waiting()


## A flight that has come to rest lies where it is, or at the return spot when it would lie inside
## a wall (T08).
func _settle(sock: int) -> void:
	var body := _flights[sock]
	var t := body.global_transform.orthonormalized()
	var centre := t * _middle(body)
	_rest(sock, _return_pose(body) if PhysicsQueries.inside(_mess, centre, Mess.LAYER_HOUSE) else t)


func _rest(sock: int, t: Transform3D) -> void:
	_mess.parts.ask(Command.new(&"rest", Parts.HOST, _mess.id, {"sock": sock, "at": t.origin, "rot": t.basis.get_euler()}))


## Under pressure (Socks waiting, the general share of the budget full), up to `most` slow flights
## farthest from the players rest now, the slowest first; never one moving for less than the rest
## time or faster than the pressure speed (M05).
func _relieve(most: int) -> void:
	var t := _mess.bodies_tuning()
	if _waiting.is_empty() or _flights.size() < t.moving_budget - t.throw_reserve:
		return
	var players := _player_spots()
	var keyed: Array[Vector3] = []
	for sock: int in _flights.keys():
		var body := _flights[sock]
		var speed := body.linear_velocity.length()
		if _airborne[sock] < t.rest_time or speed >= t.pressure_speed:
			continue
		keyed.append(Vector3(floorf(speed / t.pressure_speed * 15.0), -_nearest(players, body.global_position), sock))
	keyed.sort()
	for i in mini(keyed.size(), mini(most, _waiting.size())):
		_settle(int(keyed[i].z))


## The waiting Socks start, nearest the players first, at most the start cap a tick and while the
## general share of the budget has room (M05): one `wake` and one `fall` at most.
func _start_waiting() -> void:
	if _waiting.is_empty():
		return
	var t := _mess.bodies_tuning()
	var room := mini(t.start_cap, t.moving_budget - t.throw_reserve - _flights.size())
	if room <= 0:
		return
	if not _sorted:
		var players := _player_spots()
		var keyed: Array[Vector2] = []
		for sock in _order:
			if _waiting.has(sock):
				keyed.append(Vector2(_nearest(players, _mess.pose_of(sock).origin), sock))
		keyed.sort()
		_order = PackedInt32Array()
		for k in keyed:
			_order.append(int(k.y))
		_sorted = true
	var wakes := PackedInt32Array()
	var falls := PackedInt32Array()
	var used := 0
	while used < room and not _order.is_empty():
		var sock := _order[0]
		_order.remove_at(0)
		if not _waiting.has(sock):
			continue
		var kind: StringName = _waiting[sock]
		_waiting.erase(sock)
		if _mess.state_of(sock) != Mess.State.LYING:
			continue
		if kind == &"fall":
			falls.append(sock)
		else:
			wakes.append(sock)
		used += 1
	if not wakes.is_empty():
		_mess.parts.ask(Command.new(&"wake", Parts.HOST, _mess.id, {"socks": wakes}))
	if not falls.is_empty():
		_mess.parts.ask(Command.new(&"fall", Parts.HOST, _mess.id, {"socks": falls}))


## A flight faster than the wake speed before this step that touches a lying Sock wakes it and up
## to wake_count Socks touching it (T11, M08), one hit a flight a tick; lying Pairs stay (Q2330). The lying bodies have no node, so
## the contacts are read from the flight's body state.
func _hits() -> void:
	var fast := _mess.tuning.wake_speed if _mess.tuning != null else 1.5
	for sock: int in _flights.keys():
		if float(_speeds.get(sock, 0.0)) < fast or _dropped.has(sock):
			continue
		var state := PhysicsServer3D.body_get_direct_state(_flights[sock].get_rid())
		if state == null:
			continue
		for c in state.get_contact_count():
			var hit := _mess.sock_at(state.get_contact_collider(c))
			# A resting Pair is never moved by a hit, as in the old game (Q2330, old Q1742).
			if hit >= 0 and not _mess.is_pair(hit) and not _waiting.has(hit):
				var woken := PackedInt32Array([hit])
				for other: int in _mess.touching(hit):
					if not _mess.is_pair(other):
						woken.append(other)
				queue_wake(woken, &"wake")
				break


## Every Door and drawer moving now wakes the lying Socks in its way or on it at once (at most the
## sweep cap a tick; past the budget they wait), and its body pushes or carries them (M09).
func _sweep_movers() -> void:
	var t := _mess.bodies_tuning()
	var found := PackedInt32Array()
	for node in _mess.get_tree().get_nodes_in_group(Openable.GROUP):
		var openable := node as Openable
		if openable == null or not openable.is_moving():
			continue
		for body in openable.movers():
			for child in body.get_children():
				var shape := child as CollisionShape3D
				if shape == null or shape.disabled or shape.shape == null:
					continue
				for sock in _mess.lying_overlapping(_grown(shape.shape, t.sweep_margin), shape.global_transform, t.sweep_cap * 2):
					if found.size() < t.sweep_cap and not found.has(sock) and _mess.state_of(sock) == Mess.State.LYING:
						found.append(sock)
	if found.is_empty():
		return
	var now := PackedInt32Array()
	var late := PackedInt32Array()
	for sock in found:
		if _flights.size() + now.size() < t.moving_budget:
			now.append(sock)
		else:
			late.append(sock)
	for sock in now:
		_waiting.erase(sock)
	if not now.is_empty():
		_mess.parts.ask(Command.new(&"wake", Parts.HOST, _mess.id, {"socks": now}))
	queue_wake(late, &"wake")


## Where the players of this machine stand (the budget's "nearest the players").
func _player_spots() -> PackedVector3Array:
	var out := PackedVector3Array()
	if _mess.is_inside_tree():
		for node in _mess.get_tree().get_nodes_in_group(Hands.PLAYERS):
			var player := node as Node3D
			if player != null:
				out.append(player.global_position)
	return out


static func _nearest(players: PackedVector3Array, at: Vector3) -> float:
	var best := INF
	for p in players:
		best = minf(best, p.distance_to(at))
	return 0.0 if best == INF else best


## Where a Sock is put down when it cannot lie where its body is: the return spot, or straight under
## the body with no spot set (a Pair's ball a radius over the spot).
func _return_pose(body: RigidBody3D) -> Transform3D:
	var sock := int(body.get_meta(Mess.SOCK_META, -1))
	var lift := Vector3.UP * SockDress.ball_radius(_mess.design_of(sock)) if _mess.is_pair(sock) else Vector3.ZERO
	var spot := _mess.return_spot
	if spot != null and spot.is_inside_tree():
		var t := spot.global_transform.orthonormalized()
		return Transform3D(t.basis, t.origin + lift)
	return Transform3D(Basis.IDENTITY, body.global_position)


## Lets a Sock go: one physical body from its pose, falling, or flying with its launch. A woken one
## (`woken`), a poured one (an `add`'s push, by Mess.NOBODY: the old SockPour let its Socks fall as
## Moving Socks) and a dropped one (let go from the hand, Q2367: it falls, no bounce) slide and drag
## as a woken Sock; a thrown one bounces and drags as a Throw (M10). A dropped or thrown one's own
## player's body lets it through. A Pair is its ball's body; it drags as a Pair from its first touch
## (P07), a fallen or dropped one from the start.
func _launch(sock: int, woken: bool) -> void:
	var t := _mess.bodies_tuning()
	var hands := _mess.tuning
	var pair := _mess.is_pair(sock)
	var launch: Dictionary = _mess.throws.get(sock, {})
	var dropped := bool(launch.get("drop", false))
	if not launch.is_empty() and (int(launch.get("by", 0)) == Mess.NOBODY or dropped):
		woken = true
	var body := (BALL_FLIGHT_SCENE if pair else FLIGHT_SCENE).instantiate() as RigidBody3D
	body.name = Mess.FLIGHT_NAME % sock
	body.set_meta(Mess.SOCK_META, sock)
	_fit(body, _mess.design_of(sock))
	var material := PhysicsMaterial.new()
	material.friction = t.woken_friction if woken else t.released_friction
	material.bounce = 0.0 if woken else t.released_bounce
	body.physics_material_override = material
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	if woken:
		body.linear_damp = t.woken_linear_damp
		body.angular_damp = t.woken_angular_damp
	else:
		body.linear_damp = hands.thrown_linear_damp if hands != null else 0.05
		body.angular_damp = hands.thrown_angular_damp if hands != null else 0.8
	if not launch.is_empty():
		body.linear_velocity = launch["vel"]
		body.angular_velocity = launch["spin"]
	_switch_ccd(body)
	if not pair:
		body.inertia = turn_inertia(body.mass, SockDress.box(_mess.design_of(sock)), t.turn_weight)
	_mess.flight_holder().add_child(body, true)
	body.global_transform = _mess.pose_of(sock)
	body.reset_physics_interpolation()
	if not launch.is_empty():
		_spare_thrower(body, int(launch["by"]))
	body.body_entered.connect(_on_contact.bind(sock))
	_flights[sock] = body
	if pair and (launch.is_empty() or dropped):
		_damp_pair(sock)
	if dropped:
		_dropped[sock] = true
	_airborne[sock] = 0.0
	_still[sock] = 0.0
	_speeds[sock] = body.linear_velocity.length()
	_mess.give_looks()


## The thrower's own body (alone: the local player) lets their thrown Sock through: it leaves from
## inside their reach. A Guest's avatar is M0.6's.
func _spare_thrower(body: RigidBody3D, by: int) -> void:
	for node in _mess.get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player != null and player.player_id() == by:
			body.add_collision_exception_with(player)


## A falling body touched `other` (a node: the house, a Cabinet; the lying Socks have none and are
## read by _hits()).
func _on_contact(other: Node, sock: int) -> void:
	if _mess.is_pair(sock) and not _damped.has(sock):
		_damp_pair(sock)
	_mess.flight_touched.emit(sock, other)


## A falling Pair drags as a Pair from now on: it stops within a few cm (P07).
func _damp_pair(sock: int) -> void:
	var body: RigidBody3D = _flights.get(sock)
	if body == null:
		return
	var hands := _mess.tuning
	_damped[sock] = true
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.linear_damp = hands.pair_linear_damp if hands != null else 2.5
	body.angular_damp = hands.pair_angular_damp if hands != null else 8.0


func _drop_flight(sock: int) -> void:
	_flights[sock].queue_free()
	_flights.erase(sock)
	_airborne.erase(sock)
	_still.erase(sock)
	_speeds.erase(sock)
	_damped.erase(sock)
	_dropped.erase(sock)


## A fast body sweeps its way (continuous collision) from CCD_ON m/s and stops sweeping under
## CCD_OFF, as the old game's (SockWorld.CCD_ON, CCD_OFF): a 2 cm Sock moving most of its thickness a
## tick could pass through a thin part, and a slow one swept into its contacts is kicked into a spin.
func _switch_ccd(body: RigidBody3D) -> void:
	var speed := body.linear_velocity.length()
	if speed >= CCD_ON:
		body.continuous_cd = true
	elif speed < CCD_OFF:
		body.continuous_cd = false


## A falling body's shapes (a Pair's ball) fitted to its Design's Size: a Sock's are the leg and foot
## boxes it lies on (MessBodies.parts_at), so it flies, lands and lies as the same shape, as the old
## game's one set of shapes for both tiers.
static func _fit(body: CollisionObject3D, design: SockDesign) -> void:
	var shape := body.get_node(^"Shape") as CollisionShape3D
	if shape.shape is SphereShape3D:
		var ball := (shape.shape as SphereShape3D).duplicate() as SphereShape3D
		ball.radius = SockDress.ball_radius(design)
		shape.shape = ball
		return
	var parts := MessBodies.parts_at(design.size_scale() if design != null else 1.0)
	for i in parts.size():
		var part := shape
		if i > 0:
			part = CollisionShape3D.new()
			part.name = "Shape%d" % (i + 1)
			body.add_child(part)
		var box := BoxShape3D.new()
		box.size = parts[i][0]
		part.shape = box
		part.position = parts[i][1]


## A Sock's turning inertia: its whole flat box's, of `mass`, `weight` times over (a 50 g board's own
## is so small that an off-centre touch spins it up to Jolt's limit in one tick).
static func turn_inertia(mass: float, box: Vector3, weight: float) -> Vector3:
	var x2 := box.x * box.x
	var y2 := box.y * box.y
	var z2 := box.z * box.z
	return mass / 12.0 * weight * Vector3(y2 + z2, x2 + z2, x2 + y2)


## The middle of a falling body's shapes, in its own space.
static func _middle(body: Node3D) -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape != null:
			sum += shape.position
			n += 1
	return sum / maxf(n, 1)


## A copy of a box or ball shape, `margin` bigger all round (any other shape as it is).
static func _grown(shape: Shape3D, margin: float) -> Shape3D:
	if shape is SphereShape3D:
		var ball := (shape as SphereShape3D).duplicate() as SphereShape3D
		ball.radius += margin
		return ball
	if shape is BoxShape3D:
		var box := (shape as BoxShape3D).duplicate() as BoxShape3D
		box.size += Vector3.ONE * margin * 2.0
		return box
	return shape
