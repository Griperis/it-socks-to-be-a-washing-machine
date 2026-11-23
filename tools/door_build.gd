## Makes the room Door's leaf and the house's other door leaves (house/08, Q2571) from the old geometry of
## reference/it-socks/tools/blender/make_house.py (make_room_doors, the front door in make_door_frames,
## make_garage_door) and make_flat.py's materials: the leaf's size, its raised panels, its brass handle.
## Run it from the project folder after an import:
##   "$(kit/tools/engine.sh --path)" --headless --path . res://tools/door_build.tscn
## (a scene, not --script: the Openable and the Outline need the game's autoloads).
## It writes (and overwrites) game/entities/door/: materials/*.tres, looks_leaf.tscn and
## looks_leaf_flipped.tscn (the two hands: the hinge at the leaf's -x or +x end, both swinging to +z),
## room_door.tscn and room_door_flipped.tscn (the entity: an Openable Part and the Looks; door.tscn stays the graybox Door of the zoo's other stations), and
## game/house/shut_front_door.tscn and shut_garage_door.tscn (the leaves that stay shut, Q2514, in the
## same materials). The entities' root origin is the shut leaf's middle on the floor, +z the room it opens into.
extends Node

const FOLDER := "res://game/entities/door"
const MATERIALS := "res://game/entities/door/materials"
const HOUSE := "res://game/house"
const OPENABLE := preload("res://game/parts/openable.gd")
const OUTLINE := preload("res://game/outline/outline.gd")
## The Mess's LAYER_HOUSE (game/mess/mess.gd).
const LAYER_HOUSE := 1

## The old room door leaf (make_house.py LEAF_T, LEAF_GAP, DOOR_H): the doorway is 0.9 m wide and 2.1 m
## high, the leaf 0.017 m short of each jamb, 0.008 m off the floor and 0.017 m under the head.
const WIDTH := 0.866
const FLOOR_GAP := 0.008
const TOP := 2.083
const THICK := 0.04
## The old swing (data/tuning/doors.json swing_time) and its in-out ease (Q2368, Q2403).
const SWING_TIME := 0.6
const EASE_IN_OUT := -2.0

var _mats: Dictionary[String, StandardMaterial3D] = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(MATERIALS)
	# make_flat.py MATERIALS: (colour, roughness, metallic).
	_material("door", Color(0.96, 0.93, 0.87), 0.5, 0.0)
	_material("front_door", Color(0.36, 0.52, 0.55), 0.5, 0.0)
	_material("brass", Color(0.88, 0.68, 0.32), 0.32, 1.0)
	_material("steel", Color(0.78, 0.80, 0.82), 0.3, 1.0)
	_looks(false)
	_looks(true)
	_entity(false)
	_entity(true)
	_shut_front()
	_shut_garage()
	get_tree().quit()


func _material(key: String, colour: Color, roughness: float, metallic: float) -> void:
	var path := "%s/%s.tres" % [MATERIALS, key]
	var m := StandardMaterial3D.new()
	m.resource_name = key
	m.albedo_color = colour
	m.roughness = roughness
	m.metallic = metallic
	ResourceSaver.save(m, path)
	_mats[key] = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as StandardMaterial3D


## The leaf's Looks: `flipped` puts the hinge at the +x end (the other hand). Its room is +z.
func _looks(flipped: bool) -> void:
	# e: the direction from the hinge along the leaf.
	var e := -1.0 if flipped else 1.0
	var root := Node3D.new()
	root.name = "LooksLeafFlipped" if flipped else "LooksLeaf"
	var hinge := AnimatableBody3D.new()
	hinge.name = "Hinge"
	hinge.collision_layer = LAYER_HOUSE
	hinge.collision_mask = 0
	hinge.position = Vector3(-e * WIDTH / 2.0, 0.0, 0.0)
	_own(root, hinge)
	var height := TOP - FLOOR_GAP
	var mid := Vector3(e * WIDTH / 2.0, (FLOOR_GAP + TOP) / 2.0, 0.0)
	_own(hinge, _box("Leaf", Vector3(WIDTH, height, THICK), mid, "door"))
	var shape := CollisionShape3D.new()
	shape.name = "LeafShape"
	var box := BoxShape3D.new()
	box.size = Vector3(WIDTH, height, THICK)
	shape.shape = box
	shape.position = mid
	_own(hinge, shape)
	for face: float in [1.0, -1.0]:
		var n := 0
		# Two raised panels a face (make_house.py: 0.2-0.95 and 1.1-1.92 over the floor, 0.11 in from each edge).
		for band: Array in [[0.2, 0.95], [1.1, 1.92]]:
			n += 1
			var pa: float = band[0]
			var pb: float = band[1]
			_own(hinge, _box("Panel%s%d" % ["Front" if face > 0.0 else "Back", n],
					Vector3(WIDTH - 0.22, pb - pa, 0.006),
					Vector3(e * WIDTH / 2.0, (pa + pb) / 2.0, face * (THICK / 2.0 + 0.003)), "door"))
		# The handle: a rose, a spindle and a lever pointing at the hinge, brass.
		var hx := e * (WIDTH - 0.075)
		var z0 := face * THICK / 2.0
		_own(hinge, _cylinder("Rose%s" % ("Front" if face > 0.0 else "Back"), 0.03, 0.012,
				Vector3(hx, 1.0, z0 + face * 0.006)))
		_own(hinge, _cylinder("Spindle%s" % ("Front" if face > 0.0 else "Back"), 0.009, 0.05,
				Vector3(hx, 1.0, z0 + face * 0.025)))
		_own(hinge, _box("Lever%s" % ("Front" if face > 0.0 else "Back"), Vector3(0.13, 0.018, 0.018),
				Vector3(hx - e * 0.065, 1.0, z0 + face * 0.049), "brass"))
	var outline := Node3D.new()
	outline.name = "Outline"
	outline.set_script(OUTLINE)
	outline.visible = false
	_own(root, outline)
	var reset := Animation.new()
	reset.length = 0.001
	var open := Animation.new()
	open.length = SWING_TIME
	var turn := Vector3(0.0, -e * PI / 2.0, 0.0)
	_track(reset, "Hinge:rotation", [0.0], [Vector3.ZERO], [1.0])
	_track(open, "Hinge:rotation", [0.0, SWING_TIME], [Vector3.ZERO, turn], [EASE_IN_OUT, 1.0])
	var lib := AnimationLibrary.new()
	lib.add_animation(&"RESET", reset)
	lib.add_animation(&"open", open)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	player.add_animation_library(&"", lib)
	_own(root, player)
	_save(root, "%s/%s.tscn" % [FOLDER, "looks_leaf_flipped" if flipped else "looks_leaf"])


## The entity: an Openable Part beside its Looks (the plain leaf, or its other hand).
func _entity(flipped: bool) -> void:
	var root := Node3D.new()
	root.name = "RoomDoorFlipped" if flipped else "RoomDoor"
	var openable := Node.new()
	openable.name = "Openable"
	openable.set_script(OPENABLE)
	openable.set("open_sound", &"door_open")
	openable.set("close_sound", &"door_close")
	openable.set("noun", "Door")
	_own(root, openable)
	var looks := (ResourceLoader.load("%s/%s.tscn" % [FOLDER, "looks_leaf_flipped" if flipped else "looks_leaf"], "",
			ResourceLoader.CACHE_MODE_REPLACE) as PackedScene).instantiate()
	looks.name = "Looks"
	root.add_child(looks)
	looks.owner = root
	_save(root, "%s/%s.tscn" % [FOLDER, "room_door_flipped" if flipped else "room_door"])


## The front door's leaf (make_house.py, the front door): a teal leaf with two raised panels and a brass
## knob on the room's side, in the wall's middle; it stays shut (Q2514).
func _shut_front() -> void:
	var root := StaticBody3D.new()
	root.name = "ShutFrontDoor"
	root.collision_mask = 0
	root.set_meta("note", "house/04, Q2514: the front door stays shut until the exterior ticket. No Part: no prompt, no outline, a click meets nothing. Origin at the doorway's foot, in the wall's middle; its leaf is the old front door's (house/08, tools/door_build.gd). placeholder: the exterior ticket brings the door entity")
	var height := 2.085 - 0.01
	var mid := Vector3(0.0, (0.01 + 2.085) / 2.0, 0.0)
	_own(root, _box("Mesh", Vector3(WIDTH, height, 0.05), mid, "front_door"))
	var n := 0
	for band: Array in [[0.18, 0.95], [1.1, 1.9]]:
		n += 1
		var pa: float = band[0]
		var pb: float = band[1]
		_own(root, _box("Panel%d" % n, Vector3(0.64, pb - pa, 0.012), Vector3(0.0, (pa + pb) / 2.0, 0.025 + 0.006), "front_door"))
	var knob := MeshInstance3D.new()
	knob.name = "Knob"
	var ball := SphereMesh.new()
	ball.radius = 0.03
	ball.height = 0.06
	ball.radial_segments = 12
	ball.rings = 8
	ball.material = _mats["brass"]
	knob.mesh = ball
	knob.position = Vector3(-0.33, 1.0, 0.025 + 0.03)
	_own(root, knob)
	_own(root, _shape("Shape", Vector3(WIDTH, height, 0.05), mid))
	_save(root, "%s/shut_front_door.tscn" % HOUSE)


## The garage door's leaf (make_house.py make_garage_door): a ribbed teal leaf with a steel handle on both
## faces and the stiffening frame inside, in the wall's middle; it never opens.
func _shut_garage() -> void:
	var root := StaticBody3D.new()
	root.name = "ShutGarageDoor"
	root.collision_mask = 0
	root.set_meta("note", "house/04, Q2514: the garage door stays shut until the exterior ticket. No Part: no prompt, no outline, a click meets nothing. Origin at the doorway's foot, in the wall's middle; its leaf is the old up-and-over door's, without its track and spring gear (house/08, tools/door_build.gd). placeholder: the exterior ticket brings the door entity")
	var wide := 2.37
	var height := 2.085
	var mid := Vector3(0.0, 1.0425, 0.0)
	_own(root, _box("Mesh", Vector3(wide, height, 0.05), mid, "front_door"))
	# The ribs on the street side (-z): nine shallow panels, a plain band at the handle.
	var count := 9
	var rib := (2.1 - 0.12) / count
	var k := 0
	for i in count:
		var ya := 0.06 + i * rib + 0.02
		if absf(ya + rib / 2.0 - 1.0) < rib / 2.0:
			continue
		k += 1
		_own(root, _box("Rib%d" % k, Vector3(wide - 0.16, rib - 0.04, 0.012),
				Vector3(0.0, ya + (rib - 0.04) / 2.0, -0.025 - 0.006), "front_door"))
	# The handle on both faces: a plate and two posts.
	for face: float in [-1.0, 1.0]:
		var side := "Street" if face < 0.0 else "Room"
		var z0 := face * 0.025
		var outer := 0.012 if face < 0.0 else 0.0
		_own(root, _box("Handle%s" % side, Vector3(0.26, 0.06, 0.015), Vector3(0.0, 1.0, z0 + face * (outer + 0.0375)), "steel"))
		for sx: float in [-0.11, 0.11]:
			_own(root, _box("Post%s%s" % [side, "L" if sx < 0.0 else "R"], Vector3(0.03, 0.03, 0.035),
					Vector3(sx, 1.0, z0 + face * (outer + 0.0175)), "steel"))
	# Inside (+z): the leaf's stiffening frame.
	var bar := 0
	for band: Array in [[0.05, 0.11], [1.98, 2.04], [0.72, 0.78]]:
		bar += 1
		var ya: float = band[0]
		var yb: float = band[1]
		_own(root, _box("Bar%d" % bar, Vector3(wide - 0.12, yb - ya, 0.02), Vector3(0.0, (ya + yb) / 2.0, 0.025 + 0.01), "steel"))
	for sx: float in [-(wide / 2.0 - 0.09), wide / 2.0 - 0.09]:
		bar += 1
		_own(root, _box("Bar%d" % bar, Vector3(0.06, 2.1 - 0.11, 0.02), Vector3(sx, (0.05 + 2.04) / 2.0, 0.025 + 0.01), "steel"))
	_own(root, _shape("Shape", Vector3(wide, height, 0.05), mid))
	_save(root, "%s/shut_garage_door.tscn" % HOUSE)


func _box(node_name: String, size: Vector3, at: Vector3, material: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mats[material]
	mi.mesh = mesh
	mi.position = at
	return mi


## A cylinder along z (the leaf's thickness), brass.
func _cylinder(node_name: String, radius: float, length: float, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 16
	mesh.rings = 1
	mesh.material = _mats["brass"]
	mi.mesh = mesh
	mi.position = at
	mi.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	return mi


func _shape(node_name: String, size: Vector3, at: Vector3) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.name = node_name
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = at
	return cs


func _track(anim: Animation, path: NodePath, times: Array, values: Array, easing: Array) -> void:
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, path)
	anim.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
	for i in times.size():
		anim.track_insert_key(t, times[i], values[i], easing[i])


func _own(parent: Node, node: Node) -> void:
	parent.add_child(node)
	var top := parent if parent.owner == null else parent.owner
	node.owner = top
	for child in node.get_children():
		_own_tree(child, top)


func _own_tree(node: Node, top: Node) -> void:
	node.owner = top
	if node.scene_file_path.is_empty():
		for child in node.get_children():
			_own_tree(child, top)


func _save(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("door_build: could not save %s (%d)" % [path, err])
	root.free()
