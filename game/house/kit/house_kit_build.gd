## Makes the house kit's pieces (pieces/*.tscn) from house_kit_sizes.tres, and any missing
## material of the library (materials/*.tres) from the old house's colours (house/01). Run it
## after a change to the sizes, from the project folder:
##   "$(kit/tools/engine.sh --path)" --headless --path . --script res://game/house/kit/house_kit_build.gd
## A piece is a MeshInstance3D root (one mesh in meshes/, one surface: the one material slot a placed piece
## overrides, Q2328) with a StaticBody3D "Body" of simple boxes on the house's physics layer. A
## piece file keeps its uid across rebuilds; a material that exists is never rewritten, so the
## designer's edits to the library stay.
extends SceneTree

const SIZES := "res://game/house/kit/house_kit_sizes.tres"
const PIECES := "res://game/house/kit/pieces"
const MESHES := "res://game/house/kit/meshes"
const MATERIALS := "res://game/house/kit/materials"
const TEXTURES := "res://game/house/kit/textures"
## The house's physics layer, the Mess's LAYER_HOUSE (game/mess/mess.gd).
const LAYER_HOUSE := 1
## How deep a stair's walking ramp is under its top.
const RAMP_DEPTH := 0.3

## The library: the old house's wall, floor and tile materials (make_flat.py and make_house.py
## of the reference), sRGB colour, roughness, and a texture with the metres one repeat covers.
const LIBRARY := {
	"wall_outside": [Color(0.93, 0.90, 0.84), 0.9],
	"wall_kitchen": [Color(0.96, 0.89, 0.77), 0.9],
	"wall_hall": [Color(0.97, 0.86, 0.62), 0.9],
	"wall_bathroom": [Color(0.80, 0.91, 0.88), 0.9],
	"wall_bedroom": [Color(0.94, 0.79, 0.73), 0.9],
	"wall_office": [Color(0.90, 0.86, 0.94), 0.9],
	"wall_kids": [Color(0.98, 0.86, 0.80), 0.9],
	"wall_workshop": [Color(0.86, 0.84, 0.78), 0.9],
	"wall_boiler": [Color(0.84, 0.81, 0.78), 0.9],
	"wall_garage": [Color(0.88, 0.86, 0.80), 0.9],
	"wall_lobby": [Color(0.91, 0.88, 0.82), 0.9],
	"wall_loft": [Color(0.93, 0.85, 0.72), 0.9],
	"wall_tile": [Color(1, 1, 1), 0.3, "wall_tiles.png", 0.6],
	"ceiling": [Color(0.98, 0.95, 0.89), 0.9],
	"trim": [Color(0.98, 0.96, 0.91), 0.55],
	"wood": [Color(1, 1, 1), 0.6, "planks.png", 2.0],
	"kitchen_tile": [Color(1, 1, 1), 0.5, "kitchen_tiles.png", 1.2],
	"bath_tile": [Color(1, 1, 1), 0.4, "bath_tiles.png", 0.6],
	"basement_tile": [Color(0.72, 0.71, 0.68), 0.7],
	"loft_boards": [Color(0.80, 0.66, 0.48), 0.8],
}

var _sizes: HouseKitSizes


func _init() -> void:
	_sizes = load(SIZES)
	for name: String in LIBRARY:
		_material(name)
	var s := _sizes
	var h: float = s.storey
	for length: float in s.lengths:
		_wall("wall_exterior_%s" % _tag(length), [_box(0, length, 0, h, -s.exterior / 2, s.exterior / 2)], "wall_outside")
		_wall("wall_partition_%s" % _tag(length), [_box(0, length, 0, h, -s.partition / 2, s.partition / 2)], "wall_kitchen")
	for kind: String in ["exterior", "partition"]:
		var t: float = s.get(kind)
		var paint := "wall_outside" if kind == "exterior" else "wall_kitchen"
		_wall("corner_%s" % kind, _corner(t), paint)
		_wall("t_%s" % kind, _t(t, t), paint)
		_wall("door_%s" % kind, _door(t), paint)
	_wall("t_exterior_partition", _t(s.exterior, s.partition), "wall_outside")
	_wall("window_exterior", _window(s.exterior), "wall_outside")
	for side: float in s.tiles:
		_wall("floor_%s" % _tag(side), [_box(0, side, -s.floor_thickness, 0, 0, side)], "wood")
		var top: float = -s.floor_thickness
		_wall("ceiling_%s" % _tag(side), [_box(0, side, top - s.ceiling_thickness, top, 0, side)], "ceiling")
	_stair("stair_full", s.stair_steps)
	@warning_ignore("integer_division")
	_stair("stair_half", s.stair_steps / 2)
	var landing := _box(0, s.landing.x, 0, h / 2, 0, s.landing.y)
	_wall("landing", [landing], "wood")
	print("house_kit_build: done")
	quit()


## "05m", "1m", "2m": a length in a file name.
static func _tag(metres: float) -> String:
	if is_equal_approx(metres, roundf(metres)):
		return "%dm" % int(metres)
	return ("%sm" % str(metres)).replace("0.", "0").replace(".", "_")


static func _box(x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> AABB:
	return AABB(Vector3(x0, y0, z0), Vector3(x1 - x0, y1 - y0, z1 - z0))


## An L of two arms from the join, along +X and +Z, its outside corner closed: a building's
## outer corner seen from outside, the inner corner from inside.
func _corner(t: float) -> Array[AABB]:
	var a: float = _sizes.arm
	return [_box(-t / 2, a, 0, _sizes.storey, -t / 2, t / 2), _box(-t / 2, t / 2, 0, _sizes.storey, t / 2, a)]


## A T: the through wall along X both ways from the join, the stem along +Z.
func _t(through: float, stem: float) -> Array[AABB]:
	var a: float = _sizes.arm
	var h: float = _sizes.storey
	return [_box(-a, a, 0, h, -through / 2, through / 2), _box(-stem / 2, stem / 2, 0, h, through / 2, a)]


## A 1 m wall with the doorway in its middle.
func _door(t: float) -> Array[AABB]:
	var s := _sizes
	var a: float = (1.0 - s.door_width) / 2
	var b: float = 1.0 - a
	var h: float = s.storey
	return [_box(0, a, 0, h, -t / 2, t / 2), _box(b, 1.0, 0, h, -t / 2, t / 2), _box(a, b, s.door_height, h, -t / 2, t / 2)]


## A 2 m wall with the window in its middle.
func _window(t: float) -> Array[AABB]:
	var s := _sizes
	var a: float = (2.0 - s.window_width) / 2
	var b: float = 2.0 - a
	var h: float = s.storey
	return [_box(0, a, 0, h, -t / 2, t / 2), _box(b, 2.0, 0, h, -t / 2, t / 2),
			_box(a, b, 0, s.window_sill, -t / 2, t / 2), _box(a, b, s.window_head, h, -t / 2, t / 2)]


## A piece whose collision is the same boxes as its mesh.
func _wall(file: String, boxes: Array[AABB], paint: String) -> void:
	var shapes: Array[Transform3D] = []
	var sizes: Array[Vector3] = []
	for b in boxes:
		shapes.append(Transform3D(Basis.IDENTITY, b.get_center()))
		sizes.append(b.size)
	_save(file, _mesh(boxes, paint), shapes, sizes)


## A straight flight of `steps` steps rising towards +Z from the origin, footprint
## stair_width x steps * going. It collides through one ramp under the steps' middles and a flat
## box on the top step: the player walks it like the old house's ramps.
func _stair(file: String, steps: int) -> void:
	var s := _sizes
	var w: float = s.stair_width
	var g: float = s.stair_going
	var r: float = s.step_rise()
	var boxes: Array[AABB] = []
	for i in steps:
		boxes.append(_box(0, w, 0, (i + 1) * r, i * g, (i + 1) * g))
	var top := steps * r
	var run := steps * g
	var p0 := Vector3(w / 2, r / 2, 0.0)
	var p1 := Vector3(w / 2, top, run - g / 2)
	var angle := atan2(r, g)
	var basis := Basis.from_euler(Vector3(-angle, 0.0, 0.0))
	var down := basis * Vector3.DOWN * (RAMP_DEPTH / 2)
	var shapes: Array[Transform3D] = [Transform3D(basis, (p0 + p1) / 2 + down),
			Transform3D(Basis.IDENTITY, Vector3(w / 2, top - RAMP_DEPTH / 2, run - g / 4))]
	var sizes: Array[Vector3] = [Vector3(w, RAMP_DEPTH, p0.distance_to(p1)), Vector3(w, RAMP_DEPTH, g / 2)]
	_save(file, _mesh(boxes, "wood"), shapes, sizes)


## One surface of boxes with the library material `paint` as its own; UVs in metres.
func _mesh(boxes: Array[AABB], paint: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in boxes:
		_add_box(st, b)
	st.set_material(_material(paint))
	st.index()
	return st.commit()


static func _add_box(st: SurfaceTool, b: AABB) -> void:
	var p := b.position
	var e := b.end
	# Each face: its normal and four corners counter-clockwise seen from outside.
	var faces := [
		[Vector3.RIGHT, Vector3(e.x, p.y, e.z), Vector3(e.x, p.y, p.z), Vector3(e.x, e.y, p.z), Vector3(e.x, e.y, e.z)],
		[Vector3.LEFT, Vector3(p.x, p.y, p.z), Vector3(p.x, p.y, e.z), Vector3(p.x, e.y, e.z), Vector3(p.x, e.y, p.z)],
		[Vector3.UP, Vector3(p.x, e.y, e.z), Vector3(e.x, e.y, e.z), Vector3(e.x, e.y, p.z), Vector3(p.x, e.y, p.z)],
		[Vector3.DOWN, Vector3(p.x, p.y, p.z), Vector3(e.x, p.y, p.z), Vector3(e.x, p.y, e.z), Vector3(p.x, p.y, e.z)],
		[Vector3.BACK, Vector3(p.x, p.y, e.z), Vector3(e.x, p.y, e.z), Vector3(e.x, e.y, e.z), Vector3(p.x, e.y, e.z)],
		[Vector3.FORWARD, Vector3(e.x, p.y, p.z), Vector3(p.x, p.y, p.z), Vector3(p.x, e.y, p.z), Vector3(e.x, e.y, p.z)],
	]
	for f: Array in faces:
		var n: Vector3 = f[0]
		var corners: Array[Vector3] = [f[1], f[2], f[3], f[4]]
		# Godot's front faces wind clockwise: emit 0-2-1 and 0-3-2.
		for i: int in [0, 2, 1, 0, 3, 2]:
			var c := corners[i]
			st.set_normal(n)
			st.set_uv(_uv(c, n))
			st.add_vertex(c)


## Metres across the face: a tiled texture keeps its scale on every piece.
static func _uv(c: Vector3, n: Vector3) -> Vector2:
	if absf(n.x) > 0.5:
		return Vector2(c.z, -c.y)
	if absf(n.y) > 0.5:
		return Vector2(c.x, c.z)
	return Vector2(c.x, -c.y)


func _save(file: String, mesh: ArrayMesh, shapes: Array[Transform3D], sizes: Array[Vector3]) -> void:
	var mesh_path := MESHES.path_join(file + ".tres")
	var mesh_uid := ResourceLoader.get_resource_uid(mesh_path) if FileAccess.file_exists(mesh_path) else ResourceUID.INVALID_ID
	mesh.resource_name = file
	if ResourceSaver.save(mesh, mesh_path) != OK:
		push_error("house_kit_build: cannot save %s" % mesh_path)
		return
	_keep_uid(mesh_path, mesh_uid)
	var root := MeshInstance3D.new()
	root.name = file.to_pascal_case()
	root.mesh = load(mesh_path)
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = LAYER_HOUSE
	body.collision_mask = 0
	root.add_child(body)
	body.owner = root
	for i in shapes.size():
		var shape := CollisionShape3D.new()
		shape.name = "Box" if shapes.size() == 1 else "Box%d" % (i + 1)
		var box := BoxShape3D.new()
		box.size = sizes[i]
		shape.shape = box
		shape.transform = shapes[i]
		body.add_child(shape)
		shape.owner = root
	var path := PIECES.path_join(file + ".tscn")
	var uid := ResourceLoader.get_resource_uid(path) if FileAccess.file_exists(path) else ResourceUID.INVALID_ID
	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, path)
	if err != OK:
		push_error("house_kit_build: cannot save %s (%s)" % [path, error_string(err)])
	else:
		_keep_uid(path, uid)
	root.queue_free()   # never in the tree; gone at the frame end


## The editor's format (Q2268): the file carries a uid, the same one as before a rebuild.
static func _keep_uid(path: String, uid: int) -> void:
	if uid == ResourceUID.INVALID_ID:
		uid = ResourceUID.create_id()
	ResourceSaver.set_uid(path, uid)
	if ResourceUID.has_id(uid):
		ResourceUID.set_id(uid, path)
	else:
		ResourceUID.add_id(uid, path)
	# A script run writes its references by path only; the editor adds each one's uid.
	var text := FileAccess.get_file_as_string(path)
	var out := PackedStringArray()
	for line in text.split("\n"):
		if line.begins_with("[ext_resource ") and not line.contains(" uid=\""):
			var target := line.get_slice("path=\"", 1).get_slice("\"", 0)
			var id := ResourceLoader.get_resource_uid(target)
			if id != ResourceUID.INVALID_ID:
				line = line.replace(" path=\"", " uid=\"%s\" path=\"" % ResourceUID.id_to_text(id))
		out.append(line)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(out))


## The library's material `name`, made from LIBRARY only when its file does not exist yet.
func _material(name: String) -> Material:
	var path := MATERIALS.path_join(name + ".tres")
	if FileAccess.file_exists(path):
		return load(path)
	var spec: Array = LIBRARY[name]
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_color = spec[0]
	m.roughness = spec[1]
	if spec.size() > 2:
		m.albedo_texture = load(TEXTURES.path_join(spec[2]))
		# World triplanar: the texture runs on across neighbouring pieces, whatever their turn.
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE / float(spec[3])
	var err := ResourceSaver.save(m, path)
	if err != OK:
		push_error("house_kit_build: cannot save %s (%s)" % [path, error_string(err)])
	else:
		_keep_uid(path, ResourceUID.INVALID_ID)
	return load(path)
