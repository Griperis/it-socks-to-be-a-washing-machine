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
