## Things made during play (core/126, docs/architecture/gifts.md "A present is a spawned scene"): the
## Gifts station's "Spawn a crate" switch adds a row to its SpawnedParts and Godot's spawner makes the
## crate on every machine; Parts.adopt() binds its Carriable by path, so it is carried and laid as any
## placed one. Co-op: zoos in one process, each a machine of its own, real ENet over 127.0.0.1 on a port
## the system picks, tests/support/lag_peer.gd on every end, frames paced to 60 a second of wall time
## (tests/coop_carry_test.gd). Alone: a Host of one.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Gifts"]
const GIFTS := "Stations/Gifts"
const SPAWNED := GIFTS + "/Spawned"
const NET_WAIT_S := 20.0
const FPS := 60

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "coop_0ms", "method": "case_coop_0", "world": false,
				"title": "real path, 0 ms: the Host's click on Spawn a crate puts a crate at the PresentSpot on the Host and the Guest; the Guest's left click carries it and its right click lays it, the Host's too, both machines see it carried and laid; a late joiner sees it where it lies"},
		{"name": "coop_50ms", "method": "case_coop_50", "world": false,
				"title": "real path, 50 ms one way: the same, a late joiner's snapshot and spawn in either order"},
		{"name": "waits_by_id", "method": "case_waits_by_id", "world": false,
				"title": "a spawned part's state that comes before its node waits by id and is written when the node comes; a removed row frees its node and its part"},
		{"name": "save_load", "method": "case_save_load", "world": false,
				"title": "alone: a crate spawned by the switch and laid elsewhere is kept by a save; a load spawns it again where it was laid, and the next crate takes the next id"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	for a: StringName in [&"pick", &"drop_throw"]:
		Input.action_release(a)
	_drop_branches()


func case_coop_0() -> void:
	await _coop(0)


func case_coop_50() -> void:
	await _coop(50)


func _coop(lag_ms: int) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var spot := (host.get_node(GIFTS + "/PresentSpot") as Node3D).global_position
	# The Host clicks the switch: a crate at the spot on both.
	await _click_switch(host)
	await _wait(func() -> bool: return _crate_node(host) != null and _crate_node(guest) != null, "a crate on the Host and the Guest", FPS * 3)
	_check(_crate_node(host).name == &"Crate1" and _crate_node(guest).name == &"Crate1", "named by its scene and id (%s)" % _crate_node(guest).name)
	await _wait(func() -> bool: return _crate_node(guest).global_position.distance_to(spot) < 0.01, "it lies at the spot on the Guest", FPS)
	_check(_crate_node(host).global_position.distance_to(spot) < 0.01, "at the spot on the Host")
	_check(LevelRuntime.of(guest).parts.of(_crate(guest).id) == _crate(guest), "the Guest bound its Carriable by path (%s)" % _crate(guest).id)
	# The Guest carries it and lays it.
	await _aim(guest, spot + Vector3(0.0, 0.0, 1.3), spot + Vector3.UP * 0.17)
	await _wait(func() -> bool: return _player(guest).aimed_part() == _crate(guest), "the Guest's crosshair on the crate", FPS)
	await _click(&"pick")
	await _wait(func() -> bool: return _crate(host).holder == g and _crate(guest).holder == g, "the Guest carries it on both", FPS * 3)
	var laid := spot + Vector3(0.7, 0.0, 0.6)
	await _aim(guest, laid + Vector3(0.0, 0.0, 1.3), laid)
	await _click(&"drop_throw")
	await _wait(func() -> bool: return _crate(host).holder == 0 and _crate(guest).holder == 0, "the Guest's put down on both", FPS * 3)
	await _paced_ticks(2)
	var a := _crate_node(host).global_position
	_check(a.distance_to(_crate_node(guest).global_position) < 0.001, "it lies the same on both (%s / %s)" % [a, _crate_node(guest).global_position])
	_check(Vector2(a.x - laid.x, a.z - laid.z).length() < 0.15, "where the Guest aimed (%s, aimed %s)" % [a, laid])
	# The Host carries it and lays it.
	_place(guest, spot + Vector3(-3.0, 0.0, 3.0), spot)
	await _aim(host, a + Vector3(0.0, 0.0, 1.3), a + Vector3.UP * 0.17)
	await _wait(func() -> bool: return _player(host).aimed_part() == _crate(host), "the Host's crosshair on the crate", FPS)
	await _click(&"pick")
	await _wait(func() -> bool: return _crate(host).holder == Parts.HOST and _crate(guest).holder == Parts.HOST, "the Host carries it on both", FPS * 3)
	var laid2 := a + Vector3(-1.2, 0.0, 0.5)
	await _aim(host, laid2 + Vector3(0.0, 0.0, 1.3), laid2)
	await _click(&"drop_throw")
	await _wait(func() -> bool: return _crate(host).holder == 0 and _crate(guest).holder == 0, "the Host's put down on both", FPS * 3)
	await _paced_ticks(2)
	var b := _crate_node(host).global_position
	_check(b.distance_to(_crate_node(guest).global_position) < 0.001, "laid the same on both (%s / %s)" % [b, _crate_node(guest).global_position])
	# A late joiner sees it where it lies.
	var late := await _join(lag_ms)
	await _wait(func() -> bool: return _crate_node(late) != null, "the late joiner gets the crate", FPS * 5)
	await _wait(func() -> bool: return _crate_node(late).global_position.distance_to(b) < 0.001, "the late joiner sees it where it lies (%s, lies %s)" % [_crate_node(late).global_position if _crate_node(late) != null else Vector3.INF, b], FPS * 2)
	_check(_spawned(late).rows.size() == 1, "one row on the late joiner")
	_drop_branches()


func case_waits_by_id() -> void:
	var zoo := await _alone()
	var parts := LevelRuntime.of(zoo).parts
	var spawned := _spawned(zoo)
	var id := StringName(String(spawned.id) + "/Crate1/Carriable")
	var place := (zoo.get_node(GIFTS + "/PresentSpot") as Node3D).global_position + Vector3(1.0, 0.0, 0.5)
	# The answer for the crate's Carriable comes first: nothing to write it to yet, no error.
	parts.apply({"ok": true, "changes": {id: {"at": place, "yaw": 0.5}}})
	_check(parts.of(id) == null and parts.is_spawned(id), "no node yet: it waits by id")
	# Then the row: the node comes and takes the waited state over the row's.
	var states := {"Carriable": {"holder": 0, "at": Vector3.ZERO, "yaw": 0.0}}
	parts.apply({"ok": true, "changes": {spawned.id: spawned.add_patch("res://game/zoo/gifts/crate.tscn", states)}})
	var node := spawned.node_of(1) as Node3D
	_check(node != null and parts.of(id) != null, "the row spawned the node and its part is bound")
	_check(node != null and node.global_position.distance_to(place) < 0.001, "the waited state is written (%s, want %s)" % [node.global_position if node != null else Vector3.INF, place])
	# The row goes: the node and its part go.
	parts.apply({"ok": true, "changes": {spawned.id: spawned.remove_patch(PackedInt32Array([1]))}})
	await _frames(1)
	_check(not is_instance_valid(node) or node.is_queued_for_deletion(), "a removed row frees its node")
	_check(parts.of(id) == null, "and its part is no longer bound")
	_drop_branches()


func case_save_load() -> void:
	var zoo := await _alone()
	var spot := (zoo.get_node(GIFTS + "/PresentSpot") as Node3D).global_position
	await _click_switch(zoo)
	await _wait(func() -> bool: return _crate_node(zoo) != null, "the click spawns a crate", FPS)
	await _aim(zoo, spot + Vector3(0.0, 0.0, 1.3), spot + Vector3.UP * 0.17)
	await _click(&"pick")
	await _wait(func() -> bool: return _crate(zoo).holder == Parts.HOST, "carried", FPS)
	var laid := spot + Vector3(1.0, 0.0, 0.8)
	await _aim(zoo, laid + Vector3(0.0, 0.0, 1.3), laid)
	await _click(&"drop_throw")
	await _wait(func() -> bool: return _crate(zoo).holder == 0, "laid", FPS)
	var lies := _crate_node(zoo).global_position
	var parts := LevelRuntime.of(zoo).parts
	var saved := _roundtrip(parts.save_snapshot())
	var versions := parts.save_versions()
	_check(saved.has(String(_crate(zoo).id)), "the save keeps the crate's Carriable under its id")
	_drop_branches()
	# A fresh zoo loads it.
	var again := await _alone()
	_check(_crate_node(again) == null, "a fresh zoo has no crate")
	LevelRuntime.of(again).parts.load_save(saved, versions, "host")
	await _frames(2)
	_check(_crate_node(again) != null, "a load spawns the crate again")
	_check(_crate_node(again) != null and _crate_node(again).global_position.distance_to(lies) < 0.001,
			"where it was laid (%s, laid %s)" % [_crate_node(again).global_position if _crate_node(again) != null else Vector3.INF, lies])
	var spawned := _spawned(again)
	var patch := spawned.add_patch("res://game/zoo/gifts/crate.tscn")
	_check(int((patch["rows"] as Array)[-1]["id"]) == 2, "the next crate takes the next id")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

func _click_switch(zoo: Node3D) -> void:
	var button := zoo.get_node(GIFTS + "/CrateSwitch/Looks/Button") as Node3D
	var at := button.global_position
	await _aim(zoo, Vector3(at.x, 0.0, at.z + 1.6), at)
	await _wait(func() -> bool: return _player(zoo).aimed_part() is CrateSwitch, "the crosshair on the switch", FPS)
	await _click(&"pick")


func _alone() -> Node3D:
	var zoo := _branch("Alone")
	await _frames(2)
	return zoo


func _pair(lag_ms: int) -> Array[Node3D]:
	var host := _branch("Host")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms, 0)
	var guest := await _join(lag_ms)
	return [host, guest]


## Another zoo joins the Host (the first branch).
func _join(lag_ms: int) -> Node3D:
	var host := _in_branch(_branches[0])
	var label := "Guest%d" % _branches.size()
	var guest := _branch(label)
	await _frames(2)
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % host.session.port]) == OK, "%s joins" % label)
	_lag(guest, lag_ms, _branches.size() - 1)
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined"), "%s to be welcomed" % label, FPS * 10)
	await _wait(func() -> bool: return _avatar(host.get_parent(), gs.me()) != null and _avatar(guest, Parts.HOST) != null, "the Host's and %s's avatars of each other" % label, FPS * 5)
	return guest


## A short click of `action` by whichever player has the mouse.
func _click(action: StringName) -> void:
	Input.action_press(action)
	await _paced_ticks(2)
	Input.action_release(action)
	await _paced_ticks(1)


func _stands_still(player: Player) -> void:
	var last := player.global_position
	for _i in FPS * 2:
		await _paced()
		var now := player.global_position
		if player.is_on_floor() and now.distance_to(last) < 0.0005:
			return
		last = now
	_check(false, "the player to stand still where it was put (within %d frames)" % (FPS * 2))


## Stands `zoo`'s player at `feet` looking at `target`; only it has the mouse.
func _aim(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := _player(zoo)
	for other: Node in _branches:
		var p := _in_branch(other).player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	_place(zoo, feet, target)
	await _stands_still(player)
	_place(zoo, Vector3(feet.x, player.global_position.y, feet.z), target)
	await _paced_ticks(2)
	await _host_has(player)


## The Host judges reach by where it last heard this player stands: waits until it has the player there.
func _host_has(player: Player) -> void:
	var host_net := _in_branch(_branches[0]).net
	var me := player.player_id()
	await _wait(func() -> bool:
		var at: Variant = host_net.where(me)
		return not (at is Vector3) or (at as Vector3).distance_to(player.global_position) < 0.1,
			"the Host to have the player where it stands", FPS * 2)


func _place(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := _player(zoo)
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	var head := player.get_node("Head") as Node3D
	var up := target - (feet + Vector3.UP * head.position.y)
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	player.reset_physics_interpolation()


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


func _spawned(zoo: Node3D) -> SpawnedParts:
	return zoo.get_node(SPAWNED) as SpawnedParts


## The first crate on `zoo`'s machine, or null.
func _crate_node(zoo: Node3D) -> Node3D:
	return zoo.get_node_or_null(SPAWNED + "/Crate1") as Node3D


func _crate(zoo: Node3D) -> Carriable:
	var node := _crate_node(zoo)
	return node.get_node(^"Carriable") as Carriable if node != null else null


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


func _avatar(zoo: Node, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a) and not a.is_queued_for_deletion():
			return a
	return null


func _lag(zoo: Node3D, lag_ms: int, index: int) -> void:
	if lag_ms <= 0:
		return
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, index)


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
