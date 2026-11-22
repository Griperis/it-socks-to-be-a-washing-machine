## A player's knocked-down body (coop/10, docs/research/coop-ragdoll-sync.md option b): the avatar's four
## bones (Root, Spine0, Spine1, Spine2, Q2438) as Godot's own physical-bone ragdoll, authored in this
## scene (a Skeleton3D, its PhysicalBoneSimulator3D and one PhysicalBone3D a bone, capsules and cone
## joints set in the inspector). It is never drawn: the avatar's Looks copies its pose (motions()).
##
## Who moves it: the Host simulates it (this node's multiplayer authority is the Host, whoever's avatar
## it is in); the Host's pose goes out as one stamped PackedByteArray `pose` (a uint32 stamp, then per
## bone its world position as 3 floats and its turn as 4 half floats: 84 bytes) on the Sync beside it,
## when it changes, at most every 0.05 s. Every other machine eases its bones toward the newest pose at
## `ease` a second, the first one snapping, and never simulates; until a pose comes it stands at the
## fall place. Getting up is played by every machine itself (rise()): a smoothstep from the pose it lies
## in to standing at its feet, dropped onto the floor, facing the player's own way.
##
## While standing its bones collide with nothing; down they are on layer LAYER and meet the house,
## the furniture's player boxes, other lying bodies and standing Teammates' Mate capsules, and a
## walking player bumps them (the Player's mask holds LAYER).
class_name Ragdoll
extends Node3D

## The physics layer of a lying body, and of a standing player's Mate capsule (only ragdolls meet it).
const LAYER := 64
const MATE_LAYER := 128
## The bones, and the bytes of one in the stamped pose.
const BONES := 4
const BONE_BYTES := 20
const POSE_BYTES := 4 + BONES * BONE_BYTES

enum Phase { UP, DOWN, RISING }

@export var tuning: KnockdownTuning

## The stamped pose: written by the Host while it simulates, read by every other machine.
@export var pose := PackedByteArray():
	set(value):
		pose = value
		_feed(value)

var phase := Phase.UP
## Whether this machine simulates it now (the Host, while down and not rising).
var simulating := false
## The knock this body is lying from (Knockdowns' serial), 0 while standing.
var serial := 0
## How many poses came, and how many were dropped (malformed, or older than the newest).
var received := 0
var dropped := 0

## Each bone's frame in the world now (its head at the joint, Y along the body).
var _world: Array[Transform3D] = []
## A receiving machine's newest target per bone, its stamp, and whether one came for this knock.
var _target: Array[Transform3D] = []
var _stamp := -1
var _have_pose := false
## A pose came while standing (it may come before the knock's answer): the knock takes it at once.
var _fresh := false
## The Host's stamp counter (it only grows, across knocks).
var _tick := 0
var _rise_from: Array[Transform3D] = []
var _rise_to: Array[Transform3D] = []
var _rise_t := 0.0
var _rise_yaw := 0.0
## The bodies these bones do not collide with now (the own player, a dragger, a Teammate inside it).
var _except: Array[CollisionObject3D] = []
var _bodies: Array[PhysicalBone3D] = []
## Each bone's rest frame in the skeleton (identity turns: heads at 0, 0.45, 0.80, 1.12 m).
var _rest: Array[Transform3D] = []
var _layer := LAYER
var _mask := 0

@onready var bones: Skeleton3D = $Bones
@onready var simulator: PhysicalBoneSimulator3D = $Bones/Simulator


## The Host owns it, whoever's avatar it is in (the Avatar made its whole tree the player's a moment ago).
func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	if tuning == null:
		tuning = KnockdownTuning.new()
	_bodies.resize(BONES)
	for c in simulator.get_children():
		var pb := c as PhysicalBone3D
		if pb != null:
			_bodies[pb.get_bone_id()] = pb
	_layer = _bodies[0].collision_layer
	_mask = _bodies[0].collision_mask
	for a in _bodies:
		for b in _bodies:
			if a != b:
				a.add_collision_exception_with(b)
	for b in BONES:
		_rest.append(bones.get_bone_global_rest(b))
		_world.append(_rest[b])
		_target.append(_rest[b])
	_solid(false)
	_hold_still()


## The physical bones, in bone order.
func bodies() -> Array[PhysicalBone3D]:
	return _bodies


## Whether this machine decides it (the Host, and alone).
func decides() -> bool:
	return is_multiplayer_authority()


## Lies down from knock `p_serial` at `feet` (the player's feet, turned their way). The Host simulates,
## each bone set moving along `push` (unit, along the floor) at push_speed times its height over the top,
## harder the higher it was hit (`high`, 0 to 1), and turning about the up axis by `side` (-1 to 1).
func knock(p_serial: int, feet: Transform3D, push: Vector3, high: float, side: float) -> void:
	serial = p_serial
	phase = Phase.DOWN
	_rise_t = 0.0
	_have_pose = _fresh and not decides()
	_fresh = false
	for b in BONES:
		_world[b] = _target[b] if _have_pose else feet * _rest[b]
		if not _have_pose:
			_target[b] = _world[b]
	_place()
	_solid(true)
	if not decides():
		return
	simulator.physical_bones_start_simulation()
	var kick := 1.0 - tuning.high_kick + 2.0 * tuning.high_kick * clampf(high, 0.0, 1.0)
	for b in BONES:
		var pb := _bodies[b]
		pb.global_transform = _world[b] * pb.body_offset
		var h := clampf((pb.global_position.y - feet.origin.y) / tuning.top, 0.0, 1.0)
		pb.linear_velocity = push * tuning.push_speed * h * kick
		pb.angular_velocity = Vector3.UP * tuning.spin * clampf(side, -1.0, 1.0)
	simulating = true
	_send()


## Starts getting up: the Host stops simulating; every machine blends from the pose it lies in to
## standing over rise_time, at its feet dropped onto the floor, facing `yaw`.
func rise(yaw: float) -> void:
	if phase != Phase.DOWN:
		return
	if simulating:
		_world = motions_raw()
		simulator.physical_bones_stop_simulation()
		simulating = false
		_hold_still()
	_rise_from = _world.duplicate()
	_rise_yaw = yaw
	_rise_to.clear()  # the next physics tick finds the floor under the feet (the space is read there)
	_rise_t = 0.0
	phase = Phase.RISING


## Stands again: collides with nothing, simulates nothing.
func stand() -> void:
	if simulating:
		simulator.physical_bones_stop_simulation()
		simulating = false
		_hold_still()
	phase = Phase.UP
	serial = 0
	_fresh = false
	for b in BONES:
		_world[b] = _rest[b]
	clear_exceptions()
	_solid(false)


## Where the feet are now (the Root bone's head).
func feet() -> Vector3:
	return _world[0].origin


## Where a point `height` up the standing body is now, riding the top bone (the head's top at `top`).
func point_at(height: float) -> Vector3:
	var b := BONES - 1
	while b > 0 and _rest[b].origin.y > height:
		b -= 1
	return _world[b] * Vector3(0.0, height - _rest[b].origin.y, 0.0)


## Each bone's frame in the world as it was last ticked (the physics tick's pose).
func frames() -> Array[Transform3D]:
	return _world


## How each bone moved from standing at the origin to now, as drawn this frame: its frame now times
## its rest's inverse. The Looks places itself by the first and bends by the others.
func motions() -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for b in BONES:
		var t := _world[b]
		if simulating:
			var pb := _bodies[b]
			t = (pb.get_global_transform_interpolated() * pb.body_offset.affine_inverse()).orthonormalized()
		out.append(t * _rest[b].affine_inverse())
	return out


## Each bone's frame from the simulated bodies (Host, simulating), uninterpolated.
func motions_raw() -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for b in BONES:
		var pb := _bodies[b]
		out.append((pb.global_transform * pb.body_offset.affine_inverse()).orthonormalized())
	return out


## The Host, dragging: the feet are pulled toward `to` by a critically damped spring of `strength` (per
## second squared per metre, for the whole body's mass); the rest trails on its joints.
func pull(to: Vector3, strength: float, delta: float) -> void:
	if not simulating:
		return
	var root := _bodies[0]
	var mass := 0.0
	for pb in _bodies:
		mass += pb.mass
	var at := root.global_transform * root.body_offset.affine_inverse()
	var accel := (to - at.origin) * strength - root.linear_velocity * 2.0 * sqrt(strength)
	root.apply_central_impulse(accel * mass * delta)


## These bones and `body` stop colliding (both ways) until remove_exception(), clear_exceptions() or stand().
func except_with(body: CollisionObject3D) -> void:
	if body == null or _except.has(body):
		return
	_except.append(body)
	for pb in _bodies:
		pb.add_collision_exception_with(body)
		var other := body as PhysicsBody3D
		if other != null:
			other.add_collision_exception_with(pb)


func remove_exception(body: CollisionObject3D) -> void:
	if not _except.has(body):
		return
	_except.erase(body)
	if not is_instance_valid(body):
		return
	for pb in _bodies:
		pb.remove_collision_exception_with(body)
		var other := body as PhysicsBody3D
		if other != null:
			other.remove_collision_exception_with(pb)


func clear_exceptions() -> void:
	for body: CollisionObject3D in _except.duplicate():
		remove_exception(body)
	_except.clear()


## Where a body's feet at `at` stand on the floor or stairs under them (read in a physics tick only): a ray from floor_above over to
## floor_below under; `at` itself when it meets nothing.
func floor_under(at: Vector3) -> Vector3:
	if not is_inside_tree():
		return at
	var hit := PhysicsQueries.ray(self, at + Vector3.UP * tuning.floor_above, at + Vector3.DOWN * tuning.floor_below, Mess.LAYER_HOUSE)
	return hit["position"] if not hit.is_empty() else at


func _physics_process(delta: float) -> void:
	match phase:
		Phase.DOWN:
			if simulating:
				_world = motions_raw()
				_send()
			else:
				_place()
		Phase.RISING:
			if _rise_to.is_empty():
				var feet := Transform3D(Basis(Vector3.UP, _rise_yaw), floor_under(_rise_from[0].origin))
				for b in BONES:
					_rise_to.append(feet * _rest[b])
			_rise_t += delta
			var k := smoothstep(0.0, 1.0, _rise_t / maxf(tuning.rise_time, 0.001))
			for b in BONES:
				_world[b] = _rise_from[b].interpolate_with(_rise_to[b], k)
			_place()


## A receiving machine eases toward the newest pose (the first one snaps).
func _process(delta: float) -> void:
	if phase != Phase.DOWN or simulating or not _have_pose:
		return
	var k := minf(1.0, tuning.ease * delta)
	for b in BONES:
		var q := _world[b].basis.get_rotation_quaternion().slerp(_target[b].basis.get_rotation_quaternion(), k)
		_world[b] = Transform3D(Basis(q), _world[b].origin.lerp(_target[b].origin, k))


## The Host: the pose as it is, stamped.
func _send() -> void:
	_tick += 1
	pose = encode(_tick, _world)


## A not simulating body's bones and bodies stand where _world says (they block walkers there too).
func _place() -> void:
	for b in BONES:
		var parent := bones.get_bone_parent(b)
		var local := _world[b] if parent < 0 else _world[parent].affine_inverse() * _world[b]
		bones.set_bone_pose_position(b, local.origin)
		bones.set_bone_pose_rotation(b, local.basis.get_rotation_quaternion())
		_bodies[b].global_transform = _world[b] * _bodies[b].body_offset


## A body not simulated here is kinematic: it stands where _place() puts it and blocks walkers there
## (a PhysicalBone3D outside the simulation would otherwise fall on its own).
func _hold_still() -> void:
	for pb in _bodies:
		PhysicsServer3D.body_set_mode(pb.get_rid(), PhysicsServer3D.BODY_MODE_KINEMATIC)


func _solid(on: bool) -> void:
	for pb in _bodies:
		pb.collision_layer = _layer if on else 0
		pb.collision_mask = _mask if on else 0


## The stamped pose of four world frames: a uint32 stamp, then per frame 3 x float32 and 4 x float16.
static func encode(stamp: int, frames_now: Array[Transform3D]) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(POSE_BYTES)
	out.encode_u32(0, stamp)
	for b in BONES:
		var at := 4 + b * BONE_BYTES
		var p := frames_now[b].origin
		var q := frames_now[b].basis.get_rotation_quaternion().normalized()
		out.encode_float(at, p.x)
		out.encode_float(at + 4, p.y)
		out.encode_float(at + 8, p.z)
		out.encode_half(at + 12, q.x)
		out.encode_half(at + 14, q.y)
		out.encode_half(at + 16, q.z)
		out.encode_half(at + 18, q.w)
	return out


## A receiving machine's newest pose: a wrong size, a value not finite or an older stamp is dropped.
func _feed(value: PackedByteArray) -> void:
	if not is_inside_tree() or decides() or _target.size() < BONES:
		return
	received += 1
	if value.size() != POSE_BYTES:
		dropped += 1
		return
	var stamp := int(value.decode_u32(0))
	if stamp <= _stamp:
		dropped += 1
		return
	var frames_in: Array[Transform3D] = []
	for b in BONES:
		var at := 4 + b * BONE_BYTES
		var p := Vector3(value.decode_float(at), value.decode_float(at + 4), value.decode_float(at + 8))
		var q := Quaternion(value.decode_half(at + 12), value.decode_half(at + 14), value.decode_half(at + 16), value.decode_half(at + 18))
		if not p.is_finite() or not q.is_finite() or q.length_squared() < 0.5:
			dropped += 1
			return
		frames_in.append(Transform3D(Basis(q.normalized()), p))
	_stamp = stamp
	_target = frames_in
	if phase == Phase.UP:
		_fresh = true
	elif phase == Phase.DOWN and not _have_pose:
		_have_pose = true
		_world = _target.duplicate()


## A late joiner: the pose the Host's snapshot carried, taken at once.
func take(value: PackedByteArray) -> void:
	_stamp = -1
	_feed(value)
