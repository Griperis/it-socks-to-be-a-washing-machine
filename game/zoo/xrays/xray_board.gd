## The X-rays station's board (core/182, Q2337: built from the data at load): one row per XRayAbility
## file (XRays.listed()): its Upgrade's icon, its key cap, its words, and a line per Upgrade of its
## stats with this player's level and the stat's now -> top ("xray_cooldown: 50s -> 30s"). A dropped
## ability file shows its row with no other change. Looks only.
class_name XRayBoard
extends Node3D

const ROW := preload("res://game/zoo/xrays/xray_board_row.tscn")
const HEAD := "%s  (key %s)  \"%s\"  %s"
const KINDS := {XRayAbility.Shows.MATES: "shows mates", XRayAbility.Shows.CABINET: "shows the Cabinet"}
const LINE := "  %s  %d/%d  %s: %s -> %s"
## How often the levels are read again, in seconds.
const EVERY := 0.5

## The level's Upgrades whose levels it shows.
@export var upgrades: Upgrades
## The distance between two rows, in metres.
@export var row_gap := 0.6

var _rows: Array[XRayBoardRow] = []
var _abilities: Array[XRayAbility] = []
var _since := 0.0


func _ready() -> void:
	_abilities = XRays.listed()
	for i in _abilities.size():
		var a := _abilities[i]
		var row := ROW.instantiate() as XRayBoardRow
		add_child(row)
		row.position = Vector3(0.0, -i * row_gap, 0.0)
		row.icon.texture = a.upgrade.icon if a.upgrade != null else null
		row.key.texture = a.key_icon
		_rows.append(row)
	_relabel()


func _process(delta: float) -> void:
	_since += delta
	if _since >= EVERY:
		_since = 0.0
		_relabel()


## The row of each ability, in order.
func rows() -> Array[XRayBoardRow]:
	return _rows


func _relabel() -> void:
	var me := multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST
	var all := upgrades.all() if upgrades != null else Upgrades.listed()
	for i in _rows.size():
		var text := text_of(_abilities[i], all, upgrades, me)
		if _rows[i].text.text != text:
			_rows[i].text.text = text


## The row's words for `ability`, for player `by` of `levels` (null: level 0).
static func text_of(ability: XRayAbility, all: Array[Upgrade], levels: Upgrades, by: int) -> String:
	var key := ability.action
	var events := InputMap.action_get_events(key) if InputMap.has_action(key) else []
	var key_name := "?"
	for e: InputEvent in events:
		if e is InputEventKey:
			key_name = OS.get_keycode_string((e as InputEventKey).physical_keycode)
			break
	var lines := PackedStringArray([HEAD % [ability.name, key_name, ability.on_text, KINDS[ability.shows]]])
	for u in XRaySwitches.of_ability(ability, all):
		var lv := levels.level(u, by) if levels != null else 0
		var at := levels.stat_level(u.stat, by) if levels != null else 0
		lines.append(LINE % [u.full_title(), lv, u.top(), u.stat.resource_path.get_file().get_basename(),
				_number(u.stat, at), _number(u.stat, at - lv + u.top())])
	return "\n".join(lines)


static func _number(stat: UpgradeStat, level: int) -> String:
	var t := stat.text_at(level)
	return t if t != "" else str(stat.value_at(level))
