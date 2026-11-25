## The First wash (core/94, docs/architecture/run-ends.md "The First wash"): a New Game in the house holds the first
## Stage's Socks and reads "Wash the laundry"; a carried full bin clicked into the washing machine plays the intro
## cutscene (the calm wash with its bob, the break with the room's flicker, cutscene_1, the spray) and lets the Socks
## in; after it the bin is still full in the Hands, the machine is at its angriest, the bar shows Stage 1 and the next
## bin is refused. Once per World (saved). Lines are the behaviour list's (04 "A New Game before the First wash",
## "The First wash"). The co-op late joiner is tests/coop_first_wash_test.gd.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const STATION := "Stations/Laundry"
const KEEP := ["Laundry"]
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", CutscenePlayer.SKIP]
## The wall time the whole First wash may take (the calm wash, cutscene_1, the spray and the fades).
const SCENE_S := 90.0

var _holder: Node = null
var _house: Node3D = null
var _levels: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: a New Game in the house lays no Socks and reads Wash the laundry; the player clicks the bin into the washing machine; the First wash plays (calm wash, bob, bubbles, the break, the room's flicker); after it the Mess holds Stage 1's Socks, the bin is still full in the Hands, the bar shows Stage 1, the machine is angriest and a second click reads Fix the washing machine first"},
		{"name": "cutscene_off", "method": "case_cutscene_off", "world": false,
				"title": "with the cutscene off the start and the end are one answer: DONE, the Socks in, first_wash_done once, no cutscene, the bin full"},
		{"name": "busy", "method": "case_busy", "world": false,
				"title": "a bin clicked in while the washing machine is busy is refused The washing machine is busy and nothing moves; while it plays a second bin is refused too"},
		{"name": "before_it", "method": "case_before_it", "world": false,
				"title": "before the First wash the washer is fine and silent (no damage, no comment) and the Stage bar shows the goal; the first_wash_wanters and stage_bar_goal groups hold the Laundry day; FirstWashTuning's numbers drive first_wash.tres"},
		{"name": "load_mid_cutscene", "method": "case_load_mid_cutscene", "world": false,
				"title": "a World saved mid-First wash (PLAYING, the frame not saved) ends it at once on the Host: DONE with no cutscene"},
		{"name": "once_per_world", "method": "case_once_per_world", "world": false,
				"title": "it never plays again in that World: saved DONE, a reloaded World holds no Socks back, reads Stage 1 and the washer is angry"},
		{"name": "station", "method": "case_station", "world": false,
				"title": "the Laundry station: its First wash pillar sets it pending and holds a few Socks round the washer; a bin used on the washer lets them in at once (no cutscene in the zoo)"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_all()


func _free_all() -> void:
	if _holder != null:
		_holder.free()
		_holder = null
	for level in _levels:
		if is_instance_valid(level):
			var runtime := LevelRuntime.of(level)
			if runtime != null:
				runtime.session.close()
			level.get_parent().remove_child(level)
			level.free()
	_levels.clear()
	_house = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _house_up()
	var rt := LevelRuntime.of(_house)
	var player := rt.player
	var day := _day()
	var stages := _house.get_node("Run/Stages") as Stages
	var mess := rt.mess
	var washer := Washer.of_level(_house)
	var looks := washer.looks
	var cp := rt.cutscene_player
	var bar := player.get_node("Hud/StageBar") as StageBar
	await _until(func() -> bool: return day.drawn, "the draw", 300)
	_check(day.first_wash == LaundryDay.FirstWash.PENDING, "a New Game waits for the First wash")
	_check(stages.holding and not stages.held_designs.is_empty(), "the first Stage's Socks are laid and held (%d)" % stages.held_designs.size())
	_check(mess.count() == 0, "no Socks lie in the house (%d)" % mess.count())
	await _until(func() -> bool: return bar.text() == "Wash the laundry", "the bar to read Wash the laundry (%s)" % bar.text(), 120)
	_check(not washer.is_broken() and looks.damage == 0.0, "the washer looks fine")
	var held := stages.held_designs.size()
	# The bin by the washer, carried to the washing machine.
	var bin := _house.get_node("LaundryBins/Laundry/LaundryBin") as LaundryBin
	var thing := bin.get_parent() as Node3D
	await _stand_facing(player, thing.global_position + Vector3(1.0, 0.0, 0.0), thing.global_position + Vector3.UP * 0.26)
	await _press(&"pick")
	await _until(func() -> bool: return rt.hands.carries(1) == bin.carriable, "the bin to be carried", 60)
	var washer_thing := washer.get_parent() as Node3D
	await _stand_facing(player, washer_thing.global_position + Vector3(1.9, 0.0, 0.0), washer_thing.global_position + Vector3.UP * 0.5)
	_check(player.aimed_part() == washer, "the crosshair is on the washing machine")
	_check(player.hud().prompt_text().contains("Load the washing machine"), "it offers the load (%s)" % player.hud().prompt_text())
	var heard: Array[StringName] = []
	var on_sound := func(e: StringName, _s: bool, _at: Vector3, _b: StringName) -> void: heard.append(e)
	Sounds.played.connect(on_sound)
	await _press(&"pick")
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.PLAYING, "the click to start the First wash", 120)
	_check(rt.cutscenes.playing == LaundryDay.FIRST_WASH_SCRIPT and rt.cutscenes.trigger().id == &"cutscene_first_wash",
			"cutscene_1 plays on the frame (%s)" % rt.cutscenes.playing)
	_check(day.first_wash == LaundryDay.FirstWash.PLAYING, "the First wash is PLAYING")
	_check(cp.voiced, "the line is voiced")
	_check(mess.count() == held and not stages.holding, "the Socks are in the Mess at once, under the cutscene (%d of %d)" % [mess.count(), held])
	_check(not mess.drawn(), "the cutscene draws no Socks")
	# Part 1: the calm wash.
	var wide := washer_thing.get_node("Shots/Wide") as Node3D
	var seen := {"bob": 0.0, "bubbles": false, "loop": false, "spin": 0.0, "calm_damage": 0.0}
	await _until(func() -> bool:
		if looks.calm_washing():
			seen["bob"] = maxf(seen["bob"], absf(cp.camera.global_position.y - wide.global_position.y))
			seen["bubbles"] = seen["bubbles"] or looks.bubbling()
			seen["loop"] = seen["loop"] or looks.wash_looping()
			seen["spin"] = maxf(seen["spin"], looks.spin)
			seen["calm_damage"] = maxf(seen["calm_damage"], looks.broken_strength())
		return looks.room_flickering(), "the calm wash to break", 100000, 10.0)
	_near(seen["bob"], washer.tuning.shot_bob, 0.003, "the wide shot bobs 1 cm")
	_check(seen["bubbles"] and seen["loop"], "bubbles rise and the calm wash loops (%s)" % [seen])
	_near(seen["spin"], washer.tuning.wash_spin, 0.05, "the drum turns at wash_spin")
	_check(seen["calm_damage"] < 0.02, "no damage shows in the calm wash (%s)" % seen["calm_damage"])
	# The break.
	await _frames(2)
	_check(heard.has(&"machine_break"), "the clanks play")
	_check(not looks.bubbling() and not looks.wash_looping() and looks.spin == 0.0, "the bubbles, the loop and the drum stop")
	var lights := _house.get_node("Lights") as HouseLights
	var near_lamps: Array[Light3D] = []
	for node in lights.get_children():
		if node is Light3D and lights.flickers(node as Light3D):
			near_lamps.append(node as Light3D)
	_check(not near_lamps.is_empty(), "the room's lamps within 4 m flicker")
	var dimmed := {"yes": false}
	await _until(func() -> bool:
		dimmed["yes"] = dimmed["yes"] or lights.flicker < 0.99
		return dimmed["yes"], "a lamp to dip", 300)
	_check(looks.broken_on(), "the damage shows once it breaks")
	# To the end.
	await _until(func() -> bool: return not rt.cutscenes.is_playing(), "the First wash to end", 100000, SCENE_S)
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.IDLE, "the view to come back", 300)
	Sounds.played.disconnect(on_sound)
	_check(heard.has(&"socks_pour"), "the spray's whoosh played")
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.DONE, "the First wash to be DONE", 120)
	_check(mess.count() == held and mess.drawn(), "the Mess holds the first Stage's Socks, drawn again (%d)" % mess.count())
	_check(bin.full and rt.hands.carries(1) == bin.carriable, "the bin is still full in the Hands")
	await _until(func() -> bool: return bar.text().begins_with("Stage 1"), "the bar to show Stage 1 (%s)" % bar.text(), 200)
	_check(washer.is_broken() and washer.mood_level() == washer.mood_total(), "the machine is at its angriest (%d/%d)" % [washer.mood_level(), washer.mood_total()])
	await _until(func() -> bool: return looks.damage >= 0.99, "the damage at its angriest (%s)" % looks.damage, 60)
	_check(lights.flicker_range == 0.0, "the room's flicker ends with the cutscene")
	var spawn := (washer_thing.get_node("Spawns").get_child(0) as Node3D).global_position
	_check(Vector2(player.global_position.x - spawn.x, player.global_position.z - spawn.z).length() < 1.5, "the player is back by the washer")
	await _stand_facing(player, washer_thing.global_position + Vector3(1.9, 0.0, 0.0), washer_thing.global_position + Vector3.UP * 0.5)
	_check(not player.hud().prompt_text().contains("Load the washing machine"), "no load offered before the last Fix")
	await _press(&"pick")
	await _until(func() -> bool: return player.hud().refusal_text() == "Fix the washing machine first", "a second bin to be refused Fix the washing machine first", 60)
	_check(not rt.cutscenes.is_playing() and day.first_wash == LaundryDay.FirstWash.DONE, "it does not play again")


# --- The cutscene off ----------------------------------------------------------------------------

func case_cutscene_off() -> void:
	await _house_up()
	var rt := LevelRuntime.of(_house)
	var day := _day()
	var stages := _house.get_node("Run/Stages") as Stages
	day.cutscene = false
	var held := stages.held_designs.size()
	var done := [0]
	day.first_wash_done.connect(func() -> void: done[0] += 1)
	var bin := _carry_by_answer()
	rt.parts.ask(Command.new(LaundryDay.LOAD, 1, day.id))
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.DONE, "the First wash to be DONE at once", 60)
	_check(not rt.cutscenes.is_playing() and rt.cutscene_player.phase == CutscenePlayer.Phase.IDLE, "no cutscene plays")
	_check(rt.mess.count() == held and not stages.holding, "the Socks are in the Mess (%d)" % rt.mess.count())
	_check(done[0] == 1, "first_wash_done once (%d)" % done[0])
	_check(bin.full, "the bin is still full")
	await _frames(3)
	_check(Washer.of_level(_house).is_broken(), "the washer is broken")


# --- Busy ----------------------------------------------------------------------------------------

func case_busy() -> void:
	await _house_up()
	var rt := LevelRuntime.of(_house)
	var day := _day()
	_carry_by_answer()
	var cs := rt.cutscenes
	rt.parts.apply(cs.start("res://tests/fixtures/cutscene_silent.tres").merged({"to": cs.id}))
	_check(cs.is_playing(), "another cutscene plays")
	var answer := day.decide(Command.new(LaundryDay.LOAD, 1, day.id))
	_check(answer.get("reason", "") == LaundryDay.BUSY and LaundryDay.SAYS[LaundryDay.BUSY] == "The washing machine is busy", "busy: refused The washing machine is busy")
	_check(day.first_wash == LaundryDay.FirstWash.PENDING, "nothing moved")
	await _until(func() -> bool: return not cs.is_playing(), "that cutscene to end", 100000, 10.0)
	answer = day.decide(Command.new(LaundryDay.LOAD, 1, day.id))
	_check(answer.get("ok", false) and answer["changes"][day.id]["first_wash"] == LaundryDay.FirstWash.PLAYING, "free again: granted")
	rt.parts.apply(answer.merged({"to": day.id, "kind": LaundryDay.LOAD, "by": 1}))
	_check(day.decide(Command.new(LaundryDay.LOAD, 1, day.id)).get("reason", "") == LaundryDay.BUSY, "while it plays a bin is refused busy")
	rt.parts.ask(Command.new(Cutscenes.SKIP, Parts.HOST, cs.id))
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.DONE, "the skip to end the First wash", 120)


# --- Before it -----------------------------------------------------------------------------------

func case_before_it() -> void:
	await _house_up()
	var day := _day()
	var washer := Washer.of_level(_house)
	_check(day.is_in_group(Stages.FIRST_WASH_GROUP) and day.wants_first_wash(), "the Laundry day is a first_wash_wanter and wants it")
	_check(day.is_in_group(StageBar.GOAL_GROUP) and day.goal_pending(), "it is the Stage bar's goal while pending")
	_check(not washer.is_broken() and not washer.could_speak(), "the washer is not broken and makes no comment")
	var stare := Washer.trigger_of(&"washer_stare")
	var asked := washer.decide(Command.new(Washer.TALK, 1, washer.id, {"trigger": "washer_stare"}))
	_check(stare != null and asked.get("reason", "") == "quiet", "a comment is refused quiet (%s)" % asked)
	await _frames(3)
	_check(washer.looks.damage == 0.0 and washer.looks.repair == 1.0 and not washer.looks.broken_on(), "no sparks, no smoke, no buzz")
	LevelRuntime.of(_house).parts.apply({"ok": true, "changes": {day.id: {"first_wash": LaundryDay.FirstWash.PLAYING}}})
	_check(day.goal_pending() and not day.wants_first_wash(), "PLAYING: the goal still shows, nothing more is held")
	# The numbers are FirstWashTuning's.
	var s := load(LaundryDay.FIRST_WASH_SCRIPT) as CutsceneScript
	var t := s.numbers as FirstWashTuning
	_check(t != null and is_equal_approx(t.wash_seconds, 3.0) and t.bubbles == 40, "FirstWashTuning: 3 s, 40 bubbles")
	_near(s.lead_seconds(), t.wash_seconds, 0.0001, "the line starts after wash_seconds")
	_check(s.value("$bubbles") == 40 and is_equal_approx(float(s.value("$wash_seconds")), 3.0) and s.value("calm_wash") == "calm_wash",
			"the beats read the tuning by name")
	_check(is_equal_approx(s.after_voice_seconds, washer.sock_spray.tuning.length), "the spray's length follows the line")


# --- A load mid-cutscene -------------------------------------------------------------------------

func case_load_mid_cutscene() -> void:
	await _house_up()
	var rt := LevelRuntime.of(_house)
	var day := _day()
	var state := day.save_state()
	state["first_wash"] = LaundryDay.FirstWash.PLAYING
	day.write(state, true)
	_check(not rt.cutscenes.is_playing(), "the frame plays nothing (it is not saved)")
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.DONE, "the Host to end it", 60)
	_check(rt.cutscene_player.phase == CutscenePlayer.Phase.IDLE, "no cutscene")


# --- Once per World ------------------------------------------------------------------------------

func case_once_per_world() -> void:
	var w := Worlds.pick_solo()
	var house := await _world_house(w)
	var rt := LevelRuntime.of(house)
	var day := house.get_node("LaundryDay/Day") as LaundryDay
	day.cutscene = false
	_house = house
	_carry_by_answer()
	rt.parts.ask(Command.new(LaundryDay.LOAD, 1, day.id))
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.DONE, "the First wash", 60)
	var count := rt.mess.count()
	_check(rt.autosave.save_now()["ok"], "the Host saves")
	_free_all()
	await _frames(3)
	var again := Worlds.pick_solo()
	_check(again != null and not again.is_new, "the Solo World continues")
	house = await _world_house(again)
	rt = LevelRuntime.of(house)
	day = house.get_node("LaundryDay/Day") as LaundryDay
	var stages := house.get_node("Run/Stages") as Stages
	_check(day.first_wash == LaundryDay.FirstWash.DONE and not stages.holding, "saved DONE: nothing is held")
	_check(rt.mess.count() == count, "the Socks lie as saved (%d of %d)" % [rt.mess.count(), count])
	var bar := rt.player.get_node("Hud/StageBar") as StageBar
	await _until(func() -> bool: return bar.text().begins_with("Stage 1"), "the bar to show Stage 1 (%s)" % bar.text(), 200)
	_check(Washer.of_level(house).is_broken() and not rt.cutscenes.is_playing(), "the washer is broken and no cutscene plays")


# --- The station ---------------------------------------------------------------------------------

func case_station() -> void:
	_holder = Node.new()
	add_child(_holder)
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder.add_child(zoo)
	var rt := LevelRuntime.of(zoo)
	var player := rt.player
	var station := zoo.get_node(STATION) as Node3D
	await _until(func() -> bool: return player.is_on_floor(), "the zoo to stand", 300)
	player.capture_mouse()
	var day := station.get_node("LaundryDay/Day") as LaundryDay
	_check(day.first_wash == LaundryDay.FirstWash.DONE and not day.cutscene, "the station starts DONE with the cutscene off")
	var run := station.get_node("Run") as LaundryRun
	_check(day.stages == run and not day.wants_first_wash() and not day.goal_pending(), "the station's Laundry day reads its stand-in run, is not pending and shows no goal")
	var before := rt.mess.count()
	var pillar := station.get_node("FirstWashPillar") as Node3D
	await _stand_facing(player, pillar.global_position + Vector3(0.0, -0.5, 1.4), pillar.global_position)
	await _press(&"interact")
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.PENDING, "the pillar to reset the First wash", 60)
	_check(run.held_designs.size() == LaundryRun.HELD and rt.mess.count() == before, "a few Socks are held, none lie yet")
	var label := station.get_node("Tally") as Label3D
	await _physics_ticks(2)
	_check(label.text.contains("First wash pending"), "the label says so (%s)" % label.text)
	var bin := station.get_node("BinFull/LaundryBin") as LaundryBin
	rt.parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 1}}})
	player.global_position = (station.get_node("Washer") as Node3D).global_position + Vector3(0.0, -0.55, 1.5)
	await _physics_ticks(2)
	rt.parts.ask(Command.new(LaundryDay.LOAD, 1, day.id))
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.DONE, "the bin to start the First wash", 60)
	_check(rt.mess.count() == before + LaundryRun.HELD and run.held_designs.is_empty(), "the held Socks lie (%d)" % rt.mess.count())
	_check(not rt.cutscenes.is_playing() and bin.full, "no cutscene, the bin still full")


# --- Helpers -------------------------------------------------------------------------------------

func _house_up() -> void:
	_holder = Node.new()
	add_child(_holder)
	_house = (load(HOUSE) as PackedScene).instantiate() as Node3D
	_holder.add_child(_house)
	var runtime := LevelRuntime.of(_house)
	await _until(runtime.loading.is_lifted, "the house's Socks to be laid", 900, 20.0)
	await _until(func() -> bool: return runtime.player.is_on_floor(), "the player to stand in the house", 900)
	await _until(func() -> bool: return _day().drawn, "the draw", 300)
	var stages := _house.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return stages.due.is_empty(), "the first Stage's Socks to be laid", 3000, 20.0)
	runtime.player.capture_mouse()


## A house of World `world` (save_test's way).
func _world_house(world: WorldSlot) -> Node3D:
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var runtime := LevelRuntime.of(house)
	runtime.world = world
	runtime.from_title = world != null
	_levels.append(house)
	add_child(house)
	await _until(func() -> bool: return runtime.loading.is_lifted() and runtime.parts.is_bound and runtime.player.is_on_floor(), "the house to start", 3000, 30.0)
	return house


func _day() -> LaundryDay:
	return _house.get_node("LaundryDay/Day") as LaundryDay


## The bin by the washer is in player 1's Hands (set as an answer would) and the player stands at the washer.
func _carry_by_answer() -> LaundryBin:
	var rt := LevelRuntime.of(_house)
	var bin := _house.get_node("LaundryBins/Laundry/LaundryBin") as LaundryBin
	rt.parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 1}}})
	var washer_thing := Washer.of_level(_house).get_parent() as Node3D
	rt.player.global_position = washer_thing.global_position + Vector3(1.9, 0.0, 0.0)
	return bin


func _stand_facing(player: Player, feet: Vector3, target: Vector3) -> void:
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
