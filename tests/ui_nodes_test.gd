## UI authored in nodes (core/111, the designer's Q2658): no script of the game builds a Label, a TextureRect, a box
## container, a Panel, a ColorRect or a StyleBoxFlat with `.new()` (the zoo and the keycap StyleBox class are the
## exceptions); the pieces are scenes and Theme variations. One real-path case: the Who page opened on names shows one
## name row scene each, in the Theme's look, and its close key closes it.
extends TestSuite

const FORBIDDEN: Array[String] = [
	"Label.new()", "TextureRect.new()", "HBoxContainer.new()", "VBoxContainer.new()", "PanelContainer.new()",
	"ColorRect.new()", "Panel.new()", "StyleBoxFlat.new()",
]
const EXEMPT_PREFIX := "res://game/zoo/"
const EXEMPT_FILE := "res://game/look/keycap_style.gd"


func cases() -> Array[Dictionary]:
	return [
		{"name": "no_built_in_code", "method": "case_no_built_in_code", "world": false,
				"title": "no script of game/ (outside the zoo and keycap_style.gd) makes a Label, TextureRect, box container, Panel, ColorRect or StyleBoxFlat with .new()"},
		{"name": "who_page_real_path", "method": "case_who_page", "world": false,
				"title": "real path: the Who page opened on three names shows three name rows in the WhoName look, and pressing its close key closes it"},
	]


func case_no_built_in_code() -> void:
	var hits: Array[String] = []
	_scan("res://game", hits)
	_check(hits.is_empty(), "UI built in code: %s" % ", ".join(hits))


func _scan(dir: String, hits: Array[String]) -> void:
	if dir.begins_with(EXEMPT_PREFIX.trim_suffix("/")):
		return
	for sub in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(sub), hits)
	for file in DirAccess.get_files_at(dir):
		var path := dir.path_join(file)
		if not file.ends_with(".gd") or path == EXEMPT_FILE:
			continue
		var n := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			n += 1
			var code := line.split("#")[0]
			for word in FORBIDDEN:
				if code.contains(word):
					hits.append("%s:%d" % [path, n])


func case_who_page() -> void:
	var page := (load("res://game/lobby/who_page.tscn") as PackedScene).instantiate() as WhoPage
	add_child(page)
	await _frames(2)
	var closed := [false]
	page.closed.connect(func() -> void: closed[0] = true)
	page.open("Sunday", PackedStringArray(["Ada", "Mia", "Zoltan"]))
	await _frames(2)
	_same(page.shown_names(), PackedStringArray(["Ada", "Mia", "Zoltan"]), "the names as shown")
	var names := page.get_node("%Names") as Control
	for row in names.get_children():
		_check((row as Label).theme_type_variation == &"WhoName", "a name row in the WhoName look")
	(page.get_node("%Close") as CloseButton).key().pressed.emit()
	await _frames(1)
	_check(closed[0] and not page.visible, "the close key closed the page")
	page.free()
