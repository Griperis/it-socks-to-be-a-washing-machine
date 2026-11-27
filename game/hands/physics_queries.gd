## The game's one place that reads the physics space (kit/tools/grep_rules.py, space_query: this
## file is the exempt one). Call it from physics frames (the player's _physics_process, the Host's
## answer to a Command, which a Host of one makes there too).
class_name PhysicsQueries
extends RefCounted

## The probe ball of ball_hit, reused (its radius is set per query).
static var _ball := SphereShape3D.new()
## How many physics queries ball_hit has made (a timing case counts them, not wall time).
static var ball_queries := 0


## Where a ball `gap` wide, moved from `from` along `motion`, first rests against something of
## `mask`: {"point", "normal"} in the level, or {} when it meets nothing (the crosshair's drop spot:
## it sees no spot through a gap narrower than the ball).
static func ball_hit(node: Node3D, from: Vector3, motion: Vector3, gap: float, mask: int, exclude: Array[RID]) -> Dictionary:
	var space := _space(node)
	if space == null:
		return {}
	ball_queries += 1
	_ball.radius = gap * 0.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _ball
	query.transform = Transform3D(Basis.IDENTITY, from)
	query.motion = motion
	query.collision_mask = mask
	query.exclude = exclude
	var t := space.cast_motion(query)
	if t.size() < 2 or t[1] >= 1.0:
		return {}
	query.transform.origin = from + motion * t[1]
	query.motion = Vector3.ZERO
	var info := space.get_rest_info(query)
	if info.is_empty():
		return {}
	return {"point": info["point"], "normal": (info["normal"] as Vector3).normalized()}


## The first thing of `mask` on the line from `from` to `to`: {"position", "normal", "collider"},
## or {} for none (or when `node` has no world yet). A body of the physics server with no node has a
## "rid" and no "collider". `exclude`: bodies the line passes through.
static func ray(node: Node, from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
	var space := _space(node)
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.exclude = exclude
	return space.intersect_ray(query)


## Whether `point` is inside something solid of `mask` (a Sock that would end inside a wall, T08),
## `exclude` not counted.
static func inside(node: Node, point: Vector3, mask: int, exclude: Array[RID] = []) -> bool:
	var space := _space(node)
	if space == null:
		return false
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = mask
	query.exclude = exclude
	return not space.intersect_point(query, 1).is_empty()


## The bodies of `mask` that `shape` at `xform` overlaps, at most `most`: their RIDs (the Mess's
## lying Socks are bodies of the physics server with no node, core/13). Empty when `node` has no world yet.
static func overlap_rids(node: Node, shape: Shape3D, xform: Transform3D, mask: int, most: int) -> Array[RID]:
	var out: Array[RID] = []
	var space := _space(node) if most > 0 else null
	if space == null:
		return out
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = xform
	query.collision_mask = mask
	for hit: Dictionary in space.intersect_shape(query, most):
		out.append(hit["rid"])
	return out


## The nodes of `mask` that `shape` at `xform` overlaps, at most `most` (the Sock generator's
## clearance test, core/52: a wall and a furniture piece are told apart by their node). A body with no
## node is left out. Also read in the editor by the generator's preview. Empty when `node` has no world yet.
## `exclude`: bodies not counted (a stair's walking ramps over a Sock on its tread, house/05).
static func overlap_colliders(node: Node, shape: Shape3D, xform: Transform3D, mask: int, most: int, exclude: Array[RID] = []) -> Array[Object]:
	var out: Array[Object] = []
	var space := _space(node) if most > 0 else null
	if space == null:
		return out
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = xform
	query.collision_mask = mask
	query.exclude = exclude
	for hit: Dictionary in space.intersect_shape(query, most):
		var collider: Object = hit.get("collider")
		if collider != null:
			out.append(collider)
	return out


## Where `shape` at `xform`, moved along `motion`, first touches something of `mask` (core/163, a thrown
## carried thing's sweep): {"safe": the share of `motion` it moves free, "normal": the touched surface's},
## or {} when it meets nothing (or `node` has no world yet). `exclude`: bodies it passes through.
static func cast(node: Node, shape: Shape3D, xform: Transform3D, motion: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
	var space := _space(node)
	if space == null:
		return {}
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = xform
	q.motion = motion
	q.collision_mask = mask
	q.exclude = exclude
	var frac := space.cast_motion(q)
	if frac.size() < 2 or frac[1] >= 1.0:
		return {}
	q.transform = Transform3D(xform.basis, xform.origin + motion * frac[1])
	q.motion = Vector3.ZERO
	var info := space.get_rest_info(q)
	var n: Vector3 = info.get("normal", -motion.normalized())
	return {"safe": frac[0], "normal": n.normalized() if not n.is_zero_approx() else Vector3.UP}


## The physics space `node` is in, or null while it has no world.
static func _space(node: Node) -> PhysicsDirectSpaceState3D:
	if not node.is_inside_tree():
		return null
	var world := node.get_viewport().find_world_3d()
	return world.direct_space_state if world != null else null
