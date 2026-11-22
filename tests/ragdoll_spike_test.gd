## Spike coop/02: a 4-bone Godot physical-bone ragdoll on Jolt, knocked on the Host, and its pose on a
## Guest's skeleton two ways: (a) a MultiplayerSynchronizer on the shown skeleton's bone poses,
## (b) one stamped PackedByteArray the Guest eases towards at 12/s. Real ENet machines in one process
## (SceneTree.set_multiplayer per machine), with 0 and 50 ms one way (tests/support/lag_peer.gd).
## Each sync case runs paced to real time (the network runs in real time, the tests at --fixed-fps)
## and prints one `SPIKE` line: the largest jump of a Guest bone in one frame, the lag that best
## fits the Guest's pose to the Host's history, and the Host's ENet bytes a second while it falls.
## Report: docs/research/coop-ragdoll-sync.md.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const SPIKE := preload("res://tests/support/ragdoll_spike/ragdoll_spike.tscn")
const RagdollSpike := preload("res://tests/support/ragdoll_spike/ragdoll_spike.gd")

const NET_WAIT_S := 20.0
## How long a sync case samples the fall, in real seconds.
const SAMPLE_S := 2.5
const FRAME_USEC := 16667
## The knock: forward and a little sideways, as an off-centre hit.
const PUSH := Vector3(0.94, 0.0, 0.34)
## Swing limit plus what Jolt's soft limit lets through.
const SWING_MAX_DEG := 45.0 + 8.0
## Spine2's tip over its head (TOP 1.7 minus Spine2 at 1.12).
const TIP := Vector3(0.0, 0.58, 0.0)

## Every machine of this case: {"node", "spike", "peer"}.
var _machines: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "jolt_fall", "method": "case_jolt_fall", "world": false,
				"title": "on Jolt the 4-bone ragdoll knocked by an impulse topples, keeps its joints within the cone and lies on the floor"},
		{"name": "bones_0", "method": "case_bones_0", "world": false,
				"title": "real ENet, 0 ms: a synchronizer on the shown bone poses gives the Guest the Host's fallen pose"},
		{"name": "bones_50", "method": "case_bones_50", "world": false,
				"title": "real ENet, 50 ms each way: a synchronizer on the shown bone poses gives the Guest the Host's fallen pose"},
		{"name": "stamped_0", "method": "case_stamped_0", "world": false,
				"title": "real ENet, 0 ms: one stamped pose eased at 12/s gives the Guest the Host's fallen pose"},
		{"name": "stamped_50", "method": "case_stamped_50", "world": false,
				"title": "real ENet, 50 ms each way: one stamped pose eased at 12/s gives the Guest the Host's fallen pose"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_done_now()


func case_jolt_fall() -> void:
	_check(str(ProjectSettings.get_setting("physics/3d/physics_engine")) == "Jolt Physics", "the project runs Jolt")
	var spike := SPIKE.instantiate() as RagdollSpike
	spike.name = "Spike"
	add_child(spike)
	var bones := spike.bones()
	_check(bones.size() == 4 and not bones.has(null), "four physical bones, one per skeleton bone")
	await _physics_ticks(2)
	_near(_tilt(spike.body), 0.0, 1.0, "before the knock the body stands upright (degrees)")
	spike.knock(PUSH)
	var worst_swing := 0.0
	var lowest := INF
	for _i in 150:
		await _physics_ticks(1)
		worst_swing = maxf(worst_swing, _worst_swing(spike.body))
		for pb in bones:
			var cap := (pb.get_child(0) as CollisionShape3D).shape as CapsuleShape3D
			lowest = minf(lowest, pb.global_position.y - _lowest_point(pb, cap))
	var tilt := _tilt(spike.body)
	print("SPIKE jolt_fall: tilt %.1f deg, worst swing %.1f deg, deepest into the floor %.3f m" % [tilt, worst_swing, -lowest])
	_check(tilt > 60.0, "the knocked body lies over (tilt %.1f degrees)" % tilt)
	_check(worst_swing <= SWING_MAX_DEG, "no joint bends past the cone (worst %.1f degrees)" % worst_swing)
	_check(lowest > -0.05, "no capsule sinks into the floor (deepest %.3f m)" % -lowest)
	var moved := spike.body.get_bone_global_pose(0).origin.dot(Vector3(PUSH.x, 0.0, PUSH.z))
	_check(moved > -0.2, "it falls the way it was pushed, not back (%.2f m along the push)" % moved)
	var resting := true
	for pb in bones:
		resting = resting and pb.linear_velocity.length() < 0.3
	_check(resting, "after 2.5 s the ragdoll rests")
	spike.queue_free()


func case_bones_0() -> void:
	await _sync_case(RagdollSpike.Sync.BONES, 0, "bones_0")


func case_bones_50() -> void:
	await _sync_case(RagdollSpike.Sync.BONES, 50, "bones_50")


func case_stamped_0() -> void:
	await _sync_case(RagdollSpike.Sync.STAMPED, 0, "stamped_0")


func case_stamped_50() -> void:
	await _sync_case(RagdollSpike.Sync.STAMPED, 50, "stamped_50")


func _sync_case(mode: RagdollSpike.Sync, lag_ms: int, label: String) -> void:
	var host := _machine("Host", mode, true)
	var server := ENetMultiplayerPeer.new()
	_check(server.create_server(0, 4) == OK, "the Host listens")
	_install(host, server, lag_ms)
	var guest := _machine("Guest", mode, false)
	var client := ENetMultiplayerPeer.new()
	_check(client.create_client("127.0.0.1", server.host.get_local_port()) == OK, "the Guest starts joining")
	_install(guest, client, lag_ms)
	var gmp := (guest["node"] as Node).multiplayer
	await _until(func() -> bool: return gmp.get_peers().has(1), "the Guest to connect")
	var hs: RagdollSpike = host["spike"]
	var gs: RagdollSpike = guest["spike"]
	_check(gs.ragdoll == null, "the Guest has no ragdoll of its own: it only shows")
	await _until(func() -> bool: return _pose_gap(hs.body, gs.body) < 0.01, "the Guest to show the standing pose")
	server.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	server.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS)
	client.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	hs.knock(PUSH)
	# Paced to real time, so the fall's speed and the network's are the same clock.
	var times: Array[float] = []
	var host_pts: Array[PackedVector3Array] = []
	var guest_pts: Array[PackedVector3Array] = []
	var t0 := Time.get_ticks_usec()
	var n := 0
	while Time.get_ticks_usec() - t0 < int(SAMPLE_S * 1e6):
		await get_tree().process_frame
		n += 1
		var due := t0 + n * FRAME_USEC
		var now := Time.get_ticks_usec()
		if due > now:
			OS.delay_usec(due - now)
		times.append((Time.get_ticks_usec() - t0) / 1e6)
		host_pts.append(_points(hs.body))
		guest_pts.append(_points(gs.body))
	var secs := (Time.get_ticks_usec() - t0) / 1e6
	var sent := server.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	var packets := server.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS)
	var back := client.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	var host_jump := _largest_jump(host_pts)
	var guest_jump := _largest_jump(guest_pts)
	var fit := _best_lag(times, host_pts, guest_pts)
	var worst_gap := 0.0
	for i in times.size():
		worst_gap = maxf(worst_gap, _gap(host_pts[i], guest_pts[i]))
	print("SPIKE %s: frames %d in %.2f s; Guest largest jump %.3f m/frame (Host %.3f); lag %d ms (fit error %.3f m); worst gap %.3f m; Host sent %d B/s in %.1f packets/s; Guest sent %d B/s" % [
			label, times.size(), secs, guest_jump, host_jump, int(fit[0]), fit[1], worst_gap,
			int(sent / secs), packets / secs, int(back / secs)])
	_check(_tilt(gs.body) > 30.0, "the Guest's skeleton shows the fall (tilt %.1f degrees)" % _tilt(gs.body))
	await _until(func() -> bool: return _pose_gap(hs.body, gs.body) < 0.02,
			"the Guest's skeleton to come to the Host's resting pose within 2 cm")
	_check(int(fit[0]) < 300, "the Guest's pose trails the Host's by under 300 ms (%d ms)" % int(fit[0]))
	await _done()


## A machine: a Node with its own MultiplayerAPI and its copy of the spike.
func _machine(label: String, mode: RagdollSpike.Sync, is_host: bool) -> Dictionary:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var spike := SPIKE.instantiate() as RagdollSpike
	spike.name = "Spike"
	spike.sync_mode = mode
	spike.is_host = is_host
	node.add_child(spike)
	var out := {"node": node, "spike": spike}
	_machines.append(out)
	return out


func _install(m: Dictionary, peer: ENetMultiplayerPeer, lag_ms: int) -> void:
	var mp := (m["node"] as Node).multiplayer
	if lag_ms > 0:
		mp.multiplayer_peer = LagPeer.new(peer, lag_ms, 0.0, _machines.size())
	else:
		mp.multiplayer_peer = peer
	m["peer"] = mp.multiplayer_peer


func _done() -> void:
	for m in _machines:
		var p: MultiplayerPeer = m.get("peer")
		if p != null:
			p.close()
	await _frames(2)
	_done_now()


func _done_now() -> void:
	for m in _machines:
		var p: MultiplayerPeer = m.get("peer")
		if p != null:
			p.close()
		var path := (m["node"] as Node).get_path()
		remove_child(m["node"])
		(m["node"] as Node).free()
		get_tree().set_multiplayer(null, path)
	_machines.clear()


## The shown skeleton's bone heads and Spine2's tip, in skeleton space.
static func _points(skel: Skeleton3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in 4:
		out.append(skel.get_bone_global_pose(i).origin)
	out.append(skel.get_bone_global_pose(3) * TIP)
	return out


static func _gap(a: PackedVector3Array, b: PackedVector3Array) -> float:
	var worst := 0.0
	for i in a.size():
		worst = maxf(worst, a[i].distance_to(b[i]))
	return worst


static func _pose_gap(a: Skeleton3D, b: Skeleton3D) -> float:
	return _gap(_points(a), _points(b))


## The largest distance one point moved between two frames.
static func _largest_jump(pts: Array[PackedVector3Array]) -> float:
	var worst := 0.0
	for i in range(1, pts.size()):
		worst = maxf(worst, _gap(pts[i - 1], pts[i]))
	return worst


## [lag in ms, mean gap there]: the delay d (0 to 400 ms, by 5) for which the Guest's pose at t
## best matches the Host's at t - d, the Host's read between its samples, over the first 1.5 s.
static func _best_lag(times: Array[float], host: Array[PackedVector3Array], guest: Array[PackedVector3Array]) -> Array[float]:
	var best := [0.0, INF]
	for d_ms in range(0, 405, 5):
		var d := d_ms / 1000.0
		var total := 0.0
		var count := 0
		for i in times.size():
			var t := times[i] - d
			if t < times[0] or times[i] > 1.5:
				continue
			var j := 1
			while j < times.size() - 1 and times[j] < t:
				j += 1
			var span := maxf(1e-6, times[j] - times[j - 1])
			var w := clampf((t - times[j - 1]) / span, 0.0, 1.0)
			var at := PackedVector3Array()
			for k in host[j].size():
				at.append(host[j - 1][k].lerp(host[j][k], w))
			total += _gap(at, guest[i])
			count += 1
		if count > 0 and total / count < best[1]:
			best = [float(d_ms), total / count]
	var out: Array[float] = [best[0], best[1]]
	return out


## Degrees between up and the line from the feet (Root) to Spine2's head.
static func _tilt(skel: Skeleton3D) -> float:
	var line := skel.get_bone_global_pose(3).origin - skel.get_bone_global_pose(0).origin
	return rad_to_deg(line.angle_to(Vector3.UP))


## The largest bend between a bone and its parent, in degrees.
static func _worst_swing(skel: Skeleton3D) -> float:
	var worst := 0.0
	for i in range(1, 4):
		var up := skel.get_bone_global_pose(i).basis.y
		var parent_up := skel.get_bone_global_pose(i - 1).basis.y
		worst = maxf(worst, rad_to_deg(up.angle_to(parent_up)))
	return worst


## How far under its body's centre a capsule reaches, straight down.
static func _lowest_point(pb: PhysicalBone3D, cap: CapsuleShape3D) -> float:
	var axis := pb.global_transform.basis.y.normalized()
	return absf(axis.y) * (cap.height * 0.5 - cap.radius) + cap.radius
