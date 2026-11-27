## The encyclopedia book in the house (core/139, docs/architecture/gifts.md "In the house" and "The book"): one shared
## book on the workshop's workbench, a Carriable with `one_slot`: a Hands item in one place instead of the whole Hands.
## E reads it (the pages of the reader's own profile), A / D and the arrows turn them, E or Esc shuts them. Lines are
## list 07's "The encyclopedia": the left click into empty Hands, the one place, the wheel, Read and Drop, put down,
## never thrown, and the pages shutting when the book leaves the Hands. The co-op side (a Teammate sees it carried, each
## reader their own pages) is tests/coop_carry_test.gd's `book` case.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const LAYING_S := 20.0
## The book's place on the workbench (the old layout's props[], in the house's metres).
const SPOT := Vector3(0.95, -2.1, 0.5)
## Where the player stands in the workshop, before the bench, and the book's middle they look at.
const FRONT := Vector3(0.95, -3.0, 1.5)
const AIM := Vector3(0.95, -2.06, 0.5)

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the house a left click on the book on the workbench (crosshair \"Sock Encyclopedia\") takes it into the empty Hands; the corner reads Read and Drop; E opens the pages (the reader's own profile: a held Design named, the others \"???\"), the player held and the mouse free; A turns back, D on, Left and Right too; Esc shuts them; E opens them again and shuts them; a right click puts the book down on the bench at the crosshair"},
		{"name": "held_alone", "method": "case_held_alone", "world": false,
				"title": "Q2722: the book is held alone: with a Sock held a click on it is refused Hands full (the Host refuses the same); holding it a Sock is refused Hands full and nothing is handed in, with room for three; put the book down and the Sock is picked"},
		{"name": "leaves_hands", "method": "case_leaves_hands", "world": false,
				"title": "the book is never thrown (a held right click charges nothing); the pages shut by themselves and the player is held no more when the book leaves the Hands (put down by the Host's answer)"},
	]


func _before_case() -> void:
	SockGenerator.start_all = true
	for a: StringName in [&"interact", &"pick", &"drop_throw", &"move_forward", &"move_left", &"turn"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _house()
	var player := _player()
	var book := _book()
	var carriable := _carriable()
	var menu := _menu()
	var me := player.player_id()
	var hands := _hands()
	var profile := Worlds.profile_of(menu)
	var mine := EncyclopediaPage.sorted_designs(&"simple")
	profile.designs = PackedInt32Array([mine[0].id])
	profile.collections = [&"simple", &"patterns"]
	_check(carriable.holder == 0 and carriable.one_slot and carriable.handable and carriable.title == "Sock Encyclopedia",
			"the book lies, a one_slot, handable Carriable titled Sock Encyclopedia")
	var top := PhysicsQueries.ray(book, Vector3(0.95, -1.0, 0.5), Vector3(0.95, -3.0, 0.5), Mess.LAYER_HOUSE, [book.get_rid()])
	_check(not top.is_empty() and absf(float(top["position"].y) - book.global_position.y) < 0.02, "the bench top is under the book (%s)" % [top])
	_check(book.global_position.distance_to(SPOT) < 0.02, "it lies on the workbench's top (%s, want %s)" % [book.global_position, SPOT])
	_stand_look(FRONT, AIM)
	await _physics_ticks(4)
	_check(player.aimed_part() == carriable, "the crosshair is on the book (%s)" % player.aimed_part())
	_check(player.hud().prompt_text().contains("Sock Encyclopedia"), "the crosshair names it (%s)" % player.hud().prompt_text())
	await _press(&"pick")
	await _until(func() -> bool: return carriable.holder == me, "the left click takes the book into the empty Hands", 60)
	_check(hands.one_slot_active(me) == carriable and hands.active_of(me) < 0 and hands.carries(me) == null,
			"it is the active Hands item, a one-slot one (no whole-Hands carry)")
	await _physics_ticks(4)
	var hints := player.hud().hints_text()
	_check(hints.contains("Read") and hints.contains("Drop") and not hints.contains("Throw"), "the corner reads Read and Drop, no Throw (%s)" % hints)
	_check(hints.find("Read") < hints.find("Drop"), "Read comes before Drop")
	# E opens the pages: the reader's own profile.
	await _use()
	await _until(menu.is_open, "E opens the pages")
	var page := menu.page()
	_check(page != null and page.profile == profile, "the pages are the reader's own profile")
	_check(player.input_blocked() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "the player is held and the mouse free")
	var cells := page.cells()
	_check(cells[0].shown_name() == mine[0].name and cells[1].shown_name() == EncyclopediaCell.UNKNOWN,
			"the held Design is named, the others \"???\" (%s, %s)" % [cells[0].shown_name(), cells[1].shown_name()])
	var at := player.global_position
	Input.action_press(&"move_forward")
	await _physics_ticks(10)
	Input.action_release(&"move_forward")
	_check(player.global_position.distance_to(at) < 0.05, "the world runs but the player does not walk")
	var pages := page.pages().size()
	_check(pages > 1 and page.page == 0, "the pages start on the first (%d pages)" % pages)
	await _key(KEY_A)
	_same(page.page, pages - 1, "A turns back, wrapping to the last page")
	await _key(KEY_D)
	_same(page.page, 0, "D turns on")
	await _key(KEY_RIGHT)
	_same(page.page, 1, "Right turns on")
	await _key(KEY_LEFT)
	_same(page.page, 0, "Left turns back")
	await _key(KEY_RIGHT)
	await _key(KEY_ESCAPE)
	await _until(func() -> bool: return not menu.is_open(), "Esc shuts the pages")
	await _until(func() -> bool: return not player.input_blocked(), "the player is free again")
	_check(carriable.holder == me, "Esc did not drop the book")
	# E opens it again on the page it was left at, and E shuts it (the player gets its input back after).
	await _use()
	await _until(menu.is_open, "E opens the pages again")
	_same(menu.page().page, 1, "on the page it was left at")
	await _key(KEY_E)
	await _until(func() -> bool: return not menu.is_open(), "E shuts the pages")
	await _until(func() -> bool: return not player.input_blocked(), "the player is free after E")
	await _physics_ticks(4)
	_check(not menu.is_open(), "the E that shut it did not read the book again")
	# A right click puts it down on the bench at the crosshair.
	var target := AIM + Vector3(0.12, 0.0, 0.05)
	_stand_look(FRONT, target)
	await _physics_ticks(4)
	var yaw := player.rotation.y
	await _press(&"drop_throw")
	await _until(func() -> bool: return carriable.holder == 0, "a right click puts the book down", 60)
	await _physics_ticks(20)
	_check(hands.one_slot_of(me) == null and hands.list_size(me) == 0, "the Hands are empty again")
	_check(Vector2(book.global_position.x - target.x, book.global_position.z - target.z).length() < 0.2,
			"it lies on the bench at the crosshair (%s)" % book.global_position)
	_near(angle_difference(book.rotation.y, wrapf(yaw, -PI, PI)), 0.0, 0.05, "turned as it was held")


# --- Held alone ----------------------------------------------------------------------------------

func case_held_alone() -> void:
	await _house()
	var player := _player()
	var carriable := _carriable()
	var hands := _hands()
	var me := player.player_id()
	var tuning := player.hands_tuning.duplicate() as HandsTuning
	tuning.capacity = 3
	player.hands_tuning = tuning
	var socks := _lying_socks(3)
	var mess := _runtime().mess
	# Holding a Sock, a click on the book is refused: Hands full, the book stays.
	await _pick_sock(socks[0], 1)
	_stand_look(FRONT, AIM)
	await _physics_ticks(4)
	_check(player.aimed_part() == carriable, "the crosshair is on the book")
	await _press(&"pick")
	await _physics_ticks(4)
	_check(carriable.holder == 0 and player.message() == "Hands full", "with a Sock held a click on the book is refused: Hands full (%s)" % player.message())
	_same(carriable.pick_refusal(me), Carriable.FULL, "the Host refuses the same")
	var ev := _runtime().parts.answer(Command.new(&"pick", me, carriable.id))
	_check(not ev.get("ok", false) and ev.get("reason", "") == Carriable.FULL, "a pick of it is refused by the Host's answer")
	_drop_socks()
	await _until(func() -> bool: return hands.items_of(me).is_empty(), "the Hands are empty", 60)
	# Holding the book, a click on a Sock is refused (room or not), and nothing is handed in.
	_stand_look(FRONT, AIM)
	await _physics_ticks(4)
	await _press(&"pick")
	await _until(func() -> bool: return carriable.holder == me, "an empty Hands take the book", 60)
	await _go_to(mess.where_of(socks[1]))
	await _until(func() -> bool: return hands.pick_refusal(me, socks[1]) != Hands.SOON, "the grab interval to pass", 120)
	_same(hands.pick_refusal(me, socks[1]), Hands.FULL, "holding the book a Sock is refused Hands full, with room for three")
	_check(not hands.can_take(me, socks[1]), "nothing is handed in either")
	_same(hands.list_size(me), 1, "the book fills the Hands alone")
	hands.pick(me, socks[1])
	await _physics_ticks(6)
	_check(hands.items_of(me).is_empty() and carriable.holder == me, "a Sock asked for anyway stays where it lies")
	# Put the book down; then the Sock can be picked.
	_stand_look(player.global_position, player.global_position + Vector3(0.0, -0.9, -1.1))
	await _physics_ticks(4)
	await _press(&"drop_throw")
	await _until(func() -> bool: return carriable.holder == 0, "a right click puts the book down", 60)
	await _go_to(mess.where_of(socks[1]))
	await _until(func() -> bool: return hands.pick_refusal(me, socks[1]) != Hands.SOON, "the grab interval to pass", 120)
	_same(hands.pick_refusal(me, socks[1]), "", "with the book down the Sock can be picked")
	hands.pick(me, socks[1])
	await _until(func() -> bool: return hands.items_of(me).size() == 1, "the Sock is picked", 60)


# --- The book leaves the Hands -------------------------------------------------------------------

func case_leaves_hands() -> void:
	await _house()
	var player := _player()
	var carriable := _carriable()
	var menu := _menu()
	var hands := _hands()
	var me := player.player_id()
	await _take_book()
	# Never thrown: a held right click charges no ring and the book stays in the Hands until it is let go.
	Input.action_press(&"drop_throw")
	await _physics_ticks(40)
	_check(not player.charging and carriable.holder == me, "a held right click charges nothing and throws nothing")
	Input.action_release(&"drop_throw")
	await _physics_ticks(4)
	if carriable.holder != me:
		await _take_book()
	# The pages shut when the book leaves the Hands.
	await _use()
	await _until(menu.is_open, "E opens the pages")
	_check(player.input_blocked(), "the player is held")
	var at := player.global_position + Vector3(0.0, 0.0, -0.6)
	carriable.parts.ask(Command.new(&"drop", me, carriable.id, {"at": at, "yaw": 0.0, "normal": Vector3.UP}))
	await _until(func() -> bool: return carriable.holder == 0, "the Host lays the book down", 60)
	await _until(func() -> bool: return not menu.is_open(), "the pages shut by themselves", 60)
	await _until(func() -> bool: return not player.input_blocked(), "the player is free")


# --- Helpers -------------------------------------------------------------------------------------

func _house() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	await _until(rt.loading.is_lifted, "the house's Socks to be laid", 900, LAYING_S)
	await _until(func() -> bool: return rt.player.is_on_floor(), "the player to stand in the house")
	rt.player.capture_mouse()


func _runtime() -> LevelRuntime:
	return LevelRuntime.of(_level)


func _player() -> Player:
	return _runtime().player


func _book() -> Node3D:
	return _level.get_node("EncyclopediaBook") as Node3D


func _thing() -> Node3D:
	return _book()


func _carriable() -> Carriable:
	return _book().get_node("Carriable") as Carriable


func _menu() -> EncyclopediaMenu:
	return _book().get_node("EncyclopediaMenu") as EncyclopediaMenu


func _hands() -> Hands:
	return _player().hands()


## Stands the player at `feet` looking at `target`.
func _stand_look(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	var head := player.get_node("Head") as Node3D
	var up := target - (feet + Vector3.UP * head.position.y)
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	player.reset_physics_interpolation()


## Puts the player on the floor beside `where` and lets the Host hear it.
func _go_to(where: Vector3) -> void:
	_stand_look(where + Vector3(0.0, 0.0, 0.4), where)
	await _physics_ticks(4)


## The book into the player's empty Hands (the Part's own ask, standing near it).
func _take_book() -> void:
	await _go_to(_thing().global_position)
	var me := _player().player_id()
	_carriable().pick(me)
	await _until(func() -> bool: return _carriable().holder == me, "the book is taken", 60)


## Goes to Sock `sock`, asks to pick it and waits until the Hands hold `held` Socks.
func _pick_sock(sock: int, held: int) -> void:
	var me := _player().player_id()
	await _go_to(_runtime().mess.where_of(sock))
	await _until(func() -> bool: return _hands().pick_refusal(me, sock) != Hands.SOON, "the grab interval to pass", 120)
	_same(_hands().pick_refusal(me, sock), "", "Sock %d may be picked" % sock)
	_hands().pick(me, sock)
	await _until(func() -> bool: return _hands().items_of(me).size() == held, "the Hands to hold %d Socks" % held, 60)


## `n` lying loose Socks of different Designs.
func _lying_socks(n: int) -> Array[int]:
	var mess := _runtime().mess
	var out: Array[int] = []
	var designs := {}
	for sock in mess.count():
		if mess.state_of(sock) == Mess.State.LYING and mess.mate_of(sock) < 0 and not mess.is_pair(sock) \
				and not designs.has(mess.designs[sock]):
			designs[mess.designs[sock]] = true
			out.append(sock)
			if out.size() == n:
				break
	return out


## The Host lets every Sock in the player's Hands go where they stand.
func _drop_socks() -> void:
	var ev := _hands().left(_player().player_id())
	if not ev.is_empty():
		_runtime().parts.apply(ev)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## E pressed through the player's own input.
func _use() -> void:
	Input.action_press(Player.INTERACT)
	await _physics_ticks(2)
	Input.action_release(Player.INTERACT)


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)


func _wheel(button: MouseButton) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)
