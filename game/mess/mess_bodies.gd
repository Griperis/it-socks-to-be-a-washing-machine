## The Mess's lying Socks as the physics meets them (core/13, M01): one static body each, made in
## the physics server (no node), on Mess.LAYER_LYING in the level's own space, so the crosshair rests
## on it and falling Socks land on it, at no cost per tick. A Sock collides as two boxes, leg and foot
## (Q2309), a Pair as a sphere; the shapes are made once per Size and shared. The queries over them
## (what touches a Sock, what lies over a picked one, what a moving Door meets) go through
## PhysicsQueries and answer Sock ids. It decides nothing: the Mess says which Sock lies where.
class_name MessBodies
extends RefCounted

## The old game's thinnest Sock box (SockWorld.MIN_THICK), from the Sock's bottom up.
const MIN_THICK := 0.024
## How many places along a Sock's length the leg-and-foot split is tried at.
const SPLIT_STEPS := 40

## The node the queries are made from (the Mess: inside the level's world).
var _from: Node
## Each lying Sock's body, and the Sock each body is.
var _body: Dictionary[int, RID] = {}
var _sock: Dictionary[RID, int] = {}
## Each lying Sock's shape key and pose (what bounds_of reads).
var _key: Dictionary[int, String] = {}
var _pose: Dictionary[int, Transform3D] = {}
## Per shape key: its parts [[Shape3D, Transform3D]...] and its bounds, in the Sock's own space.
var _parts: Dictionary[String, Array] = {}
var _bounds: Dictionary[String, AABB] = {}
## The flat Sock's leg and foot boxes at Size medium: [[size, centre], [size, centre]] (from its mesh).
var _leg_foot: Array = []

## The leg and foot boxes fitted once per run (the mesh does not change while the game runs).
static var _fitted: Array = []


## `from`: the Mess. `points`: the lying Sock mesh's points in its Looks' space at Size medium (where
## the leg and foot boxes are fitted to); none gives one box, SockDress.BOX.
func _init(from: Node, points: PackedVector3Array) -> void:
	_from = from
	if _fitted.is_empty():
		_fitted = leg_and_foot(points)
	_leg_foot = _fitted


## Sock `sock` lies at `pose`: its body made, or moved there. `ball`: a Pair's sphere of `radius`;
## else the Sock's leg and foot at Size `scale`.
func place(sock: int, pose: Transform3D, ball: bool, scale: float, radius: float) -> void:
	var key := ("ball|%.4f" % radius) if ball else ("sock|%.4f" % scale)
	if _body.has(sock) and _key[sock] != key:
		remove(sock)
	if not _body.has(sock):
		var rid := PhysicsServer3D.body_create()
		PhysicsServer3D.body_set_mode(rid, PhysicsServer3D.BODY_MODE_STATIC)
		PhysicsServer3D.body_set_collision_layer(rid, Mess.LAYER_LYING)
		PhysicsServer3D.body_set_collision_mask(rid, 0)
		for part: Array in _parts_of(key, ball, scale, radius):
			PhysicsServer3D.body_add_shape(rid, (part[0] as Shape3D).get_rid(), part[1])
		PhysicsServer3D.body_set_space(rid, _space())
		_body[sock] = rid
		_sock[rid] = sock
		_key[sock] = key
	PhysicsServer3D.body_set_state(_body[sock], PhysicsServer3D.BODY_STATE_TRANSFORM, pose)
	_pose[sock] = pose


## Sock `sock`'s body is freed (it no longer lies).
func remove(sock: int) -> void:
	var rid: RID = _body.get(sock, RID())
	if not rid.is_valid():
		return
	_sock.erase(rid)
	_body.erase(sock)
	_key.erase(sock)
	_pose.erase(sock)
	PhysicsServer3D.free_rid(rid)


## Every body freed (the Mess leaves the tree).
func clear() -> void:
	for sock: int in _body.keys():
		remove(sock)


## Whether Sock `sock` has a lying body.
func has(sock: int) -> bool:
	return _body.has(sock)


## How many lying bodies there are.
func size() -> int:
	return _body.size()


## The Sock whose lying body `rid` is, or -1.
func sock_of(rid: RID) -> int:
	return _sock.get(rid, -1)


## The body of Sock `sock` (an invalid RID when it has none).
func body_of(sock: int) -> RID:
	return _body.get(sock, RID())


## The box Sock `sock`'s body takes in the level (an AABB round its turned shapes), or an empty one.
func bounds_of(sock: int) -> AABB:
	if not _body.has(sock):
		return AABB()
	return _pose[sock] * _bounds[_key[sock]]


## The lying Socks touching Sock `sock` (its box grown by `margin`), not itself, at most `most`.
func touching(sock: int, margin: float, most: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if not _body.has(sock) or most <= 0:
		return out
	var local := _bounds[_key[sock]]
	var box := BoxShape3D.new()
	box.size = local.size + Vector3.ONE * margin * 2.0
	var at := _pose[sock] * Transform3D(Basis.IDENTITY, local.get_center())
	for other in overlapping(box, at, most + 1):
		if other != sock and out.size() < most:
			out.append(other)
	return out


## The lying Socks over the box `under` (in the level), its footprint grown by `margin`, up to
## `column` m over its top, whose bottom is no lower than its top less `slack`: lowest first, at most
## `most` (M07: what rested on a picked Sock, found now, Q2307).
func above(under: AABB, margin: float, column: float, slack: float, most: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if most <= 0 or not under.has_volume():
		return out
	var top := under.end.y
	var box := BoxShape3D.new()
	box.size = Vector3(under.size.x + margin * 2.0, column, under.size.z + margin * 2.0)
	var centre := under.get_center()
	var at := Transform3D(Basis.IDENTITY, Vector3(centre.x, top - slack + column * 0.5, centre.z))
	var keyed: Array[Vector2] = []
	for sock in overlapping(box, at, most * 4 + 8):
		var bottom := bounds_of(sock).position.y
		if bottom >= top - slack:
			keyed.append(Vector2(bottom, sock))
	keyed.sort()
	for k in keyed:
		if out.size() == most:
			break
		out.append(int(k.y))
	return out


## The lying Socks `shape` at `xform` overlaps, at most `most`.
func overlapping(shape: Shape3D, xform: Transform3D, most: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for rid in PhysicsQueries.overlap_rids(_from, shape, xform, Mess.LAYER_LYING, most):
		var sock: int = _sock.get(rid, -1)
		if sock >= 0 and not out.has(sock):
			out.append(sock)
	return out


func _space() -> RID:
	var world := _from.get_viewport().find_world_3d() if _from.is_inside_tree() else null
	return world.space if world != null else RID()


func _parts_of(key: String, ball: bool, scale: float, radius: float) -> Array:
	if _parts.has(key):
		return _parts[key]
	var parts: Array = []
	var bounds := AABB()
	if ball:
		var sphere := SphereShape3D.new()
		sphere.radius = radius
		parts.append([sphere, Transform3D.IDENTITY])
		bounds = AABB(-Vector3.ONE * radius, Vector3.ONE * radius * 2.0)
	else:
		var first := true
		for part: Array in _leg_foot:
			var size: Vector3 = (part[0] as Vector3) * scale
			var centre: Vector3 = (part[1] as Vector3) * scale
			var box := BoxShape3D.new()
			box.size = size
			parts.append([box, Transform3D(Basis.IDENTITY, centre)])
			var b := AABB(centre - size * 0.5, size)
			bounds = b if first else bounds.merge(b)
			first = false
	_parts[key] = parts
	_bounds[key] = bounds
	return parts


## A lying Sock's leg and foot boxes from its mesh's points (its bottom at y = 0): the points split
## across its long side where the two boxes cover the least floor, each box round its half, at
## least MIN_THICK thick from the bottom up: [[size, centre], [size, centre]]. With no points, one
## box, SockDress.BOX.
static func leg_and_foot(points: PackedVector3Array) -> Array:
	var whole := SockDress.BOX
	if points.size() < 4:
		return [[whole, Vector3(0.0, whole.y * 0.5, 0.0)]]
	var all := AABB(points[0], Vector3.ZERO)
	for p in points:
		all = all.expand(p)
	var best: Array = []
	var best_area := INF
	for axis: int in [Vector3.AXIS_X, Vector3.AXIS_Z]:
		var lo: float = all.position[axis]
		var hi: float = all.end[axis]
		for i in range(1, SPLIT_STEPS):
			var cut := lerpf(lo, hi, float(i) / SPLIT_STEPS)
			var a := AABB()
			var b := AABB()
			var has_a := false
			var has_b := false
			for p in points:
				if p[axis] <= cut:
					a = a.expand(p) if has_a else AABB(p, Vector3.ZERO)
					has_a = true
				if p[axis] >= cut:
					b = b.expand(p) if has_b else AABB(p, Vector3.ZERO)
					has_b = true
			if not has_a or not has_b:
				continue
			# The two boxes meet at the cut (the mesh's rings lie apart).
			var qa := a.position
			qa[axis] = cut
			a = a.expand(qa)
			var qb := b.position
			qb[axis] = cut
			b = b.expand(qb)
			var area := a.size.x * a.size.z + b.size.x * b.size.z
			if area < best_area:
				best_area = area
				best = [a, b]
	if best.is_empty():
		return [[whole, Vector3(0.0, whole.y * 0.5, 0.0)]]
	var out: Array = []
	for box: AABB in best:
		var height := maxf(box.end.y, MIN_THICK)
		var size := Vector3(box.size.x, height, box.size.z)
		out.append([size, Vector3(box.get_center().x, height * 0.5, box.get_center().z)])
	return out
