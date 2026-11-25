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
	_fit()


func text() -> String:
	return _label.text


func has_icon() -> bool:
	return _icon.texture != null


## The words take only the width their text needs (at most what the row has left of the icon), so the icon
## sits against the text's left edge and the pair stays centred, on one line and on two.
func _fit() -> void:
	var parent := get_parent_control()
	var room := 100000.0 if parent == null or parent.size.x <= 0.0 else parent.size.x
	var lead: Control = _icon if _icon.visible else _disc
	var left := maxf(room - lead.custom_minimum_size.x - float(get_theme_constant(&"separation")), 1.0)
	var font := _label.get_theme_font(&"font")
	var font_size := _label.get_theme_font_size(&"font_size")
	var wanted := font.get_multiline_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, left, font_size).x
	_label.custom_minimum_size.x = minf(ceilf(wanted) + 2.0, left)
