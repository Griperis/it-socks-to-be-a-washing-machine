## A fall out of the map in co-op (core/110): zoos in one process, each a machine of its own, real ENet over
## 127.0.0.1 (tests/coop_cutscene_test.gd's pair). A Guest whose body is put far below the floor is put back by
## its own machine at its own washer spawn and the Host's view of it (its Avatar) is there too; a Guest who is
## knocked down and whose ragdoll falls out has its knockdown ended by the Host's answer, then is put back.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["WasherStation"]
const WASHER := "Stations/WasherStation/Washer"
const NET_WAIT_S := 20.0
const FPS := 60
const STATION_SHIFT := 90.0

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "guest_falls", "method": "case_guest_falls", "world": false,
				"title": "a Guest put at y = -500 is put back at its own spawn on its machine, and the Host sees its Avatar there"},
		{"name": "guest_falls_down", "method": "case_guest_falls_down", "world": false,
				"title": "a knocked-down Guest whose ragdoll falls out of the map has the knockdown ended on both machines, then stands at its spawn"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_drop_branches()


func _avatar(zoo: Node3D, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a) and not a.is_queued_for_deletion():
			return a
	return null


func case_guest_falls() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gp := _rt(guest).player
	var g := gp.player_id()
	await _wait(func() -> bool: return gp.is_on_floor() and _avatar(host, g) != null, "the Guest to stand and the Host to see it", FPS * 5)
	gp.global_position = Vector3(1.0, -500.0, 1.0)
	await _wait(func() -> bool: return _spawn_of(guest, gp.global_position) == 1, "the Guest to be put at spawn 2 on its machine", FPS * 3)
	await _wait(func() -> bool: return _spawn_of(host, _avatar(host, g).global_position) == 1, "the Host to see the Guest at spawn 2", FPS * 3)
	await _wait(func() -> bool: return gp.is_on_floor(), "the Guest to stand", FPS * 3)
	_check(_rt(host).player.global_position.y > -10.0, "the Host was not moved")
	_drop_branches()


func case_guest_falls_down() -> void:
	var zoos := await _pair(0)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gp := _rt(guest).player
	var g := gp.player_id()
	var hkd := _rt(host).player.knockdowns()
	var gkd := gp.knockdowns()
	await _wait(func() -> bool: return gp.is_on_floor() and _avatar(host, g) != null, "the Guest to stand and the Host to see it", FPS * 5)
	_rt(host).parts.ask(Command.new(Knockdowns.KNOCK, Parts.HOST, hkd.id, {"target": g, "thrower": 1,
			"push": Vector3.FORWARD, "high": 0.5, "side": 0.0, "at": gp.global_position}))
	await _wait(func() -> bool: return gkd.is_down(g) and gkd.ragdoll_of(g).phase == Ragdoll.Phase.DOWN, "the Guest to lie", FPS * 3)
	# The Host simulates every ragdoll; the Guest's copy follows its poses.
	for b in hkd.ragdoll_of(g).bodies():
		b.global_position += Vector3(0.0, -500.0, 0.0)
	await _wait(func() -> bool: return not gkd.is_down(g) and not hkd.is_down(g), "the knockdown to end on both machines", FPS * 3)
	await _wait(func() -> bool: return _spawn_of(guest, gp.global_position) == 1, "the Guest to be put at spawn 2", FPS * 3)
	await _wait(func() -> bool: return _spawn_of(host, _avatar(host, g).global_position) == 1, "the Host to see it there", FPS * 3)
	_drop_branches()


func _spawn_of(zoo: Node3D, feet: Vector3) -> int:
	var spawns := zoo.get_node(WASHER + "/Spawns").get_children()
	for i in spawns.size():
		var spot := (spawns[i] as Node3D).global_position
		if Vector2(feet.x - spot.x, feet.z - spot.z).length() < 0.05:
			return i
	return -1


func _pair(lag_ms: int) -> Array[Node3D]:
	var host := _branch("Host")
	await _frames(2)
	var hs := _rt(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(_rt(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	var guest := await _join("Guest", lag_ms)
	return [host, guest]


func _join(label: String, lag_ms := 0) -> Node3D:
	var host := (_branches[0] as Node).get_node("View/Zoo") as Node3D
	var zoo := _branch(label)
	await _frames(2)
	var gs := _rt(zoo).session
	gs.profile = PlayerProfile.fresh()
	_check(_rt(zoo).net.start(["--join=127.0.0.1:%d" % _rt(host).session.port]) == OK, "%s joins" % label)
	_lag(zoo, lag_ms)
	await _wait(func() -> bool: return _rt(zoo).net.mode_text().begins_with("Joined"), "%s to be welcomed" % label, FPS * 10)
	return zoo


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced_ticks(n: int) -> void:
	for _i in n:
		await _paced()


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _rt(zoo: Node3D) -> LevelRuntime:
	return LevelRuntime.of(zoo)


func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## A zoo in a machine of its own (its own MultiplayerAPI and 3D world), with only the KEEP stations.
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
	# The Avatar drops a pose outside the zoo's area (x within 50 m): bring the station inside it.
	(zoo.get_node("Stations/WasherStation") as Node3D).position.x -= STATION_SHIFT
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var zoo := node.get_node_or_null("View/Zoo")
		var session := LevelRuntime.of(zoo).session if zoo != null else null
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
