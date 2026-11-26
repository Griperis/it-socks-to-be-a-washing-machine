## The Upgrades and the menu at the Old Tree (core/129, docs/architecture/economy.md "`Upgrades`' state and
## verbs", "The Upgrade menu"): the real path in the Economy station (E on the Old Tree, a click on a
## button), the refusals in their old words, "Coming soon", the co-op-only Upgrades, a Guest's purchase
## decided by the Host and kept by a save and a join, the 27 files and the House prices' total, and the
## menu reachable in a house New Game. The station cases play the station on a floor with the game's
## player and a Parts (a Host of one), as economy_test does.
extends TestSuite

const ECONOMY := "res://game/zoo/stations/economy.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const HOUSE := "res://game/house/house.tscn"
const PLAN := "res://game/run/house_stage_plan.tres"
const DESIGNS := "res://game/sock/designs.tres"
const ACTIONS: Array[StringName] = [&"interact", &"move_forward"]
## Where the player stands before the station's Old Tree, and the point of the tree it aims at.
const BY_TREE := Vector3(4.7, 0.0, -1.2)
const TREE_AIM := Vector3(4.69, 1.0, -2.55)
const NET_WAIT_S := 20.0
const LAYING_S := 20.0
const TAGS := ["upgrades_test_a", "upgrades_test_b"]
const CO_OP_ONLY: Array[StringName] = [&"roomy_car", &"sole_mates", &"sole_hands", &"mate_radar"]

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _parts: Parts = null
var _bank: Bank = null
var _ups: Upgrades = null
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Economy station with 30 Coins the player presses E on the Old Tree and clicks Sock Smarts' button; it reads \"1/1\" and MAX and the Coins counter reads 0; a second click shakes it and the refusal reads \"Maxed out\"; Esc shuts the menu"},
		{"name": "coming_soon", "method": "case_coming_soon", "world": false,
				"title": "Q2669: a batch C Upgrade's button is greyed and reads \"Coming soon\"; a click is refused \"Coming soon\" and shakes it"},
		{"name": "refusals", "method": "case_refusals", "world": false,
				"title": "the old refusals: \"Locked\" (a need below its level, the lock over the icon, \"Needs: Sock Smarts\" on the tip card), \"Need Coins 120\" (too dear), Coins still flying are not spendable (Q2672); a House Upgrade is paid with the team's Drawers"},
		{"name": "coop_only", "method": "case_coop_only", "world": false,
				"title": "Q1357: the co-op-only Upgrades are hidden in Solo and refused \"Co-op only\"; the zoo's Co-op switch shows them"},
		{"name": "coop_guest", "method": "case_coop_guest", "world": false,
				"title": "Q1399, Q243: a Host shows the co-op-only Upgrades before anyone joins; a joining Guest gets the House levels; the Guest's purchase is decided by the Host from its Coins, the Host reads \"<name> bought Sock Smarts\", and a save and a load keep the Guest's levels"},
		{"name": "data", "method": "case_data", "world": false,
				"title": "the 27 Upgrades (16 Personal, 11 House) with the old cells, prices and needs; Sock Smarts, Sense, the six of core/130 and the three Sole cues (core/131) have their stats, the rest \"Coming soon\"; Personal levels sum per stat and Sock Smarts turns the player's readout on"},
		{"name": "house_total", "method": "case_house_total", "world": false,
				"title": "Q1405: the House prices total within 2 of 0.9 x the Drawers the house pays, each at least 1"},
		{"name": "house_menu", "method": "case_house_menu", "world": false,
				"title": "reachable: in a house New Game E on the Old Tree opens the Upgrade menu"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_level()
	_drop_branches()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	_set_coins(30)
	var menu := await _open_at_tree()
	var smarts := menu.button(&"sock_smarts")
	_check(smarts != null and smarts.level_text() == "0/1" and smarts.price_text() == "30", "Sock Smarts reads 0/1 and 30 (%s, %s)" % [smarts.level_text(), smarts.price_text()])
	await _click(smarts.key)
	_check(_ups.level(smarts.upgrade, 1) == 1, "the Host decided the purchase")
	await _frames(2)
	_check(smarts.level_text() == "1/1" and smarts.price_text() == "MAX" and smarts.state == UpgradeButton.MAX, "it reads 1/1 and MAX (%s, %s)" % [smarts.level_text(), smarts.price_text()])
	_check(_counters().coins.amount() == 0, "the HUD's Coins counter reads 0 (%d)" % _counters().coins.amount())
	_check(menu.get_node("Center/Panel/Box/Header/Counters").coins.amount() == 0, "the menu's header reads 0 too")
	_check(_player.upgrades.smarts(), "Sock Smarts turns the held Sock's readout on")
	await _click(smarts.key)
	_check(smarts.shakes == 1, "a second click shakes it (%d)" % smarts.shakes)
	_check(_player.message() == "Maxed out", "the refusal reads \"Maxed out\" (%s)" % _player.message())
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await _frames(2)
	_check(not menu.is_open() and not _player.input_blocked(), "Esc shuts the menu and gives the player back their input")


func case_coming_soon() -> void:
	await _build()
	_set_coins(1000)
	var menu := await _open_at_tree()
	var xray := menu.button(&"xray")
	_check(xray != null and xray.state == UpgradeButton.OFF and xray.price_text() == "Coming soon", "X-ray is greyed and reads \"Coming soon\" (%s)" % xray.price_text())
	await _click(xray.key)
	_check(_ups.level(xray.upgrade, 1) == 0 and _bank.of_player(1) == 1000, "nothing is bought")
	_check(xray.shakes == 1 and _player.message() == "Coming soon", "it shakes and the refusal reads \"Coming soon\" (%s)" % _player.message())
	await _hover(xray.key)
	_check(menu.tip().visible and menu.tip().lines().has("Coming soon"), "its tip card says \"Coming soon\" (%s)" % [menu.tip().lines()])
	# The pad's route is the old true grid.
	var footwork := menu.button(&"footwork").key
	_check(footwork.get_node(footwork.focus_neighbor_right) == menu.button(&"sprint").key, "Right from Footwork is Sprint")
	var hands := menu.button(&"big_hands").key
	_check(hands.get_node(hands.focus_neighbor_right) == menu.button(&"elevator_repair").key, "Right off the Personal row's end crosses to the House's same row")
	var repair := menu.button(&"elevator_repair").key
	_check(repair.get_node(repair.focus_neighbor_left) == hands, "Left off the House row's start crosses back to its end")
	var linger := menu.button(&"cabinet_xray_linger").key
	_check(linger.get_node(linger.focus_neighbor_right) == menu.button(&"big_bag").key, "a Personal row below the House's last crosses to that last row")
	var bottom := menu.button(&"filter_nozzle").key
	_check(bottom.get_node(bottom.focus_neighbor_bottom) == menu.close_key(), "the last row's Down is the close key")


func case_refusals() -> void:
	await _build()
	var smarts := Upgrades.find_upgrade(&"sock_smarts")
	var sense := Upgrades.find_upgrade(&"sock_sense")
	var became := []
	_ups.affordable.connect(func(_p: int, u: Upgrade) -> void: became.append(u.id()))
	_set_coins(0)
	await _physics_ticks(30)
	_set_coins(200)
	await _until(func() -> bool: return became.has(&"sock_smarts"), "Sock Smarts to become affordable")
	_check(not became.has(&"sock_sense") and not became.has(&"xray"), "a locked or unbuilt one never does (%s)" % [became])
	var menu := await _open_at_tree()
	var sense_button := menu.button(&"sock_sense")
	_check(sense_button.lock_shown() and sense_button.state == UpgradeButton.OFF, "Sock Sense is greyed under its lock")
	await _hover(sense_button.key)
	_check(menu.tip().lines().has("Needs: Sock Smarts"), "the tip card says \"Needs: Sock Smarts\" (%s)" % [menu.tip().lines()])
	await _click(sense_button.key)
	_check(_player.message() == "Locked" and sense_button.shakes == 1, "refused \"Locked\" (%s)" % _player.message())
	await _click(menu.button(&"sock_smarts").key)
	await _frames(2)
	_check(not sense_button.lock_shown(), "once Sock Smarts is bought, Sock Sense's lock goes")
	_set_coins(50)
	await _frames(2)
	_check(sense_button.price_look() == &"PriceShort", "dearer than the funds its price shows short")
	await _click(sense_button.key)
	_check(_player.message() == "Need Coins 120", "refused \"Need Coins 120\" (%s)" % _player.message())
	# Coins still flying are not spendable (Q2672).
	_parts.apply(_bank.grant(_bank.paid_patch(1, 100)))
	var ev := _parts.answer(Command.new(Upgrades.BUY, 1, _ups.id, {"upgrade": "sock_sense"}))
	_check(not ev["ok"] and ev["reason"] == Upgrades.POOR, "with 150 Coins of which 100 fly, Sock Sense is still too dear")
	_bank.clock += 10.0
	_parts.apply(_parts.answer(Command.new(Upgrades.BUY, 1, _ups.id, {"upgrade": "sock_sense"})))
	_check(_ups.level(sense, 1) == 1 and _bank.of_player(1) == 30, "landed, it is bought (%d left)" % _bank.of_player(1))
	_check(_player.upgrades.sense(), "Sock Sense turns the aimed Sock's readout on")
	# A House Upgrade costs the team's Drawers.
	var bag := Upgrades.find_upgrade(&"elevator_repair")
	bag.stat = UpgradeStat.new()  # a stand-in stat for this check: its feature is batch C's
	_parts.apply(_bank.grant(_bank.drawers_patch(2)))
	_parts.apply(_parts.answer(Command.new(Upgrades.BUY, 1, _ups.id, {"upgrade": "elevator_repair"})))
	bag.stat = null
	_check(_ups.level(bag, 1) == 1 and _bank.drawers == 1 and _bank.of_player(1) == 30, "a House Upgrade takes the team's Drawers (%d) and no Coins" % _bank.drawers)
	_check(int(_ups.house.get("elevator_repair", 0)) == 1 and _ups.level(smarts, 1) == 1, "House levels are the team's")


func case_coop_only() -> void:
	await _build()
	_set_coins(1000)
	var menu := await _open_at_tree()
	for id in CO_OP_ONLY:
		_check(menu.button(id) == null, "%s is hidden in Solo" % id)
	var ev := _parts.answer(Command.new(Upgrades.BUY, 1, _ups.id, {"upgrade": "sole_mates"}))
	_check(not ev["ok"] and _ups.says(String(ev["reason"]), null, 0) == "Co-op only", "a purchase of one is refused \"Co-op only\"")
	menu.close()
	await _frames(1)
	(_station.get_node("Coop/UpgradesSwitch") as UpgradesSwitch).use(1)
	_check(_ups.coop, "the Co-op switch counts the zoo as co-op")
	menu = await _open_at_tree()
	for id in CO_OP_ONLY:
		_check(menu.button(id) != null, "%s shows with the switch on" % id)
	(_station.get_node("ResetLevels/UpgradesSwitch") as UpgradesSwitch).use(1)
	_check(_ups.personal.is_empty() and _ups.house.is_empty(), "Reset levels empties every level")


# --- Co-op ---------------------------------------------------------------------------------------

func case_coop_guest() -> void:
	wait_floor_s = NET_WAIT_S
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hr := LevelRuntime.of(host)
	var gr := LevelRuntime.of(guest)
	var hu := Upgrades.of(hr.bank)
	var gu := Upgrades.of(gr.bank)
	var mates := Upgrades.find_upgrade(&"sole_mates")
	var smarts := Upgrades.find_upgrade(&"sock_smarts")
	_check(not hu.shown(mates), "alone and not hosting, Sole Mates is hidden")
	_check(hr.net.start(["--host", "--profile=%s" % TAGS[0]]) == OK, "the zoo hosts")
	await _until(func() -> bool: return hr.roster.peers().size() == 1, "the Host to be in its Roster")
	_check(hu.shown(mates), "a Host before anyone joins shows the co-op-only Upgrades (Q1399)")
	hr.parts.apply(hr.parts.answer(Command.new(Upgrades.SET_LEVEL, Parts.HOST, hu.id, {"upgrade": "elevator_repair", "level": 1})))
	_check(gr.net.start(["--join=127.0.0.1:%d" % hr.session.port, "--profile=%s" % TAGS[1]]) == OK, "the Guest joins")
	await _until(func() -> bool: return hr.roster.peers().size() == 2, "the Guest to be in", 900, 0.1)
	var gpeer := hr.roster.peers()[1]
	var gpid := hr.roster.id_of(gpeer)
	await _until(func() -> bool: return int(gu.house.get("elevator_repair", 0)) == 1, "the Guest to get the House levels", 900, 0.1)
	await _until(func() -> bool: return hr.bank.coins.has(gpid), "the Host to welcome the Guest", 900, 0.1)
	hr.parts.apply(hr.bank.grant({"coins": {hr.bank.key_of(1): 0, gpid: 40}}))
	await _until(func() -> bool: return gr.bank.of_player(gr.session.me()) == 40, "the Guest's Bank to read 40", 900, 0.1)
	gu.ask_buy(smarts, gr.session.me())
	_check(gu.level(smarts, gr.session.me()) == 0, "the Guest's own machine writes nothing before the Host answers")
	await _until(func() -> bool: return hu.level(smarts, gpeer) == 1, "the Host to decide the Guest's purchase", 900, 0.1)
	_check(hr.bank.of_player(gpeer) == 10 and hu.level(smarts, Parts.HOST) == 0, "the Guest paid 30 of their own Coins; the Host's level is untouched (%d)" % hr.bank.of_player(gpeer))
	_check((hu.personal.get(gpid, {}) as Dictionary).get("sock_smarts", 0) == 1, "kept under the Guest's player id")
	await _until(func() -> bool: return gu.level(smarts, gr.session.me()) == 1, "the Guest's machine to read the level", 900, 0.1)
	await _until(func() -> bool: return hr.player.hud().message_text().ends_with("bought Sock Smarts"), "the Host to read the teammate line", 900, 0.1)
	_check(gr.player.hud().message_text() == "" or not gr.player.hud().message_text().ends_with("bought Sock Smarts"), "the buyer reads no teammate line")
	# A save keeps the levels by player id; a load brings them back.
	var saved := _roundtrip(hr.parts.save_snapshot())
	var versions := hr.parts.save_versions()
	_check((saved[String(hu.id)] as Dictionary).keys() == ["personal", "house"], "a save keeps the levels, not the zoo's switch")
	hr.parts.apply(hu.grant({"personal": {}, "house": {}}))
	hr.parts.load_save(saved, versions, hr.roster.id_of(Parts.HOST))
	_check(hu.level(smarts, gpeer) == 1 and int(hu.house.get("elevator_repair", 0)) == 1, "a load keeps the Guest's and the team's levels")


# --- The data ------------------------------------------------------------------------------------

func case_data() -> void:
	var all := Upgrades.listed()
	var personal := all.filter(func(u: Upgrade) -> bool: return not u.is_house())
	_check(all.size() == 27 and personal.size() == 16, "27 Upgrades, 16 Personal (%d, %d)" % [all.size(), personal.size()])
	var footwork := Upgrades.find_upgrade(&"footwork")
	_check(footwork.prices == PackedInt32Array([40, 60, 90, 135]) and footwork.cell == Vector2i(0, 0), "Footwork: the old prices and cell")
	_check(Upgrades.find_upgrade(&"sprint").full_title() == "Sprint (hold Shift)", "Sprint's title names its key")
	_check(Upgrades.find_upgrade(&"xray").full_title() == "X-ray: Show pair (key 1)", "X-ray's title names its key")
	var sense := Upgrades.find_upgrade(&"sock_sense")
	_check(sense.needs.size() == 1 and sense.needs.keys()[0] == Upgrades.find_upgrade(&"sock_smarts"), "Sock Sense needs Sock Smarts")
	for u in all:
		var built := u.id() in [&"sock_smarts", &"sock_sense", &"footwork", &"sprint", &"quick_grab", &"big_hands", &"long_arm", &"quick_charge",
				&"sole_mates", &"sole_hands", &"mate_radar"]
		_check((u.stat != null) == built, "%s %s" % [u.id(), "has its stat" if built else "is Coming soon"])
		_check(u.icon != null and u.title != "" and u.top() > 0, "%s has its icon, title and prices" % u.id())
		_check(u.coop_only == CO_OP_ONLY.has(u.id()), "%s co-op only as the old" % u.id())
	var stat := UpgradeStat.new()
	stat.kind = UpgradeStat.Kind.SCALE_DOWN
	stat.base = 1.2
	stat.step = 0.25
	stat.least = 0.1
	_check(is_equal_approx(stat.value_at(2), 0.6) and is_equal_approx(stat.value_at(8), 0.12), "SCALE_DOWN keeps its least share")
	var t := load("res://game/ui/upgrade_menu/upgrade_menu_tuning.tres") as UpgradeMenuTuning
	_check(t.cell == 92.0 and t.gap == 8 and t.tip_width == 360.0, "the menu's old sizes")


func case_house_total() -> void:
	var plan := load(PLAN) as StagePlan
	var designs := load(DESIGNS) as DesignCatalogue
	var house := (load(HOUSE) as PackedScene).instantiate()
	var pays := 0
	for cabinet: Cabinet in _cabinets(house, []):
		var stage := plan.stages[clampi(cabinet.unlock_stage - 1, 0, plan.stages.size() - 1)]
		pays += designs.count_of(cabinet.collection) / plan.pairs_per_drawer * stage.drawer_payout
	house.free()
	var total := 0
	for u in Upgrades.listed():
		if u.is_house():
			for p in u.prices:
				total += p
				_check(p >= 1, "%s's prices are at least 1" % u.id())
	_check(absf(total - 0.9 * pays) <= 2.0, "the House prices total %d, within 2 of 0.9 x the %d Drawers the house pays" % [total, pays])


func case_house_menu() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	await _until(rt.loading.is_lifted, "the house's Socks to be laid", 900, LAYING_S)
	_player = rt.player
	_player.capture_mouse()
	var tree := _level.get_node("Furniture/OldTree") as Node3D
	var menu := tree.get_node("UpgradeMenu") as UpgradeMenu
	var aim := tree.to_global(Vector3(-0.31, 1.0, -0.12))
	var stand := tree.to_global(Vector3(-0.31, 0.0, 0.75))
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	# Where the floor and the tree's player body let it stand, then the aim from there.
	await _until(func() -> bool: return _player.is_on_floor() and _player.velocity.length() < 0.01, "the player to settle by the tree")
	await _aim(aim)
	var ray := _player.get("_aim") as RayCast3D
	await _until(func() -> bool: return _player.aimed_part() is OldTree, "the crosshair to rest on the Old Tree (on %s)" % [ray.get_collider()], 60)
	await _physics_ticks(2)
	_check(_player.aimed_outline != null and _player.aimed_outline.shown and _player.aimed_outline.get_parent() == tree, "the tree is outlined (%s)" % _player.aimed_outline)
	await _press(&"interact")
	await _until(menu.is_open, "E to open the Upgrade menu")
	_check(menu.button(&"footwork") != null and menu.button(&"sole_mates") == null, "the house's menu shows the Personal Upgrades and hides the co-op-only ones in Solo")
	menu.close()


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
	_free_level()
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
	_station = (load(ECONOMY) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_TREE
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_bank = _station.get_node("Socks/Bank") as Bank
	_ups = _station.get_node("Socks/Upgrades") as Upgrades
	await _until(func() -> bool: return _player.is_on_floor() and _parts.is_bound, "the player to stand and the parts to bind")


func _free_level() -> void:
	if _level != null:
		var menu := _level.find_child("UpgradeMenu", true, false) as UpgradeMenu
		if menu != null:
			menu.close()
		_level.free()
		_level = null


## The player's Coins, landed (nothing flying).
func _set_coins(n: int) -> void:
	_parts.apply(_bank.grant({"coins": {_bank.key_of(1): n}, "recent": {}}))


## Stands before the station's Old Tree, aims at it and presses E: the menu it opens.
func _open_at_tree() -> UpgradeMenu:
	_player.global_position = _station.to_global(BY_TREE)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await _aim(_station.to_global(TREE_AIM))
	await _until(func() -> bool: return _player.aimed_part() is OldTree, "the crosshair to rest on the Old Tree")
	_check(_player.hud().prompt_text().contains(OldTree.TITLE), "the prompt names the Old Tree (%s)" % _player.hud().prompt_text())
	await _press(&"interact")
	var menu := _station.get_node("OldTree/UpgradeMenu") as UpgradeMenu
	await _until(menu.is_open, "E to open the Upgrade menu")
	_check(_player.input_blocked() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "the menu freezes the player and frees the mouse")
	await _frames(2)
	return menu


func _counters() -> MoneyCounters:
	return _player.hud().get_node("MoneyCounters") as MoneyCounters


func _aim(target: Vector3) -> void:
	var head := _player.get_node("Head") as Node3D
	var to := target - _player.global_position
	_player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## A left click on `control`, pushed into its viewport as the player's mouse would.
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


## The mouse comes over `control`.
func _hover(control: Control) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = control.get_global_rect().get_center()
	ev.global_position = ev.position
	control.get_viewport().push_input(ev, true)
	await _frames(2)


func _cabinets(node: Node, into: Array) -> Array:
	if node is Cabinet:
		into.append(node)
	for child in node.get_children():
		_cabinets(child, into)
	return into


# --- Zoos holding only the Economy station (economy_test's way) ----------------------------------

func _branch(label: String) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in zoo.get_node("Stations").get_children():
		if String(station.name) != "Economy":
			station.get_parent().remove_child(station)
			station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var zoo := node.get_node_or_null("View/Zoo")
		var runtime := LevelRuntime.of(zoo) if zoo != null else null
		if runtime != null and runtime.session != null:
			runtime.session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
	for tag: String in TAGS:
		var path := PlayerProfile.file_of(tag)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
