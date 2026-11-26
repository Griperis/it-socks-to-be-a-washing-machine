## A zoo switch at the Economy station for the Upgrades: "Reset levels" sets every level back to 0 (every
## player's and the team's); "Co-op" counts the zoo as co-op though alone, so the co-op-only Upgrades show
## (Q1357, Q1399). It holds no state: its use asks `switch` and the Host answers with the Upgrades' own
## patch.
class_name UpgradesSwitch
extends Part

## What a switch does.
enum Does { RESET, COOP }

const SWITCH := &"switch"
const LABEL := ^"../Looks/Label"
const RESET_TITLE := "Reset levels"
const COOP_TITLE := "Co-op: %s"

## The Upgrades it switches.
@export var upgrades: Upgrades
@export var does := Does.RESET
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	if does == Does.RESET:
		return RESET_TITLE
	return COOP_TITLE % ("on" if upgrades != null and upgrades.coop else "off")


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or upgrades == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	if does == Does.RESET:
		return upgrades.grant({"personal": {}, "house": {}})
	return upgrades.grant({"coop": not upgrades.coop})


func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_relabel):
		parts.applied.connect(_relabel)
	_relabel({})


func _relabel(_ev: Dictionary) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
