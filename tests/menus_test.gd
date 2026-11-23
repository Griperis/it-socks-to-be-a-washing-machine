## The screens around play (core/58; behaviour list docs/migration/m4-lists/01-main-menu-and-saves.md,
## "Launch", "The title's look and sounds", "The pages", "Options", "Licence", "The cursor", "Loading",
## "The ESC menu"): the title and its pages, Options, Licence, the loading screen, the ESC menu, the
## menus' sounds and the cursor; screens are scenes on the one Theme, pressed by mouse clicks pushed
## into the viewport.
extends TestSuite

const TITLE := "res://game/ui/title/title.tscn"
const OPTIONS := "res://game/ui/options/options.tscn"
const LICENCE := "res://game/ui/licence/licence.tscn"
const LOADING := "res://game/level/loading_screen.tscn"
const ONE_BOX := "res://game/level/one_box_level.tscn"
const THEME := "res://game/look/theme.tres"

var _nodes: Array[Node] = []
var _went: Array = []
var _quit := 0
var _played: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "m01_title_first", "method": "case_m01", "world": false,
				"title": "M01: the game launches into the title (run/main_scene; the house stays reachable with --scene=); the mouse is freed"},
		{"name": "m02_home", "method": "case_m02", "world": false,
				"title": "M02: the home page reads \"It Socks\" over Solo, Multiplayer, Options and Quit (red), each with its icon, on the cream panel over the dark backdrop; the Licence key sits in the corner on home only; the Zoo key only in a debug build (Q2580)"},
		{"name": "m03_pages", "method": "case_m03", "world": false,
				"title": "M03: Multiplayer shows Host, Join and Back; Join shows the name and address fields, Join and the firewall line; Back and Esc go one page up; the pages swap at once"},
		{"name": "m04_join_kept", "method": "case_m04", "world": false,
				"title": "M04: leaving the Join page keeps the typed name (cleaned: trimmed, at most 16, empty is Player) and address in the profile"},
		{"name": "m05_join_goes", "method": "case_m05", "world": false,
				"title": "M05 (core/63): Join (or Enter in the address) goes to the Lobby as a Guest of that address; Solo to the Lobby with the Solo World, a New Game when none (Q2579, Q2583); Host to the Lobby listening on its World; the Lobby goes on the title's way in"},
		{"name": "m06_quit", "method": "case_m06", "world": false,
				"title": "M06: Quit closes the game"},
		{"name": "m07_notice", "method": "case_m07", "world": false,
				"title": "M07: a waiting notice (why the session ended, a save that fell back) shows once in the status line"},
		{"name": "m08_ui_sounds", "method": "case_m08", "world": false,
				"title": "M08: every menu button clicks (ui_click) when pressed and ticks (ui_hover) when the mouse comes over an enabled one, both on the UI bus; a no_ui_sound button stays silent"},
		{"name": "o01_rows", "method": "case_o01", "world": false,
				"title": "O01: Options has the old rows in order, Voices added (Q2549): Graphics, SSAO, Master, Music, Effects, Ambience, Voices, UI, Mouse speed, Invert Y, Pad speed, Pad rumble, Subtitles, Display, V-sync, FPS cap"},
		{"name": "o02_applied_kept", "method": "case_o02", "world": false,
				"title": "O02: a pressed value is chosen (orange), applied at once and kept in Settings; a slider shows its value (\"85%\", \"1.25x\")"},
		{"name": "o03_preset_ssao", "method": "case_o03", "world": false,
				"title": "O03: picking a graphics preset puts SSAO back to the preset's own; the SSAO row shows what is in force; Auto picks from the GPU"},
		{"name": "o04_pad_steps", "method": "case_o04", "world": false,
				"title": "O04: Left / Right on a focused value steps it, no wrap, and the focus follows"},
		{"name": "o05_look_settings", "method": "case_o05", "world": false,
				"title": "O05: Mouse speed and Invert Y are settings of the machine the player's look reads"},
		{"name": "l01_licence", "method": "case_l01", "world": false,
				"title": "L01: the Licence page lists the game's lines (the first larger), each work by section with its author and licence and a link, then Licences; a link opens"},
		{"name": "l02_every_asset_covered", "method": "case_l02", "world": false,
				"title": "L02: every file under assets/ is covered by a credits entry"},
		{"name": "c01_cursor", "method": "case_c01", "world": false,
				"title": "C01: the game's own cursor is the white arrow (assets/ui/cursor.svg) with its hotspot at (3, 2), set by the project"},
		{"name": "d01_loading", "method": "case_d01", "world": false,
				"title": "D01: the loading screen (one scene for the scene's load and the house's laying, Q2575) is the backdrop, the cream card, the tumbling sock, \"Loading the house...\" and a bar that never goes back; finish() shows it full, takes the card away and fades out, never holding input; a loaded World lays nothing, a Guest reads \"Joining...\""},
		{"name": "e01_esc_menu", "method": "case_e01", "world": false,
				"title": "E01: Esc in play opens the ESC menu and nothing pauses; alone Back to title and Quit game; the player's input is held; Esc closes it"},
		{"name": "e02_end_session", "method": "case_e02", "world": false,
				"title": "E02: a Host's End session asks \"Everyone will be sent back to the menu.\"; End saves, ends the session and goes to the title; a Guest's Leave goes to the title; a title Guest whose Host ended goes to the title with the reason"},
		{"name": "e03_options_in_esc", "method": "case_e03", "world": false,
				"title": "E03: Options opens from the ESC menu; Esc closes it first"},
		{"name": "x01_close_key_title", "method": "case_x01", "world": false,
				"title": "X01 real path: on the title, Multiplayer, Join, Options and Licence each show the ESC close key at the same top-right corner of their panel; a click closes the page (one page up), Esc does the same"},
		{"name": "x02_close_key_esc_menu", "method": "case_x02", "world": false,
				"title": "X02 real path: the ESC menu and the Options over it show the close key; a click closes each, Esc too; over End session's question the key cancels the question first"},
		{"name": "x03_every_dialogue_has_it", "method": "case_x03", "world": false,
				"title": "X03: every dialogue scene under game/ui (a root with a `closed` signal, the title's Multiplayer and Join pages) holds the shared close_button scene, at the top right"},
	]


func _before_case() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	_went.clear()
	_quit = 0
	_played.clear()
	await _frames(2)


# --- Title ----------------------------------------------------------------------------------------

func case_m01() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene") == TITLE, "the launched scene is the title")
	_check(GameCli.plan(PackedStringArray(["--scene=res://game/house/house.tscn"]), true)["action"] == "scene", "the house stays reachable with --scene=")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _title()
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE or DisplayServer.get_name() == "headless", "the mouse is freed")


func case_m02() -> void:
	var t := await _title()
	_check((t.get_node("Pages/Center/Column/Panel/Stack/Home/Heading") as Label).text == "It Socks", "it reads It Socks")
	var keys := {"Solo": "Solo", "MultiplayerKey": "Multiplayer", "OptionsKey": "Options", "Quit": "Quit"}
	for k: String in keys:
		var b := t.get_node("%" + k) as Button
		_check(b.visible and b.text == keys[k] and b.icon != null, "%s keycap with its icon" % keys[k])
	_check((t.get_node("%Quit") as Button).theme_type_variation == &"ExitButton", "Quit is the red keycap")
	_check((t.get_node("Pages/Center/Column/Panel") as Control).theme_type_variation == &"TitlePanel", "on the cream panel")
	_check((t.get_node("Backdrop") as ColorRect).color.is_equal_approx(Color("#2b211c")), "over the dark backdrop")
	_check((t.get_node("%LicenceKey") as Control).visible, "the Licence key on home")
	var zoo := t.get_node_or_null("%ZooKey") as Control
	_check((zoo != null and zoo.visible) == OS.is_debug_build(), "the Zoo key only in a debug build (Q2580)")
	_check(ProjectSettings.get_setting("gui/theme/custom") == THEME, "every screen is on the one Theme")
	await _click(t.get_node("%MultiplayerKey"))
	_check(not (t.get_node("%LicenceKey") as Control).visible, "the corner key hides on another page")


func case_m03() -> void:
	var t := await _title()
	await _click(t.get_node("%MultiplayerKey"))
	_check(t.page == TitleScreen.MULTIPLAYER and (t.get_node("%Host") as Control).is_visible_in_tree() and (t.get_node("%JoinKey") as Control).is_visible_in_tree(), "Multiplayer shows Host and Join")
	_check(not (t.get_node("%Home") as Control).visible, "the home page went at once")
	await _click(t.get_node("%JoinKey"))
	_check(t.page == TitleScreen.JOIN and (t.get_node("%NameField") as Control).is_visible_in_tree() and (t.get_node("%AddressField") as Control).is_visible_in_tree(), "Join shows the two fields")
	_check((t.get_node("Pages/Center/Column/Panel/Stack/Join/Firewall") as Label).text.contains("UDP port 24680"), "the firewall line")
	await _key(&"ui_cancel")
	_check(t.page == TitleScreen.MULTIPLAYER, "Esc goes one page up")
	await _click((t.get_node("%Close") as CloseButton).key())
	_check(t.page == TitleScreen.HOME, "the close key goes home")


func case_m04() -> void:
	var t := await _title()
	t.show_page(TitleScreen.JOIN)
	(t.get_node("%NameField") as LineEdit).text = "  Sockmaster  "
	(t.get_node("%AddressField") as LineEdit).text = " 10.0.0.7 "
	await _click((t.get_node("%Close") as CloseButton).key())
	var p := Worlds.profile()
	_check(p.name == "Sockmaster" and p.address == "10.0.0.7", "the name and address are kept (%s, %s)" % [p.name, p.address])
	t.show_page(TitleScreen.JOIN)
	(t.get_node("%NameField") as LineEdit).text = "   "
	t.show_page(TitleScreen.HOME)
	_check(Worlds.profile().name == PlayerProfile.NAME, "an empty name is Player")
	_check((t.get_node("%NameField") as LineEdit).max_length == PlayerProfile.NAME_MAX, "at most 16 letters")


func case_m05() -> void:
	var t := await _title()
	t.show_page(TitleScreen.JOIN)
	(t.get_node("%AddressField") as LineEdit).text = "127.0.0.1:9"
	await _click(t.get_node("%JoinGo"))
	_check(_went.size() == 1 and _went[0][0] == LobbyScreen.SCENE, "Join goes to the Lobby")
	var lobby := _lobby_from(_went[0])
	_check(lobby.mode == LobbyScreen.Mode.JOIN and lobby.address == "127.0.0.1:9" and lobby.world == null, "as a Guest of that address, with no World")
	lobby.free()
	_went.clear()
	(t.get_node("%AddressField") as LineEdit).text_submitted.emit("127.0.0.1:9")
	_check(_went.size() == 1 and _went[0][0] == LobbyScreen.SCENE, "Enter in the address joins")
	_went.clear()
	t.show_page(TitleScreen.HOME)
	await _click(t.get_node("%Solo"))
	_check(_went.size() == 1 and _went[0][0] == LobbyScreen.SCENE, "Solo goes to the Lobby (Q2583)")
	lobby = _lobby_from(_went[0])
	_check(lobby.mode == LobbyScreen.Mode.SOLO and lobby.world != null and lobby.world.slot == Worlds.SOLO and lobby.world.is_new,
			"alone, with the Solo World: a New Game with no save (Q2579)")
	_check(lobby.go_into == t.go_into, "the Lobby goes into the house the title's way")
	lobby.free()
	_went.clear()
	t.host()
	lobby = _lobby_from(_went[0])
	_check(lobby.mode == LobbyScreen.Mode.HOST and lobby.world.hosting, "Host goes to the Lobby listening on its World")
	lobby.free()


func _lobby_from(went: Array) -> LobbyScreen:
	var root := (load(String(went[0])) as PackedScene).instantiate() as LobbyScreen
	(went[2] as Callable).call(root)
	return root


func case_m06() -> void:
	var t := await _title()
	await _click(t.get_node("%Quit"))
	_check(_quit == 1, "Quit closes the game")


func case_m07() -> void:
	Worlds.notice = "The Host ended the session"
	var t := await _title()
	_check(t.status() == "The Host ended the session", "the notice shows in the status line")
	_check((t.get_node("%Status") as Label).theme_type_variation == &"StatusLabel", "in the accent colour")
	_check(Worlds.take_notice() == "", "only once")


func case_m08() -> void:
	Sounds.played.connect(_on_played)
	var t := await _title()
	await _click(t.get_node("%MultiplayerKey"))
	_check(_played.any(func(p: Array) -> bool: return p[0] == UiSounds.CLICK and p[1] == &"UI"), "a press clicks on the UI bus (%s)" % [_played])
	_played.clear()
	(t.get_node("%Host") as Button).mouse_entered.emit()
	_check(_played.any(func(p: Array) -> bool: return p[0] == UiSounds.HOVER), "the mouse over an enabled button ticks")
	_played.clear()
	var quiet := Button.new()
	quiet.set_meta(UiSounds.SILENT, true)
	t.add_child(quiet)
	quiet.pressed.emit()
	_check(_played.is_empty(), "a no_ui_sound button stays silent")
	Sounds.played.disconnect(_on_played)


# --- Options --------------------------------------------------------------------------------------

func case_o01() -> void:
	var o := await _options()
	var titles := PackedStringArray()
	for row in o.rows():
		titles.append(String(row.get(&"title")))
	_check(titles == PackedStringArray(["Graphics", "SSAO", "Master", "Music", "Effects", "Ambience", "Voices", "UI", "Mouse speed",
			"Invert Y", "Pad speed", "Pad rumble", "Subtitles", "Display", "V-sync", "FPS cap"]), "the rows in order (%s)" % titles)
	for row in o.rows():
		_check(Settings.get_value(String(row.get(&"key"))) != null, "%s is a setting (%s)" % [row.get(&"title"), row.get(&"key")])


func case_o02() -> void:
	var o := await _options()
	var fps := o.row_of(Settings.FPS_CAP) as ChoiceRow
	(o.get_node("Panel/Box/Scroll") as ScrollContainer).ensure_control_visible(fps)
	await _frames(2)
	await _click(fps.key_of(60))
	_check(Settings.get_int(Settings.FPS_CAP) == 60, "FPS cap 60 is kept")
	_check(fps.key_of(60).theme_type_variation == ChoiceRow.ON and fps.key_of(0).theme_type_variation == ChoiceRow.OFF, "the chosen one is orange")
	var music := o.row_of("audio/music_volume") as SliderRow
	music.slider().value = 0.85
	_near(Settings.get_float("audio/music_volume"), 0.85, 0.001, "the Music volume is applied and kept")
	_check((music.get_node("%Value") as Label).text == "85%", "the slider shows 85%")
	var mouse := o.row_of(Settings.MOUSE_SPEED) as SliderRow
	mouse.slider().value = 1.25
	_check((mouse.get_node("%Value") as Label).text == "1.25x", "a speed shows 1.25x")
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music"))
	_check(db < Sounds.mix_db(&"Music") and db > Sounds.mix_db(&"Music") - 3.0, "the Music bus plays at its mix times the slider (%.2f dB)" % db)
	_check(AudioServer.get_bus_index(&"Voice") >= 0, "a Voice bus (Q2549)")


func case_o03() -> void:
	var o := await _options()
	var ssao := o.row_of(Settings.SSAO) as ChoiceRow
	await _click((o.row_of(Settings.GRAPHICS_PRESET) as ChoiceRow).key_of("low"))
	_check(GraphicsPreset.chosen_name() == "low" and ssao.shown() == 0, "Low: SSAO shows the preset's own (off)")
	await _click(ssao.key_of(1))
	_check(Settings.get_int(Settings.SSAO) == 1 and GraphicsPreset.ssao_on(GraphicsPreset.chosen()), "SSAO on over Low")
	await _click((o.row_of(Settings.GRAPHICS_PRESET) as ChoiceRow).key_of("high"))
	_check(Settings.get_int(Settings.SSAO) == -1 and ssao.shown() == 1, "a preset picked puts SSAO back to its own (High: on)")
	_check(GraphicsPreset.for_adapter("llvmpipe (LLVM 15)", RenderingDevice.DEVICE_TYPE_CPU) == "low"
			and GraphicsPreset.for_adapter("Intel(R) UHD Graphics 620", RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU) == "low"
			and GraphicsPreset.for_adapter("NVIDIA GeForce GTX 1650", RenderingDevice.DEVICE_TYPE_DISCRETE_GPU) == "medium"
			and GraphicsPreset.for_adapter("NVIDIA GeForce RTX 4080", RenderingDevice.DEVICE_TYPE_DISCRETE_GPU) == "high", "Auto: software or integrated Low, mid-range Medium, else High")


func case_o04() -> void:
	var o := await _options()
	var fps := o.row_of(Settings.FPS_CAP) as ChoiceRow
	fps.key_of(0).grab_focus()
	await _key(&"ui_right")
	_check(Settings.get_int(Settings.FPS_CAP) == 30 and fps.key_of(30).has_focus(), "Right steps to 30 and the focus follows")
	await _key(&"ui_left")
	await _key(&"ui_left")
	_check(Settings.get_int(Settings.FPS_CAP) == 0 and fps.key_of(0).has_focus(), "Left steps back and stops at the first (no wrap)")


func case_o05() -> void:
	_check(Settings.get_float(Settings.MOUSE_SPEED) == 1.0 and not Settings.get_bool(Settings.INVERT_Y), "defaults: 1.00x, not inverted")
	var player := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	_nodes.append(player)
	add_child(player)
	await _frames(2)
	player.capture_mouse()
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 0)
	var before := player.rotation.y
	player._unhandled_input(motion)
	var one := player.rotation.y - before
	Settings.set_value(Settings.MOUSE_SPEED, 2.0)
	before = player.rotation.y
	player._unhandled_input(motion)
	_near(player.rotation.y - before, one * 2.0, 0.0001, "Mouse speed 2.00x turns twice as far")
	var head := player.get_node("Head") as Node3D
	motion.relative = Vector2(0, 50)
	var pitch := head.rotation.x
	player._unhandled_input(motion)
	var down := head.rotation.x - pitch
	Settings.set_value(Settings.INVERT_Y, true)
	pitch = head.rotation.x
	player._unhandled_input(motion)
	_check(signf(head.rotation.x - pitch) == -signf(down), "Invert Y turns the look the other way")


# --- Licence --------------------------------------------------------------------------------------

func case_l01() -> void:
	var page := (load(LICENCE) as PackedScene).instantiate() as LicencePage
	var opened: Array[String] = []
	page.open_link = func(url: String) -> void: opened.append(url)
	_nodes.append(page)
	add_child(page)
	await _frames(2)
	var lines := page.lines()
	_check(lines[0] == "It Socks" and lines[1] == "A game by Zdenek Dolezal" and lines[2] == "Built with Godot Engine", "the game's lines first (%s)" % lines.slice(0, 3))
	_check(lines.has("Sounds") and lines.has("Licences") and lines.find("Licences") > lines.find("Sounds"), "works by section, then Licences")
	_check(page.links().size() > 10, "each work's source is a link")
	await _click(page.links()[0])
	_check(opened.size() == 1 and opened[0].begins_with("http"), "a link opens (%s)" % [opened])


func case_l02() -> void:
	var credits := load("res://game/ui/licence/credits.tres") as Credits
	var missing: Array[String] = []
	for f in _files("res://assets"):
		var rel := f.trim_prefix("res://")
		if credits.entry_for(rel) == null:
			missing.append(rel)
	_check(missing.is_empty(), "every asset is covered (add an entry to game/ui/licence/credits.tres): %s" % [missing])


# --- Cursor, loading ------------------------------------------------------------------------------

func case_c01() -> void:
	_check(ProjectSettings.get_setting("display/mouse_cursor/custom_image") == "res://assets/ui/cursor.svg", "the cursor is the white arrow")
	_check(ProjectSettings.get_setting("display/mouse_cursor/custom_image_hotspot") == Vector2(3, 2), "its hotspot is (3, 2)")


func case_d01() -> void:
	var screen := (load(LOADING) as PackedScene).instantiate() as LoadingScreen
	screen.free_when_faded = true
	_nodes.append(screen)
	add_child(screen)
	await _frames(2)
	_check(screen.text() == LoadingScreen.LOADING and not screen.bar_shown(), "\"Loading the house...\" (Q2579), no bar until the wait can tell")
	var sock := screen.get_node("%Sock") as Control
	var turn := sock.rotation
	await _frames(10)
	_check(not is_equal_approx(sock.rotation, turn), "the sock tumbles")
	screen.set_progress(0.6)
	screen.set_progress(0.3)
	_near(screen.shown_progress(), 0.6, 0.0001, "the bar never goes back")
	_check((screen.get_node("%Back") as ColorRect).color.is_equal_approx(Color("#2b211c")), "the title's backdrop")
	screen.finish()
	_near(screen.shown_progress(), 1.0, 0.0001, "a measured wait shows full at the end")
	_check(not (screen.get_node("%Card") as Control).visible and (screen.get_node("%Back") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "the card goes and nothing holds input")
	var gone: WeakRef = weakref(screen)
	await _until(func() -> bool: return gone.get_ref() == null, "the screen to fade out and go", roundi(screen.tuning.fade_seconds * 60.0) + 30)
	# A loaded World lays nothing (its Socks come from the save), and a Guest reads "Joining...".
	var house := (load("res://game/house/house.tscn") as PackedScene).instantiate()
	var w := WorldSlot.new()
	w.is_new = false
	LevelRuntime.of(house).world = w
	_nodes.append(house)
	add_child(house)
	await _frames(2)
	_check(not LevelRuntime.of(house).mess.is_laying() and not LevelRuntime.of(house).loading.is_showing(), "a loaded World lays nothing: no laying screen")
	house.free()
	var joining := (load(ONE_BOX) as PackedScene).instantiate()
	LevelRuntime.of(joining).launch = PackedStringArray(["--join=127.0.0.1:9"])
	LevelRuntime.of(joining).from_title = true
	add_child(joining)
	_check(LevelRuntime.of(joining).loading.text() == LoadingScreen.JOINING, "a Guest reads \"Joining...\"")
	joining.free()


# --- ESC menu -------------------------------------------------------------------------------------

func case_e01() -> void:
	var level := await _level(Worlds.pick_solo(), [])
	var runtime := LevelRuntime.of(level)
	var menu := runtime.esc_menu
	await _key(&"ui_cancel")
	_check(menu.is_open() and not get_tree().paused, "Esc opens the ESC menu; nothing pauses")
	_check((menu.get_node("%BackToTitle") as Control).visible and (menu.get_node("%QuitGame") as Control).visible
			and not (menu.get_node("%EndSession") as Control).visible and not (menu.get_node("%Leave") as Control).visible, "alone: Back to title and Quit game")
	_check(runtime.player.get("_input_blocked") == true, "the player's input is held")
	var store := Save.store as MemoryStore
	var writes := store.writes
	menu.quit_game = func() -> void: _quit += 1
	await _click(menu.get_node("%QuitGame"))
	_check(_quit == 1 and store.writes > writes, "Quit game saves, then closes the game")
	await _key(&"ui_cancel")
	if menu.is_open():
		await _key(&"ui_cancel")
	_check(not menu.is_open() and runtime.player.get("_input_blocked") == false, "Esc closes it and gives the input back")


func case_e02() -> void:
	var host := await _machine(Worlds.pick_host(), ["--host"], "Host")
	var hr := LevelRuntime.of(host)
	var guest := await _machine(null, [], "Guest")
	var gr := LevelRuntime.of(guest)
	gr.launch = PackedStringArray(["--join=x"])
	gr.net.start(["--join=127.0.0.1:%d" % hr.session.port])
	await _until(func() -> bool: return gr.roster.peers().size() == 2, "the Guest to join", 900, 0.1)
	var titles: Array[String] = []
	gr.esc_menu.go_to_title = func(n: String) -> void: titles.append("guest:" + n)
	hr.esc_menu.go_to_title = func(n: String) -> void: titles.append("host:" + n)
	hr.esc_menu.open()
	_check((hr.esc_menu.get_node("%EndSession") as Control).visible and not (hr.esc_menu.get_node("%BackToTitle") as Control).visible, "a Host has End session")
	await _click(hr.esc_menu.get_node("%EndSession"))
	_check(hr.esc_menu.asking() and (hr.esc_menu.get_node("Dim/Center/Panel/Pages/Ask/Question") as Label).text == "Everyone will be sent back to the menu.", "it asks first")
	var writes := (Save.store as MemoryStore).writes
	await _click(hr.esc_menu.get_node("%End"))
	_check((Save.store as MemoryStore).writes > writes and not hr.session.is_online() and titles.has("host:"), "End saves, ends the session and goes to the title")
	await _until(func() -> bool: return titles.has("guest:" + Session.HOST_QUIT), "the Guest to go to its title with the reason", 900, 0.1)
	_free_machines()


func case_e03() -> void:
	var level := await _level(null, [])
	var menu := LevelRuntime.of(level).esc_menu
	menu.open()
	await _click(menu.get_node("%Options"))
	var options := menu.find_child("Options", false, false) as OptionsScreen
	_check(options != null, "Options opens from the ESC menu")
	await _key(&"ui_cancel")
	_check(menu.is_open() and (options == null or not is_instance_valid(options) or options.is_queued_for_deletion()), "Esc closes Options first, the menu stays")


# --- The close key ----------------------------------------------------------------------------------

## The key sits in the panel's top-right corner, and shows the ESC keycap.
func _check_corner(close: CloseButton, what: String) -> void:
	var key := close.key()
	var area := close.get_global_rect()
	_check(key.is_visible_in_tree() and absf(key.get_global_rect().end.x - area.end.x) < 1.0
			and key.get_global_rect().position.y - area.position.y < 24.0, "%s: the close key is at the top right" % what)
	_check(key.icon == UiIcons.texture("key_esc") and key.text == "", "%s: it is the ESC keycap, icon only" % what)


func case_x01() -> void:
	var t := await _title()
	var corner := (t.get_node("%Close") as CloseButton)
	for pg: String in [TitleScreen.MULTIPLAYER, TitleScreen.JOIN]:
		t.show_page(pg)
		await _frames(2)
		_check_corner(corner, pg)
		await _click(corner.key())
		_check(t.page != pg, "%s: a click closes it" % pg)
		t.show_page(pg)
		await _key(&"ui_cancel")
		_check(t.page != pg, "%s: Esc closes it" % pg)
	for pg: String in [TitleScreen.OPTIONS_PAGE, TitleScreen.LICENCE_PAGE]:
		t.show_page(pg)
		await _frames(2)
		var page := t.get_node("Pages").get_child(t.get_node("Pages").get_child_count() - 1)
		var close := page.get_node("%Back") as CloseButton
		_check_corner(close, pg)
		await _click(close.key())
		await _frames(2)
		_check(t.page == TitleScreen.HOME, "%s: a click closes it" % pg)
		t.show_page(pg)
		await _frames(2)
		await _key(&"ui_cancel")
		await _frames(2)
		_check(t.page == TitleScreen.HOME, "%s: Esc closes it" % pg)


func case_x02() -> void:
	var level := await _level(Worlds.pick_solo(), [])
	var menu := LevelRuntime.of(level).esc_menu
	for how: String in ["click", "esc"]:
		menu.open()
		await _frames(2)
		_check_corner(menu.get_node("%Back") as CloseButton, "the ESC menu")
		if how == "click":
			await _click((menu.get_node("%Back") as CloseButton).key())
		else:
			await _key(&"ui_cancel")
		_check(not menu.is_open(), "the ESC menu closes by %s" % how)
	menu.open()
	await _click(menu.get_node("%Options"))
	var options := menu.find_child("Options", false, false) as OptionsScreen
	_check_corner(options.get_node("%Back") as CloseButton, "Options over the ESC menu")
	await _click((options.get_node("%Back") as CloseButton).key())
	await _frames(2)
	_check(menu.is_open() and (not is_instance_valid(options) or options.is_queued_for_deletion()), "its key closes Options, the menu stays")
	menu.close()


func case_x03() -> void:
	var seen := 0
	for path in _scenes_under("res://game/ui"):
		var root := (load(path) as PackedScene).instantiate()
		if root.has_signal(&"closed"):
			seen += 1
			_check(_has_close(root), "%s holds the shared close key" % path)
		root.free()
	_check(seen >= 3, "the scan found the dialogues (%d)" % seen)
	var title := (load(TITLE) as PackedScene).instantiate()
	_check(_has_close(title), "the title's Multiplayer and Join pages hold it")
	title.free()


func _has_close(root: Node) -> bool:
	for n in root.find_children("*", "Control", true, false):
		if n.scene_file_path == "res://game/ui/close_button.tscn":
			return true
	return false


func _scenes_under(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tscn"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scenes_under(dir.path_join(d)))
	return out


# --- Helpers --------------------------------------------------------------------------------------

func _title() -> TitleScreen:
	var t := (load(TITLE) as PackedScene).instantiate() as TitleScreen
	t.go_into = func(path: String, heading: String, setup: Callable) -> void: _went.append([path, heading, setup])
	t.quit_game = func() -> void: _quit += 1
	_nodes.append(t)
	add_child(t)
	await _frames(2)
	return t


func _options() -> OptionsScreen:
	var o := (load(OPTIONS) as PackedScene).instantiate() as OptionsScreen
	_nodes.append(o)
	add_child(o)
	await _frames(2)
	return o


func _level(world: WorldSlot, launch: Array) -> Node:
	var level := (load(ONE_BOX) as PackedScene).instantiate()
	var runtime := LevelRuntime.of(level)
	runtime.world = world
	runtime.from_title = true
	runtime.launch = PackedStringArray(launch)
	_nodes.append(level)
	add_child(level)
	await _until(func() -> bool: return runtime.roster.id_of(1) != "", "the level to start")
	return level


var _machines: Array[Node] = []


## A one-box level in a machine of its own (tests/level_test.gd's _branch).
func _machine(world: WorldSlot, launch: Array, label: String) -> Node:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var level := (load(ONE_BOX) as PackedScene).instantiate()
	var runtime := LevelRuntime.of(level)
	runtime.world = world
	runtime.from_title = true
	runtime.launch = PackedStringArray(launch)
	view.add_child(level)
	_machines.append(node)
	await _until(func() -> bool: return runtime.roster.id_of(1) != "", "the level to start")
	return level


func _free_machines() -> void:
	for node in _machines:
		var level := node.get_node_or_null("View/OneBoxLevel")
		if level != null:
			LevelRuntime.of(level).session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_machines.clear()


func _click(target: Node) -> void:
	var control := target as Control
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


func _key(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await _frames(2)


func _on_played(event: StringName, _spatial: bool, _at: Vector3, bus: StringName) -> void:
	_played.append([event, bus])


func _files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".import") and not f.ends_with(".uid"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(d)))
	return out
