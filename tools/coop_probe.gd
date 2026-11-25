## The co-op probe (coop/13): one machine of a two-process session, started by tools/coop_probe.sh
## (one process the Host, one the Guest), as the designer's two windows (`-- --zoo --host` and
## `--join`), with an optional one-way delay on each end (tests/support/lag_peer.gd). Driven by input
## on the Guest: it picks the Sock on the handling station's floor and throws it at full charge at a
## point 4 m ahead and 1.2 m up, picks it again and drops it 1.5 m ahead; then the Host pours
## `--socks` at the heap station. Each machine prints, per physics tick, what it shows of the Sock
## (`P` lines: the Host's body by its flight time; the Guest's ghost, its body and what is drawn), the
## lowest point of every moving body under the floor's top (`LOW` lines), and every Sock's record
## once all lie (`FINAL` lines). tools/coop_probe.py compares the two logs.
##
##   godot --headless --path . res://tools/coop_probe.tscn -- --role=host --port=24600 --lag=50
##   godot --headless --path . res://tools/coop_probe.tscn -- --role=guest --port=24600 --lag=50
extends Node

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const HEAP := "Stations/Heap"
const WAIT_S := 120.0

var _role := "host"
var _port := 24600
var _lag := 0
var _socks := 200
var _flag := ""
## "" the coop/13 run (Throw, drop, pour); "flight" (coop/14): the Guest's Throw and drop, then the
## Host's own Throw and a Throw of the Host's into the Under/Over pair (knocked Socks), every Sock in
## the air logged as drawn, each frame (`S` lines).
var _case := ""
var _fps := 60
## coop/14: when set, each frame's cap is drawn between 30 and `_fps` (uneven frames, as two windows
## on one desktop), seeded.
var _uneven := false
var _dice := RandomNumberGenerator.new()
## The Guest's stream delay estimate last printed (OFFSET lines).
var _offset_seen := INF
## coop/14 strips: when set (a rendered run), both machines watch the Host's Throw and drop from one
## camera beside it and save a frame every SHOT_TICKS ticks of its flight here, `<role>_<what>_<n>.png`.
var _shots := ""
const SHOT_TICKS := 3
const SHOT_COUNT := 14
## The Sock shot, its name in the files, and the tick its shots started at (-1 none).
var _shot_sock := -1
var _shot_what := ""
var _shot_from := -1
var _shot_n := 0
## coop/14: every Sock seen moving here, and until when (msec) it is still logged once it lies.
var _seen: Dictionary[int, int] = {}
var _zoo: Node3D
var _run: LevelRuntime
## The Sock whose flight is logged, and what is logged of it now ("" none).
var _sock := -1
var _what := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
		elif arg.begins_with("--port="):
			_port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--lag="):
			_lag = int(arg.trim_prefix("--lag="))
		elif arg.begins_with("--socks="):
			_socks = int(arg.trim_prefix("--socks="))
		elif arg.begins_with("--flag="):
			_flag = arg.trim_prefix("--flag=")
		elif arg.begins_with("--case="):
			_case = arg.trim_prefix("--case=")
		elif arg.begins_with("--fps="):
			_fps = int(arg.trim_prefix("--fps="))
		elif arg.begins_with("--shots="):
			_shots = arg.trim_prefix("--shots=")
		elif arg == "--uneven":
			_uneven = true
			_dice.seed = 14 if _role == "host" else 41
	Engine.max_fps = _fps
	process_priority = 1000
	process_physics_priority = 1000
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	await get_tree().process_frame
	await get_tree().process_frame
	_run = LevelRuntime.of(_zoo)
	_run.session.profile = PlayerProfile.fresh()
	_run.session.port = _port
	var err := _run.net.start(["--host"] if _role == "host" else ["--join=127.0.0.1:%d" % _port])
	if err != OK:
		print("PROBE %s: could not start (%s)" % [_role, error_string(err)])
		get_tree().quit(1)
		return
	if _lag > 0:
		var mp := _zoo.multiplayer
		mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, _lag)
	if _role == "host":
		await _host()
	else:
		await _guest()


func _host() -> void:
	var mess := _run.mess
	if not await _wait(func() -> bool: return _run.roster.peers().size() > 1, "a Guest"):
		return
	_sock = (_zoo.get_node("Stations/Handling/Spots/Floor") as SockSpot).sock
	_what = "host"
	if not await _wait(func() -> bool: return FileAccess.file_exists(_flag), "the Guest's go to pour", 240.0):
		return
	_what = ""
	if _case == "flight":
		await _host_throws()
		return
	var spout := _zoo.get_node(HEAP + "/Spout/HeapSpout") as HeapSpout
	var t := spout.tuning.duplicate() as HeapTuning
	t.batch = _socks
	spout.tuning = t
	var before := mess.count()
	print("PROBE host pour %d from %d" % [_socks, before])
	_run.parts.apply({"ok": true, "kind": &"more", "by": Parts.HOST, "to": spout.id,
			"changes": {spout.id: {"asked": spout.asked + 1, "first": before}}})
	_what = "pour"
	if not await _wait(func() -> bool: return mess.count() >= before + _socks and not mess.states.has(Mess.State.FLYING) \
			and spout.pending() == 0 and mess.moving_count() == 0, "the pour to lie"):
		return
	await _seconds(4.0)
	_final()
	await _seconds(3.0)
	get_tree().quit(0)


func _guest() -> void:
	var mess := _run.mess
	if not await _wait(func() -> bool: return not _run.session.is_joining() and _run.session.is_online(), "the welcome"):
		return
	await _seconds(1.0)
	var player := _run.player
	_sock = (_zoo.get_node("Stations/Handling/Spots/Floor") as SockSpot).sock
	# The Throw.
	await _pick(_sock)
	await _aim(player.global_position + player.global_basis * Vector3(0.0, 1.2, -4.0), false)
	Input.action_press(&"drop_throw")
	await _ticks(int(player.hands_tuning.tap * 60) + 2 + int(player.hands_tuning.charge_time * 60))
	print("PROBE guest throw charge %.3f from %s" % [player.charge, player.global_position])
	print("MARK %s %.6f %s" % [_role, _clock, "throw"])
	_what = "throw"
	Input.action_release(&"drop_throw")
	await _wait(func() -> bool: return mess.state_of(_sock) == Mess.State.LYING and mess.moving_count() == 0 \
			and player.ghosts().ghost_of(_sock) == null, "the Throw to lie")
	await _seconds(0.5)
	_what = ""
	print("PROBE guest throw rest %s" % [mess.pose_of(_sock).origin])
	# The drop.
	await _pick(_sock)
	var feet := player.global_position
	for i in 8:
		await _aim(feet + Basis(Vector3.UP, i * PI / 4.0) * Vector3(0.0, 0.0, -1.5), false)
		if player.drop_refusal(_run.hands) == "":
			break
	await _wait(func() -> bool: return player.drop_refusal(_run.hands) == "", "a white crosshair on the floor", 4.0)
	_what = "drop"
	print("MARK %s %.6f %s" % [_role, _clock, "drop"])
	Input.action_press(&"drop_throw")
	await _ticks(2)
	Input.action_release(&"drop_throw")
	await _wait(func() -> bool: return mess.state_of(_sock) == Mess.State.LYING and mess.moving_count() == 0 \
			and player.ghosts().ghost_of(_sock) == null, "the drop to lie")
	await _seconds(0.5)
	_what = ""
	print("PROBE guest drop rest %s" % [mess.pose_of(_sock).origin])
	if _case == "flight":
		# Out of the way of the Host's Throws.
		player.global_position += Vector3(0.0, 0.0, 6.0)
		player.reset_physics_interpolation()
		FileAccess.open(_flag, FileAccess.WRITE).store_string("go")
		_what = "seen"
		await _wait(func() -> bool: return FileAccess.file_exists(_flag + ".done"), "the Host's Throws", 240.0)
		await _seconds(1.0)
		print("PROBE guest done")
		get_tree().quit(0)
		return
	# The pour, on the Host.
	var before := mess.count()
	FileAccess.open(_flag, FileAccess.WRITE).store_string("go")
	_what = "pour"
	if not await _wait(func() -> bool: return mess.count() >= before + _socks, "the pour to start"):
		return
	if not await _wait(func() -> bool: return not mess.states.has(Mess.State.FLYING) and mess.moving_count() == 0, "the pour to lie"):
		return
	await _seconds(4.0)
	_final()
	await _seconds(3.0)
	get_tree().quit(0)


## coop/14, the Host: its own Throw of the Sock on the table at a point 4 m ahead and 1.2 m up, then
## that Sock thrown again at the Under/Over pair from 1.2 m (it knocks them), each by input.
func _host_throws() -> void:
	var mess := _run.mess
	var player := _run.player
	var table := (_zoo.get_node("Stations/Handling/Spots/OnTable") as SockSpot).sock
	var under := (_zoo.get_node("Stations/Handling/Spots/Under") as SockSpot).sock
	_what = "seen"
	await _pick(table)
	await _aim(player.global_position + player.global_basis * Vector3(0.0, 1.2, -4.0), false)
	_share_camera(table, "throw")
	await _throw("host_throw")
	await _wait(func() -> bool: return mess.state_of(table) == Mess.State.LYING and mess.moving_count() == 0, "the Host's Throw to lie")
	await _seconds(1.0)
	await _pick(table)
	await _aim(mess.box_of(under).get_center(), true)
	await _throw("knock")
	await _wait(func() -> bool: return mess.moving_count() == 0 and not mess.states.has(Mess.State.FLYING), "the knock to lie")
	await _seconds(1.5)
	# The Host's drop, 1.5 m ahead.
	await _pick(table)
	var feet := player.global_position
	for i in 8:
		await _aim(feet + Basis(Vector3.UP, i * PI / 4.0) * Vector3(0.0, 0.0, -1.5), false)
		if player.drop_refusal(_run.hands) == "":
			break
	_share_camera(table, "drop")
	print("MARK %s %.6f %s" % [_role, _clock, "host_drop"])
	Input.action_press(&"drop_throw")
	await _ticks(2)
	Input.action_release(&"drop_throw")
	await _wait(func() -> bool: return mess.state_of(table) == Mess.State.LYING and mess.moving_count() == 0, "the Host's drop to lie")
	await _seconds(1.0)
	# A fall: a few Socks poured at the heap (every machine flies its own bodies of them).
	var spout := _zoo.get_node(HEAP + "/Spout/HeapSpout") as HeapSpout
	var t := spout.tuning.duplicate() as HeapTuning
	t.batch = 6
	spout.tuning = t
	var before := mess.count()
	print("MARK %s %.6f %s" % [_role, _clock, "pour"])
	_run.parts.apply({"ok": true, "kind": &"more", "by": Parts.HOST, "to": spout.id,
			"changes": {spout.id: {"asked": spout.asked + 1, "first": before}}})
	await _wait(func() -> bool: return mess.count() >= before + 6 and spout.pending() == 0 and mess.moving_count() == 0 \
			and not mess.states.has(Mess.State.FLYING), "the pour to lie")
	await _seconds(1.5)
	FileAccess.open(_flag + ".done", FileAccess.WRITE).store_string("done")
	await _seconds(2.0)
	get_tree().quit(0)


## Strips (coop/14): a camera 2.4 m to the left of the Host's player, looking across its aim, the
## same on both machines (the Host writes it beside the flag), and Sock `sock`'s next flight shot.
func _share_camera(sock: int, what: String) -> void:
	if _shots == "":
		return
	var player := _run.player
	var ahead := -player.global_basis.z
	var right := player.global_basis.x
	var look := player.global_position + ahead * 1.3 + Vector3.UP * 0.9
	var at := player.global_position + ahead * 0.5 - right * 2.4 + Vector3.UP * 1.5
	var cam := Transform3D(Basis.IDENTITY, at).looking_at(look, Vector3.UP)
	# Plain numbers: the camera's place and its look point, the Sock, the name.
	var o := cam.origin
	FileAccess.open(_flag + ".cam", FileAccess.WRITE).store_string("%f %f %f %f %f %f %d %s" % [o.x, o.y, o.z, look.x, look.y, look.z, sock, what])
	_watch_shots(cam, sock, what)


## Shoots Sock `sock`'s next flight from `cam` (shots: SHOT_COUNT frames, SHOT_TICKS ticks apart).
func _watch_shots(cam: Transform3D, sock: int, what: String) -> void:
	var c := _zoo.get_node_or_null("ProbeCamera") as Camera3D
	if c == null:
		c = Camera3D.new()
		c.name = "ProbeCamera"
		c.fov = 50.0
		_zoo.add_child(c)
	c.global_transform = cam
	c.current = true
	_run.player.hud().visible = false
	_shot_sock = sock
	_shot_what = what
	_shot_from = -1
	_shot_n = 0


## Each frame of a rendered run: the Guest takes up the Host's camera; a shot Sock is shot from its
## let-go here (its record flying) every SHOT_TICKS ticks.
func _shoot() -> void:
	if _role == "guest" and FileAccess.file_exists(_flag + ".cam"):
		var got := FileAccess.get_file_as_string(_flag + ".cam").split(" ")
		DirAccess.remove_absolute(_flag + ".cam")
		if got.size() == 8:
			var o := Vector3(float(got[0]), float(got[1]), float(got[2]))
			var look := Vector3(float(got[3]), float(got[4]), float(got[5]))
			_watch_shots(Transform3D(Basis.IDENTITY, o).looking_at(look, Vector3.UP), int(got[6]), got[7])
	if _shot_sock < 0:
		return
	var tick := Engine.get_physics_frames()
	if _shot_from < 0:
		if _run.mess.state_of(_shot_sock) != Mess.State.FLYING:
			return
		_shot_from = tick
	if tick - _shot_from < _shot_n * SHOT_TICKS:
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s_%s_%02d.png" % [_shots, _role, _shot_what, _shot_n])
	print("SHOT %s %s %d tick %d" % [_role, _shot_what, _shot_n, tick - _shot_from])
	_shot_n += 1
	if _shot_n >= SHOT_COUNT:
		_shot_sock = -1


## A full-charge Throw by input, marked `what` in the log.
func _throw(what: String) -> void:
	var player := _run.player
	Input.action_press(&"drop_throw")
	await _ticks(int(player.hands_tuning.tap * 60) + 2 + int(player.hands_tuning.charge_time * 60))
	print("PROBE %s %s charge %.3f" % [_role, what, player.charge])
	print("MARK %s %.6f %s" % [_role, _clock, what])
	Input.action_release(&"drop_throw")


## The Guest picks Sock `sock` through its crosshair and the pick button.
func _pick(sock: int) -> void:
	var mess := _run.mess
	var player := _run.player
	await _aim(mess.box_of(sock).get_center(), true)
	await _wait(func() -> bool: return player.aimed_sock == sock, "the crosshair on Sock %d" % sock, 4.0)
	Input.action_press(&"pick")
	await _ticks(2)
	Input.action_release(&"pick")
	await _wait(func() -> bool: return _run.hands.items_of(player.player_id()).has(sock) and player.held_view().settled(), "the Guest to hold %d" % sock)
	await _seconds(0.3)


## Stands the player 1.2 m from `target` (when `walk`, or it is farther than 1.6 m), looking at it.
func _aim(target: Vector3, walk: bool) -> void:
	var player := _run.player
	player.capture_mouse()
	var flat := Vector3(target.x, 0.0, target.z)
	var feet := Vector3(player.global_position.x, 0.0, player.global_position.z)
	var away := feet - flat
	away = away.normalized() if away.length() > 0.3 else Vector3.BACK
	if walk and flat.distance_to(feet) > 1.6:
		var stand := flat + away * 1.2
		player.global_position = Vector3(stand.x, player.global_position.y, stand.z)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	for _i in 2:
		await _ticks(12)
		var head := player.get_node("Head") as Node3D
		var to := target - player.global_position
		player.rotation.y = atan2(-to.x, -to.z)
		var up := target - head.global_position
		head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	await _ticks(2)


## coop/14: each frame, every Sock in the air here as it is drawn now (its interpolated place: a
## ghost's Looks, a body's Looks, else its body with its lead from the hand), and for 0.6 s after it
## lies, its lying instance: `S role usec sock x y z kind`.
func _process(delta: float) -> void:
	# The frame clock: the wall clock at the first frame, then on by each frame's delta (as drawn).
	_clock = Time.get_unix_time_from_system() if _clock < 0.0 else _clock + delta
	if _uneven:
		Engine.max_fps = _dice.randi_range(30, _fps)
	if _shots != "" and _run != null:
		_shoot()
	if _run != null and _role == "guest" and _run.mess.stream_offset != _offset_seen:
		_offset_seen = _run.mess.stream_offset
		print("OFFSET guest %.6f %.1f" % [_clock, _offset_seen])
	if _run == null or _case != "flight" or _what == "":
		return
	var mess := _run.mess
	var now := Time.get_ticks_msec()
	var ghosts := _run.player.ghosts() if _role == "guest" else null
	var socks: Dictionary[int, bool] = {}
	for body: RigidBody3D in mess.flight_bodies():
		socks[int(mess.call("_sock_of_flight", body))] = true
	if ghosts != null:
		for sock in mess.count():
			if ghosts.ghost_of(sock) != null:
				socks[sock] = true
	for sock: int in socks:
		_seen[sock] = now + 600
	var usec := _clock
	for sock: int in _seen.keys():
		if now > _seen[sock] and not socks.has(sock):
			_seen.erase(sock)
			continue
		if _role == "host" and mess.moving_body(sock) != null:
			var true_at := mess.moving_body(sock).get_global_transform_interpolated().origin
			print("T %s %.6f %d %.5f %.5f %.5f body" % [_role, usec, sock, true_at.x, true_at.y, true_at.z])
		var at: Variant = _drawn_now(sock)
		if at is Vector3:
			var v := at as Vector3
			print("S %s %.6f %d %.5f %.5f %.5f %s" % [_role, usec, sock, v.x, v.y, v.z, _kind])


var _kind := ""
var _clock := -1.0


func _drawn_now(sock: int) -> Variant:
	var mess := _run.mess
	var ghost := _run.player.ghosts().ghost_of(sock) if _role == "guest" else null
	if ghost != null and ghost.looks() != null:
		_kind = "ghost"
		return ghost.looks().get_global_transform_interpolated().origin
	var body := mess.moving_body(sock)
	# Not drawn: a ghost draws it, or (coop/14) a Guest's copy come before the answer that lets it go.
	if body != null and mess.has_method("_early_copy") and mess.call("_early_copy", sock):
		return null
	if body != null and not mess.is_held_back(sock):
		var looks := body.get_node_or_null(Mess.LOOKS) as Node3D
		if looks != null:
			_kind = "looks"
			return looks.get_global_transform_interpolated().origin
		_kind = "body"
		var pose := body.get_global_transform_interpolated().orthonormalized()
		var leads: Dictionary = mess.get("_leads")
		if leads.has(sock):
			_kind = "led"
			pose = mess.call("_led", sock, pose)
		return pose.origin
	var lying: Variant = mess.drawn_lying_of(sock)
	if lying is Transform3D:
		_kind = "lying"
		return (lying as Transform3D).origin
	return null


func _physics_process(_delta: float) -> void:
	if _run == null or _what == "":
		return
	var mess := _run.mess
	var tick := Engine.get_physics_frames()
	if _what == "pour":
		_lows(tick)
		_snaps()
		return
	if _sock < 0 or _sock >= mess.count():
		return
	_lows(tick)
	var body := mess.moving_body(_sock)
	if _role == "host":
		var row := FlightRow.of(body) if body != null else null
		if body != null:
			var ft := (float(tick) - row.born) / 60.0 if row != null else -1.0
			var shown: Variant = mess.drawn_flight_of(_sock)
			var by := int((mess.throws.get(_sock, {}) as Dictionary).get("by", -1))
			var hand: Variant = _run.hands.worn_start_of(by, _sock) if by > 1 else null
			print("P host %d ft %.4f body %s shown %s hand %s" % [tick, ft, _v(body.global_position),
					_v((shown as Transform3D).origin) if shown is Transform3D else "-", _v((hand as Transform3D).origin) if hand is Transform3D else "-"])
		else:
			var view := _avatar_held()
			if view != null and view.drawn_of(_sock) is Transform3D:
				print("P host %d worn %s" % [tick, _v((view.drawn_of(_sock) as Transform3D).origin)])
		return
	var ghost := _run.player.ghosts().ghost_of(_sock)
	var line := "P guest %d %s st %d" % [tick, _what, mess.state_of(_sock)]
	if ghost != null:
		line += " age %.4f gbody %s drawn %s" % [float(ghost.get("_age")), _v(ghost.body().global_position), _v(ghost.drawn().origin)]
	if body != null:
		var row := FlightRow.of(body)
		line += " copy %s ft %.4f" % [_v(body.global_position), row.flight_time() if row != null else -1.0]
	if mess.is_drawn(_sock):
		line += " drawn_mess %s" % _v(mess.pose_of(_sock).origin)
	print(line)


## Every moving body here whose shapes' middles are under the floor's top (y 0) by more than 5 mm.
func _lows(tick: int) -> void:
	var mess := _run.mess
	for body: RigidBody3D in mess.flight_bodies():
		var low := INF
		for child in body.get_children():
			if child is CollisionShape3D:
				low = minf(low, (child as CollisionShape3D).global_position.y)
		if low < -0.005:
			print("LOW %s %d sock %d y %.4f" % [_role, tick, int(body.get_meta(Mess.SOCK_META, -1)), low])
	var ghost := _run.player.ghosts().ghost_of(_sock) if _role == "guest" and _sock >= 0 else null
	if ghost != null:
		var low := INF
		for child in ghost.body().get_children():
			if child is CollisionShape3D:
				low = minf(low, (child as CollisionShape3D).global_position.y)
		if low < -0.005 or ghost.drawn().origin.y < -0.005:
			print("LOW %s %d ghost %d y %.4f drawn %.4f" % [_role, tick, _sock, low, ghost.drawn().origin.y])


## The last pose of every moving body here, by Sock: a Sock that lies now is snapped from it to its
## record (`SNAP` lines: how far and how much turned).
var _last: Dictionary[int, Transform3D] = {}


func _snaps() -> void:
	var mess := _run.mess
	for sock: int in _last.keys():
		if mess.state_of(sock) == Mess.State.LYING and mess.moving_body(sock) == null:
			var was := _last[sock].orthonormalized()
			var now := mess.pose_of(sock).orthonormalized()
			var turn := rad_to_deg((was.basis.get_rotation_quaternion().inverse() * now.basis.get_rotation_quaternion()).get_angle())
			print("SNAP %s %d %.4f %.2f" % [_role, sock, was.origin.distance_to(now.origin), turn])
			_last.erase(sock)
	for body: RigidBody3D in mess.flight_bodies():
		_last[mess.call("_sock_of_flight", body)] = body.global_transform


## The Guest's avatar's worn view here (the Host's), or null.
func _avatar_held() -> HeldView:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() != 1 and a.held != null:
			return a.held
	return null


func _final() -> void:
	var mess := _run.mess
	var drawing: MessDrawing = mess.get("_drawing")
	var bufs: Dictionary = drawing.get("_buf")
	var cell_of: Dictionary = drawing.get("_cell_of")
	var slot_of: Dictionary = drawing.get("_slot_of")
	for sock in mess.count():
		var p := mess.pose_of(sock)
		var q := p.basis.get_rotation_quaternion()
		print("FINAL %s %d %d %.6f %.6f %.6f %.6f %.6f %.6f %.6f" % [_role, sock, mess.state_of(sock), p.origin.x, p.origin.y, p.origin.z, q.x, q.y, q.z, q.w])
		# What is drawn: the instance's buffer row (its transform's origin row values).
		if cell_of.has(sock):
			var buf: PackedFloat32Array = bufs[cell_of[sock]]
			var i := int(slot_of[sock]) * 20
			print("DRAWN %s %d %.6f %.6f %.6f %.6f %.6f %.6f" % [_role, sock, buf[i + 3], buf[i + 7], buf[i + 11], buf[i], buf[i + 5], buf[i + 10]])
		else:
			print("DRAWN %s %d none" % [_role, sock])
	print("PROBE %s final %d Socks" % [_role, mess.count()])


func _v(v: Vector3) -> String:
	return "%.4f,%.4f,%.4f" % [v.x, v.y, v.z]


func _ticks(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func _wait(cond: Callable, what: String, limit := WAIT_S) -> bool:
	var until := Time.get_ticks_msec() + int(limit * 1000.0)
	while not cond.call():
		if Time.get_ticks_msec() > until:
			print("PROBE %s: gave up waiting for %s" % [_role, what])
			get_tree().quit(1)
			return false
		await get_tree().process_frame
	return true


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
