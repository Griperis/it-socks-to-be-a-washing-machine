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
				"title": "Solo's Lobby: one place, no Ready or Start; no save: Continue hidden and New Game goes in at once; a save: Continue goes on with it, New Game asks \"Start a new game? The saved game is lost.\" (the close key at its top right or Esc stays, Q2578; New game goes in with a New Game)"},
		{"name": "k07_display_name", "method": "case_k07", "world": false,
				"title": "display_name is the one maker of a row's name (Q2587): \"Solo World\", a co-op World's members' names in order, \"No Group yet\"; Worlds.rows() uses it; pick_slot picks the World in a slot"},
		{"name": "k08_drawer_real_path", "method": "case_k08", "world": false,
				"title": "real path: the Host's drawer starts open and a Guest's shut; Choose clears Ready; the Host shuts it (it slides), deletes the chosen World through the question (the close key backs out) and the Lobby lands on the last-played World on both machines; chooses the Solo World; New game takes the first free slot; the Guest's drawer is the same list read-only with the chosen one ticked"},
		{"name": "k09_drawer_full", "method": "case_k09", "world": false,
				"title": "five co-op Worlds used: New game and choosing the Solo World show the full page (\"All 5 co-op Worlds are used: delete one first\"); deleting one there goes on at once; a damaged World has only Delete; Solo has no drawer"},
		{"name": "k10_join_fills_place", "method": "case_k10", "world": false,
				"title": "real path: a Guest's join fills a place on both screens: the free place's silhouette and \"Waiting for a player\" give way to an Avatar in the Guest's colour, its name in that colour under the pedestal, on the Host's Lobby and the Guest's own"},
		{"name": "k11_pad_route", "method": "case_k11", "world": false,
				"title": "real path: the pad's first press selects the \"i\" key (Back when the World has no one to list, Solo's too); Down goes to the figures, Right walks them, Right of the last goes into the open drawer, Left comes back, Down reaches the bottom keys and Up returns"},
		{"name": "k12_captions_ready_tick", "method": "case_k12", "world": false,
				"title": "real path: the captions \"press again to un-ready\" and \"when everyone is Ready\" show as the list says and keep their line; the Ready key ticks (hover) and does not click, every other key clicks"},
		{"name": "k13_invite_hook", "method": "case_k13", "world": false,
				"title": "ENet cannot invite: the Host's \"Invite friends\" key is hidden; a test transport that can shows it, in the Host's drawer only, and the key asks that transport"},
		{"name": "k14_words_one_place_narrow_camera", "method": "case_k14", "world": false,
				"title": "the Lobby's scenes carry no text of their own (LobbyWords is the one place); the status line is empty and hidden; a narrower-than-16:9 stage keeps the width a 16:9 one sees"},
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
	_check((hlobby.get_node("%Back") as Button).text == LobbyWords.BACK, "the Host's key reads Back")
	globby.visible = false
	await _click(hlobby.get_node("%Back") as Control)
	await _until(func() -> bool: return _did.has("Guest:title:" + Session.HOST_QUIT), "the Guest to go to its title with the reason", 900, 20.0)
	_check(_did.has("Host:title:"), "the Host to its title with no notice (%s)" % [_did])
	_check(not hlobby.link.session.is_online() and not globby.link.session.is_online(), "the session is over on both")


# --- K10 ------------------------------------------------------------------------------------------

func case_k10() -> void:
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hlobby := await _lobby(host, LobbyScreen.Mode.HOST, _host_world())
	await _until(func() -> bool: return hlobby.link.session.is_online(), "the Host's Lobby to listen", 900, 20.0)
	_check(hlobby.stage().is_free(1) and hlobby.places()[1].is_free() and hlobby.place_texts()[1] == LobbyWords.WAITING_PLAYER,
			"before the join place 2 is a silhouette that waits (%s)" % [hlobby.place_texts()])
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hlobby.link.session.port)
	await _until(func() -> bool: return hlobby.link.roster.peers().size() == 2 and not globby.stage().is_free(1) and not hlobby.stage().is_free(1),
			"the Guest's place to fill on both screens", 900, 20.0)
	for lobby: LobbyScreen in [hlobby, globby]:
		var colour := lobby.link.roster.colour_of(lobby.link.roster.peers()[1])
		_check(not lobby.places()[1].is_free() and lobby.stage().figure(1).colour == colour, "an Avatar in the Guest's colour stands there")
		_check(lobby.place_texts()[1].begins_with(PlayerProfile.NAME) and lobby.place_texts()[2] == LobbyWords.WAITING_PLAYER,
				"its name is under the pedestal, the next place waits (%s)" % [lobby.place_texts()])


# --- K04 ------------------------------------------------------------------------------------------

func case_k04() -> void:
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hl := _link_in(host)
	await _frames(2)
	hl.session.profile = PlayerProfile.fresh()
	_check(hl.session.host() == OK, "the Host listens")
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hl.session.port)
	await _until(func() -> bool: return hl.roster.peers().size() == 2 and globby.place_texts().size() == 4 and globby.place_texts()[1] != LobbyWords.WAITING_PLAYER,
			"the Guest in the Lobby", 900, 20.0)
	_check((globby.get_node("%Back") as Button).text == LobbyWords.LEAVE, "a Guest's key reads Leave")
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
	_check((lobby.get_node("%CardTitle") as Label).text == LobbyWords.SOLO_TITLE, "the card says Solo")
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
	var close := lobby.get_node("%AskClose") as CloseButton
	var area := close.get_global_rect()  # it fills the panel's inside, as every dialogue's (menus x01)
	_check(close.key().is_visible_in_tree() and absf(close.key().get_global_rect().end.x - area.end.x) < 1.0
			and close.key().get_global_rect().position.y - area.position.y < 24.0 and close.key().icon == UiIcons.texture("key_esc"),
			"the question has the ESC close key at its top right (Q2578)")
	_check(lobby.find_children("*", "Button", true, false).all(func(b: Node) -> bool: return (b as Button).text != "Cancel"), "and no Cancel")
	await _click(close.key())
	_check(not lobby.asking() and _into.is_empty(), "the close key goes back to the Lobby")
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


# --- K07 ------------------------------------------------------------------------------------------

func case_k07() -> void:
	var rec := WorldRecord.new()
	rec.kind = WorldRecord.COOP
	_check(Worlds.display_name("coop1", rec) == Worlds.NO_GROUP, "no members: \"No Group yet\"")
	rec.members = {"a": {"name": "Ada", "colour": 1}, "b": {"name": "Mia", "colour": 2}}
	_check(Worlds.display_name("coop1", rec) == "Ada, Mia", "the members' names, in order (%s)" % Worlds.display_name("coop1", rec))
	_check(Worlds.display_name(Worlds.SOLO, rec) == Worlds.SOLO_WORLD, "the Solo World's name")
	_check(Worlds.member_colours(rec) == [1, 2], "their colours, in the same order")
	_write_world("coop1", {"a": {"name": "Ada", "colour": 1}}, 100)
	var rows := Worlds.rows()
	_check(rows.size() == 1 and rows[0]["name"] == "Ada" and rows[0]["colours"] == [1], "rows() names through display_name (%s)" % [rows])
	var picked := Worlds.pick_slot("coop1", true)
	_check(picked.slot == "coop1" and picked.hosting and not picked.is_new, "pick_slot: the saved World, hosted")
	_check(Worlds.pick_slot("coop2", true, true).is_new, "pick_slot fresh: a New Game")


# --- K08 ------------------------------------------------------------------------------------------

func case_k08() -> void:
	_write_world(Worlds.SOLO, {}, 50)
	_write_world("coop1", {"a": {"name": "Ann", "colour": 0}}, 100)
	_write_world("coop2", {"b": {"name": "Bob", "colour": 1}}, 200)
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hlobby := await _lobby(host, LobbyScreen.Mode.HOST, _host_world())
	await _until(func() -> bool: return hlobby.link.session.is_online(), "the Host's Lobby to listen", 900, 20.0)
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hlobby.link.session.port)
	var hd := hlobby.drawer()
	var gd := globby.drawer()
	await _until(func() -> bool: return gd.row_nodes().size() == 3 and hd.row_nodes().size() == 3, "both drawers to list three Worlds", 900, 20.0)
	_check(_slots(hd) == ["solo", "coop2", "coop1"] and _slots(gd) == ["solo", "coop2", "coop1"],
			"the Solo World first, the co-op Worlds newest first, on both (%s / %s)" % [_slots(hd), _slots(gd)])
	_check(hd.is_open() and not gd.is_open(), "the Host's drawer starts open, the Guest's shut")
	_check(hd.panel_x() < hd.size.x - 400.0 and gd.panel_x() >= gd.size.x - 1.0, "the open one shows its width, the shut one is off the edge")
	_check((globby.get_node("%CardTitle") as Label).text == "Bob", "the card says Bob")
	# The Guest's list: read-only, the chosen one ticked, every World.
	var g_rows := gd.row_nodes()
	_check(g_rows.all(func(r: WorldRow) -> bool: return not (r.get_node("%Choose") as Button).visible and not (r.get_node("%Delete") as Button).visible),
			"a Guest's rows have no Choose and no Delete")
	_check((g_rows[1].get_node("%Tick") as Label).visible and not (g_rows[0].get_node("%Tick") as Label).visible and not (g_rows[2].get_node("%Tick") as Label).visible,
			"the chosen one is ticked")
	_check(g_rows[1].find_children("*", "ColorRect", true, false).size() == 1, "a swatch per Group member")
	# Ready, then the drawer's Choose clears it.
	globby.visible = false
	await _click(hlobby.get_node("%Ready") as Control)
	await _until(func() -> bool: return globby.link.lobby.readied.size() == 1, "the Host's Ready on both", 900, 20.0)
	await _click(_choose_key(hd, "coop1"))
	await _until(func() -> bool: return globby.link.lobby.world == "coop1" and (globby.get_node("%CardTitle") as Label).text == "Ann", "the Guest to follow the Host to Ann's World", 900, 20.0)
	_check(hlobby.link.lobby.readied.is_empty() and globby.link.lobby.readied.is_empty(), "Choose clears Ready on every machine")
	await _until(func() -> bool: return _chosen_label(hd, "coop1") == LobbyWords.CHOSEN, "the chosen row to read Chosen", 900, 20.0)
	# The drawer slides shut (not at once) and open again.
	hd.toggle()
	_check(not hd.is_open() and not hd.is_settled(), "shutting it slides")
	await _until(func() -> bool: return hd.is_settled() and hd.panel_x() >= hd.size.x - 1.0, "the drawer to settle shut", 900, 0.0)
	await _click(hd.get_node("%Key") as Control)
	await _until(func() -> bool: return hd.is_settled() and is_equal_approx(hd.panel_x(), hd.size.x - 520.0), "the key to open it again", 900, 0.0)
	# Delete the chosen World: the question first, the close key backs out.
	await _click(_delete_key(hd, "coop1"))
	_check(hd.ask_text() == "Delete Ann? It cannot be brought back." and Save.has(Worlds.file_of("coop1")), "Delete asks first")
	await _click((hd.get_node("%AskClose") as CloseButton).key())
	_check(hd.ask_text() == "" and Save.has(Worlds.file_of("coop1")), "its close key leaves the World alone")
	await _click(_delete_key(hd, "coop1"))
	await _click(hd.get_node("%AskDelete") as Control)
	_check(not Save.has(Worlds.file_of("coop1")), "the World's file is gone")
	await _until(func() -> bool: return gd.row_nodes().size() == 2 and globby.link.lobby.world == "coop2", "the Guest to see the list and the Lobby land on Bob's World", 900, 20.0)
	_check((hlobby.get_node("%CardTitle") as Label).text == "Bob" and hlobby.world.slot == "coop2", "the Host's Lobby is on the last-played co-op World")
	# The Solo World, then New game.
	await _click(_choose_key(hd, "solo"))
	await _until(func() -> bool: return globby.link.lobby.world == "solo", "the Guest to see the Solo World chosen", 900, 20.0)
	_check((globby.get_node("%CardTitle") as Label).text == Worlds.SOLO_WORLD, "the card says Solo World")
	await _click(hd.get_node("%NewGame") as Control)
	await _until(func() -> bool: return globby.link.lobby.world == "coop1", "New game to take the first free slot", 900, 20.0)
	_check((globby.get_node("%CardTitle") as Label).text == LobbyWords.NEW_WORLD and hlobby.world.is_new, "a New Game in coop1 (card \"New World\")")


# --- K09 ------------------------------------------------------------------------------------------

func case_k09() -> void:
	for i in 5:
		_write_world("coop%d" % (i + 1), {"p%d" % i: {"name": "P%d" % i, "colour": i}}, 100 + i)
	_write_world(Worlds.SOLO, {}, 50)
	Save.store.write(Worlds.file_of("coop3"), "not a world {", false)
	var host := _machine("Host")
	var hlobby := await _lobby(host, LobbyScreen.Mode.HOST, Worlds.pick_slot("coop5", true))
	await _until(func() -> bool: return hlobby.link.session.is_online(), "the Host's Lobby to listen", 900, 20.0)
	var hd := hlobby.drawer()
	await _until(func() -> bool: return hd.row_nodes().size() == 6, "six Worlds listed", 900, 20.0)
	var damaged := _row_of(hd, "coop3")
	_check(not (damaged.get_node("%Choose") as Button).visible and (damaged.get_node("%Delete") as Button).visible
			and (damaged.get_node("%Title") as Label).text == Worlds.DAMAGED_WORLD, "a damaged World shows only Delete")
	var solo_row := hd.row_nodes()[0]
	_check(not (solo_row.get_node("%Delete") as Button).visible and (solo_row.get_node("%Choose") as Button).visible, "the Solo World cannot be deleted")
	# New game with five used: the full page.
	await _click(hd.get_node("%NewGame") as Control)
	_check(hd.dialog_open() and (hd.get_node("%FullLine") as Label).text == "All 5 co-op Worlds are used: delete one first", "New game: the full page asks to delete one")
	_check(hd.row_nodes(true).size() == 5, "it lists the five co-op Worlds")
	await _key(&"ui_cancel")
	_check(not hd.dialog_open() and hlobby.world.slot == "coop5", "Esc closes it, nothing changed")
	# The Solo World with every slot used asks the same.
	await _click(_choose_key(hd, "solo"))
	_check(hd.dialog_open() and hlobby.world.slot == "coop5", "choosing the Solo World asks to delete one first")
	await _click(_delete_key(hd, "coop2", true))
	await _click(hd.get_node("%AskDelete") as Control)
	await _until(func() -> bool: return not hd.dialog_open() and hlobby.link.lobby.world == Worlds.SOLO, "the delete to go on with the Solo World at once", 900, 20.0)
	_check(not Save.has(Worlds.file_of("coop2")) and hlobby.world.slot == Worlds.SOLO, "coop2 is gone and the Solo World is chosen")
	# Full again, New game: goes on with a New Game in the freed slot.
	_write_world("coop2", {"q": {"name": "Q", "colour": 0}}, 300)
	_check(Worlds.free_coop_slot() == "", "five used again")
	await _click(hd.get_node("%NewGame") as Control)
	await _click(_delete_key(hd, "coop4", true))
	await _click(hd.get_node("%AskDelete") as Control)
	await _until(func() -> bool: return hlobby.link.lobby.world == "coop4", "New game to go on in the freed slot", 900, 20.0)
	_check(hlobby.world.is_new and not hd.dialog_open(), "a New Game in coop4, the page gone")
	# Solo has no drawer.
	_drop_branches()
	var m := _machine("Solo")
	var solo := await _lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_solo())
	_check(not solo.drawer().visible, "Solo's Lobby has no drawer")


func _write_world(slot: String, members: Dictionary, last: int) -> void:
	var rec := WorldRecord.new()
	rec.kind = WorldRecord.SOLO if slot == Worlds.SOLO else WorldRecord.COOP
	rec.level = Worlds.LEVEL
	rec.members = members
	rec.last_played = last
	rec.floor_name = "Basement"
	Save.write_now(Worlds.file_of(slot), {"world": rec.to_dict(), "parts": {}, "versions": {}})


func _slots(drawer: WorldDrawer) -> Array:
	return drawer.row_nodes().map(func(r: WorldRow) -> String: return r.slot)


func _row_of(drawer: WorldDrawer, slot: String, in_full := false) -> WorldRow:
	return drawer.row_nodes(in_full).filter(func(r: WorldRow) -> bool: return r.slot == slot)[0]


func _choose_key(drawer: WorldDrawer, slot: String) -> Control:
	return _row_of(drawer, slot).get_node("%Choose") as Control


func _delete_key(drawer: WorldDrawer, slot: String, in_full := false) -> Control:
	return _row_of(drawer, slot, in_full).get_node("%Delete") as Control


func _chosen_label(drawer: WorldDrawer, slot: String) -> String:
	return (_row_of(drawer, slot).get_node("%Choose") as Button).text


func _world_of(into: Array) -> WorldSlot:
	var root := (load(ONE_BOX) as PackedScene).instantiate()
	(into[2] as Callable).call(root)
	var w := LevelRuntime.of(root).world
	root.free()
	return w


# --- K11 to K14: core/67, the Lobby's details ---------------------------------------------------------

func case_k11() -> void:
	_write_world("coop1", {"a": {"name": "Ann", "colour": 0}}, 100)
	_write_world("coop2", {}, 50)
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hlobby := await _lobby(host, LobbyScreen.Mode.HOST, _host_world())
	await _until(func() -> bool: return hlobby.link.session.is_online(), "the Host's Lobby to listen", 900, 20.0)
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hlobby.link.session.port)
	await _until(func() -> bool: return hlobby.link.roster.peers().size() == 2 and (hlobby.get_node("%WhoKey") as Control).visible,
			"the Guest in and the \"i\" key shown", 900, 20.0)
	globby.visible = false
	await _frames(3)
	var who := hlobby.get_node("%WhoKey") as Control
	var drawer := hlobby.drawer()
	_check(hlobby.selected() == null, "nothing is selected before the pad is used")
	await _key(&"ui_right")
	_check(hlobby.selected() == who and hlobby.first_selection() == who, "the first press selects the \"i\" key")
	_check(PadFocus.is_lit(who) and who.get_theme_stylebox(&"focus") is StyleBoxEmpty, "the selected key is lit after a pad press, and its focus style is empty")
	await _until(func() -> bool: return is_equal_approx(who.scale.x, 1.08), "the lit key to grow to 1.08 over its tween", 60, 0.0)
	var back := hlobby.get_node("%Back") as Button
	back.grab_focus()
	_check(PadFocus.is_lit(back) and not PadFocus.is_lit(who), "the light moves with the selection")
	await _until(func() -> bool: return is_equal_approx(back.scale.x, 1.08), "the lit key to grow", 60, 0.0)
	(back.get_parent() as Container).queue_sort()
	await _frames(3)
	_check(is_equal_approx(back.scale.x, 1.08), "the lit key keeps its size across a re-layout of its container")
	who.grab_focus()
	await _key(&"ui_right")
	_check(hlobby.selected() == drawer.key(), "Right goes to the World settings key")
	await _key(&"ui_left")
	await _key(&"ui_down")
	_check(hlobby.selected() == hlobby.places()[0] and hlobby.places()[0].focused(), "Down from the top row goes to the first figure, and its place is focused")
	await _key(&"ui_right")
	_check(hlobby.selected() == hlobby.places()[1], "Right walks to the second figure")
	await _key(&"ui_left")
	_check(hlobby.selected() == hlobby.places()[0], "Left walks back")
	await _key(&"ui_left")
	_check(hlobby.selected() == hlobby.places()[0], "and stops at the first (no wrap)")
	await _key(&"ui_right")
	await _key(&"ui_right")
	_check(drawer.is_open() and drawer.is_ancestor_of(hlobby.selected()), "Right of the last figure goes into the open drawer (%s)" % [hlobby.selected()])
	await _key(&"ui_left")
	_check(hlobby.selected() == hlobby.places()[1], "Left comes back out to the last figure")
	await _key(&"ui_down")
	var bottom: Array[Control] = [hlobby.get_node("%Back"), hlobby.get_node("%Ready")]
	_check(bottom.has(hlobby.selected()), "Down reaches a bottom key (%s)" % [hlobby.selected()])
	await _key(&"ui_up")
	_check(hlobby.selected() is LobbyPlace, "Up returns to a figure")
	# The drawer shut: Right of the last figure goes nowhere.
	await _click(drawer.key())
	_check(not PadFocus.is_lit(who) and not PadFocus.pad_used, "a mouse click puts the light out")
	_check(not PadFocus.is_lit(drawer.key()), "and the key the mouse pressed is not lit")
	await _until(func() -> bool: return not drawer.is_open() and drawer.is_settled(), "the drawer to shut", 300, 0.0)
	hlobby.places()[1].grab_focus()
	await _key(&"ui_right")
	_check(hlobby.selected() == hlobby.places()[1], "with the drawer shut Right of the last figure stays")
	# Solo has no "i": the first selection is Back.
	_drop_branches()
	var m := _machine("Solo")
	var lobby := await _lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_solo())
	await _frames(3)
	_check(not (lobby.get_node("%WhoKey") as Control).visible and lobby.first_selection() == lobby.get_node("%Back"), "Solo has no \"i\": the first selection is Back")
	await _key(&"ui_down")
	_check(lobby.selected() == lobby.get_node("%Back"), "the pad's first press selects Back")


func case_k12() -> void:
	_write_world("coop1", {}, 100)
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hlobby := await _lobby(host, LobbyScreen.Mode.HOST, _host_world())
	await _until(func() -> bool: return hlobby.link.session.is_online(), "the Host's Lobby to listen", 900, 20.0)
	var globby := await _lobby(guest, LobbyScreen.Mode.JOIN, null, "127.0.0.1:%d" % hlobby.link.session.port)
	await _until(func() -> bool: return hlobby.link.roster.peers().size() == 2 and globby.link.roster.peers().size() == 2, "both in", 900, 20.0)
	globby.visible = false
	await _frames(3)
	var heard: Array[StringName] = []
	Sounds.played.connect(func(n: StringName, _s: bool, _w: Vector3, _b: StringName) -> void: heard.append(n))
	var ready_key := hlobby.get_node("%Ready") as Button
	var ready_cap := hlobby.get_node("%ReadyCaption") as Label
	var start := hlobby.get_node("%Start") as Button
	var start_cap := hlobby.get_node("%StartCaption") as Label
	_check(ready_cap.text == LobbyWords.READY_CAPTION and start_cap.text == LobbyWords.START_CAPTION, "the captions' words")
	_check(ready_cap.modulate.a == 0.0 and start_cap.modulate.a == 1.0 and start.disabled, "not Ready: no un-ready caption, Start greyed with its caption")
	var rect_ready := ready_cap.get_global_rect()
	var rect_start := start_cap.get_global_rect()
	var key_rect := ready_key.get_global_rect()
	await _click(ready_key)
	await _until(func() -> bool: return hlobby.link.lobby.is_ready(1), "the Host's Ready", 900, 20.0)
	_check(ready_key.text == LobbyWords.READY_ON and ready_cap.modulate.a == 1.0, "Ready: the key reads the tick, the caption \"press again to un-ready\" shows")
	_check(ready_cap.get_global_rect() == rect_ready and ready_key.get_global_rect() == key_rect, "the caption keeps its line: nothing moved")
	_check(heard.count(&"ui_click") == 0 and heard.count(&"ui_hover") >= 1, "the Ready key ticked and did not click (%s)" % [heard])
	_check(start_cap.modulate.a == 1.0 and start.disabled, "the Guest is not Ready: Start still held")
	globby.toggle_ready()
	await _until(func() -> bool: return hlobby.link.lobby.all_ready() and not start.disabled, "everyone Ready: Start pressable", 900, 20.0)
	_check(start_cap.modulate.a == 0.0 and start_cap.get_global_rect() == rect_start, "everyone Ready: the Start caption hides and keeps its line")
	await _click(ready_key)
	await _until(func() -> bool: return not hlobby.link.lobby.is_ready(1), "the second press un-readies", 900, 20.0)
	_check(ready_cap.modulate.a == 0.0 and ready_key.text == LobbyWords.READY and start.disabled and start_cap.modulate.a == 1.0, "pressed again: back as before")
	heard.clear()
	await _click(hlobby.get_node("%Back") as Control)
	_check(heard.has(&"ui_click"), "the other keys click (%s)" % [heard])


func case_k13() -> void:
	_write_world("coop1", {}, 100)
	var host := _machine("Host")
	var hlobby := await _lobby(host, LobbyScreen.Mode.HOST, _host_world())
	await _until(func() -> bool: return hlobby.link.session.is_online(), "the Host's Lobby to listen", 900, 20.0)
	_check(not hlobby.link.session.transport.can_invite(), "ENet cannot invite")
	_check(not (hlobby.drawer().get_node("%Invite") as Control).visible, "ENet: the \"Invite friends\" key is hidden")
	_drop_branches()
	var steam_like := InvitingTransport.new()
	var host2 := _machine("Host2")
	var lobby2 := await _lobby(host2, LobbyScreen.Mode.HOST, _host_world(), "", 0, steam_like)
	await _until(func() -> bool: return lobby2.link.session.is_online(), "the second Host to listen", 900, 20.0)
	await _frames(3)
	var key := lobby2.drawer().get_node("%Invite") as Button
	_check(key.visible and key.text == LobbyWords.INVITE, "a transport that can invite shows the key")
	await _click(key)
	_check(steam_like.invited == 1, "the key asks the transport (%d)" % steam_like.invited)
	_drop_branches()
	var m := _machine("Solo")
	var solo := await _lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_solo(), "", 0, InvitingTransport.new())
	await _frames(3)
	_check(not (solo.drawer().get_node("%Invite") as Control).is_visible_in_tree(), "Solo has no drawer, so no key")


func case_k14() -> void:
	var dir := DirAccess.open("res://game/lobby")
	var texty: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".tscn"):
			for line in FileAccess.get_file_as_string("res://game/lobby/" + f).split("\n"):
				if line.begins_with("text = ") or line.begins_with("placeholder_text = "):
					texty.append("%s: %s" % [f, line])
	_check(texty.is_empty(), "no Lobby scene carries a word of its own (%s)" % [texty])
	var m := _machine("Solo")
	var lobby := await _lobby(m, LobbyScreen.Mode.SOLO, Worlds.pick_solo())
	await _frames(3)
	_check(lobby.status_text() == "" and not (lobby.get_node("%Status") as Control).visible, "the status line is empty and hidden: nothing holds the game")
	_check((lobby.get_node("%NewGame") as Button).text == LobbyWords.NEW_GAME_SOLO and (lobby.get_node("%Back") as Button).text == LobbyWords.BACK, "the keys read LobbyWords")
	# The narrower camera: 16:9 keeps the height; a narrower screen keeps the width a 16:9 one sees.
	var stage := (load("res://game/lobby/lobby_stage.tscn") as PackedScene).instantiate() as LobbyStage
	stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.size = Vector2(1600, 900)
	add_child(stage)
	await _frames(2)
	var camera := stage.get_node("%Camera") as Camera3D
	var wide_fov := camera.fov
	_check(camera.keep_aspect == Camera3D.KEEP_HEIGHT, "16:9 keeps the height")
	var wide_half_width := tan(deg_to_rad(wide_fov) * 0.5) * LobbyStage.WIDE
	stage.size = Vector2(900, 900)
	await _frames(2)
	_check(camera.keep_aspect == Camera3D.KEEP_WIDTH and absf(tan(deg_to_rad(camera.fov) * 0.5) - wide_half_width) < 0.001,
			"narrower: keeps the width a 16:9 screen sees (fov %.1f)" % camera.fov)
	stage.size = Vector2(2400, 900)
	await _frames(2)
	_check(camera.keep_aspect == Camera3D.KEEP_HEIGHT and is_equal_approx(camera.fov, wide_fov), "wider keeps the height")
	stage.free()


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
func _lobby(machine: Node, mode: LobbyScreen.Mode, world: WorldSlot, address := "", lag_ms := 0, transport: NetTransport = null) -> LobbyScreen:
	var link := _link_in(machine)
	if transport != null:
		link.session.transport = transport
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
		get_tree().root.window_input.emit(ev)
		control.get_viewport().push_input(ev, true)
	await _frames(2)


func _key(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		# A real key or pad press reaches the window's `window_input` first (the selection ring listens there);
		# a parsed event does not, so it is told too.
		get_tree().root.window_input.emit(ev)
		Input.parse_input_event(ev)
		await _frames(2)
