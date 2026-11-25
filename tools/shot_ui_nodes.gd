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


## core/115: the Stage bar's fill at a share (a `--do` step `call`s these), the numbers made up.
func fill_05() -> void:
	_fill_at(0.05)


func fill_50() -> void:
	_fill_at(0.5)


func fill_100() -> void:
	_fill_at(1.0)


func _fill_at(share: float) -> void:
	_bar.set_process(false)  # with no run in the scene the bar would hide itself
	_bar.visible = true
	_bar.call(&"_set_text", {"text": "Stage 1: Basement  %d/100" % roundi(share * 100.0)})
	_bar.call(&"_set_icons", ["simple", "sport"] as Array[String], false)
	(_bar.get_node("%Fill") as Control).size.x = (_bar.tuning.track_size.x - 2.0 * _bar.tuning.fill_inset) * share


## core/115: subtitle rows with the plain disc: a short line, two rows, a long line over two lines.
func subtitles_short() -> void:
	_rows(["Hm."])


func subtitles_two_rows() -> void:
	_rows(["Hm.", "Not again, you sock."])


func subtitles_long() -> void:
	_rows(["Every single time I wash a load, one sock goes missing and nobody in this house ever says a word about it, not one, not ever."])


func _rows(lines: Array[String]) -> void:
	var s := (load("res://game/voice/subtitles.tscn") as PackedScene).instantiate() as Subtitles
	add_child(s)
	for i in lines.size():
		s.show_line(StringName("c%d" % i), i, null, lines[i])
