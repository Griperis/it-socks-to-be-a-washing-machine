## The graybox player: it walks with the InputMap actions, jumps, its use button opens the thing it
## aims at through Parts, and it carries a crate and puts it down. Its own small level, never the zoo.
extends TestSuite

const PLAYER := "res://game/zoo/player/player.tscn"
const CUPBOARD := "res://game/entities/cupboard/cupboard.tscn"
const CRATE := "res://game/entities/crate/crate.tscn"
const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"interact"]

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
		{"name": "use", "method": "case_use", "world": false,
				"title": "interact opens the cupboard it faces, and again shuts it"},
		{"name": "carry", "method": "case_carry", "world": false,
				"title": "interact picks up the crate it looks at, walking carries it in the hands, interact puts it down on the floor"},
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
	_check(GrayboxPlayer.part_of(_level.get_child(0)) == null, "the floor belongs to no part")


func case_carry() -> void:
	var player := await _build(false, true)
	var crate := _level.get_node("Crate") as Node3D
	var carriable := crate.get_node("Carriable") as Carriable
	(player.get_node("Head") as Node3D).rotation.x = -0.73
	_check(player.interact() == carriable and player.carried() == carriable, "interact picks up the crate it looks at")
	await _hold(&"move_forward", 20)
	await _frames(1)
	_check(crate.global_position.distance_to(player.global_transform * GrayboxPlayer.HANDS) < 0.01,
			"the crate is in its hands after a walk (%s)" % crate.global_position)
	var carried_at := crate.global_position
	_check(player.interact() == carriable and carriable.holder == 0, "interact again puts it down")
	_near(crate.global_position.y, player.global_position.y, 0.01, "it lies on the floor")
	_check(Vector2(crate.global_position.x, crate.global_position.z).distance_to(Vector2(carried_at.x, carried_at.z)) < 0.01,
			"under where the hands held it")
	await _frames(3)
	_check(crate.global_position.y < 0.01, "and stays there: the hands let go")


# --- Helpers -------------------------------------------------------------------------------------

## A floor, a Parts, the player at the origin facing -Z, and with `cupboard` one 1.5 m ahead
## facing it (with `crate`, a crate there). Returns the player once it stands.
func _build(cupboard := false, crate := false) -> GrayboxPlayer:
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
	if crate:
		var thing := (load(CRATE) as PackedScene).instantiate() as Node3D
		thing.name = "Crate"
		thing.position = Vector3(0.0, 0.0, -1.5)
		_level.add_child(thing)
	var player := (load(PLAYER) as PackedScene).instantiate() as GrayboxPlayer
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
