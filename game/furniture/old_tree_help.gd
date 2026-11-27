## What the Old Tree reads of the house to help (core/133, docs/architecture/economy.md "The Old Tree talks"): the
## Stage bar's step, the Cabinets with a Row to fill, the floor of a loose Mate, the tips that are due. Reads only:
## every function takes what it reads and changes nothing.
class_name OldTreeHelp
extends RefCounted

## The ids of the triggers by family (the files in `game/voice/triggers/`).
const STAGE: Array[StringName] = [&"tree_stage_half", &"tree_stage_most", &"tree_stage_last"]
const TIPS: Array[StringName] = [&"tree_tip_throw", &"tree_tip_part"]
const GRUMBLE := &"tree_grumble"
const STORY: Array[StringName] = [&"tree_final_wash", &"tree_peace"]
const FINAL_WASH := &"tree_final_wash"
const CABINET := "tree_cabinet_"
const HINT := "tree_hint_"
const COMMENTS: Array[String] = ["tree_part_", "tree_floor_"]


## The level's Stages (the one on `node`'s Parts), or null.
static func stages_of(node: Part) -> Stages:
	if node == null or not node.is_inside_tree():
		return null
	for s in node.get_tree().get_nodes_in_group(Stages.GROUP):
		if (s as Stages).parts == node.parts:
			return s as Stages
	return null


## Whether `trigger` is a Fix comment (a Stage's part or floor line).
static func is_comment(trigger: StringName) -> bool:
	var id := String(trigger)
	for prefix in COMMENTS:
		if id.begins_with(prefix):
			return true
	return false


## The share (0 to 1) of the current Stage's bar that is shelved; 0 for no bar.
static func share(stages: Stages) -> float:
	if stages == null:
		return 0.0
	var n := stages.bar_numbers()
	return float(n.x) / float(n.y) if n.y > 0 else 0.0


## The index into `STAGE` of the highest of `thresholds` that `at` has reached, or -1.
static func step_of(at: float, thresholds: PackedFloat32Array) -> int:
	var out := -1
	for i in mini(thresholds.size(), STAGE.size()):
		if at >= thresholds[i]:
			out = i
	return out


## Whether the thing behind `tip` is there: the Throw from the start, a Part once Stage 1 completes.
static func tip_due(tip: StringName, stages: Stages) -> bool:
	match tip:
		&"tree_tip_throw":
			return true
		&"tree_tip_part":
			return stages != null and stages.stage >= 0 and (stages.stage > 0 or stages.phase != Stages.Phase.PLAYING)
	return false


## The hint triggers of the Cabinets that still have a Row of the bar to fill, in bar order, each once.
static func needy_cabinets(stages: Stages) -> Array[VoiceTrigger]:
	var out: Array[VoiceTrigger] = []
	if stages == null:
		return out
	for row: Variant in stages.bar:
		var cab := stages.cabinet_of(StringName(str((row as Array)[0])))
		if cab != null and cab.tree_hint != null and not cab.row_full(int((row as Array)[1])) and not out.has(cab.tree_hint):
			out.append(cab.tree_hint)
	return out


## The hint trigger for the floor where a loose Mate lies, never the spot: with a loose Sock in the Hands of
## player `by` the floor of a loose Sock of its Design, else of a loose Sock of a Collection the bar still needs.
## Null for none (or a floor whose Stage names no hint).
static func mate_hint(stages: Stages, hands: Hands, lights: HouseLights, by: int, rng: RandomNumberGenerator) -> VoiceTrigger:
	if stages == null or stages.plan == null or hands == null or hands.mess == null or lights == null:
		return null
	var mess := hands.mess
	var held := -1
	for sock in hands.items_of(by):
		if mess.mate_of(sock) < 0 and mess.designs.size() > sock:
			held = mess.designs[sock]
			break
	var needed: Dictionary[StringName, bool] = {}
	for row: Variant in stages.bar:
		var cab := stages.cabinet_of(StringName(str((row as Array)[0])))
		if cab != null:
			needed[cab.collection] = true
	var found: Array[VoiceTrigger] = []
	for sock in mess.count():
		if mess.state_of(sock) != Mess.State.LYING or mess.mate_of(sock) >= 0:
			continue
		if held >= 0:
			if mess.designs[sock] != held:
				continue
		else:
			var design := mess.design_of(sock)
			if design == null or not needed.has(design.collection):
				continue
		var stage := _stage_of_floor(stages.plan, lights.level_index(mess.pose_of(sock).origin.y))
		if stage != null and stage.tree_hint != null:
			found.append(stage.tree_hint)
	return null if found.is_empty() else found[rng.randi() % found.size()]


static func _stage_of_floor(plan: StagePlan, level: int) -> Stage:
	for stage in plan.stages:
		if stage.floor == level:
			return stage
	return null


## The Fix comments a floor opening can bring: Stage `next`'s Part before it, and its own floor.
static func fix_pool(plan: StagePlan, next: int) -> Array[VoiceTrigger]:
	var out: Array[VoiceTrigger] = []
	var before := plan.stage(next - 1) if plan != null else null
	var now := plan.stage(next) if plan != null else null
	if before != null and before.tree_part_comment != null:
		out.append(before.tree_part_comment)
	if now != null and now.tree_floor_comment != null:
		out.append(now.tree_floor_comment)
	return out
