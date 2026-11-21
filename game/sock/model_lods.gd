## Folds a model's hand-made LODs into its close-up's mesh (assets/01, S05): the old game's
## ModelLods, which did it at run time; here model_lods_import.gd runs it when a .glb is imported.
## A MeshInstance3D `<name>_lod<N>` beside `<name>` becomes index LOD N of `<name>`'s mesh, and the LOD node is removed: one mesh, one vertex
## buffer, one index buffer per level. Godot's mesh LOD then picks the level per drawn instance (a
## MultiMesh included) by its size on screen and the graphics preset's mesh detail
## (`Viewport.mesh_lod_threshold`).
class_name ModelLods
extends RefCounted

## When a level is drawn, in screen pixels of the model's longest side at mesh detail 1: the last
## level below FAR_PX, a middle level below MID_PX. placeholder: the old game's agent numbers
## (its pipeline/03 follow-up), kept as they were.
const MID_PX := 64.0
const FAR_PX := 24.0

## Each folded mesh by its close-up's mesh, so every instance of a model shares one.
static var _merged: Dictionary[Mesh, Mesh] = {}


## Folds every `<name>_lod<N>` MeshInstance3D under `root` into its sibling `<name>`.
static func fold(root: Node) -> void:
	var chains: Dictionary[MeshInstance3D, Dictionary] = {}
	for n: Node in root.find_children("*_lod*", "MeshInstance3D", true, false):
		var full := String(n.name)
		var cut := full.rfind("_lod")
		var level := full.substr(cut + 4)
		if not level.is_valid_int() or int(level) < 1:
			continue
		var base := n.get_parent().get_node_or_null(NodePath(full.substr(0, cut))) as MeshInstance3D
		if base == null:
			push_warning("ModelLods: %s has no close-up %s beside it" % [full, full.substr(0, cut)])
			continue
		if not chains.has(base):
			chains[base] = {}
		chains[base][int(level)] = n
	for base: MeshInstance3D in chains:
		var levels := chains[base]
		var keys := levels.keys()
		keys.sort()
		var meshes: Array[Mesh] = []
		for k: int in keys:
			meshes.append((levels[k] as MeshInstance3D).mesh)
		base.mesh = merged(base.mesh, meshes)
		for k: int in keys:
			var lod: Node = levels[k]
			lod.get_parent().remove_child(lod)
			lod.free()


## `base` with `lods` (closest first) as its index LODs; `base` itself when they don't fit (a
## different surface count or vertex format).
static func merged(base: Mesh, lods: Array[Mesh]) -> Mesh:
	if base == null or lods.is_empty():
		return base
	if _merged.has(base):
		return _merged[base]
	var out := ArrayMesh.new()
	var longest := base.get_aabb().get_longest_axis_size()
	for s in base.get_surface_count():
		var arrays := base.surface_get_arrays(s)
		var lod_index := {}
		for i in lods.size():
			var lod := lods[i]
			if lod == null or lod.get_surface_count() != base.get_surface_count():
				push_warning("ModelLods: LOD %d of %s has a different surface count" % [i + 1, base.resource_name])
				return base
			var px := FAR_PX if i == lods.size() - 1 else MID_PX
			var indices := _append(arrays, lod.surface_get_arrays(s))
			if indices.is_empty():
				push_warning("ModelLods: LOD %d of %s has a different vertex format" % [i + 1, base.resource_name])
				return base
			# The level is drawn while its "edge length" projects below the mesh detail threshold
			# (in pixels): the model's longest side over the switch size.
			lod_index[longest / px] = indices
		var flags: int = base.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], lod_index, flags)
		out.surface_set_material(s, base.surface_get_material(s))
		out.surface_set_name(s, base.surface_get_name(s))
	out.resource_name = base.resource_name
	_merged[base] = out
	return out


## Appends `more`'s vertices to `arrays` (in place) and returns `more`'s indices, shifted onto
## them; empty when the two don't carry the same attributes.
static func _append(arrays: Array, more: Array) -> PackedInt32Array:
	var offset: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var count: int = (more[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for t in Mesh.ARRAY_MAX:
		if t == Mesh.ARRAY_INDEX:
			continue
		if (arrays[t] == null) != (more[t] == null):
			return PackedInt32Array()
		if arrays[t] == null:
			continue
		# Per-vertex widths (bones and weights 4 or 8 a vertex, tangents 4) must match.
		@warning_ignore("integer_division")
		if offset > 0 and count > 0 and arrays[t].size() / offset != more[t].size() / count:
			return PackedInt32Array()
	for t in Mesh.ARRAY_MAX:
		if t == Mesh.ARRAY_INDEX or arrays[t] == null:
			continue
		var a: Variant = arrays[t]
		a.append_array(more[t])
		arrays[t] = a
	var src: PackedInt32Array = more[Mesh.ARRAY_INDEX] if more[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(count))
	var out := PackedInt32Array()
	out.resize(src.size())
	for i in src.size():
		out[i] = src[i] + offset
	return out
