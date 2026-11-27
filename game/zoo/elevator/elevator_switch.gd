## A zoo pillar at the Elevator station (core/155): "Repair" buys or takes back Elevator Repair, "Open upper floor"
## opens (or locks again) the station's upper floor, "Fast Elevator +1" and "Roomy Car +1" raise their level (past
## the top back to none). It holds no state: its use asks `switch` and the Host answers with the station's own
## Upgrades' or Stages' patch, shown by every machine.
class_name ElevatorSwitch
extends Part

## What a switch does.
enum Does { REPAIR, OPEN_UPPER, FAST, ROOMY }

const SWITCH := &"switch"
const LABEL := ^"../Looks/Label"
## placeholder: zoo wording
const REPAIR_TITLE := "Repair: %s"
const OPEN_TITLE := "Open upper floor"
const LOCK_TITLE := "Lock upper floor"
const RAISE_TITLE := "%s +1 (%d/%d)"
## The Upgrades the switches raise, by id.
const IDS := {Does.REPAIR: &"elevator_repair", Does.FAST: &"fast_elevator", Does.ROOMY: &"roomy_car"}
## The station's upper floor (its mini plan's second Stage).
const UPPER := 1

## The station's Upgrades and its run.
@export var upgrades: Upgrades
@export var stages: Stages
@export var does := Does.REPAIR
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	if does == Does.OPEN_UPPER:
		return LOCK_TITLE if stages != null and stages.floor_open(UPPER) else OPEN_TITLE
	var u := _upgrade()
	var lv := upgrades.level(u, Parts.HOST) if upgrades != null and u != null else 0
	if does == Does.REPAIR:
		return REPAIR_TITLE % ("on" if lv > 0 else "off")
	return RAISE_TITLE % [u.title if u != null else "", lv, u.top() if u != null else 0]


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	if does == Does.OPEN_UPPER:
		if stages == null or stages.stage < 0:
			return refuse("wrong")
		return stages.grant({"stage": 0 if stages.floor_open(UPPER) else UPPER})
	var u := _upgrade()
	if upgrades == null or u == null:
		return refuse("wrong")
	var house := upgrades.house.duplicate()
	var lv := upgrades.level(u, Parts.HOST)
	house[String(u.id())] = 0 if lv >= u.top() else lv + 1
	return upgrades.grant({"house": house})


## Bound: the label names what the next press does, and again after every answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_relabel):
		parts.applied.connect(_relabel)
	_relabel({})


func _upgrade() -> Upgrade:
	return upgrades.upgrade_of(IDS[does]) if upgrades != null and IDS.has(does) else null


func _relabel(_ev: Dictionary) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
