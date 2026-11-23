## The Host's moving Socks (core/13, M05-M10): each a falling body (`flight.tscn`, a Pair's
## `ball_flight.tscn`) counted against the moving budget (MessTuning). Woken Socks wait their turn
## nearest the players first and start a few a tick as a `wake` or `fall` Command; drops and Throws
## never wait. A flight rests once it has stayed still for the rest time (no total time limit,
## Q2308); under pressure the slowest farthest from the players rest first. A pick, a fast hit and a
## moving Door or drawer wake the lying Socks they meet. It writes no state: it asks the Mess's
## Host-only Commands, and the Mess says when a Sock starts or stops flying.
##
## On a Guest (coop/08) it starts a looks-only body for every Sock the Host's answers make FLYING (but
## a Throw: the spawner's copy), on Mess.LAYER_LOOKS; it never asks anything. Its moving Doors and
## drawers sweep its own lying Socks the same way, the records as they are (`tick_looks`); such a
## body the Host never moved goes back where it lay once it comes to rest.
class_name MessMoving
extends RefCounted

const FLIGHT_SCENE := preload("res://game/sock/flight.tscn")
const BALL_FLIGHT_SCENE := preload("res://game/sock/ball_flight.tscn")

var _mess: Mess
## The falling bodies, by Sock id.
var _flights: Dictionary[int, RigidBody3D] = {}
## A body's time in the air and its time still (under the rest speed and spin).
var _airborne: Dictionary[int, float] = {}
var _still: Dictionary[int, float] = {}
## Each body's speed before this physics step (what its hits are judged by), and the step before.
var _speeds: Dictionary[int, float] = {}
var _speeds_before: Dictionary[int, float] = {}
## Each body's place after the last physics step (core/50: a step that pushed it into the house is undone).
var _was: Dictionary[int, Transform3D] = {}
## How many steps were undone so since the Mess started (the suite and the benchmark read it).
var pushed_in := 0
## The boxes lying things were taken from by a pick, looked over at the next tick for what rested on
## them (M07).
var _taken: Array[AABB] = []
## The falling Pairs that drag as Pairs do (P07).
var _damped: Dictionary[int, bool] = {}
## The dropped bodies: let go, they wake nothing they fall on (as before Q2367, when a drop fell 3 cm).
var _dropped: Dictionary[int, bool] = {}
## The thrown bodies (a Throw's launch, not dropped, poured or woken): they wake what they are about to
## hit before they touch it (core/46, Q2431).
var _thrown: Dictionary[int, bool] = {}
## The sphere a Throw's look-ahead finds the lying Socks it is about to hit with (`HandsTuning.hit_reach`).
var _ahead := SphereShape3D.new()
## The lying Socks waiting to move, with the Command that starts them (&"wake" or &"fall"), and
## their order (nearest the players first), sorted again when one is added.
var _waiting: Dictionary[int, StringName] = {}
var _order := PackedInt32Array()
var _sorted := true
## The flights' physics materials, shared: one per friction and bounce (two while the tuning holds still).
static var _materials: Dictionary[Vector2, PhysicsMaterial] = {}
## The Door and drawer leaves seen moving (core/39), by body RID: the body, and its place before its
## last step and now (which side a Sock left inside it is pushed out to).
var _leaf_body: Dictionary[RID, AnimatableBody3D] = {}
var _leaf_was: Dictionary[RID, Transform3D] = {}
var _leaf_now: Dictionary[RID, Transform3D] = {}
## How many times each flight has been pushed out of a leaf (`MessTuning.leaf_push_tries`).
var _pushes: Dictionary[int, int] = {}
## The flights that came to rest this tick, each with its place, turn and whether it was lost: asked
## of the Mess as one `rest` at the tick's end (coop/07), then cleared.
var _resting: Dictionary[int, Array] = {}
## A leaf shape's box in its own space (a box's size, a convex shape's points' bounds), by shape.
var _shape_boxes: Dictionary[Shape3D, AABB] = {}
## The point that finds which leaf a Sock's middle is in.
var _probe := SphereShape3D.new()


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
## Q2367 took the drop's flick away). `motion` ([pose, velocity, spin], a whole state's body in flight:
## a late Guest, a load) starts it there instead of at its record.
func start(sock: int, woken: bool, motion: Array = []) -> void:
	if _flights.has(sock):
		return
	_launch(sock, woken, motion)


## Every body freed (a whole new state, or the Mess leaves).
func clear() -> void:
	for sock: int in _flights.keys():
		_drop_flight(sock)
	_waiting.clear()
	_order = PackedInt32Array()
	_taken.clear()
	_leaf_body.clear()
	_leaf_was.clear()
	_leaf_now.clear()
	_resting.clear()


## Once a physics tick: hits and picks and movers wake, still flights rest (at most
## the stop cap), pressure frees room, and the waiting start.
func tick(delta: float) -> void:
	var t := _mess.bodies_tuning()
	_hits(delta)
	var taken := _taken
	_taken = []
	for place in taken:
		queue_wake(_mess.resting_on(place), &"fall")
	_sweep_movers()
	var ready: Array[int] = []
	var out: Array[int] = []
	# Read once a tick, not once a body (core/31): the bounds in the level's own space.
	var bounded := _mess.bounds.has_volume()
	var to_local := _mess.lying.global_transform.affine_inverse() if bounded and _mess.lying != null else Transform3D.IDENTITY
	for sock: int in _flights:
		var body := _flights[sock]
		if _pushed_in(sock, body, delta, t):
			continue
		var speed := body.linear_velocity.length()
		_airborne[sock] += delta
		_speeds_before[sock] = float(_speeds.get(sock, speed))
		_speeds[sock] = speed
		switch_ccd(body, speed, t)
		if bounded and not _mess.bounds.has_point(to_local * body.global_position):
			out.append(sock)
			continue
		var pair := _mess.mate_of(sock) >= 0
		var slow := speed < (t.pair_rest_speed if pair else t.rest_speed) \
				and body.angular_velocity.length() < (t.pair_rest_spin if pair else t.rest_spin)
		var still := _still[sock] + delta if slow else 0.0
		_still[sock] = still
		if still >= t.rest_time or (body.sleeping and _airborne[sock] > t.asleep_rest_after):
			ready.append(sock)
	for sock in out:
		_rest(sock, _mess.return_pose(sock), true)
	var stops := t.stop_cap
	for sock in ready:
		if stops == 0:
			break
		_settle(sock)
		stops -= 1
	if stops > 0:
		_relieve(stops)
	_ask_rests()
	_start_waiting()


## A Guest, once a physics tick (coop/08): its moving Doors and drawers sweep its own lying Socks
## (looks only), and a body of a Sock the Host never moved (its record still LYING) goes back where it
## lay once still for the rest time, asleep or out of bounds (B06). Bodies the Host's answers started
## wait for its rest batch. Nothing is asked.
func tick_looks(delta: float) -> void:
	var t := _mess.bodies_tuning()
	_sweep_movers()
	var back: Array[int] = []
	var bounded := _mess.bounds.has_volume()
	var to_local := _mess.lying.global_transform.affine_inverse() if bounded and _mess.lying != null else Transform3D.IDENTITY
	for sock: int in _flights:
		var body := _flights[sock]
		if _pushed_in(sock, body, delta, t):
			continue
		var speed := body.linear_velocity.length()
		_airborne[sock] += delta
		_speeds[sock] = speed
		switch_ccd(body, speed, t)
		if _mess.state_of(sock) != Mess.State.LYING:
			continue
		if bounded and not _mess.bounds.has_point(to_local * body.global_position):
			back.append(sock)
			continue
		var slow := speed < t.rest_speed and body.angular_velocity.length() < t.rest_spin
		_still[sock] = _still[sock] + delta if slow else 0.0
		if _still[sock] >= t.rest_time or (body.sleeping and _airborne[sock] > t.asleep_rest_after):
			back.append(sock)
	for sock in back:
		_drop_flight(sock)
		_mess.lie_again(sock)


## Whether the last physics step pushed flight `sock` into the house (core/50); if so it is undone.
## A step that moved it farther than its speed (before and after the step) and its turn explain, by
## more than `MessTuning.push_slack`, and left the middle of its leg or foot (a Pair's ball) inside the
## house, was Jolt's position solve, not a flight: a Sock touching the zoo's 0.2 m floor was so pushed
## 0.17 m to 0.24 m down in one step, past the floor's middle, and from there the floor's bottom face
## held it under the floor. The body goes back to its place before the step, `push_lift` higher (at
## the same place Jolt pushes it again), with its fall and turn stopped; nothing else is judged of it
## this tick. It costs one point query only for such a step.
func _pushed_in(sock: int, body: RigidBody3D, delta: float, t: MessTuning) -> bool:
	var now := body.global_transform
	var was: Transform3D = _was.get(sock, now)
	_was[sock] = now
	var motion := float(_speeds.get(sock, 0.0)) + body.linear_velocity.length() + body.angular_velocity.length() * t.push_reach
	if now.origin.distance_to(was.origin) <= motion * delta + t.push_slack or not _in_house(body):
		return false
	var back := was.translated(Vector3.UP * t.push_lift)
	body.global_transform = back
	body.reset_physics_interpolation()
	var v := body.linear_velocity
	body.linear_velocity = Vector3(v.x, maxf(v.y, 0.0), v.z)
	body.angular_velocity = Vector3.ZERO
	_was[sock] = back
	_still[sock] = 0.0
	pushed_in += 1
	return true


## Whether the middle of one of `body`'s shapes (a leg, a foot, a Pair's ball) is inside the house.
func _in_house(body: RigidBody3D) -> bool:
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape != null and PhysicsQueries.inside(_mess, shape.global_position, Mess.LAYER_HOUSE):
			return true
	return false


## A flight that has come to rest lies where it is, pushed up onto a floor it sank into, or at the
## return spot when it would lie inside a wall (T08; core/16 P12, P13: Mess.put_down()).
## One whose middle is in a Door's or drawer's leaf is pushed out of it instead (core/39): it flies
## on from past the leaf's face, or is put down there (MessTuning "Pushed out of a leaf").
## `pressed` (made to rest under pressure, still moving, M05): it rests only where it is, never moved
## by the rule (core/50: a Sock lifted at its rest while still moving was written hot and jumped);
## else it flies on and is asked again.
func _settle(sock: int, pressed := false) -> void:
	var body := _flights[sock]
	var at := body.global_transform.orthonormalized()
	var down := _mess.put_down(sock, at)
	if pressed and not down["returned"] and not (down["pose"] as Transform3D).origin.is_equal_approx(at.origin):
		return
	var t := _mess.bodies_tuning()
	if down.has("pushed") and t.leaf_push_speed > 0.0 and _pushes.get(sock, 0) < t.leaf_push_tries:
		_pushes[sock] = _pushes.get(sock, 0) + 1
		body.global_transform = down["pose"]
		body.reset_physics_interpolation()
		_was[sock] = body.global_transform
		body.linear_velocity = (down["pushed"] as Vector3) * t.leaf_push_speed
		body.angular_velocity = Vector3.ZERO
		body.sleeping = false
		_still[sock] = 0.0
		_airborne[sock] = 0.0
		return
	_rest(sock, down["pose"], down["returned"])


## Notes `sock` to lie at `t` in this tick's `rest`; `returned`: it was lost and came back (a pop plays).
func _rest(sock: int, t: Transform3D, returned := false) -> void:
	_resting[sock] = [t.origin, t.basis.get_euler(), returned]


## Every flight that came to rest this tick lies, in one `rest` of the Mess (one answer, one reliable
## message to each Guest: the old game's settle stream); none, nothing is asked.
func _ask_rests() -> void:
	if _resting.is_empty():
		return
	var socks := PackedInt32Array()
	var ats := PackedVector3Array()
	var rots := PackedVector3Array()
	var back := PackedInt32Array()
	for sock: int in _resting:
		var r: Array = _resting[sock]
		socks.append(sock)
		ats.append(r[0])
		rots.append(r[1])
		if r[2]:
			back.append(sock)
	_resting.clear()
	_mess.parts.ask(Command.new(&"rest", Parts.HOST, _mess.id, {"socks": socks, "ats": ats, "rots": rots, "returned": back}))


## Under pressure (Socks waiting, the general share of the budget full), up to `most` slow flights
## farthest from the players rest now, the slowest first; never one moving for less than the rest
## time or faster than the pressure speed (M05), now or the step before (core/50: one just stopped
## by a hit is still moving).
func _relieve(most: int) -> void:
	var t := _mess.bodies_tuning()
	if _waiting.is_empty() or _flights.size() - _resting.size() < t.moving_budget - t.throw_reserve:
		return
	var players := _player_spots()
	var keyed: Array[Vector3] = []
	for sock: int in _flights.keys():
		if _resting.has(sock):
			continue
		var body := _flights[sock]
		var speed := body.linear_velocity.length()
		if _airborne[sock] < t.rest_time or speed >= t.pressure_speed or float(_speeds_before.get(sock, 0.0)) >= t.pressure_speed:
			continue
		keyed.append(Vector3(floorf(speed / t.pressure_speed * t.pressure_bands), -_nearest(players, body.global_position), sock))
	keyed.sort()
	for i in mini(keyed.size(), mini(most, _waiting.size())):
		_settle(int(keyed[i].z), true)


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
## the contacts are read from the flight's body state. A thrown flight first looks ahead along its
## motion and wakes what it is about to hit before the contact, so it shoves them (`_ahead_hit`).
func _hits(delta: float) -> void:
	var fast := _mess.tuning.wake_speed
	for sock: int in _flights.keys():
		if _dropped.has(sock):
			continue
		if _thrown.has(sock) and _ahead_hit(sock, delta):
			continue
		if float(_speeds.get(sock, 0.0)) < fast:
			continue
		var state := PhysicsServer3D.body_get_direct_state(_flights[sock].get_rid())
		if state == null:
			continue
		for c in state.get_contact_count():
			var hit := _mess.sock_at(state.get_contact_collider(c))
			if _wake_hit(hit):
				_bounce(sock)
				break


## A thrown flight at the wake speed or more wakes the lying Socks it is about to meet, and up to
## wake_count touching them: one query of a `hit_reach` sphere `hit_lead_ticks` ticks ahead along its
## motion, so they move before it arrives and its mass and speed push them (the old
## SockFlights._impact_wakes, Q1215; core/46, Q2431). Whether it woke any.
func _ahead_hit(sock: int, delta: float) -> bool:
	var hands := _mess.tuning
	var body := _flights[sock]
	var v := body.linear_velocity
	if v.length() < hands.wake_speed or hands.hit_reach <= 0.0:
		return false
	_ahead.radius = hands.hit_reach
	var at := Transform3D(Basis(), body.global_position + v * delta * float(hands.hit_lead_ticks))
	for hit in _mess.lying_overlapping(_ahead, at, maxi(1, hands.wake_count)):
		if _wake_hit(hit):
			return true
	return false


## Lying Sock `hit` (or -1) was hit: it and up to wake_count touching it wait to wake. A resting Pair is
## never moved by a hit, as in the old game (Q2330, old Q1742). Whether it was a hit.
func _wake_hit(hit: int) -> bool:
	if hit < 0 or _mess.is_pair(hit) or _waiting.has(hit) or _mess.state_of(hit) != Mess.State.LYING:
		return false
	var woken := PackedInt32Array([hit])
	for other: int in _mess.touching(hit):
		if not _mess.is_pair(other):
			woken.append(other)
	queue_wake(woken, &"wake")
	return true


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
			_note_leaf(body)
			for child in body.get_children():
				var shape := child as CollisionShape3D
				if shape == null or shape.disabled or shape.shape == null:
					continue
				for sock in _mess.lying_overlapping(_grown(shape.shape, t.sweep_margin), shape.global_transform, t.sweep_cap * 2):
					if found.size() < t.sweep_cap and not found.has(sock) and _mess.state_of(sock) == Mess.State.LYING:
						found.append(sock)
	if found.is_empty():
		return
	if not _mess.decides():
		# A Guest: looks only, within the budget; the rest wait for the Host's answers.
		for sock in found:
			if _flights.size() >= t.moving_budget:
				break
			_mess.lift(sock)
			_launch(sock, true)
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


## Leaf `body` is moving: its place now, and before its last step.
func _note_leaf(body: AnimatableBody3D) -> void:
	var rid := body.get_rid()
	var now := body.global_transform
	if not _leaf_body.has(rid):
		_leaf_body[rid] = body
		_leaf_was[rid] = now
	elif not _leaf_now[rid].is_equal_approx(now):
		_leaf_was[rid] = _leaf_now[rid]
	_leaf_now[rid] = now


## The way out of a Door's or drawer's leaf seen moving for a Sock whose middle is `centre` inside it
## (core/39, Q2428): {"dir": flat, to the side the leaf swept from (with no step seen, through the
## nearer face), "exit": how far along it the middle leaves the leaf, in m}; {} when it is in none.
func out_of_leaf(centre: Vector3) -> Dictionary:
	if _leaf_body.is_empty():
		return {}
	_probe.radius = 0.001
	for rid in PhysicsQueries.overlap_rids(_mess, _probe, Transform3D(Basis.IDENTITY, centre), Mess.LAYER_HOUSE, 8):
		var found: Variant = _leaf_body.get(rid)
		if not is_instance_valid(found):
			continue
		var body := found as AnimatableBody3D
		if not body.is_inside_tree():
			continue
		var back := _leaf_was[rid] * (body.global_transform.affine_inverse() * centre) - centre
		back.y = 0.0
		for child in body.get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.disabled or shape.shape == null:
				continue
			var box := _shape_box(shape.shape)
			var to_shape := shape.global_transform.affine_inverse()
			var q := to_shape * centre
			if not box.has_volume() or not box.grow(0.0005).has_point(q):
				continue
			var dir := back.normalized() if back.length() > 0.0001 else _nearest_face(shape.global_transform, box, q)
			var d := to_shape.basis * dir
			var out := _exit(box, q, d)
			if dir == Vector3.ZERO or out == INF:
				continue
			return {"dir": dir, "exit": (shape.global_transform * (q + d * out)).distance_to(centre)}
	return {}


## A leaf shape's box in its own space: a box's size, a convex shape's points' bounds; else none.
func _shape_box(shape: Shape3D) -> AABB:
	if _shape_boxes.has(shape):
		return _shape_boxes[shape]
	var box := AABB()
	if shape is BoxShape3D:
		var size := (shape as BoxShape3D).size
		box = AABB(-size * 0.5, size)
	elif shape is ConvexPolygonShape3D:
		var points := (shape as ConvexPolygonShape3D).points
		if not points.is_empty():
			box = AABB(points[0], Vector3.ZERO)
			for p in points:
				box = box.expand(p)
	_shape_boxes[shape] = box
	return box


## How far along `dir` (in the box's space) point `q` inside `box` leaves it; INF for no way out.
static func _exit(box: AABB, q: Vector3, dir: Vector3) -> float:
	var best := INF
	for i in 3:
		if absf(dir[i]) < 0.000001:
			continue
		var wall := box.end[i] if dir[i] > 0.0 else box.position[i]
		best = minf(best, maxf((wall - q[i]) / dir[i], 0.0))
	return best


## The flat way out of `box` (at `xform`) nearest to `q`: through its nearer side face.
static func _nearest_face(xform: Transform3D, box: AABB, q: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var gap := INF
	for i in 3:
		for side: float in [-1.0, 1.0]:
			var axis := Vector3.ZERO
			axis[i] = side
			var world := xform.basis * axis
			world.y = 0.0
			if world.length() < 0.5:
				continue
			var d := (box.end[i] - q[i]) if side > 0.0 else (q[i] - box.position[i])
			if d < gap:
				gap = d
				best = world.normalized()
	return best


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


## Lets a Sock go: one physical body from its pose, falling, or flying with its launch. A woken one
## (`woken`), a poured one (an `add`'s push, by Mess.NOBODY: the old SockPour let its Socks fall as
## Moving Socks) and a dropped one (let go from the hand, Q2367: it falls, no bounce) slide and drag
## as a woken Sock; a thrown one bounces and drags as a Throw (M10). A dropped or thrown one's own
## player's body lets it through. A Pair is its ball's body; it drags as a Pair from its first touch
## (P07), a fallen or dropped one from the start.
##
## On a Guest the body is looks only (coop/08): on Mess.LAYER_LOOKS, sparing no thrower (it touches
## no player's body but through the house layer). Only a Throw's body goes under the spawner's path,
## with its stamped row (FlightRow, coop/09).
func _launch(sock: int, woken: bool, motion: Array = []) -> void:
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
	fit(body, _mess.design_of(sock))
	body.physics_material_override = let_go_material(t, woken)
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	if woken:
		body.linear_damp = t.woken_linear_damp
		body.angular_damp = t.woken_angular_damp
	else:
		body.linear_damp = hands.thrown_linear_damp
		body.angular_damp = hands.thrown_angular_damp
	if not launch.is_empty():
		body.linear_velocity = launch["vel"]
		body.angular_velocity = launch["spin"]
	if motion.size() == 3:
		body.linear_velocity = motion[1]
		body.angular_velocity = motion[2]
	var here := _mess.decides()
	if not here:
		body.collision_layer = Mess.LAYER_LOOKS
		body.collision_mask = Mess.LOOKS_MASK
	switch_ccd(body, body.linear_velocity.length(), t)
	if not pair:
		body.inertia = turn_inertia(body.mass, SockDress.box(_mess.design_of(sock)), t.turn_weight)
	# The pose is set before the body enters the tree (m06 backlog: it was set after add_child, so a
	# spawner's copy was made at the holder's origin), in the holder's space.
	var thrown := _mess.is_throw(sock)
	var holder := _mess.flight_holder() if thrown else _mess.bodies_holder()
	var pose: Transform3D = motion[0] if motion.size() == 3 else _mess.pose_of(sock)
	var space := holder as Node3D
	body.transform = space.global_transform.affine_inverse() * pose if space != null and space.is_inside_tree() else pose
	if thrown:
		# coop/09: a Throw's body streams its stamped row to every Guest; the Row and its Sync are there
		# before it enters the tree, so the spawn packet carries the first row.
		FlightRow.attach(body, _mess, true)
	holder.add_child(body, true)
	body.reset_physics_interpolation()
	if not launch.is_empty() and here:
		_spare_thrower(body, int(launch["by"]))
	body.body_entered.connect(_on_contact.bind(sock))
	_flights[sock] = body
	if pair and (launch.is_empty() or dropped):
		_damp_pair(sock)
	if dropped:
		_dropped[sock] = true
	elif not woken:
		_thrown[sock] = true
	_airborne[sock] = 0.0
	_still[sock] = 0.0
	_speeds[sock] = body.linear_velocity.length()


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
	_bounce(sock)
	if _mess.decides():
		_mess.flight_touched.emit(sock, other)


## The sound of a hit: "bounce" at the body, softer and lower the slower it hit.
func _bounce(sock: int) -> void:
	var body: RigidBody3D = _flights.get(sock)
	var t := _mess.bodies_tuning()
	var speed := float(_speeds.get(sock, 0.0))
	if body != null and speed >= t.bounce_speed:
		Sounds.play_at(&"bounce", body.global_position, inverse_lerp(t.bounce_speed, t.bounce_hard_speed, speed))


## A falling Pair drags as a Pair from now on: it stops within a few cm (P07).
func _damp_pair(sock: int) -> void:
	var body: RigidBody3D = _flights.get(sock)
	if body == null:
		return
	var hands := _mess.tuning
	_damped[sock] = true
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.linear_damp = hands.pair_linear_damp
	body.angular_damp = hands.pair_angular_damp


func _drop_flight(sock: int) -> void:
	_flights[sock].queue_free()
	_flights.erase(sock)
	_was.erase(sock)
	_speeds_before.erase(sock)
	_airborne.erase(sock)
	_still.erase(sock)
	_speeds.erase(sock)
	_damped.erase(sock)
	_dropped.erase(sock)
	_thrown.erase(sock)
	_pushes.erase(sock)


## A body at `speed` sweeps its way (continuous collision) from the tuning's `ccd_on` and stops
## sweeping under its `ccd_off`.
static func switch_ccd(body: RigidBody3D, speed: float, t: MessTuning) -> void:
	if speed >= t.ccd_on:
		body.continuous_cd = true
	elif speed < t.ccd_off:
		body.continuous_cd = false


## A falling body's shapes (a Pair's ball) fitted to its Design's Size: a Sock's are the leg and foot
## boxes it lies on (MessBodies.parts_at), so it flies, lands and lies as the same shape, as the old
## game's one set of shapes for both tiers (a Guest's ghost body too, ThrowGhost).
static func fit(body: CollisionObject3D, design: SockDesign) -> void:
	var shape := body.get_node(^"Shape") as CollisionShape3D
	if shape.shape is SphereShape3D:
		var ball := (shape.shape as SphereShape3D).duplicate() as SphereShape3D
		ball.radius = SockDress.ball_radius(design)
		shape.shape = ball
		return
	var parts := MessBodies.parts_at(SockDress.scale_of(design))
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


## The shared material with this friction and bounce (made the first time it is asked for).
## The surface a let-go body has: a woken, poured or dropped one slides (`woken_friction`, no bounce),
## a thrown one bounces (`released_friction`, `released_bounce`, M10). A Guest's Throw or drop ghost
## body has the same, so it bounces as the Host's does (coop/11). One material per pair of numbers.
static func let_go_material(t: MessTuning, woken: bool) -> PhysicsMaterial:
	var key := Vector2(t.woken_friction, 0.0) if woken else Vector2(t.released_friction, t.released_bounce)
	var material: PhysicsMaterial = _materials.get(key)
	if material == null:
		material = PhysicsMaterial.new()
		material.friction = key.x
		material.bounce = key.y
		_materials[key] = material
	return material


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
