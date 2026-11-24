## core/41 played alone: the zoo with its Stacking station, the game's player a Host of one, and the
## station's stand-in Teammates (peers 7 and 8), moved only as a real Teammate's pose moves them. Lines are
## the numbered lines of docs/migration/m3-lists/01-player-stacking.md. The co-op cases are
## coop_stacking_test.gd. Look and feel numbers get no case (Q2421): the station shows them.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Stacking"]
const STATION := "Stations/Stacking"
const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"crouch"]
## How close a height must be to count as "at" it (m).
const AT := 0.05

var _holder: Node = null
var _zoo: Node3D = null
## Every sound played: [name, spatial].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "climb_ride_real_path", "method": "case_climb_ride_real_path", "world": false,
				"title": "real path alone (lines 12-17, 20-23, 30, 33, 35): the pressed jump within 0.9 m of the stand-in's back climbs: fast enough to clear it by 0.15 m, tucked at once; the player lands on the disc (feet at its top) and rides it, crouched; the stand-in walks its loop and the player goes with it, no step heard while carried; it crouches and the rider goes down with the back; walking forward the rider walks off the edge, falls and lands with the land sound, and stands again"},
		{"name": "walk_on_from_ledge", "method": "case_walk_on_from_ledge", "world": false,
				"title": "lines 9, 20: walking off a surface as high as the back onto it, the player stands on the disc and rides"},
		{"name": "no_room", "method": "case_no_room", "world": false,
				"title": "line 13c: next to the stand-in under the low board (no room for a crouched body) the jump is an ordinary one: 5.5 m/s, no tuck, no ride"},
		{"name": "back", "method": "case_back", "world": false,
				"title": "lines 1-3, 8, 10, 12-13: the back is a disc 0.3 m round, 0.1 m thick, on BACK (mask 0), 1.4 m over the feet standing and 0.7 m crouched at once; the player passes through it from below, walks into the stand-in (no wall); an ordinary jump never climbs where the back is lower than half a jump"},
		{"name": "knocked_drops", "method": "case_knocked_drops", "world": false,
				"title": "lines 4, 32: a carrier knocked down holds no one: the rider falls off and slips off the lying body"},
		{"name": "push", "method": "case_push", "world": false,
				"title": "lines 45, 46, 48: a Teammate nearer than 0.6 m pushes the player away at (0.6 - gap) * 8 m/s; exactly on each other the lower id goes right; at different heights no push"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _holder != null:
		_holder.free()
		_holder = null
	_heard.clear()


func _on_played(sound: StringName, spatial: bool, _at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial])


# --- The cases -----------------------------------------------------------------------------------

func case_climb_ride_real_path() -> void:
	await _build()
	var player := _player()
	var carrier := _carrier()
	var t := player.stack().tuning
	var back := carrier.back
	await _stand_facing(back.top() * Vector3(1, 0, 1) + _local(Vector3(0.0, 0.0, 0.7)), back.top())
	var feet := player.global_position.y
	var top := back.top().y
	await _press_jump()
	var want := sqrt(2.0 * player.tuning.gravity * (top - feet + t.climb_clear))
	_near(player.velocity.y, want, 0.25, "the climb leaves fast enough to clear the back by %.2f m (%.2f m/s)" % [t.climb_clear, want])
	_check(player.crouching, "it tucks into a crouch at once")
	_check(player.jumps == 1, "a climb is a jump: it plays jump (Q2593)")
	_check(player.stack().climb_to == back, "it steers onto the stand-in's back")
	var peak := [feet]
	await _until(func() -> bool:
		peak[0] = maxf(peak[0], player.global_position.y)
		return player.riding(), "the climber to stand on the back")
	_check(peak[0] >= top + t.climb_clear - 0.1, "the climb cleared the back (%.2f over a top at %.2f)" % [peak[0], top])
	_near(player.global_position.y, back.top().y, AT, "its feet are at the back's top")
	_check(player.stack().climb_to == null, "the steering ends on landing")
	_check(player.crouching, "a rider stays crouched")
	# The stand-in walks its loop while ridden; the rider goes with it.
	_heard.clear()
	var start := player.global_position
	await _until(func() -> bool: return player.global_position.distance_to(start) > 1.5, "the rider to be carried 1.5 m")
	_check(player.riding(), "it still rides")
	var off := player.global_position - back.top()
	_check(Vector2(off.x, off.z).length() < t.back_radius + player.tuning.radius, "it stays on the disc (%.2f m off its middle)" % Vector2(off.x, off.z).length())
	_check(not _heard_any("step_"), "no step is heard while carried standing still")
	await _until(func() -> bool: return carrier.pose_crouch == 1.0, "the stand-in to crouch")
	await _until(func() -> bool: return absf(player.global_position.y - Stacks.feet(carrier).y - 0.7) < AT, "the rider to go down with the crouched back", 60)
	_check(player.riding(), "it keeps its hold on the crouched back")
	await _until(func() -> bool: return carrier.pose_crouch == 0.0, "the stand-in to stand")
	await _until(func() -> bool: return absf(player.global_position.y - Stacks.feet(carrier).y - 1.4) < AT, "the rider to rise with the back", 60)
	# Walking off the edge.
	_heard.clear()
	Input.action_press(Player.MOVE_FORWARD)
	await _until(func() -> bool: return not player.riding() and not player.is_on_floor(), "the rider to walk off the edge")
	await _until(func() -> bool: return player.is_on_floor(), "it to land")
	Input.action_release(Player.MOVE_FORWARD)
	_check(_heard_any("land"), "it lands with the land sound")
	_near(player.global_position.y, 0.0, AT, "on the floor")
	await _until(func() -> bool: return not player.crouching, "it to stand up off the back", 30)


func case_walk_on_from_ledge() -> void:
	await _build()
	var player := _player()
	var back := _carrier().back
	var ledge := _zoo.get_node(STATION + "/Ledge") as Node3D
	var on_ledge := ledge.global_position + Vector3(0.0, 0.7, 0.0)
	await _stand_facing(on_ledge, Vector3(back.top().x, on_ledge.y, back.top().z))
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand on the ledge")
	_near(player.global_position.y, back.top().y, AT, "the ledge is as high as the back")
	Input.action_press(Player.MOVE_FORWARD)
	await _until(func() -> bool: return player.riding(), "the player to walk onto the back", 120)
	Input.action_release(Player.MOVE_FORWARD)
	_check(player.stack().ride == back, "it rides the stand-in's back")
	_near(player.global_position.y, back.top().y, AT, "its feet are at the back's top")


func case_no_room() -> void:
	await _build()
	var player := _player()
	var still := _zoo.get_node(STATION + "/Teammates/8") as Avatar
	var back := still.back
	_check(not player.stack().room_over(back.top()), "there is no room for a crouched body under the low board")
	await _stand_facing(back.top() * Vector3(1, 0, 1) + _local(Vector3(0.0, 0.0, -0.7)), back.top())
	await _press_jump()
	_near(player.velocity.y, player.tuning.jump_speed, 0.25, "an ordinary jump")
	_check(not player.crouching and player.stack().climb_to == null, "no tuck, no steering")
	await _until(func() -> bool: return player.is_on_floor() and player.velocity.y <= 0.0, "it to land")
	_check(not player.riding(), "it rides no one")


func case_back() -> void:
	await _build()
	var player := _player()
	var carrier := _carrier()
	var back := carrier.back
	var t := back.tuning
	var disc := (back.get_node("Shape") as CollisionShape3D).shape as CylinderShape3D
	_near(disc.radius, 0.3, 0.001, "the disc is 0.3 m round")
	_near(disc.height, 0.1, 0.001, "and 0.1 m thick")
	_check(back.collision_layer == Back.LAYER and back.collision_mask == 0, "it is on BACK and meets nothing itself")
	_check(player.collision_mask & Back.LAYER != 0, "the player's body meets BACK")
	_check(Mess.AIM_MASK & Back.LAYER == 0, "the crosshair and Throws pass it (line 51)")
	_near(back.top().y - Stacks.feet(carrier).y, 1.4, 0.001, "standing, 1.4 m over the feet")
	var still := _zoo.get_node(STATION + "/Teammates/8") as Avatar
	still.pose_crouch = 1.0
	await _physics_ticks(2)
	_near(still.back.top().y - Stacks.feet(still).y, 0.7, 0.001, "crouched, 0.7 m, at once")
	_check(still.back.holds(), "a crouched back holds")
	still.pose_crouch = 0.0
	# Line 13b: from the ledge, as high as the back, a jump within reach is an ordinary one.
	var ledge := _zoo.get_node(STATION + "/Ledge") as Node3D
	await _stand_facing(back.top() * Vector3(1, 0, 1) + _local(Vector3(-0.8, 0.0, 0.0)) + Vector3.UP * (ledge.global_position.y + 0.7), back.top())
	await _press_jump()
	_near(player.velocity.y, player.tuning.jump_speed, 0.25, "a back no higher than half a jump over the feet is no climb")
	_check(player.stack().climb_to == null and not player.crouching, "no tuck, no steering")
	await _until(func() -> bool: return player.is_on_floor() and player.velocity.y <= 0.0, "it to land")
	# From the floor the body passes through the back (no wall at the disc, 0.65 m out): only the soft
	# push holds it, nearer than 0.6 m (line 10).
	await _stand_facing(back.top() * Vector3(1, 0, 1) + _local(Vector3(0.0, 0.0, 1.2)), back.top() * Vector3(1, 0, 1))
	Input.action_press(Player.MOVE_FORWARD)
	await _physics_ticks(60)
	Input.action_release(Player.MOVE_FORWARD)
	var d := player.global_position - Stacks.feet(carrier)
	_check(Vector2(d.x, d.z).length() < 0.4, "walking into the stand-in it comes within 0.4 m (%.2f): no wall" % Vector2(d.x, d.z).length())
	_check(player.global_position.y < 0.05 and not player.riding(), "it stays on the floor, under the back")
	_check(t.max_high == 3, "three high at most (line 6)")


func case_knocked_drops() -> void:
	await _build()
	var player := _player()
	var carrier := _carrier()
	var back := carrier.back
	await _ride(back)
	var at := Stacks.feet(carrier)
	_parts().ask(Command.new(Knockdowns.KNOCK, Parts.HOST, _kd().id, {"target": 7, "thrower": 1,
			"push": Vector3(0.0, 0.0, -1.0), "high": 0.8, "side": 0.0, "at": at + Vector3.UP * 1.3}))
	await _until(func() -> bool: return carrier.is_down(), "the carrier to be knocked down")
	await _physics_ticks(1)
	_check(not back.holds(), "a knocked-down back holds no one")
	await _until(func() -> bool: return not player.riding(), "the rider to fall off", 30)
	await _until(func() -> bool: return player.is_on_floor() and player.global_position.y < 0.3, "the rider to reach the floor")
	_check(Vector2(player.global_position.x - at.x, player.global_position.z - at.z).length() > 0.2, "it slid off the lying body")


func case_push() -> void:
	await _build()
	var player := _player()
	var carrier := _carrier()
	var t := player.stack().tuning
	var feet := Stacks.feet(carrier)
	await _stand_facing(feet + _local(Vector3(0.0, 0.0, 0.4)), feet + _local(Vector3(0.0, 0.0, 2.0)))
	player.global_position = feet + _local(Vector3(0.0, 0.0, 0.4))
	player.stack().before_move()
	var push := player.stack().push()
	_near(push.length(), (t.push_apart - 0.4) * t.push_rate, 0.01, "0.2 m too near pushes at 1.6 m/s")
	_check(push.normalized().dot(_local(Vector3.BACK)) > 0.99, "away from the Teammate")
	player.global_position = feet + _local(Vector3(0.0, 0.0, 0.0005))
	player.stack().before_move()
	push = player.stack().push()
	_check(push.normalized().dot(Vector3.RIGHT) > 0.99, "exactly on each other, the lower id (1 under 7) goes right (%s)" % push)
	player.global_position = feet + _local(Vector3(0.0, 0.6, 0.2))
	player.stack().before_move()
	_check(player.stack().push() == Vector3.ZERO, "half a crouch higher: no push")
	# By input: standing in the Teammate, the player is pushed out to 0.6 m.
	await _stand_facing(feet + _local(Vector3(0.0, 0.0, 0.3)), feet + _local(Vector3(0.0, 0.0, 2.0)))
	await _until(func() -> bool:
		var d := player.global_position - Stacks.feet(carrier)
		return Vector2(d.x, d.z).length() > t.push_apart - 0.02, "the push to move the player out to 0.6 m", 120)


# --- Helpers ---------------------------------------------------------------------------------------

func _build() -> void:
	_holder = Node.new()
	_holder.name = "Alone"
	add_child(_holder)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder.add_child(_zoo)
	await _until(func() -> bool: return _player().is_on_floor() and _carrier() != null and _carrier().back != null,
			"the zoo to stand")


## Presses the jump and lets go once the body leaves the floor (its velocity is the jump's then).
func _press_jump() -> void:
	var player := _player()
	Input.action_press(Player.JUMP)
	await _until(func() -> bool: return player.velocity.y > 0.1, "the jump to leave the floor", 10)
	Input.action_release(Player.JUMP)


## Puts the player on `back` by the climb.
func _ride(back: Back) -> void:
	await _stand_facing(back.top() * Vector3(1, 0, 1) + _local(Vector3(0.0, 0.0, 0.7)), back.top())
	await _press_jump()
	await _until(func() -> bool: return _player().riding(), "the player to climb onto the back")


func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	player.reset_physics_interpolation()
	await _physics_ticks(2)
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand", 60)


## Whether this player's own sound (not a Teammate's, in the world) starting with `prefix` played.
func _heard_any(prefix: String) -> bool:
	for e: Array in _heard:
		if String(e[0]).begins_with(prefix) and not e[1]:
			return true
	return false


## `v` in the station's own axes (it stands turned in the zoo).
func _local(v: Vector3) -> Vector3:
	return (_zoo.get_node(STATION) as Node3D).global_basis * v


func _carrier() -> Avatar:
	return _zoo.get_node_or_null(STATION + "/Teammates/7") as Avatar


func _kd() -> Knockdowns:
	return LevelRuntime.of(_zoo).knockdowns


func _parts() -> Parts:
	return LevelRuntime.of(_zoo).parts


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
