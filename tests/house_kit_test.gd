## The house kit (house/01 h1_*, house/02 k01-k14): the old house re-gridded, pieces that snap to the
## half-metre grid, two-faced walls with skirting, the old windows, door frames, U stair and roof,
## box collision on the house's layer, materials from the shared library, no two faces in one plane,
## and the zoo's House kit station whose room the player walks in and up to a window.
extends TestSuite

const PIECES := "res://game/house/kit/pieces"
const MATERIALS := "res://game/house/kit/materials"
const SIZES := "res://game/house/kit/house_kit_sizes.tres"
const STATION := "res://game/zoo/stations/house_kit.tscn"
const PLAN := "res://docs/architecture/house-kit-plan.md"
const PLAYER := "res://game/player/player.tscn"
const FLIGHT := "res://game/sock/flight.tscn"
const EPS := 0.001
## house/01's pieces (Q2326): still in the kit.
const HOUSE_01: Array[String] = [
	"wall_exterior_05m", "wall_exterior_1m", "wall_exterior_2m",
	"wall_partition_05m", "wall_partition_1m", "wall_partition_2m",
	"corner_exterior", "corner_partition", "t_exterior", "t_partition", "t_exterior_partition",
	"door_exterior", "door_partition", "window_exterior",
	"floor_05m", "floor_1m", "floor_2m", "ceiling_05m", "ceiling_1m", "ceiling_2m",
	"stair_full", "stair_half", "landing",
]
## The old house's wall, floor and tile materials the library must hold (Q2328), and house/02's.
const LIBRARY: Array[String] = ["wall_outside", "wall_kitchen", "wall_hall", "wall_bathroom", "wall_bedroom",
		"wall_office", "wall_kids", "wall_loft", "wall_tile", "ceiling", "trim", "oak", "glass", "frosted", "rafter",
		"roof_tile", "wood", "kitchen_tile", "bath_tile", "basement_tile", "loft_boards"]
## Pieces with an inside and an outside face (K03): every one whose name starts so.
const TWO_FACED: Array[String] = ["wall_", "corner_", "t_", "door_", "window_", "knee_", "gable_"]

var _level: Node3D = null
var _sizes: HouseKitSizes = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "h1_walls", "method": "case_h1_walls", "world": false,
				"title": "house/01 K01: walls 0.5, 1 and 2 m long, a storey high less the sink, 0.2 m outside and 0.12 m partition thick; corners and T-joins reach half a metre from the join"},
		{"name": "h1_tiles", "method": "case_h1_tiles", "world": false,
				"title": "house/01 K02: floor and ceiling tiles 0.5, 1 and 2 m square, the floor's top at its origin and the ceiling right under it"},
		{"name": "h1_openings", "method": "case_h1_openings", "world": false,
				"title": "house/01 K03: a door wall lets through a 0.9 x 2.1 m doorway (less its linings), a window wall holds a 1.0 m window from 0.9 to 2.1 m"},
		{"name": "h1_stairs", "method": "case_h1_stairs", "world": false,
				"title": "house/01 K04: a full flight rises one storey, a half flight half of one, and the landing stands at half a storey"},
		{"name": "k01_plan", "method": "case_k01_plan", "world": false,
				"title": "K01: the re-gridded plan lists every room, doorway, window, the stair, the shaft, the doors, the wells, the roof and the dormer, old beside new, and the kit's numbers are the plan's"},
		{"name": "k02_storeys", "method": "case_k02_storeys", "world": false,
				"title": "K02: storeys are 3.0 m; the clear heights stay the old 2.7, 2.7 and 2.6 m through the ceiling tiles"},
		{"name": "k03_two_faces", "method": "case_k03_two_faces", "world": false,
				"title": "K03: every wall piece has an inside and an outside face, each its own material slot, and a placed piece's override paints just its face"},
		{"name": "k04_thickness_joins", "method": "case_k04_thickness_joins", "world": false,
				"title": "K04: outer walls 0.2 m, partitions 0.12 m; a partition meets an outer wall or a partition with no gap where no T can stand"},
		{"name": "k05_skirting", "method": "case_k05_skirting", "world": false,
				"title": "K05: skirting 0.12 m high and 0.022 m off the wall runs along the inside faces (both faces of a partition) and stops at a door's casing"},
		{"name": "k06_windows", "method": "case_k06_windows", "world": false,
				"title": "K06: every window of the plan has a piece in both sets at its width, sill and head; the stair window spans two storeys"},
		{"name": "k07_frame", "method": "case_k07_frame", "world": false,
				"title": "K07: a window has the old sill, casing, frame bars (a middle bar over 1.0 m) and a pane, frosted for the bathroom; the pane stops a Sock"},
		{"name": "k08_door_frames", "method": "case_k08_door_frames", "world": false,
				"title": "K08: doorways have the old jamb linings and casings: room doorways 0.9 m (one off-centre), the front door 0.9 m, the garage door 2.4 m"},
		{"name": "k09_entity_openings", "method": "case_k09_entity_openings", "world": false,
				"title": "K09: openings for the entities: the elevator shaft's hole in the floor and ceiling tiles, its hatch through the partition, the Cellar hatch, the garage and front doors"},
		{"name": "k10_u_stair", "method": "case_k10_u_stair", "world": false,
				"title": "K10: the U stair: two 1.13 m flights at 33.3 degrees, the 0.9 m half landing at half a storey, the newel wall, the attic's balustrade and newel cap; walked on ramps"},
		{"name": "k11_roof", "method": "case_k11_roof", "world": false,
				"title": "K11: the roof at 40 degrees on 0.4 m knee walls, the ridge 3.88 m up, the gables with their window, the dormer's flat ceiling at 2.2 m, the posts"},
		{"name": "k12_every_piece", "method": "case_k12_every_piece", "world": false,
				"title": "K12: every piece's origin is a grid corner; it collides through boxes on the house layer; its slots are the library's; every placed piece sits on the grid in 90 degree turns"},
		{"name": "k13_station", "method": "case_k13_station", "world": false,
				"title": "K13: the station shows every piece, labelled, a roof corner with the dormer, and the room with its door, U stair and window"},
		{"name": "r5_label_height", "method": "case_r5", "world": false,
				"title": "R5: each line-up label hangs 0.3 m over its piece's top, lifted floors and ceilings included"},
		{"name": "k14_no_z_fight", "method": "case_k14_no_z_fight", "world": false,
				"title": "K14: pieces placed by the grid convention on two floors, the station and its floor have no two faces facing the same way in one plane and overlapping"},
		{"name": "real_path_u_room", "method": "case_real_path_u_room", "world": false,
				"title": "real path: in the House kit station the player walks in at the front door, is stopped by the partition, climbs the U stair to the upper floor and stands at its window"},
	]


func _before_case() -> void:
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_sizes = load(SIZES) as HouseKitSizes


func _piece(file: String) -> MeshInstance3D:
	return (load(PIECES.path_join(file + ".tscn")) as PackedScene).instantiate() as MeshInstance3D


func _all_files() -> Array[String]:
	var out: Array[String] = []
	for f: String in ResourceLoader.list_directory(PIECES):
		if f.ends_with(".tscn"):
			out.append(f.get_basename())
	return out


## The drawn shape of a piece in its own space.
func _aabb(file: String) -> AABB:
	var p := _piece(file)
	var box := p.mesh.get_aabb()
	p.free()
	return box


## The drawn shape of one material slot of a piece.
func _slot_aabb(file: String, slot: int) -> AABB:
	var p := _piece(file)
	var verts := p.mesh.surface_get_arrays(slot)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	p.free()
	var box := AABB(verts[0], Vector3.ZERO)
	for v in verts:
		box = box.expand(v)
	return box


func _box_near(box: AABB, from: Vector3, to: Vector3, what: String) -> void:
	_check(box.position.is_equal_approx(from) and box.end.is_equal_approx(to),
			"%s spans %s to %s (got %s to %s)" % [what, from, to, box.position, box.end])


## A level of only `placed` [file, position, turn in degrees] and its physics ready.
func _build(placed: Array) -> void:
	_level = Node3D.new()
	_level.name = "Level"
	for entry: Array in placed:
		var p := _piece(entry[0])
		p.position = entry[1]
		if entry.size() > 2:
			p.rotation.y = deg_to_rad(entry[2])
		_level.add_child(p)
	add_child(_level)
	await _physics_ticks(2)


func _hit(from: Vector3, to: Vector3) -> Dictionary:
	return PhysicsQueries.ray(_level, from, to, Mess.LAYER_HOUSE)


func _hits(from: Vector3, to: Vector3) -> bool:
	return not _hit(from, to).is_empty()


## Where a ray down at (x, z) first meets the house, or -INF.
func _top(x: float, z: float, from_y := 12.0) -> float:
	var h := _hit(Vector3(x, from_y, z), Vector3(x, -2, z))
	return (h["position"] as Vector3).y if not h.is_empty() else -INF


# --- house/01 -----------------------------------------------------------------------------------

func case_h1_walls() -> void:
	var h := _sizes.storey
	var sk := _sizes.sink
	var d := _sizes.skirting_depth
	_near(h, 3.0, EPS, "a storey is the old house's 2.9 m nudged to 3.0 m")
	for tag: String in ["05m", "1m", "2m"]:
		var length := {"05m": 0.5, "1m": 1.0, "2m": 2.0}[tag] as float
		_box_near(_aabb("wall_exterior_" + tag), Vector3(0, -sk, -0.1), Vector3(length, h - sk, 0.1 + d), "wall_exterior_" + tag)
		_box_near(_aabb("wall_partition_" + tag), Vector3(0, -sk, -0.06 - d), Vector3(length, h - sk, 0.06 + d), "wall_partition_" + tag)
	for kind: String in ["exterior", "partition"]:
		var t: float = _sizes.get(kind)
		var c := _slot_aabb("corner_" + kind, 0).merge(_slot_aabb("corner_" + kind, 1))
		_box_near(c, Vector3(-t / 2, -sk, -t / 2), Vector3(0.5, h - sk, 0.5), "corner_%s's walls" % kind)
		var tt := _slot_aabb("t_" + kind, 0).merge(_slot_aabb("t_" + kind, 1))
		_box_near(tt, Vector3(-0.5, -sk, -t / 2), Vector3(0.5, h - sk, 0.5), "t_%s's walls" % kind)
	_near(_sizes.exterior, 0.2, EPS, "an outside wall is 0.2 m thick")
	_near(_sizes.partition, 0.12, EPS, "a partition is 0.12 m thick")


func case_h1_tiles() -> void:
	for tag: String in ["05m", "1m", "2m"]:
		var side := {"05m": 0.5, "1m": 1.0, "2m": 2.0}[tag] as float
		_box_near(_aabb("floor_" + tag), Vector3(0, -0.1, 0), Vector3(side, 0, side), "floor_" + tag)
		_box_near(_aabb("ceiling_" + tag), Vector3(0, -0.3, 0), Vector3(side, -0.1, side), "ceiling_" + tag)


func case_h1_openings() -> void:
	await _build([["door_exterior", Vector3.ZERO], ["door_partition", Vector3(0, 0, 2)], ["window_exterior", Vector3(0, 0, 4)]])
	for z: float in [0.0, 2.0]:
		var across := func(x: float, y: float) -> bool: return _hits(Vector3(x, y, z - 1), Vector3(x, y, z + 1))
		_check(not across.call(0.5, 1.0) and not across.call(0.07, 0.3) and not across.call(0.93, 2.05), "the doorway at z %s is open 0.9 m wide and 2.1 m high" % z)
		_check(across.call(0.03, 1.0) and across.call(0.97, 1.0) and across.call(0.5, 2.15), "the door wall at z %s stands either side and over it" % z)
	# The window: from inside, a ray meets the pane (in the wall's middle), not the inside face.
	var depth := func(x: float, y: float) -> float:
		var hit := _hit(Vector3(x, y, 5), Vector3(x, y, 3))
		return (hit["position"] as Vector3).z if not hit.is_empty() else INF
	_check(depth.call(1.0, 1.5) < 4.05 and depth.call(0.6, 1.0) < 4.05 and depth.call(1.4, 2.0) < 4.05, "the window's pane fills 1.0 m from 0.9 m to 2.1 m")
	_check(absf(depth.call(1.0, 0.85) - 4.1) < 0.01 and absf(depth.call(1.0, 2.15) - 4.1) < 0.01 and absf(depth.call(0.45, 1.5) - 4.1) < 0.01,
			"the window wall stands under, over and either side of it")


func case_h1_stairs() -> void:
	var h := _sizes.storey
	var sk := _sizes.sink
	_box_near(_aabb("stair_full"), Vector3(0, -sk, 0), Vector3(1, h, 4), "stair_full")
	_box_near(_aabb("stair_half"), Vector3(0, -sk, 0), Vector3(1, h / 2, 2), "stair_half")
	_box_near(_aabb("landing"), Vector3(0, -sk, 0), Vector3(2, h / 2, 1), "landing")
	await _build([["stair_full", Vector3.ZERO], ["landing", Vector3(3, 0, 0)]])
	_near(_top(0.5, 3.9), h, 0.01, "a full flight's top step is walked at the next floor's height")
	_near(_top(0.5, 2.0), 1.5, 0.2, "halfway up it is about half a storey")
	_near(_top(4, 0.5), h / 2, EPS, "the landing's top is half a storey up")


# --- house/02 -----------------------------------------------------------------------------------

func case_k01_plan() -> void:
	var text := FileAccess.get_file_as_string(PLAN)
	_check(not text.is_empty(), "the plan is written (%s)" % PLAN)
	for i in range(1, 13):
		_check(text.contains("| D%d |" % i), "the plan places doorway D%d, old beside new" % i)
	for i in range(1, 23):
		_check(text.contains("| W%d |" % i), "the plan places window W%d, old beside new" % i)
	for row: String in ["| workshop |", "| laundry |", "| kitchen |", "| loft |", "first riser", "shaft inside", "Cellar hatch",
			"FrontDoor", "GarageDoor", "WorkshopWell", "ridge over the attic floor", "dormer inside", "| move |"]:
		_check(text.contains(row), "the plan has '%s'" % row)
	# The kit's numbers are the plan's.
	_check(_sizes.stair_well.is_equal_approx(Vector2(2.5, 3.0)), "the stair well is the plan's 2.5 x 3.0 m")
	_near(_sizes.half_landing, 0.9, EPS, "the half landing is 0.9 m (Q2350)")
	_near(_sizes.pitch, 40.0, EPS, "the roof is 40 degrees (Q2354)")
	_check(_sizes.door_offset.is_equal_approx(Vector2(1.5, 0.15)), "D2 and D8's off-centre piece: 1.5 m, the doorway from 0.15 (Q2351)")
	_check(_sizes.windows_old.size() == 14 and _sizes.windows_grid.size() == 10, "both window sets of the plan (Q2355)")


func case_k02_storeys() -> void:
	var h := _sizes.storey
	_near(h, 3.0, EPS, "a storey is 3.0 m")
	var floor_t := -_aabb("floor_1m").position.y
	var under := -_aabb("ceiling_1m").position.y
	var under_attic := -_aabb("ceiling_attic_1m").position.y
	_near(floor_t, 0.1, EPS, "a floor tile is 0.1 m")
	_near(h - under, 2.7, EPS, "the basement's and ground floor's clear height stays 2.7 m")
	_near(h - under_attic, 2.6, EPS, "the first floor's clear height under the attic stays 2.6 m")
	# Measured: a floor on the storey line over a ceiling, a ray up from the floor below.
	await _build([["floor_1m", Vector3(0, h, 0)], ["ceiling_attic_1m", Vector3(0, h, 0)]])
	var up := _hit(Vector3(0.5, 0.1, 0.5), Vector3(0.5, 5, 0.5))
	_check(not up.is_empty() and absf((up["position"] as Vector3).y - 2.6) < 0.01, "the ceiling is met 2.6 m over the floor below (got %s)" % up.get("position"))


func case_k03_two_faces() -> void:
	for file in _all_files():
		var two := false
		for prefix in TWO_FACED:
			two = two or file.begins_with(prefix)
		if not two:
			continue
		var p := _piece(file)
		var inside := p.mesh.surface_get_material(0)
		var outside := p.mesh.surface_get_material(1)
		_check(p.mesh.get_surface_count() >= 3 and inside != null and outside != null, "%s has an inside and an outside slot, and trim" % file)
		# The inside slot holds the +Z faces, the outside slot the -Z faces (of a wall along X).
		var faces_in := _normals(p, 0)
		var faces_out := _normals(p, 1)
		_check(faces_in.has(Vector3i(0, 0, 1)) and (not faces_in.has(Vector3i(0, 0, -1)) or file.begins_with("corner_") or file.begins_with("t_")),
				"%s's inside slot faces +Z" % file)
		_check(faces_out.has(Vector3i(0, 0, -1)) and not faces_out.has(Vector3i(0, 0, 1)), "%s's outside slot faces -Z" % file)
		p.free()
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	var hall := load(MATERIALS.path_join("wall_hall.tres")) as Material
	var east := station.get_node("URoom/WallPartition2m4") as MeshInstance3D
	_check(east.get_surface_override_material(0) == hall and east.get_active_material(0) == hall
			and east.get_active_material(1) == east.mesh.surface_get_material(1),
			"the room's east partition paints its inside face wall_hall and keeps its other face")
	station.free()


## The axis-aligned normals a slot has, as integer vectors.
func _normals(p: MeshInstance3D, slot: int) -> Dictionary:
	var out := {}
	var normals := p.mesh.surface_get_arrays(slot)[Mesh.ARRAY_NORMAL] as PackedVector3Array
	for n in normals:
		out[Vector3i(roundi(n.x), roundi(n.y), roundi(n.z))] = true
	return out


func case_k04_thickness_joins() -> void:
	_near(_sizes.exterior, 0.2, EPS, "outer walls are the old 0.2 m")
	_near(_sizes.partition, 0.12, EPS, "partitions are the old 0.12 m")
	# A partition running south (turned -90) from an outer wall along X, and one from a partition.
	await _build([["wall_exterior_2m", Vector3(0, 0, 0)], ["wall_partition_end_exterior_1m", Vector3(1, 0, 0), -90],
			["wall_partition_2m", Vector3(4, 0, 0)], ["wall_partition_end_partition_1m", Vector3(5, 0, 0), -90]])
	for at: Array in [[1.0, 0.1], [5.0, 0.06]]:
		var x: float = at[0]
		var face: float = at[1]
		var just_off := _hit(Vector3(x - 0.5, 1.5, face + 0.003), Vector3(x + 0.5, 1.5, face + 0.003))
		_check(not just_off.is_empty() and absf((just_off["position"] as Vector3).x - (x - 0.06)) < 0.005,
				"the partition reaches the face of the wall it meets at x %s: no gap" % x)
		var into := _hit(Vector3(x - 0.5, 1.5, face - 0.003), Vector3(x + 0.5, 1.5, face - 0.003))
		_check(into.is_empty() or absf((into["position"] as Vector3).x - (x - 0.06)) > 0.01, "and stops there, not inside it (x %s)" % x)


func case_k05_skirting() -> void:
	var h := _sizes.skirting_height
	var d := _sizes.skirting_depth
	_near(h, 0.12, EPS, "the old skirting is 0.12 m high")
	_near(d, 0.022, EPS, "and stands 0.022 m off the wall")
	var ext := _slot_aabb("wall_exterior_1m", 2)
	_box_near(ext, Vector3(0, -_sizes.trim_sink, 0.1), Vector3(1, h, 0.1 + d), "an outer wall's skirting runs along its inside face")
	var part := _slot_aabb("wall_partition_1m", 2)
	_box_near(part, Vector3(0, -_sizes.trim_sink, -0.06 - d), Vector3(1, h, 0.06 + d), "a partition's skirting runs along both faces")
	# A door piece: skirting from each end to the casing, none across the doorway.
	var p := _piece("door_partition_15m")
	var verts := p.mesh.surface_get_arrays(2)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var across := false
	for v in verts:
		across = across or (v.y > 0.01 and v.y < 0.11 and v.x > 0.3 + 0.02 and v.x < 1.2 - 0.02 and absf(v.z) > 0.075)
	_check(not across, "no skirting crosses the doorway")
	p.free()
	var end := _slot_aabb("wall_partition_end_exterior_1m", 2)
	_near(end.position.x, 0.1 + d, EPS, "a partition meeting a wall starts its skirting after the wall's skirting")


func case_k06_windows() -> void:
	var sets := _sizes.windows_old + _sizes.windows_grid
	for spec: Vector4 in sets + _sizes.windows_frosted:
		var frosted := spec in _sizes.windows_frosted
		var file := "window_%03d_%03d_%03d%s_%s" % [roundi(spec.x * 100), roundi(spec.y * 100), roundi(spec.z * 100),
				"_frosted" if frosted else "", _tag(spec.w)]
		_check(ResourceLoader.exists(PIECES.path_join(file + ".tscn")), "%s is a piece" % file)
		if not ResourceLoader.exists(PIECES.path_join(file + ".tscn")):
			continue
		var glass := _slot_aabb(file, 3)
		var bar := _sizes.window_bar
		_near(glass.size.x, spec.x - 2 * bar + 0.02, 0.002, "%s's pane is its width inside the frame" % file)
		_near(glass.position.y, spec.y + 0.035 + bar - 0.01, 0.002, "%s's pane starts over its sill at %s" % [file, spec.y])
		_near(glass.end.y, spec.z - bar + 0.01, 0.002, "%s's pane ends under its head at %s" % [file, spec.z])
		_near(_slot_aabb(file, 0).merge(_slot_aabb(file, 1)).end.x, spec.w, EPS, "%s is a %s m piece" % [file, spec.w])
	_check(_sizes.windows_old.has(Vector4(2.4, 0.9, 2.15, 2.5)) and _sizes.windows_grid.has(Vector4(2.5, 0.9, 2.15, 3.5)),
			"the living room's south window: 2.4 m old, 2.5 m on the grid")
	var stair := _slot_aabb("window_stair", 3)
	_check(stair.position.y > 2.4 and stair.end.y < 3.5 and _aabb("window_stair").end.y > 5.9, "the stair window 2.4..3.5 m in a wall two storeys high")


static func _tag(metres: float) -> String:
	if is_equal_approx(metres, roundf(metres)):
		return "%dm" % int(metres)
	return ("%sm" % str(metres)).replace("0.", "0").replace(".", "")


func case_k07_frame() -> void:
	var file := "window_120_090_210_15m"
	var trim := _slot_aabb(file, 2)
	# The 1.2 m opening in a 1.5 m piece: 0.15..1.35; casings 0.06 round it, the sill 0.05 past it.
	_check(trim.position.x < 0.15 - 0.059 and trim.end.x > 1.35 + 0.059, "the casings and sill stand round the opening")
	_check(trim.end.z >= 0.1 + 0.05 - EPS and trim.position.z <= -0.1 - 0.03 + EPS, "the sill runs through the wall, proud of both faces")
	var middle := func(f: String, c: float) -> bool:
		var p := _piece(f)
		var verts := p.mesh.surface_get_arrays(2)[Mesh.ARRAY_VERTEX] as PackedVector3Array
		p.free()
		for v in verts:
			if absf(v.x - (c - 0.025)) < 0.001 and v.y > 0.95 and v.y < 2.1:
				return true
		return false
	_check(middle.call(file, 0.75), "a window over 1.0 m has a middle bar")
	_check(not middle.call("window_100_090_210_15m", 0.75), "a 1.0 m window has none")
	var frosted := _piece("window_100_130_200_frosted_15m")
	_check(frosted.mesh.surface_get_material(3).resource_path.ends_with("frosted.tres"), "the bathroom's pane is frosted")
	frosted.free()
	var clear := _piece(file)
	_check(clear.mesh.surface_get_material(3).resource_path.ends_with("glass.tres"), "the others are glass")
	clear.free()
	# A Sock thrown at the pane from inside stays inside.
	await _build([["floor_2m", Vector3(-0.25, 0, -1)], [file, Vector3(0, 0, 0)]])
	var sock := (load(FLIGHT) as PackedScene).instantiate() as RigidBody3D
	sock.position = Vector3(0.75, 1.5, 0.8)
	_level.add_child(sock)
	sock.linear_velocity = Vector3(0, 0.5, -6)
	await _physics_ticks(45)
	_check(sock.position.z > -0.05, "the pane stops the Sock (z %s)" % sock.position.z)


func case_k08_door_frames() -> void:
	var ln := _sizes.lining
	for entry: Array in [["door_partition", 0.05, 0.9], ["door_partition_15m", 0.3, 0.9], ["door_partition_offset_15m", 0.15, 0.9],
			["door_exterior_15m", 0.3, 0.9], ["door_garage", 0.05, 2.4]]:
		var file: String = entry[0]
		var a: float = entry[1]
		var w: float = entry[2]
		var p := _piece(file)
		var verts := p.mesh.surface_get_arrays(2)[Mesh.ARRAY_VERTEX] as PackedVector3Array
		p.free()
		var linings := 0
		var casing := false
		for v in verts:
			if (absf(v.x - (a + ln)) < 0.001 or absf(v.x - (a + w - ln)) < 0.001) and absf(v.y + _sizes.lining_sink) < 0.001:
				linings += 1
			casing = casing or (absf(v.x - (a - _sizes.casing)) < 0.001 and v.y > 2.1)
		_check(linings > 0, "%s has its jamb linings in the reveal at %s..%s" % [file, a, a + w])
		_check(casing, "%s has its casing round the doorway" % file)
	await _build([["door_partition_offset_15m", Vector3.ZERO], ["door_garage", Vector3(0, 0, 3)]])
	var open := func(x: float, y: float, z: float) -> bool: return not _hits(Vector3(x, y, z - 1), Vector3(x, y, z + 1))
	_check(open.call(0.2, 1.0, 0.0) and open.call(1.0, 1.0, 0.0) and not open.call(0.1, 1.0, 0.0) and not open.call(1.1, 1.0, 0.0),
			"the off-centre doorway is open 0.15..1.05 along its piece")
	_check(open.call(0.1, 1.0, 3.0) and open.call(2.4, 2.0, 3.0) and not open.call(1.25, 2.15, 3.0), "the garage door's opening is 2.4 x 2.1 m")


func case_k09_entity_openings() -> void:
	var hole := _sizes.shaft_hole
	await _build([["floor_shaft_1m", Vector3(0, 3, 0)], ["ceiling_shaft_1m", Vector3(0, 3, 0)], ["floor_hatch_15m", Vector3(3, 0, 0)],
			["wall_partition_hatch_1m", Vector3(6, 0, 0)]])
	var c := hole.get_center()
	_check(_top(c.x, c.y) < 0.0, "the shaft falls through the floor and ceiling tiles' hole")
	_near(_top(0.1, 0.1), 3.0, EPS, "and the tile stands round it")
	_check(_top(3.75, 0.75) < -1.0, "the Cellar hatch's hole is open in the middle of its tile")
	_near(_top(3.1, 0.1), 0.0, EPS, "its tile stands round it")
	var h := _sizes.elevator_hatch
	var across := func(x: float, y: float) -> bool: return _hits(Vector3(x, y, -1), Vector3(x, y, 1))
	_check(not across.call(6 + (h.x + h.y) / 2, (h.z + h.w) / 2), "the elevator's hatch goes through the partition")
	_check(across.call(6 + (h.x + h.y) / 2, h.z - 0.05) and across.call(6 + (h.x + h.y) / 2, h.w + 0.05) and across.call(6 + h.x - 0.05, 1.0),
			"the partition stands round the hatch")
	_near(_sizes.garage_door.x, 2.4, EPS, "the garage door's opening is the old 2.4 m")


func case_k10_u_stair() -> void:
	var h := _sizes.storey
	await _build([["stair_u", Vector3.ZERO], ["stair_newel_top", Vector3(10, 0, 0)], ["stair_balustrade", Vector3(10, 0, 0)]])
	var going := 2.0 / 7.0
	_near(rad_to_deg(atan((h / 16.0) / going)), 33.3, 0.1, "the flights are 33.3 degrees")
	_near(_top(0.6, 2.4), h / 2, EPS, "the half landing is half a storey up, 0.9 m deep (z 2.0..2.9)")
	_check(_top(0.6, 2.95) < 0.5, "and ends at the outer wall's face")
	var west := _top(0.6, 1.0)
	_near(west, (h / 16.0) * (1.0 / going + 1.0) + 0.01, 0.02, "the west flight's ramp rises south")
	var east := _top(1.9, 1.0)
	_near(east, h / 2 + (h / 16.0) * (1.0 / going + 1.0) + 0.01, 0.02, "the east flight's ramp rises north")
	_near(_top(1.9, 0.02), h, 0.03, "and reaches the next floor at the first riser")
	var aabb := _aabb("stair_u")
	_near(aabb.position.x, 0.06, EPS, "the flights stand between the partitions' faces")
	_near(aabb.end.x, 2.44, EPS, "on both sides")
	_check(_hits(Vector3(1.25, 1.0, -1), Vector3(1.25, 1.0, 1)), "the newel wall stands between the flights")
	_near(_top(11.25, 1.0), 1.05, EPS, "the attic's newel ends a handrail high under its cap")
	_check(_hits(Vector3(9.5, 0.5, 1.0), Vector3(10.5, 0.5, 1.0)) and _hits(Vector3(10.6, 0.5, -0.5), Vector3(10.6, 0.5, 0.5)),
			"the balustrade stands round the void")


func case_k11_roof() -> void:
	var s := _sizes
	_near(s.pitch, 40.0, EPS, "the roof is 40 degrees")
	_near(s.roof_under(s.roof_span), 3.88, 0.01, "the ridge is 3.88 m over the attic floor")
	await _build([["roof_2m", Vector3.ZERO], ["knee_exterior_2m", Vector3.ZERO], ["gable_exterior", Vector3(10, 0, 0)],
			["dormer", Vector3(20, 0, 0)], ["roof_post", Vector3(30, 0, 1.5)]])
	var up := s.roof_thickness / cos(deg_to_rad(s.pitch))
	for z: float in [1.0, 2.0, 3.0]:
		_near(_top(1.0, z), s.roof_under(z) + up, 0.12, "the slope's top over z %s is 40 degrees up from the knee" % z)
	var under := _hit(Vector3(1.0, 0.1, 0.12), Vector3(1.0, 5, 0.12))
	_check(not under.is_empty() and (under["position"] as Vector3).y > s.knee - 0.05, "the knee wall stands 0.4 m to the slope")
	var gw := s.gable_window
	var pane := _hit(Vector3(10 + gw.w, (gw.y + gw.z) / 2, 1), Vector3(10 + gw.w, (gw.y + gw.z) / 2, -1))
	_check(not pane.is_empty() and (pane["position"] as Vector3).z < 0.05, "the gable's window pane sits in its opening")
	var ceiling := _hit(Vector3(21.0, 1.0, 1.0), Vector3(21.0, 5.0, 1.0))
	_check(not ceiling.is_empty() and absf((ceiling["position"] as Vector3).y - s.dormer.y) < 0.02, "the dormer's flat ceiling is 2.2 m up (got %s)" % ceiling.get("position"))
	var post := _hit(Vector3(30.25, 0.5, 2.4), Vector3(30.25, 0.5, 1.0))
	_check(not post.is_empty(), "a roof post stands 1.75 m from the wall line")


func _on_grid(v: float) -> bool:
	return is_equal_approx(snappedf(v, _sizes.grid), v)


func case_k12_every_piece() -> void:
	var files := _all_files()
	for file in HOUSE_01:
		_check(files.has(file), "house/01's %s is still in the kit" % file)
	for file in files:
		var p := _piece(file)
		_check(p.transform.is_equal_approx(Transform3D.IDENTITY), "%s's root sits at its origin, unturned" % file)
		var body := p.get_node_or_null("Body") as StaticBody3D
		_check(body != null and body.collision_layer == Mess.LAYER_HOUSE and body.collision_mask == 0, "%s collides on the house layer" % file)
		if body != null:
			var drawn := p.mesh.get_aabb().grow(0.05)
			for shape: Node in body.get_children():
				var cs := shape as CollisionShape3D
				_check(cs != null and cs.shape is BoxShape3D, "%s's %s is a box, never its drawn mesh" % [file, shape.name])
				if cs != null:
					_check(drawn.has_point(cs.position), "%s's %s stands inside the drawn piece" % [file, shape.name])
		for i in p.mesh.get_surface_count():
			var m := p.mesh.surface_get_material(i)
			_check(m != null and m.resource_path.begins_with(MATERIALS), "%s's slot %d is the library's (%s)" % [file, i, m.resource_path if m else "none"])
		p.free()
	for name in LIBRARY:
		_check(ResourceLoader.exists(MATERIALS.path_join(name + ".tres")), "the library has %s" % name)
	# Every piece placed in the station's rooms sits on the grid, turned in 90 degree steps.
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	var placed := 0
	for node: Node in station.find_children("*", "MeshInstance3D", true, false):
		if not node.scene_file_path.begins_with(PIECES):
			continue
		placed += 1
		var n := node as Node3D
		var at := n.position
		_check(_on_grid(at.x) and _on_grid(at.y) and _on_grid(at.z), "%s sits on the grid (%s)" % [str(n.get_parent().name) + "/" + n.name, at])
		var turn := rad_to_deg(n.rotation.y)
		_check(is_equal_approx(snappedf(turn, 90.0), snappedf(turn, 0.01)) and absf(n.rotation.x) < EPS and absf(n.rotation.z) < EPS,
				"%s is turned in 90 degree steps (%s)" % [n.name, turn])
	_check(placed > 60, "the station's rooms place the kit's pieces (%d)" % placed)
	for root: String in ["URoom", "AtticCorner", "LineUp"]:
		var r := station.get_node(root) as Node3D
		_check(_on_grid(r.position.x) and _on_grid(r.position.z), "the station's %s is on the grid" % root)
	station.free()


## The station alone on a stand-in zoo floor, in the tree (its line-up built), with the player and
## the level's Parts, as the zoo has them.
func _station_level(with_player: bool) -> Player:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "ZooFloor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 80)
	shape.shape = box
	shape.position = Vector3(13, -0.1, -32.5)   # the zoo floor where it is, seen from the station
	floor_body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	mesh.position = shape.position
	floor_body.add_child(mesh)
	_level.add_child(floor_body)
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	station.name = "HouseKit"
	station.position = Vector3.ZERO   # its root carries its place in the zoo; the case walks it alone
	_level.add_child(station)
	var player: Player = null
	if with_player:
		player = (load(PLAYER) as PackedScene).instantiate() as Player
		player.position = Vector3(1 + 1.75, 0, -3 - 1.5)
		player.rotation.y = PI   # facing +Z, at the front door
		_level.add_child(player)
		var parts := Parts.new()
		parts.name = "Parts"
		_level.add_child(parts)
	add_child(_level)
	if with_player:
		await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	else:
		await _physics_ticks(2)
	return player


func case_r5() -> void:
	await _station_level(false)
	var line_up := _level.get_node("HouseKit/LineUp")
	var checked := 0
	var lifted := 0
	for node: Node in line_up.get_children():
		var label := node as Label3D
		if label == null:
			continue
		var piece := line_up.get_node_or_null(NodePath(label.name.trim_suffix("Label"))) as MeshInstance3D
		if piece == null:
			continue
		checked += 1
		lifted += 1 if piece.position.y > 0.0 else 0
		_near(label.position.y - piece.position.y, piece.mesh.get_aabb().end.y + 0.3, 0.0001, "%s hangs 0.3 m over its piece" % label.text)
	_check(checked > 10 and lifted > 0, "labels were checked, lifted pieces among them (%d, %d)" % [checked, lifted])

func case_k13_station() -> void:
	await _station_level(false)
	var line_up := _level.get_node("HouseKit/LineUp")
	var shown := {}
	var labels := {}
	for node: Node in line_up.get_children():
		if node.scene_file_path.begins_with(PIECES):
			shown[node.scene_file_path.get_file().get_basename()] = true
		elif node is Label3D:
			labels[(node as Label3D).text] = true
	for file in _all_files():
		_check(shown.has(file) and labels.has(file), "the line-up shows %s with its label" % file)
	var room := _level.get_node("HouseKit/URoom")
	var has := func(file: String) -> bool:
		for n: Node in room.get_children():
			if n.scene_file_path.ends_with("/" + file + ".tscn"):
				return true
		return false
	_check(has.call("door_exterior_15m") and has.call("stair_u") and has.call("window_110_090_210_15m"),
			"the room has its front door, U stair and landing window")
	var attic := _level.get_node("HouseKit/AtticCorner")
	_check(attic.get_child_count() > 8 and attic.find_children("Dormer*", "", false, false).size() == 1, "the roof corner has its dormer")


## Every triangle of every mesh under `root`, in world space, bucketed by its plane (the normal
## and the distance from the origin, rounded): faces facing the same way in one plane.
func _planes(root: Node) -> Dictionary:
	var planes := {}
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var xf := mi.global_transform
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var idx := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			var count := idx.size() if not idx.is_empty() else verts.size()
			for t in range(0, count, 3):
				var a := xf * verts[idx[t] if not idx.is_empty() else t]
				var b := xf * verts[idx[t + 1] if not idx.is_empty() else t + 1]
				var c := xf * verts[idx[t + 2] if not idx.is_empty() else t + 2]
				var n := (b - a).cross(c - a)
				if n.length() < 1e-9:
					continue
				n = n.normalized()
				var key := "%.3f %.3f %.3f %.3f" % [snappedf(n.x, 0.001) + 0.0, snappedf(n.y, 0.001) + 0.0, snappedf(n.z, 0.001) + 0.0,
						snappedf(n.dot(a), 0.001) + 0.0]
				if not planes.has(key):
					planes[key] = []
				(planes[key] as Array).append([mi, n, a, b, c])
	return planes


## The pairs of faces that overlap in one plane facing one way where they can be seen: a point just
## in front of the overlap is not inside another piece (walls run through the slabs, so some faces
## meet inside a wall or a tile, where no camera can see them).
func _fights(planes: Dictionary, limit: int) -> Array[String]:
	var out: Array[String] = []
	var space := _level.get_world_3d().direct_space_state
	var probe := PhysicsPointQueryParameters3D.new()
	probe.collision_mask = Mess.LAYER_HOUSE
	for key: String in planes:
		var tris: Array = planes[key]
		if tris.size() < 2:
			continue
		var n: Vector3 = tris[0][1]
		var d: float = n.dot(tris[0][2])
		var u := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
		var v := n.cross(u)
		var flat: Array = []
		for tri: Array in tris:
			var poly := PackedVector2Array()
			for k: int in [2, 3, 4]:
				var p: Vector3 = tri[k]
				poly.append(Vector2(p.dot(u), p.dot(v)))
			var rect := Rect2(poly[0], Vector2.ZERO).expand(poly[1]).expand(poly[2])
			flat.append([tri[0], poly, rect])
		for i in flat.size():
			for j in range(i + 1, flat.size()):
				var ri: Rect2 = flat[i][2]
				var rj: Rect2 = flat[j][2]
				if not ri.grow(-0.0005).intersects(rj.grow(-0.0005)):
					continue
				var area := 0.0
				for poly: PackedVector2Array in Geometry2D.intersect_polygons(flat[i][1], flat[j][1]):
					var part := absf(_area(poly))
					if part < 1e-6:
						continue
					var mid := Vector2.ZERO
					for q in poly:
						mid += q
					mid /= poly.size()
					# The faces' outward side: the stored triangles wind clockwise seen from outside.
					probe.position = u * mid.x + v * mid.y + n * d - n * 0.003
					if space.intersect_point(probe, 1).is_empty():
						area += part
				if area > 1e-5:
					out.append("%s and %s (plane %s, %.5f m2)" % [(flat[i][0] as Node).get_path(), (flat[j][0] as Node).get_path(), key, area])
					if out.size() >= limit:
						return out
	return out


static func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a / 2


## A small house by the grid convention on two floors (K14): four outer corners, a T at each end of
## a partition with a doorway, the upper storey the same on floor and ceiling tiles.
func _two_floors(at: Vector3) -> Node3D:
	var house := Node3D.new()
	house.name = "TwoFloors"
	house.position = at
	var h := _sizes.storey
	var put := func(file: String, pos: Vector3, deg: float) -> void:
		var p := _piece(file)
		p.position = pos
		p.rotation.y = deg_to_rad(deg)
		house.add_child(p, true)
	for y: float in [0.0, h]:
		put.call("corner_exterior", Vector3(0, y, 0), 0)
		put.call("corner_exterior", Vector3(3, y, 0), -90)
		put.call("corner_exterior", Vector3(3, y, 3), 180)
		put.call("corner_exterior", Vector3(0, y, 3), 90)
		put.call("wall_exterior_05m", Vector3(0.5, y, 0), 0)
		put.call("t_exterior_partition", Vector3(1.5, y, 0), 0)
		put.call("wall_exterior_05m", Vector3(2.0, y, 0), 0)
		put.call("wall_exterior_2m", Vector3(3, y, 0.5), -90)
		put.call("wall_exterior_05m", Vector3(2.5, y, 3), 180)
		put.call("t_exterior_partition", Vector3(1.5, y, 3), 180)
		put.call("wall_exterior_05m", Vector3(1.0, y, 3), 180)
		put.call("wall_exterior_2m", Vector3(0, y, 2.5), 90)
		put.call("door_partition", Vector3(1.5, y, 0.5), -90)
		put.call("wall_partition_1m", Vector3(1.5, y, 1.5), -90)
	for x in 3:
		for z in 3:
			put.call("floor_1m", Vector3(x, h, z), 0)
			put.call("ceiling_1m", Vector3(x, h, z), 0)
	return house


func case_k14_no_z_fight() -> void:
	await _station_level(false)
	_level.add_child(_two_floors(Vector3(-20, 0, -14)))
	var fights := _fights(_planes(_level), 40)
	for f in fights:
		_check(false, "no two faces fight: " + f)
	_check(fights.is_empty(), "no faces of the station, its floor and a two-floor house share a plane facing one way (%d found)" % fights.size())
	# The test would see a fight: a floor tile on the zoo floor's plane.
	var tile := _piece("floor_1m")
	tile.position = Vector3(20, 0, -15)
	_level.add_child(tile)
	await _physics_ticks(1)
	_check(not _fights(_planes(_level), 1).is_empty(), "a floor tile laid on the zoo floor is found fighting it")


func case_real_path_u_room() -> void:
	var player := await _station_level(true)
	var room := _level.get_node("HouseKit/URoom") as Node3D
	var local := func() -> Vector3: return room.to_local(player.global_position)
	# In at the front door (room x 1.3..2.2 of the north wall), facing south.
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return (local.call() as Vector3).z > 2.5, "the player to walk in at the front door")
	Input.action_release(&"move_forward")
	# Right (west) until the west partition stops it.
	Input.action_press(&"move_right")
	var last := (local.call() as Vector3).x
	var still := 0
	while still < 15:
		await _physics_ticks(1)
		var x := (local.call() as Vector3).x
		still = still + 1 if absf(x - last) < 0.0005 else 0
		last = x
	Input.action_release(&"move_right")
	_check(last > 0.06 + 0.3 and last < 0.06 + 0.5, "the partition stops the player beside it (x %s)" % last)
	# Up the west flight to the half landing.
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return (local.call() as Vector3).z > 7.7 and player.is_on_floor(), "the player to climb the west flight to the landing")
	Input.action_release(&"move_forward")
	_near((local.call() as Vector3).y, _sizes.storey / 2, 0.06, "the player stands on the half landing")
	# Across the landing, then up the east flight north to the upper floor.
	Input.action_press(&"move_left")
	await _until(func() -> bool: return (local.call() as Vector3).x > 1.8, "the player to cross the landing")
	Input.action_release(&"move_left")
	Input.action_press(&"move_back")
	await _until(func() -> bool: return (local.call() as Vector3).z < 5.0 and player.is_on_floor(), "the player to climb the east flight to the upper floor")
	_near((local.call() as Vector3).y, _sizes.storey, 0.06, "the player is on the upper floor, a storey up")
	# On north to the landing's window (x 0.7..1.8 of the north wall) until the wall stops it.
	Input.action_release(&"move_back")
	Input.action_press(&"move_right")
	await _until(func() -> bool: return (local.call() as Vector3).x < 1.4, "the player to step in front of the window")
	Input.action_release(&"move_right")
	Input.action_press(&"move_back")
	last = (local.call() as Vector3).z
	still = 0
	while still < 15:
		await _physics_ticks(1)
		var z := (local.call() as Vector3).z
		still = still + 1 if absf(z - last) < 0.0005 else 0
		last = z
	Input.action_release(&"move_back")
	var at := local.call() as Vector3
	_check(at.z < 0.6 and at.x > 0.7 and at.x < 1.8, "the player stands at the window (%s)" % at)
	_near(at.y, _sizes.storey, 0.06, "on the upper floor")
	var eye := player.global_position + Vector3(0, 1.5, 0)
	var ahead := PhysicsQueries.ray(_level, eye, eye + room.global_basis * Vector3(0, -0.4, -1.5), Mess.LAYER_HOUSE)
	_check(not ahead.is_empty() and room.to_local(ahead["position"] as Vector3).z < 0.06, "and looks out through the pane in the wall")
