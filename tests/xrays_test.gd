## core/182, the X-rays' owning, keys, clock and Upgrades (docs/architecture/x-rays.md "The shape", draft
## 152-A; behaviour list docs/migration/m4-lists/10-x-rays.md "Owning and using", "Show pair" line 3 and
## line 4's rule, "Show drawer" line 3 and line 4's rule, "The Upgrades", "Words"): the zoo with only its
## X-rays station, the game's player a Host of one. Keys 1 and 2 are physical key presses pushed into the
## game's input; the Socks are picked with the left button (the `pick` action). Plus a save and a load of
## the house while an X-ray cools down.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const HOUSE := "res://game/house/house.tscn"
const KEEP := ["XRays"]
const STATION := "Stations/XRays"
## The stand-in Teammate holding the mate of the Third Sock.
const TEAMMATE := 11
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"xray_show", &"cabinet_xray_show"]

var _holder_node: Node = null
var _zoo: Node3D = null
var _level: Node = null
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "core/182 real path: in the X-rays station with the X-ray owned, a left click picks the loose Sock whose mate lies behind the wall; key 1 through XRay._unhandled_input: the HUD reads \"Sock X-ray on\" and xray_on plays (Owning and using lines 1, 2)"},
		{"name": "clock", "method": "case_clock", "world": false,
				"title": "core/182 Owning and using lines 2, 4: not usable while on; at the show's end (a test-only duration) xray_off plays and the cooldown runs for its stat; a press while cooling down does nothing and plays nothing; its end with a Sock held makes it ready (became_ready)"},
		{"name": "refusals", "method": "case_refusals", "world": false,
				"title": "core/182 Owning and using lines 3, 4, Show pair line 3, Show drawer line 3: not owned, key 1 reads \"X-ray not bought\" with refuse; holding a Pair key 1 does nothing and spends no cooldown, key 2 (owned) reads \"Cabinet X-ray on\"; with empty Hands neither does anything"},
		{"name": "targets", "method": "case_targets", "world": false,
				"title": "core/182 Show pair line 4's rule, Show drawer line 4's rule: the targets are the active Sock's mate (behind the wall, under the Heap, in the Teammate's Hands); All-Hands X-ray holds the mates of every loose Sock held, each Design once; Show Cabinet takes the Cabinet of the held Collection, the sheeted locked one too; All-Hands Cabinet X-ray each held Collection's once"},
		{"name": "upgrades", "method": "case_upgrades", "world": false,
				"title": "core/182 The Upgrades: Recharge level 2 makes the X-ray's cooldown 30 s, Lingering level 1 its show 15 s, the Cabinet X-ray's alike from 30 s and 10 s; the station's switches own, level up and reset each of the eight; the board's rows show the numbers as \"%.0fs\""},
		{"name": "load_starts_ready", "method": "case_load_starts_ready", "world": false,
				"title": "core/182 Owning and using line 5: a save of the house while the X-ray cools down, loaded: the X-ray is owned again (the Upgrades' levels) and starts ready (its clock is not saved)"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _holder_node != null:
		_holder_node.free()
		_holder_node = null
	if _level != null:
		LevelRuntime.of(_level).session.close()
		_level.free()
		_level = null
	_heard.clear()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	_own(&"xray", 1)
	var player := _player()
	var x := _xray(&"xray_show")
	var sock := _spot_sock("Loose")
	var mate := _spot_sock("Behind")
	await _pick(sock)
	_check(x.targets() == [mate], "the mate behind the wall is its target (%s)" % [x.targets()])
	_check(x.usable() and x.state() == XRay.State.READY, "owned with a loose Sock held, it is usable")
	_heard.clear()
	await _key(KEY_1)
	await _until(func() -> bool: return player.hud().message_text() == "Sock X-ray on", "the HUD to read \"Sock X-ray on\" (%s)" % player.hud().message_text(), 10)
	_check(player.message() == "", "it is not a refusal")
	_check(_heard_flat(&"xray_on") and not _heard_flat(&"refuse"), "xray_on plays for the player, flat (%s)" % [_heard])
	_check(x.is_on() and x.state() == XRay.State.ON, "the X-ray is on")
	_near(x.show_left(), 10.0, 0.2, "it shows for the 10 s of the duration stat")


func case_clock() -> void:
	await _build()
	_own(&"xray", 1)
	var x := _xray(&"xray_show")
	_short_clock(x, 0.4, 0.8)
	var ready := [0]
	x.became_ready.connect(func() -> void: ready[0] += 1)
	await _pick(_spot_sock("Loose"))
	await _key(KEY_1)
	await _until(x.is_on, "key 1 to turn it on", 10)
	_check(not x.usable(), "line 4: not usable while on")
	_heard.clear()
	await _key(KEY_1)
	_check(not _heard_flat(&"xray_on") and not _heard_flat(&"refuse"), "a press while on plays nothing (%s)" % [_heard])
	await _until(func() -> bool: return not x.is_on(), "the show to end", 60)
	_check(_heard_flat(&"xray_off"), "line 2: xray_off plays at the show's end (%s)" % [_heard])
	_check(x.is_cooling() and x.state() == XRay.State.COOLDOWN, "the cooldown runs")
	_near((x.get_node("Cooldown") as Timer).wait_time, 0.8, 0.001, "for the cooldown stat's time")
	_heard.clear()
	var said := _player().hud().message_text()
	await _key(KEY_1)
	_check(_heard.is_empty(), "line 4: a press while cooling down plays nothing (%s)" % [_heard])
	_check(not x.is_on() and x.is_cooling(), "and spends nothing: still cooling, not on")
	_check(_player().hud().message_text() == said, "and says nothing new")
	await _until(func() -> bool: return not x.is_cooling(), "the cooldown to end", 90)
	_check(ready[0] == 1 and x.usable(), "Q1988: with a Sock held it is ready again, once (%d)" % ready[0])


func case_refusals() -> void:
	await _build()
	var player := _player()
	var x := _xray(&"xray_show")
	var cx := _xray(&"cabinet_xray_show")
	# Empty Hands, nothing owned: the refusal names the Upgrade.
	_heard.clear()
	await _key(KEY_1)
	_check(player.message() == "X-ray not bought", "line 3: not owned, key 1 reads \"X-ray not bought\" (%s)" % player.message())
	_check(_heard_flat(&"refuse") and not _heard_flat(&"xray_on"), "with refuse (%s)" % [_heard])
	_check(x.state() == XRay.State.HIDDEN, "its icon is hidden before the Upgrade")
	await _key(KEY_2)
	_check(player.message() == "Cabinet X-ray not bought", "key 2 reads \"Cabinet X-ray not bought\" (%s)" % player.message())
	# Owned, empty Hands: nothing at all.
	_own(&"xray", 1)
	_own(&"cabinet_xray", 1)
	player.hud().hide_message()
	_heard.clear()
	await _key(KEY_1)
	await _key(KEY_2)
	_check(_heard.is_empty() and player.hud().message_text() == "", "line 4: with empty Hands neither does anything (%s, %s)" % [_heard, player.hud().message_text()])
	_check(not x.is_on() and not x.is_cooling() and not cx.is_on() and not cx.is_cooling(), "and neither spends its cooldown")
	_check(x.state() == XRay.State.GREYED and cx.state() == XRay.State.GREYED, "both read greyed")
	# Holding a Pair.
	var lead := _spot_sock("PairA")
	await _pick(lead)
	await _pick(_spot_sock("PairB"))
	_check(_mess().is_pair(lead) and _hands().active_of(1) == lead, "a Pair is the active item")
	_heard.clear()
	var said := player.hud().message_text()
	await _key(KEY_1)
	_check(_heard.is_empty() and player.hud().message_text() == said, "Show pair line 3: holding a Pair key 1 does nothing (%s, %s)" % [_heard, player.hud().message_text()])
	_check(not x.is_on() and not x.is_cooling(), "and spends no cooldown")
	_check(x.shown_items().is_empty() and x.targets().is_empty(), "a Pair shows nothing")
	await _key(KEY_2)
	await _until(func() -> bool: return player.hud().message_text() == "Cabinet X-ray on", "key 2 to read \"Cabinet X-ray on\" (%s)" % player.hud().message_text(), 10)
	_check(_heard_flat(&"xray_on") and cx.is_on(), "xray_on plays and the Cabinet X-ray is on (%s)" % [_heard])
	_check(cx.targets() == [_cabinet("CabinetSimple")], "the Pair's Cabinet is its target (%s)" % [cx.targets()])


func case_targets() -> void:
	await _build()
	_own(&"xray", 1)
	_own(&"cabinet_xray", 1)
	var x := _xray(&"xray_show")
	var cx := _xray(&"cabinet_xray_show")
	await _until(func() -> bool: return _hands().items_of(TEAMMATE).size() == 1, "the Teammate to hold its Sock", 120)
	await _pick(_spot_sock("Third"))
	_check(x.targets() == [_spot_sock("Held")], "the mate in the Teammate's Hands (%s)" % [x.targets()])
	await _pick(_spot_sock("Loose"))
	_check(x.targets() == [_spot_sock("Behind")], "the active Sock's mate behind the wall, not the other's (%s)" % [x.targets()])
	await _pick(_spot_sock("Second"))
	_check(x.targets() == [_spot_sock("UnderHeap")], "the mate under the Heap (%s)" % [x.targets()])
	_own(&"all_hands_xray", 1)
	var all := x.targets()
	all.sort()
	var want := [_spot_sock("Behind"), _spot_sock("UnderHeap"), _spot_sock("Held")]
	want.sort()
	_check(all == want, "All-Hands X-ray: the mates of every loose Sock held, each Design once (%s)" % [all])
	_check(cx.targets() == [_cabinet("CabinetSimple")], "Show Cabinet: the held Collection's Cabinet (%s)" % [cx.targets()])
	_own(&"all_hands_cabinet_xray", 1)
	_check(cx.targets() == [_cabinet("CabinetSimple")], "All-Hands Cabinet X-ray: three Socks of one Collection, its Cabinet once (%s)" % [cx.targets()])
	# A fresh zoo: the Patterns Sock and the sheeted, locked Cabinet.
	_holder_node.free()
	_holder_node = null
	await _build()
	_own(&"xray", 1)
	_own(&"cabinet_xray", 1)
	x = _xray(&"xray_show")
	cx = _xray(&"cabinet_xray_show")
	await _pick(_spot_sock("Dots"))
	_check(cx.targets() == [_cabinet("CabinetPatterns")], "the sheeted, locked Cabinet takes the Patterns Sock (%s)" % [cx.targets()])
	_check(x.targets() == [_spot_sock("DotsMate")], "and Show pair its mate (%s)" % [x.targets()])
	await _pick(_spot_sock("PairA"))
	await _pick(_spot_sock("PairB"))
	_check(cx.targets() == [_cabinet("CabinetSimple")], "the active Pair's Cabinet only (%s)" % [cx.targets()])
	_own(&"all_hands_cabinet_xray", 1)
	var cabs := cx.targets()
	_check(cabs.size() == 2 and cabs.has(_cabinet("CabinetSimple")) and cabs.has(_cabinet("CabinetPatterns")), "All-Hands Cabinet X-ray: the Cabinet of every Sock and Pair held, each once (%s)" % [cabs])
	_own(&"all_hands_xray", 1)
	_check(x.targets() == [_spot_sock("DotsMate")], "All-Hands X-ray leaves the Pair out (%s)" % [x.targets()])


func case_upgrades() -> void:
	await _build()
	var x := _xray(&"xray_show")
	var cx := _xray(&"cabinet_xray_show")
	_own(&"xray", 1)
	_own(&"cabinet_xray", 1)
	_near(x.cooldown_seconds(), 50.0, 0.001, "the X-ray cools down 50 s")
	_near(x.show_seconds(), 10.0, 0.001, "and shows 10 s")
	_near(cx.cooldown_seconds(), 30.0, 0.001, "the Cabinet X-ray cools down 30 s")
	_own(&"xray_recharge", 2)
	_own(&"xray_linger", 1)
	_own(&"cabinet_xray_recharge", 1)
	_own(&"cabinet_xray_linger", 2)
	await _pick(_spot_sock("Loose"))
	await _key(KEY_1)
	await _until(x.is_on, "key 1 to turn it on", 10)
	_near((x.get_node("Show") as Timer).wait_time, 15.0, 0.001, "Lingering level 1: the show 15 s")
	(x.get_node("Show") as Timer).start(0.05)
	await _until(x.is_cooling, "the show to end", 20)
	_near((x.get_node("Cooldown") as Timer).wait_time, 30.0, 0.001, "Recharge level 2: the cooldown 30 s")
	_near(cx.cooldown_seconds(), 24.0, 0.001, "Cabinet Recharge level 1: 24 s")
	_near(cx.show_seconds(), 20.0, 0.001, "Cabinet Lingering level 2: 20 s")
	# The station's switches: one per X-ray Upgrade, built from the data; each use levels it up, then resets it.
	var switches := _zoo.get_node(STATION + "/Switches")
	var found := 0
	for s in switches.get_children():
		found += 1 if s.get_node_or_null("XRayUpgradeSwitch") is XRayUpgradeSwitch else 0
	_check(found == 8, "a switch per X-ray Upgrade (%d)" % found)
	var linger := switches.get_node("XrayLinger/XRayUpgradeSwitch") as XRayUpgradeSwitch
	_check(linger.prompt_title() == "Level up Lingering X-ray (1/2)", "the Linger switch levels it up (%s)" % linger.prompt_title())
	_player().global_position = linger.get_parent().global_position + Vector3(0.0, 0.0, 1.0)
	await _physics_ticks(2)
	linger.use(1)
	_check(_ups().level(Upgrades.find_upgrade(&"xray_linger"), 1) == 2, "a use raises it to its top")
	_check(linger.prompt_title().begins_with("Reset"), "at its top it reads Reset (%s)" % linger.prompt_title())
	linger.use(1)
	_check(_ups().level(Upgrades.find_upgrade(&"xray_linger"), 1) == 0, "and the next use resets it")
	var own := switches.get_node("AllHandsXray/XRayUpgradeSwitch") as XRayUpgradeSwitch
	_check(own.prompt_title().begins_with("Own"), "an Upgrade not owned reads Own (%s)" % own.prompt_title())
	# The board: a row per ability file, its numbers in the stats' format.
	var board := _zoo.get_node(STATION + "/Board") as XRayBoard
	await _frames(40)
	var rows := board.rows()
	_check(rows.size() == XRays.listed().size() and rows.size() == 2, "a row per ability file (%d)" % rows.size())
	var sock_text := rows[0].text.text
	_check(sock_text.contains("Show pair") and sock_text.contains("Sock X-ray on"), "the first row is Show pair's words (%s)" % sock_text)
	_check(sock_text.contains("xray_cooldown: 30s -> 30s") and sock_text.contains("xray_duration: 10s -> 20s"), "its numbers read \"%%.0fs\" (%s)" % sock_text)
	_check(rows[1].text.text.contains("Show Cabinet") and rows[1].text.text.contains("cabinet_xray_cooldown: 24s -> 18s"), "the second Show Cabinet's (%s)" % rows[1].text.text)
	_check(rows[0].key.texture != null and rows[0].icon.texture == Upgrades.find_upgrade(&"xray").icon, "each row shows its key cap and its Upgrade's icon")


func case_load_starts_ready() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate()
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	await _until(func() -> bool: return rt.loading.is_lifted() and rt.parts.is_bound and rt.player.is_on_floor() and rt.roster.id_of(1) != "",
			"the house to start", 3000)
	var ups := Upgrades.of(rt.hands)
	rt.parts.apply(rt.parts.answer(Command.new(Upgrades.SET_LEVEL, Parts.HOST, ups.id, {"upgrade": "xray", "level": 1, "player": 1})))
	var x := (rt.player.get_node("XRays") as XRays).of_action(&"xray_show")
	_check(x != null and x.owned(), "the house's player owns the X-ray")
	(x.get_node("Cooldown") as Timer).start(40.0)
	_check(x.is_cooling(), "the X-ray cools down")
	var saved := _roundtrip(rt.parts.save_snapshot())
	var versions := rt.parts.save_versions()
	_check(not JSON.stringify(saved).contains("Cooldown"), "a save keeps no X-ray clock")
	rt.parts.apply(ups.grant({"personal": {}, "house": {}}))
	_check(not x.owned(), "the levels cleared before the load")
	rt.parts.load_save(saved, versions, rt.roster.id_of(Parts.HOST))
	_check(x.owned(), "after the load the X-ray is still owned (the Upgrades' level)")
	_check(not x.is_cooling() and not x.is_on(), "and starts ready: no cooldown, not on")
	_check(x.state() in [XRay.State.READY, XRay.State.GREYED], "its icon reads ready or greyed (%d)" % x.state())


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
	_holder_node = Node.new()
	_holder_node.name = "Alone"
	add_child(_holder_node)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder_node.add_child(_zoo)
	_player().global_position = (_zoo.get_node(STATION) as Node3D).global_position + Vector3(0.0, 0.0, 3.0)
	await _until(func() -> bool: return _player().is_on_floor() and _parts().is_bound and _mess().looks_of(_spot_sock("Loose")) != null,
			"the zoo to stand and its Socks to lie", 300)
	_player().capture_mouse()


## Sets the player's level of Upgrade `id` (the Host's set_level, as the station's switches do).
func _own(id: StringName, level: int) -> void:
	_parts().apply(_parts().answer(Command.new(Upgrades.SET_LEVEL, Parts.HOST, _ups().id, {"upgrade": String(id), "level": level, "player": 1})))


## Gives `x` a copy of its ability with test-only duration and cooldown stats (seconds).
func _short_clock(x: XRay, show: float, cool: float) -> void:
	var a := x.ability.duplicate() as XRayAbility
	var d := UpgradeStat.new()
	d.base = show
	var c := UpgradeStat.new()
	c.base = cool
	a.duration = d
	a.cooldown = c
	x.ability = a


## A physical key pressed and let go, through the game's input.
func _key(code: Key) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.pressed = true
	Input.parse_input_event(key)
	await _physics_ticks(2)
	var up := key.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await _physics_ticks(1)


func _pick(sock: int) -> void:
	var at := _mess().box_of(sock).get_center()
	await _stand_facing(Vector3(at.x, 0.0, at.z + 1.0), at)
	await _until(func() -> bool: return _player().aimed_sock == sock, "the crosshair on Sock %d" % sock, 20)
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _until(func() -> bool: return _hands().items_of(1).has(sock) or _mess().state_of(sock) == Mess.State.IN_PAIR,
			"Sock %d to be picked" % sock, 60)
	await _physics_ticks(int(_player().hands_tuning.grab_interval * 60.0) + 2)


## Stands the player at `feet`, looking at `target`.
func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var head := player.get_node("Head") as Node3D
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _heard_flat(sound: StringName) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and not bool(e[1]):
			return true
	return false


func _xray(action: StringName) -> XRay:
	return (_player().get_node("XRays") as XRays).of_action(action)


func _spot_sock(spot: String) -> int:
	return (_zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _cabinet(node: String) -> Cabinet:
	return _zoo.get_node(STATION + "/" + node + "/Cabinet") as Cabinet


func _mess() -> Mess:
	return LevelRuntime.of(_zoo).mess


func _hands() -> Hands:
	return LevelRuntime.of(_zoo).hands


func _ups() -> Upgrades:
	return Upgrades.of(_hands())


func _parts() -> Parts:
	return LevelRuntime.of(_zoo).parts


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
