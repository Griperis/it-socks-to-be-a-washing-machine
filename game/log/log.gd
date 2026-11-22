## The game's one log: its own lines (Log.info("orders", "order 3 done")), every error and warning
## the engine or a script raises (with where it came from), and stray prints, in one stream with a
## time, a level and an area. Each line goes to a file in user://logs/ (a fresh one per run, the last
## few runs kept) and to a short memory of recent lines for a bug report or a debug overlay.
## Add it as the autoload `Log`, first in the list, so the autoloads after it are logged from their
## first line. See kit/skills/godot-game-dev/templates/README.md "log/".
extends Node

enum Level { DEBUG, INFO, WARN, ERROR }

const LEVEL_NAMES: Array[String] = ["DEBUG", "INFO ", "WARN ", "ERROR"]
## Script calls shown after an engine error, nearest first.
const MAX_FRAMES := 4

## One line was logged: {"time": String, "level": Level, "area": String, "text": String, "line": String}.
## Emitted on the main thread, a frame later for a line logged from another thread.
signal logged(entry: Dictionary)

## Where the files go. A test sets its own before add_child().
var dir := "user://logs"
## The current run's file; older runs are <name>.1.log (the last run), <name>.2.log, ...
var file_name := "game"
## How many older files stay.
var keep := 5
## A file that grows past this many bytes is closed and a new one started (a long session, or a
## log line in a loop, never fills the disk).
var max_bytes := 2_000_000
## Lines kept in memory for recent().
var ring_size := 300
## Lines below this level are dropped. Debug builds keep everything.
var min_level: Level = Level.DEBUG if OS.is_debug_build() else Level.INFO
## Also print each line (the editor's Output panel, a terminal). Off in release builds.
var echo := OS.is_debug_build()
## Take the engine's and scripts' errors and warnings into the log.
var capture_engine := true
## Take plain print() output into the log too, as INFO lines of the area "print".
var capture_prints := true
## Who this machine is in a co-op session ("host", "p2"): put in front of every line, so the
## Host's and a Guest's files can be laid side by side. Empty alone.
var who := ""

var _mutex := Mutex.new()
var _file: FileAccess = null
var _bytes := 0
var _ring: Array[String] = []
var _tap: Logger = null
## True while this script itself prints or writes: what the engine reports meanwhile is this
## log's own doing and is not logged again.
var _busy := false


## The engine's side: it calls these for every error, warning and printed line, on whatever thread
## raised it.
class Tap extends Logger:
	## True while a Log prints one of its own lines: that print is not a stray one to take in
	## again (by this Log or by another instance, as a test's own).
	static var echoing := false

	var owner_log: Node = null

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		if owner_log == null or not owner_log.capture_engine:
			return
		var what := rationale if not rationale.is_empty() else code
		# Where in the game's scripts it happened, nearest call first; the engine's own file and
		# line only when no script was running.
		var where := "%s:%d in %s" % [file, line, function]
		if not script_backtraces.is_empty() and script_backtraces[0].get_frame_count() > 0:
			var trace := script_backtraces[0]
			var frames := PackedStringArray()
			for i in mini(trace.get_frame_count(), MAX_FRAMES):
				frames.append("%s (%s:%d)" % [trace.get_frame_function(i), trace.get_frame_file(i), trace.get_frame_line(i)])
			where = " <- ".join(frames)
		var is_warning := error_type == ERROR_TYPE_WARNING
		owner_log.write(Level.WARN if is_warning else Level.ERROR,
				"script" if error_type == ERROR_TYPE_SCRIPT else "engine", "%s (%s)" % [what, where])

	func _log_message(message: String, error: bool) -> void:
		if owner_log == null or not owner_log.capture_prints or echoing:
			return
		var text := message.strip_edges()
		if text != "":
			owner_log.write(Level.ERROR if error else Level.INFO, "print", text, {}, false)


func _enter_tree() -> void:
	_open()
	_tap = Tap.new()
	(_tap as Tap).owner_log = self
	OS.add_logger(_tap)


func _exit_tree() -> void:
	if _tap != null:
		(_tap as Tap).owner_log = null
		OS.remove_logger(_tap)
		_tap = null
	_mutex.lock()
	if _file != null:
		_file.close()
		_file = null
	_mutex.unlock()


func debug(area: String, text: String, data: Dictionary = {}) -> void:
	write(Level.DEBUG, area, text, data)


func info(area: String, text: String, data: Dictionary = {}) -> void:
	write(Level.INFO, area, text, data)


func warn(area: String, text: String, data: Dictionary = {}) -> void:
	write(Level.WARN, area, text, data)


func error(area: String, text: String, data: Dictionary = {}) -> void:
	write(Level.ERROR, area, text, data)


## The last `count` lines, oldest first (everything kept when count is 0).
func recent(count: int = 0) -> Array[String]:
	_mutex.lock()
	var out: Array[String] = _ring.duplicate() if count <= 0 or count >= _ring.size() else _ring.slice(_ring.size() - count)
	_mutex.unlock()
	return out


## The current file's path on disk, for "open the log folder" and for a bug report.
func path() -> String:
	return ProjectSettings.globalize_path(_current())


## One line. `data` is plain values shown as JSON after the text (ids, counts, positions as arrays);
## never put a secret or a player's personal data in a log. `may_echo` is false for a line that
## was printed already. Safe from any thread.
func write(level: Level, area: String, text: String, data: Dictionary = {}, may_echo: bool = true) -> void:
	if level < min_level:
		return
	_mutex.lock()
	if _busy:
		_mutex.unlock()
		return
	_busy = true
	var stamp := "%s.%03d" % [Time.get_datetime_string_from_system(true), Time.get_ticks_msec() % 1000]
	var line := "%s %s %s[%s] %s" % [stamp, LEVEL_NAMES[level], who + "|" if who != "" else "", area,
			text.replace("\n", " <- ")]
	if not data.is_empty():
		line += " " + JSON.stringify(data)
	_ring.append(line)
	if _ring.size() > ring_size:
		_ring = _ring.slice(_ring.size() - ring_size)
	if _file != null:
		_file.store_line(line)
		_bytes += line.length() + 1
		# A warning or an error may be the last thing before a crash: it is on disk at once.
		if level >= Level.WARN:
			_file.flush()
		if _bytes > max_bytes:
			_file.close()
			_file = null
			_open()
	if echo and may_echo:
		Tap.echoing = true
		print(line)
		Tap.echoing = false
	_busy = false
	_mutex.unlock()
	var entry := {"time": stamp, "level": level, "area": area, "text": text, "line": line}
	if OS.get_thread_caller_id() == OS.get_main_thread_id() and is_inside_tree():
		logged.emit(entry)
	else:
		logged.emit.call_deferred(entry)


## What is buffered reaches the disk: before a scene change that may take long, at quit.
func flush() -> void:
	_mutex.lock()
	if _file != null:
		_file.flush()
	_mutex.unlock()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		flush()


func _current() -> String:
	return dir.path_join(file_name + ".log")


## Starts a fresh file: the files of earlier runs move up one number and the oldest goes.
func _open() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	if FileAccess.file_exists(_current()):
		var base := ProjectSettings.globalize_path(dir.path_join(file_name))
		for n in range(keep, 0, -1):
			var from := "%s.%d.log" % [base, n - 1] if n > 1 else base + ".log"
			var to := "%s.%d.log" % [base, n]
			if FileAccess.file_exists(from):
				if FileAccess.file_exists(to):
					DirAccess.remove_absolute(to)
				DirAccess.rename_absolute(from, to)
	_file = FileAccess.open(_current(), FileAccess.WRITE)
	_bytes = 0
	if _file != null:
		# Which build this log is of: the first thing a bug report needs.
		var engine: Dictionary = Engine.get_version_info()
		_file.store_line("# %s %s, Godot %s, %s build, %s" % [ProjectSettings.get_setting("application/config/name", ""),
				ProjectSettings.get_setting("application/config/version", ""), engine.get("string", ""),
				"debug" if OS.is_debug_build() else "release", OS.get_name()])
	if _file == null:
		# No file (a read-only folder): the memory of recent lines and the echo still work.
		printerr("log: cannot write %s (%d)" % [_current(), FileAccess.get_open_error()])
