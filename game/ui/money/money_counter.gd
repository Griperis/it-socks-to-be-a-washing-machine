## One counter of the HUD (docs/architecture/economy.md "The HUD counters and the flight"): its
## Currency's icon and a number (the old 30 pt counter: no name, no outline box, no pill). It shows what
## it is told and pulses its icon when a Coin lands.
class_name MoneyCounter
extends HBoxContainer

## The currency it counts: its icon shows.
@export var currency: Currency

@onready var icon: TextureRect = $Icon
@onready var _number: Label = $Number

var _pulse: Tween = null


func _ready() -> void:
	if currency != null:
		icon.texture = currency.icon


## Shows `value` (the label is set only when it differs).
func show_amount(value: int) -> void:
	var text := str(value)
	if _number.text != text:
		_number.text = text


## The number shown now.
func amount() -> int:
	return int(_number.text)


## The icon grows to `to` and eases back over `seconds` (a landing).
func pulse(to: float, seconds: float) -> void:
	if _pulse != null:
		_pulse.kill()
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2.ONE * to
	_pulse = icon.create_tween()
	_pulse.tween_property(icon, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
