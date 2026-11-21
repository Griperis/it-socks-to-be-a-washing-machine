## The UI art (assets/03): every old icon is in the game with its old name and size (U01), the keycap lookup
## answers for each action the prompts name, keyboard and pad (U02), and the Icons station is built from the
## folder (U03). One real-path case: the Interact action as the player's own event fires it names the keycap that
## the station shows on its wall.
extends TestSuite

const STATION := "res://game/zoo/pending/icons.tscn"
## The 111 names of the old game's assets/ui (tag v0.1.1).
const OLD_NAMES: Array[String] = [
	"animals", "ball", "carry", "coins", "cursor", "dirty", "drawers", "drinks", "emoji_help",
	"emoji_here", "emoji_nice", "emoji_no", "emoji_yes", "food", "fruit", "key_1", "key_2",
	"key_ctrl", "key_e", "key_esc", "key_g", "key_lmb", "key_mmb", "key_q", "key_r", "key_rmb",
	"key_shift", "key_space", "key_wheel", "laundry_bin", "lock", "lost", "machinery", "math",
	"menu_coop", "menu_encyclopedia", "menu_exit", "menu_licence", "menu_options", "menu_play",
	"menu_wardrobe", "nature", "pad_a", "pad_b", "pad_back", "pad_dpad", "pad_dpad_down",
	"pad_dpad_left", "pad_dpad_right", "pad_dpad_up", "pad_l3", "pad_lb", "pad_lb_rb", "pad_lt",
	"pad_r3", "pad_rb", "pad_rt", "pad_start", "pad_stick_l", "pad_stick_r", "pad_x", "pad_y",
	"pairs", "patterns", "simple", "sock", "space", "sport", "superhero", "tech", "transport",
	"upgrade_all_hands_cabinet_xray", "upgrade_all_hands_xray", "upgrade_auto_pair",
	"upgrade_big_bag", "upgrade_big_hamper", "upgrade_cabinet_xray",
	"upgrade_cabinet_xray_linger", "upgrade_cabinet_xray_recharge", "upgrade_elevator",
	"upgrade_fast_elevator", "upgrade_fast_run", "upgrade_filter_nozzle", "upgrade_hamper",
	"upgrade_hopper", "upgrade_long_hose", "upgrade_machine", "upgrade_mate_radar",
	"upgrade_quick_charge", "upgrade_quick_grab", "upgrade_roomy_car", "upgrade_sock_sense",
	"upgrade_sock_smarts", "upgrade_sole_hands", "upgrade_sole_mates", "upgrade_speed",
	"upgrade_splitter_collection", "upgrade_splitter_hopper", "upgrade_splitter_speed",
	"upgrade_splitter_third", "upgrade_sprint", "upgrade_strong_suction", "upgrade_throw",
	"upgrade_vacuum", "upgrade_wide_funnel", "upgrade_wide_nozzle", "upgrade_xray",
	"upgrade_xray_linger", "upgrade_xray_recharge", "vegetables", "winter",
]


func cases() -> Array[Dictionary]:
	return [
		{"name": "u01_old_icons", "method": "case_u01", "world": false,
				"title": "U01: every one of the old game's 111 icons is imported under its old name, a 64 by 64 picture (the cursor 36), and the aliases give their target's"},
		{"name": "u02_keycaps", "method": "case_u02", "world": false,
				"title": "U02: the lookup names the keycap of each prompt action (LMB, RMB, wheel, E, R, G, Space, Ctrl) and its pad glyph, and none for an unknown action"},
		{"name": "u03_station", "method": "case_u03", "world": false,
				"title": "U03 (Q2337): the Icons station makes one cell per icon of the folder with its name under it, in the families' order"},
		{"name": "u02_real_path", "method": "case_real_path", "world": false,
				"title": "U02, real path: the Interact action, fired by its own event, names the keycap the station shows for it"},
	]


func case_u01() -> void:
	_check(OLD_NAMES.size() == 111, "the list holds the old 111 names (%d)" % OLD_NAMES.size())
	var missing: Array[String] = []
	var wrong: Array[String] = []
	for n in OLD_NAMES:
		var t := UiIcons.texture(n)
		if t == null:
			missing.append(n)
		elif t.get_size() != (Vector2(36, 36) if n == "cursor" else Vector2(64, 64)):
			wrong.append(n)
	_check(missing.is_empty(), "every old icon loads (missing: %s)" % [missing])
	_check(wrong.is_empty(), "every icon is 64 by 64 (the cursor 36) as the old import made it (wrong: %s)" % [wrong])
	_check(UiIcons.all_keys() == OLD_NAMES, "the folder holds exactly the old names, sorted")
	_check(UiIcons.texture("upgrade_carry") == UiIcons.texture("carry"), "an alias gives its target's picture")
	_check(UiIcons.texture("key_skip") == UiIcons.texture("key_space"), "key_skip shares the Space keycap")
	_check(UiIcons.texture("no_such_icon") == null, "an unknown key has no picture")
	_check(UiIcons.or_simple("no_such_icon") == "simple", "the fallback is the simple icon")


func case_u02() -> void:
	var keys: Dictionary[StringName, String] = {
		&"pick": "key_lmb", &"drop_throw": "key_rmb", &"hands_next": "key_wheel", &"interact": "key_e",
		&"turn": "key_r", &"zoom": "key_g", &"jump": "key_space", &"crouch": "key_ctrl",
	}
	for a in keys:
		var got := UiIcons.keys_for_action(a)
		_check(got == [keys[a]], "%s shows %s on the keyboard (%s)" % [a, keys[a], got])
	var pads: Dictionary[StringName, String] = {
		&"pick": "pad_a", &"drop_throw": "pad_b", &"jump": "pad_x", &"interact": "pad_y",
		&"hands_next": "pad_rb", &"hands_prev": "pad_lb",
	}
	for a in pads:
		var got := UiIcons.keys_for_action(a, true)
		_check(got == [pads[a]], "%s shows %s on the pad (%s)" % [a, pads[a], got])
	_check(UiIcons.keys_for_action(&"no_such_action").is_empty(), "an unknown action has no keycap")
	var key_files := 0
	var pad_files := 0
	for k in UiIcons.all_keys():
		key_files += 1 if k.begins_with("key_") else 0
		pad_files += 1 if k.begins_with("pad_") else 0
	_check(key_files == 14 and pad_files == 20, "14 key and 20 pad icons are in the folder (%d, %d)" % [key_files, pad_files])


func case_u03() -> void:
	var station := (load(STATION) as PackedScene).instantiate() as IconsStation
	add_child(station)
	var all := UiIcons.all_keys()
	var cells := station.wall.get_children().filter(func(n: Node) -> bool: return n.get_node_or_null("Icon") != null)
	_check(cells.size() == all.size(), "one cell per icon (%d of %d)" % [cells.size(), all.size()])
	var named := 0
	for k in all:
		var cell := station.wall.get_node_or_null(k)
		if cell == null:
			continue
		var icon := cell.get_node("Icon") as Sprite3D
		var label := cell.get_node("Label") as Label3D
		if icon.texture == UiIcons.texture(k) and label.text == k:
			named += 1
	_check(named == all.size(), "each cell shows its picture with its name (%d of %d)" % [named, all.size()])
	_check(station.cell_position("key_e") != Vector3.INF, "a cell's place is known")
	_check(station.cell_position("key_e").y > station.cell_position("pad_a").y, "keys stand above the pad glyphs")
	_check(station.cell_position("nothing") == Vector3.INF, "an unknown name has no place")
	station.free()


func case_real_path() -> void:
	var station := (load(STATION) as PackedScene).instantiate() as IconsStation
	add_child(station)
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _until(func() -> bool: return Input.is_action_pressed(&"interact"), "the Interact action to be held")
	var key := UiIcons.keys_for_action(&"interact")[0]
	var sprite := station.wall.get_node(key + "/Icon") as Sprite3D
	_check(key == "key_e", "the Interact keycap is E (%s)" % key)
	_check(sprite.texture == UiIcons.texture("key_e"), "the station's E cell shows the E keycap")
	Input.action_release(&"interact")
	station.free()
