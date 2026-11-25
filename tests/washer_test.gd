## The washing machine as an entity that talks (core/86, docs/architecture/washer.md "The entity"): the Looks
## contract and the bone rests the baked acting keys, the entity's parts (group, shots, spawns, the Door and the
## Porthole), the comment director (silent until the First wash has broken it, a cutscene, the cooldown, the
## chance, the comment set, the picker), the senses (stare, idle, progress, hit) and the zoo-only Commands.
## The real path: in the washer station the player presses the pillars, then looks at the machine for 4 s from
## 3 m and a stage_1 stare line's subtitle shows and the door bone opens; the same Command from a Guest plays the
## same line on both machines (real ENet); in the house the machine stands at its old place, outlined and
## named, and E does nothing at it.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const STATION := "res://game/zoo/stations/washer.tscn"
const HOUSE := "res://game/house/house.tscn"
const FOLDER := "res://game/entities/washer/"
const SPEAKER := preload("res://game/voice/speakers/washer.tres")
const STATION_PATH := "Stations/WasherStation"
const ROOT := STATION_PATH + "/Washer"
const NET_WAIT_S := 20.0
const OLD_PLACE := Vector3(0.46, -3.0, 5.21)

var _holder: Node = null
var _zoo: Node3D = null
var _house: Node3D = null
var _machines: Array[Dictionary] = []
var _started: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the washer station, Stage 1 and Break it pressed, the player looks at the machine 4 s from 3 m: a stage_1 stare line's subtitle shows and the door bone opens"},
		{"name": "guest_stare", "method": "case_guest_stare", "world": false,
				"title": "co-op, real ENet: a Guest's stare is decided on the Host and plays the same line on both machines"},
		{"name": "house", "method": "case_house", "world": false,
				"title": "in the house the machine stands at the old place, in group washer, the generators' NodePath still reaches it; the crosshair names it Washing machine with no key and E does nothing; it stays silent"},
		{"name": "contract", "method": "case_contract", "world": false,
				"title": "every washer Looks loads and has what looks_contract.json names: the bones and their parents, the three players' animations, the properties, the lit drum on its own layer"},
		{"name": "rests", "method": "case_rests", "world": false,
				"title": "the bone rests of washer_acting.tres (lean, door_hinge, the brows) are the rests of every Looks' skeleton"},
		{"name": "face", "method": "case_face", "world": false,
				"title": "the face: a take's acting opens the door bone and lights the drum, rest goes back to the basic pose; wiggle weights the bob, spin turns the drum, door and pile and bubbles follow what the washes set"},
		{"name": "entity", "method": "case_entity", "world": false,
				"title": "the entity: group washer, is_washer, the box 0.7 x 0.95 x 0.7 on the player's block layer, Shots/Wide and Close, Spawns 1..4, Door and Porthole, the name for the crosshair"},
		{"name": "director", "method": "case_director", "world": false,
				"title": "the director: no comment before it is broken, none during a cutscene, none within 120 s of the last, the chance, never the last line; a trigger it does not know is refused"},
		{"name": "comment_set", "method": "case_comment_set", "world": false,
				"title": "the comment set follows the Stage (the station's stand-in's, the run's) and is the Laundry day's after the last Fix; every line given belongs to it"},
		{"name": "senses", "method": "case_senses", "world": false,
				"title": "the senses: idle after the quiet spell, a progress comment on a shelved Pair, a hit within 1.4 m on the floor plane, nothing when the level is not a staged run"},
		{"name": "talk_only", "method": "case_talk_only", "world": false,
				"title": "the washing machine grants only talk; the station's switches are its run stand-in's Commands, a Guest may ask them, a mood past the pillars is refused"},
		{"name": "pillars", "method": "case_pillars", "world": false,
				"title": "the station builds its pillars from the data: moods 0..5, a Stage each and the Laundry day, From the run, Break it, Fix it, a trigger each; a mood pillar sets damage and repair"},
	]


func _before_case() -> void:
	for a: StringName in [&"interact", &"move_forward"]:
		if InputMap.has_action(a):
			Input.action_release(a)
	_started.clear()
	if not Voices.started.is_connected(_on_started):
		Voices.started.connect(_on_started)
	_done()


func _on_started(line: VoiceLine, take: int) -> void:
	_started.append({"line": line, "take": take})


func _done() -> void:
	if _holder != null:
		_holder.free()
		_holder = null
	_zoo = null
	_house = null
	for m in _machines:
		(m["session"] as Session).close()
		var path := (m["node"] as Node).get_path()
		remove_child(m["node"])
		(m["node"] as Node).free()
		get_tree().set_multiplayer(null, path)
	_machines.clear()
	Voices.reset()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var w := _washer()
	var station := _station()
	_check(w.stages == station.run and w.senses_on(), "the station's washing machine reads the stand-in and has its senses on")
	await _press_pillar(station.pillars["stage 1"])
	await _until(func() -> bool: return station.run.at == 0, "Stage 1 to be set by the pillar", 60)
	await _press_pillar(station.pillars["break"])
	await _until(func() -> bool: return w.is_broken(), "Break it to break the machine", 60)
	_lucky(w)
	var thing := w.get_parent() as Node3D
	var door := w.looks.rig.find_bone(&"door_hinge")
	await _stand_facing(thing.global_position + Vector3(0.0, 0.0, 3.0), thing.global_position + Vector3.UP * 0.5)
	_check(not Voices.talking(&"washer"), "it is quiet before the look")
	await _until(func() -> bool: return Voices.talking(&"washer"), "the 4 s stare to make it talk", 600, 10.0)
	var line := Voices.line_of(&"washer")
	_check(line != null and line.has_trigger(&"washer_stare"), "a stare line is given (%s)" % [line.id if line != null else &""])
	_check(line != null and (line.sets.is_empty() or line.sets.has(1)), "it belongs to the stage_1 set")
	_check(Voices.subtitle_text(&"washer") != "", "its subtitle shows (%s)" % Voices.subtitle_text(&"washer"))
	var widest := 0.0
	var seconds := 0.0
	while Voices.talking(&"washer") and seconds < 4.0:
		await _physics_ticks(1)
		seconds += 1.0 / Engine.physics_ticks_per_second
		widest = maxf(widest, w.looks.rig.get_bone_pose_rotation(door).angle_to(Quaternion.IDENTITY))
	_check(widest > 0.1, "the door bone opens with the voice (%.2f rad)" % widest)


func case_guest_stare() -> void:
	var host := _machine("Host")
	_check((host["session"] as Session).host() == OK, "the Host listens")
	var guest := await _guest("Guest")
	var hp := host["parts"] as Parts
	var gp := guest["parts"] as Parts
	var g_id := (guest["session"] as Session).me()
	var hw := hp.of(&"WasherStation/Washer/Washer") as Washer
	var gw := gp.of(&"WasherStation/Washer/Washer") as Washer
	var gr := gp.of(&"WasherStation/Run") as WasherRun
	_check(hw != null and gw != null and gr != null, "both machines have the washing machine's Part and the stand-in")
	gp.ask(Command.new(WasherRun.BROKEN, g_id, gr.id, {"on": true}))
	await _until(func() -> bool: return hw.is_broken() and gw.is_broken(), "a Guest's Break it to reach both", 900, NET_WAIT_S)
	_lucky(hw)
	_started.clear()
	gp.ask(Command.new(Washer.TALK, g_id, gw.id, {"trigger": "washer_stare"}))
	await _until(func() -> bool: return gw.serial == 1 and hw.serial == 1, "the Host's answer to reach both", 900, NET_WAIT_S)
	_check(hw.last_at > -INF and gw.last_at == -INF, "the Host decided: its cooldown ran, the Guest's did not")
	_check(hw.line == gw.line and hw.take == gw.take and hw.line != &"", "both hold the same line and take (%s, %d)" % [hw.line, hw.take])
	await _until(func() -> bool: return _started.size() == 2, "both machines to play it", 900, NET_WAIT_S)
	_check(_started[0]["line"] == _started[1]["line"] and _started[0]["take"] == _started[1]["take"], "both played the same line and take")
	_check((_started[0]["line"] as VoiceLine).has_trigger(&"washer_stare"), "a stare line")
	# The cooldown holds a second stare on the Host's say alone.
	gp.ask(Command.new(Washer.TALK, g_id, gw.id, {"trigger": "washer_stare"}))
	await _frames(30)
	_check(hw.serial == 1, "a second stare inside the cooldown is a silent no")
	# A Guest cannot ask for the zoo's Commands the station did not offer it by shape.
	var bad := hp.answer(Command.new(Washer.TALK, g_id, hw.id, {"trigger": "no_such_trigger"}))
	_check(bad.get("ok", true) == false, "an unknown trigger is refused")
	for m in _machines:
		(m["session"] as Session).close()
	await _frames(2)


func case_house() -> void:
	_holder = Node.new()
	add_child(_holder)
	_house = (load(HOUSE) as PackedScene).instantiate() as Node3D
	_holder.add_child(_house)
	var runtime := LevelRuntime.of(_house)
	var player := runtime.player
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand in the house", 900)
	var root := _house.get_node("Washer") as Node3D
	var w := root.get_node("Washer") as Washer
	_check(root.global_position.distance_to(OLD_PLACE) < 0.001, "it stands at the old marker's place (%s)" % root.global_position)
	_check(root.is_in_group(Washer.GROUP) and Washer.is_washer(root.get_node("Shape")), "it is in group washer")
	var generator := _house.get_node("SockGenerators/Basement")
	_check(generator.get("washer") == root, "the Sock generators' NodePath reaches it")
	_check(w.stages == _house.get_node("Run/Stages"), "it reads the house's run")
	await _stand_facing(root.global_position + Vector3(0.0, 0.0, 1.4), root.global_position + Vector3.UP * 0.5)
	_check(player.aimed_part() == w, "the crosshair is on it")
	_check(player.hud().prompt_text().contains("Washing machine"), "it reads Washing machine (%s)" % player.hud().prompt_text())
	_check(not player.hud().prompt_text().contains("["), "with no key on the row (%s)" % player.hud().prompt_text())
	_check(player.aimed_outline != null and player.aimed_outline.shown, "it is outlined")
	var before := w.state()
	await _press(&"interact")
	_same(w.state(), before, "E changes nothing at it")
	var cmd := runtime.parts.answer(Command.new(Washer.TALK, Parts.HOST, w.id, {"trigger": "washer_stare"}))
	_check(cmd.get("ok", true) == false and cmd.get("reason", "") == "quiet", "it stays silent before the First wash has broken it")
	var stages := w.stages
	_check(w.senses_on() == (stages.stage >= 0), "its senses are on exactly while a staged run is under way (Stage %d)" % (stages.stage + 1))


# --- The Looks -----------------------------------------------------------------------------------

static func looks_paths() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(FOLDER):
		if f.begins_with("looks") and f.ends_with(".tscn"):
			out.append(FOLDER + f)
	return out


func _contract() -> Dictionary:
	var contract: Variant = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + "looks_contract.json"))
	_check(contract is Dictionary, "looks_contract.json reads")
	return contract if contract is Dictionary else {}


func case_contract() -> void:
	var contract := _contract()
	var paths := looks_paths()
	_check(not paths.is_empty(), "the folder has a Looks")
	for path in paths:
		var scene := load(path) as PackedScene
		_check(scene != null, "%s loads" % path.get_file())
		if scene == null:
			continue
		var looks := scene.instantiate() as WasherLooks
		_check(looks != null, "%s's root is a WasherLooks" % path.get_file())
		if looks == null:
			continue
		add_child(looks)
		var name := path.get_file()
		for n: String in contract.get("nodes", []) + contract.get("paths", []):
			_check(looks.get_node_or_null(n) != null, "%s has %s" % [name, n])
		for n: String in contract.get("named", []):
			_check(looks.find_child(n, true, false) != null, "%s has a %s somewhere" % [name, n])
		var rig := looks.get_node_or_null("face_rig") as Skeleton3D
		_check(rig != null, "%s has a Skeleton3D named face_rig" % name)
		if rig != null:
			for b: String in contract.get("bones", []):
				_check(rig.find_bone(b) >= 0, "%s has the bone %s" % [name, b])
			var parents: Dictionary = contract.get("parents", {})
			for b: String in parents:
				var i := rig.find_bone(b)
				_check(i >= 0 and rig.get_bone_parent(i) == rig.find_bone(String(parents[b])), "%s: %s is under %s" % [name, b, parents[b]])
		var players: Dictionary = contract.get("players", {})
		for p: String in players:
			var player := looks.get_node_or_null(p) as AnimationPlayer
			_check(player != null and player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS,
					"%s has an AnimationPlayer %s on physics frames" % [name, p])
			for a: String in players[p]:
				_check(player != null and player.has_animation(a), "%s's %s has %s" % [name, p, a])
		for prop: String in contract.get("properties", []):
			_check(prop in looks, "%s has the property %s" % [name, prop])
		for m: String in contract.get("methods", []):
			_check(looks.has_method(m), "%s has the method %s" % [name, m])
		var light := looks.find_child("DrumLight", true, false) as OmniLight3D
		if light != null:
			_near(light.omni_range, 0.45, 0.001, "%s: the drum light reaches 0.45 m" % name)
			_check(light.get_parent() is BoneAttachment3D and (light.get_parent() as BoneAttachment3D).bone_name == "drum_spin",
					"%s: the drum light rides drum_spin" % name)
			var lining := looks.find_child("Lining", true, false) as VisualInstance3D
			_check(light.light_cull_mask & 1 == 0 and lining != null and lining.layers & light.light_cull_mask != 0,
					"%s: the light lights only the drum's own layer" % name)
		var riding := looks.find_child("RidingBody", true, false) as AnimatableBody3D
		_check(riding != null and riding.get_parent() is BoneAttachment3D and (riding.get_parent() as BoneAttachment3D).bone_name == "bob",
				"%s: a body rides the bob" % name)
		looks.free()


func case_rests() -> void:
	var acting := SPEAKER.acting
	for path in looks_paths():
		var looks := (load(path) as PackedScene).instantiate() as Node3D
		add_child(looks)
		var rig := looks.get_node("face_rig") as Skeleton3D
		var want := {acting.lean_bone: acting.lean_rest, acting.mouth_bone: acting.mouth_rest,
				acting.brow_left_bone: acting.brow_left_rest, acting.brow_right_bone: acting.brow_right_rest}
		for bone: StringName in want:
			var i := rig.find_bone(bone)
			_check(i >= 0, "%s has the bone %s the acting keys" % [path.get_file(), bone])
			if i >= 0:
				var rest := rig.get_bone_rest(i)
				var expect: Transform3D = want[bone]
				_check(rest.is_equal_approx(expect), "%s: %s rests as washer_acting.tres says (%s vs %s)" % [path.get_file(), bone, rest, expect])
		looks.free()


func case_face() -> void:
	var looks := (load(FOLDER + "looks_graybox.tscn") as PackedScene).instantiate() as WasherLooks
	add_child(looks)
	await _physics_ticks(3)
	var rig := looks.rig
	var door := rig.find_bone(&"door_hinge")
	var bob := rig.find_bone(&"bob")
	var drum := rig.find_bone(&"drum_spin")
	var tuning := looks.tuning
	# Silent: the idle glow, the light off, the door shut.
	_check(not looks.lit and not looks.drum_light.visible, "silent: the light in the drum is off")
	_check(looks.shown_glow().is_equal_approx(tuning.glow_idle_colour), "silent: the lining glows its idle colour")
	_near(looks.shown_energy(), tuning.glow_idle_energy, 0.01, "silent: at the idle strength")
	# A take's acting.
	var line := _stare_line()
	var take := line.takes[0]
	looks.act(take)
	_check(looks.lit and looks.is_acting(), "a take acts and lights the drum")
	var widest := 0.0
	for i in 240:
		await _physics_ticks(1)
		widest = maxf(widest, rig.get_bone_pose_rotation(door).angle_to(Quaternion.IDENTITY))
		if not looks.is_acting():
			break
	_check(widest > 0.1, "the acting opens the door bone (%.2f rad)" % widest)
	_check(looks.drum_light.visible, "the light inside the drum is on while it speaks")
	looks.rest()
	await _physics_ticks(3)
	_check(not looks.lit and not looks.drum_light.visible, "rest: the light is off again")
	_near(rig.get_bone_pose_rotation(door).angle_to(Quaternion.IDENTITY), 0.0, 0.001, "rest: the door is shut")
	# The body loop is weighted by the wiggle.
	looks.wiggle = 1.0
	var moved := 0.0
	for i in 40:
		await _physics_ticks(1)
		moved = maxf(moved, (rig.get_bone_pose(bob).origin - rig.get_bone_rest(bob).origin).length())
	_check(looks.loops.is_playing() and moved > 0.001, "wiggle 1: the bob moves (%.4f m)" % moved)
	looks.wiggle = 0.0
	await _physics_ticks(3)
	_check(not looks.loops.is_playing() and rig.get_bone_pose(bob).is_equal_approx(rig.get_bone_rest(bob)), "wiggle 0: completely still")
	looks.wiggle = 1.0
	looks.angry = 1.0
	await _physics_ticks(3)
	_check(looks.loops.current_animation == "rumble", "angry: it rumbles instead of bobbing")
	looks.wiggle = 0.0
	looks.angry = 0.0
	await _physics_ticks(3)
	# The drum.
	looks.spin = 0.8
	await _physics_ticks(10)
	_check(looks.spinner.is_playing() and is_equal_approx(looks.spinner.speed_scale, 0.8), "spin 0.8 turns the drum at 0.8 a second")
	_check(rig.get_bone_pose_rotation(drum).angle_to(Quaternion.IDENTITY) > 0.01, "the drum bone has turned")
	looks.spin = 0.0
	await _physics_ticks(3)
	_check(not looks.spinner.is_playing() and rig.get_bone_pose(drum).is_equal_approx(rig.get_bone_rest(drum)), "spin 0: the drum is still, at its rest")
	# The washes' door, the pile, the bubbles.
	looks.door = 1.0
	await _physics_ticks(3)
	_near(rad_to_deg(rig.get_bone_pose_rotation(door).angle_to(Quaternion.IDENTITY)), SPEAKER.acting.mouth_open, 0.5, "door 1: open 40 degrees")
	looks.door = 0.0
	await _physics_ticks(3)
	_near(rig.get_bone_pose_rotation(door).angle_to(Quaternion.IDENTITY), 0.0, 0.001, "door 0: shut")
	_check(not looks.pile_node.visible, "pile 0: no laundry behind the porthole")
	looks.pile = 1.0
	await _physics_ticks(2)
	_check(looks.pile_node.visible and looks.pile_node.scale.is_equal_approx(Vector3.ONE), "pile 1: the whole heap")
	_check(not looks.bubbling(), "no bubbles")
	looks.bubbles(true)
	_check(looks.bubbling(), "bubbles rise")
	looks.free()


# --- The entity and its director -----------------------------------------------------------------

func case_entity() -> void:
	await _build()
	var w := _washer()
	var root := w.get_parent() as StaticBody3D
	_check(root.is_in_group(Washer.GROUP) and Washer.of(get_tree()) == w, "it is in group washer and Washer.of finds it")
	_check(Washer.is_washer(root.get_node("Looks")) and not Washer.is_washer(_zoo), "is_washer is true of the machine's nodes only")
	var shape := (root.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
	_check(shape.size.is_equal_approx(Vector3(0.7, 0.95, 0.7)), "a box 0.7 x 0.95 x 0.7 m")
	var body := root.get_node("PlayerBody") as StaticBody3D
	_check(body.collision_layer == Player.BLOCK_LAYER, "the player's body meets it on the block layer")
	for shot_name: String in ["Wide", "Close"]:
		var shot := root.get_node("Shots/%s" % shot_name) as WasherShot
		_check(shot != null and is_equal_approx(shot.fov, 60.0), "Shots/%s has its fov 60" % shot_name)
	var wide := root.get_node("Shots/Wide") as Marker3D
	_check(wide.position.is_equal_approx(Vector3(0.35, 1.425, 2.0)), "the wide shot stands 2.0 m out, 0.95 m over the middle, 0.35 m to the right")
	var middle := Vector3(0.0, 0.525, 0.0)
	_check((-wide.global_basis.z).angle_to(root.to_global(middle) - wide.global_position) < 0.01, "and looks at the middle 0.05 m up")
	var close := root.get_node("Shots/Close") as Marker3D
	_check(close.position.is_equal_approx(Vector3(0.06, 0.99, 1.05)), "the close shot stands 0.75 m out from the face, 0.42 m up, 0.06 m right")
	for n: int in [1, 2, 3, 4]:
		_check(root.get_node_or_null("Spawns/%d" % n) is Marker3D, "Spawns/%d is a marker" % n)
	_check(root.get_node("Door").position.is_equal_approx(Vector3(0.0, 0.0, 0.35)), "Door is the middle of the door's front on the floor")
	_check(root.get_node("Porthole") is Marker3D, "Porthole is a marker")
	_check(w.prompt_title() == "Washing machine" and w.hint_only(), "it is named for the crosshair and has no use")
	_check(Prompts.target(w)[0].keys.is_empty(), "its row carries no key")
	var before := w.state()
	w.use(1)
	_same(w.state(), before, "using it changes nothing")


func case_director() -> void:
	await _build()
	var w := _washer()
	var parts := LevelRuntime.of(_zoo).parts
	var run := _station().run
	run.at = 0
	_lucky(w)
	var progress := Command.new(Washer.TALK, Parts.HOST, w.id, {"trigger": "washer_progress"})
	var ans := parts.answer(progress)
	_check(not ans["ok"] and ans["reason"] == "quiet", "not broken: a silent no")
	parts.ask(Command.new(WasherRun.BROKEN, Parts.HOST, run.id, {"on": true}))
	_check(w.is_broken(), "Break it breaks the machine")
	# A trigger no file has, and a cutscene's.
	_check(parts.answer(Command.new(Washer.TALK, Parts.HOST, w.id, {"trigger": "no_such"}))["reason"] == "wrong", "an unknown trigger is refused")
	_check(parts.answer(Command.new(Washer.TALK, Parts.HOST, w.id, {"trigger": "cutscene_fix_1"}))["reason"] == "wrong", "a cutscene trigger is not a comment")
	# A cutscene playing keeps it quiet.
	Voices.play_cutscene(Washer.trigger_of(&"cutscene_first_wash"))
	_check(Voices.cutscene_playing(), "a cutscene plays")
	ans = parts.answer(progress)
	_check(not ans["ok"] and ans["reason"] == "quiet", "during a cutscene: a silent no")
	Voices.stop_cutscene()
	# A comment, then the cooldown.
	ans = parts.answer(progress)
	_check(ans["ok"], "broken, no cutscene: it gives a line")
	parts.apply(ans)
	_check(w.serial == 1 and w.line != &"" and w.last_at > -INF, "the answer is on the Part and starts the cooldown")
	ans = parts.answer(progress)
	_check(not ans["ok"] and ans["reason"] == "quiet", "within 120 s of the last: a silent no")
	w.last_at = Time.get_ticks_msec() / 1000.0 - 119.0
	_check(not parts.answer(progress)["ok"], "119 s after: still quiet")
	w.last_at = Time.get_ticks_msec() / 1000.0 - 121.0
	_check(parts.answer(progress)["ok"], "121 s after: it speaks again")
	# The chance: the stare's is half; a seeded stream shows both.
	var spoke := 0
	var quiet := 0
	for i in 40:
		w.last_at = -INF
		w.picker.rng.seed = 100 + i
		if parts.answer(Command.new(Washer.TALK, Parts.HOST, w.id, {"trigger": "washer_stare"}))["ok"]:
			spoke += 1
		else:
			quiet += 1
	_check(spoke > 5 and quiet > 5, "the stare's chance is a half (%d spoke, %d quiet)" % [spoke, quiet])
	# Never the line before: lines in a row differ.
	w.picker.forget()
	var last: StringName = &""
	var same := 0
	for i in 12:
		w.last_at = -INF
		w.picker.rng.seed = 7 + i
		var got := parts.answer(Command.new(Washer.TALK, Parts.HOST, w.id, {"trigger": "washer_progress"}))
		if got["ok"]:
			var id: StringName = (got["changes"][w.id] as Dictionary)["line"]
			same += 1 if id == last else 0
			last = id
	_check(same == 0, "never the line before")


func case_comment_set() -> void:
	await _build()
	var w := _washer()
	var parts := LevelRuntime.of(_zoo).parts
	var run := _station().run
	parts.ask(Command.new(WasherRun.BROKEN, Parts.HOST, run.id, {"on": true}))
	_check(w.comment_set() == 0, "no Stage: any set")
	var plan := load("res://game/run/house_stage_plan.tres") as StagePlan
	for stage in plan.size() + 1:
		run.at = stage
		var want := plan.stage(stage).comment_set if stage < plan.size() else plan.laundry_day_comment_set
		_check(w.comment_set() == want, "Stage %d draws from set %d (got %d)" % [stage + 1, want, w.comment_set()])
		for i in 8:
			w.last_at = -INF
			w.picker.rng.seed = 31 * stage + i
			var got := parts.answer(Command.new(Washer.TALK, Parts.HOST, w.id, {"trigger": "washer_idle"}))
			if got["ok"]:
				var line := Voices.book().find_line(&"washer", (got["changes"][w.id] as Dictionary)["line"])
				_check(line.sets.is_empty() or line.sets.has(want), "set %d: %s belongs to it" % [want, line.id])
	_check(plan.laundry_day_comment_set == 4, "the Laundry day's set is Stage 4's by default (Q2635)")
	# The run's own Stage, as the house's Stages Part reads it.
	var stages := Stages.new()
	stages.plan = plan
	w.stages = stages
	stages.stage = 1
	_check(w.comment_set() == plan.stage(1).comment_set, "the run's Stage 2 gives its set")
	stages.phase = Stages.Phase.FIXED
	_check(w.comment_set() == plan.laundry_day_comment_set, "a fixed machine gives the Laundry day's")
	w.stages = run
	stages.free()


func case_senses() -> void:
	await _build()
	var w := _washer()
	var parts := LevelRuntime.of(_zoo).parts
	var senses := w.get_parent().get_node("Senses") as WasherSenses
	senses.tuning = senses.tuning.duplicate()
	senses.tuning.idle_seconds = 1.5
	w.tuning = senses.tuning
	# Not broken: even the idle clock says nothing.
	await _frames(5)
	_check(not Voices.talking(&"washer"), "not broken: quiet")
	var run := _station().run
	parts.ask(Command.new(WasherRun.BROKEN, Parts.HOST, run.id, {"on": true}))
	w.last_at = -INF
	await _until(func() -> bool: return w.serial > 0, "the idle comment after the quiet spell", 600, 6.0)
	_check(Voices.book().find_line(&"washer", w.line) != null, "the idle comment is a real line (%s)" % w.line)
	# A shelved Pair asks for progress at once (chance 1); the cooldown starts after it.
	Voices.reset()
	w.last_at = -INF
	var serial := w.serial
	parts.applied.emit({"ok": true, "kind": &"shelve", "to": &"x", "changes": {}})
	await _until(func() -> bool: return w.serial > serial, "a progress comment on a shelved Pair", 60)
	# A hit within 1.4 m on the floor plane, not beyond it.
	var at := (w.get_parent() as Node3D).global_position
	_check(senses.landed_near(PackedVector3Array([at + Vector3(1.3, 3.0, 0.0)])), "a landing 1.3 m away (any height) is a hit")
	_check(not senses.landed_near(PackedVector3Array([at + Vector3(1.5, 0.0, 0.0), at + Vector3(0.0, 0.0, -2.0)])), "1.5 m and 2 m away are not")
	# Off in a level that is not a staged run: no ask at all.
	var stages := Stages.new()
	w.stages = stages
	w.last_at = -INF
	serial = w.serial
	parts.applied.emit({"ok": true, "kind": &"shelve", "to": &"x", "changes": {}})
	await _frames(10)
	_check(w.serial == serial and not w.senses_on(), "not a staged run: the senses are off")
	w.stages = run
	stages.free()


func case_talk_only() -> void:
	var scene := load(FOLDER + "washer.tscn") as PackedScene
	var root := scene.instantiate() as Node3D
	add_child(root)
	var w := root.get_node("Washer") as Washer
	_check(w.accepts().size() == 1 and w.accepts().has(Washer.TALK), "a Guest may only ask talk of the washing machine")
	for verb: StringName in [&"say_line", WasherRun.MOOD, WasherRun.STAGE, WasherRun.BROKEN, WasherRun.CUTSCENE]:
		_check(w.decide(Command.new(verb, 1, w.id, {}))["ok"] == false, "%s is refused by the washing machine" % verb)
	root.free()
	await _build()
	var run := _station().run
	var offered := run.accepts()
	_check(offered.has(WasherRun.MOOD) and offered.has(WasherRun.STAGE) and offered.has(WasherRun.BROKEN) and offered.has(WasherRun.CUTSCENE),
			"the stand-in offers the station's switches to a Guest")
	_check(run.decide(Command.new(WasherRun.MOOD, 1, run.id, {"level": 3}))["ok"], "a mood level is granted")
	_check(not run.decide(Command.new(WasherRun.MOOD, 1, run.id, {"level": 99}))["ok"], "a level past the pillars is refused")


func case_pillars() -> void:
	await _build()
	var w := _washer()
	var station := _station()
	var tuning := w.tuning
	for n in tuning.zoo_levels + 1:
		_check(station.pillars.has("mood %d" % n), "a pillar for mood %d" % n)
	var plan := load("res://game/run/house_stage_plan.tres") as StagePlan
	for n in plan.size():
		_check(station.pillars.has("stage %d" % (n + 1)), "a pillar for Stage %d" % (n + 1))
	for key: String in ["laundry_day", "run", "break", "fix"]:
		_check(station.pillars.has(key), "a pillar: %s" % key)
	for trigger: String in ["washer_stare", "washer_progress", "washer_hit", "washer_idle"]:
		_check(station.pillars.has("trigger %s" % trigger), "a pillar fires %s" % trigger)
	_check(not station.pillars.has("trigger cutscene_fix_1"), "no pillar fires a cutscene here (core/88)")
	await _press_pillar(station.pillars["mood 3"])
	await _until(func() -> bool: return station.run.mood == 3, "the mood pillar to set the level", 60)
	_near(w.looks.damage, 3.0 / 5.0, 0.001, "mood 3 of 5: damage 0.6")
	_near(w.looks.repair, 0.4, 0.001, "and repair 0.4")
	await _press_pillar(station.pillars["mood 0"])
	await _until(func() -> bool: return station.run.mood == 0, "mood 0", 60)
	_near(w.looks.damage, 0.0, 0.001, "mood 0: no damage")
	_near(w.looks.repair, 1.0, 0.001, "and full repair")
	await _press_pillar(station.pillars["break"])
	await _until(func() -> bool: return w.is_broken(), "Break it", 60)
	await _press_pillar(station.pillars["fix"])
	await _until(func() -> bool: return not w.is_broken(), "Fix it", 60)
	await _press_pillar(station.pillars["laundry_day"])
	await _until(func() -> bool: return w.comment_set() == plan.laundry_day_comment_set and station.run.at == plan.size(), "the Laundry day", 60)
	await _press_pillar(station.pillars["run"])
	await _until(func() -> bool: return w.comment_set() == 0 and station.run.at == -1, "From the run", 60)


# --- Helpers -------------------------------------------------------------------------------------

func _stare_line() -> VoiceLine:
	for line in Voices.book().lines_of(&"washer"):
		if line.has_trigger(&"washer_stare") and not line.takes.is_empty() and line.takes[0].acting != null:
			return line
	return null


## Seeds the washer's dice so its next draw lets a trigger of chance a half speak.
func _lucky(w: Washer) -> void:
	for s in 400:
		w.picker.rng.seed = s
		var r := w.picker.rng.randf()
		w.picker.rng.seed = s
		if r < 0.45:
			return


func _washer() -> Washer:
	return _zoo.get_node(ROOT + "/Washer") as Washer


func _station() -> WasherStation:
	return _zoo.get_node(STATION_PATH) as WasherStation


func _player() -> Player:
	return LevelRuntime.of(_zoo if _zoo != null else _house).player


## The zoo with only the washer station, the player standing in front of it.
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
	await _look_at(target)


func _look_at(target: Vector3) -> void:
	var player := _player()
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## A machine: a Node with its own MultiplayerAPI, the washer station as its level, its Parts and its Session.
func _machine(label: String) -> Dictionary:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var level := Node3D.new()
	level.name = "Level"
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	level.add_child(station)
	node.add_child(level)
	var parts := Parts.new()
	parts.name = "Parts"
	parts.level = level
	node.add_child(parts)
	var session := Session.new()
	session.name = "Session"
	session.parts = parts
	session.port = 0
	node.add_child(session)
	var out := {"node": node, "level": level, "parts": parts, "session": session}
	_machines.append(out)
	return out


func _guest(label: String) -> Dictionary:
	var m := _machine(label)
	var s: Session = m["session"]
	var welcomed: Array[bool] = []
	s.welcomed.connect(func() -> void: welcomed.append(true))
	s.port = (_machines[0]["session"] as Session).port
	_check(s.join("127.0.0.1:%d" % s.port) == OK, "%s starts joining" % label)
	await _until(func() -> bool: return not welcomed.is_empty(), "%s to be welcomed" % label, 900, NET_WAIT_S)
	return m
