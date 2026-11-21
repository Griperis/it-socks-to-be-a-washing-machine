## The Mess benchmark's clock (core/31, B1): what one physics tick and one frame's scripts cost.
## A tick is timed from one `physics_frame` to the next inside the same frame, so it holds every
## script's _physics_process, the physics step and its callbacks, and nothing of drawing or of the
## wait for the screen; the benchmark runs several ticks a frame for that (`--fixed-fps 10`).
## Godot's own TIME_PHYSICS_PROCESS monitor is not a tick's cost (docs/architecture/mess.md).
## A frame's scripts are timed from `process_frame` to this node's own _process, the last to run.
class_name MessBenchClock
extends Node

## Its own look is taken off each tick.
var watch: MessWatch

var _ticks := PackedFloat32Array()
var _frames := PackedFloat32Array()
var _walls := PackedFloat32Array()
var _scripts := PackedFloat32Array()
var _last_tick := -1
var _last_tick_frame := -1
var _frame_from := -1
var _last_frame := -1


func _ready() -> void:
	process_priority = 100000
	process_physics_priority = 100000
	get_tree().physics_frame.connect(_on_tick)
	get_tree().process_frame.connect(_on_frame)


## Measures again from nothing.
func restart() -> void:
	_ticks = PackedFloat32Array()
	_frames = PackedFloat32Array()
	_walls = PackedFloat32Array()
	_scripts = PackedFloat32Array()
	_last_tick = -1


func _on_tick() -> void:
	var now := Time.get_ticks_usec()
	var frame := Engine.get_process_frames()
	if _last_tick >= 0 and frame == _last_tick_frame:
		var own := watch.own_usec if watch != null else 0
		_ticks.append(maxf(float(now - _last_tick - own), 0.0) / 1000.0)
	_last_tick = now
	_last_tick_frame = frame


func _on_frame() -> void:
	var now := Time.get_ticks_usec()
	if _last_frame >= 0:
		_walls.append(float(now - _last_frame) / 1000.0)
	_last_frame = now
	_frame_from = now


## The last node to tick: from the tick's start to here is every script's _physics_process.
func _physics_process(_delta: float) -> void:
	if _last_tick >= 0:
		var own := watch.own_usec if watch != null else 0
		_scripts.append(maxf(float(Time.get_ticks_usec() - _last_tick - own), 0.0) / 1000.0)


func _process(_delta: float) -> void:
	if _frame_from >= 0:
		_frames.append(float(Time.get_ticks_usec() - _frame_from) / 1000.0)


## How many ticks were timed.
func tick_count() -> int:
	return _ticks.size()


## A tick's cost in ms: [median, 95th percentile, worst].
func tick_ms() -> Array[float]:
	return _stats(_ticks)


## The scripts' share of a tick (every _physics_process; the rest is the physics step and its
## callbacks), in ms: [median, 95th percentile, worst].
func script_ms() -> Array[float]:
	return _stats(_scripts)


## The scripts of one frame (every _process), in ms: [median, 95th percentile, worst].
func frame_ms() -> Array[float]:
	return _stats(_frames)


## One whole frame from start to start, drawing and its ticks included, in ms: [median, 95th
## percentile, worst]. Only a windowed run on a real graphics card says anything with it.
func wall_ms() -> Array[float]:
	return _stats(_walls)


static func _stats(samples: PackedFloat32Array) -> Array[float]:
	if samples.is_empty():
		return [0.0, 0.0, 0.0]
	var sorted := samples.duplicate()
	sorted.sort()
	var last := sorted.size() - 1
	return [sorted[last / 2], sorted[mini(last, int(ceil(last * 0.95)))], sorted[last]]
