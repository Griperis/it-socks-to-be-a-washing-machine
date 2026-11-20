## The heap station's counter sign (core/20, H04): how many Socks move now, how many wait for the
## moving budget (woken ones, and the spout's still to pour), how many of the heap rest, and what a
## physics tick costs. Looks only: it reads the Mess and the spout, never writes. A tick is timed
## from this node's _physics_process (it runs first) to its next _process (it runs first too), so
## the scripts and the physics step are in it (core/13: Godot's TIME_PHYSICS_PROCESS monitor is not).
class_name HeapCounter
extends Label3D

## How many frames a shown tick time averages over.
const WINDOW := 30

@export var mess: Mess
@export var spout: HeapSpout

## The physics ticks timed so far, the average over the last WINDOW frames and the worst since
## reset_timing(), in ms.
var tick_ms := 0.0
var worst_ms := 0.0
## The last frame's tick time, in ms (0 before the first).
var last_ms := 0.0
var _from := -1
var _ticks := 0
var _sum := 0.0
var _frames := 0


func _ready() -> void:
	process_physics_priority = -1000
	process_priority = -1000


## The worst tick is counted again from now.
func reset_timing() -> void:
	worst_ms = 0.0


## The heap's Socks lying now (every record from the spout's first on).
func resting() -> int:
	if mess == null or spout == null or spout.first < 0 or spout.first >= mess.count():
		return 0
	return mess.states.slice(spout.first).count(Mess.State.LYING)


## Socks waiting for the budget: woken ones of the Mess and the spout's still to pour.
func waiting() -> int:
	return (mess.waiting_count() if mess != null else 0) + (spout.pending() if spout != null else 0)


func _physics_process(_delta: float) -> void:
	if _from < 0:
		_from = Time.get_ticks_usec()
	_ticks += 1


func _process(_delta: float) -> void:
	if _from >= 0 and _ticks > 0:
		var each := float(Time.get_ticks_usec() - _from) / 1000.0 / _ticks
		last_ms = each
		worst_ms = maxf(worst_ms, each)
		_sum += each
		_frames += 1
		if _frames >= WINDOW:
			tick_ms = _sum / _frames
			_sum = 0.0
			_frames = 0
	_from = -1
	_ticks = 0
	if Engine.get_process_frames() % 10 == 0:
		text = "Moving %d\nWaiting %d\nResting %d\nTick %.1f ms" % [mess.moving_count() if mess != null else 0,
				waiting(), resting(), tick_ms]
