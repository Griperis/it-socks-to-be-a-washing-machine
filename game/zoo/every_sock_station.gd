## The every-Sock station (core/12, Q2290): both Socks of every Design of the catalogue lie on the
## ground, in rows by Collection (the Collection's name at the start of its block), the Designs in
## id order, each Sock beside its mate, and its info as text in front of the pair. All of it is
## made from the catalogue when the station enters the tree (before any Mess reads its spots), in
## the same order on every machine: a new Design in designs.tres appears here with no other change.
## The Socks are SockSpots under `Spots`, so they are real Socks of whichever Mess the station
## joins (the zoo's one, or its own when played alone).
class_name EverySockStation
extends Node3D

## The Designs to lay out.
@export var catalogue: DesignCatalogue
@export var layout: EverySockLayout
## Where the SockSpots go (the station's Mess reads them), and the labels.
@export var spots: Node3D
@export var labels: Node3D

var _built := false


func _enter_tree() -> void:
	if _built or catalogue == null or layout == null or spots == null or labels == null:
		return
	_built = true
	build()


## The Collections in the order their first Design (by id) appears.
func collections() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in catalogue.size():
		var d := catalogue.design(id)
		if d != null and not out.has(d.collection):
			out.append(d.collection)
	return out


## The Designs' ids of a Collection, in id order.
func designs_of(collection: StringName) -> PackedInt32Array:
	var out := PackedInt32Array()
	for id in catalogue.size():
		var d := catalogue.design(id)
		if d != null and d.collection == collection:
			out.append(id)
	return out


func _cell(column: int, z: float) -> Array[Vector3]:
	var x := (column - (layout.per_row - 1) * 0.5) * layout.cell_width
	return [Vector3(x - layout.mate_gap * 0.5, 0.0, z), Vector3(x + layout.mate_gap * 0.5, 0.0, z),
			Vector3(x, 0.0, z + layout.label_offset)]


## Lays out the whole catalogue: one pass, each Collection a block of rows.
func build() -> void:
	var z := 0.0
	for c in collections():
		var ids := designs_of(c)
		var title := Label3D.new()
		title.name = "Name_%s" % c
		title.text = String(c).capitalize()
		title.pixel_size = layout.name_pixel_size
		title.modulate = Color(0.1, 0.1, 0.12)
		title.shaded = false
		title.double_sided = false
		title.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5),
				Vector3(-(layout.per_row - 1) * 0.5 * layout.cell_width - layout.name_offset, 0.01, z))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		labels.add_child(title)
		for i in ids.size():
			@warning_ignore("integer_division")
			var place := _cell(i % layout.per_row, z - (i / layout.per_row) * layout.row_pitch)
			var id := ids[i]
			for m in 2:
				var spot := SockSpot.new()
				spot.name = "d%d_%s" % [id, "ab"[m]]
				spot.design = id
				spot.position = place[m]
				spots.add_child(spot)
			labels.add_child(_label(catalogue.design(id), place[2]))
		@warning_ignore("integer_division")
		z -= ((ids.size() + layout.per_row - 1) / layout.per_row) * layout.row_pitch + layout.collection_gap


## A Design's info, as it lies in front of its Socks.
static func info(d: SockDesign) -> String:
	return "%d %s\n%s\n%s, %s" % [d.id, d.name, String(d.collection), SockDesign.Size.keys()[d.size].to_lower(),
			SockDesign.Rarity.keys()[d.rarity].to_lower()]


func _label(d: SockDesign, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.name = "d%d" % d.id
	label.text = info(d)
	label.pixel_size = layout.label_pixel_size
	label.modulate = Color(0.1, 0.1, 0.12)
	label.shaded = false
	label.double_sided = false
	label.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), at + Vector3(0.0, 0.01, 0.0))
	return label
