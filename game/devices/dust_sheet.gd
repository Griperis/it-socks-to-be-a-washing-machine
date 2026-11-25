## The dust sheet over a locked Cabinet (the old campaign/dust_sheet.gd: progression/21, Q679; Q719;
## Q2507): an off-white cloth draped over the Cabinet's top, rounded over its edges and hanging down
## its front and sides to the floor in soft folds, a little down its back. On the unlock it is pulled
## off: it slides forward over the top front edge, spills onto the floor and fades, then is gone, and
## the reveal sounds at the Cabinet. Looks only: a child of the Cabinet's root named "DustSheet",
## shown by the Cabinet's own state (Cabinet._show calls follow()); drawn in code, no collision. It
## stands in the Cabinet's frame (its front +Z, its floor y 0).
class_name DustSheet
extends MeshInstance3D

## Grid cells across and along the sheet.
const CELLS := Vector2i(28, 30)
## How far the sheet reaches past the Cabinet's sides (down them) and how far it bulges out.
const SIDE_HANG := 0.9
const BULGE := 0.018
## How far it folds down the Cabinet's back (it stands against its wall).
const BACK_HANG := 0.08
## How much roomier than the Cabinet it lies, metres.
const LOOSE := 0.015
## The rounding of the top edges, metres.
const EDGE_R := 0.035
## The folds' depth.
const FOLD := 0.022
## How far past its own length it slides on the pull, metres.
const SLIDE_PAST := 0.2
## Over what last share of the pull it fades out.
const FADE_SHARE := 0.4
## The reveal's sound, and how high over the Cabinet's floor it plays.
const REVEAL := &"cabinet_reveal"
const REVEAL_UP := 1.0

@export var tuning: DustSheetTuning

## The draped box: the Cabinet's width, depth and height (x, y, z), and its middle's x and z.
var box := Vector3(1.5, 0.5, 1.0)
## How far off it is: 0 draped, 1 gone.
var pull := 0.0
var _mid := Vector2.ZERO
var _material: StandardMaterial3D
var _tween: Tween = null
## Whether follow() has shown a state yet.
var _followed := false


func _ready() -> void:
	_material = (material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	material_override = _material


## Shows the Cabinet's lock: locked, draped over it; unlocked, gone. `now` (a load, a late Guest)
## jumps there; else turning unlocked pulls it off with its reveal and turning locked drapes it at once.
func follow(locked: bool, now: bool) -> void:
	var first := not _followed
	_followed = true
	if locked:
		if now or first or not visible or pulling():
			drape_over(get_parent() as Node3D)
			show_on(true)
	elif now or first:
		show_on(false)
	elif visible and not pulling():
		pull_off()


## Drapes it over what `cabinet` shows now (its visible meshes, less this sheet), at once.
func drape_over(cabinet: Node3D) -> void:
	if cabinet != null:
		drape(shown_bounds(cabinet, self))


## Drapes it over `bounds` (standing on the floor, y 0, to its top) at once, whole and still.
func drape(bounds: AABB) -> void:
	_stop()
	box = Vector3(bounds.size.x + 2.0 * LOOSE, bounds.size.z + 2.0 * LOOSE, bounds.end.y + LOOSE)
	_mid = Vector2(bounds.get_center().x, bounds.get_center().z)
	_set_pull(0.0)


## The bounds of what `node` shows (its visible meshes under it, in its own frame), less `skip`.
static func shown_bounds(node: Node3D, skip: Node = null) -> AABB:
	var out := AABB()
	var first := true
	var inv := node.global_transform.affine_inverse()
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == skip or (n is Node3D and not (n as Node3D).visible):
			continue
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var b := inv * (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
			out = b if first else out.merge(b)
			first = false
		stack.append_array(n.get_children())
	return out


## Stands draped (`on`) or gone, at once.
func show_on(on: bool) -> void:
	_stop()
	_set_pull(0.0)
	visible = on


## Pulls it off: it slides forward over the Cabinet's top front edge, spills onto the floor and fades
## away over pull_time, then hides; the reveal sounds at the Cabinet after the pull (and at least
## reveal_delay). Returns the seconds the pull takes.
func pull_off() -> float:
	if not visible:
		return 0.0
	if not is_inside_tree():
		show_on(false)
		return 0.0
	_stop()
	var t := _tuning()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tween = create_tween()
	_tween.tween_method(_set_pull, 0.0, 1.0, t.pull_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void: show_on(false))
	var wait := maxf(t.reveal_delay, t.pull_time)
	# A method of the sheet's, so a sheet freed before the timer (its level left) is never called.
	get_tree().create_timer(wait, false).timeout.connect(_reveal_sound)
	return t.pull_time


## The reveal sounds over the Cabinet, after the pull.
func _reveal_sound() -> void:
	var cabinet := get_parent() as Node3D
	if cabinet != null and cabinet.is_inside_tree():
		Sounds.play_at(REVEAL, cabinet.global_position + Vector3.UP * REVEAL_UP)


## Whether the pull is still playing.
func pulling() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


func _stop() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	if _material != null:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_material.albedo_color.a = 1.0


## `t` of the way off (0 draped, 1 gone): the sheet slides forward by t of its length (and a bit) and
## fades over the last FADE_SHARE of it.
func _set_pull(t: float) -> void:
	pull = t
	if _material != null:
		_material.albedo_color.a = clampf((1.0 - t) / FADE_SHARE, 0.0, 1.0)
	mesh = _build()


## The sheet's mesh: a flat cloth laid over the box's top and folded down past its edges.
func _build() -> ArrayMesh:
	var w := box.x
	var d := box.y
	var h := box.z
	var hang := h - 0.02
	var across := w + 2.0 * SIDE_HANG
	var along := d + hang + BACK_HANG
	var slide := pull * (along + SLIDE_PAST)
	var nx := CELLS.x + 1
	var nz := CELLS.y + 1
	var verts := PackedVector3Array()
	verts.resize(nx * nz)
	for j in nz:
		var b := -d / 2.0 - BACK_HANG + along * float(j) / CELLS.y + slide
		for i in nx:
			var a := -across / 2.0 + across * float(i) / CELLS.x
			verts[j * nx + i] = _drape_point(a, b, w, d, h)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in CELLS.y:
		for i in CELLS.x:
			var p00 := verts[j * nx + i]
			var p10 := verts[j * nx + i + 1]
			var p01 := verts[(j + 1) * nx + i]
			var p11 := verts[(j + 1) * nx + i + 1]
			for p: Vector3 in [p00, p01, p10, p10, p01, p11]:
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()


## Where the flat sheet's point (a across, b along: front +Z) lies once draped over the box (its top
## `h`, `w` wide, `d` deep): over the top it lies on it; past an edge it rounds over it and hangs
## straight down, bulging out a little in folds, and what reaches the floor lies on it.
func _drape_point(a: float, b: float, w: float, d: float, h: float) -> Vector3:
	var ca := clampf(a, -w / 2.0, w / 2.0)
	var cb := clampf(b, -d / 2.0, d / 2.0)
	var over := Vector2(a - ca, b - cb)
	var l := over.length()
	if l < 0.0001:
		return Vector3(_mid.x + a, h + 0.004, _mid.y + b)
	var dir := over / l
	# The folds run down from the edge (along it by `e`), shallow there, full a third of the way down.
	var e := ca + cb
	var fold := FOLD * smoothstep(0.0, 0.35, l) * (sin(e * TAU * 3.2) + 0.45 * sin(e * TAU * 6.1 + 1.3))
	var arc := EDGE_R * PI / 2.0
	var out: float
	var y: float
	if l < arc:
		var ang := l / EDGE_R
		out = EDGE_R * sin(ang)
		y = h + 0.004 - EDGE_R * (1.0 - cos(ang))
	else:
		out = EDGE_R + BULGE * smoothstep(0.0, 0.3, l) + fold
		y = h + 0.004 - EDGE_R - (l - arc)
		if y < 0.006:
			# On the floor: it spills out from the foot.
			out += 0.006 - y
			y = 0.006
	return Vector3(_mid.x + ca + dir.x * out, y, _mid.y + cb + dir.y * out)


func _tuning() -> DustSheetTuning:
	if tuning == null:
		tuning = DustSheetTuning.new()
	return tuning
