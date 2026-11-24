## One World's row in the drawer or the full page (docs/architecture/lobby.md "Core/65"): a tinted panel
## with a swatch per Group member, the name, the Host's Choose and a red Delete (co-op Worlds only),
## the details under it. A damaged World has only Delete. A Guest's row is read-only with a tick on the
## chosen one. A view: the keys only say what was pressed.
class_name WorldRow
extends PanelContainer

signal choose
signal delete

var slot := ""

@onready var _swatches: HBoxContainer = %Swatches
@onready var _tick: Label = %Tick
@onready var _title: Label = %Title
@onready var _choose: Button = %Choose
@onready var _delete: Button = %Delete
@onready var _details: Label = %Details


## Shows `row` (a Worlds.rows() entry). `chosen`: the chosen World's slot. `host`: the keys show (Choose
## only with `choosable`); `colour_of`: the Player colour of an index.
func fill(row: Dictionary, chosen: String, host: bool, choosable: bool, tuning: WorldDrawerTuning, colour_of: Callable) -> void:
	slot = String(row["slot"])
	var is_chosen := slot == chosen
	_title.text = String(row["name"])
	_details.text = String(row.get("details", ""))
	_details.visible = _details.text != ""
	for c in _swatches.get_children():
		_swatches.remove_child(c)
		c.queue_free()
	for i: Variant in row.get("colours", []):
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(14, 14)
		swatch.color = colour_of.call(int(i))
		_swatches.add_child(swatch)
	_tick.visible = is_chosen and not host
	_choose.visible = host and choosable and not bool(row.get("damaged", false))
	_choose.text = LobbyWords.CHOSEN if is_chosen else LobbyWords.CHOOSE
	_choose.disabled = is_chosen
	_delete.visible = host and slot != Worlds.SOLO
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1.0, 0.8, 0.2, tuning.chosen_tint) if is_chosen else Color(0.0, 0.0, 0.0, 0.08)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	add_theme_stylebox_override(&"panel", box)


func _ready() -> void:
	_tick.text = LobbyWords.CHOSEN_TICK
	_choose.pressed.connect(choose.emit)
	_delete.pressed.connect(delete.emit)


## The Choose key and the Delete key.
func choose_key() -> Button:
	return _choose


func delete_key() -> Button:
	return _delete
