## Back to the Lobby after the end (core/97, run-ends.md "Continue"): any player's Continue on the Final screen has the
## Host save and everyone load the Lobby with the Session and Roster kept; the finished World stays chosen as a record
## ("Finished" and its play time on its row and card), cannot be continued, and Start (Solo: New Game) asks "Start a new
## game? The finished World is replaced." and makes a New Game in its slot. Co-op: two houses in one process (real ENet).
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const NET_WAIT_S := 30.0
const FPS := 60

## Machines (a node each, with its own MultiplayerAPI) and loose nodes a case made.
var _machines: Array[Node] = []
var _loose: Array[Node] = []
## What a Lobby asked to go into: [path, heading, setup].
var _into: Array = []
## The Lobby each machine came to, by its label.
var _lobbies := {}


func cases() -> Array[Dictionary]:
	return [
		{"name": "guest_continue", "method": "case_guest_continue", "world": false,
				"title": "real path: a Guest presses Continue on the Final screen; both machines are in the Lobby with the same Roster, the World's row says Finished with its play time, and the Host's Start asks before replacing it"},
		{"name": "solo_new_game", "method": "case_solo_new_game", "world": false,
				"title": "Solo: Continue goes back to the Lobby; the finished World has no Continue; New Game asks and makes a New Game in the finished World's slot"},
		{"name": "never_loads", "method": "case_never_loads", "world": false,
				"title": "a finished World never loads into the house: Solo's Continue does nothing and its row says Finished with the play time"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(CutscenePlayer.SKIP)
	SockGenerator.start_all = false
	_drop_all()
	_into.clear()
	_lobbies.clear()


func _after_case() -> void:
	_drop_all()


func case_guest_continue() -> void:
	# A Guest's house goes while the Host's still stands: the Host's despawn of that Guest's avatar finds nothing there.
	_expect_error("recv_nodes.has(net_id)")  # one for each avatar the Guest's house knew: the Host's and its own
	_expect_error("recv_nodes.has(net_id)")
	var world := Worlds.pick_slot("coop1", true, true)
	var host := _branch("Host", world)
	await _frames(2)
	var hs := _rt(host).session
	hs.port = 0
	_check(_rt(host).net.start(["--host"]) == OK, "the host house hosts")
	await _until(func() -> bool: return _rt(host).loading.is_lifted() and _day(host).drawn and _stages(host).due.is_empty(), "the Host's run to start", FPS * 40)
	var guest := _branch("Guest", null)
	await _frames(2)
	_check(_rt(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the guest joins")
	await _until(func() -> bool: return _rt(guest).net.mode_text().begins_with("Joined"), "the Guest to be welcomed", FPS * 40)
	await _until(func() -> bool: return _day(guest).drawn, "the Guest to see the Laundry day", FPS * 10)
	_day(host).cutscene = false
	_one_bin_left(host)
	# A started game: the Lobby's started flag is what Continue must reopen.
	var link := _rt(host).link
	link.parts.apply({"ok": true, "changes": {link.lobby.id: {"started": true, "level": HOUSE}}})
	_rt(host).parts.ask(Command.new(LaundryDay.LOAD, 1, _day(host).id))
	await _until(func() -> bool: return _rt(host).final_screen.is_open() and _rt(guest).final_screen.is_open(), "the Final screen on both machines", FPS * 20)
	_hook(host)
	_hook(guest)
	var screen := _rt(guest).final_screen
	screen.skip()
	await _until(func() -> bool: return screen.continue_button().visible, "the Guest's Continue to show", FPS * 20)
	await _click(screen.continue_button())
	await _until(func() -> bool: return _lobbies.has("Host") and _lobbies.has("Guest"), "both machines to be in the Lobby", FPS * 20)
	var hl := _lobbies["Host"] as LobbyScreen
	var gl := _lobbies["Guest"] as LobbyScreen
	_check(hl.mode == LobbyScreen.Mode.HOST and gl.mode == LobbyScreen.Mode.JOIN, "the Host is the Host and the Guest a Guest")
	await _until(func() -> bool: return hl.link.roster.peers().size() == 2 and gl.link.roster.peers().size() == 2, "the same Roster on both", FPS * 10)
	_check(not hl.link.lobby.started and not gl.link.lobby.started, "the Lobby is open again: not started")
	await _until(func() -> bool: return gl.link.lobby.line.begins_with("Finished"), "the card to say Finished on the Guest", FPS * 10)
	_check(gl.link.lobby.line.contains("played") and hl.link.lobby.line == gl.link.lobby.line, "with its play time: %s" % gl.link.lobby.line)
	var rows: Array = gl.link.lobby.worlds
	_check(rows.any(func(r: Variant) -> bool: return String((r as Dictionary)["slot"]) == "coop1" and String((r as Dictionary)["details"]).begins_with("Finished")),
			"the World's row says Finished (%s)" % [rows])
	# Ready, then Start asks first.
	await _click(gl.get_node("%Ready") as Control)
	await _click(hl.get_node("%Ready") as Control)
	await _until(func() -> bool: return hl.link.lobby.all_ready(), "everyone Ready", FPS * 10)
	await _click(hl.get_node("%Start") as Control)
	_check(hl.asking() and not hl.link.lobby.started and _into.is_empty(), "Start asks and does not start")
	_check((hl.get_node("Ask/Center/Panel/Box/Question") as Label).text == LobbyWords.FINISHED_ASK, "with the words of the finished World")
	await _click(hl.get_node("%AskYes") as Control)
	_check(hl.link.lobby.started, "its yes starts the game")
	await _until(func() -> bool: return _into.size() == 3, "the Host to go into the house", FPS * 10)
	var fresh := _world_of(_into)
	_check(fresh != null and fresh.is_new and fresh.slot == "coop1", "with a New Game in the finished World's slot")


func case_solo_new_game() -> void:
	var world := Worlds.pick_slot(Worlds.SOLO, false, true)
	var link := GameLink.make()
	add_child(link)
	_loose.append(link)
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var rt := _rt(house)
	rt.world = world
	rt.from_title = true
	add_child(house)
	_loose.append(house)
	await _until(func() -> bool: return rt.loading.is_lifted() and rt.parts.is_bound and rt.player.is_on_floor(), "the house to start", 3000, 30.0)
	await _until(func() -> bool: return _day(house).drawn and _stages(house).due.is_empty(), "the run to start", 3000, 20.0)
	_day(house).cutscene = false
	_one_bin_left(house)
	rt.parts.ask(Command.new(LaundryDay.LOAD, 1, _day(house).id))
	await _until(func() -> bool: return rt.final_screen.is_open(), "the Final screen", 900, 20.0)
	_hook(house, "Solo", self)
	rt.final_screen.skip()
	await _until(func() -> bool: return rt.final_screen.continue_button().visible, "Continue to show", 900, 20.0)
	await _click(rt.final_screen.continue_button())
	await _until(func() -> bool: return _lobbies.has("Solo"), "the Lobby", 900)
	var lobby := _lobbies["Solo"] as LobbyScreen
	await _frames(3)
	_check(lobby.mode == LobbyScreen.Mode.SOLO and lobby.world != null and lobby.world.record.finished, "Solo's Lobby has the finished World chosen")
	_check(not (lobby.get_node("%Continue") as Control).visible, "it has no Continue")
	await _click(lobby.get_node("%NewGame") as Control)
	_check(lobby.asking() and _into.is_empty(), "New Game asks first")
	_check((lobby.get_node("Ask/Center/Panel/Box/Question") as Label).text == LobbyWords.FINISHED_ASK, "with the finished World's words")
	await _click(lobby.get_node("%AskYes") as Control)
	var fresh := _world_of(_into)
	_check(fresh != null and fresh.is_new and fresh.slot == Worlds.SOLO, "a New Game in the Solo slot")


func case_never_loads() -> void:
	var rec := WorldRecord.new()
	rec.level = Worlds.LEVEL
	rec.finished = true
	rec.play_time = 3700.0
	_check(bool(Save.write_now(Worlds.file_of(Worlds.SOLO), {"world": rec.to_dict(), "parts": {}, "versions": {}})["ok"]), "a finished Solo save")
	var m := _machine("Solo")
	var lobby := _make_lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_slot(Worlds.SOLO, false))
	await _frames(3)
	var details := String(Worlds.rows()[0]["details"])
	_check(details.begins_with("Finished · played 1h 01m"), "the row says Finished and the play time (%s)" % details)
	lobby.continue_world()
	await _frames(2)
	_check(_into.is_empty() and not lobby.is_going(), "Continue does nothing on a finished World")


# --- Machines -------------------------------------------------------------------------------------

func _machine(label: String) -> Node:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(1920, 1080)
	node.add_child(view)
	_machines.append(node)
	return node


## A house in a machine of its own, its game link made beside it first (as the title does) so it outlives the house.
func _branch(label: String, world: WorldSlot) -> Node3D:
	var node := _machine(label)
	var link := GameLink.make()
	node.add_child(link)
	link.session.profile = world.profile if world != null else PlayerProfile.fresh()
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var rt := _rt(house)
	rt.world = world
	rt.from_title = world != null
	node.get_node("View").add_child(house)
	return house


## The way back to the Lobby, as a test: the house goes and a Lobby takes its place in the same machine.
func _hook(house: Node3D, label := "", home: Node = null) -> void:
	var rt := _rt(house)
	var machine := home if home != null else house.get_parent().get_parent()
	var key := label if label != "" else String(machine.name)
	rt.go_into_lobby = func(setup: Callable) -> void:
		var swap := func() -> void:
			house.get_parent().remove_child(house)
			house.free()
			_lobbies[key] = _make_lobby(machine, LobbyScreen.Mode.SOLO, null, setup)
		swap.call_deferred()


func _make_lobby(machine: Node, mode: LobbyScreen.Mode, world: WorldSlot, setup := Callable()) -> LobbyScreen:
	if GameLink.of(machine) == null:
		machine.add_child(GameLink.make())
	var lobby := (load(LobbyScreen.SCENE) as PackedScene).instantiate() as LobbyScreen
	lobby.mode = mode
	lobby.world = world
	if setup.is_valid():
		setup.call(lobby)
	lobby.go_into = func(path: String, heading: String, st: Callable) -> void:
		if lobby.mode != LobbyScreen.Mode.JOIN:  # a Guest's Lobby follows the Host's into the house too
			_into = [path, heading, st]
	var view := machine.get_node_or_null("View")
	(view if view != null else machine).add_child(lobby)
	_loose.append(lobby)
	return lobby


## The World the setup hands a level.
func _world_of(into: Array) -> WorldSlot:
	if into.size() < 3:
		return null
	var root := Node.new()
	var runtime := LevelRuntime.new()
	root.add_child(runtime)
	(into[2] as Callable).call(root)
	var w := runtime.world
	root.free()
	return w


func _rt(house: Node3D) -> LevelRuntime:
	return LevelRuntime.of(house)


func _stages(house: Node3D) -> Stages:
	return house.get_node("Run/Stages") as Stages


func _day(house: Node3D) -> LaundryDay:
	return house.get_node("LaundryDay/Day") as LaundryDay


## Every drawn bin but the one by the washer loaded, the last Fix and the First wash done, that bin in the Host's Hands.
func _one_bin_left(house: Node3D) -> void:
	var day := _day(house)
	var changes := {day.id: {"first_wash": LaundryDay.FirstWash.DONE, "loaded_bins": day.total() - 1}, _stages(house).id: {"phase": Stages.Phase.FIXED}}
	var last: LaundryBin = null
	for bin in day.used_bins():
		if bin.always:
			last = bin
		else:
			changes[bin.id] = {"full": false}
	changes[last.carriable.id] = {"holder": 1}
	_rt(house).parts.apply({"ok": true, "changes": changes})
	_rt(house).player.global_position = (Washer.of_level(house).get_parent() as Node3D).global_position + Vector3(1.9, 0.0, 0.0)


func _click(control: Control) -> void:
	await _frames(2)
	var at := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = pressed
		get_tree().root.window_input.emit(ev)
		control.get_viewport().push_input(ev, true)
	await _frames(2)


func _drop_all() -> void:
	for node in _machines:
		if not is_instance_valid(node):
			continue
		var link := GameLink.of(node)
		if link != null:
			link.session.close()
		var path := node.get_path()
		node.get_parent().remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_machines.clear()
	for node in _loose:
		if is_instance_valid(node):
			var runtime := LevelRuntime.of(node) if node is Node3D else null
			if runtime != null:
				runtime.session.close()
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_loose.clear()
