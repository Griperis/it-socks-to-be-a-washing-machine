## How a flight starts and settles (core/23): Socks never flip, spin up or jump without a cause (T01),
## a Throw's and a drop's body leaves from the hand (T02, T05, Q2356, Q2367) and lands where the
## player aimed (T03), never through a wall (T04). Most cases play the handling station
## (game/zoo/stations/handling.tscn) on a floor with the game's player and a Parts (a Host of one);
## the heap's and the every-Sock station's play the zoo.
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
## The station's Sock on the floor.
const ON_FLOOR := 0
const FRONT := Vector3(0.0, 0.0, 1.5)
## T01's limits, per physics tick: a body turns at most this much (a flip a frame is 45 degrees and
## more), and where a Sock's drawing passes from one tier to the other it moves and turns no more than this.
const MOST_TURN := 36.0
const SWITCH_MOVE := 0.002
const SWITCH_TURN := 1.0
## How near the aimed point a thrown or dropped Sock first lands (a Sock's half length and a bit).
const LANDS_NEAR := 0.2

var _level: Node3D = null
var _zoo: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
## T01's watch: each Sock's last drawn pose and tier ("body" or "lying"), and what broke the limits.
var _last: Dictionary[int, Array] = {}
var _faults: Array[String] = []
var _worst_turn := 0.0


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path_throw", "method": "case_real_path_throw", "world": false,
				"title": "T02, real path: the player throws with the real button and the body's first positions lie on the line from the hand to the aimed point, moving away from the hand"},
		{"name": "real_path_drop", "method": "case_real_path_drop", "world": false,
				"title": "T05, real path: the player drops with the real button; the body is let go at the hand at once (no flick, no hold over the spot) and lands on the aimed spot"},
		{"name": "t01_throw_drop", "method": "case_t01_hand", "world": false,
				"title": "T01: a thrown and a dropped Sock never turn more than 36 degrees a tick, and nothing moves where it comes to rest"},
		{"name": "t01_heap", "method": "case_t01_heap", "world": false,
				"title": "T01: in the heap's pour no Sock turns more than 36 degrees a tick, none bounces back up, and none moves where it starts or rests"},
		{"name": "t01_every_sock", "method": "case_t01_every", "world": false,
				"title": "T01: at the every-Sock station's start nothing moves"},
		{"name": "t03_lands", "method": "case_t03", "world": false,
				"title": "T03: the lob, a half and a full charge land where the crosshair was (within 0.2 m); an aim out of reach flies along the aim as before"},
		{"name": "t04_wall", "method": "case_t04", "world": false,
				"title": "T04: with the hand inside or behind a wall, a Throw and a drop leave from the eye-line's clear point; nothing passes through the wall"},
	]


func _before_case() -> void:
	for a: StringName in [&"pick", &"drop_throw"]:
		Input.action_release(a)
	for node: Node3D in [_level, _zoo]:
		if node != null:
			node.free()
	_level = null
	_zoo = null
	_last.clear()
	_faults.clear()
	_worst_turn = 0.0


# --- The real paths ------------------------------------------------------------------------------

func case_real_path_throw() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var target := FRONT + Vector3(0.4, 0.0, 2.2)
	await _aim(_player, target)
	var hand := _hands.hand_of(1, _player.aim_dir())
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging and _player.charge >= 0.5, "the ring to fill halfway", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the Sock to fly", 5)
	var body := _mess.flight_of(ON_FLOOR)
	var first: Array[Vector3] = [body.global_position]
	_check(first[0].distance_to(hand.origin) < 0.01, "the body leaves from the hand (%.3f m off it)" % first[0].distance_to(hand.origin))
	for i in 3:
		await _physics_ticks(1)
		first.append(body.global_position)
	var line := (target - hand.origin).normalized()
	var flat := Vector3(line.x, 0.0, line.z).normalized()
	for i in range(1, first.size()):
		var off := first[i] - hand.origin
		var aside := absf(off.dot(flat.cross(Vector3.UP).normalized()))
		_check(aside < 0.01, "position %d lies on the line from the hand to the aimed point (%.3f m aside)" % [i, aside])
		_check(first[i].distance_to(hand.origin) > first[i - 1].distance_to(hand.origin), "position %d is farther from the hand" % i)
		_check((first[i] - first[i - 1]).dot(flat) > 0.0, "position %d moves toward the target, never back across the view" % i)
	var landed := await _landing(ON_FLOOR)
	_check(_flat(landed).distance_to(_flat(target)) < LANDS_NEAR, "it lands where the crosshair was (%.2f m off)" % _flat(landed).distance_to(_flat(target)))


func case_real_path_drop() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var spot := Vector3(0.4, 0.0, 0.3)
	await _aim(_player, spot)
	var hand := _hands.hand_of(1, (spot - _player.eyes()).normalized())
	Input.action_press(&"drop_throw")
	await _physics_ticks(2)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _hands.items_of(1).is_empty(), "the Sock to leave the Hands", 5)
	var body := _mess.flight_of(ON_FLOOR)
	_check(body != null, "its body is let go at once: no flick")
	if body == null:
		return
	_check(body.global_position.distance_to(hand.origin) < 0.01, "at the hand (%.3f m off it), not over the spot" % body.global_position.distance_to(hand.origin))
	_check(body.global_position.y > 0.5, "high in the air where the hand is (%.2f m)" % body.global_position.y)
	_check(absf(body.linear_velocity.y) < 0.01, "let go, not pushed up or down (%.3f m/s)" % body.linear_velocity.y)
	var landed := await _landing(ON_FLOOR)
	_check(_flat(landed).distance_to(_flat(spot)) < 0.1, "it falls on its own onto the aimed spot (%.3f m off)" % _flat(landed).distance_to(_flat(spot)))
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to lie")
	_check(_flat(_mess.pose_of(ON_FLOOR).origin).distance_to(_flat(spot)) < LANDS_NEAR, "and lies there")
	# The drop's refusals stay: aimed at the open air, no drop.
	await _repick(ON_FLOOR)
	_face(Vector3(0.0, 0.0, 1.0), 10.0)
	await _physics_ticks(2)
	Input.action_press(&"drop_throw")
	await _physics_ticks(2)
	Input.action_release(&"drop_throw")
	await _physics_ticks(2)
	_check(_hands.items_of(1).has(ON_FLOOR) and _player.message() == Player.CANT_DROP, "aimed at the open air it is refused, as before")


# --- T01 -----------------------------------------------------------------------------------------

func case_t01_hand() -> void:
	await _build()
	await _pick(ON_FLOOR)
	await _aim(_player, FRONT + Vector3(0.0, 0.0, 4.0))
	_hands.throw(1, _player.aim_dir(), 0.3)
	await _watch(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the lob to rest")
	await _repick(ON_FLOOR)
	await _aim(_player, _player.global_position + Vector3(0.3, -1.6, -0.5))
	Input.action_press(&"drop_throw")
	await _physics_ticks(2)
	Input.action_release(&"drop_throw")
	await _watch(func() -> bool: return _hands.items_of(1).is_empty() and _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the drop to rest")
	_check(_faults.is_empty(), "a throw and a drop turn smoothly, and rest where they are (worst %.1f deg a tick) %s" % [_worst_turn, _faults.slice(0, 3)])


func case_t01_heap() -> void:
	await _zoo_up()
	var station := _zoo.get_node("Stations/Heap") as Node3D
	var spout := station.get_node("Spout/HeapSpout") as HeapSpout
	var t := spout.tuning.duplicate() as HeapTuning
	t.batch = 60
	spout.tuning = t
	var first := _mess.count()
	_player.global_position = station.to_global(Vector3(0.0, 0.0, -4.5))
	LevelRuntime.of(_zoo).parts.ask(Command.new(&"more", 1, spout.id, {}))
	var rises: Dictionary[int, float] = {}
	var lows: Dictionary[int, float] = {}
	# A bounce is a body flying back up. A tick's heights are sampled after Jolt's step and before the
	# Mess's tick, which puts back a step Jolt's position solve pushed into the floor (core/50) and counts
	# it (core/69: a Sock pushed 0.22 m under the floor and put back read as a 0.233 m bounce). So each
	# tick's heights count one tick later, and not at all when the Mess put a push back in between.
	var held: Dictionary[int, float] = {}
	var undone: Array[int] = [_mess._moving.pushed_in, 0]
	await _watch(func() -> bool:
		if _mess._moving.pushed_in == undone[0]:
			for sock: int in held:
				lows[sock] = minf(lows.get(sock, INF), held[sock])
				rises[sock] = maxf(rises.get(sock, 0.0), held[sock] - lows[sock])
		else:
			undone[1] += _mess._moving.pushed_in - undone[0]
			undone[0] = _mess._moving.pushed_in
		held.clear()
		for sock in range(first, _mess.count()):
			var body := _mess.flight_of(sock)
			if body != null:
				held[sock] = body.global_position.y
		return _mess.count() - first == 60 and _mess.moving_count() == 0 and _mess.waiting_count() == 0, "60 poured Socks to rest", 2400)
	var rise := 0.0
	for sock: int in rises:
		rise = maxf(rise, rises[sock])
	_check(_faults.is_empty(), "every poured Sock turns smoothly and rests where it is (worst %.1f deg a tick) %s" % [_worst_turn, _faults.slice(0, 3)])
	_check(rise < 0.08, "none bounces back up off the heap or the floor (most %.3f m; %d steps into the floor put back)" % [rise, undone[1]])


func case_t01_every() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	_mess = LevelRuntime.of(_zoo).mess
	_player = LevelRuntime.of(_zoo).player
	var ticks: Array[int] = [0]
	await _watch(func() -> bool:
		ticks[0] += 1
		return ticks[0] >= 240, "4 seconds")
	_check(_faults.is_empty() and _mess.moving_count() == 0, "nothing moves at the start (%d Socks, %d moving) %s" % [_mess.count(), _mess.moving_count(), _faults.slice(0, 3)])


# --- T03, T04 ------------------------------------------------------------------------------------

func case_t03() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var targets := {0.0: FRONT + Vector3(-0.4, 0.0, 1.6), 0.5: FRONT + Vector3(0.5, 0.0, 2.6), 1.0: FRONT + Vector3(0.0, 0.0, 3.0)}
	var first := true
	for charge: float in targets:
		if not first:
			await _repick(ON_FLOOR)
			_player.global_position = FRONT
			await _physics_ticks(2)
		first = false
		var target: Vector3 = targets[charge]
		await _aim(_player, target)
		_hands.throw(1, _player.aim_dir(), charge)
		var landed := await _landing(ON_FLOOR)
		_check(_flat(landed).distance_to(_flat(target)) < LANDS_NEAR,
				"at charge %.1f it lands where the crosshair was (%.2f m off)" % [charge, _flat(landed).distance_to(_flat(target))])
		await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to lie")
	# Out of reach (the far floor, nearly level): it flies along the aim, as the old Throw did.
	await _repick(ON_FLOOR)
	_player.global_position = FRONT
	_face(Vector3(0.0, 0.0, 1.0), -2.0)
	await _physics_ticks(2)
	var launch := _hands.launch_of(1, _player.aim_dir(), 0.5)
	_check((launch["vel"] as Vector3).normalized().dot(_player.aim_dir()) > 0.999, "an aim past the arc's reach flies along the aim")


func case_t04() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var setups := [["throw", "behind"], ["drop", "behind"], ["throw", "inside"], ["drop", "inside"]]
	var first := true
	for setup: Array in setups:
		var kind: String = setup[0]
		if not first:
			await _repick(ON_FLOOR)
		first = false
		_player.global_position = FRONT
		_face(Vector3(0.0, 0.0, 1.0), -50.0 if kind == "drop" else 5.0)
		await _physics_ticks(3)
		var dir := _player.aim_dir()
		var hand := _hands.hand_of(1, dir)
		var eyes := _player.eyes()
		# A wall piece right of the eye-line: between the eyes and the hand, or round the hand.
		var side := signf(hand.origin.x - eyes.x)
		var size := Vector3(0.25, 1.0, 0.1)
		var at := Vector3(hand.origin.x + side * 0.05, hand.origin.y, lerpf(eyes.z, hand.origin.z, 0.75))
		if setup[1] == "inside":
			size = Vector3(0.2, 0.2, 0.2)
			at = hand.origin
		var wall := _box("Wall_%s_%s" % setup, size, at)
		await _physics_ticks(1)
		var what := "%s, hand %s the wall" % setup
		_check(not PhysicsQueries.ray(_mess, eyes, hand.origin, Mess.LAYER_HOUSE, [_player.get_rid()]).is_empty()
				or PhysicsQueries.inside(_mess, hand.origin, Mess.LAYER_HOUSE), "the wall is in the hand's way (%s)" % what)
		var from := _hands.start_of(1, dir)
		_check(PhysicsQueries.ray(_mess, eyes, from.origin, Mess.LAYER_HOUSE, [_player.get_rid()]).is_empty()
				and not PhysicsQueries.inside(_mess, from.origin, Mess.LAYER_HOUSE),
				"it leaves from the eye-line's clear point (%s, %.2f m from the eye-line)" % [what, (from.origin - eyes).cross(dir).length()])
		_check((from.origin - eyes).cross(dir).length() < 0.01, "on the eye-line (%s)" % what)
		if kind == "throw":
			_hands.throw(1, dir, 0.5)
		else:
			var spot := _player.drop_spot()
			_check(not spot.is_empty(), "a drop spot on the floor (%s)" % what)
			if spot.is_empty():
				return
			_hands.drop(1, spot["point"], spot["normal"])
		await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the Sock to fly (%s)" % what, 5)
		var body := _mess.flight_of(ON_FLOOR)
		_check(body != null and body.global_position.distance_to(from.origin) < 0.01, "its body starts there (%s)" % what)
		var through := false
		var box := AABB(at - size * 0.5, size)
		while _mess.state_of(ON_FLOOR) == Mess.State.FLYING:
			await _physics_ticks(1)
			if _mess.flight_of(ON_FLOOR) != null and box.has_point(_mess.flight_of(ON_FLOOR).global_position):
				through = true
		_check(not through, "nothing passes through the wall (%s)" % what)
		wall.queue_free()
		await _physics_ticks(1)


## A box on the house layer, `size` big, centred at `at` (a stand-in wall piece).
func _box(box_name: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	_level.add_child(body)
	body.global_position = at
	return body


# --- Helpers -------------------------------------------------------------------------------------

## Runs physics ticks until `done`, watching every Sock each tick (T01): a body turns at most
## MOST_TURN degrees a tick, and where a Sock passes between its body and its lying record it moves
## and turns no more than SWITCH_MOVE and SWITCH_TURN.
func _watch(done: Callable, what: String, most := 900) -> void:
	for i in most:
		await _physics_ticks(1)
		_look()
		if done.call():
			return
	_check(false, "waited %d ticks for %s" % [most, what])


func _look() -> void:
	for sock in _mess.count():
		var body := _mess.flight_of(sock)
		var kind := "body" if body != null else ("lying" if _mess.state_of(sock) == Mess.State.LYING else "")
		if kind == "":
			_last.erase(sock)
			continue
		var now := body.global_transform.orthonormalized() if body != null else _mess.pose_of(sock).orthonormalized()
		if _last.has(sock):
			var was: Transform3D = _last[sock][0]
			var turn := rad_to_deg((was.basis.inverse() * now.basis).get_rotation_quaternion().get_angle())
			var move := was.origin.distance_to(now.origin)
			if _last[sock][1] != kind and (move > SWITCH_MOVE or turn > SWITCH_TURN):
				_faults.append("Sock %d moved %.3f m, turned %.1f deg from %s to %s" % [sock, move, turn, _last[sock][1], kind])
			elif kind == "body":
				_worst_turn = maxf(_worst_turn, turn)
				if turn > MOST_TURN:
					_faults.append("Sock %d turned %.1f deg in a tick" % [sock, turn])
		_last[sock] = [now, kind]


## Where Sock `sock`'s body first touches something (its velocity bends more than gravity does).
func _landing(sock: int) -> Vector3:
	var body := _mess.flight_of(sock)
	var last := body.linear_velocity
	for i in 600:
		var at := body.global_position
		await _physics_ticks(1)
		if not is_instance_valid(body) or _mess.flight_of(sock) != body:
			return at
		var v := body.linear_velocity
		if (v - (last + Vector3.DOWN * 9.8 / 60.0)).length() > 0.6:
			return body.global_position
		last = v
	return body.global_position


static func _flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


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
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	_mess = LevelRuntime.of(_zoo).mess
	_player = LevelRuntime.of(_zoo).player
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(_mess.count() - 1) != null, "the player to stand and every Sock to lie", 600)
	_mess.return_looks(_mess.count() - 1)


func _face(dir: Vector3, pitch: float) -> void:
	_player.rotation.y = atan2(-dir.x, -dir.z)
	(_player.get_node("Head") as Node3D).rotation.x = deg_to_rad(pitch)


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _pick(sock: int) -> void:
	await _aim(_player, _mess.pose_of(sock) * Vector3(0.0, 0.013, 0.0))
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock), "Sock %d to be picked" % sock)


## Waits out the grab interval, steps to 1 m from the Sock where it lies now and picks it.
func _repick(sock: int) -> void:
	await _physics_ticks(25)
	var at := _mess.pose_of(sock).origin
	var flat := Vector3(at.x, 0.0, at.z)
	var off := -flat.normalized() if flat.length() > 0.5 else Vector3(0.0, 0.0, 1.0)
	_player.global_position = flat + off
	await _physics_ticks(2)
	await _pick(sock)
