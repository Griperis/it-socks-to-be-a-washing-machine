## A plain first-person walker for graybox levels and the zoo. The move_* actions walk, the mouse
## looks (a click captures it, ui_cancel lets it go), jump jumps, and interact uses the Part the
## crosshair is on, through Parts like any player's input: alone this player is the Host of one.
## A Carriable it picked is carried in its hands once the pick is granted, and interact puts it down.
## In co-op it is the local player: Avatars copies its body to the others. It stands in until the
## game has its own player.
class_name Player
extends CharacterBody3D

## The input actions it reads (project.godot [input]), named once: a misspelt one is one line to fix.
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_FORWARD := &"move_forward"
const MOVE_BACK := &"move_back"
const JUMP := &"jump"
const CROUCH := &"crouch"
const LOOK_LEFT := &"look_left"
const LOOK_RIGHT := &"look_right"
const LOOK_UP := &"look_up"
const LOOK_DOWN := &"look_down"
const INTERACT := &"interact"
const LET_MOUSE_GO := &"ui_cancel"
## Where the hands hold a carried thing, from the feet: up, and ahead (-Z).
const HANDS := Vector3(0.0, 0.6, -1.0)

@export var tuning: MoveTuning

@onready var _head: Node3D = %Head
@onready var _camera: Camera3D = %Camera
@onready var _shape: CollisionShape3D = %Shape
@onready var _mesh: MeshInstance3D = %Mesh
@onready var _aim: RayCast3D = %Aim

## The Carriable this player asked to pick: carried while it is the holder.
var _held: Carriable = null
## True while a menu has the player's input (set_input_blocked()).
var _input_blocked := false
## True while this player has the mouse captured (L03): the look turns only then. Kept here as well as
## in Input.mouse_mode, which a headless run does not hold.
var _captured := false
## True while crouched (C01).
var crouching := false


func _ready() -> void:
	_aim.add_exception(self)
	# Each body sizes its own capsule: the scene's shapes are shared between instances.
	_shape.shape = _shape.shape.duplicate()
	_mesh.mesh = _mesh.mesh.duplicate()
	_camera.fov = tuning.fov
	_apply_height(tuning.stand_height)
	_camera.global_transform = Transform3D(_head.global_basis, _head.global_position)
	add_to_group(&"local_input")


## A menu over the game (the pause template tells the group `local_input`): while blocked the
## player reads no walk, jump, look or use input; it still falls and still carries what it holds.
func set_input_blocked(on: bool) -> void:
	_input_blocked = on


func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return
	if event is InputEventMouseButton and event.is_pressed() and not _captured:
		_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(LET_MOUSE_GO):
		_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and _captured:
		var motion := event as InputEventMouseMotion
		var step := tuning.look_sensitivity * tuning.look_scale
		_turn(-motion.relative.x * step, -motion.relative.y * step * (-1.0 if tuning.invert_y else 1.0))


## Turns the body sideways by `yaw` and tilts the head by `pitch` (radians), the tilt kept to the limit.
func _turn(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	var limit := deg_to_rad(tuning.pitch_limit)
	_head.rotation.x = clampf(_head.rotation.x + pitch, -limit, limit)


func _physics_process(delta: float) -> void:
	var walk := Vector2.ZERO if _input_blocked else Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK)
	_update_crouch(not _input_blocked and Input.is_action_pressed(CROUCH))
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	elif not _input_blocked and not crouching and Input.is_action_just_pressed(JUMP):
		velocity.y = tuning.jump_speed
	var pace := tuning.walk_speed * (tuning.crouch_speed_factor if crouching else 1.0)
	var direction := global_basis * Vector3(walk.x, 0.0, walk.y)
	velocity.x = direction.x * pace
	velocity.z = direction.z * pace
	move_and_slide()
	if not _input_blocked and Input.is_action_just_pressed(INTERACT):
		interact()
	_carry()


## C01, C02: down at once; up only when the crouched body could move up into the standing height.
func _update_crouch(want: bool) -> void:
	if not want and crouching and test_move(global_transform, Vector3.UP * (tuning.stand_height - tuning.crouch_height)):
		want = true
	if want != crouching:
		crouching = want
		_apply_height(tuning.crouch_height if crouching else tuning.stand_height)


## Sizes the capsule, its mesh and the eyes for a body `height` tall, the origin at the feet.
func _apply_height(height: float) -> void:
	var capsule := _shape.shape as CapsuleShape3D
	capsule.radius = tuning.radius
	capsule.height = height
	var mesh := _mesh.mesh as CapsuleMesh
	mesh.radius = tuning.radius
	mesh.height = height
	_shape.position.y = height * 0.5
	_mesh.position.y = height * 0.5
	_head.position.y = height - tuning.eye_below_top


## L04: the camera is top-level, drawn every frame at the head's interpolated place but turned by the
## look as it is now, so a mouse turn never waits for a physics tick. The right stick turns here too (P01).
func _process(delta: float) -> void:
	if not _input_blocked:
		var stick := Input.get_vector(LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN)
		if stick != Vector2.ZERO:
			var step := deg_to_rad(tuning.pad_look_speed) * delta
			_turn(-stick.x * step, -stick.y * step * (-1.0 if tuning.invert_y else 1.0))
	_camera.global_transform = Transform3D(_head.global_basis, _head.get_global_transform_interpolated().origin)


## What interact does: puts down what it carries, otherwise uses the Part it aims at.
func interact() -> Part:
	var me := multiplayer.get_unique_id()
	if _held != null and _held.holder == me:
		var put := _held
		# Hands let go in the frame they ask to drop: no later move of ours is still in flight.
		_held = null
		var thing := put.get_parent() as Node3D
		var spot := thing.global_position
		spot.y = global_position.y
		var parent := thing.get_parent() as Node3D
		put.drop(me, parent.to_local(spot) if parent != null else spot, wrapf(thing.rotation.y, -PI, PI))
		return put
	return use_aimed()


## The thing it carries, or null: only once its pick is granted.
func carried() -> Carriable:
	return _held if _held != null and _held.holder == multiplayer.get_unique_id() else null


## Uses the Part the crosshair is on, as this player; returns it, or null when it aims at none.
func use_aimed() -> Part:
	_aim.force_raycast_update()
	var part := part_of(_aim.get_collider() as Node)
	if part != null:
		part.use(multiplayer.get_unique_id())
		if part is Carriable:
			_held = part as Carriable
	return part


## Holds the carried thing in the hands. Before the grant nothing moves; someone else's it is not.
func _carry() -> void:
	if _held == null:
		return
	if _held.holder != multiplayer.get_unique_id():
		if _held.holder != 0:
			_held = null
		return
	(_held.get_parent() as Node3D).global_position = global_transform * HANDS


## The Part of the thing `node` belongs to: the first part of the closest entity root above it
## (Parts.part_of(): a direct climb, cheap every frame), or null for the floor.
static func part_of(node: Node) -> Part:
	return Parts.part_of(node)
