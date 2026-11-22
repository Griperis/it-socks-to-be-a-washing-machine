## Spike coop/02 (throwaway, tests only): a stand-in for the avatar's 4 bones (Root, Spine0-2) as a
## Godot physical-bone ragdoll, simulated by the Host and shown on a Guest.
## `Ragdoll` (Skeleton3D, PhysicalBoneSimulator3D, 4 PhysicalBone3D) is the Host's hidden helper; a Guest
## frees it. `Body` (Skeleton3D, same bones) is what a player would see: the Host copies the ragdoll's
## pose into it each physics tick. Two ways the pose reaches a Guest, one per instance (`sync_mode`):
## BONES, a MultiplayerSynchronizer on Body's own bone poses (the engine writes them, no easing);
## STAMPED, one PackedByteArray `pose` (a stamp, then per bone 20 bytes: position 3 x float32,
## rotation 4 x float16), which the Guest eases towards at EASE per second, as the old game did.
## Numbers are the old game's (docs/migration/m06-lists/04-knockdown.md "Numbers"); a spike has no Resource.
extends Node3D

enum Sync { BONES, STAMPED }

## Top of the body push: a bone moves at PUSH_SPEED times its height over TOP (old ragdoll.gd:160).
const PUSH_SPEED := 3.0
const TOP := 1.7
## The Guest's easing towards the newest stamped pose, per second (old ragdoll.gd:49).
const EASE := 12.0
const BONE_COUNT := 4
const BONE_BYTES := 20

## Which sync this instance uses; set before it enters the tree, the same on every machine.
var sync_mode: Sync = Sync.BONES
## True on the Host (it simulates); false on a Guest (it only shows). Set before it enters the tree.
var is_host := true
## The stamped pose (STAMPED): written by the Host, synchronized, decoded by the Guest.
@export var pose: PackedByteArray:
	set = _set_pose
## Whether the Host's ragdoll is simulating.
var simulating := false
## The Guest's newest pose target per bone (Body skeleton pose space) and its stamp.
var _target: Array[Transform3D] = []
var _stamp := -1
var _tick := 0

@onready var ragdoll: Skeleton3D = $Ragdoll
@onready var simulator: PhysicalBoneSimulator3D = $Ragdoll/Simulator
@onready var body: Skeleton3D = $Body


func _ready() -> void:
	if sync_mode == Sync.BONES:
		$StampedSync.free()
	else:
		$BonesSync.free()
	if not is_host:
		ragdoll.free()
		ragdoll = null
		simulator = null
	for i in BONE_COUNT:
		_target.append(body.get_bone_pose(i))


## The physical bones, in skeleton bone order.
func bones() -> Array[PhysicalBone3D]:
	var out: Array[PhysicalBone3D] = []
	out.resize(BONE_COUNT)
	for c in simulator.get_children():
		var pb := c as PhysicalBone3D
		if pb != null:
			out[pb.get_bone_id()] = pb
	return out


## The Host knocks the ragdoll: simulation starts and each bone is pushed along `push` (a unit
## direction), harder the higher it is, as the old ragdoll did.
func knock(push: Vector3) -> void:
	var all := bones()
	for a in all:
		for b in all:
			if a != b:
				a.add_collision_exception_with(b)
	simulator.physical_bones_start_simulation()
	for pb in all:
		var h := clampf(pb.global_position.y / TOP, 0.0, 1.0)
		pb.apply_central_impulse(push * PUSH_SPEED * h * pb.mass)
	simulating = true


func _physics_process(_delta: float) -> void:
	if not is_host or not simulating:
		return
	_tick += 1
	var bodies := bones()
	var skel_inv := body.global_transform.affine_inverse()
	var globals: Array[Transform3D] = []
	for i in BONE_COUNT:
		var pb := bodies[i]
		var g := skel_inv * (pb.global_transform * pb.body_offset.affine_inverse())
		globals.append(g.orthonormalized())
		var parent := body.get_bone_parent(i)
		var local := globals[i] if parent < 0 else globals[parent].affine_inverse() * globals[i]
		body.set_bone_pose_position(i, local.origin)
		body.set_bone_pose_rotation(i, local.basis.get_rotation_quaternion())
	if sync_mode == Sync.STAMPED:
		pose = encode(_tick, body)


func _process(delta: float) -> void:
	if is_host or sync_mode != Sync.STAMPED or _stamp < 0:
		return
	var k := minf(1.0, EASE * delta)
	for i in BONE_COUNT:
		var now := body.get_bone_pose(i)
		var to := _target[i]
		body.set_bone_pose_position(i, now.origin.lerp(to.origin, k))
		body.set_bone_pose_rotation(i, now.basis.get_rotation_quaternion().slerp(to.basis.get_rotation_quaternion(), k))


## The stamped pose of a skeleton: the stamp (uint32), then per bone its pose position (3 x float32)
## and rotation (4 x float16): 4 + 4 x 20 bytes.
static func encode(stamp: int, skel: Skeleton3D) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(4 + BONE_COUNT * BONE_BYTES)
	out.encode_u32(0, stamp)
	for i in BONE_COUNT:
		var at := 4 + i * BONE_BYTES
		var p := skel.get_bone_pose_position(i)
		var q := skel.get_bone_pose_rotation(i).normalized()
		out.encode_float(at, p.x)
		out.encode_float(at + 4, p.y)
		out.encode_float(at + 8, p.z)
		out.encode_half(at + 12, q.x)
		out.encode_half(at + 14, q.y)
		out.encode_half(at + 16, q.z)
		out.encode_half(at + 18, q.w)
	return out


func _set_pose(value: PackedByteArray) -> void:
	pose = value
	if is_host or _target.size() < BONE_COUNT or value.size() != 4 + BONE_COUNT * BONE_BYTES:
		return
	var stamp := value.decode_u32(0)
	if stamp <= _stamp:
		return
	_stamp = stamp
	for i in BONE_COUNT:
		var at := 4 + i * BONE_BYTES
		var p := Vector3(value.decode_float(at), value.decode_float(at + 4), value.decode_float(at + 8))
		var q := Quaternion(value.decode_half(at + 12), value.decode_half(at + 14),
				value.decode_half(at + 16), value.decode_half(at + 18))
		if not p.is_finite() or not q.is_finite() or q.length_squared() < 0.5:
			continue
		_target[i] = Transform3D(Basis(q.normalized()), p)
