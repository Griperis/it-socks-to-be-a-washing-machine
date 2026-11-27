## A zoo switch at the X-rays station (core/182): "Grow a Row" gives its Cabinet one more Row (a Drawer
## module falls in on top, as a floor's opening grows it), up to the Cabinet's modules; at the top it
## puts the Cabinet back to `start` Rows. So Show Cabinet's outline can be watched following a Cabinet
## that grows (core/184). It holds no state: its use asks `switch` and the Host answers with the
## Cabinet's own `rows`.
class_name GrowRowSwitch
extends Part

const SWITCH := &"switch"
const LABEL := ^"../Looks/Label"
## placeholder: zoo wording
const GROW := "Grow a Row (%d)"
const BACK := "Back to %d Rows"

## The Cabinet it grows.
@export var cabinet: Cabinet
## The Rows it goes back to from the top.
@export_range(1, 6, 1) var start := 2
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	if cabinet == null:
		return ""
	return BACK % start if cabinet.rows >= cabinet.drawer_count() else GROW % cabinet.rows


func use(by: int) -> void:
	parts.ask(Command.new(SWITCH, by, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or cabinet == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	var to := start if cabinet.rows >= cabinet.drawer_count() else cabinet.rows + 1
	return cabinet.grant({"rows": to})


## Bound: the label names what the next press does, and again after every answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_relabel):
		parts.applied.connect(_relabel)
	_relabel({})


func _relabel(_ev: Dictionary) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
