## A zoo pillar at the Stages station (core/80): "Open the locks" opens every floor lock of the run at once as
## a floor's opening does (padlock, chain, swing, lamps), and "Lock the locks" shuts them again, so a lock can
## be watched over and over. It holds no state: its use asks `switch` and the Host answers with the locks'
## own states (the leaf's `{open, locked}`), shown by every machine.
class_name LockSwitch
extends Part

## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"
const SWITCH := &"switch"
## placeholder: zoo wording
const OPEN_TITLE := "Open the locks"
const LOCK_TITLE := "Lock the locks"

## The run whose locks it moves.
@export var stages: Stages
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	return OPEN_TITLE if _any_locked() else LOCK_TITLE


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or stages == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	var opening := _any_locked()
	var changes := {}
	for lock in stages.floor_locks():
		changes[lock.leaf().id] = {"open": opening, "locked": not opening}
	return {"ok": true, "changes": changes}


## Bound: the label names what the next press does, and again after every answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_relabel):
		parts.applied.connect(_relabel)
	_relabel({})


func _any_locked() -> bool:
	if stages == null:
		return true
	for lock in stages.floor_locks():
		if lock.is_locked():
			return true
	return false


func _relabel(_ev: Dictionary) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
