## What the washing machine notices (docs/architecture/washer.md "The entity"): the triggers it asks its
## Part for a comment with. Looks only: it decides nothing, it only asks `talk` (the Host decides).
##   stare: on every machine, for its own player: the local camera on the machine's middle for
##          `stare_seconds`, within `stare_range` and `stare_degrees`; once per look (look away and back
##          for another chance).
##   progress, hit, idle: on the Host only, from the answers of the level's Parts: a Pair shelved, a
##          thrown thing landing within `hit_radius` of the machine on the floor plane, and
##          `idle_seconds` since the last Pair was shelved (checked once a second, only when a comment
##          could be given).
## Nothing at the run's last Pair (Q1413). Off while the level is not a staged run
## (`Washer.senses_on()`).
class_name WasherSenses
extends Node

const STARE := &"washer_stare"
const PROGRESS := &"washer_progress"
const HIT := &"washer_hit"
const IDLE := &"washer_idle"

@export var washer: Washer
@export var tuning: WasherTuning

## Seconds the local camera has looked at the machine, and whether this look has asked already.
var _stare := 0.0
var _asked := false
var _idle := 0.0
var _second := 0.0
var _parts: Parts = null


func _process(delta: float) -> void:
	if washer == null or tuning == null or washer.parts == null:
		return
	_listen()
	if not washer.senses_on():
		_stare = 0.0
		_asked = false
		return
	_look(delta)
	if washer.parts.is_host():
		_idle += delta
		_second += delta
		if _second >= 1.0:
			_second = 0.0
			if _idle >= tuning.idle_seconds and washer.could_speak():
				_idle = 0.0  # the quiet spell starts again
				_ask(IDLE)


## Whether the local camera looks at the machine's middle from where it stands.
func staring_now() -> bool:
	var camera := get_viewport().get_camera_3d()
	var thing := washer.get_parent() as Node3D
	if camera == null or thing == null:
		return false
	var middle := thing.global_position + Vector3.UP * tuning.stare_up
	var to := middle - camera.global_position
	if to.length() > tuning.stare_range or to.length() < 0.001:
		return false
	return rad_to_deg((-camera.global_basis.z).angle_to(to)) <= tuning.stare_degrees


func _look(delta: float) -> void:
	if staring_now():
		_stare += delta
		if _stare >= tuning.stare_seconds and not _asked:
			_asked = true
			_ask(STARE)
	else:
		_stare = 0.0
		_asked = false


## The Host hears the level's answers (the Part's own answers, once).
func _listen() -> void:
	if _parts == washer.parts or not washer.parts.is_host():
		return
	_parts = washer.parts
	_parts.applied.connect(_heard)


func _heard(ev: Dictionary) -> void:
	if not washer.senses_on() or not ev.get("ok", false):
		return
	var kind: StringName = ev.get("kind", &"")
	if kind == &"shelve" or kind == &"thrown_shelve":
		_idle = 0.0
		if not _is_last_pair():
			_ask(PROGRESS)
	elif kind == &"rest":
		var part := _parts.of(StringName(ev.get("to", "")))
		if part is Mess and _landed_near(part as Mess, ev):
			_ask(HIT)


## The run's last Pair went in: the last Stage's bar is full (Q1413).
func _is_last_pair() -> bool:
	return washer.last_pair_in()


func _landed_near(mess: Mess, ev: Dictionary) -> bool:
	var rows: Variant = (ev.get("changes", {}) as Dictionary).get(mess.id, {}).get(Mess.ROWS)
	if not (rows is PackedInt32Array):
		return false
	var points := PackedVector3Array()
	for sock: int in rows:
		points.append(mess.pose_of(sock).origin)
	return landed_near(points)


## Whether any of the points `points` (where things came to rest) is within `hit_radius` of the machine on
## the floor plane.
func landed_near(points: PackedVector3Array) -> bool:
	var thing := washer.get_parent() as Node3D
	if thing == null:
		return false
	var here := Vector2(thing.global_position.x, thing.global_position.z)
	for at in points:
		if Vector2(at.x, at.z).distance_to(here) <= tuning.hit_radius:
			return true
	return false


func _ask(trigger: StringName) -> void:
	washer.parts.ask(Command.new(Washer.TALK, multiplayer.get_unique_id(), washer.id, {"trigger": String(trigger)}))
