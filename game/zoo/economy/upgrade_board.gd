## The Economy station's board of every Upgrade (Q2337: built from the data at load): one row per `.tres`
## in the Upgrades folder (Upgrades.listed()), icon and a line: its title, section, this player's level of
## its levels, the prices, what it needs and its stat's now -> top ("Coming soon" with none). A new file
## shows here with no other change. Looks only.
class_name UpgradeBoard
extends Node3D

const ROW := preload("res://game/zoo/economy/upgrade_board_row.tscn")
const SECTIONS := {Upgrade.Section.PERSONAL: "Personal", Upgrade.Section.HOUSE: "House"}
const LINE := "%s  [%s]  %d/%d  prices %s%s  %s"
const NEEDS := "  needs %s"
const SOON := "Coming soon"
const STAT := "%s: %s -> %s"
## How often the levels are read again, in seconds.
const EVERY := 0.5

## The Upgrades whose levels it shows.
@export var upgrades: Upgrades
## The distance between two rows, in metres.
@export var row_gap := 0.12

var _rows: Dictionary[StringName, UpgradeBoardRow] = {}
var _since := 0.0


func _ready() -> void:
	var i := 0
	for u in Upgrades.listed():
		var row := ROW.instantiate() as UpgradeBoardRow
		add_child(row)
		row.position = Vector3(0.0, -i * row_gap, 0.0)
		row.icon.texture = u.icon
		_rows[u.id()] = row
		i += 1
	_relabel()


func _process(delta: float) -> void:
	_since += delta
	if _since >= EVERY:
		_since = 0.0
		_relabel()


## Every row's line now.
func _relabel() -> void:
	var me := multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST
	for u in Upgrades.listed():
		var row: UpgradeBoardRow = _rows.get(u.id())
		if row != null:
			var text := line_of(u, upgrades, me)
			if row.text.text != text:
				row.text.text = text


## The board's line for `u`, for player `by` of `levels` (null: level 0).
static func line_of(u: Upgrade, levels: Upgrades, by: int) -> String:
	var prices := PackedStringArray()
	for p in u.prices:
		prices.append(str(p))
	var lacking := PackedStringArray()
	for need: Upgrade in u.needs:
		lacking.append("%s %d" % [need.title, int(u.needs[need])])
	var stat := SOON
	if u.stat != null:
		var at := levels.stat_level(u.stat, by) if levels != null else 0
		stat = STAT % [u.stat.resource_path.get_file().get_basename(), _number(u.stat, at), _number(u.stat, at - (levels.level(u, by) if levels != null else 0) + u.top())]
	var lv := levels.level(u, by) if levels != null else 0
	return LINE % [u.full_title(), SECTIONS[u.section], lv, u.top(), "/".join(prices),
			NEEDS % ", ".join(lacking) if not lacking.is_empty() else "", stat]


static func _number(stat: UpgradeStat, level: int) -> String:
	var t := stat.text_at(level)
	return t if t != "" else str(stat.value_at(level))
