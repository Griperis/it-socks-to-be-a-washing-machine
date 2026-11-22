## The log template (game/log/log.gd): the line's shape, levels, the file and its older runs, the
## engine's errors and plain prints taken in, the co-op tag, the size limit. Each case builds its own
## Log on a test folder.
extends TestSuite

const LogScript := preload("res://game/log/log.gd")
const DIR := "user://test_logs"
const STAMP := "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3} "

var _made: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "line", "method": "case_line", "world": false,
				"title": "a line has a time, a level, an area, the text and its data"},
		{"name": "levels", "method": "case_levels", "world": false,
				"title": "lines under the minimum level are dropped"},
		{"name": "file", "method": "case_file", "world": false,
				"title": "every line is in the run's file, and a warning is on disk at once"},
		{"name": "runs", "method": "case_runs", "world": false,
				"title": "a new run starts a fresh file and keeps the last few"},
		{"name": "engine", "method": "case_engine", "world": false,
				"title": "a push_error and a push_warning land in the log with where they came from"},
		{"name": "prints", "method": "case_prints", "world": false,
				"title": "a plain print is taken in once, and the log's own echo is not taken in again"},
		{"name": "who", "method": "case_who", "world": false,
				"title": "a co-op machine's name is in front of every line"},
		{"name": "limit", "method": "case_limit", "world": false,
				"title": "a file over its size limit is closed and a new one started"},
		{"name": "signal", "method": "case_signal", "world": false,
				"title": "logged fires once per line with its parts"},
		{"name": "removed", "method": "case_removed", "world": false,
				"title": "a Log out of the tree takes nothing more from the engine"},
	]


func _before_case() -> void:
	_made.clear()
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))


## A Log on the test folder, in the tree. Quiet: it does not print its lines.
func _log(setup: Callable = Callable()) -> Node:
	var l: Node = LogScript.new()
	l.set("dir", DIR)
	l.set("echo", false)
	l.set("min_level", 0)
	if setup.is_valid():
		setup.call(l)
	add_child(l)
	_made.append(l)
	return l


func _lines(l: Node) -> Array[String]:
	return l.call("recent")


func _file_text(name: String = "game.log") -> String:
	return FileAccess.get_file_as_string(DIR.path_join(name))


func _close(l: Node) -> void:
	remove_child(l)
	l.free()


func case_line() -> void:
	var l := _log()
	l.call("info", "orders", "order 3 done", {"id": 3, "at": [1, 2]})
	var lines := _lines(l)
	_check(lines.size() == 1, "one line (got %d)" % lines.size())
	var rx := RegEx.create_from_string(STAMP + "INFO  \\[orders\\] order 3 done \\{\"at\":\\[1,2\\],\"id\":3\\}$")
	_check(rx.search(lines[0]) != null, "the line's shape (got '%s')" % lines[0])
	l.call("error", "save", "two\nlines")
	_check(_lines(l)[1].ends_with("ERROR [save] two <- lines"), "a line break stays on one line (got '%s')" % _lines(l)[1])
	_close(l)


func case_levels() -> void:
	var l := _log(func(x: Node) -> void: x.set("min_level", 2))
	l.call("debug", "a", "d")
	l.call("info", "a", "i")
	l.call("warn", "a", "w")
	l.call("error", "a", "e")
	var lines := _lines(l)
	_check(lines.size() == 2 and lines[0].contains("WARN  [a] w") and lines[1].contains("ERROR [a] e"),
			"only the warning and the error are kept (got %s)" % [lines])
	_close(l)


func case_file() -> void:
	var l := _log()
	l.call("info", "boot", "started")
	l.call("warn", "boot", "slow start")
	# No flush asked for: the warning put both lines on disk.
	var text := _file_text()
	_check(text.contains("[boot] started") and text.contains("WARN  [boot] slow start"), "the file has both lines (got '%s')" % text)
	_check(text.begins_with("# ") and text.get_slice("\n", 0).contains("Godot ") and text.get_slice("\n", 0).contains(" build, "),
			"the file starts with the build it is of (got '%s')" % text.get_slice("\n", 0))
	_check(String(l.call("path")).ends_with("test_logs/game.log"), "path() is the file on disk (got %s)" % l.call("path"))
	_close(l)


func case_runs() -> void:
	for run in 4:
		var l := _log(func(x: Node) -> void: x.set("keep", 2))
		l.call("info", "run", "run %d" % run)
		_close(l)
	_check(_file_text().contains("run 3"), "game.log is the newest run")
	_check(_file_text("game.1.log").contains("run 2"), "game.1.log is the run before")
	_check(_file_text("game.2.log").contains("run 1"), "game.2.log is the one before that")
	_check(not FileAccess.file_exists(DIR.path_join("game.3.log")), "only `keep` older runs stay")


func case_engine() -> void:
	var l := _log()
	_expect_error("the oven is missing")
	push_error("the oven is missing")
	push_warning("the oven is cold")
	var lines := _lines(l)
	var err := lines.filter(func(s: String) -> bool: return s.contains("ERROR [engine] the oven is missing"))
	var warn := lines.filter(func(s: String) -> bool: return s.contains("WARN  [engine] the oven is cold"))
	_check(err.size() == 1 and warn.size() == 1, "one line each (got %s)" % [lines])
	if err.size() == 1:
		_check(err[0].contains("log_test.gd") and err[0].contains("case_engine"), "the error says where it came from (got '%s')" % err[0])
	_check(_file_text().contains("the oven is missing"), "the error is on disk")
	_close(l)


func case_prints() -> void:
	var l := _log(func(x: Node) -> void: x.set("echo", true))
	print("a stray print")
	l.call("info", "menu", "opened")
	var lines := _lines(l)
	_check(lines.filter(func(s: String) -> bool: return s.contains("[print] a stray print")).size() == 1,
			"the print is in the log once (got %s)" % [lines])
	_check(lines.filter(func(s: String) -> bool: return s.contains("opened")).size() == 1,
			"the log's own echoed line is not taken in a second time (got %s)" % [lines])
	_close(l)
	var quiet := _log(func(x: Node) -> void: x.set("capture_prints", false))
	print("not taken")
	_check(_lines(quiet).is_empty(), "capture_prints off leaves prints alone (got %s)" % [_lines(quiet)])
	_close(quiet)


func case_who() -> void:
	var l := _log(func(x: Node) -> void: x.set("who", "p2"))
	l.call("info", "net", "joined")
	_check(_lines(l)[0].contains("INFO  p2|[net] joined"), "the machine's name is in the line (got '%s')" % _lines(l)[0])
	_close(l)


func case_limit() -> void:
	var l := _log(func(x: Node) -> void: x.set("max_bytes", 300))
	for i in 12:
		l.call("info", "loop", "line number %d of a chatty loop" % i)
	_check(FileAccess.file_exists(DIR.path_join("game.1.log")), "the full file was closed and kept")
	_check(_file_text().length() <= 400, "the current file started again (got %d bytes)" % _file_text().length())
	_check(_lines(l).size() == 12, "the memory of recent lines has them all")
	_check((l.call("recent", 3) as Array).size() == 3 and String((l.call("recent", 3) as Array)[2]).contains("number 11"),
			"recent(3) is the last three, oldest first")
	_close(l)


func case_signal() -> void:
	var l := _log()
	var got: Array[Dictionary] = []
	l.connect("logged", func(e: Dictionary) -> void: got.append(e))
	l.call("warn", "audio", "no device")
	_check(got.size() == 1, "one signal (got %d)" % got.size())
	if got.size() == 1:
		_check(got[0]["area"] == "audio" and got[0]["text"] == "no device" and int(got[0]["level"]) == 2
				and String(got[0]["line"]).contains("WARN  [audio] no device"), "the entry has its parts (got %s)" % got[0])
	_close(l)


func case_removed() -> void:
	var l := _log()
	remove_child(l)
	print("after it left the tree")
	_check((l.call("recent") as Array).is_empty(), "nothing is taken once it is out of the tree (got %s)" % [l.call("recent")])
	l.free()
