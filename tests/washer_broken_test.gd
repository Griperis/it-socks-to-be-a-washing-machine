## The broken washer's looks (core/87, docs/architecture/washer.md "How it looks, by state"): the sparks, smoke,
## flash and buzz as strong as the mood, bursts on a fixed clock with fixed seeds, the drum light dimmed and
## flickering by the repair, the angry rumble, a cutscene's look, the body that rides the bob.
## The real path: in the washer station the player presses E at the angriest mood pillar: sparks burst, the buzz
## plays and the drum light is dimmed to 0.3; at the calm pillar none of it shows and the light is steady.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const STATION_PATH := "Stations/WasherStation"
const ROOT := STATION_PATH + "/Washer"

var _holder: Node = null
var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the washer station the player presses E at the angriest mood pillar: sparks burst, the buzz plays, the drum light is 0.3 of its idle; at the calm pillar none show and the light is steady"},
		{"name": "from_the_run", "method": "case_from_the_run", "world": false,
				"title": "from the run: each Part fitted in a stand-in run makes the machine one step calmer (less damage, more repair); before the First wash it looks fine"},
		{"name": "strength", "method": "case_strength", "world": false,
				"title": "the effects scale with the mood: the buzz from -22 to -6 dB, the bursts' gap from 2.4 to 0.5 s; two machines burst together"},
		{"name": "flicker", "method": "case_flicker", "world": false,
				"title": "the drum's glow: dimmed to 0.3 at repair 0, flickering a new level every 70 ms down to 0.2, steady at repair 1"},
		{"name": "rumble", "method": "case_rumble", "world": false,
				"title": "the rumble plays only under an angry voice, from -36 to -12 dB by anger times wiggle, and stops when the anger goes"},
		{"name": "cutscene", "method": "case_cutscene", "world": false,
				"title": "a cutscene's look sets the repair and damage share; an angry loud stretch bursts, any other mood only smokes a little; its end gives the run's mood back"},
		{"name": "riding", "method": "case_riding", "world": false,
				"title": "a body lying on top rides the talking bob and lean: the riding body moves when the talk loop plays at full wiggle"},
	]


func _before_case() -> void:
	for a: StringName in [&"interact", &"move_forward"]:
		if InputMap.has_action(a):
			Input.action_release(a)
	_done()


func _done() -> void:
	if _holder != null:
		_holder.free()
		_holder = null
	_zoo = null
	Voices.reset()


func case_real_path() -> void:
	await _build()
	var w := _washer()
	var station := _station()
	var looks := w.looks as WasherLooks
	await _press_pillar(station.pillars["mood 5"])
	await _until(func() -> bool: return w.zoo_mood == 5, "the angriest pillar to set the level", 60)
	await _until(func() -> bool: return looks.sparking() and looks.buzzing(), "sparks to burst and the buzz to play", 600, 3.0)
	_check(looks.broken_on(), "the broken look is on")
	var idle := looks.tuning.glow_idle_energy
	_near(looks.dim(), 0.3, 0.001, "the drum light is dimmed to 0.3 of its idle")
	_check(looks.shown_energy() <= idle * 0.3 + 0.001, "so its energy is at most 0.3 of the idle (%.3f)" % looks.shown_energy())
	_near(looks.buzz_db(), looks.tuning.buzz_db_max, 0.01, "the buzz is at its loudest")
	await _press_pillar(station.pillars["mood 0"])
	await _until(func() -> bool: return w.zoo_mood == 0 and not looks.buzzing(), "the calm pillar to still the buzz", 600, 1.0)
	_check(not looks.broken_on(), "calm: no effects")
	await _physics_ticks(30)
	_near(looks.flicker(), 1.0, 0.0001, "calm: the light is steady")
	_near(looks.shown_energy(), looks.tuning.glow_idle_energy, 0.01, "calm: at the full idle strength")


func case_from_the_run() -> void:
	await _build()
	var w := _washer()
	var looks := w.looks as WasherLooks
	var plan := load("res://game/run/house_stage_plan.tres") as StagePlan
	var stages := Stages.new()
	stages.plan = plan
	w.zoo_mood = -1
	w.stages = stages
	stages.stage = 0
	w.broken = false
	await _physics_ticks(3)
	_near(looks.damage, 0.0, 0.0001, "before the First wash it looks fine: no damage")
	_near(looks.repair, 1.0, 0.0001, "and full repair")
	w.broken = true
	var last_damage := 2.0
	for fitted in plan.size():
		stages.stage = fitted
		await _until(func() -> bool: return w.mood_level() == plan.size() - fitted, "the mood to follow the Parts fitted (%d)" % fitted, 60)
		await _physics_ticks(2)
		_check(looks.damage < last_damage, "%d Parts fitted: calmer than before (%.2f)" % [fitted, looks.damage])
		_near(looks.repair, 1.0 - looks.damage, 0.0001, "and repaired by the same step")
		last_damage = looks.damage
	stages.phase = Stages.Phase.FIXED
	await _until(func() -> bool: return w.mood_level() == 0 and looks.damage == 0.0, "fixed: calm", 60)
	_near(looks.repair, 1.0, 0.0001, "fixed: full repair")
	w.stages = null
	stages.free()


func case_strength() -> void:
	var a := _looks()
	var b := _looks()
	var t := a.tuning
	a.damage = 1.0 / float(t.zoo_levels)
	await _physics_ticks(3)
	_near(a.buzz_db(), t.buzz_db_min, 0.01, "mood 1: the buzz at -22 dB")
	a.damage = 1.0
	await _physics_ticks(3)
	_near(a.buzz_db(), t.buzz_db_max, 0.01, "the angriest: the buzz at -6 dB")
	_near(a.broken_strength(), 1.0, 0.001, "full strength")
	b.damage = 1.0
	var bursts_a: Array[int] = []
	var bursts_b: Array[int] = []
	var last_a := false
	var last_b := false
	for i in 400:
		await _physics_ticks(1)
		var sa := a.flashing()
		var sb := b.flashing()
		if sa and not last_a:
			bursts_a.append(i)
		if sb and not last_b:
			bursts_b.append(i)
		last_a = sa
		last_b = sb
	_check(bursts_a.size() >= 2, "bursts come on a clock (%d in 400 ticks)" % bursts_a.size())
	_check(bursts_b.size() >= 2, "the other machine bursts too")
	if bursts_a.size() >= 3:
		var gap := float(bursts_a[2] - bursts_a[1]) / float(Engine.physics_ticks_per_second)
		_near(gap, t.burst_fastest, 0.2, "at full strength a burst every 0.5 s (%.2f)" % gap)
	var sp := a.get_node("Damage/SparksBack") as GPUParticles3D
	_check(sp.use_fixed_seed and sp.seed != 0, "the sparks have a fixed seed")
	a.free()
	b.free()


func case_flicker() -> void:
	var looks := _looks()
	var t := looks.tuning
	looks.repair = 0.0
	await _physics_ticks(2)
	_near(looks.dim(), t.repair_dim, 0.001, "repair 0: dimmed to 0.3")
	var seen := {}
	var lowest := 1.0
	for i in 200:
		await _physics_ticks(1)
		seen[snappedf(looks.flicker(), 0.0001)] = true
		lowest = minf(lowest, looks.flicker())
	_check(seen.size() > 5, "it flickers: %d levels in 200 ticks" % seen.size())
	_check(lowest >= 1.0 - t.repair_flicker - 0.001, "no deeper than 0.8 (%.2f)" % lowest)
	var changes := 0
	var prev := looks.flicker()
	for i in int(Engine.physics_ticks_per_second):
		await _physics_ticks(1)
		if looks.flicker() != prev:
			changes += 1
			prev = looks.flicker()
	_check(changes >= 8 and changes <= 15, "about 14 new levels a second (%d)" % changes)
	looks.repair = 1.0
	await _physics_ticks(3)
	_near(looks.dim(), 1.0, 0.001, "repair 1: undimmed")
	for i in 20:
		await _physics_ticks(1)
		_near(looks.flicker(), 1.0, 0.0001, "repair 1: steady")
	looks.free()


func case_rumble() -> void:
	var looks := _looks()
	var t := looks.tuning
	await _physics_ticks(3)
	_check(not looks.rumbling(), "silent: no rumble")
	looks.lit = true
	looks.angry = 1.0
	looks.wiggle = 1.0
	await _physics_ticks(3)
	_check(looks.rumbling(), "angry and loud: it rumbles")
	_near(looks.rumble_db(), t.rumble_db_max, 0.01, "at -12 dB")
	looks.wiggle = 0.5
	await _physics_ticks(3)
	_near(looks.rumble_db(), lerpf(t.rumble_db_min, t.rumble_db_max, 0.5), 0.01, "half as loud by the wiggle")
	looks.angry = 0.0
	await _physics_ticks(3)
	_check(not looks.rumbling(), "the anger goes, the rumble stops")
	looks.free()


func case_cutscene() -> void:
	var looks := _looks()
	var t := looks.tuning
	var fix1 := t.cutscene_look(&"cutscene_fix_1")
	var last := t.cutscene_look(&"cutscene_final_wash")
	_check(fix1 != null and last != null, "the tuning has the cutscene looks")
	looks.damage = 0.0
	looks.repair = 1.0
	looks.set_cutscene(fix1)
	_check(looks.cutscene_playing(), "a cutscene look is on")
	_near(looks.shown_repair(), fix1.repair, 0.0001, "its repair replaces the run's")
	await _physics_ticks(60)
	_check(not looks.sparking(), "between lines nothing bursts")
	looks.lit = true
	looks.angry = 1.0
	looks.wiggle = 1.0
	await _until(func() -> bool: return looks.sparking(), "an angry loud line to burst", 300, 2.0)
	await _until(func() -> bool: return absf(looks.broken_strength() - fix1.damage) < 0.05, "the strength to ease up to its share", 300, 2.0)
	looks.angry = 0.0
	looks.wiggle = 0.4
	await _physics_ticks(200)
	_check(looks.broken_on() and looks.broken_strength() < 0.3, "another mood only smokes a little (%.2f)" % looks.broken_strength())
	looks.set_cutscene(last)
	looks.angry = 1.0
	looks.wiggle = 1.0
	await _physics_ticks(120)
	_check(not looks.broken_on(), "the last cutscene has no share")
	looks.set_cutscene(null)
	_check(not looks.cutscene_playing(), "its end gives the run's mood back")
	_near(looks.shown_repair(), 1.0, 0.0001, "the run's repair again")
	looks.free()


func case_riding() -> void:
	var looks := _looks()
	var riding := looks.find_child("RidingBody", true, false) as AnimatableBody3D
	_check(riding != null, "a riding body")
	await _physics_ticks(30)
	var rest := riding.global_position
	looks.lit = true
	looks.angry = 0.0
	looks.wiggle = 1.0
	var moved := 0.0
	for i in 120:
		await _physics_ticks(1)
		moved = maxf(moved, riding.global_position.distance_to(rest))
	_check(moved > 0.0005, "it rides the talking bob and lean (%.4f)" % moved)
	looks.wiggle = 0.0
	await _physics_ticks(60)
	_check(riding.global_position.distance_to(rest) < 0.0005, "it settles when the machine is silent (%.4f)" % riding.global_position.distance_to(rest))
	looks.free()


# --- Helpers -------------------------------------------------------------------------------------

func _looks() -> WasherLooks:
	var looks := (load("res://game/entities/washer/looks_graybox.tscn") as PackedScene).instantiate() as WasherLooks
	add_child(looks)
	return looks


func _washer() -> Washer:
	return _zoo.get_node(ROOT + "/Washer") as Washer


func _station() -> WasherStation:
	return _zoo.get_node(STATION_PATH) as WasherStation


func _player() -> Player:
	return LevelRuntime.of(_zoo).player


func _build() -> void:
	_holder = Node.new()
	_holder.name = "Alone"
	add_child(_holder)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if String(station.name) != "WasherStation":
			station.get_parent().remove_child(station)
			station.free()
	_holder.add_child(_zoo)
	var at := (_zoo.get_node(STATION_PATH) as Node3D).global_position
	_player().global_position = at + Vector3(0.0, 0.1, 5.0)
	await _until(func() -> bool: return _player().is_on_floor(), "the player to stand in the station", 600)
	_player().capture_mouse()


func _press_pillar(pillar: WasherPillar) -> void:
	var body := pillar.get_parent() as Node3D
	await _stand_facing(body.global_position + Vector3(0.0, 0.0, 1.2), body.global_position + Vector3.UP * 0.5)
	await _press(&"interact")


func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var head := player.get_node("Head") as Node3D
	var look := target - player.global_position
	player.rotation.y = atan2(-look.x, -look.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)
