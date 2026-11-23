## The landing places a SockArea finds under it (core/52, Q2518, Q2519, Q2527, Q2528): open floor cells,
## furniture tops (a piece's `Spots/Top<n>`), insides (an opening's `Inside` and its shelves), the gap
## under a piece (its `crawl_gap`, in strips along the edges that face open floor), and the boxes no
## Sock may touch (SockExclusions, the clear box in front of every Cabinet). Read from the level's nodes
## and the physics space, the same in the editor and in the game.
##
## A place is {"kind": SockArea.Kind, "space": Transform3D (its surface at y = 0), "rect": Rect2 (in
## that space's x/z), "from": the height its rays start at, "along": -1 for any turn, else the turn
## (radians, about up) a Sock lies along, "weight": its size times its kind's weight, "piece": the
## furniture piece or null}.
@tool
class_name SockPlaces
extends RefCounted

## How far a floor ray starts over the floor (under a table, over a rug), and how far under it it looks.
const FLOOR_RAY := 0.6
const RAY_DOWN := 0.5
## A surface is flat when its normal's up part is over this.
const FLAT := 0.95
## A Sock under furniture keeps this far in from the gap's edges (old SockLayout: 0.06).
const UNDER_INSET := 0.06
## An inside's places keep this far in from its walls (old SockLayout: 0.01).
const INSIDE_INSET := 0.01

var area: SockArea
var tuning: SockGeneratorTuning
## Where furniture is looked for (the generator's level).
var scan: Node
## The washer marker the open floor and tops thin out from, or null.
var washer: Node3D
## Every place found: open floor first, then the hidden and the top ones.
var floor_places: Array[Dictionary] = []
var top_places: Array[Dictionary] = []
var hidden_places: Array[Dictionary] = []
## Each open floor cell's place by its cell (x, z) in the area's grid.
var cells: Dictionary[Vector2i, Dictionary] = {}
## The boxes no Sock may touch: [size, middle's transform] each.
var keep_out: Array[Array] = []

var _probe := BoxShape3D.new()
## The finding so far (step()): the level's nodes, the area's grid, the next floor cell and the next
## node looked at for tops, insides and under-gaps.
var _nodes: Array[Node] = []
var _nx := 1
var _nz := 1
var _cell := 0
var _node := 0


## Finds every place at once, or with `at_once` false only gets ready for step() (house/09: a level
## may lay its Socks a slice per frame). Either way the places come out the same, in the same order.
func _init(of_area: SockArea, with: SockGeneratorTuning, in_level: Node, from_washer: Node3D, exclusions: Array[Array], at_once := true) -> void:
	area = of_area
	tuning = with
	scan = in_level
	washer = from_washer
	keep_out = exclusions.duplicate()
	_walk(scan, _nodes)
	for node in _nodes:
		if node is Cabinet:
			_cabinet_zone(node as Cabinet)
	_nx = maxi(1, floori(area.size.x / tuning.floor_grid))
	_nz = maxi(1, floori(area.size.z / tuning.floor_grid))
	if at_once:
		step(null)


## Finds places, the floor cells first, then the furniture's, while `clock` has room for one more
## (null: no limit). Returns whether all are found.
func step(clock: SliceClock) -> bool:
	while _cell < _nx * _nz:
		if not SliceClock.fits(clock, &"cell"):
			return false
		_try_cell(_cell / _nz, _cell % _nz)
		_cell += 1
	while _node < _nodes.size():
		var node: Object = _nodes[_node]
		# A node made and gone meanwhile (a slice per frame: a toast, a body) is no place.
		if is_instance_valid(node):
			if not SliceClock.fits(clock, &"node"):
				return false
			_look_at(node as Node)
		_node += 1
	return true


func _look_at(node: Node) -> void:
	if node is Area3D and String(node.name).begins_with("Top") and node.get_parent() != null and node.get_parent().name == &"Spots":
		_add_top(node as Area3D)
	elif node is Area3D and node.name == &"Inside" and node.has_meta(&"shelves_y"):
		_add_inside(node as Area3D)
	elif node is Node3D and float(node.get_meta(&"crawl_gap", 0.0)) > 0.0 and node.has_meta(&"footprint"):
		_add_under(node as Node3D)


## The level's furniture piece `node` belongs to (the nearest node up with a `footprint`), or null.
static func piece_of(node: Node) -> Node3D:
	while node != null:
		if node is Node3D and node.has_meta(&"footprint"):
			return node as Node3D
		node = node.get_parent()
	return null


## Whether level point `p` (on a floor) is open floor for this area: a flat surface near its bottom face,
## `wall` clear of anything of the house that is not furniture, `furniture` clear of furniture, with the
## rules' headroom over it. `p.y` is ignored: the ray finds the floor. Returns the floor's height, or NAN.
func floor_at(p: Vector3, wall: float, furniture: float) -> float:
	var up := area.global_basis.y
	var bottom := area.global_position.y
	var hit := PhysicsQueries.ray(area, Vector3(p.x, bottom + area.size.y, p.z), Vector3(p.x, bottom - 0.05, p.z), Mess.LAYER_HOUSE)
	if hit.is_empty() or (hit["normal"] as Vector3).y < FLAT:
		return NAN
	var y := (hit["position"] as Vector3).y
	if absf(y - bottom) > area.rules.floor_band:
		return NAN
	var head := area.rules.headroom
	var centre := Transform3D(area.global_basis, Vector3(p.x, y + 0.05 + head * 0.5, p.z))
	_probe.size = Vector3(furniture * 2.0 + 0.01, head, furniture * 2.0 + 0.01)
	if not PhysicsQueries.overlap_colliders(area, _probe, centre, Mess.LAYER_HOUSE, 1).is_empty():
		return NAN
	_probe.size = Vector3(wall * 2.0 + 0.01, head, wall * 2.0 + 0.01)
	for collider in PhysicsQueries.overlap_colliders(area, _probe, centre, Mess.LAYER_HOUSE, 16):
		if not _is_furniture(collider as Node):
			return NAN
	return y if up.y > 0.0 else NAN


## How thick Socks lie at `p` (Q2528): thinning out with the distance from the washer marker.
func fade(p: Vector3) -> float:
	if washer == null or not washer.is_inside_tree():
		return 1.0
	return maxf(tuning.fade_floor, exp(-p.distance_to(washer.global_position) / tuning.fade_falloff))


func _walk(node: Node, into: Array[Node]) -> void:
	into.append(node)
	for child in node.get_children():
		_walk(child, into)


func _is_furniture(node: Node) -> bool:
	if piece_of(node) != null:
		return true
	return node != null and node.get_children().any(func(c: Node) -> bool: return c is Cabinet)


## Grid cell (i, k)'s middle of the area tried once for open floor (every cell, i then k).
func _try_cell(i: int, k: int) -> void:
	var g := tuning.floor_grid
	var x0 := -_nx * g * 0.5
	var z0 := -_nz * g * 0.5
	var local := Vector3(x0 + (i + 0.5) * g, 0.0, z0 + (k + 0.5) * g)
	var p := area.global_transform * local
	var y := floor_at(p, area.rules.wall_margin, area.rules.furniture_margin)
	if is_nan(y):
		return
	var space := Transform3D(area.global_basis, Vector3(p.x, y, p.z))
	var place := {"kind": SockArea.Kind.FLOOR, "space": space, "rect": Rect2(-g * 0.5, -g * 0.5, g, g),
			"from": FLOOR_RAY, "along": -1.0, "weight": g * g * area.floor_weight * fade(space.origin),
			"piece": null, "cell": Vector2i(i, k)}
	floor_places.append(place)
	cells[Vector2i(i, k)] = place


## A top's box (`Spots/Top<n>` and its box shape): a Sock rests on its bottom face.
func _add_top(top: Area3D) -> void:
	for shape_node in top.get_children():
		var shape := shape_node as CollisionShape3D
		if shape == null or not (shape.shape is BoxShape3D):
			continue
		var size := (shape.shape as BoxShape3D).size
		var space := shape.global_transform * Transform3D(Basis.IDENTITY, Vector3(0.0, -size.y * 0.5, 0.0))
		if not area.has_point(space.origin):
			continue
		var piece := piece_of(top)
		top_places.append({"kind": SockArea.Kind.TOP, "space": space, "rect": Rect2(-size.x * 0.5, -size.z * 0.5, size.x, size.z),
				"from": size.y, "along": -1.0, "piece": piece,
				"weight": size.x * size.z * _weight(SockArea.Kind.TOP, piece) * fade(space.origin)})


## An opening's inside box and its shelves (metadata `shelves_y`, heights in its piece's space): one
## place per level, a Sock along its long side.
func _add_inside(inside: Area3D) -> void:
	var piece := piece_of(inside)
	for shape_node in inside.get_children():
		var shape := shape_node as CollisionShape3D
		if shape == null or not (shape.shape is BoxShape3D):
			continue
		var size := (shape.shape as BoxShape3D).size
		var box_xf := shape.global_transform
		if not area.has_point(box_xf.origin):
			continue
		var levels: Array[float] = [-size.y * 0.5]
		for y: Variant in inside.get_meta(&"shelves_y", []):
			var at := (piece.global_transform * Vector3(0.0, float(y), 0.0)) if piece != null else inside.global_transform * Vector3(0.0, float(y), 0.0)
			var local := box_xf.affine_inverse() * at
			if local.y > -size.y * 0.5 and local.y < size.y * 0.5:
				levels.append(local.y)
		levels.sort()
		var rect := Rect2(-size.x * 0.5, -size.z * 0.5, size.x, size.z).grow(-INSIDE_INSET)
		var along := 0.0 if rect.size.x >= rect.size.y else PI * 0.5
		for k in levels.size():
			var ceiling := size.y * 0.5 if k == levels.size() - 1 else levels[k + 1]
			var space := box_xf * Transform3D(Basis.IDENTITY, Vector3(0.0, levels[k], 0.0))
			hidden_places.append({"kind": SockArea.Kind.INSIDE, "space": space, "rect": rect,
					"from": ceiling - levels[k] - 0.01, "along": along, "piece": piece,
					"weight": rect.get_area() * _weight(SockArea.Kind.INSIDE, piece)})


## The gap under a piece (its footprint, or `crawl_box`, from the floor up to `crawl_gap`): strips along
## the edges that face open floor, a Sock lying along its strip; the whole gap when none does.
func _add_under(piece: Node3D) -> void:
	var space := piece.global_transform
	if not area.has_point(space.origin):
		return
	var gap := float(piece.get_meta(&"crawl_gap"))
	var rect: Rect2
	var box: Variant = piece.get_meta(&"crawl_box") if piece.has_meta(&"crawl_box") else null
	if box is Dictionary and (box as Dictionary).has("min"):
		var lo: Array = box["min"]
		var hi: Array = box["max"]
		rect = Rect2(float(lo[0]), float(lo[1]), float(hi[0]) - float(lo[0]), float(hi[1]) - float(lo[1]))
	else:
		var fp: Array = piece.get_meta(&"footprint")
		rect = Rect2(-float(fp[0]) * 0.5, -float(fp[1]) * 0.5, float(fp[0]), float(fp[1]))
	rect = rect.grow(-UNDER_INSET)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var depth := minf(tuning.strip_low if gap < tuning.low_furniture else tuning.strip_high, minf(rect.size.x, rect.size.y) * 0.5)
	var w := _weight(SockArea.Kind.UNDER, piece)
	var from := gap - 0.005
	var sides := [
		[Rect2(rect.position.x, rect.position.y, rect.size.x, depth), Vector2(0, -1), 0.0],
		[Rect2(rect.position.x, rect.end.y - depth, rect.size.x, depth), Vector2(0, 1), 0.0],
		[Rect2(rect.position.x, rect.position.y, depth, rect.size.y), Vector2(-1, 0), PI * 0.5],
		[Rect2(rect.end.x - depth, rect.position.y, depth, rect.size.y), Vector2(1, 0), PI * 0.5],
	]
	var found := 0
	for side: Array in sides:
		var out_dir: Vector2 = side[1]
		var mid := rect.get_center() + out_dir * rect.size * 0.5
		var across := Vector2(absf(out_dir.y), absf(out_dir.x)) * rect.size * 0.35
		var open := 0
		for k: float in [-1.0, 0.0, 1.0]:
			var edge: Vector2 = mid + out_dir * (UNDER_INSET + 0.01) + across * k
			var q: Vector2 = mid + out_dir * (UNDER_INSET + tuning.strip_probe) + across * k
			var p := space * Vector3(q.x, 0.0, q.y)
			# Open floor out there, and nothing of the house (a wall) between the edge and it.
			var low := minf(gap * 0.5, 0.05)
			var seen := PhysicsQueries.ray(area, space * Vector3(edge.x, low, edge.y), space * Vector3(q.x, low, q.y), Mess.LAYER_HOUSE).is_empty()
			if seen and not is_nan(floor_at(p, area.rules.furniture_margin, area.rules.furniture_margin)):
				open += 1
		if open >= 2:
			var strip: Rect2 = side[0]
			hidden_places.append({"kind": SockArea.Kind.UNDER, "space": space, "rect": strip, "from": from,
					"along": float(side[2]), "piece": piece, "weight": strip.get_area() * w})
			found += 1
	if found == 0:
		hidden_places.append({"kind": SockArea.Kind.UNDER, "space": space, "rect": rect, "from": from,
				"along": -1.0, "piece": piece, "weight": rect.get_area() * w})


## A kind's weight in this area, or the piece's own (its metadata `sock_weight`, Q2520).
func _weight(kind: SockArea.Kind, piece: Node) -> float:
	if piece != null and piece.has_meta(&"sock_weight"):
		return float(piece.get_meta(&"sock_weight"))
	return area.weight_of(kind)


## The box kept clear in front of a Cabinet (its front is +z), if the Cabinet stands in the area.
func _cabinet_zone(cabinet: Cabinet) -> void:
	var root := cabinet.get_parent() as Node3D
	if root == null or not area.has_point(root.global_position):
		return
	var c := area.rules.cabinet_clear
	var head := area.rules.headroom
	keep_out.append([Vector3(c.x, head, c.y), root.global_transform * Transform3D(Basis.IDENTITY, Vector3(0.0, head * 0.5, 0.25 + c.y * 0.5))])
