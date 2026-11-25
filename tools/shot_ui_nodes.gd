## core/111's stills: the Stage bar with icons and a lit key, on their own (`--scene=res://tools/shot_ui_nodes.tscn`,
## then a `--do` step `call`s one of these by name). The bar is drawn straight with made-up words.
extends Node

var _bar: StageBar = null
var _keys: Array[Button] = []


func _ready() -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var back := ColorRect.new()
	back.color = Color(0.45, 0.4, 0.35)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(back)
	_bar = (load("res://game/ui/stage_bar.tscn") as PackedScene).instantiate() as StageBar
	layer.add_child(_bar)
	var row := HBoxContainer.new()
	row.position = Vector2(300, 300)
	row.add_theme_constant_override(&"separation", 40)
	layer.add_child(row)
	for t: String in ["Start", "Options", "Quit"]:
		var b := Button.new()
		b.text = t
		b.theme_type_variation = &"KeycapButton"
		row.add_child(b)
		_keys.append(b)


func stage_bar() -> void:
	_bar.visible = true
	_bar.call(&"_set_text", {"text": "Stage 1: Basement  2/4"})
	_bar.call(&"_set_icons", ["simple", "sport", "wool"] as Array[String], false)


func lit_key() -> void:
	PadFocus.pad_used = true
	_keys[1].grab_focus()
