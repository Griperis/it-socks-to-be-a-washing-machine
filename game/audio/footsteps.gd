## The sound of a walking body. A child of a CharacterBody3D (the player): a step every
## `step_distance` metres walked on the floor, `step_<surface>` by the floor under it (the floor's
## `surface` metadata, "wood" or "tile", set in the editor on the floor body or a node above it; none
## means wood), and `land` after a fall of `land_speed` or more. Flat: the player's own.
class_name Footsteps
extends Node

## A step was taken: the surface it was heard on.
signal stepped(surface: StringName)
## The body landed after a fall at this speed (m/s, positive).
signal landed(speed: float)

## The metadata name of a floor's surface.
const SURFACE_META := &"surface"
const DEFAULT_SURFACE := &"wood"
## The look for the floor starts this far above the feet and reaches this far below them.
const LOOK_UP := 0.2
const LOOK_DOWN := 0.5

@export var tuning: FootstepTuning

var _body: CharacterBody3D
var _was_on_floor := true
var _fall_speed := 0.0
var _stride := 0.0


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	if tuning == null:
		tuning = FootstepTuning.new()
	_was_on_floor = _body.is_on_floor()


## After the body's own move (a child runs after its parent), once a physics frame.
func _physics_process(delta: float) -> void:
	var on_floor := _body.is_on_floor()
	if on_floor and not _was_on_floor:
		_stride = 0.0
		if _fall_speed >= tuning.land_speed:
			landed.emit(_fall_speed)
			Sounds.play(&"land")
	if on_floor:
		var real := _body.get_real_velocity()
		_stride += Vector2(real.x, real.z).length() * delta
		if _stride >= tuning.step_distance:
			_stride = fmod(_stride, tuning.step_distance)
			var surface := surface_under()
			stepped.emit(surface)
			Sounds.play(StringName("step_" + surface))
	_was_on_floor = on_floor
	_fall_speed = 0.0 if on_floor else maxf(-_body.velocity.y, 0.0)


## The surface of the floor the body stands on: the metadata of the thing a short look straight down
## meets, or of the nodes above it; wood when none says.
func surface_under() -> StringName:
	var from := _body.global_position + Vector3.UP * LOOK_UP
	var hit := PhysicsQueries.ray(_body, from, from + Vector3.DOWN * LOOK_DOWN, Mess.LAYER_HOUSE)
	var node: Node = hit.get("collider") as Node
	while node != null:
		if node.has_meta(SURFACE_META):
			var s := StringName(String(node.get_meta(SURFACE_META)))
			return s if Sounds.has_event(StringName("step_" + s)) else DEFAULT_SURFACE
		node = node.get_parent()
	return DEFAULT_SURFACE
