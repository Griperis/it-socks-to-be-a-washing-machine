## The arcs a Sock let go from the hand flies on (core/23, Q2356, Q2367): the velocity that carries a
## body from where it leaves to where the player aimed, under gravity and its own drag, stepped as
## the physics steps it (60 a second: gravity, then the drag, then the move). Numbers only, no nodes:
## the Host's Hands ask it for a Throw (a set speed, the arc nearest the old aim's) and for a drop
## (let go, it falls on its own: no push up or down, only the drift that brings it to its spot).
class_name Arc
extends RefCounted

## How many times an arc is aimed again by how far its drag made it miss.
const PASSES := 6
## A miss this small (m) is a hit.
const NEAR := 0.003
## The most physics steps an arc is followed for.
const STEPS := 900


## The velocity of `speed` that carries a body from `from` to `to` (gravity `gravity` down, linear
## drag `damp`), on the arc whose direction is nearest `like` (the low or the high one), aimed again
## by how far its drag made it miss, up to PASSES times. Vector3.ZERO only when no arc of that speed
## reaches it at the first aim; when a later aim finds none (the drag asks for more than the speed
## gives) or never gets that far, the aim before it, the nearest found, is kept (core/30: a ZERO there
## made a charge-0 lob land 0.38 m from the crosshair).
static func aimed(from: Vector3, to: Vector3, speed: float, gravity: float, damp: float, like: Vector3) -> Vector3:
	var flat := Vector2(to.x - from.x, to.z - from.z)
	var d := flat.length()
	if d < 0.01 or speed <= 0.0:
		return Vector3.ZERO
	var across := Vector3(flat.x, 0.0, flat.y) / d
	var rise := to.y - from.y
	var best := Vector3.ZERO
	for i in PASSES:
		var angles := _angles(d, rise, speed, gravity)
		if angles.is_empty():
			break
		var angle := angles[0]
		if angles.size() > 1:
			var dir0 := _dir(across, angles[0])
			var dir1 := _dir(across, angles[1])
			if dir1.dot(like.normalized()) > dir0.dot(like.normalized()):
				angle = angles[1]
		best = _dir(across, angle) * speed
		var miss := height_at(from, best, d, gravity, damp) - to.y
		if is_nan(miss) or absf(miss) < NEAR:
			break
		rise -= miss
	return best


## The velocity a body let go at `from` drifts with to land on `to` (gravity `gravity`, drag `damp`):
## level, only as fast across as its fall needs, when `to` is below; a spot level with it or higher
## needs a lift, the slowest arc that reaches it (Vector3.ZERO when aimed() finds none).
static func dropped(from: Vector3, to: Vector3, gravity: float, damp: float) -> Vector3:
	var flat := Vector2(to.x - from.x, to.z - from.z)
	var d := flat.length()
	var fall := from.y - to.y
	if d < 0.005:
		return Vector3.ZERO
	var across := Vector3(flat.x, 0.0, flat.y) / d
	if fall > 0.02:
		var speed := d / sqrt(2.0 * fall / gravity)
		for i in PASSES:
			var reached := reach_at(from, across * speed, to.y, gravity, damp)
			if reached <= 0.0 or absf(reached - d) < NEAR:
				break
			speed *= d / reached
		return across * speed
	var rise := -fall
	var slowest := sqrt(gravity * (rise + sqrt(rise * rise + d * d))) * 1.03
	return aimed(from, to, slowest, gravity, damp, _dir(across, deg_to_rad(45.0)))


## How high (m) a body leaving `from` at `vel` is when it has gone `across` metres along the floor,
## or NAN when it never gets that far.
static func height_at(from: Vector3, vel: Vector3, across: float, gravity: float, damp: float) -> float:
	var dt := _dt()
	var at := from
	var v := vel
	var gone := 0.0
	for i in STEPS:
		v = _stepped(v, gravity, damp, dt)
		var next := at + v * dt
		var step := Vector2(next.x - at.x, next.z - at.z).length()
		if step <= 0.0:
			return NAN
		if gone + step >= across:
			return lerpf(at.y, next.y, (across - gone) / step)
		gone += step
		at = next
	return NAN


## How far along the floor (m) a body leaving `from` at `vel` has gone when it falls to height `y`,
## or -1 when it does not within STEPS.
static func reach_at(from: Vector3, vel: Vector3, y: float, gravity: float, damp: float) -> float:
	var dt := _dt()
	var at := from
	var v := vel
	var gone := 0.0
	for i in STEPS:
		v = _stepped(v, gravity, damp, dt)
		var next := at + v * dt
		var step := Vector2(next.x - at.x, next.z - at.z).length()
		if next.y <= y and v.y < 0.0:
			return gone + step * clampf((at.y - y) / maxf(at.y - next.y, 0.000001), 0.0, 1.0)
		gone += step
		at = next
	return -1.0


## The places a body leaving `from` at `vel` passes, one a physics step, until it falls below `y`
## (that last place included), at most STEPS.
static func path(from: Vector3, vel: Vector3, y: float, gravity: float, damp: float) -> PackedVector3Array:
	var dt := _dt()
	var out := PackedVector3Array([from])
	var at := from
	var v := vel
	for i in STEPS:
		v = _stepped(v, gravity, damp, dt)
		at += v * dt
		out.append(at)
		if at.y < y and v.y < 0.0:
			break
	return out


## The turn (rad/s) that takes a body from `from` to `to` in `ticks` physics steps under angular
## drag `damp` (the drag slows it each step; the start is that much faster).
static func turn_to(from: Basis, to: Basis, ticks: int, damp: float) -> Vector3:
	if ticks <= 0:
		return Vector3.ZERO
	var dt := _dt()
	var q := (to.orthonormalized() * from.orthonormalized().inverse()).get_rotation_quaternion()
	var angle := q.get_angle()
	if angle < 0.0001:
		return Vector3.ZERO
	var keep := maxf(0.0, 1.0 - damp * dt)
	var gone := 0.0
	var k := keep
	for i in ticks:
		gone += k * dt
		k *= keep
	return q.get_axis().normalized() * angle / maxf(gone, 0.0001)


## The launch angles (radians over level) of speed `v` that reach `d` along and `rise` up, low first.
static func _angles(d: float, rise: float, v: float, g: float) -> PackedFloat32Array:
	var v2 := v * v
	var disc := v2 * v2 - g * (g * d * d + 2.0 * rise * v2)
	if disc < 0.0:
		return PackedFloat32Array()
	var root := sqrt(disc)
	return PackedFloat32Array([atan((v2 - root) / (g * d)), atan((v2 + root) / (g * d))])


## One physics step's length (s).
static func _dt() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


## A body's velocity `v` one physics step `dt` later, as the physics steps it: gravity, then the drag.
static func _stepped(v: Vector3, gravity: float, damp: float, dt: float) -> Vector3:
	return (v + Vector3.DOWN * gravity * dt) * maxf(0.0, 1.0 - damp * dt)


static func _dir(across: Vector3, angle: float) -> Vector3:
	return across * cos(angle) + Vector3.UP * sin(angle)
