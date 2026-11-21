## The Sock looks station (assets/01): a line-up of the Sock Looks, each dressed as a Design: the
## first Design of every Collection (each shape and cloth), the first of every pattern kind, print
## layout, coat and trim patches, and every sock ball as the first Design whose Pair rolls into it.
## Built from the catalogue and the look table when the station enters the tree (Q2337): a new
## Collection, pattern or ball appears here with no other change. Looks only, no Socks of the Mess.
class_name SockLooksStation
extends Node3D

## The groups of the line-up, in order (a group is one or more rows).
const GROUPS: Array[StringName] = [&"collections", &"patterns", &"balls"]

@export var catalogue: DesignCatalogue
@export var layout: SockLooksLayout
## Where the Looks and the labels go.
@export var looks: Node3D
@export var labels: Node3D

var _built := false


func _enter_tree() -> void:
	if _built or catalogue == null or layout == null or looks == null or labels == null:
		return
	_built = true
	build()


## The Designs' ids of a group of the line-up, in order.
func lineup(group: StringName) -> PackedInt32Array:
	var out := PackedInt32Array()
	match group:
		&"collections":
			var seen: Array[StringName] = []
			for id in catalogue.size():
				var d := catalogue.design(id)
				if d != null and not seen.has(d.collection):
					seen.append(d.collection)
					out.append(id)
		&"patterns":
			for p in MessDrawing.PATTERNS:
				_first(out, func(d: SockDesign) -> bool: return d.pattern == p)
			for l in MessDrawing.LAYOUTS:
				_first(out, func(d: SockDesign) -> bool: return d.pattern == &"print" and d.layout == l and d.coat < 0)
			_first(out, func(d: SockDesign) -> bool: return d.coat >= 0)
			for p in MessDrawing.PATCHES:
				_first(out, func(d: SockDesign) -> bool: return d.patches == p)
		&"balls":
			for c in SockLook.TABLE.cuffs:
				_first(out, func(d: SockDesign) -> bool: return SockLook.TABLE.cuff_of(d) == c)
	return out


## Appends the first Design (by id) that `test` accepts and `out` does not hold yet.
func _first(out: PackedInt32Array, test: Callable) -> void:
	for id in catalogue.size():
		var d := catalogue.design(id)
		if d != null and not out.has(id) and test.call(d):
			out.append(id)
			return


## The Looks of Design `id` in group `group` (its node's name).
static func looks_name(group: StringName, id: int) -> String:
	return "%s_%d" % [group, id]


## Lays out the line-up: each group in rows, a Looks and its label per Design.
func build() -> void:
	var z := 0.0
	for group in GROUPS:
		var ids := lineup(group)
		var ball := group == &"balls"
		for i in ids.size():
			var d := catalogue.design(ids[i])
			@warning_ignore("integer_division")
			var row := i / layout.per_row
			var x := (i % layout.per_row - (layout.per_row - 1) * 0.5) * layout.spacing
			var at := Vector3(x, 0.0, z - row * layout.row_pitch)
			var l := SockLook.make(d, SockDress.LYING, ball)
			l.name = looks_name(group, d.id)
			# A ball's origin is its centre: it rests on the ground.
			l.position = at + (Vector3.UP * SockLook.ball_radius(SockLook.TABLE.cuff_of(d)) * d.size_scale() if ball else Vector3.ZERO)
			looks.add_child(l)
			labels.add_child(_label(d, at + Vector3(0.0, 0.012, layout.label_offset)))
		@warning_ignore("integer_division")
		z -= ((ids.size() + layout.per_row - 1) / layout.per_row) * layout.row_pitch + layout.group_gap


func _label(d: SockDesign, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.name = "d%d_%d" % [d.id, labels.get_child_count()]
	label.text = "%d %s\n%s" % [d.id, d.name, String(d.collection)]
	label.pixel_size = layout.label_pixel_size
	label.modulate = Color(0.1, 0.1, 0.12)
	label.shaded = false
	label.double_sided = false
	label.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), at)
	return label
