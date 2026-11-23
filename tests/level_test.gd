## The level runtime (core/51, Q2517): one sealed scene, game/level/level_runtime.tscn, with the full
## game setup (the player, the Mess, the Parts, the Session, the Avatars, the Net); a level is its own
## geometry, a Spawn marker and one instance of it. The house, the zoo and the one-box example level
## each instance it once and override nothing inside it; the one-box level is walked by the player's
## own input and played by a Host and a Guest who see each other.
extends TestSuite

const RUNTIME := "res://game/level/level_runtime.tscn"
const ONE_BOX := "res://game/level/one_box_level.tscn"
const HOUSE := "res://game/house/house.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
## The nodes the runtime holds; no level has one of its own.
const RUNTIME_NODES: Array[String] = ["Player", "Players", "Avatars", "Session", "Net", "Parts", "Socks", "Spots",
		"Lying", "Flights", "FlightSpawner"]

var _level: Node3D = null
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "sealed", "method": "case_sealed", "world": false,
				"title": "the house, the zoo and the one-box level each instance the runtime once, keep none of its nodes of their own and override nothing inside it"},
		{"name": "settings", "method": "case_settings", "world": false,
				"title": "what differs per level is set on the instance: the player starts on the level's Spawn, the zoo's player holds 3 and the zoo's corner says zoo, the Parts bind the whole level"},
		{"name": "real_path_one_box_walk", "method": "case_real_path_one_box_walk", "world": false,
				"title": "real path: in the one-box level the player stands on its Spawn and walks forward on the move key; its view goes with it"},
		{"name": "one_box_coop", "method": "case_one_box_coop", "world": false,
				"title": "the one-box level is played alone as a Host of one; with --host and --join a second one joins it and each sees the other's avatar"},
	]


func _before_case() -> void:
	Input.action_release(&"move_forward")
	if _level != null:
		_level.free()
		_level = null
	_drop_branches()


func case_sealed() -> void:
	for path: String in [HOUSE, ZOO, ONE_BOX]:
		var state := (load(path) as PackedScene).get_state()
		var instances := 0
		for i in state.get_node_count():
			var node_path := String(state.get_node_path(i))
			var name := String(state.get_node_name(i))
			var inst := state.get_node_instance(i)
			if inst != null and inst.resource_path == RUNTIME:
				instances += 1
				_same(String(state.get_node_path(i, true)), ".", "%s: the runtime is a child of the level's root" % path)
			_check(not node_path.begins_with("./Runtime/"), "%s: nothing overrides %s inside the runtime" % [path, node_path])
			if String(state.get_node_path(i, true)) == ".":
				_check(not RUNTIME_NODES.has(name), "%s: no %s of its own beside the runtime" % [path, name])
		_same(instances, 1, "%s instances the runtime once" % path)
		_check(not FileAccess.get_file_as_string(path).contains("[editable path="), "%s: no editable children" % path)


func case_settings() -> void:
	_level = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var runtime := LevelRuntime.of(_level)
	_check(runtime != null and LevelRuntime.of(runtime.mess) == runtime, "the runtime is found from the level and from a node inside it")
	_check(LevelRuntime.level_of(runtime.mess) == _level, "a runtime node's level is the zoo")
	_check(runtime.player.hands_tuning.capacity == 3, "the zoo's player holds 3 (%d)" % runtime.player.hands_tuning.capacity)
	_same(runtime.net.place_name(), "zoo", "the zoo's corner says zoo")
	_check(runtime.mess.return_spot == _level.get_node("ReturnSpot"), "the Mess puts lost Socks at the zoo's ReturnSpot")
	_check(runtime.parts.find(func(p: Part) -> bool: return String(p.id).begins_with("Stations/")) != null,
			"the Parts bind the stations' parts, outside the runtime")
	_level.free()
	_level = null
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	runtime = LevelRuntime.of(_level)
	var spawn := _level.get_node("Spawn") as Marker3D
	_check(runtime.player.global_transform.is_equal_approx(spawn.global_transform), "the house's player starts on its Spawn")
	_same(runtime.net.place_name(), "house", "the house's corner says house")


func case_real_path_one_box_walk() -> void:
	_level = (load(ONE_BOX) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var player := LevelRuntime.of(_level).player
	var spawn := (_level.get_node("Spawn") as Marker3D).global_position
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand on the box")
	_check(Vector2(player.global_position.x - spawn.x, player.global_position.z - spawn.z).length() < 0.05,
			"it stands on the Spawn (%s)" % player.global_position)
	var eyes := player.view().origin
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.z < spawn.z - 1.0, "the player to walk 1 m forward", 300)
	Input.action_release(&"move_forward")
	_check(player.view().origin.z < eyes.z - 0.8, "its view went with it (%s to %s)" % [eyes, player.view().origin])
	_check(player.is_on_floor(), "still on the box")


func case_one_box_coop() -> void:
	var alone := _branch("Alone")
	await _frames(2)
	_check(not LevelRuntime.of(alone).session.is_online() and LevelRuntime.of(alone).players.get_child_count() == 0,
			"alone, the level opens no network and has no avatars")
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the level hosts")
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "another one joins it")
	await _until(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined"), "the guest to be welcomed")
	var g_id := gs.me()
	var ha := LevelRuntime.of(host).avatars
	var ga := LevelRuntime.of(guest).avatars
	await _until(func() -> bool: return ha.of(g_id) != null and ga.of(1) != null, "each to show the other's avatar")
	_drop_branches()


## A one-box level in a machine of its own (its own MultiplayerAPI and 3D world).
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
	var level := (load(ONE_BOX) as PackedScene).instantiate() as Node3D
	view.add_child(level)
	_branches.append(node)
	return level


## Every co-op machine goes: its session closes, then the nodes, then its MultiplayerAPI.
func _drop_branches() -> void:
	for node in _branches:
		var level := node.get_node_or_null("View/OneBoxLevel")
		var session := LevelRuntime.of(level).session if level != null else null
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
