## coop/03: Host, join and roster. Real zoos (only their Handling station, to stay light), each a
## machine of its own in one process, joined over real ENet through the zoo's own wiring: LevelNet
## reads the command line's flags, the Session gates, the Roster places and colours, the HUD says who
## came and went. Plus the pieces that need no network: the profile file, the transport's address,
## the next free colour.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
## The stations each zoo keeps.
const KEEP := ["Handling"]
## Network waits give real time, which a busy machine stretches.
const NET_WAIT_S := 20.0
## Where the Host stands and faces when a Guest joins (in the zoo's space).
const HOST_AT := Vector3(2.0, 0.0, 6.0)
const HOST_YAW := 0.7
## Where a Guest stands to pick at the Handling station, in the station's space (zoo_test BY_HANDLING).
const BY_HANDLING := Vector3(0.0, 0.0, 1.5)
## A place nobody listens on, for the give-up.
const NOBODY := "127.0.0.1:1"
## Profile tags this suite writes, removed after each case.
const TAGS := ["coop_join_test_a", "coop_join_test_b"]
## The one-way delays the real path runs at (coop/12).
const LAGS: Array[int] = [0, 50]

## Each machine: a Node with its own MultiplayerAPI.
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "profile", "method": "case_profile", "world": false,
				"title": "a profile is a 32-hex-character id and the name Player, kept in profile.json or profile_<tag>.json and read back the same"},
		{"name": "seam", "method": "case_seam", "world": false,
				"title": "the transport alone reads an address; the next free colour wraps round the 8 and skips the taken ones"},
		{"name": "join", "method": "case_join", "world": false,
				"title": "real path, 0 and 50 ms one way: a zoo started with --host and another with --join= and its own --profile=: the Guest reads \"Joined Player's zoo\" and stands 0.6 m beside the Host facing its way; the Host reads \"Player joined\" in the second colour"},
		{"name": "free_port", "method": "case_free_port", "world": false,
				"title": "coop/12: in a test every Host listens on a port the system picks: with the game's port taken by another program, two Hosts at once each host on their own port and a Guest joins one"},
		{"name": "refusals", "method": "case_refusals", "world": false,
				"title": "a full house of 4 refuses a fifth (\"The game is full (4 players)\"), the same player id (\"You are already in this game\"), another protocol and another scene layout (\"Another version of the game\"), each told on the Guest and none admitted"},
		{"name": "leave_and_return", "method": "case_leave_and_return", "world": false,
				"title": "a third player sees both others where they stand in their colours; a Guest holding Socks leaves: they drop at its last place on the Host and the third, the drop heard once, its avatar gone, \"Player left\"; it comes back where it left in its colour"},
		{"name": "nobody_there", "method": "case_nobody_there", "world": false,
				"title": "a join with nobody there gives up after the join timeout with \"Could not reach <where>\" and the zoo plays alone"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_drop_branches()
	_forget_profiles()


# --- No network ----------------------------------------------------------------------------------

func case_profile() -> void:
	var path := PlayerProfile.file_of(TAGS[0])
	_check(path == "user://profile_%s.json" % TAGS[0], "--profile=<tag> keeps its own file (%s)" % path)
	_check(PlayerProfile.file_of("") == "user://profile.json", "no tag is the player's own profile.json")
	_check(PlayerProfile.file_of("../x") == "user://profile_x.json", "a tag cannot leave the folder")
	var made := PlayerProfile.load_or_make(TAGS[0])
	_check(made.id.length() == 32 and made.id == made.id.to_lower() and PlayerProfile.is_id(made.id),
			"the id is 128 bits as 32 hex characters (%s)" % made.id)
	_check(made.name == "Player", "the name is Player (Q2440)")
	_check(FileAccess.file_exists(path), "it is written")
	var again := PlayerProfile.load_or_make(TAGS[0])
	_check(again.id == made.id, "read back, it is the same player")
	var other := PlayerProfile.load_or_make(TAGS[1])
	_check(other.id != made.id, "another tag is another player")
	_check(PlayerProfile.clean_name("   ") == "Player" and PlayerProfile.clean_name("abcdefghijklmnopqrst") == "abcdefghijklmnop",
			"a name is trimmed to 16 letters, an empty one is Player")
	_check(not PlayerProfile.is_id("12 34") and not PlayerProfile.is_id(7) and not PlayerProfile.is_id(""),
			"an id is plain letters and digits")


func case_seam() -> void:
	_check(EnetTransport.split_address("10.0.0.2", 24565) == ["10.0.0.2", 24565], "an address without a port takes the default")
	_check(EnetTransport.split_address("[::1]:7000", 24565) == ["::1", 7000], "an IPv6 address in brackets with a port")
	# Nothing outside the transport names ENet's peer or splits an address (the seam, Q2457).
	for path: String in _scripts("res://game"):
		if path.ends_with("enet_transport.gd"):
			continue
		var text := FileAccess.get_file_as_string(path)
		_check(not text.contains("ENetMultiplayerPeer") and not text.contains("split_address") and not text.contains("create_client"),
				"%s names no ENet peer and reads no address" % path)
	var roster := Roster.new()
	roster.tuning = CoopTuning.new()
	_check(roster.tuning.colours.size() == 8, "8 Player colours")
	_check(roster.free_colour(0) == 0, "nobody in: the first colour")
	roster.players = {"a": {"peer": 1, "colour": 0}, "b": {"peer": 5, "colour": 1}, "c": {"peer": 0, "colour": 2}}
	_check(roster.free_colour(0) == 2, "the next free one; a player who left holds none (%d)" % roster.free_colour(0))
	roster.players["d"] = {"peer": 9, "colour": 7}
	_check(roster.free_colour(7) == 2, "it wraps round the 8 (%d)" % roster.free_colour(7))
	roster.free()


# --- Joining -------------------------------------------------------------------------------------

func case_join() -> void:
	for lag_ms: int in LAGS:
		await _join_round(lag_ms)
		_drop_branches()


func _join_round(lag_ms: int) -> void:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	_stand(_player(host), HOST_AT, HOST_YAW)
	_check(_net(host).start(["--host", "--profile=%s" % TAGS[0]]) == OK, "the zoo started with --host hosts (%d ms)" % lag_ms)
	_lag(host, lag_ms)
	_check(_session(host).profile.id == PlayerProfile.load_or_make(TAGS[0]).id, "as the player of --profile=")
	_check(_net(guest).start(["--join=127.0.0.1:%d" % _session(host).port, "--profile=%s" % TAGS[1]]) == OK,
			"the other zoo started with --join= and its own --profile= starts joining")
	_lag(guest, lag_ms)
	_check(Worlds.profile_of(guest) == _session(guest).profile and Worlds.profile_of(host) != Worlds.profile_of(guest), "each machine reaches its own profile")
	var g_hud := _player(guest).hud()
	await _until(func() -> bool: return g_hud.message_text() == "Joined Player's zoo", "the Guest to read \"Joined Player's zoo\"")
	var h_hud := _player(host).hud()
	await _until(func() -> bool: return h_hud.message_text() == "Player joined", "the Host to read \"Player joined\" (%s)" % h_hud.message_text())
	var teal := (_session(host).tuning as CoopTuning).colours[1]
	_check(h_hud.message_name_colour() == teal, "the name in the Guest's colour, the second one (%s)" % h_hud.message_name_colour())
	var beside := HOST_AT + Basis(Vector3.UP, HOST_YAW).x * 0.6
	var gp := _player(guest)
	_check(Vector2(gp.global_position.x - beside.x, gp.global_position.z - beside.z).length() < 0.05,
			"the Guest stands 0.6 m to the Host's side (%s, wanted %s)" % [gp.global_position, beside])
	_near(gp.rotation.y, HOST_YAW, 0.01, "facing the Host's way")
	var hr := _roster(host)
	var gr := _roster(guest)
	var g_peer := _session(guest).me()
	_check(hr.peers() == PackedInt32Array([1, g_peer]), "the Host's roster holds both (%s)" % hr.peers())
	_check(hr.colour_index_of(1) == 0 and hr.colour_index_of(g_peer) == 1, "the Host has the first colour, the Guest the next")
	_same(gr.players, hr.players, "the Guest's roster is the Host's")
	_check(hr.id_of(g_peer) == _session(guest).profile.id, "keyed by the Guest's player id, not its peer")
	var ha := _avatars(host)
	await _until(func() -> bool: return ha.of(g_peer) != null and ha.of(g_peer).position.distance_to(gp.global_position) < 0.05,
			"the Host to see the Guest's avatar where it stands")


func case_free_port() -> void:
	_check(Session.free_port, "the test hooks set Session.free_port")
	# Another program (or another test run) holds the game's port.
	var squatter := PacketPeerUDP.new()
	var held := squatter.bind(Session.PORT, "*") == OK
	var a := _branch("HostA")
	var b := _branch("HostB")
	var guest := _branch("Guest")
	await _frames(2)
	for zoo: Node3D in [a, b, guest]:
		_session(zoo).profile = PlayerProfile.fresh()
	_check(_net(a).start(["--host"]) == OK and _session(a).is_online(), "the first Host hosts (the game's port %s)" % ("held elsewhere" if held else "already in use"))
	_check(_net(b).start(["--host"]) == OK and _session(b).is_online(), "a second Host at the same time hosts too")
	var pa := _session(a).port
	var pb := _session(b).port
	_check(pa > 0 and pb > 0 and pa != pb and pa != Session.PORT and pb != Session.PORT,
			"each on its own free port, not the game's %d (%d, %d)" % [Session.PORT, pa, pb])
	_net(guest).start(["--join=127.0.0.1:%d" % pb])
	await _until(func() -> bool: return _player(guest).hud().message_text() == "Joined Player's zoo", "a Guest to join the second Host by its port")
	squatter.close()
	_drop_branches()


func case_refusals() -> void:
	var host := _branch("Host")
	await _frames(2)
	var hs := _session(host)
	hs.profile = PlayerProfile.fresh()
	_check(_net(host).start(["--host"]) == OK, "the Host hosts")
	var guests: Array[Node3D] = []
	for i in 3:
		var g := _branch("Guest%d" % (i + 1))
		guests.append(g)
		await _frames(1)
		_session(g).profile = PlayerProfile.fresh()
		_net(g).start(["--join=127.0.0.1:%d" % hs.port])
	await _until(func() -> bool: return _roster(host).peers().size() == 4, "three Guests to be in: a full house of 4")
	var other := _branch("Other")
	await _frames(2)
	var os := _session(other)
	var where_to := "--join=127.0.0.1:%d" % hs.port
	# A fifth player.
	os.profile = PlayerProfile.fresh()
	await _refused(host, other, where_to, "The game is full (4 players)", "full")
	# The same player id as one who plays.
	os.profile = PlayerProfile.new()
	os.profile.id = _session(guests[0]).profile.id
	await _refused(host, other, where_to, "You are already in this game", "already")
	# Another build.
	os.profile = PlayerProfile.fresh()
	os.protocol = Session.PROTOCOL + 1
	await _refused(host, other, where_to, "Another version of the game", "protocol")
	os.protocol = Session.PROTOCOL
	# Another scene layout: a zoo with no station at all.
	var bare := _branch("Bare", [])
	await _frames(2)
	_session(bare).profile = PlayerProfile.fresh()
	await _refused(host, bare, where_to, "Another version of the game", "layout")
	_check(_roster(host).peers().size() == 4 and LevelRuntime.of(host).players.get_child_count() == 4,
			"none was admitted: still 4 in the roster and 4 avatars")


## `zoo` tries to join `host` and is refused with `text`, counted on the Host under `reason`.
func _refused(host: Node3D, zoo: Node3D, flag: String, text: String, reason: String) -> void:
	var hs := _session(host)
	var counted := _counted(hs, reason)
	var before := _roster(host).players.duplicate(true)
	var ended: Array[String] = []
	var on_end := func(t: String) -> void: ended.append(t)
	_session(zoo).ended.connect(on_end)
	_check(_net(zoo).start([flag]) == OK, "a Guest starts joining (%s)" % reason)
	await _until(func() -> bool: return not ended.is_empty(), "it to be refused (%s)" % reason)
	_session(zoo).ended.disconnect(on_end)
	_check(ended == [text], "it hears why: %s" % [ended])
	_check(_player(zoo).hud().message_text() == text, "its HUD says it (%s)" % _player(zoo).hud().message_text())
	_check(_net(zoo).mode_text() == "Alone: %s" % text, "and its corner (%s)" % _net(zoo).mode_text())
	_check(not _session(zoo).is_online() and LevelRuntime.of(zoo).players.get_child_count() == 0,
			"it plays alone, with no avatar spawned")
	_check(_counted(hs, reason) == counted + 1, "the Host counts it as %s (%s)" % [reason, hs.dropped])
	_same(_roster(host).players, before, "the Host's roster is as it was")


func _counted(s: Session, reason: String) -> int:
	var n := 0
	for peer: int in s.dropped:
		n += int(s.dropped[peer].get(reason, 0))
	return n


func case_leave_and_return() -> void:
	var host := _branch("Host")
	var a := _branch("A")
	var b := _branch("B")
	await _frames(2)
	var hs := _session(host)
	hs.profile = PlayerProfile.fresh()
	_stand(_player(host), HOST_AT, HOST_YAW)
	_check(_net(host).start(["--host"]) == OK, "the Host hosts")
	var a_profile := PlayerProfile.fresh()
	_session(a).profile = a_profile
	_net(a).start(["--join=127.0.0.1:%d" % hs.port])
	await _until(func() -> bool: return _player(a).hud().message_text() == "Joined Player's zoo", "A to join")
	var a_peer := _session(a).me()
	# A walks to the Handling station and picks two Socks.
	var handling := a.get_node("Stations/Handling") as Node3D
	var a_at := handling.to_global(BY_HANDLING)
	_stand(_player(a), a_at, 0.0)
	var ha := _avatars(host)
	await _until(func() -> bool: return ha.of(a_peer) != null and ha.of(a_peer).pose_position.distance_to(a_at) < 0.05,
			"the Host to see A at the Handling station")
	var a_hands := LevelRuntime.of(a).hands
	var h_hands := LevelRuntime.of(host).hands
	var socks: Array[int] = []
	for spot: String in ["Floor", "Over"]:
		var sock := (handling.get_node("Spots/" + spot) as SockSpot).sock
		socks.append(sock)
		a_hands.pick(a_peer, sock)
		await _until(func() -> bool: return h_hands.items_of(a_peer).has(sock), "A to hold the %s Sock" % spot)
		await _physics_ticks(25)  # the grab interval
	# Z1: the Hands keep A's Socks under A's player id; D13: the Host holds A to A's own numbers (the
	# zoo player's 3, sent at the join), clamped to what the Upgrades can make them.
	_check(h_hands.held.has(a_profile.id) and not h_hands.held.has(a_peer), "Z1: the Host's Hands key A by its player id")
	_check(h_hands.tuning_of(a_peer).capacity == _player(a).hands_tuning.capacity, "D13: the Host reads A's own capacity (%d)" % h_hands.tuning_of(a_peer).capacity)
	var forged := h_hands.own_tuning().clamped({"capacity": 99, "reach": 40.0, "charge_time": 0.0, "max_speed": INF})
	var own := h_hands.own_tuning()
	_check(forged.capacity == own.capacity_most and forged.reach == maxf(own.reach, own.reach_most) \
			and forged.charge_time == minf(own.charge_time_least, own.charge_time) and forged.max_speed == own.max_speed,
			"D13: a forged tuning is clamped to the Upgrades' values")
	# B joins late: it sees the Host and A where they stand, in their colours.
	_session(b).profile = PlayerProfile.fresh()
	_net(b).start(["--join=127.0.0.1:%d" % hs.port])
	await _until(func() -> bool: return _player(b).hud().message_text() == "Joined Player's zoo", "B to join late")
	var b_peer := _session(b).me()
	var ba := _avatars(b)
	await _until(func() -> bool: return ba.of(1) != null and ba.of(a_peer) != null \
			and ba.of(1).position.distance_to(_player(host).global_position) < 0.05 \
			and ba.of(a_peer).position.distance_to(a_at) < 0.05, "B to see the Host and A where they stand")
	var br := _roster(b)
	_check(br.colour_index_of(1) == 0 and br.colour_index_of(a_peer) == 1 and br.colour_index_of(b_peer) == 2,
			"B knows each colour: Host 0, A 1, itself 2")
	var bm := LevelRuntime.of(b).mess
	_check(bm.state_of(socks[0]) == Mess.State.HELD and bm.state_of(socks[1]) == Mess.State.HELD,
			"B's Mess has A's Socks held")
	var b_hands := LevelRuntime.of(b).hands
	_check(b_hands.items_of(a_peer) == PackedInt32Array(socks), "Z1: the late joiner B sees A's Hands")
	await _until(func() -> bool: return ba.of(a_peer).held.looks_of(socks[1]) != null, "Z1: B draws A's Socks at A's hand")
	# A leaves, holding them.
	var drops: Array[int] = [0]
	var heard := func(name: StringName, _spatial: bool, _at: Vector3, _bus: StringName) -> void:
		if name == &"drop":
			drops[0] += 1
	Sounds.played.connect(heard)
	var left_on := {"host": 0, "b": 0}
	var count_left := func(ev: Dictionary, who: String) -> void:
		if ev.has("dropped_at"):
			left_on[who] = int(left_on[who]) + 1
	LevelRuntime.of(host).parts.applied.connect(count_left.bind("host"))
	LevelRuntime.of(b).parts.applied.connect(count_left.bind("b"))
	_session(a).close()
	var hm := LevelRuntime.of(host).mess
	var lies_by_a := func(m: Mess) -> bool:
		for sock in socks:
			var lead := sock if m.state_of(sock) != Mess.State.IN_PAIR else m.mate_of(sock)
			if m.state_of(lead) != Mess.State.LYING:
				return false
			var at := m.where_of(lead)
			if Vector2(at.x - a_at.x, at.z - a_at.z).length() > 0.8:
				return false
		return true
	await _until(func() -> bool: return lies_by_a.call(hm) and lies_by_a.call(bm),
			"A's Socks to lie at A's last place on the Host and on B")
	Sounds.played.disconnect(heard)
	_check(left_on == {"host": 1, "b": 1}, "one drop answer reached each machine (%s)" % [left_on])
	_check(drops[0] >= 1, "the drop is heard (%d)" % drops[0])
	_check(h_hands.items_of(a_peer).is_empty(), "A's Hands are empty on the Host")
	await _until(func() -> bool: return ha.of(a_peer) == null and ba.of(a_peer) == null, "A's avatar to go on the Host and on B")
	for zoo: Node3D in [host, b]:
		var hud := _player(zoo).hud()
		_check(hud.message_text() == "Player left" and hud.message_name_colour() == _roster(zoo).tuning.colours[1],
				"%s reads \"Player left\" in A's colour (%s)" % [zoo.get_parent().get_parent().name, hud.message_text()])
	_check(_roster(host).peers() == PackedInt32Array([1, b_peer]), "the Host's roster holds the Host and B")
	# A comes back as the same player: where it left, its colour still free.
	_stand(_player(a), Vector3(-3.0, 0.0, 9.0), 2.0)
	_net(a).start(["--join=127.0.0.1:%d" % hs.port])
	await _until(func() -> bool: return _player(a).hud().message_text() == "Joined Player's zoo", "A to join again")
	var a_again := _session(a).me()
	var ap := _player(a)
	_check(Vector2(ap.global_position.x - a_at.x, ap.global_position.z - a_at.z).length() < 0.05,
			"A stands where it left (%s, left at %s)" % [ap.global_position, a_at])
	_check(_roster(host).colour_index_of(a_again) == 1, "and keeps its colour")
	_check(_roster(host).id_of(a_again) == a_profile.id, "as the same player id")
	# Z1: back on a new peer, A picks again; every machine sees A's Hands by its player id.
	var again := (handling.get_node("Spots/Under") as SockSpot).sock
	await _until(func() -> bool: return ha.of(a_again) != null and ha.of(a_again).pose_position.distance_to(a_at) < 0.1,
			"the Host to see A back at the Handling station")
	LevelRuntime.of(a).hands.pick(a_again, again)
	await _until(func() -> bool: return h_hands.items_of(a_again) == PackedInt32Array([again]) \
			and b_hands.items_of(a_again) == PackedInt32Array([again]), "Z1: the Host and B to see A's Hands after the rejoin")
	_check(h_hands.held.has(a_profile.id) and not h_hands.held.has(a_again), "Z1: still under A's player id")
	await _until(func() -> bool: return ba.of(a_again) != null and ba.of(a_again).held.looks_of(again) != null,
			"Z1: B draws the Sock at the returned A's hand")


func case_nobody_there() -> void:
	var zoo := _branch("Lonely")
	await _frames(2)
	var s := _session(zoo)
	s.profile = PlayerProfile.fresh()
	s.tuning = (s.tuning as CoopTuning).duplicate() as CoopTuning
	s.tuning.join_timeout = 0.5
	_check(_net(zoo).start(["--join=%s" % NOBODY]) == OK, "it starts joining")
	# The timeout runs on the game's clock (the runner's fixed frame rate): 0.3 s of it is not enough.
	await _physics_ticks(18)
	_check(s.is_joining() and _net(zoo).mode_text().begins_with("Joining"), "0.3 s in, it still waits (%s)" % _net(zoo).mode_text())
	var text := "Could not reach %s" % NOBODY
	await _until(func() -> bool: return _net(zoo).mode_text() == "Alone: %s" % text, "the join to give up")
	_check(_player(zoo).hud().message_text() == text, "the HUD says it (%s)" % _player(zoo).hud().message_text())
	_check(not s.is_online() and not s.is_joining(), "it plays alone")
	var ok := s.parts.is_host()
	_check(ok, "a Host of one: its Commands are answered at home")


# --- Machines ------------------------------------------------------------------------------------

## A zoo in a machine of its own (zoo_test's _branch) keeping only the stations named in `keep`.
func _branch(label: String, keep: Array = KEEP) -> Node3D:
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
		if not keep.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var session := _in_branch(node).session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


## Puts `lag_ms` of delay on every packet `zoo`'s machine receives (tests/support/lag_peer.gd).
func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


func _forget_profiles() -> void:
	for tag: String in TAGS:
		var path := PlayerProfile.file_of(tag)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _stand(player: Player, at: Vector3, yaw: float) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.rotation.y = yaw
	player.reset_physics_interpolation()


func _session(zoo: Node3D) -> Session:
	return LevelRuntime.of(zoo).session


func _net(zoo: Node3D) -> LevelNet:
	return LevelRuntime.of(zoo).net


func _roster(zoo: Node3D) -> Roster:
	return LevelRuntime.of(zoo).roster


func _avatars(zoo: Node3D) -> Avatars:
	return LevelRuntime.of(zoo).avatars


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


## Every .gd under `folder`.
static func _scripts(folder: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(folder):
		if f.ends_with(".gd"):
			out.append(folder.path_join(f))
	for d in DirAccess.get_directories_at(folder):
		out.append_array(_scripts(folder.path_join(d)))
	return out


## The level runtime of the zoo in branch `node` (a machine of its own), or null.
func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
