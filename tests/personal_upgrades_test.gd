## The Personal Upgrades take effect (core/130, docs/architecture/economy.md "The Personal effects"):
## Footwork, Sprint, Quick Grab, Big Hands, Long Arm and Quick Charge, each an UpgradeStat its feature
## reads through the level's Upgrades when it uses it. The real path buys Big Hands I by a click in the
## Economy station's menu and picks two loose Socks by the pick key; Sprint is held by its own action;
## the numbers are the old placeholders; a level without an Upgrades Part keeps its own tuning. The
## station cases play the station on a floor with the game's player and a Parts (a Host of one), as
## upgrades_test does. The co-op lines are coop_hands' guest_big_hands and refusals.
extends TestSuite

const ECONOMY := "res://game/zoo/stations/economy.tscn"
const HANDLING := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"interact", &"pick", &"move_forward", &"sprint", &"crouch"]
## Where the player stands before the station's Old Tree, and the point of the tree it aims at.
const BY_TREE := Vector3(4.7, 0.0, -1.2)
const TREE_AIM := Vector3(4.69, 1.0, -2.55)
## Open floor past the station's front, where a walk meets nothing.
const OPEN := Vector3(0.0, 0.0, 8.0)
## The six Upgrades and the stat each names.
const SIX := {&"footwork": &"walk_speed", &"sprint": &"sprint", &"quick_grab": &"grab_interval",
		&"big_hands": &"carry", &"long_arm": &"throw_speed", &"quick_charge": &"charge_time"}

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _parts: Parts = null
var _bank: Bank = null
var _ups: Upgrades = null
var _mess: Mess = null
var _hands: Hands = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Economy station the player buys Sock Smarts and Big Hands I by clicks in the Old Tree's menu, shuts it, presses pick on two loose Socks of two Designs: both are in the Hands, the readout \"2/2\""},
		{"name": "sprint", "method": "case_sprint", "world": false,
				"title": "before Sprint is bought, holding Sprint walks at the walk's pace and the corner has no Sprint; bought, it walks 1.3 times faster and the corner shows \"Sprint\" with the Shift key; crouching cancels it"},
		{"name": "stats", "method": "case_stats", "world": false,
				"title": "the six stats hold the old numbers and are read when used: Footwork's walk x1.05 a level, Quick Grab's pick gap 0.35 s down 8 % a level, Big Hands 1 to 5, Long Arm's full Throw 5 m/s +4 a level, Quick Charge's charge 1.2 s down 25 % a level"},
		{"name": "no_upgrades", "method": "case_no_upgrades", "world": false,
				"title": "a level without an Upgrades Part keeps its own tuning: the player's HandsTuning holds, the walk has no factor and Sprint does nothing"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_level()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build(ECONOMY)
	var smarts := Upgrades.find_upgrade(&"sock_smarts")
	var big := Upgrades.find_upgrade(&"big_hands")
	_set_coins(smarts.prices[0] + big.prices[0])
	_check(_hands.tuning_of(1).capacity == 1, "before Big Hands the Hands hold one (%d)" % _hands.tuning_of(1).capacity)
	var menu := await _open_at_tree()
	await _click(menu.button(&"sock_smarts").key)
	var button := menu.button(&"big_hands")
	_check(button.price_text() == str(big.prices[0]), "Big Hands is buyable at %d (%s)" % [big.prices[0], button.price_text()])
	await _click(button.key)
	_check(_ups.level(big, 1) == 1 and button.level_text() == "1/4", "the Host decided Big Hands I (%s)" % button.level_text())
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await _until(func() -> bool: return not menu.is_open() and not _player.input_blocked(), "Esc to shut the menu")
	_player.capture_mouse()
	await _until(func() -> bool: return _lying().size() >= 2, "two loose Socks to lie")
	var first := await _pick_by_key([])
	_check(first >= 0, "the first Sock is picked by the pick key")
	await _physics_ticks(int(_hands.tuning_of(1).grab_interval * 60.0) + 2)
	var second := await _pick_by_key([_mess.designs[first]])
	_check(second >= 0, "the second Sock, of another Design, is picked by the pick key")
	var items := _hands.items_of(1)
	_check(items.size() == 2 and items.has(first) and items.has(second), "both are in the Hands (%s)" % [items])
	await _until(func() -> bool: return _player.hud().hands_text().contains("2/2"), "the readout to say 2/2")


# --- Sprint --------------------------------------------------------------------------------------

func case_sprint() -> void:
	await _build(ECONOMY)
	var walk := _player.tuning.walk_speed
	var plain := await _pace(false)
	_near(plain, walk, 0.01, "the walk's pace with nothing bought")
	var held := await _pace(true)
	_near(held, walk, 0.01, "holding Sprint does nothing before it is bought")
	_check(not _player.hud().hints_text().contains(Prompts.SPRINT), "the corner has no Sprint (%s)" % _player.hud().hints_text())
	_level_to(&"sprint", 1)
	var ran := await _pace(true)
	_near(ran, walk * _player.tuning.sprint_multiplier, 0.01, "bought, holding Sprint walks %.2f times faster" % _player.tuning.sprint_multiplier)
	_near(_player.tuning.sprint_multiplier, 1.3, 0.0001, "the multiplier is the old 1.3")
	await _physics_ticks(2)
	var hints := _player.hud().hints_text()
	var cap := Prompt.cap_text(Prompts.keys(Player.SPRINT)[0]) if not Prompts.keys(Player.SPRINT).is_empty() else "?"
	_check(hints.contains("%s %s" % [cap, Prompts.SPRINT]) and cap.to_lower().contains("shift"), "the corner shows Sprint with Shift (%s)" % hints)
	_check(hints.find(Prompts.SPRINT) < hints.find(Prompts.JUMP), "Sprint stands before Jump, as the old")
	Input.action_press(&"crouch")
	await _until(func() -> bool: return _player.crouching, "the player to crouch")
	var crept := await _pace(true)
	_near(crept, walk * _player.tuning.crouch_speed_factor, 0.01, "crouching cancels the sprint")
	Input.action_release(&"crouch")
	_level_to(&"footwork", 4)
	await _until(func() -> bool: return not _player.crouching, "the player to stand")
	var quick := await _pace(true)
	_near(quick, walk * 1.2 * _player.tuning.sprint_multiplier, 0.01, "Footwork IV and Sprint multiply")


# --- The numbers ---------------------------------------------------------------------------------

func case_stats() -> void:
	await _build(ECONOMY)
	for uid: StringName in SIX:
		var u := Upgrades.find_upgrade(uid)
		_check(u != null and u.stat != null and u.stat.resource_path.get_file().get_basename() == String(SIX[uid]),
				"%s names its stat %s" % [uid, SIX[uid]])
	var top := {&"footwork": 4, &"sprint": 1, &"quick_grab": 4, &"big_hands": 4, &"long_arm": 3, &"quick_charge": 2}
	for uid: StringName in top:
		_check(Upgrades.find_upgrade(uid).top() == int(top[uid]), "%s has %d levels" % [uid, top[uid]])
	var want := {&"walk_speed": [UpgradeStat.Kind.SCALE_UP, 1.0, 0.05], &"sprint": [UpgradeStat.Kind.FLAG, 0.0, 0.0],
			&"grab_interval": [UpgradeStat.Kind.SCALE_DOWN, 0.35, 0.08], &"carry": [UpgradeStat.Kind.ADD, 1.0, 1.0],
			&"throw_speed": [UpgradeStat.Kind.ADD, 5.0, 4.0], &"charge_time": [UpgradeStat.Kind.SCALE_DOWN, 1.2, 0.25]}
	for uid: StringName in SIX:
		var st := Upgrades.find_upgrade(uid).stat
		var w: Array = want[SIX[uid]]
		_check(st.kind == int(w[0]) and is_equal_approx(st.base, float(w[1])) and is_equal_approx(st.step, float(w[2])),
				"%s: the old kind, base and step (%d, %.2f, %.2f)" % [SIX[uid], st.kind, st.base, st.step])
	_near(Upgrades.find_upgrade(&"quick_charge").stat.least, 0.1, 0.0001, "Quick Charge keeps at least a tenth")
	# The house's HandsTuning holds the stats' bases: where the levels start.
	var t := _hands.tuning_of(1)
	_check(t.capacity == 1, "Big Hands' base: one (%d)" % t.capacity)
	_near(t.grab_interval, 0.35, 0.0001, "Quick Grab's base: 0.35 s")
	_near(t.max_speed, 5.0, 0.0001, "Long Arm's base: 5 m/s")
	_near(t.charge_time, 1.2, 0.0001, "Quick Charge's base: 1.2 s")
	_near(_player.walk_factor(), 1.0, 0.0001, "Footwork's base: x1.00")
	_level_to(&"big_hands", 4)
	_level_to(&"quick_grab", 4)
	_level_to(&"long_arm", 3)
	_level_to(&"quick_charge", 2)
	_level_to(&"footwork", 4)
	t = _hands.tuning_of(1)
	_check(t.capacity == 5, "Big Hands IV: five (%d)" % t.capacity)
	_near(t.grab_interval, 0.35 * (1.0 - 4 * 0.08), 0.0001, "Quick Grab IV: 0.35 s less 32 %")
	_near(t.max_speed, 17.0, 0.0001, "Long Arm III: 17 m/s")
	_near(t.charge_time, 0.6, 0.0001, "Quick Charge II: 0.6 s")
	_near(_player.walk_factor(), 1.2, 0.0001, "Footwork IV: x1.20")
	_near(t.min_speed, _player.hands_tuning.min_speed, 0.0001, "the Throw's weak end stays (Q1344)")
	_check(Upgrades.find_upgrade(&"long_arm").stat.text_at(1) == "9 m/s" and Upgrades.find_upgrade(&"quick_charge").stat.text_at(1) == "0.90s",
			"the tip's numbers read the old formats (%s, %s)" % [Upgrades.find_upgrade(&"long_arm").stat.text_at(1), Upgrades.find_upgrade(&"quick_charge").stat.text_at(1)])
	# Read when used, never kept: a level set back is felt at once.
	_level_to(&"big_hands", 0)
	_check(_hands.tuning_of(1).capacity == 1, "Big Hands set back: one again")


# --- A level without Upgrades --------------------------------------------------------------------

func case_no_upgrades() -> void:
	await _build(HANDLING)
	_check(Upgrades.of(_hands) == null, "the Handling station alone has no Upgrades Part")
	var mine := _player.hands_tuning.duplicate() as HandsTuning
	mine.capacity = 3
	_player.hands_tuning = mine
	_check(_hands.tuning_of(1) == mine, "the Hands read the player's own HandsTuning")
	_near(_player.walk_factor(), 1.0, 0.0001, "no factor on the walk")
	_check(not _player.can_sprint(), "nobody sprints")
	var held := await _pace(true)
	_near(held, _player.tuning.walk_speed, 0.01, "holding Sprint walks at the walk's pace")


# --- Helpers -------------------------------------------------------------------------------------

func _build(scene: String) -> void:
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
	_station = (load(scene) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_TREE if scene == ECONOMY else OPEN
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_bank = _station.get_node_or_null("Socks/Bank") as Bank
	_ups = _station.get_node_or_null("Socks/Upgrades") as Upgrades
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
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


## The Host sets player 1's level of `upgrade` outright (the zoo's switches' verb).
func _level_to(upgrade: StringName, level: int) -> void:
	_parts.apply(_parts.answer(Command.new(Upgrades.SET_LEVEL, Parts.HOST, _ups.id, {"upgrade": String(upgrade), "level": level, "player": 1})))
	_check(_ups.level(Upgrades.find_upgrade(upgrade), 1) == level, "%s set to %d" % [upgrade, level])


## The player's pace along the floor while walking forward on open floor, holding Sprint when `sprint`.
func _pace(sprint: bool) -> float:
	_player.global_position = _station.to_global(OPEN)
	_player.rotation = Vector3(0.0, PI, 0.0)  # facing +z, away from the station
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await _physics_ticks(2)
	Input.action_press(&"move_forward")
	if sprint:
		Input.action_press(&"sprint")
	await _physics_ticks(4)
	var v := _player.velocity
	Input.action_release(&"move_forward")
	Input.action_release(&"sprint")
	await _physics_ticks(2)
	return Vector2(v.x, v.z).length()


## Stands before the station's Old Tree, aims at it and presses E: the menu it opens.
func _open_at_tree() -> UpgradeMenu:
	_player.global_position = _station.to_global(BY_TREE)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await _aim(_station.to_global(TREE_AIM))
	await _until(func() -> bool: return _player.aimed_part() is OldTree, "the crosshair to rest on the Old Tree")
	await _press(&"interact")
	var menu := _station.get_node("OldTree/UpgradeMenu") as UpgradeMenu
	await _until(menu.is_open, "E to open the Upgrade menu")
	await _frames(2)
	return menu


## The loose lying Socks not in the Hands.
func _lying() -> Array[int]:
	var out: Array[int] = []
	for sock in _mess.count():
		if _mess.state_of(sock) == Mess.State.LYING and not _mess.is_pair(sock):
			out.append(sock)
	return out


## Aims at a loose lying Sock whose Design is not in `skip` until the crosshair rests on it, and presses
## the pick key: the Sock once it is in the Hands, or -1 when none could be aimed at.
func _pick_by_key(skip: Array) -> int:
	for sock in _lying():
		if skip.has(_mess.designs[sock]):
			continue
		var at := _mess.box_of(sock).get_center()
		_player.global_position = Vector3(at.x, 0.0, at.z) + Vector3(0.0, 0.0, 1.0)
		_player.velocity = Vector3.ZERO
		_player.reset_physics_interpolation()
		await _aim(at)
		await _physics_ticks(3)
		if _player.aimed_sock != sock:
			continue
		await _press(&"pick")
		await _until(func() -> bool: return _hands.items_of(1).has(sock), "Sock %d to be in the Hands" % sock)
		return sock
	return -1


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
