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
## Where the real path's extra Sock records lie (core/49): free floor on the Knockdown station's pad.
const EXTRA_AT := Vector3(-18.3, 0.0, 2.5)
## The faults a heap at rest must not have (MessWatch.result() and survey()). Two more are counted
## and reported but not yet held at none, because their cure changes how Socks move or rest and
## waits for the designer (core/31 Open follow-ups): "flips" (a Sock landing on its edge from the
## spout's height still turns faster than the limit for a tick or two) and "sunk" (a few Socks of a
## big heap rest pressed part-way into the floor).
## A Sock made inside another (by a pour's wave: "made_inside", core/49) is a fault. Socks a heap's
## weight presses into each other are allowed and counted (Q2499, Jolt's 20 mm slop): "pressed", and
## "inside" for the few the sharp boxes measure deeper (a slanted edge: Jolt's boxes have rounded edges).
## A moving Sock under the floor ("under", core/50: Jolt's position solve pushed one through the zoo's
## 0.2 m floor, and the rest rule then lifted it) is a fault.
const FAULTS: Array[String] = ["lost", "hot", "jumped", "jitter", "made_inside", "under"]
const COUNTED: Array[String] = ["flips", "sunk", "pressed", "inside"]

var _zoo: Node3D = null
var _level: MessBenchLevel = null
var _watch: MessWatch = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "Real path, B3: the player clicks More at the heap station; the heap pours and settles to no moving Sock within the benchmark's limit, none lost or glitching"},
		{"name": "real_path_1", "method": "case_real_path_1", "world": false,
				"title": "core/49: the same real path with 1 more Sock record in the zoo before the heap's (the ids and the physics shift): no Sock is made inside another"},
		{"name": "real_path_2", "method": "case_real_path_2", "world": false,
				"title": "core/49: the same real path with 2 more Sock records in the zoo: no Sock is made inside another"},
		{"name": "real_path_3", "method": "case_real_path_3", "world": false,
				"title": "core/49: the same real path with 3 more Sock records in the zoo: no Sock is made inside another"},
		{"name": "real_path_4", "method": "case_real_path_4", "world": false,
				"title": "core/49: the same real path with 4 more Sock records in the zoo: no Sock is made inside another"},
		{"name": "real_path_thin_floor", "method": "case_real_path_thin_floor", "world": false,
				"title": "core/50: the same real path with the zoo floor's collision margin at 1 mm (there Jolt pushes a poured Sock through the floor in every pour): no Sock goes under the floor, none is lifted at its rest or rests moving"},
		{"name": "pushed_in", "method": "case_pushed_in", "world": false,
				"title": "core/50: a falling Sock that one step moves down into the floor, more than its motion explains, is put back over the floor at once and rests on it, not lifted; one that moves only as it flies is left alone"},
		{"name": "wave_places", "method": "case_wave_places", "world": false,
				"title": "core/49: two Sock boxes crossed or stacked into each other meet, apart or side by side they do not; the spout never picks a place that meets another of its wave"},
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
				"title": "B3: a lying Sock under the floor is counted sunk, one overlapping another deeper than Jolt's slop is counted inside it, one within the slop pressed (Q2499); a clean stack has none"},
		{"name": "made_inside", "method": "case_made_inside", "world": false,
				"title": "core/49: two new Socks made overlapping are each counted made inside (a fault); one made apart is not"},
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
	await _real_path(0)


func case_real_path_1() -> void:
	await _real_path(1)


func case_real_path_2() -> void:
	await _real_path(2)


func case_real_path_3() -> void:
	await _real_path(3)


func case_real_path_4() -> void:
	await _real_path(4)


## core/50: a floor margin of 1 mm makes Jolt's wrong push happen in every pour (with the zoo's own
## margin it came in about one pour of 30); the floor's shape is a copy, the scene file is untouched.
func case_real_path_thin_floor() -> void:
	await _real_path(0, 0.001)


## The player clicks More at the heap station, with `extra` more Sock records lying in the zoo before
## the heap's (core/49: their count once decided whether two poured Socks rested inside each other).
func _real_path(extra: int, floor_margin := -1.0) -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	if floor_margin >= 0.0:
		var floor_shape := _zoo.get_node("Floor/Shape") as CollisionShape3D
		var thin := floor_shape.shape.duplicate() as BoxShape3D
		thin.margin = floor_margin
		floor_shape.shape = thin
	var spots := LevelRuntime.of(_zoo).spots
	for k in extra:
		var spot := SockSpot.new()
		spot.design = 4 + k
		spot.position = EXTRA_AT + Vector3(0.4 * k, 0.0, 0.0)
		spots.add_child(spot)
	add_child(_zoo)
	var mess := LevelRuntime.of(_zoo).mess
	var player := LevelRuntime.of(_zoo).player
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
	_check(_interpolated(LevelRuntime.of(_zoo).lying) == 0, "no MultiMesh of the Mess is physics-interpolated (%d)" % _interpolated(LevelRuntime.of(_zoo).lying))


# --- core/50: pushed into the floor --------------------------------------------------------------

## A Sock falls flat onto the benchmark level's floor (0.2 m thick, its top at 0). Just before it
## lands, its body is moved down to 0.12 m inside the floor, as Jolt's position solve moved one in the
## heap (core/50); the Mess's next tick puts it back over the floor, and it rests on the floor where it
## lands, written as it lay (no lift). A body that only flies, however fast, is never put back.
func case_pushed_in() -> void:
	await _level_up(MessBenchScenario.Kind.IDLE, 4, 0)
	var mess := _level.mess
	var fast := mess.thrown_patch(1, Transform3D(Basis.IDENTITY, Vector3(5.0, 1.2, 4.0)), Vector3(0.0, -8.0, 0.0), Vector3.ZERO, 1)
	_level.parts.apply({"ok": true, "kind": &"throw", "by": 1, "to": mess.id, "changes": {mess.id:
			mess.thrown_patch(0, Transform3D(Basis.IDENTITY, Vector3(4.0, 0.4, 4.0)), Vector3.ZERO, Vector3.ZERO, 1, false, fast)}})
	await _until(func() -> bool: return mess.moving_body(0) != null and mess.moving_body(1) != null, "the two Socks to fly")
	await _until(func() -> bool: return mess.moving_body(0).global_position.y < 0.2, "the slow one to fall to 0.2 m")
	var body := mess.moving_body(0)
	var before := body.global_transform
	body.global_transform = Transform3D(before.basis, Vector3(before.origin.x, -0.12, before.origin.z))
	# The test wakes on a frame; the Mess's tick of the next one sees the move (its second tick ends after it).
	await _physics_ticks(2)
	_check(mess._moving.pushed_in == 1, "the step into the floor was undone once (%d)" % mess._moving.pushed_in)
	_check(body.global_position.y > before.origin.y - 0.05, "the body is back where it was, not in the floor (%.3f m, was %.3f m)" % [body.global_position.y, before.origin.y])
	await _settled()
	_check(mess.state_of(0) == Mess.State.LYING and mess.state_of(1) == Mess.State.LYING, "both lie")
	_check(_watch.under == 0, "no Sock was seen under the floor (%d, deepest %.3f m)" % [_watch.under, _watch.worst_under])
	_check(_watch.jumped == 0 and _watch.hot == 0, "neither was lifted at its rest nor rested moving (jumped %d, hot %d)" % [_watch.jumped, _watch.hot])
	_near(mess.pose_of(0).origin.y, 0.0, 0.025, "the Sock lies on the floor's top")
	_check(mess._moving.pushed_in == 1, "the Sock thrown down at 8 m/s was never put back (%d)" % mess._moving.pushed_in)


# --- core/49: a wave's places --------------------------------------------------------------------

func case_wave_places() -> void:
	var box := SockDress.BOX
	var at := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0))
	var crossed := Transform3D(Basis(Vector3.UP, PI * 0.5), at.origin + Vector3(0.0, box.y * 0.3, 0.0))
	_check(MessBodies.boxes_meet(box, at, box, crossed), "two flat Socks crossed at nearly one height meet")
	_check(MessBodies.boxes_meet(box, at, box, Transform3D(Basis.IDENTITY, at.origin + Vector3(box.x * 0.6, 0.0, 0.0))),
			"two Socks overlapping end to end meet")
	_check(not MessBodies.boxes_meet(box, at, box, Transform3D(Basis.IDENTITY, at.origin + Vector3(0.0, box.y * 1.05, 0.0))),
			"one lying just over the other does not")
	_check(not MessBodies.boxes_meet(box, at, box, Transform3D(Basis.IDENTITY, at.origin + Vector3(0.0, 0.0, box.z * 1.05))),
			"side by side they do not")
	# Turned 45 degrees on the first one's diagonal: their bounding boxes overlap at both distances; the
	# boxes themselves meet only at the nearer one (a turned axis separates them at the farther).
	var turn := Basis(Vector3.UP, -PI * 0.25)
	var near := Transform3D(turn, at.origin + Vector3(0.2, 0.0, 0.2))
	var far := Transform3D(turn, at.origin + Vector3(0.25, 0.0, 0.25))
	_check(MessBodies.boxes_meet(box, at, box, near), "turned on the diagonal, near, they meet")
	_check(not MessBodies.boxes_meet(box, at, box, far), "turned on the diagonal, a little farther, they do not")
	_check(MessBodies.boxes_meet(box, near, box, at) and not MessBodies.boxes_meet(box, far, box, at), "the test does not depend on the order")
	# The spout's own pick: a wave's place that meets one of its others is refused.
	var taken: Array[Array] = [[box, at]]
	_check(HeapSpout._meets(taken, box, crossed), "the spout refuses a place inside one of its wave's")
	_check(not HeapSpout._meets(taken, box, Transform3D(Basis.IDENTITY, at.origin + Vector3(0.0, 0.0, box.z * 1.05))),
			"and takes one beside it")


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
	_check(int(clean["sunk"]) == 0 and int(clean["inside"]) == 0 and int(clean["pressed"]) == 0,
			"a stack of 40 has no sunk Sock and none pressed into or inside another (%s)" % str(clean))
	# Sock 0 is put under the floor, Sock 3 exactly where Sock 2 (its Design's other Sock) lies, Sock 7
	# on Sock 6 (the same Design) pressed 12 mm into it: within Jolt's slop (Q2499).
	var thick: float = (_watch._parts(6)[0][0] as Vector3).y
	var under := mess.pose_of(6).translated(Vector3.UP)
	var on := under
	on.origin += on.basis.y.normalized() * (thick - 0.012)
	var patch := mess.lying_patch(0, Transform3D(Basis.IDENTITY, mess.pose_of(0).origin + Vector3.DOWN * 0.05))
	patch = mess.lying_patch(3, mess.pose_of(2), patch)
	patch = mess.lying_patch(6, under, patch)
	patch = mess.lying_patch(7, on, patch)
	_level.parts.apply({"ok": true, "kind": &"put", "by": 1, "to": mess.id, "changes": {mess.id: patch}})
	await _physics_ticks(1)
	var found := _watch.survey()
	_check(int(found["sunk"]) == 1, "the Sock 5 cm under the floor is counted sunk (%d)" % found["sunk"])
	_near(float(found["sunk_worst"]), 0.05, 0.002, "and how deep")
	_check(int(found["inside"]) == 2, "the two Socks in one place are each counted inside the other (%d)" % found["inside"])
	_check(int(found["pressed"]) == 2, "the two Socks 12 mm into each other are each counted pressed, not inside (%d)" % found["pressed"])
	_near(float(found["pressed_worst"]), 0.012, 0.001, "and how deep")


## core/49: two new Socks made overlapping are counted made inside; one made apart is not.
func case_made_inside() -> void:
	await _level_up(MessBenchScenario.Kind.IDLE, 4, 0)
	var mess := _level.mess
	var design := mess.design_of(0).id
	var at := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.5, 0.0))
	var poses := PackedFloat32Array()
	for pose: Transform3D in [at, at.translated(Vector3(0.05, 0.005, 0.0)), at.translated(Vector3(0.0, 0.0, 1.0))]:
		poses.append_array(Mess.pack(pose))
	var zero := PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	_level.parts.ask(Command.new(&"add", Parts.HOST, mess.id,
			{"designs": PackedInt32Array([design, design, design]), "poses": poses, "vels": zero, "spins": zero}))
	await _until(func() -> bool: return mess.moving_count() == 3, "the three new Socks to fall")
	await _physics_ticks(1)
	_check(_watch.made_inside == 2, "the two made 5 cm apart, one through the other, are each counted made inside; the third is not (%d)" % _watch.made_inside)
	_check(int(_watch.result()["made_inside"]) == _watch.made_inside, "the count is in the result")


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
	print("mess_settle: %d Socks rested; counted and not yet held at none: flips %d (fastest turn %.1f rad/s), sunk %d (deepest %.0f mm), pressed %d (deepest %.1f mm), inside %d (deepest %.1f mm)"
			% [r["rests"], r["flips"], r["worst_spin"], r["sunk"], float(r["sunk_worst"]) * 1000.0, r["pressed"], float(r["pressed_worst"]) * 1000.0,
			r["inside"], float(r["inside_worst"]) * 1000.0])


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
