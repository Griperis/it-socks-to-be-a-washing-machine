## The Lobby scene and LobbyState (core/63, docs/architecture/lobby.md "Core/63", Q2582, Q2583): a Guest's
## Ready is its own only and guarded; Start is the Host's only and needs everyone present Ready; a
## leaver is forgotten, a joiner is not Ready; choosing a World clears Ready; Ready is never saved; the
## Host's Back ends the session for everyone, a Guest's Leave (Esc) leaves alone; a Guest that connects
## after Start skips the Lobby into the Host's level; Solo's bar (Continue, New Game that asks first).
## The real path from both titles through Ready and Start into the house is game_link_test l06.
extends TestSuite

const ONE_BOX := "res://game/level/one_box_level.tscn"
const LagPeer := preload("res://tests/support/lag_peer.gd")

var _branches: Array[Node] = []
## What the Lobbies did: ["<machine>:title:<notice>"], ["<machine>:into:<path>"].
var _did: Array[String] = []
## The last way into the house a Lobby asked for: [path, heading, setup].
var _into: Array = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "k01_ready_guard", "method": "case_k01", "world": false,
				"title": "a Guest's Ready is its own: another id in the args, a non-bool and a flood are dropped and counted; it cannot ask start or world; the Host's Start is refused until everyone present is Ready, then every machine sees started"},
		{"name": "k02_leaver_joiner", "method": "case_k02", "world": false,
				"title": "a joiner is not Ready; a leaver is forgotten as Ready on every machine; choosing a World clears Ready; Ready is never saved"},
		{"name": "k03_back_ends_session", "method": "case_k03", "world": false,
				"title": "the Host's Back (its key) ends the session: the Guest's Lobby goes to its title with \"The Host ended the session\", the Host's with no notice"},
		{"name": "k04_leave_esc", "method": "case_k04", "world": false,
				"title": "a Guest's Esc is Leave: it goes to its title alone, the Host forgets it and stays"},
		{"name": "k05_late_joiner_skips", "method": "case_k05", "world": false,
				"title": "a Guest that connects after the Host's Start skips the Lobby: it goes into the Host's level at once, as a Guest, and is welcomed there"},
		{"name": "k05_late_joiner_skips_50ms", "method": "case_k05_50ms", "world": false,
				"title": "the late joiner with 50 ms each way"},
		{"name": "k06_solo_bar", "method": "case_k06", "world": false,
				"title": "Solo's Lobby: one place, no Ready or Start; no save: Continue hidden and New Game goes in at once; a save: Continue goes on with it, New Game asks \"Start a new game? The saved game is lost.\" (Cancel stays, New game goes in with a New Game)"},
	]


func _before_case() -> void:
	_drop_branches()
	_did.clear()
	_into.clear()


func _after_case() -> void:
	_drop_branches()
	_into.clear()


# --- K01 ------------------------------------------------------------------------------------------

func case_k01() -> void:
	var pair := await _linked_pair(0)
	var hl := GameLink.of(pair[0])
	var gl := GameLink.of(pair[1])
	var hs := hl.session
	var gs := gl.session
	var g_peer := gs.me()
	var g_id := gs.profile.id
	var lobby_id := hl.lobby.id
	_check(String(lobby_id) == "Runtime/LobbyState" and gl.lobby.id == lobby_id, "LobbyState is a Part of the link (%s)" % lobby_id)
	hl.parts.ask(hl.lobby.world_command(1, ONE_BOX, "New World", "", "coop1"))
	await _until(func() -> bool: return gl.lobby.level == ONE_BOX, "the Host's World to reach the Guest", 900, 20.0)
	# The Guest's own Ready, through its Parts.
	gl.parts.ask(gl.lobby.ready_command(g_peer, true))
	await _until(func() -> bool: return hl.lobby.readied.has(g_id) and gl.lobby.readied.has(g_id), "the Guest's Ready on both", 900, 20.0)
	# Another id in the args, a non-bool: dropped as args, nothing changes.
	gs._command.rpc_id(1, Command.new(LobbyState.READY, g_peer, lobby_id, {"on": false, "id": hs.profile.id}).to_wire())
	gs._command.rpc_id(1, Command.new(LobbyState.READY, g_peer, lobby_id, {"on": 0}).to_wire())
	# The Host's verbs: not a Guest's.
	gs._command.rpc_id(1, Command.new(LobbyState.START, g_peer, lobby_id).to_wire())
	gs._command.rpc_id(1, Command.new(LobbyState.WORLD, g_peer, lobby_id, {"level": "x", "title": "x", "line": "", "world": "x"}).to_wire())
	await _until(func() -> bool: return _counted(hs, "args") == 2 and _counted(hs, "verb") == 2, "the four to be dropped", 900, 20.0)
	_check(hl.lobby.readied == PackedStringArray([g_id]) and not hl.lobby.started and hl.lobby.level == ONE_BOX,
			"none changed anything (%s)" % [hl.lobby.state()])
	# A flood: more than the rate in one go.
	for i in LobbyState.READY_RATE * 3:
		gs._command.rpc_id(1, Command.new(LobbyState.READY, g_peer, lobby_id, {"on": i % 2 == 0}).to_wire())
	await _until(func() -> bool: return _counted(hs, "rate") >= LobbyState.READY_RATE, "the flood to be dropped as rate", 900, 20.0)
	await _wall(200)
	# Whatever got through, the Guest settles its Ready on: off.
	gl.parts.ask(gl.lobby.ready_command(g_peer, false))
	await _wall(1100)  # a fresh second for the rate
	gl.parts.ask(gl.lobby.ready_command(g_peer, true))
	await _until(func() -> bool: return hl.lobby.readied == PackedStringArray([g_id]), "the Guest Ready again after the flood", 900, 20.0)
	# Start: refused while the Host is not Ready.
	hl.parts.ask(hl.lobby.start_command(1))
	_check(not hl.lobby.started, "Start refused: the Host is not Ready")
	hl.parts.ask(hl.lobby.ready_command(1, true))
	_check(hl.lobby.all_ready(), "everyone present is Ready")
	hl.parts.ask(hl.lobby.start_command(1))
	_check(hl.lobby.started, "Start once everyone is Ready")
	await _until(func() -> bool: return gl.lobby.started, "started to reach the Guest", 900, 20.0)
	gl.parts.ask(gl.lobby.ready_command(g_peer, false))
	await _wall(300)
	_check(hl.lobby.readied.has(g_id), "after Start a Ready no longer changes")


# --- K02 ------------------------------------------------------------------------------------------

func case_k02() -> void:
	var pair := await _linked_pair(0)
	var hl := GameLink.of(pair[0])
	var g1 := GameLink.of(pair[1])
	var g1_id := g1.session.profile.id
	g1.parts.ask(g1.lobby.ready_command(g1.session.me(), true))
	hl.parts.ask(hl.lobby.ready_command(1, true))
	await _until(func() -> bool: return hl.lobby.all_ready(), "the Host and the first Guest Ready", 900, 20.0)
	# A second Guest joins: not Ready, so not everyone is.
	var m2 := _machine("Guest2")
	var g2 := _link_in(m2)
	await _frames(2)
	g2.session.profile = PlayerProfile.fresh()
	_check(g2.session.join("127.0.0.1:%d" % hl.session.port) == OK, "a second Guest joins")
	await _until(func() -> bool: return hl.roster.peers().size() == 3 and g2.roster.peers().size() == 3, "the second Guest in", 900, 20.0)
	_check(not hl.lobby.is_ready(g2.session.me()) and not hl.lobby.all_ready(), "a joiner is not Ready")
	await _until(func() -> bool: return g2.lobby.readied.size() == 2, "the joiner sees who is Ready", 900, 20.0)
	# The first Guest leaves: forgotten as Ready, on every machine.
	g1.session.close()
	await _until(func() -> bool: return not hl.lobby.readied.has(g1_id) and not g2.lobby.readied.has(g1_id), "the leaver to be forgotten as Ready", 900, 20.0)
	_check(hl.lobby.readied == PackedStringArray([hl.session.profile.id]), "the Host stays Ready (%s)" % [hl.lobby.readied])
	# Choosing a World clears Ready.
	hl.parts.ask(hl.lobby.world_command(1, ONE_BOX, "Ada, Mia", "Floor 1", "coop2"))
	await _until(func() -> bool: return g2.lobby.title == "Ada, Mia", "the World's card to reach the Guest", 900, 20.0)
	_check(hl.lobby.readied.is_empty() and g2.lobby.readied.is_empty(), "a chosen World clears Ready")
	# Ready is never saved.
	hl.parts.ask(hl.lobby.ready_command(1, true))
	_check(hl.lobby.save_state().is_empty() and not hl.parts.save_snapshot().has(String(hl.lobby.id)), "Ready is never saved")


# --- K03 ------------------------------------------------------------------------------------------

func case_k03() -> void:
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hlobby := await _lobby(host, LobbyScreen.Mode.HOST, _host_world())
	await _until(func() -> bool: return hlobby.link.session.is_online(), "the Host's Lobby to listen", 900, 20.0)
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hlobby.link.session.port)
	await _until(func() -> bool: return hlobby.link.roster.peers().size() == 2 and globby.place_texts()[1].contains(PlayerProfile.NAME),
			"the Guest in both Lobbies", 900, 20.0)
	_check((hlobby.get_node("%Back") as Button).text == LobbyScreen.BACK, "the Host's key reads Back")
	globby.visible = false
	await _click(hlobby.get_node("%Back") as Control)
	await _until(func() -> bool: return _did.has("Guest:title:" + Session.HOST_QUIT), "the Guest to go to its title with the reason", 900, 20.0)
	_check(_did.has("Host:title:"), "the Host to its title with no notice (%s)" % [_did])
	_check(not hlobby.link.session.is_online() and not globby.link.session.is_online(), "the session is over on both")


# --- K04 ------------------------------------------------------------------------------------------

func case_k04() -> void:
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hl := _link_in(host)
	await _frames(2)
	hl.session.profile = PlayerProfile.fresh()
	_check(hl.session.host() == OK, "the Host listens")
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hl.session.port)
	await _until(func() -> bool: return hl.roster.peers().size() == 2 and globby.place_texts().size() == 4 and globby.place_texts()[1] != LobbyScreen.WAITING_PLAYER,
			"the Guest in the Lobby", 900, 20.0)
	_check((globby.get_node("%Back") as Button).text == LobbyScreen.LEAVE, "a Guest's key reads Leave")
	await _key(&"ui_cancel")
	await _until(func() -> bool: return _did.has("Guest:title:"), "Esc to take the Guest to its title", 900, 20.0)
	await _until(func() -> bool: return hl.roster.peers().size() == 1, "the Host to forget the Guest", 900, 20.0)
	_check(hl.session.is_online() and not _did.has("Host:title:"), "the Host stays, listening")


# --- K05 ------------------------------------------------------------------------------------------

func case_k05() -> void:
	await _late_joiner(0)


func case_k05_50ms() -> void:
	await _late_joiner(50)


func _late_joiner(lag_ms: int) -> void:
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hl := _link_in(host)
	await _frames(2)
	hl.session.profile = PlayerProfile.fresh()
	_check(hl.session.host() == OK, "the Host listens")
	if lag_ms > 0:
		_lag(host, lag_ms)
	hl.parts.ask(hl.lobby.world_command(1, ONE_BOX, "New World", "", "coop1"))
	hl.parts.ask(hl.lobby.ready_command(1, true))
	hl.parts.ask(hl.lobby.start_command(1))
	_check(hl.lobby.started, "the Host started alone")
	var hlevel := await _level_in(host)
	var hr := LevelRuntime.of(hlevel)
	_check(hr.link == hl, "the Host's level plays through its link")
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hl.session.port, lag_ms)
	var gl := globby.link
	await _until(func() -> bool: return not _into.is_empty(), "the Guest to go on into the level", 900, 20.0)
	_check(String(_into[0]) == ONE_BOX and _did == ["Guest:into:" + ONE_BOX], "into the Host's level, the Lobby skipped (%s)" % [_did])
	_check(globby.is_going() and (globby.get_node("%Ready") as Button).disabled, "its keys lock")
	# The level as SceneChanger would put it in.
	var root := (load(ONE_BOX) as PackedScene).instantiate()
	(_into[2] as Callable).call(root)
	var gr := LevelRuntime.of(root)
	_check(gr.launch_joins() and gr.world == null and gr.from_title, "as a Guest from the title, with no World")
	guest.remove_child(globby)
	globby.queue_free()
	var welcomed: Array[bool] = []
	gl.session.welcomed.connect(func() -> void: welcomed.append(true))
	(guest.get_node("View") as Node).add_child(root)
	await _until(func() -> bool: return not welcomed.is_empty(), "the late Guest to be welcomed into the level", 900, 20.0)
	var g_peer := gl.session.me()
	await _until(func() -> bool: return hr.avatars.of(g_peer) != null and gr.avatars.of(1) != null, "each to see the other's avatar", 900, 20.0)
	var g_at: Variant = hl.roster.entry_of(g_peer).get("at")
	_check(g_at is Vector3 and Vector2(gr.player.global_position.x, gr.player.global_position.z).distance_to(Vector2((g_at as Vector3).x, (g_at as Vector3).z)) < 0.3,
			"the Guest stands at its Roster spot (%s, %s)" % [gr.player.global_position, g_at])


# --- K06 ------------------------------------------------------------------------------------------

func case_k06() -> void:
	var m := _machine("Solo")
	var lobby := await _lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_solo())
	await _frames(3)
	_check(lobby.place_texts().size() == 1 and lobby.place_texts()[0] == PlayerProfile.NAME, "one place, the player's (%s)" % [lobby.place_texts()])
	_check(not (lobby.get_node("%Ready") as Control).visible and not (lobby.get_node("%Start") as Control).visible
			and not (lobby.get_node("%Waiting") as Control).visible, "no Ready, no Start")
	_check(not (lobby.get_node("%Continue") as Control).visible and (lobby.get_node("%NewGame") as Control).visible, "no save: Continue hidden")
	_check((lobby.get_node("%CardTitle") as Label).text == LobbyScreen.SOLO_TITLE, "the card says Solo")
	await _click(lobby.get_node("%NewGame") as Control)
	_check(not lobby.asking() and _into.size() == 3, "New Game with no save goes in at once")
	_check(_world_of(_into).is_new and _world_of(_into).slot == Worlds.SOLO, "with a New Game in the Solo slot")
	_drop_branches()
	_into.clear()
	_did.clear()
	# A saved Solo World.
	var rec := WorldRecord.new()
	rec.level = Worlds.LEVEL
	rec.floor_name = "Basement"
	rec.last_played = 1_700_000_000
	_check(bool(Save.write_now(Worlds.file_of(Worlds.SOLO), {"world": rec.to_dict(), "parts": {}, "versions": {}})["ok"]), "a Solo save written")
	m = _machine("Solo")
	lobby = await _lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_solo())
	await _frames(3)
	_check((lobby.get_node("%Continue") as Control).visible and (lobby.get_node("%CardLine") as Label).text.begins_with(Worlds.SOLO_WORLD + " · Basement"),
			"a save: Continue shows, the card's line the Solo World (%s)" % (lobby.get_node("%CardLine") as Label).text)
	await _click(lobby.get_node("%NewGame") as Control)
	_check(lobby.asking() and _into.is_empty(), "New Game over a save asks first")
	_check((lobby.get_node("Ask/Center/Panel/Box/Question") as Label).text == "Start a new game? The saved game is lost.", "with the old words")
	await _click(lobby.get_node("%AskNo") as Control)
	_check(not lobby.asking() and _into.is_empty(), "Cancel goes back to the Lobby")
	await _click(lobby.get_node("%NewGame") as Control)
	await _key(&"ui_cancel")
	_check(not lobby.asking() and _into.is_empty() and _did.is_empty(), "Esc closes the question, the Lobby stays")
	await _click(lobby.get_node("%Continue") as Control)
	_check(_into.size() == 3 and not _world_of(_into).is_new, "Continue goes on with the saved World")
	_drop_branches()
	_into.clear()
	m = _machine("Solo")
	lobby = await _lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_solo())
	await _frames(3)
	await _click(lobby.get_node("%NewGame") as Control)
	await _click(lobby.get_node("%AskYes") as Control)
	_check(_into.size() == 3 and _world_of(_into).is_new and _world_of(_into).slot == Worlds.SOLO, "New game after asking: a New Game over the Solo World")


func _world_of(into: Array) -> WorldSlot:
	var root := (load(ONE_BOX) as PackedScene).instantiate()
	(into[2] as Callable).call(root)
	var w := LevelRuntime.of(root).world
	root.free()
	return w


# --- Machines -------------------------------------------------------------------------------------

func _machine(label: String) -> Node:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	_branches.append(node)
	return node


func _link_in(machine: Node) -> GameLink:
	var link := GameLink.make()
	machine.add_child(link)
	return link


## A Lobby in `machine` (its link made beside it, as the title does), its ways out noted.
func _lobby(machine: Node, mode: LobbyScreen.Mode, world: WorldSlot, address := "", lag_ms := 0) -> LobbyScreen:
	var link := _link_in(machine)
	if mode == LobbyScreen.Mode.JOIN:
		link.session.profile = PlayerProfile.fresh()  # one process: each Guest its own player
	var lobby := (load(LobbyScreen.SCENE) as PackedScene).instantiate() as LobbyScreen
	lobby.mode = mode
	lobby.world = world
	lobby.address = address
	var label := String(machine.name)
	lobby.go_to_title = func(notice: String) -> void: _did.append("%s:title:%s" % [label, notice])
	lobby.go_into = func(path: String, heading: String, setup: Callable) -> void:
		_did.append("%s:into:%s" % [label, path])
		_into = [path, heading, setup]
	machine.add_child(lobby)
	if lag_ms > 0:
		(func() -> void: _lag(machine, lag_ms)).call_deferred()
	await _frames(2)
	return lobby


func _host_world() -> WorldSlot:
	var w := Worlds.pick_host()
	w.record.level = ONE_BOX
	return w


func _linked_pair(lag_ms: int) -> Array[Node]:
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hl := _link_in(host)
	var gl := _link_in(guest)
	await _frames(2)
	hl.session.profile = PlayerProfile.fresh()
	gl.session.profile = PlayerProfile.fresh()
	_check(hl.session.host() == OK, "the Host's link listens")
	if lag_ms > 0:
		_lag(host, lag_ms)
	var linked: Array[bool] = []
	gl.session.linked.connect(func() -> void: linked.append(true))
	_check(gl.session.join("127.0.0.1:%d" % hl.session.port) == OK, "the Guest's link joins")
	if lag_ms > 0:
		_lag(guest, lag_ms)
	await _until(func() -> bool: return not linked.is_empty() and hl.roster.peers().size() == 2, "the Guest to be in the game", 900, 20.0)
	return [host, guest]


func _level_in(machine: Node) -> Node:
	var l := (load(ONE_BOX) as PackedScene).instantiate()
	(machine.get_node("View") as Node).add_child(l)
	var rt := LevelRuntime.of(l)
	await _until(func() -> bool: return rt.parts.is_bound and rt.parts.is_settled(), "the level's Parts to bind")
	return l


func _drop_branches() -> void:
	for node in _branches:
		if not is_instance_valid(node):
			continue
		var link := node.get_node_or_null(NodePath(GameLink.NAME)) as GameLink
		if link != null:
			link.session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


func _lag(machine: Node, lag_ms: int) -> void:
	var mp := machine.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


func _wall(ms: int) -> void:
	var until := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < until:
		OS.delay_msec(2)
		await get_tree().process_frame


func _counted(s: Session, reason: String) -> int:
	var n := 0
	for peer: int in s.dropped:
		n += int(s.dropped[peer].get(reason, 0))
	return n


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


func _key(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)
