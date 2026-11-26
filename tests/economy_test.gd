## Coins and Drawers (core/124, docs/architecture/economy.md): the Bank, the payouts and the HUD counters.
## The Economy station's small Cabinet (2 Pairs a drawer) for the real path, the drawer payout, the
## landed-only spending and the debug cheat; the Stages station's mini run for the two Stage bonuses
## (Q2667) and their counting up (Q2668); zoos holding only the Economy station for a Guest's welcome;
## the house for the counters on a New Game. The station cases play the station on a floor with the
## game's player and a Parts (a Host of one), as cabinet_test does.
extends TestSuite

const ECONOMY := "res://game/zoo/stations/economy.tscn"
const STAGES := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const HOUSE := "res://game/house/house.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## Where the player stands before the Economy Cabinet's drawers, in station space.
const BY_DRAWERS := Vector3(-2.0, 0.0, -0.9)
## The Stages station's Simple Pairs (each Sock and the next id are mates) and where its switches are.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const STAGES_START := Vector3(-1.6, 0.0, 1.2)
const NET_WAIT_S := 20.0
const LAYING_S := 20.0
const TAGS := ["economy_test_a", "economy_test_b"]

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _parts: Parts = null
var _mess: Mess = null
var _hands: Hands = null
var _bank: Bank = null
var _cabinet: Cabinet = null
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Economy station the player holding the Pair that fills a drawer presses the pick key on it; a Coins \"+N\" and a Drawers \"+1\" (80 px higher) pop over it and fly, and the HUD counters then read the new totals"},
		{"name": "short_row", "method": "case_short_row", "world": false,
				"title": "a drawer pays its Drawers only when it reaches the Pairs per Drawer, once; the Collection's short last Row never pays"},
		{"name": "floor_bonus", "method": "case_floor_bonus", "world": false,
				"title": "Q2667, Q2668: in the Stages station's mini run opening a floor pays every player 100 with no \"+N\": the Coins counter counts up after the delay, one landing at a time; the tallies count it"},
		{"name": "cabinet_bonus", "method": "case_cabinet_bonus", "world": false,
				"title": "Q2667: filling a Cabinet's current Rows pays the filler 50 the same way, once per Rows count; grown, its new Rows filled pay again; each filled drawer pays the team its Stage's Drawers"},
		{"name": "spendable", "method": "case_spendable", "world": false,
				"title": "Q2672: the Host's purchase check (the Bank's spendable Coins) refuses Coins still flying and allows them once landed; a load lands them at once"},
		{"name": "cheat", "method": "case_cheat", "world": false,
				"title": "Q292: F9 in a debug build gives the Host 1000 Coins with no flight, spendable at once, and the message \"Debug: +1000 Coins\""},
		{"name": "coop_welcome", "method": "case_coop_welcome", "world": false,
				"title": "Q1249: a Guest new to the World starts with the average of the present players' Coins, rounded down; a known id is not welcomed again; a Guest's F9 asks nothing"},
		{"name": "house_counters", "method": "case_house_counters", "world": false,
				"title": "in a house New Game the Coins and Drawers counters show at the HUD's top left, reading 0 and 0"},
		{"name": "drawer_payouts", "method": "case_drawer_payouts", "world": false,
				"title": "the house's Stages pay 1, 1, 2 and 3 Drawers a filled drawer; the economy's numbers are the old placeholders"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_level()
	_drop_branches()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build(ECONOMY)
	var counters := _counters()
	var flight := _flight()
	var pairs := _simple_pairs(2)
	_check(pairs.size() == 2, "the station's generator laid Simple Pairs (%s)" % [pairs])
	var pay: Array[int] = []
	for pair: Array in pairs:
		pay.append(_cabinet.tuning.pay_for(int(_mess.design_of(int(pair[0])).rarity)))
	# The first Pair goes in by the Cabinet's own click; its drawer then holds one of two.
	await _pair(pairs[0])
	_cabinet.click(1, 0)
	await _until(func() -> bool: return _cabinet.contents(0).size() == 1, "the first Pair to be shelved")
	await _until(func() -> bool: return flight.pending(counters.coins.currency) == 0, "the first Coins to land")
	await _frames(1)
	_check(counters.coins.amount() == pay[0] and counters.drawers.amount() == 0, "the counters read %d and 0 (%d, %d)" % [pay[0], counters.coins.amount(), counters.drawers.amount()])
	# Holding the Pair that fills the drawer, the player presses the pick key on it.
	await _pair(pairs[1])
	_stand(BY_DRAWERS)
	await _aim(_drawer_front(0))
	await _press(&"pick")
	await _until(func() -> bool: return _cabinet.contents(0).size() == 2, "the second Pair to fill the bottom drawer")
	_check(_bank.of_player(1) == pay[0] + pay[1] and _bank.drawers == 1, "the Bank decided %d Coins and 1 Drawer (%d, %d)" % [pay[0] + pay[1], _bank.of_player(1), _bank.drawers])
	await _until(func() -> bool: return flight.pop_texts().size() == 2, "the two \"+N\" to pop")
	var texts := flight.pop_texts()
	texts.sort()
	_check(flight.pop_texts() == ["+%d" % pay[1], "+1"], "a Coins \"+%d\" and a Drawers \"+1\" pop (%s)" % [pay[1], texts])
	var points := flight.pop_points()
	_near(absf(points[0].y - points[1].y), 80.0, 1.0, "the Drawers' \"+N\" pops 80 px above the Coins'")
	_check(counters.coins.amount() == pay[0] and counters.drawers.amount() == 0, "while they fly the counters hold the old totals (%d, %d)" % [counters.coins.amount(), counters.drawers.amount()])
	await _until(func() -> bool: return flight.flying() > 0, "the icons to burst and fly")
	await _until(func() -> bool: return flight.pending(counters.coins.currency) == 0 and flight.pending(counters.drawers.currency) == 0, "every icon to land", 300)
	await _frames(1)
	_check(counters.coins.amount() == pay[0] + pay[1] and counters.drawers.amount() == 1, "the HUD counters read the new totals (%d, %d)" % [counters.coins.amount(), counters.drawers.amount()])
	_check(PadRumble.last == PadRumble.DONE, "the pad gave its \"done\" buzz for the filled drawer")


func case_short_row() -> void:
	await _build(ECONOMY)
	_check(_cabinet.drawer_payout() == 1, "with no run a drawer pays 1")
	await _shelve_simple(0)
	_check(_bank.drawers == 0, "a drawer holding 1 of 2 pays no Drawers")
	await _shelve_simple(0)
	_check(_bank.drawers == 1, "the drawer filled to 2 paid 1 Drawer (%d)" % _bank.drawers)
	await _shelve_simple(0)
	_check(_cabinet.contents(1).size() == 1 and _bank.drawers == 1, "the full drawer passes the next Pair on and pays no more (%d)" % _bank.drawers)
	# At the Collection's Designs less 3 a Drawer, its second (last) Row takes 3: filled, it never pays.
	var per := _cabinet.designs_count() - 3
	_cabinet.tuning = _cabinet.tuning.duplicate() as CabinetTuning
	_cabinet.tuning.drawer_capacity = per
	_check(_cabinet.row_capacity(1) == 3, "Simple's second Row takes 3 at %d a Drawer (%d)" % [per, _cabinet.row_capacity(1)])
	for i in 2:
		await _shelve_simple(1)
	_check(_cabinet.contents(1).size() == 3 and not _cabinet.has_room(1), "the short Row is full (%d)" % _cabinet.contents(1).size())
	_check(_bank.drawers == 1, "the short last Row paid no Drawers (%d)" % _bank.drawers)


# --- The Stage bonuses ---------------------------------------------------------------------------

func case_floor_bonus() -> void:
	await _build(STAGES)
	var stages := _station.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return stages.stage == 0 and stages.due.is_empty(), "the mini run to start")
	var counters := _counters()
	var flight := _flight()
	var tallies := RunTallies.of(stages)
	await _frames(1)
	_check(counters.coins.amount() == 0, "the Coins counter starts at 0")
	(_station.get_node("FitNow/StagesSwitch") as StagesSwitch).use(1)
	await _physics_ticks(1)
	_check(stages.stage == 1, "the next floor opened")
	_check(_bank.of_player(1) == 100, "the Bank paid the player 100 (%d)" % _bank.of_player(1))
	_check(tallies.tally(1, RunTallies.COINS) == 100, "the tallies count the bonus (%d)" % tallies.tally(1, RunTallies.COINS))
	_check(flight.pop_texts().is_empty(), "no \"+N\" pops for a bonus")
	_check(flight.pending(counters.coins.currency) == 100, "its 100 Coins are on their way (%d)" % flight.pending(counters.coins.currency))
	var frames := [0]
	await _until(func() -> bool:
		frames[0] += 1
		return counters.coins.amount() > 0, "the counter to start counting up", 300)
	var want := flight.tuning.first_landing(true) * 60.0
	_check(frames[0] >= want - 6.0, "the first Coin lands after the bonus delay (%d frames, %.0f expected)" % [frames[0], want])
	_check(counters.coins.amount() < 100, "the counter counts up, not jumps (%d)" % counters.coins.amount())
	_check(flight.flying() == 0, "no icon flies for a bonus")
	await _until(func() -> bool: return counters.coins.amount() == 100, "the counter to reach 100", 300)


func case_cabinet_bonus() -> void:
	await _build(STAGES)
	var stages := _station.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return stages.stage == 0 and stages.due.is_empty(), "the mini run to start")
	var a := _station.get_node("CabinetA/Cabinet") as Cabinet
	_cabinet = a
	var tallies := RunTallies.of(stages)
	var bonuses := []
	_bank.paid.connect(func(_p: int, amount: int, _at: Node3D, bonus: bool) -> void:
		if bonus:
			bonuses.append(amount))
	for i in 3:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	_check(_bank.drawers == 1, "Row 1 filled to 2 paid the team Stage 1's 1 Drawer (%d)" % _bank.drawers)
	_check(bonuses.is_empty(), "no bonus while a Row has room")
	var before := _bank.of_player(1)
	await _shelve_pair(SIMPLE[3], 1)
	_check(_bank.of_player(1) - before == 10 + 50, "the Pair that fills the current Rows pays 10 and the Cabinet bonus 50 (%d)" % (_bank.of_player(1) - before))
	_check(bonuses == [50], "the bonus is paid as a bonus, once (%s)" % [bonuses])
	_check(_bank.drawers == 2 and a.bonus_rows == 2, "two Drawers, the bonus kept for 2 Rows (%d, %d)" % [_bank.drawers, a.bonus_rows])
	_check(tallies.tally(1, RunTallies.COINS) == _bank.of_player(1), "the tallies count the bonus with the Pairs (%d)" % tallies.tally(1, RunTallies.COINS))
	_check(not _flight().pop_texts().has("+50"), "no \"+50\" pops (%s)" % [_flight().pop_texts()])
	await _until(func() -> bool: return stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	(_station.get_node("FitNow/StagesSwitch") as StagesSwitch).use(1)
	await _physics_ticks(1)
	_check(a.rows == 3, "Cabinet A grew to 3 Rows")
	await _shelve_pair(SIMPLE[4], 2)
	_check(bonuses.size() == 2 and bonuses[1] == 100, "the floor paid its bonus (%s)" % [bonuses])
	before = _bank.of_player(1)
	await _shelve_pair(SIMPLE[5], 2)
	_check(_bank.of_player(1) - before == 60 and bonuses.size() == 3 and a.bonus_rows == 3, "its new Row filled pays the Cabinet bonus again (%d, %s)" % [_bank.of_player(1) - before, bonuses])


# --- Spending, the cheat -------------------------------------------------------------------------

func case_spendable() -> void:
	await _build(ECONOMY)
	_parts.apply(_bank.grant(_bank.paid_patch(1, 30)))
	_check(_bank.of_player(1) == 30, "the Bank decided 30 Coins at once")
	_check(_bank.spendable(1) == 0 and not _bank.can_spend(1, 1), "a purchase is refused while they fly (%d spendable)" % _bank.spendable(1))
	var t := _bank.flight
	_bank.clock += t.first_landing(false) + t.spread() * 0.5
	_check(_bank.spendable(1) > 0 and _bank.spendable(1) < 30, "half way, some have landed (%d)" % _bank.spendable(1))
	_bank.clock += t.spread()
	_check(_bank.spendable(1) == 30 and _bank.can_spend(1, 30), "once landed they may all be spent (%d)" % _bank.spendable(1))
	# A bonus lands bonus_delay later.
	_parts.apply(_bank.grant(_bank.paid_patch(1, 10, true)))
	_bank.clock += t.first_landing(false) + 0.01
	_check(_bank.spendable(1) == 30, "a bonus's first Coin is not landed when a payout's would be (%d)" % _bank.spendable(1))
	# A load lands everything still flying.
	_parts.apply(_bank.grant(_bank.paid_patch(1, 5)))
	var saved := _roundtrip(_parts.save_snapshot())
	var versions := _parts.save_versions()
	_check(not (saved[String(_bank.id)] as Dictionary).has("recent"), "a save keeps nothing flying")
	_parts.load_save(saved, versions, "host")
	_check(_bank.of_player(1) == 45 and _bank.spendable(1) == 45, "a load lands them at once (%d of %d)" % [_bank.spendable(1), _bank.of_player(1)])
	_check(_bank.whole_state().keys() == ["coins", "drawers"], "a join's snapshot carries nothing flying")


func case_cheat() -> void:
	await _build(ECONOMY)
	var counters := _counters()
	await _frames(1)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F9
	key.pressed = true
	Input.parse_input_event(key)
	await _physics_ticks(2)
	var up := key.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await _until(func() -> bool: return _bank.of_player(1) == 1000, "F9 to give the Host 1000 Coins")
	_check(_bank.spendable(1) == 1000, "spendable at once (%d)" % _bank.spendable(1))
	_check(_flight().pop_texts().is_empty() and _flight().pending(counters.coins.currency) == 0, "no flight")
	await _frames(1)
	_check(counters.coins.amount() == 1000, "the counter reads 1000 at once (%d)" % counters.coins.amount())
	_check(_player.hud().message_text() == "Debug: +1000 Coins", "the message (%s)" % _player.hud().message_text())


# --- Co-op ---------------------------------------------------------------------------------------

func case_coop_welcome() -> void:
	wait_floor_s = NET_WAIT_S
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hr := LevelRuntime.of(host)
	var gr := LevelRuntime.of(guest)
	_check(hr.net.start(["--host", "--profile=%s" % TAGS[0]]) == OK, "the zoo hosts")
	var hb := hr.bank
	await _until(func() -> bool: return hr.roster.peers().size() == 1, "the Host to be in its Roster")
	hr.parts.apply(hb.grant(hb.paid_patch(1, 101)))
	_check(gr.net.start(["--join=127.0.0.1:%d" % hr.session.port, "--profile=%s" % TAGS[1]]) == OK, "the Guest joins")
	await _until(func() -> bool: return hr.roster.peers().size() == 2, "the Guest to be in", 900, 0.1)
	var gpeer := hr.roster.peers()[1]
	var gpid := hr.roster.id_of(gpeer)
	await _until(func() -> bool: return hb.coins.has(gpid), "the Host to welcome the Guest", 900, 0.1)
	_check(hb.of_player(gpeer) == 101, "the new Guest starts with the Host's 101, the one present player's average (%d)" % hb.of_player(gpeer))
	var gb := gr.bank
	await _until(func() -> bool: return gb.of_player(gr.session.me()) == 101, "the Guest's own Bank to read 101", 900, 0.1)
	var again := hr.parts.answer(Command.new(Bank.WELCOME, Parts.HOST, hb.id, {"player": gpid}))
	_check(not again["ok"], "a known id is not welcomed again")
	# Rounding down: 101 and 102 present average 101.5; a new id gets 101.
	hr.parts.apply(hb.grant(hb.paid_patch(gpeer, 1)))
	hr.parts.ask(Command.new(Bank.WELCOME, Parts.HOST, hb.id, {"player": "someone_new"}))
	_check(int(hb.coins.get("someone_new", -1)) == 101, "the average is rounded down (%d)" % int(hb.coins.get("someone_new", -1)))
	# A Guest's F9 asks nothing.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F9
	key.pressed = true
	var host_had := hb.of_player(1)
	gb._unhandled_input(key)
	await _frames(10)
	_check(hb.of_player(1) == host_had and hb.of_player(gpeer) == 102, "the Guest's F9 changed nothing (%d, %d)" % [hb.of_player(1), hb.of_player(gpeer)])


# --- The house -----------------------------------------------------------------------------------

func case_house_counters() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	await _until(rt.loading.is_lifted, "the house's Socks to be laid", 900, LAYING_S)
	_player = rt.player
	await _frames(2)
	var counters := _counters()
	_check(counters.visible and counters.is_visible_in_tree(), "the counters show on the HUD")
	_check(counters.bank() == rt.bank, "they show the house's Bank")
	_check(counters.coins.amount() == 0 and counters.drawers.amount() == 0, "they read 0 and 0 (%d, %d)" % [counters.coins.amount(), counters.drawers.amount()])
	var rect := counters.get_global_rect()
	_check(rect.position.x <= 30.0 and rect.position.y <= 20.0, "at the top left (%s)" % rect.position)
	_check(counters.coins.icon.texture != null and counters.drawers.icon.texture != null, "each with its icon")


func case_drawer_payouts() -> void:
	var plan := load("res://game/run/house_stage_plan.tres") as StagePlan
	_check(plan.stages.map(func(s: Stage) -> int: return s.drawer_payout) == [1, 1, 2, 3], "1, 1, 2 and 3 Drawers")
	var t := load("res://game/economy/economy_tuning.tres") as EconomyTuning
	_check(t.floor_bonus == 100 and t.cabinet_bonus == 50 and t.cheat_coins == 1000, "the bonuses 100 and 50, the cheat 1000")
	var f := load("res://game/ui/money/coin_flight_tuning.tres") as CoinFlightTuning
	_check(f.hold == 0.5 and f.pop_in == 0.12 and f.burst == 0.2 and f.flight == 0.45 and f.total == 1.5 and f.bonus_delay == 0.35, "the flight's old times")
	_check(f.radius == 70.0 and f.icon == 34.0 and f.drawer_rise == 80.0 and f.pulse == 1.35, "the flight's old sizes")
	var coins := load("res://game/economy/coins.tres") as Currency
	var drawers := load("res://game/economy/drawers.tres") as Currency
	_check(coins.name == "Coins" and drawers.name == "Drawers" and drawers.tint.is_equal_approx(Color("#1e2b55")), "the currencies' names and the House blue")


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
	_player.position = BY_DRAWERS if scene == ECONOMY else STAGES_START
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_bank = _station.get_node("Socks/Bank") as Bank
	_cabinet = _station.get_node_or_null("Cabinet/Cabinet") as Cabinet
	PadRumble.reset()
	await _until(func() -> bool: return _player.is_on_floor() and _mess.count() > 0 and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


func _free_level() -> void:
	if _level != null:
		_level.free()
		_level = null


func _counters() -> MoneyCounters:
	return _player.hud().get_node("MoneyCounters") as MoneyCounters


func _flight() -> CoinFlight:
	return _player.hud().get_node("CoinFlight") as CoinFlight


## `n` Simple Pairs lying loose in the Mess (two Socks of one Design), as [sock, mate] each.
func _simple_pairs(n: int) -> Array:
	var out := []
	var first := {}
	for sock in _mess.count():
		if _mess.state_of(sock) != Mess.State.LYING or _mess.mate_of(sock) >= 0 or _mess.design_of(sock).collection != &"simple":
			continue
		var design := _mess.designs[sock]
		if not first.has(design):
			first[design] = sock
			continue
		out.append([int(first[design]), sock])
		first.erase(design)
		if out.size() == n:
			break
	return out


## Takes `pair` ([sock, mate]) into the Hands by the Hands' own Command: one Pair.
func _pair(pair: Array) -> void:
	for s: int in pair:
		_hands.clock += 10.0
		_hands.pick(1, s)
		await _physics_ticks(1)
	_check(_mess.is_pair(int(pair[0])) or _mess.is_pair(int(pair[1])), "Socks %s fused into a Pair" % [pair])


## The Economy station: takes the next Simple Pair lying and shelves it by the Cabinet's click at `drawer`.
func _shelve_simple(drawer: int) -> void:
	var pairs := _simple_pairs(1)
	_check(not pairs.is_empty(), "a Simple Pair lies")
	await _pair(pairs[0])
	var before := _cabinet.shelved().size()
	_cabinet.click(1, drawer)
	await _until(func() -> bool: return _cabinet.shelved().size() == before + 1, "the Pair to be shelved")
	await _physics_ticks(1)


## The Stages station: pairs Sock `sock` with its mate and shelves the Pair into Cabinet A's drawer.
func _shelve_pair(sock: int, drawer: int) -> void:
	await _pair([sock, sock + 1])
	var before := _cabinet.shelved().size()
	_cabinet.click(1, drawer)
	await _until(func() -> bool: return _cabinet.shelved().size() == before + 1, "the Pair %d to be shelved" % sock)
	await _physics_ticks(1)


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


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


func _drawer_front(index: int) -> Vector3:
	var front := _cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


# --- Zoos holding only the Economy station (stages_test's way) -----------------------------------

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
