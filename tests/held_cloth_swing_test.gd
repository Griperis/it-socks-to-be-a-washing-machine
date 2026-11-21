## The held Sock's cloth swing (core/36): the toe's swing after a quick turn of the view and after a walk
## start and stop, for candidate settings of drag, stiffness and gravity (the measurement the designer's pick
## rests on). Every case plays the handling station on a floor with the game's player, through the player's
## own input and view turn, as the zoo does.
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward", &"hands_next", &"hands_prev"]
const ON_FLOOR := 0
const CREW_DESIGN := 135
const FRONT := Vector3(0.0, 0.0, 1.5)
const TOE := 4
const LEG := 1
## The candidates (core/36 S1): label, drag, stiffness, gravity. The first is today's tuning.
const CANDIDATES: Array[Dictionary] = [
	{"label": "today", "drag": 1.0, "stiffness": 5.0, "gravity": 3.0},
	{"label": "d0.6", "drag": 0.6, "stiffness": 5.0, "gravity": 3.0},
	{"label": "d0.4", "drag": 0.4, "stiffness": 5.0, "gravity": 3.0},
	{"label": "d0.4s3", "drag": 0.4, "stiffness": 3.0, "gravity": 3.0},
	{"label": "d0.25s2g4", "drag": 0.25, "stiffness": 2.0, "gravity": 4.0},
	{"label": "d0.25s5", "drag": 0.25, "stiffness": 5.0, "gravity": 3.0},
	{"label": "d0.15s3", "drag": 0.15, "stiffness": 3.0, "gravity": 3.0},
	{"label": "d0.1s2", "drag": 0.1, "stiffness": 2.0, "gravity": 3.0},
	{"label": "d0.1s1g4", "drag": 0.1, "stiffness": 1.0, "gravity": 4.0},
]

var _level: Node3D = null
var _player: Player = null
var _hands: Hands = null
var _mess: Mess = null
var _toe: Array[Vector3] = []
var _rows: PackedStringArray = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "measure", "method": "case_measure", "world": false,
				"title": "core/36 S2: today's drag 1 never swings the held toe past its rest; a lower drag does, after a 90 degree turn in 0.15 s (a table of every candidate, turn and walk stop, is printed)"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_level()


func _free_level() -> void:
	if _level != null:
		_level.free()
		_level = null


func _tuning() -> SockClothTuning:
	return preload("res://game/sock/sock_cloth_tuning.tres") as SockClothTuning


func _build() -> void:
	_free_level()
	_level = Node3D.new()
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	(station.get_node("Spots/Floor") as SockSpot).design = CREW_DESIGN
	(station.get_node("Spots/MateFloor") as SockSpot).design = CREW_DESIGN
	_level.add_child(station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = FRONT
	_level.add_child(_player)
	_player.capture_mouse()
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	_mess = station.get_node("Socks/Mess") as Mess
	_hands = station.get_node("Socks/Hands") as Hands
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(ON_FLOOR) != null, "the player to stand and the Socks to lie")


## Aims at the Sock on the floor, picks it with the real action, waits until it is in the hand and still,
## turns the view to the open floor and starts recording the toe. Returns the held Looks.
func _pick_and_settle() -> Node3D:
	var head := _player.get_node("Head") as Node3D
	var target := _mess.looks_of(ON_FLOOR).global_position
	var to := target - _player.global_position
	_player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(ON_FLOOR), "the Sock to be picked")
	var view := _player.held_view()
	await _until(view.settled, "the fly-up to end")
	_player.rotation.y = PI
	head.rotation.x = deg_to_rad(-10.0)
	_player.reset_physics_interpolation()
	var held := view.looks_of(ON_FLOOR)
	var skeleton := held.find_child("Skeleton3D", true, false) as Skeleton3D
	skeleton.skeleton_updated.connect(func() -> void:
		_toe.append(skeleton.get_bone_global_pose(TOE).origin))
	await _physics_ticks(60)
	return held


## Plays `moves` (a Callable, awaited) and returns the toe's positions, one per drawn tick, from its start.
func _record(moves: Callable) -> Array[Vector3]:
	_toe.clear()
	await moves.call()
	return _toe.duplicate()


## The measurements of a toe series that starts at rest: the first peak (rad, as the angle about the
## Leg), the overshoot past rest after it (rad), the swings (crossings of rest, 10 percent of the
## peak apart), the time to settle (s, within 5 percent of the peak, counted from tick `from`).
func _swing(series: Array[Vector3], length: float, from: int) -> Dictionary:
	var rest := series[0]
	var axis := Vector3.ZERO
	var peak := 0.0
	var peak_i := 0
	for i in series.size():
		var d := series[i] - rest
		if d.length() > peak:
			peak = d.length()
			axis = d / peak
			peak_i = i
	if peak < 1e-5:
		return {"peak": 0.0, "over": 0.0, "swings": 0, "settle": 0.0}
	var over := 0.0
	var swings := 0
	var side := 1
	var last_big := 0
	for i in range(peak_i, series.size()):
		var s := (series[i] - rest).dot(axis)
		over = maxf(over, -s)
		if absf(s) > 0.1 * peak:
			var now := 1 if s > 0.0 else -1
			if now != side:
				swings += 1
				side = now
		if absf(s) > 0.05 * peak:
			last_big = i
	return {"peak": atan2(peak, length), "over": atan2(over, length), "swings": swings,
			"settle": maxf(last_big - from, 0) / 60.0}


func _chain_length(held: Node3D) -> float:
	var skeleton := held.find_child("Skeleton3D", true, false) as Skeleton3D
	return skeleton.get_bone_global_rest(TOE).origin.distance_to(skeleton.get_bone_global_rest(LEG).origin)


## A quick turn of the view: 90 degrees in 0.15 s, then still.
func _turn_moves() -> void:
	var tween := _player.create_tween()
	tween.tween_property(_player, ^"rotation:y", _player.rotation.y + PI / 2.0, 0.15)
	await _physics_ticks(120)


## A walk of 40 ticks, then standing.
func _walk_moves() -> void:
	Input.action_press(&"move_forward")
	await _physics_ticks(40)
	Input.action_release(&"move_forward")
	await _physics_ticks(80)


func case_measure() -> void:
	var tuning := _tuning()
	var keep := [tuning.drag, tuning.stiffness, tuning.gravity]
	var results: Dictionary = {}
	_rows.clear()
	# label | turn: peak deg, overshoot deg, swings, settle s | walk: peak, overshoot, swings, settle s after the stop")
	for c in CANDIDATES:
		tuning.drag = c["drag"]
		tuning.stiffness = c["stiffness"]
		tuning.gravity = c["gravity"]
		await _build()
		var held := await _pick_and_settle()
		var length := _chain_length(held)
		var turn := _swing(await _record(_turn_moves), length, 9)
		await _physics_ticks(30)
		var walk := _swing(await _record(_walk_moves), length, 40)
		results[c["label"]] = {"turn": turn, "walk": walk}
		_rows.append("%-10s | turn %5.1f %5.1f %d %4.2f | walk %5.1f %5.1f %d %4.2f" % [c["label"],
				rad_to_deg(turn["peak"]), rad_to_deg(turn["over"]), turn["swings"], turn["settle"],
				rad_to_deg(walk["peak"]), rad_to_deg(walk["over"]), walk["swings"], walk["settle"]])
	tuning.drag = keep[0]
	tuning.stiffness = keep[1]
	tuning.gravity = keep[2]
	_free_level()
	var f := FileAccess.open(OS.get_environment("CLOTH_TABLE") if OS.get_environment("CLOTH_TABLE") != "" else "user://cloth_table.txt", FileAccess.WRITE)
	f.store_string("\n".join(_rows) + "\n")
	f.close()
	var today: float = results["today"]["turn"]["over"]
	var low: float = results["d0.4"]["turn"]["over"]
	_check(today < 0.01, "today's drag 1 does not swing past rest (%.3f rad)" % today)
	_check(low > today + 0.01, "drag 0.4 swings past rest after the turn (%.3f rad)" % low)
