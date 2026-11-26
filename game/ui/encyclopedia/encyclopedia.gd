## The Sock encyclopedia's pages (core/136, the old EncyclopediaView, Q1153, Q1161, Q1163): one page per
## Collection the profile has unlocked and that is not held back (the Lost Socks wait for the Drum, Q2675),
## in catalogue order, 50 Designs a page (a bigger Collection takes several), sorted small, medium, large,
## then catalogue order. A Design the profile holds is drawn as its Sock (fitted to FIT metres, PPM pixels a
## metre) behind its cell; the others as a silhouette named "???". `Prev` and `Next` wrap round; Esc or the
## close key shuts it. Set `profile` before it enters the tree. The look is the scene's; code fills the cells.
class_name EncyclopediaPage
extends Control

signal closed

const CELL := preload("res://game/ui/encyclopedia/encyclopedia_cell.tscn")
const CATALOGUE := preload("res://game/sock/designs.tres")
const SILHOUETTE := preload("res://game/ui/encyclopedia/silhouette.tres")
const PER_PAGE := 50
## Pixels a metre of the Sock stage is, and the metres a Sock is fitted to across.
const PPM := 400.0
const FIT := 0.34

## Whose encyclopedia it shows (its `designs` and unlocked `collections`).
var profile: PlayerProfile = null
## The page on show: an index into pages().
var page := 0

var _pages: Array[Dictionary] = []
var _cells_made: Array[EncyclopediaCell] = []

@onready var _prev: Button = %Prev
@onready var _next: Button = %Next
@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _count: Label = %Count
@onready var _cells: GridContainer = %Cells
@onready var _stage: SubViewport = %SockStage
@onready var _socks: Node3D = %Socks
@onready var _close: CloseButton = %Close


func _ready() -> void:
	_close.pressed.connect(close)
	_prev.pressed.connect(step.bind(-1))
	_next.pressed.connect(step.bind(1))
	_pages = _make_pages()
	show_page(0)
	_next.grab_focus()


## The pages in order: {"collection": SockCollection, "chunk", "chunks"}.
func pages() -> Array[Dictionary]:
	return _pages


## Collection `id`'s Designs, small first, then medium, then large; inside a Size, the catalogue's order.
static func sorted_designs(id: StringName) -> Array[SockDesign]:
	var out: Array[SockDesign] = []
	for size: SockDesign.Size in [SockDesign.Size.SMALL, SockDesign.Size.MEDIUM, SockDesign.Size.LARGE]:
		for d in CATALOGUE.designs:
			if d != null and d.collection == id and d.size == size:
				out.append(d)
	return out


## How many of Collection `id`'s Designs the profile holds.
func collected(id: StringName) -> int:
	var n := 0
	for d in CATALOGUE.designs:
		if d != null and d.collection == id and profile.designs.has(d.id):
			n += 1
	return n


## The heading, "Simple (1/3)", or just the name on a Collection of one page.
func title_text() -> String:
	if _pages.is_empty():
		return ""
	var p := _pages[page]
	var c: SockCollection = p["collection"]
	return c.name if int(p["chunks"]) == 1 else "%s (%d/%d)" % [c.name, int(p["chunk"]) + 1, int(p["chunks"])]


## The count, "37 / 130".
func count_text() -> String:
	if _pages.is_empty():
		return ""
	var id: StringName = (_pages[page]["collection"] as SockCollection).id
	return "%d / %d" % [collected(id), CATALOGUE.count_of(id)]


## One page on, or back with a negative `dir`, wrapping round.
func step(dir: int) -> void:
	if not _pages.is_empty():
		show_page(posmod(page + dir, _pages.size()))


func show_page(i: int) -> void:
	if _pages.is_empty():
		return
	page = clampi(i, 0, _pages.size() - 1)
	var p := _pages[page]
	var c: SockCollection = p["collection"]
	_title.text = title_text()
	_count.text = count_text()
	_icon.texture = c.icon
	_fill_page(c, int(p["chunk"]))


## The cells of the page on show, in order.
func cells() -> Array[EncyclopediaCell]:
	return _cells_made


func close() -> void:
	closed.emit()
	queue_free()


func _make_pages() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in Collections.shown():
		if profile != null and not profile.collections.has(c.id):
			continue
		var chunks := maxi(1, ceili(CATALOGUE.count_of(c.id) / float(PER_PAGE)))
		for k in chunks:
			out.append({"collection": c, "chunk": k, "chunks": chunks})
	return out


func _fill_page(c: SockCollection, chunk: int) -> void:
	for n in _cells.get_children():
		_cells.remove_child(n)
		n.queue_free()
	for n in _socks.get_children():
		_socks.remove_child(n)
		n.queue_free()
	_cells_made.clear()
	var designs := sorted_designs(c.id)
	var from := chunk * PER_PAGE
	var view := Vector2(_stage.size)
	for k in mini(PER_PAGE, designs.size() - from):
		var d := designs[from + k]
		var held := profile.designs.has(d.id)
		var cell := CELL.instantiate() as EncyclopediaCell
		_cells.add_child(cell)
		cell.fill(d, held)
		_cells_made.append(cell)
		var at := Vector2(k % _cells.columns, k / _cells.columns) * cell.custom_minimum_size + cell.sock_centre()
		_put_sock(d, held, (at - view * 0.5) / PPM)


## The Design's Sock lying flat in the stage at `at` (metres from the middle), fitted to FIT across.
func _put_sock(d: SockDesign, held: bool, at: Vector2) -> void:
	var looks := SockLook.scene(d).instantiate() as Node3D
	_socks.add_child(looks)
	if held:
		SockLook.paint(looks, d)
	else:
		for m in looks.find_children("*", "MeshInstance3D", true, false):
			if not m.is_in_group(Outline.COPY):
				(m as MeshInstance3D).material_override = SILHOUETTE
	SockDress.play(looks, SockDress.LYING)
	var box := _footprint(looks)
	var fit := minf(1.0, FIT / maxf(maxf(box.size.x, box.size.z), 0.01))
	looks.scale = Vector3.ONE * fit
	var centre := box.get_center()
	looks.position = Vector3(at.x - centre.x * fit, 0.0, at.y - centre.z * fit)


## The box of the Looks' visible meshes in the Looks' own space.
func _footprint(looks: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var back := looks.global_transform.affine_inverse()
	for n in looks.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		if m.mesh == null or not m.visible or m.is_in_group(Outline.COPY) or m.visibility_range_begin > 0.0:
			continue
		var a := (back * m.global_transform) * m.mesh.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
