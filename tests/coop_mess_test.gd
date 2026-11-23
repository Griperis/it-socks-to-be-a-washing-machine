## coop/08: the Mess's moving Socks on every machine (docs/migration/coop-mess-sync.md, Q2472). Two
## whole zoos in one process, each a machine of its own (tests/coop_respill_test.gd), real ENet over
## 127.0.0.1 with tests/support/lag_peer.gd on both ends, frames paced to 60 a second of wall time.
## A woken, fallen, poured or swept Sock is a body on each machine, started from the Host's answer
## (on a Guest a looks-only body that writes nothing shared), and snaps to the Host's rest batch. The
## join carries the Mess packed and compressed, a flying Sock with its motion. Numbers are printed as
## `MESS` lines (the ticket's Built log has them).
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const HEAP := "Stations/Heap"
const NET_WAIT_S := 20.0
const FPS := 60
## The one-way delay the real path also runs at (coop/12).
const LAG_MS := 50
## The real-path pour (the ticket's 200 Socks) and the large one (2,000).
const POUR := 200
const LARGE := 2000
## The longest a pour may take to come to rest, in paced frames.
const SETTLE_FRAMES := FPS * 90
## A late joiner's body starts within this of where the Host's body was when the snapshot was made,
## plus how far that body went until the welcome (in-process, a few frames at 0 ms).
const START_SLACK := 0.05

var _branches: Array[Node] = []
var _pace_next := 0
## The Commands the Guest's machine sent up (its Parts' relay, wrapped).
var _guest_asked: Array[Command] = []
## Per machine (0 the Host, 1 the Guest): the Mess's script time of each physics tick, in µs.
var _tick_us: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array()]


func cases() -> Array[Dictionary]:
	return [
		{"name": "pour_real_path", "method": "case_pour_real_path", "world": false,
				"title": "coop/08, real path, 0 and 50 ms one way: the Host's player clicks More (200 Socks); the Guest shows each Sock falling as a body of its own from the Host's answer, writes nothing shared, and ends with the Host's records and poses"},
		{"name": "throw_into_heap", "method": "case_throw_into_heap", "world": false,
				"title": "coop/08: a Throw into a heap on the Host: the Guest shows the woken Socks tumbling as its own bodies, then snapped to the Host's rest"},
		{"name": "drawer_sweep", "method": "case_drawer_sweep", "world": false,
				"title": "coop/08: a drawer opening on the Host over lying Socks: the Guest shows them moving and ends equal; a drawer moving on a Guest alone sweeps its own Socks as looks only and they go back where they lay"},
		{"name": "leave_mid_pour", "method": "case_leave_mid_pour", "world": false,
				"title": "coop/12, coop/08 follow-up: a Guest leaving mid-pour with a Throw in the air, and a Guest whose Host quits, each play on alone: no looks-only body or frozen Throw copy is left, every Sock that flew rests by this machine's own bodies"},
		{"name": "late_join_pour", "method": "case_late_join_pour", "world": false,
				"title": "coop/08: a Guest joining mid-pour starts each flying Sock's body from where the Host's is, and ends equal; the join is packed and compressed"},
		{"name": "pour_2000_0ms", "method": "case_pour_2000_0ms", "world": false, "stress": true,
				"title": "coop/08, no delay: a 2,000-Sock pour with a Guest; reliable bytes a second, the Guest's Mess ticks against the Host's, a late join's size mid-pour"},
		{"name": "pour_2000_50ms", "method": "case_pour_2000_50ms", "world": false, "stress": true,
				"title": "coop/08, 50 ms each way: a 2,000-Sock pour with a Guest; reliable bytes a second, the Guest's Mess ticks against the Host's"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(&"pick")
	_guest_asked.clear()
	_tick_us = [PackedInt32Array(), PackedInt32Array()]
	_drop_branches()


# --- The cases -----------------------------------------------------------------------------------

func case_pour_real_path() -> void:
	for lag_ms: int in [0, LAG_MS]:
		await _pour_round(lag_ms)


func _pour_round(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var spout := _spout(host, POUR)
	var first_count := hm.count()
	await _click(host, "More")
	await _until(func() -> bool: return spout.asked == 1, "the click on More to be answered")
	# Every paced frame: each Sock the Guest's records have FLYING (none is a Throw here) has a body
	# of the Guest's own there and then; count those that moved from where they started.
	var started: Dictionary[int, Vector3] = {}
	var moved: Dictionary[int, bool] = {}
	var without := 0
	var most_moving := 0
	var spawned := 0
	var frames := 0
	while frames < SETTLE_FRAMES and not _rested(hm, gm, spout, POUR):
		await _paced()
		frames += 1
		most_moving = maxi(most_moving, gm.moving_count())
		spawned = maxi(spawned, LevelRuntime.of(guest).flights.get_child_count())
		for sock in range(first_count, gm.count()):
			if gm.state_of(sock) != Mess.State.FLYING:
				continue
			var body := gm.moving_body(sock)
			if body == null:
				without += 1
				continue
			if not started.has(sock):
				started[sock] = body.global_position
			elif body.global_position.distance_to(started[sock]) > 0.1:
				moved[sock] = true
	print("MESS real path %d ms: %d frames; the Guest showed %d of %d poured Socks as bodies, %d moved; most moving on the Guest %d" \
			% [lag_ms, frames, started.size(), POUR, moved.size(), most_moving])
	_check(without == 0, "every Sock the Guest has flying has a body there in the same frame (%d frame-Socks without)" % without)
	_check(started.size() == POUR, "the Guest showed every poured Sock as a body (%d of %d)" % [started.size(), POUR])
	_check(moved.size() >= POUR * 0.9, "the Guest's bodies fall, not only rest (%d of %d moved)" % [moved.size(), POUR])
	_check(most_moving > 0, "the heap sign's Moving count on the Guest reads its own bodies (most %d)" % most_moving)
	_check(spawned == 0, "no poured Sock comes over the spawner (%d copies)" % spawned)
	_check(_rested(hm, gm, spout, POUR), "every Sock rests on both machines within %d frames" % frames)
	_same(gm.state(), hm.state(), "the Guest's records and poses equal the Host's")
	_check(_guest_asked.is_empty(), "the Guest's machine asked nothing (%s)" % [_kinds(_guest_asked)])
	_drop_branches()


func case_throw_into_heap() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var spout := _spout(host, POUR)
	await _click(host, "More")
	await _settle(host, guest, spout, POUR, "throw heap")
	# A Throw from 2 m beside the heap, straight at its middle, fast (the Host's Hands' answer).
	var heap_at := (host.get_node(HEAP + "/Spout") as Node3D).global_position
	heap_at.y = 0.15
	var sock := _loose_lying(hm, 0, spout.first)
	var from := heap_at + Vector3(-2.0, 0.5, 0.0)
	var vel := (heap_at - from).normalized() * 8.0
	var parts := LevelRuntime.of(host).parts
	parts.apply({"ok": true, "kind": &"throw", "by": Parts.HOST, "to": hm.id,
			"changes": {hm.id: hm.thrown_patch(sock, Transform3D(Basis.IDENTITY, from), vel, Vector3.ZERO, Parts.HOST)}})
	var woken: Dictionary[int, bool] = {}
	var local_bodies: Dictionary[int, bool] = {}
	var frames := 0
	while frames < SETTLE_FRAMES and (frames < 10 or not _rested(hm, gm, spout, POUR)):
		await _paced()
		frames += 1
		for s in range(spout.first, gm.count()):
			if gm.state_of(s) != Mess.State.FLYING:
				continue
			woken[s] = true
			var body := gm.moving_body(s)
			if body != null and body.get_parent() != LevelRuntime.of(guest).flights:
				local_bodies[s] = true
	print("MESS throw: %d heap Socks woken on the Host and shown on the Guest; %d as the Guest's own bodies" % [woken.size(), local_bodies.size()])
	_check(not woken.is_empty(), "the Throw wakes Socks of the heap")
	_check(local_bodies.size() == woken.size(), "the Guest shows every woken Sock tumbling as its own body (%d of %d)" % [local_bodies.size(), woken.size()])
	_check(_rested(hm, gm, spout, POUR), "every Sock rests again on both machines")
	_same(gm.state(), hm.state(), "the Guest's woken Socks are snapped to the Host's rest")
	_check(_guest_asked.is_empty(), "the Guest's machine asked nothing (%s)" % [_kinds(_guest_asked)])
	_drop_branches()


func case_drawer_sweep() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var hd := _drawer(host)
	var gd := _drawer(guest)
	_check(not hd.locked, "the zoo Cabinet's first drawer is not locked")
	var slide := await _slide_dir(host, hd)
	await _until(func() -> bool: return not gd.open and not gd.is_moving(), "the Guest's drawer to be shut")
	# Three loose lying Socks set just before the shut drawer's front (a zoo button's answer on the Host).
	var socks := _before_front(host, hd, slide)
	await _until(func() -> bool: return gm.pose_of(socks[0]).is_equal_approx(hm.pose_of(socks[0])), "the Guest to lie them there too")
	# The Host opens it: the Guest shows them moving, then lying where the Host's lie.
	await _open(host, hd, true)
	var shown: Dictionary[int, bool] = {}
	var frames := 0
	while frames < SETTLE_FRAMES and (frames < 10 or hd.is_moving() or gd.is_moving() or not _all_lie(hm, gm)):
		await _paced()
		frames += 1
		for s in socks:
			if gm.moving_body(s) != null:
				shown[s] = true
	print("MESS drawer: %d of %d Socks before the front shown moving on the Guest" % [shown.size(), socks.size()])
	_check(hd.open and gd.open, "the drawer is open on both machines")
	_check(shown.size() == socks.size(), "the Guest shows every Sock the drawer sweeps moving (%d of %d)" % [shown.size(), socks.size()])
	_check(_all_lie(hm, gm), "every Sock lies again on both machines")
	_same(gm.state(), hm.state(), "the Guest's swept Socks end where the Host's lie")
	# A Guest's own sweep, alone (the drawer shown opening on the Guest only: the test's stand-in for a
	# Guest whose drawer moves before the Host's answers): looks only, its records never change, and its
	# Socks go back where they lay.
	await _open(host, hd, false)
	await _until(func() -> bool: return not hd.open and not gd.open and not hd.is_moving() and not gd.is_moving() \
			and _all_lie(hm, gm), "the drawer to be shut on both machines")
	var again := _before_front(host, hd, slide)
	await _until(func() -> bool: return gm.pose_of(again[0]).is_equal_approx(hm.pose_of(again[0])), "the Guest to lie them before the front again")
	var before := gm.state()
	gd.write({"open": true}, false)
	var swept: Dictionary[int, bool] = {}
	var stayed := true
	frames = 0
	while frames < SETTLE_FRAMES and (frames < 10 or gd.is_moving() or gm.moving_count() > 0):
		await _paced()
		frames += 1
		for s in again:
			if gm.moving_body(s) != null:
				swept[s] = true
		stayed = stayed and gm.states == before["states"] and gm.poses == before["poses"]
	print("MESS drawer on the Guest alone: %d of %d Socks swept there as looks" % [swept.size(), again.size()])
	_check(swept.size() == again.size(), "the Guest's own drawer sweeps its own lying Socks (%d of %d)" % [swept.size(), again.size()])
	_check(stayed, "the Guest's sweep changed no record")
	_same(gm.state(), before, "the Guest's records are as before")
	for s in again:
		_check(gm.is_drawn(s) and gm.moving_body(s) == null and gm.box_of(s).has_volume(), "Sock %d lies where its record says again, drawn, with its body" % s)
	_check(not hm.states.has(Mess.State.FLYING) and hm.moving_count() == 0, "nothing moved on the Host")
	_check(_guest_asked.is_empty(), "the Guest's machine asked nothing (%s)" % [_kinds(_guest_asked)])
	_drop_branches()


func case_leave_mid_pour() -> void:
	for host_quits: bool in [false, true]:
		await _leave_round(host_quits)


## The Host pours and throws one Sock; while they fly the Guest leaves (or the Host quits). The Guest,
## alone now, must end with every Sock lying and no body of the session's left.
func _leave_round(host_quits: bool) -> void:
	var label := "the Host quits" if host_quits else "the Guest leaves"
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var spout := _spout(host, POUR)
	await _click(host, "More")
	await _until(func() -> bool: return spout.first >= 0 and gm.count() == hm.count() and gm.moving_count() >= POUR / 4,
			"%s: a share of the pour to fly on the Guest" % label)
	var heap_at := (host.get_node(HEAP + "/Spout") as Node3D).global_position
	var sock := _loose_lying(hm, 0, spout.first)
	var from := heap_at + Vector3(-3.0, 1.5, 0.0)
	LevelRuntime.of(host).parts.apply({"ok": true, "kind": &"throw", "by": Parts.HOST, "to": hm.id,
			"changes": {hm.id: hm.thrown_patch(sock, Transform3D(Basis.IDENTITY, from), Vector3(0.0, 5.0, 1.0), Vector3.ZERO, Parts.HOST)}})
	await _until(func() -> bool: return gm.moving_body(sock) != null and FlightRow.of(gm.moving_body(sock)) != null,
			"%s: the Guest's stamped copy of the Throw" % label)
	await _paced_frames(3)
	var flying_then := 0
	for s in gm.count():
		if gm.state_of(s) == Mess.State.FLYING:
			flying_then += 1
	if host_quits:
		LevelRuntime.of(host).session.close()
	else:
		LevelRuntime.of(guest).session.close()
	await _until(func() -> bool: return not LevelRuntime.of(guest).session.is_online(), "%s: the Guest is alone" % label)
	var looks_left := 0
	var frames := 0
	while frames < SETTLE_FRAMES and (gm.states.has(Mess.State.FLYING) or gm.moving_count() > 0):
		await _paced()
		frames += 1
		for body in gm.flight_bodies():
			if body.collision_layer == Mess.LAYER_LOOKS or body.freeze:
				looks_left += 1
	print("MESS leave (%s): %d Socks flying at the leave; all lie %d frames later" % [label, flying_then, frames])
	_check(flying_then > POUR / 4, "%s: Socks were flying on the Guest at the leave (%d)" % [label, flying_then])
	_check(looks_left == 0, "%s: no looks-only body or frozen Throw copy is left on the Guest after it (%d frame-bodies)" % [label, looks_left])
	_check(not gm.states.has(Mess.State.FLYING) and gm.flight_bodies().is_empty(), "%s: every Sock lies on the Guest, with no body left" % label)
	_check(gm.state_of(sock) == Mess.State.LYING, "%s: the Throw lies too" % label)
	_drop_branches()


func _paced_frames(n: int) -> void:
	for _i in n:
		await _paced()


func case_late_join_pour() -> void:
	await _late_join(500, 0)


func case_pour_2000_0ms() -> void:
	await _late_join(LARGE, 0)


func case_pour_2000_50ms() -> void:
	await _late_join(LARGE, 50)


# --- The rounds ----------------------------------------------------------------------------------

## The Host alone pours `n`; a Guest joins `lag_ms` away once a good share of the Socks fly. Its
## bodies must start where the Host's are; once all rest, the two Messes are equal. Prints the join's
## size, the reliable bytes a second from the welcome on and the two Messes' tick times.
func _late_join(n: int, lag_ms: int) -> void:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	var hm := _mess(host)
	var gm := _mess(guest)
	var tag := "%d at %dms" % [n, lag_ms]
	print("MESS join %s: a fresh zoo's Mess (%d Socks) packs to %d bytes; whole fields would be %d" \
			% [tag, hm.count(), var_to_bytes(LevelRuntime.of(host).parts.snapshot()).size(), var_to_bytes(hm.state()).size()])
	var spout := _spout(host, n)
	await _click(host, "More")
	var want := mini(n / 2, hm.bodies_tuning().moving_budget / 2)
	await _until(func() -> bool: return hm.count() - maxi(spout.first, 0) >= n / 2 and hm.moving_count() >= want,
			"half the pour to be out with many flying", FPS * 60)
	var peer := host.multiplayer.multiplayer_peer as LagPeer
	var r0 := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0))
	# The Host's bodies as the snapshot is made (the welcome is sent in the frame the Guest joins).
	var at_welcome: Dictionary[int, Vector3] = {}
	var host_at: Dictionary[int, Array] = {}
	var not_flying := [0]
	gs.welcomed.connect(func() -> void:
		for sock in gm.count():
			var body := gm.moving_body(sock)
			if body != null:
				at_welcome[sock] = body.global_position
				if gm.state_of(sock) != Mess.State.FLYING:
					not_flying[0] += 1)
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, lag_ms)
	_spy(guest)
	var frames := 0
	var note := func() -> void:
		for sock in hm.count():
			var body := hm.moving_body(sock)
			if body != null:
				if not host_at.has(sock):
					host_at[sock] = []
				(host_at[sock] as Array).append(body.global_position)
	while frames < FPS * 20 and at_welcome.is_empty():
		# Every frame until the welcome, and the frame of it: where each of the Host's bodies is (the
		# snapshot is made in one of these frames, during the network poll, between two physics steps).
		note.call()
		await _paced()
		frames += 1
	note.call()
	var join_bytes := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)) - r0
	print("MESS join %s: mid-pour, %d Socks (%d flying on the Host): %d reliable bytes from the Host until the welcome; the snapshot packs to %d bytes" \
			% [tag, hm.count(), hm.moving_count(), join_bytes, var_to_bytes(LevelRuntime.of(host).parts.snapshot()).size()])
	_check(not at_welcome.is_empty(), "the Guest is welcomed with flying Socks as bodies (%d)" % at_welcome.size())
	# Each body starts on the path the Host's took between the snapshot and the welcome.
	var off := 0
	var worst := 0.0
	for sock: int in at_welcome:
		if not host_at.has(sock):
			continue
		var best := INF
		for p: Vector3 in host_at[sock]:
			best = minf(best, p.distance_to(at_welcome[sock]))
		worst = maxf(worst, best)
		if best > START_SLACK:
			off += 1
	print("MESS join %s: %d bodies started on the Guest; the farthest from the Host's path %.3f m" % [tag, at_welcome.size(), worst])
	_check(off == 0, "every flying Sock's body starts on the Guest where the Host's was (%d farther than %.2f m; worst %.3f)" % [off, START_SLACK, worst])
	_check(not_flying[0] == 0, "each body started is of a Sock the Guest's records have flying (%d not)" % not_flying[0])
	var r1 := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0))
	var t0 := Time.get_ticks_usec()
	_time_ticks(host, 0)
	_time_ticks(guest, 1)
	frames = 0
	var worst_second := 0
	var second_from := r1
	var second_at := t0
	while frames < SETTLE_FRAMES and gs.is_online() and not _rested(hm, gm, spout, n):
		await _paced()
		frames += 1
		var now := Time.get_ticks_usec()
		if now - second_at >= 1000000:
			var sent := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0))
			worst_second = maxi(worst_second, sent - second_from)
			second_from = sent
			second_at = now
	var secs := (Time.get_ticks_usec() - t0) / 1e6
	var bytes := int(peer.sent_bytes.get(MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)) - r1
	print("MESS pour %s: %.1f s from the welcome to all at rest; reliable from the Host %d B: %.0f B/s, worst second %d B" \
			% [tag, secs, bytes, bytes / maxf(secs, 0.001), worst_second])
	print("MESS ticks %s: the Mess's scripts a tick, Host %s, Guest %s" % [tag, _tick_text(0), _tick_text(1)])
	print("MESS join %s: once all rest, %d Socks, the snapshot packs to %d bytes" % [tag, hm.count(), var_to_bytes(LevelRuntime.of(host).parts.snapshot()).size()])
	_check(gs.is_online(), "%s: the Guest stays joined" % tag)
	_check(_rested(hm, gm, spout, n), "%s: every Sock rests on both machines" % tag)
	_same(gm.state(), hm.state(), "%s: the late Guest's Mess ends equal to the Host's" % tag)
	_check(_guest_asked.is_empty(), "the Guest's machine asked nothing (%s)" % [_kinds(_guest_asked)])
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## A Host and a Guest `lag_ms` each way, the Guest welcomed with the Host's Mess. [host, guest]
func _pair(lag_ms: int) -> Array[Node3D]:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, lag_ms)
	var hm := _mess(host)
	var gm := _mess(guest)
	await _until(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") \
			and gm.count() == hm.count(), "the guest zoo to be welcomed with the Host's Mess")
	_spy(guest)
	return [host, guest]


## From now on every Command the Guest's machine sends up is noted.
func _spy(guest: Node3D) -> void:
	var parts := LevelRuntime.of(guest).parts
	var up := parts.relay
	parts.relay = func(cmd: Command) -> void:
		_guest_asked.append(cmd)
		if up.is_valid():
			up.call(cmd)


func _kinds(cmds: Array[Command]) -> String:
	var out := PackedStringArray()
	for cmd: Command in cmds.slice(0, 4):
		out.append("%s to %s" % [cmd.kind, cmd.to])
	return ", ".join(out)


func _mess(zoo: Node3D) -> Mess:
	return LevelRuntime.of(zoo).mess


## The heap station's spout with a batch of `n`.
func _spout(zoo: Node3D, n: int) -> HeapSpout:
	var spout := zoo.get_node(HEAP + "/Spout/HeapSpout") as HeapSpout
	var t := spout.tuning.duplicate() as HeapTuning
	t.batch = n
	spout.tuning = t
	return spout


func _rested(hm: Mess, gm: Mess, spout: HeapSpout, n: int) -> bool:
	return spout.first >= 0 and hm.count() - spout.first >= n and spout.pending() == 0 and _all_lie(hm, gm)


func _all_lie(hm: Mess, gm: Mess) -> bool:
	return not hm.states.has(Mess.State.FLYING) and hm.waiting_count() == 0 and gm.count() == hm.count() \
			and not gm.states.has(Mess.State.FLYING) and gm.moving_count() == 0


## Paces frames until the pour of `n` rests on both machines; checks the two Messes are equal.
func _settle(host: Node3D, guest: Node3D, spout: HeapSpout, n: int, label: String) -> void:
	var hm := _mess(host)
	var gm := _mess(guest)
	var frames := 0
	while frames < SETTLE_FRAMES and not _rested(hm, gm, spout, n):
		await _paced()
		frames += 1
	_check(_rested(hm, gm, spout, n), "%s: every Sock rests on both machines within %d frames" % [label, frames])
	_same(gm.state(), hm.state(), "%s: the Guest's Mess equals the Host's" % label)


## A loose lying Sock with an id from `lo` to `hi`.
func _loose_lying(mess: Mess, lo: int, hi: int) -> int:
	for sock in range(lo, hi):
		if mess.state_of(sock) == Mess.State.LYING and not mess.is_pair(sock):
			return sock
	return -1


## The zoo Cabinet's first drawer.
func _drawer(zoo: Node3D) -> Openable:
	return (zoo.get_node("Stations/Cabinet").find_children("*", "Cabinet", true, false)[0] as Cabinet).drawer(0)


## The box drawer `drawer`'s moving body takes now, in the level.
func _drawer_box(drawer: Openable) -> AABB:
	var body := drawer.movers()[0]
	var box := AABB()
	var first := true
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		var b := shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## The Host's player steps beside drawer `drawer` and asks it open or shut (the Host's answer).
func _open(host: Node3D, drawer: Openable, open: bool) -> void:
	var player := LevelRuntime.of(host).player
	# Beside the Cabinet, out of the drawer's way; the Host's avatar takes the place in a few ticks
	# (what the reach check reads).
	var cabinet := drawer.get_parent() as Node3D
	var at := drawer.movers()[0].global_position + cabinet.global_basis.x.normalized() * 1.5
	player.global_position = Vector3(at.x, 0.0, at.z)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	await _physics_ticks(4)
	LevelRuntime.of(host).parts.ask(Command.new(&"open", Parts.HOST, drawer.id, {"open": open}))


## The flat way drawer `drawer` slides out: it is opened and shut again on the Host, and its body's
## two places read. It ends shut.
func _slide_dir(host: Node3D, drawer: Openable) -> Vector3:
	var shut_at := drawer.movers()[0].global_position
	await _open(host, drawer, true)
	await _until(func() -> bool: return drawer.open and not drawer.is_moving(), "the drawer to open")
	var d := drawer.movers()[0].global_position - shut_at
	await _open(host, drawer, false)
	await _until(func() -> bool: return not drawer.open and not drawer.is_moving(), "the drawer to shut")
	await _physics_ticks(2)
	d.y = 0.0
	_check(d.length() > 0.05, "the drawer slides out (%.2f m)" % d.length())
	return d.normalized() if d.length() > 0.0001 else Vector3.FORWARD


## Three loose lying Socks are put down (a zoo button's answer on the Host) just before shut drawer
## `drawer`'s front, in the way it slides out (`slide`), side by side.
func _before_front(host: Node3D, drawer: Openable, slide: Vector3) -> PackedInt32Array:
	var hm := _mess(host)
	var box := _drawer_box(drawer)
	var reach := absf(box.size.x * slide.x) + absf(box.size.z * slide.z)
	var edge := box.get_center() + slide * (reach * 0.5 + 0.07)
	var across := Vector3(-slide.z, 0.0, slide.x)
	var p := {}
	var socks := PackedInt32Array()
	var sock := 0
	while socks.size() < 3:
		sock = _loose_lying(hm, sock, hm.count())
		socks.append(sock)
		var at := Vector3(edge.x, box.get_center().y, edge.z) + across * (socks.size() - 2) * 0.12
		p = hm.lying_patch(sock, Transform3D(Basis(Vector3.UP, atan2(slide.x, slide.z) + PI * 0.5), at), p)
		sock += 1
	LevelRuntime.of(host).parts.apply({"ok": true, "kind": &"lose", "by": Parts.HOST, "to": hm.id, "changes": {hm.id: p}})
	return socks


## The Host's player stands before heap button `button`, aims at it and clicks (the pick action).
func _click(zoo: Node3D, button: String) -> void:
	var station := zoo.get_node(HEAP) as Node3D
	var target := (station.get_node(button) as Node3D).global_position
	var player := LevelRuntime.of(zoo).player
	player.capture_mouse()
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


## From now on each physics tick of machine `i`'s Mess is timed: its `_physics_process` runs at a
## priority of its own, between two markers of this suite (the scripts only: both machines' physics
## spaces step together in this one process).
func _time_ticks(zoo: Node3D, i: int) -> void:
	var mess := _mess(zoo)
	var at := 1000 * (i + 1)
	mess.process_physics_priority = at
	var from := [0]
	var start := TickMark.new()
	start.process_physics_priority = at - 1
	start.tick = func() -> void: from[0] = Time.get_ticks_usec()
	var end := TickMark.new()
	end.process_physics_priority = at + 1
	end.tick = func() -> void: _tick_us[i].append(Time.get_ticks_usec() - from[0])
	zoo.add_child(start)
	zoo.add_child(end)


## A node that calls `tick` in its physics step (the markers round a timed Mess).
class TickMark extends Node:
	var tick: Callable

	func _physics_process(_delta: float) -> void:
		tick.call()


func _tick_text(i: int) -> String:
	var us := _tick_us[i]
	if us.is_empty():
		return "none"
	var sorted := us.duplicate()
	sorted.sort()
	var sum := 0
	for v in us:
		sum += v
	return "mean %.2f ms, 95th %.2f ms over %d ticks" % [sum / 1000.0 / us.size(), sorted[int(sorted.size() * 0.95)] / 1000.0, us.size()]


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
