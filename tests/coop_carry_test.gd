## Carried things in co-op (core/78): two zoos in one process, each a machine of its own, real ENet over
## 127.0.0.1 on a port the system picks, tests/support/lag_peer.gd on both ends at 50 ms one way, frames
## paced to 60 a second of wall time (tests/coop_hand_off_test.gd). The Handling station's stand-in crate:
## the Host carries it and puts it down by its own input, and the Guest sees it lying there, the same
## place and turn; the Guest carries it by its own input, the Host draws it at the Guest's avatar's slot,
## and the Guest's right click lays it the same on both.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Handling"]
const CRATE := "Stations/Handling/Crate"
const BOOK := "Stations/Handling/Book"
const BOOK_PLACE := Vector3(0.5, 0.0, 1.6)
const NET_WAIT_S := 20.0
const FPS := 60
const LAG_MS := 50

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "carry", "method": "case_carry", "world": false,
				"title": "core/78, 50 ms one way: the Host's left click carries the crate and its right click lays it on the floor; the Guest sees it lying there, the same place and turn; the Guest carries it (the Host draws it at the Guest's slot) and lays it, the same on both"},
		{"name": "book", "method": "case_book", "world": false,
				"title": "core/139, 50 ms one way: the Host takes the book with its left click and reads it (E: its own pages, its own profile; the Guest's pages stay shut); the Guest sees it carried at the Host's avatar's slot and, put down, lying there; the Guest takes it and reads it: its own pages, not the Host's"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	for a: StringName in [&"pick", &"drop_throw"]:
		Input.action_release(a)
	_drop_branches()


func case_carry() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var start := _thing(host).global_position
	# The Host carries it and lays it down.
	await _aim(host, start + Vector3(0.0, 0.0, 1.3), start + Vector3.UP * 0.17)
	await _wait(func() -> bool: return _player(host).aimed_part() == _crate(host), "the Host's crosshair on the crate", FPS)
	await _click(&"pick")
	await _wait(func() -> bool: return _crate(host).holder == Parts.HOST and _crate(guest).holder == Parts.HOST,
			"the Host carries it on both", FPS * 2)
	var spot := start + Vector3(-0.8, 0.0, 0.6)
	await _aim(host, spot + Vector3(0.6, 0.0, 1.2), spot)
	var yaw := _player(host).rotation.y
	await _click(&"drop_throw")
	await _wait(func() -> bool: return _crate(host).holder == 0 and _crate(guest).holder == 0, "it is put down on both", FPS * 2)
	await _paced_ticks(2)
	var on_host := _thing(host).global_transform
	var on_guest := _thing(guest).global_transform
	_check(on_host.origin.distance_to(on_guest.origin) < 0.001, "the Guest sees it lying there (%s / %s)" % [on_host.origin, on_guest.origin])
	_check(Vector2(on_host.origin.x - spot.x, on_host.origin.z - spot.z).length() < 0.15, "at the Host's crosshair (%s, aimed %s)" % [on_host.origin, spot])
	_near(angle_difference(on_guest.basis.get_euler().y, wrapf(yaw, -PI, PI)), 0.0, 0.01, "turned as it was held, on the Guest")

	# The Guest carries it: the Host draws it at the Guest's avatar's slot.
	var lying := on_guest.origin
	_place(host, Vector3(-8.0, 0.0, 6.0), Vector3(-8.0, 1.6, 3.0))
	await _aim(guest, lying + Vector3(0.0, 0.0, 1.3), lying + Vector3.UP * 0.17)
	await _wait(func() -> bool: return _player(guest).aimed_part() == _crate(guest), "the Guest's crosshair on the crate", FPS)
	await _click(&"pick")
	await _wait(func() -> bool: return _crate(host).holder == g and _crate(guest).holder == g, "the Guest carries it on both", FPS * 3)
	await _paced_ticks(int(LAG_MS * 3 * FPS / 1000.0) + 10)
	var drawn: Variant = _crate(host).carry_pose(g)
	_check(drawn is Transform3D and _thing(host).global_position.distance_to((drawn as Transform3D).origin) < 0.01,
			"the Host draws it at the Guest's avatar's slot")
	var mine: Variant = _crate(guest).carry_pose(g)
	_check(mine is Transform3D and _thing(guest).global_position.distance_to((mine as Transform3D).origin) < 0.01,
			"the Guest draws it at its own slot")
	var spot2 := lying + Vector3(0.5, 0.0, 0.4)
	await _aim(guest, spot2 + Vector3(-0.4, 0.0, 1.3), spot2)
	await _click(&"drop_throw")
	await _wait(func() -> bool: return _crate(host).holder == 0 and _crate(guest).holder == 0, "the Guest's put down on both", FPS * 3)
	await _paced_ticks(2)
	var a := _thing(host).global_transform
	var b := _thing(guest).global_transform
	_check(a.origin.distance_to(b.origin) < 0.001 and absf(angle_difference(a.basis.get_euler().y, b.basis.get_euler().y)) < 0.001,
			"it lies the same on both (%s / %s)" % [a.origin, b.origin])
	_drop_branches()


## core/139: the book in two machines. Each reader's pages are their own profile's; the Teammate sees it carried.
func case_book() -> void:
	var zoos := await _pair(LAG_MS, true)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var mine := EncyclopediaPage.sorted_designs(&"simple")
	for z: Node3D in zoos:
		LevelRuntime.of(z).session.profile.collections = [&"simple"]
	LevelRuntime.of(host).session.profile.designs = PackedInt32Array([mine[0].id])
	LevelRuntime.of(guest).session.profile.designs = PackedInt32Array([mine[1].id])
	var lying := _book_thing(host).global_position
	# The Host takes it by its own click, and the Guest sees it carried at the Host's avatar's slot.
	await _aim(host, lying + Vector3(0.0, 0.0, 1.0), lying + Vector3.UP * 0.03)
	await _wait(func() -> bool: return _player(host).aimed_part() == _book_part(host), "the Host's crosshair on the book", FPS)
	await _click(&"pick")
	await _wait(func() -> bool: return _book_part(host).holder == Parts.HOST and _book_part(guest).holder == Parts.HOST,
			"the Host holds the book on both", FPS * 2)
	await _paced_ticks(int(LAG_MS * 3 * FPS / 1000.0) + 10)
	var drawn: Variant = _book_part(guest).carry_pose(Parts.HOST)
	_check(drawn is Transform3D and _book_thing(guest).global_position.distance_to((drawn as Transform3D).origin) < 0.01
			and _book_thing(guest).visible, "the Guest draws it at the Host's avatar's slot")
	# E: the Host's own pages, on the Host's machine only.
	Input.action_press(Player.INTERACT)
	await _paced_ticks(2)
	Input.action_release(Player.INTERACT)
	await _wait(func() -> bool: return _book_menu(host).is_open(), "E opens the Host's pages", FPS)
	_check(not _book_menu(guest).is_open(), "the Guest's pages stay shut")
	var host_cells := _book_menu(host).page().cells()
	_check(host_cells[0].shown_name() == mine[0].name and host_cells[1].shown_name() == EncyclopediaCell.UNKNOWN,
			"the Host reads their own Design (%s)" % host_cells[0].shown_name())
	_book_menu(host).close()
	await _paced_ticks(FPS / 4)
	# The Host puts it down; the Guest sees it lying and takes it.
	var spot := lying + Vector3(-0.3, 0.0, 0.5)
	await _aim(host, spot + Vector3(0.0, 0.0, 1.0), spot)
	await _click(&"drop_throw")
	await _wait(func() -> bool: return _book_part(host).holder == 0 and _book_part(guest).holder == 0, "it is put down on both", FPS * 2)
	await _paced_ticks(2)
	_check(_book_thing(host).global_position.distance_to(_book_thing(guest).global_position) < 0.001, "the Guest sees it lying there")
	var down := _book_thing(guest).global_position
	_place(host, Vector3(-8.0, 0.0, 6.0), Vector3(-8.0, 1.6, 3.0))
	await _aim(guest, down + Vector3(0.0, 0.0, 1.0), down + Vector3.UP * 0.03)
	await _wait(func() -> bool: return _player(guest).aimed_part() == _book_part(guest), "the Guest's crosshair on the book", FPS)
	await _click(&"pick")
	await _wait(func() -> bool: return _book_part(host).holder == g and _book_part(guest).holder == g, "the Guest holds the book on both", FPS * 3)
	Input.action_press(Player.INTERACT)
	await _paced_ticks(2)
	Input.action_release(Player.INTERACT)
	await _wait(func() -> bool: return _book_menu(guest).is_open(), "E opens the Guest's pages", FPS)
	_check(not _book_menu(host).is_open(), "the Host's pages stay shut")
	var guest_cells := _book_menu(guest).page().cells()
	_check(guest_cells[0].shown_name() == EncyclopediaCell.UNKNOWN and guest_cells[1].shown_name() == mine[1].name,
			"the Guest reads their own Design, not the Host's (%s, %s)" % [guest_cells[0].shown_name(), guest_cells[1].shown_name()])
	_book_menu(guest).close()
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

func _book_thing(zoo: Node3D) -> Node3D:
	return zoo.get_node(BOOK) as Node3D


func _book_part(zoo: Node3D) -> Carriable:
	return zoo.get_node(BOOK + "/Carriable") as Carriable


func _book_menu(zoo: Node3D) -> EncyclopediaMenu:
	return zoo.get_node(BOOK + "/EncyclopediaMenu") as EncyclopediaMenu


func _pair(lag_ms: int, with_book := false) -> Array[Node3D]:
	var host := _branch("Host", with_book)
	var guest := _branch("Guest", with_book)
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
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") and _mess(guest).count() == _mess(host).count(),
			"the guest zoo to be welcomed", FPS * 10)
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null, "each machine's avatar of the other", FPS * 5)
	return [host, guest]


## A short click of `action` by whichever player has the mouse.
func _click(action: StringName) -> void:
	Input.action_press(action)
	await _paced_ticks(2)
	Input.action_release(action)
	await _paced_ticks(1)


## Waits until `player` stands on the floor and did not move over the last paced tick (a body put down
## in something is pushed out of it first).
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


## The Host judges reach by where it last heard this player stands (LevelNet.where()): a click sent before the pose
## got there is refused as too far (core/101, core/103). Waits until the Host has the player at `player`'s feet (all three axes: reach is 3D).
func _host_has(player: Player) -> void:
	var host_net := _in_branch(_branches[0]).net
	var me := player.player_id()
	await _wait(func() -> bool:
		var at: Variant = host_net.where(me)
		return at is Vector3 and (at as Vector3).distance_to(player.global_position) < 0.1,
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


func _crate(zoo: Node3D) -> Carriable:
	return zoo.get_node(CRATE + "/Carriable") as Carriable


func _thing(zoo: Node3D) -> Node3D:
	return zoo.get_node(CRATE) as Node3D


func _mess(zoo: Node3D) -> Mess:
	return LevelRuntime.of(zoo).mess


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


func _avatar(zoo: Node3D, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a) and not a.is_queued_for_deletion():
			return a
	return null


func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## A zoo in a machine of its own (its own MultiplayerAPI and 3D world), with only the KEEP stations.
func _branch(label: String, with_book := false) -> Node3D:
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
	if with_book:
		var book := (load("res://game/entities/encyclopedia_book/encyclopedia_book.tscn") as PackedScene).instantiate() as Node3D
		book.name = "Book"
		book.position = BOOK_PLACE
		zoo.get_node("Stations/Handling").add_child(book)
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
