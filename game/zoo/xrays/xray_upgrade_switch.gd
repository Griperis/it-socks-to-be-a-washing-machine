## A zoo switch at the X-rays station for one X-ray Upgrade (core/182): each use raises the user's level
## by one, "Own" it at 0, "Level up" it below its top, "Reset" it to 0 at its top, so every effect can
## be tried without Coins. It holds no state: its use asks `switch` and the Host answers with the
## Upgrades' own level patch. Made at load by XRaySwitches, one per Upgrade found by its stat.
class_name XRayUpgradeSwitch
extends Part

## Links the wiring check lets stay empty: XRaySwitches sets them as it makes the switch.
const WIRING_OPTIONAL := ["upgrades"]
const SWITCH := &"switch"
const LABEL := ^"../Looks/Label"
## placeholder: zoo wording
const OWN := "Own %s"
const LEVEL_UP := "Level up %s (%d/%d)"
const RESET := "Reset %s"

## The Upgrade it switches, and the level's Upgrades whose levels it changes.
@export var upgrade: Upgrade
@export var upgrades: Upgrades
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	if upgrade == null:
		return ""
	var me := multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST
	var lv := upgrades.level(upgrade, me) if upgrades != null else 0
	if lv <= 0:
		return OWN % upgrade.title
	if lv >= upgrade.top():
		return RESET % upgrade.title
	return LEVEL_UP % [upgrade.title, lv, upgrade.top()]


func use(by: int) -> void:
	parts.ask(Command.new(SWITCH, by, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 5}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or upgrades == null or upgrade == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	var lv := upgrades.level(upgrade, cmd.by)
	var to := 0 if lv >= upgrade.top() else lv + 1
	return upgrades.grant(upgrades.level_patch(upgrade, cmd.by, to))


## Bound: the label names what the next press does, and again after every answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_relabel):
		parts.applied.connect(_relabel)
	_relabel({})


func _relabel(_ev: Dictionary) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
