## A zoo switch at the Stages station (docs/architecture/stages.md "How it is authored"): "Complete"
## completes the mini run's Stage outright, "Fit now" fits its Part and opens the next floor at once
## (until core/79's MachinePartSlot, the way to open a floor). It holds no state: its use asks
## `switch` and the Host answers with the run's own answer (Stages.complete_now_answer() or
## fit_now_answer()), so every machine sees the run move and its signals fire. Its Looks' label
## names it and says where the run stands.
class_name StagesSwitch
extends Part

## What a switch does.
enum Does { COMPLETE, FIT_NOW }

## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"
const SWITCH := &"switch"
## Its prompt per Does. placeholder: zoo wording
const TITLES := {Does.COMPLETE: "Complete the Stage", Does.FIT_NOW: "Fit now"}
## The run's phases as the label says them.
const PHASES := {Stages.Phase.PLAYING: "playing", Stages.Phase.PART_OUT: "Part out",
		Stages.Phase.FIXING: "fixing", Stages.Phase.FIXED: "fixed"}

## The run it moves.
@export var stages: Stages
@export var does := Does.FIT_NOW
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	return TITLES[does]


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or stages == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	return stages.complete_now_answer() if does == Does.COMPLETE else stages.fit_now_answer()


## Bound: the label says where the run stands now, and again after every answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_relabel):
		parts.applied.connect(_relabel)
	_relabel({})


func _relabel(_ev: Dictionary) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label == null or stages == null:
		return
	var at := "not started" if stages.stage < 0 else "Stage %d: %s, %s" % [stages.stage + 1, stages.floor_title(), PHASES.get(stages.phase, "")]
	label.text = "%s\n%s" % [prompt_title(), at]
