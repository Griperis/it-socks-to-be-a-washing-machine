## The game's own log (the autoload Log, game/log/log.gd): a run of the zoo leaves its file under
## user://logs/, which starts with the build and holds an engine error with its area and script call.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"


func cases() -> Array[Dictionary]:
	return [
		{"name": "zoo_run", "method": "case_zoo_run", "world": false,
				"title": "a zoo run's log file starts with the build and holds an engine error with its area and call"},
		{"name": "autoload", "method": "case_autoload", "world": false,
				"title": "Log is the first autoload"},
	]


func case_zoo_run() -> void:
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(zoo)
	await _frames(5)
	_expect_error("the test's own fault")
	_raise()
	Log.flush()
	var path := Log.path()
	_check(path.contains("/logs/") and FileAccess.file_exists(path), "the run's file exists under logs/ (%s)" % path)
	var text := FileAccess.get_file_as_string(path)
	var lines: Array = Array(text.split("\n"))
	_check(lines[0].begins_with("# It Socks ") and lines[0].contains("build"), "it starts with the build line (got '%s')" % lines[0])
	var hit: Array = lines.filter(func(s: String) -> bool: return s.contains("ERROR [") and s.contains("the test's own fault"))
	_check(hit.size() == 1, "the engine error is in the file once")
	if hit.size() == 1:
		_check(hit[0].contains("_raise") and hit[0].contains("game_log_test.gd"), "with its script call (got '%s')" % hit[0])
		_check(hit[0].contains("[script]") or hit[0].contains("[engine]"), "with its area")
	zoo.queue_free()


func case_autoload() -> void:
	var autoloads: Array[String] = []
	for prop: Dictionary in ProjectSettings.get_property_list():
		var key: String = prop["name"]
		if key.begins_with("autoload/"):
			autoloads.append(key)
	_check(not autoloads.is_empty() and autoloads[0] == "autoload/Log", "Log is first (got %s)" % [autoloads.slice(0, 2)])


func _raise() -> void:
	push_error("the test's own fault")
