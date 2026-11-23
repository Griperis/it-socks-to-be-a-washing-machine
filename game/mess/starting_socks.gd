## A level's generated starting Socks (core/52, house/09, Q2542): every GeneratedSocks of a Mess, in
## tree order, laid all at once or a slice at a time (step()), the same Socks either way. Every seed is
## picked first; then every generator's places are found ("planned"); then each generator lays its
## Socks, avoiding the lying Socks before it (the SockSpots' and the earlier generators'), and turns
## them into records. When the last is done they all join the Mess at once, lying (Q2523).
class_name StartingSocks
extends RefCounted

var mess: Mess
var _gens: Array[GeneratedSocks] = []
var _jobs: Array[SockLayingJob] = []
## Each finished generator's records, in order.
var _made: Array[Dictionary] = []
## The lying boxes the next generator avoids ([size, middle's transform] each, Mess.lying_boxes()'s order).
var _before: Array[Array] = []
var _planned := 0
var _asked := 0
var _done := false


func _init(of_mess: Mess, gens: Array[GeneratedSocks]) -> void:
	mess = of_mess
	for gen in gens:
		var job := gen.start()
		if job != null:
			_gens.append(gen)
			_jobs.append(job)
			_asked += job.asked()
	_before = mess.lying_boxes()


## Whether every generator's records are made (step()).
func is_done() -> bool:
	return _done


## How far it is (the old loading bar, sock_layout.gd bake_progress): 0 while the places are found,
## 0.1 once they are, then the share of the Socks tried, up to 1.
func progress() -> float:
	if _done:
		return 1.0
	if _planned < _jobs.size():
		return 0.0
	var tried := 0
	for job in _jobs:
		tried += job.tried()
	return 0.1 + 0.9 * float(tried) / float(maxi(1, _asked))


## Works until all is laid or the clock (Time.get_ticks_usec()) passes `until` (below 0: no limit).
## Returns whether every generator's records are made (reveal() then puts them in the Mess).
func step(until: int) -> bool:
	if _done:
		return true
	while _planned < _jobs.size():
		if not _jobs[_planned].plan(until):
			return false
		_planned += 1
		if _past(until):
			return false
	while _made.size() < _jobs.size():
		var job := _jobs[_made.size()]
		if not job.lay(_before, until) or not job.records(mess.catalogue, until):
			return false
		_made.append(job.made)
		_before.append_array(_boxes(job.made))
		if _made.size() < _jobs.size() and _past(until):
			return false
	_done = true
	return true


## Once done: every generator's records join the Mess, in order.
func reveal() -> void:
	for k in _gens.size():
		mess.add_generated(_gens[k], _made[k])


## The lying boxes of a generator's records, as Mess.lying_boxes() makes them.
func _boxes(made: Dictionary) -> Array[Array]:
	var out: Array[Array] = []
	var designs: PackedInt32Array = made["designs"]
	var poses: PackedFloat32Array = made["poses"]
	for i in designs.size():
		var size := SockDress.box(mess.catalogue.design(designs[i]) if mess.catalogue != null else null)
		out.append([size, Mess.unpack(poses, i) * Transform3D(Basis.IDENTITY, Vector3(0.0, size.y * 0.5, 0.0))])
	return out


static func _past(until: int) -> bool:
	return until >= 0 and Time.get_ticks_usec() >= until
