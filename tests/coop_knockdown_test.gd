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
## The game clock runs this many times faster than the wall clock, one frame per physics tick (runner.gd puts it back after each case).
const PACE_SPEED := 2.0
const LAG_MS := 50
## Where the Guest stands in the real path, and the Host throws from.
const GUEST_AT := Vector3(-18.5, 0.0, 3.0)
const HOST_AT := Vector3(-18.5, 0.0, 4.3)

var _branches: Array[Node] = []
var _pace_next := 0
var _speed := 1.0
## Every spatial sound played: [name, where, frame].
var _heard: Array[Array] = []
## Why each drag the Guest saw end ended (case_drag_ends).
var _whys: Array[String] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "coop/10 real path, 0 and 50 ms one way: the Host throws a full-charge Sock at the Guest: it falls as a ragdoll on both (E40, J129, J130, K141), drops its Sock where it stood (D36), its view rides the head (F68, F69, F75), reads Player knocked you down (F78), hears knockdown (M155), its pad buzzes (M149), and stands up 5.5 s later where it lies (G85, K142)"},
		{"name": "drag_and_struggle", "method": "case_drag_and_struggle", "world": false,
				"title": "coop/10 H93-H110, 50 ms: the Guest grabs the knocked Host by the feet and drags it; the Host's 10 jump presses free it and it gets up (H106); a drag ends at the rise (H104)"},
		{"name": "late_joiner", "method": "case_late_joiner", "world": false,
				"title": "coop/10 J136: a Guest who joins while a Teammate lies dragged sees the body lying where it lies and the drag"},
		{"name": "forged", "method": "case_forged", "world": false,
				"title": "coop/10 B23, B26, invariant 1: a Guest's knock or release Command is dropped by the Host; its grab of a standing body is refused"},
		{"name": "pose_bytes", "method": "case_pose_bytes", "world": false,
				"title": "coop/10 J132, J133: the Host's bytes a second per knocked player, at 0 and 50 ms one way (printed); a pose of the wrong size is dropped (J134)"},
		{"name": "drag_ends", "method": "case_drag_ends", "world": false,
				"title": "coop/12 (coop/10 D37, H97, H101 in co-op): the Guest drags the knocked Host; its drag ends on both machines when a menu opens on it (H97), when the feet are left over 2 m behind (H101, apart), and when the Guest is knocked down itself (D37, knocked)"},
		{"name": "inside", "method": "case_inside", "world": false,
				"title": "coop/12 (coop/10 E53): a Teammate standing inside the body as it is knocked is let through by the falling bones on both machines; one standing 1.5 m off is not"},
		{"name": "wall_gap", "method": "case_wall_gap", "world": false,
				"title": "coop/12 (coop/10 F70, F71): the knocked Guest's view stops wall_gap short of a wall between the body's middle and its eyes, a physics tick after the wall is there"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_speed = PACE_SPEED
	Engine.time_scale = _speed
	for a: StringName in [&"pick", &"drop_throw", &"jump", &"move_back"]:
		Input.action_release(a)
	_heard.clear()
	PadRumble.reset()
	_drop_branches()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	if spatial:
		_heard.append([sound, at, Engine.get_process_frames()])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	for lag_ms: int in [0, LAG_MS]:
		await _real_path_round(lag_ms)


func _real_path_round(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
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
	print("KNOCK real path %d ms: lies over %.0f (Host) and %.0f (Guest) degrees, feet %.2f m apart" % [lag_ms, _topple(host_rag), _topple(own.ragdoll), gap])
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
	var ls := LevelRuntime.of(late).session
	ls.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(late).net.start(["--join=127.0.0.1:%d" % LevelRuntime.of(host).session.port]) == OK, "a third zoo joins")
	_lag(late, LAG_MS)
	var lk := _kd(late)
	await _wait(func() -> bool: return LevelRuntime.of(late).net.mode_text().begins_with("Joined") and _avatar(late, g) != null, "the late Guest welcomed, with the avatars", FPS * 10)
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
	var hs := LevelRuntime.of(host).session
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


func case_drag_ends() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gp := _player(guest)
	var g := gp.player_id()
	var hk := _kd(host)
	var gk := _kd(guest)
	_whys.clear()
	_parts(guest).applied.connect(_on_guest_applied)
	var whys := _whys
	_place(host, GUEST_AT, GUEST_AT + Vector3(0.0, 1.6, -3.0))
	await _paced_ticks(20)
	# H97: a menu opens on the dragger.
	await _down_and_grabbed(host, guest)
	gp.set_input_blocked(true)
	await _wait(func() -> bool: return not hk.drags.has(Parts.HOST) and not gk.drags.has(Parts.HOST), "H97: a menu on the Guest lets go, on both", FPS * 2)
	gp.set_input_blocked(false)
	gp.set("_grab_held", false)
	await _wait(func() -> bool: return not hk.is_down(Parts.HOST), "the Host stands again", FPS * 8)
	await _paced_ticks(10)
	# H101: the feet left more than break_distance behind (the dragger moved off at once: stuck, a wall).
	await _down_and_grabbed(host, guest)
	await _paced_ticks(20)
	_check(gk.dragger_of(Parts.HOST) == g, "H101: a drag within the break distance holds")
	var rag := _avatar(host, Parts.HOST).ragdoll
	var away := rag.feet() + Vector3(hk.tuning.break_distance + 3.0, 0.0, 0.0)
	_place(guest, away, away + Vector3(3.0, 1.0, 0.0))
	await _wait(func() -> bool: return not hk.drags.has(Parts.HOST) and not gk.drags.has(Parts.HOST), "H101: the feet over 2 m away end the drag, on both", FPS * 2)
	_check(whys.has(Knockdowns.APART), "H101: as apart (%s)" % [whys])
	gp.set("_grab_held", false)
	await _wait(func() -> bool: return not hk.is_down(Parts.HOST), "the Host stands again", FPS * 8)
	await _paced_ticks(10)
	# D37: the dragger is knocked down.
	await _down_and_grabbed(host, guest)
	_knock(host, g, Parts.HOST)
	await _wait(func() -> bool: return gk.is_down(g) and not hk.drags.has(Parts.HOST) and not gk.drags.has(Parts.HOST),
			"D37: a knocked dragger's drag ends, on both", FPS * 2)
	_check(whys.has(Knockdowns.KNOCKED), "D37: as knocked (%s)" % [whys])
	_check(hk.is_down(Parts.HOST), "D37: the body lies where it is")
	gp.set("_grab_held", false)
	_drop_branches()


func case_inside() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	# The soft push (core/41) would part two players 0.25 m apart before the knock; this case is about the
	# falling body, so both stand still where they are put.
	for zoo: Node3D in [host, guest]:
		var stack := _player(zoo).stack()
		stack.tuning = stack.tuning.duplicate() as StackingTuning
		stack.tuning.push_rate = 0.0
	for d: float in [0.25, 1.5]:
		_place(host, GUEST_AT, GUEST_AT + Vector3(0.0, 1.6, -3.0))
		_place(guest, GUEST_AT + Vector3(d, 0.0, 0.0), GUEST_AT + Vector3(d, 1.6, -3.0))
		await _wait(func() -> bool: return _avatar(host, g).global_position.distance_to(GUEST_AT + Vector3(d, 0.0, 0.0)) < 0.05 \
				and _avatar(guest, Parts.HOST).global_position.distance_to(GUEST_AT) < 0.05, "both stand %.2f m apart on both machines" % d, FPS * 2)
		_knock(host, Parts.HOST, g)
		await _wait(func() -> bool: return _kd(guest).is_down(Parts.HOST) and _avatar(guest, Parts.HOST).ragdoll.phase == Ragdoll.Phase.DOWN, "the Host down on both", FPS * 2)
		await _paced_ticks(2)
		for zoo: Node3D in [host, guest]:
			var body := _avatar(zoo, Parts.HOST)
			var mate := _avatar(zoo, g)
			var through := _bones_except(body.ragdoll, mate.mate)
			var where := "on the %s's machine" % zoo.get_parent().get_parent().name
			if d < 1.0:
				_check(through, "E53: the falling body lets the Guest standing inside it through, %s" % where)
			else:
				_check(not through, "E53: a Guest standing %.1f m off is not let through, %s" % [d, where])
		await _wait(func() -> bool: return not _kd(host).is_down(Parts.HOST) and not _kd(guest).is_down(Parts.HOST) \
				and _avatar(guest, Parts.HOST).ragdoll.phase == Ragdoll.Phase.UP, "the Host stands up", FPS * 8)
		await _paced_ticks(10)
	_drop_branches()


func case_wall_gap() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gp := _player(guest)
	var g := gp.player_id()
	_place(guest, GUEST_AT, GUEST_AT + Vector3(0.0, 1.6, -3.0))
	await _paced_ticks(20)
	_knock(host, g, Parts.HOST)
	await _wait(func() -> bool: return gp.knocked, "the Guest down", FPS * 2)
	var rag := _avatar(guest, g).ragdoll
	await _wait(func() -> bool: return _topple(rag) > 40.0, "the Guest's body to lie over", FPS * 3)
	await _paced_ticks(20)
	var t := _kd(guest).tuning
	var middle := rag.point_at(gp.tuning.stand_height * 0.5)
	var eye := rag.point_at(t.eye)
	var free := gp.view().origin.distance_to(middle)
	_check(free > t.wall_gap + 0.1, "F70: with no wall the view rides the head (%.2f m from the middle)" % free)
	# A thin wall across the line from the body's middle to its eyes, a third of the way.
	var wall := StaticBody3D.new()
	wall.collision_layer = Mess.LAYER_HOUSE
	wall.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 0.05)
	shape.shape = box
	wall.add_child(shape)
	guest.add_child(wall)
	var at := middle.lerp(eye, 0.6)
	wall.global_transform = Transform3D(Basis.looking_at((eye - middle).normalized(), Vector3.UP if absf((eye - middle).normalized().y) < 0.9 else Vector3.FORWARD), at)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	middle = rag.point_at(gp.tuning.stand_height * 0.5)
	var to_wall := middle.distance_to(at)
	var now := gp.view().origin.distance_to(middle)
	print("KNOCK wall gap: view %.2f m from the body's middle with no wall; a wall %.2f m off: %.2f m" % [free, to_wall, now])
	_check(now <= to_wall - t.wall_gap + 0.05 and now >= to_wall - t.wall_gap - 0.1,
			"F70, F71: the view stops wall_gap (%.2f) short of the wall within a tick (%.2f m from the middle, wall %.2f m)" % [t.wall_gap, now, to_wall])
	wall.queue_free()
	_drop_branches()


## Why each drag a Guest saw end ended (the answers' "why").
func _on_guest_applied(ev: Dictionary) -> void:
	if ev.has("why"):
		_whys.append(String(ev["why"]))


## The Host knocks itself down (as by the Guest) and the Guest, standing at its feet, grabs it as its
## held button does.
func _down_and_grabbed(host: Node3D, guest: Node3D) -> void:
	var gp := _player(guest)
	var g := gp.player_id()
	_knock(host, Parts.HOST, g)
	await _wait(func() -> bool: return _kd(guest).is_down(Parts.HOST) and _player(host).knocked, "the Host to lie down", FPS * 2)
	await _paced_ticks(70)
	var rag := _avatar(guest, Parts.HOST).ragdoll
	_place(guest, rag.feet() + Vector3(0.8, 0.0, 0.0), rag.feet())
	await _paced_ticks(int(LAG_MS * 3 * FPS / 1000.0) + 4)
	gp.capture_mouse()
	gp.set("_grab_held", true)
	_parts(guest).ask(Command.new(Knockdowns.GRAB, g, _kd(guest).id, {"target": Parts.HOST}))
	await _wait(func() -> bool: return _kd(host).dragger_of(Parts.HOST) == g and _kd(guest).dragger_of(Parts.HOST) == g,
			"the Guest drags the Host", FPS * 2)


## Whether every bone of `rag` has a collision exception with `body`.
func _bones_except(rag: Ragdoll, body: CollisionObject3D) -> bool:
	var bones := rag.find_children("*", "PhysicalBone3D", true, false)
	if bones.is_empty() or body == null:
		return false
	for bone: Node in bones:
		if not (bone as PhysicalBone3D).get_collision_exceptions().has(body):
			return false
	return true


func case_pose_bytes() -> void:
	# bytes a second of wall time: the game clock runs at its own speed here
	_speed = 1.0
	Engine.time_scale = 1.0
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
		var p := _in_branch(other).player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	_place(zoo, feet, target)
	await _paced_ticks(int(LAG_MS * 3 * FPS / 1000.0) + 4)
	_place(zoo, Vector3(feet.x, player.global_position.y, feet.z), target)
	await _paced_ticks(2)
	# The Host judges reach by where it last heard this player stands (LevelNet.where()): a click sent
	# before the pose got there is refused as too far (core/101). Wait until the Host has it here.
	var host_net := LevelRuntime.of(_branches[0].get_node("View/Zoo")).net
	var me := player.player_id()
	await _wait(func() -> bool:
		var at: Variant = host_net.where(me)
		return at is Vector3 and Vector2((at as Vector3).x - feet.x, (at as Vector3).z - feet.z).length() < 0.1,
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
	_pace_next += int(1000000 / (FPS * _speed))
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _spot_sock(zoo: Node3D, spot: String) -> int:
	return (zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _kd(zoo: Node3D) -> Knockdowns:
	return LevelRuntime.of(zoo).knockdowns


func _mess(zoo: Node3D) -> Mess:
	return LevelRuntime.of(zoo).mess


func _hands(zoo: Node3D) -> Hands:
	return LevelRuntime.of(zoo).hands


func _parts(zoo: Node3D) -> Parts:
	return LevelRuntime.of(zoo).parts


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
