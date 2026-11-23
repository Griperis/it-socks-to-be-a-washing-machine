## A zoo switch at the Furniture station that locks or unlocks one Cabinet for every player (assets/07,
## Q2507): what a Stage's unlock will do once Cabinet locks exist (M4), so the dust sheet's pull-off can
## be tried. It holds no state of its own: its use asks `switch`, and the Host's answer is the
## Cabinet's own lock patch (Cabinet.lock_patch), the Rows kept. Its Looks' label says the lock.
class_name CabinetLockSwitch
extends Part

## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"
const SWITCH := &"switch"

## The Cabinet it locks and unlocks.
@export var cabinet: Cabinet
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


## The prompt and the label: "Sport Cabinet: locked".
func prompt_title() -> String:
	if cabinet == null:
		return ""
	return "Cabinet: %s" % ("locked" if cabinet.locked else "unlocked")


func use(player: int) -> void:
	if cabinet != null:
		parts.ask(Command.new(SWITCH, player, id, {"locked": not cabinet.locked}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {"locked": TYPE_BOOL}, "rate": 5}}


func decide(cmd: Command) -> Dictionary:
	var to: Variant = cmd.args.get("locked")
	if cmd.kind != SWITCH or not (to is bool) or cabinet == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	if to == cabinet.locked:
		return refuse("already")
	return {"ok": true, "changes": cabinet.lock_patch(to, cabinet.rows)}


## Bound: the label says the lock now, and again after every answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_relabel):
		parts.applied.connect(_relabel)
	_relabel({})


func _relabel(_ev: Dictionary) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
