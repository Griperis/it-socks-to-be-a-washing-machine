## core/42 in co-op (list 02, answered by Q2588-Q2590): two zoos in one process, each a machine of its
## own, real ENet over 127.0.0.1 on a port the system picks, with tests/support/lag_peer.gd on both ends,
## frames paced to 60 a second of wall time (tests/coop_knockdown_test.gd). The Guest hands to the Hand-off
## station's stand-in Teammate (peer 6, holding a Brown Sock; on both machines) by its own input: accepted
## into a Pair, refused ("Not their mate"), no room (the Pair at their feet); the Host hands a Pair to
## the Guest; the Guest's Throw below full charge is caught or bounces. Both machines end with the same
## Hands and the same lying poses, at 0 and 50 ms one way. A Guest's own Hand-off shows nothing before the
## Host's answer, and with none after 2 s it is "refuse" only.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["HandOff"]
const STATION := "Stations/HandOff"
const NET_WAIT_S := 20.0
const FPS := 60
const LAG_MS := 50
const HOLDER := 6
## Where the Host waits, out of the Guest's way.
const HOST_ASIDE := Vector3(-8.0, 0.0, 6.0)

var _branches: Array[Node] = []
var _pace_next := 0
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []
## While set, the Guest's Commands never reach the Host (an answer that never comes).
var _withhold := false


func cases() -> Array[Dictionary]:
	return [
		{"name": "hand_off", "method": "case_hand_off", "world": false,
				"title": "core/42 lines 10-14, 18-25, 40, 41, 0 and 50 ms one way: the Guest's right click hands its Brown Sock to the stand-in holding the mate (the Pair on both machines), a Charcoal Sock is refused with Not their mate on the Guest alone, a Pair finds no room and lies at the stand-in's feet in the same pose on both; the Host hands that Pair to the Guest, flown into its Hands"},
		{"name": "catch", "method": "case_catch", "world": false,
				"title": "core/42 lines 33-35, Q2588, 0 and 50 ms one way: the Guest's Throw below full charge is caught by the stand-in holding its mate, the same Pair on both; a Charcoal Sock bounces off and lies in the same pose on both"},
		{"name": "guest_waits", "method": "case_guest_waits", "world": false,
				"title": "core/42 lines 10, 42, Q2477, Q2482, 50 ms: a Guest's own Hand-off changes nothing on the Guest before the Host's answer; with no answer after 2 s the item is still held and refuse plays once, nothing else"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	for a: StringName in [&"pick", &"drop_throw"]:
		Input.action_release(a)
	_heard.clear()
	_withhold = false
	_drop_branches()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_hand_off() -> void:
	for lag_ms: int in [0, LAG_MS]:
		await _hand_off_round(lag_ms)


func _hand_off_round(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gp := _player(guest)
	var hp := _player(host)
	var g := gp.player_id()
	_place(host, HOST_ASIDE, HOST_ASIDE + Vector3.FORWARD)
	var lead := _spot_sock(host, "Held")
	await _wait(func() -> bool: return _hands(host).items_of(HOLDER).has(lead) and _hands(guest).items_of(HOLDER).has(lead),
			"the stand-in holds its Brown Sock on both", FPS * 5)
	# Accepted: the Pair is made in the stand-in's Hands on both machines.
	var sock := _spot_sock(guest, "Mate")
	await _pick(guest, sock)
	await _face(guest, _stand_in(guest).global_position)
	await _wait(func() -> bool: return gp.aimed_mate == HOLDER, "the Guest aims at the stand-in", FPS)
	await _tap()
	await _wait(func() -> bool: return _mess(host).mate_of(lead) == sock and _mess(guest).mate_of(lead) == sock,
			"line 41: the Pair made on both machines (%d ms)" % lag_ms, FPS * 3)
	_same_hands(host, guest, [g, HOLDER], "accepted, %d ms" % lag_ms)
	_check(_hands(guest).items_of(g).is_empty(), "the Guest's Hands empty")
	await _paced_ticks(1)
	_check(_stand_in(guest).held.flying_up(lead) or _stand_in(guest).held.sparkles > 0, "line 25: the Guest sees it fly into the stand-in's Hands")

	# Refused: Not their mate to the Guest alone, the Sock still held on both.
	var odd := _spot_sock(guest, "Odd")
	await _pick(guest, odd)
	await _face(guest, _stand_in(guest).global_position)
	await _wait(func() -> bool: return gp.aimed_mate == HOLDER, "the Guest aims again", FPS)
	await _tap()
	await _wait(func() -> bool: return gp.message() == Player.NOT_THEIR_MATE, "line 14: the Guest reads Not their mate (%d ms)" % lag_ms, FPS * 2)
	_check(hp.message() != Player.NOT_THEIR_MATE, "line 14: the Host reads nothing")
	_check(_hands(host).items_of(g).has(odd) and _hands(guest).items_of(g).has(odd), "line 14: the Sock stays held on both")
	_same_hands(host, guest, [g, HOLDER], "refused, %d ms" % lag_ms)

	# No room: the Pair lies at the stand-in's feet, the same pose on both.
	var a := _spot_sock(guest, "PairA")
	await _pick(guest, a)
	await _pick(guest, _spot_sock(guest, "PairB"))
	await _face(guest, _stand_in(guest).global_position)
	await _wait(func() -> bool: return gp.aimed_mate == HOLDER, "the Guest aims with the Pair", FPS)
	await _tap()
	await _wait(func() -> bool: return _mess(host).state_of(a) == Mess.State.LYING and _mess(guest).state_of(a) == Mess.State.LYING,
			"line 23: the Pair lies down on both (%d ms)" % lag_ms, FPS * 3)
	await _paced_ticks(2)
	var gap := _mess(host).pose_of(a).origin.distance_to(_mess(guest).pose_of(a).origin)
	_check(gap < 0.001, "line 41: the same pose on both (%.4f m)" % gap)
	_same_hands(host, guest, [g, HOLDER], "no room, %d ms" % lag_ms)
	_check(gp.message() != Player.HANDS_FULL, "line 23: the giver reads nothing of it")

	# The Host hands that Pair to the Guest, who has room.
	_place(guest, Vector3(-13.0, 0.0, 6.5), Vector3(-13.0, 1.6, 3.0))
	await _pick(host, a)
	var target := _avatar(host, g)
	await _face(host, target.global_position)
	await _wait(func() -> bool: return hp.aimed_mate == g, "the Host aims at the Guest", FPS)
	await _tap()
	await _wait(func() -> bool: return _hands(host).items_of(g).has(a) and _hands(guest).items_of(g).has(a),
			"line 18: the Pair in the Guest's Hands on both (%d ms)" % lag_ms, FPS * 3)
	_check(_hands(guest).active_of(g) == a, "line 20: active")
	await _paced_ticks(1)
	_check(gp.held_view().flying_up(a) or gp.held_view().settled() == false, "line 25: it flies into the Guest's own view")
	_same_hands(host, guest, [Parts.HOST, g, HOLDER], "to the Guest, %d ms" % lag_ms)
	_drop_branches()


func case_catch() -> void:
	for lag_ms: int in [0, LAG_MS]:
		await _catch_round(lag_ms)


func _catch_round(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	_place(host, HOST_ASIDE, HOST_ASIDE + Vector3.FORWARD)
	var lead := _spot_sock(host, "Held")
	await _wait(func() -> bool: return _hands(host).items_of(HOLDER).has(lead) and _hands(guest).items_of(HOLDER).has(lead),
			"the stand-in holds its Brown Sock on both", FPS * 5)
	var odd := _spot_sock(guest, "Odd")
	await _pick(guest, odd)
	await _face(guest, _stand_in(guest).global_position, 1.2)
	await _throw(guest, 0.6)
	var kd := LevelRuntime.of(host).knockdowns
	await _wait(func() -> bool: return kd.bounces == 1, "line 35: the Charcoal Sock bounces off on the Host (%d ms)" % lag_ms, FPS * 2)
	await _wait(func() -> bool: return _mess(host).state_of(odd) == Mess.State.LYING and _mess(guest).state_of(odd) == Mess.State.LYING,
			"it lies on both", FPS * 8)
	await _paced_ticks(2)
	var gap := _mess(host).pose_of(odd).origin.distance_to(_mess(guest).pose_of(odd).origin)
	_check(gap < 0.001, "the same lying pose on both (%.4f m)" % gap)
	_check(_player(guest).message() == "", "line 35: nobody reads anything")
	_same_hands(host, guest, [g, HOLDER], "bounced, %d ms" % lag_ms)
	var sock := _spot_sock(guest, "Mate")
	await _pick(guest, sock)
	await _face(guest, _stand_in(guest).global_position, 1.2)
	await _throw(guest, 0.6)
	await _wait(func() -> bool: return _mess(host).mate_of(lead) == sock and _mess(guest).mate_of(lead) == sock,
			"line 34: caught into the Pair on both (%d ms)" % lag_ms, FPS * 3)
	_same_hands(host, guest, [g, HOLDER], "caught, %d ms" % lag_ms)
	await _paced_ticks(int(LAG_MS * 2 * FPS / 1000.0) + 4)
	_check(_mess(guest).moving_body(sock) == null and _player(guest).ghosts().ghost_of(sock) == null, "the Guest's Throw copy and ghost end")
	_drop_branches()


func case_guest_waits() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gp := _player(guest)
	var g := gp.player_id()
	_place(host, HOST_ASIDE, HOST_ASIDE + Vector3.FORWARD)
	var lead := _spot_sock(host, "Held")
	await _wait(func() -> bool: return _hands(guest).items_of(HOLDER).has(lead), "the stand-in holds its Sock on the Guest", FPS * 5)
	var sock := _spot_sock(guest, "Mate")
	await _pick(guest, sock)
	await _face(guest, _stand_in(guest).global_position)
	await _wait(func() -> bool: return gp.aimed_mate == HOLDER, "the Guest aims at the stand-in", FPS)
	# Before the answer: nothing changes on the Guest (line 10).
	_heard.clear()
	await _tap()
	var view := gp.held_view()
	_check(_hands(guest).items_of(g).has(sock) and view.looks_of(sock) != null and view.looks_of(sock).visible and not view.is_hidden(sock),
			"line 10: right after the click the Sock is still held and drawn on the Guest")
	await _wait(func() -> bool: return _mess(guest).mate_of(lead) == sock, "then the answer pairs it", FPS * 2)
	# No answer: refuse only, after 2 s.
	var odd := _spot_sock(guest, "Odd")
	await _pick(guest, odd)
	await _face(guest, _stand_in(guest).global_position)
	await _wait(func() -> bool: return gp.aimed_mate == HOLDER, "the Guest aims again", FPS)
	_withhold = true
	_heard.clear()
	var timed := gp.ghosts().timed_out
	await _tap()
	await _paced_ticks(int(gp.ghosts().tuning.answer_timeout * FPS * 0.8))
	_check(gp.ghosts().timed_out == timed and _count_flat(&"refuse") == 0, "nothing before 2 s")
	await _wait(func() -> bool: return gp.ghosts().timed_out > timed, "line 42: the Hand-off times out", FPS * 2)
	_check(_count_flat(&"refuse") == 1, "Q2477: refuse plays once (%s)" % [_heard])
	_check(gp.message() == "", "Q2482: no text")
	_check(_hands(guest).items_of(g).has(odd) and view.looks_of(odd) != null and view.looks_of(odd).visible, "the item stays in the Hands")
	_withhold = false
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## Both machines hold the same items, the same active one, for each player of `who`.
func _same_hands(host: Node3D, guest: Node3D, who: Array, what: String) -> void:
	for peer: int in who:
		var a := _hands(host).items_of(peer)
		var b := _hands(guest).items_of(peer)
		_check(a == b and _hands(host).active_of(peer) == _hands(guest).active_of(peer),
				"the same Hands on both for %d, %s (%s / %s)" % [peer, what, a, b])


func _count_flat(sound: StringName) -> int:
	var n := 0
	for e: Array in _heard:
		if StringName(e[0]) == sound and not bool(e[1]):
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
	var parts := LevelRuntime.of(guest).parts
	var up := parts.relay
	parts.relay = func(cmd: Command) -> void:
		if not _withhold:
			up.call(cmd)
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null, "each machine's avatar of the other", FPS * 5)
	return [host, guest]


## `zoo`'s player picks Sock `sock` (a lying Pair by its ball) with its own click.
func _pick(zoo: Node3D, sock: int) -> void:
	var mess := _mess(zoo)
	var at := mess.pose_of(sock).origin if mess.is_pair(sock) else mess.box_of(sock).get_center()
	await _aim(zoo, Vector3(at.x, 0.0, at.z + 1.0), at)
	await _wait(func() -> bool: return _player(zoo).aimed_sock == sock, "the crosshair on Sock %d" % sock, FPS * 2)
	Input.action_press(&"pick")
	await _paced_ticks(2)
	Input.action_release(&"pick")
	var me := _player(zoo).player_id()
	await _wait(func() -> bool: return _hands(zoo).items_of(me).has(sock) or mess.state_of(sock) == Mess.State.IN_PAIR,
			"Sock %d to be held" % sock, FPS * 3)
	await _paced_ticks(int(_player(zoo).hands_tuning.grab_interval * FPS) + 2)


## Stands `zoo`'s player `away` m in front of the body at `feet` (on its +z side), looking at its chest.
func _face(zoo: Node3D, feet: Vector3, away := 1.5) -> void:
	await _aim(zoo, Vector3(feet.x, 0.0, feet.z + away), feet + Vector3.UP * 1.1)


## A short click of the right button.
func _tap() -> void:
	Input.action_press(&"drop_throw")
	await _paced_ticks(2)
	Input.action_release(&"drop_throw")
	await _paced_ticks(1)


## Holds `zoo`'s right button until the ring shows `charge`, then lets go.
func _throw(zoo: Node3D, charge: float) -> void:
	var player := _player(zoo)
	Input.action_press(&"drop_throw")
	await _wait(func() -> bool: return player.charging and player.charge >= charge, "the ring to reach %.1f" % charge, FPS * 3)
	Input.action_release(&"drop_throw")
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


## The Host judges reach by where it last heard this player stands (LevelNet.where()): waits until the
## Host has the player at its feet (within 0.1 m), as a click sent before that is refused as too far.
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


func _spot_sock(zoo: Node3D, spot: String) -> int:
	return (zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _stand_in(zoo: Node3D) -> Avatar:
	return zoo.get_node(STATION + "/Holder/%d" % HOLDER) as Avatar


func _mess(zoo: Node3D) -> Mess:
	return LevelRuntime.of(zoo).mess


func _hands(zoo: Node3D) -> Hands:
	return LevelRuntime.of(zoo).hands


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
