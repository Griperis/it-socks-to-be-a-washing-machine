## The Wardrobe page and the station in the house (core/142, docs/architecture/wardrobe.md "The Wardrobe page",
## "The station in the house"): the player walks to the oak wardrobe in the parents' bedroom and presses E; the
## doors swing open and the page shows them in their colour; the Hats ">" puts an owned hat on the preview and
## their Roster entry; Esc shuts it and the doors close. A colour another player has is greyed with their name and
## refused; the floor in front of the station is kept free of Socks. The co-op side (the Teammate sees the hat and
## the doors) is tests/coop_wardrobe_test.gd's `station` case.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const STATION := "res://game/zoo/stations/wardrobe.tscn"
const PLAYER := "res://game/player/player.tscn"
const LAYING_S := 20.0
## Where the player stands in the bedroom, in front of the wardrobe (it faces +x), and what it aims at (a door).
const IN_FRONT := Vector3(1.75, 3.0, 4.1)
const DOOR_AIM := Vector3(0.75, 4.1, 3.7)
## In the zoo's Wardrobe station: before the wardrobe, and its doors.
const ZOO_FRONT := Vector3(4.1, 0.0, 1.3)
const ZOO_DOOR := Vector3(5.2, 1.1, 1.3)
const OPEN_DEG := 80.0

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the house the player walks to the wardrobe in the parents' bedroom (outlined, prompt \"Wardrobe\") and presses E: the doors swing open with wardrobe_open, the player is held and the mouse free, the page shows their creature in their colour; a click on the Hats \">\" puts the first owned hat on the preview and their Roster entry (\"1/N unlocked\" counts listed pieces only); Esc shuts it, the doors swing shut and the player moves again; no Sock of the New Game lies in the station's clear zone, which SockPlaces keeps out"},
		{"name": "colour_taken", "method": "case_colour_taken", "world": false,
				"title": "in the zoo's Wardrobe station (the wardrobe beside a wall mirror): a colour another player has is greyed with their name and a click on it asks nothing; a click on a free one taken meanwhile (the Host refuses \"taken\") springs back to the player's own colour; a free one is the player's; E shuts the page"},
	]


func _before_case() -> void:
	SockGenerator.start_all = true
	for a: StringName in [&"interact", &"move_forward"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	var player := rt.player
	await _until(rt.loading.is_lifted, "the house's Socks to be laid", 900, LAYING_S)
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand in the house")
	var station_root := _level.get_node("WardrobeStation") as Node3D
	var station := station_root.get_node("WardrobeStation") as WardrobeStation
	var roster := rt.roster
	# No Sock of the New Game in the clear zone, and SockPlaces keeps it out.
	_check_clear_zone(station_root, station, rt.mess)
	# The player walks up to the wardrobe and looks at a door.
	player.global_position = IN_FRONT + Vector3(1.0, 0.0, 0.0)
	player.reset_physics_interpolation()
	_face(player, player.global_position, IN_FRONT + Vector3.UP * 1.5)
	await _walk_to(player, IN_FRONT)
	_face(player, player.global_position, DOOR_AIM)
	await _physics_ticks(3)
	_check(player.aimed_part() == station, "the crosshair is on the wardrobe (%s)" % player.aimed_part())
	_check(player.aimed_outline != null and station_root.is_ancestor_of(player.aimed_outline), "its doors are outlined")
	_check("Wardrobe" in player.hud().prompt_text(), "the prompt reads Wardrobe (%s)" % player.hud().prompt_text())
	# E: the doors open, the page shows.
	var menu := station.menu
	var page := menu.page()
	Input.action_press(Player.INTERACT)
	await _physics_ticks(2)
	Input.action_release(Player.INTERACT)
	await _until(menu.is_open, "the Wardrobe menu to open")
	var me := roster.id_of(multiplayer.get_unique_id())
	_check(station.inside.has(me), "the station has the player inside")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "the mouse is free")
	var door := station_root.get_node("Looks/door_left") as Node3D
	await _until(func() -> bool: return absf(rad_to_deg(door.rotation.y)) > OPEN_DEG - 1.0, "the left door to swing 80 degrees open")
	_near(rad_to_deg((station_root.get_node("Looks/door_right") as Node3D).rotation.y), OPEN_DEG, 1.0, "the right door swings 80 degrees the other way")
	_check(page.creature().colour == roster.colour_of(multiplayer.get_unique_id()), "the preview is in the player's colour")
	var hats := page.row(WardrobePiece.Slot.HAT)
	_same(hats.shown_name(), "None", "the Hats row starts on None")
	var listed_hats := Wardrobe.counted(WardrobePiece.Slot.HAT)
	var basic_hats := _owned_hats().size()
	_same(hats.count_text(), "%d/%d unlocked" % [basic_hats, listed_hats], "the Hats count is the owned of the listed hats")
	# The world runs while the player is held: walking keys move nothing.
	var at := player.global_position
	Input.action_press(&"move_forward")
	await _physics_ticks(10)
	Input.action_release(&"move_forward")
	_check(player.global_position.distance_to(at) < 0.05, "the player is held while the page is open")
	# A click on the Hats ">".
	await _click(hats.next_key())
	var hat := _owned_hats()[0]
	await _until(func() -> bool: return page.creature().dresser().worn[&"hat"] == hat, "the preview to wear %s" % hat)
	_check(page.creature().dresser().hat != null, "its hat's Looks is on the preview")
	_same(String(roster.look_of(multiplayer.get_unique_id())["hat"]), String(hat), "the player's Roster entry wears it")
	_same(hats.shown_name(), Wardrobe.piece_name(hat), "the row names it")
	# Esc shuts it; the doors close.
	await _key(KEY_ESCAPE)
	await _until(func() -> bool: return not menu.is_open(), "Esc to shut the page")
	await _until(func() -> bool: return station.inside.is_empty(), "the player to leave the station")
	await _until(func() -> bool: return absf(door.rotation.y) < 0.02, "the doors to swing shut")
	at = player.global_position
	Input.action_press(&"move_back")
	await _physics_ticks(15)
	Input.action_release(&"move_back")
	_check(player.global_position.distance_to(at) > 0.05, "the player moves again")


## No Sock lies in the zone in front of the wardrobe, and the first floor's SockPlaces keeps that box out.
func _check_clear_zone(root: Node3D, station: WardrobeStation, mess: Mess) -> void:
	var inv := root.global_transform.affine_inverse()
	var half := station.clear_box * 0.5
	var inside := 0
	for sock in mess.count():
		var p := mess.where_of(sock)
		var local := inv * p
		if absf(local.y) < 1.5 and absf(local.x - station.clear_centre.x) < half.x and absf(local.z - station.clear_centre.z) < half.y:
			inside += 1
	_check(inside == 0, "no Sock lies in the wardrobe's clear zone (%d of %d do)" % [inside, mess.count()])
	var gen := _level.get_node("SockGenerators/First") as SockGenerator
	var area := gen.get_node("Floor") as SockArea
	var none: Array[Array] = []
	var places := SockPlaces.new(area, gen.tuning, gen.scan if gen.scan != null else _level, null, none, false)
	var want := root.global_transform * (station.clear_centre + Vector3(0.0, area.rules.headroom * 0.5, 0.0))
	var found := false
	for box: Array in places.keep_out:
		var size: Vector3 = box[0]
		var xf: Transform3D = box[1]
		if xf.origin.distance_to(want) < 0.01 and absf(size.x - station.clear_box.x) < 0.001 and absf(size.z - station.clear_box.y) < 0.001:
			found = true
	_check(found, "SockPlaces keeps the wardrobe's clear box out (%d boxes)" % places.keep_out.size())


# --- A colour taken ------------------------------------------------------------------------------

func case_colour_taken() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(station)
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	player.position = ZOO_FRONT
	_level.add_child(player)
	var roster := Roster.new()
	roster.name = "Roster"
	_level.add_child(roster)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	player.capture_mouse()
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	parts.apply(roster.joined(PlayerProfile.new_id(), Parts.HOST, "Me", {}, {"colour": 0}))
	# Another player (present, on another peer) has colour 2.
	parts.apply(roster.joined("bob", 7, "Bob", {}, {"colour": 2}))
	var mirror := station.get_node_or_null("WallMirror") as Node3D
	var wardrobe := station.get_node("WardrobeStation") as Node3D
	_check(mirror != null and mirror.global_position.distance_to(wardrobe.global_position) < 2.5, "the zoo's Wardrobe stands beside a wall mirror")
	_face(player, player.global_position, ZOO_DOOR)
	await _physics_ticks(3)
	var part := wardrobe.get_node("WardrobeStation") as WardrobeStation
	_check(player.aimed_part() == part, "the crosshair is on the zoo's wardrobe")
	Input.action_press(Player.INTERACT)
	await _physics_ticks(2)
	Input.action_release(Player.INTERACT)
	var menu := part.menu
	await _until(menu.is_open, "the Wardrobe menu to open")
	var page := menu.page()
	var swatches := page.swatches()
	_same(swatches.size(), roster.tuning.colours.size(), "a swatch per Player colour")
	_check(swatches[0].is_picked(), "the player's colour is ringed")
	_check(swatches[2].taken and swatches[2].holder() == "Bob" and swatches[2].key().disabled, "Bob's colour is greyed with his name")
	# A click on Bob's colour asks nothing.
	var asked := [0]
	var count_colour := func(ev: Dictionary) -> void:
		if ev.get("kind") == Roster.COLOUR:
			asked[0] += 1
	parts.applied.connect(count_colour)
	await _click(swatches[2].key())
	_check(asked[0] == 0 and roster.colour_index_of(Parts.HOST) == 0 and swatches[0].is_picked(), "a click on a taken colour is refused: nothing is asked")
	# Bob takes colour 4 while this page still shows it free (his answer not yet arrived here): a click on it is
	# refused by the Host ("taken") and the swatch springs back.
	(roster.players["bob"] as Dictionary)["colour"] = 4
	await _click(swatches[4].key())
	_check(asked[0] == 1, "the click on the free-looking colour asks the Host")
	_check(roster.colour_index_of(Parts.HOST) == 0, "the Host refused it")
	_check(swatches[0].is_picked() and not swatches[4].is_picked(), "the pick springs back to the player's own colour")
	_check(page.creature().colour == roster.tuning.colour(0), "the preview's colour springs back")
	# A free one is the player's.
	await _click(swatches[5].key())
	_check(roster.colour_index_of(Parts.HOST) == 5 and swatches[5].is_picked(), "a free colour is the player's")
	_check(page.creature().colour == roster.tuning.colour(5), "the preview takes it")
	parts.applied.disconnect(count_colour)
	# D on a focused arrow steps its row (a hat on), A steps it back (None).
	var hats := page.row(WardrobePiece.Slot.HAT)
	hats.prev_key().grab_focus()
	await _key(KEY_D)
	var hat := _owned_hats()[0]
	_check(String(roster.look_of(Parts.HOST)["hat"]) == String(hat) and hats.shown_name() == Wardrobe.piece_name(hat), "D on a focused arrow puts on %s" % hat)
	await _key(KEY_A)
	_check(String(roster.look_of(Parts.HOST)["hat"]) == "" and hats.shown_name() == "None", "A steps back to None")
	# E shuts the page.
	await _key(KEY_E)
	await _until(func() -> bool: return not menu.is_open(), "E to shut the page")
	await _until(func() -> bool: return part.inside.is_empty(), "the player to leave the station")


# --- Helpers -------------------------------------------------------------------------------------

## The hats a fresh profile owns, in the row's order (the basic ones).
func _owned_hats() -> Array[StringName]:
	var owned := Wardrobe.owned(PackedStringArray())
	var out: Array[StringName] = []
	for p in Wardrobe.row(WardrobePiece.Slot.HAT):
		if Wardrobe.shown(p) and owned.has(String(p.id)):
			out.append(p.id)
	return out


## Turns `player` standing at `feet` to look at `target`.
func _face(player: Player, feet: Vector3, target: Vector3) -> void:
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	var head := player.get_node("Head") as Node3D
	var up := target - (feet + Vector3.UP * head.position.y)
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)


## Walks `player` forward (its own input) until it is within a few centimetres of `to` (it faces it).
func _walk_to(player: Player, to: Vector3) -> void:
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return Vector2(player.global_position.x - to.x, player.global_position.z - to.z).length() < 0.1,
			"the player to walk up to the wardrobe", 600)
	Input.action_release(&"move_forward")
	await _physics_ticks(10)


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


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)
