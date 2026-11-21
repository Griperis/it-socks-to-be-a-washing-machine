## The Materials station's board (assets/04 F01, Q2337): every material of the shared library
## (res://game/materials/) on a sphere, built from the folder when the node enters the tree, so a new
## .tres appears with no other change. First a row per candidate group (candidates/<name>/: one name the
## old game used with several sets of values, for the designer to pick the one that stays, Q2177), then
## the single materials in rows. Under each swatch: its file, the old pieces that used it, its roughness
## and metallic. Rows run along +X from the board's origin, the next row lower, blocks of rows side by side.
class_name MaterialBoard
extends Node3D

## The shared material library; its candidate groups are the folders of its CANDIDATES subfolder.
const LIBRARY := "res://game/materials"
const CANDIDATES := "candidates"
## The row name of the single materials' rows: "singles_<n>".
const SINGLES := "singles"
const SWATCH := preload("res://game/zoo/materials/swatch.tscn")
const LABEL := preload("res://game/zoo/zoo_label.tscn")

@export var layout: MaterialBoardLayout
## The folder shown: the library (another only in a test).
@export_dir var library := LIBRARY

var _built := false


func _enter_tree() -> void:
	if _built or layout == null:
		return
	_built = true
	build()


## The candidate groups of `folder`, sorted: each a folder of its candidates/.
static func groups(folder := LIBRARY) -> Array[String]:
	var out: Array[String] = []
	for d: String in ResourceLoader.list_directory(folder.path_join(CANDIDATES)):
		if d.ends_with("/"):
			out.append(d.trim_suffix("/"))
	out.sort()
	return out


## The material files of `folder` (res:// paths of its .tres), sorted.
static func files_in(folder: String) -> Array[String]:
	var out: Array[String] = []
	for f: String in ResourceLoader.list_directory(folder):
		if f.ends_with(".tres"):
			out.append(folder.path_join(f))
	out.sort()
	return out


## Every material file of the library `folder`, candidates first: what the board shows.
static func all_files(folder := LIBRARY) -> Array[String]:
	var out: Array[String] = []
	for g in groups(folder):
		out.append_array(files_in(folder.path_join(CANDIDATES).path_join(g)))
	out.append_array(files_in(folder))
	return out


## The row named `row` ("oak", "singles_1"), or null.
func row(row_name: String) -> Node3D:
	return get_node_or_null(NodePath("Row_%s" % row_name)) as Node3D


## The swatch of material file `stem` ("oak_1", "rubber"), or null.
func swatch(stem: String) -> MeshInstance3D:
	for r in get_children():
		var s := r.get_node_or_null(NodePath(stem)) as MeshInstance3D
		if s != null:
			return s
	return null


func build() -> void:
	var rows: Array[Array] = []   # [row name, files]
	for g in groups(library):
		rows.append([g, files_in(library.path_join(CANDIDATES).path_join(g))])
	var singles := files_in(library)
	var n := 1
	while not singles.is_empty():
		rows.append(["%s_%d" % [SINGLES, n], singles.slice(0, layout.per_row)])
		singles = singles.slice(layout.per_row)
		n += 1
	for i in rows.size():
		@warning_ignore("integer_division")
		var at := Vector3((i / layout.rows_per_block) * layout.block_pitch, layout.top - (i % layout.rows_per_block) * layout.row_pitch, 0.0)
		add_child(_row(rows[i][0], rows[i][1], at))


func _row(row_name: String, files: Array, at: Vector3) -> Node3D:
	var r := Node3D.new()
	r.name = "Row_%s" % row_name
	r.position = at
	var title := LABEL.instantiate() as Label3D
	title.name = "Name"
	title.text = row_name.replace("_", " ") if not row_name.begins_with(SINGLES) else ""
	# Standing on the board as the swatches' names do (swatch.tscn's Label).
	title.transform = Transform3D(Basis.IDENTITY, Vector3(layout.name_width - layout.pitch, 0.0, 0.0))
	title.double_sided = true
	title.modulate = Color(0.96, 0.96, 0.94)
	title.font_size = 64
	title.outline_size = 0
	title.pixel_size = layout.name_pixel_size
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_child(title)
	for k in files.size():
		r.add_child(_swatch(files[k], Vector3(layout.name_width + k * layout.pitch, 0.0, 0.0)))
	return r


## A material's swatch (swatch.tscn): its sphere, and its name and numbers under it.
func _swatch(path: String, at: Vector3) -> MeshInstance3D:
	var mat := load(path) as StandardMaterial3D
	var s := SWATCH.instantiate() as MeshInstance3D
	s.name = path.get_file().get_basename()
	s.position = at
	var sphere := SphereMesh.new()
	sphere.radius = layout.swatch_size / 2.0
	sphere.height = layout.swatch_size
	s.mesh = sphere
	s.material_override = mat
	s.set_meta(&"file", path)
	var pieces: PackedStringArray = mat.get_meta(&"old_pieces", PackedStringArray()) if mat != null else PackedStringArray()
	var lines := [s.name]
	if mat != null:
		lines.append("%d piece%s" % [pieces.size(), "" if pieces.size() == 1 else "s"] if pieces != PackedStringArray(["house kit"]) else "house kit")
		lines.append("rough %.2f" % mat.roughness)
		lines.append("metal %.2f" % mat.metallic)
	var label := s.get_node(^"Label") as Label3D
	label.text = "\n".join(lines)
	label.pixel_size = layout.label_pixel_size
	label.position = Vector3(0.0, -layout.swatch_size * 0.6, 0.0)
	return s
