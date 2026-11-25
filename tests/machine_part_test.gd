## Machine Parts (core/79, docs/architecture/stages.md "Machine Parts"): the Part a Stage earns pops out
## of the top of the Cabinet that took the last Pair, lies turning with its glow, is carried and fitted
## through the MachinePartSlot. Played in the Stages station's mini run (Cabinet A, the slot box, the
## filter for Stage 1 and the motor for Stage 2) on a floor with the game's player and a Parts, as
## stages_test does; the co-op case plays two zoos holding only that station.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's Simple Pairs, by first Sock id.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
const FILTER := "Run/MachineParts/Filter"
const MOTOR := "Run/MachineParts/Motor"
const SLOT := "SlotBox"
const NET_WAIT_S := 20.0
const TAGS := ["machine_part_test_a", "machine_part_test_b"]

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _stages: Stages = null
var _a: Cabinet = null
var _branches: Array[Node] = []
var _washer: Node = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player shelves the last Pair, the Part pops out of Cabinet A's top; a click carries it (the readout names it), a click on the slot box fits it and the platform's floor opens"},
		{"name": "pop_and_lie", "method": "case_pop_and_lie", "world": false,
				"title": "the Part is hidden until its Stage completes, flies from the Cabinet's top to 1.5 m in front of it on the floor in 0.7 s, then lies with its glow, sparkle and the lying animation and an 18-spark burst on landing"},
		{"name": "carry_and_put", "method": "case_carry_and_put", "world": false,
				"title": "carried, the glow and sparkle are off and the turn and bob are back at 0; a right click puts it down at the crosshair and it lies again"},
		{"name": "hands_full", "method": "case_hands_full", "world": false,
				"title": "with a Sock in the Hands a click on the Part is refused Hands full and the Part stays"},
		{"name": "fit_refusals", "method": "case_fit_refusals", "world": false,
				"title": "the slot refuses with nothing carried; \"The washing machine is busy\" while the washer is busy; the Part is not handed over wrongly (handable), and a Part not this Stage's is not fitted"},
		{"name": "save_and_load", "method": "case_save_and_load", "world": false,
				"title": "a save with the Part lying loads with it lying where it was, drawn, with no pop; with it carried it loads lying where it last lay"},
		{"name": "guest", "method": "case_guest", "world": false,
				"title": "a Guest sees the Part pop and lie, and sees the Host carry it"},
		{"name": "looks_contract", "method": "case_looks_contract", "world": false,
				"title": "every kind's Looks has the nodes Part, Model, Outline, AnimationPlayer and the animations lying and RESET (assets/12's contract); the board lists each Part's name"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _washer != null:
		_washer.free()
		_washer = null
	if _level != null:
		_level.free()
		_level = null
	_drop_branches()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	for i in 3:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	var part := _part(FILTER)
	_check(not part.out() and not _thing(FILTER).visible, "before its Stage completes the Part is hidden")
	_stand(BY_SOCKS)
	await _aim(_player, _centre(SIMPLE[3]))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == SIMPLE[3], "the Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(SIMPLE[3] + 1))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair")
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 1))
	await _press(&"pick")
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	_check(part.out() and _thing(FILTER).visible, "the Stage's Part is out")
	_check(part.popping(), "it pops out of the Cabinet")
	await _until(func() -> bool: return not part.popping(), "the pop to land", 120)
	# Carry it.
	var lies := _thing(FILTER).global_position
	_stand(lies + Vector3(0.0, 0.0, 1.3))
	await _aim(_player, lies + Vector3.UP * 0.13)
	_check(_player.aimed_part() == _carriable(FILTER), "the crosshair is on the Part")
	_check(_player.hud().prompt_text().contains("New filter"), "the readout names it (%s)" % _player.hud().prompt_text())
	await _press(&"pick")
	await _until(func() -> bool: return _hands.carries(1) == _carriable(FILTER), "the Part to be carried", 60)
	await _physics_ticks(2)
	_check(_player.hud().prompt_text().contains("New filter"), "carried, the readout still names it (%s)" % _player.hud().prompt_text())
	# Click the slot box.
	var slot := _thing(SLOT).global_position
	_stand(slot + Vector3(0.0, 0.0, 1.6))
	await _aim(_player, slot + Vector3.UP * 0.45)
	_check(_player.aimed_part() is MachinePartSlot, "the crosshair is on the slot box")
	_check(_player.hud().prompt_text().to_lower().contains("fit the new filter"), "it reads Fit the new filter (%s)" % _player.hud().prompt_text())
	var fitted: Array = []
	_stages.part_fitted.connect(func(s: int) -> void: fitted.append(s))
	await _press(&"pick")
	await _until(func() -> bool: return _stages.stage == 1, "the floor to open", 60)
	_check(fitted == [0], "part_fitted(0) fired once (%s)" % [fitted])
	_check(_stages.phase == Stages.Phase.PLAYING and _hands.carries(1) == null, "the Hands are empty and Stage 2 counts")
	_check(not part.out() and not _thing(FILTER).visible, "the fitted Part is put away")
	var b := _station.get_node("CabinetB/Cabinet") as Cabinet
	_check(not b.locked, "the platform's Cabinet is unlocked: the floor opened")


# --- Rules ---------------------------------------------------------------------------------------

func case_pop_and_lie() -> void:
	await _build()
	var part := _part(FILTER)
	var thing := _thing(FILTER)
	var burst := thing.get_node("Burst") as GPUParticles3D
	_check(not part.lying() and not (thing.get_node("Glow") as Node3D).visible, "hidden Part: no glow")
	_check(not (_part(MOTOR).out()), "the other Stage's Part stays hidden")
	var heard: Array = []
	_stages.stage_completed.connect(func(s: int, c: StringName) -> void: heard.append([s, c]))
	await _complete()
	_check(heard.size() == 1 and part.popping(), "the Stage completed and the Part pops")
	var target := _station.to_global(Vector3(-2.0, 0.0, -0.5))
	var carriable := _carriable(FILTER)
	_check(carriable.holder == 0 and carriable.at.distance_to(target) < 0.05, "it is laid 1.5 m in front of Cabinet A on the floor (%s)" % carriable.at)
	_check(not (thing.get_node("Glow") as Node3D).visible, "no glow while it flies")
	var top := MachinePart.top_of(_a)
	var peak := 0.0
	var start := Time.get_ticks_msec()
	while part.popping() and Time.get_ticks_msec() - start < 3000:
		peak = maxf(peak, part.looks().global_position.y)
		await _frames(1)
	_check(peak > top.y, "it flies up over the top (peak %.2f over %.2f)" % [peak, top.y])
	_check(part.looks().position.length() < 0.001, "landed, its Looks is back on the thing")
	_check(thing.global_position.distance_to(target) < 0.05, "it lies where the Host put it (%s, want %s)" % [thing.global_position, target])
	_check(burst.emitting and burst.amount == 18 and burst.one_shot, "an 18-spark burst on landing")
	_check((thing.get_node("Glow") as Node3D).visible and (thing.get_node("Sparkle") as GPUParticles3D).emitting, "lying, the glow disc and the sparkle show")
	var player := part.looks().get_node("AnimationPlayer") as AnimationPlayer
	_check(player.current_animation == &"lying" and player.is_playing(), "lying plays")
	var before := (part.looks().get_node("Part") as Node3D).rotation.y
	await _physics_ticks(20)
	_check(not is_equal_approx((part.looks().get_node("Part") as Node3D).rotation.y, before), "it turns")
	_check(_player.hud() != null and _carriable(FILTER).title == "New filter", "its readout is the kind's name")


func case_carry_and_put() -> void:
	await _build()
	await _complete()
	var part := _part(FILTER)
	await _until(func() -> bool: return not part.popping(), "the pop to land", 120)
	var thing := _thing(FILTER)
	var lies := thing.global_position
	_stand(lies + Vector3(0.0, 0.0, 1.3))
	await _aim(_player, lies + Vector3.UP * 0.13)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.carries(1) == _carriable(FILTER), "the Part to be carried", 60)
	await _physics_ticks(2)
	_check(not part.lying(), "carried, it does not lie")
	_check(not (thing.get_node("Glow") as Node3D).visible and not (thing.get_node("Sparkle") as GPUParticles3D).emitting, "carried, the glow and the sparkle are off")
	var player := part.looks().get_node("AnimationPlayer") as AnimationPlayer
	_check(player.current_animation == &"RESET", "carried, the turn and bob are back at 0 (%s)" % player.current_animation)
	_check(_carriable(FILTER).handable, "a right click at a Teammate hands it over (core/78's verb, on)")
	# Put it down at the crosshair.
	var spot := _player.global_position + Basis(Vector3.UP, _player.rotation.y) * Vector3(0.0, 0.0, -1.4)
	spot.y = 0.0
	await _aim(_player, spot)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _carriable(FILTER).holder == 0, "a right click puts it down", 60)
	await _until(func() -> bool: return not _carriable(FILTER).putting(), "the put to end", 60)
	_check(part.lying() and (thing.get_node("Glow") as Node3D).visible, "put down, it lies again with its glow")
	_check(Vector2(thing.global_position.x - spot.x, thing.global_position.z - spot.z).length() < 0.15, "at the crosshair (%s, aimed %s)" % [thing.global_position, spot])


func case_hands_full() -> void:
	await _build()
	await _complete()
	var part := _part(FILTER)
	await _until(func() -> bool: return not part.popping(), "the pop to land", 120)
	var lies := _thing(FILTER).global_position
	_stand(lies + Vector3(0.0, 0.0, 1.3))
	_hands.clock += 10.0
	_hands.pick(1, SIMPLE[0])
	await _until(func() -> bool: return _hands.active_of(1) == SIMPLE[0], "the Sock to be in the Hands")
	await _aim(_player, lies + Vector3.UP * 0.13)
	await _press(&"pick")
	await _physics_ticks(4)
	_check(_carriable(FILTER).holder == 0 and _hands.carries(1) == null, "with a Sock in the Hands the Part stays")
	_check(_player.message() == "Hands full", "and the player reads Hands full (%s)" % _player.message())


func case_fit_refusals() -> void:
	await _build()
	var slot := _slot()
	slot.use(1)
	await _physics_ticks(2)
	_check(_stages.phase == Stages.Phase.PLAYING and _stages.stage == 0, "the slot does nothing before the Stage completes")
	await _complete()
	var part := _part(FILTER)
	await _until(func() -> bool: return not part.popping(), "the pop to land", 120)
	var lies := _thing(FILTER).global_position
	slot.use(1)
	await _physics_ticks(2)
	_check(_stages.phase == Stages.Phase.PART_OUT, "nothing carried: nothing fits")
	# Carry it, then the washer is busy.
	_stand(lies + Vector3(0.0, 0.0, 1.3))
	await _aim(_player, lies + Vector3.UP * 0.13)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.carries(1) == _carriable(FILTER), "the Part to be carried", 60)
	_washer = Node.new()
	_washer.set_script(load("res://tests/support/busy_washer.gd"))
	_washer.add_to_group(MachinePartSlot.WASHER_GROUP)
	_level.add_child(_washer)
	var spot := _thing(SLOT).global_position
	_stand(spot + Vector3(0.0, 0.0, 1.6))
	await _aim(_player, spot + Vector3.UP * 0.45)
	await _press(&"pick")
	await _physics_ticks(6)
	_check(_stages.phase == Stages.Phase.PART_OUT and _hands.carries(1) != null, "a busy washer refuses the fit and the Part stays in the Hands")
	_check(_player.message() == "The washing machine is busy", "the player reads the refusal (%s)" % _player.message())
	_washer.set("busy_now", false)
	await _press(&"pick")
	await _until(func() -> bool: return _stages.stage == 1, "the fit to go through once the washer is free", 60)


func case_save_and_load() -> void:
	await _build()
	await _complete()
	await _until(func() -> bool: return not _part(FILTER).popping(), "the pop to land", 120)
	var lies := _thing(FILTER).global_position
	var saved := _parts.save_snapshot()
	var versions := _parts.save_versions()
	await _build()
	_parts.load_save(_roundtrip(saved), versions, "host")
	await _physics_ticks(3)
	var part := _part(FILTER)
	_check(part.out() and _thing(FILTER).visible and not part.popping(), "loaded, the Part is out with no pop")
	_check(_thing(FILTER).global_position.distance_to(lies) < 0.01, "lying where it lay")
	_check(part.lying() and (_thing(FILTER).get_node("Glow") as Node3D).visible, "lying with its glow")
	# Carried at the save: it loads where it last lay.
	var carriable := _carriable(FILTER)
	_stand(lies + Vector3(0.0, 0.0, 1.3))
	await _aim(_player, lies + Vector3.UP * 0.13)
	await _press(&"pick")
	await _until(func() -> bool: return carriable.holder == 1, "the Part to be carried", 60)
	var carried := _parts.save_snapshot()
	await _build()
	_parts.load_save(_roundtrip(carried), versions, "host")
	await _physics_ticks(3)
	_check(_carriable(FILTER).holder == 0 and _part(FILTER).out(), "a Part carried at the save lies after the load")


func case_guest() -> void:
	wait_floor_s = NET_WAIT_S
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := _stages_of(host)
	await _until(func() -> bool: return hs.stage == 0, "the Host's run to start")
	_check(_net(host).start(["--host", "--profile=%s" % TAGS[0]]) == OK, "the zoo hosts")
	_check(_net(guest).start(["--join=127.0.0.1:%d" % _session(host).port, "--profile=%s" % TAGS[1]]) == OK, "the Guest joins")
	var gs := _stages_of(guest)
	await _until(func() -> bool: return LevelRuntime.of(host).roster.peers().size() == 2 and gs.stage == 0, "the Guest to be in")
	var gp := guest.get_node("Stations/Stages/" + FILTER + "/MachinePart") as MachinePart
	var hp := host.get_node("Stations/Stages/" + FILTER + "/MachinePart") as MachinePart
	var popped: Array = []
	gs.stage_completed.connect(func(_s: int, _c: StringName) -> void: popped.append(gp.popping()))
	LevelRuntime.of(host).parts.ask(Command.new(&"complete_now", Parts.HOST, hs.id))
	await _until(func() -> bool: return gp.out(), "the Guest to see the Part out", 600)
	await _frames(1)
	_check(gp.popping() or gp.lying(), "the Guest sees it pop or lie")
	await _until(func() -> bool: return gp.lying(), "the Part to lie on the Guest's machine", 600)
	var carriable := hp.carriable
	var gc := gp.carriable
	_check(gc.at.distance_to(carriable.at) < 0.001, "it lies at the same place on both machines")
	# The Host's player is not placed by this test: the reach rule stands aside (Parts.where unset).
	LevelRuntime.of(host).parts.where = Callable()
	var host_player := LevelRuntime.of(host).player
	var seen: Array = []
	LevelRuntime.of(host).parts.applied.connect(func(ev: Dictionary) -> void: seen.append(ev.get("reason", ev.get("ok"))))
	LevelRuntime.of(host).parts.ask(Command.new(&"pick", LevelRuntime.of(host).player.player_id(), carriable.id))
	await _until(func() -> bool: return gc.holder == 1, "the Guest to see the Host carry it (%s)" % [seen], 600)
	_check(not gp.lying(), "carried, it does not lie on the Guest's machine")


func case_looks_contract() -> void:
	for path: String in ["part_filter", "part_motor", "part_drum_belt", "part_detergent"]:
		var kind := load("res://game/entities/machine_part/%s.tres" % path) as MachinePartKind
		_check(kind != null and kind.looks != null and kind.name != "", "%s has a name and a Looks" % path)
		if kind == null or kind.looks == null:
			continue
		var looks := kind.looks.instantiate() as Node3D
		for node_path: String in ["Part", "Part/Model", "Part/Outline", "AnimationPlayer"]:
			_check(looks.get_node_or_null(node_path) != null, "%s's Looks has %s" % [path, node_path])
		var player := looks.get_node("AnimationPlayer") as AnimationPlayer
		_check(player.has_animation(&"lying") and player.has_animation(&"RESET"), "%s's Looks has lying and RESET" % path)
		_check(player.get_animation(&"lying").loop_mode == Animation.LOOP_LINEAR, "%s's lying loops" % path)
		looks.free()
	await _build()
	var board := _station.get_node("PlanBoard")
	_check(board.get_node_or_null("Part1") != null and board.get_node("Part1").get_node_or_null("AnimationPlayer") != null, "the plan board lists the Part's Looks")


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
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
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and _stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")


## Completes the Stage outright (the zoo's own verb), as the Host.
func _complete() -> void:
	_parts.ask(Command.new(&"complete_now", Parts.HOST, _stages.id))
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")


func _shelve_pair(sock: int, drawer: int) -> void:
	for s: int in [sock, sock + 1]:
		_hands.clock += 10.0
		_hands.pick(1, s)
		await _physics_ticks(1)
	var before := _a.shelved().size()
	_a.click(1, drawer)
	await _until(func() -> bool: return _a.shelved().size() == before + 1, "the Pair %d to be shelved" % sock)
	await _physics_ticks(1)


func _stand(spot: Vector3) -> void:
	_player.global_position = spot  # the station is at the level's origin
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


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


func _thing(path: String) -> Node3D:
	return _station.get_node(path) as Node3D


func _part(path: String) -> MachinePart:
	return _station.get_node(path + "/MachinePart") as MachinePart


func _carriable(path: String) -> Carriable:
	return _station.get_node(path + "/Carriable") as Carriable


func _slot() -> MachinePartSlot:
	return _station.get_node(SLOT + "/MachinePartSlot") as MachinePartSlot


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
