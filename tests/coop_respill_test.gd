## coop/07: a Guest stays joined through the heap station's Respill and a 2,000-Sock pour. Two whole
## zoos in one process, each a machine of its own (tests/coop_flight_test.gd), real ENet over
## 127.0.0.1 with tests/support/lag_peer.gd on both ends for the delay and the byte count, frames
## paced to 60 a second of wall time (ENet's timeouts run on wall time). The Host's player clicks
## More, then Respill (or More with a batch of 2,000); every answer of the Mess goes down to the
## Guest. The Guest must stay joined, neither machine may print an engine error or warning (a Jolt
## buffer overflow), and the Guest's Mess must end equal to the Host's once every Sock rests. Reliable
## bytes a second from the Host are printed as `RESPILL` lines (the ticket's Built log has the numbers).
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const HEAP := "Stations/Heap"
const NET_WAIT_S := 20.0
const FPS := 60
## The large pour (the ticket's 2,000 Socks).
const LARGE := 2000
## The longest a pour may take to come to rest, in paced frames (a minute and a half).
const SETTLE_FRAMES := FPS * 90

var _branches: Array[Node] = []
var _pace_next := 0
## When the Guest's session ended, and why ("" while it is joined).
var _ended := ""
var _ended_frame := -1


func cases() -> Array[Dictionary]:
	return [
		{"name": "respill_0ms", "method": "case_respill_0ms", "world": false,
				"title": "coop/07, real path, no delay: the Host clicks More, then Respill; the Guest stays joined and its Mess ends equal to the Host's"},
		{"name": "respill_50ms", "method": "case_respill_50ms", "world": false, "stress": true,
				"title": "coop/07, 50 ms each way: More, then Respill; the Guest stays joined and its Mess ends equal to the Host's"},
		{"name": "pour_0ms", "method": "case_pour_0ms", "world": false, "stress": true,
				"title": "coop/07, no delay: the Host pours 2,000 Socks; the Guest stays joined and its Mess ends equal to the Host's"},
		{"name": "pour_50ms", "method": "case_pour_50ms", "world": false, "stress": true,
				"title": "coop/07, 50 ms each way: the Host pours 2,000 Socks; the Guest stays joined and its Mess ends equal to the Host's"},
	]


## The engine's errors and warnings on either machine (a Jolt buffer overflow is a warning).
class EngineErrors extends Logger:
	var mutex := Mutex.new()
	var lines: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		mutex.lock()
		lines.append((rationale if not rationale.is_empty() else code).left(70))
		mutex.unlock()


var _errors := EngineErrors.new()


func _enter_tree() -> void:
	OS.add_logger(_errors)


func _exit_tree() -> void:
	OS.remove_logger(_errors)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(&"pick")
	_ended = ""
	_ended_frame = -1
	_drop_branches()


func case_respill_0ms() -> void:
	await _round(0, false)


func case_respill_50ms() -> void:
	await _round(50, false)


func case_pour_0ms() -> void:
	await _round(0, true)


func case_pour_50ms() -> void:
	await _round(50, true)


## A Host and a Guest, `lag_ms` each way. `large`: one pour of LARGE Socks; else More (the station's
## batch), then Respill (the heap taken out and a fresh batch poured).
func _round(lag_ms: int, large: bool) -> void:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	gs.ended.connect(func(text: String) -> void:
		_ended = text
		_ended_frame = Engine.get_process_frames())
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, lag_ms)
	var hm := LevelRuntime.of(host).mess
	var gm := LevelRuntime.of(guest).mess
	await _until(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") \
			and gm.count() == hm.count(), "the guest zoo to be welcomed with the Host's Mess")
	var tag := "%dms" % lag_ms
	var peer := host.multiplayer.multiplayer_peer as LagPeer
	var spout := host.get_node(HEAP + "/Spout/HeapSpout") as HeapSpout
	_errors.lines.clear()
	if large:
		var t := spout.tuning.duplicate() as HeapTuning
		t.batch = LARGE
		spout.tuning = t
	var batch := spout.tuning.batch
	await _click(host, "More")
	await _until(func() -> bool: return spout.asked == 1, "the click on More to be answered")
	await _settle(host, guest, spout, batch, "%s %s" % [tag, "pour of %d" % batch], peer)
	if not large and gs.is_online():
		# Respill: the heap goes (take_out) and a fresh batch pours.
		await _click(host, "Respill")
		await _until(func() -> bool: return spout.respills == 1, "the click on Respill to be answered")
		await _until(func() -> bool: return hm.count() < spout.first + batch, "the old heap to be taken out")
		await _settle(host, guest, spout, batch, tag + " respill", peer)
	var counts := {}
	for line in _errors.lines:
		counts[line] = int(counts.get(line, 0)) + 1
	print("RESPILL %s: engine errors and warnings on either machine: %s" % [tag, counts])
	_check(_errors.lines.is_empty(), "%s: no engine error or warning on either machine (%s)" % [tag, counts.keys().slice(0, 2)])
	_drop_branches()


## Paces frames until `n` heap Socks were poured and every Sock rests on both machines (or the Guest
## is gone); prints the reliable bytes; checks the Guest is still joined and its Mess is the Host's.
func _settle(host: Node3D, guest: Node3D, spout: HeapSpout, n: int, label: String, peer: LagPeer) -> void:
	var hm := LevelRuntime.of(host).mess
	var gm := LevelRuntime.of(guest).mess
	var gs := LevelRuntime.of(guest).session
	var r0 := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0))
	var p0 := int(peer.sent_packets.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0))
	var t0 := Time.get_ticks_usec()
	var worst_second := 0
	var second_from := r0
	var second_at := t0
	var frames := 0
	var rested := func() -> bool:
		return spout.first >= 0 and hm.count() - spout.first >= n and spout.pending() == 0 \
				and not hm.states.has(Mess.State.FLYING) and hm.waiting_count() == 0 \
				and gm.count() == hm.count() and not gm.states.has(Mess.State.FLYING)
	while frames < SETTLE_FRAMES and gs.is_online() and not rested.call():
		await _paced()
		frames += 1
		var now := Time.get_ticks_usec()
		if now - second_at >= 1000000:
			var sent := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0))
			worst_second = maxi(worst_second, sent - second_from)
			second_from = sent
			second_at = now
	var secs := (Time.get_ticks_usec() - t0) / 1e6
	var bytes := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)) - r0
	var packets := int(peer.sent_packets.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)) - p0
	print("RESPILL %s: %d frames, %.1f s; reliable from the Host %d B in %d packets: %.0f B/s, worst second %d B; Guest %s" \
			% [label, frames, secs, bytes, packets, bytes / maxf(secs, 0.001), worst_second,
			"joined" if gs.is_online() else "gone at frame %d: %s" % [_ended_frame, _ended]])
	_check(gs.is_online(), "%s: the Guest stays joined (%s)" % [label, _ended if _ended != "" else "online"])
	if not gs.is_online():
		return
	_check(rested.call(), "%s: every Sock rests on both machines within %d frames (Host %d of %d flying, Guest %d)" \
			% [label, frames, hm.states.count(Mess.State.FLYING), hm.count(), gm.states.count(Mess.State.FLYING)])
	_same(gm.state(), hm.state(), "%s: the Guest's Mess equals the Host's" % label)


## The Host's player stands before heap button `button`, aims at it and clicks (the pick action).
func _click(zoo: Node3D, button: String) -> void:
	var station := zoo.get_node(HEAP) as Node3D
	var target := (station.get_node(button) as Node3D).global_position
	var player := LevelRuntime.of(zoo).player
	player.capture_mouse()   # the mouse is the Host player's: buttons act (R01); the Guest's is not
	player.global_position = target + station.global_basis * Vector3(0.0, -0.5, -1.5)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _physics_ticks(2)


## One frame, then a wait until the next 1/60 s of wall time (tests/coop_flight_test.gd _paced).
func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## A whole zoo in a machine of its own: its own MultiplayerAPI and 3D world.
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
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var session := _in_branch(node).session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


## The level runtime of the zoo in branch `node` (a machine of its own), or null.
func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
