## The house kit (house/01, K01-K08): snapping pieces on the half-metre grid, simple box
## collision on the house's layer, one material slot from the shared library, and the zoo's
## House kit station whose small room the player walks into and up.
extends TestSuite

const PIECES := "res://game/house/kit/pieces"
const MATERIALS := "res://game/house/kit/materials"
const SIZES := "res://game/house/kit/house_kit_sizes.tres"
const STATION := "res://game/zoo/stations/house_kit.tscn"
const PLAYER := "res://game/player/player.tscn"
const FLIGHT := "res://game/sock/flight.tscn"
const EPS := 0.001
## Every piece the kit has (Q2326), by file name.
const ALL: Array[String] = [
	"wall_exterior_05m", "wall_exterior_1m", "wall_exterior_2m",
	"wall_partition_05m", "wall_partition_1m", "wall_partition_2m",
	"corner_exterior", "corner_partition", "t_exterior", "t_partition", "t_exterior_partition",
	"door_exterior", "door_partition", "window_exterior",
	"floor_05m", "floor_1m", "floor_2m", "ceiling_05m", "ceiling_1m", "ceiling_2m",
	"stair_full", "stair_half", "landing",
]
## The old house's wall, floor and tile materials the library must hold (Q2328).
const LIBRARY: Array[String] = ["wall_outside", "wall_kitchen", "wall_hall", "wall_bathroom", "wall_bedroom",
		"wall_office", "wall_kids", "wall_tile", "ceiling", "wood", "kitchen_tile", "bath_tile", "basement_tile"]

var _level: Node3D = null
var _sizes: HouseKitSizes = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "k01_walls", "method": "case_k01_walls", "world": false,
				"title": "K01: walls 0.5, 1 and 2 m long, a storey high, 0.2 m outside and 0.12 m partition thick; corners and T-joins reach half a metre from the join"},
		{"name": "k02_tiles", "method": "case_k02_tiles", "world": false,
				"title": "K02: floor and ceiling tiles 0.5, 1 and 2 m square, the floor's top at its origin and the ceiling right under it"},
		{"name": "k03_openings", "method": "case_k03_openings", "world": false,
				"title": "K03: a door wall lets through a 0.9 x 2.1 m doorway, a window wall a 1.0 m window from 0.9 to 2.1 m"},
		{"name": "k04_stairs", "method": "case_k04_stairs", "world": false,
				"title": "K04: a full flight rises one storey, a half flight half of one, and the landing stands at half a storey, all on the grid"},
		{"name": "k05_grid", "method": "case_k05_grid", "world": false,
				"title": "K05: every piece is a scene whose origin is a grid corner, and every piece the station places sits on the grid, turned in 90 degree steps"},
		{"name": "k06_collision", "method": "case_k06_collision", "world": false,
				"title": "K06: every piece collides through a few boxes on the house's layer, inside its drawn shape; a Sock lands and lies on a floor tile and on a stair"},
		{"name": "k07_material", "method": "case_k07_material", "world": false,
				"title": "K07: every piece draws with one material slot from the library, and a placed piece's override is what it draws"},
		{"name": "k08_station", "method": "case_k08_station", "world": false,
				"title": "K08: the House kit station shows every piece of the kit"},
		{"name": "real_path_room", "method": "case_real_path_room", "world": false,
				"title": "real path: in the House kit station the player walks in at the door, is stopped by the partition, and climbs the stair onto the upper floor"},
	]


func _before_case() -> void:
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_sizes = load(SIZES) as HouseKitSizes


func _piece(file: String) -> MeshInstance3D:
	return (load(PIECES.path_join(file + ".tscn")) as PackedScene).instantiate() as MeshInstance3D


## The drawn shape of a piece in its own space.
func _aabb(file: String) -> AABB:
	var p := _piece(file)
	var box := p.mesh.get_aabb()
	p.free()
	return box


func _box_near(box: AABB, from: Vector3, to: Vector3, what: String) -> void:
	_check(box.position.is_equal_approx(from) and box.end.is_equal_approx(to),
			"%s spans %s to %s (got %s to %s)" % [what, from, to, box.position, box.end])


func case_k01_walls() -> void:
	var h := _sizes.storey
	_near(h, 3.0, EPS, "a storey is the old house's 2.9 m nudged to 3.0 m")
	for kind: String in ["exterior", "partition"]:
		var t: float = _sizes.get(kind)
		for tag: String in ["05m", "1m", "2m"]:
			var length := {"05m": 0.5, "1m": 1.0, "2m": 2.0}[tag] as float
			_box_near(_aabb("wall_%s_%s" % [kind, tag]), Vector3(0, 0, -t / 2), Vector3(length, h, t / 2), "wall_%s_%s" % [kind, tag])
		_box_near(_aabb("corner_" + kind), Vector3(-t / 2, 0, -t / 2), Vector3(0.5, h, 0.5), "corner_" + kind)
		_box_near(_aabb("t_" + kind), Vector3(-0.5, 0, -t / 2), Vector3(0.5, h, 0.5), "t_" + kind)
	_near(_sizes.exterior, 0.2, EPS, "an outside wall is 0.2 m thick")
	_near(_sizes.partition, 0.12, EPS, "a partition is 0.12 m thick")
	_box_near(_aabb("t_exterior_partition"), Vector3(-0.5, 0, -0.1), Vector3(0.5, h, 0.5), "t_exterior_partition")


func case_k02_tiles() -> void:
	for tag: String in ["05m", "1m", "2m"]:
		var side := {"05m": 0.5, "1m": 1.0, "2m": 2.0}[tag] as float
		_box_near(_aabb("floor_" + tag), Vector3(0, -0.1, 0), Vector3(side, 0, side), "floor_" + tag)
		_box_near(_aabb("ceiling_" + tag), Vector3(0, -0.2, 0), Vector3(side, -0.1, side), "ceiling_" + tag)


## A level of only `files` at their places, and its physics ready.
func _build(placed: Array) -> void:
	_level = Node3D.new()
	_level.name = "Level"
	for entry: Array in placed:
		var p := _piece(entry[0])
		p.position = entry[1]
		_level.add_child(p)
	add_child(_level)
	await _physics_ticks(2)


func _hits(from: Vector3, to: Vector3) -> bool:
	return not PhysicsQueries.ray(_level, from, to, Mess.LAYER_HOUSE).is_empty()


func case_k03_openings() -> void:
	await _build([["door_exterior", Vector3.ZERO], ["door_partition", Vector3(0, 0, 2)], ["window_exterior", Vector3(0, 0, 4)]])
	for z: float in [0.0, 2.0]:
		var across := func(x: float, y: float) -> bool: return _hits(Vector3(x, y, z - 1), Vector3(x, y, z + 1))
		_check(not across.call(0.5, 1.0) and not across.call(0.07, 0.3) and not across.call(0.93, 2.05), "the doorway at z %s is open 0.9 m wide and 2.1 m high" % z)
		_check(across.call(0.03, 1.0) and across.call(0.97, 1.0) and across.call(0.5, 2.15), "the door wall at z %s stands either side and over it" % z)
	var win := func(x: float, y: float) -> bool: return _hits(Vector3(x, y, 3), Vector3(x, y, 5))
	_check(not win.call(1.0, 1.5) and not win.call(0.55, 0.95) and not win.call(1.45, 2.05), "the window is open 1.0 m wide from 0.9 m to 2.1 m")
	_check(win.call(1.0, 0.85) and win.call(1.0, 2.15) and win.call(0.45, 1.5) and win.call(1.55, 1.5), "the window wall stands under, over and either side of it")


func case_k04_stairs() -> void:
	var h := _sizes.storey
	_box_near(_aabb("stair_full"), Vector3.ZERO, Vector3(1, h, 4), "stair_full")
	_box_near(_aabb("stair_half"), Vector3.ZERO, Vector3(1, h / 2, 2), "stair_half")
	_box_near(_aabb("landing"), Vector3.ZERO, Vector3(2, h / 2, 1), "landing")
	await _build([["stair_full", Vector3.ZERO], ["landing", Vector3(3, 0, 0)]])
	var top := PhysicsQueries.ray(_level, Vector3(0.5, 5, 3.9), Vector3(0.5, -1, 3.9), Mess.LAYER_HOUSE)
	_check(not top.is_empty() and absf((top["position"] as Vector3).y - h) < 0.01, "a full flight's top step is walked at the next floor's height (got %s)" % top.get("position"))
	var mid := PhysicsQueries.ray(_level, Vector3(0.5, 5, 2.0), Vector3(0.5, -1, 2.0), Mess.LAYER_HOUSE)
	_check(not mid.is_empty() and absf((mid["position"] as Vector3).y - 1.5) < 0.2, "halfway up it is about half a storey (got %s)" % mid.get("position"))
	var land := PhysicsQueries.ray(_level, Vector3(4, 5, 0.5), Vector3(4, -1, 0.5), Mess.LAYER_HOUSE)
	_check(not land.is_empty() and absf((land["position"] as Vector3).y - h / 2) < EPS, "the landing's top is half a storey up (got %s)" % land.get("position"))


func _on_grid(v: float) -> bool:
	return is_equal_approx(snappedf(v, _sizes.grid), v)


func case_k05_grid() -> void:
	var files := Array(ResourceLoader.list_directory(PIECES)).filter(func(f: String) -> bool: return f.ends_with(".tscn"))
	_check(files.size() == ALL.size(), "the kit has its %d pieces (found %d)" % [ALL.size(), files.size()])
	for file: String in ALL:
		_check(ResourceLoader.exists(PIECES.path_join(file + ".tscn")), "%s is a scene of the kit" % file)
		var p := _piece(file)
		_check(p.transform.is_equal_approx(Transform3D.IDENTITY), "%s's root sits at its origin, unturned" % file)
		# The grid corners a piece reaches along the floor are on the grid; a wall's thickness is
		# centred on its grid line.
		var box := p.mesh.get_aabb()
		var flat := file.begins_with("floor") or file.begins_with("ceiling") or file.begins_with("stair") or file == "landing"
		var xs := [box.end.x] if file.begins_with("corner") else [box.position.x, box.end.x]
		if file.begins_with("t_"):
			xs = [box.position.x, box.end.x]
		for x: float in xs:
			_check(_on_grid(x), "%s reaches x %s, on the grid" % [file, x])
		if flat or file.begins_with("corner") or file.begins_with("t_"):
			_check(_on_grid(box.end.z), "%s reaches z %s, on the grid" % [file, box.end.z])
		p.free()
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	var placed := 0
	for node: Node in station.find_children("*", "MeshInstance3D", true, false):
		if not node.scene_file_path.begins_with(PIECES):
			continue
		placed += 1
		var n := node as Node3D
		var at := n.position
		_check(_on_grid(at.x) and _on_grid(at.y) and _on_grid(at.z), "%s sits on the grid (%s)" % [n.name, at])
		var turn := rad_to_deg(n.rotation.y)
		_check(is_equal_approx(snappedf(turn, 90.0), snappedf(turn, 0.01)) and absf(n.rotation.x) < EPS and absf(n.rotation.z) < EPS,
				"%s is turned in 90 degree steps about the vertical (%s)" % [n.name, turn])
	_check(placed > ALL.size(), "the station places the kit's pieces (%d)" % placed)
	_check(_on_grid(station.position.x) and _on_grid(station.position.z), "the station's root is on the grid")
	station.free()


func case_k06_collision() -> void:
	for file: String in ALL:
		var p := _piece(file)
		var body := p.get_node_or_null("Body") as StaticBody3D
		_check(body != null, "%s has a static Body" % file)
		if body == null:
			p.free()
			continue
		_check(body.collision_layer == Mess.LAYER_HOUSE, "%s is on the house's physics layer (%d)" % [file, body.collision_layer])
		var shapes := body.get_children()
		_check(shapes.size() >= 1 and shapes.size() <= 4, "%s collides through a few shapes (%d)" % [file, shapes.size()])
		var drawn := p.mesh.get_aabb().grow(0.01)
		for s: Node in shapes:
			var cs := s as CollisionShape3D
			_check(cs != null and cs.shape is BoxShape3D, "%s's %s is a box, never its drawn mesh" % [file, s.name])
			if cs == null or not cs.shape is BoxShape3D:
				continue
			var half := (cs.shape as BoxShape3D).size / 2
			var top := cs.transform * Vector3(0, half.y, 0)
			_check(drawn.has_point(top), "%s's %s keeps its top inside the drawn piece" % [file, s.name])
		p.free()
	# Socks lie on floors and stairs: a falling Sock (the Mess's flight body) comes to rest on them.
	await _build([["floor_2m", Vector3(0, 1, 0)], ["stair_full", Vector3(4, 0, 0)]])
	var on_floor := (load(FLIGHT) as PackedScene).instantiate() as RigidBody3D
	on_floor.position = Vector3(1, 2, 1)
	var on_stair := (load(FLIGHT) as PackedScene).instantiate() as RigidBody3D
	on_stair.position = Vector3(4.5, 3, 2)
	_level.add_child(on_floor)
	_level.add_child(on_stair)
	await _until(func() -> bool: return on_floor.sleeping or (on_floor.linear_velocity.length() < 0.01 and on_floor.position.y < 1.2), "the Sock to settle on the floor tile")
	_near(on_floor.position.y, 1.0, 0.03, "the Sock lies on the floor tile's top")
	await _physics_ticks(60)
	_check(on_stair.position.y > 1.0 and on_stair.position.y < 2.5, "the Sock lies on the stair, not through it (y %s)" % on_stair.position.y)


func case_k07_material() -> void:
	for name: String in LIBRARY:
		var m := load(MATERIALS.path_join(name + ".tres")) as StandardMaterial3D
		_check(m != null, "the library has %s" % name)
	for file: String in ALL:
		var p := _piece(file)
		_check(p.mesh.get_surface_count() == 1, "%s has one material slot (%d)" % [file, p.mesh.get_surface_count()])
		var own := p.mesh.surface_get_material(0)
		_check(own != null and own.resource_path.begins_with(MATERIALS), "%s draws with a library material (%s)" % [file, own.resource_path if own else "none"])
		p.free()
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	var partition := station.get_node("Room/PartitionDoor") as MeshInstance3D
	var hall := load(MATERIALS.path_join("wall_hall.tres")) as Material
	_check(partition.get_surface_override_material(0) == hall and partition.get_active_material(0) == hall,
			"the station's partition door draws the wall_hall it was given")
	var plain := station.get_node("Room/Door") as MeshInstance3D
	_check(plain.get_surface_override_material(0) == null and plain.get_active_material(0) == plain.mesh.surface_get_material(0),
			"a piece given nothing draws its own material")
	station.free()


func case_k08_station() -> void:
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	var shown := {}
	for node: Node in station.get_node("LineUp").get_children():
		if node.scene_file_path.begins_with(PIECES):
			shown[node.scene_file_path.get_file().get_basename()] = true
	for file: String in ALL:
		_check(shown.has(file), "the line-up shows %s" % file)
	_check(station.get_node_or_null("Room/Stair") != null and station.get_node_or_null("Room/Door") != null, "the small room has its door and stair")
	station.free()


## The station alone on a floor, with the player and the level's Parts, as the zoo has them.
func _station_level() -> Player:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 40)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	station.position = Vector3.ZERO   # its root carries its place in the zoo; the case walks it alone
	_level.add_child(station)
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	player.position = Vector3(3.5, 0, -1.5)
	player.rotation.y = PI   # facing +Z, at the door
	_level.add_child(player)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	return player


func case_real_path_room() -> void:
	var player := await _station_level()
	# In at the door (x 3..4 of the front wall at z 0) and on until the partition at z 5 stops it.
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.z > 1.0, "the player to walk in at the door")
	var last := player.global_position.z
	var still := 0
	while still < 20:
		await _physics_ticks(1)
		still = still + 1 if absf(player.global_position.z - last) < 0.0005 else 0
		last = player.global_position.z
		_check(last < 6.0, "the player never walks through the partition")
		if last >= 6.0:
			break
	Input.action_release(&"move_forward")
	_check(last < 5.0 - 0.06 - 0.3 and last > 4.0, "the partition stopped the player before it (z %s)" % last)
	# To the stair's foot (x 1..2, from z 1), then up it onto the upper floor.
	player.global_position = Vector3(1.5, 0.0, 0.5)
	player.rotation.y = PI
	player.reset_physics_interpolation()
	await _physics_ticks(3)
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return player.global_position.z > 5.6 and player.is_on_floor(), "the player to climb the stair onto the upper floor")
	Input.action_release(&"move_forward")
	_near(player.global_position.y, _sizes.storey, 0.05, "the player stands on the upper floor, a storey up")
