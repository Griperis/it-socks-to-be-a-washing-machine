## The coop/01 spike (Option A of docs/migration/coop-structure-for-the-port.md section 4): thrown
## Socks carried from the Host to a Guest by Godot's own nodes. Two zoos in one process, each in a
## machine of its own (a Node with its own MultiplayerAPI and a SubViewport with its own 3D world, as
## tests/zoo_test.gd case_coop). The zoo's FlightSpawner spawns the Host's falling bodies on the
## Guest; the test adds to every body one stamped row (tests/support/flight_row.gd) and one
## MultiplayerSynchronizer that carries it, which is what flight.tscn would hold under Option A.
## One Throw through the Hands, then 16 Throws in one tick; at 0 ms and at 50 ms each way, paced at
## 60 frames a second of real time. The two everyday cases use a small zoo (only the stations whose
## Socks are placed by hand, about 30 Socks), so the Mess's answers are small and what is measured is
## the flight's own path; the stress case uses the whole zoo (about 2,000 Socks), where every Mess
## answer carries the whole poses array (about 100 KB) and the reliable channel backs up. Every number is printed as a `SPIKE` line; the report is
## docs/research/coop-flight-sync.md.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const FlightRow := preload("res://tests/support/flight_row.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const NET_WAIT_S := 20.0
const FPS := 60
## Where the 16 Throws leave from (a 4 by 4 grid over the open floor south of the stations), and
## how fast.
const BURST_FROM := Vector3(0.0, 1.5, 8.0)
const BURST_GAP := 0.45
const BURST_SPEED := 5.0
## The stations the small zoo keeps.
const SMALL := ["Handling", "Cabinet", "Outline", "Screen"]


## The engine's errors (not script errors): a synchronizer or spawner fault prints one.
class EngineErrors extends Logger:
	var mutex := Mutex.new()
	var lines: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			mutex.lock()
			lines.append(rationale if not rationale.is_empty() else code)
			mutex.unlock()


var _branches: Array[Node] = []
var _errors := EngineErrors.new()
## Per Guest copy, as it was spawned: {sock: {"frame": int, "answer_first": bool}}.
var _spawned: Dictionary[int, Dictionary] = {}
var _pace_next := 0


func _enter_tree() -> void:
	OS.add_logger(_errors)


func _exit_tree() -> void:
	OS.remove_logger(_errors)


func cases() -> Array[Dictionary]:
	return [
		{"name": "flight_0ms", "method": "case_flight_0ms", "world": false,
				"title": "coop/01, no delay: one Throw and 16 at once on the Host; the Guest's copies spawn, move and lie where the Host's did"},
		{"name": "flight_50ms", "method": "case_flight_50ms", "world": false,
				"title": "coop/01, 50 ms each way: one Throw and 16 at once on the Host; the Guest's copies spawn, move and lie where the Host's did"},
		{"name": "flight_throttled_50ms", "method": "case_flight_throttled_50ms", "world": false, "stress": true,
				"title": "coop/01, ENet's own packet throttle left on, 50 ms each way: the Guest's records end where the Host's are (numbers only: the throttle drops most rows)"},
		{"name": "flight_full_50ms", "method": "case_flight_full_50ms", "world": false, "stress": true,
				"title": "coop/01, the whole zoo, 50 ms each way: the Guest's records end where the Host's are (numbers only: the 100 KB answers back up the reliable channel)"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	FlightRow.offset = INF
	_spawned.clear()
	_drop_branches()


func case_flight_0ms() -> void:
	await _flight_round(0)


func case_flight_50ms() -> void:
	await _flight_round(50)


func case_flight_throttled_50ms() -> void:
	await _flight_round(50, true, false)


func case_flight_full_50ms() -> void:
	await _flight_round(50, false)


## With `unthrottled`, ENet's packet throttle is held at full on both ends as each peer connects
## (what the Session's EnetTransport does, coop/03); without, it is left alone: it sinks to 0 at 60 frames a second and
## then drops 31 of every 32 unreliable packets.
func _flight_round(lag_ms: int, small := true, unthrottled := true) -> void:
	var host := _branch("Host", small)
	var guest := _branch("Guest", small)
	await _frames(2)
	_hook(host, true)
	_hook(guest, false)
	var hs := host.get_node("Session") as Session
	hs.port = 0
	# Two players (a profile each, in memory); the throttle as the case asks (the transport holds it
	# at full unless told not to).
	for zoo: Node3D in [host, guest]:
		var s := zoo.get_node("Session") as Session
		s.profile = PlayerProfile.fresh()
		(s.transport as EnetTransport).full_throttle = unthrottled
	_check((host.get_node("Net") as ZooNet).start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	_check((guest.get_node("Net") as ZooNet).start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, lag_ms)
	var gm := guest.get_node("Socks/Mess") as Mess
	var hm := host.get_node("Socks/Mess") as Mess
	await _until(func() -> bool: return (guest.get_node("Net") as ZooNet).mode_text().begins_with("Joined") \
			and gm.count() == hm.count() and gm.looks_of(0) != null, "the guest zoo to be welcomed with the Host's Mess")
	_errors.lines.clear()
	var peer := host.multiplayer.multiplayer_peer as LagPeer
	# What the Host sends unreliably with nothing flying (the avatars' poses): taken off below.
	var b0 := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, 0))
	var t0 := Time.get_ticks_usec()
	for i in FPS:
		await _paced()
	var idle := float(int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, 0)) - b0) \
			/ ((Time.get_ticks_usec() - t0) / 1e6)
	var tag := "%dms%s%s" % [lag_ms, "" if small else " whole zoo", "" if unthrottled else " throttled"]
	print("SPIKE %s: %d Socks; idle unreliable from the Host: %.0f B/s" % [tag, hm.count(), idle])

	# One Throw, through the Hands' Command, from the zoo's handling station.
	var hands := host.get_node("Socks/Hands") as Hands
	var player := host.get_node("Player") as Player
	var handling := host.get_node("Stations/Handling") as Node3D
	var one := (handling.get_node("Spots/Under") as SockSpot).sock
	_stand(player, handling.to_global(Vector3(0.0, 0.0, 1.5)), 0.0)
	await _physics_ticks(2)
	hands.clock += 10.0
	hands.pick(1, one)
	await _until(func() -> bool: return hands.active_of(1) == one, "the Host to hold one Sock")
	_stand(player, Vector3(-3.0, 0.0, 8.0), PI)
	await _physics_ticks(2)
	hands.throw(1, (Vector3(0.0, 0.3, 1.0)).normalized(), 0.7)
	await _watch(host, guest, PackedInt32Array([one]), tag + " one", peer, idle, small and unthrottled)

	# 16 Throws in one tick, as the Host's answers (the benchmark's burst, Mess.thrown_patch).
	var socks := PackedInt32Array()
	for sock in hm.count():
		if socks.size() == 16:
			break
		if sock != one and hm.state_of(sock) == Mess.State.LYING and not hm.is_pair(sock):
			socks.append(sock)
	var parts := host.get_node("Parts") as Parts
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in socks.size():
		var from := BURST_FROM + Vector3((i % 4 - 1.5) * BURST_GAP, (i / 4) * BURST_GAP * 0.5, 0.0)
		var vel := Vector3(rng.randf_range(-0.3, 0.3), 0.35, 1.0).normalized() * BURST_SPEED
		var spin := Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-3.0, 3.0), rng.randf_range(-3.0, 3.0))
		parts.apply({"ok": true, "kind": &"throw", "by": 1, "to": hm.id,
				"changes": {hm.id: hm.thrown_patch(socks[i], Transform3D(Basis.from_euler(Vector3(0.0, rng.randf() * TAU, 0.0)), from), vel, spin, 1)}})
	await _watch(host, guest, socks, tag + " sixteen", peer, idle, small and unthrottled)
	var errors := _errors.lines.duplicate()
	_check(errors.is_empty(), "no engine error on either machine: %s" % ", ".join(errors.slice(0, 3)))
	_drop_branches()


## Follows `socks` from their Throw until every one lies on both machines, every frame: what the
## Guest shows (its copy's body, else the record it lies at), the Host's body, and the bytes. Prints
## the numbers and checks the rules.
## With `strict`, also that every copy moved and ended where its Sock lies.
func _watch(host: Node3D, guest: Node3D, socks: PackedInt32Array, label: String, peer: LagPeer, idle: float, strict: bool) -> void:
	var hm := host.get_node("Socks/Mess") as Mess
	var gm := guest.get_node("Socks/Mess") as Mess
	var start := Engine.get_process_frames()
	var host_hist: Dictionary[int, Array] = {}  # sock: [[frame, pos]]
	var last_guest: Dictionary[int, Vector3] = {}
	var last_host: Dictionary[int, Vector3] = {}
	var had_body: Dictionary[int, bool] = {}
	var had_host: Dictionary[int, bool] = {}
	var body_end: Dictionary[int, Vector3] = {}
	var moved: Dictionary[int, float] = {}
	var first_body: Dictionary[int, Vector3] = {}
	var answer_frame: Dictionary[int, int] = {}
	var gone := 0          # frames a Sock was flying on the Guest with no copy to show
	var twice := 0         # frames a Sock had a copy on the Guest and still lay there too
	var r0 := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0))
	var guest_step := 0.0
	var host_step := 0.0
	var rest_snap := 0.0
	var lags: Array[float] = []
	var body_frames := 0
	var b0 := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, 0))
	var t0 := Time.get_ticks_usec()
	var flying_s := 0.0
	var last_t := t0
	for sock in socks:
		last_guest[sock] = gm.pose_of(sock).origin
		last_host[sock] = hm.pose_of(sock).origin
		host_hist[sock] = []
	var done := func() -> bool:
		for sock in socks:
			if hm.state_of(sock) != Mess.State.LYING or gm.state_of(sock) != Mess.State.LYING \
					or hm.moving_body(sock) != null or gm.moving_body(sock) != null \
					or not answer_frame.has(sock):
				return false
		return true
	var frames := 0
	while not done.call() and frames < FPS * 30:
		await _paced()
		frames += 1
		var now := Engine.get_process_frames()
		var t := Time.get_ticks_usec()
		var host_flying := 0
		for sock in socks:
			var hb := hm.moving_body(sock)
			var hp: Vector3 = hb.global_position if hb != null else hm.pose_of(sock).origin
			if hb != null:
				host_flying += 1
				host_hist[sock].append([now, hp])
			if hb != null and had_host.get(sock, false):
				host_step = maxf(host_step, hp.distance_to(last_host[sock]))
			had_host[sock] = hb != null
			last_host[sock] = hp
			if gm.state_of(sock) != Mess.State.LYING and not answer_frame.has(sock):
				answer_frame[sock] = now
			var gb := gm.moving_body(sock)
			var gp: Vector3
			if gb != null:
				gp = gb.global_position
				if gm.state_of(sock) == Mess.State.LYING:
					twice += 1
				if not last_guest.has(sock) or not had_body.get(sock, false):
					last_guest[sock] = gp
				if not first_body.has(sock):
					first_body[sock] = gp
				moved[sock] = maxf(moved.get(sock, 0.0), gp.distance_to(first_body[sock]))
				had_body[sock] = true
				body_end[sock] = gp
				body_frames += 1
				var lag := _lag_of(host_hist[sock], gp, now)
				if lag >= 0.0:
					lags.append(lag)
			elif gm.state_of(sock) == Mess.State.LYING:
				gp = gm.pose_of(sock).origin
				if had_body.get(sock, false):
					rest_snap = maxf(rest_snap, gp.distance_to(body_end[sock]))
					had_body[sock] = false
			else:
				gone += 1
				last_guest.erase(sock)
				continue
			if gb != null:
				guest_step = maxf(guest_step, gp.distance_to(last_guest[sock]))
			last_guest[sock] = gp
		if host_flying > 0:
			flying_s += (t - last_t) / 1e6 * host_flying
		last_t = t
	var bytes := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, 0)) - b0
	var secs := (Time.get_ticks_usec() - t0) / 1e6
	var per_body := (bytes - idle * secs) / flying_s if flying_s > 0.0 else 0.0
	var late := 0
	var spawn_gap := 0
	for sock in socks:
		var s: Dictionary = _spawned.get(sock, {})
		if not s.is_empty():
			if bool(s["answer_first"]):
				late += 1
			spawn_gap = maxi(spawn_gap, int(s["frame"]) - int(answer_frame.get(sock, s["frame"])))
	lags.sort()
	var lag_mid := lags[lags.size() / 2] if not lags.is_empty() else -1.0
	var lag_max := lags[-1] if not lags.is_empty() else -1.0
	var lag_95 := lags[int(lags.size() * 0.95)] if not lags.is_empty() else -1.0
	var reliable := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)) - r0
	print("SPIKE %s: %d frames; largest step a frame of a flying copy: Guest %.3f m, Host body %.3f m; snap at rest %.4f m; Sock-frames shown nothing %d, shown twice %d" \
			% [label, frames, guest_step, host_step, rest_snap, gone, twice])
	print("SPIKE %s: lag behind the Host median %.3f s, 95th %.3f s, largest %.3f s (%d samples)" % [label, lag_mid, lag_95, lag_max, lags.size()])
	print("SPIKE %s: reliable from the Host %d B" % [label, reliable])
	print("SPIKE %s: spawn after the answer naming it: %d of %d, by up to %d frames" % [label, late, socks.size(), spawn_gap])
	print("SPIKE %s: unreliable from the Host %.0f B/s per flying body (%d B over %.2f s, %.2f body-seconds)" \
			% [label, per_body, bytes, secs, flying_s])
	_check(done.call(), "%s: every Sock lies on both machines (%d frames)" % [label, frames])
	for sock in socks:
		_check(_spawned.has(sock), "%s: Sock %d's copy was spawned on the Guest" % [label, sock])
		_check(gm.pose_of(sock).is_equal_approx(hm.pose_of(sock)), "%s: Sock %d lies on the Guest where it lies on the Host" % [label, sock])
		if strict:
			_check(moved.get(sock, 0.0) > 0.3, "%s: Sock %d's copy moved on the Guest (%.2f m)" % [label, sock, moved.get(sock, 0.0)])
	if strict:
		_check(rest_snap < 0.05, "%s: a copy ends within 5 cm of where its Sock lies (%.4f m)" % [label, rest_snap])


## How far behind the Host a Guest copy at `pos` is: the frames since the Host's body was nearest
## that place in its last 60 frames, as seconds; -1 while it barely moves (the place is ambiguous).
static func _lag_of(hist: Array, pos: Vector3, now: int) -> float:
	if hist.size() < 2:
		return -1.0
	var newest: Array = hist[-1]
	var before: Array = hist[-2]
	if (newest[1] as Vector3).distance_to(before[1]) < 0.02:
		return -1.0
	var best := INF
	var at := -1
	for i in range(maxi(0, hist.size() - 60), hist.size()):
		var d := (hist[i][1] as Vector3).distance_to(pos)
		if d < best:
			best = d
			at = int(hist[i][0])
	return float(now - at) / FPS


## Every Flight body that enters this machine's `Flights` gets a Row and a synchronizer carrying it
## (the Host's spawn packet then holds the first row); on the Guest the body is frozen, kinematic,
## and noted: when it came, and whether the Host's answer naming it was already there.
func _hook(zoo: Node3D, host_side: bool) -> void:
	var flights := zoo.get_node("Flights") as Node3D
	var mess := zoo.get_node("Socks/Mess") as Mess
	flights.child_entered_tree.connect(func(node: Node) -> void:
		var body := node as RigidBody3D
		if body == null or not String(body.name).begins_with(Mess.FLIGHT_PREFIX):
			return
		var sock := int(String(body.name).trim_prefix(Mess.FLIGHT_PREFIX))
		if host_side:
			# The spawn packet (with the first row) is made when the body is ready, inside add_child;
			# MessMoving._launch sets the pose only after add_child. Under Option A it sets it before.
			body.global_transform = mess.pose_of(sock)
		if not host_side:
			_spawned[sock] = {"frame": Engine.get_process_frames(), "answer_first": mess.state_of(sock) == Mess.State.FLYING}
			body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			body.freeze = true
		var row := FlightRow.new()
		row.name = "Row"
		row.host_side = host_side
		body.add_child(row)
		var sync := MultiplayerSynchronizer.new()
		sync.name = "Sync"
		var config := SceneReplicationConfig.new()
		config.add_property(^"Row:row")
		config.property_set_spawn(^"Row:row", true)
		config.property_set_replication_mode(^"Row:row", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		sync.replication_config = config
		sync.replication_interval = 0.0
		body.add_child(sync))


## One frame, then a wait until the next 1/60 s of wall time: the engine runs frames as fast as it
## can under the runner's --fixed-fps, so network delays (real time) and frames would not match.
func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _stand(player: Player, at: Vector3, turn: float) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.rotation.y = turn
	(player.get_node("Head") as Node3D).rotation.x = 0.0
	player.reset_physics_interpolation()


func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## A zoo in a machine of its own (tests/zoo_test.gd _branch); `small` keeps only the SMALL stations.
func _branch(label: String, small: bool) -> Node3D:
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
	if small:
		for station in zoo.get_node("Stations").get_children():
			if not SMALL.has(String(station.name)):
				station.get_parent().remove_child(station)
				station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var session := node.get_node_or_null("View/Zoo/Session") as Session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
