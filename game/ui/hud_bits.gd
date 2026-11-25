## The HUD's small pieces, each an instanced scene (core/111): an icon, a text, the Size box. Their looks are the
## scenes' and the theme's; these only fill in what a row says.
class_name HudBits
extends RefCounted

const ICON := preload("res://game/ui/ui_icon.tscn")
const LABEL := preload("res://game/ui/hud_label.tscn")
const SIZE_BOX := preload("res://game/ui/size_box.tscn")


## A picture of icon `key` drawn `px` wide and high.
static func icon(key: String, px: float) -> TextureRect:
	var t := ICON.instantiate() as TextureRect
	t.name = "Icon_" + key
	t.texture = UiIcons.texture(key)
	t.custom_minimum_size = Vector2(px, px)
	return t


## A text in theme variation `variation`.
static func label(text: String, variation: StringName) -> Label:
	var l := LABEL.instantiate() as Label
	l.text = text
	l.theme_type_variation = variation
	return l


## The Size letter in its small rounded box (the old UiBits.size_box at 28 pt).
static func size_box(letter: String) -> PanelContainer:
	var box := SIZE_BOX.instantiate() as PanelContainer
	(box.get_child(0) as Label).text = letter
	return box
