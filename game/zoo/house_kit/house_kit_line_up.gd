## The House kit station's line-up (house/02, K13): every piece in the kit's folder, labelled,
## built when the station loads (Q2337: a new piece shows with no other change). Rows by family,
## each piece on the grid with the grid's step between neighbours, so no two touch (K14). Flat
## pieces stand half a metre up, off the zoo floor's plane.
class_name HouseKitLineUp
extends Node3D

const PIECES := "res://game/house/kit/pieces"
const LABEL := preload("res://game/zoo/zoo_label.tscn")
## The families, a row (or more) each, in this order; a piece goes in the first family it starts with.
const FAMILIES: Array[String] = ["wall_", "corner_", "t_", "knee_", "door_", "window_", "floor_", "ceiling_",
		"stair", "landing", "roof_", "dormer", "gable_"]
## Pieces lifted off the zoo floor: their faces would lie in its plane.
const LIFTED: Array[String] = ["floor_", "ceiling_"]

## How wide a row may run, in metres, along +X from this node.
@export_range(5.0, 60.0, 0.5, "suffix:m") var row_width := 25.5
## The step between pieces and rows (the kit's grid).
@export_range(0.25, 1.0, 0.25, "suffix:m") var step := 0.5


func _ready() -> void:
	build()


## Fills the line-up.
func build() -> void:
	var files := Array(ResourceLoader.list_directory(PIECES)).filter(func(f: String) -> bool: return f.ends_with(".tscn"))
	files.sort()
	var by_family := {}
	for file: String in files:
		var family := FAMILIES.size()
		for i in FAMILIES.size():
			if file.begins_with(FAMILIES[i]):
				family = i
				break
		if not by_family.has(family):
			by_family[family] = []
		(by_family[family] as Array).append(file)
	var z := 0.0
	var families := by_family.keys()
	families.sort()
	for family: int in families:
		var x := 0.0
		var depth := 0.0
		for file: String in by_family[family]:
			var piece := (load(PIECES.path_join(file)) as PackedScene).instantiate() as MeshInstance3D
			var box := piece.mesh.get_aabb()
			if x > 0.0 and x + box.end.x - _snap_down(box.position.x) > row_width:
				z += _snap_up(depth) + step
				x = 0.0
				depth = 0.0
			var lift := 0.0
			for prefix in LIFTED:
				if file.begins_with(prefix):
					lift = step
			piece.position = Vector3(x - _snap_down(box.position.x), lift, z - _snap_down(box.position.z))
			piece.name = file.get_basename().to_pascal_case()
			add_child(piece)
			var label := LABEL.instantiate() as Label3D
			label.name = piece.name + "Label"
			label.text = file.get_basename()
			label.pixel_size = 0.004
			# Over its piece, turned to the camera.
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.transform = Transform3D(Basis.IDENTITY,
					piece.position + Vector3(box.get_center().x, box.end.y + 0.3, box.get_center().z))
			label.double_sided = true
			label.modulate = Color.WHITE
			add_child(label)
			x += _snap_up(box.end.x - _snap_down(box.position.x)) + step
			depth = maxf(depth, box.end.z - _snap_down(box.position.z))
		z += _snap_up(depth) + step


func _snap_up(v: float) -> float:
	return ceilf(v / step - 0.001) * step


func _snap_down(v: float) -> float:
	return floorf(v / step + 0.001) * step
