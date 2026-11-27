## The day in co-op (core/160; docs/architecture/day-and-exterior.md "Saves, joins and the Lobby"): houses in one
## process, each a machine of its own, real ENet over 127.0.0.1 (tests/coop_fix_scene_test.gd's frame). A Guest's
## hour matches the Host's within 0.01 h when it comes in and after the Host's syncs; so does a late Guest's.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const DAY := "Systems/Day/Day"
const NET_WAIT_S := 30.0
const FPS := 60
## The most a Guest's hour may differ from the Host's.
const EPS := 0.01

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "guest_hour", "method": "case_guest_hour", "world": false,
				"title": "a Guest's hour matches the Host's within 0.01 h when it comes in and after the Host's syncs, and a late Guest's too"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	SockGenerator.start_all = false
	_drop_branches()


func case_guest_hour() -> void:
	var host := _branch("Host")
	await _frames(2)
	var hs := _rt(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(_rt(host).net.start(["--host"]) == OK, "the host house hosts")
	await _wait(func() -> bool: return _rt(host).loading.is_lifted(), "the Host's house to be laid", FPS * 40)
	var hd := _day(host)
	# The Host's syncs come often in this case, so one passes while it is watched.
	var tuning := hd.tuning.duplicate() as DayTuning
	tuning.sync_every = 1.0
	hd.tuning = tuning
	_check(absf(hd.shown_hour() - hd.hour) > 0.0 and hd.hour == 9.0, "the Host's day started at 9:00 and runs on (%.4f)" % hd.shown_hour())
	var guest := _branch("Guest")
	await _join(guest, hs.port)
	_check(_gap(hd, _day(guest)) < EPS, "the Guest's hour is the Host's as it comes in (%.4f vs %.4f)" % [_day(guest).shown_hour(), hd.shown_hour()])
	var synced := hd.hour
	await _wait(func() -> bool: return hd.hour != synced, "the Host to sync", FPS * 3)
	await _wait(func() -> bool: return absf(_day(guest).hour - hd.hour) < 0.0001, "the sync to reach the Guest", FPS * 2)
	_check(_gap(hd, _day(guest)) < EPS, "after a sync the Guest's hour is the Host's (%.4f vs %.4f)" % [_day(guest).shown_hour(), hd.shown_hour()])
	# A late Guest, a while after the last sync.
	await _wait(func() -> bool: return false, "two seconds of play", FPS * 2, false)
	var late := _branch("Late")
	await _join(late, hs.port)
	_check(_gap(hd, _day(late)) < EPS, "a late Guest's hour is the Host's (%.4f vs %.4f)" % [_day(late).shown_hour(), hd.shown_hour()])
	_check(_gap(hd, _day(guest)) < EPS, "and the first Guest's still is")
	_drop_branches()


func _join(house: Node3D, port: int) -> void:
	await _frames(2)
	var gs := _rt(house).session
	gs.profile = PlayerProfile.fresh()
	_check(_rt(house).net.start(["--join=127.0.0.1:%d" % port]) == OK, "the %s joins" % house.get_parent().get_parent().name)
	await _wait(func() -> bool: return _rt(house).net.mode_text().begins_with("Joined"), "the %s to be welcomed" % house.get_parent().get_parent().name, FPS * 40)


func _gap(a: Day, b: Day) -> float:
	var d := absf(a.shown_hour() - b.shown_hour())
	return minf(d, 24.0 - d)


func _day(house: Node3D) -> Day:
	return house.get_node(DAY) as Day


func _wait(cond: Callable, what: String, max_frames := FPS * 6, must := true) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	if must:
		_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _rt(house: Node3D) -> LevelRuntime:
	return LevelRuntime.of(house)


## A house in a machine of its own (its own MultiplayerAPI and 3D world).
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
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	view.add_child(house)
	_branches.append(node)
	return house


func _drop_branches() -> void:
	for node in _branches:
		var view := node.get_node_or_null("View")
		var house: Node = view.get_child(0) if view != null and view.get_child_count() > 0 else null
		var session := LevelRuntime.of(house).session if house != null else null
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
