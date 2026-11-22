## The own body's belly (coop/06, the old avatar.gd belly_mesh() and _MeshClip): the first surface of
## a mesh (the sock creature's `player` surface) below a height, with its shape keys. The triangles
## across the cut are cut along it (new vertices between theirs), so its edge is a smooth line, not a
## triangle's jagged steps, and the opening is closed by a flat top, skinned like its edge. A vertex
## made where an edge crosses the cut is the two ends' blend (positions, normals, tangents, UVs,
## colours and every shape key's), skinned like the end inside; one per edge, shared by the two
## triangles on it. Made once at load from the imported mesh.
class_name BellyMesh
extends RefCounted

## The surface's arrays and its shape keys' arrays, growing as vertices are made.
var arrays: Array
var shapes: Array
## The vertices on the cut (the body's own there, and those made on it).
var on_cut: Dictionary[int, bool] = {}
## Edge (lower index, higher index) -> the vertex made where it crosses the cut.
var _made: Dictionary[Vector2i, int] = {}


func _init(surface: Array, shape_arrays: Array) -> void:
	arrays = surface
	shapes = shape_arrays


## Surface 0 of `src` below `height` metres, named `surface_name`, with its material and shape keys.
static func cut(src: ArrayMesh, height: float, surface_name: StringName) -> ArrayMesh:
	var surface := src.surface_get_arrays(0)
	var clip := BellyMesh.new(surface, src.surface_get_blend_shape_arrays(0))
	var plane := Plane(Vector3.UP, height)
	var idx: PackedInt32Array = surface[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	var rim: Array[Vector2i] = []  # the edges along the cut, as the body's triangles run them
	for t: int in range(0, idx.size(), 3):
		var poly := clip.clip(PackedInt32Array([idx[t], idx[t + 1], idx[t + 2]]), plane)
		for k: int in range(1, poly.size() - 1):
			kept.append_array([poly[0], poly[k], poly[k + 1]])
		for k: int in (poly.size() if poly.size() >= 3 else 0):
			var a := poly[k]
			var b := poly[(k + 1) % poly.size()]
			if clip.on_cut.has(a) and clip.on_cut.has(b):
				rim.append(Vector2i(a, b))
	kept.append_array(clip.cap(rim))
	var out_arrays := clip.arrays
	out_arrays[Mesh.ARRAY_INDEX] = kept
	var out := ArrayMesh.new()
	out.blend_shape_mode = src.blend_shape_mode
	for i: int in src.get_blend_shape_count():
		out.add_blend_shape(src.get_blend_shape_name(i))
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arrays, clip.shapes)
	out.surface_set_material(0, src.surface_get_material(0))
	out.surface_set_name(0, surface_name)
	return out


## `poly` (vertex indices, in order) clipped to where `plane` is <= 0.
func clip(poly: PackedInt32Array, plane: Plane) -> PackedInt32Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var out := PackedInt32Array()
	for i: int in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var da := plane.distance_to(verts[a])
		var db := plane.distance_to(verts[b])
		# A vertex of the body's own on the cut stays, and is the edge's crossing.
		da = 0.0 if absf(da) < 0.000001 else da
		db = 0.0 if absf(db) < 0.000001 else db
		if da <= 0.0:
			out.append(a)
			if da == 0.0:
				on_cut[a] = true
		if (da < 0.0 and db > 0.0) or (da > 0.0 and db < 0.0):
			var key := Vector2i(mini(a, b), maxi(a, b))
			if not _made.has(key):
				var t := da / (da - db)
				_made[key] = _add(a, b, t, a if da <= 0.0 else b)
				on_cut[_made[key]] = true
			out.append(_made[key])
	return out


## Closes the cut: a flat top over `rim` (edges, each running the way its body triangle does), the
## triangles from each edge to the rim's middle, facing up (each edge reversed). The top's vertices
## are the rim's again, their normals up; the middle is the rim's mean in every shape.
func cap(rim: Array[Vector2i]) -> PackedInt32Array:
	var out := PackedInt32Array()
	if rim.is_empty():
		return out
	var ring: Dictionary[int, bool] = {}
	for e: Vector2i in rim:
		ring[e.x] = true
		ring[e.y] = true
	var copy: Dictionary[int, int] = {}
	for v: int in ring:
		copy[v] = _add(v, v, 0.0, v, Vector3.UP)
	var middle := _add(rim[0].x, rim[0].x, 0.0, rim[0].x, Vector3.UP)
	for arr: Array in [arrays] + shapes:
		var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var sum := Vector3.ZERO
		for v: int in ring:
			sum += pos[v]
		pos[middle] = sum / ring.size()
		arr[Mesh.ARRAY_VERTEX] = pos
	for e: Vector2i in rim:
		out.append_array([copy[e.y], copy[e.x], middle])
	return out


## A new vertex `t` of the way from `a` to `b`, skinned like `skin`; `normal` replaces the blend's.
func _add(a: int, b: int, t: float, skin: int, normal: Variant = null) -> int:
	var at := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_lerp_into(arrays, a, b, t, skin, normal)
	for shape: Array in shapes:
		_lerp_into(shape, a, b, t, skin, normal)  # shape keys hold whole positions and normals
	return at


static func _lerp_into(arr: Array, a: int, b: int, t: float, skin: int, normal: Variant) -> void:
	var n := (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for kind: int in arr.size():
		var data: Variant = arr[kind]
		if data == null or kind == Mesh.ARRAY_INDEX:
			continue
		if data is PackedVector3Array:
			var v: Vector3 = (data[a] as Vector3).lerp(data[b], t)
			if kind == Mesh.ARRAY_NORMAL:
				v = normal if normal != null else (v.normalized() if v.length() > 0.0001 else v)
			data.append(v)
		elif data is PackedVector2Array:
			data.append((data[a] as Vector2).lerp(data[b], t))
		elif data is PackedColorArray:
			data.append((data[a] as Color).lerp(data[b], t))
		elif data is PackedFloat32Array or data is PackedInt32Array or data is PackedByteArray:
			if n == 0:
				continue
			var stride: int = data.size() / n
			for c: int in stride:
				if kind == Mesh.ARRAY_TANGENT:
					data.append(lerpf(data[a * stride + c], data[b * stride + c], t) if c < 3 else data[a * stride + c])
				else:
					data.append(data[skin * stride + c])
		else:
			continue
		arr[kind] = data
