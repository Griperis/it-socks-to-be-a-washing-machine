## The settings template (game/settings/settings.gd): defaults, the file round-trip, change signals,
## plain data only, and the engine-owned keys. Each case builds its own Settings on a test file.
extends TestSuite

const SettingsScript := preload("res://game/settings/settings.gd")
const FILE := "user://test_settings.json"
## Set by the script below when the engine builds it: proof that a file built an object.
const SPY := "user://test_settings_spy.gd"


func cases() -> Array[Dictionary]:
	return [
		{"name": "defaults", "method": "case_defaults", "world": false,
				"title": "with no file every setting has its default"},
		{"name": "roundtrip", "method": "case_roundtrip", "world": false,
				"title": "a saved setting comes back from the file with its type"},
		{"name": "changed", "method": "case_changed", "world": false,
				"title": "changed(key) fires once per real change, never for the same value"},
		{"name": "plain_only", "method": "case_plain_only", "world": false,
				"title": "an Object is refused, never stored"},
		{"name": "load_drops", "method": "case_load_drops", "world": false,
				"title": "a file holding an Object or a wrong type is read without them"},
		{"name": "builds_nothing", "method": "case_builds_nothing", "world": false,
				"title": "an Object written into the file is never built, while ConfigFile and str_to_var do build it"},
		{"name": "atomic", "method": "case_atomic", "world": false,
				"title": "a save replaces the file whole and leaves no temp file; a broken file reads as defaults"},
		{"name": "engine_owned", "method": "case_engine_owned", "world": false,
				"title": "master volume reaches the audio bus, and zero mutes it"},
		{"name": "reset", "method": "case_reset", "world": false,
				"title": "reset_to_defaults puts every key back and empties the file"},
		{"name": "game_keys", "method": "case_game_keys", "world": false,
				"title": "a game registers its own keys and reads them typed"},
	]


func _before_case() -> void:
	_remove_file()


func _remove_file() -> void:
	var abs_path := ProjectSettings.globalize_path(FILE)
	if FileAccess.file_exists(FILE):
		DirAccess.remove_absolute(abs_path)


## A Settings on the test file, in the tree, loaded.
func _make() -> SettingsScript:
	var s: SettingsScript = SettingsScript.new()
	s.path = FILE
	add_child(s)
	return s


func case_defaults() -> void:
	var s := _make()
	_near(s.master_volume, 1.0, 0.0001, "master volume starts full")
	_check(s.vsync, "vsync starts on")
	_check(s.window_mode == "windowed", "the window starts windowed (got %s)" % s.window_mode)
	_check(s.get_value("game/unknown", 7) == 7, "an unknown key gives the fallback")
	s.queue_free()


func case_roundtrip() -> void:
	var s := _make()
	s.register({"game/zoom": Vector2(1, 1), "game/name": "Ann", "game/level": 3})
	s.set_value("game/zoom", Vector2(2, 3))
	s.set_value("game/level", 5)
	s.master_volume = 0.25
	s.vsync = false
	s.free()
	var back := _make()
	back.register({"game/zoom": Vector2(1, 1), "game/name": "Ann", "game/level": 3})
	back.load_file()
	_check(back.get_value("game/zoom") == Vector2(2, 3), "a Vector2 comes back as a Vector2")
	_check(back.get_int("game/level") == 5 and typeof(back.get_value("game/level")) == TYPE_INT, "an int stays an int")
	_near(back.master_volume, 0.25, 0.0001, "the volume comes back")
	_check(not back.vsync, "vsync off comes back")
	_check(back.get_string("game/name") == "Ann", "a key never set keeps its default")
	back.master_volume = 1.0
	back.queue_free()


func case_changed() -> void:
	var s := _make()
	var seen: Array[String] = []
	s.changed.connect(func(key: String) -> void: seen.append(key))
	s.master_volume = 0.5
	s.master_volume = 0.5
	s.vsync = true  # already its default
	s.vsync = false
	_check(seen == ["audio/master_volume", "display/vsync"], "one signal per real change (got %s)" % [seen])
	s.master_volume = 1.0
	s.queue_free()


func case_plain_only() -> void:
	var s := _make()
	s.register({"game/thing": 1})
	_check(not s.set_value("game/thing", InputEventKey.new()), "an InputEvent is refused")
	_check(_logged("must be plain data"), "the refusal is in the log")
	_check(not s.set_value("game/thing", [1, {"deep": Node.new()}]), "an Object hidden in an Array is refused too")
	_check(_logged("must be plain data"), "the second refusal is in the log")
	_check(s.get_int("game/thing") == 1, "the old value stays")
	_check(not s.set_value("game/thing", "text"), "a String for an int key is refused")
	_check(_logged("wrong type"), "the wrong type is in the log")
	_check(SettingsScript.is_plain({"a": [1, 2.5, "x", Vector2.ONE, Color.RED]}), "plain data is plain")
	s.queue_free()


func case_load_drops() -> void:
	# A file written by someone else: an Object's encoding, a string where a float belongs, a whole
	# number typed by hand where a float and where an int belong, and one honest value.
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	f.store_string('{"audio/master_volume": "s:loud", "game/bad": {"type": "InputEventKey", "props": ["keycode", "i:65"]},'
			+ ' "game/score": "i:4", "game/level": 7, "game/name": "typed by hand", "display/vsync": false, "nosection": 1}')
	f.close()
	var s: SettingsScript = SettingsScript.new()
	s.path = FILE
	s.register({"game/score": 0.0, "game/level": 1, "game/name": ""})
	add_child(s)
	_near(s.master_volume, 1.0, 0.0001, "a wrong-typed value falls back to the default")
	_check(s.get_value("game/bad") == null, "an Object in the file is not loaded")
	_check(s.get_value("game/score") == 4.0 and typeof(s.get_value("game/score")) == TYPE_FLOAT, "an int in the file becomes the float the default has")
	_check(s.get_value("game/level") == 7 and typeof(s.get_value("game/level")) == TYPE_INT, "a whole number typed by hand becomes the int the default has")
	_check(s.get_string("game/name") == "typed by hand", "a text typed by hand is read as it is")
	_check(not s.vsync, "an honest value is loaded")
	_check(s.get_value("nosection") == null, "a key without a section is not loaded")
	s.queue_free()


## Why the file is JSON: the same Object text builds a live object, and runs its script, in the two
## parsers the file could have used; in this one it builds nothing.
func case_builds_nothing() -> void:
	var src := FileAccess.open(SPY, FileAccess.WRITE)
	src.store_string("extends RefCounted\nfunc _init() -> void:\n\tEngine.set_meta(&\"settings_spy\", int(Engine.get_meta(&\"settings_spy\", 0)) + 1)\n")
	src.close()
	Engine.set_meta(&"settings_spy", 0)
	var as_text := 'Object(RefCounted,"script":Resource("%s"))' % SPY
	_check(typeof(str_to_var(as_text)) == TYPE_OBJECT and int(Engine.get_meta(&"settings_spy")) == 1,
			"str_to_var builds the object and runs its script while it parses")
	var cfg := FileAccess.open("user://test_settings_spy.cfg", FileAccess.WRITE)
	cfg.store_string("[game]\nbad=%s\n" % as_text)
	cfg.close()
	var cf := ConfigFile.new()
	cf.load("user://test_settings_spy.cfg")
	_check(int(Engine.get_meta(&"settings_spy")) == 2, "ConfigFile.load does too, before any check can look at the value")
	# The same object as JSON.from_native(x, true) writes it, in a settings file.
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	f.store_string('{"game/bad": {"type": "RefCounted", "props": ["script", "s:%s"]},' % SPY
			+ ' "game/list": [{"type": "RefCounted", "props": ["script", "s:%s"]}],' % SPY
			+ ' "game/typed": {"type": "Array", "elem_type": "%s", "args": []}, "game/ok": "i:3"}' % SPY)
	f.close()
	var s := _make()
	_check(int(Engine.get_meta(&"settings_spy")) == 2, "Settings builds nothing from the file (the script ran %d times in all)" % int(Engine.get_meta(&"settings_spy")))
	_check(s.get_value("game/bad") == null and s.get_value("game/list") == null and s.get_value("game/typed") == null,
			"and keeps none of the three values")
	_check(s.get_value("game/ok") == 3, "the honest value beside them is loaded")
	Engine.remove_meta(&"settings_spy")
	for leftover: String in [SPY, "user://test_settings_spy.cfg"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(leftover))
	s.queue_free()


func case_atomic() -> void:
	var s := _make()
	s.master_volume = 0.3
	_check(FileAccess.file_exists(FILE) and not FileAccess.file_exists(FILE + ".tmp"), "the file is there and the temp file is gone")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	_check(parsed is Dictionary and (parsed as Dictionary).get("audio/master_volume") == "f:0.3",
			"the file is JSON, a float marked as a float (got %s)" % [parsed])
	s.master_volume = 1.0
	s.free()
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	f.store_string('{"audio/master_volume": "f:0.')
	f.close()
	var back := _make()
	_near(back.master_volume, 1.0, 0.0001, "a file cut off mid-write reads as defaults, with no error")
	back.queue_free()


func case_engine_owned() -> void:
	var s := _make()
	var bus := AudioServer.get_bus_index("Master")
	var before := AudioServer.get_bus_volume_db(bus)
	s.master_volume = 0.5
	_near(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.001, "half volume is on the Master bus")
	s.master_volume = 0.0
	_check(AudioServer.is_bus_mute(bus), "zero mutes the bus")
	s.master_volume = 1.0
	_check(not AudioServer.is_bus_mute(bus), "full volume unmutes it")
	_near(AudioServer.get_bus_volume_db(bus), before, 0.001, "and puts the level back")
	# Window mode and vsync are applied the same way; a headless run has no window to look at.
	s.window_mode = "fullscreen"
	s.window_mode = "windowed"
	_check(s.window_mode == "windowed", "the window mode is kept")
	s.queue_free()


func case_reset() -> void:
	var s := _make()
	s.master_volume = 0.1
	s.vsync = false
	var seen: Array[String] = []
	s.changed.connect(func(key: String) -> void: seen.append(key))
	s.reset_to_defaults()
	_near(s.master_volume, 1.0, 0.0001, "the volume is back")
	_check(s.vsync, "vsync is back")
	_check(seen.size() == 2, "each changed key said so (got %s)" % [seen])
	var left: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	_check(left is Dictionary and (left as Dictionary).is_empty(), "the file holds nothing set")
	s.queue_free()


func case_game_keys() -> void:
	var s := _make()
	s.register({"game/difficulty": 1, "game/subtitles": true, "game/tint": Color.WHITE})
	_check(s.get_int("game/difficulty") == 1 and s.get_bool("game/subtitles"), "the game's defaults read typed")
	s.set_value("game/difficulty", 2)
	_check(s.get_int("game/difficulty") == 2, "a game key can be set")
	_check(not s.set_value("nodash", 1), "a key without a section is refused")
	_check(_logged("section/name key"), "the bad key is in the log")
	_check(s.keys_under("game/") == ["game/difficulty"], "keys_under lists what is set under a prefix")
	s.queue_free()


## True when one of the last few log lines is an ERROR holding `part` (the game reports a refusal through
## Log, which raises no engine error).
func _logged(part: String) -> bool:
	for line: String in Log.recent(6):
		if "ERROR" in line and part in line:
			return true
	return false
