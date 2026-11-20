## The game's one place that reads the physics space (kit/tools/grep_rules.py, space_query: this
## file is the exempt one). Call it from physics frames (the player's _physics_process, the Host's
## answer to a Command, which a Host of one makes there too).
class_name PhysicsQueries
extends RefCounted


## Where a ball `gap` wide, moved from `from` along `motion`, first rests against something of
## `mask`: {"point", "normal"} in the level, or {} when it meets nothing (the crosshair's drop spot:
## it sees no spot through a gap narrower than the ball).
static func ball_hit(node: Node3D, from: Vector3, motion: Vector3, gap: float, mask: int, exclude: Array[RID]) -> Dictionary:
	var space := node.get_world_3d().direct_space_state
	var ball := SphereShape3D.new()
	ball.radius = gap * 0.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
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
## or {} for none (or when `node` has no world yet).
static func ray(node: Node, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	if not node.is_inside_tree():
		return {}
	var world := node.get_viewport().find_world_3d()
	if world == null:
		return {}
	return world.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, mask))
