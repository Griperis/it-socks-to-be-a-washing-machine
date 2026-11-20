## The zoo scene itself: it loads, runs a few frames with no script error, and keeps the zoo's
## rules; alone it opens no network, and two zoos in co-op see each other's players and what one's
## player uses the other sees. Nothing here tests a feature's rules through the zoo: features have their own
## suites, and the zoo is for a person to play in.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
## Scenes that may only appear in the zoo: everything else on a station comes from the game.
const ZOO_FOLDER := "res://game/zoo/"

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
		{"name": "alone", "method": "case_alone", "world": false,
				"title": "each station scene runs on its own, and two zoos hold the same stations in the same order"},
		{"name": "coop", "method": "case_coop", "world": false,
				"title": "alone the zoo opens no network; a hosting zoo and a joining zoo show each other's players, and the guest's player opens a cupboard on both"},
	]


func _before_case() -> void:
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
	var parts := _zoo.get_node("Parts") as Parts
	_check(parts.find(func(_p: Part) -> bool: return true) != null, "its Parts found the parts on the stations")
	_check(_zoo.get_node_or_null("Spawn") is Marker3D, "it has a spawn point")
	await _frames(30)
	var player := _zoo.get_node("Player") as CharacterBody3D
	_check(player.is_on_floor(), "the player stands on the floor")
	_zoo.free()
	_zoo = null


func case_stations() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var files := ZooStations.scenes()
	var stations := _zoo.get_node("Stations").get_children()
	_check(not stations.is_empty(), "the zoo has stations")
	_check(stations.size() == files.size(), "every scene in %s is a station (%d files, %d stations)" % [ZooStations.FOLDER, files.size(), stations.size()])
	var places: Array[Vector3] = []
	for station: Node3D in stations:
		_check(files.has(station.scene_file_path), "station %s comes from its own scene file (%s)" % [station.name, station.scene_file_path])
		var label := station.get_node_or_null("Name") as Label3D
		_check(label != null and not label.text.is_empty(), "station %s has a name" % station.name)
		_check(not places.has(station.position), "station %s stands on a place of its own (%s)" % [station.name, station.position])
		places.append(station.position)
		for child in station.get_children():
			if child.scene_file_path.is_empty():
				continue
			_check(not child.scene_file_path.begins_with(ZOO_FOLDER),
					"%s on %s is the game's own scene (%s)" % [child.name, station.name, child.scene_file_path])
	_check(ZooStations.place(0) != ZooStations.place(1) and ZooStations.place(0).z > ZooStations.place(ZooStations.COLUMNS).z,
			"the grid gives each station its own place, a full row starting the next one further away")
	_zoo.free()
	_zoo = null


func case_alone() -> void:
	for path in ZooStations.scenes():
		var scene := load(path) as PackedScene
		_check(scene != null, "%s loads" % path)
		if scene == null:
			continue
		var station := scene.instantiate() as Node3D
		_check(station != null, "the root of %s is a Node3D" % path)
		if station == null:
			continue
		_check(station.position.is_zero_approx() or station.position.snappedf(0.5) == station.position,
				"%s leaves its place to the zoo's grid, or sits on the 0.5 m grid" % path)
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
	var alone_net := alone.get_node("Net") as ZooNet
	_check(not (alone.get_node("Session") as Session).is_online() and alone.get_node("Players").get_child_count() == 0,
			"alone, the zoo opens no network and has no avatars")
	_check(alone_net.mode_text().begins_with("Alone"), "the corner says: %s" % alone_net.mode_text())
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := host.get_node("Session") as Session
	hs.port = 0
	_check((host.get_node("Net") as ZooNet).start(["--host"]) == OK, "the host zoo hosts")
	var gs := guest.get_node("Session") as Session
	_check((guest.get_node("Net") as ZooNet).start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	await _until(func() -> bool: return (guest.get_node("Net") as ZooNet).mode_text().begins_with("Joined"), "the guest zoo to be welcomed")
	var g_id := gs.me()
	_check((host.get_node("Net") as ZooNet).mode_text().contains("2 player"), "the host's corner counts two players")
	var ha := host.get_node("Avatars") as Avatars
	var ga := guest.get_node("Avatars") as Avatars
	await _until(func() -> bool: return ha.of(g_id) != null and ga.of(1) != null, "each zoo to show the other's avatar")
	var host_player := host.get_node("Player") as Player
	var guest_player := guest.get_node("Player") as Player
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
		var session := node.get_node_or_null("View/Zoo/Session") as Session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()

