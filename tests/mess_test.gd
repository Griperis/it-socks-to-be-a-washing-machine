## The two-tier Mess (core/13, M01-M10): a lying Sock is a static body of the physics server and an
## instance of a floor cell's MultiMesh; only the aimed, held and nearest flying Socks are Looks
## scenes; moving Socks are budgeted, woken by picks, hits and moving Doors and drawers, and rest when
## still. One case per behaviour line and the two real paths. The cases play the handling station on
## a floor with the game's player and a Parts (a Host of one), or the zoo.
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const EVERY := "Stations/EverySock"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw"]
## The handling station's Socks, by id (the order of its SockSpots).
const ON_FLOOR := 0
const UNDER := 1
const OVER := 2
const ON_TABLE := 3
const BEHIND_WALL := 4
const MATE_FLOOR := 6
const MATE_UNDER := 7
const FRONT := Vector3(0.0, 0.0, 1.5)

var _level: Node3D = null
var _zoo: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path_pick_under", "method": "case_real_pick", "world": false,
				"title": "Real path, M07: the player picks a Sock from under another at the handling station and the one on top falls"},
		{"name": "real_path_throw_rows", "method": "case_real_throw", "world": false,
				"title": "Real path, M08: a full Throw into the every-Sock rows wakes the lying Socks it hits, and they rest again"},
		{"name": "m01_no_node", "method": "case_m01", "world": false,
				"title": "M01: a lying Sock is a server body and an instance, no node; the crosshair hits it and a falling Sock lands on it"},
		{"name": "m02_cells", "method": "case_m02", "world": false,
				"title": "M02: lying Socks are drawn in MultiMeshes by 8 m floor cell and shape, tinted and packed per Design, with a visibility range"},
		{"name": "m03_looks", "method": "case_m03", "world": false,
				"title": "M03: the aimed Sock is lent its Looks where its instance was (no pop) and gives it back; a thrown one flies with its Looks"},
		{"name": "m04_every_sock", "method": "case_m04", "world": false,
				"title": "M04: with the every-Sock station in the zoo, no lying Sock has a node and the zoo keeps a few thousand nodes"},
		{"name": "m05_budget", "method": "case_m05", "world": false,
				"title": "M05: woken Socks wait for the budget, start nearest first and a few a tick, rest under pressure; a Throw never waits"},
		{"name": "m06_rest", "method": "case_m06", "world": false,
				"title": "M06: a fall Jolt never sleeps rests once it has stayed still for the rest time"},
		{"name": "m07_cap", "method": "case_m07", "world": false,
				"title": "M07: a pick wakes at most pick_wakes of the Socks on it, found by a query; a Sock beside it stays"},
		{"name": "m09_door", "method": "case_m09_door", "world": false,
				"title": "M09: a swinging Door wakes the lying Sock in its way"},
		{"name": "m09_drawer", "method": "case_m09_drawer", "world": false,
				"title": "M09: a Sock lying in a drawer wakes as it slides and rides out with it"},
		{"name": "m10_bodies", "method": "case_m10", "world": false,
				"title": "M10: a dropped Sock bounces 0.35, slides 0.6 and drags 0.05 / 0.8; a woken one slides 0.9 and drags 0.6 / 3.0"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	if _zoo != null:
		_zoo.free()
		_zoo = null


# --- The real paths ------------------------------------------------------------------------------

func case_real_pick() -> void:
	await _build()
	var over_was := _mess.pose_of(OVER).origin
	var under := _mess.pose_of(UNDER).origin
	var under_left := under.x - SockDress.box(_mess.design_of(UNDER)).x * 0.5
	var over_left := over_was.x - SockDress.box(_mess.design_of(OVER)).x * 0.5
	await _aim(_player, Vector3((under_left + over_left) * 0.5, 0.02, under.z))
	_check(_player.aimed_sock == UNDER, "the crosshair rests on the lower Sock's tip (%d)" % _player.aimed_sock)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(UNDER), "the lower Sock to be picked")
	await _until(func() -> bool: return _mess.state_of(OVER) == Mess.State.FLYING, "the Sock on top to fall", 10)
	_check(_mess.flight_of(OVER) != null, "it falls as a body")
	await _until(func() -> bool: return _mess.state_of(OVER) == Mess.State.LYING, "it to lie again")
	var now := _mess.pose_of(OVER).origin
	_check(now.y < over_was.y - 0.01, "it came down to the floor (%.3f from %.3f)" % [now.y, over_was.y])
	_check(_mess.is_drawn(OVER) and _mess.flight_of(OVER) == null, "lying again: drawn, its body gone")


func case_real_throw() -> void:
	await _zoo_up()
	var station := _zoo.get_node(EVERY) as Node3D
	var first := -1
	for sock in _mess.count():
		var spot := _mess.pose_of(sock).origin
		if station.to_local(spot).z < -2.0 and absf(station.to_local(spot).x) < 4.0:
			first = sock
			break
	_check(first >= 0, "a Sock of the station's rows")
	var target := _mess.pose_of(first).origin
	_player.global_position = target + Vector3(0.0, 0.0, 1.6)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await _physics_ticks(3)
	var woken := {}
	_parts.applied.connect(func(ev: Dictionary) -> void:
		if ev.get("ok", false) and StringName(ev.get("kind", &"")) == &"wake":
			var states: PackedByteArray = ev["changes"][_mess.id]["states"]
			for sock in states.size():
				if states[sock] == Mess.State.FLYING:
					woken[sock] = true)
	# Pick the nearest Sock with the real action, then throw it at the rows.
	await _aim(_player, target + Vector3(0.0, 0.013, 0.0))
	await _press(&"pick")
	await _until(func() -> bool: return not _hands.items_of(1).is_empty(), "a Sock to be picked")
	var thrown := _hands.items_of(1)[0]
	await _aim(_player, target + Vector3(0.0, 0.0, -1.2))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(thrown) != null, "the Sock to fly", 10)
	await _until(func() -> bool: return not woken.is_empty(), "a lying Sock of the rows to wake", 180)
	woken.erase(thrown)
	_check(woken.size() >= 1 and woken.size() <= 1 + 8, "the Sock hit and at most 8 touching it wake (%d)" % woken.size())
	await _until(func() -> bool:
		for sock: int in woken:
			if _mess.state_of(sock) == Mess.State.FLYING:
				return false
		return _mess.state_of(thrown) != Mess.State.FLYING, "every woken Sock to rest again", 900)
	for sock: int in woken:
		if _mess.state_of(sock) != Mess.State.LYING or not _mess.is_drawn(sock):
			_check(false, "woken Sock %d lies drawn again" % sock)


# --- One case a line ------------------------------------------------------------------------------

func case_m01() -> void:
	await _build()
	for child in _mess.lying.get_children():
		if not (child is MultiMeshInstance3D):
			_check(false, "nothing but MultiMeshes under Lying (%s)" % child.name)
	var lying := 0
	for sock in _mess.count():
		if _mess.state_of(sock) == Mess.State.LYING:
			lying += 1
			_check(_mess.is_drawn(sock), "lying Sock %d is drawn" % sock)
	_check(_mess.body_count() == lying, "one body a lying Sock (%d of %d)" % [_mess.body_count(), lying])
	var top := _centre(ON_FLOOR) + Vector3(0.0, 0.5, 0.0)
	var hit := PhysicsQueries.ray(_mess, top, top + Vector3.DOWN, Mess.AIM_MASK)
	_check(not hit.is_empty() and _mess.sock_at(hit["rid"]) == ON_FLOOR and hit["collider"] == null,
			"a ray meets the lying Sock's body, which has no node (%s)" % [hit])
	await _aim(_player, _centre(ON_FLOOR))
	_check(_player.aimed_sock == ON_FLOOR, "the crosshair rests on it")
	await _aim(_player, _centre(MATE_FLOOR))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(MATE_FLOOR), "a Sock to be picked")
	await _aim(_player, _centre(ON_FLOOR) + Vector3(0.0, 0.013, 0.0))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(MATE_FLOOR) == Mess.State.LYING, "the dropped Sock to rest")
	var low := _mess.box_of(MATE_FLOOR).position.y
	_check(low > 0.015, "it rests on the lying Sock, not through it (bottom %.3f)" % low)


func case_m02() -> void:
	await _zoo_up()
	var t := _mess.bodies
	var lying := 0
	for sock in _mess.count():
		if _mess.state_of(sock) == Mess.State.LYING:
			lying += 1
	_check(_mess.drawn_count() + _mess._lent.size() == lying, "every lying Sock not lent its Looks is an instance (%d of %d)" % [_mess.drawn_count(), lying])
	var drawing := _mess._drawing
	_check(drawing.cell_count() > 4, "the zoo's Socks lie in several cells (%d)" % drawing.cell_count())
	var wrong := 0
	for sock: int in drawing._cell_of:
		var c: Vector3i = drawing._cell_of[sock]
		var at := _mess.lying.to_local(_mess.pose_of(sock).origin)
		var row := drawing.instance_of(sock)
		var design := _mess.design_of(sock)
		var shape := MessDrawing.shape_of(design, _mess.is_pair(sock))
		var placed := drawing._cells[c].global_transform * (row[0] as Transform3D)
		if floori(at.x / t.cell_size) != c.x or floori(at.z / t.cell_size) != c.y or drawing._shapes[c.z] != shape \
				or row[1] != design.colour or row[2] != MessDrawing.look_data(design) \
				or placed.origin.distance_to((_mess.pose_of(sock) * Transform3D(Basis.from_scale(Vector3.ONE * design.size_scale())) \
				* drawing._mesh_at[shape]).origin) > 0.001:
			wrong += 1
	_check(wrong == 0, "each instance in its own cell and shape, its colour and look data its Design's (%d wrong)" % wrong)
	for node: MultiMeshInstance3D in drawing._cells.values():
		if node.visibility_range_end != t.draw_range or not node.multimesh.use_custom_data or node.multimesh.mesh == null:
			_check(false, "%s has the draw range, custom data and the Looks' mesh" % node.name)
	var d := SockDesign.new()
	d.pattern = &"dots"
	d.patches = &"heel_toe"
	d.motif = 4
	d.coat = 1
	d.layout = &"band"
	d.colour3 = Color8(1, 2, 3)
	var look := MessDrawing.look_data(d)
	_check(look.r == 4.0 + 16.0 * 2.0 and look.g == 5.0 + 2.0 * 256.0 + 2.0 * 65536.0 and look.a == float(65536 + 2 * 256 + 3 + 1),
			"the look data packs as the old game's (%s)" % look)


func case_m03() -> void:
	await _build()
	var drawing := _mess._drawing
	var c: Vector3i = drawing._cell_of[ON_FLOOR]
	var drawn := drawing._cells[c].global_transform * (drawing.instance_of(ON_FLOOR)[0] as Transform3D)
	await _aim(_player, _centre(ON_FLOOR))
	var looks := _mess.looks_of(ON_FLOOR)
	_check(looks != null and SockDress.state_of(looks) == SockDress.AIMED, "the aimed Sock is lent its Looks, outlined")
	_check(not drawing.is_drawn(ON_FLOOR) and _mess.is_drawn(ON_FLOOR), "its instance hides while the Looks shows it")
	var mesh := looks.get_node("Body").find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var gap := (mesh.global_transform.origin - drawn.origin).length() + (mesh.global_transform.basis.x - drawn.basis.x).length()
	_near(gap, 0.0, 0.0005, "the Looks' mesh is where the instance was: no pop (%s vs %s)" % [mesh.global_transform, drawn])
	await _aim(_player, _centre(ON_TABLE) + Vector3(0.0, 0.5, 0.0))
	_check(drawing.is_drawn(ON_FLOOR) and (not is_instance_valid(looks) or looks.is_queued_for_deletion()), "aimed away, it gives the Looks back")
	await _pick(ON_FLOOR)
	_check(not _mess.is_drawn(ON_FLOOR), "held, the Mess draws nothing of it (the Hands do)")
	await _aim(_player, _player.global_position + Vector3(0.0, 1.6, -3.0))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the Sock to fly", 10)
	_check(_mess.flight_of(ON_FLOOR).has_node(^"Looks"), "the thrown Sock flies with its Looks (its cloth)")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to lie")
	_check(_mess.is_drawn(ON_FLOOR), "lying, it is an instance again")


func case_m04() -> void:
	await _zoo_up()
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_check(nodes < 8000, "the zoo with every Sock keeps a few thousand nodes (%d; 48,000 with a node a Sock)" % nodes)
	var station := _zoo.get_node(EVERY)
	_check(station.find_children("*", "StaticBody3D", true, false).is_empty() and station.find_children("Sock*", "", true, false).is_empty(),
			"no lying Sock of the station is a node")
	_check(_mess.body_count() > 2000, "every Sock still lies as a body (%d)" % _mess.body_count())


func case_m05() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var t := _mess.bodies.duplicate() as MessTuning
	t.moving_budget = 4
	t.throw_reserve = 2
	t.start_cap = 1
	t.stop_cap = 1
	t.rest_speed = 0.0
	t.rest_spin = 0.0
	t.rest_time = 0.2
	_mess.bodies = t
	var queued := PackedInt32Array([ON_TABLE, BEHIND_WALL, MATE_FLOOR, MATE_UNDER])
	_mess.queue_wake(queued, &"wake")
	var started: Array[int] = []
	var most := 0
	var most_a_tick := 0
	var rested_under_pressure := false
	for i in 400:
		await _physics_ticks(1)
		var new_now := 0
		for sock in queued:
			var body := _mess.flight_of(sock)
			if body != null:
				body.can_sleep = false
				if not started.has(sock):
					started.append(sock)
					new_now += 1
			elif started.has(sock) and _mess.state_of(sock) == Mess.State.LYING and _mess.waiting_count() > 0:
				rested_under_pressure = true
		most = maxi(most, _mess.moving_count())
		most_a_tick = maxi(most_a_tick, new_now)
		if started.size() == queued.size():
			break
	_check(started.size() == queued.size(), "every woken Sock starts in the end (%s)" % [started])
	_check(not started.is_empty() and started[0] == MATE_FLOOR, "the nearest the player starts first (%s)" % [started])
	_check(most <= 2, "they move no more than the general share at once (%d)" % most)
	_check(most_a_tick <= 1, "at most the start cap a tick (%d)" % most_a_tick)
	_check(rested_under_pressure, "with Socks waiting, still ones rest to make room")
	await _physics_ticks(30)
	_check(_mess.moving_count() >= 1, "with nobody waiting, no pressure: a still Sock that never sleeps stays moving")
	_mess.queue_wake(PackedInt32Array([UNDER, OVER]), &"wake")
	await _aim(_player, _player.global_position + Vector3(0.0, 1.6, -3.0))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _hands.items_of(1).is_empty(), "the Sock to leave the Hands", 5)
	_check(_mess.flight_of(ON_FLOOR) != null, "a Throw flies at once though the general share is full")


func case_m06() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, Vector3(0.3, 0.0, 0.4))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the body to be let go")
	_mess.flight_of(ON_FLOOR).can_sleep = false
	var ticks := 0
	while _mess.state_of(ON_FLOOR) == Mess.State.FLYING and ticks < 120:
		ticks += 1
		await _physics_ticks(1)
	_check(_mess.state_of(ON_FLOOR) == Mess.State.LYING, "it rests without Jolt's sleep, %d ticks after the drop" % ticks)
	_check(float(ticks) / 60.0 >= _mess.bodies.rest_time, "not before it has stayed still for the rest time")


func case_m07() -> void:
	await _build()
	var t := _mess.bodies.duplicate() as MessTuning
	t.pick_wakes = 0
	_mess.bodies = t
	await _pick_under()
	await _physics_ticks(10)
	_check(_mess.state_of(OVER) == Mess.State.LYING, "with pick_wakes 0 the Sock on top stays")
	var beside := _mess.resting_on(_mess.box_of(MATE_UNDER))
	_check(not beside.has(MATE_FLOOR), "a Sock lying beside on the floor is not on it (%s)" % beside)
	t.pick_wakes = 40
	_check(_mess.resting_on(_mess.box_of(ON_FLOOR)).is_empty(), "nothing lies on a Sock alone on the floor")


func case_m09_door() -> void:
	await _build()
	var cupboard := _station.get_node("Cupboard/Openable") as Openable
	var pivot := (cupboard.movers()[0] as Node3D).global_position
	var at := Transform3D(Basis.IDENTITY, pivot + Vector3(0.35, 0.45, 0.35))
	_mess.write({"poses": _pose_row(ON_TABLE, at)}, false)
	await _physics_ticks(5)
	_check(_mess.state_of(ON_TABLE) == Mess.State.LYING, "a Sock lies in the Door's way (held there)")
	cupboard.write({"open": true}, false)
	await _until(func() -> bool: return _mess.state_of(ON_TABLE) == Mess.State.FLYING, "the swinging Door to wake it", 60)
	await _until(func() -> bool: return _mess.state_of(ON_TABLE) == Mess.State.LYING, "it to rest")
	_check(_mess.pose_of(ON_TABLE).origin.y < 0.05, "it fell to the floor (%.3f)" % _mess.pose_of(ON_TABLE).origin.y)


func case_m09_drawer() -> void:
	await _build()
	var tray := _tray(Vector3(3.2, 0.0, 1.0))
	_station.add_child(tray)
	await _physics_ticks(3)
	var at := Transform3D(Basis.IDENTITY, Vector3(3.2, 0.32, 1.0))
	_mess.write({"poses": _pose_row(ON_TABLE, at)}, false)
	await _physics_ticks(10)
	_check(_mess.state_of(ON_TABLE) == Mess.State.LYING, "a Sock lies in the shut drawer and stays")
	(tray.get_node("Openable") as Openable).write({"open": true}, false)
	await _until(func() -> bool: return _mess.state_of(ON_TABLE) == Mess.State.FLYING, "the sliding drawer to wake it", 30)
	await _until(func() -> bool: return _mess.state_of(ON_TABLE) == Mess.State.LYING, "it to rest")
	var now := _mess.pose_of(ON_TABLE).origin
	_check(now.z > 1.0 + 0.2 and now.y > 0.25, "it rode out with the drawer and lies in it (%s)" % now)


func case_m10() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, Vector3(0.3, 0.0, 0.4))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the body to be let go")
	var dropped := _mess.flight_of(ON_FLOOR)
	var m := dropped.physics_material_override
	_check(m != null and is_equal_approx(m.bounce, 0.35) and is_equal_approx(m.friction, 0.6), "a dropped Sock bounces 0.35 and slides 0.6")
	_check(is_equal_approx(dropped.linear_damp, 0.05) and is_equal_approx(dropped.angular_damp, 0.8), "and drags 0.05 / 0.8")
	_mess.queue_wake(PackedInt32Array([BEHIND_WALL]), &"wake")
	await _until(func() -> bool: return _mess.flight_of(BEHIND_WALL) != null, "the woken Sock to move", 10)
	var woken := _mess.flight_of(BEHIND_WALL)
	m = woken.physics_material_override
	_check(m != null and is_equal_approx(m.bounce, 0.0) and is_equal_approx(m.friction, 0.9), "a woken Sock slides 0.9, no bounce")
	_check(is_equal_approx(woken.linear_damp, 0.6) and is_equal_approx(woken.angular_damp, 3.0), "and drags 0.6 / 3.0")


# --- helpers ------------------------------------------------------------------------------------

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
	await _until(func() -> bool: return _player.is_on_floor() and _mess.is_drawn(0), "the player to stand and the Socks to lie")


func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	_mess = _zoo.get_node("Socks/Mess") as Mess
	_hands = _zoo.get_node("Socks/Hands") as Hands
	_parts = _zoo.get_node("Parts") as Parts
	_player = _zoo.get_node("Player") as Player
	_player.capture_mouse()   # the mouse is the player's: buttons act (R01)
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(_mess.count() - 1) != null, "the player to stand and every Sock to lie", 600)


## A drawer of the test's own: an Openable whose Looks slides a tray 0.4 m out over 0.5 s.
func _tray(at: Vector3) -> Node3D:
	var thing := Node3D.new()
	thing.name = "Tray"
	thing.position = at
	var openable := Openable.new()
	openable.name = "Openable"
	thing.add_child(openable)
	var looks := Node3D.new()
	looks.name = "Looks"
	thing.add_child(looks)
	var slide := AnimatableBody3D.new()
	slide.name = "Slide"
	looks.add_child(slide)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.04, 0.6)
	shape.shape = box
	shape.position.y = 0.3
	slide.add_child(shape)
	var anim := Animation.new()
	anim.length = 0.5
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, ^"Slide:position")
	anim.track_insert_key(track, 0.0, Vector3.ZERO)
	anim.track_insert_key(track, 0.5, Vector3(0.0, 0.0, 0.4))
	var library := AnimationLibrary.new()
	library.add_animation(Openable.ANIMATION, anim)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	player.add_animation_library(&"", library)
	looks.add_child(player)
	return thing


func _pose_row(sock: int, t: Transform3D) -> PackedFloat32Array:
	var p := _mess.poses.duplicate()
	var row := Mess.pack(t)
	for i in Mess.POSE:
		p[sock * Mess.POSE + i] = row[i]
	return p


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock), "Sock %d to be picked" % sock)


## Picks the lower Sock of the station's heap by its tip, which sticks out from under the upper one.
func _pick_under() -> void:
	var under := _mess.pose_of(UNDER).origin
	var under_left := under.x - SockDress.box(_mess.design_of(UNDER)).x * 0.5
	var over_left := _mess.pose_of(OVER).origin.x - SockDress.box(_mess.design_of(OVER)).x * 0.5
	await _aim(_player, Vector3((under_left + over_left) * 0.5, 0.02, under.z))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(UNDER), "the lower Sock to be picked")


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
