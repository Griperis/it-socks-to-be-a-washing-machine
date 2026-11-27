## The day (core/160, Q2693; docs/architecture/day-and-exterior.md "The day"): the house's 20-minute day starts at
## 9:00 on a New Game and runs on; the Sun follows the old path (the moon by night, hidden at sunrise and sunset), the
## sky turns to the dusk and night photos, the basement's fill follows the sky; a save keeps the hour; the zoo keeps
## its noon and the Day station's board is built from the keys in the folder.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const TITLE_SCENE := "res://game/ui/title/title.tscn"
const STATION := "res://game/zoo/stations/day.tscn"
const PLAYER := "res://game/player/player.tscn"
const KEYS := "res://game/day/keys"
const DAY := "Systems/Day/Day"
const DAY_LIGHT := "Systems/Day/DayLight"
const LAYING_S := 20.0
const ACTIONS: Array[StringName] = [&"interact", &"move_forward"]
## A short day for the real path: 24 hours in 30 s.
const SHORT_MINUTES := 0.5

var _level: Node3D = null
var _title: TitleScreen = null
var _lobby: LobbyScreen = null
var _extra: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path_night", "method": "case_real_path_night", "world": false,
				"title": "real path: the Solo New Game from the title starts the house at 9:00 and its own clock runs on (a short day); at 21:00 the camera's Sun is the moonlight from the south-east and its sky shows the night photo"},
		{"name": "sun_path", "method": "case_sun_path", "world": false,
				"title": "the Sun moves along the old path (up in the east at 6:00, low across the south, down in the south-west at 20:00), is hidden at sunrise and sunset and is the moon by night; the sky's phase is 1 at 20:00 and 2 at 23:00; the basement's fill follows the sky"},
		{"name": "lamps_by_clock", "method": "case_lamps_by_clock", "world": false,
				"title": "the lamps' night follows the clock (on from 19:30, off at 7:00) and lamps_switched fires when the hour passes them, not when the hour is written whole"},
		{"name": "save_keeps_hour", "method": "case_save_keeps_hour", "world": false,
				"title": "a save at 18:00 and its load show 18:00 (the shown hour is saved)"},
		{"name": "zoo_noon_and_board", "method": "case_zoo_noon_and_board", "world": false,
				"title": "real path: in the Day station the player presses a key's button and the station's hour is the key's; inside the room the camera shows the station's night, the zoo's picture keeps its noon"},
		{"name": "board_from_keys", "method": "case_board_from_keys", "world": false,
				"title": "the Day station's board has one button per key in the folder: a key dropped in shows with no other change"},
	]


func _before_case() -> void:
	SockGenerator.start_all = false
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	for node: Node in [_title, _lobby]:
		if node != null and is_instance_valid(node):
			node.free()
	_title = null
	_lobby = null
	for node in _extra:
		if is_instance_valid(node):
			node.free()
	_extra.clear()


# --- The real path -------------------------------------------------------------------------------

func case_real_path_night() -> void:
	var short := DayTuning.new()
	short.length_minutes = SHORT_MINUTES
	_open_title(func(root: Node) -> void:
		var d := root.get_node_or_null(DAY) as Day
		if d != null:
			d.tuning = short)
	await _click(_title.get_node("%Solo") as Control)
	await _until(func() -> bool: return _lobby != null, "the title's Solo to open the Lobby")
	await _frames(3)
	await _click(_lobby.get_node("%NewGame") as Control)
	await _click(_lobby.get_node("%AskYes") as Control)
	await _until(func() -> bool: return _level != null, "Start to load the house")
	var day := _level.get_node(DAY) as Day
	var light := _level.get_node(DAY_LIGHT) as DayLight
	var rt := LevelRuntime.of(_level)
	await _until(func() -> bool: return day.parts != null and day.parts.is_bound, "the house's Parts to bind")
	_check(is_equal_approx(day.hour, 9.0), "a New Game starts at 9:00 (%.2f)" % day.hour)
	await _until(rt.loading.is_lifted, "the house to be laid", 6000, LAYING_S)
	var cam := rt.player.get_viewport().get_camera_3d()
	_check(cam != null and rt.player.is_ancestor_of(cam), "the player's camera renders the house")
	# The game's own clock runs on to 21:00 (a whole short day at most).
	await _until(func() -> bool: return day.shown_hour() >= 21.0 and day.shown_hour() < 21.4, "the clock to reach 21:00 (%.2f)" % day.shown_hour(), 2400)
	await _until(func() -> bool: return light.hour >= 20.5 and light.hour < 21.5, "the sky to follow the hour", 60)
	var sun := light.picture.sun
	var env := cam.get_world_3d().environment if cam.environment == null else cam.environment
	_check(env == light.picture.environment(), "the camera renders the picture's Environment, the one the day writes")
	var to_moon := short.to_light(23.0)
	var from := -sun.global_basis.z
	_check(sun.visible and sun.light_energy > 0.01, "the light is on at 21:00 (energy %.3f)" % sun.light_energy)
	_check(from.dot(-to_moon) > 0.999, "it shines from the moon, up in the south-east (travels %s)" % from)
	_check(to_moon.x > 0.0 and to_moon.z > 0.0 and to_moon.y > 0.5, "the moon stands in the south-east, 40 degrees up (%s)" % to_moon)
	_check(sun.light_color.b > sun.light_color.r, "pale blue moonlight (%s)" % sun.light_color)
	var mat := env.sky.sky_material as ShaderMaterial
	var night := mat.get_shader_parameter(&"night_panorama") as Texture2D
	_check(float(mat.get_shader_parameter(&"phase")) > 1.0, "the sky blends into the night photo (phase %.2f)" % float(mat.get_shader_parameter(&"phase")))
	_check(night != null and night.resource_path == "res://assets/sky/street_lamp_2k.hdr", "the night photo is the street lamp (%s)" % night)


# --- Rules ---------------------------------------------------------------------------------------

func case_sun_path() -> void:
	await _house()
	var day := _level.get_node(DAY) as Day
	var light := _level.get_node(DAY_LIGHT) as DayLight
	var sun := light.picture.sun
	var probe := _level.get_node("Systems/Day/BasementLight") as ReflectionProbe
	var t := day.tuning
	await _at(day, 6.0)
	_check(not sun.visible, "at sunrise (6:00) the light is hidden (sun and moon swap)")
	await _at(day, 6.5)
	var morning := -sun.global_basis.z
	_check(sun.visible and morning.x < 0.0 and morning.y < 0.0, "in the morning the sun shines from the east (travels %s)" % morning)
	await _at(day, 13.0)
	var noon := -sun.global_basis.z
	var up := rad_to_deg(asin(-noon.y))
	_check(noon.z < 0.0 and up > 20.0 and up <= t.sun_max_elevation + 0.01, "after noon the sun is low in the south (%.1f degrees up, travels %s)" % [up, noon])
	await _at(day, 19.9)
	var evening := -sun.global_basis.z
	_check(evening.x > 0.0 and evening.z < 0.0, "in the evening it shines from the south-west (travels %s)" % evening)
	await _at(day, 20.0)
	_check(not sun.visible, "at sunset (20:00) the light is hidden")
	var mat := light.picture.sky_material()
	_near(float(mat.get_shader_parameter(&"phase")), 1.0, 0.01, "the sky's phase is 1 (dusk) at 20:00")
	await _at(day, 23.0)
	_near(float(mat.get_shader_parameter(&"phase")), 2.0, 0.01, "and 2 (night) at 23:00")
	var at_night := -sun.global_basis.z
	_check(sun.visible and at_night.dot(-t.to_light(23.0)) > 0.999, "by night the light is the moon's")
	var night_fill := probe.ambient_color_energy
	_near(night_fill, t.basement_ambient * light.sky_energy * light.ambient, 0.001, "the basement's fill is its share of the sky's ambient at night (%.4f)" % night_fill)
	await _at(day, 12.0)
	var noon_fill := probe.ambient_color_energy
	_near(noon_fill, t.basement_ambient * 0.9 * 0.75, 0.001, "and at noon (%.4f)" % noon_fill)
	_check(noon_fill > night_fill * 5.0, "the basement's fill follows the sky: bright by day, dark by night")
	_check(probe.ambient_color.is_equal_approx(t.basement_tint), "in its warm tint")
	# The hour runs on by itself.
	var before := day.shown_hour()
	await _frames(60)
	_near(day.shown_hour() - before, 60.0 / 60.0 * day.rate(), 0.0005, "the hour runs on at 24 hours in %.0f minutes" % t.length_minutes)


func case_lamps_by_clock() -> void:
	await _house()
	var day := _level.get_node(DAY) as Day
	var light := _level.get_node(DAY_LIGHT) as DayLight
	var lights := light.lights
	var switched: Array = []
	light.lamps_switched.connect(func(on: bool) -> void: switched.append(on))
	await _at(day, 19.4, true)
	_check(not lights.night, "before 19:30 the lamps keep the day's rule")
	_check(switched.is_empty(), "a written hour switches nothing aloud")
	var fast := day.tuning.duplicate() as DayTuning
	fast.length_minutes = 0.5
	day.tuning = fast
	await _until(func() -> bool: return lights.night, "the hour to pass 19:30", 120)
	_check(switched == [true], "the lamps switched on at 19:30 (%s)" % [switched])
	await _at(day, 6.9, true)
	await _until(func() -> bool: return not lights.night, "the hour to pass 7:00", 120)
	_check(switched == [true, false], "and off at 7:00 (%s)" % [switched])


func case_save_keeps_hour() -> void:
	await _house()
	var day := _level.get_node(DAY) as Day
	var parts := LevelRuntime.of(_level).parts
	parts.apply(day.grant({"hour": 18.0}))
	var saved := _roundtrip(parts.save_snapshot())
	var versions := parts.save_versions()
	_near(float((saved[DAY] as Dictionary)["hour"]), 18.0, 0.001, "the save keeps 18:00")
	_level.free()
	_level = null
	await _house()
	var again := _level.get_node(DAY) as Day
	var light := _level.get_node(DAY_LIGHT) as DayLight
	_check(absf(again.shown_hour() - 18.0) > 0.5, "a fresh house is not at 18:00 (%.2f)" % again.shown_hour())
	LevelRuntime.of(_level).parts.load_save(saved, versions, "host")
	_near(again.shown_hour(), 18.0, 0.01, "the load shows 18:00")
	_near(light.hour, 18.0, 0.01, "and the light is 18:00's")


func case_zoo_noon_and_board() -> void:
	var station := await _station_level()
	var day := station.get_node("Day") as Day
	var light := station.get_node("DayLight") as DayLight
	var player := _level.get_node("Player") as Player
	var zoo_picture := _level.get_node("ZooPicture") as Picture
	var key_button := station.get_node("Board/Key_2130") as Node3D
	player.global_position = station.to_global(Vector3(5.0, 0.0, 2.4))
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	await _aim(player, key_button.get_node("Body/Mesh") as Node3D)
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return absf(day.shown_hour() - 21.5) < 0.05, "the station's hour to be the key's 21:30 (%.2f)" % day.shown_hour())
	_near(float(light.picture.sky_material().get_shader_parameter(&"phase")), 2.0, 0.01, "the station's sky is the night")
	var zoo_phase: Variant = zoo_picture.sky_material().get_shader_parameter(&"phase")
	_check(zoo_phase == null or is_zero_approx(float(zoo_phase)), "the zoo's sky keeps its noon (phase %s: the shader's 0)" % [zoo_phase])
	# In the room the camera shows the station's day; outside the zoo's.
	var cam := player.get_viewport().get_camera_3d()
	_check(cam.environment == null and not (station.get_node("SunHolder") as Node3D).visible, "outside the room the camera shows the zoo's noon")
	player.global_position = station.to_global(Vector3(1.0, 0.1, -3.0))
	player.reset_physics_interpolation()
	await _until(func() -> bool: return cam.environment == light.picture.environment(), "the room's camera to show the station's Environment")
	_check((station.get_node("SunHolder") as Node3D).visible and not zoo_picture.sun.visible, "inside, the station's moon lights the room, not the zoo's sun")


func case_board_from_keys() -> void:
	var folder := "user://day_test_keys"
	DirAccess.make_dir_recursive_absolute(folder)
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(f))
	var keys := DayLight.load_keys(KEYS)
	_same(keys.size(), 9, "the nine old keys are in the folder")
	for k in keys:
		ResourceSaver.save(k, folder.path_join(k.resource_path.get_file()))
	var extra := DayKey.new()
	extra.hour = 14.25
	ResourceSaver.save(extra, folder.path_join("key_1415.tres"))
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	(station.get_node("DayLight") as DayLight).keys_folder = folder
	_extra.append(station)
	add_child(station)
	var board := station.get_node("Board")
	var buttons := board.get_children().filter(func(n: Node) -> bool: return String(n.name).begins_with("Key_"))
	_same(buttons.size(), 10, "one button per key, the dropped one too")
	_check(board.has_node("Key_1415") and (board.get_node("Key_1415/Label") as Label3D).text == "14:15", "the dropped key's button shows its hour")
	var swatch := (board.get_node("Key_2130/Body/Mesh") as MeshInstance3D).material_override as StandardMaterial3D
	_check(swatch.albedo_color.is_equal_approx(keys[8].light_colour), "a button's swatch is its key's light colour")
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(f))


# --- Helpers -------------------------------------------------------------------------------------

## The house level, its Parts bound (no Socks laid).
func _house() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var day := _level.get_node(DAY) as Day
	await _until(func() -> bool: return day.parts != null and day.parts.is_bound, "the house's Parts to bind")
	await _frames(2)


## The Day station in a level of its own with the player, its Parts, and a noon picture standing in for the zoo's.
func _station_level() -> Node3D:
	_level = Node3D.new()
	_level.name = "Level"
	var env := WorldEnvironment.new()
	env.name = "ZooEnvironment"
	env.environment = load("res://game/look/noon_environment.tres") as Environment
	_level.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "ZooSun"
	_level.add_child(sun)
	var picture := Picture.new()
	picture.name = "ZooPicture"
	picture.world_environment = env
	picture.sun = sun
	_level.add_child(picture)
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(station)
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 3.0)
	_level.add_child(player)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	player.capture_mouse()
	await _until(func() -> bool: return parts.is_bound and player.is_on_floor(), "the station to bind and the player to stand")
	return station


## The Host writes `hour` (as a station's key does) and the light shows it.
func _at(day: Day, hour: float, now := false) -> void:
	day.parts.apply(day.grant({"hour": hour}))
	if now:
		day.write({"hour": hour}, true)
	await _frames(1)


func _aim(player: Player, target: Node3D) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target.global_position - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target.global_position - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _open_title(on_level: Callable) -> void:
	_title = (load(TITLE_SCENE) as PackedScene).instantiate() as TitleScreen
	_title.go_into = func(path: String, _heading: String, setup: Callable) -> void:
		var root := (load(path) as PackedScene).instantiate()
		if setup.is_valid():
			setup.call(root)
		if _title != null:
			_title.queue_free()
		_title = null
		if _lobby != null:
			_lobby.queue_free()
		_lobby = null
		if root is LobbyScreen:
			_lobby = root as LobbyScreen
			add_child(root)
		else:
			on_level.call(root)
			_level = root as Node3D
			add_child(root)
	add_child(_title)


func _click(control: Control) -> void:
	await _frames(2)
	var at := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = pressed
		control.get_viewport().push_input(ev, true)
	await _frames(2)
