## core/182 in co-op (docs/architecture/x-rays.md "The kinds of state"; behaviour list "Owning and using"
## lines 1 and 6): two zoos in one process, each a machine of its own, real ENet over 127.0.0.1 on a port
## the system picks, frames paced to 60 a second of wall time (tests/coop_pings_test.gd). Only the X-rays
## station. The Guest owns the X-ray (its own Upgrade, set by the Host), picks the loose Sock with its own
## left button and presses key 1 into its own machine: its X-ray turns on from its own copies of the
## Hands, the Mess and the Upgrades, and it sends the Host nothing.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["XRays"]
const STATION := "Stations/XRays"
const NET_WAIT_S := 20.0
const FPS := 60
## Where the Host waits, out of the Guest's way.
const HOST_ASIDE := Vector3(4.0, 0.0, 5.0)

var _branches: Array[Node] = []
var _pace_next := 0
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []
## The Commands the Guest's machine sent up to the Host.
var _sent: Array[Command] = []
var _up := Callable()


func cases() -> Array[Dictionary]:
	return [
		{"name": "guest_own_copy", "method": "case_guest_own_copy", "world": false,
				"title": "core/182 lines 1, 6: the Guest owns the X-ray (its own level, kept by the Host), picks the loose Sock and presses key 1 on its machine: its HUD reads \"Sock X-ray on\" and xray_on plays, its X-ray shows the mate where its own Mess has it, and it sends no Command (the Session's sent count unchanged); the Host's X-ray is untouched (not owned by the Host, not on)"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(&"pick")
	_heard.clear()
	_sent.clear()
	_drop_branches()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


func case_guest_own_copy() -> void:
	var zoos := await _pair()
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := _player(guest).player_id()
	var hr := LevelRuntime.of(host)
	var hu := Upgrades.of(hr.hands)
	hr.parts.apply(hr.parts.answer(Command.new(Upgrades.SET_LEVEL, Parts.HOST, hu.id, {"upgrade": "xray", "level": 1, "player": g})))
	var gx := _xray(guest)
	var hx := _xray(host)
	await _wait(gx.owned, "the Guest's machine to read its X-ray owned", FPS * 3)
	_check(not hx.owned(), "the Host does not own it: each player's own Upgrade")
	_place(host, _station(host).to_global(HOST_ASIDE), _station(host).to_global(HOST_ASIDE + Vector3.FORWARD))
	var sock := _spot_sock(guest, "Loose")
	var at := _mess(guest).box_of(sock).get_center()
	await _aim(guest, Vector3(at.x, 0.0, at.z + 1.0), at)
	await _wait(func() -> bool: return _player(guest).aimed_sock == sock, "the Guest's crosshair on the Sock", FPS * 2)
	Input.action_press(&"pick")
	await _paced_ticks(2)
	Input.action_release(&"pick")
	await _wait(func() -> bool: return _hands(guest).items_of(g).has(sock), "the Host to answer the Guest's pick, on the Guest's machine", FPS * 3)
	await _paced_ticks(int(_player(guest).hands_tuning.grab_interval * FPS) + 2)
	var sent := _sent.size()
	_heard.clear()
	_check(gx.targets() == [_spot_sock(guest, "Behind")], "the Guest's X-ray finds the mate in its own Mess (%s)" % [gx.targets()])
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	_player(guest).get_viewport().push_input(key, true)
	await _paced_ticks(2)
	var up := key.duplicate() as InputEventKey
	up.pressed = false
	_player(guest).get_viewport().push_input(up, true)
	await _wait(gx.is_on, "key 1 to turn the Guest's X-ray on", FPS)
	_check(_player(guest).hud().message_text() == "Sock X-ray on", "the Guest's HUD reads \"Sock X-ray on\" (%s)" % _player(guest).hud().message_text())
	_check(_heard.any(func(e: Array) -> bool: return StringName(e[0]) == &"xray_on" and not bool(e[1])), "xray_on plays flat on the Guest's machine (%s)" % [_heard])
	await _paced_ticks(FPS / 2)
	_check(_sent.size() == sent, "line 6: the Guest sent no Command (%d then %d)" % [sent, _sent.size()])
	_check(not hx.is_on() and _player(host).hud().message_text() != "Sock X-ray on", "line 6: nothing of it on the Host's machine")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

func _pair() -> Array[Node3D]:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") and _mess(guest).count() == _mess(host).count(),
			"the guest zoo to be welcomed", FPS * 10)
	var parts := LevelRuntime.of(guest).parts
	_up = parts.relay
	parts.relay = func(cmd: Command) -> void:
		_sent.append(cmd)
		_up.call(cmd)
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null, "each machine's avatar of the other", FPS * 5)
	return [host, guest]


func _avatar(zoo: Node3D, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a) and not a.is_queued_for_deletion():
			return a
	return null


## Waits until `player` stands on the floor and did not move over the last paced tick.
func _stands_still(player: Player) -> void:
	var last := player.global_position
	for _i in FPS * 2:
		await _paced()
		var now := player.global_position
		if player.is_on_floor() and now.distance_to(last) < 0.0005:
			return
		last = now
	_check(false, "the player to stand still where it was put (within %d frames)" % (FPS * 2))


func _xray(zoo: Node3D) -> XRay:
	return (_player(zoo).get_node("XRays") as XRays).of_action(&"xray_show")


## Stands `zoo`'s player at `feet` looking at `target`; only it has the mouse; waits until the Host has it there.
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


func _station(zoo: Node3D) -> Node3D:
	return zoo.get_node(STATION) as Node3D


func _spot_sock(zoo: Node3D, spot: String) -> int:
	return (zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _mess(zoo: Node3D) -> Mess:
	return LevelRuntime.of(zoo).mess


func _hands(zoo: Node3D) -> Hands:
	return LevelRuntime.of(zoo).hands


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


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
