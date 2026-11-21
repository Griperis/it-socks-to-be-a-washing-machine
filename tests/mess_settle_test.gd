## How the Mess's Socks come to rest (core/31, B3, B4): "settles correctly" and "glitches" as the
## counts of MessWatch, on the zoo's heap station (the real path) and on small heaps in the Mess
## benchmark's own level; the rest's switch from a falling body to a lying instance (Q2407); and the
## benchmark's pieces (its plan, its level's acts, its report). The benchmark itself is not run here
## (tools/mess_bench.sh).
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const LEVEL := "res://game/debug/mess_bench_level.tscn"
const PLAN: MessBenchPlan = preload("res://game/debug/mess_bench_plan.tres")
const HEAP := "Stations/Heap"
## A small heap for the rule cases (the shipped 500 is the real path's).
const SMALL := 60
## The faults a heap at rest must not have (MessWatch.result() and survey()). Two more are counted
## and reported but not yet held at none, because their cure changes how Socks move or rest and
## waits for the designer (core/31 Open follow-ups): "flips" (a Sock landing on its edge from the
## spout's height still turns faster than the limit for a tick or two) and "sunk" (a few Socks of a
## big heap rest pressed part-way into the floor).
const FAULTS: Array[String] = ["lost", "hot", "jumped", "jitter", "inside"]
const COUNTED: Array[String] = ["flips", "sunk"]

var _zoo: Node3D = null
var _level: MessBenchLevel = null
var _watch: MessWatch = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "Real path, B3: the player clicks More at the heap station; the heap pours and settles to no moving Sock within the benchmark's limit, none lost or glitching"},
		{"name": "switch", "method": "case_switch", "world": false,
				"title": "Q2407: a Sock that comes to rest is drawn the same tick as a lying instance; no MultiMesh of the Mess is physics-interpolated"},
		{"name": "small_heap", "method": "case_small_heap", "world": false,
				"title": "B3: a small pour in the benchmark's level settles with every Sock lying and no fault counted"},
		{"name": "lost", "method": "case_lost", "world": false,
				"title": "B3: a Sock that leaves the bounds and comes back at the return spot is counted lost"},
		{"name": "flip", "method": "case_flip", "world": false,
				"title": "B3: a moving Sock turning faster than the flip limit is counted as flipping, once"},
		{"name": "jitter", "method": "case_jitter", "world": false,
				"title": "B3: a Sock woken again and again is counted as jittering; each wake is counted"},
		{"name": "survey", "method": "case_survey", "world": false,
				"title": "B3: a lying Sock under the floor is counted sunk, one with its middle inside another is counted inside it; a clean stack has neither"},
		{"name": "burst", "method": "case_burst", "world": false,
				"title": "B1: a burst of Throws into a stacked heap wakes lying Socks and all come to rest again"},
		{"name": "sweep", "method": "case_sweep", "world": false,
				"title": "B1: the Door and the drawer open and shut through lying Socks, wake them, and all come to rest again"},
		{"name": "flights", "method": "case_flights", "world": false,
				"title": "B4: a moving Sock's body is known by its Sock id while it moves and no longer once it lies; with nothing flying, nothing is drawn as a flying instance"},
		{"name": "plan", "method": "case_plan", "world": false,
				"title": "B1: the plan holds the idle, pour, settle, burst and sweep scenarios, each with its own id"},
		{"name": "report", "method": "case_report", "world": false,
				"title": "B2: the report puts the runs of two commits side by side, names each scenario's faults and the old game's number"},
	]


func _before_case() -> void:
	Input.action_release(&"pick")
	if _zoo != null:
		_zoo.free()
		_zoo = null
	if _level != null:
		_level.free()
		_level = null
	_watch = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var mess := _zoo.get_node("Socks/Mess") as Mess
	var player := _zoo.get_node("Player") as Player
	var station := _zoo.get_node(HEAP) as Node3D
	var spout := station.get_node("Spout/HeapSpout") as HeapSpout
	await _until(func() -> bool: return player.is_on_floor() and mess.body_count() > 0, "the player to stand and the Socks to lie", 600)
	player.capture_mouse()
	var before := mess.count()
	_watch = MessWatch.new()
	_watch.mess = mess
	_watch.first = before
	_watch.floor_y = station.global_position.y
	_zoo.add_child(_watch)
	var more := station.get_node("More") as Node3D
	player.global_position = more.global_position + station.global_basis * Vector3(0.0, -0.5, -1.5)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	var head := player.get_node("Head") as Node3D
	var to := more.global_position - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := more.global_position - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _until(func() -> bool: return mess.count() > before, "the click on More to pour Socks")
	var limit := int(PLAN.scenario(&"settle_500").limit * Engine.physics_ticks_per_second)
	await _until(func() -> bool: return spout.pending() == 0 and mess.count() - before >= spout.tuning.batch and _watch.settled(),
			"the heap to settle to no moving Sock", limit)
	var r := _watch.result()
	r.merge(_watch.survey())
	_check(mess.count() - before == spout.tuning.batch, "one batch of %d Socks poured (%d)" % [spout.tuning.batch, mess.count() - before])
	_check(mess.states.slice(before).count(Mess.State.LYING) == spout.tuning.batch,
			"every poured Sock lies (%d of %d)" % [mess.states.slice(before).count(Mess.State.LYING), spout.tuning.batch])
	_check(int(r["moving"]) == 0 and int(r["waiting"]) == 0, "no Sock moves or waits (%d, %d)" % [r["moving"], r["waiting"]])
	_no_faults(r)
	_check(_interpolated(_zoo.get_node("Lying")) == 0, "no MultiMesh of the Mess is physics-interpolated (%d)" % _interpolated(_zoo.get_node("Lying")))


# --- The rest's switch ---------------------------------------------------------------------------

func case_switch() -> void:
	await _level_up(MessBenchScenario.Kind.POUR, 0, 8)
	var mess := _level.mess
	_level.act(_scenario(MessBenchScenario.Kind.POUR, 0, 8))
	await _until(func() -> bool: return mess.moving_count() > 0, "Socks to pour")
	var lying := _level.get_node("Lying")
	await _until(func() -> bool: return lying.get_child_count() > 0, "the flying Socks to be drawn")
	_check(lying.get_child_count() > 0 and _interpolated(lying) == 0,
			"the flying Socks' MultiMeshes are not physics-interpolated (%d of %d)" % [_interpolated(lying), lying.get_child_count()])
	# The tick a body goes, its Sock is a drawn lying instance at the body's last pose, at its Size.
	var seen := 0
	var worst := 0.0
	var last: Dictionary[int, Transform3D] = {}
	for i in 1200:
		await _physics_ticks(1)
		for sock: int in last:
			if mess.flight_of(sock) == null and mess.state_of(sock) == Mess.State.LYING:
				seen += 1
				_check(mess.is_drawn(sock), "Sock %d is drawn as a lying instance the tick its body goes" % sock)
				var row := mess._drawing.instance_of(sock)
				var at: Transform3D = row[0]
				var size := mess.design_of(sock).size_scale()
				var mesh_at: Transform3D = mess._drawing._mesh_at[MessDrawing.shape_of(mess.design_of(sock), false)]
				worst = maxf(worst, at.origin.distance_to((last[sock] * Transform3D(Basis.from_scale(Vector3.ONE * size)) * mesh_at).origin))
				_near(at.basis.get_scale().x, mess.design_of(sock).size_scale(), 0.001, "Sock %d lies at its Size" % sock)
		last.clear()
		for sock in mess.count():
			var body := mess.flight_of(sock)
			if body != null:
				last[sock] = body.global_transform
		if mess.moving_count() == 0 and not _level.acting():
			break
	_check(seen == 8, "every poured Sock was seen coming to rest (%d of 8)" % seen)
	_check(worst < 0.01, "a lying instance is drawn where its body was the tick before (%.4f m at most)" % worst)
	_check(_interpolated(lying) == 0, "the lying Socks' MultiMeshes are not physics-interpolated (%d)" % _interpolated(lying))


# --- B3: the counts ------------------------------------------------------------------------------

func case_small_heap() -> void:
	await _level_up(MessBenchScenario.Kind.POUR, 0, SMALL)
	_level.act(_scenario(MessBenchScenario.Kind.POUR, 0, SMALL))
	await _settled()
	var mess := _level.mess
	_check(mess.count() == SMALL and mess.states.count(Mess.State.LYING) == SMALL,
			"every poured Sock lies (%d of %d)" % [mess.states.count(Mess.State.LYING), SMALL])
	var r := _watch.result()
	r.merge(_watch.survey())
	_check(int(r["rests"]) >= SMALL, "each rest was counted (%d)" % r["rests"])
	_check(int(r["peak_moving"]) > 0 and (r["series"] as PackedInt32Array).size() > 0, "the moving count was followed over time")
	_no_faults(r)


func case_lost() -> void:
	await _level_up(MessBenchScenario.Kind.IDLE, 4, 0)
	var mess := _level.mess
	# Thrown far out past the level's bounds: it comes back at the return spot.
	_level.parts.apply({"ok": true, "kind": &"throw", "by": 1, "to": mess.id, "changes": {mess.id:
			mess.thrown_patch(0, Transform3D(Basis.IDENTITY, Vector3(95.0, 2.0, 0.0)), Vector3(60.0, 5.0, 0.0), Vector3.ZERO, 1)}})
	await _until(func() -> bool: return mess.state_of(0) == Mess.State.LYING, "the Sock to come back")
	await _physics_ticks(2)
	_check(_watch.lost == 1, "one Sock counted lost (%d)" % _watch.lost)
	_check(_watch.jumped == 0, "a return is not counted as a jump too (%d)" % _watch.jumped)
	_check(mess.pose_of(0).origin.distance_to(_level.get_node("ReturnSpot").global_position) < 1.0, "it lies at the return spot")


func case_flip() -> void:
	await _level_up(MessBenchScenario.Kind.IDLE, 4, 0)
	var mess := _level.mess
	_level.parts.apply({"ok": true, "kind": &"throw", "by": 1, "to": mess.id, "changes": {mess.id:
			mess.thrown_patch(0, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.5, 0.0)), Vector3.ZERO, Vector3(40.0, 0.0, 0.0), 1)}})
	await _physics_ticks(5)
	_check(_watch.flipped() == 1, "the Sock thrown turning at 40 rad/s is counted as flipping, once (%d)" % _watch.flipped())
	_check(_watch.worst_spin > PLAN.checks.flip_spin, "its turn was noted (%.1f rad/s)" % _watch.worst_spin)
	await _settled()
	_check(_watch.flipped() == 1, "still once when it lies (%d)" % _watch.flipped())


func case_jitter() -> void:
	await _level_up(MessBenchScenario.Kind.IDLE, 4, 0)
	var mess := _level.mess
	var times := PLAN.checks.jitter_wakes
	for i in times:
		_level.parts.ask(Command.new(&"wake", Parts.HOST, mess.id, {"sock": 0}))
		await _until(func() -> bool: return mess.state_of(0) == Mess.State.FLYING, "the Sock to wake")
		await _until(func() -> bool: return mess.state_of(0) == Mess.State.LYING, "the Sock to rest again")
		await _physics_ticks(1)
		_check(_watch.jittering() == (1 if i == times - 1 else 0), "woken %d times: %d Socks jitter" % [i + 1, _watch.jittering()])
	_check(_watch.wakes == times, "each wake was counted (%d of %d)" % [_watch.wakes, times])


func case_survey() -> void:
	await _level_up(MessBenchScenario.Kind.IDLE, 40, 0)
	var mess := _level.mess
	var clean := _watch.survey()
	_check(int(clean["sunk"]) == 0 and int(clean["inside"]) == 0, "a stack of 40 has no sunk Sock and none inside another (%s)" % str(clean))
	# Sock 0 is put under the floor, Sock 3 exactly where Sock 2 (its Design's other Sock) lies.
	var patch := mess.lying_patch(0, Transform3D(Basis.IDENTITY, mess.pose_of(0).origin + Vector3.DOWN * 0.05), mess.states, mess.poses, mess.throws)
	patch = mess.lying_patch(3, mess.pose_of(2), patch["states"], patch["poses"], patch["throws"])
	_level.parts.apply({"ok": true, "kind": &"put", "by": 1, "to": mess.id, "changes": {mess.id: patch}})
	await _physics_ticks(1)
	var found := _watch.survey()
	_check(int(found["sunk"]) == 1, "the Sock 5 cm under the floor is counted sunk (%d)" % found["sunk"])
	_near(float(found["sunk_worst"]), 0.05, 0.002, "and how deep")
	_check(int(found["inside"]) == 2, "the two Socks in one place are each counted inside the other (%d)" % found["inside"])


# --- B1: the level's acts ------------------------------------------------------------------------

func case_burst() -> void:
	await _level_up(MessBenchScenario.Kind.BURST, 120, 6)
	var mess := _level.mess
	_check(mess.states.count(Mess.State.LYING) == 120 and mess.states.count(Mess.State.HELD) == 6, "120 Socks lie stacked, 6 wait to be thrown")
	_level.act(_scenario(MessBenchScenario.Kind.BURST, 120, 6))
	await _physics_ticks(1)
	_check(mess.moving_count() == 6, "the 6 are thrown in one tick (%d moving)" % mess.moving_count())
	await _settled()
	_check(_watch.wakes > 0, "the Throws woke lying Socks (%d)" % _watch.wakes)
	_check(mess.states.count(Mess.State.LYING) == 126, "every Sock lies again (%d of 126)" % mess.states.count(Mess.State.LYING))
	_check(_watch.lost == 0, "none was lost (%d)" % _watch.lost)


func case_sweep() -> void:
	await _level_up(MessBenchScenario.Kind.SWEEP, 80, 0)
	var mess := _level.mess
	_level.act(_scenario(MessBenchScenario.Kind.SWEEP, 80, 0))
	_check(_level.acting(), "the Door and the drawer move")
	await _until(func() -> bool: return _level.door.open and _level.drawer.open, "the Door and the drawer to open")
	await _until(func() -> bool: return not _level.acting(), "the Door and the drawer to shut again", 1200)
	_check(not _level.door.open and not _level.drawer.open, "both are shut again")
	await _settled()
	_check(_watch.wakes > 0, "they woke lying Socks in their way (%d)" % _watch.wakes)
	_check(mess.states.count(Mess.State.LYING) == 80, "every Sock lies again (%d of 80)" % mess.states.count(Mess.State.LYING))


# --- B4: the flights' index ----------------------------------------------------------------------

func case_flights() -> void:
	await _level_up(MessBenchScenario.Kind.IDLE, 4, 0)
	var mess := _level.mess
	await _frames(2)
	_check(not mess._flying_drawn, "with nothing flying, no flying instance is drawn or uploaded")
	_check(mess.moving_body(0) == null and not mess.is_moving(0), "a lying Sock has no moving body")
	_level.parts.ask(Command.new(&"wake", Parts.HOST, mess.id, {"socks": PackedInt32Array([0, 1, 2])}))
	await _physics_ticks(1)
	for sock in 3:
		_check(mess.moving_body(sock) != null and mess.moving_body(sock) == mess.flight_of(sock), "woken Sock %d's body is found by its id" % sock)
		_check(mess.is_moving(sock), "Sock %d counts as moving" % sock)
	_check(mess.moving_body(3) == null, "the Sock left lying still has none")
	await _settled()
	await _physics_ticks(1)
	for sock in 3:
		_check(mess.moving_body(sock) == null, "Sock %d, lying again, has no moving body" % sock)
	_check(mess._flight_by_sock.is_empty() and mess._flight_looks.is_empty(), "no body is kept once every Sock lies")


# --- B1, B2: the plan and the report ----------------------------------------------------------

func case_plan() -> void:
	var ids: Dictionary[StringName, bool] = {}
	for s in PLAN.scenarios:
		_check(not ids.has(s.id) and s.id != &"" and s.title != "", "scenario %s has its own id and a title" % s.id)
		ids[s.id] = true
	for id: StringName in [&"idle_500", &"idle_2000", &"idle_10000", &"pour_500", &"settle_500", &"burst_16", &"sweep"]:
		_check(PLAN.scenario(id) != null, "the plan has %s" % id)
	_check(PLAN.scenario(&"idle_10000").lying == 10000, "idle_10000 has 10,000 lying Socks")
	_check(PLAN.scenario(&"burst_16").count == 16, "burst_16 throws 16")
	_check(PLAN.scenario(&"pour_500").phase == MessBenchScenario.Phase.ACTING and PLAN.scenario(&"settle_500").phase == MessBenchScenario.Phase.SETTLING,
			"the pour is timed while it pours, the settling from its end")
	_check(PLAN.checks != null, "the plan names what counts as a fault")


func case_report() -> void:
	var a := _run_of("before", "abc1234", 1.0, {"lost": 2})
	var b := _run_of("after", "def5678", 0.5, {})
	var text := MessBenchReport.text([a, b], PLAN)
	_check(text.contains("| Scenario | before: tick ms | settle | faults | after: tick ms | settle | faults |"), "the runs stand side by side")
	_check(text.contains("| `settle_500` | 1.000 / 2.000 / 3.000 | 4.0 s | lost 2 | 0.500 / 1.000 / 1.500 | 4.0 s | - |"),
			"a scenario's row holds each run's ticks, settle time and faults")
	_check(text.contains("(`abc1234`)") and text.contains("(`def5678`)"), "each run names its commit")
	_check(text.contains("S3 (500 dropped on a pile"), "the old game's nearest number is in it")
	_check(text.contains("**fail**: lost 2"), "a failed scenario says why")
	_check(MessBench.line_of(a["results"][0]).begins_with("BENCH settle_500 socks=500 tick=1.000/2.000/3.000 ms scripts="), "a result prints as one BENCH line")


# --- Helpers -------------------------------------------------------------------------------------

func _scenario(kind: MessBenchScenario.Kind, lying: int, count: int) -> MessBenchScenario:
	var s := MessBenchScenario.new()
	s.id = &"case"
	s.kind = kind
	s.lying = lying
	s.count = count
	return s


## The benchmark's level with a scenario's starting Socks, bound, and a MessWatch on its Mess.
func _level_up(kind: MessBenchScenario.Kind, lying: int, count: int) -> void:
	_level = (load(LEVEL) as PackedScene).instantiate() as MessBenchLevel
	_level.prepare(_scenario(kind, lying, count), PLAN.dice)
	add_child(_level)
	await _until(func() -> bool: return _level.mess.parts != null and _level.mess.body_count() == lying, "the level's Socks to lie")
	_watch = MessWatch.new()
	_watch.mess = _level.mess
	_level.add_child(_watch)
	await _physics_ticks(1)


func _settled() -> void:
	await _until(func() -> bool: return not _level.acting() and _watch.settled(), "every Sock to come to rest", 3600)


func _no_faults(r: Dictionary) -> void:
	for key in FAULTS:
		_check(int(r[key]) == 0, "no Sock %s (%d)" % [key, r[key]])
	for key in COUNTED:
		_check(r.has(key), "Socks that %s are counted" % key)
	print("mess_settle: %d Socks rested; counted and not yet held at none: flips %d (fastest turn %.1f rad/s), sunk %d (deepest %.0f mm)"
			% [r["rests"], r["flips"], r["worst_spin"], r["sunk"], float(r["sunk_worst"]) * 1000.0])


## How many MultiMeshInstance3Ds under `root` the engine would physics-interpolate.
func _interpolated(root: Node) -> int:
	var n := 0
	for node in root.get_children():
		if node is MultiMeshInstance3D and (node as Node3D).is_physics_interpolated():
			n += 1
	return n


func _run_of(label: String, commit: String, tick: float, faults: Dictionary) -> Dictionary:
	var r := {"id": "settle_500", "title": "t", "old_game": "", "socks": 500, "lying": 500, "tick_med": tick, "tick_p95": tick * 2.0,
			"tick_worst": tick * 3.0, "ticks": 100, "script_med": 0.3, "script_p95": 0.4, "frame_med": 0.1, "frame_p95": 0.2, "wall_med": -1.0, "wall_p95": -1.0,
			"seconds": 5.0, "acted_for": 1.0, "settle_s": 4.0, "never": 0, "wakes_per_s": 0.0, "nodes": 100, "draws": -1,
			"rests": 500, "lost": 0, "jumped": 0, "hot": 0, "wakes": 0, "jitter": 0, "flips": 0, "peak_moving": 480,
			"worst_jump": 0.0, "worst_spin": 0.0, "moving": 0, "waiting": 0, "series": [1, 2], "sunk": 0, "inside": 0}
	r.merge(faults, true)
	var why := PackedStringArray()
	for key: String in faults:
		why.append("%s %d" % [key, faults[key]])
	r["ok"] = faults.is_empty()
	r["why"] = ", ".join(why)
	return {"label": label, "commit": commit, "date": "2026-11-21T00:00:0%d" % (1 if label == "after" else 0), "machine": "m",
			"verdict": "v", "results": [r]}
