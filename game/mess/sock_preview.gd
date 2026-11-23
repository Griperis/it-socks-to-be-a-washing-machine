## What the Sock generator draws in the editor (core/52, Q2522): the areas' translucent boxes, the
## exclusions' red ones, a trail's line, and a dot at every landing point the current seed makes, tinted
## by its kind. Editor-only looks (internal children, never saved); a game build draws none of it unless
## a shot asks (the zoo's preview still).
@tool
class_name SockPreview
extends RefCounted

const AREA_COLOUR := Color(0.3, 0.55, 1.0, 0.12)
const EXCLUSION_COLOUR := Color(1.0, 0.25, 0.2, 0.25)
## A dot's tint by kind: open floor, top, inside, under, trail.
const KIND_COLOURS: Array[Color] = [
	Color(0.35, 0.8, 1.0), Color(1.0, 0.85, 0.2), Color(0.35, 1.0, 0.45), Color(1.0, 0.35, 0.9), Color(1.0, 0.55, 0.15),
]
## A dot's radius.
const DOT := 0.04


## A translucent, unshaded box of `size` in `colour`.
static func box_mesh(size: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(colour)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## A line (an ImmediateMesh) in `colour`, drawn by set_line().
static func line_mesh(colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = ImmediateMesh.new()
	node.material_override = _material(colour)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


static func set_line(node: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var mesh := node.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()


## The dots: one instance per landing point, at the middle of its Sock's place, tinted by its kind.
## `places` are SockLaying rows ({"pose": Transform3D, "kind": SockArea.Kind}).
static func dots(places: Array[Dictionary], in_space: Transform3D) -> MultiMeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = DOT
	sphere.height = DOT * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var mat := _material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	sphere.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sphere
	mm.instance_count = places.size()
	var to_local := in_space.affine_inverse()
	for i in places.size():
		var pose: Transform3D = places[i]["pose"]
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, to_local * (pose * Vector3(0.0, DOT, 0.0))))
		mm.set_instance_color(i, KIND_COLOURS[int(places[i]["kind"])])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


static func _material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = colour
	if colour.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return mat
