## The outline (core/11): a soft edge drawn outside a thing's shape, the same width on screen near and
## far. Drop it as a child of any entity's Looks; whoever decides (the player's aim) sets `shown`.
## The outline only draws: it never says right or wrong, except the "full" tint someone sets as `tint`.
##
## How it draws: each outlined mesh gets a child copy whose material first marks the mesh's silhouette
## in the stencil buffer, then draws the style's shells, grown along averaged normals and fainter
## outwards, only outside that silhouette (OutlineStyle, outline.gdshader). The copies keep the
## source's skin and blend shapes, so a bending mesh keeps its outline on its moving shape. They are
## made the first time it is shown, so a thing never outlined costs nothing.
class_name Outline
extends Node3D

## A node in this group, and everything under it, is never outlined (a drawer's shelved balls).
const SKIP := &"no_outline"
## The copies it makes are in this group (never outlined themselves).
const COPY := &"outline_copy"
## The copies' node name.
const COPY_NAME := &"OutlineCopy"
## The style when none is set: the crosshair's warm white.
const AIM := preload("res://game/outline/aim.tres")
## Vertices closer than this (in the mesh's units) share one averaged normal.
const WELD := 0.0005

## How it draws (aim.tres when empty).
@export var style: OutlineStyle
## The meshes it outlines (MeshInstance3D paths from this node); empty: every visible mesh under its
## parent, minus anything in the group SKIP.
@export var meshes: Array[NodePath] = []
## Whether it shows now. The node's own `visible` follows it.
@export var shown := false:
	set(value):
		shown = value
		visible = value
		if is_node_ready():
			_apply()

## A style shown in place of `style` while set (the red "full" tint on a drawer with no room).
var tint: OutlineStyle = null:
	set(value):
		if tint == value:
			return
		tint = value
		if is_node_ready():
			_set_material()

var _sources: Array[MeshInstance3D] = []
var _copies: Array[MeshInstance3D] = []

## Mesh -> its copy with normals averaged across shared corners, so a box's shells have no gaps.
static var _smoothed: Dictionary[Mesh, Mesh] = {}


## The Outline of the thing `node` is part of (a collider the crosshair hit): one beside `node` or an
## ancestor of it, or under a "Looks" beside it, up to its entity's root; null when it has none.
static func of(node: Node) -> Outline:
	while node != null:
		var found := _child_outline(node)
		if found == null and node.has_node(^"Looks"):
			found = _child_outline(node.get_node(^"Looks"))
		if found != null:
			return found
		if node.has_meta(Parts.ENTITY_META):
			return null
		node = node.get_parent()
	return null


static func _child_outline(node: Node) -> Outline:
	for child in node.get_children():
		if child is Outline:
			return child as Outline
	return null


func _ready() -> void:
	visible = shown
	_apply()


func _exit_tree() -> void:
	set_process(false)


## The style it draws in now: the tint while one is set, else its style.
func current_style() -> OutlineStyle:
	if tint != null:
		return tint
	return style if style != null else AIM


## The meshes it outlines now (visible ones, or the ones it names).
func sources() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if not meshes.is_empty():
		for path in meshes:
			var m := get_node_or_null(path) as MeshInstance3D
			if m != null and m.mesh != null:
				out.append(m)
		return out
	var root := get_parent()
	if root == null:
		return out
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.is_in_group(SKIP) or n.is_in_group(COPY) or n == self:
			continue
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null and mi.is_visible_in_tree():
			out.append(mi)
		stack.append_array(n.get_children())
	return out


## How many meshes it draws an outline on now (0 while hidden).
func outlined_count() -> int:
	if not shown:
		return 0
	var n := 0
	for c in _copies:
		if is_instance_valid(c) and c.visible:
			n += 1
	return n


## The copies it made (tests read their mesh, skin and material).
func copies() -> Array[MeshInstance3D]:
	return _copies.filter(func(c: MeshInstance3D) -> bool: return is_instance_valid(c))


func _process(_delta: float) -> void:
	_sync_blends()


## Shows or hides the copies, making them on the first show (and again when the meshes changed).
func _apply() -> void:
	if shown:
		var now := sources()
		if now != _sources or not _copies_alive():
			_make_copies(now)
		_set_material()
		_sync_blends()
	for c in _copies:
		if is_instance_valid(c):
			c.visible = shown
	set_process(shown and _has_blends())


func _make_copies(now: Array[MeshInstance3D]) -> void:
	for c in _copies:
		if is_instance_valid(c):
			c.get_parent().remove_child(c)
			c.queue_free()
	_copies.clear()
	_sources = now
	for s in now:
		var copy := MeshInstance3D.new()
		copy.name = COPY_NAME
		copy.add_to_group(COPY)
		copy.mesh = smoothed(s.mesh)
		copy.skin = s.skin
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s.add_child(copy, false, Node.INTERNAL_MODE_BACK)
		var skel := s.get_node_or_null(s.skeleton) as Skeleton3D
		copy.skeleton = copy.get_path_to(skel) if skel != null else NodePath()
		_copies.append(copy)


func _set_material() -> void:
	var material := current_style().material()
	for c in _copies:
		if is_instance_valid(c):
			c.material_override = material


func _copies_alive() -> bool:
	if _copies.size() != _sources.size():
		return false
	for c in _copies:
		if not is_instance_valid(c):
			return false
	return true


func _has_blends() -> bool:
	for s in _sources:
		if is_instance_valid(s) and s.get_blend_shape_count() > 0:
			return true
	return false


## Gives each copy its source's blend shape values, so the outline follows a squashed shape.
func _sync_blends() -> void:
	for i in mini(_copies.size(), _sources.size()):
		var copy := _copies[i]
		var src := _sources[i]
		if not is_instance_valid(copy) or not is_instance_valid(src):
			continue
		for b in src.get_blend_shape_count():
			copy.set_blend_shape_value(b, src.get_blend_shape_value(b))


## A copy of `mesh` whose normals are averaged across vertices at the same place, so a grown shell has
## no gaps at hard edges (box corners). It keeps the bones, weights and blend shapes. Cached per mesh.
static func smoothed(mesh: Mesh) -> Mesh:
	if _smoothed.has(mesh):
		return _smoothed[mesh]
	var out := ArrayMesh.new()
	var am := mesh as ArrayMesh
	if am != null:
		for b in am.get_blend_shape_count():
			out.add_blend_shape(am.get_blend_shape_name(b))
		out.blend_shape_mode = am.blend_shape_mode
	for i in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(i)
		var shapes := mesh.surface_get_blend_shape_arrays(i)
		for sh: Array in shapes:
			sh[Mesh.ARRAY_TANGENT] = null
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		if normals.size() == verts.size():
			var sums: Dictionary[Vector3, Vector3] = {}
			for v in verts.size():
				var k := verts[v].snapped(Vector3.ONE * WELD)
				sums[k] = sums.get(k, Vector3.ZERO) + normals[v]
			for v in verts.size():
				var n: Vector3 = sums[verts[v].snapped(Vector3.ONE * WELD)]
				normals[v] = n.normalized() if n.length() > 0.0001 else normals[v]
			arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = null
		var flags := 0
		var bones: Variant = arrays[Mesh.ARRAY_BONES]
		if bones != null and verts.size() > 0 and (bones as PackedInt32Array).size() == verts.size() * 8:
			flags = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		var prim := am.surface_get_primitive_type(i) if am != null else Mesh.PRIMITIVE_TRIANGLES
		out.add_surface_from_arrays(prim, arrays, shapes, {}, flags)
	_smoothed[mesh] = out
	return out
