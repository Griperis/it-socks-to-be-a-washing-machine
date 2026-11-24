## The Options page (the old OptionsView; the kit's options/ template, rows rebuilt to the old ones,
## core/58): one row per setting, in the old order, each a ChoiceRow or SliderRow placed in the scene
## by hand. A change is applied at once and kept per machine by Settings (never in a save or the
## profile, Q2565). Picking a graphics preset puts SSAO back to the preset's own; the SSAO row always
## shows what is in force. Opened from the title and from the ESC menu; Back (or Esc) closes it.
class_name OptionsScreen
extends Control

signal closed

@onready var _rows: Container = %Rows
@onready var _back: CloseButton = %Back


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for row in rows():
		row.connect(&"picked", _on_picked)
	_back.pressed.connect(close)
	refresh()
	var first := rows()[0] as ChoiceRow if not rows().is_empty() else null
	if first != null and first.key_of(first.shown()) != null:
		first.key_of(first.shown()).grab_focus()


## Every row, in order.
func rows() -> Array[Control]:
	var out: Array[Control] = []
	for c in _rows.get_children():
		if c is ChoiceRow or c is SliderRow:
			out.append(c as Control)
	return out


## The row of setting `key`, or null.
func row_of(key: String) -> Control:
	for row in rows():
		if String(row.get(&"key")) == key:
			return row
	return null


## Shows what Settings holds now.
func refresh() -> void:
	for row in rows():
		var key := String(row.get(&"key"))
		var value: Variant = Settings.get_value(key)
		if key == Settings.SSAO:
			value = 1 if GraphicsPreset.ssao_on(GraphicsPreset.chosen()) else 0
		if row is ChoiceRow:
			(row as ChoiceRow).show_value(value)
		elif row is SliderRow:
			(row as SliderRow).show_value(value)


## Closes the page: it frees itself and says so.
func close() -> void:
	closed.emit()
	queue_free()


func _on_picked(key: String, value: Variant) -> void:
	Settings.set_value(key, value)
	if key == Settings.GRAPHICS_PRESET:
		Settings.set_value(Settings.SSAO, -1)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
