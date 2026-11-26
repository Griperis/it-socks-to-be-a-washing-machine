## core/131 in co-op: two zoos in one process, each a machine of its own, real ENet over 127.0.0.1 (the
## frames paced to 60 a second as tests/coop_hand_off_test.gd). The Host is player A, the Guest player B,
## both on the Handling station. The team owns Sole Mates (the Host's set_level, synced); A picks a loose
## Sock by its own click, B picks its mate by its own click: on A's screen B's Sock is outlined in B's
## colour and `match` plays once at B's Hands, A's own Sock glows; with Sole Hands B holding the mate in a
## slot that is not active outlines the whole of B; with Mate Radar the cue shows through the Wall and an
## arrow at the screen's edge points to B. Solo: no cue.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Handling"]
const STATION := "Stations/Handling"
const NET_WAIT_S := 20.0
const FPS := 60
const LAG_MS := 50

var _branches: Array[Node] = []
var _pace_next := 0
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "core/131 Sole Mates, 50 ms one way: A holds a loose Sock, B picks its mate by its own click: on A's screen B's Sock is outlined in B's colour, `match` plays once at B's Hands and A's own Sock glows; without the Upgrade neither"},
		{"name": "sole_hands", "method": "case_sole_hands", "world": false,
				"title": "core/131 Sole Hands: B holding the mate in a slot that is not active has the whole of B outlined in B's colour on A's screen, and with only Sole Mates it has not"},
		{"name": "mate_radar", "method": "case_mate_radar", "world": false,
				"title": "core/131 Mate Radar: with the Wall between them B's Sock is not outlined; with Mate Radar it is, and turned away A sees an edge arrow in B's colour"},
		{"name": "solo", "method": "case_solo", "world": false,
				"title": "core/131: alone the three Upgrades are hidden and no cue shows, whatever the levels"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	for a: StringName in [&"pick", &"drop_throw"]:
		Input.action_release(a)
	_heard.clear()
	_drop_branches()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var cues := _cues(host)
	_check(not cues.owned(), "without the Upgrade the team owns no Sole Mates")
	var mine := _spot_sock(host, "Floor")
	var theirs := _spot_sock(host, "MateFloor")
	await _pick(host, mine)
	await _pick(guest, theirs)
	await _paced_ticks(10)
	_check(cues.sole_outline_count() == 0 and cues.sounds == 0 and _count(&"match") == 0 and not _held(host).glowing(mine),
			"line 1: no cue at all without Sole Mates (%d, %d)" % [cues.sole_outline_count(), _count(&"match")])
	await _own(host, guest, ["sole_mates"])
	await _wait(func() -> bool: return cues.owned(), "A's machine reads Sole Mates", FPS)
	await _wait(func() -> bool: return cues.sock_outline(g) != null, "on A's screen B's Sock is outlined", FPS * 3)
	var colour := _roster(host).colour_of(g)
	_check(cues.sock_outline(g).current_style().colour.to_html(false) == colour.to_html(false), "in B's colour")
	_check(cues.sock_outline(g).current_style().width == cues.tuning.outline_width, "as wide as a Ping's")
	await _paced_ticks(6)
	var hold := (_avatar(host, g).get_node("Held") as HeldView).anchor.global_position
	_check(cues.sounds == 1 and _cues(guest).sounds == 1 and _count(&"match") == 2 and _count_near(&"match", hold) >= 1,
			"`match` plays once on each machine, on A's at B's Hands (%s, %s)" % [hold, _heard])
	_check(_held(host).glowing(mine), "A's own Sock glows")
	await _wait(func() -> bool: return not _held(host).glowing(mine), "and the glow fades", FPS * 3)
	_check(cues.sock_outline(g) != null and cues.sounds == 1, "the outline stays while they hold mates, the sound is not played again")
	# B's own screen sees A's Sock in A's colour, the same cue the other way.
	var back := _cues(guest)
	await _wait(func() -> bool: return back.sock_outline(Parts.HOST) != null, "B sees A's Sock outlined", FPS * 3)
	_check(back.sock_outline(Parts.HOST).current_style().colour.to_html(false) == _roster(guest).colour_of(Parts.HOST).to_html(false),
			"in A's colour")
	# A puts its Sock down by its own right click: the match is over and the outline goes.
	var hp := _player(host)
	var floor_at := _station(host).global_position + Vector3(0.6, 0.0, 2.5)
	await _aim(host, floor_at + Vector3(0.0, 0.0, 1.5), floor_at)
	await _wait(func() -> bool: return hp.drop_refusal(_hands(host)) == "", "a white crosshair on the floor", FPS * 2)
	Input.action_press(&"drop_throw")
	await _paced_ticks(2)
	Input.action_release(&"drop_throw")
	await _wait(func() -> bool: return cues.sock_outline(g) == null, "the outline ends when A no longer holds a Sock", FPS * 3)
	_drop_branches()


func case_sole_hands() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var cues := _cues(host)
	await _own(host, guest, ["sole_mates"])
	var mine := _spot_sock(host, "Floor")
	var theirs := _spot_sock(host, "MateFloor")
	var other := _spot_sock(host, "OnTable")
	await _pick(host, mine)
	await _pick(guest, theirs)
	await _pick(guest, other)
	await _wait(func() -> bool: return _hands(host).items_of(g).size() == 2, "B holds two on A's machine", FPS * 2)
	_check(_hands(host).active_of(g) == other, "the mate is not B's active item")
	await _paced_ticks(10)
	_check(cues.sock_outline(g) == null and cues.hands_outline(g) == null, "with Sole Mates alone nothing is outlined (B's active is not the mate)")
	await _own(host, guest, ["sole_hands"])
	await _wait(func() -> bool: return cues.hands_outline(g) != null, "the whole of B is outlined", FPS * 3)
	_check(cues.hands_outline(g).current_style().colour.to_html(false) == _roster(host).colour_of(g).to_html(false), "in B's colour")
	_check(cues.sock_outline(g) == null, "and not the Sock that is not the mate")
	_drop_branches()


func case_mate_radar() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var cues := _cues(host)
	await _own(host, guest, ["sole_mates"])
	var mine := _spot_sock(host, "Floor")
	var theirs := _spot_sock(host, "MateFloor")
	await _pick(host, mine)
	await _pick(guest, theirs)
	# B behind the Wall (z -1.2), A in front looking at it.
	var wall := _station(host).global_position + Vector3(0.0, 0.0, -1.2)
	var b_feet := wall + Vector3(0.0, 0.0, -1.0)
	var a_feet := wall + Vector3(0.0, 0.0, 2.0)
	await _aim(guest, b_feet, b_feet + Vector3.FORWARD)
	await _aim(host, a_feet, wall + Vector3.UP * 1.0)
	await _wait(func() -> bool: return _avatar(host, g).global_position.distance_to(b_feet) < 0.3, "B stands behind the Wall on A's machine", FPS * 2)
	await _paced_ticks(20)
	_check(cues.sock_outline(g) == null, "the Wall hides B's Sock: no outline without Mate Radar")
	await _own(host, guest, ["sole_hands", "mate_radar"])
	await _wait(func() -> bool: return cues.sock_outline(g) != null, "with Mate Radar the cue shows through the Wall", FPS * 3)
	_check(cues.hands_outline(g) != null, "and Sole Hands' outline of B too")
	# Turned away, an arrow points to B in B's colour.
	_place(host, a_feet, a_feet + Vector3.BACK * 3.0)
	await _paced_ticks(4)
	var arrows := _player(host).hud().hint_arrows()
	var colour := _roster(host).colour_of(g)
	_check(arrows.count() == 1 and (arrows.shown()[0]["colour"] as Color).to_html(false) == colour.to_html(false),
			"an arrow in B's colour at the edge (%s)" % [arrows.shown()])
	_drop_branches()


func case_solo() -> void:
	var zoo := _branch("Solo")
	await _frames(3)
	var runtime := LevelRuntime.of(zoo)
	var ups := Upgrades.of(runtime.hands)
	for id: StringName in [&"sole_mates", &"sole_hands", &"mate_radar"]:
		var u := Upgrades.find_upgrade(id)
		_check(not ups.shown(u), "%s is hidden alone" % id)
		runtime.parts.apply(runtime.parts.answer(Command.new(Upgrades.SET_LEVEL, Parts.HOST, ups.id, {"upgrade": String(id), "level": 1})))
	await _paced_ticks(3)
	var cues := _cues(zoo)
	_check(not cues.owned() and not cues.hands_owned() and not cues.radar_owned(), "alone the levels count for nothing")
	_check(cues.matches().is_empty() and cues.arrow_targets().is_empty(), "alone no match and no arrow")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## The Host sets the team's House levels of `ids` to 1 (the Guest reads them off the answer).
func _own(host: Node3D, guest: Node3D, ids: Array) -> void:
	var hr := LevelRuntime.of(host)
	var hu := Upgrades.of(hr.hands)
	for id: String in ids:
		hr.parts.apply(hr.parts.answer(Command.new(Upgrades.SET_LEVEL, Parts.HOST, hu.id, {"upgrade": id, "level": 1})))
	var gu := Upgrades.of(_hands(guest))
	await _wait(func() -> bool: return ids.all(func(id: String) -> bool: return int(gu.house.get(id, 0)) == 1),
			"the Guest to read %s" % [ids], FPS * 2)


func _count(sound: StringName) -> int:
	var n := 0
	for e: Array in _heard:
		if StringName(e[0]) == sound and bool(e[1]):
			n += 1
	return n


## How many times `sound` played in the world within 2 m of `at` (both machines share this process's log).
func _count_near(sound: StringName, at: Vector3) -> int:
	var n := 0
	for e: Array in _heard:
		if StringName(e[0]) == sound and bool(e[1]) and (e[2] as Vector3).distance_to(at) < 2.0:
			n += 1
	return n


func _pair(lag_ms: int) -> Array[Node3D]:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, lag_ms)
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") and _mess(guest).count() == _mess(host).count(),
			"the guest zoo to be welcomed", FPS * 10)
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null, "each machine's avatar of the other", FPS * 5)
	return [host, guest]


## `zoo`'s player picks lying Sock `sock` with its own click.
func _pick(zoo: Node3D, sock: int) -> void:
	var mess := _mess(zoo)
	var at := mess.box_of(sock).get_center()
	await _aim(zoo, Vector3(at.x, 0.0, at.z + 1.0), at)
	await _wait(func() -> bool: return _player(zoo).aimed_sock == sock, "the crosshair on Sock %d" % sock, FPS * 2)
	Input.action_press(&"pick")
	await _paced_ticks(2)
	Input.action_release(&"pick")
	var me := _player(zoo).player_id()
	await _wait(func() -> bool: return _hands(zoo).items_of(me).has(sock), "Sock %d to be held" % sock, FPS * 3)
	await _paced_ticks(int(_player(zoo).hands_tuning.grab_interval * FPS) + 2)


func _stands_still(player: Player) -> void:
	var last := player.global_position
	for _i in FPS * 2:
		await _paced()
		var now := player.global_position
		if player.is_on_floor() and now.distance_to(last) < 0.0005:
			return
		last = now
	_check(false, "the player to stand still where it was put (within %d frames)" % (FPS * 2))


## Stands `zoo`'s player at `feet` looking at `target`; only it has the mouse.
func _aim(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := _player(zoo)
	for other: Node in _branches:
		var p := _in_branch(other).player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	_place(zoo, feet, target)
	await _stands_still(player)
	_place(zoo, Vector3(feet.x, player.global_position.y, feet.z), target)
	await _paced_ticks(2)
	await _host_has(player)


func _host_has(player: Player) -> void:
	var host_net := _in_branch(_branches[0]).net
	var me := player.player_id()
	for _i in FPS * 2:
		var at: Variant = host_net.where(me)
		if at is Vector3 and (at as Vector3).distance_to(player.global_position) < 0.1:
			return
		await _paced()
	_check(false, "the Host to have the player where it stands (within %d frames)" % (FPS * 2))


func _place(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := _player(zoo)
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	var head := player.get_node("Head") as Node3D
	var up := target - (feet + Vector3.UP * head.position.y)
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	player.reset_physics_interpolation()


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced_ticks(n: int) -> void:
	for _i in n:
		await _paced()


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _station(zoo: Node3D) -> Node3D:
	return zoo.get_node(STATION) as Node3D


func _spot_sock(zoo: Node3D, spot: String) -> int:
	return (zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _mess(zoo: Node3D) -> Mess:
	return LevelRuntime.of(zoo).mess


func _hands(zoo: Node3D) -> Hands:
	return LevelRuntime.of(zoo).hands


func _roster(zoo: Node3D) -> Roster:
	return LevelRuntime.of(zoo).roster


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


func _held(zoo: Node3D) -> HeldView:
	return _player(zoo).hud().held_view


func _cues(zoo: Node3D) -> SoleCues:
	return _player(zoo).get_node("Hud/SoleCues") as SoleCues


func _avatar(zoo: Node3D, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a) and not a.is_queued_for_deletion():
			return a
	return null


func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## A zoo in a machine of its own (its own MultiplayerAPI and 3D world), with only the KEEP stations.
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
		if not KEEP.has(String(station.name)):
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


func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
