## The sound system (core/17): the catalogue of named events, plug-and-play clips, random clip and
## pitch, the buses and their volume settings, world sounds, muffling behind a shut Door, footsteps by
## floor, the landing, the zoo's ambience and its Sounds station. The real-path cases walk and press
## use in the zoo itself.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const STATION := Vector3(13.0, 0.0, 13.0)
## Where a case stands, in the Sounds station's space, before the Pick pillar and the Drawer open one.
const BY_PICK := Vector3(-4.9, 0.0, -1.3)
const BY_DRAWER_OPEN := Vector3(-3.5, 0.0, 2.2)
## The Door of the station, the pillar behind it, and the one in the open.
const DOOR := Vector3(5.0, 0.0, 3.0)
const BEHIND_DOOR := Vector3(5.0, 0.0, 2.0)
const IN_THE_OPEN := Vector3(3.6, 0.0, 2.0)
const TILE := Vector3(-3.5, 0.0, 2.5)
## The events the ticket names (S01).
const NAMED: Array[StringName] = [&"pick", &"drop", &"cycle", &"pair", &"pop", &"throw_charge", &"throw", &"refuse",
		&"bounce", &"drawer_open", &"drawer_close", &"door_open", &"door_close", &"cupboard_open", &"cupboard_close",
		&"shelve", &"step_wood", &"step_tile", &"land"]
const BUSES: Array[StringName] = [&"Master", &"SFX", &"Ambient", &"Music", &"UI"]
## The same buses in the order of the layout, with the mix of the old game (audio.json).
const MIX := {&"Master": 0.6, &"SFX": 1.0, &"Ambient": 0.5, &"Music": 0.8, &"UI": 0.8}
const ACTIONS: Array[StringName] = [&"move_forward", &"interact"]

var _zoo: Node3D = null
var _heard: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "s01_catalogue", "method": "case_s01", "world": false,
				"title": "S01: every named event is in the catalogue with clips and a real bus, and every name the game's code and scenes ask for is there too"},
		{"name": "s02_plug_and_play", "method": "case_s02", "world": false,
				"title": "S02: an event added to the catalogue in data plays with no code change"},
		{"name": "s03_variation", "method": "case_s03", "world": false,
				"title": "S03: a play goes through an AudioStreamRandomizer over the event's clips with the pitch jittered by 0.05"},
		{"name": "s04_buses", "method": "case_s04", "world": false,
				"title": "S04: the layout has Master, SFX, Ambient, Music, UI mixed 0.6, 1.0, 0.5, 0.8, 0.8 and a volume setting per bus moves the bus and mutes at zero"},
		{"name": "s05_world", "method": "case_s05", "world": false,
				"title": "S05: a world sound plays from where it happens (unit size 3 m, max 20 m), a flat one plays flat"},
		{"name": "s05_wrong_kind", "method": "case_s05_kind", "world": false,
				"title": "S05: asking a world event flat, a flat one from a spot, or an unknown name is an error and plays nothing"},
		{"name": "s06_muffle", "method": "case_s06", "world": false,
				"title": "S06, real path: in the zoo a sound behind a shut Door goes to the muffled bus (-9 dB, 900 Hz), in the open it does not, and once the player opens the Door by use it does not"},
		{"name": "s07_steps", "method": "case_s07", "world": false,
				"title": "S07, real path: walking the zoo floor plays a wood step every 1.4 m and the tile patch plays tile ones"},
		{"name": "s07_land", "method": "case_s07_land", "world": false,
				"title": "S07: a fall of 3 m/s or more plays the landing, a smaller one does not"},
		{"name": "s08_ambience", "method": "case_s08", "world": false,
				"title": "S08: the zoo plays a looping ambience on the Ambient bus"},
		{"name": "s10_station", "method": "case_s10", "world": false,
				"title": "S10, real path: the Sounds station has a pillar for every event, and the player's use plays the flat one flat and the world one from its spot"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _zoo != null:
		_zoo.free()
		_zoo = null
	_heard.clear()
	if not Sounds.played.is_connected(_on_played):
		Sounds.played.connect(_on_played)
	Sounds.catalogue = Sounds.CATALOGUE


func _on_played(event: StringName, spatial: bool, at: Vector3, bus: StringName) -> void:
	_heard.append({"event": event, "spatial": spatial, "at": at, "bus": bus})


func _count(event: StringName) -> int:
	var n := 0
	for h in _heard:
		if h["event"] == event:
			n += 1
	return n


func case_s01() -> void:
	var cat := Sounds.catalogue
	for n in NAMED:
		var e := cat.find(n)
		_check(e != null, "the catalogue has %s" % n)
		if e == null:
			continue
		_check(not e.clips.is_empty() and not e.clips.has(null), "%s has clips" % n)
		_check(AudioServer.get_bus_index(e.bus) >= 0, "%s plays on a bus that exists (%s)" % [n, e.bus])
	var seen := {}
	for e in cat.events:
		_check(not seen.has(e.event), "%s is in the catalogue once" % e.event)
		seen[e.event] = true
	_check(not cat.has(&"no_such_sound"), "a name it does not know is not found")
	# Every name the code and the scenes ask for is in it.
	var names := {}
	var re := RegEx.create_from_string("Sounds\\.(?:play|play_at|start_loop|stop_loop)\\(&\"([a-z0-9_]+)\"")
	var re_scene := RegEx.create_from_string("event = &\"([a-z0-9_]+)\"")
	for path in _files("res://game", [".gd", ".tscn"]):
		if path.begins_with("res://game/audio/sounds.gd"):
			continue
		var text := FileAccess.get_file_as_string(path)
		for m in re.search_all(text):
			names[m.get_string(1)] = path
		if path.ends_with(".tscn"):
			for m in re_scene.search_all(text):
				names[m.get_string(1)] = path
	_check(not names.is_empty(), "the scan finds the names in use")
	for n: String in names:
		_check(cat.has(StringName(n)), "%s (asked in %s) is in the catalogue" % [n, names[n]])
	for s: StringName in [&"wood", &"tile"]:
		_check(cat.has(StringName("step_" + s)), "the footstep of the %s surface is in the catalogue" % s)


func case_s02() -> void:
	var cat := Sounds.catalogue.duplicate() as SoundCatalogue
	var extra := SoundEvent.new()
	extra.event = &"plugged_in"
	var clips: Array[AudioStream] = [Sounds.catalogue.find(&"pick").clips[0]]
	extra.clips = clips
	extra.volume_db = -3.0
	var events: Array[SoundEvent] = cat.events.duplicate()
	events.append(extra)
	cat.events = events
	Sounds.catalogue = cat
	Sounds.play(&"plugged_in")
	_check(_count(&"plugged_in") == 1, "the new event played by its name")
	_near((Sounds.last_voice as AudioStreamPlayer).volume_db, -3.0, 0.001, "at its own level")
	_check((Sounds.last_voice as AudioStreamPlayer).playing, "and the voice is playing")


func case_s03() -> void:
	Sounds.play(&"pop")
	var voice := Sounds.last_voice as AudioStreamPlayer
	var r := voice.stream as AudioStreamRandomizer
	_check(r != null, "the voice plays an AudioStreamRandomizer")
	if r == null:
		return
	_check(r.streams_count == Sounds.catalogue.find(&"pop").clips.size() and r.streams_count == 2, "over the event's two clips")
	_near(r.random_pitch, 1.05, 0.0001, "its pitch strays by 0.05")
	_near(voice.volume_db, 3.0, 0.001, "the pop is 3 dB up (old level)")
	for i in r.streams_count:
		_check(r.get_stream(i) == Sounds.catalogue.find(&"pop").clips[i], "clip %d is the catalogue's" % i)


func case_s04() -> void:
	for b in BUSES:
		_check(AudioServer.get_bus_index(b) >= 0, "the bus %s exists" % b)
		_near(Sounds.mix_db(b), linear_to_db(MIX[b]), 0.01, "%s is mixed at %.1f" % [b, MIX[b]])
		if b != &"Master":
			_check(AudioServer.get_bus_send(AudioServer.get_bus_index(b)) == &"Master", "%s sends to Master" % b)
	for b: StringName in [&"SFX", &"Ambient", &"Music"]:
		var i := AudioServer.get_bus_index("Muffled" + b)
		_check(i >= 0 and AudioServer.get_bus_send(i) == b, "Muffled%s sends into %s" % [b, b])
		_near(AudioServer.get_bus_volume_db(i), -9.0, 0.001, "Muffled%s is 9 dB down" % b)
		var lp := AudioServer.get_bus_effect(i, 0) as AudioEffectLowPassFilter
		_check(lp != null and is_equal_approx(lp.cutoff_hz, 900.0), "Muffled%s is low-passed at 900 Hz" % b)
	var sfx := AudioServer.get_bus_index("SFX")
	_near(AudioServer.get_bus_volume_db(sfx), 0.0, 0.01, "at rest the effects bus sits at the mix")
	Settings.set_value("audio/sfx_volume", 0.5)
	_near(AudioServer.get_bus_volume_db(sfx), linear_to_db(0.5), 0.01, "half the effects slider halves the level")
	Settings.set_value("audio/sfx_volume", 0.0)
	_check(AudioServer.is_bus_mute(sfx), "zero mutes it")
	Settings.reset_key("audio/sfx_volume")
	_check(not AudioServer.is_bus_mute(sfx), "back at default it sounds again")
	var master := AudioServer.get_bus_index("Master")
	Settings.set_value("audio/master_volume", 0.5)
	_near(AudioServer.get_bus_volume_db(master), linear_to_db(0.6) + linear_to_db(0.5), 0.01, "the Master slider is multiplied onto its 0.6 mix")
	Settings.reset_key("audio/master_volume")
	_near(AudioServer.get_bus_volume_db(master), linear_to_db(0.6), 0.01, "and Master is at 0.6 again")


func case_s05() -> void:
	var where := Vector3(2.0, 1.0, -3.0)
	Sounds.play_at(&"drawer_open", where)
	var world := Sounds.last_voice as AudioStreamPlayer3D
	_check(world != null, "a world sound plays on a 3D voice")
	if world != null:
		_near(world.global_position.distance_to(where), 0.0, 0.001, "from where it happens")
		_near(world.unit_size, 3.0, 0.001, "unit size 3 m")
		_near(world.max_distance, 20.0, 0.001, "max distance 20 m")
	Sounds.play(&"pick")
	_check(Sounds.last_voice is AudioStreamPlayer and not (Sounds.last_voice is AudioStreamPlayer3D), "a flat sound plays on a flat voice")
	_check(_heard[0]["spatial"] == true and _heard[1]["spatial"] == false, "the played signal says which was which")
	# Eight voices are used in turn.
	var first := Sounds.last_voice
	for i in Sounds.VOICES:
		Sounds.play(&"pick")
	_check(Sounds.last_voice == first, "the ninth flat play uses the first voice again")


func case_s05_kind() -> void:
	_expect_error("a world sound")
	Sounds.play(&"drawer_open")
	_expect_error("a flat sound")
	Sounds.play_at(&"pick", Vector3.ZERO)
	_expect_error("no event named")
	Sounds.play(&"no_such_sound")
	_check(_heard.is_empty(), "none of the three played")


func case_s06() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	_stand(player, STATION + DOOR + Vector3(0.0, 0.0, 2.5))
	await _physics_ticks(3)
	await _frames(2)
	var behind := STATION + BEHIND_DOOR
	_check(Sounds.is_muffled(behind), "with the Door shut, a spot behind it is muffled")
	_check(not Sounds.is_muffled(STATION + IN_THE_OPEN) or _line_hits_door(player, STATION + IN_THE_OPEN), "a spot beside it is not muffled unless the Door is in the way")
	Sounds.play_at(&"bounce", behind)
	_check(_heard.back()["bus"] == &"MuffledSFX", "the sound behind the Door goes to MuffledSFX (%s)" % _heard.back()["bus"])
	_stand(player, STATION + IN_THE_OPEN + Vector3(0.0, 0.0, 2.5))
	await _physics_ticks(3)
	await _frames(2)
	Sounds.play_at(&"bounce", STATION + IN_THE_OPEN)
	_check(_heard.back()["bus"] == &"SFX", "the same sound in the open is on SFX")
	# The player opens the Door by use, as the game does; the way is then free.
	_stand(player, STATION + DOOR + Vector3(0.0, 0.0, 2.0))
	await _physics_ticks(3)
	await _frames(2)
	Input.action_press(&"interact")
	await _frames(3)
	Input.action_release(&"interact")
	var openable := _zoo.get_node("Stations/Sounds/Door/Openable") as Openable
	_check(openable.open, "use opens the Door")
	await _until(func() -> bool: return not openable.animator().is_playing(), "the Door to finish opening")
	await _physics_ticks(2)
	_stand(player, STATION + DOOR + Vector3(0.0, 0.0, 2.5))
	await _physics_ticks(3)
	await _frames(2)
	_check(not Sounds.is_muffled(behind), "with the Door open the spot behind it is clear")
	Sounds.play_at(&"bounce", behind)
	_check(_heard.back()["bus"] == &"SFX", "and plays on SFX")


## Whether the way from the player's eyes to `spot` meets the Door (a case's own check of the answer).
func _line_hits_door(player: Player, spot: Vector3) -> bool:
	var eyes := player.camera().global_position
	var door := STATION + DOOR
	var t := (door.z - eyes.z) / (spot.z - eyes.z)
	var x := lerpf(eyes.x, spot.x, t)
	return absf(x - door.x) < 0.45


func case_s07() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	_stand(player, Vector3(-8.0, 0.0, 8.0))
	await _physics_ticks(4)
	_heard.clear()
	var start := player.global_position
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return start.z - player.global_position.z >= 5.0, "the player to walk 5 m")
	Input.action_release(&"move_forward")
	var walked := start.z - player.global_position.z
	var want := walked / 1.4
	_check(absf(_count(&"step_wood") - want) <= 1.0 and _count(&"step_wood") >= 3, "a wood step every 1.4 m: %d steps in %.2f m (%.1f)" % [_count(&"step_wood"), walked, want])
	_check(_count(&"step_tile") == 0, "and no tile one on the wood")
	# The tile patch of the Sounds station: a drop onto it restarts the stride, then one stride across.
	_stand(player, STATION + TILE + Vector3(0.0, 0.3, 0.9))
	await _until(func() -> bool: return player.is_on_floor() and player.global_position.y < 0.05, "the player to land on the tile")
	await _physics_ticks(2)
	_heard.clear()
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return _count(&"step_tile") >= 1 or player.global_position.z < STATION.z + TILE.z - 1.0, "a step on the tile")
	Input.action_release(&"move_forward")
	_check(_count(&"step_tile") >= 1, "walking on the tile patch plays step_tile")
	_check(_count(&"step_wood") == 0, "and no wood step there")


func case_s07_land() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	_stand(player, Vector3(-8.0, 0.1, 8.0))
	await _physics_ticks(2)
	await _until(func() -> bool: return player.is_on_floor() and player.global_position.y < 0.05, "a short drop to land")
	await _physics_ticks(2)
	_check(_count(&"land") == 0, "a fall under 3 m/s makes no landing sound")
	_heard.clear()
	_stand(player, Vector3(-8.0, 0.8, 8.0))
	await _until(func() -> bool: return _count(&"land") > 0, "the landing after a longer fall")
	_check(_count(&"land") == 1, "one landing sound")
	_check(_heard[0]["spatial"] == false, "and it is the player's own, flat")


func case_s08() -> void:
	await _zoo_up()
	_check(Sounds.is_looping(&"amb_room"), "the zoo has the room ambience looping")
	var voice := Sounds.start_loop(&"amb_room")
	_check(voice != null and voice.playing and voice.bus == &"Ambient", "playing on the Ambient bus")
	_check(Sounds.start_loop(&"amb_room") == voice, "asking again does not start a second one")
	_zoo.free()
	_zoo = null
	_check(not Sounds.is_looping(&"amb_room"), "and it stops with the zoo")


func case_s10() -> void:
	await _zoo_up()
	var station := _zoo.get_node("Stations/Sounds") as Node3D
	var cat := Sounds.catalogue
	for e in cat.events:
		if e.loop:
			continue
		var spots := station.find_children("*", "SoundSpot", true, false)
		var found := false
		for s: SoundSpot in spots:
			if s.event == e.event:
				found = true
		_check(found, "the station has a pillar for %s" % e.event)
	var player := _zoo.get_node("Player") as Player
	_stand(player, STATION + BY_PICK)
	await _physics_ticks(3)
	await _frames(2)
	Input.action_press(&"interact")
	await _frames(3)
	Input.action_release(&"interact")
	_check(_count(&"pick") == 1, "use on the Pick pillar plays pick (%d)" % _count(&"pick"))
	_check(_heard[0]["spatial"] == false, "flat")
	_heard.clear()
	_stand(player, STATION + BY_DRAWER_OPEN)
	await _physics_ticks(3)
	await _frames(2)
	Input.action_press(&"interact")
	await _frames(3)
	Input.action_release(&"interact")
	_check(_count(&"drawer_open") == 1, "use on the Drawer open pillar plays drawer_open (%d)" % _count(&"drawer_open"))
	if _count(&"drawer_open") > 0:
		var h: Dictionary = _heard[0]
		_check(h["spatial"] == true, "from a spot")
		_check((h["at"] as Vector3).distance_to(STATION + Vector3(-3.5, 0.0, 1.0)) < 0.01, "where the pillar stands (%s)" % h["at"])


## The zoo, whole, with the player in it and the Parts bound.
func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := _zoo.get_node("Player") as Player
	await _until(func() -> bool: return player.is_on_floor(), "the zoo's player to stand")
	await _frames(2)
	_heard.clear()


## Puts the player at `spot` of the level, facing -Z, at rest.
func _stand(player: Player, spot: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = spot
	player.rotation = Vector3.ZERO
	player.reset_physics_interpolation()


## Every file under `folder` that ends with one of `endings`.
static func _files(folder: String, endings: Array[String]) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(folder):
		for e in endings:
			if f.ends_with(e):
				out.append(folder.path_join(f))
	for d in DirAccess.get_directories_at(folder):
		out.append_array(_files(folder.path_join(d), endings))
	return out
