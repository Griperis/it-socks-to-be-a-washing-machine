## One section of the Upgrade menu (Personal or House): its heading (the currency's icon and the title) and
## its grid. fill() instances one `upgrade_button.tscn` per Upgrade at its cell and one `upgrade_spacer.tscn`
## per empty cell; a row no listed Upgrade stands in is closed up (the old UM:120-175).
class_name UpgradeSection
extends VBoxContainer

const BUTTON := preload("res://game/ui/upgrade_menu/upgrade_button.tscn")
const SPACER := preload("res://game/ui/upgrade_menu/upgrade_spacer.tscn")
const TITLES := {Upgrade.Section.PERSONAL: "Personal", Upgrade.Section.HOUSE: "House"}

@export var tuning: UpgradeMenuTuning = preload("res://game/ui/upgrade_menu/upgrade_menu_tuning.tres")

## The section it shows.
var section := Upgrade.Section.PERSONAL
## Its grid as rows, top to bottom, of buttons left to right with their columns: [[{"col", "button"}]]
## (the pad's route).
var rows: Array = []

@onready var _icon: TextureRect = %Icon
@onready var _heading: Label = %Heading
@onready var _grid: GridContainer = %Grid


## Shows `ups` (all of section `of`) at their cells, paid with `currency`. Returns the buttons made.
func fill(of: Upgrade.Section, ups: Array[Upgrade], currency: Currency) -> Array[UpgradeButton]:
	section = of
	name = TITLES[of]
	_heading.text = TITLES[of]
	_heading.theme_type_variation = &"SectionHeadingHouse" if of == Upgrade.Section.HOUSE else &"Heading2"
	_icon.texture = currency.icon if currency != null else null
	_grid.add_theme_constant_override(&"h_separation", tuning.gap)
	_grid.add_theme_constant_override(&"v_separation", tuning.gap)
	var used: Array[int] = []
	var cols := 0
	for u in ups:
		if not used.has(u.cell.x):
			used.append(u.cell.x)
		cols = maxi(cols, u.cell.y + 1)
	used.sort()
	_grid.columns = maxi(cols, 1)
	var at := {}
	for u in ups:
		at[Vector2i(used.find(u.cell.x), u.cell.y)] = u
	var made: Array[UpgradeButton] = []
	rows = []
	for r in used.size():
		var row: Array = []
		for c in cols:
			if at.has(Vector2i(r, c)):
				var b := BUTTON.instantiate() as UpgradeButton
				_grid.add_child(b)
				b.setup(at[Vector2i(r, c)] as Upgrade, currency.icon if currency != null else null)
				row.append({"col": c, "button": b})
				made.append(b)
			else:
				var gap := SPACER.instantiate() as Control
				gap.custom_minimum_size = Vector2.ONE * tuning.cell
				_grid.add_child(gap)
		rows.append(row)
	return made
