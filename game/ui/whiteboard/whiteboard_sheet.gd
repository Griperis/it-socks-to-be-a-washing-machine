## The Whiteboard's tallies, drawn as if in marker (the old whiteboard_sheet.gd): one row per player
## with their Pairs shelved, Socks picked and Coins earned this run (a column each, headed by its icon),
## and a Team row of the totals last after a divider. The same scene draws the board's face (in the
## board's SubViewport) and the Tab overlay, so both read alike. It follows the level's RunTallies
## itself and is drawn again only when what it would show changed. It draws in a fixed design space
## (BASE) scaled to its size.
class_name WhiteboardSheet
extends Control

## The design space every coordinate below is in; 4:3, like the board's face.
const BASE := Vector2(1024, 768)
const FONT := preload("res://assets/fonts/patrickhand/PatrickHand-Regular.ttf")
const INK := Color(0.13, 0.16, 0.3)
const RED := Color(0.78, 0.2, 0.18)
const BOARD := Color(0.96, 0.96, 0.94)
const ROW_H := 110.0
const TOP := 190.0
const LEFT := 36.0
## Where the tally columns start and end (x); the label column is before them.
const COL_FROM := 380.0
const COL_TO := 1000.0
## The columns, left to right: the key into a listing entry, its label and the icon that heads it.
const COLUMNS := [["pairs", "Pairs shelved", "pairs"], ["socks", "Socks picked", "sock"], ["coins", "Coins earned", "coins"]]

## The picture changed: a tally, a name or a column moved (the board draws its SubViewport again).
signal changed

## What the sheet shows now: RunTallies.listing().
var entries: Array[Dictionary] = []
## How many times the sheet was drawn again from a change (a case reads that nothing else does).
var redraws := 0

var _tallies: RunTallies = null


func _process(_delta: float) -> void:
	if _tallies != null and not is_instance_valid(_tallies):
		_tallies = null
	if _tallies == null:
		_tallies = get_tree().get_first_node_in_group(RunTallies.GROUP) as RunTallies
		if _tallies == null:
			return
		_tallies.changed.connect(refresh)
		refresh()


## Takes the tallies' listing; the picture is drawn again only when it differs from what is shown.
func refresh() -> void:
	if _tallies == null:
		return
	var now := _tallies.listing()
	if now == entries:
		return
	show_entries(now)


## Shows `now` (a listing) and tells the board.
func show_entries(now: Array[Dictionary]) -> void:
	entries = now
	redraws += 1
	queue_redraw()
	changed.emit()


## The team's total of tally `key`.
func team_total(key: String) -> int:
	var n := 0
	for e: Dictionary in entries:
		n += int(e[key])
	return n


func _draw() -> void:
	var s := minf(size.x / BASE.x, size.y / BASE.y)
	draw_set_transform((size - BASE * s) / 2.0, 0.0, Vector2(s, s))
	draw_rect(Rect2(Vector2.ZERO, BASE), BOARD)
	# Old marker ghosts, wiped but not quite.
	for k in 5:
		var at := Vector2(140 + 170 * k, 110 + (k * 137) % 560)
		_scribble([at, at + Vector2(90, 14), at + Vector2(150, -6)], Color(0.5, 0.52, 0.6, 0.07), 9.0, k)
	_text("This Run", Vector2(36, 70), 54, INK)
	_scribble([Vector2(34, 88), Vector2(260, 92), Vector2(470, 86)], RED, 4.0, 1)
	var n := entries.size() + 1  # the players, then the Team
	var row_h := minf(ROW_H, (BASE.y - TOP - 40.0) / n)
	var w := (COL_TO - COL_FROM) / COLUMNS.size()
	for c in COLUMNS.size():
		var tex := UiIcons.texture(String(COLUMNS[c][2]))
		if tex != null:
			draw_texture_rect(tex, Rect2(COL_FROM + w * c + w / 2.0 - 30, 104, 60, 60), false)
	for r in n:
		var team := r == entries.size()
		var e: Dictionary = {} if team else entries[r]
		var y := TOP + row_h * r
		var mid := y + row_h / 2.0
		var colour: Color = INK if team else (e["colour"] as Color).darkened(0.2)
		var fs := 44 if row_h >= 90.0 else 34
		_text_fit("Team" if team else String(e["name"]), Vector2(LEFT, mid + fs * 0.35), fs, COL_FROM - LEFT - 20.0, colour)
		for c in COLUMNS.size():
			var key := String(COLUMNS[c][0])
			var v := team_total(key) if team else int(e[key])
			_centred(str(v), Vector2(COL_FROM + w * c + w / 2.0, mid + 20), 56, w - 10.0, INK)
		if r < n - 1:
			var last := r == n - 2
			_scribble([Vector2(LEFT, y + row_h - 2), Vector2(COL_TO, y + row_h - 4)], Color(INK, 0.5 if last else 0.18),
					4.0 if last else 2.0, int(y))


## `text` left-aligned at `at` with its font size shrunk (down to 16) until it fits `max_w`.
func _text_fit(text: String, at: Vector2, font_size: int, max_w: float, colour: Color) -> void:
	var fs := font_size
	while fs > 16 and FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		fs -= 2
	_text(text, at, fs, colour)


## `text` centred on `at.x` with its baseline at `at.y`, shrunk (down to 16) until it fits `max_w`.
func _centred(text: String, at: Vector2, font_size: int, max_w: float, colour: Color) -> void:
	var fs := font_size
	var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	while tw > max_w and fs > 16:
		fs -= 2
		tw = FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(text, Vector2(at.x - tw / 2.0, at.y), fs, colour)


## Text in marker: thick strokes (an outline in the same colour), so it reads from across the room.
func _text(text: String, at: Vector2, font_size: int, colour: Color) -> void:
	draw_string_outline(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, font_size / 12), colour)
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


## A marker stroke through `pts`, a little wobbly (the same wobble every time: seeded).
func _scribble(pts: Array, colour: Color, width: float, seed_k: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (seed_k + 1)
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := maxi(2, int(a.distance_to(b) / 40.0))
		var side := (b - a).orthogonal().normalized()
		for k in n:
			var t := float(k) / n
			out.append(a.lerp(b, t) + side * rng.randf_range(-1.6, 1.6))
	out.append(pts[pts.size() - 1])
	draw_polyline(out, colour, width, true)
