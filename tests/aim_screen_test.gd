## Aiming and the screen (core/15): the crosshair's prompt, the aimed Sock's row, the key hints, the
## held readout, Sock Smarts and Sock Sense, and the crosshair's red. One case per line of the
## behaviour list (A01-A16) and the real path. Every case plays the station
## game/zoo/stations/screen.tscn on a floor with the game's player and a Parts (a Host of one), as
## the zoo does; the rows are read back from the player's Hud. The pixels are the review still's.
extends TestSuite

const STATION := "res://game/zoo/stations/screen.tscn"
const PLAYER := "res://game/player/player.tscn"
const CUPBOARD := "res://game/entities/cupboard/cupboard.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"zoom", &"turn"]
## The station's Socks, by id (the order of its SockSpots): an Aqua (L) and its mate, an Apricot (S).
const SOCK := 0
const MATE := 1
const OTHER := 2
## Where the player stands (station space).
const BY_SOCKS := Vector3(-0.7, 0.0, 2.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.1)
const BY_DOOR := Vector3(1.0, 0.0, -0.2)
const BY_SWITCHES := Vector3(1.0, 0.0, 0.0)
## The hints with empty Hands, one item and two (A04-A07).
const HINTS_EMPTY := "[SPACE] Jump  [CTRL] Crouch"
const HINTS_ONE := "[RMB] Drop / hold: Throw  [G] Zoom  [R] Turn  [SPACE] Jump  [CTRL] Crouch"
const HINTS_TWO := "[RMB] Drop / hold: Throw  [G] Zoom  [R] Turn  [WHEEL] Cycle  [SPACE] Jump  [CTRL] Crouch"

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _hud: Hud = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the station the player aims at a lying Sock, a drawer and the Door, presses E on the Door and picks the Sock with the mouse: the rows and the crosshair are read from the HUD"},
		{"name": "a01_aimed_sock", "method": "case_a01", "world": false,
				"title": "A01: a lying Sock or Pair in reach shows the pick key and its Size letter in its box at 63 % of the height"},
		{"name": "a02_row_empties", "method": "case_a02", "world": false,
				"title": "A02: when the crosshair leaves it the aimed row empties at once"},
		{"name": "a03_openables", "method": "case_a03", "world": false,
				"title": "A03: a Cabinet drawer shows its Cabinet's name and the Collection icon (\"Simple Cabinet Drawer\"), a cupboard its own name, the Door \"Open the Door\" and \"Shut the Door\" once open, each with the use key (Q2388)"},
		{"name": "a04_drop_throw", "method": "case_a04", "world": false,
				"title": "A04: with something in the Hands the corner shows \"Drop / hold: Throw\" [RMB]"},
		{"name": "a05_zoom_turn", "method": "case_a05", "world": false,
				"title": "A05: a held Sock or Pair adds \"Zoom\" [G] and \"Turn\" [R]"},
		{"name": "a06_cycle", "method": "case_a06", "world": false,
				"title": "A06: with 2 or more items the corner shows \"Cycle\" [Wheel]"},
		{"name": "a07_jump_crouch", "method": "case_a07", "world": false,
				"title": "A07: the corner always shows \"Jump\" [Space] and \"Crouch\" [Ctrl], at its old place and size"},
		{"name": "a08_no_rebuild", "method": "case_a08", "world": false,
				"title": "A08: a row whose content is the same as last frame is not rebuilt"},
		{"name": "a09_crosshair_red", "method": "case_a09", "world": false,
				"title": "A09: the crosshair turns red where a drop would be refused and white again where it would not"},
		{"name": "a10_old_red", "method": "case_a10", "world": false,
				"title": "A10: the crosshair's red is (0.95, 0.25, 0.2) at alpha 0.9, its white alpha 0.9"},
		{"name": "a11_moving_sock", "method": "case_a11", "world": false,
				"title": "A11: a Sock flying under the crosshair shows its Size row like a lying one"},
		{"name": "a12_crosshair_same", "method": "case_a12", "world": false,
				"title": "A12: aiming a Sock does not change the crosshair: no colour, no growing, no extra mark"},
		{"name": "a13_plain_text", "method": "case_a13", "world": false,
				"title": "A13: every text on the screen reads back as plain text"},
		{"name": "a14_sock_smarts", "method": "case_a14", "world": false,
				"title": "A14: with Sock Smarts the held readout shows Collection icon, Design name, Sock or Pair icon and n/capacity, the wheel with 2+; without, only the boxed Size"},
		{"name": "a15_sock_sense", "method": "case_a15", "world": false,
				"title": "A15: with Sock Sense (and Smarts) the aimed loose Sock shows the readout it would have once picked, a Pair when it would fuse"},
		{"name": "a16_zoo_switches", "method": "case_a16", "world": false,
				"title": "A16: both flags are on in the zoo, and a station switch toggles each by the use key"},
		{"name": "pad_keys", "method": "case_pad_keys", "world": false,
				"title": "the keycaps follow the last input: a pad press shows the pad's glyphs, a key press the keyboard's"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var letter := _mess.design_of(SOCK).size_letter()
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _hud.aimed_text() == "[LMB] [%s]" % letter, "the aimed Sock's row (%s)" % _hud.aimed_text())
	_check(_hud.prompt_text() == "", "no crosshair prompt on a Sock")
	_check(_hud.crosshair_tint() == Hud.CROSSHAIR_OK, "the crosshair is white")
	_stand(BY_CABINET)
	await _aim(_drawer_front(1))
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Simple Cabinet Drawer", "the drawer's prompt (%s)" % _hud.prompt_text())
	_check(_hud.aimed_text() == "", "the Sock's row went")
	_stand(BY_DOOR)
	await _aim(_door_point())
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Open the Door", "the Door's prompt (%s)" % _hud.prompt_text())
	await _press(&"interact")
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Shut the Door", "the opened Door's prompt (%s)" % _hud.prompt_text())
	_check(_hud.hints_text() == HINTS_EMPTY, "empty Hands: Jump and Crouch (%s)" % _hud.hints_text())
	_stand(BY_SOCKS)
	await _aim(_centre(SOCK))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(SOCK), "the click to pick the Sock")
	await _until(func() -> bool: return _hud.hints_text() == HINTS_ONE, "the held hints (%s)" % _hud.hints_text())
	_check(_hud.hands_text() == "[%s]" % letter, "the held Size in its box (%s)" % _hud.hands_text())
	await _aim(_player.global_position + Vector3(0.0, 20.0, -1.0))
	await _until(func() -> bool: return _hud.crosshair_tint() == Hud.CROSSHAIR_NO, "the crosshair to turn red at the sky")


# --- The behaviour lines -------------------------------------------------------------------------

func case_a01() -> void:
	await _build()
	var letter := _mess.design_of(SOCK).size_letter()
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _hud.aimed_text() == "[LMB] [%s]" % letter, "the Sock's row (%s)" % _hud.aimed_text())
	var row := _hud.row("aimed")
	_check(row.get_child_count() == 2, "two pieces: the key and the box (%d)" % row.get_child_count())
	_check(row.get_child(0).name == "Icon_key_lmb" and (row.get_child(0) as TextureRect).texture != null, "the LMB keycap picture first")
	var box := row.get_child(1) as PanelContainer
	_check(box != null and box.theme_type_variation == Hud.SIZE_BOX, "then the Size box")
	_check(box != null and (box.get_child(0) as Label).text == letter, "with the letter %s" % letter)
	var style := box.get_theme_stylebox(&"panel") as StyleBoxFlat
	_check(style != null and style.bg_color.is_equal_approx(Color(0.16, 0.12, 0.1, 0.75)), "a dark panel")
	_check(style != null and style.border_color.is_equal_approx(Color(1.0, 0.94, 0.82)) and style.border_width_left == 2,
			"a 2 px cream border")
	_check(style != null and style.corner_radius_top_left == 6 and is_equal_approx(style.content_margin_left, 7.0), "corner 6, margin 7")
	_check(is_equal_approx((row.get_child(0) as TextureRect).custom_minimum_size.x, 42.0), "the key is 1.5 times 28 pt")
	var holder := _hud.get_node("AimedRow") as Control
	_check(is_equal_approx(holder.anchor_top, 0.63), "at 63 % of the height")
	# A lying Pair shows the same.
	await _take(SOCK)
	await _take(MATE)
	var pair := _hands.active_of(1)
	_check(_mess.is_pair(pair), "the two make a Pair")
	_hands.drop(1, _station.to_global(Vector3(-0.7, 0.0, 1.2)), Vector3.UP)
	await _until(func() -> bool: return _mess.state_of(pair) == Mess.State.LYING, "the Pair to lie")
	await _aim(_centre(pair))
	await _until(func() -> bool: return _hud.aimed_text() == "[LMB] [%s]" % letter, "the lying Pair's row (%s)" % _hud.aimed_text())


func case_a02() -> void:
	await _build()
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _hud.aimed_text() != "", "the Sock's row")
	await _aim(_player.global_position + Vector3(0.0, 20.0, -1.0))
	_check(_hud.aimed_text() == "" and _hud.row("aimed").get_child_count() == 0, "two ticks later the row is empty")


func case_a03() -> void:
	await _build()
	_stand(BY_CABINET)
	await _aim(_drawer_front(1))
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Simple Cabinet Drawer", "the drawer's prompt (%s)" % _hud.prompt_text())
	var line := _hud.row("prompt").get_child(0) as HBoxContainer
	_check(line != null and line.get_child(0).name == "Icon_key_e", "the E keycap picture")
	_check(line != null and is_equal_approx((line.get_child(0) as TextureRect).custom_minimum_size.x, 48.0), "48 px: 1.5 times 32 pt")
	_check(line != null and line.get_child(1).name == "Icon_simple", "then the Collection's icon")
	_check(line != null and is_equal_approx((line.get_child(1) as TextureRect).custom_minimum_size.x, 32.0 * 1.3), "1.3 times 32 pt")
	_check(line != null and (line.get_child(2) as Label).get_theme_font_size(&"font_size") == 32, "the words at 32 pt")
	var holder := _hud.get_node("PromptRow") as Control
	_check(is_equal_approx(holder.anchor_top, 0.58), "the prompt row at 58 % of the height")
	var drawer := _station.get_node("Cabinet/Drawer2/Openable") as Openable
	drawer.use(1)
	await _until(func() -> bool: return drawer.open, "the drawer to open")
	await _physics_ticks(2)
	_check(_hud.prompt_text() == "[E] Simple Cabinet Drawer", "an open drawer keeps its name (%s)" % _hud.prompt_text())
	var cabinet := _station.get_node("Cabinet/Cabinet") as Cabinet
	cabinet.collection = &"lost"
	_check(Prompt.joined(Prompts.target(drawer), " ") == "[E] Lost Socks Cabinet Drawer", "another Collection's Cabinet by the old names")
	cabinet.collection = &"simple"
	_stand(BY_DOOR)
	await _aim(_door_point())
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Open the Door", "the Door's prompt (%s)" % _hud.prompt_text())
	(_station.get_node("Door/Openable") as Openable).use(1)
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Shut the Door", "the open Door's prompt (%s)" % _hud.prompt_text())
	var cupboard := (load(CUPBOARD) as PackedScene).instantiate()
	var openable := cupboard.get_node("Openable") as Openable
	_check(Prompt.joined(Prompts.target(openable), " ") == "[E] Cupboard", "a cupboard reads its own name (%s)" % Prompt.joined(Prompts.target(openable), " "))
	openable.open = true
	_check(Prompt.joined(Prompts.target(openable), " ") == "[E] Cupboard", "the same open")
	openable.title = "Cupboard A Drawer"
	_check(Prompt.joined(Prompts.target(openable), " ") == "[E] Cupboard A Drawer", "a title names it (the old layout name)")
	cupboard.free()


func case_a04() -> void:
	await _build()
	await _until(func() -> bool: return _hud.hints_text() == HINTS_EMPTY, "the empty Hands' hints")
	_check(not _hud.hints_text().contains("Throw"), "no Throw hint with empty Hands")
	await _take(OTHER)
	await _until(func() -> bool: return _hud.hints_text().begins_with("[RMB] Drop / hold: Throw"), "the Throw hint first (%s)" % _hud.hints_text())


func case_a05() -> void:
	await _build()
	await _take(OTHER)
	await _until(func() -> bool: return _hud.hints_text() == HINTS_ONE, "the held Sock's hints (%s)" % _hud.hints_text())
	await _take(SOCK)
	await _take(MATE)
	_check(_mess.is_pair(_hands.active_of(1)), "a Pair is active")
	await _until(func() -> bool: return _hud.hints_text().contains("[G] Zoom  [R] Turn"), "a held Pair zooms and turns too")


func case_a06() -> void:
	await _build()
	await _take(OTHER)
	await _take(SOCK)
	await _until(func() -> bool: return _hud.hints_text() == HINTS_TWO, "the Cycle hint with two (%s)" % _hud.hints_text())


func case_a07() -> void:
	await _build()
	await _until(func() -> bool: return _hud.hints_text() == HINTS_EMPTY, "Jump and Crouch with empty Hands (%s)" % _hud.hints_text())
	await _take(OTHER)
	await _until(func() -> bool: return _hud.hints_text().ends_with("[SPACE] Jump  [CTRL] Crouch"), "and with a Sock held")
	var hints := _hud.row("hints")
	_check(is_equal_approx(hints.anchor_left, 1.0) and is_equal_approx(hints.anchor_top, 1.0), "bottom right")
	_check(is_equal_approx(hints.offset_right, -24.0) and is_equal_approx(hints.offset_bottom, -24.0), "24 px from the edges")
	_check(hints.get_theme_constant(&"separation") == 22, "22 px apart")
	var line := hints.get_child(0) as HBoxContainer
	_check((line.get_child(line.get_child_count() - 1) as Label).get_theme_font_size(&"font_size") == 24, "24 pt")
	await _frames(1)
	var screen := _hud.get_viewport().get_visible_rect().size
	var rect := hints.get_global_rect()
	_check(absf(rect.end.x - (screen.x - 24.0)) < 1.0 and absf(rect.end.y - (screen.y - 24.0)) < 1.0,
			"its corner 24 px in from the screen's (%s in %s)" % [rect, screen])


func case_a08() -> void:
	await _build()
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _hud.aimed_text() != "", "the Sock's row")
	var before := _hud.rebuilds.duplicate()
	var first := _hud.row("aimed").get_child(0)
	await _physics_ticks(10)
	_same(_hud.rebuilds, before, "ten frames of the same content rebuild no row")
	_check(_hud.row("aimed").get_child(0) == first, "the same nodes are kept")
	await _take(OTHER)
	await _physics_ticks(2)
	_check(_hud.rebuilds["hints"] == before["hints"] + 1, "a change rebuilds its row once (%d)" % (_hud.rebuilds["hints"] - before["hints"]))


func case_a09() -> void:
	await _build()
	await _aim(_player.global_position + Vector3(0.0, 20.0, -1.0))
	_check(_hud.crosshair_tint() == Hud.CROSSHAIR_OK, "with empty Hands it is white anywhere")
	await _take(OTHER)
	await _aim(_player.global_position + Vector3(0.0, 20.0, -1.0))
	await _until(func() -> bool: return _hud.blocked(), "red at the sky with a Sock held")
	_check(_player.crosshair_colour() == Player.CROSSHAIR_NO, "the player reads it red")
	await _aim(_player.global_position + Vector3(0.0, 0.0, -1.2))
	await _until(func() -> bool: return not _hud.blocked(), "white again on the floor")
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK, "the player reads it white")


func case_a10() -> void:
	await _build()
	_check(_hud.crosshair_colour().is_equal_approx(Color(1.0, 1.0, 1.0, 0.9)), "white at alpha 0.9 (%s)" % _hud.crosshair_colour())
	_hud.show_blocked(true)
	_check(_hud.crosshair_colour().is_equal_approx(Color(0.95, 0.25, 0.2, 0.9)), "red (0.95, 0.25, 0.2) at alpha 0.9 (%s)" % _hud.crosshair_colour())
	_hud.show_blocked(false)


func case_a11() -> void:
	await _build()
	var letter := _mess.design_of(OTHER).size_letter()
	await _take(OTHER)
	await _aim(_player.global_position + Vector3(0.0, 6.0, -1.0))
	_hands.throw(1, _player.aim_dir(), 0.3)
	await _until(func() -> bool: return _mess.flight_of(OTHER) != null, "the thrown Sock to fly")
	var seen := false
	for i in 120:
		var body := _mess.flight_of(OTHER)
		if body == null:
			break
		await _aim(body.global_position)
		if _player.aimed_sock == OTHER and _mess.is_moving(OTHER) and _hud.aimed_text() == "[LMB] [%s]" % letter:
			seen = true
			break
	_check(seen, "the flying Sock under the crosshair shows its row")


func case_a12() -> void:
	await _build()
	var crosshair := _hud.get_node("Crosshair") as Crosshair
	var bars := crosshair.bars()
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _player.aimed_sock == SOCK, "the Sock to be aimed")
	_check(crosshair.modulate == Hud.CROSSHAIR_OK, "the same white")
	_check(crosshair.scale == Vector2.ONE, "the same size")
	_check(crosshair.get_child_count() == 2, "the same two bars, no extra mark")
	_same(crosshair.bars(), bars, "the bars where they were")


func case_a13() -> void:
	await _build()
	_player.upgrades.sock_smarts = true
	_player.upgrades.sock_sense = true
	await _take(SOCK)
	await _aim(_centre(MATE))
	await _until(func() -> bool: return _hud.sense_text() != "", "the Sense readout")
	var rows := {"aimed": _hud.aimed_text(), "sense": _hud.sense_text(), "held": _hud.hands_text(), "hints": _hud.hints_text()}
	for which: String in rows:
		var text: String = rows[which]
		_check(text != "", "the %s row reads back (%s)" % [which, text])
		for label in _hud.row(which).find_children("*", "Label", true, false):
			_check(text.contains((label as Label).text), "%s's \"%s\" is in its text (%s)" % [which, (label as Label).text, text])
	_stand(BY_DOOR)
	await _aim(_door_point())
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Open the Door", "the prompt reads back")
	_player.say("Hands full")
	_check(_player.message() == "Hands full", "the message reads back")


func case_a14() -> void:
	await _build()
	var d := _mess.design_of(OTHER)
	await _take(OTHER)
	await _until(func() -> bool: return _hud.hands_text() == "[%s]" % d.size_letter(), "without Sock Smarts only the boxed Size (%s)" % _hud.hands_text())
	_check(_hud.row("held").get_child_count() == 1, "one piece: the box")
	_player.upgrades.sock_smarts = true
	var want := "[%s] Sock 1/3 %s (%s)" % [d.size_letter(), d.name, d.collection]
	await _until(func() -> bool: return _hud.hands_text() == want, "the Smarts readout (%s)" % _hud.hands_text())
	var names: Array[String] = []
	for c in _hud.row("held").get_children():
		names.append(c.name if not c is Label else "Label:" + (c as Label).text)
	_same(names, ["SizeBox", "Icon_" + String(d.collection), "Label:" + d.name, "Icon_sock", "Label:1/3"], "box, Collection, name, Sock, count")
	await _take(SOCK)
	await _until(func() -> bool: return _hud.hands_text().ends_with("2/3 %s (%s) [WHEEL]" % [_mess.design_of(SOCK).name, _mess.design_of(SOCK).collection]),
			"two held: 2/3 and the wheel (%s)" % _hud.hands_text())
	await _take(MATE)
	await _until(func() -> bool: return _hud.hands_text().contains("Pair 2/3"), "a Pair reads Pair (%s)" % _hud.hands_text())
	_check(_hud.row("held").has_node("Icon_ball"), "with the ball icon")
	# The readout sits right of the active item, on the screen.
	await _frames(2)
	var rect := _hud.row("held").get_global_rect()
	var screen := _hud.get_viewport().get_visible_rect().size
	_check(rect.position.x > screen.x * 0.5 and rect.end.x <= screen.x, "right of centre, on the screen (%s in %s)" % [rect, screen])


func case_a15() -> void:
	await _build()
	_player.upgrades.sock_sense = true
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _player.aimed_sock == SOCK, "the Sock to be aimed")
	_check(_hud.sense_text() == "", "Sense without Smarts shows nothing")
	_player.upgrades.sock_smarts = true
	var d := _mess.design_of(SOCK)
	await _until(func() -> bool: return _hud.sense_text() == "[%s] Sock 1/3 %s (%s)" % [d.size_letter(), d.name, d.collection],
			"the aimed Sock as it would be held (%s)" % _hud.sense_text())
	_check(not _hud.row("sense").has_node("SizeBox"), "without a second Size box")
	await _take(SOCK)
	await _aim(_centre(MATE))
	await _until(func() -> bool: return _hud.sense_text() == "[%s] Pair 1/3 %s (%s)" % [d.size_letter(), d.name, d.collection],
			"its mate reads Pair (%s)" % _hud.sense_text())
	await _aim(_centre(OTHER))
	await _until(func() -> bool: return _hud.sense_text().contains("Sock 2/3") and _hud.sense_text().ends_with("[WHEEL]"),
			"another reads 2/3 with the wheel (%s)" % _hud.sense_text())


func case_a16() -> void:
	var state := (load(ZOO) as PackedScene).get_state()
	var zoo_flags: PlayerUpgrades = null
	for i in state.get_node_count():
		if state.get_node_name(i) == &"Player":
			for p in state.get_node_property_count(i):
				if state.get_node_property_name(i, p) == &"upgrades":
					zoo_flags = state.get_node_property_value(i, p) as PlayerUpgrades
	_check(zoo_flags != null and zoo_flags.smarts() and zoo_flags.sense(), "the zoo's player has both flags on")
	await _build(false)
	_check(_player.upgrades.smarts() and _player.upgrades.sense(), "the station's switches turn both on")
	_stand(BY_SWITCHES)
	var smarts_button := _station.get_node("SmartsSwitch/Looks/Button") as Node3D
	await _aim(smarts_button.global_position)
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Sock Smarts: on", "the switch's prompt (%s)" % _hud.prompt_text())
	await _press(&"interact")
	await _until(func() -> bool: return not _player.upgrades.smarts(), "E turns Sock Smarts off")
	_check(_hud.prompt_text() == "[E] Sock Smarts: off", "the prompt says off (%s)" % _hud.prompt_text())
	_check(not _player.upgrades.sense(), "Sense needs Smarts")
	var sense_button := _station.get_node("SenseSwitch/Looks/Button") as Node3D
	await _aim(sense_button.global_position)
	await _until(func() -> bool: return _hud.prompt_text() == "[E] Sock Sense: on", "the Sense switch's prompt (%s)" % _hud.prompt_text())
	await _press(&"interact")
	await _until(func() -> bool: return not _player.upgrades.sock_sense, "E turns Sock Sense off")
	_check((_station.get_node("SenseSwitch/Looks/Label") as Label3D).text == "Sock Sense: off", "its label says off")


func case_pad_keys() -> void:
	await _build()
	await _until(func() -> bool: return _hud.hints_text() == HINTS_EMPTY, "the keyboard's keycaps")
	var press := InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_START
	press.pressed = true
	Input.parse_input_event(press)
	var pad_jump := Prompts.keys(Player.JUMP, true)
	_check(not pad_jump.is_empty() and pad_jump[0].begins_with("pad_"), "jump has a pad glyph (%s)" % [pad_jump])
	await _until(func() -> bool: return _hud.pad and _hud.hints_text().contains(Prompt.cap_text(pad_jump[0])), "the pad's glyphs (%s)" % _hud.hints_text())
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	await _until(func() -> bool: return not _hud.pad and _hud.hints_text() == HINTS_EMPTY, "the keyboard's again")
	key.pressed = false
	Input.parse_input_event(key)


# --- Helpers -------------------------------------------------------------------------------------

## A floor, the station, a Parts and the player (it holds 3, as the zoo's) standing at BY_SOCKS.
func _build(flags_off := true) -> void:
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
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = 3
	_player.position = _station.position + BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_hud = _player.hud()
	await _until(func() -> bool: return _player.is_on_floor() and _mess.count() == 3, "the player to stand and the Socks to lie")
	# The station's switches start on; each case sets the flags it is about.
	if flags_off:
		_player.upgrades.sock_smarts = false
		_player.upgrades.sock_sense = false


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(target: Vector3) -> void:
	var head := _player.get_node("Head") as Node3D
	var to := target - _player.global_position
	_player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Presses and lets go of input action `action` as the player would.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(1)


## Takes Sock `sock` into the Hands by the Hands' own Command, past the grab interval.
func _take(sock: int) -> void:
	_hands.clock += 10.0
	_hands.pick(1, sock)
	await _physics_ticks(2)
	_check(_hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d is taken" % sock)


func _centre(sock: int) -> Vector3:
	return _mess.box_of(sock).get_center()


## The front of drawer `index` (0 the bottom), in the level.
func _drawer_front(index: int) -> Vector3:
	var slide := _station.get_node("Cabinet/Drawer%d/Looks/Slide" % (index + 1)) as Node3D
	return slide.global_transform * Vector3(0.0, 0.14, 0.25)


func _door_point() -> Vector3:
	return (_station.get_node("Door/Looks/Hinge") as Node3D).global_transform * Vector3(0.45, 1.3, 0.025)
