## The close key every dialogue shows at its top right, always in the same place (Q2578): the ESC
## keycap, icon only, on the Theme's `CloseButton`. Put this scene as a child of the dialogue's panel
## (it fills the panel and ignores the mouse; only the key answers), connect `pressed`, and Esc (a
## pad's B) is the dialogue's own `ui_cancel` handler. Every one is in the group
## `close_button`, so a case can find them all.
class_name CloseButton
extends Control

## The key was clicked (or pressed with the pad or Enter while focused).
signal pressed

const GROUP := &"close_button"

@onready var _key: Button = %Key


func _ready() -> void:
	add_to_group(GROUP)
	_key.pressed.connect(pressed.emit)


## The key itself (for a test that clicks it).
func key() -> Button:
	return _key
