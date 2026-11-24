## core/43 played alone (list 03, docs/migration/m3-lists/03-hint-arrows-and-pings.md, answered by Q2590):
## the zoo with its Pings station, the game's player a Host of one (pinging alone works), the station's
## stand-in Teammate (peer 9), a box with an Outline, a wall, two Socks. Input goes through the game's own
## action (click_middle) and mouse motion. Lines are named by their number in the list. The co-op cases
## and the real path across two machines: tests/coop_pings_test.gd.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Pings"]
const STATION := "Stations/Pings"
const MATE := 9
const MIDDLE := &"click_middle"

var _holder_node: Node = null
var _zoo: Node3D = null
var _events: Array[Dictionary] = []
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "highlight", "method": "case_highlight", "world": false,
				"title": "core/43 lines 1-3, 19, 22, 25, 27, 28, 30, 40-42, 56, Q2590: alone, the corner says Ping with the middle button; a tap on the box outlines it in the player's colour, 2.2 times the crosshair's, after the aim's outline, and the blip plays at the spot; a tap on the floor puts a ring there and the box's outline goes (one ping each); it pops in, fades over its last second and is gone after 4 s"},
		{"name": "wheel", "method": "case_wheel", "world": false,
				"title": "core/43 lines 4, 5, 9-15, 31-33, 35, 38, 39: held past 0.25 s the wheel opens with five keycaps, the mouse steers its pointer and the view does not turn; slices are chosen from the top clockwise past 40 px with a hover tick each; let go on Help, an emoji bubble stands over the Sock, no copy over the own head, gone with its 3 s while the ping lasts 4; let go in the centre, nothing and no click"},
		{"name": "targets", "method": "case_targets", "world": false,
				"title": "core/43 lines 16-18, 20, 21, 24, 29, 36: a tap on the stand-in Teammate outlines its avatar (its own Outline still the aim's); open sky pings nothing and plays nothing; a bubble behind the wall is hidden; the Host makes a held Sock a spot, an unknown emoji a highlight, a path out of the level a spot, refuses a spot out of reach, and a ping on oneself is never on one's body"},
		{"name": "arrows", "method": "case_arrows", "world": false,
				"title": "core/43 lines 44-53: turned away from the ping, an arrow in the player's colour sits 56 px inside the edge (straight behind: down) and hides once it is on screen again; pings first, then nearest, at most 4; an arrow over a part of the HUD slides along the edge clear of it; with the HUD hidden none"},
		{"name": "menu_closes", "method": "case_menu_closes", "world": false,
				"title": "core/43 line 6: a menu opening closes the wheel with nothing placed; the right stick steers an open wheel (line 8)"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	Input.action_release(MIDDLE)
	if _holder_node != null:
		_holder_node.free()
		_holder_node = null
	_events.clear()
	_heard.clear()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_highlight() -> void:
	await _build()
	var player := _player()
	var pings := _pings()
	_check(player.hud().hints_text().contains("Ping"), "line 56: the corner says Ping (%s)" % player.hud().hints_text())
	var keys := Prompts.keys(Pinger.CLICK_MIDDLE)
	_check(not keys.is_empty() and keys[0] == "key_mmb", "line 56: with the middle button's icon (%s)" % [keys])
	_check(player.hud().hints_text().find("Ping") < player.hud().hints_text().find("Jump"), "line 56: before Jump")
	var box := _station().get_node("Box") as Node3D
	await _stand_facing(box.global_position + Vector3(1.6, -0.25, 0.0), box.global_position)
	_heard.clear()
	await _tap()
	await _until(func() -> bool: return _marks().mark_of(1) != null, "line 3: a tap places a ping", 30)
	var entry := pings.ping_of(1)
	_check(String(entry.get("path", "")) == String(LevelRuntime.level_of(pings).get_path_to(box)), "line 19: the box is named by its path (%s)" % [entry])
	_check(int(entry["emoji"]) == Pings.HIGHLIGHT, "line 3: a highlight")
	await _frames(2)
	var mark := _marks().mark_of(1)
	var outline := mark.outline()
	_check(outline != null and outline.shown and outline.get_parent() == box, "line 22: the box is outlined by the ping")
	_check(Outline.of(box) != outline, "the box's own Outline is still the aim's")
	if outline != null:
		var style := outline.current_style()
		_check(style.colour.to_html(false) == _marks().colour_of(1).to_html(false), "line 22: in the pinger's colour")
		_near(style.width, 2.2, 0.001, "line 22: 2.2 times as wide as the crosshair's")
		_check(style.priority > Outline.AIM.priority + Outline.AIM.shells.size(), "line 30: drawn after the aim's outline")
		_check(outline.outlined_count() > 0, "line 22: the box's mesh is outlined")
	_check(mark.grow > 0.0 and mark.grow <= 1.0, "line 27: popping in")
	await _frames(12)
	_near(mark.grow, 1.0, 0.001, "line 27: full after 0.15 s")
	_check(_heard_at(&"ping", entry["at"] as Vector3), "line 41: the blip at the spot (%s)" % [_heard])
	_check(mark.ring() == null, "no ring on an outlined thing")

	# Line 40: a tap on the floor replaces it with a ring.
	var floor_at := _station().global_position + Vector3(0.6, 0.0, 1.2)
	await _stand_facing(floor_at + Vector3(0.0, 0.0, 2.0), floor_at)
	await _tap()
	await _until(func() -> bool: return pings.serial == 2 and _marks().mark_of(1) != null and _marks().mark_of(1).n == 2, "line 40: the new ping replaces the last", 30)
	await _frames(1)
	_check(not is_instance_valid(outline) or outline.is_queued_for_deletion() or outline.get_parent() == null, "line 40: the box's ping outline goes at once")
	_check(_marks().count() == 1, "line 40: one ping per player")
	var ring := _marks().mark_of(1).ring()
	_check(ring != null and ring.global_position.distance_to(floor_at) < 0.3, "line 25: a ring lies on the bare spot")
	if ring != null:
		_check(ring.global_basis.y.normalized().dot(Vector3.UP) > 0.99, "line 25: flat against the surface")
	# Lines 28, 42: the last second fades, then it is gone.
	var tuning := pings.tuning
	await _until(func() -> bool: return pings.left_of(1) < tuning.fade * 0.5, "the last half second", 300)
	_check(_marks().mark_of(1).alpha < 0.55 and _marks().mark_of(1).alpha > 0.0, "line 28: fading (%.2f)" % _marks().mark_of(1).alpha)
	await _until(func() -> bool: return _marks().mark_of(1) == null, "line 42: gone after its 4 s", 60)
	_check(pings.standing().is_empty(), "line 42: no ping stands")


func case_wheel() -> void:
	await _build()
	var player := _player()
	var pings := _pings()
	var wheel := player.hud().wheel()
	var sock := _spot_sock("Near")
	var at := _mess().box_of(sock).get_center()
	await _stand_facing(Vector3(at.x, 0.0, at.z + 1.2), at)
	await _until(func() -> bool: return player.aimed_sock == sock, "the crosshair on the Sock", 20)
	Input.action_press(MIDDLE)
	await _physics_ticks(int(pings.tuning.hold * 60.0) - 4)
	_check(not wheel.is_open(), "line 3: not open before 0.25 s")
	await _until(func() -> bool: return wheel.is_open(), "line 4: the wheel opens after 0.25 s", 10)
	for i in 5:
		var k := wheel.key(i)
		_check(k.visible and (k.get_node("Column/Name") as Label).text == PingWheel.NAMES[i], "line 9: keycap %s" % PingWheel.NAMES[i])
	var top := wheel.key(0).get_global_rect().get_center()
	var centre := wheel.get_viewport_rect().size * 0.5
	_check(top.y < centre.y - 100.0 and absf(top.x - centre.x) < 2.0, "line 9: Here at the top")
	_check(wheel.key(1).get_global_rect().get_center().x > centre.x, "line 9: Help next, clockwise")
	var yaw := player.rotation.y
	var pitch := (player.get_node("Head") as Node3D).rotation.x
	await _move_mouse(Vector2(0.0, -20.0))
	_check(wheel.chosen == -1, "line 12: nearer than 40 px nothing is chosen (%d, %s)" % [wheel.chosen, wheel.pointer])
	var ticks := wheel.ticks
	await _move_mouse(Vector2(0.0, -40.0))
	_check(wheel.chosen == 0 and wheel.ticks == ticks + 1, "lines 12, 14: Here chosen, one hover tick")
	_near(wheel.key(0).scale.x, pings.tuning.wheel_chosen_scale, 0.001, "line 13: the chosen keycap grows 1.18")
	await _move_mouse(Vector2(500.0, 0.0))
	_check(wheel.pointer.length() <= pings.tuning.wheel_radius + 0.01, "line 11: never further than 150 px")
	await _move_mouse(Vector2(0.0, 300.0))
	await _move_mouse(Vector2(-150.0, -320.0))
	await _move_mouse(Vector2(200.0, -40.0))
	_check(wheel.chosen == 1, "line 12: Help, a fifth clockwise from the top (pointer %s)" % wheel.pointer)
	_near(player.rotation.y, yaw, 0.0001, "line 15: the view did not turn")
	_near((player.get_node("Head") as Node3D).rotation.x, pitch, 0.0001, "line 15: nor tilt")
	var clicks := wheel.clicks
	Input.action_release(MIDDLE)
	await _until(func() -> bool: return _marks().mark_of(1) != null, "line 5: the emoji is placed", 30)
	_check(not wheel.is_open() and wheel.clicks == clicks + 1, "line 14: the wheel closes with the click")
	var entry := pings.ping_of(1)
	_check(int(entry["sock"]) == sock and Pings.emoji_of(entry) == "help", "line 5: Help on the Sock (%s)" % [entry])
	await _physics_ticks(2)
	await _frames(1)
	var mark := _marks().mark_of(1)
	var sticker := mark.sticker()
	_check(sticker != null, "line 31: the bubble stands")
	if sticker != null:
		_check(sticker.position.y > at.y + 0.1 and Vector2(sticker.global_position.x - at.x, sticker.global_position.z - at.z).length() < 0.1, "line 33: over the Sock")
		_check(sticker.fixed_size and sticker.no_depth_test and sticker.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "line 32: a fixed-size billboard drawn through walls")
		_check((sticker.get_node("Emoji") as Sprite3D).texture == UiIcons.texture("emoji_help"), "line 31: with Help's icon")
	_check(mark.over_head() == null, "line 38: no copy over the own head")
	_check(mark.outline() == null and mark.ring() == null, "line 39: an emoji has no outline, no ring")
	await _until(func() -> bool: return mark.sticker() == null, "line 35: the bubble goes", 260)
	_check(pings.left_of(1) > 0.5, "line 35: inside the ping's 4 s (%.2f left)" % pings.left_of(1))

	# Line 5: let go in the centre, nothing.
	await _until(func() -> bool: return _marks().mark_of(1) == null, "the ping ends", 120)
	var asked := player.pinger().asked
	clicks = wheel.clicks
	Input.action_press(MIDDLE)
	await _until(func() -> bool: return wheel.is_open(), "the wheel opens again", 30)
	Input.action_release(MIDDLE)
	await _physics_ticks(3)
	_check(not wheel.is_open() and player.pinger().asked == asked and wheel.clicks == clicks, "lines 5, 14: a cancel places nothing, silent")


func case_targets() -> void:
	await _build()
	var player := _player()
	var pings := _pings()
	var mate := _station().get_node("Mate/%d" % MATE) as Avatar
	await _stand_facing(mate.global_position + Vector3(0.0, 0.0, 2.0), mate.global_position + Vector3.UP * 1.0)
	await _tap()
	await _until(func() -> bool: return int(pings.ping_of(1).get("mate", -1)) == MATE, "line 16: the Teammate is pinged", 30)
	await _frames(2)
	var outline := _marks().mark_of(1).outline()
	_check(outline != null and outline.shown and mate.is_ancestor_of(outline), "line 24: their avatar is outlined")
	_check(Outline.of(mate) != outline and Outline.of(mate) != null, "their own Outline stays the aim's")

	# Line 17: open sky.
	var missed := player.pinger().missed
	var serial := pings.serial
	await _stand_facing(_station().global_position + Vector3(0.0, 0.0, 2.5), _station().global_position + Vector3(0.0, 40.0, 2.4))
	_heard.clear()
	await _tap()
	await _physics_ticks(3)
	_check(player.pinger().missed == missed + 1 and pings.serial == serial, "line 17: nothing is placed")
	_check(_heard.is_empty(), "line 17: nothing sounds (%s)" % [_heard])

	# Line 36: a bubble behind the wall is hidden.
	var behind := _spot_sock("Behind")
	var at := _mess().box_of(behind).get_center()
	await _stand_facing(at + Vector3(-1.4, -at.y, 0.0), at)
	await _hold_choose(Vector2(0.0, -80.0))
	await _until(func() -> bool: return int(pings.ping_of(1).get("sock", -1)) == behind and Pings.emoji_of(pings.ping_of(1)) == "here",
			"the Here bubble on the Sock behind the wall", 30)
	await _physics_ticks(2)
	await _frames(1)
	_check(_marks().mark_of(1).sticker() != null, "seen from the side, the bubble shows")
	await _stand_facing(Vector3(at.x, 0.0, at.z + 3.5), at)
	await _physics_ticks(2)
	await _frames(1)
	_check(_marks().mark_of(1).sticker() == null and _marks().mark_of(1).sticker_hidden, "line 36: behind the wall it is hidden")

	# The Host's checks (lines 18, 20, 21).
	var hands := LevelRuntime.of(_zoo).hands
	var near := _spot_sock("Near")
	var where := _mess().where_of(near)
	hands.pick(1, near)
	await _until(func() -> bool: return hands.items_of(1).has(near), "the Near Sock is held", 30)
	pings.ping(1, {"sock": near, "mate": -1, "path": "", "at": where, "normal": Vector3.UP}, 9)
	var e := pings.ping_of(1)
	_check(int(e["sock"]) == -1 and (e["at"] as Vector3).distance_to(where) < 0.001, "line 20: a held Sock is a spot")
	_check(int(e["emoji"]) == Pings.HIGHLIGHT, "line 21: an emoji not of the five is a highlight")
	pings.ping(1, {"sock": -1, "mate": 1, "path": "../../x", "at": where, "normal": Vector3.UP}, 0)
	e = pings.ping_of(1)
	_check(int(e["mate"]) == -1 and String(e["path"]) == "", "line 18: not oneself; a path out of the level is a spot")
	serial = pings.serial
	pings.ping(1, {"sock": -1, "mate": -1, "path": "", "at": where + Vector3(80.0, 0.0, 0.0), "normal": Vector3.UP}, -1)
	_check(pings.serial == serial and _last_refusal() == Pings.FAR, "the Host refuses a spot out of reach")
	# Line 29: a ping of this machine's own player (as a Teammate would) draws nothing on them.
	pings.parts.apply(pings.grant({"pings": {7: {"sock": -1, "mate": 1, "path": "", "at": player.global_position,
			"normal": Vector3.UP, "emoji": -1, "seconds": 4.0, "n": pings.serial + 1}}, "serial": pings.serial + 1}))
	await _frames(2)
	var on_me := _marks().mark_of(7)
	_check(on_me != null and on_me.on_self() and on_me.ring() == null and on_me.outline() == null, "line 29: nothing on oneself, no ring")
	_check(_marks().hint_targets().is_empty(), "lines 43, 48: no arrow to oneself")


func case_arrows() -> void:
	await _build()
	var player := _player()
	var arrows := player.hud().hint_arrows()
	var floor_at := _station().global_position + Vector3(0.6, 0.0, 1.2)
	var feet := floor_at + Vector3(0.0, 0.0, 2.0)
	await _stand_facing(feet, floor_at)
	await _tap()
	await _until(func() -> bool: return _marks().mark_of(1) != null, "a ping on the floor", 30)
	await _frames(2)
	_check(arrows.count() == 0, "line 44: no arrow while it is on screen")
	await _stand_facing(feet, feet + Vector3(0.0, 1.0, 5.0))
	await _frames(2)
	_check(arrows.count() == 1, "line 44: an arrow once it is behind the camera")
	var size := arrows.get_viewport_rect().size
	var margin := arrows.tuning.margin
	if arrows.count() == 1:
		var a := arrows.shown()[0]
		var tip := a["tip"] as Vector2
		_check((a["colour"] as Color).to_html(false) == _marks().colour_of(1).to_html(false), "line 46: in the pinger's colour")
		_check(absf(tip.y - (size.y - margin)) < 1.0, "line 45: straight behind, it points down from %.0f px inside the edge (%s)" % [margin, tip])
		_check(Vector2.from_angle(float(a["angle"])).dot(Vector2.DOWN) > 0.9, "line 45: pointing down")
	await _stand_facing(feet, feet + Vector3(5.0, 0.0, 0.0))
	await _frames(2)
	if arrows.count() == 1:
		var side := arrows.shown()[0]
		_check(Vector2.from_angle(float(side["angle"])).x < -0.5, "line 44: turned right, it points left")
	# Line 50: pings first, then the nearest, at most 4.
	var cam := player.camera().global_transform
	var behind := cam.origin + cam.basis.z * 3.0
	var many: Array[Dictionary] = []
	for i in 6:
		many.append({"at": behind + cam.basis.x * float(i - 3), "colour": Color.RED})
	arrows.add_source(func() -> Array[Dictionary]: return many)
	await _frames(2)
	_check(arrows.count() == arrows.tuning.max_arrows, "line 50: at most %d (%d)" % [arrows.tuning.max_arrows, arrows.count()])
	_check(int(arrows.shown()[0]["priority"]) == 1, "line 50: the ping's first")
	_check(float(arrows.shown()[1]["dist"]) <= float(arrows.shown()[2]["dist"]), "line 50: then the nearest")
	# Line 51: an arrow over a part of the HUD slides along the edge.
	var t := arrows.tuning
	var want := Vector2(size.x * 0.5, size.y - margin)
	var rects: Array[Rect2] = [Rect2(want - Vector2(80.0, 40.0), Vector2(160.0, 80.0))]
	var got := HintArrows.slide_clear(want, PI * 0.5, t.size, t.side, size, margin, rects, t.clear_pad, t.slide_step)
	_check(got != want and absf(got.y - want.y) < 0.5, "line 51: slid along the bottom edge (%s)" % got)
	_check(not HintArrows.arrow_bounds(got, PI * 0.5, t.size, t.side).intersects(rects[0].grow(t.clear_pad)), "line 51: clear of it by 8 px")
	# Line 52: the HUD hidden, none.
	player.hud().visible = false
	await _frames(2)
	_check(arrows.count() == 0, "line 52: no arrow with the HUD hidden")
	player.hud().visible = true


func case_menu_closes() -> void:
	await _build()
	var player := _player()
	var wheel := player.hud().wheel()
	await _stand_facing(_station().global_position + Vector3(0.0, 0.0, 2.5), _station().global_position)
	Input.action_press(MIDDLE)
	await _until(func() -> bool: return wheel.is_open(), "the wheel opens", 30)
	await _stick(1.0)
	await _frames(2)
	_check(wheel.chosen == 1, "line 8: the right stick to the right steers the open wheel to Help (%d, %s)" % [wheel.chosen, wheel.pointer])
	await _stick(0.1)
	await _frames(2)
	_check(wheel.chosen == -1, "line 8: the stick at rest is the centre (%d, %s)" % [wheel.chosen, wheel.pointer])
	await _stick(0.0)
	var asked := player.pinger().asked
	player.set_input_blocked(true)
	await _physics_ticks(2)
	_check(not wheel.is_open(), "line 6: a menu closes the wheel")
	Input.action_release(MIDDLE)
	await _physics_ticks(2)
	player.set_input_blocked(false)
	await _physics_ticks(2)
	_check(player.pinger().asked == asked and _pings().standing().is_empty(), "line 6: nothing placed")


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
	_holder_node = Node.new()
	_holder_node.name = "Alone"
	add_child(_holder_node)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder_node.add_child(_zoo)
	_parts().applied.connect(func(ev: Dictionary) -> void: _events.append(ev))
	_player().global_position = _station().global_position + Vector3(0.0, 0.0, 3.0)
	await _until(func() -> bool: return _player().is_on_floor() and _spot_sock("Near") >= 0 and _mess().state_of(_spot_sock("Near")) == Mess.State.LYING,
			"the zoo to stand and its Socks to lie", 300)
	_player().capture_mouse()


## A short press of the middle button (a tap).
func _tap() -> void:
	Input.action_press(MIDDLE)
	await _physics_ticks(2)
	Input.action_release(MIDDLE)
	await _physics_ticks(2)


## Holds the middle button until the wheel opens, moves the mouse by `move` and lets go.
func _hold_choose(move: Vector2) -> void:
	var wheel := _player().hud().wheel()
	Input.action_press(MIDDLE)
	await _until(func() -> bool: return wheel.is_open(), "the wheel opens", 30)
	await _move_mouse(move)
	Input.action_release(MIDDLE)
	await _physics_ticks(2)


## The mouse moves by `relative` pixels, as a real mouse's motion reaches the player.
func _move_mouse(relative: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	# The window's pixels: the viewport reads them through its stretch.
	motion.relative = relative * get_viewport().get_final_transform().get_scale()
	Input.parse_input_event(motion)
	await _frames(1)


## A pad's right stick pushed `x` to the right, as a real pad's motion reaches the game.
func _stick(x: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = x
	Input.parse_input_event(motion)
	await _frames(1)


## Stands the player at `feet`, looking at `target`.
func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var head := player.get_node("Head") as Node3D
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var up := target - head.global_position
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _heard_at(sound: StringName, at: Vector3) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and bool(e[1]) and (e[2] as Vector3).distance_to(at) < 0.01:
			return true
	return false


func _last_refusal() -> String:
	for i in range(_events.size() - 1, -1, -1):
		if StringName(_events[i].get("kind", &"")) == Pings.PING and not _events[i].get("ok", false):
			return String(_events[i].get("reason", ""))
	return ""


func _station() -> Node3D:
	return _zoo.get_node(STATION) as Node3D


func _spot_sock(spot: String) -> int:
	return (_zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _mess() -> Mess:
	return LevelRuntime.of(_zoo).mess


func _pings() -> Pings:
	return LevelRuntime.of(_zoo).pings


func _marks() -> PingMarks:
	return _pings().get_node("Marks") as PingMarks


func _parts() -> Parts:
	return LevelRuntime.of(_zoo).parts


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
