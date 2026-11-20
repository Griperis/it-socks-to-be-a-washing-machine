## Every loose Sock of the level as one Part (coop-structure section 5): one record a Sock, by id,
## in packed arrays (its Design, its state, its pose). A Sock is LYING (drawn and aimable), HELD (in
## somebody's Hands: the Hands Part says whose) or FLYING (a falling body the Host owns, after a
## drop, a Throw or a wake). The Hands change it with their own answers (a pick, a drop, a throw);
## the Host alone writes a Sock lying again when its body comes to rest or leaves the level's
## bounds (`rest`), and wakes lying Socks a fast body hits (`wake`), both Host-only Commands.
##
## M0.5 draws a lying Sock as one body each (a handful); M3 adds the MultiMesh, the settle stream,
## the wake budget and the bulk snapshot, without changing the records.
class_name Mess
extends Part

enum State { LYING, HELD, FLYING }

## The physics layers (bits): the house and its furniture, a falling Sock, a lying Sock. The
## player's body collides with the house only, so it walks over Socks; the crosshair sees the house
## and lying Socks, never a falling one.
const LAYER_HOUSE := 1
const LAYER_FLIGHT := 2
const LAYER_LYING := 4
const AIM_MASK := LAYER_HOUSE | LAYER_LYING
## Floats in one pose: a Transform3D (basis columns x, y, z, then the origin).
const POSE := 12
## The metadata a lying Sock's body carries: its Sock id.
const SOCK_META := &"sock"
## How near another lying Sock must be to count as touching one (T11).
const TOUCH_MARGIN := 0.01

const LYING_SCENE := preload("res://game/sock/lying_sock.tscn")
const FLIGHT_SCENE := preload("res://game/sock/flight.tscn")

## The Designs a Sock's record names.
@export var catalogue: DesignCatalogue
## The flick before a dropped Sock falls, the settle limit of a fall, a Throw's drag and the wake.
@export var tuning: HandsTuning
## Where the SockSpots placed in the editor are (their children); they become the starting Socks.
@export var spots: Node3D
## Where lying Socks are drawn, and where the Host adds falling ones (a MultiplayerSpawner's
## spawn path in co-op, M0.6).
@export var lying: Node3D
@export var flights: Node3D
## The playable space, in the space of `lying` (the level's or the station's, set per level in the
## editor): a falling body outside it is put down at once at `return_spot` (T14). No volume: no bounds.
@export var bounds := AABB()
## Where a Sock that left `bounds`, or would end inside a wall, is put down lying (T08, T14).
@export var return_spot: Marker3D

@export_group("State")
## Each Sock's Design id, by Sock id.
@export var designs := PackedInt32Array()
## Each Sock's State, by Sock id.
@export var states := PackedByteArray()
## Each Sock's pose in the level (POSE floats a Sock): where it lies, or where it was let go.
@export var poses := PackedFloat32Array()
## The launch of each thrown Sock still in the air: {Sock id: {"vel": Vector3, "spin": Vector3,
## "by": the thrower's player id}}. A dropped or woken Sock has none.
@export var throws := {}
@export_group("")

## The lying Sock bodies drawn now, and the falling ones (the Host's), by Sock id.
var _bodies: Dictionary[int, StaticBody3D] = {}
var _flights: Dictionary[int, RigidBody3D] = {}
## The Host: a dropped Sock's flick time left before its body is let go, and a body's time in the air.
var _flicking: Dictionary[int, float] = {}
var _airborne: Dictionary[int, float] = {}
## The Host: each body's speed before this physics step (what its contacts are judged by), and the
## lying Socks a fast body hit in the step, woken at the next.
var _speeds: Dictionary[int, float] = {}
var _hit: Dictionary[int, bool] = {}


## Before the level binds: the SockSpots become the starting records (as if placed in the
## inspector), and hide. A snapshot (a late Guest, a load) replaces them whole.
func _ready() -> void:
	if spots == null or not designs.is_empty():
		return
	for node in spots.get_children():
		var spot := node as SockSpot
		if spot == null:
			continue
		designs.append(spot.design)
		states.append(State.LYING)
		poses.append_array(pack(spot.global_transform))
		spot.visible = false


## How many Socks there are (every id from 0 to count() - 1).
func count() -> int:
	return designs.size()


func state_of(sock: int) -> State:
	return states[sock] as State if sock >= 0 and sock < states.size() else State.HELD


func design_of(sock: int) -> SockDesign:
	if sock < 0 or sock >= designs.size() or catalogue == null:
		return null
	return catalogue.design(designs[sock])


## Where the Sock lies, or where it was let go, in the level.
func pose_of(sock: int) -> Transform3D:
	return unpack(poses, sock)


## The Sock whose lying body `collider` is (what the crosshair rests on), or -1.
func sock_at(collider: Object) -> int:
	var body := collider as StaticBody3D
	if body == null or not body.has_meta(SOCK_META):
		return -1
	var sock := int(body.get_meta(SOCK_META))
	return sock if _bodies.get(sock) == body and state_of(sock) == State.LYING else -1


## The Looks a lying Sock is drawn with (the outline plays there), or null.
func looks_of(sock: int) -> Node3D:
	var body: StaticBody3D = _bodies.get(sock)
	return body.get_node_or_null(^"Looks") as Node3D if body != null else null


## The falling body of a Sock (the Host's), or null.
func flight_of(sock: int) -> RigidBody3D:
	return _flights.get(sock)


## The change that takes a lying Sock into somebody's Hands (part of the Hands' pick answer).
func held_patch(sock: int) -> Dictionary:
	var s := states.duplicate()
	s[sock] = State.HELD
	return {"states": s, "throws": _without_throw(sock)}


## The change that lets a held Sock go at `pose` (part of the Hands' drop answer): it falls from there.
func flying_patch(sock: int, pose: Transform3D) -> Dictionary:
	var s := states.duplicate()
	s[sock] = State.FLYING
	return {"states": s, "poses": _with_pose(sock, pose), "throws": _without_throw(sock)}


## The change that throws a held Sock (part of the Hands' throw answer): it leaves `pose` at once,
## no flick, with velocity `vel` and turn `spin`, thrown by player `by`.
func thrown_patch(sock: int, pose: Transform3D, vel: Vector3, spin: Vector3, by: int) -> Dictionary:
	var s := states.duplicate()
	s[sock] = State.FLYING
	var t := throws.duplicate()
	t[sock] = {"vel": vel, "spin": spin, "by": by}
	return {"states": s, "poses": _with_pose(sock, pose), "throws": t}


## Only the Host's own `rest` and `wake` (no Guest may send one: nothing in accepts()).
func decide(cmd: Command) -> Dictionary:
	if cmd.by != Parts.HOST:
		return refuse("wrong")
	match cmd.kind:
		&"rest":
			var sock: Variant = cmd.args.get("sock")
			var at: Variant = cmd.args.get("at")
			var rot: Variant = cmd.args.get("rot")
			if not (sock is int) or not (at is Vector3) or not (rot is Vector3) or state_of(sock) != State.FLYING:
				return refuse("wrong")
			var s := states.duplicate()
			s[sock] = State.LYING
			return grant({"states": s, "poses": _with_pose(sock, Transform3D(Basis.from_euler(rot), at)),
					"throws": _without_throw(sock)})
		&"wake":
			var sock: Variant = cmd.args.get("sock")
			if not (sock is int) or state_of(sock) != State.LYING:
				return refuse("wrong")
			var s := states.duplicate()
			for woken in touching(sock) + PackedInt32Array([sock]):
				s[woken] = State.FLYING
			return grant({"states": s})
	return refuse("wrong")


## The lying Socks touching lying Sock `sock`, at most the tuning's wake_count (T11).
func touching(sock: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var most := tuning.wake_count if tuning != null else 8
	var body: StaticBody3D = _bodies.get(sock)
	if body == null or most <= 0:
		return out
	var shape := body.get_node(^"Shape") as CollisionShape3D
	var box := (shape.shape as BoxShape3D).duplicate() as BoxShape3D
	box.size += Vector3.ONE * TOUCH_MARGIN * 2.0
	for collider in PhysicsQueries.overlaps(self, box, shape.global_transform, LAYER_LYING, most + 1):
		var other := sock_at(collider)
		if other >= 0 and other != sock and not out.has(other) and out.size() < most:
			out.append(other)
	return out


## Whether `point` (in the level) is inside the playable space (always, with no bounds).
func in_bounds(point: Vector3) -> bool:
	if not bounds.has_volume():
		return true
	var local := lying.global_transform.affine_inverse() * point if lying != null else point
	return bounds.has_point(local)


## Every Sock is drawn as its record says: lying Socks as bodies, held ones not at all (the Hands
## draw them), a falling one as the Host's body: a dropped one let go after the flick, a thrown or
## woken one (or any when `now`) at once.
func _show(now: bool) -> void:
	var woken: Dictionary[int, bool] = {}
	for sock: int in _bodies.keys():
		if sock >= count() or state_of(sock) != State.LYING:
			_bodies[sock].queue_free()
			_bodies.erase(sock)
			woken[sock] = true
	for sock: int in _flights.keys():
		if sock >= count() or state_of(sock) != State.FLYING:
			_drop_flight(sock)
	for sock: int in _flicking.keys():
		if state_of(sock) != State.FLYING:
			_flicking.erase(sock)
	for sock in count():
		match state_of(sock):
			State.LYING:
				_lie(sock)
			State.FLYING:
				if _is_host() and not _flights.has(sock) and not _flicking.has(sock):
					if now or woken.has(sock) or throws.has(sock) or tuning == null or tuning.flick <= 0.0:
						_launch(sock)
					else:
						_flicking[sock] = tuning.flick


## The Host: wakes the lying Socks a fast body hit (T11), lets flicked Socks go, and writes a fallen
## one lying where its body rests (T13: put down where it is after the settle limit), or at the
## return spot when it left the bounds (T14) or would lie inside a wall (T08).
func _physics_process(delta: float) -> void:
	for sock: int in _hit.keys():
		if state_of(sock) == State.LYING:
			parts.ask(Command.new(&"wake", Parts.HOST, id, {"sock": sock}))
	_hit.clear()
	for sock: int in _flicking.keys():
		_flicking[sock] -= delta
		if _flicking[sock] <= 0.0:
			_flicking.erase(sock)
			_launch(sock)
	for sock: int in _flights.keys():
		var body := _flights[sock]
		_airborne[sock] += delta
		_speeds[sock] = body.linear_velocity.length()
		if not in_bounds(body.global_position):
			_rest(sock, _return_pose(body))
			continue
		var limit := tuning.settle_limit if tuning != null else 6.0
		if (body.sleeping and _airborne[sock] > 0.1) or _airborne[sock] >= limit:
			var t := body.global_transform.orthonormalized()
			var centre := t * (body.get_node(^"Shape") as CollisionShape3D).position
			_rest(sock, _return_pose(body) if PhysicsQueries.inside(self, centre, LAYER_HOUSE) else t)


func _is_host() -> bool:
	return parts == null or parts.is_host()


func _rest(sock: int, t: Transform3D) -> void:
	parts.ask(Command.new(&"rest", Parts.HOST, id, {"sock": sock, "at": t.origin, "rot": t.basis.get_euler()}))


## Where a Sock is put down when it cannot lie where its body is: the return spot, or straight under
## the body with no spot set.
func _return_pose(body: RigidBody3D) -> Transform3D:
	if return_spot != null and return_spot.is_inside_tree():
		return return_spot.global_transform.orthonormalized()
	return Transform3D(Basis.IDENTITY, body.global_position)


## Draws a lying Sock at its pose (a body the crosshair and falling Socks meet).
func _lie(sock: int) -> void:
	var body: StaticBody3D = _bodies.get(sock)
	if body == null:
		body = LYING_SCENE.instantiate() as StaticBody3D
		body.name = "Sock%d" % sock
		body.set_meta(SOCK_META, sock)
		_fit(body, design_of(sock))
		_container(lying).add_child(body)
		_bodies[sock] = body
	body.global_transform = pose_of(sock)
	body.reset_physics_interpolation()


## The Host lets a Sock go: one physical body from its pose, falling, or flying with its throw's
## launch and drag (the thrower's own body does not stop it).
func _launch(sock: int) -> void:
	var body := FLIGHT_SCENE.instantiate() as RigidBody3D
	body.name = "Flight%d" % sock
	_fit(body, design_of(sock))
	var launch: Dictionary = throws.get(sock, {})
	if not launch.is_empty():
		body.linear_velocity = launch["vel"]
		body.angular_velocity = launch["spin"]
		body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		body.linear_damp = tuning.thrown_linear_damp if tuning != null else 0.05
		body.angular_damp = tuning.thrown_angular_damp if tuning != null else 0.8
	_container(flights).add_child(body, true)
	body.global_transform = pose_of(sock)
	body.reset_physics_interpolation()
	if not launch.is_empty():
		_spare_thrower(body, int(launch["by"]))
	body.body_entered.connect(_on_contact.bind(sock))
	_flights[sock] = body
	_airborne[sock] = 0.0
	_speeds[sock] = body.linear_velocity.length()


## The thrower's own body (alone: the local player) lets their thrown Sock through: it leaves from
## inside their reach. A Guest's avatar is M0.6's.
func _spare_thrower(body: RigidBody3D, by: int) -> void:
	for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player != null and player.player_id() == by:
			body.add_collision_exception_with(player)


## The Host: a falling body touched `other`. A lying Sock hit faster than the wake speed wakes, with
## those touching it, at the next physics step (T11): no body is swapped inside the step.
func _on_contact(other: Node, sock: int) -> void:
	var hit := sock_at(other)
	var fast := tuning.wake_speed if tuning != null else 1.5
	if hit >= 0 and float(_speeds.get(sock, 0.0)) > fast:
		_hit[hit] = true


func _drop_flight(sock: int) -> void:
	_flights[sock].queue_free()
	_flights.erase(sock)
	_airborne.erase(sock)
	_speeds.erase(sock)


## A body's box and Looks fitted to its Design (Size and colour).
func _fit(body: CollisionObject3D, design: SockDesign) -> void:
	var shape := body.get_node(^"Shape") as CollisionShape3D
	var box := (shape.shape as BoxShape3D).duplicate() as BoxShape3D
	box.size = SockDress.box(design)
	shape.shape = box
	shape.position.y = box.size.y * 0.5
	var looks := body.get_node(^"Looks") as Node3D
	SockDress.dress(looks, design)
	SockDress.play(looks, SockDress.LYING)


func _container(node: Node3D) -> Node:
	return node if node != null else self


func _without_throw(sock: int) -> Dictionary:
	var t := throws.duplicate()
	t.erase(sock)
	return t


func _with_pose(sock: int, pose: Transform3D) -> PackedFloat32Array:
	var p := poses.duplicate()
	var row := pack(pose)
	for i in POSE:
		p[sock * POSE + i] = row[i]
	return p


## A pose as POSE floats.
static func pack(t: Transform3D) -> PackedFloat32Array:
	var b := t.basis
	return PackedFloat32Array([b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, t.origin.x, t.origin.y, t.origin.z])


## The pose of record `i` in `rows` (POSE floats a record).
static func unpack(rows: PackedFloat32Array, i: int) -> Transform3D:
	var o := i * POSE
	if i < 0 or o + POSE > rows.size():
		return Transform3D.IDENTITY
	return Transform3D(Vector3(rows[o], rows[o + 1], rows[o + 2]), Vector3(rows[o + 3], rows[o + 4], rows[o + 5]),
			Vector3(rows[o + 6], rows[o + 7], rows[o + 8]), Vector3(rows[o + 9], rows[o + 10], rows[o + 11]))
