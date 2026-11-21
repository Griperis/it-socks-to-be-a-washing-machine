## The Sock looks station (assets/01): a line-up of the Sock Looks, each dressed as a Design: the
## first Design of every Collection (each shape and cloth), the first of every pattern kind, print
## layout, coat and trim patches, and every sock ball as the first Design whose Pair rolls into it.
## Built from the catalogue and the look table when the station enters the tree (Q2337): a new
## Collection, pattern or ball appears here with no other change. Looks only, no Socks of the Mess.
class_name SockLooksStation
extends Node3D

## The groups of the line-up, in order (a group is one or more rows).
const GROUPS: Array[StringName] = [&"collections", &"patterns", &"balls"]
const LABEL := preload("res://game/zoo/zoo_label.tscn")

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
			for c in catalogue.collections():
				_first(out, func(d: SockDesign) -> bool: return d.collection == c)
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
				_first(out, func(d: SockDesign) -> bool: return SockLook.TABLE.cuff_of(d.collection) == c)
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
			var l := SockDress.make(d, SockDress.LYING, ball)
			l.name = looks_name(group, d.id)
			# A ball's origin is its centre: it rests on the ground.
			l.position = at + (Vector3.UP * SockDress.ball_radius(d) if ball else Vector3.ZERO)
			looks.add_child(l)
			labels.add_child(_label(d, at + Vector3(0.0, 0.012, layout.label_offset)))
		z -= DesignCatalogue.rows_of(ids.size(), layout.per_row) * layout.row_pitch + layout.group_gap


func _label(d: SockDesign, at: Vector3) -> Label3D:
	var label := LABEL.instantiate() as Label3D
	label.name = "d%d_%d" % [d.id, labels.get_child_count()]
	label.text = "%d %s\n%s" % [d.id, d.name, String(d.collection)]
	label.pixel_size = layout.label_pixel_size
	label.position = at
	return label
