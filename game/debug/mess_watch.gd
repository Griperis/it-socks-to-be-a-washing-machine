## Counts what a Mess's Socks do wrong while they move and come to rest (core/31, B3), for the Mess
## benchmark and the suite: put it in the tree beside a Mess (the Host's) and read result(). Each
## physics tick, after the Mess, it looks only at the falling bodies (never at every record), so it
## costs the same with 500 lying Socks as with 10,000; own_usec says what the last tick's look cost.
## It changes nothing and reads only what the Mess shows everyone (its records, its falling bodies).
##
## The counts, against MessChecks:
## - rests, and of them: lost (written lying far from where its body was: it came back at the
##   return spot), jumped (snapped farther than `jump` from where its body was when the Mess judged
##   it), hot (written lying while still turning or moving fast at its last tick seen moving);
## - wakes (a lying Sock that moves again), and Socks that jitter (woken `jitter_wakes` times or more);
## - Socks that flip (turning faster than `flip_spin` while moving);
## - Socks under the floor: the middle of a moving Sock's leg or foot (a Pair's ball) more than `under`
##   under `floor_y` (core/50: Jolt's position solve pushed one through the zoo's 0.2 m floor);
## - made inside: a new Sock (a record that never lay) whose boxes overlap a moving Sock's from the
##   tick it is first seen (core/49: two Socks of one pour made inside each other rest stuck together);
## - survey(), once the heap rests: lying Socks sunk under the floor, pressed into another lying Sock
##   (allowed and counted, Q2499: Jolt's slop) or inside it (deeper than the slop).
## Each fault leaves a line in `notes` with the Sock's id and its last ticks (core/54).
class_name MessWatch
extends Node

## A rest farther than this from the body's last place is a return to the return spot, not a snap
## (the rest rule lifts a sunk Sock by at most MessTuning.sunk_depth, 0.3 m).
const LOST_OVER := 0.35
## The survey's grid: lying Socks are compared with those in the cells round their own.
const CELL := 0.45
## Two Socks whose middles are farther apart than this cannot overlap (a Sock is under 0.45 m long).
const NEAR := 0.45
## How often the moving count is noted for the report's line over time.
const SERIES_EVERY := 0.5
## How many ticks of a moving Sock's track a fault's note keeps.
const TRACK := 12

@export var mess: Mess
@export var checks: MessChecks = preload("res://game/debug/mess_checks.tres")
## Only records from this one on are surveyed (a station's own Socks in the zoo); every flight counts.
@export var first := 0
## The floor's height a sunk Sock is judged by.
@export var floor_y := 0.0

var rests := 0
var lost := 0
var jumped := 0
var hot := 0
var made_inside := 0
## How many Socks went under the floor while moving (each once).
var under := 0
var wakes := 0
var peak_moving := 0
## The longest snap of a rest that was not a return, in m.
var worst_jump := 0.0
## The fastest turn any moving Sock had, in rad/s.
var worst_spin := 0.0
## The moving count every SERIES_EVERY seconds.
var series := PackedInt32Array()
## Seconds watched, and for how long nothing has moved or waited.
var watched := 0.0
var quiet_for := 0.0
## What this node's own look cost in the last tick, in microseconds (the benchmark's clock takes it
## off the tick it measures).
var own_usec := 0

var _flying: Dictionary[int, bool] = {}
var _at: Dictionary[int, Vector3] = {}
## Each falling body's place before this tick's Mess (`_before_tick`).
var _judged: Dictionary[int, Vector3] = {}
var _speed: Dictionary[int, float] = {}
var _spin: Dictionary[int, float] = {}
## The Socks that lay at some time while watched (a body starting for one of them is a wake).
var _lay: Dictionary[int, bool] = {}
var _woken: Dictionary[int, int] = {}
var _flipped: Dictionary[int, bool] = {}
var _under: Dictionary[int, bool] = {}
## The deepest a moving Sock's leg or foot middle went under the floor, in m.
var worst_under := 0.0
## The Socks seen moving at some time while watched (a body first seen for a record not among them is new).
var _seen: Dictionary[int, bool] = {}
var _since_series := 0.0
var _started := false
## What each fault was, one line a Sock with its last TRACK ticks (place, speed, turn, contacts,
## asleep): what a failing suite prints, so a rare fault can be looked into from one run (core/54).
var notes := PackedStringArray()
## The last TRACK ticks of each moving Sock, as text, and each Sock's wakes and rests (time, place).
var _track: Dictionary[int, PackedStringArray] = {}
var _story: Dictionary[int, PackedStringArray] = {}


func _ready() -> void:
	process_physics_priority = 1000
	get_tree().physics_frame.connect(_before_tick)
	_note_lying()


## Before every node's physics tick (the Mess's too): where each falling body is now, the place the
## Mess judges it at this tick and writes it lying at when it comes to rest (core/54: Jolt's position
## solve moved a slow Sock 13 mm in the step before its rest; that was the body's own move, drawn so,
## not a snap of the rest rule, which the jump counts).
func _before_tick() -> void:
	if mess == null:
		return
	_judged.clear()
	for body in mess.flight_bodies():
		if body.has_meta(Mess.SOCK_META):
			_judged[int(body.get_meta(Mess.SOCK_META))] = body.global_position


## The Socks lying now are known as lying (once: when it starts with a Mess that has its records).
func _note_lying() -> void:
	if _started or mess == null or mess.count() == 0:
		return
	_started = true
	for sock in mess.count():
		if mess.states[sock] == Mess.State.LYING:
			_lay[sock] = true


## Counts again from nothing.
func restart() -> void:
	rests = 0
	lost = 0
	jumped = 0
	hot = 0
	made_inside = 0
	under = 0
	worst_under = 0.0
	_under.clear()
	wakes = 0
	peak_moving = 0
	worst_jump = 0.0
	worst_spin = 0.0
	series = PackedInt32Array()
	watched = 0.0
	quiet_for = 0.0
	_woken.clear()
	_flipped.clear()
	_since_series = 0.0
	notes = PackedStringArray()
	_track.clear()
	_story.clear()


## Whether nothing has moved or waited for MessChecks.quiet.
func settled() -> bool:
	return quiet_for >= checks.quiet


## How many Socks were woken `jitter_wakes` times or more, and how many flipped.
func jittering() -> int:
	var n := 0
	for sock: int in _woken:
		if _woken[sock] >= checks.jitter_wakes:
			n += 1
	return n


func flipped() -> int:
	return _flipped.size()


func _physics_process(delta: float) -> void:
	var from := Time.get_ticks_usec()
	if mess == null:
		return
	_note_lying()
	var now: Dictionary[int, bool] = {}
	var made: Array[int] = []
	var poses: Dictionary[int, Transform3D] = {}
	for body in mess.flight_bodies():
		if not body.has_meta(Mess.SOCK_META):
			continue
		var sock := int(body.get_meta(Mess.SOCK_META))
		now[sock] = true
		poses[sock] = body.global_transform
		if not _flying.has(sock) and not _lay.has(sock) and not _seen.has(sock):
			_seen[sock] = true
			made.append(sock)
		if not _flying.has(sock) and _lay.has(sock):
			wakes += 1
			_woken[sock] = int(_woken.get(sock, 0)) + 1
			_tell(sock, "woken at %.2f s at %s" % [watched, body.global_position])
			if _woken[sock] == checks.jitter_wakes:
				notes.append("Sock %d jitters: %s" % [sock, " | ".join(_story[sock])])
		if not _flying.has(sock):
			_track[sock] = PackedStringArray()
		_note_tick(sock, body)
		var spin := body.angular_velocity.length()
		_at[sock] = body.global_position
		_speed[sock] = body.linear_velocity.length()
		_spin[sock] = spin
		worst_spin = maxf(worst_spin, spin)
		if spin > checks.flip_spin:
			_flipped[sock] = true
		for child in body.get_children():
			var part := child as CollisionShape3D
			if part != null and part.global_position.y < floor_y - checks.under:
				worst_under = maxf(worst_under, floor_y - part.global_position.y)
				if not _under.has(sock):
					_under[sock] = true
					under += 1
					notes.append("Sock %d under: its part's middle at %.3f m | track: %s" % [sock, part.global_position.y, " | ".join(_track[sock])])
	for sock in made:
		if _made_inside(sock, poses):
			made_inside += 1
	for sock: int in _flying:
		if now.has(sock):
			continue
		if sock < mess.count() and mess.states[sock] == Mess.State.LYING:
			_rested(sock)
		_at.erase(sock)
		_speed.erase(sock)
		_spin.erase(sock)
		_track.erase(sock)
	_flying = now
	peak_moving = maxi(peak_moving, now.size())
	watched += delta
	quiet_for = quiet_for + delta if now.is_empty() and mess.waiting_count() == 0 else 0.0
	_since_series += delta
	if _since_series >= SERIES_EVERY:
		_since_series -= SERIES_EVERY
		series.append(now.size())
	own_usec = Time.get_ticks_usec() - from


## Whether new Sock `sock` overlaps another moving Sock deeper than MessChecks.made_inside.
func _made_inside(sock: int, poses: Dictionary[int, Transform3D]) -> bool:
	var at := poses[sock]
	for other: int in poses:
		if other != sock and poses[other].origin.distance_to(at.origin) < NEAR \
				and _depth(sock, at, other, poses[other]) > checks.made_inside:
			return true
	return false


## How deep Socks `a` and `b` overlap at poses `at_a` and `at_b`, in m (the deepest of their leg and
## foot boxes' overlaps; 0 or less: apart).
func _depth(a: int, at_a: Transform3D, b: int, at_b: Transform3D) -> float:
	var deepest := -INF
	for pa: Array in _parts(a):
		var ta := Transform3D(at_a.basis.orthonormalized(), at_a * (pa[1] as Vector3))
		for pb: Array in _parts(b):
			var tb := Transform3D(at_b.basis.orthonormalized(), at_b * (pb[1] as Vector3))
			deepest = maxf(deepest, MessBodies.overlap_depth(pa[0], ta, pb[0], tb))
	return deepest


func _rested(sock: int) -> void:
	rests += 1
	_lay[sock] = true
	var snap := mess.pose_of(sock).origin.distance_to(_judged.get(sock, _at[sock]))
	var faults := PackedStringArray()
	if snap > LOST_OVER:
		lost += 1
	else:
		worst_jump = maxf(worst_jump, snap)
		if snap > checks.jump:
			jumped += 1
			faults.append("jumped")
	if _spin[sock] > checks.hot_spin or _speed[sock] > checks.hot_speed:
		hot += 1
		faults.append("hot")
	_tell(sock, "rested at %.2f s at %s (snap %.3f m, speed %.2f m/s, turn %.2f rad/s)" % [watched, mess.pose_of(sock).origin, snap, _speed[sock], _spin[sock]])
	if not faults.is_empty():
		notes.append("Sock %d %s: rested at %s, snap %.3f m | track: %s" % [sock, " and ".join(faults), mess.pose_of(sock).origin, snap, " | ".join(_track.get(sock, PackedStringArray()))])


## One tick of moving Sock `sock`'s track: time, place, speed, turn, contacts, asleep.
func _note_tick(sock: int, body: RigidBody3D) -> void:
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	var lines: PackedStringArray = _track[sock]
	var p := body.global_position
	lines.append("%.3f (%.3f %.3f %.3f) v %.2f w %.2f c %d%s" % [watched, p.x, p.y, p.z, body.linear_velocity.length(), body.angular_velocity.length(),
			state.get_contact_count() if state != null else -1, " asleep" if body.sleeping else ""])
	if lines.size() > TRACK:
		lines.remove_at(0)
	_track[sock] = lines


## A line of Sock `sock`'s story (its wakes and rests).
func _tell(sock: int, line: String) -> void:
	var lines: PackedStringArray = _story.get(sock, PackedStringArray())
	lines.append(line)
	_story[sock] = lines


## The heap as it lies now: {"sunk": lying Socks whose lowest point is under the floor, "sunk_worst":
## how far under the deepest one is, in m, "pressed": lying Socks whose leg or foot overlaps another
## lying Sock's deeper than MessChecks.pressed and no deeper than MessChecks.inside (Q2499: allowed,
## counted), "pressed_worst": the deepest of them, in m, "inside": those overlapping deeper, "inside_worst"}. Judged
## by the boxes a Sock lies on (its leg and its foot), not its outline's box, so a Sock leaning on
## its heel is not sunk. Pairs are left out (a ball rests in the dip between Socks). Not for every
## tick: it walks every lying record from `first` on.
func survey() -> Dictionary:
	var out := {"sunk": 0, "sunk_worst": 0.0, "pressed": 0, "pressed_worst": 0.0, "inside": 0, "inside_worst": 0.0}
	if mess == null:
		return out
	var cells: Dictionary[Vector3i, PackedInt32Array] = {}
	var socks := PackedInt32Array()
	for sock in range(first, mess.count()):
		if mess.states[sock] != Mess.State.LYING or mess.is_pair(sock):
			continue
		socks.append(sock)
		var c := _cell(mess.pose_of(sock).origin)
		var list: PackedInt32Array = cells.get(c, PackedInt32Array())
		list.append(sock)
		cells[c] = list
	for sock in socks:
		var pose := mess.pose_of(sock)
		var low := INF
		for part: Array in _parts(sock):
			var size: Vector3 = part[0]
			var centre: Vector3 = part[1]
			for x: float in [-0.5, 0.5]:
				for y: float in [-0.5, 0.5]:
					for z: float in [-0.5, 0.5]:
						low = minf(low, (pose * (centre + Vector3(x * size.x, y * size.y, z * size.z))).y)
		if low < floor_y - checks.sunk:
			out["sunk"] += 1
			out["sunk_worst"] = maxf(out["sunk_worst"], floor_y - low)
		var c := _cell(pose.origin)
		var deepest := 0.0
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					for other: int in cells.get(c + Vector3i(dx, dy, dz), PackedInt32Array()):
						if other != sock:
							deepest = maxf(deepest, _depth(sock, pose, other, mess.pose_of(other)))
		if deepest > checks.inside:
			out["inside"] += 1
			out["inside_worst"] = maxf(out["inside_worst"], deepest)
		elif deepest > checks.pressed:
			out["pressed"] += 1
			out["pressed_worst"] = maxf(out["pressed_worst"], deepest)
	return out


## Everything counted, as one Dictionary (what the benchmark reports and the suite checks).
func result() -> Dictionary:
	return {"rests": rests, "lost": lost, "jumped": jumped, "hot": hot, "made_inside": made_inside, "under": under, "worst_under": worst_under, "wakes": wakes, "jitter": jittering(),
			"flips": flipped(), "peak_moving": peak_moving, "worst_jump": worst_jump, "worst_spin": worst_spin,
			"moving": _flying.size(), "waiting": mess.waiting_count() if mess != null else 0, "series": series}


## The boxes lying Sock `sock` lies on, in its own space: [[size, centre], ...] (its leg and foot as
## the Mess fitted them, at its Size; its outline's one box before any Mess has).
func _parts(sock: int) -> Array:
	var design := mess.design_of(sock)
	var scale := design.size_scale() if design != null else 1.0
	var fitted: Array = MessBodies._fitted
	if fitted.is_empty():
		fitted = [[SockDress.BOX, Vector3(0.0, SockDress.BOX.y * 0.5, 0.0)]]
	var out: Array = []
	for part: Array in fitted:
		out.append([(part[0] as Vector3) * scale, (part[1] as Vector3) * scale])
	return out


static func _cell(at: Vector3) -> Vector3i:
	return Vector3i(floori(at.x / CELL), floori(at.y / CELL), floori(at.z / CELL))
