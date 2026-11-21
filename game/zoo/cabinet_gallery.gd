## The Cabinet station's line-up (assets/02, K02, Q2337): one real Cabinet (cabinet.tscn) per
## Collection of the catalogue, wearing that Collection's Looks, in rows from this node's origin
## (the first row along +X, the next rows behind, -Z), each with its Collection's name above it.
## Built from the catalogue when the node enters the tree, before the level's Parts bind, in the
## same order on every machine: a new Collection in designs.tres appears here with no other change.
## A Collection that already has a Cabinet among the station's own children is left out.
class_name CabinetGallery
extends Node3D

const CABINET := preload("res://game/entities/cabinet/cabinet.tscn")
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


## The Collections in the order their first Design (by id) appears.
func collections() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in catalogue.size():
		var d := catalogue.design(id)
		if d != null and not out.has(d.collection):
			out.append(d.collection)
	return out


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
	for c in collections():
		if skip.has(c):
			continue
		var cabinet := CABINET.instantiate() as Node3D
		cabinet.name = "Cabinet_%s" % c
		(cabinet.get_node(PART) as Cabinet).collection = c
		@warning_ignore("integer_division")
		cabinet.position = Vector3((k % layout.per_row) * layout.spacing, 0.0, -(k / layout.per_row) * layout.row_pitch)
		add_child(cabinet)
		var title := Label3D.new()
		title.name = "Name"
		title.text = String(c).capitalize()
		title.pixel_size = layout.name_pixel_size
		title.modulate = Color(0.1, 0.1, 0.12)
		title.outline_size = 0
		title.shaded = false
		title.position = Vector3(0.0, layout.name_height, 0.0)
		cabinet.add_child(title)
		k += 1
