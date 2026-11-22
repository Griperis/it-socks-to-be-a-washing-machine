## The Mess benchmark's report (core/31, B1, B2): keeps a run as `results-<label>.json` and writes
## `report.md` from every results file in the folder, oldest run first, so the runs of several
## commits (tools/mess_bench.sh --at=<commit>) stand side by side in one table.
class_name MessBenchReport
extends RefCounted

const REPORT := "report.md"
const RESULTS := "results-%s.json"
## The faults a scenario is judged by, in the report's order (MessWatch, MessBench).
const FAULTS: Array[String] = ["never", "lost", "hot", "jumped", "flips", "jitter", "sunk", "inside", "made_inside", "under"]


## Keeps `run` in `folder` and writes the report there. Returns the report's path, "" on a failure.
static func keep(folder: String, run: Dictionary, plan: MessBenchPlan) -> String:
	var dir := ProjectSettings.globalize_path(folder)
	if DirAccess.make_dir_recursive_absolute(dir) != OK and not DirAccess.dir_exists_absolute(dir):
		Log.error("bench", "cannot make %s" % dir)
		return ""
	var own := dir.path_join(RESULTS % String(run["label"]).validate_filename())
	var file := FileAccess.open(own, FileAccess.WRITE)
	if file == null:
		Log.error("bench", "cannot write %s" % own)
		return ""
	file.store_string(JSON.stringify(run, "\t"))
	file.close()
	var runs: Array[Dictionary] = []
	for name in DirAccess.get_files_at(dir):
		if name.begins_with("results-") and name.ends_with(".json"):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(name)))
			if parsed is Dictionary and (parsed as Dictionary).has("results"):
				runs.append(parsed)
	runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["date"]) < String(b["date"]))
	var path := dir.path_join(REPORT)
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out == null:
		Log.error("bench", "cannot write %s" % path)
		return ""
	out.store_string(text(runs, plan))
	out.close()
	return path


## The report of `runs` (each as MessBench keeps it), as Markdown.
static func text(runs: Array[Dictionary], plan: MessBenchPlan) -> String:
	var lines := PackedStringArray()
	lines.append("# Mess benchmark")
	lines.append("")
	lines.append("core/31, `tools/mess_bench.sh` (`game/debug/mess_bench.gd`). How to run it and what each scenario measures:")
	lines.append("`docs/architecture/mess.md` \"Benchmark\". A tick is every script's physics work plus the physics step.")
	lines.append("")
	lines.append("## The runs")
	lines.append("")
	for run in runs:
		lines.append("- **%s**%s, %s: %s" % [run["label"], _commit(run), run["date"], run["verdict"]])
		lines.append("  - %s" % run["machine"])
	lines.append("")
	lines.append("## Side by side")
	lines.append("")
	lines.append("Tick ms as median / 95th percentile / worst; time to settle in game seconds (\"never\": Socks still moving")
	lines.append("at the limit); faults as counted by `MessWatch` (none: \"-\").")
	lines.append("")
	var head := "| Scenario |"
	var rule := "|---|"
	for run in runs:
		head += " %s: tick ms | settle | faults |" % run["label"]
		rule += "---|---|---|"
	lines.append(head)
	lines.append(rule)
	for id in _ids(runs):
		var row := "| `%s` |" % id
		for run in runs:
			var r := _result(run, id)
			if r.is_empty():
				row += " not run | | |"
			else:
				row += " %.3f / %.3f / %.3f | %s | %s |" % [r["tick_med"], r["tick_p95"], r["tick_worst"], _settle(r), _faults(r)]
		lines.append(row)
	lines.append("")
	for run in runs:
		lines.append("## %s%s" % [run["label"], _commit(run)])
		lines.append("")
		lines.append("%s" % run["verdict"])
		lines.append("")
		lines.append("| Scenario | Socks | Tick ms (median / p95 / worst) | Of it scripts ms (median / p95) | Frame scripts ms (median / p95) | Whole frame ms (median / p95) | Moving at most | Settled after | Rests | Lost | Never settle | Wakes a second | Hot rests | Jumped | Flips (fastest turn rad/s) | Jitter | Sunk (deepest mm) | Inside another | Nodes | Draw calls | Result |")
		lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
		for r: Dictionary in run["results"]:
			lines.append("| `%s` | %d | %.3f / %.3f / %.3f | %.3f / %.3f | %.3f / %.3f | %s | %d | %s | %d | %d | %d | %.1f | %d | %d | %d (%.0f) | %d | %s | %s | %d | %s | %s |" % [
					r["id"], r["socks"], r["tick_med"], r["tick_p95"], r["tick_worst"], r.get("script_med", 0.0), r.get("script_p95", 0.0),
					r["frame_med"], r["frame_p95"],
					_or_dash(float(r["wall_med"]) >= 0.0, "%.2f / %.2f" % [r["wall_med"], r["wall_p95"]]),
					r["peak_moving"], _settle(r), r["rests"], r["lost"], r["never"], r["wakes_per_s"], r["hot"], r["jumped"],
					r["flips"], r.get("worst_spin", 0.0), r["jitter"],
					_or_dash(r.has("sunk"), "%d (%.0f)" % [int(r.get("sunk", 0)), float(r.get("sunk_worst", 0.0)) * 1000.0]),
					_or_dash(r.has("inside"), str(int(r.get("inside", 0)))), r["nodes"],
					_or_dash(int(r["draws"]) >= 0, str(int(r["draws"]))), "ok" if r["ok"] else "**fail**: %s" % r["why"]])
		lines.append("")
		lines.append("Moving Socks every %.1f s:" % MessWatch.SERIES_EVERY)
		lines.append("")
		for r: Dictionary in run["results"]:
			var series: Array = r.get("series", [])
			if int(r["peak_moving"]) > 0:
				lines.append("- `%s`: %s" % [r["id"], " ".join(PackedStringArray(series.map(func(v: Variant) -> String: return str(int(v)))))])
		lines.append("")
	lines.append("## The scenarios")
	lines.append("")
	lines.append("| Scenario | What | The old game's nearest number |")
	lines.append("|---|---|---|")
	for s in plan.scenarios:
		lines.append("| `%s` | %s | %s |" % [s.id, s.title, s.old_game if s.old_game != "" else "-"])
	lines.append("")
	lines.append("## What counts as a fault")
	lines.append("")
	var c := plan.checks
	lines.append("`game/debug/mess_checks.tres`; a scenario with any of them, or over its tick budget, fails.")
	lines.append("")
	lines.append("- never: Socks still moving or waiting when the scenario's limit ran out.")
	lines.append("- lost: a Sock written lying more than %.2f m from where its body was (it came back at the return spot)." % MessWatch.LOST_OVER)
	lines.append("- hot: a Sock written lying while turning faster than %.1f rad/s or moving faster than %.2f m/s." % [c.hot_spin, c.hot_speed])
	lines.append("- jumped: a Sock written lying more than %.0f mm from where its body was." % (c.jump * 1000.0))
	lines.append("- flips: a moving Sock that turned faster than %.0f rad/s." % c.flip_spin)
	lines.append("- jitter: a Sock woken %d times or more in the scenario." % c.jitter_wakes)
	lines.append("- sunk: a lying Sock whose lowest point is more than %.0f mm under the floor." % (c.sunk * 1000.0))
	lines.append("- inside another: a lying Sock whose leg or foot overlaps another lying Sock's more than %.0f mm deep (from %.0f mm it is pressed: allowed, Q2499)." % [c.inside * 1000.0, c.pressed * 1000.0])
	lines.append("- made_inside: a new Sock made overlapping a moving one more than %.0f mm deep." % (c.made_inside * 1000.0))
	lines.append("- under: a moving Sock with the middle of its leg or foot more than %.0f mm under the floor." % (c.under * 1000.0))
	lines.append("- tick budget: 95th percentile over %.1f ms (nothing moving: %.2f ms)." % [plan.tick_budget, plan.idle_tick_budget])
	lines.append("")
	return "\n".join(lines)


static func _commit(run: Dictionary) -> String:
	return " (`%s`)" % run["commit"] if String(run.get("commit", "")) != "" else ""


static func _ids(runs: Array[Dictionary]) -> PackedStringArray:
	var out := PackedStringArray()
	for run in runs:
		for r: Dictionary in run["results"]:
			if not out.has(String(r["id"])):
				out.append(String(r["id"]))
	return out


static func _result(run: Dictionary, id: String) -> Dictionary:
	for r: Dictionary in run["results"]:
		if String(r["id"]) == id:
			return r
	return {}


static func _settle(r: Dictionary) -> String:
	if int(r["never"]) > 0:
		return "never (%d)" % r["never"]
	return "-" if float(r["settle_s"]) < 0.0 else "%.1f s" % r["settle_s"]


static func _faults(r: Dictionary) -> String:
	var out := PackedStringArray()
	for key in FAULTS:
		if int(r.get(key, 0)) > 0:
			out.append("%s %d" % [key, r[key]])
	return ", ".join(out) if not out.is_empty() else "-"


static func _or_dash(has: bool, value: String) -> String:
	return value if has else "-"
