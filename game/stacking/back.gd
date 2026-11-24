## A player's back (core/41, list 1-8): a flat disc a Teammate can stand on, a child of the player's
## Avatar on every machine. Its origin is its top, `ride_sink` under the top of the body as drawn here,
## crouched or standing at once (lists 2, 3); placed every physics frame before any player moves. It is
## on BACK, a layer only players' bodies meet, and meets nothing itself. It holds no one while its player
## lies down or tops a full stack (lists 4, 6); a player's own body never meets its own back (list 8).
## A plain collider (Q2591): a rider's machine moves the rider's own body on it (PlayerStack).
class_name Back
extends StaticBody3D

## The layer only players' bodies meet (their mask has it; nothing else's does).
const LAYER := 256

@export var tuning: StackingTuning

## The player whose back this is.
var avatar: Avatar
## Whether it holds riders now.
var _on := true

@onready var _shape := $Shape as CollisionShape3D


func _ready() -> void:
	if tuning == null:
		tuning = StackingTuning.new()
	avatar = get_parent() as Avatar
	top_level = true
	collision_layer = LAYER
	collision_mask = 0
	# Before every player's own move (a lower priority runs first), so a rider moves with this frame's back.
	process_physics_priority = -10
	var disc := CylinderShape3D.new()
	disc.radius = tuning.back_radius
	disc.height = tuning.back_thickness
	_shape.shape = disc
	_shape.position = Vector3.DOWN * tuning.back_thickness * 0.5
	place()


func _physics_process(_delta: float) -> void:
	place()


## Stands at the top of its player's back as drawn now, and holds riders or not.
func place() -> void:
	if avatar == null or not is_inside_tree():
		return
	var at := Transform3D(Basis.IDENTITY, Stacks.back_top(avatar, tuning))
	global_transform = at
	# The node tells the physics server only at the next flush of transforms; a rider moving this tick
	# must already meet the disc where it is now.
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, at)
	var on := Stacks.holds(avatar, Stacks.peers(avatar), tuning)
	if on != _on:
		_on = on
		_shape.set_deferred(&"disabled", not on)  # a rider lets go now (holds()), the shape at the flush


## Whether it holds riders now.
func holds() -> bool:
	return _on


## The top of the disc.
func top() -> Vector3:
	return global_position
