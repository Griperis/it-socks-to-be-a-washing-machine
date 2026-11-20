## The Hands' small motions (core/09): a Sock's cloth (D01-D07), the glide on switching (D08), the
## pick fly-up (D09) and the pairing moment's fly-in (D10), one case per line, and the real path.
## The shelving flight and the drawer's slide (D11, D12) are in cabinet_test.gd, beside the Cabinet.
## Every case plays the station scene game/zoo/stations/handling.tscn on a floor, with the game's
## player and a Parts (a Host of one), as the zoo does. A bend is read as the skeleton draws it
## (after its modifiers, in skeleton_updated): reading a bone from outside gives the unbent pose.
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"turn", &"move_forward", &"hands_next", &"hands_prev"]
## The station's Socks, by id (the order of its SockSpots).
const ON_FLOOR := 0
const UNDER := 1
const OVER := 2
const MATE_FLOOR := 6
const SOCKS := 8
## Where the player stands for most cases: in front of the Socks on the floor, facing -Z.
const FRONT := Vector3(0.0, 0.0, 1.5)
## The Sock Looks' skeleton and the bones its cloth bends.
const SKELETON := ^"Body/sock_crew/crew_rig/Skeleton3D"
const CLOTH := ^"Body/sock_crew/crew_rig/Skeleton3D/Cloth"
const BONES: Array[int] = [1, 2, 3, 4]
const TOE := 4

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
## Each watched Looks' bend (how far its Toe is from its rest place, in the skeleton's space) and the
## lowest of its chain's joints in the level, as last drawn, by the Looks' instance id.
var _bends: Dictionary[int, float] = {}
var _lows: Dictionary[int, float] = {}


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player picks a Sock, walks, turns and throws it with the real actions; it bends held and flying and lies flat at rest"},
		{"name": "d01_droop", "method": "case_d01", "world": false,
				"title": "D01: a held Sock droops from its cuff and settles, fully damped (it never swings past)"},
		{"name": "d02_walk", "method": "case_d02", "world": false,
				"title": "D02: walking with a Sock held bends it; standing again it settles back"},
		{"name": "d03_turn", "method": "case_d03", "world": false,
				"title": "D03: turning the view, or the item with R, drags the Sock against the turn"},
		{"name": "d04_lies_flat", "method": "case_d04", "world": false,
				"title": "D04: a thrown Sock flops as it flies and lies flat as it slows under 0.6 m/s, so nothing pops at rest"},
		{"name": "d05_ground", "method": "case_d05", "world": false,
				"title": "D05: a flying or settling Sock's chain never dips below the surface it lands on"},
		{"name": "d06_pair_rigid", "method": "case_d06", "world": false,
				"title": "D06: a Pair's sock ball has no cloth"},
		{"name": "d07_cap", "method": "case_d07", "world": false,
				"title": "D07: cloth runs for the held Socks and the 4 nearest flying ones; the others fly rigid, and lying Socks are rigid"},
		{"name": "d08_glide", "method": "case_d08", "world": false,
				"title": "D08: when the active item changes the held items glide to their new places instead of jumping"},
		{"name": "d09_fly_up", "method": "case_d09", "world": false,
				"title": "D09: a picked Sock flies from where it lay into its place in 0.3 s on a small hop"},
		{"name": "d10_fly_in", "method": "case_d10", "world": false,
				"title": "D10: the pairing moment's second Sock flies in from where it lay"},
		{"name": "f1_throw_from_hand", "method": "case_f1_throw", "world": false,
				"title": "core/19 F1: a Sock thrown with the real button is drawn leaving from where it hung in the hand and joins its body (which flies from the eyes) over catch_up 0.1 s"},
		{"name": "f1_drop_from_hand", "method": "case_f1_drop", "world": false,
				"title": "core/19 F1: a dropped Sock is drawn leaving from the hand too: it flicks to its spot before its body falls"},
		{"name": "f2_ring_round_ball", "method": "case_f2_ring", "world": false,
				"title": "core/19 F2: the pairing moment's ring and sparkles keep its scale: the ring grows round the ball, at the ball's size, not round the view"},
		{"name": "f3_sign_clear", "method": "case_f3_sign", "world": false,
				"title": "core/19 F3: standing on the handling station's pad, its sign does not cover the view's centre"},
		{"name": "looks_cloth", "method": "case_looks", "world": false,
				"title": "the Sock's Looks has its Cloth on the skeleton, from the leg to the toe"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_bends.clear()
	_lows.clear()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var view := _player.held_view()
	var held := view.looks_of(ON_FLOOR)
	_watch(held)
	await _until(view.settled, "the fly-up to end")
	await _physics_ticks(40)
	var still := _bend(held)
	_check(still > 0.002, "held, it droops (%.4f)" % still)
	Input.action_press(&"move_forward")
	var walked := 0.0
	for i in 30:
		await _physics_ticks(1)
		walked = maxf(walked, absf(_bend(held) - still))
	Input.action_release(&"move_forward")
	_check(walked > 0.003, "walking bends it (%.4f)" % walked)
	var turned := 0.0
	for i in 20:
		_player.rotation.y += 0.07
		await _physics_ticks(1)
		turned = maxf(turned, absf(_bend(held) - still))
	_check(turned > 0.003, "turning bends it (%.4f)" % turned)
	await _physics_ticks(60)
	_near(_bend(held), still, 0.002, "standing still it settles back")
	await _aim(_player, _player.global_position + Vector3(0.0, 1.6, -3.0))
	await _throw_full()
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the thrown Sock to fly")
	var flight := _mess.flight_of(ON_FLOOR)
	var looks := flight.get_node(^"Looks") as Node3D
	_watch(looks)
	var cloth := looks.get_node(CLOTH) as SockCloth
	var flopped := 0.0
	var last := 1.0
	var last_influence := 1.0
	for i in 600:
		await _physics_ticks(1)
		if _mess.state_of(ON_FLOOR) != Mess.State.FLYING or not is_instance_valid(looks):
			break
		flopped = maxf(flopped, _bend(looks))
		last = _bend(looks)
		last_influence = cloth.influence
	_check(flopped > 0.003, "it flops as it flies (%.4f)" % flopped)
	_check(_mess.state_of(ON_FLOOR) == Mess.State.LYING, "it comes to rest")
	_near(last, 0.0, 0.001, "its last drawn pose in the air is flat")
	_near(last_influence, 0.0, 0.05, "its bend is blended out")


# --- Cloth ---------------------------------------------------------------------------------------

func case_d01() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var view := _player.held_view()
	var held := view.looks_of(ON_FLOOR)
	_watch(held)
	var cloth := held.get_node(CLOTH) as SockCloth
	_check(cloth.role == SockCloth.Role.HELD and cloth.ranked, "a held Sock's cloth is on")
	_near(cloth.get_drag(0), 1.0, 0.0001, "fully damped: each tick's swing is thrown away")
	await _until(view.settled, "the fly-up to end")
	await _physics_ticks(30)
	var a := _bend(held)
	await _physics_ticks(10)
	var b := _bend(held)
	_check(b > 0.002, "it droops from its cuff (%.4f)" % b)
	_near(a, b, 0.0005, "and has settled within half a second")


func case_d02() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var view := _player.held_view()
	var held := view.looks_of(ON_FLOOR)
	_watch(held)
	await _until(view.settled, "the fly-up to end")
	await _physics_ticks(40)
	var still := _bend(held)
	Input.action_press(&"move_forward")
	await _physics_ticks(20)
	var walking := _bend(held)
	Input.action_release(&"move_forward")
	_check(absf(walking - still) > 0.003, "walking, it lags behind the move (%.4f against %.4f)" % [walking, still])
	await _physics_ticks(60)
	_near(_bend(held), still, 0.002, "stopped, it settles again")


func case_d03() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var view := _player.held_view()
	var held := view.looks_of(ON_FLOOR)
	_watch(held)
	await _until(view.settled, "the fly-up to end")
	await _physics_ticks(40)
	var still := _bend(held)
	var most := 0.0
	for i in 15:
		_player.rotation.y += 0.07
		await _physics_ticks(1)
		most = maxf(most, absf(_bend(held) - still))
	_check(most > 0.003, "turning the view drags it (%.4f)" % most)
	await _physics_ticks(60)
	_near(_bend(held), still, 0.002, "the turn over, it settles")
	Input.action_press(&"turn")
	most = 0.0
	for i in 20:
		await _physics_ticks(1)
		most = maxf(most, absf(_bend(held) - still))
	Input.action_release(&"turn")
	_check(most > 0.003, "turning the item with R drags it (%.4f)" % most)


func case_d04() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, _player.global_position + Vector3(0.0, 1.6, -3.0))
	await _throw_full()
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the thrown Sock to fly")
	var body := _mess.flight_of(ON_FLOOR)
	var looks := body.get_node(^"Looks") as Node3D
	var cloth := looks.get_node(CLOTH) as SockCloth
	_watch(looks)
	_check(cloth.role == SockCloth.Role.FLYING, "a thrown Sock's cloth flies")
	var bent_fast := false
	var flat_slow := true
	var last := 1.0
	for i in 600:
		await _physics_ticks(1)
		if _mess.state_of(ON_FLOOR) != Mess.State.FLYING or not is_instance_valid(body):
			break
		var fast := cloth.speed >= cloth.tuning.flat_speed
		bent_fast = bent_fast or (fast and cloth.influence > 0.5 and _bend(looks) > 0.003)
		# Slow for longer than the blend, it is flat.
		if not fast and cloth.influence > 0.0:
			flat_slow = flat_slow and cloth.influence < 1.0
		last = _bend(looks)
	_check(bent_fast, "fast, it flops")
	_check(flat_slow, "slow, its bend blends out")
	_near(last, 0.0, 0.001, "it reaches the floor flat (%.4f)" % last)
	await _physics_ticks(2)
	var lying := _mess.looks_of(ON_FLOOR)
	_check(lying != null and not (lying.get_node(CLOTH) as SockCloth).active, "lying, it is the Mess's rigid flat Sock")


func case_d05() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, _player.global_position + Vector3(0.0, 1.0, -2.0))
	await _throw_full()
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the thrown Sock to fly")
	var body := _mess.flight_of(ON_FLOOR)
	var looks := body.get_node(^"Looks") as Node3D
	_watch(looks)
	var lowest := INF
	for i in 600:
		await _physics_ticks(1)
		if _mess.state_of(ON_FLOOR) != Mess.State.FLYING or not is_instance_valid(body):
			break
		lowest = minf(lowest, _lows.get(looks.get_instance_id(), INF))
	_check(lowest > -0.003, "no joint of its chain dips below the floor (lowest %.4f m)" % lowest)



func case_d06() -> void:
	await _build()
	var ball := SockDress.make(_mess.design_of(ON_FLOOR), SockDress.HELD, true)
	add_child(ball)
	_check(ball.find_children("*", "SpringBoneSimulator3D", true, false).is_empty(), "the sock ball has no cloth")
	ball.free()


func case_d07() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var flights: Array[RigidBody3D] = []
	for i in 6:
		var body := Mess.FLIGHT_SCENE.instantiate() as RigidBody3D
		body.name = "Probe%d" % i
		body.gravity_scale = 0.0
		var looks := SockDress.make(null)
		looks.name = "Looks"
		body.add_child(looks)
		_level.add_child(body)
		body.global_position = _player.global_position + Vector3(0.0, 1.0, -1.0 - float(i))
		flights.append(body)
	await _physics_ticks(3)
	var on: Array[int] = []
	for i in flights.size():
		if ((flights[i].get_node(^"Looks") as Node3D).get_node(CLOTH) as SockCloth).active:
			on.append(i)
	_check(on == [0, 1, 2, 3], "the 4 nearest of 6 flying Socks bend (%s)" % [on])
	var held := (_player.held_view().looks_of(ON_FLOOR).get_node(CLOTH) as SockCloth)
	_check(held.active, "the held one bends too")
	var lying := (_mess.looks_of(OVER).get_node(CLOTH) as SockCloth)
	_check(lying.role == SockCloth.Role.RIGID and not lying.active and not lying.is_physics_processing(), "a lying Sock is rigid and costs nothing")
	flights[0].global_position += Vector3(0.0, 0.0, -20.0)
	await _physics_ticks(2)
	_check(not ((flights[0].get_node(^"Looks") as Node3D).get_node(CLOTH) as SockCloth).active
			and ((flights[4].get_node(^"Looks") as Node3D).get_node(CLOTH) as SockCloth).active, "one flying off makes room for the next nearest")


# --- Switching and picking -----------------------------------------------------------------------

func case_d08() -> void:
	await _build()
	_capacity(3)
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	await _pick(OVER)
	var view := _player.held_view()
	await _until(view.settled, "the fly-up to end")
	var looks := view.looks_of(OVER)
	var before := looks.position
	await _wheel(&"hands_next")
	var goal := view.target(1, _hands.active_index(1), OVER).origin
	var now := looks.position
	_check(now.distance_to(before) > 0.0005 and now.distance_to(goal) > 0.005, "a frame later it is on its way, not there (%.3f from its new place)" % now.distance_to(goal))
	await _until(view.settled, "the glide to end", 120)
	_near(looks.position.distance_to(view.target(1, _hands.active_index(1), OVER).origin), 0.0, 0.001, "then it is at its new place")


func case_d09() -> void:
	await _build()
	var lay := _mess.pose_of(ON_FLOOR).origin
	await _aim(_player, _centre(ON_FLOOR))
	Input.action_press(&"pick")
	var view := _player.held_view()
	await _until(func() -> bool: return view.looks_of(ON_FLOOR) != null, "the picked Sock to show in the Hands")
	Input.action_release(&"pick")
	var looks := view.looks_of(ON_FLOOR)
	_check(view.flying_up(ON_FLOOR), "it flies up")
	_check(looks.global_position.distance_to(lay) < 0.15, "from where it lay (%.3f m off)" % looks.global_position.distance_to(lay))
	var start := looks.global_position
	await _frames(9)
	var mid := looks.global_position
	var u := 9.0 / 60.0 / _player.hands_tuning.pick_time
	var goal := view.global_transform * view.target(0, 0, ON_FLOOR).origin
	var line := start.lerp(goal, smoothstep(0.0, 1.0, u))
	_check(mid.y > line.y + 0.05, "on a hop above the straight line (%.3f m)" % (mid.y - line.y))
	await _until(func() -> bool: return not view.flying_up(ON_FLOOR), "the fly to end", int(0.3 * 60.0) + 3)
	await _frames(1)
	_near(looks.position.distance_to(view.target(0, 0, ON_FLOOR).origin), 0.0, 0.001, "in 0.3 s it is in its place")


func case_d10() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	var lay := _mess.pose_of(MATE_FLOOR).origin
	await _pick(MATE_FLOOR)
	var view := _player.held_view()
	await _until(func() -> bool: return view.moment_of(ON_FLOOR) != null, "the pairing moment to start")
	var moment := view.moment_of(ON_FLOOR)
	var mate := moment.get_node(^"Mate/FlyIn/Looks") as Node3D
	_check(mate.global_position.distance_to(lay) < 0.25, "the second Sock starts where it lay (%.3f m off)" % mate.global_position.distance_to(lay))
	var anim := moment.get_node(^"AnimationPlayer") as AnimationPlayer
	await _until(func() -> bool: return anim.current_animation_position >= HeldView.FLY_IN_END, "the fly-in to end", 120)
	await _frames(1)
	_check((moment.get_node(^"Mate/FlyIn") as Node3D).transform.is_equal_approx(Transform3D.IDENTITY), "then it is in its line-up place")


# --- core/19: batch 1 fixes ----------------------------------------------------------------------

func case_f1_throw() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var view := _player.held_view()
	await _until(view.settled, "the fly-up to end")
	await _aim(_player, _player.global_position + Vector3(0.0, 1.6, -3.0))
	await _frames(2)
	var held := view.looks_of(ON_FLOOR)
	var cam := _player.camera()
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	var hand := held.global_transform
	var hand_px := cam.unproject_position(hand.origin)
	# What is drawn, each frame (read as the next frame starts, after every _process): where on screen, how big.
	var drawn: Array[Array] = []
	var held_id := held.get_instance_id()
	var record := func() -> void:
		var looks := instance_from_id(held_id) as Node3D
		if looks != null and view.catching_up(ON_FLOOR):
			drawn.append([cam.unproject_position(looks.global_position), looks.global_transform.basis.get_scale().x,
					view.catch_up_offset(ON_FLOOR)])
	get_tree().process_frame.connect(record)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return not drawn.is_empty(), "the throw's catch-up to be drawn", 10)
	var body_looks := _mess.flight_of(ON_FLOOR).get_node(^"Looks") as Node3D
	_check(is_instance_valid(held) and held.visible, "the Looks that hung in the hand is still what is drawn")
	if not drawn.is_empty():
		var first_px: Vector2 = drawn[0][0]
		_check(first_px.distance_to(hand_px) < 40.0,
				"its first frame is at the hand on screen (%.0f px from it), not at the eyes" % first_px.distance_to(hand_px))
		_check(float(drawn[0][1]) < hand.basis.get_scale().x * 1.5, "and about its size in the hand (%.2f, held %.2f)" % [drawn[0][1], hand.basis.get_scale().x])
	_check(not body_looks.visible, "the body's own Looks is hidden while it catches up")
	await _until(func() -> bool: return not view.catching_up(ON_FLOOR), "the catch-up to end", 30)
	get_tree().process_frame.disconnect(record)
	_check(drawn.size() >= 3, "the catch-up is drawn over several frames (%d)" % drawn.size())
	if drawn.size() >= 2:
		var gap: float = drawn[-1][2]
		_check(float(drawn[0][2]) > 0.05 and gap < float(drawn[0][2]) * 0.1,
				"it starts off its body and on its last frame has nearly joined it (%.3f m off, from %.3f)" % [gap, drawn[0][2]])
	await _frames(1)
	_check(body_looks.visible, "then the body's Looks is drawn")
	_check(not is_instance_valid(held) or held.is_queued_for_deletion(), "and the hand's Looks is gone")


func case_f1_drop() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var view := _player.held_view()
	await _until(view.settled, "the fly-up to end")
	await _aim(_player, _player.global_position + Vector3(0.0, 0.0, -1.0))
	var held := view.looks_of(ON_FLOOR)
	var hand := held.global_position
	var drawn: Array[Vector3] = []
	var held_id := held.get_instance_id()
	var record := func() -> void:
		var looks := instance_from_id(held_id) as Node3D
		if looks != null and _hands.items_of(1).is_empty() and _mess.flight_of(ON_FLOOR) == null:
			drawn.append(looks.global_position)
	get_tree().process_frame.connect(record)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null or _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the body to fall", 60)
	get_tree().process_frame.disconnect(record)
	_check(drawn.size() >= 3, "the dropped Sock is drawn from the hand over several frames before its body falls (%d)" % drawn.size())
	if not drawn.is_empty():
		_check(drawn[0].distance_to(hand) < 0.1, "its first frame is near the hand (%.3f m off)" % drawn[0].distance_to(hand))
	_check(not view.catching_up(ON_FLOOR), "a drop flicks: no catch-up")


func case_f2_ring() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _physics_ticks(25)
	await _pick(MATE_FLOOR)
	var view := _player.held_view()
	await _until(func() -> bool: return view.moment_of(ON_FLOOR) != null, "the pairing moment to start")
	var moment := view.moment_of(ON_FLOOR)
	var ring := moment.get_node(^"Ring") as MeshInstance3D
	var ball := moment.get_node(^"Ball") as Node3D
	var burst := moment.get_node(^"Burst") as GPUParticles3D
	_check((ring.material_override as StandardMaterial3D).billboard_keep_scale, "the ring's billboard keeps its scale (else it is drawn at 0.6 m round the view)")
	_check(((burst.draw_pass_1 as QuadMesh).material as StandardMaterial3D).billboard_keep_scale, "and so do the sparkles")
	await _until(func() -> bool: return ring.visible, "the ring to show", 120)
	var cam := _player.camera()
	var size := cam.get_viewport().get_visible_rect().size
	var widest := 0.0
	var off := 0.0
	while is_instance_valid(ring) and ring.visible:
		var centre := cam.unproject_position(ring.global_position)
		var radius := (ring.mesh as QuadMesh).size.x * 0.5 * ring.global_transform.basis.get_scale().x
		var rim := cam.unproject_position(ring.global_position + cam.global_basis.x * radius)
		widest = maxf(widest, rim.distance_to(centre))
		off = maxf(off, centre.distance_to(cam.unproject_position(ball.global_position)))
		await _frames(1)
	_check(off < 2.0, "the ring's centre stays on the ball (%.1f px off at most)" % off)
	_check(widest * 2.0 < size.y * 0.4, "it grows round the ball only: %.0f px across at most, of a %.0f px view" % [widest * 2.0, size.y])
	_check(widest > 20.0, "and it is seen (%.0f px across)" % (widest * 2.0))


func case_f3_sign() -> void:
	await _build()
	var sign := _station.get_node(^"Name") as Label3D
	var cam := _player.camera()
	for at: Vector3 in [FRONT, Vector3.ZERO, Vector3(1.5, 0.0, 1.5)]:
		_player.global_position = _station.to_global(at)
		_player.rotation.y = 0.0
		(_player.get_node(^"Head") as Node3D).rotation.x = 0.0
		_player.reset_physics_interpolation()
		await _physics_ticks(3)
		await _frames(1)
		var size := cam.get_viewport().get_visible_rect().size
		# A billboard's AABB is a cube that covers every turn: the text's own box, from its font.
		var font := sign.font if sign.font != null else ThemeDB.fallback_font
		var text := font.get_multiline_string_size(sign.text, sign.horizontal_alignment, sign.width, sign.font_size,
				-1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE) * sign.pixel_size
		var right := cam.global_basis.x * sign.width * sign.pixel_size * 0.5
		var up := cam.global_basis.y * text.y * 0.5
		var mid := sign.global_position
		var rect := Rect2(cam.unproject_position(mid - right + up), Vector2.ZERO)
		for corner: Vector3 in [mid + right + up, mid - right - up, mid + right - up]:
			rect = rect.expand(cam.unproject_position(corner))
		_check(not rect.has_point(size * 0.5), "from %s on the pad the sign (%s) does not cover the view's centre" % [at, rect])
		_check(text.y > 0.05 and rect.size.y < size.y * 0.25, "and it is a short band, not a tall block (%.0f of %.0f px high)" % [rect.size.y, size.y])
	_check(sign.text.begins_with("Handling Socks"), "the sign keeps its words")


func case_looks() -> void:
	var looks := SockDress.make(null)
	add_child(looks)
	var cloth := looks.get_node_or_null(CLOTH) as SockCloth
	_check(cloth != null, "the Looks has its Cloth under the skeleton")
	if cloth != null:
		var skeleton := looks.get_node(SKELETON) as Skeleton3D
		_check(skeleton.get_bone_name(cloth.get_root_bone(0)) == "Leg" and skeleton.get_bone_name(cloth.get_end_bone(0)) == "Toe",
				"its chain runs from the leg to the toe")
		_check(cloth.get_node_or_null(^"Ground") is SpringBoneCollisionPlane3D, "with its Ground plane")
		_check(cloth.role == SockCloth.Role.RIGID and not cloth.active, "a Looks on its own is rigid")
	looks.free()


# --- Helpers -------------------------------------------------------------------------------------

## A floor, the station, a Parts and the player standing at FRONT facing -Z.
func _build() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = FRONT
	_level.add_child(_player)
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


## Reads `looks`' bend and its chain's lowest point each time its skeleton is drawn.
func _watch(looks: Node3D) -> void:
	var skeleton := looks.get_node(SKELETON) as Skeleton3D
	var key := looks.get_instance_id()
	skeleton.skeleton_updated.connect(func() -> void:
		_bends[key] = skeleton.get_bone_global_pose(TOE).origin.distance_to(skeleton.get_bone_global_rest(TOE).origin)
		var low := INF
		for bone in BONES:
			var pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
			low = minf(low, pose.origin.y)
		_lows[key] = low)


## `looks`' bend as last drawn (0 before it is drawn).
func _bend(looks: Node3D) -> float:
	return _bends.get(looks.get_instance_id(), 0.0)


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Presses an action for two physics ticks, then lets it go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## A wheel step through the viewport, as the mouse wheel's event comes.
func _wheel(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	await _physics_ticks(2)


## Holds the drop button until the ring is full, then lets it go: the Sock flies.
func _throw_full() -> void:
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _hands.items_of(1).is_empty(), "the Sock to leave the Hands", 5)


## Aims at Sock `sock` and picks it with the real action.
func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d to be picked" % sock)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


## The middle of a lying Sock.
func _centre(sock: int) -> Vector3:
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
