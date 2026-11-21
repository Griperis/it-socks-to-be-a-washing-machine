## The game's command line (core/35, Q2416): an autoload that reads the user arguments after `--`
## once at start (`"It Socks.exe" -- --bench=mess`, or the editor exe with `--path`). With none the
## game starts as it always did. In a release build every command is refused with one printed line
## and the game starts as it always did: the benchmarks never run there.
##
## The commands are the const tables below: the next benchmark is one more entry of BENCHES.
## `plan()` is the pure part (arguments in, what to do out); `_ready` carries it out.
class_name GameCli
extends Node

## `--bench=<name>`: the scene that runs it, one line of help, and the options it reads itself.
const BENCHES: Array[Dictionary] = [
	{"name": "mess", "scene": "res://game/debug/mess_bench.tscn",
			"help": "the Mess benchmark (core/31); exit code 0 on PASS, 1 on FAIL",
			"options": ["--only=<ids>", "--list", "--label=<name>", "--commit=<hash>", "--out=<folder>"]},
]
## Where the zoo's stations are, for `--scene=<name>`.
const STATIONS := "res://game/zoo/stations/%s.tscn"
## Flags that are accepted and mean nothing to a command (the engine's own are before the `--`).
const QUIET: Array[String] = ["--headless"]

## Whether this is a debug build. A test sets it to stand in for a release build.
static var debug_build: bool = OS.is_debug_build()


func _ready() -> void:
	if other_scene_asked(OS.get_cmdline_args()):
		return
	var what := plan(OS.get_cmdline_user_args(), debug_build)
	match what["action"]:
		"none":
			return
		"refused":
			print(what["text"])
		"help":
			print(what["text"])
			get_tree().quit(int(what["code"]))
		"scene":
			print("GameCli: scene %s" % what["scene"])
			_change.call_deferred(String(what["scene"]))


func _change(scene: String) -> void:
	var err := get_tree().change_scene_to_file(scene)
	if err != OK:
		printerr("GameCli: cannot start %s (error %d)" % [scene, err])
		get_tree().quit(2)


## Whether the engine's own arguments (before the `--`) name a scene or a script to run: the test
## runner, the shot harness and tools do, and their user arguments are theirs, not this command line's.
static func other_scene_asked(engine_args: PackedStringArray) -> bool:
	for arg in engine_args:
		if arg == "--":
			break
		if arg.ends_with(".tscn") or arg.ends_with(".scn") or arg == "--script" or arg == "-s":
			return true
	return false


## What the arguments ask for: {action: "none" | "refused" | "help" | "scene", code, text, scene}.
static func plan(args: PackedStringArray, debug: bool) -> Dictionary:
	var scene := ""
	var asked := false
	var wants_help := false
	var unknown := PackedStringArray()
	var bench := false
	for arg in args:
		if arg == "--help":
			wants_help = true
		elif arg.begins_with("--bench="):
			asked = true
			var b := _bench(arg.trim_prefix("--bench="))
			if b.is_empty():
				unknown.append(arg)
			else:
				bench = true
				scene = b["scene"]
		elif arg.begins_with("--scene="):
			asked = true
			scene = _station(arg.trim_prefix("--scene="))
			if scene == "":
				unknown.append(arg)
		elif QUIET.has(arg):
			continue
		elif not _bench_option(arg):
			unknown.append(arg)
	if not wants_help and unknown.is_empty() and not asked and not _has_bench_option(args):
		return {"action": "none"}
	if not debug:
		return {"action": "refused", "text": "GameCli: the command line is for debug builds; ignored (%s)" % " ".join(args)}
	if wants_help:
		return {"action": "help", "code": 0, "text": help_text()}
	if not unknown.is_empty():
		return {"action": "help", "code": 2, "text": "GameCli: unknown %s\n%s" % [" ".join(unknown), help_text()]}
	if not bench and _has_bench_option(args):
		return {"action": "help", "code": 2, "text": "GameCli: a benchmark option needs --bench=<name>\n%s" % help_text()}
	return {"action": "scene", "scene": scene}


## The help: the commands, their options, where results go.
static func help_text() -> String:
	var lines := PackedStringArray(["It Socks command line (debug builds), after `--`:",
			"  --help                 this text, then quit",
			"  --scene=<scene>        start a scene (res:// path) or a zoo station by its file name (--scene=heap)"])
	for b in BENCHES:
		lines.append("  --bench=%-14s %s" % [b["name"], b["help"]])
		lines.append("      options: %s" % " ".join(PackedStringArray(b["options"])))
	lines.append("Results go to user://bench/<bench>/ (Windows: %APPDATA%\\Godot\\app_userdata\\It Socks\\bench\\<bench>\\);")
	lines.append("the last line printed is `BENCH saved <folder>`. --out=<folder> overrides.")
	lines.append("A bench is drawn in a window unless the engine's own --headless is given before the `--`.")
	lines.append("Worker threads are not capped from here (an engine setting read at start): the report says \"uncapped\".")
	lines.append("Exit codes: 0 done / PASS, 1 FAIL, 2 unknown flag.")
	return "\n".join(lines)


static func _bench(name: String) -> Dictionary:
	for b in BENCHES:
		if b["name"] == name:
			return b
	return {}


static func _station(name: String) -> String:
	if name.begins_with("res://"):
		return name if ResourceLoader.exists(name) else ""
	var path := STATIONS % name
	return path if ResourceLoader.exists(path) else ""


static func _bench_option(arg: String) -> bool:
	for b in BENCHES:
		for o: String in b["options"]:
			if arg == o or (o.contains("=") and arg.begins_with(o.get_slice("=", 0) + "=")):
				return true
	return false


static func _has_bench_option(args: PackedStringArray) -> bool:
	for arg in args:
		if _bench_option(arg):
			return true
	return false
