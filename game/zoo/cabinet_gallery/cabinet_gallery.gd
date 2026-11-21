## The Cabinet station's line-up (assets/02, K02, Q2337): one real Cabinet (cabinet.tscn) per
## Collection of the catalogue, wearing that Collection's Looks, in rows from this node's origin
## (the first row along +X, the next rows behind, -Z), each with its Collection's name above it.
## Built from the catalogue when the node enters the tree, before the level's Parts bind, in the
## same order on every machine: a new Collection in designs.tres appears here with no other change.
## A Collection that already has a Cabinet among the station's own children is left out.
class_name CabinetGallery
extends Node3D

const CABINET := preload("res://game/entities/cabinet/cabinet.tscn")
const LABEL := preload("res://game/zoo/zoo_label.tscn")
const PART := ^"Cabinet"

## The Designs whose Collections are lined up.
@export var catalogue: DesignCatalogue
@export var layout: CabinetGalleryLayout

var _built := false


func _enter_tree() -> void:
	if _built or catalogue == null or layout == null:
		return
	_built = true
	build()



## The Collections whose Cabinets already stand in the station (its own children, not the line-up's).
func placed() -> Array[StringName]:
	var out: Array[StringName] = []
	var station := get_parent()
	if station == null:
		return out
	for child in station.get_children():
		var part := child.get_node_or_null(PART) as Cabinet
		if part != null:
			out.append(part.collection)
	return out


## The Cabinet of Collection `collection` in the line-up, or null.
func cabinet_of(collection: StringName) -> Node3D:
	return get_node_or_null(NodePath("Cabinet_%s" % collection)) as Node3D


func build() -> void:
	var skip := placed()
	var k := 0
	for c in catalogue.collections():
		if skip.has(c):
			continue
		var cabinet := CABINET.instantiate() as Node3D
		cabinet.name = "Cabinet_%s" % c
		(cabinet.get_node(PART) as Cabinet).collection = c
		@warning_ignore("integer_division")
		cabinet.position = Vector3((k % layout.per_row) * layout.spacing, 0.0, -(k / layout.per_row) * layout.row_pitch)
		add_child(cabinet)
		var title := LABEL.instantiate() as Label3D
		title.name = "Name"
		title.text = String(c).capitalize()
		title.pixel_size = layout.name_pixel_size
		title.outline_size = 0
		# Standing over its Cabinet, read from the front.
		title.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, layout.name_height, 0.0))
		title.double_sided = true
		cabinet.add_child(title)
		k += 1
