## What the crosshair rests on among the Socks (core/14): the Sock or Pair a line from the eyes meets
## before any wall, lying or moving (R03). Where a lying Sock and a lying Pair are both under the
## crosshair, the nearer is aimed: the ball's surface against the Sock's middle (R02, the old
## rig_aim.gd). It reads the physics space through PhysicsQueries, from a physics frame.
class_name AimFinder
extends RefCounted


## The Sock aimed from `from` along unit `dir` within `reach`: {"sock": its id or -1, "point": where
## the line enters it (a Pair: the top of its ball), "lying": whether it lies}. `exclude`: the
## player's own body.
static func find(node: Node, mess: Mess, from: Vector3, dir: Vector3, reach: float, exclude: Array[RID]) -> Dictionary:
	var none := {"sock": -1, "point": Vector3.ZERO, "lying": false}
	if mess == null:
		return none
	var to := from + dir * reach
	var wall := PhysicsQueries.ray(node, from, to, Mess.LAYER_HOUSE, exclude)
	var wall_at := from.distance_to(wall["position"]) if not wall.is_empty() else INF
	var skip := exclude.duplicate()
	var found: Array[Dictionary] = []
	for i in 2:
		var hit := PhysicsQueries.ray(node, from, to, Mess.SOCK_MASK, skip)
		if hit.is_empty() or from.distance_to(hit["position"]) > wall_at:
			break
		var sock := mess.sock_of_hit(hit)
		if sock >= 0:
			found.append({"sock": sock, "point": hit["position"], "lying": mess.state_of(sock) == Mess.State.LYING})
		skip.append(hit["rid"])
	if found.is_empty():
		return none
	var best := found[0]
	if found.size() == 2 and found[0]["lying"] and found[1]["lying"] \
			and mess.is_pair(found[0]["sock"]) != mess.is_pair(found[1]["sock"]):
		var ball: Dictionary = found[0] if mess.is_pair(found[0]["sock"]) else found[1]
		var flat: Dictionary = found[1] if ball == found[0] else found[0]
		var radius := SockDress.ball_radius(mess.design_of(ball["sock"]))
		var ball_at := from.distance_to(mess.pose_of(ball["sock"]).origin) - radius
		var flat_at := from.distance_to(mess.box_of(flat["sock"]).get_center())
		best = ball if ball_at < flat_at else flat
	if best["lying"] and mess.is_pair(best["sock"]):
		best["point"] = mess.pose_of(best["sock"]).origin + Vector3.UP * SockDress.ball_radius(mess.design_of(best["sock"]))
	return best


## The Teammate a Hand-off from `from` along unit `dir` would go to (core/42 lines 1, 4, 5; Q2589):
## the one whose body the line meets first within `reach`, shortened by the first wall it meets. A
## body is the segment from `numbers.feet_lift` over their feet to the top of their height as drawn
## here (crouch counts), `numbers.body_radius` round; the point where the line enters it counts, not
## its middle. Not player `me`, not one `kd` says is knocked down, only avatars in `node`'s level.
## {"peer": their peer, or -1; "along": how far along the line it enters them, or INF}.
static func mate(node: Node, from: Vector3, dir: Vector3, reach: float, me: int, numbers: HandOffTuning,
		kd: Knockdowns, exclude: Array[RID]) -> Dictionary:
	var best := {"peer": -1, "along": INF}
	if node == null or not node.is_inside_tree() or numbers == null:
		return best
	var wall := PhysicsQueries.ray(node, from, from + dir * reach, Mess.LAYER_HOUSE, exclude)
	var far := from.distance_to(wall["position"]) if not wall.is_empty() else reach
	var level := LevelRuntime.level_of(node)
	var r := numbers.body_radius
	for n in node.get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := n as Avatar
		if a == null or a.peer() == me or a.is_queued_for_deletion() or not a.is_visible_in_tree() \
				or (level != null and not level.is_ancestor_of(a)):
			continue
		if kd != null and kd.is_down(a.peer()):
			continue
		var t := a.tuning if a.tuning != null else AvatarTuning.new()
		var feet := a.global_position
		var top := feet + Vector3.UP * lerpf(t.stand_height, t.crouch_height, a.crouch)
		var hit := Knockdowns.closest_on_segments(from, from + dir * far, feet + Vector3.UP * numbers.feet_lift, top)
		if hit[0] > r:
			continue
		var along := maxf(0.0, hit[1] - sqrt(r * r - hit[0] * hit[0]))
		if along < float(best["along"]):
			best = {"peer": a.peer(), "along": along}
	return best
