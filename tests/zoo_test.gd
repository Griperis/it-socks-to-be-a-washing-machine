## The zoo scene itself: it loads, runs a few frames with no script error, and keeps the zoo's
## rules; alone it opens no network, and two zoos in co-op see each other's players and what one's
## player uses the other sees. Nothing here tests a feature's rules through the zoo: features have their own
## suites, and the zoo is for a person to play in. The one exception is the zoo's one Mess, Hands and
## Coins (core/10, Z01-Z04), which only the zoo has.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## Where the player stands, in a station's space: before the handling station's Socks, before the
## Cabinet's drawers, and a step back to throw at it (as the stations' own suites do).
const BY_HANDLING := Vector3(0.0, 0.0, 1.5)
const BY_DRAWERS := Vector3(-1.0, 0.0, -0.4)
const THROW_FROM := Vector3(-1.0, 0.0, 0.6)
## Where a Throw at the Cabinet station's Cabinet is aimed, in the station's space.
## Scenes that may only appear in the zoo: everything else on a station comes from the game.
const ZOO_FOLDER := "res://game/zoo/"
const STATIONS_FOLDER := "res://game/zoo/stations"

## Network waits give real time, which a busy machine stretches.
const NET_WAIT_S := 20.0
const CUPBOARD := "Stations/Openables/Cupboard"

var _zoo: Node3D = null
## The co-op case's machines: each a Node with its own MultiplayerAPI.
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "runs", "method": "case_runs", "world": false,
				"title": "the zoo loads, binds its parts and runs 30 frames with the player standing on the floor"},
		{"name": "stations", "method": "case_stations", "world": false,
				"title": "every scene in game/zoo/stations/ is a station of the zoo, named and placed apart, built from the game's own scenes"},
		{"name": "labels", "method": "case_labels", "world": false,
				"title": "core/33: every station's Name label hangs between 0.8 and 2.2 m, outside every other station's pad, and all share one look"},
		{"name": "labels_walk", "method": "case_labels_walk", "world": false,
				"title": "core/33, real path: the player walks from the start spot over to the Furniture station beside the zoo floor and its name is on screen, upright and whole, on the way"},
		{"name": "alone", "method": "case_alone", "world": false,
				"title": "each station scene runs on its own, and two zoos hold the same stations in the same order"},
		{"name": "coop", "method": "case_coop", "world": false,
				"title": "alone the zoo opens no network; a hosting zoo and a joining zoo show each other's players, and the guest's player opens a cupboard on both"},
		{"name": "z01_click", "method": "case_z01_click", "world": false,
				"title": "Z01, real path: in the zoo the player pairs two Socks at the handling station, walks to the Cabinet station and shelves the Pair by a click"},
		{"name": "z01_throw", "method": "case_z01_throw", "world": false,
				"title": "Z01: a Pair made at the handling station is still in the Hands at the Cabinet station and shelves itself when thrown at the Cabinet"},
		{"name": "z02", "method": "case_z02", "world": false,
				"title": "Z02: the zoo has one Mess, one Hands and one Coins; every station's Socks are records of that Mess, lying where the station places them"},
		{"name": "z03", "method": "case_z03", "world": false,
				"title": "Z03: a station instanced without the zoo keeps its own Mess, Hands and Coins, and its links point at them"},
		{"name": "z04", "method": "case_z04", "world": false,
				"title": "Z04: a Sock thrown off the zoo's floor comes back to the zoo's return spot, in the zoo's Mess"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	wait_floor_s = NET_WAIT_S
	if _zoo != null:
		_zoo.free()
		_zoo = null
	_drop_branches()


func case_runs() -> void:
	var scene := load(ZOO) as PackedScene
	_check(scene != null, "the zoo scene loads")
	if scene == null:
		return
	_zoo = scene.instantiate() as Node3D
	add_child(_zoo)
	var parts := LevelRuntime.of(_zoo).parts
	_check(parts.find(func(_p: Part) -> bool: return true) != null, "its Parts found the parts on the stations")
	_check(_zoo.get_node_or_null("Spawn") is Marker3D, "it has a spawn point")
	await _frames(30)
	var player := LevelRuntime.of(_zoo).player
	_check(player.is_on_floor(), "the player stands on the floor")
	_zoo.free()
	_zoo = null


## The station scenes in the folder, sorted by name.
func _station_files() -> PackedStringArray:
	var out := PackedStringArray()
	for f in ResourceLoader.list_directory(STATIONS_FOLDER):
		if f.ends_with(".tscn"):
			out.append(STATIONS_FOLDER.path_join(f))
	out.sort()
	return out


func case_stations() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var files := _station_files()
	var stations := _zoo.get_node("Stations").get_children()
	_check(not stations.is_empty(), "the zoo has stations")
	for path in files:
		_check(stations.any(func(n: Node) -> bool: return n.scene_file_path == path), "%s is instanced under Stations in zoo.tscn" % path)
	_check(stations.size() == files.size(), "every scene in %s is a station (%d files, %d stations)" % [STATIONS_FOLDER, files.size(), stations.size()])
	var places: Array[Vector3] = []
	var pads: Array[Array] = []   # [station name, its pad on the floor]
	for station: Node3D in stations:
		_check(station.position.snappedf(0.5) == station.position, "station %s sits on the 0.5 m grid (%s)" % [station.name, station.position])
		_check(files.has(station.scene_file_path), "station %s comes from its own scene file (%s)" % [station.name, station.scene_file_path])
		var label := station.get_node_or_null("Name") as Label3D
		_check(label != null and not label.text.is_empty(), "station %s has a name" % station.name)
		_check(not places.has(station.position), "station %s stands on a place of its own (%s)" % [station.name, station.position])
		places.append(station.position)
		var pad := station.get_node_or_null("Pad") as MeshInstance3D
		_check(pad != null, "station %s has a Pad" % station.name)
		if pad != null:
			var box := pad.global_transform * pad.get_aabb()
			var rect := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
			for other: Array in pads:
				_check(not rect.intersects(other[1]), "station %s's pad stays clear of %s's" % [station.name, other[0]])
			pads.append([station.name, rect])
		for child in station.get_children():
			if child.scene_file_path.is_empty():
				continue
			var own_folder := ZOO_FOLDER + station.scene_file_path.get_file().get_basename() + "/"
			_check(not child.scene_file_path.begins_with(ZOO_FOLDER) or child.scene_file_path.begins_with(own_folder),
					"%s on %s is the game's own scene or the station's own zoo-only one (%s)" % [child.name, station.name, child.scene_file_path])
	_zoo.free()
	_zoo = null


## The look every Name label shares and where it may hang (core/33; placeholders for the designer).
const LABEL_LOW := 0.8
const LABEL_HIGH := 2.2
const LABEL_PIXEL_SIZE := 0.004
const LABEL_WIDTH := 700.0


func case_labels() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	await _frames(2)
	var rects: Array[Array] = []
	for station: Node3D in _zoo.get_node("Stations").get_children():
		var pad := station.get_node("Pad") as MeshInstance3D
		var box := pad.global_transform * pad.get_aabb()
		rects.append([station.name, Rect2(box.position.x, box.position.z, box.size.x, box.size.z)])
	var first: Label3D = null
	for station: Node3D in _zoo.get_node("Stations").get_children():
		var label := station.get_node("Name") as Label3D
		var at := label.global_position
		_check(at.y >= LABEL_LOW and at.y <= LABEL_HIGH, "%s's name hangs between %.1f and %.1f m (%.2f)" % [station.name, LABEL_LOW, LABEL_HIGH, at.y])
		for r: Array in rects:
			if r[0] != station.name:
				_check(not (r[1] as Rect2).has_point(Vector2(at.x, at.z)), "%s's name stays outside %s's pad (%s)" % [station.name, r[0], at])
		_check(label.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, "%s's name turns about the up axis only" % station.name)
		_check(is_equal_approx(label.pixel_size, LABEL_PIXEL_SIZE) and is_equal_approx(label.width, LABEL_WIDTH),
				"%s's name has the shared pixel size and wrap width" % station.name)
		if first == null:
			first = label
		_check(label.font_size == first.font_size and label.outline_size == first.outline_size and label.autowrap_mode == first.autowrap_mode,
				"%s's name has the shared font size, outline and wrap" % station.name)
	_zoo.free()
	_zoo = null


## Walks the zoo's player to `target` on the ground by the move key, turning it as the mouse would;
## `each` runs every physics tick.
func _walk_to(target: Vector3, each: Callable = Callable()) -> void:
	var player := LevelRuntime.of(_zoo).player
	Input.action_press(&"move_forward")
	var ticks := 0
	while ticks < 1500:
		var to := target - player.global_position
		to.y = 0.0
		if to.length() < 0.4:
			break
		player.rotation.y = atan2(-to.x, -to.z)
		await _physics_ticks(1)
		ticks += 1
		if each.is_valid():
			each.call()
	Input.action_release(&"move_forward")
	_check(ticks < 1500, "the player reached %s (stopped at %s)" % [target, player.global_position])


## Whether all of `label` shows in `camera`'s view: its four corners in front of the camera and
## inside the viewport. The label faces the camera about the up axis, as its billboard does.
func _label_whole(camera: Camera3D, label: Label3D) -> bool:
	var size := label.get_aabb().size
	var away := camera.global_position - label.global_position
	away.y = 0.0
	var right := Vector3.UP.cross(away.normalized())
	var view := camera.get_viewport().get_visible_rect()
	for dx: float in [-0.5, 0.5]:
		for y: float in [0.0, 1.0]:
			var corner: Vector3 = label.global_position + right * size.x * dx + Vector3.UP * size.y * y
			if camera.is_position_behind(corner) or not view.has_point(camera.unproject_position(corner)):
				return false
	return true


func case_labels_walk() -> void:
	await _zoo_up()
	var player := LevelRuntime.of(_zoo).player
	var camera := player.camera()
	# The old houses that stood here went to the house level (house/04); the Furniture station stands
	# on its own ground east of the zoo floor, its name at its south end.
	var station := _zoo.get_node("Stations/Furniture") as Node3D
	var label := station.get_node("Name") as Label3D
	player.capture_mouse()
	var seen: Array[int] = [0]
	var near_label := func() -> void:
		if player.global_position.distance_to(label.global_position) < 6.0:
			_check(_label_whole(camera, label), "on the way %s sees the house's name whole" % player.global_position)
			seen[0] += 1
	# From the start spot east past the stations, over onto the station's ground, then to stand square
	# before the name on its north side.
	await _walk_to(Vector3(4.0, 0.0, 1.0))
	await _walk_to(Vector3(18.0, 0.0, -2.5))
	await _walk_to(station.to_global(Vector3(6.0, 0.0, -8.0)))
	await _walk_to(station.to_global(Vector3(6.0, 0.0, -3.4)), near_label)
	_check(seen[0] > 0, "the name was checked on the way")
	_check(_label_whole(camera, label), "5 m in front of it, over the first row, the name is whole in view")
	_check(label.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, "and upright")


func case_alone() -> void:
	for path in _station_files():
		var scene := load(path) as PackedScene
		_check(scene != null, "%s loads" % path)
		if scene == null:
			continue
		var station := scene.instantiate() as Node3D
		_check(station != null, "the root of %s is a Node3D" % path)
		if station == null:
			continue
		add_child(station)
		await _frames(2)
		station.free()
	var a := (load(ZOO) as PackedScene).instantiate() as Node3D
	var b := (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(a)
	add_child(b)
	var names := func(zoo: Node3D) -> Array:
		return zoo.get_node("Stations").get_children().map(func(n: Node) -> String: return "%s %s" % [n.name, (n as Node3D).position])
	_check(names.call(a) == names.call(b), "two zoos hold the same stations, in the same order and places (%s)" % [names.call(a)])
	a.free()
	b.free()


func case_coop() -> void:
	var alone := _branch("Alone")
	await _frames(2)
	var alone_net := LevelRuntime.of(alone).net
	_check(not LevelRuntime.of(alone).session.is_online() and LevelRuntime.of(alone).players.get_child_count() == 0,
			"alone, the zoo opens no network and has no avatars")
	_check(alone_net.mode_text().begins_with("Alone"), "the corner says: %s" % alone_net.mode_text())
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	await _until(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined"), "the guest zoo to be welcomed")
	var g_id := gs.me()
	_check(LevelRuntime.of(host).net.mode_text().contains("2 player"), "the host's corner counts two players")
	var ha := LevelRuntime.of(host).avatars
	var ga := LevelRuntime.of(guest).avatars
	await _until(func() -> bool: return ha.of(g_id) != null and ga.of(1) != null, "each zoo to show the other's avatar")
	var host_player := LevelRuntime.of(host).player
	var guest_player := LevelRuntime.of(guest).player
	var cupboard_at := (guest.get_node(CUPBOARD) as Node3D).global_position
	guest_player.global_position = cupboard_at + Vector3(0.0, 0.0, 1.5)
	guest_player.rotation.y = 0.0
	host_player.global_position = Vector3(3.0, 0.0, 4.0)
	var guest_seen := func() -> bool: return ha.of(g_id).position.distance_to(guest_player.global_position) < 0.05
	await _until(guest_seen, "the host to see the guest's avatar where the guest's player stands")
	var host_seen := func() -> bool: return ga.of(1).position.distance_to(host_player.global_position) < 0.05
	await _until(host_seen, "the guest to see the host's avatar where the host's player stands")
	(guest_player.get_node("Head") as Node3D).rotation.x = 0.0
	var host_openable := host.get_node(CUPBOARD + "/Openable") as Openable
	var guest_openable := guest.get_node(CUPBOARD + "/Openable") as Openable
	_check(guest_player.interact() == guest_openable, "the guest's player aims at the cupboard and asks to open it")
	await _until(func() -> bool: return host_openable.open and guest_openable.open, "both zoos to have the cupboard open")
	_drop_branches()


# --- One Mess for the zoo (core/10) -------------------------------------------------------------

func case_z01_click() -> void:
	await _zoo_up()
	var handling := _zoo.get_node("Stations/Handling") as Node3D
	var station := _zoo.get_node("Stations/Cabinet") as Node3D
	var mess := LevelRuntime.of(_zoo).mess
	var hands := LevelRuntime.of(_zoo).hands
	var coins := LevelRuntime.of(_zoo).coins
	var cabinet := station.get_node("Cabinet/Cabinet") as Cabinet
	var player := LevelRuntime.of(_zoo).player
	var sock := _sock_of(handling, "Floor")
	var mate := _sock_of(handling, "MateFloor")
	_stand(handling, BY_HANDLING)
	await _aim(_centre(mess, sock))
	await _press(&"pick")
	await _until(func() -> bool: return hands.active_of(1) == sock, "the first Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_centre(mess, mate))
	await _press(&"pick")
	await _until(func() -> bool: return mess.is_pair(sock), "the mate to fuse into a Pair")
	_stand(station, BY_DRAWERS)
	await _physics_ticks(2)
	_check(player.hands() == hands and hands.items_of(1) == PackedInt32Array([sock]),
			"at the Cabinet station the Pair is still in the Hands (%s)" % [hands.items_of(1)])
	await _aim(_drawer_front(cabinet, 0))
	await _press(&"pick")
	await _until(func() -> bool: return cabinet.contents(0) == PackedInt32Array([sock]), "the Pair to be shelved in the bottom drawer")
	_check(hands.items_of(1).is_empty(), "the Hands are empty")
	_check(mess.state_of(sock) == Mess.State.SHELVED, "the Pair's record is shelved")
	_check(coins.of_player(1) == 10, "10 Coins are the player's (%d)" % coins.of_player(1))
	_check(cabinet.drawer(0).open, "the drawer slid open")


func case_z01_throw() -> void:
	await _zoo_up()
	var handling := _zoo.get_node("Stations/Handling") as Node3D
	var station := _zoo.get_node("Stations/Cabinet") as Node3D
	var mess := LevelRuntime.of(_zoo).mess
	var hands := LevelRuntime.of(_zoo).hands
	var cabinet := station.get_node("Cabinet/Cabinet") as Cabinet
	var player := LevelRuntime.of(_zoo).player
	var sock := _sock_of(handling, "Under")
	var mate := _sock_of(handling, "MateUnder")
	_stand(handling, BY_HANDLING)
	await _physics_ticks(2)
	hands.clock += 10.0
	hands.pick(1, sock)
	await _physics_ticks(1)
	hands.clock += 10.0
	hands.pick(1, mate)
	await _physics_ticks(1)
	_check(mess.is_pair(sock), "the two handling Socks fused into a Pair")
	_stand(station, THROW_FROM)
	await _aim(_drawer_front(cabinet, 1))  # core/23: a Throw lands where the crosshair is
	_check(player.hands() == hands and hands.active_of(1) == sock, "at the Cabinet station the Pair is still the active item")
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return player.charging and player.charge >= 1.0, "the ring to fill", 200)
	Input.action_release(&"drop_throw")
	await _until(func() -> bool: return mess.state_of(sock) != Mess.State.HELD, "the Pair to leave the Hands")
	await _until(func() -> bool: return mess.state_of(sock) != Mess.State.FLYING, "the thrown Pair to land or shelve")
	_check(mess.state_of(sock) == Mess.State.SHELVED, "the thrown Pair shelved itself (state %d)" % mess.state_of(sock))
	_check(cabinet.shelved().has(sock), "it is on the Cabinet's shelf (%s)" % [cabinet.shelved()])


func case_z02() -> void:
	await _zoo_up()
	var mess := LevelRuntime.of(_zoo).mess
	var hands := LevelRuntime.of(_zoo).hands
	var coins := LevelRuntime.of(_zoo).coins
	var found := {"Mess": 0, "Hands": 0, "Coins": 0}
	for node in _zoo.find_children("*", "Node", true, false):
		if node is Mess:
			found["Mess"] += 1
		elif node is Hands:
			found["Hands"] += 1
		elif node is Coins:
			found["Coins"] += 1
	_check(found == {"Mess": 1, "Hands": 1, "Coins": 1}, "one Mess, one Hands, one Coins in the zoo (%s)" % [found])
	_check(hands.mess == mess and hands.id == &"Runtime/Socks/Hands" and mess.id == &"Runtime/Socks/Mess" and coins.id == &"Runtime/Socks/Coins",
			"the Hands' Mess is the Mess; their ids are the zoo's (%s, %s, %s)" % [hands.id, mess.id, coins.id])
	var seen := {}
	var spots := 0
	for station in _zoo.get_node("Stations").get_children():
		_check(station.get_node_or_null(ZooStations.SOCKS) == null, "station %s has no Socks of its own" % station.name)
		for node in station.find_children("*", "Marker3D", true, false):
			var spot := node as SockSpot
			if spot == null:
				continue
			spots += 1
			_check(spot.sock >= 0 and spot.sock < mess.count() and not seen.has(spot.sock),
					"%s/%s is Sock %d of the zoo's Mess" % [station.name, spot.name, spot.sock])
			seen[spot.sock] = true
			_check(mess.state_of(spot.sock) == Mess.State.LYING and mess.designs[spot.sock] == spot.design
					and mess.pose_of(spot.sock).origin.distance_to(spot.global_position) < 0.001 and mess.looks_of(spot.sock) != null,
					"it lies where %s/%s places it, as its Design" % [station.name, spot.name])
	# A station's Sock generator (core/52) adds its own records after the SockSpots.
	var generated := 0
	for node in _zoo.get_tree().get_nodes_in_group(GeneratedSocks.GROUP):
		if (node as GeneratedSocks).mess == mess:
			generated += (node as GeneratedSocks).socks
	_check(mess.count() == spots + generated and spots > 0, "every SockSpot of every station is one record, and every generated Sock one more (%d records, %d spots, %d generated)" % [mess.count(), spots, generated])
	var cabinet := _zoo.get_node("Stations/Cabinet/Cabinet/Cabinet") as Cabinet
	_check(cabinet.hands_of() == hands and cabinet.coins_of() == coins and cabinet.mess_of() == mess,
			"the Cabinet takes from the zoo's Hands and Mess and pays into the zoo's Coins")


func case_z03() -> void:
	var with_socks := 0
	for path in _station_files():
		var station := (load(path) as PackedScene).instantiate() as Node3D
		add_child(station)
		await _frames(1)
		var mess := station.get_node_or_null(^"Socks/Mess") as Mess
		if mess != null:
			with_socks += 1
			var spots := mess.spots.get_children().filter(func(n: Node) -> bool: return n is SockSpot).size()
			for node in station.find_children("*", "Node", true, false):
				if node is GeneratedSocks:
					spots += (node as GeneratedSocks).socks
			_check(mess.count() == spots, "%s alone: its own Mess holds its %d Socks (%d)" % [path, spots, mess.count()])
			var hands := station.get_node(^"Socks/Hands") as Hands
			_check(hands.mess == mess, "%s alone: its own Hands take from its own Mess" % path)
			for node in station.find_children("*", "Node", true, false):
				if node is Cabinet:
					_check((node as Cabinet).hands_of() == hands, "%s alone: its Cabinet takes from its own Hands" % path)
		station.free()
	_check(with_socks >= 2, "the handling and Cabinet stations keep Socks of their own (%d)" % with_socks)


func case_z04() -> void:
	await _zoo_up()
	var handling := _zoo.get_node("Stations/Handling") as Node3D
	var mess := LevelRuntime.of(_zoo).mess
	var hands := LevelRuntime.of(_zoo).hands
	var spot := _zoo.get_node("ReturnSpot") as Marker3D
	var player := LevelRuntime.of(_zoo).player
	var sock := _sock_of(handling, "Floor")
	_stand(handling, BY_HANDLING)
	await _physics_ticks(2)
	hands.clock += 10.0
	hands.pick(1, sock)
	await _physics_ticks(1)
	_check(hands.active_of(1) == sock, "the handling station's Sock is in the Hands")
	# To the zoo floor's west edge, throwing off it.
	player.global_position = Vector3(-19.0, 0.0, handling.global_position.z + 1.5)
	player.velocity = Vector3.ZERO
	player.rotation.y = PI * 0.5
	(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(15.0)
	await _physics_ticks(2)
	_check(mess.in_bounds(player.global_position) and not mess.in_bounds(Vector3(-21.0, 1.0, 0.0)), "the zoo's playable space ends at its floor's edge")
	hands.throw(1, player.aim_dir(), 1.0)
	await _until(func() -> bool: return mess.state_of(sock) == Mess.State.FLYING, "the Sock to fly")
	await _until(func() -> bool: return mess.state_of(sock) == Mess.State.LYING, "the Sock to come down")
	_check(mess.pose_of(sock).origin.distance_to(spot.global_position) <= mess.bodies_tuning().return_scatter + 0.001, "it lies at the zoo's return spot, scattered within its radius (core/16 P12)")
	var looks := mess.looks_of(sock)
	_check(looks != null and looks.get_parent() == LevelRuntime.of(_zoo).lying, "drawn in the zoo's Lying")


## A zoo, its player standing on the floor and every Sock lying.
func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var mess := LevelRuntime.of(_zoo).mess
	var player := LevelRuntime.of(_zoo).player
	await _until(func() -> bool: return player.is_on_floor() and mess.looks_of(0) != null, "the player to stand and the Socks to lie")


## The Sock a station's SockSpot `spot_name` (under its Spots) became.
func _sock_of(station: Node, spot_name: String) -> int:
	return (station.get_node("Spots/" + spot_name) as SockSpot).sock


## Puts the zoo's player at `at` in `station`'s space.
func _stand(station: Node3D, at: Vector3) -> void:
	var player := LevelRuntime.of(_zoo).player
	player.global_position = station.to_global(at)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


## Turns the zoo's player to `target` and pitches the head at it, as the mouse would.
func _aim(target: Vector3) -> void:
	var player := LevelRuntime.of(_zoo).player
	player.capture_mouse()   # the mouse is the player's: buttons act (R01)
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Presses an action for two physics ticks, then lets it go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## The middle of a lying Sock, or of a lying Pair's ball.
func _centre(mess: Mess, sock: int) -> Vector3:
	if mess.is_pair(sock):
		return mess.pose_of(sock).origin
	return mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)


## The middle of drawer `index`'s front, in the level (the drawer shut).
func _drawer_front(cabinet: Cabinet, index: int) -> Vector3:
	var front := cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


## A zoo in a machine of its own: a Node with its own MultiplayerAPI, and a SubViewport with its own
## 3D world so two zoos in one process never touch. Returns the zoo.
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


## Every co-op machine goes: its session closes, then the nodes, then its MultiplayerAPI.
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
