## The F3 stats overlay (Profily through game/debug/profiler.gd): there in a debug build, hidden
## at start-up, F3 shows and hides it, and a release build's F3 does nothing. Removed with the
## add-on by kit/tools/setup.py --profily=no.
extends TestSuite


func cases() -> Array[Dictionary]:
	return [
		{"name": "hidden", "method": "case_hidden", "world": false,
				"title": "Profily is loaded in a debug build, hidden at start-up, with its own hotkeys off"},
		{"name": "f3", "method": "case_f3", "world": false,
				"title": "the toggle_profiler action (F3) shows it and hides it again"},
		{"name": "release", "method": "case_release", "world": false,
				"title": "when not allowed (a release build), F3 shows nothing"},
	]


func _before_case() -> void:
	Profiler.hide_it()


func case_hidden() -> void:
	_check(Profiler.node() != null, "the Profily autoload is there")
	_check(not Profiler.shown(), "it starts hidden")
	_check(ProjectSettings.get_setting("profily/hotkeys/enabled") == false, "its own hotkeys are off")
	var keys := InputMap.action_get_events("toggle_profiler")
	_check(keys.size() == 1 and (keys[0] as InputEventKey).physical_keycode == KEY_F3, "toggle_profiler is F3")


func case_f3() -> void:
	var press := InputEventAction.new()
	press.action = "toggle_profiler"
	press.pressed = true
	Input.parse_input_event(press)
	await _until(func() -> bool: return Profiler.shown(), "F3 to show it")
	Input.parse_input_event(press)
	await _until(func() -> bool: return not Profiler.shown(), "F3 again to hide it")


func case_release() -> void:
	Profiler.allowed = false
	_check(not Profiler.toggle(), "the toggle refuses")
	_check(not Profiler.shown(), "and nothing shows")
	Profiler.allowed = true
