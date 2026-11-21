## Builds the old house from the house kit's pieces (house/03, Q2345): the zoo stations
## game/zoo/stations/old_house_a.tscn (the windows at their old widths) and old_house_b.tscn (the
## widths rounded to 0.5 m, Q2381), every room, wall, opening, the U stair, the shaft's and the
## Cellar hatch's tiles and the roof at the numbers of docs/architecture/house-kit-plan.md. Each
## station stands on its own ground: a lawn round the house with holes for the basement, its light
## wells and the garage ramp (Q2386). Run it from the project folder after a change to the plan or
## the kit:
##   "$(kit/tools/engine.sh --path)" --headless --path . --script res://tools/old_house_build.gd
## It writes both station files again (their uids kept): an edit made to them by hand is lost.
## The house's frame is the plan's: x east, z south, the outer walls' centre lines on x 0..10.5 and
## z 0..8.5, the ground floor's top at y 0. Pieces follow the kit's grid convention
## (docs/architecture/house-kit.md): outer walls placed clockwise seen from above, inside inward.
extends SceneTree

const PIECES := "res://game/house/kit/pieces"
const MATERIALS := "res://game/house/kit/materials"
const STATIONS := "res://game/zoo/stations"
## The kit's builder: its keep_uid keeps a saved file in the editor's format (Q2268).
const KIT_BUILD := preload("res://tools/house_kit_build.gd")
const STOREY := 3.0
## The outer walls' centre lines.
const X1 := 10.5
const Z1 := 8.5
## Outer wall and partition thickness (the kit's).
const EXT := 0.2
## A corner's arm along each wall.
const ARM := 0.5
## Plain wall lengths, longest first.
const LENGTHS: Array[float] = [2.0, 1.0, 0.5]
## The storeys: name, floor top y.
const STOREYS: Array[Array] = [["Basement", -3.0], ["Ground", 0.0], ["First", 3.0], ["Attic", 6.0]]
## The U stair's well (x0, z0, x1, z1): its floor is open on every storey above the basement.
const WELL := Rect2(4.0, 5.5, 2.5, 3.0)
## The elevator shaft's tile (x, z) on the ground, first and attic floors (plan K09).
const SHAFT_TILE := Vector2(3.0, 4.5)
## The Cellar hatch's tile in the workshop floor (plan K09).
const HATCH_TILE := Vector2(2.0, 1.0)

## Rooms by storey, centre line to centre line: name, rect, wall paint, floor paint (make_house.py
## ROOMS and WALL_COLOURS: the laundry has the bathroom's colour, the living room the kitchen's).
const ROOMS := {
	"Basement": [["workshop", Rect2(0, 0, 4, 3.5), "wall_workshop", "basement_tile"],
			["laundry", Rect2(0, 3.5, 4, 5), "wall_bathroom", "basement_tile"],
			["boiler", Rect2(4, 0, 2.5, 2), "wall_boiler", "basement_tile"],
			["stair lobby", Rect2(4, 2, 2.5, 6.5), "wall_lobby", "basement_tile"],
			["garage", Rect2(6.5, 0, 4, 8.5), "wall_garage", "basement_tile"]],
	"Ground": [["kitchen", Rect2(0, 0, 4, 8.5), "wall_kitchen", "kitchen_tile"],
			["hall", Rect2(4, 0, 2.5, 8.5), "wall_hall", "wood"],
			["living", Rect2(6.5, 0, 4, 8.5), "wall_kitchen", "wood"]],
	"First": [["office", Rect2(0, 0, 4, 3.5), "wall_office", "wood"],
			["bedroom", Rect2(0, 3.5, 4, 5), "wall_bedroom", "wood"],
			["landing", Rect2(4, 0, 2.5, 8.5), "wall_hall", "wood"],
			["bathroom", Rect2(6.5, 0, 4, 3.5), "wall_bathroom", "bath_tile"],
			["kids", Rect2(6.5, 3.5, 4, 5), "wall_kids", "wood"]],
	"Attic": [["loft", Rect2(0, 0, 10.5, 8.5), "wall_loft", "loft_boards"]],
}

## The openings in the outer walls, by house: id -> [storey, side, piece from, to along the wall,
## piece]. Along is x on the N and S walls, z on the W and E walls (plan K06, K08).
const DOORS := {
	"D11": ["Ground", "N", 5.0, 6.5, "door_exterior_15m"],
	"D12": ["Basement", "N", 7.0, 9.5, "door_garage"],
}
const WINDOWS_A := {
	"W1": ["Basement", "N", 1.0, 2.5, "window_120_175_245_15m"],
	"W2": ["Basement", "W", 6.0, 7.5, "window_100_175_245_15m"],
	"W3": ["Basement", "S", 2.5, 4.0, "window_100_175_245_15m"],
	"W4": ["Basement", "E", 3.0, 4.5, "window_100_175_245_15m"],
	"W5": ["Ground", "N", 2.5, 4.0, "window_100_110_215_15m"],
	"W6": ["Ground", "W", 6.5, 8.0, "window_110_090_215_15m"],
	"W7": ["Ground", "S", 0.5, 3.0, "window_200_090_215_25m"],
	"W8": ["Ground", "N", 4.0, 5.0, "window_050_130_200_1m"],
	"W9": ["Ground", "N", 7.5, 9.0, "window_120_090_215_15m"],
	"W10": ["Ground", "E", 4.0, 5.5, "window_140_090_215_15m"],
	"W11": ["Ground", "S", 7.0, 9.5, "window_240_090_215_25m"],
	"W12": ["Ground", "S", 4.0, 6.5, "window_stair"],
	"W13": ["First", "N", 1.0, 2.5, "window_120_090_210_15m"],
	"W14": ["First", "W", 1.0, 2.5, "window_110_090_210_15m"],
	"W15": ["First", "W", 7.0, 8.5, "window_080_090_210_15m"],
	"W16": ["First", "S", 1.5, 3.0, "window_140_090_210_15m"],
	"W17": ["First", "N", 4.5, 6.0, "window_110_090_210_15m"],
	"W18": ["First", "N", 7.0, 8.5, "window_100_130_200_frosted_15m"],
	"W19": ["First", "S", 7.0, 9.0, "window_150_090_210_2m"],
}
const WINDOWS_B := {
	"W1": ["Basement", "N", 1.0, 2.5, "window_100_175_245_15m"],
	"W2": ["Basement", "W", 6.0, 7.5, "window_100_175_245_15m"],
	"W3": ["Basement", "S", 2.5, 4.0, "window_100_175_245_15m"],
	"W4": ["Basement", "E", 3.0, 4.5, "window_100_175_245_15m"],
	"W5": ["Ground", "N", 2.5, 4.0, "window_100_110_215_15m"],
	"W6": ["Ground", "W", 6.5, 8.0, "window_100_090_215_15m"],
	"W7": ["Ground", "S", 0.5, 3.0, "window_200_090_215_25m"],
	"W8": ["Ground", "N", 4.0, 5.0, "window_050_130_200_1m"],
	"W9": ["Ground", "N", 7.5, 9.0, "window_100_090_215_15m"],
	"W10": ["Ground", "E", 3.5, 6.0, "window_150_090_215_25m"],
	"W11": ["Ground", "S", 6.5, 10.0, "window_250_090_215_35m"],
	"W12": ["Ground", "S", 4.0, 6.5, "window_stair"],
	"W13": ["First", "N", 1.0, 2.5, "window_100_090_210_15m"],
	"W14": ["First", "W", 1.0, 2.5, "window_100_090_210_15m"],
	"W15": ["First", "W", 7.0, 8.5, "window_100_090_210_15m"],
	"W16": ["First", "S", 1.0, 3.5, "window_150_090_210_25m"],
	"W17": ["First", "N", 4.5, 6.0, "window_100_090_210_15m"],
	"W18": ["First", "N", 7.0, 8.5, "window_100_130_200_frosted_15m"],
	"W19": ["First", "S", 7.0, 9.0, "window_150_090_210_2m"],
}
## The attic's windows by house: the gables (W20 west, W21 east) and the dormer (W22).
const ATTIC_A := {"W20": "gable_exterior_mirrored", "W21": "gable_exterior", "W22": "dormer"}
const ATTIC_B := {"W20": "gable_exterior_grid_mirrored", "W21": "gable_exterior_grid", "W22": "dormer_grid"}

## The partitions by storey: name, axis of the line ("x": the line is x = const, it runs along z),
## the line, then its pieces [from, to along it, piece, run direction]. A piece's start (its origin)
## is where it begins in its run direction: an end piece (`_end_exterior_`, `_end_partition_`)
## starts at the face of the wall it meets, so the last one of a line runs back from its far end.
const PARTITIONS := {
	"Basement": [
		["X4", "x", 4.0, [[0, 2, "wall_partition_end_exterior_2m", "S"], [2, 3.5, "door_partition_15m", "S"],
				[3.5, 5, "door_partition_offset_15m", "S"], [5, 7, "wall_partition_2m", "S"],
				[7, 7.5, "wall_partition_05m", "S"], [7.5, 8.5, "wall_partition_end_exterior_1m", "N"]]],
		["X6_5", "x", 6.5, [[0, 2, "wall_partition_end_exterior_2m", "S"], [2, 4, "wall_partition_2m", "S"],
				[4, 5.5, "door_partition_15m", "S"], [5.5, 7.5, "wall_partition_2m", "S"],
				[7.5, 8.5, "wall_partition_end_exterior_1m", "N"]]],
		["Z3_5", "z", 3.5, [[0, 2, "wall_partition_end_exterior_2m", "E"], [2, 4, "wall_partition_end_partition_2m", "W"]]],
		["Z2", "z", 2.0, [[4, 4.5, "wall_partition_end_partition_05m", "E"], [4.5, 6, "door_partition_15m", "E"],
				[6, 6.5, "wall_partition_end_partition_05m", "W"]]],
	],
	"Ground": [
		["X4", "x", 4.0, [[0, 2, "wall_partition_end_exterior_2m", "S"], [2, 3.5, "door_partition_15m", "S"],
				[3.5, 5.5, "wall_partition_2m", "S"], [5.5, 7.5, "wall_partition_2m", "S"],
				[7.5, 8.5, "wall_partition_end_exterior_1m", "N"]]],
		["X6_5", "x", 6.5, [[0, 2, "wall_partition_end_exterior_2m", "S"], [2, 4, "wall_partition_2m", "S"],
				[4, 5.5, "door_partition_15m", "S"], [5.5, 7.5, "wall_partition_2m", "S"],
				[7.5, 8.5, "wall_partition_end_exterior_1m", "N"]]],
	],
	"First": [
		["X4", "x", 4.0, [[0, 2, "wall_partition_end_exterior_2m", "S"], [2, 3.5, "door_partition_15m", "S"],
				[3.5, 5.5, "door_partition_offset_hatch_2m", "S"], [5.5, 7.5, "wall_partition_2m", "S"],
				[7.5, 8.5, "wall_partition_end_exterior_1m", "N"]]],
		["X6_5", "x", 6.5, [[0, 2, "wall_partition_end_exterior_2m", "S"], [2, 3.5, "door_partition_15m", "S"],
				[3.5, 4, "wall_partition_05m", "S"], [4, 5.5, "door_partition_15m", "S"],
				[5.5, 7.5, "wall_partition_2m", "S"], [7.5, 8.5, "wall_partition_end_exterior_1m", "N"]]],
		["Z3_5W", "z", 3.5, [[0, 2, "wall_partition_end_exterior_2m", "E"], [2, 4, "wall_partition_end_partition_2m", "W"]]],
		["Z3_5E", "z", 3.5, [[6.5, 8.5, "wall_partition_end_partition_2m", "E"], [8.5, 10.5, "wall_partition_end_exterior_2m", "W"]]],
	],
}

## The roof posts' piece origins (plan K11: post centres at 3.75/8.75 z 1.75, 2.75/9.25 z 6.75).
const POSTS: Array[Vector3] = [Vector3(3.5, 0, 1.5), Vector3(8.5, 0, 1.5), Vector3(2.5, 0, 6.5), Vector3(9.0, 0, 6.5)]

## The station's ground (house frame): how far it reaches, its top (the ground floor's), and the
## old exterior's numbers (make_exterior.py): the light wells 0.9 m out and 0.25 m wider each side
## than their window, their gravel floor under the sill; the garage ramp's level apron 0.9 m out,
## then the slope up to the lawn; the drive 0.2 m wider each side than the garage door.
const GROUND := Rect2(-3.0, -9.0, 27.0, 33.0)
const GROUND_DEEP := 3.2
const WELL_OUT := 0.9
const WELL_SIDE := 0.25
const WELL_FLOOR := -1.45
const RAMP_X := Vector2(6.85, 9.65)
const RAMP_APRON := -1.0
const RAMP_TOP := -5.3
const LAWN := Color(0.50, 0.68, 0.36)
const GRAVEL := Color(0.60, 0.58, 0.54)
const CONCRETE := Color(0.74, 0.73, 0.70)

var _materials := {}
var _ground_materials := {}


func _init() -> void:
	_station("old_house_a", "OldHouseA", WINDOWS_A, ATTIC_A,
			"Old house A: the old house rebuilt from the house kit, its windows at their old widths. In at the front door on the north side; the U stair climbs from the basement to the attic.")
	_station("old_house_b", "OldHouseB", WINDOWS_B, ATTIC_B,
			"Old house B: the old house rebuilt from the house kit, its windows rounded to 0.5 m. In at the front door on the north side; the U stair climbs from the basement to the attic.")
	print("old_house_build: done")
	quit()


func _station(file: String, root_name: String, windows: Dictionary, attic: Dictionary, title: String) -> void:
	var root := Node3D.new()
	root.name = root_name
	var label := Label3D.new()
	label.name = "Name"
	label.position = Vector3(5.25, 11.5, -3.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = 900.0
	_add(root, root, label)
	_ground(root, windows)
	var house := Node3D.new()
	house.name = "House"
	_add(root, root, house)
	for storey: Array in STOREYS:
		var node := Node3D.new()
		node.name = storey[0]
		node.position.y = storey[1]
		_add(root, house, node)
		if storey[0] == "Attic":
			_attic(root, node, attic)
		else:
			_outer_walls(root, node, windows)
			_partitions(root, node)
			_stair(root, node)
		_floor(root, node)
	_save(root, STATIONS.path_join(file + ".tscn"))


func _add(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child, true)
	child.owner = root


func _group(root: Node, storey: Node3D, group: String) -> Node3D:
	var node := storey.get_node_or_null(group) as Node3D
	if node == null:
		node = Node3D.new()
		node.name = group
		_add(root, storey, node)
	return node


# --- Walls --------------------------------------------------------------------------------------

## The outer walls of one storey: the four corners and each side clockwise from its west or north
## corner, the openings at their pieces and plain pieces between (longest first).
func _outer_walls(root: Node, storey: Node3D, windows: Dictionary) -> void:
	var name := String(storey.name)
	var openings := {"N": [], "E": [], "S": [], "W": []}
	for table: Dictionary in [DOORS, windows]:
		for id: String in table:
			var o: Array = table[id]
			if o[0] == name:
				(openings[o[1]] as Array).append([o[2], o[3], o[4], id])
			elif o[0] == "Ground" and o[4] == "window_stair" and name == "First":
				# The stair window is two storeys high: the first floor's wall leaves its place.
				(openings[o[1]] as Array).append([o[2], o[3], "", id])
	# The bedroom's west window runs to the south wall's line (W15): that corner is the open one.
	var open_sw := false
	for o: Array in openings["W"]:
		if o[1] > Z1 - ARM:
			open_sw = true
	var corners := {"N": [Vector3(0, 0, 0), 0.0], "E": [Vector3(X1, 0, 0), -90.0], "S": [Vector3(X1, 0, Z1), 180.0],
			"W": [Vector3(0, 0, Z1), 90.0]}
	for side: String in ["N", "E", "S", "W"]:
		var group := _group(root, storey, side)
		var c: Array = corners[side]
		var corner := "corner_exterior_open" if side == "W" and open_sw else "corner_exterior"
		_piece(root, group, name, corner, c[0], c[1], "Corner")
		var length := X1 if side in ["N", "S"] else Z1
		var lo := ARM
		var hi := length - ARM
		if side == "W" and open_sw:
			hi = length
		var list: Array = openings[side]
		list.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
		var at := lo
		for o: Array in list:
			_plain(root, group, name, side, at, o[0])
			if o[2] != "":
				_on_side(root, group, name, side, o[0], o[1], o[2], o[3])
			at = o[1]
		_plain(root, group, name, side, at, hi)


## Plain outer wall pieces from `a` to `b` along a side, longest first.
func _plain(root: Node, group: Node3D, storey: String, side: String, a: float, b: float) -> void:
	var at := a
	while at < b - 0.001:
		for l: float in LENGTHS:
			if at + l <= b + 0.001:
				_on_side(root, group, storey, side, at, at + l, "wall_exterior_" + _tag(l), "")
				at += l
				break


## A piece on an outer side from `a` to `b` along it, placed clockwise (inside inward).
func _on_side(root: Node, group: Node3D, storey: String, side: String, a: float, b: float, file: String, label: String) -> void:
	match side:
		"N":
			_piece(root, group, storey, file, Vector3(a, 0, 0), 0.0, label)
		"S":
			_piece(root, group, storey, file, Vector3(b, 0, Z1), 180.0, label)
		"E":
			_piece(root, group, storey, file, Vector3(X1, 0, a), -90.0, label)
		"W":
			_piece(root, group, storey, file, Vector3(0, 0, b), 90.0, label)


func _partitions(root: Node, storey: Node3D) -> void:
	var name := String(storey.name)
	for line: Array in PARTITIONS.get(name, []):
		var group := _group(root, storey, line[0])
		var v: float = line[2]
		for seg: Array in line[3]:
			var a := float(seg[0])
			var b := float(seg[1])
			var dir: String = seg[3]
			var at := Vector3.ZERO
			var deg := 0.0
			if line[1] == "x":
				at = Vector3(v, 0, a if dir == "S" else b)
				deg = -90.0 if dir == "S" else 90.0
			else:
				at = Vector3(a if dir == "E" else b, 0, v)
				deg = 0.0 if dir == "E" else 180.0
			_piece(root, group, name, seg[2], at, deg, "")


# --- Stair, floors, attic -----------------------------------------------------------------------

func _stair(root: Node, storey: Node3D) -> void:
	var file := "stair_u_solid" if storey.name == &"Basement" else "stair_u"
	_piece(root, _group(root, storey, "Stair"), String(storey.name), file, Vector3(WELL.position.x, 0, WELL.position.y), 0.0, "")


## The floor tiles of a storey and, under each, the ceiling of the storey below (in this storey's
## node, at its floor line): the shaft's and the Cellar hatch's tiles first, then each room covered
## from its north-west corner with the largest tile that fits. The stair's well stays open above the
## basement.
func _floor(root: Node, storey: Node3D) -> void:
	var name := String(storey.name)
	var floor_group := _group(root, storey, "Floor")
	var ceiling: Node3D = null
	var ceiling_kind := ""
	if name != "Basement":
		ceiling = _group(root, storey, "CeilingBelow")
		ceiling_kind = "ceiling_attic_" if name == "Attic" else "ceiling_"
	var covered := {}
	if name != "Basement":
		_mark(covered, Rect2(WELL.position, WELL.size))
		_mark(covered, Rect2(SHAFT_TILE, Vector2.ONE))
		var at := Vector3(SHAFT_TILE.x, 0, SHAFT_TILE.y)
		_tile(root, floor_group, name, "floor_shaft_1m", at, 1.0)
		_piece(root, ceiling, name, ceiling_kind + "shaft_1m", at, 0.0, "")
	else:
		_mark(covered, Rect2(HATCH_TILE, Vector2(1.5, 1.5)))
		_tile(root, floor_group, name, "floor_hatch_15m", Vector3(HATCH_TILE.x, 0, HATCH_TILE.y), 1.5)
	for room: Array in ROOMS[name]:
		var r: Rect2 = room[1]
		var z := r.position.y
		while z < r.end.y - 0.001:
			var x := r.position.x
			while x < r.end.x - 0.001:
				if not covered.has(_cell(x, z)):
					for side: float in LENGTHS:
						var sq := Rect2(x, z, side, side)
						if r.encloses(sq) and _free(covered, sq):
							_mark(covered, sq)
							var at := Vector3(x, 0, z)
							_tile(root, floor_group, name, "floor_" + _tag(side), at, side)
							if ceiling != null:
								_piece(root, ceiling, name, ceiling_kind + _tag(side), at, 0.0, "")
							break
				x += 0.5
			z += 0.5


func _tile(root: Node, group: Node3D, storey: String, file: String, at: Vector3, side: float) -> void:
	var p := _piece(root, group, storey, file, at, 0.0, "")
	var room := _room(storey, at.x + side / 2, at.z + side / 2)
	var want := _material(room[3])
	if p.mesh.surface_get_material(0) != want:
		p.set_surface_override_material(0, want)


static func _cell(x: float, z: float) -> Vector2i:
	return Vector2i(roundi(x * 2), roundi(z * 2))


static func _mark(covered: Dictionary, r: Rect2) -> void:
	var z := r.position.y
	while z < r.end.y - 0.001:
		var x := r.position.x
		while x < r.end.x - 0.001:
			covered[_cell(x, z)] = true
			x += 0.5
		z += 0.5


static func _free(covered: Dictionary, r: Rect2) -> bool:
	var z := r.position.y
	while z < r.end.y - 0.001:
		var x := r.position.x
		while x < r.end.x - 0.001:
			if covered.has(_cell(x, z)):
				return false
			x += 0.5
		z += 0.5
	return true


## The attic: the gables on the west and east walls, the knee walls between them on the north and
## south, both roof slopes with their verges (the south one with the dormer), the posts, and the
## stair's newel cap and balustrade round the well.
func _attic(root: Node, storey: Node3D, attic: Dictionary) -> void:
	var walls := _group(root, storey, "Walls")
	_piece(root, walls, "Attic", attic["W20"], Vector3(0, 0, Z1), 90.0, "W20")
	_piece(root, walls, "Attic", attic["W21"], Vector3(X1, 0, 0), -90.0, "W21")
	# The north knee wall west to east, the south one east to west (turned half round).
	var knee: Array = [["knee_exterior_start_1m", 1.0], ["knee_exterior_2m", 2.0], ["knee_exterior_2m", 2.0],
			["knee_exterior_2m", 2.0], ["knee_exterior_2m", 2.0], ["knee_exterior_05m", 0.5], ["knee_exterior_end_1m", 1.0]]
	var x := 0.0
	for k: Array in knee:
		_piece(root, walls, "Attic", k[0], Vector3(x, 0, 0), 0.0, "")
		_piece(root, walls, "Attic", k[0], Vector3(X1 - x, 0, Z1), 180.0, "")
		x += k[1]
	var roof := _group(root, storey, "Roof")
	_piece(root, roof, "Attic", "roof_verge_w", Vector3(0, 0, 0), 0.0, "")
	for xn: float in [0.0, 2.0, 4.0, 6.0, 8.0]:
		_piece(root, roof, "Attic", "roof_2m", Vector3(xn, 0, 0), 0.0, "")
	_piece(root, roof, "Attic", "roof_05m", Vector3(10.0, 0, 0), 0.0, "")
	_piece(root, roof, "Attic", "roof_verge_e", Vector3(X1, 0, 0), 0.0, "")
	# The south slope from the east: 1.5 m, the dormer between its cheeks' lines x 9..7, then on west.
	_piece(root, roof, "Attic", "roof_verge_w", Vector3(X1, 0, Z1), 180.0, "")
	_piece(root, roof, "Attic", "roof_1m", Vector3(X1, 0, Z1), 180.0, "")
	_piece(root, roof, "Attic", "roof_05m", Vector3(9.5, 0, Z1), 180.0, "")
	_piece(root, roof, "Attic", attic["W22"], Vector3(9.0, 0, Z1), 180.0, "W22")
	for xs: float in [7.0, 5.0, 3.0]:
		_piece(root, roof, "Attic", "roof_2m", Vector3(xs, 0, Z1), 180.0, "")
	_piece(root, roof, "Attic", "roof_1m", Vector3(1.0, 0, Z1), 180.0, "")
	_piece(root, roof, "Attic", "roof_verge_e", Vector3(0, 0, Z1), 180.0, "")
	for p: Vector3 in POSTS:
		_piece(root, roof, "Attic", "roof_post", p, 0.0, "")
	var stair := _group(root, storey, "Stair")
	var at := Vector3(WELL.position.x, 0, WELL.position.y)
	_piece(root, stair, "Attic", "stair_newel_top", at, 0.0, "")
	_piece(root, stair, "Attic", "stair_balustrade", at, 0.0, "")


# --- Pieces and paint ---------------------------------------------------------------------------

## A kit piece in `group` at `at` (storey-local), turned `deg` about the vertical, its faces painted
## for the rooms they face: a wall-like piece's slot 0 (its +Z side) and slot 1 (its -Z side) take
## the wall paint of the room a step off each face, or the outside render.
func _piece(root: Node, group: Node3D, storey: String, file: String, at: Vector3, deg: float, label: String) -> MeshInstance3D:
	var scene := load(PIECES.path_join(file + ".tscn")) as PackedScene
	var p := scene.instantiate() as MeshInstance3D
	p.position = at
	p.rotation.y = deg_to_rad(deg)
	if label != "":
		p.name = label
	_add(root, group, p)
	var basis := Basis(Vector3.UP, deg_to_rad(deg))
	var faced := ["wall_", "door_", "window_", "knee_", "gable_"].any(func(prefix: String) -> bool: return file.begins_with(prefix))
	if faced:
		var box := p.mesh.get_aabb()
		var mid := at + basis * Vector3(box.get_center().x, 0, 0)
		for slot: int in [0, 1]:
			var out := basis * (Vector3.BACK if slot == 0 else Vector3.FORWARD)
			var spot := mid + out * 0.3
			_paint(p, slot, _wall_paint(storey, spot.x, spot.z))
	elif file.begins_with("corner_"):
		var spot := at + basis * Vector3(0.3, 0, 0.3)
		_paint(p, 0, _wall_paint(storey, spot.x, spot.z))
	return p


func _paint(p: MeshInstance3D, slot: int, paint: String) -> void:
	var want := _material(paint)
	if p.mesh.surface_get_material(slot) != want:
		p.set_surface_override_material(slot, want)


func _wall_paint(storey: String, x: float, z: float) -> String:
	if x <= 0.0 or x >= X1 or z <= 0.0 or z >= Z1:
		return "wall_outside"
	return _room(storey, x, z)[2]


func _room(storey: String, x: float, z: float) -> Array:
	for room: Array in ROOMS[storey]:
		if (room[1] as Rect2).has_point(Vector2(x, z)):
			return room
	return ROOMS[storey][0]


func _material(paint: String) -> Material:
	if not _materials.has(paint):
		_materials[paint] = load(MATERIALS.path_join(paint + ".tres"))
	return _materials[paint]


## "05m", "1m", "2m": a length in a piece's name (house_kit_build.gd's _tag).
static func _tag(metres: float) -> String:
	if is_equal_approx(metres, roundf(metres)):
		return "%dm" % int(metres)
	return ("%sm" % str(metres)).replace("0.", "0").replace(".", "")


# --- The station's ground -----------------------------------------------------------------------

## The lawn as boxes round the house's holes (the basement, the wells, the garage ramp), the wells'
## gravel floors, the ramp's apron and slope, the front door's threshold, and the Pad: the
## station's footprint under it all (the zoo's pads must not overlap).
func _ground(root: Node3D, windows: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	_add(root, root, body)
	var holes: Array[Rect2] = [Rect2(-EXT / 2, -EXT / 2, X1 + EXT, Z1 + EXT), Rect2(RAMP_X.x, RAMP_TOP, RAMP_X.y - RAMP_X.x, -EXT / 2 - RAMP_TOP)]
	var wells: Array[Rect2] = []
	for id: String in windows:
		var w: Array = windows[id]
		if w[0] != "Basement":
			continue
		var width := float(String(w[4]).get_slice("_", 1)) / 100.0
		var c := (float(w[2]) + float(w[3])) / 2
		var a := c - width / 2 - WELL_SIDE
		var b := c + width / 2 + WELL_SIDE
		var f := EXT / 2
		match String(w[1]):
			"N":
				wells.append(Rect2(a, -f - WELL_OUT, b - a, WELL_OUT))
			"S":
				wells.append(Rect2(a, Z1 + f, b - a, WELL_OUT))
			"W":
				wells.append(Rect2(-f - WELL_OUT, a, WELL_OUT, b - a))
			"E":
				wells.append(Rect2(X1 + f, a, WELL_OUT, b - a))
	holes.append_array(wells)
	var n := 0
	for r in _cut(GROUND, holes):
		n += 1
		_box(root, body, "Lawn%d" % n, r, -GROUND_DEEP, 0.0, LAWN)
	n = 0
	for r in wells:
		n += 1
		_box(root, body, "WellFloor%d" % n, r, -GROUND_DEEP, WELL_FLOOR, GRAVEL)
	_box(root, body, "RampApron", Rect2(RAMP_X.x, RAMP_APRON, RAMP_X.y - RAMP_X.x, -RAMP_APRON), -STOREY - 0.2, -STOREY, CONCRETE)
	# The slope: a slab whose top runs from the apron's edge at the basement floor up to the lawn.
	var run := Vector2(RAMP_TOP - RAMP_APRON, STOREY)   # along z, up y
	var length := run.length()
	var up := Vector3(0, -run.x, run.y).normalized()   # the slope's upward normal
	var thick := 0.3
	var mid := Vector3((RAMP_X.x + RAMP_X.y) / 2, -STOREY / 2, (RAMP_APRON + RAMP_TOP) / 2) - up * (thick / 2)
	var slope := Transform3D(Basis(Vector3.RIGHT, up, Vector3.RIGHT.cross(up)), mid)
	_shape(root, body, "Ramp", slope, Vector3(RAMP_X.y - RAMP_X.x, thick, length), CONCRETE)
	# The front door's threshold over the outer wall's outside half (the floor tiles start on its line).
	_box(root, body, "Threshold", Rect2(5.3, -EXT / 2, 0.9, EXT / 2), -0.12, 0.0, CONCRETE)
	var pad := MeshInstance3D.new()
	pad.name = "Pad"
	var plane := PlaneMesh.new()
	plane.size = GROUND.size
	plane.material = _ground_material(LAWN)
	pad.mesh = plane
	pad.position = Vector3(GROUND.get_center().x, -GROUND_DEEP, GROUND.get_center().y)
	_add(root, root, pad)


## `area` less `holes`, as rectangles: cut on every hole edge, the cells outside the holes, then
## merged along x and along z.
static func _cut(area: Rect2, holes: Array[Rect2]) -> Array[Rect2]:
	var xs: Array[float] = [area.position.x, area.end.x]
	var zs: Array[float] = [area.position.y, area.end.y]
	for h in holes:
		for v: float in [h.position.x, h.end.x]:
			if v > area.position.x and v < area.end.x and not xs.any(func(o: float) -> bool: return is_equal_approx(o, v)):
				xs.append(v)
		for v: float in [h.position.y, h.end.y]:
			if v > area.position.y and v < area.end.y and not zs.any(func(o: float) -> bool: return is_equal_approx(o, v)):
				zs.append(v)
	xs.sort()
	zs.sort()
	# Runs along x per row, then rows with the same run merged along z.
	var rows: Array[Array] = []
	for j in zs.size() - 1:
		var runs: Array[Vector2] = []
		var start := -1
		for i in xs.size():
			var solid := false
			if i < xs.size() - 1:
				var centre := Vector2((xs[i] + xs[i + 1]) / 2, (zs[j] + zs[j + 1]) / 2)
				solid = not holes.any(func(h: Rect2) -> bool: return h.has_point(centre))
			if solid and start < 0:
				start = i
			elif not solid and start >= 0:
				runs.append(Vector2(xs[start], xs[i]))
				start = -1
		rows.append(runs)
	var out: Array[Rect2] = []
	var open := {}   # run -> its rect's index in out
	for j in rows.size():
		var next := {}
		for run: Vector2 in rows[j]:
			if open.has(run):
				var k: int = open[run]
				out[k] = Rect2(out[k].position, Vector2(out[k].size.x, zs[j + 1] - out[k].position.y))
				next[run] = k
			else:
				out.append(Rect2(run.x, zs[j], run.y - run.x, zs[j + 1] - zs[j]))
				next[run] = out.size() - 1
		open = next
	return out


func _box(root: Node, body: StaticBody3D, name: String, r: Rect2, y0: float, y1: float, colour: Color) -> void:
	var at := Transform3D(Basis.IDENTITY, Vector3(r.get_center().x, (y0 + y1) / 2, r.get_center().y))
	_shape(root, body, name, at, Vector3(r.size.x, y1 - y0, r.size.y), colour)


func _shape(root: Node, body: StaticBody3D, name: String, at: Transform3D, size: Vector3, colour: Color) -> void:
	var shape := CollisionShape3D.new()
	shape.name = name
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = at
	_add(root, body, shape)
	var mesh := MeshInstance3D.new()
	mesh.name = name + "Mesh"
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = _ground_material(colour)
	mesh.mesh = bm
	mesh.transform = at
	_add(root, body, mesh)


func _ground_material(colour: Color) -> StandardMaterial3D:
	if not _ground_materials.has(colour):
		var m := StandardMaterial3D.new()
		m.albedo_color = colour
		m.roughness = 0.95
		_ground_materials[colour] = m
	return _ground_materials[colour]


# --- Saving -------------------------------------------------------------------------------------

func _save(root: Node3D, path: String) -> void:
	var uid := ResourceLoader.get_resource_uid(path) if FileAccess.file_exists(path) else ResourceUID.INVALID_ID
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("old_house_build: cannot save %s (%s)" % [path, error_string(err)])
	else:
		KIT_BUILD.keep_uid(path, uid)
		print("old_house_build: %s" % path)
	root.free()

