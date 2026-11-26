## The encyclopedia's record and the Collections' unlocking (core/134): the Stages station's mini run with the game's
## player (a Pair shelved by a left click puts its Design in the profile and its file; a snapshot, an unsettled level
## record nothing; a loaded World adds its shelved Designs once) and the house's Final wash (the last bin loaded by a
## click ends the run: the profile unlocks Space and the Final screen's strip shows it).
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const HOUSE := "res://game/house/house.tscn"
const FOLDER := "user://"
const GAP := 0.6
## The station's Socks, by id: Simple Pairs of Designs 0..5, then Sport.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _a: Cabinet = null
var _profile: PlayerProfile = null
var _was: ProfileTuning = null
var _holder: Node = null
var _house: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player shelves a Pair by a left click; the profile's designs hold that Pair's Design and the file has it within the save gap"},
		{"name": "not_recorded", "method": "case_not_recorded", "world": false,
				"title": "a join snapshot and an answer while the level is not settled record nothing; a loaded World adds its shelved Designs once"},
		{"name": "final_unlock", "method": "case_final_unlock", "world": false,
				"title": "the house's last bin loaded by a click ends the run: the profile unlocks Space once, the New Game's draw reads it, and the Final screen's strip pops it"},
		{"name": "unlock_rule", "method": "case_unlock_rule", "world": false,
				"title": "the order skips a held-back Collection; a profile with none stored still draws from the start set"},
	]


func _before_case() -> void:
	if _level != null:
		_level.free()
		_level = null
	if _holder != null:
		_holder.free()
		_holder = null
		_house = null
	for a: StringName in [&"pick", &"drop_throw"]:
		Input.action_release(a)
	_was = PlayerProfile.tuning
	var t := ProfileTuning.new()
	t.save_every = GAP
	PlayerProfile.tuning = t
	_clean()


func _after_case() -> void:
	PlayerProfile.tuning = _was
	_clean()


func _clean() -> void:
	var f := FOLDER + "profile_etest.json"
	if FileAccess.file_exists(f):
		DirAccess.remove_absolute(f)


func _designs_in_file(path: String) -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary and (data as Dictionary).get("designs") is Array:
		return (data as Dictionary)["designs"]
	return []


func case_real_path() -> void:
	_profile = PlayerProfile.load_or_make("etest", FOLDER)
	await _build()
	_check(_profile.designs.is_empty(), "the profile has seen no Design yet")
	_stand(BY_SOCKS)
	await _aim(_player, _centre(SIMPLE[3]))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == SIMPLE[3], "the Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(SIMPLE[3] + 1))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair")
	var design := _mess.designs[SIMPLE[3]]
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 0))
	await _press(&"pick")
	await _until(func() -> bool: return _a.shelved().size() == 1, "the Pair to be shelved")
	_check(_profile.designs == PackedInt32Array([design]), "the profile's encyclopedia holds the Pair's Design (%s, want %d)" % [_profile.designs, design])
	await _until(func() -> bool: return _designs_in_file(_profile.path) == [float(design)],
			"the file on disk to hold the Design within the save gap", 600)


func case_not_recorded() -> void:
	_profile = PlayerProfile.fresh()
	await _build()
	_parts.load_snapshot(_parts.snapshot())
	_check(_profile.designs.is_empty(), "a join snapshot records nothing")
	_parts.unsettle(self)
	_parts.apply({"ok": true, "shelved": PackedInt32Array([SIMPLE[0]]), "changes": {_a.id: {}}})
	_check(_profile.designs.is_empty(), "an answer while the level is not settled records nothing")
	_parts.settle(self)
	_parts.apply({"ok": true, "shelved": PackedInt32Array([SIMPLE[0], SIMPLE[1]]), "changes": {_a.id: {}}})
	var want := PackedInt32Array([_mess.designs[SIMPLE[0]]])
	if _mess.designs[SIMPLE[1]] != want[0]:
		want.append(_mess.designs[SIMPLE[1]])
	want.sort()
	_check(_profile.designs == want, "a settled level records each Design shelved, once (%s, want %s)" % [_profile.designs, want])
	# A World loaded: what the Cabinets hold was in that World.
	var shelf := [PackedInt32Array([SIMPLE[2]]), PackedInt32Array(), PackedInt32Array()]
	_parts.apply({"ok": true, "changes": {_a.id: {"shelf": shelf}}})
	var recorder := _station.get_node("Run/ProfileRecorder") as ProfileRecorder
	recorder._on_restored()
	recorder._on_restored()
	_check(_profile.designs.has(_mess.designs[SIMPLE[2]]), "a loaded World's shelved Design is in the encyclopedia")
	var seen := _profile.designs.size()
	recorder._on_restored()
	_check(_profile.designs.size() == seen, "loading again adds nothing twice")


func case_final_unlock() -> void:
	await _house_up()
	var rt := LevelRuntime.of(_house)
	var profile := Worlds.profile()
	_check(not profile.collections.has(&"space"), "Space is not unlocked yet")
	var day := _day()
	day.cutscene = false
	var bin := _one_bin_left()
	rt.parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 1}}})
	var washer := Washer.of_level(_house)
	var washer_thing := washer.get_parent() as Node3D
	await _stand_facing(rt.player, washer_thing.global_position + Vector3(1.9, 0.0, 0.0), washer_thing.global_position + Vector3.UP * 0.5)
	await _press(&"pick")
	await _until(func() -> bool: return day.ended and rt.final_screen.is_open(), "the run to end and the Final screen to open", 600, 30.0)
	_check(profile.collections.has(&"space"), "finishing the game unlocked Space (%s)" % [profile.collections])
	var screen := rt.final_screen
	_check(screen.unlocked_strip().visible and screen.unlock_cells().size() == 1, "the strip has one cell")
	var cell := screen.unlock_cells()[0]
	_check((cell.get_node("Body/Name") as Label).text == Collections.of(&"space").name, "the cell names the Collection")
	var body := cell.get_node("Body") as Control
	await _key(KEY_SPACE)
	await _until(func() -> bool: return screen.totals_shown(), "a key (or the clock) brings the totals")
	await _until(func() -> bool: return screen.unlocks_shown() == 1, "the Collection to pop", 600, 10.0)
	await _until(func() -> bool: return body.scale == Vector2.ONE, "the pop clip to end", 120, 5.0)
	_check(screen.unlocks_shown() == 1, "the Collection popped")
	var stages := _house.get_node("Run/Stages") as Stages
	_check(stages.unlocked_collections().has(&"space"), "the New Game's draw reads the profile's Collections")
	var recorder := _house.get_node("Run/ProfileRecorder") as ProfileRecorder
	recorder._unlock_next()
	_check(profile.collections.count(&"space") == 1 and profile.collections.has(&"fruit"), "the next game unlocks the next one, never Space twice")


func case_unlock_rule() -> void:
	var rule := load("res://game/collections/collection_unlocks.tres") as CollectionUnlocks
	var held := CollectionUnlocks.new()
	held.start = rule.start
	held.order = [&"lost", &"space"]
	_check(held.next_after(rule.start) == [&"space"], "a held-back Collection is never unlocked by the order")
	var stages := Stages.new()
	stages.unlocks = rule
	var open := stages.unlocked_collections()
	stages.free()
	_check(open == rule.start, "a profile with none stored draws from the start set (%s)" % [open])


# --- The Stages station ----------------------------------------------------------------------------

func _build() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_a = _station.get_node("CabinetA/Cabinet") as Cabinet
	(_station.get_node("Run/ProfileRecorder") as ProfileRecorder).profile = _profile
	var stages := _station.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")
	await _until(func() -> bool: return stages.due.is_empty(), "Stage 1's Socks to be laid")


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


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


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


# --- The house -------------------------------------------------------------------------------------

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


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	var up := InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	Input.parse_input_event(up)
	await _frames(1)

