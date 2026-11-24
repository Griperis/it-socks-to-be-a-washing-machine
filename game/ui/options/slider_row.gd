## One Options row with a slider (a volume, a speed): its name, the slider and its value beside it
## ("85%", "1.25x"). A move says `picked`; the Options screen writes the setting.
class_name SliderRow
extends HBoxContainer

signal picked(key: String, value: Variant)

@export var key := ""
@export var title := ""
@export var min_value := 0.0
@export var max_value := 1.0
@export var step := 0.05
## Shown as a percent ("85%") or as a multiplier ("1.25x").
@export var percent := true

@onready var _name: Label = %Name
@onready var _slider: HSlider = %Slider
@onready var _value: Label = %Value


func _ready() -> void:
	_name.text = title
	_slider.min_value = min_value
	_slider.max_value = max_value
	_slider.step = step
	_slider.value_changed.connect(func(v: float) -> void:
		_value.text = words(v)
		picked.emit(key, v))


## Shows `value` (no signal).
func show_value(value: Variant) -> void:
	_slider.set_value_no_signal(float(value))
	_value.text = words(float(value))


func shown() -> float:
	return _slider.value


func slider() -> HSlider:
	return _slider


## The words beside the slider for `v`.
func words(v: float) -> String:
	return "%d%%" % roundi(v * 100.0) if percent else "%.2fx" % v
