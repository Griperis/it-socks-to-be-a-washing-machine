## One Lifetime tally on the Profile page (core/147): a number over its caption. The look is the scene's.
class_name TallyCell
extends VBoxContainer

@onready var _caption: Label = %Caption
@onready var _number: Label = %Number


## Shows `caption` under `value`.
func fill(caption_text: String, value: int) -> void:
	_caption.text = caption_text
	_number.text = str(value)


## The caption shown.
func caption() -> String:
	return _caption.text


## The number shown.
func number() -> String:
	return _number.text
