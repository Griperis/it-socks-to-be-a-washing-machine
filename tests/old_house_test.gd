## The old house rebuilt from the house kit (house/03, Q2345): the two zoo stations, A with the old
## window widths and B with the widths rounded to 0.5 m (Q2381), built from kit pieces only at the
## plan's numbers (docs/architecture/house-kit-plan.md), painted with the old rooms' materials, with
## no two faces in one plane, beside the zoo (Q2386), and walked from the front door to the attic and
## from the basement out of the front door by the player's own input.
extends TestSuite

const PIECES := "res://game/house/kit/pieces"
const MATERIALS := "res://game/house/kit/materials"
const ZOO := "res://game/zoo/zoo.tscn"
const PLAYER := "res://game/player/player.tscn"
const STATION_A := "res://game/zoo/stations/old_house_a.tscn"
const STATION_B := "res://game/zoo/stations/old_house_b.tscn"
const EPS := 0.001
## The layer of the meshes' hollow shapes in the z-fight cases (_occluders()).
const OCCLUDE := 1 << 19
## The directions _inside_mesh() looks from, skewed off every axis.
const SKEW: Array[Vector3] = [Vector3(0.31, 0.83, 0.47), Vector3(-0.62, 0.41, 0.67), Vector3(0.53, -0.38, 0.76),
		Vector3(-0.44, -0.71, -0.55), Vector3(0.77, 0.29, -0.57), Vector3(0.97, 0.13, 0.21), Vector3(-0.96, -0.17, 0.22),
		Vector3(0.14, 0.97, -0.19), Vector3(-0.18, -0.96, 0.21), Vector3(0.16, -0.23, 0.96), Vector3(-0.21, 0.15, -0.97)]
## Floor tops by storey (plan K02).
const FLOOR_Y := {"Basement": -3.0, "Ground": 0.0, "First": 3.0, "Attic": 6.0}
## The doorways (plan K08): id, storey, axis of the wall line ("x": x = line), line, centre along,
## width.
const DOORWAYS: Array[Array] = [
	["D1", "Basement", "x", 4.0, 2.75, 0.9], ["D2", "Basement", "x", 4.0, 4.1, 0.9],
	["D3", "Basement", "z", 2.0, 5.25, 0.9], ["D4", "Basement", "x", 6.5, 4.75, 0.9],
	["D5", "Ground", "x", 4.0, 2.75, 0.9], ["D6", "Ground", "x", 6.5, 4.75, 0.9],
	["D7", "First", "x", 4.0, 2.75, 0.9], ["D8", "First", "x", 4.0, 4.1, 0.9],
	["D9", "First", "x", 6.5, 2.75, 0.9], ["D10", "First", "x", 6.5, 4.75, 0.9],
	["D11", "Ground", "z", 0.0, 5.75, 0.9], ["D12", "Basement", "z", 0.0, 8.25, 2.4],
]
## The windows in the outer walls (plan K06): id, storey, side, centre along, old width, grid width,
## sill (W12's over the ground floor).
const WINDOWS: Array[Array] = [
	["W1", "Basement", "N", 1.75, 1.2, 1.0, 1.75], ["W2", "Basement", "W", 6.75, 1.0, 1.0, 1.75],
	["W3", "Basement", "S", 3.25, 1.0, 1.0, 1.75], ["W4", "Basement", "E", 3.75, 1.0, 1.0, 1.75],
	["W5", "Ground", "N", 3.25, 1.0, 1.0, 1.1], ["W6", "Ground", "W", 7.25, 1.1, 1.0, 0.9],
	["W7", "Ground", "S", 1.75, 2.0, 2.0, 0.9], ["W8", "Ground", "N", 4.5, 0.5, 0.5, 1.3],
	["W9", "Ground", "N", 8.25, 1.2, 1.0, 0.9], ["W10", "Ground", "E", 4.75, 1.4, 1.5, 0.9],
	["W11", "Ground", "S", 8.25, 2.4, 2.5, 0.9], ["W12", "Ground", "S", 5.25, 1.5, 1.5, 2.4],
	["W13", "First", "N", 1.75, 1.2, 1.0, 0.9], ["W14", "First", "W", 1.75, 1.1, 1.0, 0.9],
	["W15", "First", "W", 7.75, 0.8, 1.0, 0.9], ["W16", "First", "S", 2.25, 1.4, 1.5, 0.9],
	["W17", "First", "N", 5.25, 1.1, 1.0, 0.9], ["W18", "First", "N", 7.75, 1.0, 1.0, 1.3],
	["W19", "First", "S", 8.0, 1.5, 1.5, 0.9],
]
## The rooms' paints by storey, centre line to centre line (make_house.py ROOMS, WALL_COLOURS).
const ROOMS := {
	"Basement": [[Rect2(0, 0, 4, 3.5), "wall_workshop", "basement_tile"], [Rect2(0, 3.5, 4, 5), "wall_bathroom", "basement_tile"],
			[Rect2(4, 0, 2.5, 2), "wall_boiler", "basement_tile"], [Rect2(4, 2, 2.5, 6.5), "wall_lobby", "basement_tile"],
			[Rect2(6.5, 0, 4, 8.5), "wall_garage", "basement_tile"]],
	"Ground": [[Rect2(0, 0, 4, 8.5), "wall_kitchen", "kitchen_tile"], [Rect2(4, 0, 2.5, 8.5), "wall_hall", "wood"],
			[Rect2(6.5, 0, 4, 8.5), "wall_kitchen", "wood"]],
	"First": [[Rect2(0, 0, 4, 3.5), "wall_office", "wood"], [Rect2(0, 3.5, 4, 5), "wall_bedroom", "wood"],
			[Rect2(4, 0, 2.5, 8.5), "wall_hall", "wood"], [Rect2(6.5, 0, 4, 3.5), "wall_bathroom", "bath_tile"],
			[Rect2(6.5, 3.5, 4, 5), "wall_kids", "wood"]],
	"Attic": [[Rect2(0, 0, 10.5, 8.5), "wall_loft", "loft_boards"]],
}

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "b01_kit_pieces_only", "method": "case_b01_kit_pieces_only", "world": false,
				"title": "B01: each house is built from the kit's pieces only, every one on the half-metre grid in 90 degree turns, on four storeys"},
		{"name": "b01_openings", "method": "case_b01_openings", "world": false,
				"title": "B01: every doorway lets a player through at the plan's place, every window piece is centred where the plan says, the stair, the shaft and the Cellar hatch are open"},
		{"name": "b02_materials", "method": "case_b02_materials", "world": false,
				"title": "B02: every wall face, floor and corner wears its room's old paint, the outside the old render"},
		{"name": "b05_two_sets", "method": "case_b05_two_sets", "world": false,
				"title": "B05: house A has the windows at their old widths, house B rounded to 0.5 m; nothing else differs"},
		{"name": "b06_beside_the_zoo", "method": "case_b06_beside_the_zoo", "world": false,
				"title": "B06: both houses are stations of the zoo on their own ground off the zoo floor, the ground reaching the zoo floor's edge"},
		{"name": "k14_no_z_fight_a", "method": "case_k14_no_z_fight_a", "world": false,
				"title": "K14: house A and its ground have no two faces facing the same way in one plane where they can be seen"},
		{"name": "k14_no_z_fight_b", "method": "case_k14_no_z_fight_b", "world": false,
				"title": "K14: house B and its ground have no two faces facing the same way in one plane where they can be seen"},
		{"name": "real_path_front_door_to_attic", "method": "case_real_path_front_door_to_attic", "world": false,
				"title": "real path: in house A the player walks in at the front door, is stopped by the hall's partition, and climbs the U stair to the first floor and on to the attic"},
		{"name": "real_path_basement_out", "method": "case_real_path_basement_out", "world": false,
				"title": "real path: in house B the player climbs from the basement to the ground floor, walks the hall and goes out of the front door onto the lawn"},
	]


func _before_case() -> void:
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


## A level of one station at the origin (its frame the house's), optionally with the player at
## `at` facing +Z and the level's Parts; physics ready.
func _station(path: String, player_at := Vector3.INF) -> Player:
	_level = Node3D.new()
	_level.name = "Level"
	var station := (load(path) as PackedScene).instantiate() as Node3D
	_level.add_child(station)
	var player: Player = null
	if player_at != Vector3.INF:
		player = (load(PLAYER) as PackedScene).instantiate() as Player
		player.position = player_at
		player.rotation.y = PI   # facing +Z
		_level.add_child(player)
		var parts := Parts.new()
		parts.name = "Parts"
		_level.add_child(parts)
	add_child(_level)
	if player != null:
		await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	else:
		await _physics_ticks(2)
	return player


func _house() -> Node3D:
	return _level.get_child(0).get_node("House") as Node3D


func _pieces(house: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for node: Node in house.find_children("*", "MeshInstance3D", true, false):
		if node.owner == house.owner:
			out.append(node as MeshInstance3D)
	return out


func _hit(from: Vector3, to: Vector3) -> Dictionary:
	return PhysicsQueries.ray(_level, from, to, Mess.LAYER_HOUSE)


func _clear(from: Vector3, to: Vector3) -> bool:
	return _hit(from, to).is_empty()


static func _on_grid(v: float) -> bool:
	return absf(v - snappedf(v, 0.5)) < EPS


## The material a piece shows on `slot`: its override, else its mesh's.
static func _shown(p: MeshInstance3D, slot: int) -> String:
	var m := p.get_surface_override_material(slot)
	if m == null:
		m = p.mesh.surface_get_material(slot)
	return m.resource_path.get_file().get_basename() if m != null else ""


func _storey_of(p: Node) -> String:
	var n := p
	while n != null and not FLOOR_Y.has(String(n.name)):
		n = n.get_parent()
	return String(n.name) if n != null else ""


# --- B01 ----------------------------------------------------------------------------------------

func case_b01_kit_pieces_only() -> void:
	for path: String in [STATION_A, STATION_B]:
		var station := (load(path) as PackedScene).instantiate() as Node3D
		var house := station.get_node("House") as Node3D
		var storeys := {}
		var count := 0
		var odd: Array[String] = []
		for p in _pieces(house):
			count += 1
			if not p.scene_file_path.begins_with(PIECES):
				odd.append("%s is no kit piece" % house.get_path_to(p))
				continue
			var at := house.to_local(p.global_transform.origin) if p.is_inside_tree() else _local(house, p)
			var turn := rad_to_deg(p.rotation.y)
			if not (_on_grid(at.x) and _on_grid(at.y) and _on_grid(at.z)):
				odd.append("%s is off the grid (%s)" % [house.get_path_to(p), at])
			if not is_equal_approx(snappedf(turn, 90.0), snappedf(turn, 0.01)) or absf(p.rotation.x) > EPS or absf(p.rotation.z) > EPS:
				odd.append("%s is not turned in 90 degree steps (%s)" % [house.get_path_to(p), turn])
			storeys[_storey_of(p)] = true
		for o: String in odd.slice(0, 10):
			_check(false, "%s: %s" % [path.get_file(), o])
		_check(odd.is_empty(), "%s: all %d meshes of the house are kit pieces on the grid in 90 degree turns" % [path.get_file(), count])
		_check(count > 400, "%s: the whole house is there (%d pieces)" % [path.get_file(), count])
		for s: String in FLOOR_Y:
			_check(storeys.has(s), "%s has its %s storey" % [path.get_file(), s])
			var node := house.get_node_or_null(s) as Node3D
			_check(node != null and is_equal_approx(node.position.y, FLOOR_Y[s]), "%s's %s floor is at y %s" % [path.get_file(), s, FLOOR_Y[s]])
		station.free()


## A node's position in `house`'s frame, out of the tree (the parents' positions added up).
static func _local(house: Node3D, p: Node3D) -> Vector3:
	var at := p.position
	var n := p.get_parent() as Node3D
	while n != null and n != house:
		at = n.transform * at
		n = n.get_parent() as Node3D
	return at


func case_b01_openings() -> void:
	await _station(STATION_A)
	var house := _house()
	# Each doorway lets a body 0.7 m wide and 1.8 m tall through at its place; just past each jamb
	# the wall stands.
	for d: Array in DOORWAYS:
		var y: float = FLOOR_Y[d[1]]
		var line: float = d[3]
		var c: float = d[4]
		var w: float = d[5]
		var across := func(along: float, h: float) -> bool:
			if d[2] == "x":
				return _clear(Vector3(line - 0.5, y + h, along), Vector3(line + 0.5, y + h, along))
			return _clear(Vector3(along, y + h, line - 0.5), Vector3(along, y + h, line + 0.5))
		var through := true
		for off: float in [-0.35, 0.0, 0.35]:
			for h: float in [0.3, 1.0, 1.8]:
				through = through and across.call(c + off, h)
		_check(through, "%s lets the player through at %s %s, along %s" % [d[0], d[2], line, c])
		_check(not across.call(c - w / 2 - 0.12, 1.0) and not across.call(c + w / 2 + 0.12, 1.0) and not across.call(c, 2.3),
				"%s has wall beside and over it" % d[0])
	# Each window piece is centred where the plan says (the piece's middle along its wall).
	for w: Array in WINDOWS:
		var node := house.get_node_or_null("%s/%s/%s" % [w[1], w[2], w[0]]) as MeshInstance3D
		_check(node != null, "%s is in its storey's %s wall" % [w[0], w[2]])
		if node == null:
			continue
		var box := node.mesh.get_aabb()
		var mid := node.global_transform * Vector3(box.get_center().x, 0, 0)
		var along := mid.x if w[2] in ["N", "S"] else mid.z
		_near(along, w[3], EPS, "%s is centred at %s along the %s wall" % [w[0], w[3], w[2]])
		var line := {"N": 0.0, "S": 8.5, "W": 0.0, "E": 10.5}
		var across := mid.z if w[2] in ["N", "S"] else mid.x
		_near(across, line[w[2]], EPS, "%s stands in the %s wall's line" % [w[0], w[2]])
	# Down the shaft from over the roof to the basement floor; down the stair's well to the basement;
	# down the Cellar hatch under the basement floor.
	var hit := _hit(Vector3(3.59, 12, 5.15), Vector3(3.59, -2.5, 5.15))
	_check(hit.is_empty() or (hit["position"] as Vector3).y > 8.0, "the shaft is under the roof only")
	hit = _hit(Vector3(3.59, 9.0, 5.15), Vector3(3.59, -4, 5.15))
	_check(not hit.is_empty() and absf((hit["position"] as Vector3).y + 3.0) < 0.01,
			"the shaft runs through the ground, first and attic floors to the basement floor (%s)" % [hit.get("position")])
	hit = _hit(Vector3(4.6, 5.9, 6.0), Vector3(4.6, -4, 6.0))
	_check(not hit.is_empty() and (hit["position"] as Vector3).y < 4.6 and (hit["position"] as Vector3).y > 3.0,
			"the attic floor is open over the U stair (%s)" % [hit.get("position")])
	_check(_clear(Vector3(2.75, -2.5, 1.75), Vector3(2.75, -4, 1.75)), "the Cellar hatch opens through the workshop floor")
	_check(not _clear(Vector3(2.0, -2.5, 3.0), Vector3(2.0, -4, 3.0)), "the workshop floor stands round it")
	# The roof over the attic, the ridge 3.88 m over its floor at z 4.25 (plan K11).
	hit = _hit(Vector3(2.0, 6.5, 4.25), Vector3(2.0, 12, 4.25))
	_check(not hit.is_empty() and absf((hit["position"] as Vector3).y - (6.0 + 3.88)) < 0.3, "the roof closes the attic at the ridge (%s)" % [hit.get("position")])
	for s: String in ["Basement", "Ground", "First"]:
		var stair := house.get_node("%s/Stair" % s).get_child(0) as Node3D
		_check(stair.position.is_equal_approx(Vector3(4, 0, 5.5)), "the %s's U stair stands on its well's corner, its first riser at z 5.5" % s)


# --- B02 ----------------------------------------------------------------------------------------

## The room paint a step off a point, or the outside render.
func _paint_at(storey: String, at: Vector3, column: int) -> String:
	if at.x <= 0.0 or at.x >= 10.5 or at.z <= 0.0 or at.z >= 8.5:
		return "wall_outside"
	for room: Array in ROOMS[storey]:
		if (room[0] as Rect2).has_point(Vector2(at.x, at.z)):
			return room[column]
	return ""


func case_b02_materials() -> void:
	await _station(STATION_A)
	var house := _house()
	var wrong: Array[String] = []
	var faced := 0
	for p in _pieces(house):
		var file := p.scene_file_path.get_file().get_basename()
		var storey := _storey_of(p)
		var xf := house.global_transform.affine_inverse() * p.global_transform
		var box := p.mesh.get_aabb()
		if file.begins_with("floor_"):
			var c := xf * Vector3(box.get_center().x, 0, box.get_center().z)
			if _shown(p, 0) != _paint_at(storey, c, 2):
				wrong.append("%s shows %s" % [house.get_path_to(p), _shown(p, 0)])
		elif file.begins_with("wall_") or file.begins_with("door_") or file.begins_with("window_"):
			faced += 1
			for slot: int in [0, 1]:
				var spot := xf * Vector3(box.get_center().x, 0, 0.3 if slot == 0 else -0.3)
				var want := _paint_at("Ground" if file == "window_stair" else storey, spot, 1)
				if _shown(p, slot) != want:
					wrong.append("%s slot %d shows %s, not %s" % [house.get_path_to(p), slot, _shown(p, slot), want])
		elif file.begins_with("corner_"):
			var inside := xf * Vector3(0.3, 0, 0.3)
			if _shown(p, 0) != _paint_at(storey, inside, 1) or _shown(p, 1) != "wall_outside":
				wrong.append("%s shows %s / %s" % [house.get_path_to(p), _shown(p, 0), _shown(p, 1)])
		elif file.begins_with("ceiling"):
			if _shown(p, 0) != "ceiling":
				wrong.append("%s shows %s" % [house.get_path_to(p), _shown(p, 0)])
	for w: String in wrong.slice(0, 10):
		_check(false, w)
	_check(wrong.is_empty() and faced > 100, "every wall face, floor, corner and ceiling wears its room's paint (%d wall pieces, %d wrong)" % [faced, wrong.size()])
	# Spot checks against the old house: the kitchen's tiles, the bathroom's, the loft's boards, the
	# hall's yellow beside the kitchen's cream on the x 4 partition, the laundry's bathroom green.
	var first_x4 := house.get_node("Ground/X4").get_child(0) as MeshInstance3D
	_check(_shown(first_x4, 0) == "wall_kitchen" and _shown(first_x4, 1) == "wall_hall", "the ground floor's x 4 partition is the kitchen's on its west face and the hall's on its east")
	var tiles := {"Ground": [1.0, 1.0, "kitchen_tile"], "First": [8.0, 1.0, "bath_tile"], "Attic": [1.0, 1.0, "loft_boards"],
			"Basement": [1.0, 6.0, "basement_tile"]}
	for s: String in tiles:
		var t: Array = tiles[s]
		var found := false
		for p in _pieces(house.get_node("%s/Floor" % s)):
			var at := p.position
			var side := p.mesh.get_aabb().size.x
			if t[0] >= at.x and t[0] < at.x + side and t[1] >= at.z and t[1] < at.z + side:
				found = _shown(p, 0) == t[2]
		_check(found, "the %s floor at x %s z %s is %s" % [s, t[0], t[1], t[2]])
	var laundry := house.get_node("Basement/Z3_5").get_child(0) as MeshInstance3D
	_check(_shown(laundry, 0) == "wall_bathroom" and _shown(laundry, 1) == "wall_workshop", "the laundry's walls have the old green, the workshop's its grey")


# --- B05, B06 -----------------------------------------------------------------------------------

func case_b05_two_sets() -> void:
	var a := (load(STATION_A) as PackedScene).instantiate() as Node3D
	var b := (load(STATION_B) as PackedScene).instantiate() as Node3D
	var ha := a.get_node("House")
	var hb := b.get_node("House")
	var pa := _pieces(ha)
	var pb := _pieces(hb)
	var width := func(p: MeshInstance3D) -> float:
		return float(p.scene_file_path.get_file().get_slice("_", 1)) / 100.0
	for w: Array in WINDOWS:
		if w[0] == "W12":
			continue
		var path := "%s/%s/%s" % [w[1], w[2], w[0]]
		var na := ha.get_node_or_null(path) as MeshInstance3D
		var nb := hb.get_node_or_null(path) as MeshInstance3D
		_check(na != null and nb != null, "both houses have %s" % w[0])
		if na != null and nb != null:
			_near(width.call(na), w[4], EPS, "house A's %s is the old %s m wide" % [w[0], w[4]])
			_near(width.call(nb), w[5], EPS, "house B's %s is rounded to %s m" % [w[0], w[5]])
	for pair: Array in [["Attic/Walls/W20", "gable_exterior_mirrored", "gable_exterior_grid_mirrored"],
			["Attic/Walls/W21", "gable_exterior", "gable_exterior_grid"], ["Attic/Roof/W22", "dormer", "dormer_grid"]]:
		_check(ha.get_node(pair[0]).scene_file_path.ends_with("/%s.tscn" % pair[1]) and hb.get_node(pair[0]).scene_file_path.ends_with("/%s.tscn" % pair[2]),
				"%s: house A's %s, house B's %s" % [pair[0], pair[1], pair[2]])
	# Away from the windows the houses are the same piece for piece.
	var plain := func(list: Array[MeshInstance3D], house: Node) -> Dictionary:
		var out := {}
		for p in list:
			var file := p.scene_file_path.get_file()
			if file.begins_with("window_") or file.begins_with("wall_exterior_") or file.begins_with("gable_") or file.begins_with("dormer"):
				continue
			out["%s %s" % [house.get_path_to(p), file]] = true
		return out
	var ka: Dictionary = plain.call(pa, ha)
	var kb: Dictionary = plain.call(pb, hb)
	_check(ka.size() > 300 and ka.keys() == kb.keys(), "every other piece is the same in both houses (%d, %d)" % [ka.size(), kb.size()])
	a.free()
	b.free()


func case_b06_beside_the_zoo() -> void:
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(zoo)
	await _physics_ticks(2)
	var floor_box := Rect2(-20, -60, 40, 80)   # the zoo floor (zoo.tscn Floor)
	for n: String in ["OldHouseA", "OldHouseB"]:
		var station := zoo.get_node_or_null("Stations/" + n) as Node3D
		_check(station != null, "%s is a station of the zoo" % n)
		if station == null:
			continue
		var house := station.get_node("House") as Node3D
		var corners := [house.to_global(Vector3(-0.1, 0, -0.1)), house.to_global(Vector3(10.6, 0, 8.6))]
		var foot := Rect2(Vector2(corners[0].x, corners[0].z), Vector2.ZERO).expand(Vector2(corners[1].x, corners[1].z))
		_check(not foot.intersects(floor_box), "%s stands off the zoo floor (%s)" % [n, foot])
		var ground_top := PhysicsQueries.ray(zoo, Vector3(20.5, 5, foot.get_center().y), Vector3(20.5, -1, foot.get_center().y), 0xFFFFFFFF)
		if n == "OldHouseA":
			_check(not ground_top.is_empty() and absf((ground_top["position"] as Vector3).y) < EPS,
					"its ground meets the zoo floor's edge at the zoo floor's height")
	var a := zoo.get_node("Stations/OldHouseA") as Node3D
	var b := zoo.get_node("Stations/OldHouseB") as Node3D
	_check(a.position.x - 3.0 == 20.0, "house A's ground starts at the zoo floor's east edge")
	_check(is_equal_approx(b.position.x - a.position.x, 27.0) and b.position.z == a.position.z, "house B's ground runs on from house A's")
	zoo.free()


# --- K14 ----------------------------------------------------------------------------------------

func case_k14_no_z_fight_a() -> void:
	await _z_fight(STATION_A)


func case_k14_no_z_fight_b() -> void:
	await _z_fight(STATION_B)


func _z_fight(path: String) -> void:
	await _station(path)
	_occluders()
	await _physics_ticks(2)
	# The inside test itself: inside the hall's first skirting board, and in the hall's air.
	var space := _level.get_world_3d().direct_space_state
	_check(_inside_mesh(space, Vector3(4.07, 0.05, 1.0)), "a point in the hall's west skirting is inside a mesh")
	_check(not _inside_mesh(space, Vector3(5.25, 1.2, 2.0)), "a point in the hall's air is inside none")
	var fights := _fights(_planes(_level), 30)
	for f in fights:
		_check(false, "no two faces fight: " + f)
	_check(fights.is_empty(), "%s: no two faces share a plane facing one way where they can be seen (%d found)" % [path.get_file(), fights.size()])
	# The test would see a fight: a floor tile laid on the lawn, and one beside a skirting board.
	for at: Vector3 in [Vector3(14, 0, 2), Vector3(4.06, 0.12, 1.0)]:
		var tile := (load(PIECES.path_join("floor_05m.tscn")) as PackedScene).instantiate() as MeshInstance3D
		tile.position = at
		_level.add_child(tile)
		await _physics_ticks(1)
		_check(not _fights(_planes(_level), 1).is_empty(), "a floor tile at %s is found fighting" % at)
		tile.free()


## Every mesh of the level as a hollow shape on its own layer, for _inside_mesh(): trim (skirting, casings)
## has no collider, yet hides what is behind it.
func _occluders() -> void:
	var body := StaticBody3D.new()
	body.name = "Occluders"
	body.collision_layer = OCCLUDE
	body.collision_mask = 0
	var shapes := {}
	for node: Node in _level.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		if not shapes.has(mi.mesh):
			var made := mi.mesh.create_trimesh_shape()
			made.backface_collision = true
			shapes[mi.mesh] = made
		var cs := CollisionShape3D.new()
		cs.shape = shapes[mi.mesh]
		cs.transform = mi.global_transform
		body.add_child(cs)
	_level.add_child(body)


## Whether a point lies inside some mesh (a skirting board, a casing: trim has no collider): from the
## point, a ray in one of a few skewed directions meets the inside of a face first. In open air every
## ray meets an outside first; where two faces meet face to face the first hit is either, so a
## direction whose first back face is no nearer than a front face says nothing.
func _inside_mesh(space: PhysicsDirectSpaceState3D, at: Vector3) -> bool:
	for dir: Vector3 in SKEW:
		var query := PhysicsRayQueryParameters3D.create(at, at + dir.normalized() * 2.0, OCCLUDE)
		query.hit_back_faces = true
		var any := space.intersect_ray(query)
		if any.is_empty():
			continue
		query.hit_back_faces = false
		var front := space.intersect_ray(query)
		if front.is_empty() or at.distance_to(front["position"] as Vector3) > at.distance_to(any["position"] as Vector3) + 0.00001:
			return true
	return false


## Every triangle of every mesh under `root`, in world space, bucketed by its plane (the normal and
## the distance from the origin, rounded): faces facing the same way in one plane (as house_kit_test).
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
## in front of the overlap is inside no collider (as house_kit_test).
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
					probe.position = u * mid.x + v * mid.y + n * d - n * 0.003
					if space.intersect_point(probe, 1).is_empty() and not _inside_mesh(space, probe.position):
						area += part
				if area > 1e-5:
					out.append("%s and %s (plane %s, %.5f m2)" % [_level.get_path_to(flat[i][0] as Node), _level.get_path_to(flat[j][0] as Node), key, area])
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


# --- The real path ------------------------------------------------------------------------------

## Holds `action` until `cond` holds, then lets go.
func _walk(action: StringName, cond: Callable, what: String) -> void:
	Input.action_press(action)
	await _until(cond, what, 1200)
	Input.action_release(action)


## Holds `action` until the player stops moving along `axis` (0 x, 2 z); returns where it stopped.
func _walk_to_stop(player: Player, action: StringName, axis: int) -> float:
	Input.action_press(action)
	var last := player.global_position[axis]
	var still := 0
	var frames := 0
	while still < 15 and frames < 900:
		await _physics_ticks(1)
		frames += 1
		var v := player.global_position[axis]
		still = still + 1 if absf(v - last) < 0.0005 else 0
		last = v
	Input.action_release(action)
	return last


## Up one storey's U stair from beside the well's west partition, the player facing +Z: south up the
## west flight to the half landing, east across it, north up the east flight to the floor above.
func _climb(player: Player, floor_y: float) -> void:
	var at := func() -> Vector3: return player.global_position
	await _walk(&"move_forward", func() -> bool: return (at.call() as Vector3).z > 7.7 and player.is_on_floor(),
			"the player to climb the west flight to the half landing over y %s" % floor_y)
	_near((at.call() as Vector3).y, floor_y + 1.5, 0.06, "the player stands on the half landing over y %s" % floor_y)
	await _walk(&"move_left", func() -> bool: return (at.call() as Vector3).x > 5.8, "the player to cross the landing")
	await _walk(&"move_back", func() -> bool: return (at.call() as Vector3).z < 5.0 and player.is_on_floor(),
			"the player to climb the east flight to the floor over y %s" % floor_y)
	_near((at.call() as Vector3).y, floor_y + 3.0, 0.06, "the player is a storey up, on y %s" % (floor_y + 3.0))


func case_real_path_front_door_to_attic() -> void:
	var player := await _station(STATION_A, Vector3(5.75, 0, -1.5))
	var at := func() -> Vector3: return player.global_position
	# In at the front door (x 5.3..6.2 of the north wall) and down the hall.
	await _walk(&"move_forward", func() -> bool: return (at.call() as Vector3).z > 4.2, "the player to walk in at the front door and down the hall")
	_near((at.call() as Vector3).y, 0.0, 0.06, "the player walks the ground floor")
	# Right (west) until the x 4 partition stops it, beside the up flight.
	var x := await _walk_to_stop(player, &"move_right", 0)
	_check(x > 4.06 + 0.3 and x < 4.06 + 0.5, "the hall's west partition stops the player beside it (x %s)" % x)
	await _climb(player, 0.0)
	# On the first floor's landing, back west beside the next up flight, and up again.
	await _walk(&"move_right", func() -> bool: return (at.call() as Vector3).x < 4.65, "the player to step beside the attic's flight")
	await _climb(player, 3.0)
	var top := at.call() as Vector3
	_check(top.z < 5.5 and top.x > 5.2 and top.x < 6.5, "the player stands in the attic beside the balustrade (%s)" % top)
	var eye := top + Vector3(0, 1.6, 0)
	var roof := _hit(eye, eye + Vector3(0, 4, 0))
	_check(not roof.is_empty() and (roof["position"] as Vector3).y > 7.7 and (roof["position"] as Vector3).y < 9.9, "the roof is over the player's head in the attic (%s)" % [roof.get("position")])


func case_real_path_basement_out() -> void:
	var player := await _station(STATION_B, Vector3(4.6, -3.0, 4.0))
	var at := func() -> Vector3: return player.global_position
	_near((at.call() as Vector3).y, -3.0, 0.06, "the player stands in the basement's stair lobby")
	await _climb(player, -3.0)
	# North along the hall and out of the front door onto the lawn.
	await _walk(&"move_right", func() -> bool: return (at.call() as Vector3).x < 5.8, "the player to line up with the front door")
	await _walk(&"move_back", func() -> bool: return (at.call() as Vector3).z < -1.0 and player.is_on_floor(),
			"the player to walk up the hall and out of the front door")
	var out := at.call() as Vector3
	_near(out.y, 0.0, 0.06, "the player stands on the lawn outside the front door (%s)" % out)
	_check(out.x > 5.3 and out.x < 6.2, "having gone out through the doorway (x %s)" % out.x)
