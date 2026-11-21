## The 17 Cabinets (assets/02): each Collection's Cabinet wears the old game's model as a Looks of
## the one Cabinet entity and its drawers (K01), the Cabinet station lines up every Collection's
## Cabinet, built from the catalogue at load (K02, Q2337), and the drawers' collision and Sock spots
## are the old models' (K03). The real path: the player shelves a Patterns Pair into the Patterns
## Cabinet of the line-up and sees its ball in that Cabinet's own drawer.
extends TestSuite

const STATION := "res://game/zoo/stations/cabinet.tscn"
const CABINET := "res://game/entities/cabinet/cabinet.tscn"
const PLAYER := "res://game/player/player.tscn"
const DESIGNS := "res://game/sock/designs.tres"
const LAYOUT := "res://game/zoo/cabinet_gallery/cabinet_gallery_layout.tres"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's Patterns Pair (its SockSpots' order, as in cabinet_test.gd).
const PATTERNS := 10
const PATTERNS_MATE := 11
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
## The old models' collision (every one of the 17 the same, in the glb's `-convcolonly` meshes): a
## drawer front from y 0.11 to 0.39 and z 0.21 to 0.25 with the drawer at y 0.11, 1.46 m wide; the
## shell 1.5 m wide, z -0.25 to 0.21. The old first slot point, `slot_01`, in the drawer.
const FRONT_SIZE := Vector3(1.46, 0.28, 0.04)
const FRONT_AT := Vector3(0.0, 0.14, 0.23)
const SHELL_X := 0.75
const SHELL_Z := Vector2(-0.25, 0.21)
const OLD_SLOT_01 := Vector3(-0.585, 0.085, -0.15)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _coins: Coins = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the station the real actions pair two Patterns Socks and click the Patterns Cabinet's drawer: the ball shows in that Cabinet's own drawer, which wears the Patterns Looks"},
		{"name": "k01_looks", "method": "case_k01_looks", "world": false,
				"title": "K01: every Collection has a Cabinet Looks and a drawer Looks, each with what its folder's looks_contract.json names and that Collection's own meshes"},
		{"name": "k01_dress", "method": "case_k01_dress", "world": false,
				"title": "K01: a Cabinet wears its Collection's Looks on itself and on every drawer once ready; a new Collection's Looks takes an open drawer's pose at once"},
		{"name": "k02_station", "method": "case_k02_station", "world": false,
				"title": "K02: the Cabinet station shows every Collection's Cabinet once, each in its own Looks, on its pad and inside its Mess bounds"},
		{"name": "k02_from_data", "method": "case_k02_from_data", "world": false,
				"title": "K02 (Q2337): a new Collection in the catalogue gets a Cabinet in the line-up with no other change"},
		{"name": "k03_collision_spots", "method": "case_k03", "world": false,
				"title": "K03: every Collection's drawer front, shell and 25 slot points are the old models'"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


## Every Collection of the catalogue, in the order its first Design appears.
static func collections() -> Array[StringName]:
	var catalogue := load(DESIGNS) as DesignCatalogue
	var out: Array[StringName] = []
	for id in catalogue.size():
		var d := catalogue.design(id)
		if d != null and not out.has(d.collection):
			out.append(d.collection)
	return out


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var gallery := _station.get_node("Gallery") as CabinetGallery
	var root := gallery.cabinet_of(&"patterns")
	_check(root != null, "the line-up has the Patterns Cabinet")
	if root == null:
		return
	var cabinet := root.get_node("Cabinet") as Cabinet
	_stand(_station.to_global(BY_SOCKS))
	await _aim(_centre(PATTERNS))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == PATTERNS, "the first Patterns Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_centre(PATTERNS_MATE))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(PATTERNS), "its mate to fuse into a Pair")
	_stand(root.to_global(Vector3(-0.3, 0.0, 1.3)))
	var front := root.get_node("Drawer1/Looks/Slide/Front") as Node3D
	await _aim(front.global_position + root.global_basis * Vector3(0.3, 0.0, 0.0))
	await _press(&"pick")
	await _until(func() -> bool: return cabinet.contents(0) == PackedInt32Array([PATTERNS]),
			"the Pair to be shelved in the Patterns Cabinet's bottom drawer")
	await _frames(2)
	var looks := root.get_node("Drawer1/Looks") as Node3D
	_check(looks.scene_file_path == Cabinet.looks_path(&"patterns", true),
			"the drawer wears the Patterns Looks (%s)" % looks.scene_file_path)
	var slot := looks.find_child(Cabinet.SLOT % 1, true, false)
	var ball := slot.get_node_or_null(NodePath(Cabinet.BALL)) if slot != null else null
	_check(ball != null and int(ball.get_meta(Mess.SOCK_META, -1)) == PATTERNS, "the Pair's ball shows in its first slot")
	_check(cabinet.drawer(0).open, "the drawer slid open")
	_check(_coins.of_player(1) > 0, "the player is paid (%d)" % _coins.of_player(1))
	_check(_hands.items_of(1).is_empty(), "the Hands are empty")


# --- K01 -----------------------------------------------------------------------------------------

func case_k01_looks() -> void:
	var cabinet_names := _contract("res://game/entities/cabinet/looks_contract.json")
	var drawer_contract := _contract_all("res://game/entities/drawer/looks_contract.json")
	_check(not cabinet_names.is_empty() and not drawer_contract.is_empty(), "both contracts read")
	for c in collections():
		for for_drawer: bool in [false, true]:
			var path := Cabinet.looks_path(c, for_drawer)
			_check(not path.is_empty(), "%s has its own %s Looks" % [c, "drawer" if for_drawer else "Cabinet"])
			if path.is_empty():
				continue
			var looks := (load(path) as PackedScene).instantiate() as Node3D
			var names: PackedStringArray = drawer_contract.get("nodes", []) if for_drawer else cabinet_names
			for n in names:
				_check(looks.find_child(n, true, false) != null, "%s has %s" % [path.get_file(), n])
			if for_drawer:
				var player := looks.find_children("*", "AnimationPlayer", true, false)
				_check(player.size() == 1, "%s has its AnimationPlayer" % path.get_file())
				for a: String in drawer_contract.get("animations", []):
					_check(player.size() == 1 and (player[0] as AnimationPlayer).has_animation(a), "%s has the animation %s" % [path.get_file(), a])
			# The meshes are this Collection's (assets/cabinet/<collection>_<part>.res).
			for m in looks.find_children("*", "MeshInstance3D", true, false):
				var mesh := (m as MeshInstance3D).mesh
				if mesh == null or not mesh.resource_path.begins_with("res://assets/cabinet/"):
					continue
				_check(mesh.resource_path.get_file().begins_with("%s_" % c), "%s draws %s's mesh (%s)" % [path.get_file(), c, mesh.resource_path.get_file()])
			looks.free()


func case_k01_dress() -> void:
	_level = Node3D.new()
	add_child(_level)
	for c in collections():
		var root := (load(CABINET) as PackedScene).instantiate() as Node3D
		(root.get_node("Cabinet") as Cabinet).collection = c
		_level.add_child(root)
		var part := root.get_node("Cabinet") as Cabinet
		_check((root.get_node("Looks") as Node3D).scene_file_path == Cabinet.looks_path(c, false), "a %s Cabinet wears its Looks" % c)
		_check(part.drawer_count() == 3, "it keeps its 3 drawers (%d)" % part.drawer_count())
		for i in part.drawer_count():
			var looks := root.get_node("Drawer%d/Looks" % (i + 1)) as Node3D
			_check(looks.scene_file_path == Cabinet.looks_path(c, true), "its drawer %d wears its Looks" % (i + 1))
			_check(looks.get_index() == root.get_node("Drawer%d/Openable" % (i + 1)).get_index() + 1, "the Looks keeps its place beside the Openable")
	# An open drawer of a Simple Cabinet that turns Space: its new Looks is open at once.
	var root := (load(CABINET) as PackedScene).instantiate() as Node3D
	_level.add_child(root)
	var part := root.get_node("Cabinet") as Cabinet
	var openable := part.drawer(0)
	openable.open = true
	openable._show(true)
	await _physics_ticks(2)
	part.collection = &"space"
	part.dress()
	await _physics_ticks(2)
	var slide := root.get_node("Drawer1/Looks/Slide") as Node3D
	_check(root.get_node("Drawer1/Looks").scene_file_path == Cabinet.looks_path(&"space", true), "the drawer wears the Space Looks")
	_check(is_equal_approx(slide.position.z, 0.4), "the new Looks shows the drawer open (z %.3f)" % slide.position.z)
	_check(is_zero_approx((root.get_node("Drawer2/Looks/Slide") as Node3D).position.z), "a shut drawer stays shut")


# --- K02 -----------------------------------------------------------------------------------------

func case_k02_station() -> void:
	await _build()
	var seen: Array[StringName] = []
	var pad := _station.get_node("Pad") as MeshInstance3D
	var box := pad.global_transform * pad.get_aabb()
	var rect := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	for part: Node in _station.find_children("Cabinet", "Node", true, false):
		var cabinet := part as Cabinet
		if cabinet == null:
			continue
		var root := cabinet.get_parent() as Node3D
		_check(not seen.has(cabinet.collection), "%s has one Cabinet" % cabinet.collection)
		seen.append(cabinet.collection)
		var looks := root.get_node("Looks") as Node3D
		_check(looks.scene_file_path == Cabinet.looks_path(cabinet.collection, false), "the %s Cabinet wears its Looks" % cabinet.collection)
		for corner: Vector3 in [Vector3(-SHELL_X, 0.0, SHELL_Z.x), Vector3(SHELL_X, 0.0, SHELL_Z.y)]:
			var at := root.to_global(corner)
			_check(rect.has_point(Vector2(at.x, at.z)), "the %s Cabinet stands on the station's pad (%s)" % [cabinet.collection, at])
			_check(_mess.in_bounds(at + Vector3.UP * 0.5), "the %s Cabinet is inside the Mess bounds" % cabinet.collection)
		_check(not String(cabinet.id).is_empty(), "the %s Cabinet is a Part of the level (%s)" % [cabinet.collection, cabinet.id])
	for c in collections():
		_check(seen.has(c), "the station shows the %s Cabinet" % c)
	_check(seen.size() == collections().size(), "and no other (%d of %d)" % [seen.size(), collections().size()])


func case_k02_from_data() -> void:
	var old := load(DESIGNS) as DesignCatalogue
	var catalogue := DesignCatalogue.new()
	catalogue.designs = old.designs.duplicate()
	var extra := SockDesign.new()
	extra.id = catalogue.designs.size()
	extra.collection = &"brand_new"
	catalogue.designs.append(extra)
	_level = Node3D.new()
	var gallery := CabinetGallery.new()
	gallery.name = "Gallery"
	gallery.catalogue = catalogue
	gallery.layout = load(LAYOUT) as CabinetGalleryLayout
	_level.add_child(gallery)
	add_child(_level)
	await _frames(1)
	for c in collections():
		_check(gallery.cabinet_of(c) != null, "the line-up has the %s Cabinet" % c)
	var fresh := gallery.cabinet_of(&"brand_new")
	_check(fresh != null, "the new Collection has a Cabinet in the line-up")
	if fresh != null:
		_check((fresh.get_node("Cabinet") as Cabinet).collection == &"brand_new", "it takes the new Collection's Pairs")
		_check((fresh.get_node("Looks") as Node3D).scene_file_path == "res://game/entities/cabinet/looks_simple.tscn",
				"with no Looks of its own it keeps the scene's")
		_check((fresh.get_node("Name") as Label3D).text == "Brand New", "its name stands above it")


# --- K03 -----------------------------------------------------------------------------------------

func case_k03() -> void:
	var simple := (load(Cabinet.looks_path(&"simple", true)) as PackedScene).instantiate() as Node3D
	var first := simple.find_child(Cabinet.SLOT % 1, true, false) as Node3D
	_check(first != null and first.position.is_equal_approx(OLD_SLOT_01), "the first slot point is the old slot_01")
	var root := (load(CABINET) as PackedScene).instantiate() as Node3D
	var shell := (root.get_node("Shape") as CollisionShape3D)
	var size := (shell.shape as BoxShape3D).size
	_check(is_equal_approx(size.x * 0.5, SHELL_X) and is_equal_approx(shell.position.z - size.z * 0.5, SHELL_Z.x)
			and is_equal_approx(shell.position.z + size.z * 0.5, SHELL_Z.y), "the shell is the old one (%s at %s)" % [size, shell.position])
	root.free()
	for c in collections():
		var looks := (load(Cabinet.looks_path(c, true)) as PackedScene).instantiate() as Node3D
		var front := looks.get_node("Slide/Front") as CollisionShape3D
		var box := front.shape as BoxShape3D
		_check(box != null and box.size.is_equal_approx(FRONT_SIZE) and front.position.is_equal_approx(FRONT_AT),
				"%s: the drawer front is the old one" % c)
		_check(looks.get_node("Slide") is AnimatableBody3D, "%s: the front slides with the drawer" % c)
		for k in 25:
			var name := Cabinet.SLOT % (k + 1)
			var slot := looks.find_child(name, true, false) as Node3D
			var want := simple.find_child(name, true, false) as Node3D
			_check(slot != null and want != null and slot.position.is_equal_approx(want.position), "%s: %s is the old spot" % [c, name])
		looks.free()
	simple.free()


# --- Helpers -------------------------------------------------------------------------------------

func _contract(path: String) -> PackedStringArray:
	return PackedStringArray(_contract_all(path).get("nodes", []))


func _contract_all(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


## The station alone on a floor, with the game's player and a Parts (a Host of one), as cabinet_test.gd.
func _build() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 0.2, 60.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = _station.position + BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_coins = _station.get_node("Socks/Coins") as Coins
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


func _stand(at: Vector3) -> void:
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(target: Vector3) -> void:
	var head := _player.get_node("Head") as Node3D
	var to := target - _player.global_position
	_player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _centre(sock: int) -> Vector3:
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
