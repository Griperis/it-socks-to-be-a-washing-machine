## The shared material library (assets/04 F01): one StandardMaterial3D .tres per material of the old
## furniture in game/materials/, the names the old game used with several sets of values as candidates
## for the designer's pick (Q2177), and the zoo's Materials station, whose board is built from the folder
## at load (Q2337). The real path: the player walks up to the board and sees the candidates on it.
extends TestSuite

const STATION := "res://game/zoo/stations/materials.tscn"
const LAYOUT := "res://game/zoo/material_board_layout.tres"
const PLAYER := "res://game/player/player.tscn"
## The old furniture's material names (54, `tools/materials_from_old.py`): each is one file of the
## library or one candidate group.
const OLD_NAMES := 54
## The picks (Q2389): in each group the set the most old pieces used, on a tie the one nearest the
## group's median roughness: [name, roughness, metallic] of a few (docs/architecture/materials.md).
const PICKS := [["oak", 0.6, 0.0], ["charcoal", 0.6, 0.0], ["pad", 0.7, 0.0], ["brass", 0.3, 0.8], ["sky", 0.4, 0.0]]
const TEMP := "user://materials_test"

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Materials station the player walks up to the board, is stopped by it and sees a row of materials on it, each wearing the library's file"},
		{"name": "f01_library", "method": "case_f01_library", "world": false,
				"title": "F01 (Q2389): every old furniture material is one library file, the picked set where the old game had several, each a StandardMaterial3D with its uid, its name and the old pieces that used it"},
		{"name": "f01_station", "method": "case_f01_station", "world": false,
				"title": "F01: the Materials station's board shows every library file once, a named row per candidate group, each swatch labelled with its file and its old pieces, all on the board"},
		{"name": "f01_from_data", "method": "case_f01_from_data", "world": false,
				"title": "F01 (Q2337): a new material file or candidate group in the library appears on the board with no other change"},
	]


func _before_case() -> void:
	Input.action_release(&"move_forward")
	if _level != null:
		_level.free()
		_level = null


func _station() -> Node3D:
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	station.name = "Materials"
	return station


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position = Vector3(8, -0.1, 4)
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	var station := _station()
	_level.add_child(station)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	await _frames(1)
	var board := station.get_node("Board") as MaterialBoard
	# Before a low row, facing the board (-Z).
	var target := board.swatch("terracotta")
	_check(target != null, "the board has terracotta")
	if target == null:
		return
	var row_x := 0.0
	var swatches := 0
	for s: Node in target.get_parent().get_children():
		if s is MeshInstance3D:
			row_x += board.to_local((s as Node3D).global_position).x
			swatches += 1
	var front := Vector3(row_x / swatches - 0.5, 0.0, 0.0)   # before the row's middle
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	player.position = board.to_global(Vector3(front.x + 0.5, 0.0, 6.0))
	player.rotation.y = 0.0
	_level.add_child(player)
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	var local := func() -> Vector3: return board.to_local(player.global_position)
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return (local.call() as Vector3).z < 2.2, "the player to walk up to the board")
	_check(board.to_local(player.camera().global_position).z > 1.0, "the player still stands back from the board")
	var cam := player.camera()
	_check(cam.is_position_in_frustum(target.global_position), "terracotta is in the player's view")
	var row := target.get_parent()
	for s: Node in row.get_children():
		if s is MeshInstance3D:
			_check(cam.is_position_in_frustum((s as Node3D).global_position), "%s is in the player's view" % s.name)
	_check(target.material_override == load(String(target.get_meta(&"file", ""))) and target.material_override != null, "it wears the library's material")
	# On into the board: it stops the player.
	var last := (local.call() as Vector3).z
	var still := 0
	while still < 15:
		await _physics_ticks(1)
		var z := (local.call() as Vector3).z
		still = still + 1 if absf(z - last) < 0.0005 else 0
		last = z
	Input.action_release(&"move_forward")
	_check(last > -0.25 and last < 0.6, "the board stops the player in front of it (z %s)" % last)


# --- F01 -----------------------------------------------------------------------------------------

func case_f01_library() -> void:
	var names: Array[String] = []
	var groups := MaterialBoard.groups()
	for g in groups:
		var files := MaterialBoard.files_in(MaterialBoard.LIBRARY.path_join(MaterialBoard.CANDIDATES).path_join(g))
		_check(files.size() >= 2, "the candidate group %s has two or more candidates (%d)" % [g, files.size()])
		for f in files:
			_check(f.get_file().get_basename().begins_with(g + "_"), "%s is named after its group" % f)
			_material(f, g)
		names.append(g)
	for f in MaterialBoard.files_in(MaterialBoard.LIBRARY):
		var n := f.get_file().get_basename()
		_check(not groups.has(n), "%s is a library file or a candidate group, not both" % n)
		_material(f, n)
		names.append(n)
	_check(names.size() == OLD_NAMES, "the library holds every old furniture material (%d of %d)" % [names.size(), OLD_NAMES])
	_check(groups.is_empty(), "every group is picked: no candidates are left (%s)" % [groups])
	for pick: Array in PICKS:
		var mat := load("%s/%s.tres" % [MaterialBoard.LIBRARY, pick[0]]) as StandardMaterial3D
		_check(mat != null and is_equal_approx(mat.roughness, pick[1]) and is_equal_approx(mat.metallic, pick[2]),
				"%s is the picked set (roughness %s, metallic %s)" % [pick[0], pick[1], pick[2]])


func _material(path: String, material_name: String) -> void:
	var mat := load(path) as StandardMaterial3D
	_check(mat != null, "%s is a StandardMaterial3D" % path)
	if mat == null:
		return
	_check(mat.resource_name == material_name, "%s is named %s (%s)" % [path, material_name, mat.resource_name])
	_check(ResourceLoader.get_resource_uid(path) != ResourceUID.INVALID_ID, "%s has its uid" % path)
	var pieces: PackedStringArray = mat.get_meta(&"old_pieces", PackedStringArray())
	_check(not pieces.is_empty(), "%s names the old pieces that used it" % path)


func case_f01_station() -> void:
	_level = _station()
	add_child(_level)
	await _frames(1)
	var board := _level.get_node("Board") as MaterialBoard
	var back := _level.get_node("Back") as Node3D
	var mesh := (back.get_node("Mesh") as MeshInstance3D)
	var panel := mesh.global_transform * mesh.get_aabb()
	var files := MaterialBoard.all_files()
	var shown := 0
	for r: Node in board.get_children():
		for s: Node in r.get_children():
			if s is MeshInstance3D:
				shown += 1
	_check(shown == files.size(), "the board shows every library file once (%d of %d)" % [shown, files.size()])
	for f in files:
		var stem := f.get_file().get_basename()
		var s := board.swatch(stem)
		_check(s != null, "the board shows %s" % stem)
		if s == null:
			continue
		_check(s.material_override == load(f), "%s wears its file's material" % stem)
		_check(s.get_meta(&"file", "") == f, "%s names its file" % stem)
		var pieces: PackedStringArray = (load(f) as Material).get_meta(&"old_pieces", PackedStringArray())
		var label := s.get_node("Label") as Label3D
		_check(label.text.begins_with(stem) and (label.text.contains("%d piece" % pieces.size()) or label.text.contains("house kit")),
				"%s is labelled with its file and its old pieces (%s)" % [stem, label.text.replace("\n", " / ")])
		var at := s.global_position
		_check(at.x > panel.position.x and at.x < panel.end.x and at.y > panel.position.y and at.y < panel.end.y,
				"%s hangs on the board (%s)" % [stem, at])
		_check(at.z > panel.end.z, "%s hangs in front of it" % stem)
	for g in MaterialBoard.groups():
		var r := board.row(g)
		_check(r != null and (r.get_node("Name") as Label3D).text == g.replace("_", " "), "the group %s has its named row" % g)


func case_f01_from_data() -> void:
	_remove_temp()
	DirAccess.make_dir_recursive_absolute(TEMP.path_join(MaterialBoard.CANDIDATES).path_join("brand_new"))
	for stem: String in ["rubber", "soil"]:
		ResourceSaver.save(load(MaterialBoard.LIBRARY.path_join(stem + ".tres")), TEMP.path_join(stem + ".tres"))
	var fresh := StandardMaterial3D.new()
	fresh.resource_name = "fresh"
	fresh.set_meta(&"old_pieces", PackedStringArray(["test"]))
	ResourceSaver.save(fresh, TEMP.path_join("fresh.tres"))
	for k in 2:
		var cand := StandardMaterial3D.new()
		cand.resource_name = "brand_new"
		cand.roughness = 0.2 + k * 0.5
		ResourceSaver.save(cand, TEMP.path_join(MaterialBoard.CANDIDATES).path_join("brand_new").path_join("brand_new_%d.tres" % (k + 1)))
	_level = Node3D.new()
	var board := MaterialBoard.new()
	board.name = "Board"
	board.layout = load(LAYOUT) as MaterialBoardLayout
	board.library = TEMP
	_level.add_child(board)
	add_child(_level)
	await _frames(1)
	_check(board.swatch("fresh") != null, "the new material file has a swatch")
	_check(board.swatch("rubber") != null and board.swatch("soil") != null, "beside the others")
	var row := board.row("brand_new")
	_check(row != null, "the new candidate group has its row")
	if row != null:
		_check(row.get_node_or_null("brand_new_1") != null and row.get_node_or_null("brand_new_2") != null, "with both its candidates")
		_check(is_equal_approx((row.get_node("brand_new_2") as MeshInstance3D).material_override.get(&"roughness"), 0.7), "each wearing its own file")
	_check(board.row("singles_1") != null and row != null and board.row("singles_1").position.y < row.position.y, "the single materials come after the groups")
	_level.free()
	_level = null
	_remove_temp()


func _remove_temp() -> void:
	for path: String in [TEMP.path_join(MaterialBoard.CANDIDATES).path_join("brand_new"), TEMP.path_join(MaterialBoard.CANDIDATES), TEMP]:
		var dir := DirAccess.open(path)
		if dir == null:
			continue
		for f in dir.get_files():
			dir.remove(f)
		DirAccess.remove_absolute(path)
