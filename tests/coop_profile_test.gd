## maintenance/09: one profile object per machine. Two zoos in one process, each a machine of its own (real ENet
## over 127.0.0.1, frames paced, as tests/coop_wardrobe_test.gd), only the Stages station kept, the Host and the
## Guest started with their own `--profile=<tag>`. The Guest shelves a Pair by left clicks: its profile (the object
## its Session welcomed with) counts the Coins and its file has them; the Host's profile, another object, counts the
## Pair too (the whole team, Q896) but none of the Guest's Coins; the Host's gate has the Guest's own pieces.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Stages"]
const STATION := "Stations/Stages"
const NET_WAIT_S := 30.0
const FPS := 60
const TAGS := ["cprof_host", "cprof_guest"]
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
const ASIDE := Vector3(4.0, 0.0, 3.0)

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path (co-op): the Guest started with --profile= shelves a Pair by left clicks; its own profile's coins_earned rises and its file has it, the Host's profile (another object, another file) counts the Pair but not the Coins, and the Host's Roster entry of the Guest holds the Guest's own pieces"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_drop_branches()
	_clean()


func _after_case() -> void:
	_drop_branches()
	_clean()


func _clean() -> void:
	for tag: String in TAGS:
		var f := "user://profile_%s.json" % tag
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)


func _tally_in_file(path: String, tally: String) -> int:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return 0
	var t: Variant = (data as Dictionary).get("tallies", {})
	return int((t as Dictionary).get(tally, 0)) if t is Dictionary else 0


func case_real_path() -> void:
	var gp := PlayerProfile.load_or_make(TAGS[1])
	gp.pieces = PackedStringArray(["odd_pair"])
	gp.save()
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hr := LevelRuntime.of(host)
	var gr := LevelRuntime.of(guest)
	hr.session.port = 0
	_check(hr.net.start(["--host", "--profile=%s" % TAGS[0]]) == OK, "the Host zoo hosts under its --profile=")
	_check(gr.net.start(["--join=127.0.0.1:%d" % hr.session.port, "--profile=%s" % TAGS[1]]) == OK, "the Guest joins under its own --profile=")
	await _wait(func() -> bool: return gr.net.mode_text().begins_with("Joined"), "the Guest to be welcomed", FPS * 15)
	var g := gr.session.me()
	var host_profile := Worlds.profile_of(host)
	var guest_profile := Worlds.profile_of(guest)
	_check(host_profile != guest_profile and host_profile.id != guest_profile.id, "the two machines reach two profile objects")
	_check(guest_profile == gr.session.profile and guest_profile.path == "user://profile_%s.json" % TAGS[1], "the Guest's is the --profile= file's")
	var entry: Dictionary = hr.roster.players[guest_profile.id]
	_check(Array(entry["owned"]).has("odd_pair"), "the welcome shows the Guest's own piece (%s)" % [entry["owned"]])
	var host_entry: Dictionary = hr.roster.players[host_profile.id]
	_check(not Array(host_entry["owned"]).has("odd_pair"), "and not on the Host's entry")
	# The Guest's player shelves a Pair, by real clicks.
	var mess := gr.mess
	var hands := gr.hands
	var cab := guest.get_node(STATION + "/CabinetA/Cabinet") as Cabinet
	await _wait(func() -> bool: return mess.looks_of(SIMPLE[3]) != null and mess.looks_of(SIMPLE[3] + 1) != null,
			"the Socks to lie on the Guest's machine", FPS * 20)
	_place(host, _spot(host, ASIDE), _spot(host, Vector3.ZERO))
	await _aim(guest, BY_SOCKS, _centre(mess, SIMPLE[3]))
	await _paced_ticks(25)
	await _press(&"pick")
	await _wait(func() -> bool: return hands.active_of(g) == SIMPLE[3], "the Sock to be in the Guest's Hands", FPS * 5)
	await _paced_ticks(25)
	await _aim(guest, BY_SOCKS, _centre(mess, SIMPLE[3] + 1))
	await _press(&"pick")
	await _wait(func() -> bool: return mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair", FPS * 5)
	await _aim(guest, BY_CABINET, _drawer_front(cab, 0))
	await _press(&"pick")
	await _wait(func() -> bool: return cab.shelved().size() == 1, "the Pair to be shelved", FPS * 5)
	await _wait(func() -> bool: return guest_profile.tally(PlayerProfile.COINS_EARNED) > 0, "the Guest's own profile to count its Coins", FPS * 5)
	var coins := guest_profile.tally(PlayerProfile.COINS_EARNED)
	_check(guest_profile.tally(PlayerProfile.PAIRS_SHELVED) == 1, "the Guest's profile counts the Pair (%s)" % [guest_profile.tallies])
	await _wait(func() -> bool: return host_profile.tally(PlayerProfile.PAIRS_SHELVED) == 1, "the Host's profile counts the Pair too", FPS * 5)
	_check(host_profile.tally(PlayerProfile.COINS_EARNED) == 0, "the Host's profile counts none of the Guest's Coins (%s)" % [host_profile.tallies])
	await _wait(func() -> bool: return _tally_in_file(guest_profile.path, PlayerProfile.COINS_EARNED) == coins,
			"the Guest's file to hold its Coins", FPS * 10)
	_check(_tally_in_file(host_profile.path, PlayerProfile.COINS_EARNED) == 0, "the Host's file has none")


func _spot(zoo: Node3D, local: Vector3) -> Vector3:
	return (zoo.get_node(STATION) as Node3D).global_transform * local


func _centre(mess: Mess, sock: int) -> Vector3:
	if mess.is_pair(sock):
		return mess.pose_of(sock).origin
	return mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _paced_ticks(2)
	Input.action_release(action)
	await _paced_ticks(2)


## Stands `zoo`'s player at station point `local` looking at world `target`; only it has the mouse.
func _aim(zoo: Node3D, local: Vector3, target: Vector3) -> void:
	var player := LevelRuntime.of(zoo).player
	for other: Node in _branches:
		var p := _in_branch(other).player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	var feet := _spot(zoo, local)
	_place(zoo, feet, target)
	await _paced_ticks(20)
	_place(zoo, Vector3(feet.x, player.global_position.y, feet.z), target)
	await _paced_ticks(2)


func _place(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := LevelRuntime.of(zoo).player
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


func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
