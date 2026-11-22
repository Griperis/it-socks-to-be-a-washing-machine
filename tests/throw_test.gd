## The Throw (core/08): the drop button held past the tap charges a ring, the release throws the
## active item through the Hands' `throw` Command, and the Host's Flight carries it to rest. One case
## per line of the approved behaviour list (T01-T04, T07, T08, T11, T13, T14), the invariant I.1
## after each Throw, the Commands, and the real path. Every case plays the station scene
## game/zoo/stations/handling.tscn on a floor, with the game's player and a Parts (a Host of one).
extends TestSuite

const STATION := "res://game/zoo/stations/handling.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's Socks, by id (the order of its SockSpots).
const ON_FLOOR := 0
const UNDER := 1
const OVER := 2
const ON_TABLE := 3
## Where the player stands: in front of the Socks on the floor.
const FRONT := Vector3(0.0, 0.0, 1.5)
## Physics ticks a second (every delta is 1/60 s in a run).
const TICKS := 60.0

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
## The answers applied since the case began.
var _events: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the station, pick a Sock, hold the right button, release, and it lands farther than a drop would"},
		{"name": "t01_charge", "method": "case_t01", "world": false,
				"title": "T01: held past 0.25 s with something in the Hands, a ring fills round the crosshair (full in 1.2 s) and the release throws along the aim; a menu drops the charge"},
		{"name": "t02_lob", "method": "case_t02", "world": false,
				"title": "T02: a charge released under 15% is a short lob (3.5 m/s forward, 2 m/s up), not a drop"},
		{"name": "t03_speed", "method": "case_t03", "world": false,
				"title": "T03: more charge flies faster, 3 m/s at the tap to 5 m/s at full, and farther"},
		{"name": "t04_q", "method": "case_t04", "world": false,
				"title": "T04: pressing Q does nothing"},
		{"name": "t07_cabinet", "method": "case_t07", "world": false,
				"title": "T07: a loose Sock thrown at a Cabinet bounces off and lies loose again, never shelved"},
		{"name": "t08_wall", "method": "case_t08", "world": false,
				"title": "T08: a Sock thrown at a wall from up close never ends inside it and always lies loose"},
		{"name": "t11_wake", "method": "case_t11", "world": false,
				"title": "T11: a Throw faster than 1.5 m/s wakes the lying Sock it hits and those touching it (at most 8); a slow drop wakes none"},
		{"name": "t11_shove", "method": "case_t11_shove", "world": false,
				"title": "core/46, Q2431: a Throw wakes the lying Socks it is about to hit before the contact, so it shoves them away in the hit's direction"},
		{"name": "t11_pair_stays", "method": "case_t11_pair", "world": false,
				"title": "T11, Q2330: a full Throw into a lying Pair does not wake it, as in the old game (Q1742)"},
		{"name": "t13_rest", "method": "case_t13", "world": false,
				"title": "T13, M06: a thrown Sock lies where its body stopped; one Jolt never sleeps rests once it is still"},
		{"name": "t14_bounds", "method": "case_t14", "world": false,
				"title": "T14: a thrown Sock that leaves the playable space or goes above the ceiling comes down at once at the station's return spot"},
		{"name": "commands", "method": "case_commands", "world": false,
				"title": "the Throw is a throw Command the Host answers: refused with empty Hands or a bad direction or charge; only the Host wakes or rests a Sock"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_events.clear()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	await _pick(ON_FLOOR)
	_face(Vector3(0.0, 0.0, 1.0), 0.0)
	await _aim(_player, FRONT + Vector3(0.0, 0.0, 2.0))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the dropped Sock to lie")
	var dropped := _flat_distance(_mess.pose_of(ON_FLOOR).origin)
	_places("after the drop")
	await _repick(ON_FLOOR)
	_face(Vector3(0.0, 0.0, 1.0), 15.0)
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.ring().visible and _player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.FLYING, "the Sock to fly")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the thrown Sock to lie")
	var thrown := _flat_distance(_mess.pose_of(ON_FLOOR).origin)
	_check(thrown > dropped + 1.0 and thrown > _player.hands_tuning.reach,
			"the thrown Sock lands farther (%.2f m) than the drop (%.2f m) and than any drop could (%.1f m)" % [thrown, dropped, _player.hands_tuning.reach])
	_places("after the Throw")


# --- Charge and throw ----------------------------------------------------------------------------

func case_t01() -> void:
	await _build()
	_face(Vector3(0.0, 0.0, 1.0), 10.0)
	Input.action_press(&"drop_throw")
	await _physics_ticks(int(0.5 * TICKS))
	_check(not _player.ring().visible and not _player.charging, "with empty Hands no ring shows")
	Input.action_release(&"drop_throw")
	await _physics_ticks(2)
	await _pick(ON_FLOOR)
	_face(Vector3(0.0, 0.0, 1.0), 10.0)
	Input.action_press(&"drop_throw")
	await _physics_ticks(int(0.2 * TICKS))
	_check(not _player.ring().visible, "before 0.25 s no ring shows")
	await _until(func() -> bool: return _player.charging, "the charge to start", 30)
	_check(_player.ring().visible, "past 0.25 s the ring shows round the crosshair")
	await _physics_ticks(int(0.6 * TICKS))
	_near(_player.charge, 0.5, 0.05, "0.6 s into the charge the ring is half full")
	_near(_player.ring().value, _player.charge, 0.0001, "the ring shows the charge")
	await _physics_ticks(int(0.7 * TICKS))
	_near(_player.charge, 1.0, 0.0001, "after 1.2 s it is full and stays full")
	var dir := _player.aim_dir()
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the Sock to fly at once, no flick", 3)
	_check(not _player.ring().visible, "the release hides the ring")
	_check(_hands.items_of(1).is_empty(), "it left the Hands")
	var ev := _last(&"throw")
	var vel: Vector3 = ev["launch"]["vel"] if not ev.is_empty() else Vector3.ZERO
	_check(vel.normalized().dot(dir) > 0.999, "it flies along the aim (%s, aim %s)" % [vel, dir])
	_places("in the air")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to come to rest")
	_places("after the Throw")
	await _repick(ON_FLOOR)
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "a second charge to start", 30)
	_player.set_input_blocked(true)
	await _physics_ticks(2)
	_check(not _player.charging and not _player.ring().visible, "a menu opening mid-charge drops the charge")
	_player.set_input_blocked(false)
	Input.action_release(&"drop_throw")
	await _physics_ticks(5)
	_check(_hands.active_of(1) == ON_FLOOR, "and nothing is thrown")
	_places("after the menu")


func case_t02() -> void:
	await _build()
	await _pick(ON_FLOOR)
	_face(Vector3(0.0, 0.0, 1.0), 0.0)
	var dir := _player.aim_dir()
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "the charge to start", 30)
	await _physics_ticks(3)
	var charge := _player.charge
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the lob to fly")
	_check(charge < _player.hands_tuning.tap_charge, "released at %.2f, under 15%%" % charge)
	var vel: Vector3 = _last(&"throw")["launch"]["vel"]
	_near((vel - Vector3.UP * 2.0).dot(dir), 3.5, 0.001, "3.5 m/s forward")
	_near(vel.y, 2.0, 0.001, "2 m/s up")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the lob to lie")
	var far := _flat_distance(_mess.pose_of(ON_FLOOR).origin)
	_check(far > 1.0, "a short lob, not a drop at the feet (%.2f m)" % far)
	_places("after the lob")


func case_t03() -> void:
	await _build()
	var t := _player.hands_tuning
	_near(_hands.launch_of(1, Vector3.FORWARD, t.tap_charge)["vel"].length(), lerpf(3.0, 5.0, t.tap_charge), 0.001,
			"at the tap charge 3 m/s plus its share")
	_near(_hands.launch_of(1, Vector3.FORWARD, 1.0)["vel"].length(), 5.0, 0.001, "at a full charge 5 m/s")
	var distances: Array[float] = []
	for hold: float in [0.6, 1.3]:
		await _repick(ON_FLOOR)
		# Both from the same place (a bouncing Throw lies far off, M10: the pick walks there).
		_player.global_position = FRONT
		await _physics_ticks(2)
		_face(Vector3(0.0, 0.0, 1.0), 15.0)
		Input.action_press(&"drop_throw")
		await _until(func() -> bool: return _player.charging, "the charge to start", 30)
		await _physics_ticks(int(hold * TICKS))
		Input.action_release(&"drop_throw")
		await _until(func() -> bool: return _mess.flight_of(ON_FLOOR) != null, "the Sock to fly")
		var speed: float = (_last(&"throw")["launch"]["vel"] as Vector3).length()
		_near(speed, lerpf(3.0, 5.0, minf(hold / 1.2, 1.0)), 0.1, "held %.1f s it leaves at %.2f m/s" % [hold, speed])
		# Where its arc first comes down (a Throw bounces and slides on from there, M10).
		var body := _mess.flight_of(ON_FLOOR)
		var landed := Vector3.INF
		while _mess.state_of(ON_FLOOR) == Mess.State.FLYING:
			if landed == Vector3.INF and is_instance_valid(body) and body.global_position.y < 0.06:
				landed = body.global_position
			await _physics_ticks(1)
		distances.append(_flat_distance(landed if landed != Vector3.INF else _mess.pose_of(ON_FLOOR).origin))
		_player.global_position = FRONT
		await _physics_ticks(2)
	_check(distances[1] > distances[0] + 0.3, "the full Throw comes down farther (%.2f m) than the half one (%.2f m)" % [distances[1], distances[0]])
	_places("after the Throws")


func case_t04() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var before := [_mess.state(), _hands.state()]
	for pressed: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_Q
		key.physical_keycode = KEY_Q
		key.pressed = pressed
		Input.parse_input_event(key)
		await _physics_ticks(10)
	_same([_mess.state(), _hands.state()], before, "Q changes no Sock and no Hands")
	_check(not _player.charging and _player.message() == "", "and starts nothing, says nothing")


# --- Where it ends -------------------------------------------------------------------------------

func case_t07() -> void:
	await _build()
	# A stand-in Cabinet until core/04: a box on the house layer in the throw's path.
	var cabinet := _box("Cabinet", Vector3(1.2, 1.6, 0.5), FRONT + Vector3(0.0, 0.8, 2.2))
	await _pick(ON_FLOOR)
	await _aim(_player, cabinet.global_position + Vector3(0.0, 0.0, -0.25))  # core/23: it lands where aimed
	await _throw_full()
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to lie again")
	var at := _mess.pose_of(ON_FLOOR).origin
	_check(at.z < cabinet.global_position.z - 0.25 + 0.01, "it bounced back off the Cabinet's front (z %.2f)" % at.z)
	_check(at.y < 0.2, "it lies loose at the foot of the Cabinet, not on or in it (y %.3f)" % at.y)
	_check(not PhysicsQueries.inside(_mess, _centre(ON_FLOOR), Mess.LAYER_HOUSE), "and not inside it")
	_places("after the Throw at the Cabinet")


func case_t08() -> void:
	await _build()
	await _pick(ON_FLOOR)
	# Right against the station's wall (its face at z -1.15), throwing into it.
	_player.global_position = Vector3(0.0, 0.0, -0.75)
	await _physics_ticks(5)
	for pitch: float in [0.0, -30.0, 20.0]:
		if pitch != 0.0:
			await _take(ON_FLOOR)  # it may lie under the table: taken, not aimed at
			_player.global_position = Vector3(0.0, 0.0, -0.75)
			await _physics_ticks(2)
		_face(Vector3(0.0, 0.0, -1.0), pitch)
		await _throw_full()
		await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to lie (pitch %d)" % pitch)
		var centre := _centre(ON_FLOOR)
		_check(not PhysicsQueries.inside(_mess, centre, Mess.LAYER_HOUSE), "it is not inside the wall (pitch %d, %s)" % [pitch, centre])
		_check(centre.z > -1.15, "it stayed on the thrower's side of the wall (pitch %d, z %.2f)" % [pitch, centre.z])
		_places("after the Throw at the wall (pitch %d)" % pitch)
	# The Host's own guard: a body that would rest inside a wall lies at the return spot.
	await _take(ON_FLOOR)
	_player.global_position = FRONT
	await _physics_ticks(2)
	_face(Vector3(0.0, 0.0, 1.0), 0.0)
	await _throw_full()
	var body := _mess.flight_of(ON_FLOOR)
	body.freeze = true
	body.global_position = Vector3(0.0, 0.9, -1.2 - 0.013)
	body.sleeping = true
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the walled-in Sock to be put down")
	var spot := _station.get_node("ReturnSpot") as Marker3D
	_check(_mess.pose_of(ON_FLOOR).origin.distance_to(spot.global_position) <= _mess.bodies_tuning().return_scatter + 0.001, "a Sock that would end inside a wall lies at the return spot, scattered within its radius (core/16 P12)")


func case_t11() -> void:
	await _build()
	await _pick(ON_FLOOR)
	var woken := {}
	_parts.applied.connect(func(ev: Dictionary) -> void:
		if ev.get("ok", false) and StringName(ev.get("kind", &"")) == &"wake":
			var states := Mess.row_states(ev["changes"][_mess.id])
			for sock: int in states:
				if states[sock] == Mess.State.FLYING and sock != ON_FLOOR:
					woken[sock] = true)
	# A slow drop onto the Heap (UNDER with OVER on it) wakes none.
	await _aim(_player, _centre(OVER) + Vector3(0.0, 0.013, 0.0))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the dropped Sock to lie")
	_check(woken.is_empty(), "a slow drop on lying Socks wakes none (%s)" % [woken.keys()])
	await _repick(ON_FLOOR)
	# Close in front of the Heap, aimed a little beyond it: the arc comes down on it.
	_player.global_position = Vector3(0.6, 0.0, 0.7)
	await _physics_ticks(2)
	await _aim(_player, _centre(UNDER) + Vector3(0.0, 0.0, -0.2))
	await _throw_full()
	await _until(func() -> bool: return not woken.is_empty(), "a lying Sock to wake", 120)
	_check(woken.has(UNDER) and woken.has(OVER), "the Sock hit and the one touching it wake (%s)" % [woken.keys()])
	_check(not woken.has(ON_TABLE), "a Sock touching neither stays (%s)" % [woken.keys()])
	_places("while they fall")
	await _until(func() -> bool:
		for sock in _mess.count():
			if _mess.state_of(sock) == Mess.State.FLYING:
				return false
		return true, "every Sock to rest again", 900)
	_places("after the wake")
	_mess.tuning = _mess.tuning.duplicate() as HandsTuning
	_mess.tuning.wake_count = 1
	await _aim(_player, _centre(UNDER))
	var near := _mess.touching(UNDER)
	_check(near.size() <= 1, "the wake takes at most wake_count touching Socks (%s)" % near)


func case_t11_shove() -> void:
	# The Heap (UNDER with OVER on it) and the Sock on the table, each thrown at with the look-ahead
	# off (they wake on the contact, as before core/46) and on.
	for target: int in [UNDER, ON_TABLE]:
		var off := await _shove(0.0, target)
		var on := await _shove(-1.0, target)
		print("t11_shove %d: look-ahead off %s, on %s" % [target, off, on])
		_check(on["woken"].has(target), "the Throw wakes Sock %d it is about to hit (%s)" % [target, on["woken"]])
		_check(on["fastest"] >= 0.2,
				"the hit pushes Sock %d's woken Socks along its motion at %.2f m/s (at least 0.2 m/s)" % [target, on["fastest"]])
		_check(off["fastest"] < 0.05,
				"woken only on the contact, they get no push along it (%.3f m/s): the look-ahead makes the shove" % off["fastest"])
		_check(on["farthest"] >= -0.001, "they end no nearer the thrower than they lay (%.4f m along the hit)" % on["farthest"])


## Throws ON_FLOOR with the Throw input from 0.8 m at lying Sock `target`, the look-ahead's reach
## `reach` (0: it wakes on the contact only, as before core/46; below 0: the tuning's own). Returns the
## Socks the hit woke, their fastest flat speed along the thrown Sock's flat motion at the wake, and how
## far the farthest of them went that way once all rest.
func _shove(reach: float, target: int) -> Dictionary:
	if _level != null:
		_level.free()
		_level = null
	await _build()
	_mess.tuning = _mess.tuning.duplicate() as HandsTuning
	if reach >= 0.0:
		_mess.tuning.hit_reach = reach
	var was: Array[Vector3] = []
	for sock in _mess.count():
		was.append(_centre(sock))
	await _pick(ON_FLOOR)
	var seen := {"dir": Vector3.ZERO, "woken": PackedInt32Array()}
	_parts.applied.connect(func(ev: Dictionary) -> void:
		if ev.get("ok", false) and StringName(ev.get("kind", &"")) == &"wake" and seen["dir"] == Vector3.ZERO:
			var body := _mess.flight_of(ON_FLOOR)
			if body == null:
				return
			var v := body.linear_velocity
			seen["dir"] = Vector3(v.x, 0.0, v.z).normalized()
			var states := Mess.row_states(ev["changes"][_mess.id])
			var woken := PackedInt32Array()
			for sock: int in states:
				if states[sock] == Mess.State.FLYING and sock != ON_FLOOR:
					woken.append(sock)
			seen["woken"] = woken)
	var at := was[target]
	_player.global_position = Vector3(at.x, 0.0, at.z + 0.8)
	await _physics_ticks(2)
	await _aim(_player, at + Vector3(0.0, 0.0, -0.2))
	await _throw_full()
	await _until(func() -> bool: return seen["dir"] != Vector3.ZERO, "the hit to wake a Sock", 120)
	var dir: Vector3 = seen["dir"]
	var fastest := 0.0
	for i in 900:
		var flying := _mess.state_of(ON_FLOOR) == Mess.State.FLYING
		for sock: int in seen["woken"]:
			var body := _mess.flight_of(sock)
			if body != null:
				fastest = maxf(fastest, body.linear_velocity.dot(dir))
			flying = flying or _mess.state_of(sock) == Mess.State.FLYING
		if not flying:
			break
		await _physics_ticks(1)
	var farthest := -INF
	for sock: int in seen["woken"]:
		farthest = maxf(farthest, (_centre(sock) - was[sock]).dot(dir))
	return {"woken": seen["woken"], "fastest": fastest, "farthest": farthest}


func case_t11_pair() -> void:
	await _build()
	# The Heap's two Socks become one lying Pair: UNDER its lead, OVER inside it.
	var states := _mess.states.duplicate()
	states[OVER] = Mess.State.IN_PAIR
	var mates := _mess.mates.duplicate()
	mates[UNDER] = OVER
	mates[OVER] = UNDER
	var designs := _mess.designs.duplicate()
	designs[OVER] = designs[UNDER]
	_mess.write({"designs": designs, "states": states, "poses": _mess.poses.duplicate(), "mates": mates}, true)
	await _physics_ticks(2)
	_check(_mess.is_pair(UNDER) and _mess.state_of(UNDER) == Mess.State.LYING, "a lying Pair stands where the Heap was")
	await _pick(ON_FLOOR)
	var woken := {}
	_parts.applied.connect(func(ev: Dictionary) -> void:
		if ev.get("ok", false) and StringName(ev.get("kind", &"")) == &"wake":
			var s := Mess.row_states(ev["changes"][_mess.id])
			for sock: int in s:
				if s[sock] == Mess.State.FLYING and sock != ON_FLOOR:
					woken[sock] = true)
	# The same Throw as T11's, which hits the Heap.
	_player.global_position = Vector3(0.6, 0.0, 0.7)
	await _physics_ticks(2)
	await _aim(_player, _centre(UNDER) + Vector3(0.0, 0.0, -0.2))
	await _throw_full()
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "the thrown Sock to rest", 900)
	_check(not woken.has(UNDER) and _mess.state_of(UNDER) == Mess.State.LYING, "the hit Pair stays lying (%s)" % [woken.keys()])


func case_t13() -> void:
	await _build()
	await _pick(ON_FLOOR)
	_face(Vector3(0.0, 0.0, 1.0), 10.0)
	await _throw_full()
	var body := _mess.flight_of(ON_FLOOR)
	var last := Vector3.ZERO
	while _mess.state_of(ON_FLOOR) == Mess.State.FLYING:
		last = body.global_position
		await _physics_ticks(1)
	_near(_mess.pose_of(ON_FLOOR).origin.distance_to(last), 0.0, 0.01, "it lies where its body stopped (%s)" % last)
	_check(last.y < SockDress.BOX.y + 0.005, "on the floor, either side up (y %.3f)" % last.y)
	_places("after it came to rest")
	await _repick(ON_FLOOR)
	_player.global_position = FRONT
	await _physics_ticks(2)
	_face(Vector3(0.0, 0.0, 1.0), 10.0)
	await _throw_full()
	_mess.flight_of(ON_FLOOR).can_sleep = false
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "a body that never sleeps to rest once still", 600)
	_places("after a rest without sleep")


func case_t14() -> void:
	await _build()
	var spot := _station.get_node("ReturnSpot") as Marker3D
	_check(spot.global_position.y < 0.01 and absf(spot.global_position.x) < 2.5 and absf(spot.global_position.z) < 2.0,
			"the station's return spot is on its pad (%s)" % spot.global_position)
	_check(_mess.in_bounds(Vector3(0.0, 1.0, 0.0)) and not _mess.in_bounds(Vector3(0.0, 7.0, 0.0)),
			"the station's playable space ends under 6 m")
	# Out of the side: the playable space shrunk to 3 m in front of the Socks.
	_mess.bounds = AABB(Vector3(-4.0, -2.0, -4.0), Vector3(8.0, 8.0, 7.0))
	await _pick(ON_FLOOR)
	_face(Vector3(0.0, 0.0, 1.0), 15.0)
	await _throw_full()
	var body := _mess.flight_of(ON_FLOOR)
	var past := 0.0
	while _mess.state_of(ON_FLOOR) == Mess.State.FLYING:
		past = maxf(past, body.global_position.z)
		await _physics_ticks(1)
	_check(past < 3.0 + 0.2, "it comes down as soon as it leaves (got to z %.2f)" % past)
	_check(_mess.pose_of(ON_FLOOR).origin.distance_to(spot.global_position) <= _mess.bodies_tuning().return_scatter + 0.001, "it lies at the return spot, scattered within its radius (core/16 P12)")
	_places("after leaving by the side")
	# Above the ceiling: a ceiling at 2.5 m.
	_mess.bounds = AABB(Vector3(-8.0, -2.0, -8.0), Vector3(16.0, 4.5, 16.0))
	await _repick(ON_FLOOR)
	_player.global_position = FRONT
	await _physics_ticks(2)
	_face(Vector3(0.0, 0.0, 1.0), 80.0)
	await _throw_full()
	body = _mess.flight_of(ON_FLOOR)
	var top := 0.0
	while _mess.state_of(ON_FLOOR) == Mess.State.FLYING:
		top = maxf(top, body.global_position.y)
		await _physics_ticks(1)
	_check(top < 2.5 + 0.2, "it comes down at once above the ceiling (got to %.2f m)" % top)
	_check(_mess.pose_of(ON_FLOOR).origin.distance_to(spot.global_position) <= _mess.bodies_tuning().return_scatter + 0.001, "it lies at the return spot, scattered within its radius (core/16 P12)")
	_places("after going above the ceiling")


# --- Commands ------------------------------------------------------------------------------------

func case_commands() -> void:
	await _build()
	var ev := _parts.answer(Command.new(&"throw", 1, _hands.id, {"dir": Vector3.FORWARD, "charge": 0.5}))
	_check(not ev["ok"] and ev["reason"] == Hands.NOTHING, "a throw with empty Hands is refused (%s)" % ev)
	await _pick(ON_FLOOR)
	for bad: Dictionary in [{"dir": Vector3(0.0, 0.0, -2.0), "charge": 0.5}, {"dir": Vector3.ZERO, "charge": 0.5},
			{"dir": Vector3.FORWARD, "charge": 1.5}, {"dir": Vector3.FORWARD, "charge": -0.1}, {"dir": Vector3.FORWARD}]:
		ev = _parts.answer(Command.new(&"throw", 1, _hands.id, bad))
		_check(not ev["ok"] and ev["reason"] == "wrong", "a bad throw is refused as wrong (%s)" % bad)
	var verb: Dictionary = _hands.accepts().get(&"throw", {})
	_check(verb.has("rate") and Command.args_error({"dir": Vector3.FORWARD, "charge": 0.5}, verb["args"]) == "",
			"a Guest may ask a throw, rate-limited (%s)" % verb)
	_check(Command.args_error({"dir": Vector3.FORWARD, "charge": 2.0}, verb["args"]) != "", "a Guest's charge over 1 is dropped at the gate")
	_check(not _parts.answer(Command.new(&"wake", 2, _mess.id, {"sock": UNDER}))["ok"], "only the Host wakes a Sock")
	_check(_mess.accepts().is_empty(), "no Guest may ask the Mess anything")
	_parts.apply(_parts.answer(Command.new(&"throw", 1, _hands.id, {"dir": Vector3.FORWARD, "charge": 1.0})))
	_check(_mess.state_of(ON_FLOOR) == Mess.State.FLYING and _mess.flight_of(ON_FLOOR) != null, "a granted throw: the Host's body flies")
	_check(_mess.flight_of(ON_FLOOR).get_parent() == _station.get_node("Flights"), "the flying Sock is the Host's body, under the spawn path")
	var snap := _parts.snapshot()
	var back := _roundtrip(snap)
	_same(Mess.unpacked(back[String(_mess.id)])["throws"], _mess.throws, "a thrown Sock's launch survives a save")
	_places("in the air")
	await _until(func() -> bool: return _mess.state_of(ON_FLOOR) == Mess.State.LYING, "it to lie")
	_check(_mess.throws.is_empty(), "a Sock at rest keeps no launch")
	var guest := _hands.launch_of(2, Vector3.FORWARD, 1.0)
	_check(guest["from"] is Transform3D and is_equal_approx((guest["vel"] as Vector3).length(), 5.0),
			"a Guest's direction is only a direction: the Host decides from and speed")
	_places("after the Commands")


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
	_parts.applied.connect(func(ev: Dictionary) -> void: _events.append(ev))


## A box on the house layer, `size` big, centred at `at` (a stand-in piece of furniture).
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


## Turns the body to face `dir` (flat) and tilts the head `pitch` degrees up, as the mouse would.
func _face(dir: Vector3, pitch: float) -> void:
	_player.rotation.y = atan2(-dir.x, -dir.z)
	(_player.get_node("Head") as Node3D).rotation.x = deg_to_rad(pitch)


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
	await _until(func() -> bool: return _hands.items_of(1).has(sock), "Sock %d to be picked" % sock)


## Waits out the grab interval, steps to 1 m from the Sock where it lies now (on its side towards
## the station's middle) and picks it.
func _repick(sock: int) -> void:
	await _physics_ticks(25)
	var at := _mess.pose_of(sock).origin
	var flat := Vector3(at.x, 0.0, at.z)
	var off := -flat.normalized() if flat.length() > 0.5 else Vector3(0.0, 0.0, 1.0)
	_player.global_position = flat + off
	await _physics_ticks(2)
	await _pick(sock)


## Waits out the grab interval, steps to 0.6 m from the Sock and takes it (the Hands' own pick, not
## the crosshair: a Throw at the wall may leave it under the table).
func _take(sock: int) -> void:
	await _physics_ticks(25)
	var at := _mess.pose_of(sock).origin
	_player.global_position = Vector3(at.x, 0.0, at.z + 0.6)
	await _physics_ticks(2)
	_hands.pick(1, sock)
	await _until(func() -> bool: return _hands.items_of(1).has(sock), "Sock %d to be taken" % sock)


## The last granted answer of `kind`, or {}.
func _last(kind: StringName) -> Dictionary:
	for i in range(_events.size() - 1, -1, -1):
		if _events[i].get("ok", false) and StringName(_events[i].get("kind", &"")) == kind:
			return _events[i]
	return {}


## How far `p` is from the player's feet, along the floor.
func _flat_distance(p: Vector3) -> float:
	var at := _player.global_position
	return Vector2(p.x - at.x, p.z - at.z).length()


## The middle of a lying Sock.
func _centre(sock: int) -> Vector3:
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


## I.1: every Sock is in exactly one place: lying (drawn), in exactly one player's Hands, or flying.
func _places(when: String) -> void:
	var counts := {"lying": 0, "held": 0, "flying": 0}
	var ok := true
	for sock in _mess.count():
		var holders := 0
		for by: Variant in _hands.held:
			holders += (_hands.held[by] as PackedInt32Array).count(sock)
		match _mess.state_of(sock):
			Mess.State.LYING:
				ok = ok and holders == 0 and _mess.looks_of(sock) != null and _mess.flight_of(sock) == null
				counts["lying"] += 1
			Mess.State.HELD:
				ok = ok and holders == 1 and _mess.looks_of(sock) == null and _mess.flight_of(sock) == null
				counts["held"] += 1
			Mess.State.FLYING:
				ok = ok and holders == 0 and _mess.looks_of(sock) == null
				counts["flying"] += 1
	_check(ok and _mess.count() == 8, "%s every Sock is in exactly one place (%s)" % [when, counts])
