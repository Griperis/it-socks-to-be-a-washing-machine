## A Teammate's steps and landing (coop/05, Q2452): a child of their Avatar on every other machine,
## heard at their body with the local player's clips and level, in the world (full up close, fading
## from 3 m to 20 m, muffled behind a shut Door). Read from how the drawn body moves, so nothing more
## is sent: a step every `step_distance` metres walked along the floor (`step_<surface>` by the floor
## under it, as the local Footsteps), `land` when a fall of `land_speed` or more stops. A move over
## `teleport` in one frame is a jump of the pose, not a walk. On the owner's own machine it is silent
## (their own Footsteps play there).
class_name TeammateSteps
extends Node

@export var tuning: FootstepTuning
## A move further than this in one frame (metres) is a jump of the pose, not a walk or a fall.
@export_range(0.1, 10.0, 0.1, "suffix:m") var teleport := 1.0
## Seconds the body's vertical speed is smoothed over.
@export_range(0.005, 1.0, 0.005, "suffix:s") var rise_smooth := 0.05
## A body rising or falling faster than this is in the air: no steps; a fall slower than this has stopped.
@export_range(0.1, 5.0, 0.1, "suffix:m/s") var air_speed := 1.0

## How many steps and landings it played (for the tests).
var steps := 0
var lands := 0

var _body: Avatar
var _last := Vector3.INF
var _stride := 0.0
var _rise := 0.0
var _fall := 0.0


func _ready() -> void:
	_body = get_parent() as Avatar
	if tuning == null:
		tuning = FootstepTuning.new()


func _process(delta: float) -> void:
	if _body == null or delta <= 0.0 or _body.is_multiplayer_authority():
		return
	var at := _body.global_position
	if _last == Vector3.INF or at.distance_to(_last) > teleport:
		_last = at
		_rise = 0.0
		_fall = 0.0
		return
	var moved := at - _last
	_last = at
	_rise = lerpf(_rise, moved.y / delta, 1.0 - exp(-delta / rise_smooth))
	if _rise < -air_speed:
		_fall = maxf(_fall, -_rise)
		return
	if _fall > 0.0:
		if _fall >= tuning.land_speed:
			lands += 1
			Sounds.play_from(&"land", at)
		_fall = 0.0
		_stride = 0.0
	if _rise > air_speed:
		return
	_stride += Vector2(moved.x, moved.z).length()
	if _stride >= tuning.step_distance:
		_stride = fmod(_stride, tuning.step_distance)
		steps += 1
		Sounds.play_from(StringName("step_" + Footsteps.surface_at(_body, at)), at)
