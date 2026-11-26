## core/41 in co-op: two real zoos (only their Stacking station, to stay light), each a machine of its
## own in one process, joined over real ENet through the zoo's own wiring. The Guest's player (B) climbs
## onto the Host's (A) back by its pressed jump; A walks by its own input. Nothing about the stack is
## sent (Q2591): each machine moves its own body on the back as drawn there. Lines are the numbered
## lines of docs/migration/m3-lists/01-player-stacking.md.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Stacking"]
const STATION := "Stations/Stacking"
const NET_WAIT_S := 20.0
## Where A stands, from the station along the zoo's axes: off its pad, clear of the stand-ins and the ledge.
const A_SPOT := Vector3(3.5, 0.0, -2.5)
## The one-way delays the co-op case runs at.
const LAGS: Array[int] = [0, 50]
## How close a height must be to count as "at" it (m).
const AT := 0.05
## The loop A walks while carrying: its turn rate (rad/s) and how long (s).
const TURN_RATE := 1.2
const LOOP_S := 4.0
## On B's own machine B stands on A's drawn disc: at most its radius plus the body's round bottom off
## its middle, and within AT of its top.
const RIDER_OFF_MOST := 0.65
## On A's machine B is drawn at A's feet plus the offset B's pose sends (Q2592): within this of A's back.
const SEEN_OFF_MOST := 0.65
## The jitter bound: how much the frame's move of B's place against A's on-screen back may differ from the
## frame before's. A trail that turns with A changes smoothly; a jitter jumps back and forth. Measured once
## A is under way: for its first SETTLE_FRAMES A goes from still to its pace in one tick and B's drawn
## body eases after it, as every Teammate's does when they set off.
const STEP_MOST := 0.01
const SETTLE_FRAMES := 30

var _branches: Array[Node] = []
var _pace_next := 0
## The carried loop's numbers by one-way delay, walked once a process (_carried_loop).
var _loops: Dictionary[int, Dictionary] = {}


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path, two players in the zoo station: B's pressed jump near A's back climbs: B ends on A's disc (feet at A's back height) on B's machine; A's pace is halved (2 m/s); A walks by its input and B moves with A on both machines"},
		{"name": "carried_loop", "method": "case_carried_loop", "world": false,
				"title": "0 and 50 ms one way: B rides A while A walks a loop: on each machine B's drawn place stays within a typed bound of A's on-screen back (on A's machine it trails by the lag, Q2591), and on B's machine no jitter (the frame's move against the frame before's) over 0.01 m once under way; A stays at the carry pace throughout and counts B on its back (the numbers on A's machine are printed: carried_loop_seen holds the open rule)"},
		{"name": "jump_heard", "method": "case_jump_heard", "world": false,
				"title": "Q2593: B's climb is a jump: jump plays on B's machine and at B's body on A's; A's jump with B on its back plays at A's body on B's machine, and none at B's (the rider rides, it does not jump); B still rides after A lands"},
		{"name": "carried_loop_seen", "method": "case_carried_loop_seen", "world": false,
				"title": "0 and 50 ms one way: on A's machine B is drawn on A's disc (within its radius and the body's round bottom) and riding adds no jitter over 0.01 m"},
		{"name": "carrier_stands", "method": "case_carrier_stands", "world": false,
				"title": "lines 29, 30: crouched A with B on its back stands up with room for the stack (B rides up), and stays crouched under a board that leaves room for A alone"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_drop_branches()


func case_real_path() -> void:
	var pair := await _joined(0)
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var a := _player(host)
	var b := _player(guest)
	await _climb(host, guest)
	var a_seen := _avatars(guest).of(1)
	_near(b.global_position.y, a_seen.back.top().y, AT, "B's feet are at A's back height on B's machine")
	_near(b.global_position.y - Stacks.feet(a_seen).y, 1.4, AT, "1.4 m over A's feet")
	_check(b.crouching, "B rides crouched")
	await _until(func() -> bool: return a.stack().carry < 1.0, "A's machine to see B on A's back")
	b.set_input_blocked(true)
	a.set_input_blocked(false)
	var start_a := a.global_position
	var start_b := b.global_position
	var speed := [0.0]
	Input.action_press(Player.MOVE_FORWARD)
	await _until(func() -> bool:
		_pace()
		speed[0] = maxf(speed[0], Vector2(a.velocity.x, a.velocity.z).length())
		return a.global_position.distance_to(start_a) > 2.0, "A to walk 2 m")
	Input.action_release(Player.MOVE_FORWARD)
	_near(speed[0], a.tuning.walk_speed * a.stack().tuning.carry_speed, 0.05, "A walks at half its pace with B on its back")
	await _until(func() -> bool: return b.global_position.distance_to(start_b) > 1.9 and a_seen.global_position.distance_to(a.global_position) < 0.02,
			"B to be carried along on B's machine")
	_check(b.riding(), "B still rides")
	var off := b.global_position - a_seen.back.top()
	_check(Vector2(off.x, off.z).length() < RIDER_OFF_MOST, "B is on A's disc (%.2f m off its middle)" % Vector2(off.x, off.z).length())
	var b_seen := _avatars(host).of(_session(guest).me())
	await _until(func() -> bool: return b_seen.global_position.distance_to(b.global_position) < 0.02, "A's machine to draw B where B stands")
	var seen_off := b_seen.global_position - a.stack().top()
	_check(Vector2(seen_off.x, seen_off.z).length() < 0.3 and absf(seen_off.y) < AT, "on A's machine B stands on A's back (%s)" % seen_off)
	_drop_branches()


func case_carried_loop() -> void:
	for lag_ms: int in LAGS:
		await _carried_loop(lag_ms, false)


func case_carried_loop_seen() -> void:
	for lag_ms: int in LAGS:
		await _carried_loop(lag_ms, true)


## B rides A round a loop at `lag_ms`; `on_disc` asks the stricter rule of the open question (B drawn on
## A's disc on A's machine, no added jitter) instead of the counting reach the stack keeps today. The loop
## is walked once per lag in a process: carried_loop and carried_loop_seen judge the same numbers.
func _carried_loop(lag_ms: int, on_disc: bool) -> void:
	if not _loops.has(lag_ms):
		_loops[lag_ms] = await _walk_loop(lag_ms)
	var r: Dictionary = _loops[lag_ms]
	var most: Dictionary = r["most"]
	var off_back: int = r["off_back"]
	var full_pace: int = r["full_pace"]
	var alone: float = r["alone"]
	_check(off_back == 0, "%d ms: B rode A the whole loop on B's machine (off %d frames)" % [lag_ms, off_back])
	_check(most["rider"] <= RIDER_OFF_MOST and most["rider_y"] <= AT, "%d ms: on B's machine B stays on A's drawn disc (%.3f m off, %.3f high)" % [lag_ms, most["rider"], most["rider_y"]])
	_check(most["seen"] <= SEEN_OFF_MOST and most["seen_y"] <= 0.15, "%d ms: on A's machine B's drawn body stays counted on A's back (within %.2f m) (%.3f m off, %.3f high)" % [lag_ms, SEEN_OFF_MOST, most["seen"], most["seen_y"]])
	_check(most["step_guest"] <= STEP_MOST, "%d ms: on B's machine no jitter over %.2f m against A's drawn back (%.4f)" % [lag_ms, STEP_MOST, most["step_guest"]])
	if on_disc:
		_check(most["seen"] <= RIDER_OFF_MOST, "%d ms: on A's machine B is drawn on A's disc (%.3f m off)" % [lag_ms, most["seen"]])
		_check(most["step_host"] <= STEP_MOST, "%d ms: on A's machine riding adds no jitter over %.2f m (%.4f; B walking alone there: %.4f)" % [
				lag_ms, STEP_MOST, most["step_host"], alone])
	_check(full_pace == 0, "%d ms: A kept the carry pace the whole loop (full pace %d frames)" % [lag_ms, full_pace])


## Walks the loop at `lag_ms` (B alone first for the baseline, then B on A's back) and returns what it
## measured: {most, off_back, full_pace, alone}.
func _walk_loop(lag_ms: int) -> Dictionary:
	var pair := await _joined(lag_ms)
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var a := _player(host)
	var b := _player(guest)
	var alone := await _teammate_jitter(host, guest)
	await _climb(host, guest)
	await _until(func() -> bool: return a.stack().carry < 1.0, "A's machine to see B on A's back", 900, 0.2)
	b.set_input_blocked(true)
	a.set_input_blocked(false)
	var a_seen := _avatars(guest).of(1)
	var b_seen := _avatars(host).of(_session(guest).me())
	await _until(func() -> bool:
		_pace()
		return b_seen.global_position.distance_to(b.global_position) < 0.01, "A's machine to draw B where B stands", 900, 0.2)
	var most := {"rider": 0.0, "rider_y": 0.0, "seen": 0.0, "seen_y": 0.0, "step_guest": 0.0, "step_host": 0.0}
	var last := {"guest": Vector3.INF, "host": Vector3.INF, "dg": Vector3.ZERO, "dh": Vector3.ZERO}
	var full_pace := [0]
	var off_back := [0]
	var frames := [0]
	var begin := Time.get_ticks_msec()
	Input.action_press(Player.MOVE_FORWARD)
	await _until(func() -> bool:
		_pace()
		a.rotate_y(TURN_RATE / 60.0)
		frames[0] += 1
		if a.stack().carry >= 1.0:
			full_pace[0] += 1
		if not b.riding():
			off_back[0] += 1
		var g := b.global_position - a_seen.back.top()
		var h := b_seen.global_position - a.stack().top()
		most["rider"] = maxf(most["rider"], Vector2(g.x, g.z).length())
		most["rider_y"] = maxf(most["rider_y"], absf(g.y))
		most["seen"] = maxf(most["seen"], Vector2(h.x, h.z).length())
		most["seen_y"] = maxf(most["seen_y"], absf(h.y))
		if last["guest"] != Vector3.INF:
			var dg: Vector3 = g - last["guest"]
			var dh: Vector3 = h - last["host"]
			if frames[0] > SETTLE_FRAMES:
				most["step_guest"] = maxf(most["step_guest"], (dg - last["dg"]).length())
				most["step_host"] = maxf(most["step_host"], (dh - last["dh"]).length())
			last["dg"] = dg
			last["dh"] = dh
		last["guest"] = g
		last["host"] = h
		return Time.get_ticks_msec() - begin > LOOP_S * 1000.0, "A to walk its loop", 100000, LOOP_S)
	Input.action_release(Player.MOVE_FORWARD)
	print("STACK carried %d ms over %d frames: rider %.3f m off A's drawn disc (y %.3f), drawn on A's machine %.3f m off A's back (y %.3f); jitter %.4f (B's machine) %.4f (A's; B walking alone %.4f); full pace %d frames, off the back %d" % [
			lag_ms, frames[0], most["rider"], most["rider_y"], most["seen"], most["seen_y"], most["step_guest"], most["step_host"], alone, full_pace[0], off_back[0]])
	_drop_branches()
	return {"most": most, "off_back": off_back[0], "full_pace": full_pace[0], "alone": alone}


func case_jump_heard() -> void:
	var pair := await _joined(0)
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var a := _player(host)
	var b := _player(guest)
	var b_steps := _avatars(host).of(_session(guest).me()).get_node("Steps") as TeammateSteps
	var a_steps := _avatars(guest).of(1).get_node("Steps") as TeammateSteps
	var heard_b := b_steps.jumps
	var heard_a := a_steps.jumps
	await _climb(host, guest)
	_check(b.jumps == 1, "B's climb counts as its jump (it plays jump on B's machine)")
	await _until(func() -> bool:
		_pace()
		return b_steps.jumps == heard_b + 1, "A's machine to hear B's jump at B's body", 900, 0.1)
	await _until(func() -> bool: return a.stack().carry < 1.0, "A's machine to see B on A's back")
	b.set_input_blocked(true)
	a.set_input_blocked(false)
	Input.action_press(Player.JUMP)
	await _until(func() -> bool: return a.velocity.y > 0.1, "A's jump to leave the floor", 30)
	Input.action_release(Player.JUMP)
	await _until(func() -> bool:
		_pace()
		return a_steps.jumps == heard_a + 1, "B's machine to hear A's jump at A's body", 900, 0.1)
	await _until(func() -> bool:
		_pace()
		return a.is_on_floor() and a.velocity.y <= 0.0, "A to land")
	await _until(func() -> bool:
		_pace()
		return b.riding() and absf(b.global_position.y - Stacks.feet(_avatars(guest).of(1)).y - 1.4) < AT, "B to ride A's back again after the jump", 900, 0.3)
	_check(b_steps.jumps == heard_b + 1 and b.jumps == 1, "the rider made no jump of its own")
	_drop_branches()


func case_carrier_stands() -> void:
	var pair := await _joined(0)
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var a := _player(host)
	var b := _player(guest)
	await _climb(host, guest)
	b.set_input_blocked(true)
	a.set_input_blocked(false)
	await _until(func() -> bool: return a.stack().carry < 1.0, "A's machine to see B on A's back")
	var a_seen := _avatars(guest).of(1)
	Input.action_press(Player.CROUCH)
	await _until(func() -> bool: return a.crouching, "A to crouch", 30)
	await _until(func() -> bool:
		_pace()
		return absf(b.global_position.y - Stacks.feet(a_seen).y - 0.7) < AT, "B to ride down with A's back on B's machine", 900, 0.1)
	_check(b.riding(), "B kept its hold as A crouched (line 30)")
	await _until(func() -> bool:
		_pace()
		return absf(a.stack().load_height - (1.0 - 0.3)) < AT, "A's machine to count B's crouched body less the sink on A's crouched back", 900, 0.1)
	Input.action_release(Player.CROUCH)
	await _until(func() -> bool: return not a.crouching, "A to stand up with room for B", 30)
	await _until(func() -> bool:
		_pace()
		return absf(b.global_position.y - Stacks.feet(a_seen).y - 1.4) < AT, "B to ride up with A's back on B's machine", 900, 0.1)
	_check(b.riding(), "B kept its hold as A stood (line 30)")
	# Under a board 2.2 m up A alone could stand (1.7), but not with B's 0.7 m on its back (2.4).
	Input.action_press(Player.CROUCH)
	await _until(func() -> bool: return a.crouching, "A to crouch again", 30)
	var b_seen := _avatars(host).of(_session(guest).me())
	await _until(func() -> bool:
		_pace()
		return absf(b_seen.global_position.y - a.global_position.y - 0.7) < 0.01 and absf(a.stack().load_height - 0.7) < AT,
				"A's machine to draw B on A's crouched back", 900, 0.1)
	var board := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 0.2, 3.0)
	shape.shape = box
	board.add_child(shape)
	host.add_child(board)
	board.global_position = a.global_position + Vector3.UP * 2.3
	await _physics_ticks(2)
	_check(not a.test_move(a.global_transform, Vector3.UP * (a.tuning.stand_height - a.tuning.crouch_height)), "alone A would have room to stand there")
	Input.action_release(Player.CROUCH)
	await _physics_ticks(30)
	_check(a.crouching, "under 2.2 m A stays crouched with B on its back (line 29)")
	board.free()
	await _until(func() -> bool: return not a.crouching, "A to stand once the board is gone", 30)
	_drop_branches()


# --- Helpers ---------------------------------------------------------------------------------------

## B walks a loop alone, crouched (at the carry pace, 2 m/s), A still: the largest jitter of B's drawn
## body on A's machine once under way (the frame's move against the frame before's), the baseline any
## Teammate's drawn walk has there.
func _teammate_jitter(host: Node3D, guest: Node3D) -> float:
	var a := _player(host)
	var b := _player(guest)
	var at := (host.get_node(STATION) as Node3D).global_position + A_SPOT
	_stand(a, at, 0.0)
	_stand(b, at + Vector3(0.0, 0.0, 2.5), 0.0)
	a.set_input_blocked(true)
	b.set_input_blocked(false)
	var b_seen := _avatars(host).of(_session(guest).me())
	await _until(func() -> bool:
		_pace()
		return b_seen.global_position.distance_to(b.global_position) < 0.01, "A's machine to draw B where B stands", 900, 0.2)
	var worst := [0.0]
	var last := [Vector3.INF, Vector3.ZERO]
	var frames := [0]
	var begin := Time.get_ticks_msec()
	Input.action_press(Player.CROUCH)
	Input.action_press(Player.MOVE_FORWARD)
	await _until(func() -> bool:
		_pace()
		b.rotate_y(TURN_RATE / 60.0)
		frames[0] += 1
		var p := b_seen.global_position
		if last[0] != Vector3.INF:
			var d: Vector3 = p - last[0]
			if frames[0] > SETTLE_FRAMES:
				worst[0] = maxf(worst[0], (d - last[1]).length())
			last[1] = d
		last[0] = p
		return Time.get_ticks_msec() - begin > LOOP_S * 1000.0, "B to walk its loop alone", 100000, LOOP_S)
	Input.action_release(Player.MOVE_FORWARD)
	Input.action_release(Player.CROUCH)
	await _until(func() -> bool: return not b.crouching, "B to stand", 60)
	return worst[0]


## A stands at A_SPOT; B stands 0.7 m behind A and jumps (by its pressed jump, A's input blocked) onto
## A's back, as B's machine draws it.
func _climb(host: Node3D, guest: Node3D) -> void:
	var a := _player(host)
	var b := _player(guest)
	var at := (host.get_node(STATION) as Node3D).global_position + A_SPOT
	_stand(a, at, 0.0)
	_stand(b, at + Vector3(0.0, 0.0, 0.7), 0.0)
	var a_seen := _avatars(guest).of(1)
	await _until(func() -> bool:
		_pace()
		return a_seen.global_position.distance_to(a.global_position) < 0.01 and b.is_on_floor(), "B's machine to draw A where A stands", 900, 0.1)
	a.set_input_blocked(true)
	b.set_input_blocked(false)
	Input.action_press(Player.JUMP)
	await _until(func() -> bool: return b.velocity.y > 0.1, "B's jump to leave the floor", 30)
	Input.action_release(Player.JUMP)
	_check(b.stack().climb_to == a_seen.back, "B's jump is a climb onto A's back")
	await _until(func() -> bool:
		_pace()
		return b.riding(), "B to stand on A's back")
	_check(b.stack().ride == a_seen.back, "B rides A's back")


## A Host zoo and a Guest zoo, joined, each seeing the other's avatar: [host, guest].
func _joined(lag_ms := 0) -> Array:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	_session(host).profile = PlayerProfile.fresh()
	_session(guest).profile = PlayerProfile.fresh()
	_check(_net(host).start(["--host"]) == OK, "the Host hosts")
	if lag_ms > 0:
		_lag(host, lag_ms)
	_net(guest).start(["--join=127.0.0.1:%d" % _session(host).port])
	if lag_ms > 0:
		_lag(guest, lag_ms)
	await _until(func() -> bool: return _avatars(guest).of(1) != null and _avatars(host).of(_session(guest).me()) != null \
			and not _roster(guest).entry_of(1).is_empty(), "each to see the other's avatar")
	return [host, guest]


## Holds this frame until 1/60 s of wall time since the last paced one (teammates_test's pace).
func _pace() -> void:
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / 60
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


## Puts `lag_ms` of delay on every packet `zoo`'s machine receives (tests/support/lag_peer.gd).
func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


func _branch(label: String) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for action: StringName in [Player.JUMP, Player.MOVE_FORWARD, Player.CROUCH]:
		Input.action_release(action)
	for node in _branches:
		var session := _in_branch(node).session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


func _stand(player: Player, at: Vector3, yaw: float) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.rotation.y = yaw
	player.reset_physics_interpolation()


func _session(zoo: Node3D) -> Session:
	return LevelRuntime.of(zoo).session


func _net(zoo: Node3D) -> LevelNet:
	return LevelRuntime.of(zoo).net


func _roster(zoo: Node3D) -> Roster:
	return LevelRuntime.of(zoo).roster


func _avatars(zoo: Node3D) -> Avatars:
	return LevelRuntime.of(zoo).avatars


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


## The level runtime of the zoo in branch `node` (a machine of its own), or null.
func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
