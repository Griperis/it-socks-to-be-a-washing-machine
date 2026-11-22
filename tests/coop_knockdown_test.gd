## coop/10 in co-op (list 04, approved by Q2496): two zoos in one process, each a machine of its own,
## real ENet over 127.0.0.1 with tests/support/lag_peer.gd on both ends, frames paced to 60 a second of
## wall time (tests/coop_hands_test.gd). The Host's input throws a full-charge Sock at the Guest: the
## Guest falls as a ragdoll on both machines (the Host simulates, the Guest eases to the stamped pose),
## drops what it held, reads "Player knocked you down", hears the knockdown, stands up 5.5 s later where it
## lies. The Guest drags the knocked Host; the Host's 10 jump presses free it. A late joiner sees a body
## lying and dragged. A Guest's forged knock is dropped. Numbers are printed as `KNOCK` lines.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Knockdown"]
const STATION := "Stations/Knockdown"
const NET_WAIT_S := 20.0
const FPS := 60
const LAG_MS := 50
## Where the Guest stands in the real path, and the Host throws from.
const GUEST_AT := Vector3(-18.5, 0.0, 3.0)
const HOST_AT := Vector3(-18.5, 0.0, 4.3)

var _branches: Array[Node] = []
var _pace_next := 0
## Every spatial sound played: [name, where, frame].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path_50ms", "method": "case_real_path_50ms", "world": false,
				"title": "coop/10 real path, 50 ms: the Host throws a full-charge Sock at the Guest: it falls as a ragdoll on both (E40, J129, J130, K141), drops its Sock where it stood (D36), its view rides the head (F68, F69, F75), reads Player knocked you down (F78), hears knockdown (M155), its pad buzzes (M149), and stands up 5.5 s later where it lies (G85, K142)"},
		{"name": "drag_and_struggle", "method": "case_drag_and_struggle", "world": false,
				"title": "coop/10 H93-H110, 50 ms: the Guest grabs the knocked Host by the feet and drags it; the Host's 10 jump presses free it and it gets up (H106); a drag ends at the rise (H104)"},
		{"name": "late_joiner", "method": "case_late_joiner", "world": false,
				"title": "coop/10 J136: a Guest who joins while a Teammate lies dragged sees the body lying where it lies and the drag"},
		{"name": "forged", "method": "case_forged", "world": false,
				"title": "coop/10 B23, B26, invariant 1: a Guest's knock or release Command is dropped by the Host; its grab of a standing body is refused"},
		{"name": "pose_bytes", "method": "case_pose_bytes", "world": false,
				"title": "coop/10 J132, J133: the Host's bytes a second per knocked player, at 0 and 50 ms one way (printed); a pose of the wrong size is dropped (J134)"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	for a: StringName in [&"pick", &"drop_throw", &"jump", &"move_back"]:
		Input.action_release(a)
	_heard.clear()
	PadRumble.reset()
	_drop_branches()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	if spatial:
		_heard.append([sound, at, Engine.get_process_frames()])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path_50ms() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hp := _player(host)
	var gp := _player(guest)
	var g := gp.player_id()
	var hk := _kd(host)
	var gk := _kd(guest)
	# The Guest holds a Sock (D36), standing where it will be hit.
	var held := _spot_sock(guest, "SockB")
	await _pick(guest, held)
	_place(guest, GUEST_AT, GUEST_AT + Vector3(0.0, 1.6, -3.0))
	var sock := _spot_sock(host, "SockA")
	await _pick(host, sock)
	await _paced_ticks(20)
	var target := _avatar(host, g)
	await _aim(host, HOST_AT, target.global_position + Vector3.UP * 1.25)
	var yaw := gp.global_rotation.y
	var heard_from := Engine.get_process_frames()
	Input.action_press(&"drop_throw")
	await _wait(func() -> bool: return hp.charging and hp.charge >= 1.0, "the Host's ring to fill", FPS * 3)
	Input.action_release(&"drop_throw")
	await _wait(func() -> bool: return hk.is_down(g), "A2: the Host decides the Guest is knocked down", FPS * 2)
	var stood := gp.global_position
	await _wait(func() -> bool: return gk.is_down(g) and gp.knocked, "the Guest's machine has it down", FPS * 2)
	_check(not hk.is_down(Parts.HOST), "B16: the thrower is not knocked")
	var host_rag := target.ragdoll
	var own := _avatar(guest, g)
	_check(host_rag.simulating, "K141: the Host simulates the Guest's ragdoll")
	_check(own != null and not own.ragdoll.simulating and own.ragdoll.phase == Ragdoll.Phase.DOWN, "J130: the Guest's copy never simulates")
	await _wait(func() -> bool: return own.ragdoll.received > 0, "J132: the Host's pose reaches the Guest", FPS)
	_check(_hands(host).items_of(g).is_empty() and _hands(guest).items_of(g).is_empty(), "D36: the knocked Guest's Hands are empty on both")
	await _wait(func() -> bool: return _mess(host).state_of(held) == Mess.State.LYING and _mess(guest).state_of(held) == Mess.State.LYING,
			"the dropped Sock to lie on both", FPS * 6)
	var lies := _mess(host).pose_of(held).origin
	_check(Vector2(lies.x - stood.x, lies.z - stood.z).length() < 0.8, "D36, Q2486: it lies where the Guest stood (%.2f m)" % Vector2(lies.x - stood.x, lies.z - stood.z).length())
	_check(gp.hud().message_text() == "Player knocked you down", "F78: the Guest reads Player knocked you down (%s)" % gp.hud().message_text())
	_check(hp.hud().message_text() != "Player knocked you down", "F78: the thrower gets no line")
	_check(_heard_in(&"knockdown", guest, heard_from) and _heard_in(&"knockdown", host, heard_from), "M155: both machines hear knockdown")
	_check(PadRumble.last == PadRumble.KNOCK, "M149: the knocked player's pad buzzes")
	_check(gp.ring().visible == false and not gp.charging, "F68, L145: no charge while down")
	_check(gp.get_node("%Vignette").visible, "F75: the vignette shows while down")
	_check(gp.hud().visible, "F76: the HUD stays")
	await _wait(func() -> bool: return _topple(host_rag) > 45.0 and _topple(own.ragdoll) > 40.0, "J129: it lies over on both machines", FPS * 3)
	var gap := host_rag.feet().distance_to(own.ragdoll.feet())
	print("KNOCK real path 50 ms: lies over %.0f (Host) and %.0f (Guest) degrees, feet %.2f m apart" % [_topple(host_rag), _topple(own.ragdoll), gap])
	var eye := gp.view().origin
	_check(eye.y < 1.2, "F69: the Guest's view rides the fallen head (%.2f m up)" % eye.y)
	_check(Vector2(gp.global_position.x - own.ragdoll.feet().x, gp.global_position.z - own.ragdoll.feet().z).length() < 0.05,
			"G85, K142: the Guest's own body stays at its ragdoll's feet")
	Input.action_press(&"move_back")
	await _paced_ticks(10)
	Input.action_release(&"move_back")
	_check(Vector2(gp.global_position.x - own.ragdoll.feet().x, gp.global_position.z - own.ragdoll.feet().z).length() < 0.05,
			"F68: walking input does nothing while down")
	await _wait(func() -> bool: return own.ragdoll.phase == Ragdoll.Phase.RISING, "G80: the Guest starts getting up", FPS * 8)
	var lay := own.ragdoll.feet()
	await _wait(func() -> bool: return not gk.is_down(g) and not gp.knocked, "G86: the Guest stands up", FPS * 2)
	await _paced_ticks(10)
	_check(not own.looks.ragdolled and not target.looks.ragdolled, "G86: the avatar stands on both")
	_check(absf(gp.global_position.y) < 0.1 and Vector2(gp.global_position.x - lay.x, gp.global_position.z - lay.z).length() < 0.4,
			"G82: the Guest stands where it lay (%s, its feet lay at %s)" % [gp.global_position, lay])
	_near(gp.global_rotation.y, yaw, 0.01, "G83: facing its own way")
	_check(gp.view().origin.distance_to(gp.eyes()) < 0.2, "F74: the view is back at the standing head")
	_drop_branches()


func case_drag_and_struggle() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hp := _player(host)
	var gp := _player(guest)
	var g := gp.player_id()
	var hk := _kd(host)
	var gk := _kd(guest)
	_place(host, GUEST_AT, GUEST_AT + Vector3(0.0, 1.6, -3.0))
	await _paced_ticks(20)
	_knock(host, Parts.HOST, g)
	await _wait(func() -> bool: return gk.is_down(Parts.HOST) and hp.knocked, "the Host to lie down", FPS * 2)
	await _paced_ticks(70)
	var body := _avatar(guest, Parts.HOST)
	var mid := body.ragdoll.point_at(0.8)
	await _aim(guest, Vector3(mid.x + 1.4, 0.0, mid.z), mid)
	await _wait(func() -> bool: return gp.aimed_body == Parts.HOST, "H92: the Guest aims at the lying Host", FPS)
	Input.action_press(&"pick")
	await _wait(func() -> bool: return gk.dragger_of(Parts.HOST) == g and hk.dragger_of(Parts.HOST) == g, "H93: the Guest grabs the Host by the feet", FPS * 2)
	_check(PadRumble.last == PadRumble.KNOCK, "H110, M150: the dragged player's pad buzzes")
	_check(hp.hud().hints_text().contains(Prompts.STRUGGLE), "H105: the dragged Host is told Mash: Struggle (%s)" % hp.hud().hints_text())
	var feet_from := _avatar(host, Parts.HOST).ragdoll.feet()
	Input.action_press(&"move_back")
	await _paced_ticks(40)
	Input.action_release(&"move_back")
	var moved := _avatar(host, Parts.HOST).ragdoll.feet().distance_to(feet_from)
	_check(moved > 0.4, "H99: the Host's feet are pulled after the Guest (%.2f m)" % moved)
	for i in 10:
		Input.action_press(&"jump")
		await _paced_ticks(2)
		Input.action_release(&"jump")
		await _paced_ticks(4)
	await _wait(func() -> bool: return hk.dragger_of(Parts.HOST) == -1 and gk.dragger_of(Parts.HOST) == -1, "H106: 10 presses free the Host", FPS * 2)
	_check(hk.is_rising(Parts.HOST) or not hk.is_down(Parts.HOST), "H106: freed, it gets up at once")
	await _wait(func() -> bool: return not hp.knocked, "the Host stands", FPS * 2)
	Input.action_release(&"pick")
	await _paced_ticks(20)
	# H104: a drag ends at the rise.
	_knock(host, Parts.HOST, g)
	await _wait(func() -> bool: return gk.is_down(Parts.HOST), "the Host down again", FPS * 2)
	await _paced_ticks(70)
	mid = body.ragdoll.point_at(0.8)
	await _aim(guest, Vector3(mid.x + 1.4, 0.0, mid.z), mid)
	await _wait(func() -> bool: return gp.aimed_body == Parts.HOST, "the Guest aims again", FPS)
	Input.action_press(&"pick")
	await _wait(func() -> bool: return hk.dragger_of(Parts.HOST) == g, "grabbed again", FPS * 2)
	await _wait(func() -> bool: return hk.is_rising(Parts.HOST), "the rise", FPS * 7)
	await _wait(func() -> bool: return not hk.drags.has(Parts.HOST) and not gk.drags.has(Parts.HOST), "H104: the drag ends at the rise, on both", FPS)
	Input.action_release(&"pick")
	_drop_branches()


func case_late_joiner() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var hk := _kd(host)
	_place(guest, GUEST_AT, GUEST_AT + Vector3(0.0, 1.6, -3.0))
	await _paced_ticks(20)
	_knock(host, g, Parts.HOST)
	await _paced_ticks(60)
	var rag := _avatar(host, g).ragdoll
	var hp := _player(host)
	hp.global_position = rag.feet() + Vector3(1.0, 0.0, 0.0)
	await _paced_ticks(4)
	hp.capture_mouse()  # the Host's button holds the drag (it lets go once it does not act)
	hp.set("_grab_held", true)
	_parts(host).ask(Command.new(Knockdowns.GRAB, Parts.HOST, hk.id, {"target": g}))
	_check(hk.dragger_of(g) == Parts.HOST, "the Host drags the Guest")
	var late := _branch("Late")
	await _frames(2)
	var ls := late.get_node("Session") as Session
	ls.profile = PlayerProfile.fresh()
	_check((late.get_node("Net") as ZooNet).start(["--join=127.0.0.1:%d" % (host.get_node("Session") as Session).port]) == OK, "a third zoo joins")
	_lag(late, LAG_MS)
	var lk := _kd(late)
	await _wait(func() -> bool: return (late.get_node("Net") as ZooNet).mode_text().begins_with("Joined") and _avatar(late, g) != null, "the late Guest welcomed, with the avatars", FPS * 10)
	await _paced_ticks(10)
	_check(lk.is_down(g) and absf(lk.left_of(g) - hk.left_of(g)) < 0.5, "J136: the joiner has the knockdown with what is left (%.2f, Host %.2f)" % [lk.left_of(g), hk.left_of(g)])
	_check(lk.dragger_of(g) == Parts.HOST, "J136: and the drag")
	var seen := _avatar(late, g)
	_check(seen.ragdoll.phase == Ragdoll.Phase.DOWN and seen.looks.ragdolled, "J136: the body lies there")
	var off := seen.ragdoll.feet().distance_to(rag.feet())
	_check(off < 0.5 and _topple(seen.ragdoll) > 40.0, "J136: where the Host's lies, lying over (%.2f m, %.0f degrees)" % [off, _topple(seen.ragdoll)])
	await _wait(func() -> bool: return not lk.is_down(g) and seen.ragdoll.phase == Ragdoll.Phase.UP, "everyone stands it up at the end", FPS * 8)
	hp.set("_grab_held", false)
	_drop_branches()


func case_forged() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var hs := host.get_node("Session") as Session
	var gk := _kd(guest)
	var relay: Callable = _parts(guest).relay
	relay.call(Command.new(Knockdowns.KNOCK, g, gk.id, {"target": Parts.HOST, "thrower": g, "push": Vector3.FORWARD,
			"high": 0.5, "side": 0.0, "at": Vector3.ZERO}))
	relay.call(Command.new(Knockdowns.RELEASE, g, gk.id, {"target": Parts.HOST, "why": "up"}))
	relay.call(Command.new(Knockdowns.GRAB, g, gk.id, {"target": Parts.HOST}))
	await _wait(func() -> bool: return int(hs.dropped.get(g, {}).get("verb", 0)) >= 2, "the Host drops the forged knock and release", FPS * 2)
	await _paced_ticks(10)
	_check(not _kd(host).is_down(Parts.HOST) and not gk.is_down(Parts.HOST), "invariant 1: nobody is knocked by a Guest's word")
	_check(_kd(host).drags.is_empty(), "H94: a grab of a standing body is refused")
	_drop_branches()


func case_pose_bytes() -> void:
	for lag: int in [0, LAG_MS]:
		var zoos := await _pair(lag)
		var host: Node3D = zoos[0]
		var guest: Node3D = zoos[1]
		var g := _player(guest).player_id()
		_place(guest, GUEST_AT, GUEST_AT + Vector3(0.0, 1.6, -3.0))
		await _paced_ticks(30)
		var enet := (host.multiplayer.multiplayer_peer as LagPeer).inner.host
		enet.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
		var t0 := Time.get_ticks_msec()
		await _paced_ticks(90)
		var still := enet.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA) * 1000.0 / maxf(1.0, Time.get_ticks_msec() - t0)
		_knock(host, g, Parts.HOST)
		await _paced_ticks(2)
		enet.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
		t0 = Time.get_ticks_msec()
		var own := _avatar(guest, g).ragdoll
		var got := own.received
		await _paced_ticks(90)
		var down := enet.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA) * 1000.0 / maxf(1.0, Time.get_ticks_msec() - t0)
		var poses := (own.received - got) * 1000.0 / maxf(1.0, Time.get_ticks_msec() - t0)
		print("KNOCK bytes at %d ms one way: Host sends %.0f B/s with nobody down, %.0f B/s with one falling: %.0f B/s per knocked player; %.1f poses a second reach the Guest" \
				% [lag, still, down, down - still, poses])
		_check(poses > 8.0 and poses < 25.0, "J132: the pose reaches the Guest about 20 times a second while it moves (%.1f)" % poses)
		_check(down - still < 4000.0, "J133: under 4 kB/s per knocked player (%.0f)" % (down - still))
		var before := own.dropped
		own.pose = PackedByteArray([1, 2, 3])
		_check(own.dropped == before + 1, "J134: a pose of the wrong size is dropped")
		_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## The Host knocks `target` down as thrown by `thrower` (the hit's own answer, without a Throw).
func _knock(host: Node3D, target: int, thrower: int) -> void:
	var hk := _kd(host)
	var place: Variant = hk.place_of(target)
	var at: Vector3 = (place as Transform3D).origin if place is Transform3D else Vector3.ZERO
	_parts(host).ask(Command.new(Knockdowns.KNOCK, Parts.HOST, hk.id, {"target": target, "thrower": thrower,
			"push": Vector3.FORWARD, "high": 0.8, "side": 0.1, "at": at + Vector3.UP * 1.3}))


func _pair(lag_ms: int) -> Array[Node3D]:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := host.get_node("Session") as Session
	var gs := guest.get_node("Session") as Session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	_check((host.get_node("Net") as ZooNet).start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	_check((guest.get_node("Net") as ZooNet).start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, lag_ms)
	await _wait(func() -> bool: return (guest.get_node("Net") as ZooNet).mode_text().begins_with("Joined") and _mess(guest).count() == _mess(host).count(),
			"the guest zoo to be welcomed", FPS * 10)
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null, "each machine's avatar of the other", FPS * 5)
	return [host, guest]


## `zoo`'s player picks Sock `sock` with its own click.
func _pick(zoo: Node3D, sock: int) -> void:
	var at := _mess(zoo).box_of(sock).get_center()
	await _aim(zoo, Vector3(at.x, 0.0, at.z + 1.0), at)
	await _wait(func() -> bool: return _player(zoo).aimed_sock == sock, "the crosshair on Sock %d" % sock, FPS * 2)
	Input.action_press(&"pick")
	await _paced_ticks(2)
	Input.action_release(&"pick")
	await _wait(func() -> bool: return _hands(zoo).items_of(_player(zoo).player_id()).has(sock), "Sock %d to be held" % sock, FPS * 3)


## Stands `zoo`'s player at `feet` looking at `target`; only it has the mouse.
func _aim(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := _player(zoo)
	for other: Node in _branches:
		var p := other.get_node_or_null("View/Zoo/Player") as Player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	_place(zoo, feet, target)
	await _paced_ticks(int(LAG_MS * 3 * FPS / 1000.0) + 4)
	_place(zoo, Vector3(feet.x, player.global_position.y, feet.z), target)
	await _paced_ticks(2)


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


func _topple(rag: Ragdoll) -> float:
	return rad_to_deg((rag.point_at(1.7) - rag.feet()).angle_to(Vector3.UP))


## Whether `sound` played in `zoo`'s world (near one of its players' bodies or avatars) since `frame`.
func _heard_in(sound: StringName, zoo: Node3D, frame: int) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and int(e[2]) >= frame and (e[1] as Vector3).distance_to(_player(zoo).global_position) < 6.0:
			return true
	return false


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


func _kd(zoo: Node3D) -> Knockdowns:
	return zoo.get_node("Socks/Knockdowns") as Knockdowns


func _mess(zoo: Node3D) -> Mess:
	return zoo.get_node("Socks/Mess") as Mess


func _hands(zoo: Node3D) -> Hands:
	return zoo.get_node("Socks/Hands") as Hands


func _parts(zoo: Node3D) -> Parts:
	return zoo.get_node("Parts") as Parts


func _player(zoo: Node3D) -> Player:
	return zoo.get_node("Player") as Player


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
		var session := node.get_node_or_null("View/Zoo/Session") as Session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
