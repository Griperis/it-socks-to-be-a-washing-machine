## The game's command line (core/35, GameCli): no arguments change nothing, --help lists the
## commands, an unknown flag is code 2, a release build refuses every command, and the game
## started as a child process with `-- --bench=mess` / `-- --scene=heap` / `-- --zoo` does what it
## says; started plainly it plays the house (house/04, Q2509).
extends TestSuite


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "Real path: the game started with -- --bench=mess --only=idle_500 --headless prints the BENCH line, the verdict and BENCH saved <path>, writes the report there and exits 0"},
		{"name": "scene", "method": "case_scene", "world": false,
				"title": "the game started with -- --scene=heap starts the heap station"},
		{"name": "zoo_and_house", "method": "case_zoo_and_house", "world": false,
				"title": "the game started plainly shows the title (core/58); -- --scene= starts the house, -- --zoo the zoo"},
		{"name": "none", "method": "case_none", "world": false,
				"title": "no arguments (and engine flags alone) start the game as before"},
		{"name": "help", "method": "case_help", "world": false,
				"title": "--help lists bench and scene and quits with 0; an unknown flag prints it and quits with 2"},
		{"name": "release", "method": "case_release", "world": false,
				"title": "in a release build every command is refused with one line and the game starts"},
		{"name": "table", "method": "case_table", "world": false,
				"title": "a bench option without --bench, an unknown bench and an unknown station are refused with 2; a res:// scene is accepted"},
	]


## The game as a child process, `args` after `--`; returns {code, text}.
func _game(engine: PackedStringArray, args: PackedStringArray) -> Dictionary:
	var all := PackedStringArray(["--path", ProjectSettings.globalize_path("res://")])
	all.append_array(engine)
	all.append("--")
	all.append_array(args)
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), all, out, true)
	return {"code": code, "text": "\n".join(PackedStringArray(out))}


func case_real_path() -> void:
	var r := _game(PackedStringArray(["--headless", "--audio-driver", "Dummy", "--fixed-fps", "10"]),
			PackedStringArray(["--bench=mess", "--only=idle_500", "--headless", "--label=cli_test"]))
	var text: String = r["text"]
	_check(r["code"] == 0, "exit code 0 (got %s)" % r["code"])
	_check(text.contains("BENCH idle_500 "), "the BENCH line is printed")
	_check(text.contains("PASS mess bench: 1 scenarios"), "the verdict is printed")
	var last := ""
	for line in text.split("\n", false):
		last = line.strip_edges()
	_check(last.begins_with("BENCH saved "), "the last line says where it went (got '%s')" % last)
	var folder := last.trim_prefix("BENCH saved ")
	_check(FileAccess.file_exists(folder.path_join("report.md")), "report.md is there")
	_check(FileAccess.file_exists(folder.path_join("results-cli_test.json")), "results-cli_test.json is there")
	DirAccess.remove_absolute(folder.path_join("report.md"))
	DirAccess.remove_absolute(folder.path_join("results-cli_test.json"))


func case_scene() -> void:
	var r := _game(PackedStringArray(["--headless", "--audio-driver", "Dummy", "--quit-after", "30"]),
			PackedStringArray(["--scene=heap"]))
	var text: String = r["text"]
	_check(text.contains("GameCli: scene res://game/zoo/stations/heap.tscn"), "the heap station is named")
	_check(not text.contains("SCRIPT ERROR") and not text.contains("cannot start"), "it started without an error")


func case_zoo_and_house() -> void:
	_same(String(ProjectSettings.get_setting("application/run/main_scene")), "res://game/ui/title/title.tscn", "the title is the main scene (core/58)")
	var plain := _game(PackedStringArray(["--headless", "--audio-driver", "Dummy", "--quit-after", "40"]), PackedStringArray())
	var text: String = plain["text"]
	_check(not text.contains("GameCli: scene"), "a plain start swaps no scene")
	_check(not text.contains("SCRIPT ERROR"), "the title starts without an error")
	var house := _game(PackedStringArray(["--headless", "--audio-driver", "Dummy", "--quit-after", "40"]), PackedStringArray(["--scene=res://game/house/house.tscn"]))
	text = house["text"]
	_check(text.contains("GameCli: scene res://game/house/house.tscn") and not text.contains("SCRIPT ERROR"), "-- --scene= starts the house alone, without an error")
	var zoo := _game(PackedStringArray(["--headless", "--audio-driver", "Dummy", "--quit-after", "40"]), PackedStringArray(["--zoo"]))
	text = zoo["text"]
	_check(text.contains("GameCli: scene res://game/zoo/zoo.tscn"), "-- --zoo starts the zoo")
	_check(not text.contains("SCRIPT ERROR") and not text.contains("cannot start"), "the zoo started without an error")
	var p := GameCli.plan(PackedStringArray(["--zoo", "--host"]), true)
	_same(p["scene"], "res://game/zoo/zoo.tscn", "--zoo with --host: the zoo, the co-op flag passed on")


func case_none() -> void:
	_same(GameCli.plan(PackedStringArray(), true)["action"], "none", "no arguments: nothing to do")
	_same(GameCli.plan(PackedStringArray(["--headless"]), true)["action"], "none", "--headless alone: nothing to do")
	_same(GameCli.plan(PackedStringArray(["--host"]), true)["action"], "none", "--host passes through to the session")
	_same(GameCli.plan(PackedStringArray(["--join=127.0.0.1"]), true)["action"], "none", "--join= passes through to the session")
	_same(GameCli.plan(PackedStringArray(["--join=127.0.0.1", "--profile=two"]), true)["action"], "none", "--profile= passes through to the session")
	_check(GameCli.other_scene_asked(PackedStringArray(["--path", ".", "res://tests/runner.tscn", "--", "--only=x"])),
			"an engine run of another scene keeps its own arguments")
	_check(not GameCli.other_scene_asked(PackedStringArray(["--path", ".", "--", "res://x.tscn"])), "a .tscn after -- is not the engine's")
	_check(get_tree().current_scene == null or get_tree().current_scene.scene_file_path != "res://game/debug/mess_bench.tscn",
			"this run is not in a benchmark")


func case_help() -> void:
	var p := GameCli.plan(PackedStringArray(["--help"]), true)
	_same(p["action"], "help", "--help helps")
	_same(p["code"], 0, "with code 0")
	_check(String(p["text"]).contains("--bench=mess") and String(p["text"]).contains("--scene="), "it lists bench and scene")
	var bad := GameCli.plan(PackedStringArray(["--nonsense"]), true)
	_same(bad["action"], "help", "an unknown flag helps")
	_same(bad["code"], 2, "with code 2")
	var r := _game(PackedStringArray(["--headless"]), PackedStringArray(["--nonsense"]))
	_same(r["code"], 2, "the game exits with 2 for it")


func case_release() -> void:
	GameCli.debug_build = false
	var p := GameCli.plan(PackedStringArray(["--bench=mess"]), GameCli.debug_build)
	GameCli.debug_build = OS.is_debug_build()
	_same(p["action"], "refused", "--bench is refused")
	_check(not String(p["text"]).contains("\n"), "with one line")
	_same(GameCli.plan(PackedStringArray(["--nonsense"]), false)["action"], "refused", "an unknown flag too, the game starts")


func case_table() -> void:
	_same(GameCli.plan(PackedStringArray(["--only=idle_500"]), true)["code"], 2, "a bench option alone is refused")
	_same(GameCli.plan(PackedStringArray(["--bench=nope"]), true)["code"], 2, "an unknown bench is refused")
	_same(GameCli.plan(PackedStringArray(["--scene=nope"]), true)["code"], 2, "an unknown station is refused")
	var p := GameCli.plan(PackedStringArray(["--scene=res://game/zoo/stations/heap.tscn"]), true)
	_same(p["scene"], "res://game/zoo/stations/heap.tscn", "a res:// scene is accepted")
	var b := GameCli.plan(PackedStringArray(["--bench=mess", "--only=idle_500", "--label=x", "--out=/tmp/x", "--list"]), true)
	_same(b["scene"], "res://game/debug/mess_bench.tscn", "the mess bench with all its options")
