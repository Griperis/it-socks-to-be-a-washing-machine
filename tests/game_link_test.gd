## The game link (core/62, docs/architecture/lobby.md "Core/62", Q2582): the Session and its Roster
## live for the whole game beside the current scene, so a Guest stays connected across a scene change;
## the house handshake (a Guest's level snapshot only after its house_ready and the Host's settled
## level; a wrong layout refused; a level Command before it dropped; a late joiner the same); a save's
## Roster merged into the live one; and the real path from the title: Host, a Guest joins by address,
## both play the house through the link, see each other and the Guest's pick lands on the Host.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ONE_BOX := "res://game/level/one_box_level.tscn"
const LICENCE := "res://game/ui/licence/licence.tscn"
const TITLE := "res://game/ui/title/title.tscn"
const STEP_PART := "res://tests/saves/save_step_part.gd"
## The kitchen floor (x, z) where the house has open Socks to pick, and the player's body layer (save_test's).
const KITCHEN := Rect2(0.1, 0.1, 3.84, 8.3)
const PLAYER_BODY := 8

var _branches: Array[Node] = []
var _stand_in: Node = null
var _runner_scene: Node = null
var _went_titles: Array[String] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "l01_scene_change", "method": "case_l01", "world": false,
				"title": "a Guest connected through the game link stays connected across SceneChanger.change_to and keeps its Roster entry on both machines"},
		{"name": "l02_handshake", "method": "case_l02", "world": false,
				"title": "the house handshake: a level Command before house_ready is dropped (not_ready); the Guest's level snapshot waits for its house_ready and for the Host's level to settle; then both see each other's avatar; PROTOCOL raised"},
		{"name": "l02_handshake_50ms", "method": "case_l02_50ms", "world": false,
				"title": "the house handshake with 50 ms each way"},
		{"name": "l03_wrong_layout", "method": "case_l03", "world": false,
				"title": "a Guest in the game whose level has another layout is refused at house_ready (\"Another version of the game\"), counted as layout, never welcomed"},
		{"name": "l04_late_joiner", "method": "case_l04", "world": false,
				"title": "a Guest who joins a Host already in its level takes the same steps: in the game first, then its level, house_ready, the welcome"},
		{"name": "l05_roster_merge", "method": "case_l05", "world": false,
				"title": "a save loads into the live Roster: the present player stays (standing where the save kept it), an absent player's entry comes back with its spot and colour, an entry the save lacks stays"},
		{"name": "l06_real_path_title", "method": "case_l06", "world": false,
				"title": "real path (core/63): title Host into the Lobby, a Guest's title joins its Lobby by address, Ready from both, the Host's Start loads the house for both through the link, each stands at its Roster spot, both see each other's avatar and the Guest's pick (its key) lands on the Host"},
		{"name": "l06_real_path_title_50ms", "method": "case_l06_50ms", "world": false,
				"title": "real path from the title with 50 ms each way"},
	]


func _before_case() -> void:
	_drop_branches()
	_went_titles.clear()


# --- L01 ------------------------------------------------------------------------------------------

func case_l01() -> void:
	var host := _machine("Host")
	var hl := _link_in(host)
	await _frames(2)
	hl.session.profile = PlayerProfile.fresh()
	_check(hl.session.host() == OK, "the Host's link listens with no level (a Lobby's place)")
	# The Guest is this process's own: its link under the tree's root, beside the current scene.
	_runner_scene = get_tree().current_scene
	_stand_in = Node.new()
	_stand_in.name = "StandIn"
	get_tree().root.add_child(_stand_in)
	get_tree().current_scene = _stand_in
	var gl := GameLink.open_beside(_stand_in)
	_check(gl.get_parent() == get_tree().root, "the link is made beside the current scene, under the root")
	await _frames(2)
	gl.session.profile = PlayerProfile.fresh()
	var linked: Array[bool] = []
	gl.session.linked.connect(func() -> void: linked.append(true))
	_check(gl.session.join("127.0.0.1:%d" % hl.session.port) == OK, "the Guest's link joins")
	await _until(func() -> bool: return not linked.is_empty() and hl.roster.peers().size() == 2, "the Guest to be in the game", 900, 20.0)
	var g_peer := gl.session.me()
	var g_id := gl.session.profile.id
	_check(gl.roster.peers().size() == 2 and gl.roster.id_of(g_peer) == g_id, "the Guest's Roster has both, itself by its id")
	SceneChanger.change_to(LICENCE)
	await _until(func() -> bool: return not SceneChanger.is_busy(), "the scene change to end")
	var now := get_tree().current_scene
	_check(now != null and now.scene_file_path == LICENCE and not is_instance_valid(_stand_in), "the current scene changed")
	_check(is_instance_valid(gl) and gl.get_parent() == get_tree().root and GameLink.of(now) == gl, "the link is the same one, still beside the scene")
	await _frames(10)
	_check(gl.session.is_online() and gl.session.me() == g_peer, "the Guest is still connected, the same peer")
	_check(hl.roster.id_of(g_peer) == g_id and hl.roster.is_live(g_id), "the Host's Roster keeps its entry, live")
	_check(gl.roster.id_of(g_peer) == g_id and gl.roster.peers().size() == 2, "and so does the Guest's")
	_check(not hl.session.dropped.has(g_peer), "nothing dropped (%s)" % hl.session.dropped)
	# Put the runner back as the current scene.
	get_tree().current_scene = _runner_scene
	if now != null and now != _runner_scene:
		now.get_parent().remove_child(now)
		now.free()


# --- L02 ------------------------------------------------------------------------------------------

func case_l02() -> void:
	await _handshake(0)


func case_l02_50ms() -> void:
	await _handshake(50)


func _handshake(lag_ms: int) -> void:
	_check(Session.PROTOCOL >= 14, "PROTOCOL raised for the game link (%d)" % Session.PROTOCOL)
	var pair := await _linked_pair(lag_ms)
	var host: Node = pair[0]
	var guest: Node = pair[1]
	var hl := GameLink.of(host)
	var gl := GameLink.of(guest)
	var hs := hl.session
	var gs := gl.session
	var g_peer := gs.me()
	var welcomed: Array[bool] = []
	gs.welcomed.connect(func() -> void: welcomed.append(true))
	# The Host loads its level; the link's session goes on in it.
	var hlevel := await _level_in(host)
	var hr := LevelRuntime.of(hlevel)
	_check(hr.link == hl and not hl.is_private(), "the Host's level plays through the machine's link")
	await _until(func() -> bool: return hr.avatars.of(1) != null, "the Host's avatar in its level", 900, 20.0)
	# A Command for a level Part before the Guest's house is ready is dropped.
	var wire := Command.new(&"pick", g_peer, hr.hands.id, {"sock": 0}).to_wire()
	gs._command.rpc_id(1, wire)
	await _until(func() -> bool: return _counted(hs, "not_ready") == 1, "the level Command to be dropped as not_ready", 900, 20.0)
	_check(_counted(hs, "not_ready") == 1 and welcomed.is_empty(), "dropped, and no level snapshot yet")
	_check(hr.avatars.of(g_peer) == null, "no avatar of the Guest before its house is ready")
	# The Host's level still makes its starting state: the Guest waits for it.
	hr.parts.unsettle(self)
	var glevel := await _level_in(guest)
	var gr := LevelRuntime.of(glevel)
	_check(gr.link == gl, "the Guest's level plays through its link")
	await _physics_ticks(40)
	await _wall(300 + lag_ms * 3)  # time for a house_ready to travel and be answered, were it answered
	_check(welcomed.is_empty() and not hs.in_house(g_peer), "the Guest waits while the Host's level is not settled")
	hr.parts.settle(self)
	await _until(func() -> bool: return not welcomed.is_empty(), "the Guest to be welcomed once the Host's level settled", 900, 20.0)
	_check(welcomed.size() == 1 and hs.in_house(g_peer), "one welcome, after its house_ready")
	await _until(func() -> bool: return hr.avatars.of(g_peer) != null and gr.avatars.of(1) != null, "each to see the other's avatar", 900, 20.0)
	_check(gr.net.mode_text().begins_with("Joined"), "the Guest's corner says it joined (%s)" % gr.net.mode_text())
	_check(gs.is_online() and hl.roster.is_live(gs.profile.id), "still connected, its Roster entry live")


# --- L03 ------------------------------------------------------------------------------------------

func case_l03() -> void:
	var pair := await _linked_pair(0)
	var host: Node = pair[0]
	var guest: Node = pair[1]
	var hs := GameLink.of(host).session
	var gs := GameLink.of(guest).session
	var g_peer := gs.me()
	await _level_in(host)
	var ended: Array[String] = []
	gs.ended.connect(func(t: String) -> void: ended.append(t))
	var welcomed: Array[bool] = []
	gs.welcomed.connect(func() -> void: welcomed.append(true))
	# Another build's level: one more Part.
	var other := (load(ONE_BOX) as PackedScene).instantiate()
	var extra := (load(STEP_PART) as GDScript).new() as Node
	extra.name = "StepPart"
	other.add_child(extra)
	await _level_in(guest, other)
	await _until(func() -> bool: return not ended.is_empty(), "the Guest to be refused at house_ready", 900, 20.0)
	_check(ended == [Session.WRONG_BUILD], "it hears why: %s" % [ended])
	_check(welcomed.is_empty() and not hs.in_house(g_peer), "never welcomed")
	_check(_counted(hs, "layout") == 1, "the Host counts it as layout (%s)" % hs.dropped)
	_check(not gs.is_online(), "the Guest is alone again")


# --- L04 ------------------------------------------------------------------------------------------

func case_l04() -> void:
	var host := _machine("Host")
	var guest := _machine("Guest")
	var hl := _link_in(host)
	var gl := _link_in(guest)
	await _frames(2)
	hl.session.profile = PlayerProfile.fresh()
	gl.session.profile = PlayerProfile.fresh()
	var hlevel := await _level_in(host)
	var hr := LevelRuntime.of(hlevel)
	_check(hr.net.start(["--host"]) == OK and hl.session.is_online(), "the Host hosts from its level")
	var linked: Array[bool] = []
	var welcomed: Array[bool] = []
	gl.session.linked.connect(func() -> void: linked.append(true))
	gl.session.welcomed.connect(func() -> void: welcomed.append(true))
	_check(gl.session.join("127.0.0.1:%d" % hl.session.port) == OK, "a late Guest joins with no level yet")
	await _until(func() -> bool: return not linked.is_empty(), "the late Guest to be in the game", 900, 20.0)
	await _physics_ticks(20)
	_check(welcomed.is_empty() and hr.avatars.of(gl.session.me()) == null, "no level snapshot and no avatar while it has no level")
	var glevel := await _level_in(guest)
	await _until(func() -> bool: return not welcomed.is_empty(), "the late Guest to be welcomed into the level", 900, 20.0)
	var gr := LevelRuntime.of(glevel)
	await _until(func() -> bool: return hr.avatars.of(gl.session.me()) != null and gr.avatars.of(1) != null, "each to see the other's avatar", 900, 20.0)


# --- L05 ------------------------------------------------------------------------------------------

func case_l05() -> void:
	var m := _machine("Alone")
	await _frames(1)
	var level := await _level_in(m)
	var rt := LevelRuntime.of(level)
	await _until(func() -> bool: return rt.roster.id_of(1) != "", "the player alone in its Roster")
	var me := rt.roster.id_of(1)
	var colour := rt.roster.colour_index_of(1)
	# Another entry the save does not name, in the live Roster.
	var live := rt.roster.players.duplicate(true)
	live["here_only"] = {"peer": 0, "name": "Kept", "colour": 3, "at": Vector3.ZERO, "yaw": 0.0}
	rt.parts.apply(rt.roster.grant({"players": live}))
	var spot := Vector3(1.5, 0.0, -2.0)
	var saved := {"players": {
		me: {"peer": 0, "name": "Old name", "colour": 2, "at": spot, "yaw": 1.0},
		"absent": {"peer": 0, "name": "Absent", "colour": 1, "at": Vector3(3.0, 0.0, 1.0), "yaw": 0.5, "hands": {"capacity": 3}},
	}}
	rt.parts.load_save({String(rt.roster.id): saved}, {}, me)
	var now := rt.roster.players
	_check(int(now[me]["peer"]) == 1 and String(now[me]["name"]) != "Old name" and int(now[me]["colour"]) == colour,
			"the present player stays as it is (%s)" % [now[me]])
	_check((now[me]["at"] as Vector3).is_equal_approx(spot) and is_equal_approx(float(now[me]["yaw"]), 1.0), "standing where the save kept it")
	_check(now.has("absent") and int(now["absent"]["peer"]) == 0 and int(now["absent"]["colour"]) == 1
			and (now["absent"]["at"] as Vector3).is_equal_approx(Vector3(3.0, 0.0, 1.0)) and now["absent"].get("hands") == {"capacity": 3},
			"the absent player comes back with its spot, colour and Hands (%s)" % [now.get("absent")])
	_check(now.has("here_only"), "an entry the save lacks stays")
	_check(rt.parts.save_snapshot().has("Runtime/Session/Roster"), "the Roster is saved under its old id")


# --- L06 ------------------------------------------------------------------------------------------

func case_l06() -> void:
	await _from_title(0)


func case_l06_50ms() -> void:
	await _from_title(50)


func _from_title(lag_ms: int) -> void:
	var host := _machine("Host")
	var guest := _machine("Guest")
	await _frames(1)
	_open_title(host, false, lag_ms)
	_open_title(guest, true, lag_ms)
	await _frames(2)
	var ht := host.get_node("Title") as TitleScreen
	var gt := guest.get_node("Title") as TitleScreen
	# Both screens lie over each other in this one window: only the one clicked shows.
	gt.visible = false
	await _click(ht.get_node("%MultiplayerKey") as Control)
	await _click(ht.get_node("%Host") as Control)
	await _until(func() -> bool: return _lobby_of(host) != null, "the Host's title to open the Lobby", 900, 20.0)
	var hlobby := _lobby_of(host)
	var hs := hlobby.link.session
	await _until(func() -> bool: return hs.is_online(), "the Host's Lobby to listen", 900, 20.0)
	hlobby.visible = false
	gt.visible = true
	await _click(gt.get_node("%MultiplayerKey") as Control)
	await _click(gt.get_node("%JoinKey") as Control)
	(gt.get_node("%AddressField") as LineEdit).text = "127.0.0.1:%d" % hs.port
	await _click(gt.get_node("%JoinGo") as Control)
	await _until(func() -> bool: return _lobby_of(guest) != null, "the Guest's title to open the Lobby", 900, 20.0)
	var globby := _lobby_of(guest)
	await _until(func() -> bool: return (globby.place_texts().size() == 4 and globby.place_texts()[1].contains(PlayerProfile.NAME)
			and hlobby.place_texts()[1].contains(PlayerProfile.NAME)), "both Lobbies to show both players", 900, 20.0)
	var g_peer := globby.link.session.me()
	_check(hlobby.place_texts()[0].begins_with(LobbyScreen.HOST_MARK) and hlobby.place_texts()[3] == LobbyScreen.WAITING_PLAYER,
			"the Host's place first with its mark, a free place waits (%s)" % [hlobby.place_texts()])
	_check((globby.get_node("%Waiting") as Control).visible and not (globby.get_node("%Start") as Control).visible
			and (globby.get_node("%Back") as Button).text == LobbyScreen.LEAVE, "the Guest waits for the Host to start, its Back reads Leave")
	_check((hlobby.get_node("%Start") as Button).disabled, "Start is greyed while nobody is Ready")
	# Ready from both: the Guest's click asks the Host.
	await _click(globby.get_node("%Ready") as Control)
	await _until(func() -> bool: return hlobby.link.lobby.is_ready(g_peer), "the Guest's Ready to reach the Host", 900, 20.0)
	_check((hlobby.get_node("%Start") as Button).disabled, "Start still greyed: the Host is not Ready")
	globby.visible = false
	hlobby.visible = true
	await _click(hlobby.get_node("%Ready") as Control)
	await _until(func() -> bool: return not (hlobby.get_node("%Start") as Button).disabled and globby.link.lobby.all_ready(),
			"everyone Ready on both machines", 900, 20.0)
	_check((globby.get_node("%Ready") as Button).text == LobbyScreen.READY_ON, "the Guest's key says it is Ready")
	# The Host's Start: both machines load the house behind the loading screen.
	await _click(hlobby.get_node("%Start") as Control)
	await _until(func() -> bool: return _level_of(host) != null and _level_of(guest) != null, "Start to load the house on both machines", 900, 30.0)
	_check(_lobby_of(host) == null and _lobby_of(guest) == null, "the Lobby is gone on both")
	_check(_went_titles.is_empty(), "nobody went back to the title (%s)" % [_went_titles])
	var hr := LevelRuntime.of(_level_of(host))
	var gr := LevelRuntime.of(_level_of(guest))
	_check(hr.link == GameLink.of(host) and not hr.link.is_private() and gr.link == GameLink.of(guest) and not gr.link.is_private(),
			"each house plays through the link its title made")
	await _until(func() -> bool: return hr.loading.is_lifted() and hr.parts.is_settled(), "the Host's house to be laid", 3000, 60.0)
	await _until(func() -> bool: return gr.net.mode_text().begins_with("Joined"), "the Guest to be welcomed into the house", 3000, 60.0)
	_check(gr.session.me() == g_peer and gr.session.is_online(), "the same connection, no reconnect")
	await _until(func() -> bool: return hr.avatars.of(g_peer) != null and gr.avatars.of(1) != null, "each to see the other's avatar", 900, 20.0)
	# Both stand at their Roster spots: the Host where its body is, the Guest beside it.
	var h_at: Variant = hr.roster.entry_of(1).get("at")
	var g_at: Variant = hr.roster.entry_of(g_peer).get("at")
	_check(h_at is Vector3 and g_at is Vector3 and (h_at as Vector3).distance_to(g_at) > 0.3, "both have spots, apart (%s, %s)" % [h_at, g_at])
	if h_at is Vector3 and g_at is Vector3:
		_check(Vector2(hr.player.global_position.x, hr.player.global_position.z).distance_to(Vector2(h_at.x, h_at.z)) < 0.3,
				"the Host stands at its spot")
		_check(Vector2(gr.player.global_position.x, gr.player.global_position.z).distance_to(Vector2(g_at.x, g_at.z)) < 0.3,
				"the Guest stands at its spot (%s, %s)" % [gr.player.global_position, g_at])
	await _frames(5)
	_check(_lobby_of(host) == null and _lobby_of(guest) == null, "the Lobby does not come back")
	# The Guest picks a Sock by its key; the Host's Hands hold it for the Guest.
	hr.player.set_input_blocked(true)
	var mess := gr.mess
	var pair_of := _kitchen_pair(mess, _level_of(guest))
	_check(not pair_of.is_empty(), "a Sock lies open in the kitchen")
	if pair_of.is_empty():
		return
	var sock: int = pair_of["socks"][0]
	var player := gr.player
	player.capture_mouse()
	_stand(player, pair_of["spots"][0])
	await _until(func() -> bool: return hr.avatars.of(g_peer).pose_position.distance_to(pair_of["spots"][0]) < 0.2,
			"the Host to see the Guest at the Sock", 900, 20.0)
	await _aim(player, _centre(mess, sock))
	await _press(&"pick")
	await _until(func() -> bool: return hr.hands.active_of(g_peer) == sock, "the Guest's pick to land on the Host", 900, 20.0)
	await _until(func() -> bool: return gr.hands.active_of(g_peer) == sock, "and come back to the Guest", 900, 20.0)


# --- Machines -------------------------------------------------------------------------------------

## A machine of its own: a Node with its own MultiplayerAPI and a SubViewport with its own 3D world.
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


## The machine's game link, as a title would make it: beside the scenes, under the machine.
func _link_in(machine: Node) -> GameLink:
	var link := GameLink.make()
	machine.add_child(link)
	return link


## A level (the one-box one, or `level`) in the machine's view; awaits its Parts bound.
func _level_in(machine: Node, level: Node = null) -> Node:
	var l := level if level != null else (load(ONE_BOX) as PackedScene).instantiate()
	(machine.get_node("View") as Node).add_child(l)
	var rt := LevelRuntime.of(l)
	await _until(func() -> bool: return rt.parts.is_bound, "the level's Parts to bind")
	return l


## A Host and a Guest whose links are connected with no level on either (a Lobby's place).
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


## The title in `machine`; its way in puts the Lobby under the machine and the level in the machine's
## view; the ways back to the title only note it. With `lag_ms`, the machine's peer is wrapped once the
## Lobby has started its session.
func _open_title(machine: Node, guest: bool, lag_ms: int) -> void:
	var t := (load(TITLE) as PackedScene).instantiate() as TitleScreen
	t.name = "Title"
	t.go_into = func(path: String, _heading: String, setup: Callable) -> void:
		var root := (load(path) as PackedScene).instantiate()
		if setup.is_valid():
			setup.call(root)
		var lobby := root as LobbyScreen
		var before := _lobby_of(machine)
		if lobby != null:
			if guest:
				# One process, one profile file: the Guest plays as another player.
				GameLink.of(machine).session.profile = PlayerProfile.fresh()
			lobby.go_to_title = func(notice: String) -> void: _went_titles.append("%s:%s" % [machine.name, notice])
			var title := machine.get_node_or_null("Title")
			if title != null:
				machine.remove_child(title)
				title.queue_free()
			lobby.name = "Lobby"
			machine.add_child(lobby)
			if lag_ms > 0:
				# Queued after the Lobby's own deferred start: the peer is wrapped before anything is polled.
				(func() -> void: _lag(machine, lag_ms)).call_deferred()
			return
		var runtime := LevelRuntime.of(root)
		runtime.esc_menu.go_to_title = func(_notice: String) -> void: pass
		if before != null:
			machine.remove_child(before)
			before.queue_free()
		(machine.get_node("View") as Node).add_child(root)
	machine.add_child(t)


func _lobby_of(machine: Node) -> LobbyScreen:
	var l := machine.get_node_or_null("Lobby") as LobbyScreen
	return l if l != null and not l.is_queued_for_deletion() else null


func _level_of(machine: Node) -> Node:
	var view := machine.get_node("View")
	return view.get_child(0) if view.get_child_count() > 0 else null


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
	if is_instance_valid(_stand_in):
		_stand_in.free()
	_stand_in = null
	if _runner_scene != null and is_instance_valid(_runner_scene):
		get_tree().current_scene = _runner_scene
	_runner_scene = null


func _lag(machine: Node, lag_ms: int) -> void:
	var mp := machine.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## Frames until `ms` of wall time went by (the network runs on real time).
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


# --- Input and the kitchen (save_test's) ----------------------------------------------------------

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


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _stand(player: Player, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _centre(mess: Mess, sock: int) -> Vector3:
	return mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)


## A loose Pair lying open in the kitchen, each Sock with a place to stand and see it: {"socks", "spots"}.
func _kitchen_pair(mess: Mess, house: Node) -> Dictionary:
	var made := house.get_node("SockGenerators/Ground/Generated") as GeneratedSocks
	for sock in range(made.first, made.first + made.socks):
		var at := mess.pose_of(sock).origin
		if mess.design_of(sock).collection != &"food" or not KITCHEN.has_point(Vector2(at.x, at.z)) or not _open_sock(mess, sock):
			continue
		var s1 := _spot_seeing(mess, _centre(mess, sock))
		if s1 != Vector3.INF and _seen_first(mess, s1, sock):
			return {"socks": [sock], "spots": [s1]}
	return {}


func _seen_first(mess: Mess, spot: Vector3, sock: int) -> bool:
	var eye := spot + Vector3.UP * 1.6
	var target := _centre(mess, sock)
	var hit := PhysicsQueries.ray(mess, eye, eye + (target - eye) * 1.2, Mess.AIM_MASK)
	return not hit.is_empty() and mess.sock_of_hit(hit) == sock


func _open_sock(mess: Mess, sock: int) -> bool:
	if mess.state_of(sock) != Mess.State.LYING:
		return false
	var at := mess.pose_of(sock).origin
	return PhysicsQueries.ray(mess, at + Vector3.UP * 0.06, at + Vector3.UP * 2.2, Mess.LAYER_HOUSE | Mess.LAYER_LYING).is_empty()


func _spot_seeing(mess: Mess, target: Vector3) -> Vector3:
	var probe := BoxShape3D.new()
	probe.size = Vector3(0.6, 1.5, 0.6)
	for r: float in [1.0, 1.3, 1.6]:
		for k in 12:
			var a := TAU * k / 12.0
			var at := Vector3(target.x + cos(a) * r, 0.0, target.z + sin(a) * r)
			var floor_hit := PhysicsQueries.ray(mess, at + Vector3.UP * 1.0, at + Vector3.DOWN * 0.3, Mess.LAYER_HOUSE)
			if floor_hit.is_empty() or absf((floor_hit["position"] as Vector3).y) > 0.05:
				continue
			if not PhysicsQueries.overlap_rids(mess, probe, Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.85), Mess.LAYER_HOUSE | PLAYER_BODY, 1).is_empty():
				continue
			if PhysicsQueries.ray(mess, at + Vector3.UP * 1.5, target, Mess.LAYER_HOUSE).is_empty():
				return at
	return Vector3.INF
