## The Furniture station's line-up (assets/04 F03, Q2337): every piece of game/furniture/ as its real
## scene, built from the folder when the node enters the tree, so a new piece appears with no other
## change. Pieces by name in rows along +X from this node's origin (each footprint's left-front corner
## on the row's line), the next row behind (-Z); each piece's name stands in front of it. Built before
## the level's Parts bind, in the same order on every machine.
class_name FurnitureLineUp
extends Node3D

const FOLDER := "res://game/furniture"
const LABEL := preload("res://game/zoo/zoo_label.tscn")

@export var layout: FurnitureLineUpLayout
## The folder lined up: the furniture (another only in a test).
@export_dir var folder := FOLDER

var _built := false


func _enter_tree() -> void:
	if _built or layout == null:
		return
	_built = true
	build()


## The piece scenes of `from` (res:// paths), sorted by name.
static func pieces(from := FOLDER) -> Array[String]:
	var out: Array[String] = []
	for f: String in ResourceLoader.list_directory(from):
		if f.ends_with(".tscn"):
			out.append(from.path_join(f))
	out.sort()
	return out


## Where each piece stands, by its footprint [width, depth]: the centre of its footprint on the floor,
## in this node's space. The same numbers give the same places on every machine (and in the old
## game's beside-shots).
static func places(footprints: Array, plan: FurnitureLineUpLayout) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var x := 0.0
	var z := 0.0
	var row_depth := 0.0
	for fp: Variant in footprints:
		var size := fp as Vector2
		if x > 0.0 and x + size.x > plan.row_width:
			z -= row_depth + plan.row_gap
			x = 0.0
			row_depth = 0.0
		out.append(Vector3(x + size.x / 2.0, 0.0, z - size.y / 2.0))
		x += size.x + plan.gap
		row_depth = maxf(row_depth, size.y)
	return out


## The pieces of row `row` (0: the front one), in order.
func row_of(row: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child in get_children():
		if child.get_meta(&"row", -1) == row:
			out.append(child as Node3D)
	return out


## The piece named `piece_name` ("kitchen_cupboard") in the line-up, or null.
func piece(piece_name: String) -> Node3D:
	return get_node_or_null(NodePath(piece_name.to_pascal_case())) as Node3D


func build() -> void:
	var scenes: Array[Node3D] = []
	var footprints: Array = []
	for path in pieces(folder):
		var scene := (load(path) as PackedScene).instantiate() as Node3D
		scenes.append(scene)
		var fp: Array = scene.get_meta(&"footprint", [1.0, 1.0])
		footprints.append(Vector2(float(fp[0]), float(fp[1])))
	var at := places(footprints, layout)
	var row := 0
	for i in scenes.size():
		var scene := scenes[i]
		scene.position = at[i]
		if i > 0 and at[i].x < at[i - 1].x:
			row += 1
		scene.set_meta(&"row", row)
		add_child(scene)
		var title := LABEL.instantiate() as Label3D
		title.name = "Name"
		title.text = scene.name
		title.pixel_size = layout.name_pixel_size
		title.font_size = 64
		title.outline_size = 0
		title.double_sided = true
		title.position = Vector3(0.0, 0.08, (footprints[i] as Vector2).y / 2.0 + layout.name_ahead)
		scene.add_child(title)
