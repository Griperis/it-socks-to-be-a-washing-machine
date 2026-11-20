## Every loose Sock of the level as one Part (coop-structure section 5): one record a Sock, by id,
## in packed arrays (its Design, its state, its pose). A Sock is LYING (drawn and aimable), HELD (in
## somebody's Hands: the Hands Part says whose) or FLYING (a falling body the Host owns, after a
## drop; core/08 adds the Throw). The Hands change it with their own answers (a pick, a drop); the
## Host alone writes a Sock lying again when its body comes to rest (`rest`, a Host-only Command).
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

const LYING_SCENE := preload("res://game/sock/lying_sock.tscn")
const FLIGHT_SCENE := preload("res://game/sock/flight.tscn")

## The Designs a Sock's record names.
@export var catalogue: DesignCatalogue
## The flick before a dropped Sock falls, and the settle limit of a fall.
@export var tuning: HandsTuning
## Where the SockSpots placed in the editor are (their children); they become the starting Socks.
@export var spots: Node3D
## Where lying Socks are drawn, and where the Host adds falling ones (a MultiplayerSpawner's
## spawn path in co-op, M0.6).
@export var lying: Node3D
@export var flights: Node3D

@export_group("State")
## Each Sock's Design id, by Sock id.
@export var designs := PackedInt32Array()
## Each Sock's State, by Sock id.
@export var states := PackedByteArray()
## Each Sock's pose in the level (POSE floats a Sock): where it lies, or where it was let go.
@export var poses := PackedFloat32Array()
@export_group("")

## The lying Sock bodies drawn now, and the falling ones (the Host's), by Sock id.
var _bodies: Dictionary[int, StaticBody3D] = {}
var _flights: Dictionary[int, RigidBody3D] = {}
## The Host: a dropped Sock's flick time left before its body is let go, and a body's time in the air.
var _flicking: Dictionary[int, float] = {}
var _airborne: Dictionary[int, float] = {}


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
	return {"states": s}


## The change that lets a held Sock go at `pose` (part of the Hands' drop answer): it falls from there.
func flying_patch(sock: int, pose: Transform3D) -> Dictionary:
	var s := states.duplicate()
	s[sock] = State.FLYING
	return {"states": s, "poses": _with_pose(sock, pose)}


## Only the Host's own `rest` (no Guest may send one: nothing in accepts()).
func decide(cmd: Command) -> Dictionary:
	if cmd.kind != &"rest" or cmd.by != Parts.HOST:
		return refuse("wrong")
	var sock: Variant = cmd.args.get("sock")
	var at: Variant = cmd.args.get("at")
	var rot: Variant = cmd.args.get("rot")
	if not (sock is int) or not (at is Vector3) or not (rot is Vector3) or state_of(sock) != State.FLYING:
		return refuse("wrong")
	var s := states.duplicate()
	s[sock] = State.LYING
	return grant({"states": s, "poses": _with_pose(sock, Transform3D(Basis.from_euler(rot), at))})


## Every Sock is drawn as its record says: lying Socks as bodies, held ones not at all (the Hands
## draw them), a falling one as the Host's body, let go after the flick (at once when `now`).
func _show(now: bool) -> void:
	for sock: int in _bodies.keys():
		if sock >= count() or state_of(sock) != State.LYING:
			_bodies[sock].queue_free()
			_bodies.erase(sock)
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
					if now or tuning == null or tuning.flick <= 0.0:
						_launch(sock)
					else:
						_flicking[sock] = tuning.flick


## The Host: lets flicked Socks go, and writes a fallen one lying where its body rests (T13: put
## down where it is after the settle limit).
func _physics_process(delta: float) -> void:
	for sock: int in _flicking.keys():
		_flicking[sock] -= delta
		if _flicking[sock] <= 0.0:
			_flicking.erase(sock)
			_launch(sock)
	for sock: int in _flights.keys():
		var body := _flights[sock]
		_airborne[sock] += delta
		var limit := tuning.settle_limit if tuning != null else 6.0
		if (body.sleeping and _airborne[sock] > 0.1) or _airborne[sock] >= limit:
			var t := body.global_transform.orthonormalized()
			parts.ask(Command.new(&"rest", Parts.HOST, id, {"sock": sock, "at": t.origin, "rot": t.basis.get_euler()}))


func _is_host() -> bool:
	return parts == null or parts.is_host()


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


## The Host lets a dropped Sock go: one physical body from its pose, falling.
func _launch(sock: int) -> void:
	var body := FLIGHT_SCENE.instantiate() as RigidBody3D
	body.name = "Flight%d" % sock
	_fit(body, design_of(sock))
	_container(flights).add_child(body, true)
	body.global_transform = pose_of(sock)
	body.reset_physics_interpolation()
	_flights[sock] = body
	_airborne[sock] = 0.0


func _drop_flight(sock: int) -> void:
	_flights[sock].queue_free()
	_flights.erase(sock)
	_airborne.erase(sock)


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
