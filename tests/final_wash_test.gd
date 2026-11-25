## The Final wash (core/96, docs/architecture/run-ends.md "The Final wash and the end of the run"): the last bin
## clicked into the washing machine starts the ending after the tip's wait: the door shuts, the happy wash plays
## (the drum, the bubbles, the push-in, the room's lamps), cutscene_6 whole with the drum slowed, black is held, nobody
## respawns, then the run ends once: the Final screen is open over the frozen game, play time stopped, the World's
## record finished. A load after it began ends it at once; the senses are off. The co-op case is
## tests/coop_final_wash_test.gd. Lines are the behaviour list's (04 "The Final wash").
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", CutscenePlayer.SKIP]
## The wall time the whole Final wash may take (the wash, cutscene_6, the fades).
const SCENE_S := 120.0
## What the washer's clips draw (core/108; the old wash_spin, after_spin and happy.hop): the voiced drum's turns a
## second, its slow turn after the wash, and the unvoiced hop's height in metres.
const WASH_SPIN := 0.8
const AFTER_SPIN := 0.12
const HAPPY_HOP := 0.06

var _holder: Node = null
var _house: Node3D = null
var _levels: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: with one bin left the player clicks it into the washing machine; the tip's wait, then the door shuts and the happy wash plays (the drum, bubbles, the room's lamps flicker, the camera pushes in), cutscene_6 whole with the drum slowed and the bubbles off, black is held with nobody respawned, and the Final screen opens with play time stopped; the lamps are cleared and the senses are off"},
		{"name": "load_after_begun", "method": "case_load_after_begun", "world": false,
				"title": "a World saved with the Final wash begun but not ended ends at once on the Host: the Final screen is up, the record finished, the clock stopped; a World saved ended opens the screen at once"},
		{"name": "cutscene_off", "method": "case_cutscene_off", "world": false,
				"title": "with the cutscene off the Final wash begins and the run ends in one answer; the Host only asks it, once"},
		{"name": "unvoiced", "method": "case_unvoiced", "world": false,
				"title": "without a line the old happy look carries the wash: the body hops and sways, the glow is warm, the rumble plays, and all of it is gone when the cutscene ends"},
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
	var washer := Washer.of_level(_house)
	var looks := washer.looks
	var cp := rt.cutscene_player
	var bin := _one_bin_left()
	var thing := bin.get_parent() as Node3D
	await _stand_facing(player, thing.global_position + Vector3(1.0, 0.0, 0.0), thing.global_position + Vector3.UP * 0.26)
	await _press(&"pick")
	await _until(func() -> bool: return rt.hands.carries(1) == bin.carriable, "the bin to be carried", 60)
	var washer_thing := washer.get_parent() as Node3D
	await _stand_facing(player, washer_thing.global_position + Vector3(1.9, 0.0, 0.0), washer_thing.global_position + Vector3.UP * 0.5)
	_check(player.aimed_part() == washer, "the crosshair is on the washing machine")
	_check(player.hud().prompt_text().contains("Load the washing machine"), "it offers the load (%s)" % player.hud().prompt_text())
	var stood := player.global_position
	await _press(&"pick")
	await _until(func() -> bool: return day.loaded_bins == day.total(), "the last bin to load", 60)
	_check(day.ending_left >= 0.0 and not day.final_started, "the tip's wait runs first")
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.PLAYING, "the Final wash to start", 300)
	_check(day.final_started and not day.ended and day.ending_left < 0.0, "the Final wash began, the run has not ended")
	_check(rt.cutscenes.playing == LaundryDay.FINAL_WASH_SCRIPT and rt.cutscenes.trigger().id == &"cutscene_final_wash",
			"cutscene_6 plays on the frame (%s)" % rt.cutscenes.playing)
	_check(cp.voiced, "the line is voiced")
	var lights := _house.get_node("Lights") as HouseLights
	var push := washer_thing.get_node("Shots/Push") as Node3D
	var wide := washer_thing.get_node("Shots/Wide") as Node3D
	var seen := {"flicker": false, "bubbles": false, "spin": 0.0, "push": 0.0, "wide_to_push": wide.global_position.distance_to(push.global_position)}
	var start_gap := {"v": INF}
	await _until(func() -> bool:
		if looks.happy_washing():
			if start_gap["v"] == INF:
				start_gap["v"] = cp.camera.global_position.distance_to(wide.global_position)
			for node in lights.get_children():
				if node is Light3D and lights.flickers(node as Light3D):
					seen["flicker"] = true
			seen["bubbles"] = seen["bubbles"] or looks.bubbling()
			seen["spin"] = maxf(seen["spin"], looks.spin)
			seen["push"] = maxf(seen["push"], looks.shot_push())
		return looks.slowing(), "the happy wash to end", 100000, 20.0)
	_check(_door_shut(looks), "the washer's door is shut")
	_check(seen["flicker"], "the room's lamps within 4 m flicker in the happy wash")
	_check(seen["bubbles"] and absf(seen["spin"] - WASH_SPIN) < 0.05, "bubbles rise and the drum turns at 0.8 (%s)" % [seen])
	_check(seen["push"] > 0.99, "the camera's push ran its whole way (%s)" % seen["push"])
	_check(not looks.bubbling() or looks.slowing(), "the wash is over")
	_check(rt.cutscenes.is_playing(), "cutscene_6 follows the wash")
	# The line: the drum eases to after_spin, the bubbles stop a second later.
	await _until(func() -> bool: return not looks.bubbling(), "the bubbles to stop", 600, 10.0)
	_check(looks.spin <= WASH_SPIN and looks.spin >= AFTER_SPIN - 0.001, "the drum slows (%s)" % looks.spin)
	await _until(func() -> bool: return absf(looks.spin - AFTER_SPIN) < 0.001, "the drum to reach 0.12", 3000, 20.0)
	_check(not looks.drum_light.visible or looks.lit, "the drum light follows the line")
	# To the end: black, no respawn, then the screen.
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.BLACK or day.ended, "the cutscene to end on black", 100000, SCENE_S)
	await _until(func() -> bool: return day.ended and rt.final_screen.is_open(), "the Final screen to open", 600, 30.0)
	_check(cp.phase == CutscenePlayer.Phase.IDLE, "the cutscene's black let go for the screen")
	_check(player.global_position.distance_to(stood) < 0.05, "nobody respawned (%s)" % player.global_position)
	_check(day.ended and day.final_started, "the run has ended")
	_check(not looks.room_flickering() and lights.flicker_range == 0.0, "the room's lamps are cleared")
	await _frames(2)
	_check(not washer.senses_on() and not washer.could_speak(), "the washer's senses are off and it comments no more")
	_check(rt.final_screen.columns.size() == 1, "the screen has the player's column (%d)" % rt.final_screen.columns.size())
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "the mouse is free")


# --- A load after it began -----------------------------------------------------------------------

func case_load_after_begun() -> void:
	var w := Worlds.pick_solo()
	var house := await _world_house(w)
	_house = house
	var rt := LevelRuntime.of(house)
	var day := _day()
	var clock := rt.autosave.world.record
	_check(not clock.finished and not rt.final_screen.is_open(), "a fresh World is not finished")
	# Saved with the Final wash begun but not ended (the frame is never saved).
	var state := day.save_state()
	state["final_started"] = true
	day.write(state, true)
	_check(not rt.cutscenes.is_playing(), "the frame plays nothing")
	await _until(func() -> bool: return day.ended, "the Host to end the run at once", 120)
	await _until(func() -> bool: return rt.final_screen.is_open(), "the Final screen to open", 120)
	_check(clock.finished, "the World's record is finished")
	var at := clock.play_time
	await _frames(30)
	_check(clock.play_time == at, "play time has stopped (%s)" % clock.play_time)
	_check(day.play_seconds == int(at), "the play time it ended on is kept (%d)" % day.play_seconds)
	_check(rt.autosave.save_now()["ok"], "the Host saves")
	_free_all()
	await _frames(3)
	# A load of a World saved ended goes straight to the screen.
	var again := Worlds.pick_solo()
	house = await _world_house(again)
	_house = house
	rt = LevelRuntime.of(house)
	await _until(func() -> bool: return rt.final_screen.is_open(), "a load after the end to open the Final screen", 300)
	_check(_day().ended and rt.autosave.world.record.finished, "saved ended: the record stays finished")


# --- With the cutscene off -----------------------------------------------------------------------

func case_cutscene_off() -> void:
	await _house_up()
	var rt := LevelRuntime.of(_house)
	var day := _day()
	day.cutscene = false
	var bin := _one_bin_left()
	rt.parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 1}}})
	var washer_thing := Washer.of_level(_house).get_parent() as Node3D
	rt.player.global_position = washer_thing.global_position + Vector3(1.9, 0.0, 0.0)
	var guest := day.decide(Command.new(LaundryDay.FINAL_WASH, 2, day.id, {}))
	_check(not guest.get("ok", false), "a Guest cannot ask for the Final wash")
	rt.parts.ask(Command.new(LaundryDay.LOAD, 1, day.id))
	await _until(func() -> bool: return day.ended, "the run to end with the Final wash", 600, 20.0)
	_check(day.final_started and not rt.cutscenes.is_playing(), "begun and over, no cutscene")
	await _until(func() -> bool: return rt.final_screen.is_open(), "the Final screen to open", 120)
	_check(not day.decide(Command.new(LaundryDay.FINAL_WASH_END, Parts.HOST, day.id, {})).get("ok", false), "the end is asked once")
	_check(not day.decide(Command.new(LaundryDay.FINAL_WASH_END, 2, day.id, {})).get("ok", false), "a Guest cannot end it")


# --- Without a line ------------------------------------------------------------------------------

func case_unvoiced() -> void:
	await _house_up()
	var washer := Washer.of_level(_house)
	var looks := washer.looks
	var rest := looks.transform
	looks.set_voiced(false)
	looks.happy_wash(null)
	var moved := {"hop": 0.0, "sway": 0.0, "rumble": false}
	await _until(func() -> bool:
		moved["hop"] = maxf(moved["hop"], looks.transform.origin.y - rest.origin.y)
		moved["sway"] = maxf(moved["sway"], absf(looks.rotation.z - rest.basis.get_euler().z))
		moved["rumble"] = moved["rumble"] or looks.rumbling()
		return looks.happy_look() and moved["hop"] > 0.01 and moved["rumble"], "the unvoiced look to move", 600, 10.0)
	_check(moved["hop"] <= HAPPY_HOP + 0.001, "it hops no more than 6 cm (%s)" % moved["hop"])
	_check(moved["sway"] > 0.0, "it sways")
	_check(looks.lit and looks.spin > 0.0, "the glow is lit and the drum turns")
	looks.set_cutscene(null)
	await _frames(3)
	_check(looks.transform.is_equal_approx(rest) and not looks.happy_look() and looks.spin == 0.0 and not looks.bubbling(),
			"all of it is gone when the cutscene ends")
	_check(not looks.room_flickering(), "and the lamps are cleared")


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


## A house of World `world` (the First wash's suite's way).
func _world_house(world: WorldSlot) -> Node3D:
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var runtime := LevelRuntime.of(house)
	runtime.world = world
	runtime.from_title = world != null
	_levels.append(house)
	_house = house
	add_child(house)
	await _until(func() -> bool: return runtime.loading.is_lifted() and runtime.parts.is_bound and runtime.player.is_on_floor(), "the house to start", 3000, 30.0)
	await _until(func() -> bool: return _day().drawn, "the draw", 300)
	return house


func _day() -> LaundryDay:
	return _house.get_node("LaundryDay/Day") as LaundryDay


## The First wash done, the last Fix done, every drawn bin but the one by the washer loaded: that one is the last.
func _one_bin_left() -> LaundryBin:
	var rt := LevelRuntime.of(_house)
	var day := _day()
	var stages := _house.get_node("Run/Stages") as Stages
	var changes := {day.id: {"first_wash": LaundryDay.FirstWash.DONE, "loaded_bins": day.total() - 1}, stages.id: {"phase": Stages.Phase.FIXED}}
	var last: LaundryBin = null
	for bin in day.used_bins():
		if bin.always:
			last = bin
		else:
			changes[bin.id] = {"full": false}
	rt.parts.apply({"ok": true, "changes": changes})
	return last


func _door_shut(looks: WasherLooks) -> bool:
	return looks.door < 0.05


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
