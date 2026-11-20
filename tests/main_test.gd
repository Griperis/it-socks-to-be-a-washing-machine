## The example suite: the placeholder main scene boots, and a click on its square counts.
## Copy its shape for every new suite: any `tests/<name>_test.gd` is found by the runner, no list to edit.
extends TestSuite


func cases() -> Array[Dictionary]:
	return [
		{"name": "boots", "method": "case_boots", "world": true,
				"title": "the main scene boots and says it runs"},
		{"name": "click", "method": "case_click", "world": true,
				"title": "a real left click on the square, through the viewport, counts on the label"},
		{"name": "roundtrip", "method": "case_roundtrip", "world": false,
				"title": "a dictionary survives the save text round-trip"},
	]


func case_boots() -> void:
	var label := world.get_node("Label") as Label
	_check(label != null, "the main scene has its label")
	if label != null:
		_check(label.text == "It runs", "the label says it runs (got '%s')" % label.text)


func case_click() -> void:
	var square := world.get_node("Square") as ColorRect
	var before: Color = square.color
	# The real path: a mouse press at the square's place goes into the viewport, as a mouse's
	# does (in the viewport's own coordinates), and reaches the square through the scene's own wiring. (Calling world.click() or
	# emitting gui_input by hand would pass even if the square had stopped taking the mouse.)
	var at := square.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = pressed
		world.get_viewport().push_input(ev, true)
	await _until(func() -> bool: return world.get("clicks") == 1, "the click to count")
	var label := world.get_node("Label") as Label
	_check(label.text == "It runs (clicked 1)", "the label counts the click (got '%s')" % label.text)
	_check(square.color != before, "the square changes colour")


func case_roundtrip() -> void:
	var back := _roundtrip({"clicks": 3})
	_near(float(back.get("clicks", 0)), 3.0, 0.0, "the number comes back")
