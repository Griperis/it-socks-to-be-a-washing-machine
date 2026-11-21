## The Icons station (assets/03, U03, Q2337): every icon of assets/ui/ on a wall, each with its name under
## it, built from the folder when the station enters the tree: a new svg appears with no other change.
## Groups are the first word of a name (key, pad, menu, emoji, upgrade; the rest are "other"), each a
## block of rows. `show_old_beside(dir)` puts the same file of another folder (the old game's) at the right
## of each icon, for a before and after.
class_name IconsStation
extends Node3D

## Icons per row.
@export var per_row := 12
## Distance between two cells, sideways and down, in metres.
@export var column_pitch := 1.15
@export var row_pitch := 0.75
## The side of an icon's picture, metres, and the pixel size of the names under them.
@export var icon_size := 0.5
@export var label_pixel_size := 0.0028
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
		var title := _label(g.to_upper(), Vector3(-column_pitch * 0.9, y, 0.0), 0.006)
		title.name = "Group_%s" % g
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		wall.add_child(title)
		for i in list.size():
			@warning_ignore("integer_division")
			var at := Vector3((i % per_row) * column_pitch, y - (i / per_row) * row_pitch, 0.0)
			_cells[list[i]] = at
			wall.add_child(_cell(list[i], at))
		@warning_ignore("integer_division")
		y -= ((list.size() + per_row - 1) / per_row + group_gap_rows) * row_pitch


func _cell(key: String, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = key
	root.position = at
	var sprite := Sprite3D.new()
	sprite.name = "Icon"
	sprite.texture = UiIcons.texture(key)
	sprite.pixel_size = icon_size / 64.0
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.add_child(sprite)
	var label := _label(key, Vector3(0.0, -icon_size * 0.7, 0.0), label_pixel_size * minf(1.0, 20.0 / key.length()))
	label.name = "Label"
	root.add_child(label)
	return root


func _label(text: String, at: Vector3, pixel_size: float) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = pixel_size
	l.font_size = 48
	l.outline_size = 8
	l.position = at
	return l


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
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		wall.get_node(key).add_child(sprite)
		made += 1
	return made
