## One Options row of a few values (Graphics, SSAO, Display, FPS cap...): its name on the left, its
## values as small cream keycaps on the right, the chosen one orange (ChoiceOnButton). Left / Right on
## a focused value steps to the next one, no wrap, and the focus follows (Q1577). A press says
## `picked`; the Options screen writes the setting and shows it back with show_value().
class_name ChoiceRow
extends HBoxContainer

signal picked(key: String, value: Variant)

const KEY_SCENE := preload("res://game/ui/options/choice_key.tscn")
const OFF := &"ChoiceButton"
const ON := &"ChoiceOnButton"

## The setting this row shows (Settings key).
@export var key := ""
@export var title := ""
## The values, and the words on their keycaps (alike in number).
@export var values: Array = []
@export var labels: PackedStringArray = []

var _keys: Array[Button] = []
var _shown: Variant = null

@onready var _name: Label = %Name
@onready var _choices: HBoxContainer = %Choices


func _ready() -> void:
	_name.text = title
	for i in values.size():
		var b := KEY_SCENE.instantiate() as Button
		b.text = labels[i] if i < labels.size() else str(values[i])
		b.name = "Choice%d" % i
		var v: Variant = values[i]
		b.pressed.connect(func() -> void: picked.emit(key, v))
		b.gui_input.connect(_on_key_input.bind(i))
		_choices.add_child(b)
		_keys.append(b)


## Shows `value` as the chosen one (no signal).
func show_value(value: Variant) -> void:
	_shown = value
	for i in _keys.size():
		_keys[i].theme_type_variation = ON if values[i] == value else OFF


## The value shown now.
func shown() -> Variant:
	return _shown


## The keycap of value `value`, or null.
func key_of(value: Variant) -> Button:
	var i := values.find(value)
	return _keys[i] if i >= 0 else null


func _on_key_input(event: InputEvent, i: int) -> void:
	var step := 0
	if event.is_action_pressed(&"ui_right"):
		step = 1
	elif event.is_action_pressed(&"ui_left"):
		step = -1
	if step == 0:
		return
	var j := clampi(i + step, 0, _keys.size() - 1)
	get_viewport().set_input_as_handled()
	if j != i:
		_keys[j].grab_focus()
		picked.emit(key, values[j])
