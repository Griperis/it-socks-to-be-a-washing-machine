## The stamped stream of one thrown body (coop/09, coop/01 Option A, docs/research/coop-flight-sync.md):
## a child "Row" of a Throw's body, beside the MultiplayerSynchronizer "Sync" that carries `row` from
## the Host to every Guest every network frame, unreliably. A late joiner gets the row with the spawn,
## so a Throw in the air flies on from where it is (Q2472).
##
## Host: `row` is read live from the body: [position, rotation, velocity, spin, the Host's tick].
## Guest: each row that comes is kept (an older one than the newest is dropped, H02); every tick the
## body (frozen, kinematic: it never simulates there) is put where the rows say it was `stream_lag`
## behind on the Host's clock, mapped onto this machine's by the smallest difference seen so far (the
## one-way delay, kept by the Mess for every body); past the newest row it goes on along the velocity
## for at most `stream_extrapolate`. A Guest's own Throw ghost (GuestGhosts) samples the same rows at a
## moment of the flight (flight_time(), sample()). A Guest hears the copy's bounces (H07, M04): a row
## whose velocity turned by more than gravity and drag explain is a hit, heard as "bounce" where the
## copy is drawn when its moment is played, softer the slower it hit (as MessMoving._bounce).
class_name FlightRow
extends Node

## The node names on the body.
const NAME := "Row"
const SYNC := "Sync"
## The rows kept on a Guest (the old flight.gd's 90).
const KEEP := 90

## The Mess the body is of: its clock offset and its numbers. Set before the body enters the tree.
var mess: Mess
## Whether this machine decides (the Host, or alone): the row is read here, never fed.
var host_side := true
## How many rows came, how many came out of order and were dropped, and how many hits were heard.
var received := 0
var stale := 0
var heard := 0
## Rows kept, oldest first: [tick, position, rotation, velocity, spin].
var _rows: Array[Array] = []
## The Host's tick whose row shows the body's launch pose, its first step not yet seen (coop/11): sent
## once, with the spawn. A row stamped N shows the body as the step before tick N left it, so a body
## let go outside a physics tick still shows its launch pose at the tick after; counting the flight
## from the first row's stamp put the Host's flight a step ahead of the thrower's ghost. -1 before.
var born := -1.0
## The Host's tick of the first row seen: the flight's start on the Host's clock when no `born` came.
var _first := -1.0
## The Host's tick the body was last put at (flight_time()).
var _played := -1.0
## The hits seen in the rows, not heard yet: [Host tick, speed before the hit].
var _hits: Array[Array] = []

## What the synchronizer carries. Read on the Host, written on a Guest.
var row: Array:
	get:
		var body := get_parent() as RigidBody3D
		if body == null or not body.is_inside_tree():
			return []
		return [body.global_position, body.global_basis.get_rotation_quaternion(), body.linear_velocity,
				body.angular_velocity, tick()]
	set(value):
		_feed(value)


## The body `body` streams from the Host: its Row and its Sync, added before it enters the tree on
## the Host (so the spawn packet holds the first row) and as it enters on a Guest (the spawner's copy).
static func attach(body: RigidBody3D, p_mess: Mess, p_host_side: bool) -> FlightRow:
	var existing := body.get_node_or_null(NAME) as FlightRow
	if existing != null:
		return existing
	var r := FlightRow.new()
	r.name = NAME
	r.mess = p_mess
	r.host_side = p_host_side
	if p_host_side:
		r.born = tick() + (0.0 if Engine.is_in_physics_frame() else 1.0)
	body.add_child(r)
	var sync := MultiplayerSynchronizer.new()
	sync.name = SYNC
	var config := SceneReplicationConfig.new()
	var path := NodePath("%s:row" % NAME)
	config.add_property(path)
	config.property_set_spawn(path, true)
	config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var born_path := NodePath("%s:born" % NAME)
	config.add_property(born_path)
	config.property_set_spawn(born_path, true)
	config.property_set_replication_mode(born_path, SceneReplicationConfig.REPLICATION_MODE_NEVER)
	sync.replication_config = config
	sync.replication_interval = 0.0
	body.add_child(sync)
	return r


## The row of `body`, or null for a body that does not stream.
static func of(body: Node) -> FlightRow:
	return body.get_node_or_null(NAME) as FlightRow if body != null else null


## The clock rows are stamped with and played against: this machine's physics ticks.
static func tick() -> float:
	return float(Engine.get_physics_frames())


static func _tps() -> float:
	return float(Engine.physics_ticks_per_second)


func _feed(value: Variant) -> void:
	if host_side or not (value is Array) or (value as Array).size() != 5:
		return
	var v: Array = value
	if not (v[0] is Vector3) or not (v[1] is Quaternion) or not (v[2] is Vector3) or not (v[3] is Vector3) \
			or not (v[4] is float or v[4] is int):
		return
	if not (v[0] as Vector3).is_finite() or not (v[1] as Quaternion).is_finite():
		return
	received += 1
	var stamp := float(v[4])
	if not _rows.is_empty() and stamp <= float(_rows[-1][0]):
		stale += 1
		return
	if _first < 0.0:
		_first = stamp
	if mess != null:
		mess.stream_offset = minf(mess.stream_offset, tick() - stamp)
	if not _rows.is_empty():
		_note_hit(_rows[-1], stamp, v[2])
	_rows.append([stamp, v[0], (v[1] as Quaternion).normalized(), v[2], v[3]])
	if _rows.size() > KEEP:
		_rows.pop_front()
	if is_inside_tree() and _rows.size() == 1:
		_show()


func _physics_process(_delta: float) -> void:
	if not host_side:
		_show()


## The Host's tick this machine plays now: its own tick less the delay and the lag.
func _play_at() -> float:
	var offset := mess.stream_offset if mess != null and mess.stream_offset < INF else 0.0
	var lag := mess.ghost_tuning().stream_lag if mess != null else 0.1
	return tick() - offset - lag * _tps()


func _show() -> void:
	var body := get_parent() as Node3D
	if body == null or _rows.is_empty():
		return
	var at := _play_at()
	_played = at
	var pose: Variant = _sample_tick(at)
	if pose is Transform3D:
		body.global_transform = pose
	while not _hits.is_empty() and float(_hits[0][0]) <= at:
		var hit: Array = _hits.pop_front()
		_bounce(body.global_position, float(hit[1]))


## A hit between row `before` and the row stamped `stamp` with velocity `vel`: the velocity changed by
## more than gravity (and a little drag) explain over the time between.
func _note_hit(before: Array, stamp: float, vel: Vector3) -> void:
	if mess == null:
		return
	var dt := (stamp - float(before[0])) / _tps()
	var was: Vector3 = before[3]
	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var change := (vel - was - Vector3.DOWN * g * dt).length()
	var t := mess.bodies_tuning()
	if change >= t.bounce_speed and was.length() >= t.bounce_speed:
		_hits.append([stamp, was.length()])


## "bounce" at `at`, softer and lower the slower the hit.
func _bounce(at: Vector3, speed: float) -> void:
	var t := mess.bodies_tuning()
	if speed >= t.bounce_speed:
		heard += 1
		Sounds.play_at(&"bounce", at, inverse_lerp(t.bounce_speed, t.bounce_hard_speed, speed))


## How far into its flight the body is drawn now on this machine (Host seconds since its first row),
## or -1 before any row.
func flight_time() -> float:
	if _start() < 0.0 or _played < 0.0:
		return -1.0
	return maxf(0.0, (_played - _start()) / _tps())


## Where the Host's body was `t` seconds into its flight, or null when no row is kept from then.
func sample(t: float) -> Variant:
	if _start() < 0.0 or _rows.is_empty():
		return null
	return _sample_tick(_start() + t * _tps())


## The Host's tick the flight started at: `born`, else the first row's.
func _start() -> float:
	return born if born >= 0.0 else _first


## The pose at Host tick `at` from the rows kept: between two rows, or on along the newest row's
## velocity for at most `stream_extrapolate`; before the oldest, the oldest.
func _sample_tick(at: float) -> Variant:
	if _rows.is_empty():
		return null
	var a: Array = _rows[0]
	if at <= float(a[0]):
		return Transform3D(Basis(a[2] as Quaternion), a[1])
	for i in range(_rows.size() - 1):
		var p: Array = _rows[i]
		var q: Array = _rows[i + 1]
		if at <= float(q[0]):
			var w := (at - float(p[0])) / maxf(float(q[0]) - float(p[0]), 0.0001)
			return Transform3D(Basis((p[2] as Quaternion).slerp(q[2], w)), (p[1] as Vector3).lerp(q[1], w))
	var b: Array = _rows[-1]
	var ahead := minf((at - float(b[0])) / _tps(), mess.ghost_tuning().stream_extrapolate if mess != null else 0.1)
	return Transform3D(Basis(b[2] as Quaternion), (b[1] as Vector3) + (b[3] as Vector3) * ahead)
