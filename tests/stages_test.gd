## Stages: the run's state and Rows (core/76). The Stages station's mini run (two Stages, 2 Pairs a
## Drawer: Cabinet A Simple for Stage 1, Cabinet B Sport sheeted on the platform for Stage 2): a New
## Game's start, a Stage completing on its last Pair, "Fit now" opening the next floor, the bar fixed
## when a Stage begins and the attic's own-Cabinets rule, a Row's capacity, a save mid-Stage and
## between the Fix and its floor's opening, a Guest who joins, and the World's row naming its floor.
## Most cases play the station scene on a floor with the game's player and a Parts (a Host of one), as
## cabinet_test does; the co-op and the save record ones play zoos holding only the station.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's Socks, by id (the order of its SockSpots): Simple Pairs of Designs 0..5, then Sport.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const SPORT := [12, 14]
## Where the player stands (station space): before the Simple Socks, before Cabinet A, at the switches.
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
const BY_SWITCHES := Vector3(0.25, 0.0, 2.8)
const NET_WAIT_S := 20.0
const TAGS := ["stages_test_a", "stages_test_b"]

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _stages: Stages = null
var _a: Cabinet = null
var _b: Cabinet = null
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player clicks the last Pair into Cabinet A, the Stage completes (Part out); E on \"Fit now\" unlocks Cabinet B at its starting Rows, its sheet comes off, and Cabinet A is one Row taller"},
		{"name": "start", "method": "case_start", "world": false,
				"title": "a New Game starts at Stage 1: only Stage 1's Cabinets unlocked at 2 Rows, the rest locked showing 2 under the sheet; the bar counts their Rows at the World's Pairs per Drawer"},
		{"name": "row_capacity", "method": "case_row_capacity", "world": false,
				"title": "a Row takes the Pairs per Drawer, the Collection's last Row only the Designs left (Simple's sixth 5, Sport's third 20); the full height is Designs over Pairs per Drawer, rounded up"},
		{"name": "bar_fixed", "method": "case_bar_fixed", "world": false,
				"title": "Q633: a Stage's bar is fixed when it begins (full Rows are not in it, grown Rows are); a Stage that counts only its own Cabinets (the attic, Q2623) leaves the older ones out"},
		{"name": "last_stage", "method": "case_last_stage", "world": false,
				"title": "the last Stage's Fix leaves the machine fixed (phase FIXED, machine_fixed), and nothing opens after it"},
		{"name": "save_mid_stage", "method": "case_save_mid_stage", "world": false,
				"title": "a save mid-Stage loads to the same Stage, phase, bar, Rows and shelf"},
		{"name": "save_fixing", "method": "case_save_fixing", "world": false,
				"title": "a save between the Fix and its floor's opening opens the floor after the load"},
		{"name": "guest_join", "method": "case_guest_join", "world": false,
				"title": "a Guest who joins sees the same Stage, Rows and phase, and hears the next Stage event as its signal"},
		{"name": "floor_name", "method": "case_floor_name", "world": false,
				"title": "the World's row names its floor: the save's record carries the current Stage's title"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_drop_branches()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var completed: Array = []
	_stages.stage_completed.connect(func(s: int, cab: StringName) -> void: completed.append([s, cab]))
	for i in 3:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	_check(_stages.phase == Stages.Phase.PLAYING and _stages.bar_numbers() == Vector2i(3, 4), "three of the bar's four Pairs in (%s)" % _stages.bar_numbers())
	# The last Pair, by the player's own input.
	_stand(BY_SOCKS)
	await _aim(_player, _centre(SIMPLE[3]))
	await _physics_ticks(25)  # past the grab interval of the last helper pick
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == SIMPLE[3], "the Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(SIMPLE[3] + 1))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair")
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 1))
	await _press(&"pick")
	await _until(func() -> bool: return _a.contents(1).size() == 2, "the last Pair to be shelved in the second Row")
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	_check(_stages.bar_numbers() == Vector2i(4, 4), "the bar is full (%s)" % _stages.bar_numbers())
	_check(completed == [[0, _a.id]], "stage_completed(0, Cabinet A) fired once (%s)" % [completed])
	# E on the "Fit now" pillar.
	_stand(BY_SWITCHES)
	await _aim(_player, _button("FitNow"))
	await _press(&"interact")
	await _until(func() -> bool: return _stages.stage == 1, "the next floor to open")
	_check(_stages.phase == Stages.Phase.PLAYING, "Stage 2 counts")
	_check(not _b.locked and _b.rows == 2, "Cabinet B is unlocked at its starting Rows (locked %s, rows %d)" % [_b.locked, _b.rows])
	_check(not _b.sheeted(), "its dust sheet comes off")
	_check(not _b.drawer(0).locked and not _b.drawer(1).locked and _b.drawer(2).locked, "its two Rows' drawers open to a click, the third stays shut")
	_check(_a.rows == 3 and not _a.drawer(2).locked, "Cabinet A is one Row taller (%d) and its third drawer takes Pairs" % _a.rows)
	_check(_stages.floor_title() == "Ground", "the run is on the Ground floor")
	_check(_stages.bar_numbers() == Vector2i(0, 6), "the new bar: A's third Row and B's two (%s)" % _stages.bar_numbers())
	_check((_station.get_node("FitNow/Looks/Label") as Label3D).text.contains("Stage 2: Ground"), "the pillar's label says Stage 2")


# --- Rules ---------------------------------------------------------------------------------------

func case_start() -> void:
	await _build()
	_check(_stages.stage == 0 and _stages.phase == Stages.Phase.PLAYING, "Stage 1 counts (stage %d)" % _stages.stage)
	_check(_stages.pairs_per_drawer == 2, "the World's Pairs per Drawer is the plan's 2")
	_check(not _a.locked and _a.rows == 2, "Cabinet A, Stage 1's, unlocked at 2 Rows")
	_check(_b.locked and _b.rows == 2 and _b.sheeted(), "Cabinet B locked, showing 2 Rows, under its sheet")
	_check(not _b.aimable(), "the sheeted Cabinet cannot be aimed at")
	_check(_stages.bar.size() == 2, "the bar counts Cabinet A's two Rows only (%s)" % [_stages.bar])
	_check(_stages.bar_source() == Stages.BAR_SOURCE and _stages.is_in_group(StageBarPhase.SOURCES), "Stages answers the bar's stage_rows provider")
	_check(_stages.bar_numbers() == Vector2i(0, 4), "0/4 (%s)" % _stages.bar_numbers())
	_check(_stages.floor_open(0) and not _stages.floor_open(1), "only the basement is open")
	_check(_stages.fitted_count() == 0, "no Part is in the machine")
	_parts.ask(Command.new(&"start", Parts.HOST, _stages.id, {"pairs_per_drawer": 2}))
	_check(_stages.stage == 0, "a second start is refused")
	_check(_a.room() == 4, "Cabinet A takes 2 Pairs a Row (%d)" % _a.room())


func case_row_capacity() -> void:
	await _build()
	_parts.load_snapshot({_stages.id: {"pairs_per_drawer": 25}})
	_check(_a.row_capacity(0) == 25 and _a.row_capacity(5) == 5 and _a.row_capacity(6) == 0, "Simple's Rows take 25, its sixth 5 (%d)" % _a.row_capacity(5))
	_check(_a.full_height() == 6, "Simple is 6 Rows high (%d)" % _a.full_height())
	_check(_b.row_capacity(2) == 20 and _b.full_height() == 3, "Sport's third Row takes 20, 3 Rows high")
	_check(Stages.height_of(_a, 25) == mini(6, _a.drawer_count()), "a Cabinet never has more Rows than Drawers")
	var plan := _stages.plan
	_check(plan.pairs_of(0, 25) == 50 and plan.pairs_of(0, 2) == 4 and plan.pairs_of(1, 1) == 3, "a Stage's Pairs scale by Pairs per Drawer / 25, rounded up")
	var house := load("res://game/run/house_stage_plan.tres") as StagePlan
	var titles := house.stages.map(func(s: Stage) -> String: return s.title)
	_check(titles == ["Basement", "Ground", "First", "Attic"], "the house's Stages are the old floors (%s)" % [titles])
	_check(house.stages.map(func(s: Stage) -> int: return s.pairs) == [50, 160, 150, 130], "their Pairs are the old 50/160/150/130")
	_check(house.start_rows == 2 and house.rows_per_stage == 1 and house.high_share == 0.05 and house.high_spot == 1.7, "start_rows 2, rows_per_stage 1, high_share 0.05, high_spot 1.7")
	_check(house.stages[3].counts_only_own and not house.stages[0].counts_only_own, "only the attic counts only its own Cabinets")
	_check(house.goal_phase.text == "Wash the laundry" and house.stage_phase.source == Stages.BAR_SOURCE and house.after_phase.source == &"laundry_bins", "the bar's three phases")


func case_bar_fixed() -> void:
	await _build()
	for i in 4:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	await _fit_now()
	var want := [[String(_a.id), 2], [String(_b.id), 0], [String(_b.id), 1]]
	_check(_stages.bar == want, "the full Rows are left out, the grown one and the new Cabinet's are in (%s)" % [_stages.bar])
	# A Pair into a Row not in the bar leaves the bar as it is.
	var before := _stages.bar.duplicate(true)
	await _shelve_pair(SIMPLE[4], 2)
	_check(_stages.bar == before and _stages.bar_numbers() == Vector2i(1, 6), "the bar stays as it began; the Pair counts (%s)" % _stages.bar_numbers())
	# The attic's rule: a plan whose second Stage counts only its own Cabinets.
	var own := (load("res://game/zoo/stages/mini_plan.tres") as StagePlan).duplicate(true) as StagePlan
	own.stages[1].counts_only_own = true
	await _build(own)
	for i in 4:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	await _fit_now()
	_check(_stages.bar == [[String(_b.id), 0], [String(_b.id), 1]], "only Cabinet B's Rows count (%s)" % [_stages.bar])
	_check(_a.rows == 3, "Cabinet A still grows")


func case_last_stage() -> void:
	await _build()
	var fixed := [0]
	_stages.machine_fixed.connect(func() -> void: fixed[0] += 1)
	await _fit_now()
	_check(_stages.stage == 1, "the zoo's Fit now completes and opens Stage 2 at once")
	await _fit_now()
	_check(_stages.stage == 1 and _stages.phase == Stages.Phase.FIXED, "the last Stage's Fix leaves the machine fixed (phase %d)" % _stages.phase)
	_check(fixed[0] == 1, "machine_fixed fired once")
	_check(_stages.fitted_count() == 2, "both Parts are in the machine")
	var ev := _parts.answer(Command.new(&"fit_now", Parts.HOST, _stages.id))
	_check(not ev["ok"], "nothing opens after the last Stage")


func case_save_mid_stage() -> void:
	await _build()
	await _shelve_pair(SIMPLE[0], 0)
	var saved := _parts.save_snapshot()
	var versions := _parts.save_versions()
	var was := _stages.state()
	await _build()
	_parts.load_save(_roundtrip(saved), versions, "host")
	_same(_stages.state(), was, "the Stages' state")
	_check(_a.contents(0).size() == 1 and _a.rows == 2 and _b.locked, "the Rows, the shelf and the locks")
	_check(_stages.bar_numbers() == Vector2i(1, 4), "the bar reads 1/4 (%s)" % _stages.bar_numbers())


func case_save_fixing() -> void:
	await _build()
	for i in 4:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	var saved := _roundtrip(_parts.save_snapshot())
	# The Part went into the machine (core/79's fit) and the game quit during the Fix scene.
	(saved[String(_stages.id)] as Dictionary)["phase"] = Stages.Phase.FIXING
	var versions := _parts.save_versions()
	await _build()
	var opened: Array = []
	_stages.floor_opened.connect(func(s: int, grown: Array) -> void: opened.append([s, grown]))
	_parts.load_save(saved, versions, "host")
	_check(_stages.stage == 1 and _stages.phase == Stages.Phase.PLAYING, "the floor opened after the load (stage %d, phase %d)" % [_stages.stage, _stages.phase])
	_check(not _b.locked and _a.rows == 3, "Cabinet B unlocked, Cabinet A grown")
	_check(opened == [[1, [_a.id]]], "floor_opened(1, [Cabinet A]) fired (%s)" % [opened])


func case_guest_join() -> void:
	wait_floor_s = NET_WAIT_S
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := _stages_of(host)
	await _until(func() -> bool: return hs.stage == 0, "the Host's run to start")
	_check(_net(host).start(["--host", "--profile=%s" % TAGS[0]]) == OK, "the zoo hosts")
	# The Host opens Stage 2 before the Guest comes.
	LevelRuntime.of(host).parts.ask(Command.new(&"fit_now", Parts.HOST, hs.id))
	_check(hs.stage == 1, "the Host's Fit now opened Stage 2")
	_check(_net(guest).start(["--join=127.0.0.1:%d" % _session(host).port, "--profile=%s" % TAGS[1]]) == OK, "the Guest joins")
	var gs := _stages_of(guest)
	await _until(func() -> bool: return LevelRuntime.of(host).roster.peers().size() == 2 and gs.stage == 1, "the Guest to be in and see Stage 2")
	_same(gs.state(), hs.state(), "the Guest's Stages are the Host's")
	var hb := host.get_node("Stations/Stages/CabinetB/Cabinet") as Cabinet
	var gb := guest.get_node("Stations/Stages/CabinetB/Cabinet") as Cabinet
	var ga := guest.get_node("Stations/Stages/CabinetA/Cabinet") as Cabinet
	_check(not gb.locked and gb.rows == hb.rows and ga.rows == 3 and not gb.sheeted(), "the Guest sees Cabinet B unlocked and A grown")
	var heard: Array = []
	gs.machine_fixed.connect(func() -> void: heard.append(true))
	LevelRuntime.of(host).parts.ask(Command.new(&"fit_now", Parts.HOST, hs.id))
	await _until(func() -> bool: return gs.phase == Stages.Phase.FIXED, "the Guest to see the machine fixed")
	_check(heard.size() == 1, "the Guest's machine_fixed fired")


func case_floor_name() -> void:
	var zoo := _branch("Solo")
	await _frames(2)
	var s := _stages_of(zoo)
	await _until(func() -> bool: return s.stage == 0, "the run to start")
	var autosave := LevelRuntime.of(zoo).autosave
	autosave.world = WorldSlot.new()
	_check(String(autosave.collect()["world"]["floor"]) == "Basement", "the World's row names the basement")
	LevelRuntime.of(zoo).parts.ask(Command.new(&"fit_now", Parts.HOST, s.id))
	_check(String(autosave.collect()["world"]["floor"]) == "Ground", "after the Fix, the Ground floor")
	_check(WorldRecord.from_dict(autosave.collect()["world"]).floor_name == "Ground", "and it reads back from the file")


# --- Helpers -------------------------------------------------------------------------------------

## The station on a floor with the player and a Parts; `plan` replaces the mini run's plan. Waits for
## the run to start.
func _build(plan: StagePlan = null) -> void:
	if _level != null:
		_level.free()
		_level = null
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
	_station.position = Vector3.ZERO
	if plan != null:
		(_station.get_node("Run/Stages") as Stages).plan = plan
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_stages = _station.get_node("Run/Stages") as Stages
	_a = _station.get_node("CabinetA/Cabinet") as Cabinet
	_b = _station.get_node("CabinetB/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and _stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")
	await _until(func() -> bool: return _stages.due.is_empty(), "Stage 1's Socks to be laid")


## Pairs Sock `sock` with its mate (the next id) by the Hands' Command and shelves the Pair into
## Cabinet A's drawer `drawer` by the Cabinet's click.
func _shelve_pair(sock: int, drawer: int) -> void:
	for s: int in [sock, sock + 1]:
		_hands.clock += 10.0
		_hands.pick(1, s)
		await _physics_ticks(1)
	_check(_mess.is_pair(sock), "Socks %d and %d fused into a Pair" % [sock, sock + 1])
	var before := _a.shelved().size()
	_a.click(1, drawer)
	await _until(func() -> bool: return _a.shelved().size() == before + 1, "the Pair %d to be shelved" % sock)
	await _physics_ticks(1)


## Asks the "Fit now" switch by its own Command.
func _fit_now() -> void:
	(_station.get_node("FitNow/StagesSwitch") as StagesSwitch).use(1)
	await _physics_ticks(1)


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


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _button(switch: String) -> Vector3:
	return (_station.get_node("%s/Looks/Button" % switch) as Node3D).global_position


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


# --- Zoos holding only the Stages station (coop_join_test's way) ---------------------------------

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
		if String(station.name) != "Stages":
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


func _stages_of(zoo: Node3D) -> Stages:
	return zoo.get_node("Stations/Stages/Run/Stages") as Stages


func _session(zoo: Node3D) -> Session:
	return LevelRuntime.of(zoo).session


func _net(zoo: Node3D) -> LevelNet:
	return LevelRuntime.of(zoo).net
