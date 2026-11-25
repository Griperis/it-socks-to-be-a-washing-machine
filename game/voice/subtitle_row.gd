## One row of the subtitles (core/85, V6): the speaker's icon and the words, no name. A speaker with no icon
## yet shows a plain disc in the Theme's colours (the `SubtitleIcon` look); the drawn icon is assets/15.
class_name SubtitleRow
extends HBoxContainer

## The channel this row belongs to (a speaker's id, or the cutscene channel's).
var channel: StringName = &""
## Rows stack in priority order, the highest at the bottom.
var priority := 0

@onready var _icon: TextureRect = $Icon
@onready var _disc: Control = $Disc
@onready var _label: Label = $Words


## Shows `text` with `icon` (null: the plain disc).
func set_content(icon: Texture2D, text: String) -> void:
	_icon.texture = icon
	_icon.visible = icon != null
	_disc.visible = icon == null
	_label.text = text


func text() -> String:
	return _label.text


func has_icon() -> bool:
	return _icon.texture != null
