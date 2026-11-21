## Pairing (core/03): two Socks of one Design become one Pair in the Hands that picked the second.
## One case per line of the approved behaviour list (P01-P03, P05-P08, H12), the never-split rule,
## the invariants I.1 and I.4, the refusals and the real path. Every case plays the station scene
## game/zoo/stations/handling.tscn on a floor, with the game's player and a Parts (a Host of one),
## as the zoo does.
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"hands_next", &"hands_prev", &"move_forward"]
## The station's Socks, by id (the order of its SockSpots): two pairs of mates and singles.
const ON_FLOOR := 0
const UNDER := 1
const OVER := 2
const ON_TABLE := 3
const MATE_FLOOR := 6
const MATE_UNDER := 7
## Where the player stands for most cases: in front of the Socks on the floor, facing -Z.
const FRONT := Vector3(0.0, 0.0, 1.5)
const SOCKS := 8

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
## Each Design's record count when the case began (I.1: it never changes).
var _design_counts := {}


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the station the real actions pick a Sock, pick its mate, see one Pair in the Hands, drop it and pick it again"},
		{"name": "p01_fuse", "method": "case_p01", "world": false,
				"title": "P01: picking the mate of a held Sock fuses the two at once into one Pair in the Hands, the active item, in one place"},
		{"name": "p02_full_mate", "method": "case_p02", "world": false,
				"title": "P02: with the Hands otherwise full the mate still fuses, with no \"Hands full\"; another Sock is still refused \"full\""},
		{"name": "p03_not_mate", "method": "case_p03", "world": false,
				"title": "P03: a Sock of another Design never fuses; a held Pair never takes a third Sock"},
		{"name": "never_split", "method": "case_never_split", "world": false,
				"title": "a held Pair is never split: cycled, dropped, thrown and picked again it stays one Pair"},
		{"name": "p05_moment", "method": "case_p05", "world": false,
				"title": "P05: a pairing plays the moment once (fly, fold, roll, the ball pops at 0.5 s with the burst and ring in the Collection's colour); a whole Pair picked plays none; a drop ends it"},
		{"name": "p06_held_ball", "method": "case_p06", "world": false,
				"title": "P06: a held Pair is drawn as one sock ball, tinted as its Sock, 1.6 times a Sock's size"},
		{"name": "p07_floor", "method": "case_p07", "world": false,
				"title": "P07: a dropped Pair falls as a ball that drags 2.5 / 8, lies where it lands and is pickable once settled; a Sock dropped on it rests on or beside it, never inside"},
		{"name": "h12_floor_pair", "method": "case_h12", "world": false,
				"title": "H12: a click on a lying Pair takes it back as a Pair with a free place, else it stays and \"Hands full\" shows"},
		{"name": "p08_falls", "method": "case_p08", "world": false,
				"title": "P08: when the Sock under a lying Pair is picked the Pair falls and lands on the floor"},
		{"name": "p08_beside", "method": "case_p08_beside", "world": false,
				"title": "P08: a Pair lying beside a picked Sock stays where it is"},
		{"name": "r01_free_mouse", "method": "case_r01", "world": false,
				"title": "R01: the click that captures the mouse does nothing else; with the mouse free, clicks, the drop button, zoom and the wheel do nothing"},
		{"name": "r02_nearer", "method": "case_r02", "world": false,
				"title": "R02: with a lying Sock and a lying Pair both under the crosshair the nearer is aimed, the ball's surface against the Sock's middle"},
		{"name": "r03_moving_pick", "method": "case_r03", "world": false,
				"title": "R03: a moving Sock can be aimed and picked mid-air or mid-slide"},
		{"name": "r03_thrown", "method": "case_r03_thrown", "world": false,
				"title": "R03: a Sock thrown by the player can be caught by a click while it is in the air"},
		{"name": "r05_drop_on_pair", "method": "case_r05", "world": false,
				"title": "R05: a drop onto a lying Pair's ball or a Sock is allowed anywhere on it, with no slope test"},
		{"name": "invariants", "method": "case_invariants", "world": false,
				"title": "I.1, I.4 and the Commands: two records per Design, Pairs only in one player's Hands, the Host's answer decides, a Sock in a Pair is refused \"gone\", a Pair survives a save"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	await _aim(_player, _centre(ON_FLOOR))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == ON_FLOOR, "the first Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(MATE_FLOOR))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(ON_FLOOR), "the mate to fuse")
	_check(_hands.items_of(1) == PackedInt32Array([ON_FLOOR]), "one Pair in the Hands (%s)" % _hands.items_of(1))
	_check(_player.message() == "", "no refusal shows")
	await _frames(2)
	_check(_is_ball(_player.held_view().looks_of(ON_FLOOR)), "the Hands show one sock ball")
	_places("after the pairing")
	var spot := Vector3(0.3, 0.0, 0.4)
	await _aim(_player, spot)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the Pair to come to rest")
	_check(_is_ball(_mess.looks_of(ON_FLOOR)), "it lies as a sock ball")
	_places("after the drop")
	await _physics_ticks(25)
	await _aim(_player, _mess.pose_of(ON_FLOOR).origin)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == ON_FLOOR, "the Pair to be in the Hands again")
	_check(_mess.is_pair(ON_FLOOR) and _mess.mate_of(ON_FLOOR) == MATE_FLOOR, "still the same Pair")
	_places("after the second pick")


# --- Forming a Pair ------------------------------------------------------------------------------

func case_p01() -> void:
	await _build()
	_capacity(3)
	await _pick(ON_FLOOR)
	await _repick(OVER)
	_check(_hands.active_of(1) == OVER, "the newest Sock is active")
	await _repick(MATE_FLOOR)
	_check(_hands.items_of(1) == PackedInt32Array([OVER, ON_FLOOR]), "R04: the Pair goes to the end, the mate takes no place of its own (%s)" % _hands.items_of(1))
	_check(_hands.active_of(1) == ON_FLOOR and _hands.active_index(1) == 1, "the Pair is the active item, the last")
	_check(_mess.mate_of(ON_FLOOR) == MATE_FLOOR and _mess.mate_of(MATE_FLOOR) == ON_FLOOR, "the two name each other")
	_check(_mess.state_of(MATE_FLOOR) == Mess.State.IN_PAIR and _mess.state_of(ON_FLOOR) == Mess.State.HELD, "the picked one is in the Pair, the held one leads it")
	_check(_mess.looks_of(MATE_FLOOR) == null, "the mate no longer lies on the floor")
	_places("after the fuse")


func case_p02() -> void:
	await _build()
	_check(_player.hands_tuning.capacity == 1, "the Hands hold one item")
	await _pick(ON_FLOOR)
	_check(_hands.pick_refusal(1, MATE_FLOOR) != Hands.FULL, "the mate is never refused \"full\"")
	await _repick(MATE_FLOOR)
	_check(_mess.is_pair(ON_FLOOR) and _hands.items_of(1).size() == 1, "full Hands still fuse the mate")
	_check(_player.message() == "", "\"Hands full\" never shows for a mate (%s)" % _player.message())
	await _physics_ticks(25)
	await _aim(_player, _centre(OVER))
	await _press(&"pick")
	_check(_mess.state_of(OVER) == Mess.State.LYING, "another Sock stays")
	_check(_player.message() == Player.HANDS_FULL, "and \"Hands full\" shows (%s)" % _player.message())
	_places("after the refused pick")


func case_p03() -> void:
	await _build()
	_capacity(3)
	# A third Sock of the Pair's Design (a stray, never in a real level) shows a held Pair takes none.
	var stray := SOCKS
	var poses := _mess.poses.duplicate()
	poses.append_array(Mess.pack(Transform3D(Basis.IDENTITY, Vector3(0.3, 0.0, 0.5))))
	var states := _mess.states.duplicate()
	states.append(Mess.State.LYING)
	var designs := _mess.designs.duplicate()
	designs.append(_mess.designs[ON_FLOOR])
	var mates := _mess.mates.duplicate()
	mates.append(-1)
	_mess.write({"designs": designs, "states": states, "poses": poses, "mates": mates}, true)
	_design_counts = _counts()
	await _physics_ticks(2)
	await _pick(ON_FLOOR)
	await _repick(MATE_UNDER)
	_check(_mess.mate_of(ON_FLOOR) == -1 and _mess.mate_of(MATE_UNDER) == -1, "a Sock of another Design never fuses")
	_check(_hands.items_of(1).size() == 2, "it takes its own place")
	await _repick(MATE_FLOOR)
	_check(_mess.is_pair(ON_FLOOR), "the mate fuses")
	await _repick(stray)
	_check(_mess.mate_of(stray) == -1 and _mess.mate_of(ON_FLOOR) == MATE_FLOOR, "a held Pair never takes a third Sock of its Design")
	_check(_hands.items_of(1) == PackedInt32Array([MATE_UNDER, ON_FLOOR, stray]), "the third is held loose (%s)" % _hands.items_of(1))
	_places("after a third Sock", SOCKS + 1)


func case_never_split() -> void:
	await _build()
	_capacity(3)
	await _pair()
	await _repick(OVER)
	await _wheel(&"hands_next")
	_check(_hands.active_of(1) == ON_FLOOR and _mess.is_pair(ON_FLOOR), "cycled to, it is still one Pair")
	var verbs := PackedStringArray()
	for verb: StringName in _hands.accepts():
		verbs.append(String(verb))
	verbs.sort()
	_same(verbs, PackedStringArray(["cycle", "drop", "pick", "throw"]), "no Command splits a Pair")
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return not _hands.items_of(1).has(ON_FLOOR), "the Pair to be thrown", 10)
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the thrown Pair to come to rest")
	_check(_mess.is_pair(ON_FLOOR) and _mess.state_of(MATE_FLOOR) == Mess.State.IN_PAIR, "thrown, it lands as one Pair")
	_check(_is_ball(_mess.looks_of(ON_FLOOR)), "drawn as a ball")
	_places("after the throw")


# --- How it looks --------------------------------------------------------------------------------

func case_p05() -> void:
	await _build()
	var view := _player.held_view()
	await _pick(ON_FLOOR)
	_check(view.moments_played == 0, "a loose Sock picked plays no moment")
	await _repick(MATE_FLOOR)
	await _frames(1)
	var moment := view.moment_of(ON_FLOOR)
	_check(moment != null and view.moments_played == 1, "the pairing starts the moment once")
	if moment == null:
		return
	_check(not view.looks_of(ON_FLOOR).visible, "the held ball is hidden under the moment")
	_near(moment.transform.origin.distance_to(view.looks_of(ON_FLOOR).transform.origin), 0.0, 0.0001, "it plays at the Pair's place")
	var colour := _mess.catalogue.collection_colour(_mess.design_of(ON_FLOOR).collection)
	var burst := moment.get_node("Burst") as GPUParticles3D
	_check((burst.process_material as ParticleProcessMaterial).color == colour, "the burst is in the Collection's colour")
	_check(((moment.get_node("Ring") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color.r == colour.r, "and so is the ring")
	var anim := moment.get_node("AnimationPlayer") as AnimationPlayer
	var mate := moment.get_node("Mate") as Node3D
	var fly_in := moment.get_node("Mate/FlyIn") as Node3D
	_check(anim.current_animation == HeldView.PAIR, "its AnimationPlayer plays \"pair\"")
	_check((moment.get_node("Ball") as Node3D).visible == false and mate.visible, "first the two Socks show, no ball")
	_check(not fly_in.transform.is_equal_approx(Transform3D.IDENTITY), "the picked Sock starts away from its line-up place")
	await _until(func() -> bool: return anim.current_animation_position >= 0.2, "the fly to end", 120)
	await _frames(1)
	_check(fly_in.transform.is_equal_approx(Transform3D.IDENTITY), "the picked Sock has flown in")
	await _until(func() -> bool: return anim.current_animation_position >= HeldView.PAIR_TIME, "the roll to end", 120)
	var ball := moment.get_node("Ball") as Node3D
	_check(ball.visible and not mate.visible, "the Socks rolled into the ball")
	_near(ball.scale.x, 1.0, 0.1, "at 0.5 s the ball has popped and settled to its size")
	_check(burst.emitting or burst.one_shot, "the burst went off")
	await _until(func() -> bool: return view.moment_of(ON_FLOOR) == null, "the moment to end", 120)
	_check(view.looks_of(ON_FLOOR).visible, "then the held ball shows")
	await _drop_at(Vector3(0.3, 0.0, 0.4), ON_FLOOR, "the floor")
	await _repick(ON_FLOOR)
	await _frames(2)
	_check(view.moments_played == 1 and view.moment_of(ON_FLOOR) == null, "a whole Pair picked plays none")
	await _drop_at(Vector3(0.3, 0.0, 0.4), ON_FLOOR, "the floor")
	await _repick(MATE_UNDER)
	await _physics_ticks(25)
	await _aim(_player, Vector3(0.45, 0.016, 0.0))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(MATE_UNDER), "the second pair of mates to fuse")
	await _frames(1)
	_check(view.moment_of(MATE_UNDER) != null and view.moments_played == 2, "a second pairing plays its own moment")
	await _aim(_player, Vector3(0.3, 0.0, 0.3))
	await _press(&"drop_throw")
	await _frames(1)
	_check(view.moment_of(MATE_UNDER) == null and _mess.state_of(MATE_UNDER) == Mess.State.FLYING, "dropping the Pair mid-moment ends it")
	_places("after the moments")


func case_p06() -> void:
	await _build()
	await _pair()
	await _frames(2)
	var view := _player.held_view()
	var looks := view.looks_of(ON_FLOOR)
	_check(_is_ball(looks), "the held Pair is one sock ball")
	var mesh := looks.get_node("Body").find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var design := _mess.design_of(ON_FLOOR)
	_check(mesh.material_override == SockLook.material(design, true), "drawn as its Sock's Design")
	var t := _player.hands_tuning
	var sock := design.size_scale() * t.active_scale * t.depth
	_near(looks.scale.x / sock, 1.6, 0.01, "1.6 times a Sock's size (%.3f)" % (looks.scale.x / sock))
	_places("while held")


# --- A Pair on the floor -------------------------------------------------------------------------

func case_p07() -> void:
	await _build()
	await _pair()
	var spot := Vector3(0.3, 0.0, 0.4)
	await _aim(_player, spot)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the Pair's body to be let go")
	var body := _mess.flight_of(ON_FLOOR)
	_check((body.get_node("Shape") as CollisionShape3D).shape is SphereShape3D, "it falls as a ball")
	_near(body.linear_damp, 2.5, 0.001, "dragging 2.5")
	_near(body.angular_damp, 8.0, 0.001, "and 8 turning")
	_hands.clock += 1.0   # past the grab interval
	_check(_hands.pick_refusal(1, ON_FLOOR) == "", "it can be picked while it falls (Q2339)")
	_places("while it falls")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to come to rest")
	var rest := _mess.pose_of(ON_FLOOR).origin
	var r := SockDress.ball_radius(_mess.design_of(ON_FLOOR))
	_check(Vector2(rest.x, rest.z).distance_to(Vector2(spot.x, spot.z)) < 0.08, "it lies within a few cm of the spot (%s)" % rest)
	_near(rest.y, r, 0.01, "on the floor, neither sinking nor floating")
	_check(_hands.pick_refusal(1, ON_FLOOR) == "", "settled, it can be picked")
	# A Sock dropped on it rests on or beside it.
	_capacity(2)
	await _physics_ticks(25)
	_player.global_position = Vector3(-0.6, 0.0, 1.0)
	await _physics_ticks(2)
	await _pick(MATE_UNDER)
	_player.global_position = Vector3(0.3, 0.0, 1.2)
	await _physics_ticks(2)
	await _drop_at(rest + Vector3.UP * r, MATE_UNDER, "the lying Pair")
	var gap := _gap_to_box(MATE_UNDER, _mess.pose_of(ON_FLOOR).origin)
	_check(gap > r - 0.006, "the Sock is not inside the ball (%.3f from its centre, radius %.3f)" % [gap, r])
	_places("after a Sock dropped on the Pair")


func case_h12() -> void:
	await _build()
	await _pair()
	await _drop_at(Vector3(0.3, 0.0, 0.4), ON_FLOOR, "the floor")
	await _repick(OVER)
	await _physics_ticks(25)
	await _aim(_player, _mess.pose_of(ON_FLOOR).origin)
	await _press(&"pick")
	_check(_mess.state_of(ON_FLOOR) == Mess.State.LYING, "with full Hands the Pair stays")
	_check(_player.message() == Player.HANDS_FULL, "\"Hands full\" shows (%s)" % _player.message())
	await _drop_at(Vector3(-0.3, 0.0, 0.5), OVER, "the floor")
	await _repick(ON_FLOOR)
	_check(_hands.items_of(1) == PackedInt32Array([ON_FLOOR]) and _mess.is_pair(ON_FLOOR), "with a free place it goes back as a Pair")
	_places("after the floor Pair picks")


func case_p08() -> void:
	await _build()
	await _pair()
	var top := _mess.pose_of(MATE_UNDER) * Vector3(0.0, SockDress.box(_mess.design_of(MATE_UNDER)).y, 0.0)
	_player.global_position = Vector3(-0.8, 0.0, 1.0)
	await _physics_ticks(2)
	await _drop_at(top, ON_FLOOR, "the Sock")
	var r := SockDress.ball_radius(_mess.design_of(ON_FLOOR))
	# core/23: a Pair dropped from the hand may roll off a thin Sock; this case is about what lies on
	# it, so its record is laid there.
	var poses := _mess.poses.duplicate()
	var row := Mess.pack(Transform3D(Basis.IDENTITY, top + Vector3.UP * r))
	for i in Mess.POSE:
		poses[ON_FLOOR * Mess.POSE + i] = row[i]
	_mess.write({"poses": poses}, true)
	await _physics_ticks(2)
	var lying := _mess.pose_of(ON_FLOOR).origin
	_check(lying.y > top.y + r - 0.01, "the Pair rests on the Sock (%s)" % lying)
	_capacity(2)
	await _physics_ticks(25)
	await _aim(_player, _mess.pose_of(MATE_UNDER) * Vector3(0.12, 0.016, 0.0))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(MATE_UNDER), "the Sock under it to be picked")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.FLYING, "the Pair to fall", 10)
	_places("while it falls")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to land")
	_near(_mess.pose_of(ON_FLOOR).origin.y, r, 0.01, "it lands on the floor")
	_places("after it lands")


func case_p08_beside() -> void:
	await _build()
	await _pair()
	_player.global_position = Vector3(-0.57, 0.0, 1.0)
	await _physics_ticks(2)
	await _drop_at(Vector3(-0.57, 0.0, 0.0), ON_FLOOR, "the floor beside the Sock")
	var r := SockDress.ball_radius(_mess.design_of(ON_FLOOR))
	var lying := _mess.pose_of(ON_FLOOR).origin
	_near(lying.y, r, 0.01, "the Pair lies on the floor")
	_capacity(2)
	await _physics_ticks(25)
	await _aim(_player, _centre(MATE_UNDER))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(MATE_UNDER), "the Sock beside it to be picked")
	await _physics_ticks(10)
	_check(_mess.state_of(ON_FLOOR) == Mess.State.LYING, "the Pair beside stays")
	_near(_mess.pose_of(ON_FLOOR).origin.distance_to(lying), 0.0, 0.001, "where it was")
	_places("after the pick beside")


# --- Rules back to the old game (core/14) -----------------------------------------------------

## Lets the mouse go as Esc does, through the viewport.
func _free_mouse() -> void:
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await _physics_ticks(2)


## A left button press or release through the viewport, as the mouse sends it.
func _button(pressed: bool, index := MOUSE_BUTTON_LEFT) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = index
	ev.pressed = pressed
	Input.parse_input_event(ev)
	await _physics_ticks(2)


func case_r01() -> void:
	await _build()
	await _free_mouse()
	await _aim(_player, _centre(ON_FLOOR))
	_check(_player.aimed_sock == ON_FLOOR, "the crosshair is on the Sock")
	await _press(&"pick")
	_check(_hands.items_of(1).is_empty(), "free: the pick button picks nothing")
	var fov := _player.camera().fov
	Input.action_press(&"zoom")
	await _physics_ticks(30)
	_near(_player.camera().fov, fov, 0.001, "free: zoom does nothing")
	Input.action_release(&"zoom")
	await _wheel(&"hands_next")
	await _button(true, MOUSE_BUTTON_WHEEL_DOWN)
	await _button(false, MOUSE_BUTTON_WHEEL_DOWN)
	await _button(true)
	_check(_hands.items_of(1).is_empty(), "the click that captures picks nothing")
	await _button(false)
	await _physics_ticks(25)
	await _button(true)
	await _button(false)
	await _until(func() -> bool: return _hands.items_of(1).has(ON_FLOOR), "the next click to pick the Sock")
	await _free_mouse()
	Input.action_press(&"drop_throw")
	await _physics_ticks(30)
	Input.action_release(&"drop_throw")
	await _physics_ticks(2)
	_check(_hands.items_of(1).has(ON_FLOOR) and not _player.charging, "free: the drop button does nothing, no charge")
	await _button(true, MOUSE_BUTTON_WHEEL_UP)
	await _button(false, MOUSE_BUTTON_WHEEL_UP)
	await _button(true, MOUSE_BUTTON_RIGHT)
	_check(_hands.items_of(1).has(ON_FLOOR), "the right click that captures drops nothing")
	await _button(false, MOUSE_BUTTON_RIGHT)
	_check(_hands.items_of(1).has(ON_FLOOR), "nor on its release")


func case_r02() -> void:
	await _build()
	# A Pair lying where the Sock MATE_UNDER lies, its ball's centre over the Sock's middle.
	var box := _mess.box_of(MATE_UNDER)
	var middle := box.get_center()
	var radius := SockDress.ball_radius(_mess.design_of(ON_FLOOR))
	var states := _mess.states.duplicate()
	states[MATE_FLOOR] = Mess.State.IN_PAIR
	var mates := _mess.mates.duplicate()
	mates[ON_FLOOR] = MATE_FLOOR
	mates[MATE_FLOOR] = ON_FLOOR
	var poses := _mess.poses.duplicate()
	var at := Vector3(middle.x, radius, middle.z)
	for i in Mess.POSE:
		poses[ON_FLOOR * Mess.POSE + i] = Mess.pack(Transform3D(Basis.IDENTITY, at))[i]
	_mess.write({"states": states, "mates": mates, "poses": poses}, true)
	await _physics_ticks(2)
	var from := Vector3(middle.x, 0.02, middle.z + 1.0)
	var first := PhysicsQueries.ray(_player, from, from + Vector3(0.0, 0.0, -1.6), Mess.SOCK_MASK)
	_check(_mess.sock_of_hit(first) == MATE_UNDER, "the line meets the Sock's edge first (%d)" % _mess.sock_of_hit(first))
	var found := AimFinder.find(_player, _mess, from, Vector3(0.0, 0.0, -1.0), 1.6, [_player.get_rid()])
	_check(found["sock"] == ON_FLOOR, "the ball's surface is nearer than the Sock's middle: the Pair is aimed (%d)" % found["sock"])
	# The Pair further along the line: the Sock is nearer.
	at.z -= 0.3
	for i in Mess.POSE:
		poses[ON_FLOOR * Mess.POSE + i] = Mess.pack(Transform3D(Basis.IDENTITY, at))[i]
	_mess.write({"poses": poses}, true)
	await _physics_ticks(2)
	found = AimFinder.find(_player, _mess, from, Vector3(0.0, 0.0, -1.0), 1.6, [_player.get_rid()])
	_check(found["sock"] == MATE_UNDER, "a Pair behind the Sock's middle: the Sock is aimed (%d)" % found["sock"])
	# And through the player: a Pair lying on a Sock is the one aimed from above.
	at.z = middle.z
	for i in Mess.POSE:
		poses[ON_FLOOR * Mess.POSE + i] = Mess.pack(Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.03))[i]
	_mess.write({"poses": poses}, true)
	await _physics_ticks(2)
	_player.global_position = Vector3(middle.x, 0.0, middle.z + 1.0)
	await _aim(_player, _centre(ON_FLOOR))
	_check(_player.aimed_sock == ON_FLOOR, "from the player's eyes the Pair on the Sock is aimed (%d)" % _player.aimed_sock)


func case_r03() -> void:
	await _build()
	_parts.apply(_parts.answer(Command.new(&"wake", Parts.HOST, _mess.id, {"sock": ON_FLOOR})))
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the woken Sock to move")
	await _aim(_player, _mess.where_of(ON_FLOOR) + Vector3(0.0, 0.01, 0.0))
	_check(_mess.state_of(ON_FLOOR) == Mess.State.FLYING, "it is still moving")
	_check(_player.aimed_sock == ON_FLOOR, "the crosshair rests on the moving Sock (%d)" % _player.aimed_sock)
	await _press(&"pick")
	_check(_hands.items_of(1).has(ON_FLOOR), "a click picks it mid-slide")
	_check(_mess.state_of(ON_FLOOR) == Mess.State.HELD and _mess.flight_of(ON_FLOOR) == null, "held, its body gone")
	_places("after the mid-slide pick")


func case_r03_thrown() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, Vector3(0.0, 1.2, -2.0))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "the ring to show", 100)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the Sock to fly")
	# Hang it in the air a moment, in reach, so the aim has something to hold on to.
	var body := _mess.flight_of(ON_FLOOR)
	body.freeze = true
	await _physics_ticks(1)
	await _aim(_player, _mess.where_of(ON_FLOOR))
	_check(_mess.state_of(ON_FLOOR) == Mess.State.FLYING and _mess.throws.has(ON_FLOOR) and _player.aimed_sock == ON_FLOOR, "the crosshair rests on the Sock in the air (%d)" % _player.aimed_sock)
	await _press(&"pick")
	_check(_hands.items_of(1).has(ON_FLOOR), "a click catches it mid-air")
	_places("after the catch")


func case_r05() -> void:
	await _build()
	await _pair()
	_player.global_position = Vector3(-0.57, 0.0, 1.0)
	await _physics_ticks(2)
	await _drop_at(Vector3(-0.57, 0.0, 0.0), ON_FLOOR, "the floor beside the Sock")
	_capacity(2)
	await _physics_ticks(25)
	await _pick(MATE_UNDER)
	var ball := _mess.pose_of(ON_FLOOR).origin
	_player.global_position = ball + Vector3(0.0, 0.0, 1.0)
	await _physics_ticks(2)
	# Aimed at the ball's middle, the line meets a side steeper than the drop slope.
	await _aim(_player, ball)
	var raw := PhysicsQueries.ball_hit(_player, _player.eyes(), _player.aim_dir() * 2.5, 0.08, Mess.AIM_MASK, [_player.get_rid()])
	_check(not raw.is_empty() and (raw["normal"] as Vector3).y < cos(deg_to_rad(25.0)), "the ball's side there is steeper than the slope (%s)" % [raw.get("normal")])
	_check(_player.aimed_sock == ON_FLOOR, "the Pair is aimed")
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK and not _player.drop_refused, "the crosshair is white on the ball")
	var side := ball + Vector3(SockDress.ball_radius(_mess.design_of(ON_FLOOR)), 0.0, 0.0)
	_check(_hands.drop_refusal(1, side, Vector3.RIGHT) == "", "the Host takes a spot on the ball's very side, no slope test")
	var nothing := _hands.drop_refusal(1, side + Vector3(0.0, 0.5, 0.0), Vector3.UP)
	_check(nothing == Hands.NO_SPOT, "a spot in the air is still refused (%s)" % nothing)
	await _press(&"drop_throw")
	_check(_hands.items_of(1).is_empty() and _player.message() == "", "the drop is allowed on it, no \"Can't drop there\"")
	await _until(func() -> bool: return _mess.state_of(MATE_UNDER) == Mess.State.LYING, "the dropped Sock to come to rest")
	_places("after the drop on the Pair")


# --- Invariants and Commands ---------------------------------------------------------------------

func case_invariants() -> void:
	await _build()
	_parts.where = func(_by: int) -> Variant: return _player.global_position
	_parts.apply(_parts.answer(Command.new(&"pick", 2, _hands.id, {"sock": MATE_FLOOR})))
	_check(_hands.items_of(2) == PackedInt32Array([MATE_FLOOR]), "another player holds one Sock of the Design")
	await _pick(ON_FLOOR)
	_check(_mess.mate_of(ON_FLOOR) == -1 and _mess.mate_of(MATE_FLOOR) == -1, "halves in two players' Hands never pair (I.4)")
	_places("with the halves apart")
	_parts.apply(_parts.answer(Command.new(&"drop", 2, _hands.id, {"point": Vector3(0.3, 0.0, 0.6), "normal": Vector3.UP})))
	await _until(func() -> bool: return _mess.state_of(MATE_FLOOR) == Mess.State.LYING, "the other player's Sock to come to rest")
	await _physics_ticks(25)
	var ev := _parts.answer(Command.new(&"pick", 1, _hands.id, {"sock": MATE_FLOOR}))
	_check(ev["ok"] and int(ev.get("paired", -1)) == ON_FLOOR, "the Host's answer is the fuse (%s)" % ev)
	_parts.apply(ev)
	_check(_mess.is_pair(ON_FLOOR), "and the Pair formed in the picker's Hands")
	_places("after the fuse")
	ev = _parts.answer(Command.new(&"pick", 2, _hands.id, {"sock": MATE_FLOOR}))
	_check(not ev["ok"] and ev["reason"] == Hands.GONE, "a Sock in a Pair is refused \"gone\" (%s)" % ev)
	_check(not _parts.answer(Command.new(&"fall", 2, _mess.id, {"sock": ON_FLOOR}))["ok"], "only the Host lets a Pair fall")
	_check(not _parts.answer(Command.new(&"fall", Parts.HOST, _mess.id, {"sock": ON_FLOOR}))["ok"], "and only a lying one")
	var snap := _parts.snapshot()
	var back := _roundtrip(snap)
	var saved: Dictionary = back[String(_mess.id)]
	_same(saved["mates"], snap[_mess.id]["mates"], "the Pair survives a save")
	_parts.where = Callable()


# --- Helpers -------------------------------------------------------------------------------------

## A floor, the station, a Parts and the player standing at FRONT facing -Z.
func _build() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = FRONT
	_level.add_child(_player)
	_player.capture_mouse()   # the mouse is the player's: buttons act (R01)
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")
	_design_counts = _counts()


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


## Aims at Sock (or Pair) `sock` where it lies and picks it with the real action.
func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR,
			"Sock %d to be picked" % sock)


## Waits out the grab interval and picks `sock`.
func _repick(sock: int) -> void:
	await _physics_ticks(25)
	await _pick(sock)


## Picks ON_FLOOR, then its mate: one Pair in the Hands.
func _pair() -> void:
	await _pick(ON_FLOOR)
	await _repick(MATE_FLOOR)
	_check(_mess.is_pair(ON_FLOOR), "the two fused into a Pair")


## Aims at `spot`, taps the drop button and waits for `sock` to come to rest.
func _drop_at(spot: Vector3, sock: int, what: String) -> void:
	await _aim(_player, spot)
	_check(_player.crosshair_colour() == Player.CROSSHAIR_OK, "the crosshair is white on %s" % what)
	await _press(&"drop_throw")
	_check(not _hands.items_of(1).has(sock), "a tap drops it on %s" % what)
	await _until(func() -> bool: return _mess.state_of(sock) == Mess.State.LYING, "it to come to rest on %s" % what)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


## The middle of a lying Sock, or of a lying Pair's ball.
func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


## How far `point` is from lying Sock `sock`'s box.
func _gap_to_box(sock: int, point: Vector3) -> float:
	var b := SockDress.box(_mess.design_of(sock))
	var local := _mess.pose_of(sock).affine_inverse() * point
	var near := Vector3(clampf(local.x, -b.x * 0.5, b.x * 0.5), clampf(local.y, 0.0, b.y), clampf(local.z, -b.z * 0.5, b.z * 0.5))
	return local.distance_to(near)


## Whether `looks` is a sock ball's Looks.
func _is_ball(looks: Node3D) -> bool:
	return looks != null and SockLook.is_ball(looks)


func _counts() -> Dictionary:
	var out := {}
	for d in _mess.designs:
		out[d] = int(out.get(d, 0)) + 1
	return out


## I.1: every Sock is in exactly one place: lying (drawn), in exactly one player's Hands, falling, or
## in a Pair whose lead is in one of those; mates name each other; each Design keeps its records.
func _places(when: String, total := SOCKS) -> void:
	var counts := {"lying": 0, "held": 0, "flying": 0, "in_pair": 0}
	var ok := true
	for sock in _mess.count():
		var holders := 0
		for by: Variant in _hands.held:
			holders += (_hands.held[by] as PackedInt32Array).count(sock)
		var mate := _mess.mate_of(sock)
		ok = ok and (mate < 0 or (_mess.mate_of(mate) == sock and _mess.designs[mate] == _mess.designs[sock]))
		match _mess.state_of(sock):
			Mess.State.LYING:
				ok = ok and holders == 0 and _mess.looks_of(sock) != null and _mess.flight_of(sock) == null
				ok = ok and _is_ball(_mess.looks_of(sock)) == (mate >= 0)
				counts["lying"] += 1
			Mess.State.HELD:
				ok = ok and holders == 1 and _mess.looks_of(sock) == null and _mess.flight_of(sock) == null
				counts["held"] += 1
			Mess.State.FLYING:
				ok = ok and holders == 0 and _mess.looks_of(sock) == null
				counts["flying"] += 1
			Mess.State.IN_PAIR:
				ok = ok and holders == 0 and mate >= 0 and _mess.state_of(mate) != Mess.State.IN_PAIR
				ok = ok and _mess.looks_of(sock) == null and _mess.flight_of(sock) == null
				counts["in_pair"] += 1
	_check(ok and _mess.count() == total, "%s every Sock is in exactly one place (%s)" % [when, counts])
	_same(_counts(), _design_counts, "%s each Design keeps its records" % when)
