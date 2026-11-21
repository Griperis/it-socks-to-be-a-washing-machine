## Every core sound and pad rumble at its moment (core/25, W01-W16): the events heard and the rumble
## last asked, read from the real actions in the Cabinet station (pick, pair, wheel, drop, refusal, throw,
## shelve, a drawer by use) and in the zoo (steps, the jump's landing). What the game asked of Sounds is
## read from its `played` signal and the voice it used.
extends TestSuite

const STATION := "res://game/zoo/stations/cabinet.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward", &"jump", &"hands_next"]
const S0 := 0
const S0_MATE := 1
const S1 := 2
const S4 := 4
const LOOSE := 12
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
const BY_DRAWERS := Vector3(-1.0, 0.0, -0.4)
## Sounds the walk and the fall make that a case about the Hands does not read.
const BACKGROUND: Array[StringName] = [&"land", &"step_wood", &"step_tile", &"amb_room"]
## Every event the wiring plays, by the ticket's lines.
const WIRED: Array[StringName] = [&"pick", &"pair", &"pop", &"cycle", &"drop", &"refuse", &"throw_charge", &"throw",
		&"bounce", &"shelve", &"drawer_open", &"drawer_close", &"door_open", &"door_close", &"cupboard_open",
		&"cupboard_close", &"land", &"step_wood", &"step_tile"]

var _level: Node3D = null
var _station: Node3D = null
var _zoo: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _cabinet: Cabinet = null
var _parts: Parts = null
var _heard: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Cabinet station the player picks, pairs, shelves, picks two, cycles, is refused, drops and throws, and the events heard and the rumble asked come in that order"},
		{"name": "w01_w02_pick_pair", "method": "case_w01", "world": false,
				"title": "W01, W02, W03, W09: a pick plays pick; a pick that makes a Pair plays pair (not pick), the ball's pop 0.455 s on, and rumbles 0.5 / 0.2 for 0.2 s"},
		{"name": "w04_cycle", "method": "case_w04", "world": false,
				"title": "W04: the wheel with two items plays cycle; with one item, nothing"},
		{"name": "w05_w06_drop_refuse", "method": "case_w05", "world": false,
				"title": "W05, W06: a drop plays drop; Hands full, and a drop refused, play refuse with the red line"},
		{"name": "w07_w08_throw", "method": "case_w07", "world": false,
				"title": "W07, W08: the charge starting plays throw_charge; the release plays throw and rumbles 0.3 / 0.7 for 0.25 s"},
		{"name": "rumble_setting", "method": "case_rumble", "world": false,
				"title": "pad rumble: on by default, and with the setting pad/rumble off nothing is asked"},
		{"name": "w10_bounce", "method": "case_w10", "world": false,
				"title": "W10, Q2371: a thrown Sock hitting a surface plays bounce in 3D at the contact, quieter and lower the softer"},
		{"name": "w10_gap", "method": "case_gap", "world": false,
				"title": "Q2372: an event plays at most once in its min_gap (bounce 0.05 s); after the gap it plays again"},
		{"name": "w11_shelve", "method": "case_w11", "world": false,
				"title": "W11: shelving plays shelve in 3D at the drawer it went into, with the drawer's own opening"},
		{"name": "w12_openables", "method": "case_w12", "world": false,
				"title": "W12: a drawer, the Door and the cupboard opened and shut by use play their open and close in 3D; a state arriving whole is silent"},
		{"name": "w13_land", "method": "case_w13", "world": false,
				"title": "W13, W14, real path: a jump lands with land every time and walking plays a step every 1.4 m; jump itself is silent"},
		{"name": "w16_names", "method": "case_w16", "world": false,
				"title": "W16: every event the wiring plays, and every open_sound and close_sound of a scene, is in the catalogue"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	if _zoo != null:
		_zoo.free()
		_zoo = null
	_heard.clear()
	PadRumble.reset()
	if not Sounds.played.is_connected(_on_played):
		Sounds.played.connect(_on_played)


func _on_played(event: StringName, spatial: bool, at: Vector3, bus: StringName) -> void:
	var voice := Sounds.last_voice
	_heard.append({"event": event, "spatial": spatial, "at": at, "bus": bus,
			"db": voice.get("volume_db") if voice != null else 0.0, "pitch": voice.get("pitch_scale") if voice != null else 1.0})


## The names heard in order, the walk's and the fall's left out.
func _seq() -> Array[StringName]:
	var out: Array[StringName] = []
	for h in _heard:
		if not BACKGROUND.has(h["event"]):
			out.append(h["event"])
	return out


func _count(event: StringName) -> int:
	var n := 0
	for h in _heard:
		if h["event"] == event:
			n += 1
	return n


func _last(event: StringName) -> Dictionary:
	for i in range(_heard.size() - 1, -1, -1):
		if _heard[i]["event"] == event:
			return _heard[i]
	return {}


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	await _until(func() -> bool: return _count(&"pop") == 1, "the ball to pop")
	_check(PadRumble.last == PadRumble.PAIR, "the pair rumbled")
	_stand(BY_DRAWERS)
	await _aim(_player, _drawer_front(0))
	await _press(&"pick")
	await _until(func() -> bool: return _cabinet.contents(0) == PackedInt32Array([S0]), "the Pair to be shelved")
	_stand(BY_SOCKS)
	await _repick(LOOSE)
	await _repick(S1)
	await _wheel(&"hands_next")
	await _physics_ticks(25)
	await _aim(_player, _centre(S4))
	await _press(&"pick")
	_check(_player.message() == Player.HANDS_FULL, "Hands full shows")
	await _wait(0.15)
	await _aim(_player, _station.to_global(Vector3(-1.0, 0.0, 0.2)))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _hands.items_of(1).size() == 1, "the drop")
	await _aim(_player, _drawer_front(1))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "the charge")
	await _physics_ticks(5)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _hands.items_of(1).is_empty(), "the throw")
	var seq := _seq().filter(func(n: StringName) -> bool: return n != &"bounce")
	var want: Array[StringName] = [&"pick", &"pair", &"pop", &"drawer_open", &"shelve", &"pick", &"pick", &"cycle", &"refuse",
			&"drop", &"throw_charge", &"throw"]
	_check(seq == want, "the events in order: %s" % [seq])
	_check(PadRumble.last == PadRumble.THROW, "the throw rumbled last")


func case_w01() -> void:
	await _build()
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	_check(_seq() == _names([&"pick"]), "a pick plays pick: %s" % [_seq()])
	_check(not _heard[0]["spatial"], "flat")
	_check(PadRumble.asked == 0, "and no rumble")
	await _repick(S0_MATE)
	_check(_mess.is_pair(S0), "the pair formed")
	_check(_seq() == _names([&"pick", &"pair"]), "the pairing plays pair, not pick: %s" % [_seq()])
	_check(PadRumble.last == PadRumble.PAIR and PadRumble.asked == 1, "the pair rumbled once")
	_near(PadRumble.PAIR.weak, 0.5, 0.0001, "weak 0.5")
	_near(PadRumble.PAIR.strong, 0.2, 0.0001, "strong 0.2")
	_near(PadRumble.PAIR.seconds, 0.2, 0.0001, "for 0.2 s")
	await _until(func() -> bool: return _count(&"pop") == 1, "the ball to pop")
	_check(not _last(&"pop")["spatial"], "the pop is flat")
	_near(float(_last(&"pop")["db"]), 3.0, 0.01, "at +3 dB")
	await _physics_ticks(60)
	_check(_count(&"pop") == 1, "once per pairing")


func case_w04() -> void:
	await _build()
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _wheel(&"hands_next")
	_check(_count(&"cycle") == 0, "with one item the wheel is silent")
	await _repick(S1)
	await _wheel(&"hands_next")
	_check(_count(&"cycle") == 1 and not _last(&"cycle")["spatial"], "with two the wheel plays cycle, flat")


func case_w05() -> void:
	await _build()
	_stand(BY_SOCKS)
	await _pick(S0)
	await _physics_ticks(25)
	await _aim(_player, _centre(S1))
	await _press(&"pick")
	_check(_count(&"refuse") == 1 and _player.message() == Player.HANDS_FULL, "Hands full plays refuse with the red line")
	await _wait(0.15)
	await _aim(_player, _station.to_global(Vector3(-1.0, 6.0, -9.0)))
	await _press(&"drop_throw")
	_check(_player.message() == Player.CANT_DROP and _count(&"refuse") == 2, "a drop with no spot plays refuse")
	_check(_count(&"drop") == 0, "and no drop")
	await _aim(_player, _station.to_global(Vector3(-1.0, 0.0, 0.2)))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _count(&"drop") == 1, "the drop")
	_check(not _last(&"drop")["spatial"], "drop is flat")


func case_w07() -> void:
	await _build()
	_stand(BY_SOCKS)
	await _pick(S0)
	await _aim(_player, _drawer_front(1))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "the charge to start")
	_check(_count(&"throw_charge") == 1 and _count(&"throw") == 0, "the charge plays throw_charge, not throw yet")
	await _physics_ticks(5)
	_check(_count(&"throw_charge") == 1, "once")
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _count(&"throw") == 1, "the throw")
	_check(PadRumble.last == PadRumble.THROW and PadRumble.asked == 1, "and the pad rumbles")
	_near(PadRumble.THROW.weak, 0.3, 0.0001, "weak 0.3")
	_near(PadRumble.THROW.strong, 0.7, 0.0001, "strong 0.7")
	_near(PadRumble.THROW.seconds, 0.25, 0.0001, "for 0.25 s")


func case_rumble() -> void:
	_check(Settings.get_bool(PadRumble.SETTING), "pad/rumble is on by default")
	PadRumble.play(PadRumble.THROW)
	_check(PadRumble.asked == 1, "so a cue is asked")
	Settings.set_value(PadRumble.SETTING, false)
	PadRumble.play(PadRumble.THROW)
	_check(PadRumble.asked == 1, "off, nothing is asked")


func case_w10() -> void:
	await _build()
	_stand(BY_SOCKS)
	await _pick(LOOSE)
	await _aim(_player, _station.to_global(Vector3(-1.0, 0.0, -3.0)))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _count(&"bounce") >= 1, "the bounce")
	var b := _last(&"bounce")
	var e := Sounds.catalogue.find(&"bounce")
	_check(b["spatial"], "bounce is a world sound")
	_check(float(b["db"]) <= e.volume_db + 0.01 and float(b["db"]) >= e.volume_db + e.soft_db - 0.01, "its level is between the softest and the hardest (%.1f dB)" % float(b["db"]))
	_check(float(b["pitch"]) >= e.soft_pitch - 0.001 and float(b["pitch"]) <= e.hard_pitch + 0.001, "and its pitch (%.2f)" % float(b["pitch"]))
	_check(_mess.bodies_tuning().bounce_speed == 1.5, "the hit counts from the old 1.5 m/s")
	# The map of a hit's speed to the level.
	Sounds.reset()
	_heard.clear()
	Sounds.play_at(&"bounce", Vector3.ZERO, 0.0)
	Sounds.reset()
	Sounds.play_at(&"bounce", Vector3.ZERO, 1.0)
	_check(_heard.size() == 2, "both played")
	_check(float(_heard[0]["db"]) < float(_heard[1]["db"]) - 1.0, "a soft hit is quieter (%.1f, %.1f dB)" % [float(_heard[0]["db"]), float(_heard[1]["db"])])
	_check(float(_heard[0]["pitch"]) < float(_heard[1]["pitch"]), "and lower (%.2f, %.2f)" % [float(_heard[0]["pitch"]), float(_heard[1]["pitch"])])


func case_gap() -> void:
	var e := Sounds.catalogue.find(&"bounce")
	_near(e.min_gap, 0.05, 0.0001, "bounce has a min gap of 0.05 s")
	Sounds.play_at(&"bounce", Vector3.ZERO)
	Sounds.play_at(&"bounce", Vector3.ZERO)
	_check(_count(&"bounce") == 1, "two in one instant are one")
	await _wait(0.12)
	Sounds.play_at(&"bounce", Vector3.ZERO)
	_check(_count(&"bounce") == 2, "after the gap it plays again")
	Sounds.play(&"pick")
	Sounds.play(&"pick")
	_check(_count(&"pick") == 2, "an event with no gap plays every time")


func case_w11() -> void:
	await _build()
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	await _until(func() -> bool: return _count(&"pop") == 1, "the pop")
	_heard.clear()
	_stand(BY_DRAWERS)
	await _aim(_player, _drawer_front(0))
	await _press(&"pick")
	await _until(func() -> bool: return _count(&"shelve") == 1, "the shelve sound")
	var drawer := _cabinet.drawer(0).get_parent() as Node3D
	_check(_last(&"shelve")["spatial"], "shelve is a world sound")
	_check((_last(&"shelve")["at"] as Vector3).is_equal_approx(drawer.global_position), "at the drawer it went into")
	_check(_count(&"drawer_open") == 1, "the drawer opened with its own sound")


func case_w12() -> void:
	await _build()
	var drawer := _cabinet.drawer(1)
	_stand(BY_DRAWERS)
	_heard.clear()
	await _aim(_player, _drawer_front(1))
	await _press(&"pick")
	await _until(func() -> bool: return drawer.open, "the drawer to open")
	_check(_count(&"drawer_open") == 1 and _last(&"drawer_open")["spatial"], "a drawer opened by use plays drawer_open in 3D")
	_check((_last(&"drawer_open")["at"] as Vector3).is_equal_approx((drawer.get_parent() as Node3D).global_position), "at the drawer")
	await _physics_ticks(10)
	await _aim(_player, _drawer_front(1))
	await _press(&"pick")
	await _until(func() -> bool: return not drawer.open, "the drawer to shut")
	_check(_count(&"drawer_close") == 1, "shut by use it plays drawer_close")
	# The Door, past its min gap.
	var door := _station.get_node("Door/Openable") as Openable
	_check(door.open_sound == &"door_open" and door.close_sound == &"door_close", "the Door has its sounds")
	_heard.clear()
	_parts.ask(Command.new(&"open", 1, door.id, {"open": true}))
	_check(_count(&"door_open") == 1, "the Door plays door_open")
	await _wait(0.15)
	_parts.ask(Command.new(&"open", 1, door.id, {"open": false}))
	_check(_count(&"door_close") == 1, "and door_close")
	# A state arriving whole is silent.
	_heard.clear()
	var snap := _parts.snapshot()
	snap[door.id] = {"open": true, "locked": false}
	_parts.load_snapshot(snap)
	_check(door.open and _heard.is_empty(), "a Door arriving open makes no sound (%s)" % [_seq()])
	# The cupboard.
	var cupboard := (load("res://game/entities/cupboard/cupboard.tscn") as PackedScene).instantiate() as Node3D
	_level.add_child(cupboard)
	var c := cupboard.get_node("Openable") as Openable
	_check(c.open_sound == &"cupboard_open" and c.close_sound == &"cupboard_close", "the cupboard has its sounds")
	_parts.bind(_level)
	_heard.clear()
	_parts.ask(Command.new(&"open", 1, c.id, {"open": true}))
	_check(_count(&"cupboard_open") == 1, "the cupboard plays cupboard_open")
	await _wait(0.15)
	_parts.ask(Command.new(&"open", 1, c.id, {"open": false}))
	_check(_count(&"cupboard_close") == 1, "and cupboard_close")


func case_w13() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := _zoo.get_node("Player") as Player
	await _until(func() -> bool: return player.is_on_floor(), "the zoo's player to stand")
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(-8.0, 0.0, 8.0)
	player.rotation = Vector3.ZERO
	player.reset_physics_interpolation()
	await _physics_ticks(6)
	_heard.clear()
	for i in 3:
		Input.action_press(&"jump")
		await _physics_ticks(2)
		Input.action_release(&"jump")
		await _until(func() -> bool: return _count(&"land") == i + 1, "jump %d to land" % (i + 1))
		await _physics_ticks(4)
	_check(_count(&"land") == 3 and _count(&"jump") == 0, "every jump lands, jump itself is silent")
	_check(not _last(&"land")["spatial"], "land is flat")
	player.global_position = Vector3(17.0, 0.0, 18.0)
	await _physics_ticks(6)
	_heard.clear()
	var start := player.global_position
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return start.z - player.global_position.z >= 3.0, "the player to walk 3 m")
	Input.action_release(&"move_forward")
	_check(_count(&"step_wood") >= 2, "walking plays steps (%d)" % _count(&"step_wood"))


func case_w16() -> void:
	for n in WIRED:
		_check(Sounds.has_event(n), "%s is in the catalogue" % n)
	var re := RegEx.create_from_string("(?:open_sound|close_sound) = &\"([a-z0-9_]+)\"")
	var found := 0
	for path in _files("res://game", ".tscn"):
		for m in re.search_all(FileAccess.get_file_as_string(path)):
			found += 1
			_check(Sounds.has_event(StringName(m.get_string(1))), "%s (set in %s) is in the catalogue" % [m.get_string(1), path])
	_check(found >= 6, "the scan finds the scenes' sounds (%d)" % found)


# --- Helpers -------------------------------------------------------------------------------------

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
	_player.position = _station.position + BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_cabinet = _station.get_node("Cabinet/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")
	_heard.clear()


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


## Waits `seconds` of the clock's time (a min gap is measured on it, which a headless run may outrun).
func _wait(seconds: float) -> void:
	var from := Time.get_ticks_msec()
	while Time.get_ticks_msec() - from < int(seconds * 1000.0):
		await get_tree().process_frame


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _wheel(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	await _physics_ticks(2)


func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d to be picked" % sock)


func _repick(sock: int) -> void:
	await _physics_ticks(25)
	await _pick(sock)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


func _drawer_front(index: int) -> Vector3:
	var front := _cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


static func _names(list: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for n: StringName in list:
		out.append(n)
	return out


## Every file under `folder` that ends with `ending`.
static func _files(folder: String, ending: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(folder):
		if f.ends_with(ending):
			out.append(folder.path_join(f))
	for d in DirAccess.get_directories_at(folder):
		out.append_array(_files(folder.path_join(d), ending))
	return out
