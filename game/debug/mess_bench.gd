## The Mess benchmark's runner (core/31, B1; mess_bench.tscn, started by tools/mess_bench.sh or
## .cmd): runs the plan's scenarios (mess_bench_plan.tres) one after another, each in a fresh
## MessBenchLevel, with a MessWatch counting the faults and a MessBenchClock timing the ticks.
## Prints one `BENCH` line per scenario and a verdict line last (`PASS mess bench ...` or
## `FAIL mess bench ...`), keeps the run as `results-<label>.json` and has MessBenchReport write
## `report.md` from every results file in the folder, so runs of several commits sit in one table.
##
## After `--` on the command line:
##   --only=idle_500,sweep   those scenarios          --out=<folder>   where the report goes
##   --label=main            the run's name in the report (a commit, "this branch")
##   --commit=<hash>         the commit it ran on, for the report
##   --list                  prints the scenarios and quits
## Normally started through GameCli (`-- --bench=mess`), which owns the command line.
class_name MessBench
extends Node

const PLAN: MessBenchPlan = preload("res://game/debug/mess_bench_plan.tres")
const LEVEL := preload("res://game/debug/mess_bench_level.tscn")

var _only := PackedStringArray()
var _out := "user://bench/mess"
var _label := "run"
var _commit := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--commit="):
			_commit = arg.trim_prefix("--commit=")
		elif arg == "--list":
			for s in PLAN.scenarios:
				print("%s  %s" % [s.id, s.title])
			get_tree().quit()
			return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_start.call_deferred()


## A tick is timed between two ticks of one frame (MessBenchClock), so the run needs several ticks a
## frame: the engine's own `--fixed-fps 10` gives six. Nothing sets that at run time (Engine.time_scale
## also scales the physics delta; max_fps 10 runs in real time, hours) and the engine hides its own
## flags from OS.get_cmdline_args(), so the ticks of a few frames are counted: with fewer than two a
## frame the run says which flag is missing and quits with 2.
func _start() -> void:
	var ticks := Engine.get_physics_frames()
	var frames := Engine.get_process_frames()
	for i in 5:
		await get_tree().process_frame
	if float(Engine.get_physics_frames() - ticks) / maxf(Engine.get_process_frames() - frames, 1) < 2.0:
		print("FAIL mess bench: needs the engine flag --fixed-fps 10 before the `--` (a tick is timed between two ticks of one frame): \"It Socks.exe\" --fixed-fps 10 -- --bench=mess")
		get_tree().quit(2)
		return
	_run_all()


func _run_all() -> void:
	var results: Array[Dictionary] = []
	for s in PLAN.scenarios:
		if not _only.is_empty() and not _only.has(String(s.id)):
			continue
		var r := await _run(s)
		results.append(r)
		print(line_of(r))
	var failed := PackedStringArray()
	for r in results:
		if not r["ok"]:
			failed.append("%s (%s)" % [r["id"], r["why"]])
	var verdict := "PASS mess bench: %d scenarios" % results.size()
	if results.is_empty():
		verdict = "FAIL mess bench: no scenario named so (--list)"
	elif not failed.is_empty():
		verdict = "FAIL mess bench: %d of %d scenarios: %s" % [failed.size(), results.size(), "; ".join(failed)]
	var run := {"label": _label, "commit": _commit, "date": Time.get_datetime_string_from_system(false, true),
			"machine": machine(), "verdict": verdict, "results": results}
	var report := MessBenchReport.keep(_out, run, PLAN)
	if report != "":
		print("Report: %s" % report)
	print(verdict)
	print("BENCH saved %s" % ProjectSettings.globalize_path(_out))
	get_tree().quit(0 if verdict.begins_with("PASS") else 1)


## One scenario, from a fresh level to its result.
func _run(s: MessBenchScenario) -> Dictionary:
	var level := LEVEL.instantiate() as MessBenchLevel
	level.prepare(s, PLAN.dice)
	add_child(level)
	for i in PLAN.warm_ticks:
		await get_tree().physics_frame
	var watch := MessWatch.new()
	watch.mess = level.mess
	watch.checks = PLAN.checks
	level.add_child(watch)
	var clock := MessBenchClock.new()
	clock.watch = watch
	level.add_child(clock)
	await get_tree().physics_frame
	level.act(s)
	var tick := 1.0 / Engine.physics_ticks_per_second
	var t := 0.0
	var acted_for := -1.0
	var timing := s.phase != MessBenchScenario.Phase.SETTLING
	clock.restart()
	while t < (s.seconds if s.kind == MessBenchScenario.Kind.IDLE else s.limit):
		await get_tree().physics_frame
		t += tick
		if s.kind == MessBenchScenario.Kind.IDLE:
			continue
		if acted_for < 0.0 and not level.acting():
			acted_for = t
			if s.phase == MessBenchScenario.Phase.ACTING:
				break
			if not timing:
				timing = true
				clock.restart()
		if acted_for >= 0.0 and watch.settled():
			break
	var ticks := clock.tick_ms()
	var scripts := clock.script_ms()
	var frames := clock.frame_ms()
	var walls := clock.wall_ms()
	var r := watch.result()
	r["series"] = Array(r["series"])
	var mess := level.mess
	var headless := DisplayServer.get_name() == "headless"
	r.merge({"id": String(s.id), "title": s.title, "old_game": s.old_game, "socks": mess.count(),
			"lying": mess.states.count(Mess.State.LYING),
			"tick_med": ticks[0], "tick_p95": ticks[1], "tick_worst": ticks[2], "ticks": clock.tick_count(),
			"script_med": scripts[0], "script_p95": scripts[1],
			"frame_med": frames[0], "frame_p95": frames[1],
			"wall_med": -1.0 if headless else walls[0], "wall_p95": -1.0 if headless else walls[1],
			"seconds": t, "acted_for": acted_for,
			"settle_s": -1.0, "never": 0,
			"wakes_per_s": watch.wakes / maxf(t, tick),
			"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"draws": -1 if headless else int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))})
	if s.kind != MessBenchScenario.Kind.IDLE and s.phase != MessBenchScenario.Phase.ACTING:
		if watch.settled():
			r["settle_s"] = maxf(t - watch.quiet_for, 0.0)
		else:
			r["never"] = int(r["moving"]) + int(r["waiting"])
	if s.phase != MessBenchScenario.Phase.ACTING:
		r.merge(watch.survey())
	_judge(s, r)
	level.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	return r


## Whether result `r` of scenario `s` passes, and why not.
func _judge(s: MessBenchScenario, r: Dictionary) -> void:
	var why := PackedStringArray()
	var budget := PLAN.idle_tick_budget if s.kind == MessBenchScenario.Kind.IDLE else PLAN.tick_budget
	if float(r["tick_p95"]) > budget:
		why.append("tick p95 %.2f ms over %.2f" % [r["tick_p95"], budget])
	for key: String in ["never", "lost", "hot", "jumped", "flips", "jitter", "sunk", "inside"]:
		if int(r.get(key, 0)) > 0:
			why.append("%s %d" % [key, r[key]])
	r["ok"] = why.is_empty()
	r["why"] = ", ".join(why)


## A result as its `BENCH` line.
static func line_of(r: Dictionary) -> String:
	var settle := "-" if float(r["settle_s"]) < 0.0 else "%.1fs" % r["settle_s"]
	var draws := "-" if int(r["draws"]) < 0 else str(r["draws"])
	return ("BENCH %s socks=%d tick=%.3f/%.3f/%.3f ms scripts=%.3f ms frame=%.3f ms moving_peak=%d settle=%s lost=%d never=%d"
			+ " wakes/s=%.1f hot=%d jumped=%d flips=%d jitter=%d sunk=%d inside=%d nodes=%d draws=%s %s") % [
			r["id"], r["socks"], r["tick_med"], r["tick_p95"], r["tick_worst"], r.get("script_med", 0.0), r["frame_med"],
			r["peak_moving"], settle,
			r["lost"], r["never"], r["wakes_per_s"], r["hot"], r["jumped"], r["flips"], r["jitter"],
			r.get("sunk", 0), r.get("inside", 0), r["nodes"], draws, "ok" if r["ok"] else "FAIL (%s)" % r["why"]]


## The machine and the engine, in a line.
static func machine() -> String:
	return "%s, %d threads (worker pool %s), %s, %s; Godot %s, %s, %d ticks a second, %s" % [
			OS.get_processor_name(), OS.get_processor_count(),
			_threads(),
			RenderingServer.get_video_adapter_name() if DisplayServer.get_name() != "headless" else "headless (nothing drawn)",
			OS.get_name(), Engine.get_version_info()["string"], ProjectSettings.get_setting("physics/3d/physics_engine"),
			Engine.physics_ticks_per_second, "debug build" if OS.is_debug_build() else "release build"] + ", --fixed-fps 10 (six ticks a frame)"


## The worker pool's cap, or "uncapped": an engine setting read at start (the override.cfg that
## tools/mess_bench.sh writes beside project.godot); the command line cannot set it.
static func _threads() -> String:
	var cap := int(ProjectSettings.get_setting("threading/worker_pool/max_threads", -1))
	return "capped at %d" % cap if cap > 0 else "uncapped"
