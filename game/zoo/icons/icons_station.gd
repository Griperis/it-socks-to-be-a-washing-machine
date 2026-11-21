## The Icons station (assets/03, U03, Q2337): every icon of assets/ui/ on a wall, each with its name under
## it, built from the folder when the station enters the tree: a new svg appears with no other change.
## Groups are the first word of a name (key, pad, menu, emoji, upgrade; the rest are "other"), each a
## block of rows. `show_old_beside(dir)` puts the same file of another folder (the old game's) at the right
## of each icon, for a before and after.
class_name IconsStation
extends Node3D

const CELL := preload("res://game/zoo/icons/icon_cell.tscn")
const LABEL := preload("res://game/zoo/zoo_label.tscn")

## Icons per row.
@export var per_row := 12
## Distance between two cells, sideways and down, in metres.
@export var column_pitch := 1.15
@export var row_pitch := 0.75
## The side of an icon's picture, metres, and the pixel size of the names under them.
@export var icon_size := 0.5
@export var label_pixel_size := 0.0028
## A name longer than `label_fit` letters is drawn that much smaller, so it fits under its icon; its
## top `label_drop` icon sizes under the icon's middle.
@export var label_fit := 20.0
@export var label_drop := 0.7
## The pixel size of a group's name, at the left of its block.
@export var group_pixel_size := 0.006
## The gap between two groups, in rows.
@export var group_gap_rows := 0.6
## Where the icons and the names go.
@export var wall: Node3D

var _built := false
var _cells: Dictionary[String, Vector3] = {}


func _enter_tree() -> void:
	if _built or wall == null:
		return
	_built = true
	build()


## The group of an icon key: its first word when that is one of the families, else "other".
static func group_of(key: String) -> String:
	var head := key.get_slice("_", 0)
	return head if ["key", "pad", "menu", "emoji", "upgrade"].has(head) else "other"


## The groups in the order they are shown.
static func group_names() -> Array[String]:
	return ["other", "menu", "emoji", "key", "pad", "upgrade"]


## The icon keys of a group, sorted.
func keys_of(group: String) -> Array[String]:
	var out: Array[String] = []
	for k in UiIcons.all_keys():
		if group_of(k) == group:
			out.append(k)
	return out


## Where an icon's cell stands in the station's space (its picture's centre), or Vector3.INF.
func cell_position(key: String) -> Vector3:
	return _cells.get(key, Vector3.INF)


func build() -> void:
	var y := 0.0
	for g in group_names():
		var list := keys_of(g)
		if list.is_empty():
			continue
		var title := LABEL.instantiate() as Label3D
		title.name = "Group_%s" % g
		title.text = g.to_upper()
		# Standing on the wall as the cells' names do (icon_cell.tscn's Label).
		title.transform = Transform3D(Basis.IDENTITY, Vector3(-column_pitch * 0.9, y, 0.0))
		title.double_sided = true
		title.modulate = Color.WHITE
		title.font_size = 48
		title.outline_size = 8
		title.pixel_size = group_pixel_size
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		wall.add_child(title)
		for i in list.size():
			@warning_ignore("integer_division")
			var at := Vector3((i % per_row) * column_pitch, y - (i / per_row) * row_pitch, 0.0)
			_cells[list[i]] = at
			wall.add_child(_cell(list[i], at))
		@warning_ignore("integer_division")
		y -= ((list.size() + per_row - 1) / per_row + group_gap_rows) * row_pitch


## An icon's cell (icon_cell.tscn): its picture, and its name under it.
func _cell(key: String, at: Vector3) -> Node3D:
	var root := CELL.instantiate() as Node3D
	root.name = key
	root.position = at
	var sprite := root.get_node(^"Icon") as Sprite3D
	sprite.texture = UiIcons.texture(key)
	sprite.pixel_size = icon_size / 64.0
	var label := root.get_node(^"Label") as Label3D
	label.text = key
	label.position = Vector3(0.0, -icon_size * label_drop, 0.0)
	label.pixel_size = label_pixel_size * minf(1.0, label_fit / key.length())
	return root


## Puts the same file of the folder `dir` (a directory path on disk) beside each icon, one icon width to the
## right and marked "old". An icon with no such file there gets nothing. Returns how many were made.
func show_old_beside(dir: String) -> int:
	var made := 0
	for key: String in _cells:
		var file := dir.path_join(String(UiIcons.ALIASES.get(key, key)) + ".svg")
		var image := Image.load_from_file(file)
		if image == null or image.is_empty():
			continue
		var sprite := Sprite3D.new()
		sprite.name = "Old"
		sprite.texture = ImageTexture.create_from_image(image)
		sprite.pixel_size = icon_size / 64.0
		sprite.position = Vector3(icon_size * 1.05, 0.0, 0.0)
		wall.get_node(key).add_child(sprite)
		made += 1
	return made
