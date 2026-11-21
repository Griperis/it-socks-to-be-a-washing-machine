## The pairing moment's fold (core/27 P14, the old paired_moment.gd and paired.json `curl`, Q2281):
## while the two Socks fold over and roll into the ball, every bone of their cloth chain rolls up by
## `curl` radians times `fold`. The moment's AnimationPlayer keys `fold` (half through the fold, whole
## by the roll's end); this applies it to whatever Looks the Held and Mate are dressed as. Looks only.
class_name PairMoment
extends Node3D

## Where the two Socks' Looks are.
const SOCKS: Array[NodePath] = [^"Held/Looks", ^"Mate/FlyIn/Looks"]

## How far each cloth bone rolls up at the full fold, in radians (negative rolls the other way).
@export_range(-3.0, 3.0, 0.05, "suffix:rad") var curl := 1.3
## How far the fold has gone: 0 straight, 1 rolled up by `curl`. The AnimationPlayer writes it.
@export_range(0.0, 1.0, 0.01) var fold := 0.0:
	set(value):
		fold = value
		_apply()

## Each skeleton's chain bones at their pose before the fold, by the skeleton's instance id.
var _unfolded: Dictionary[int, Dictionary] = {}
## The SockCloth of each of SOCKS, found once, and how many searches found them.
var _cloths: Dictionary[NodePath, SockCloth] = {}
var cloth_searches := 0


## How far each Sock's bones are rolled now (tests read it): the first chain bone's turn from its
## unfolded pose, in radians, per Sock path; 0 for a Sock not found.
func rolled() -> Array[float]:
	var out: Array[float] = []
	for path in SOCKS:
		var cloth := _cloth(path)
		var turn := 0.0
		if cloth != null:
			var skeleton := cloth.get_skeleton()
			var base: Dictionary = _unfolded.get(skeleton.get_instance_id(), {})
			var chain := cloth.chain()
			if not chain.is_empty() and base.has(chain[0]):
				turn = (base[chain[0]] as Quaternion).angle_to(skeleton.get_bone_pose_rotation(chain[0]))
		out.append(turn)
	return out


func _apply() -> void:
	if not is_node_ready():
		return
	for path in SOCKS:
		var cloth := _cloth(path)
		if cloth == null:
			continue
		var skeleton := cloth.get_skeleton()
		if skeleton == null:
			continue
		var key := skeleton.get_instance_id()
		if not _unfolded.has(key):
			var base := {}
			for b in cloth.chain():
				base[b] = skeleton.get_bone_pose_rotation(b)
			_unfolded[key] = base
		var unfolded: Dictionary = _unfolded[key]
		var roll := Quaternion(Vector3.RIGHT, curl * fold)
		for b: int in unfolded:
			skeleton.set_bone_pose_rotation(b, (unfolded[b] as Quaternion) * roll)


## The SockCloth under the Looks at `path`, found once and kept.
func _cloth(path: NodePath) -> SockCloth:
	var kept: SockCloth = _cloths.get(path)
	if kept != null and is_instance_valid(kept):
		return kept
	var looks := get_node_or_null(path)
	if looks == null:
		return null
	cloth_searches += 1
	var found := looks.find_children("*", "SockCloth", true, false)
	var cloth := found[0] as SockCloth if not found.is_empty() else null
	if cloth != null:
		_cloths[path] = cloth
	return cloth
