## core/43 in co-op (list 03, answered by Q2590): two zoos in one process, each a machine of its own, real
## ENet over 127.0.0.1 on a port the system picks, with tests/support/lag_peer.gd on both ends, frames
## paced to 60 a second of wall time (tests/coop_hand_off_test.gd). Pings are made by each machine's own
## middle button (the click_middle action, mouse motion pushed into that machine's viewport) at the
## Pings station's Socks. The real path: the Guest's wheel puts Help on a Sock; the Host sees the bubble
## and hears the blip, a tap outlines a Sock on the other machine, and turned away the arrow points to it
## in the pinger's colour; at 0 and 50 ms one way.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Pings"]
const STATION := "Stations/Pings"
const NET_WAIT_S := 20.0
const FPS := 60
const LAG_MS := 50
const MIDDLE := &"click_middle"
## Where the Host waits, out of the Guest's way.
const HOST_ASIDE := Vector3(6.0, 0.0, -18.0)
## How long a ping stands in a joined pair (the Host's tuning, carried in the ping): shorter than the
## shipped seconds, so the waits for a ping's end are short; every check is made well before it ends.
const PING_S := 2.0

var _branches: Array[Node] = []
var _pace_next := 0
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []
## While set, the Guest's Commands are held back (sent on when it is cleared).
var _withhold := false
var _held_back: Array[Command] = []
var _up := Callable()


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "core/43 real path, 0 and 50 ms one way: the Guest holds the middle button past 0.25 s, the wheel opens, a mouse move toward Help and the release put Help on the Sock under its crosshair: on the Host the bubble stands over it and the blip plays there; the Host's tap outlines a Sock on the Guest's machine in the Host's colour; the Guest turned away sees an arrow to it in that colour"},
		{"name": "same_on_both", "method": "case_same_on_both", "world": false,
				"title": "core/43 co-op, 0 and 50 ms one way: a ping made by the Guest and by the Host is seen on the other machine with the same target, emoji and time (its serial and seconds), each ending on its own clock within the delay; a Guest sees its own ping only on the Host's answer; one per player (line 40)"},
		{"name": "picked_meanwhile", "method": "case_picked_meanwhile", "world": false,
				"title": "core/43 line 20, 50 ms: a Guest's ping on a Sock the Host picks up before the ping reaches it stands at the Sock's spot on both machines, a ring there"},
		{"name": "not_in_snapshot", "method": "case_not_in_snapshot", "world": false,
				"title": "core/43 line 42: pings are not in the join snapshot: a Guest joining while the Host's ping stands sees none, then sees the next"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	for a: StringName in [MIDDLE, &"pick"]:
		Input.action_release(a)
	_heard.clear()
	_withhold = false
	_held_back.clear()
	_drop_branches()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	for lag_ms: int in [0, LAG_MS]:
		await _real_path_round(lag_ms)


func _real_path_round(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	_place(host, HOST_ASIDE, HOST_ASIDE + Vector3.FORWARD)
	var sock := _spot_sock(guest, "Near")
	await _face_sock(guest, sock)
	await _wait(func() -> bool: return _player(guest).aimed_sock == sock, "the Guest's crosshair on the Sock", FPS * 2)
	var wheel := _player(guest).hud().wheel()
	Input.action_press(MIDDLE)
	await _wait(func() -> bool: return wheel.is_open(), "the Guest's wheel opens past 0.25 s (%d ms)" % lag_ms, FPS)
	_check(not _player(host).hud().wheel().is_open(), "the wheel is the Guest's own")
	await _move_mouse(guest, Vector2(140.0, -50.0))
	_check(wheel.chosen == 1, "a move toward Help chooses it (%d, %s)" % [wheel.chosen, wheel.pointer])
	_heard.clear()
	Input.action_release(MIDDLE)
	await _paced_ticks(1)
	var hp := _pings(host)
	await _wait(func() -> bool: return int(hp.ping_of(g).get("sock", -1)) == sock and Pings.emoji_of(hp.ping_of(g)) == "help",
			"Help on the Sock on the Host (%d ms)" % lag_ms, FPS * 2)
	await _wait(func() -> bool: return _marks(host).mark_of(g) != null and _marks(host).mark_of(g).sticker() != null,
			"the bubble stands on the Host's machine", FPS)
	var sticker := _marks(host).mark_of(g).sticker()
	var at := _mess(host).where_of(sock)
	_check(Vector2(sticker.global_position.x - at.x, sticker.global_position.z - at.z).length() < 0.1 and sticker.global_position.y > at.y,
			"line 33: over the Sock (%s, %s)" % [sticker.global_position, at])
	_check(_heard_at(&"ping", hp.ping_of(g)["at"] as Vector3), "line 41: the blip at the spot (%s)" % [_heard])

	# The Host's tap outlines a Sock on the Guest's machine, in the Host's colour.
	await _wait(func() -> bool: return _marks(host).mark_of(g) == null, "the Guest's ping ends", FPS * 6)
	var other := _spot_sock(host, "Behind")
	await _face_sock(host, other, Vector3(-1.4, 0.0, 0.0))
	await _wait(func() -> bool: return _player(host).aimed_sock == other, "the Host's crosshair on the other Sock", FPS * 2)
	await _tap()
	await _wait(func() -> bool: return _marks(guest).mark_of(Parts.HOST) != null and _marks(guest).mark_of(Parts.HOST).outline() != null,
			"line 22: the Sock is outlined on the Guest's machine (%d ms)" % lag_ms, FPS * 2)
	var colour := _roster(guest).colour_of(Parts.HOST)
	var outline := _marks(guest).mark_of(Parts.HOST).outline()
	_check(outline.current_style().colour.to_html(false) == colour.to_html(false), "line 22: in the Host's colour")
	_check(_marks(guest).mark_of(Parts.HOST).point().distance_to(_mess(guest).where_of(other)) < 0.01, "line 49: at the Sock")
	# Turned away, the arrow points to it in the Host's colour.
	var gp := _player(guest)
	_place(guest, gp.global_position, gp.global_position + (gp.global_position - _mess(guest).where_of(other)) * 3.0)
	await _paced_ticks(3)
	var arrows := gp.hud().hint_arrows()
	_check(arrows.count() == 1 and (arrows.shown()[0]["colour"] as Color).to_html(false) == colour.to_html(false),
			"line 46: an arrow in the Host's colour on the Guest's screen (%s)" % [arrows.shown()])
	_drop_branches()


func case_same_on_both() -> void:
	for lag_ms: int in [0, LAG_MS]:
		await _same_round(lag_ms)


func _same_round(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	_place(host, HOST_ASIDE, HOST_ASIDE + Vector3.FORWARD)
	var sock := _spot_sock(guest, "Near")
	await _face_sock(guest, sock)
	await _wait(func() -> bool: return _player(guest).aimed_sock == sock, "the Guest's crosshair on the Sock", FPS * 2)
	Input.action_press(MIDDLE)
	await _paced_ticks(2)
	Input.action_release(MIDDLE)
	await _paced_ticks(1)
	if lag_ms > 0:
		_check(_pings(guest).ping_of(g).is_empty() and _marks(guest).mark_of(g) == null, "Q2590: the Guest shows nothing before the Host's answer")
	await _wait(func() -> bool: return not _pings(guest).ping_of(g).is_empty(), "the Guest sees its own ping on the answer (%d ms)" % lag_ms, FPS * 2)
	_same(_pings(host).ping_of(g), _pings(guest).ping_of(g), "the Guest's ping, the same target, emoji, seconds and serial on both (%d ms)" % lag_ms)
	var gap := _pings(guest).left_of(g) - _pings(host).left_of(g)
	_check(gap >= -0.02 and gap <= lag_ms * 2.0 / 1000.0 + 0.1, "the same time, each on its own clock: the Guest's clock started at most the round trip later (%.3f s)" % gap)
	# The Host pings the floor; the Guest sees it, the same.
	var spot := _station(host).global_position + Vector3(0.6, 0.0, 1.2)
	await _aim(host, spot + Vector3(0.0, 0.0, 2.0), spot)
	await _tap()
	await _wait(func() -> bool: return not _pings(guest).ping_of(Parts.HOST).is_empty(), "the Host's ping reaches the Guest (%d ms)" % lag_ms, FPS * 2)
	_same(_pings(host).ping_of(Parts.HOST), _pings(guest).ping_of(Parts.HOST), "the Host's ping, the same on both (%d ms)" % lag_ms)
	await _paced_ticks(2)
	_check(_marks(guest).mark_of(Parts.HOST) != null and _marks(guest).mark_of(Parts.HOST).ring() != null, "line 25: the Guest draws its ring")
	# Line 40: the Host pings again; its last goes on both.
	var n := int(_pings(host).ping_of(Parts.HOST)["n"])
	await _tap()
	await _wait(func() -> bool: return int(_pings(guest).ping_of(Parts.HOST).get("n", -1)) > n, "the new ping reaches the Guest", FPS * 2)
	await _paced_ticks(1)
	_check(_marks(guest).count() <= 2 and _marks(guest).mark_of(Parts.HOST).n > n, "line 40: one ping per player on the Guest")
	# Each ends on its own clock.
	await _wait(func() -> bool: return _marks(host).count() == 0, "the pings end on the Host", FPS * 6)
	await _wait(func() -> bool: return _marks(guest).count() == 0, "and on the Guest within the delay", int(lag_ms * 2 * FPS / 1000.0) + 6)
	_drop_branches()


func case_picked_meanwhile() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var sock := _spot_sock(guest, "Near")
	var where := _mess(guest).where_of(sock)
	_place(host, where + Vector3(1.0, 0.0, 0.0), where)
	await _face_sock(guest, sock)
	await _wait(func() -> bool: return _player(guest).aimed_sock == sock, "the Guest's crosshair on the Sock", FPS * 2)
	_withhold = true
	Input.action_press(MIDDLE)
	await _paced_ticks(2)
	Input.action_release(MIDDLE)
	await _paced_ticks(1)
	_check(_held_back.size() == 1, "the Guest's ping is on its way")
	_hands(host).pick(Parts.HOST, sock)
	await _wait(func() -> bool: return _hands(host).items_of(Parts.HOST).has(sock), "the Host picks the Sock meanwhile", FPS)
	_withhold = false
	for cmd in _held_back:
		_up.call(cmd)
	_held_back.clear()
	await _wait(func() -> bool: return not _pings(guest).ping_of(g).is_empty(), "the ping is answered", FPS * 2)
	for zoo: Node3D in [host, guest]:
		var e := _pings(zoo).ping_of(g)
		_check(int(e["sock"]) == -1 and (e["at"] as Vector3).distance_to(where) < 0.01, "line 20: it stands at the Sock's spot (%s)" % [e])
	await _paced_ticks(2)
	_check(_marks(host).mark_of(g).ring() != null and _marks(guest).mark_of(g).ring() != null, "line 25: a ring there on both")
	_drop_branches()


func case_not_in_snapshot() -> void:
	var host := _branch("Host")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	var spot := _station(host).global_position + Vector3(0.6, 0.0, 1.2)
	await _aim(host, spot + Vector3(0.0, 0.0, 2.0), spot)
	await _tap()
	await _wait(func() -> bool: return not _pings(host).ping_of(Parts.HOST).is_empty(), "the Host's ping stands", FPS)
	_check(LevelRuntime.of(host).parts.snapshot()[_pings(host).id].is_empty(), "line 42: not in the snapshot")
	var guest := _branch("Guest")
	await _frames(2)
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") and _mess(guest).count() == _mess(host).count(),
			"the guest zoo to be welcomed", FPS * 10)
	await _paced_ticks(3)
	_check(_pings(guest).standing().is_empty() and _marks(guest).count() == 0, "line 42: the joiner sees no standing ping")
	await _tap()
	await _wait(func() -> bool: return not _pings(guest).ping_of(Parts.HOST).is_empty(), "then sees the next", FPS * 2)
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

func _heard_at(sound: StringName, at: Vector3) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and bool(e[1]) and (e[2] as Vector3).distance_to(at) < 0.01:
			return true
	return false


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
	var parts := LevelRuntime.of(guest).parts
	_up = parts.relay
	parts.relay = func(cmd: Command) -> void:
		if _withhold:
			_held_back.append(cmd)
		else:
			_up.call(cmd)
	for zoo: Node3D in [host, guest]:
		var pings := _pings(zoo)
		var t := pings.tuning.duplicate() as PingTuning
		t.seconds = PING_S
		pings.tuning = t
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null, "each machine's avatar of the other", FPS * 5)
	return [host, guest]


## Stands `zoo`'s player 1.2 m from Sock `sock` (on its +z side, or `side` away), looking at it.
func _face_sock(zoo: Node3D, sock: int, side := Vector3(0.0, 0.0, 1.2)) -> void:
	var at := _mess(zoo).box_of(sock).get_center()
	await _aim(zoo, Vector3(at.x + side.x, 0.0, at.z + side.z), at)


## A short press of the middle button (a tap).
func _tap() -> void:
	Input.action_press(MIDDLE)
	await _paced_ticks(2)
	Input.action_release(MIDDLE)
	await _paced_ticks(1)


## The mouse moves by `relative` pixels on `zoo`'s machine (its own viewport).
func _move_mouse(zoo: Node3D, relative: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.relative = relative
	_player(zoo).get_viewport().push_input(motion, true)
	await _paced_ticks(1)


## Waits until `player` stands on the floor and did not move over the last paced tick (a body put down
## in something is pushed out of it first).
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


## The Host judges reach by where it last heard this player stands (LevelNet.where()): a click sent before the pose
## got there is refused as too far (core/101, core/103). Waits until the Host has the player at `player`'s feet (all three axes: reach is 3D).
func _host_has(player: Player) -> void:
	var host_net := _in_branch(_branches[0]).net
	var me := player.player_id()
	await _wait(func() -> bool:
		var at: Variant = host_net.where(me)
		return at is Vector3 and (at as Vector3).distance_to(player.global_position) < 0.1,
			"the Host to have the player where it stands", FPS * 2)


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


func _pings(zoo: Node3D) -> Pings:
	return LevelRuntime.of(zoo).pings


func _marks(zoo: Node3D) -> PingMarks:
	return _pings(zoo).get_node("Marks") as PingMarks


func _roster(zoo: Node3D) -> Roster:
	return LevelRuntime.of(zoo).roster


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


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


## The level runtime of the zoo in branch `node` (a machine of its own), or null.
func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
