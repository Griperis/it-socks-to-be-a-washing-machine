## Test support for the coop/01 spike (Option A, "A-with-stamp"): one stamped row per falling body,
## carried by a MultiplayerSynchronizer beside it. The test adds this node (named "Row") and the
## synchronizer to every Flight body as it enters `Flights`, on the Host and on the Guest, standing in
## for what flight.tscn would hold if A is chosen.
## Host: `row` is read live from the body: [position, rotation, linear velocity, the Host's clock].
## Guest: each row that arrives is kept; every tick the body (frozen, kinematic) is put where the rows
## say it was DELAY seconds ago on the Host's clock, mapped onto this machine's by the smallest
## difference seen so far (the one-way delay); past the newest row it goes on along the velocity for
## at most EXTRAPOLATE seconds.
extends Node

## How far behind the Host's clock a Guest plays (the old flight.gd's 0.1 s).
const DELAY := 0.1
const EXTRAPOLATE := 0.1

## The smallest (this machine's clock - the Host's stamp) seen in any row: the one-way delay
## estimate, shared by every body on this machine. The test sets it back to INF before each case.
static var offset := INF

var host_side := false
## How many rows arrived, and how many came out of order (and were dropped).
var received := 0
var stale := 0
## Rows kept, oldest first: [clock, position, rotation, velocity].
var _rows: Array[Array] = []

## What the synchronizer carries. Read on the Host, written on a Guest.
var row: Array:
	get:
		var body := get_parent() as RigidBody3D
		if body == null:
			return []
		return [body.global_position, body.global_basis.get_rotation_quaternion(), body.linear_velocity, clock()]
	set(value):
		_feed(value)


## The clock rows are stamped with and played against: physics ticks as seconds.
static func clock() -> float:
	return float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second)


func _feed(value: Array) -> void:
	if host_side or value.size() != 4:
		return
	received += 1
	var stamp := float(value[3])
	if not _rows.is_empty() and stamp <= float(_rows[-1][0]):
		stale += 1
		return
	offset = minf(offset, clock() - stamp)
	_rows.append([stamp, value[0], value[1], value[2]])
	if is_inside_tree() and _rows.size() == 1:
		_show()


func _physics_process(_delta: float) -> void:
	if not host_side:
		_show()


func _show() -> void:
	var body := get_parent() as Node3D
	if body == null or _rows.is_empty():
		return
	var at := clock() - offset - DELAY
	while _rows.size() > 2 and float(_rows[1][0]) <= at:
		_rows.pop_front()
	var a: Array = _rows[0]
	var pos: Vector3 = a[1]
	var rot: Quaternion = a[2]
	if _rows.size() > 1 and at > float(a[0]):
		var b: Array = _rows[1]
		if at <= float(b[0]):
			var w := (at - float(a[0])) / (float(b[0]) - float(a[0]))
			pos = (a[1] as Vector3).lerp(b[1], w)
			rot = (a[2] as Quaternion).slerp(b[2], w)
		else:
			pos = (b[1] as Vector3) + (b[3] as Vector3) * minf(at - float(b[0]), EXTRAPOLATE)
			rot = b[2]
	elif _rows.size() == 1 and at > float(a[0]):
		pos += (a[3] as Vector3) * minf(at - float(a[0]), EXTRAPOLATE)
	body.global_transform = Transform3D(Basis(rot), pos)
