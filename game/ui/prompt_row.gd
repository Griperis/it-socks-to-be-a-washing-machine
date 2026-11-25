## One Prompt as KEY, ICON, Name in a text variation (core/111: the HUD's prompt row, an instanced scene). Its gap is
## the theme variation HudRow's.
class_name PromptRow
extends HBoxContainer

## Keys are drawn 1.5 times their text's size, icons 1.3.
const KEY_SCALE := 1.5
const ICON_SCALE := 1.3


## Fills the row with `p`'s keys, icon and title; the title is in theme variation `variation` of `font` pt.
func fill(p: Prompt, variation: StringName, font: int) -> void:
	for k in p.keys:
		add_child(HudBits.icon(k, font * KEY_SCALE))
	if p.icon != "":
		add_child(HudBits.icon(UiIcons.or_simple(p.icon), font * ICON_SCALE))
	add_child(HudBits.label(p.title, variation))
