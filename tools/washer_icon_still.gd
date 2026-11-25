## Assets/15's still: the washer's subtitle icon on a real subtitle row at 1080p, over a plain room colour.
extends Control


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color(0.42, 0.36, 0.3)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var subs := (load("res://game/voice/subtitles.tscn") as PackedScene).instantiate() as Subtitles
	add_child(subs)
	var speaker := load("res://game/voice/speakers/washer.tres") as VoiceSpeaker
	subs.show_line(&"washer", speaker.priority, speaker.icon, "Oh, a sock. How original.")
	subs.show_line(&"none", 10, null, "A speaker with no icon keeps the plain disc.")
	# Among the UI icons, at their drawn size (64) and at the subtitle's (44).
	var box := VBoxContainer.new()
	box.position = Vector2(560, 300)
	add_child(box)
	for px: int in [128, 44]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		box.add_child(row)
		for key: String in ["coins", "dirty", "drawers", "carry", "animals", "washer", "emoji_yes", "key_e"]:
			var tr_ := TextureRect.new()
			tr_.texture = UiIcons.texture(key)
			tr_.custom_minimum_size = Vector2(px, px)
			tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(tr_)
