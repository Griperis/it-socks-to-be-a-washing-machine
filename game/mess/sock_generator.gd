## The Sock generator of a level (core/52, Q2518-Q2528): the SockAreas, SockExclusions and SockTrails
## under it say where a floor's starting Mess may land, and it lays it from a seed, deterministic, by
## rays and overlap tests (SockPlaces, SockLaying). Its `Generated` child (GeneratedSocks, the Part)
## turns the result into lying Socks of the Mess when the level starts and holds the seed that made
## them; only the Host's answer changes them after that (a regeneration).
##
## In the editor it draws a dot at every landing point the current seed makes, tinted by kind (Q2522),
## redrawn when an area, an exclusion, a trail or a number changes (or on "Refresh preview" after
## moving furniture). Nothing of the preview runs in a game build unless a shot asks (show_preview()).
@tool
class_name SockGenerator
extends Node3D

## The level's numbers (fitting, Mates, Heaps, thinning, strips).
@export var tuning: SockGeneratorTuning = preload("res://game/mess/sock_generator_tuning.tres"):
	set(value):
		tuning = value
		preview_later()
## The level's seed (Q2524): the same Mess every start, as the preview shows.
@export var seed := 1:
	set(value):
		seed = value
		preview_later()
## A new seed each New Game instead (Q2524), saved with the game (GeneratedSocks' state).
@export var new_seed_each_start := false
## The Collections its Designs come from (each its share, spread evenly); empty: every Collection.
@export var collections: Array[StringName] = []
## The washer marker the open floor and tops thin out from (Q2528); none: no thinning.
@export var washer: Node3D:
	set(value):
		washer = value
		preview_later()
## Where furniture, tops, insides and Cabinets are looked for (the level, or a station's root).
@export var scan: Node3D
## Draws the preview again (after furniture moved: its places are not watched).
@export_tool_button("Refresh preview") var refresh := preview_now

## The editor's dots (an internal child, never saved), and whether a redraw waits.
var _dots: MultiMeshInstance3D
var _pending := false
## The last laying's report, for the log and the tests: asked, laid and left out by area.
var last_report: Dictionary = {}


func _ready() -> void:
	if Engine.is_editor_hint():
		preview_later()


## The SockGenerator `node` is under (itself included), or null.
static func of(node: Node) -> SockGenerator:
	while node != null:
		if node is SockGenerator:
			return node as SockGenerator
		node = node.get_parent()
	return null


## Lays every area's Socks, then the trails', from `with_seed`, avoiding the boxes `before` ([size,
## middle's transform] each, the Socks already lying). Returns the laying (its rows and report).
func lay(with_seed: int, before: Array[Array] = []) -> SockLaying:
	var laying := SockLaying.new(tuning, self, before)
	var keep_out: Array[Array] = []
	var areas: Array[SockArea] = []
	var trails: Array[SockTrail] = []
	_collect(self, areas, trails, keep_out)
	var level := scan if scan != null else get_parent() as Node3D
	for area in areas:
		var places := SockPlaces.new(area, tuning, level if level != null else self, washer, keep_out)
		laying.set_spacing(area.rules.spacing)
		laying.lay_area(area, places, with_seed)
	laying.set_spacing(0.0)
	for trail in trails:
		laying.lay_trail(trail, with_seed, keep_out)
	last_report = {"asked": laying.asked, "laid": laying.rows.size(), "left_out": laying.left_out.duplicate(),
			"fails": laying.fails.duplicate(), "hidden_to_floor": laying.hidden_to_floor.duplicate()}
	return laying


## The Mess records of a laying from `with_seed` (Q2523, Q2525): {"designs": PackedInt32Array, "poses":
## PackedFloat32Array (Mess.POSE floats each), "kinds": PackedByteArray}, both Socks of a Pair about a
## Mate distance apart, every Pair a Design of `catalogue` (each Collection its share, spread evenly,
## repeating when the Pairs outnumber the Designs).
func records(with_seed: int, catalogue: DesignCatalogue, before: Array[Array] = []) -> Dictionary:
	var laying := lay(with_seed, before)
	var pairs := laying.pair_up(with_seed)
	var pool := _designs(catalogue)
	var designs := PackedInt32Array()
	var poses := PackedFloat32Array()
	var kinds := PackedByteArray()
	if pool.is_empty():
		return {"designs": designs, "poses": poses, "kinds": kinds}
	var order: Array[int] = []
	for k in pairs.size():
		order.append(_spread(k, pairs.size(), pool.size()))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([with_seed, "designs"])
	for k in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, k)
		var tmp := order[k]
		order[k] = order[j]
		order[j] = tmp
	# Each row's leg and foot at its Size, then a Heap's stacked Socks come down onto the real
	# Socks under them (core/55, Q2531). A row left out of the Pairs is not laid: nothing rests on it.
	var parts: Array[Array] = []
	for r in laying.rows.size():
		parts.append([])
	for k in pairs.size():
		var shape := MessBodies.parts_at(SockDress.scale_of(pool[order[k]]))
		parts[pairs[k].x] = shape
		parts[pairs[k].y] = shape
	laying.restack(parts)
	for k in pairs.size():
		var design := pool[order[k]]
		for row: int in [pairs[k].x, pairs[k].y]:
			var r: Dictionary = laying.rows[row]
			designs.append(design.id)
			# A smaller Sock keeps its place's middle: its box's bottom middle is the place's.
			poses.append_array(Mess.pack(r["pose"]))
			kinds.append(int(r["kind"]))
	if laying.left_out.size() > 0:
		Log.warn("mess", "Sock generator: %d of %d Socks found no place (%s)" % [laying.asked - laying.rows.size(), laying.asked, laying.left_out])
	return {"designs": designs, "poses": poses, "kinds": kinds}


## Pair `k` of `n`'s Design index among `m`: spread evenly through them, repeating past them.
static func _spread(k: int, n: int, m: int) -> int:
	if n > m:
		return k % m
	return mini(floori((k + 0.5) * m / float(n)), m - 1)


func _designs(catalogue: DesignCatalogue) -> Array[SockDesign]:
	var out: Array[SockDesign] = []
	if catalogue == null:
		return out
	for d in catalogue.designs:
		if d != null and (collections.is_empty() or collections.has(d.collection)):
			out.append(d)
	return out


func _collect(node: Node, areas: Array[SockArea], trails: Array[SockTrail], keep_out: Array[Array]) -> void:
	for child in node.get_children():
		if child is SockArea:
			areas.append(child as SockArea)
		elif child is SockTrail:
			trails.append(child as SockTrail)
		elif child is SockExclusion:
			keep_out.append((child as SockExclusion).box())
		_collect(child, areas, trails, keep_out)


## Shows the landing points (of `with_seed`, avoiding `before`) and the boxes in a running game (a
## shot of the preview), or hides them.
func show_preview(on: bool, with_seed: int, before: Array[Array] = []) -> void:
	_draw_preview(on, with_seed, before)
	for node in _descendants(self):
		if node is SockArea:
			(node as SockArea).show_box(on)
		elif node is SockExclusion:
			(node as SockExclusion).show_box(on)
		elif node is SockTrail:
			(node as SockTrail).show_line(on)


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out


## The editor: the preview is drawn again shortly (one redraw for a burst of changes).
func preview_later() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or _pending:
		return
	_pending = true
	get_tree().create_timer(0.2).timeout.connect(preview_now)


## Draws the preview now (the editor; the tool button).
func preview_now() -> void:
	_pending = false
	if is_inside_tree():
		_draw_preview(true, seed, [])


func _draw_preview(on: bool, with_seed: int, before: Array[Array]) -> void:
	if _dots != null:
		_dots.queue_free()
		_dots = null
	if not on:
		return
	var laying := lay(with_seed, before)
	_dots = SockPreview.dots(laying.rows, global_transform)
	add_child(_dots, false, INTERNAL_MODE_BACK)
