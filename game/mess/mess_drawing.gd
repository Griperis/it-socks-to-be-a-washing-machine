## How the Mess's Socks are drawn when no Looks scene is needed (core/13, M02, M03; assets/01): the
## lying ones as instances of one MultiMesh per floor cell (MessTuning.cell_size) and shape, each
## scaled by its Size, with the Looks' own mesh (the model's LODs folded in, ModelLods) and a
## visibility range; the flying ones without a Looks in one MultiMesh per shape, refilled each frame.
## A shape is a Collection's (its Sock model, or with a Pair its sock ball, and its cloth): one
## material per shape, SockLook.instance_material(), as the old game had one per Collection. Each
## instance carries its Design as the old game packed it (sock_drawing.gd, sock_look.gd): the colour
## as the instance colour and the look data (look_data()) as INSTANCE_CUSTOM, read by the sock shader.
## The mesh, its place in the Looks and the material are the Looks scene's and SockLook's, so a Sock
## lent its Looks (the aimed one) shows no pop. It decides nothing: the Mess
## says what is drawn where. Looks of this machine only.
class_name MessDrawing
extends RefCounted

## A Pair's shape is its Collection's with this in front.
const BALL_PREFIX := "ball:"
## The Looks whose lying mesh the Socks' boxes fit (MessBodies; every shape today).
const BOX_LOOKS := preload("res://game/sock/looks_crew.tscn")
## Floats per instance in a MultiMesh's buffer: a 3D transform (12), a colour (4), custom data (4).
const STRIDE := 20
## The old Design's lists the look data numbers (core/design.gd): a pattern, a print's layout, the
## trim patches; and the pattern's step per patches index (sock_look.gd).
const PATTERNS: Array[StringName] = [&"solid", &"stripes", &"bands", &"checks", &"dots", &"print"]
const LAYOUTS: Array[StringName] = [&"big", &"two", &"band", &"cuff"]
const PATCHES: Array[StringName] = [&"all", &"top_toe", &"heel_toe", &"none"]
const PATCHES_STEP := 16
## A cell's MultiMesh starts with room for this many instances and doubles when full.
const FIRST_ROOM := 32

## Where the MultiMeshInstance3Ds go (the Mess's `lying` node).
var _root: Node3D
var _tuning: MessTuning
## The shapes in the order first drawn (a cell key's third number), and per shape the mesh and where
## it sits in its Looks (Looks space at Size medium).
var _shapes: Array[StringName] = []
var _mesh: Dictionary[StringName, Mesh] = {}
var _mesh_at: Dictionary[StringName, Transform3D] = {}
## Each shape's material (the sock shader reading the instance data).
var _material: Dictionary[StringName, ShaderMaterial] = {}
## The cells' MultiMeshInstance3Ds, by (cell x, cell z, shape index), and the Sock in each instance.
var _cells: Dictionary[Vector3i, MultiMeshInstance3D] = {}
var _in_cell: Dictionary[Vector3i, PackedInt32Array] = {}
## This machine's copy of each cell's instance buffer (STRIDE floats an instance, room to grow), and
## the cells changed since the last flush(). The renderer's copy is never read back.
var _buf: Dictionary[Vector3i, PackedFloat32Array] = {}
var _dirty: Dictionary[Vector3i, bool] = {}
## Each drawn lying Sock's cell and instance.
var _cell_of: Dictionary[int, Vector3i] = {}
var _slot_of: Dictionary[int, int] = {}
## The flying Socks' MultiMeshInstance3Ds, by shape.
var _flying: Dictionary[StringName, MultiMeshInstance3D] = {}
## Each Design's look data, once worked out.
var _look: Dictionary[SockDesign, Color] = {}
## This machine's copy of each flying MultiMesh's buffer, written again each frame something flies.
var _flying_buf: Dictionary[StringName, PackedFloat32Array] = {}


func _init(root: Node3D, tuning: MessTuning) -> void:
	_root = root
	_tuning = tuning


## The shape a Sock of `design` is drawn as (`pair`: its ball): its Collection's.
static func shape_of(design: SockDesign, pair: bool) -> StringName:
	var collection := String(design.collection) if design != null else ""
	return StringName(BALL_PREFIX + collection if pair else collection)


## A Design's look as the old sock shader reads it (sock_look.gd look_data(), packing documented in the
## old sock_pattern.gdshaderinc): r the pattern plus PATCHES_STEP per patches index, g the motif + 1
## plus (coat + 1) * 256 plus the layout * 65536, b the second colour (no Design has one yet), a the
## third (pack_rgb()).
static func look_data(design: SockDesign) -> Color:
	if design == null:
		return Color(0, 0, 0, 0)
	var code := 0
	if design.motif >= 0:
		code += design.motif + 1
	if design.coat >= 0:
		code += (design.coat + 1) * 256
	code += maxi(LAYOUTS.find(design.layout), 0) * 65536
	var pattern := maxi(PATTERNS.find(design.pattern), 0) + PATCHES_STEP * maxi(PATCHES.find(design.patches), 0)
	return Color(float(pattern), float(code), 0.0, pack_rgb(design.colour3))


## A colour as one whole number (sRGB bytes, plus one so that 0 means "unset").
static func pack_rgb(c: Color) -> float:
	if c.a <= 0.0:
		return 0.0
	return float(c.r8 * 65536 + c.g8 * 256 + c.b8 + 1)


## Shape `shape` (of a Sock of `design`) is drawn from now on: its mesh, place and material.
func _add_shape(shape: StringName, design: SockDesign) -> void:
	if _mesh.has(shape):
		return
	var pair := String(shape).begins_with(BALL_PREFIX)
	var found := body_mesh(SockLook.scene(design, pair))
	_shapes.append(shape)
	_mesh[shape] = found[0]
	_mesh_at[shape] = found[1]
	_material[shape] = SockLook.instance_material(design.collection if design != null else &"", pair)
	var flying := _new_instance(found[0], shape)
	flying.name = "Flying_%s" % String(shape).replace(":", "_")
	_flying[shape] = flying


## The lying Sock mesh's points in its Looks' space at Size medium (what the Sock's boxes fit).
func sock_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	var found := body_mesh(BOX_LOOKS)
	var mesh: Mesh = found[0]
	if mesh == null:
		return out
	var at: Transform3D = found[1]
	for s in mesh.get_surface_count():
		for p: Vector3 in mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			out.append(at * p)
	return out


## Draws lying Sock `sock` of `design` at `pose` as `shape`, scaled by its Size (in this machine's
## copy of its cell's buffer; flush() hands the changed cells to the renderer).
func draw(sock: int, pose: Transform3D, shape: StringName, design: SockDesign) -> void:
	undraw(sock)
	_add_shape(shape, design)
	var c := _cell(pose.origin, shape)
	if not _cells.has(c):
		var node := _new_instance(_mesh[shape], shape)
		node.name = "Cell_%d_%d_%s" % [c.x, c.y, String(shape).replace(":", "_")]
		node.visibility_range_end = _tuning.draw_range
		_cells[c] = node
		_in_cell[c] = PackedInt32Array()
		_buf[c] = PackedFloat32Array()
	var socks := _in_cell[c]
	var slot := socks.size()
	socks.append(sock)
	_in_cell[c] = socks
	# Taken out of the Dictionary while written, so the array is written in place, not copied.
	var buf := _buf[c]
	_buf.erase(c)
	if (slot + 1) * STRIDE > buf.size():
		buf.resize(maxi(FIRST_ROOM, buf.size() / STRIDE * 2) * STRIDE)
	_write_row(buf, slot * STRIDE, _placed(pose, shape, SockDress.scale_of(design)), design)
	_buf[c] = buf
	_dirty[c] = true
	_cell_of[sock] = c
	_slot_of[sock] = slot


## Lying Sock `sock` is no longer drawn here: the last instance of its cell takes its place.
func undraw(sock: int) -> void:
	if not _cell_of.has(sock):
		return
	var c := _cell_of[sock]
	var slot := _slot_of[sock]
	var socks := _in_cell[c]
	var last := socks.size() - 1
	if slot != last:
		var moved := socks[last]
		var buf := _buf[c]
		_buf.erase(c)
		for i in STRIDE:
			buf[slot * STRIDE + i] = buf[last * STRIDE + i]
		_buf[c] = buf
		socks[slot] = moved
		_slot_of[moved] = slot
	socks.resize(last)
	_in_cell[c] = socks
	_dirty[c] = true
	_cell_of.erase(sock)
	_slot_of.erase(sock)


## The changed cells go to the renderer (once a frame, and after a change the Mess shows at once).
func flush() -> void:
	for c: Vector3i in _dirty:
		var mm := _cells[c].multimesh
		var buf := _buf[c]
		if mm.instance_count * STRIDE != buf.size():
			mm.instance_count = buf.size() / STRIDE
		mm.buffer = buf
		mm.visible_instance_count = _in_cell[c].size()
	_dirty.clear()


## What lying Sock `sock`'s instance holds, in its cell's space: [transform, colour, look data], or [].
func instance_of(sock: int) -> Array:
	if not _cell_of.has(sock):
		return []
	var buf := _buf[_cell_of[sock]]
	var o := _slot_of[sock] * STRIDE
	var t := Transform3D(Basis(Vector3(buf[o], buf[o + 4], buf[o + 8]), Vector3(buf[o + 1], buf[o + 5], buf[o + 9]),
			Vector3(buf[o + 2], buf[o + 6], buf[o + 10])), Vector3(buf[o + 3], buf[o + 7], buf[o + 11]))
	return [t, Color(buf[o + 12], buf[o + 13], buf[o + 14], buf[o + 15]), Color(buf[o + 16], buf[o + 17], buf[o + 18], buf[o + 19])]


## Whether lying Sock `sock` is drawn as an instance now.
func is_drawn(sock: int) -> bool:
	return _cell_of.has(sock)


## How many lying Socks are drawn as instances, and in how many MultiMeshes.
func drawn_count() -> int:
	return _cell_of.size()


func cell_count() -> int:
	return _cells.size()


## Every flying Sock without a Looks, drawn this frame: by shape, the `poses` and the `designs` of
## its Socks (two lists as long as each other). A shape with no Sock now and none the frame before
## is left alone, and each shape's buffer is kept and written again, so a level where nothing flies
## uploads nothing (core/31).
func draw_flying(poses: Dictionary[StringName, Array], designs: Dictionary[StringName, Array]) -> void:
	for shape: StringName in poses:
		if not _flying.has(shape) and not poses[shape].is_empty():
			_add_shape(shape, designs[shape][0])
	for shape: StringName in _flying:
		var list: Array = poses.get(shape, [])
		var mm := _flying[shape].multimesh
		if list.is_empty():
			if mm.visible_instance_count != 0:
				mm.visible_instance_count = 0
			continue
		var of: Array = designs[shape]
		if list.size() > mm.instance_count:
			mm.instance_count = maxi(FIRST_ROOM, nearest_po2(list.size()))
		# Taken out of the Dictionary while written, so the array is written in place, not copied.
		var buf: PackedFloat32Array = _flying_buf.get(shape, PackedFloat32Array())
		_flying_buf.erase(shape)
		if buf.size() != mm.instance_count * STRIDE:
			buf.resize(mm.instance_count * STRIDE)
		var size := SockDress.scale_of(of[0])
		var o := 0
		for i in list.size():
			var design: SockDesign = of[i]
			if i > 0:
				size = SockDress.scale_of(design)
			_write_row(buf, o, _placed(list[i], shape, size), design)
			o += STRIDE
		_flying_buf[shape] = buf
		mm.buffer = buf
		mm.visible_instance_count = list.size()


## Every MultiMesh freed (the Mess leaves the tree).
func clear() -> void:
	for node: MultiMeshInstance3D in _cells.values():
		node.queue_free()
	for node: MultiMeshInstance3D in _flying.values():
		node.queue_free()
	_cells.clear()
	_in_cell.clear()
	_buf.clear()
	_dirty.clear()
	_cell_of.clear()
	_slot_of.clear()
	_flying.clear()
	_flying_buf.clear()
	_look.clear()
	_shapes.clear()
	_mesh.clear()
	_mesh_at.clear()
	_material.clear()


## Where an instance of `shape` goes for a Sock at `pose`, `scale` times its size: as its Looks is placed.
func _placed(pose: Transform3D, shape: StringName, scale: float) -> Transform3D:
	return pose * Transform3D(Basis.from_scale(Vector3.ONE * scale)) * _mesh_at[shape]


func _cell(at: Vector3, shape: StringName) -> Vector3i:
	var local := _root.global_transform.affine_inverse() * at if _root.is_inside_tree() else at
	var size := maxf(_tuning.cell_size, 0.5)
	return Vector3i(floori(local.x / size), floori(local.z / size), _shapes.find(shape))


func _new_instance(mesh: Mesh, shape: StringName) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = _material[shape]
	# Never physics-interpolated (core/31, Q2407): the engine would draw each instance between the
	# buffer of the tick before and this one, so a Sock just come to rest was not drawn for a tick
	# (its row was all zeros before) and every row that changed its Sock (a rest, a wake, the
	# flying rows closing up) was drawn for a tick smeared between two Socks' places. A lying Sock
	# does not move, and the flying rows are written every frame from poses already interpolated.
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_root.add_child(node)
	return node


## One instance's floats at `o` in `buf`: the transform (rows of its basis, then the origin), the
## Design's colour and its look data (worked out once per Design: the flying rows are written every frame).
func _write_row(buf: PackedFloat32Array, o: int, t: Transform3D, design: SockDesign) -> void:
	var colour := design.colour if design != null else Color.WHITE
	var look: Color
	if _look.has(design):
		look = _look[design]
	else:
		look = look_data(design)
		_look[design] = look
	var b := t.basis
	buf[o] = b.x.x
	buf[o + 1] = b.y.x
	buf[o + 2] = b.z.x
	buf[o + 3] = t.origin.x
	buf[o + 4] = b.x.y
	buf[o + 5] = b.y.y
	buf[o + 6] = b.z.y
	buf[o + 7] = t.origin.y
	buf[o + 8] = b.x.z
	buf[o + 9] = b.y.z
	buf[o + 10] = b.z.z
	buf[o + 11] = t.origin.z
	buf[o + 12] = colour.r
	buf[o + 13] = colour.g
	buf[o + 14] = colour.b
	buf[o + 15] = colour.a
	buf[o + 16] = look.r
	buf[o + 17] = look.g
	buf[o + 18] = look.b
	buf[o + 19] = look.a


## The drawn mesh of a Looks scene's Body (its first visible MeshInstance3D) and where it sits in the
## Looks: [Mesh, Transform3D].
static func body_mesh(scene: PackedScene) -> Array:
	var looks := scene.instantiate() as Node3D
	var body := looks.get_node_or_null(^"Body")
	var found: MeshInstance3D = null
	if body != null:
		ModelLods.fold(body)
		for node in body.find_children("*", "MeshInstance3D", true, false):
			if (node as MeshInstance3D).visible:
				found = node
				break
	var mesh: Mesh = null
	var at := Transform3D.IDENTITY
	if found != null:
		mesh = found.mesh
		var node: Node = found
		while node != looks and node is Node3D:
			at = (node as Node3D).transform * at
			node = node.get_parent()
	looks.queue_free()
	return [mesh, at]
