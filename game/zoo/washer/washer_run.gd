## The washer station's stand-in for the run (core/107, Q2409): the station has no Stages and no Laundry day, so
## the washing machine's `stages` link points here and this Part answers the same reads (`wants_first_wash()`,
## `under_way()`, `comment_set()`, `parts_missing()`, `part_total()`, `last_pair_in()`). Its pillars' switches are
## its own Commands, decided by the Host, and their state is its own: broken, the mood level and the Stage.
##   `broken {on}`: "Break it" / "Fix it" (in the house the First wash breaks it).
##   `mood {level}`: a mood level 0..`part_total()` (core/87 shows it), or -1 for calm.
##   `stage {stage}`: the Stage whose comment set it draws from, one past the last for the Laundry day's, or -1
##                    for any set ("From the run").
##   `cutscene {trigger}`: a CUTSCENE trigger played plainly on the Cutscene frame (core/88).
## Its senses are always on (a staged run is "under way"). It keeps nothing in a save.
class_name WasherRun
extends Part

const BROKEN := &"broken"
const MOOD := &"mood"
const STAGE := &"stage"
const CUTSCENE := &"cutscene"

## The washing machine it stands in for (its tuning's `zoo_levels` is the number of mood levels).
@export var washer: Washer
## The plan the Stage pillars read the comment sets from (the house's).
@export var plan: StagePlan

@export_group("State")
## "Break it": the machine is broken (it comments and may look angry).
@export var broken := false
## The mood level, or -1 for calm.
@export var mood := -1
## The Stage 0.., one past the last for the Laundry day, or -1 for any set.
@export var at := -1
@export_group("")


func save_state() -> Dictionary:
	return {}


func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		BROKEN: {"args": {"on": TYPE_BOOL}, "rate": 5},
		MOOD: {"args": {"level": {"type": TYPE_INT, "min": -1, "max": 64}}, "rate": 5},
		STAGE: {"args": {"stage": {"type": TYPE_INT, "min": -1, "max": 64}}, "rate": 5},
		CUTSCENE: {"args": {"trigger": {"type": TYPE_STRING, "max": 64}}, "rate": 5},
	}


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		BROKEN:
			var on: Variant = cmd.args.get("on")
			if not (on is bool) or on == broken:
				return refuse("wrong")
			return grant({"broken": on})
		MOOD:
			var level: Variant = cmd.args.get("level")
			if not (level is int) or level > part_total():
				return refuse("wrong")
			return grant({"mood": level})
		STAGE:
			var stage: Variant = cmd.args.get("stage")
			if not (stage is int):
				return refuse("wrong")
			return grant({"at": stage})
		CUTSCENE:
			var cutscene := Washer.trigger_of(StringName(str(cmd.args.get("trigger", ""))))
			var frame := Cutscenes.of(self)
			if cutscene == null or cutscene.kind != VoiceTrigger.Kind.CUTSCENE or frame == null:
				return refuse("wrong")
			return frame.start(cutscene.resource_path)
	return refuse("wrong")


# --- The run's reads -----------------------------------------------------------------------------

## The First wash is still to come while it is not broken.
func wants_first_wash() -> bool:
	return not broken


func under_way() -> bool:
	return true


func comment_set() -> int:
	if at < 0 or plan == null:
		return 0
	if at >= plan.size():
		return plan.laundry_day_comment_set
	var s := plan.stage(at)
	return s.comment_set if s != null else 0


## The mood pillar's level, whether or not it is broken (calm when none is set).
func parts_missing() -> int:
	return maxi(mood, 0)


func part_total() -> int:
	return washer.tuning.zoo_levels if washer != null and washer.tuning != null else 5


func last_pair_in() -> bool:
	return false
