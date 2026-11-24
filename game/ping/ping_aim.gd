## What a ping from the crosshair points at (core/43 lines 16-19, Q2590): the crosshair's line cast to
## the ping's reach. The nearest of a Mess Sock or Pair (AimFinder.find(), up to the reach plus the
## pick slack, stopped by a wall) and a Teammate's body (AimFinder.mate(), the Hand-off's aim, core/42)
## wins, a Teammate only when nearer; else the first thing of the house the line meets within the
## reach: one with an Outline is named by its path from the level, anything else is the spot on its
## surface. Nothing in reach (open space) is nothing (line 17). It reads the physics space through
## PhysicsQueries, from a physics frame.
class_name PingAim
extends RefCounted


## From `from` along unit `dir`, for player `me`: {"sock": a Mess id or -1, "mate": a peer or -1,
## "path": a thing's path from the level or "", "at": the spot, "normal": the surface's normal there},
## or {} when the line meets nothing in reach. `exclude`: the player's own body.
static func find(node: Node, mess: Mess, from: Vector3, dir: Vector3, numbers: PingTuning, me: int,
		body: HandOffTuning, kd: Knockdowns, exclude: Array[RID]) -> Dictionary:
	var reach := numbers.reach
	var sock := AimFinder.find(node, mess, from, dir, reach + numbers.pick_slack, exclude) if mess != null else {"sock": -1}
	var sock_at := from.distance_to(sock["point"]) if int(sock["sock"]) >= 0 else INF
	var mate := AimFinder.mate(node, from, dir, reach, me, body if body != null else HandOffTuning.new(), kd, exclude)
	if int(mate["peer"]) >= 0 and float(mate["along"]) < sock_at:
		var feet := _avatar_feet(node, int(mate["peer"]))
		return {"sock": -1, "mate": int(mate["peer"]), "path": "", "at": feet, "normal": Vector3.UP}
	if int(sock["sock"]) >= 0:
		var s := int(sock["sock"])
		return {"sock": s, "mate": -1, "path": "", "at": mess.where_of(s), "normal": Vector3.UP}
	var hit := PhysicsQueries.ray(node, from, from + dir * reach, Mess.LAYER_HOUSE, exclude)
	if hit.is_empty():
		return {}
	var out := {"sock": -1, "mate": -1, "path": "", "at": hit["position"], "normal": hit["normal"]}
	var thing := hit.get("collider") as Node
	var level := LevelRuntime.level_of(node)
	if thing != null and level != null and level.is_ancestor_of(thing) and Outline.of(thing) != null:
		out["path"] = String(level.get_path_to(thing))
	return out


## Where player `peer`'s avatar stands in `node`'s level, or the origin.
static func _avatar_feet(node: Node, peer: int) -> Vector3:
	var level := LevelRuntime.level_of(node)
	for n in node.get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := n as Avatar
		if a != null and a.peer() == peer and (level == null or level.is_ancestor_of(a)):
			return a.global_position
	return Vector3.ZERO
