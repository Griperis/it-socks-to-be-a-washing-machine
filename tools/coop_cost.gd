## The co-op cost (coop/12, M0.6 batch 5): one machine of a two-process session, started by
## tools/coop_cost.sh (one process the Host, one the Guest). Each process loads the zoo, the Host hosts
## and the Guest joins over real ENet on 127.0.0.1; once the Guest is in, the Host pours `--socks` Socks
## at the heap station. Each machine measures, from the pour's first Sock to all lying ("pour") and then
## for `--rest` seconds ("rest"): bytes a second each way (ENet's own totals, headers included), and its
## frame time (the engine's process plus physics time a frame, no drawing: headless) as mean, 95th
## percentile and worst, and the frames a second it kept at a 60 cap. One `COST` line per window.
##
##   godot --headless --path . res://tools/coop_cost.tscn -- --role=host --port=24600 --socks=2000
##   godot --headless --path . res://tools/coop_cost.tscn -- --role=guest --port=24600
extends Node

const ZOO := "res://game/zoo/zoo.tscn"
const HEAP := "Stations/Heap"
## The longest a run waits for the Guest, or for the pour to lie.
const WAIT_S := 240.0

var _role := "host"
var _port := 24600
var _socks := 2000
var _rest_s := 5.0
var _zoo: Node3D
var _frame_ms: PackedFloat32Array = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
		elif arg.begins_with("--port="):
			_port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--socks="):
			_socks = int(arg.trim_prefix("--socks="))
		elif arg.begins_with("--rest="):
			_rest_s = float(arg.trim_prefix("--rest="))
	Engine.max_fps = 60
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	await get_tree().process_frame
	await get_tree().process_frame
	var run := LevelRuntime.of(_zoo)
	run.session.profile = PlayerProfile.fresh()
	run.session.port = _port
	var err := run.net.start(["--host"] if _role == "host" else ["--join=127.0.0.1:%d" % _port])
	if err != OK:
		print("COST %s: could not start (%s)" % [_role, error_string(err)])
		get_tree().quit(1)
		return
	var mess := run.mess
	var before := mess.count()
	if _role == "host":
		if not await _wait(func() -> bool: return run.roster.peers().size() > 1, "a Guest"):
			return
		await _seconds(1.0)
		var spout := _zoo.get_node(HEAP + "/Spout/HeapSpout") as HeapSpout
		var t := spout.tuning.duplicate() as HeapTuning
		t.batch = _socks
		spout.tuning = t
		before = mess.count()
		run.parts.apply({"ok": true, "kind": &"more", "by": Parts.HOST, "to": spout.id,
				"changes": {spout.id: {"asked": spout.asked + 1, "first": before}}})
	else:
		if not await _wait(func() -> bool: return not run.session.is_joining() and run.session.is_online(), "the welcome"):
			return
		before = mess.count()
	if not await _wait(func() -> bool: return mess.count() > before, "the pour to start"):
		return
	var enet := (run.session.transport.peer as ENetMultiplayerPeer).host
	_window_start(enet)
	var t0 := Time.get_ticks_msec()
	if not await _wait(func() -> bool: return mess.count() >= before + _socks and not mess.states.has(Mess.State.FLYING) \
			and (_role != "host" or (_zoo.get_node(HEAP + "/Spout/HeapSpout") as HeapSpout).pending() == 0), "the pour to lie"):
		return
	_window_end("pour", enet, Time.get_ticks_msec() - t0, mess.count())
	_window_start(enet)
	t0 = Time.get_ticks_msec()
	await _seconds(_rest_s)
	_window_end("rest", enet, Time.get_ticks_msec() - t0, mess.count())
	await _seconds(1.0)
	get_tree().quit(0)


func _process(_delta: float) -> void:
	_frame_ms.append((Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)


func _window_start(enet: ENetConnection) -> void:
	enet.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	enet.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
	_frame_ms.clear()


func _window_end(label: String, enet: ENetConnection, ms: int, socks: int) -> void:
	var s := maxf(0.001, ms / 1000.0)
	var sent := enet.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA) / s
	var got := enet.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA) / s
	var sorted := _frame_ms.duplicate()
	sorted.sort()
	var mean := 0.0
	for f in sorted:
		mean += f
	mean /= maxf(1.0, sorted.size())
	var p95 := sorted[int(sorted.size() * 0.95)] if not sorted.is_empty() else 0.0
	var worst := sorted[-1] if not sorted.is_empty() else 0.0
	print("COST %s %s: %.1f s, %d Socks; sent %.0f B/s, received %.0f B/s; frame %.2f ms mean, %.2f ms 95th, %.2f ms worst; %.1f frames/s" \
			% [_role, label, s, socks, sent, got, mean, p95, worst, sorted.size() / s])


func _wait(cond: Callable, what: String) -> bool:
	var until := Time.get_ticks_msec() + int(WAIT_S * 1000.0)
	while not cond.call():
		if Time.get_ticks_msec() > until:
			print("COST %s: gave up waiting for %s" % [_role, what])
			get_tree().quit(1)
			return false
		await get_tree().process_frame
	return true


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
