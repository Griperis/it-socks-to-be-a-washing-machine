## A Sock's cloth (core/09, D01-D07; the old ADR-0004): Godot's own SpringBoneSimulator3D on the
## Looks' skeleton, its chain from the leg to the toe, bending with the Sock's own speed and turn as
## the node does by itself (Q2286). This script only switches it and feeds it what it cannot see:
## - which Socks bend: the held ones (the Looks is a child of a HeldView) and the `flying_cap`
##   flying ones (the Looks is a child of a falling body) nearest the camera, ranked once a tick over
##   the GROUP; any other Sock (lying, in a pairing moment, ranked out) is rigid and costs nothing;
## - lying flat: a flying Sock slower than `flat_speed` blends its bend out to the rest pose, the flat
##   pose the Mess draws, so nothing pops when it comes to rest (D04); a Sock switched on blends in
##   from flat, which also hides the node's first tick after a switch;
## - the ground: its Ground plane is put on the surface under a flying Sock each tick (D05, the
##   node's own collision, Q2287); within `ground_room` of it the whole bend straightens, all of it
##   at the surface, so the chain never crumples against it (core/16 P07, Q2366).
## Looks of this machine only: it reads where the Sock is, never the Mess or the Hands.
class_name SockCloth
extends SpringBoneSimulator3D

## Every Sock whose cloth may bend (held or flying): the ranking runs over it.
const GROUP := &"sock_cloth"
## What it is doing: rigid (lying, in a moment, no parent it knows), held in Hands, or flying.
enum Role { RIGID, HELD, FLYING }
## What the ground ray meets: the house and lying Socks (Mess.AIM_MASK), never the falling bodies.
const GROUND_MASK := 1 | 4
## Where the Ground plane waits when nothing is under the Sock.
const FAR := Vector3(0.0, -10000.0, 0.0)

## The numbers (sock_cloth_tuning.tres).
@export var tuning: SockClothTuning

## What it does now, from where its Looks is (set as it enters the tree).
var role := Role.RIGID
## How fast the Sock moved over the last tick, in m/s.
var speed := 0.0
## Whether it may bend now (held, or a flying one ranked in); off, `active` is off.
var ranked := false
## How far over the surface under it a flying Sock is, in m (INF when held or nothing is under it).
var ground_gap := INF

## The physics frame the ranking last ran on, shared by every Sock.
static var _ranked_on := -1

var _last := Vector3.INF
@onready var _ground: SpringBoneCollisionPlane3D = get_node_or_null(^"Ground")


func _enter_tree() -> void:
	role = _role()
	active = false
	influence = 0.0
	ranked = false
	_last = Vector3.INF
	if role == Role.RIGID:
		if is_in_group(GROUP):
			remove_from_group(GROUP)
	else:
		add_to_group(GROUP)
	set_physics_process(role != Role.RIGID)


func _ready() -> void:
	set_physics_process(role != Role.RIGID)
	var skeleton := get_skeleton()
	if skeleton != null:
		skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
	if _ground != null:
		_ground.top_level = true
		_ground.global_transform = Transform3D(Basis.IDENTITY, FAR)
	if tuning == null:
		tuning = SockClothTuning.new()
	set_drag(0, tuning.drag)
	set_stiffness(0, tuning.stiffness)
	set_radius(0, tuning.radius)


func _physics_process(delta: float) -> void:
	if _ranked_on != Engine.get_physics_frames():
		_ranked_on = Engine.get_physics_frames()
		rank(get_tree())
	var at := _at()
	speed = 0.0 if _last == Vector3.INF or delta <= 0.0 else at.distance_to(_last) / delta
	_last = at
	if not ranked:
		active = false
		influence = 0.0
		return
	if not active:
		active = true
		reset()
		influence = 0.0
	var skeleton := get_skeleton()
	var size := skeleton.global_transform.basis.get_scale().x if skeleton != null else 1.0
	set_gravity(0, tuning.gravity * size)
	_place_ground(at)
	var want := 0.0 if role == Role.FLYING and speed < tuning.flat_speed else 1.0
	influence = move_toward(influence, want, delta / maxf(tuning.blend_time, 0.01))
	# Near the ground the whole bend straightens at once (no blend: it must not dip in first).
	influence = minf(influence, ground_room_share(size))


## Switches the cloth of every Sock in `tree`'s GROUP: every held one, and the `flying_cap` flying
## ones nearest the camera (D07). Run once a physics tick, by the first Sock to tick.
static func rank(tree: SceneTree) -> void:
	var flying: Array[SockCloth] = []
	var eye := Vector3.ZERO
	for node in tree.get_nodes_in_group(GROUP):
		var cloth := node as SockCloth
		if cloth == null:
			continue
		if cloth.role == Role.HELD:
			cloth.ranked = true
		elif cloth.role == Role.FLYING:
			flying.append(cloth)
			cloth.ranked = false
	if flying.is_empty():
		return
	var camera := flying[0].get_viewport().get_camera_3d()
	if camera != null:
		eye = camera.global_position
	flying.sort_custom(func(a: SockCloth, b: SockCloth) -> bool:
		return a._at().distance_squared_to(eye) < b._at().distance_squared_to(eye))
	var cap := flying[0].tuning.flying_cap if flying[0].tuning != null else 4
	for i in mini(cap, flying.size()):
		flying[i].ranked = true


## Where the Sock is: its Looks' origin.
func _at() -> Vector3:
	var looks := owner as Node3D
	return looks.global_position if looks != null else (get_skeleton().global_position if get_skeleton() != null else Vector3.ZERO)


## Its role from its Looks' parent: a HeldView's child is held, a falling body's is flying.
func _role() -> Role:
	var looks := owner
	var parent := looks.get_parent() if looks != null else null
	if parent is HeldView:
		return Role.HELD
	if parent is RigidBody3D:
		return Role.FLYING
	return Role.RIGID


## How much of the bend the room over the ground leaves (P07): 1 at `ground_room` (scaled by the
## drawn `size`) or more, down to 0 at the surface.
func ground_room_share(size: float) -> float:
	if ground_gap == INF:
		return 1.0
	return clampf(ground_gap / maxf(tuning.ground_room * size, 0.001), 0.0, 1.0)


## Puts the Ground plane on the first surface under a flying Sock, facing up from it, and notes how
## far over it the Sock is; far away when held or when nothing is under it.
func _place_ground(at: Vector3) -> void:
	ground_gap = INF
	var place := Transform3D(Basis.IDENTITY, FAR)
	if role == Role.FLYING:
		var hit := PhysicsQueries.ray(self, at + Vector3.UP * 0.1, at + Vector3.DOWN * tuning.ground_probe, GROUND_MASK)
		if not hit.is_empty():
			var up := (hit["normal"] as Vector3).normalized()
			var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
			place = Transform3D(Basis(side, up, side.cross(up)), hit["position"])
			ground_gap = maxf((at - (hit["position"] as Vector3)).dot(up), 0.0)
	if _ground != null:
		_ground.global_transform = place
