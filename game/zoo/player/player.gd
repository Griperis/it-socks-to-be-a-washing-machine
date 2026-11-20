## A plain first-person walker for graybox levels and the zoo. The move_* actions walk, the mouse
## looks (a click captures it, ui_cancel lets it go), jump jumps, and interact uses the Part the
## crosshair is on, through Parts like any player's input: alone this player is the Host of one.
## A Carriable it picked is carried in its hands once the pick is granted, and interact puts it down.
## In co-op it is the local player: Avatars copies its body to the others. It stands in until the
## game has its own player.
class_name GrayboxPlayer
extends CharacterBody3D

const HEAD_PITCH_MAX := 1.4
## The input actions it reads (project.godot [input]), named once: a misspelt one is one line to fix.
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_FORWARD := &"move_forward"
const MOVE_BACK := &"move_back"
const JUMP := &"jump"
const INTERACT := &"interact"
const LET_MOUSE_GO := &"ui_cancel"
## Where the hands hold a carried thing, from the feet: up, and ahead (-Z).
const HANDS := Vector3(0.0, 0.6, -1.0)

@export var tuning: WalkTuning

@onready var _head: Node3D = %Head
@onready var _aim: RayCast3D = %Aim

## The Carriable this player asked to pick: carried while it is the holder.
var _held: Carriable = null
## True while a menu has the player's input (set_input_blocked()).
var _input_blocked := false


func _ready() -> void:
	_aim.add_exception(self)
	add_to_group(&"local_input")


## A menu over the game (the pause template tells the group `local_input`): while blocked the
## player reads no walk, jump, look or use input; it still falls and still carries what it holds.
func set_input_blocked(on: bool) -> void:
	_input_blocked = on


func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return
	if event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(LET_MOUSE_GO):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * tuning.look_sensitivity)
		_head.rotation.x = clampf(_head.rotation.x - motion.relative.y * tuning.look_sensitivity,
				-HEAD_PITCH_MAX, HEAD_PITCH_MAX)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif not _input_blocked and Input.is_action_just_pressed(JUMP):
		velocity.y = tuning.jump_speed
	var input := Vector2.ZERO if _input_blocked else Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK)
	var direction := global_basis * Vector3(input.x, 0.0, input.y)
	velocity.x = direction.x * tuning.walk_speed
	velocity.z = direction.z * tuning.walk_speed
	move_and_slide()
	if not _input_blocked and Input.is_action_just_pressed(INTERACT):
		interact()
	_carry()


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
