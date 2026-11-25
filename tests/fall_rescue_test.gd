## Anyone out of the map is put back (core/110): a body below the level's lowest floor, far away or not finite is
## stood at the washer's spawn (the level's Spawn without a washer) by its own machine and can move on; a body
## anywhere in the house is never caught.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const ZOO := "res://game/zoo/zoo.tscn"

var _holder: Node = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the house the body put at y = -500 stands at a washer spawn within a second and walks on; a far one and an absurd depth the same (a NaN position is judged as a value: the engine logs its own errors if a body is really put there); a warning is logged"},
		{"name": "never_inside", "method": "case_never_inside", "world": false,
				"title": "a body at every corner of the house's volume, or mid-jump, is never caught; the test is exact at the margins"},
		{"name": "zoo", "method": "case_zoo", "world": false,
				"title": "the zoo (its Laundry station has a washer) puts a body back at the respawn point"},
	]


func _before_case() -> void:
	if _holder != null:
		_holder.free()
		_holder = null


func _up(path: String) -> LevelRuntime:
	_holder = Node.new()
	add_child(_holder)
	var level := (load(path) as PackedScene).instantiate() as Node3D
	_holder.add_child(level)
	var rt := LevelRuntime.of(level)
	await _until(func() -> bool: return rt.loading.is_lifted() and rt.player.is_on_floor(), "the player to stand", 3000, 20.0)
	return rt


func _spawn_near(rt: LevelRuntime) -> bool:
	var spawns := Washer.of_level(rt).get_parent().get_node("Spawns")
	for m: Node in spawns.get_children():
		var d := (m as Node3D).global_position - rt.player.global_position
		if Vector2(d.x, d.z).length() < 0.5 and absf(d.y) < 1.0:
			return true
	return false


func case_real_path() -> void:
	var rt := await _up(HOUSE)
	var player := rt.player
	player.capture_mouse()
	for lost: Vector3 in [Vector3(1.0, -500.0, 1.0), Vector3(5000.0, 1.0, 0.0), Vector3(1.0, -1.0e9, 1.0)]:
		player.global_position = lost
		player.velocity = Vector3.ZERO
		await _until(func() -> bool: return _spawn_near(rt), "the player to be put back from %s" % lost, 90)
		if lost.y == -500.0:
			await _until(func() -> bool: return player.is_on_floor(), "the player to stand again", 300)
			var before := player.global_position
			Input.action_press(&"move_forward")
			await _physics_ticks(10)
			Input.action_release(&"move_forward")
			_check(before.distance_to(player.global_position) > 0.1, "the player walks on")
		_check(Log.recent(40).any(func(l: String) -> bool: return l.contains("out of the map")), "the catch is logged")


func case_never_inside() -> void:
	var rt := await _up(HOUSE)
	var frame := rt.map_frame()
	var box := rt.global_transform * rt.mess_bounds
	_check(box.has_volume(), "the house has a volume")
	for i in 8:
		var corner := box.get_endpoint(i)
		_check(not FallRescue.out_of_map(corner, frame["floor"], frame["centre"], rt.player.tuning.fall_depth, rt.player.tuning.fall_reach), "corner %d is inside" % i)
	var floor_y: float = frame["floor"]
	_check(FallRescue.out_of_map(Vector3(NAN, 1.0, 1.0), floor_y, frame["centre"], 50.0, 1000.0), "NaN is out")
	_check(FallRescue.out_of_map(Vector3(1.0, INF, 1.0), floor_y, frame["centre"], 50.0, 1000.0), "inf is out")
	var c: Vector3 = frame["centre"]
	_check(not FallRescue.out_of_map(Vector3(c.x, floor_y - 49.9, c.z), floor_y, c, 50.0, 1000.0), "49.9 m below is inside")
	_check(FallRescue.out_of_map(Vector3(c.x, floor_y - 50.1, c.z), floor_y, c, 50.0, 1000.0), "50.1 m below is out")
	_check(FallRescue.out_of_map(c + Vector3(1000.1, 0, 0), floor_y, c, 50.0, 1000.0), "1000.1 m east is out")
	_check(FallRescue.out_of_map(c + Vector3(0, 0, -1000.1), floor_y, c, 50.0, 1000.0), "1000.1 m north is out")
	var player := rt.player
	var spot := player.global_position
	player.velocity.y = player.tuning.jump_speed
	await _physics_ticks(30)
	_check(Vector2(player.global_position.x - spot.x, player.global_position.z - spot.z).length() < 0.5, "a jump is not caught")


func case_zoo() -> void:
	var rt := await _up(ZOO)
	var at: Variant = rt.respawn_point()
	_check(at != null, "the zoo has a place to put a body back")
	rt.player.global_position = Vector3(0.0, -900.0, 0.0)
	await _until(func() -> bool: return rt.player.global_position.y > -10.0, "the player to be put back", 90)
	_check(rt.player.global_position.distance_to((at as Transform3D).origin) < 0.5, "at the respawn point")

