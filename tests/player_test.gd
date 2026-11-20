## The graybox player: it walks with the InputMap actions, jumps, its use button opens the thing it
## aims at through Parts. Its own small level, never the zoo. Its Hands are tests/handling_test.gd's.
extends TestSuite

const PLAYER := "res://game/player/player.tscn"
const CUPBOARD := "res://game/entities/cupboard/cupboard.tscn"
const STATION := "res://game/zoo/stations/movement.tscn"
const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"crouch", &"look_left", &"look_right", &"look_up", &"look_down", &"interact",
		&"pick", &"drop_throw", &"zoom", &"turn", &"hands_next", &"hands_prev"]

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "actions", "method": "case_actions", "world": false,
				"title": "every action the player reads is in the InputMap"},
		{"name": "walk", "method": "case_walk", "world": false,
				"title": "move_forward walks it the way it faces, move_right to its right, and it stops on release"},
		{"name": "blocked", "method": "case_blocked", "world": false,
				"title": "while a menu blocks its input it does not walk, and walks again after"},
		{"name": "jump", "method": "case_jump", "world": false,
				"title": "jump lifts it off the floor and it lands again"},
		{"name": "l01_look", "method": "case_l01_look", "world": false,
				"title": "L01: a mouse turn while captured turns the body and tilts the head, scaled, Invert Y flips the tilt, a free mouse does not turn"},
		{"name": "l02_tilt_limit", "method": "case_l02_tilt_limit", "world": false,
				"title": "L02: the tilt stops at 85 degrees either way"},
		{"name": "l03_capture", "method": "case_l03_capture", "world": false,
				"title": "L03: a click captures the mouse and Esc frees it"},
		{"name": "l04_camera", "method": "case_l04_camera", "world": false,
				"title": "L04: physics interpolation is on and a mouse turn shows in the camera on the next frame"},
		{"name": "l05_fov", "method": "case_l05_fov", "world": false,
				"title": "L05: the field of view is 75 degrees"},
		{"name": "p01_pad", "method": "case_p01_pad", "world": false,
				"title": "P01: the pad bindings are in the InputMap and the right stick turns the view"},
		{"name": "w01_walk", "method": "case_w01_walk", "world": false,
				"title": "W01: 4 m/s, a diagonal no faster, a stop at once, steering in the air"},
		{"name": "w02_wall", "method": "case_w02_wall", "world": false,
				"title": "W02: it stops at a wall and slides along it"},
		{"name": "w03_ramp", "method": "case_w03_ramp", "world": false,
				"title": "W03: on a ramp it keeps the floor's pace"},
		{"name": "w04_fall", "method": "case_w04_fall", "world": false,
				"title": "W04: off an edge it falls under gravity 20"},
		{"name": "j01_jump", "method": "case_j01_jump", "world": false,
				"title": "J01: jump leaves the floor at 5.5 m/s and peaks about 0.76 m"},
		{"name": "j02_no_double_no_crouch_jump", "method": "case_j02", "world": false,
				"title": "J02: no jump in the air or while crouched"},
		{"name": "c01_crouch", "method": "case_c01_crouch", "world": false,
				"title": "C01: crouch at once to 1.0 m, eyes 0.9 m, half pace; stands up at once"},
		{"name": "c02_stays_down_under_beam", "method": "case_c02", "world": false,
				"title": "C02: under a low beam it stays crouched after crouch is let go, and stands once clear"},
		{"name": "b01_body", "method": "case_b01_body", "world": false,
				"title": "B01: the body is a 0.35 m capsule 1.7 m tall, origin at the feet"},
		{"name": "b02_blocked", "method": "case_b02_blocked", "world": false,
				"title": "B02: blocked, look, jump and crouch are ignored too"},
		{"name": "real_path_station", "method": "case_station", "world": false,
				"title": "real path: in the movement station the real actions walk the ramp, jump onto the box, crouch under the beam"},
		{"name": "use", "method": "case_use", "world": false,
				"title": "interact opens the cupboard it faces, and again shuts it"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


func case_actions() -> void:
	for a in ACTIONS:
		_check(InputMap.has_action(a), "the InputMap has %s" % a)


func case_walk() -> void:
	var player := await _build()
	var start := player.global_position
	await _hold(&"move_forward", 30)
	_check(start.z - player.global_position.z > 0.5, "forward walks it towards -Z (%.2f m)" % (start.z - player.global_position.z))
	_near(player.global_position.x, start.x, 0.01, "and not sideways")
	var at := player.global_position
	await _hold(&"move_right", 30)
	_check(player.global_position.x - at.x > 0.5, "right walks it towards +X")
	at = player.global_position
	await _frames(5)
	_check(player.global_position.distance_to(at) < 0.01, "it stops when the key is up")


func case_blocked() -> void:
	var player := await _build()
	_check(player.is_in_group(&"local_input"), "it is in the group a menu tells")
	var start := player.global_position
	player.set_input_blocked(true)
	await _hold(&"move_forward", 20)
	_check(player.global_position.distance_to(start) < 0.01, "blocked, held move_forward moves it nowhere")
	player.set_input_blocked(false)
	await _hold(&"move_forward", 20)
	_check(start.z - player.global_position.z > 0.3, "unblocked, it walks again")


func case_jump() -> void:
	var player := await _build()
	var floor_y := player.global_position.y
	Input.action_press(&"jump")
	await _until(func() -> bool: return player.global_position.y > floor_y + 0.3, "it to rise")
	Input.action_release(&"jump")
	await _until(func() -> bool: return player.is_on_floor(), "it to land")


func case_use() -> void:
	var player := await _build(true)
	var openable := _level.get_node("Cupboard/Openable") as Openable
	await _hold(&"interact", 2)
	_check(openable.open, "interact opens the cupboard")
	await _frames(2)
	await _hold(&"interact", 2)
	_check(not openable.open, "interact again shuts it")
	_check(player.use_aimed() == openable, "the crosshair finds the cupboard's Openable")
	_check(Player.part_of(_level.get_child(0)) == null, "the floor belongs to no part")


func _mouse(player: Player, dx: float, dy: float) -> void:
	var ev := InputEventMouseMotion.new()
	ev.relative = Vector2(dx, dy)
	player._unhandled_input(ev)


func _click(player: Player) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)


func case_l01_look() -> void:
	var player := await _build()
	_mouse(player, 100, 50)
	_near(player.rotation.y, 0.0, 0.0001, "a free mouse does not turn the body")
	_click(player)
	_mouse(player, 100, 40)
	var head := player.get_node("Head") as Node3D
	_near(player.rotation.y, -0.25, 0.0001, "100 px right turns the body 0.25 rad to the right")
	_near(head.rotation.x, -0.1, 0.0001, "40 px down tilts the head down 0.1 rad")
	_near(head.rotation.z, 0.0, 0.0001, "only the head tilts")
	player.tuning.look_scale = 2.0
	_mouse(player, 0, -40)
	_near(head.rotation.x, 0.1, 0.0001, "scale 2 doubles the turn")
	player.tuning.look_scale = 1.0
	player.tuning.invert_y = true
	_mouse(player, 0, -40)
	_near(head.rotation.x, 0.0, 0.0001, "Invert Y flips the tilt")
	player.tuning.invert_y = false


func case_l02_tilt_limit() -> void:
	var player := await _build()
	_click(player)
	var head := player.get_node("Head") as Node3D
	_mouse(player, 0, -5000)
	_near(head.rotation.x, deg_to_rad(85.0), 0.0001, "up stops at 85 degrees")
	_mouse(player, 0, 10000)
	_near(head.rotation.x, -deg_to_rad(85.0), 0.0001, "down stops at 85 degrees")


func case_l03_capture() -> void:
	var player := await _build()
	_mouse(player, 100, 0)
	_near(player.rotation.y, 0.0, 0.0001, "free: no turn")
	_click(player)
	_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless", "a click captures the mouse")
	_mouse(player, 100, 0)
	_check(player.rotation.y < -0.1, "captured: it turns")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	player._unhandled_input(esc)
	var at := player.rotation.y
	_mouse(player, 100, 0)
	_near(player.rotation.y, at, 0.0001, "Esc frees it: no turn")


func case_l04_camera() -> void:
	_check(ProjectSettings.get_setting("physics/common/physics_interpolation", false) == true, "physics interpolation is on")
	var player := await _build()
	_click(player)
	var camera := player.get_node("Head/Camera") as Camera3D
	_check(camera.top_level, "the camera is top-level")
	_check(camera.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "its own interpolation is off")
	_mouse(player, 200, 0)
	await _frames(1)
	var forward := -camera.global_basis.z
	_near(forward.x, sin(0.5), 0.01, "the camera shows the turn on the next frame")


func case_l05_fov() -> void:
	var player := await _build()
	_near((player.get_node("Head/Camera") as Camera3D).fov, 75.0, 0.001, "fov is 75")


func case_p01_pad() -> void:
	var player := await _build()
	for pair: Array in [[&"look_left", "InputEventJoypadMotion"], [&"look_right", "InputEventJoypadMotion"], [&"look_up", "InputEventJoypadMotion"],
			[&"look_down", "InputEventJoypadMotion"], [&"crouch", "InputEventJoypadMotion"], [&"move_forward", "InputEventJoypadMotion"],
			[&"jump", "InputEventJoypadButton"]]:
		var found := false
		for e in InputMap.action_get_events(pair[0]):
			found = found or e.get_class() == pair[1]
		_check(found, "%s has a pad binding" % pair[0])
	var jump_buttons: Array[int] = []
	for e in InputMap.action_get_events(&"jump"):
		if e is InputEventJoypadButton:
			jump_buttons.append((e as InputEventJoypadButton).button_index)
	_check(2 in jump_buttons, "jump has the pad's X")
	var yaw := player.rotation.y
	Input.action_press(&"look_right", 1.0)
	await _frames(10)
	Input.action_release(&"look_right")
	_check(player.rotation.y < yaw - 0.05, "the right stick turns the view right")


func case_w01_walk() -> void:
	var player := await _build()
	await _physics_ticks(5)
	var start := player.global_position
	Input.action_press(&"move_forward")
	await _physics_ticks(30)
	_near(Vector2(player.velocity.x, player.velocity.z).length(), 4.0, 0.01, "speed is 4 m/s at once")
	Input.action_press(&"move_right")
	await _physics_ticks(5)
	_near(Vector2(player.velocity.x, player.velocity.z).length(), 4.0, 0.01, "a diagonal is no faster")
	Input.action_release(&"move_forward")
	Input.action_release(&"move_right")
	await _physics_ticks(1)
	_near(Vector2(player.velocity.x, player.velocity.z).length(), 0.0, 0.001, "it stops at once")
	_check(start.distance_to(player.global_position) > 2.0, "it moved")
	Input.action_press(&"jump")
	await _physics_ticks(2)
	Input.action_release(&"jump")
	Input.action_press(&"move_forward")
	await _physics_ticks(3)
	_check(not player.is_on_floor(), "in the air")
	_near(-player.velocity.z, 4.0, 0.01, "steering goes on in the air")
	Input.action_release(&"move_forward")


func case_w02_wall() -> void:
	var player := await _build()
	_add_box(Vector3(0, 1, -3), Vector3(6, 2, 0.2))
	await _physics_ticks(2)
	Input.action_press(&"move_forward")
	await _physics_ticks(120)
	_check(player.global_position.z > -3.0 + 0.1 + 0.35 - 0.05, "it stops at the wall (z %.2f)" % player.global_position.z)
	player.rotation.y = -PI / 4.0
	var x := player.global_position.x
	await _physics_ticks(30)
	_check(absf(player.global_position.x - x) > 1.0, "turned, it slides along the wall")
	_check(player.global_position.z > -3.0, "and never through")
	Input.action_release(&"move_forward")


func case_w03_ramp() -> void:
	var player := await _build()
	_ramp()
	player.global_position = Vector3(0, 0, -3.5)
	player.rotation.y = PI
	await _physics_ticks(5)
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.y > 0.5 and player.is_on_floor(), "it to climb the ramp")
	_near(player.get_real_velocity().length(), 4.0, 0.2, "on the ramp it keeps the floor's pace")
	Input.action_release(&"move_forward")


func case_w04_fall() -> void:
	var player := await _build()
	player.global_position = Vector3(30, 5, 30)
	await _physics_ticks(30)
	_near(player.velocity.y, -20.0 * 0.5, 1.0, "after 0.5 s it falls at 10 m/s (gravity 20)")


func case_j01_jump() -> void:
	var player := await _build()
	await _physics_ticks(2)
	var floor_y := player.global_position.y
	Input.action_press(&"jump")
	await _physics_ticks(1)
	Input.action_release(&"jump")
	await _physics_ticks(1)
	_check(player.velocity.y > 5.0, "it leaves at 5.5 m/s (%.2f)" % player.velocity.y)
	var peak := floor_y
	for _i in 60:
		await _physics_ticks(1)
		peak = maxf(peak, player.global_position.y)
	_near(peak - floor_y, 0.756, 0.05, "it peaks about 0.76 m")
	_check(player.is_on_floor(), "and lands")


func case_j02() -> void:
	var player := await _build()
	await _physics_ticks(2)
	Input.action_press(&"jump")
	await _physics_ticks(1)
	Input.action_release(&"jump")
	await _physics_ticks(10)
	var vy := player.velocity.y
	Input.action_press(&"jump")
	await _physics_ticks(1)
	Input.action_release(&"jump")
	_check(player.velocity.y < vy, "no second jump in the air")
	await _until(func() -> bool: return player.is_on_floor(), "it to land")
	Input.action_press(&"crouch")
	await _physics_ticks(2)
	Input.action_press(&"jump")
	await _physics_ticks(2)
	_check(player.is_on_floor() and player.velocity.y <= 0.0, "no jump while crouched")
	Input.action_release(&"jump")
	Input.action_release(&"crouch")


func case_c01_crouch() -> void:
	var player := await _build()
	await _physics_ticks(2)
	var head := player.get_node("Head") as Node3D
	_near(head.position.y, 1.6, 0.001, "standing eyes are at 1.6 m")
	Input.action_press(&"crouch")
	await _physics_ticks(1)
	_check(player.crouching, "crouching at once")
	_near(((player.get_node("Shape") as CollisionShape3D).shape as CapsuleShape3D).height, 1.0, 0.001, "1.0 m tall")
	_near(head.position.y, 0.9, 0.001, "eyes at 0.9 m")
	Input.action_press(&"move_forward")
	await _physics_ticks(5)
	_near(Vector2(player.velocity.x, player.velocity.z).length(), 2.0, 0.01, "half pace")
	Input.action_release(&"move_forward")
	Input.action_release(&"crouch")
	await _physics_ticks(1)
	_check(not player.crouching, "stands up at once")
	_near(head.position.y, 1.6, 0.001, "eyes back at 1.6 m")


func case_c02() -> void:
	var player := await _build()
	await _physics_ticks(2)
	Input.action_press(&"crouch")
	await _physics_ticks(2)
	_add_box(Vector3(0, 1.4, -3), Vector3(4, 0.2, 4))
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.z < -2.0, "it to get under the beam")
	Input.action_release(&"move_forward")
	Input.action_release(&"crouch")
	await _physics_ticks(5)
	_check(player.crouching, "under the beam it stays crouched")
	Input.action_press(&"move_back")
	await _until(func() -> bool: return player.global_position.z > 0.0, "it to walk out")
	Input.action_release(&"move_back")
	await _physics_ticks(3)
	_check(not player.crouching, "clear of the beam it stands")


func case_b01_body() -> void:
	var player := await _build()
	var shape := player.get_node("Shape") as CollisionShape3D
	var capsule := shape.shape as CapsuleShape3D
	_near(capsule.radius, 0.35, 0.001, "radius 0.35")
	_near(capsule.height, 1.7, 0.001, "1.7 m tall")
	_near(shape.position.y - capsule.height * 0.5, 0.0, 0.001, "origin at the feet")


func case_b02_blocked() -> void:
	var player := await _build()
	await _physics_ticks(2)
	player.set_input_blocked(true)
	Input.action_press(&"crouch")
	Input.action_press(&"jump")
	Input.action_press(&"look_right", 1.0)
	await _frames(10)
	_check(not player.crouching and player.is_on_floor(), "no crouch, no jump")
	_near(player.rotation.y, 0.0, 0.0001, "no stick look")
	Input.action_release(&"look_right")
	Input.action_release(&"jump")
	Input.action_release(&"crouch")
	player.set_input_blocked(false)


func case_station() -> void:
	var player := await _build(false, true)
	# walk the ramp onto the ledge, facing +Z
	player.global_position = Vector3(-1, 0, -3.5)
	player.rotation.y = PI
	await _physics_ticks(3)
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.y > 0.9 and player.is_on_floor(), "it to walk the ramp onto the ledge")
	Input.action_release(&"move_forward")
	# jump onto the box
	player.global_position = Vector3(2, 0, 4.5)
	player.rotation.y = 0.0
	await _physics_ticks(5)
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.z < 3.4, "it to reach the box")
	Input.action_press(&"jump")
	await _physics_ticks(12)
	Input.action_release(&"move_forward")
	await _until(func() -> bool: return player.global_position.y > 0.45 and player.is_on_floor(), "it to land on the box")
	Input.action_release(&"jump")
	# crouch under the beam
	player.global_position = Vector3(3.5, 0, 3)
	await _physics_ticks(5)
	Input.action_press(&"crouch")
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.z < 0.0, "it to get under the beam")
	Input.action_release(&"move_forward")
	Input.action_release(&"crouch")
	await _physics_ticks(5)
	_check(player.crouching, "under the beam it stays down")


func _add_box(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	_level.add_child(body)


## A 15 degree ramp rising towards +Z, 4 m long, centred on the origin.
func _ramp() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 0.2, 4)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0, 0.42, 0)
	body.rotation.x = deg_to_rad(-15.0)
	_level.add_child(body)


# --- Helpers -------------------------------------------------------------------------------------

## A floor, a Parts, the player at the origin facing -Z, and with `cupboard` one 1.5 m ahead
## facing it. Returns the player once it stands.
func _build(cupboard := false, station := false) -> Player:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	if cupboard:
		var c := (load(CUPBOARD) as PackedScene).instantiate() as Node3D
		c.name = "Cupboard"
		c.position = Vector3(0.0, 0.0, -1.5)
		_level.add_child(c)
	if station:
		var st := (load(STATION) as PackedScene).instantiate() as Node3D
		st.name = "Station"
		_level.add_child(st)
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	_level.add_child(player)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	return player


func _hold(action: StringName, frames: int) -> void:
	Input.action_press(action)
	await _frames(frames)
	Input.action_release(action)
