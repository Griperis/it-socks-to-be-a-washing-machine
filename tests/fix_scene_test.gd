## The Fix scene (core/92, docs/architecture/stages.md "Its verbs", washer.md "Cutscenes: the washer's part"): a
## Machine Part fitted into the washing machine plays its Fix as a cutscene on the frame (the Stage names
## `fix_cutscene` and `fix_script` on the house plan); the floor opens at the scene's fade, under its black, and the
## spray plays after the Fixes that open a floor (not after the last). Played in the house, the Stage completed by
## the run's own Host verb and the Part carried and fitted by the player's own clicks.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const LAYING_S := 20.0
## The wall time a whole Fix scene may take (the longest recording plus the spray and the fades).
const SCENE_S := 90.0
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward", CutscenePlayer.SKIP]

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path_fix", "method": "case_real_path_fix", "world": false,
				"title": "real path: the player carries the New filter to the washing machine and clicks; cutscene_2 plays on the frame (the machine busy), the spray plays, and at its fade the ground floor's door opens, the Stage bar shows Stage 2 and the Stage 2 Socks are laid"},
		{"name": "last_fix", "method": "case_last_fix", "world": false,
				"title": "the fourth Fix plays cutscene_5 whole (one line), opens no floor, plays no spray and sets the machine fixed"},
		{"name": "plan_names_scenes", "method": "case_plan_names_scenes", "world": false,
				"title": "the house plan names a Fix cutscene and its script on each Stage, the script's voice the same trigger, a spray after Fixes 1 to 3 only; the zoo's mini plan names none"},
		{"name": "busy", "method": "case_busy", "world": false,
				"title": "the washing machine is busy while a cutscene plays or someone is in its drum, and the slot refuses the fit"},
		{"name": "load_mid_fix", "method": "case_load_mid_fix", "world": false,
				"title": "a load between the fit and the fade opens the floor after the load"},
		{"name": "skip", "method": "case_skip", "world": false,
				"title": "the Host's skip ends the Fix scene early and the floor opens at once, the door shut and the spray gone"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_level()


func _free_level() -> void:
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path_fix() -> void:
	await _house()
	var rt := LevelRuntime.of(_level)
	var stages := _stages()
	var cs := rt.cutscenes
	var cp := rt.cutscene_player
	var washer := Washer.of_level(_level)
	var spray := washer.sock_spray
	await _complete()
	await _carry_part_to_washer()
	var slot := _level.get_node("Washer/PartSlot/MachinePartSlot") as MachinePartSlot
	_check(rt.player.aimed_part() == slot, "the crosshair is on the washing machine's slot (%s)" % rt.player.aimed_part())
	await _press(&"pick")
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.PLAYING, "the click to start the Fix scene", 120)
	_check(stages.phase == Stages.Phase.FIXING and stages.stage == 0, "the Stage is FIXING while the scene plays")
	_check(cs.playing.ends_with("fix_scene_1.tres") and cs.trigger().id == &"cutscene_fix_1", "cutscene_2 plays (%s)" % cs.playing)
	_check(washer.busy(), "the washing machine is busy while it plays")
	var poured: Array = []
	var heard := func(e: StringName, _s: bool, at: Vector3, _b: StringName) -> void:
		if e == &"socks_pour":
			poured.append(at)
	Sounds.played.connect(heard)
	var seen := {"spray": false, "stage_at_spray": -1, "open_before_end": false}
	var door := _level.get_node("FloorLocks/Ground/Padlock/FloorLock") as FloorLock
	_check(door.is_locked(), "the ground floor's door is shut before the scene's fade")
	await _until(func() -> bool:
		if spray.playing and not seen["spray"]:
			seen["spray"] = true
			seen["stage_at_spray"] = stages.stage
		return not cs.is_playing(), "the Fix scene to end", 100000, SCENE_S)
	Sounds.played.disconnect(heard)
	var door_at := washer.porthole.global_position
	_check(poured.size() == 1 and (poured[0] as Vector3).distance_to(door_at) < 0.01, "socks_pour plays once at the porthole (%s)" % [poured])
	_check(seen["spray"] and seen["stage_at_spray"] == 0, "the spray played before the floor opened (%s)" % [seen])
	_check(stages.stage == 1 and stages.phase == Stages.Phase.PLAYING, "Stage 2 is current (%d, phase %d)" % [stages.stage, stages.phase])
	_check(not door.is_locked() and door.leaf().open, "the ground floor's door is open")
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.IDLE, "the view to come back", 300)
	var bar := rt.player.get_node("Hud/StageBar") as StageBar
	_check(bar.text().begins_with("Stage 2: Ground"), "the Stage bar shows Stage 2 (%s)" % bar.text())
	_check(not stages.spawned.is_empty() and stages.spawned.size() > 0, "Stage 2's Designs are on the run's list (%d)" % stages.spawned.size())
	await _until(func() -> bool: return stages.due.is_empty(), "Stage 2's Socks to be laid", 6000, LAYING_S)
	_check(not spray.playing and washer.looks.door == 0.0, "the spray is gone and the door is shut")
	var near := rt.player.global_position
	var spawn := (washer.get_parent().get_node("Spawns").get_child(0) as Node3D).global_position
	_check(Vector2(near.x - spawn.x, near.z - spawn.z).length() < 1.5, "everyone is back by the washer (%s)" % near)


func case_last_fix() -> void:
	await _house()
	var rt := LevelRuntime.of(_level)
	var stages := _stages()
	for i in 3:
		_ask(&"zoo_fit_now")
		await _until(func() -> bool: return stages.stage == i + 1, "Stage %d to open" % (i + 2))
	await _complete()
	var fixed: Array = []
	stages.machine_fixed.connect(func() -> void: fixed.append(true))
	await _carry_part_to_washer()
	await _press(&"pick")
	var cp := rt.cutscene_player
	var washer := Washer.of_level(_level)
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.PLAYING, "the click to start the last Fix scene", 120)
	_check(rt.cutscenes.trigger().id == &"cutscene_fix_4", "cutscene_5 plays")
	var lines := Voices.book().cutscene_lines("cutscene_fix_4")
	_check(lines.size() == 1 and cp.voiced, "it is one line, played whole (%d)" % lines.size())
	var sprayed := {"yes": false}
	await _until(func() -> bool:
		sprayed["yes"] = sprayed["yes"] or washer.sock_spray.playing
		return cp.phase == CutscenePlayer.Phase.HOLDING or not rt.cutscenes.is_playing(), "its timeline to run out", 100000, SCENE_S)
	_check(not sprayed["yes"], "no spray after the last Fix")
	_check(stages.phase == Stages.Phase.FIXING or stages.phase == Stages.Phase.FIXED, "the machine is not fixed before the fade")
	await _until(func() -> bool: return stages.phase == Stages.Phase.FIXED, "the machine to be fixed", 600)
	_check(stages.stage == 3 and fixed.size() == 1, "no floor opened and machine_fixed fired once (stage %d, %s)" % [stages.stage, fixed])
	_check(not sprayed["yes"] and not washer.sock_spray.playing, "still no spray")


func case_plan_names_scenes() -> void:
	var plan := load("res://game/run/house_stage_plan.tres") as StagePlan
	for i in plan.size():
		var s := plan.stage(i)
		_check(s.fix_cutscene != null and s.fix_script != null and s.fix_script.voice == s.fix_cutscene,
				"Stage %d names its Fix cutscene and a script playing the same trigger" % (i + 1))
		var sprays := false
		for beat in s.fix_script.beats:
			sprays = sprays or str(beat[1]) == "spray"
		_check(sprays == (i < plan.size() - 1), "Stage %d's script %s the spray" % [i + 1, "has" if sprays else "has no"])
		_check(Voices.book().cutscene_lines(String(s.fix_cutscene.id)).size() >= 1, "Stage %d's cutscene has its recorded line" % (i + 1))
	var mini := load("res://game/zoo/stages/mini_plan.tres") as StagePlan
	for i in mini.size():
		_check(mini.stage(i).fix_cutscene == null, "the zoo's mini plan Stage %d names none" % (i + 1))


func case_busy() -> void:
	await _house()
	var rt := LevelRuntime.of(_level)
	var washer := Washer.of_level(_level)
	var slot := _level.get_node("Washer/PartSlot/MachinePartSlot") as MachinePartSlot
	_check(not washer.busy() and not slot.busy(), "idle: not busy")
	var wash := washer.get_parent().get_node("Wash") as WasherWash
	wash.peer = 1
	_check(washer.busy() and slot.busy(), "someone in the drum: busy")
	wash.peer = 0
	rt.parts.apply(rt.cutscenes.start("res://game/voice/triggers/cutscene_fix_1.tres"))
	await _until(func() -> bool: return rt.cutscene_player.phase == CutscenePlayer.Phase.PLAYING, "a cutscene to play", 120)
	_check(washer.busy() and slot.busy(), "a cutscene plays: busy")
	rt.parts.ask(Command.new(Cutscenes.SKIP, Parts.HOST, rt.cutscenes.id))
	await _until(func() -> bool: return not rt.cutscenes.is_playing(), "the skip to end it", 120)
	_check(not washer.busy(), "over: free again")


func case_load_mid_fix() -> void:
	await _house()
	var rt := LevelRuntime.of(_level)
	var stages := _stages()
	await _complete()
	rt.parts.apply(stages.fit_answer())
	await _physics_ticks(2)
	_check(stages.phase == Stages.Phase.FIXING and rt.cutscenes.is_playing(), "fitted: FIXING and the scene plays")
	var saved := rt.parts.save_snapshot()
	var versions := rt.parts.save_versions()
	_free_level()
	await _house()
	rt = LevelRuntime.of(_level)
	stages = _stages()
	rt.parts.load_save(_roundtrip(saved), versions, "host")
	await _physics_ticks(3)
	_check(not rt.cutscenes.is_playing(), "a cutscene is not saved: nothing plays after the load")
	_check(stages.stage == 1 and stages.phase == Stages.Phase.PLAYING, "the floor opened after the load (stage %d, phase %d)" % [stages.stage, stages.phase])
	var door := _level.get_node("FloorLocks/Ground/Padlock/FloorLock") as FloorLock
	_check(not door.is_locked(), "the ground floor's door is open")


func case_skip() -> void:
	await _house()
	var rt := LevelRuntime.of(_level)
	var stages := _stages()
	var washer := Washer.of_level(_level)
	await _complete()
	rt.parts.apply(stages.fit_answer())
	await _until(func() -> bool: return rt.cutscene_player.phase == CutscenePlayer.Phase.PLAYING, "the scene to play", 120)
	await _press(CutscenePlayer.SKIP)
	await _until(func() -> bool: return stages.stage == 1, "the skip to open the floor", 300)
	_check(not rt.cutscenes.is_playing() and stages.phase == Stages.Phase.PLAYING, "the scene is over and Stage 2 counts")
	_check(not washer.sock_spray.playing and washer.looks.door == 0.0, "no spray, the door shut")


# --- Helpers -------------------------------------------------------------------------------------

func _house() -> void:
	SockGenerator.start_all = false
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	await _until(rt.loading.is_lifted, "the house's Stage 1 to be laid", 900, LAYING_S)
	await _until(func() -> bool: return rt.player.is_on_floor() and _stages().stage == 0, "the player to stand and the run to start")
	# The First wash is over (core/94's suite plays it): the held Socks lie, the Laundry day DONE.
	var day := _level.get_node("LaundryDay/Day") as LaundryDay
	await _until(func() -> bool: return _stages().due.is_empty(), "Stage 1's Socks to be laid and held", 3000, LAYING_S)
	if _stages().holding:
		rt.parts.apply(_stages().lay_first_answer())
	rt.parts.apply({"ok": true, "changes": {day.id: {"first_wash": LaundryDay.FirstWash.DONE}}})


func _stages() -> Stages:
	return _level.get_node("Run/Stages") as Stages


func _ask(verb: StringName) -> void:
	LevelRuntime.of(_level).parts.ask(Command.new(verb, Parts.HOST, _stages().id))


## The current Stage completes (the run's own Host verb): its Part pops and lies.
func _complete() -> void:
	_ask(&"zoo_complete")
	var stages := _stages()
	await _until(func() -> bool: return stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	var part := stages.machine_part()
	await _until(func() -> bool: return not part.popping(), "the Part to land", 300)


## The player clicks the lying Part to carry it, then stands at the washing machine aiming at it.
func _carry_part_to_washer() -> void:
	var rt := LevelRuntime.of(_level)
	var player := rt.player
	var part := _stages().machine_part()
	var thing := part.get_parent() as Node3D
	var lies := thing.global_position
	player.capture_mouse()
	_stand(player, lies + Vector3(0.0, 0.0, 1.3))
	await _aim(player, lies + Vector3.UP * 0.13)
	await _press(&"pick")
	await _until(func() -> bool: return rt.hands.carries(player.player_id()) == part.carriable, "the Part to be carried", 90)
	var washer := Washer.of_level(_level).get_parent() as Node3D
	var front := washer.global_position + washer.global_basis * Vector3(0.0, 0.0, 1.6)
	_stand(player, front)
	await _aim(player, washer.global_position + Vector3.UP * 0.45)


func _stand(player: Player, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)
