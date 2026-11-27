## The house (house/03, house/04): its shell, the old house rebuilt from the house kit with its
## windows rounded to 0.5 m (Q2381, Q2503), built from kit pieces only at the plan's numbers
## (docs/architecture/house-kit-plan.md), painted with the old rooms' materials, with the bathroom's
## tile wainscot (D01), the elevator shaft's walls (D07), nothing through the roof (D09) and no two
## faces in one plane; and the level game/house/house.tscn, the project's main scene (Q2509): the
## shell, the old furniture where the old house had it (Q2510), the old lamps and the zoo's noon
## light (Q2512), the player at the old spawn and the shared-state path (a Host of one; --host and
## --join). Walked by the player's own input from the spawn to every floor, and from the front door
## to the attic.
extends TestSuite

const PIECES := "res://game/house/kit/pieces"
const MATERIALS := "res://game/house/kit/materials"
const PLAYER := "res://game/player/player.tscn"
const SHELL := "res://game/house/shell.tscn"
const HOUSE := "res://game/house/house.tscn"
const RUNTIME := "res://game/level/level_runtime.tscn"
const FURNITURE := "res://game/furniture"
## The least wall time a wait on the house's laying gives it: on a busy machine the loading screen's
## slices shrink (SliceClock lets fewer units fit), so the laying takes more frames, not a set number.
const LAYING_S := 20.0
## How many times house:h09_slices_within_budget lays the house: a unit's least time over these is its
## own work, not a busy machine's (maintenance/13).
const H09_LAYINGS := 3
## The old spawn moved to the plan (room.gd spawn_pos 1.58, -2.9, 5.59 in the laundry, spawn_yaw).
const SPAWN := Vector3(1.68, -3.0, 5.87)
const SPAWN_YAW := 0.922
## The old room light (room.gd LAMP_COLOUR) and the old lamp's.
const LAMP_COLOUR := Color(1.0, 0.88, 0.7)
## The shaft's hole (plan K09): x 3.24..3.94 (the x 4 partition's face), z 4.8..5.5.
const SHAFT := Rect2(3.24, 4.8, 0.7, 0.7)
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
			[Rect2(4, 0, 2.5, 8.5), "wall_hall", "wood"], [Rect2(6.5, 0, 4, 3.5), "wall_bathroom_tiled", "bath_tile"],
			[Rect2(6.5, 3.5, 4, 5), "wall_kids", "wood"]],
	"Attic": [[Rect2(0, 0, 10.5, 8.5), "wall_loft", "loft_boards"]],
}

var _level: Node3D = null
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "b01_kit_pieces_only", "method": "case_b01_kit_pieces_only", "world": false,
				"title": "B01: the shell is built from the kit's pieces only, every one on the half-metre grid in 90 degree turns, on four storeys"},
		{"name": "b01_openings", "method": "case_b01_openings", "world": false,
				"title": "B01: every doorway lets a player through at the plan's place, every window piece is centred where the plan says, the stair is open"},
		{"name": "b02_materials", "method": "case_b02_materials", "world": false,
				"title": "B02: every wall face, floor and corner wears its room's old paint, the outside the old render"},
		{"name": "b05_grid_windows", "method": "case_b05_grid_windows", "world": false,
				"title": "B05: the house has the windows rounded to 0.5 m (house B, Q2503)"},
		{"name": "d01_wainscot", "method": "case_d01_wainscot", "world": false,
				"title": "D01: the bathroom's walls have the old tile wainscot to 1.2 m and a trim band over it; no other room has it"},
		{"name": "d07_shaft", "method": "case_d07_shaft", "world": false,
				"title": "D07: the elevator shaft has walls round its hole on every storey, its hatch open at the old faces, its sill out of it, the attic's closed by a lid"},
		{"name": "d09_roof", "method": "case_d09_roof", "world": false,
				"title": "D09: nothing in the attic comes out through the roof (the balustrade's ends stop under the slope)"},
		{"name": "k14_no_z_fight", "method": "case_k14_no_z_fight", "world": false,
				"title": "K14: the shell has no two faces facing the same way in one plane where they can be seen"},
		{"name": "h01_main_scene", "method": "case_h01_main_scene", "world": false,
				"title": "the house is the level the title's Solo and Host play (core/58): the shell, the player, the shared-state path, the zoo's noon light, and nothing of game/zoo/"},
		{"name": "h02_furniture", "method": "case_h02_furniture", "world": false,
				"title": "the old furniture stands where the old house had it, moved to the plan, each piece on its floor inside its room"},
		{"name": "h03_lights", "method": "case_h03_lights", "world": false,
				"title": "every old room light hangs in its room, the old lamps' lights at their lamps, with the old colour, energy, range and shadow"},
		{"name": "h04_coop", "method": "case_h04_coop", "world": false,
				"title": "the house is played alone as a Host of one; with --host and --join a second house joins it and each sees the other's avatar"},
		{"name": "real_path_doors_shut", "method": "case_real_path_doors_shut", "world": false,
				"title": "real path (Q2514): the front door and the garage door stay shut: aimed at, no prompt and no outline, the use button opens nothing, and the player walking at the front door stops at it"},
		{"name": "real_path_spawn_to_every_floor", "method": "case_real_path_spawn_to_every_floor", "world": false,
				"title": "real path: in the house the player starts at the old spawn in the laundry, walks through the doorway to the stair lobby and climbs the U stair to the ground, first and attic floors"},
		{"name": "h05_mess", "method": "case_h05_mess", "world": false,
				"title": "house/05: each floor's Sock generator lays the old stage's Pairs (50, 160, 150, 130) of its floor's two Cabinets' Collections on every kind of place, each Sock on its floor; the old eight Cabinets stand at the old spots; the laying time is measured"},
		{"name": "h05_stair_treads", "method": "case_h05_stair_treads", "world": false,
				"title": "house/05 (Q2530): the stair trails' Socks lie flat on the steps' treads, never leaned on the ramp; the player does not meet the treads"},
		{"name": "real_path_loading_screen", "method": "case_real_path_loading_screen", "world": false,
				"title": "real path (house/09, Q2542): F5 shows the loading screen (\"Loading the house...\", Q2579, a filling bar) while the Socks are laid a slice per frame, the player held at the spawn though walk is pressed; then every Socks appears at once and the player walks"},
		{"name": "h09_slices_within_budget", "method": "case_h09_slices_within_budget", "world": false, "perf": true,
				"title": "house/09: no frame's slice of laying the house does more work than the loading screen's slice budget (each unit at its least time over three layings, so a busy machine cannot fail it): each unit of work runs only when the longest of its kind still fits"},
		{"name": "h09_same_seed_sliced", "method": "case_h09_same_seed_sliced", "world": false,
				"title": "house/09: the same seed lays the same Socks (Designs, poses, generators' records) all in one frame and over many frames"},
		{"name": "h09_trail_stays_on_treads", "method": "case_h09_trail_stays_on_treads", "world": false,
				"title": "house/09 (Q2530): the stair trails' Socks laid flat on the treads stay lying there through 120 ticks of play (a tread holds a Sock up)"},
		{"name": "real_path_kitchen_loop", "method": "case_real_path_kitchen_loop", "world": false,
				"title": "real path (house/05, core/60): in the house the player picks the top Sock of a kitchen Heap, picks its mate into a Pair, shelves it in the kitchen's Cabinet with a click and earns Coins"},
		{"name": "real_path_front_door_to_attic", "method": "case_real_path_front_door_to_attic", "world": false,
				"title": "real path: in the shell the player walks in from the front door (no ground outside, Q2503), is stopped by the hall's partition, and climbs the U stair to the first floor and on to the attic"},
		{"name": "r01_run_placed", "method": "case_r01_run_placed", "world": false,
				"title": "core/91: the house's run is placed: Run with the house's plan, the three floor locks at the old places (the tops of the ground's and the first floor's flights shut by a door, the foot of the attic's by the gate, each with its floor), the Cabinets' unlock_stage (the garage's 2, sheeted), the generators' floors with lays_at_start off, the four Machine Parts, the washer's slot and the Stage bar"},
		{"name": "r02_new_game_lays_stage1", "method": "case_r02_new_game_lays_stage1", "world": false,
				"title": "core/91 (core/77): a house New Game lays Stage 1 behind the loading screen (the Stage spawner the Mess's layer, its bar filling): only Simple Pairs, all on the basement, alone with no high pass"},
		{"name": "r03_high_spots_two_players", "method": "case_r03_high_spots_two_players", "world": false,
				"title": "core/91 (core/77, Q664): with two players present at Stage 1's spawn a few of its Socks lie on a top at least 1.7 m over the basement"},
		{"name": "real_path_new_game_from_title", "method": "case_real_path_new_game_from_title", "world": false,
				"title": "real path (core/91): a house New Game from the title (Solo, the debug Pairs per Drawer slider on its New Game page): only the basement holds Socks, the garage Cabinet is sheeted, the player climbing the stair is stopped by the ground floor's door, and a Pair clicked into the laundry Cabinet moves the Stage bar"},
	]


func _before_case() -> void:
	SockGenerator.start_all = true  # the house lays its starting Mess here, as before the run (core/77)
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	for screen: Node in [_title, _lobby]:
		if screen != null and is_instance_valid(screen):
			screen.free()
	_title = null
	_lobby = null
	_drop_branches()


## A level of the shell at the origin (its frame the house's), optionally with the player at `at`
## facing +Z and the level's Parts; physics ready.
func _shell(player_at := Vector3.INF) -> Player:
	_level = Node3D.new()
	_level.name = "Level"
	var shell := (load(SHELL) as PackedScene).instantiate() as Node3D
	_level.add_child(shell)
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
	return _level.get_child(0) as Node3D


## The house level, in the tree; its Socks laid, physics ready and the player standing. The loading
## screen holds the player while it lays a slice per frame, and a busy machine makes those slices
## short (a unit's time grows, so fewer fit), so the laying is waited for in wall time, not frames.
func _level_up() -> Node3D:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	var player := rt.player
	await _until(rt.loading.is_lifted, "the house's Socks to be laid", 900, LAYING_S)
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand in the house")
	await _first_wash_done(_level)
	return _level


## The First wash is over (core/94, played in tests/first_wash_test.gd): the held Stage 1 Socks lie and the
## Laundry day is DONE, as the Host's answers leave them, so the run reads as before it.
func _first_wash_done(house: Node3D) -> void:
	var rt := LevelRuntime.of(house)
	var stages := house.get_node("Run/Stages") as Stages
	var day := house.get_node("LaundryDay/Day") as LaundryDay
	# With start_all the generators lay the starting Mess and the run's spawner stays idle (core/77).
	await _until(func() -> bool: return stages.stage == 0 and (SockGenerator.start_all or stages.due.is_empty()), "Stage 1's Socks to be laid and held", 3000, 20.0)
	if stages.holding:
		rt.parts.apply(stages.lay_first_answer())
	rt.parts.apply({"ok": true, "changes": {day.id: {"first_wash": LaundryDay.FirstWash.DONE}}})


func _pieces(house: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var own := house if house.owner == null else house.owner
	for node: Node in house.find_children("*", "MeshInstance3D", true, false):
		if node.owner == own:
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
	for path: String in [SHELL]:
		var station := (load(path) as PackedScene).instantiate() as Node3D
		var house := station
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
			# The bathroom's trim strips stand off wall faces, off the half-metre grid (house/07).
			if not p.scene_file_path.get_file().begins_with("wainscot_trim_") and not (_on_grid(at.x) and _on_grid(at.y) and _on_grid(at.z)):
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
	await _shell()
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
	# Down the stair's well to the basement; the basement floor has no hatch (house/07).
	var hit := _hit(Vector3(4.6, 5.9, 6.0), Vector3(4.6, -4, 6.0))
	_check(not hit.is_empty() and (hit["position"] as Vector3).y < 4.6 and (hit["position"] as Vector3).y > 3.0,
			"the attic floor is open over the U stair (%s)" % [hit.get("position")])
	_check(not _clear(Vector3(2.75, -2.5, 1.75), Vector3(2.75, -4, 1.75)), "the workshop floor is whole where the Cellar hatch was (house/07)")
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
	await _shell()
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

func case_b05_grid_windows() -> void:
	var shell := (load(SHELL) as PackedScene).instantiate() as Node3D
	var width := func(p: MeshInstance3D) -> float:
		return float(p.scene_file_path.get_file().get_slice("_", 1)) / 100.0
	for w: Array in WINDOWS:
		if w[0] == "W12":
			continue
		var node := shell.get_node_or_null("%s/%s/%s" % [w[1], w[2], w[0]]) as MeshInstance3D
		_check(node != null, "the house has %s" % w[0])
		if node != null:
			_near(width.call(node), w[5], EPS, "%s is rounded to %s m" % [w[0], w[5]])
	for pair: Array in [["Attic/Walls/W20", "gable_exterior_grid_mirrored"], ["Attic/Walls/W21", "gable_exterior_grid"],
			["Attic/Roof/W22", "dormer_grid"]]:
		_check(shell.get_node(pair[0]).scene_file_path.ends_with("/%s.tscn" % pair[1]), "%s is the %s" % [pair[0], pair[1]])
	shell.free()


# --- D01, D07, D09 ------------------------------------------------------------------------------

func case_d01_wainscot() -> void:
	var tiled := load(MATERIALS.path_join("wall_bathroom_tiled.tres")) as ShaderMaterial
	_check(tiled != null and tiled.shader != null, "the tiled bathroom paint is a shader material")
	if tiled == null:
		return
	_near(float(tiled.get_shader_parameter("top")), 1.2, EPS, "the tiles reach 1.2 m over the floor (make_flat.py make_wall_tiles)")
	_near(float(tiled.get_shader_parameter("band")), 0.0, EPS, "no painted band over them: the trim is a raised strip (house/07)")
	var strips := 0
	var shell := (load(SHELL) as PackedScene).instantiate() as Node3D
	for p in _pieces(shell):
		if p.scene_file_path.get_file().begins_with("wainscot_trim_"):
			strips += 1
			_near(p.mesh.get_aabb().position.y, 1.2, EPS, "%s sits at the tiles' top" % p.name)
	_check(strips == 5, "the bathroom has its five trim strips (%d)" % strips)
	shell.free()
	_check(tiled.get_shader_parameter("tiles") is Texture2D and String((tiled.get_shader_parameter("tiles") as Texture2D).resource_path).ends_with("wall_tiles.png"),
			"the tiles are the old wall tiles")
	_check(tiled.get_shader_parameter("paint") == (load(MATERIALS.path_join("wall_bathroom.tres")) as StandardMaterial3D).albedo_color,
			"over them the bathroom's paint")
	await _shell()
	var house := _house()
	var faces := 0
	var elsewhere := 0
	for p in _pieces(house):
		for slot in p.get_surface_override_material_count():
			if _shown(p, slot) != "wall_bathroom_tiled":
				continue
			var xf := house.global_transform.affine_inverse() * p.global_transform
			var spot := xf * Vector3(p.mesh.get_aabb().get_center().x, 0, 0.3 if slot == 0 else -0.3)
			if _storey_of(p) == "First" and Rect2(6.5, 0, 4, 3.5).has_point(Vector2(spot.x, spot.z)):
				faces += 1
			else:
				elsewhere += 1
	_check(faces >= 8, "the bathroom's wall faces wear the wainscot (%d)" % faces)
	_same(elsewhere, 0, "no face outside the bathroom wears it")
	var laundry := house.get_node("Basement/Z3_5").get_child(0) as MeshInstance3D
	_same(_shown(laundry, 0), "wall_bathroom", "the laundry keeps the plain green")


func case_d07_shaft() -> void:
	await _shell()
	var house := _house()
	var want := {"Basement": "shaft_hatch_w", "Ground": "shaft_hatch_w", "First": "shaft_closed", "Attic": "shaft_attic"}
	for st: String in want:
		var group := house.get_node_or_null("%s/Shaft" % st)
		var piece := group.get_child(0) as MeshInstance3D if group != null and group.get_child_count() > 0 else null
		_check(piece != null and piece.scene_file_path.ends_with("/%s.tscn" % want[st]), "the %s has the shaft's %s" % [st, want[st]])
		if piece != null:
			_check(piece.position.is_equal_approx(Vector3(3, 0, 4.5)), "on the shaft's tile")
	var mid := SHAFT.get_center()
	for st: String in want:
		var y: float = FLOOR_Y[st]
		# The north and south walls, and the west one under the hatch, stand on the hole's edges.
		var n := _hit(Vector3(mid.x, y + 0.5, mid.y - 1.0), Vector3(mid.x, y + 0.5, mid.y))
		_check(not n.is_empty() and absf((n["position"] as Vector3).z - SHAFT.position.y) < 0.01, "%s: the shaft's north wall stands on the hole's edge (%s)" % [st, n.get("position")])
		var s := _hit(Vector3(mid.x, y + 0.5, mid.y + 1.0), Vector3(mid.x, y + 0.5, mid.y))
		_check(not s.is_empty() and absf((s["position"] as Vector3).z - SHAFT.end.y) < 0.01, "%s: its south wall too (%s)" % [st, s.get("position")])
		var w := _hit(Vector3(mid.x - 1.0, y + 0.5, mid.y), Vector3(mid.x, y + 0.5, mid.y))
		_check(not w.is_empty() and absf((w["position"] as Vector3).x - SHAFT.position.x) < 0.01, "%s: its west wall too (%s)" % [st, w.get("position")])
	# The hatch: at 1.1 m over the floor, open on the west in the basement and on the ground floor
	# (the ray reaches the x 4 partition), closed there on the first floor and in the attic.
	for st: String in want:
		var y: float = FLOOR_Y[st]
		var h := _hit(Vector3(mid.x - 1.0, y + 1.1, mid.y), Vector3(mid.x + 0.6, y + 1.1, mid.y))
		var x := (h["position"] as Vector3).x if not h.is_empty() else INF
		if want[st] == "shaft_hatch_w":
			_check(absf(x - 3.94) < 0.01, "%s: the hatch opens into the shaft from the west (%s)" % [st, x])
		else:
			_check(absf(x - SHAFT.position.x) < 0.01, "%s: the west wall is closed at the hatch's height (%s)" % [st, x])
	# The first floor's hatch is the partition's, onto the landing; the attic's faces east.
	for st: String in ["First", "Attic"]:
		var y: float = FLOOR_Y[st]
		var h := _hit(Vector3(mid.x + 1.0, y + 1.1, mid.y), Vector3(mid.x - 0.6, y + 1.1, mid.y))
		_check(not h.is_empty() and absf((h["position"] as Vector3).x - (SHAFT.position.x + 0.04)) < 0.01,
				"%s: from the east, the hatch opens into the shaft (%s)" % [st, h.get("position")])
		var low := _hit(Vector3(mid.x + 1.0, y + 0.4, mid.y), Vector3(mid.x - 0.6, y + 0.4, mid.y))
		_check(not low.is_empty() and (low["position"] as Vector3).x > SHAFT.end.x - 0.05, "%s: under the hatch the shaft is closed from the east (%s)" % [st, low.get("position")])
	# The sill sticks out of the hatch's face; down the shaft from under the attic's lid to the
	# basement floor; the lid closes it at 2.15 m over the attic floor.
	var sill := _hit(Vector3(SHAFT.position.x - 0.03, 2.0, mid.y), Vector3(SHAFT.position.x - 0.03, 0.5, mid.y))
	_check(not sill.is_empty() and absf((sill["position"] as Vector3).y - 0.805) < 0.01, "the ground floor's hatch has its sill out of its face (%s)" % [sill.get("position")])
	var down := _hit(Vector3(mid.x, 8.0, mid.y), Vector3(mid.x, -4, mid.y))
	_check(not down.is_empty() and absf((down["position"] as Vector3).y + 3.0) < 0.01, "the shaft runs open from the attic to the basement floor (%s)" % [down.get("position")])
	var lid := _hit(Vector3(mid.x, 9.0, mid.y), Vector3(mid.x, 6.5, mid.y))
	_check(not lid.is_empty() and absf((lid["position"] as Vector3).y - (6.0 + 2.15 + 0.04)) < 0.01, "the attic's lid closes the shaft (%s)" % [lid.get("position")])


## The roof's underside over the attic floor (house_kit_sizes roof_under) at a point of the plan.
static func _roof_under(x: float, z: float) -> float:
	var d := minf(z, 8.5 - z)
	return 0.4 + (d - 0.1) * tan(deg_to_rad(40.0))


func case_d09_roof() -> void:
	await _shell()
	var house := _house()
	var out: Array[String] = []
	for group: String in ["Stair", "Shaft"]:
		for p in _pieces(house.get_node("Attic/" + group)):
			var xf := house.global_transform.affine_inverse() * p.global_transform
			for s in p.mesh.get_surface_count():
				for v: Vector3 in p.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
					var at := xf * v
					if at.y - 6.0 > _roof_under(at.x, at.z) + 0.001:
						out.append("%s at %s" % [p.name, at])
	for o: String in out.slice(0, 5):
		_check(false, "comes out through the roof: " + o)
	_check(out.is_empty(), "the attic's stair, balustrade and shaft stay under the roof (%d points over it)" % out.size())


# --- K14 ----------------------------------------------------------------------------------------

func case_k14_no_z_fight() -> void:
	await _shell()
	_occluders()
	await _physics_ticks(2)
	# The inside test itself: inside the hall's first skirting board, and in the hall's air.
	var space := _level.get_world_3d().direct_space_state
	_check(_inside_mesh(space, Vector3(4.07, 0.05, 1.0)), "a point in the hall's west skirting is inside a mesh")
	_check(not _inside_mesh(space, Vector3(5.25, 1.2, 2.0)), "a point in the hall's air is inside none")
	var fights := _fights(_planes(_level), 30)
	for f in fights:
		_check(false, "no two faces fight: " + f)
	_check(fights.is_empty(), "the shell: no two faces share a plane facing one way where they can be seen (%d found)" % fights.size())
	# The test would see a fight: a floor tile laid on the hall's floor, and one beside a skirting board.
	for at: Vector3 in [Vector3(5.0, 0, 2.0), Vector3(4.06, 0.12, 1.0)]:
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
	var player := await _shell(Vector3(5.75, 0, 0.45))
	var at := func() -> Vector3: return player.global_position
	# In from the front door (x 5.3..6.2 of the north wall) and down the hall.
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


## Walks the player (facing +Z) to `to` (x, z) by its own buttons: forward and back along z, left
## and right along x, held while it is off by more than a few centimetres.
func _go(player: Player, to: Vector2, what: String) -> void:
	var keys := {&"move_forward": false, &"move_back": false, &"move_left": false, &"move_right": false}
	var frames := 0
	var d := Vector2.INF
	while frames < 900:
		d = to - Vector2(player.global_position.x, player.global_position.z)
		if d.length() < 0.08:
			break
		var want := {&"move_forward": d.y > 0.04, &"move_back": d.y < -0.04, &"move_left": d.x > 0.04, &"move_right": d.x < -0.04}
		for a: StringName in want:
			if want[a] != keys[a]:
				keys[a] = want[a]
				if want[a]:
					Input.action_press(a)
				else:
					Input.action_release(a)
		await _physics_ticks(1)
		frames += 1
	for a: StringName in keys:
		Input.action_release(a)
	_check(d.length() < 0.15, "%s (off by %.2f m)" % [what, d.length()])


func case_real_path_doors_shut() -> void:
	var house := await _level_up()
	var player := LevelRuntime.of(house).player
	# In the hall, facing the front door (north, -Z) from 1.5 m in.
	player.global_position = Vector3(5.75, 0.0, 1.5)
	player.rotation.y = 0.0
	(player.get_node("%Head") as Node3D).rotation.x = -0.15
	player.reset_physics_interpolation()
	await _physics_ticks(6)
	var hud := player.hud()
	_check(player.aimed_outline == null, "aimed at the front door, nothing is outlined")
	_same(hud.prompt_text(), "", "and no prompt shows")
	Input.action_press(Player.INTERACT)
	await _physics_ticks(2)
	Input.action_release(Player.INTERACT)
	await _physics_ticks(2)
	_same(hud.refusal_text(), "", "the use button says nothing")
	_check(player.interact() == null, "and finds nothing to use there")
	# Walking at it, the player stops at the door's leaf (in the wall's middle, z 0).
	var z := await _walk_to_stop(player, &"move_forward", 2)
	_check(z > 0.3 and z < 0.5, "the player is stopped by the shut front door (z %s)" % z)
	# Both doorways are closed from outside too: a ray at waist height meets each leaf in the wall's line.
	for d: Array in [["front door", Vector3(5.75, 1.0, -1.0)], ["garage door", Vector3(8.25, -2.0, -1.0)]]:
		var from: Vector3 = d[1]
		var hit := _hit(from, from + Vector3(0, 0, 2.0))
		_check(not hit.is_empty() and absf((hit["position"] as Vector3).z + 0.025) < 0.005, "the %s is shut (%s)" % [d[0], hit.get("position")])
		_check(hit.is_empty() or Parts.part_of(hit["collider"] as Node) == null, "the %s is no thing to open" % d[0])
	for n: String in ["Doors/FrontDoor", "Doors/GarageDoor"]:
		var odd := house.get_node(n).find_children("*", "", true, false).filter(func(c: Node) -> bool: return c is Part or c is Outline)
		_check(odd.is_empty(), "%s has no Part and no Outline" % n)


func case_real_path_spawn_to_every_floor() -> void:
	var house := await _level_up()
	await _open_floors(house)  # the floor locks stand open, as after the last Fix (core/91)
	var player := LevelRuntime.of(house).player
	var at := func() -> Vector3: return player.global_position
	_check((at.call() as Vector3).distance_to(SPAWN) < 0.1, "the player starts at the old spawn in the laundry (%s)" % at.call())
	_near(player.rotation.y, SPAWN_YAW, 0.01, "facing the old spawn's way")
	player.rotation.y = PI   # facing +Z: forward is south, left east
	# Round the ironing board, through the laundry's doorway (D2, z 3.65..4.55 of the x 4 partition)
	# into the stair lobby, beside the up flight.
	await _go(player, Vector2(2.4, 4.1), "the player walks to the laundry's doorway")
	await _go(player, Vector2(4.6, 4.1), "the player walks through it into the stair lobby")
	_near((at.call() as Vector3).y, -3.0, 0.06, "the player walks the basement")
	await _climb(player, -3.0)
	await _walk(&"move_right", func() -> bool: return (at.call() as Vector3).x < 4.65, "the player to step beside the first floor's flight")
	await _climb(player, 0.0)
	await _walk(&"move_right", func() -> bool: return (at.call() as Vector3).x < 4.65, "the player to step beside the attic's flight")
	await _climb(player, 3.0)
	var top := at.call() as Vector3
	_check(top.y > 5.9 and top.z < 5.5, "the player stands in the attic (%s)" % top)


# --- The level ----------------------------------------------------------------------------------

## Every res:// file `path` needs, through its dependencies.
static func _needs(path: String, seen: Dictionary) -> void:
	if seen.has(path):
		return
	seen[path] = true
	if not (path.ends_with(".tscn") or path.ends_with(".tres") or path.ends_with(".gd")):
		return
	for dep: String in ResourceLoader.get_dependencies(path):
		var p := dep.get_slice("::", dep.get_slice_count("::") - 1) if dep.contains("::") else dep
		if p.begins_with("uid://"):
			p = ResourceUID.ensure_path(p)
		if p.begins_with("res://"):
			_needs(p, seen)


func case_h01_main_scene() -> void:
	_same(String(ProjectSettings.get_setting("application/run/main_scene")), "res://game/ui/title/title.tscn", "the title is the project's main scene and Solo plays the house (core/58)")
	_same(Worlds.LEVEL, HOUSE, "Solo and Host go into the house")
	var house := await _level_up()
	var shell := house.get_node_or_null("Shell") as Node3D
	_check(shell != null and shell.scene_file_path == SHELL and shell.transform == Transform3D.IDENTITY, "the shell stands at the origin, the house's frame")
	var runtime := LevelRuntime.of(house)
	_check(runtime != null and runtime.scene_file_path == RUNTIME and runtime.get_parent() == house, "the house has one instance of the level runtime")
	for n: String in ["Player", "Parts", "Socks/Mess", "Socks/Hands", "Socks/Knockdowns", "Socks/Bank",
			"Avatars", "FlightSpawner", "Net", "Net/Hud/Mode"]:
		_check(runtime.get_node_or_null(n) != null, "the house has its %s, as the zoo" % n)
	# core/62: the Session and its Roster are the game link's (a private one when nothing started a game).
	for n: String in ["Session", "Session/Roster"]:
		_check(runtime.link != null and runtime.link.get_node_or_null(n) != null, "the house has its %s, as the zoo" % n)
	var net := runtime.net
	_check(net is LevelNet, "its co-op start is the game's LevelNet")
	_same((net as LevelNet).place_name(), "house", "which names the house")
	var parts := LevelRuntime.of(house).parts
	var door := house.get_node("Furniture/Fridge/Door_Top/Openable") as Part
	_check(door != null and door.parts == parts, "the furniture's openings are bound to the house's Parts (%s)" % (door.id if door != null else &""))
	var fresh := (load(HOUSE) as PackedScene).instantiate()
	var env := fresh.get_node("Environment") as WorldEnvironment
	_check(env.environment != null and env.environment.resource_path == "res://game/look/noon_environment.tres", "the zoo's noon sky and grade")
	fresh.free()
	var sun := house.get_node("Sun") as DirectionalLight3D
	_check(sun.shadow_enabled, "the zoo's sun, shadowed")
	var day_light := house.get_node("Systems/Day/DayLight") as DayLight
	_check(day_light.picture == house.get_node("Picture") and sun.visible and sun.light_energy > 1.0,
			"the house's day lights it (core/160: the sun of %.2f h at %.2f)" % [day_light.hour, sun.light_energy])
	_check(house.get_node_or_null("Picture") != null, "and its picture (AgX, grade)")
	var seen := {}
	_needs(HOUSE, seen)
	var zoo: Array = seen.keys().filter(func(p: String) -> bool: return p.begins_with("res://game/zoo/"))
	_check(zoo.is_empty(), "the house needs nothing of game/zoo/ (%s)" % [zoo])


## The storeys' floors.
const FLOORS: Array[float] = [-3.0, 0.0, 3.0, 6.0]
## The old rooms by storey (the old layout's names; a stair room's light hangs over its floor's well).
const ROOM_FLOORS := {"Basement": ["workshop", "laundry", "boiler", "stair_lobby", "garage", "stairs_basement"],
		"Ground": ["kitchen", "hall", "living", "stairs_ground"],
		"First": ["office", "bedroom", "landing", "bathroom", "kids", "stairs_first"]}


func case_h02_furniture() -> void:
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var pieces := house.get_node("Furniture").get_children()
	_same(pieces.size(), 66, "every old placement of the house's four floors is there (66; the Grotto's are not)")
	var wrong: Array[String] = []
	for node in pieces:
		var p := node as Node3D
		if not p.scene_file_path.begins_with(FURNITURE + "/"):
			wrong.append("%s is no furniture scene" % p.name)
		var at := p.position
		if at.x < 0.1 or at.x > 10.4 or at.z < 0.1 or at.z > 8.4:
			wrong.append("%s stands outside the house's walls (%s)" % [p.name, at])
		var on_floor := FLOORS.any(func(f: float) -> bool: return at.y >= f - EPS and at.y < f + 2.3)
		if not on_floor:
			wrong.append("%s is on no floor (%s)" % [p.name, at])
		if absf(p.rotation.x) > EPS or absf(p.rotation.z) > EPS:
			wrong.append("%s is tipped" % p.name)
	for w: String in wrong.slice(0, 8):
		_check(false, w)
	_check(wrong.is_empty(), "each piece is a furniture scene, upright, on a floor inside the walls")
	# The old places moved to the plan: against the wall they stood against, lifted as they were.
	var spots := {"Fridge": [Vector3(0.49, 0, 0.47), 0.0], "Bathtub": [Vector3(10.02, 3, 1.05), -90.0],
			"WallCupboard": [Vector3(3.75, 1.45, 1.46), -90.0], "SkiBag": [Vector3(6.706, -2, 2.261), 90.0],
			"Car": [Vector3(8.41, -3, 2.24), 180.0], "OldCot": [Vector3(1.421, 6, 6.86), 180.0], "Piano": [Vector3(8.858, 0, 8.08), 180.0]}
	for n: String in spots:
		var p := house.get_node_or_null("Furniture/" + n) as Node3D
		_check(p != null, "%s is placed" % n)
		if p != null:
			_check(p.position.distance_to(spots[n][0]) < 0.002, "%s stands at %s (%s)" % [n, spots[n][0], p.position])
			_near(rad_to_deg(p.rotation.y), spots[n][1], 0.01, "%s turned %s degrees" % [n, spots[n][1]])
	_check(house.get_node("Furniture/Fridge").scene_file_path == FURNITURE + "/fridge.tscn" and house.get_node("Furniture/Chair4").scene_file_path == FURNITURE + "/dining_chair.tscn",
			"each is the old piece's scene (a repeat numbered: Chair4)")
	house.free()


func case_h03_lights() -> void:
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var ceiling := 0
	var lamps := 0
	var wrong: Array[String] = []
	for node in house.get_node("Lights").get_children():
		var l := node as OmniLight3D
		if l == null:
			wrong.append("%s is no OmniLight3D" % node.name)
			continue
		if not l.light_color.is_equal_approx(LAMP_COLOUR):
			wrong.append("%s is %s" % [l.name, l.light_color])
		if String(l.name).begins_with("Ceiling_"):
			ceiling += 1
			if not (is_equal_approx(l.light_energy, 1.0) and is_equal_approx(l.omni_range, 6.0) and l.shadow_enabled
					and is_equal_approx(l.shadow_blur, 2.0) and is_equal_approx(l.shadow_bias, 0.05)):
				wrong.append("%s: energy %s range %s shadow %s" % [l.name, l.light_energy, l.omni_range, l.shadow_enabled])
			# Under its room's ceiling, high over its floor (a stair's light hangs in the well above).
			var room := String(l.name).trim_prefix("Ceiling_")
			var fl := 6.0
			for level: String in ROOM_FLOORS:
				if room in ROOM_FLOORS[level]:
					fl = FLOOR_Y[level]
			if l.position.y - fl < 2.0 or l.position.y - fl > 4.5:
				wrong.append("%s hangs at %s over its floor" % [l.name, l.position.y - fl])
		elif String(l.name).begins_with("Lamp_"):
			lamps += 1
			if not (is_equal_approx(l.light_energy, 0.7) and is_equal_approx(l.omni_range, 3.0) and not l.shadow_enabled):
				wrong.append("%s: energy %s range %s" % [l.name, l.light_energy, l.omni_range])
	for w: String in wrong.slice(0, 8):
		_check(false, w)
	_check(wrong.is_empty(), "every light has the old colour, energy, range and shadow")
	_same(ceiling, 18, "a ceiling light per old room light (18)")
	_same(lamps, 2, "the floor lamp's and the nightstand's lights")
	var kitchen := house.get_node("Lights/Ceiling_kitchen") as Node3D
	_check(kitchen.position.distance_to(Vector3(2.02, 2.54, 4.25)) < 0.01, "the kitchen's hangs in its middle, 16 cm under its ceiling (%s)" % kitchen.position)
	var lamp := house.get_node("Lights/Lamp_FloorLamp") as Node3D
	var stand := house.get_node("Furniture/FloorLamp") as Node3D
	_check(lamp.position.distance_to(stand.position + Vector3(0, 1.38, 0)) < 0.002, "the floor lamp's light is in its shade, 1.38 m up")
	house.free()


func case_h04_coop() -> void:
	var alone := _branch("Alone")
	await _frames(2)
	var alone_net := LevelRuntime.of(alone).net
	_check(not LevelRuntime.of(alone).session.is_online() and LevelRuntime.of(alone).players.get_child_count() == 0,
			"alone, the house opens no network and has no avatars")
	_check(alone_net.mode_text().begins_with("Alone"), "the corner says: %s" % alone_net.mode_text())
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the house hosts")
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	# house/09: the Guest joins while the Host still lays its Socks; it is welcomed only once they are laid.
	var host_mess := LevelRuntime.of(host).mess
	_check(host_mess.is_laying(), "the guest joins while the host still lays its Socks")
	var laying_at_welcome: Array[bool] = []
	gs.welcomed.connect(func() -> void: laying_at_welcome.append(host_mess.is_laying()))
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "another house joins it")
	await _until(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined"), "the guest to be welcomed")
	_check(LevelRuntime.of(guest).net.mode_text().contains("house"), "into the host's house: %s" % LevelRuntime.of(guest).net.mode_text())
	_check(laying_at_welcome == [false], "the guest waited for the host's Socks to be laid (%s)" % [laying_at_welcome])
	var g_id := gs.me()
	var ha := LevelRuntime.of(host).avatars
	var ga := LevelRuntime.of(guest).avatars
	await _until(func() -> bool: return ha.of(g_id) != null and ga.of(1) != null, "each house to show the other's avatar")
	# house/05: the Guest sees the Host's Mess, the generated Socks where the Host laid them.
	var hm := LevelRuntime.of(host).mess
	var gm := LevelRuntime.of(guest).mess
	await _until(func() -> bool: return gm.count() == hm.count(), "the guest's Mess to have the host's Socks")
	var differ := 0
	for sock in hm.count():
		if gm.designs[sock] != hm.designs[sock] or not gm.pose_of(sock).origin.is_equal_approx(hm.pose_of(sock).origin):
			differ += 1
	_check(hm.count() > 900 and differ == 0, "the guest sees the host's %d Socks, each its Design where it lies (%d differ)" % [hm.count(), differ])
	_drop_branches()


func _branch(label: String) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	view.add_child(house)
	_branches.append(node)
	return house


## Every co-op machine goes: its session closes, then the nodes, then its MultiplayerAPI.
func _drop_branches() -> void:
	for node in _branches:
		var house := node.get_node_or_null("View/House")
		var session := LevelRuntime.of(house).session if house != null else null
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


# --- The Mess in the house (house/05) -----------------------------------------------------------

## Each floor's generator: its floor height, the old stage's Pairs (stages.json "pairs") and the
## Collections of the floor's two Cabinets (stages.json "floors").
const GENERATORS := {
	"Basement": [-3.0, 50, [&"simple", &"sport"]], "Ground": [0.0, 160, [&"food", &"patterns"]],
	"First": [3.0, 150, [&"animals", &"superhero"]], "Attic": [6.0, 130, [&"winter", &"space"]],
}
## The old cabinet_spots (house_layout.json) moved to the plan: name, Collection, x, floor, z, yaw.
const CABINETS: Array[Array] = [
	["Laundry", &"simple", 1.42, -3.0, 8.15, PI], ["Garage", &"sport", 10.15, -3.0, 7.30, -PI / 2],
	["Kitchen", &"food", 0.35, 0.0, 4.99, PI / 2], ["Living", &"patterns", 10.15, 0.0, 2.08, -PI / 2],
	["KidsNorth", &"animals", 7.84, 3.0, 3.81, 0.0], ["KidsEast", &"superhero", 10.15, 3.0, 5.38, -PI / 2],
	["LoftWest", &"winter", 0.35, 6.0, 4.26, PI / 2], ["LoftEast", &"space", 10.15, 6.0, 4.26, -PI / 2],
]
## The kitchen's inside faces (house-kit-plan.md "Rooms").
const KITCHEN := Rect2(0.1, 0.1, 3.84, 8.3)
## The player's own collision layer (furniture's PlayerBody, docs/architecture/furniture.md).
const PLAYER_BODY := 8
## The player's eyes over its feet, and how far its crosshair reaches (the Hands' reach), for the aim probe.
const EYE_HEIGHT := 1.6
const AIM_REACH := 2.5
## A Heap's top Sock in the kitchen lies on another Sock: over the floor, under any counter (core/60).
const HEAP_TOP_LOWEST := 0.01
const HEAP_TOP_HIGHEST := 0.3


func _generator(house: Node3D, floor_name: String) -> SockGenerator:
	return house.get_node("SockGenerators/" + floor_name) as SockGenerator


func case_h05_mess() -> void:
	var house := await _level_up()
	var mess := LevelRuntime.of(house).mess
	var cat := mess.catalogue
	var total := 0
	var all_kinds: Dictionary[int, int] = {}
	for floor_name: String in GENERATORS:
		var want: Array = GENERATORS[floor_name]
		var gen := _generator(house, floor_name)
		var made := gen.get_node("Generated") as GeneratedSocks
		var trail := 0
		for node in gen.get_children():
			if node is SockTrail:
				trail += (node as SockTrail).socks
		var area := gen.get_node("Floor") as SockArea
		_same(area.pairs, want[1], "%s: the old stage's %d Pairs" % [floor_name, want[1]])
		_check(area.heap, "%s: its floor Socks gather in Heaps, as on the old game's every floor" % floor_name)
		var asked := area.pairs * 2 + trail
		_check(made.socks >= asked - 2 and made.socks % 2 == 0,
				"%s: its Socks lie (%d of %d asked, %s)" % [floor_name, made.socks, asked, gen.last_report])
		total += made.socks
		var wrong_floor := 0
		var wrong_design := 0
		for sock in range(made.first, made.first + made.socks):
			var y := mess.pose_of(sock).origin.y
			if y < float(want[0]) - 0.05 or y > float(want[0]) + 3.0:
				wrong_floor += 1
			if not (want[2] as Array).has(cat.design(mess.designs[sock]).collection):
				wrong_design += 1
		_check(wrong_floor == 0, "%s: every Sock lies on its floor or its stair (%d do not)" % [floor_name, wrong_floor])
		_check(wrong_design == 0, "%s: every Sock is of its floor's Cabinets' Collections %s (%d are not)" % [floor_name, want[2], wrong_design])
		var laying := gen.lay(made.seed, mess.lying_boxes(made.first, made.first + made.socks))
		var kinds: Dictionary[int, int] = {}
		for row: Dictionary in laying.rows:
			kinds[int(row["kind"])] = kinds.get(int(row["kind"]), 0) + 1
		for k: int in [SockArea.Kind.FLOOR, SockArea.Kind.TOP]:
			_check(kinds.get(k, 0) > 0, "%s: Socks on %s places (%s; %s)" % [floor_name, SockArea.Kind.keys()[k], kinds, gen.last_report])
		# Hidden: inside and under furniture.
		var hidden: int = kinds.get(SockArea.Kind.INSIDE, 0) + kinds.get(SockArea.Kind.UNDER, 0)
		_check(hidden > 0, "%s: Socks hidden inside and under furniture (%s; %s)" % [floor_name, kinds, gen.last_report])
		for k: int in kinds:
			all_kinds[k] = all_kinds.get(k, 0) + kinds[k]
	for k: int in SockArea.Kind.values():
		_check(all_kinds.get(k, 0) > 0, "the house has Socks on %s places (%d)" % [SockArea.Kind.keys()[k], all_kinds.get(k, 0)])
	Log.info("house", "house/05: the house's Socks by kind %s" % [all_kinds])
	# house/09: the attic's two trunks hold Socks inside (their Inside on the lump in their bottom).
	var attic := _generator(house, "Attic").get_node("Generated") as GeneratedSocks
	var in_trunks := {}
	for trunk_name: String in ["TrunkA", "TrunkB"]:
		var box := house.get_node("Furniture/%s/Lid/Inside/Box" % trunk_name) as CollisionShape3D
		var half := (box.shape as BoxShape3D).size * 0.5 + Vector3(0.01, 0.01, 0.01)
		var n := 0
		for sock in range(attic.first, attic.first + attic.socks):
			var local := box.global_transform.affine_inverse() * mess.pose_of(sock).origin
			if absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z:
				n += 1
		in_trunks[trunk_name] = n
	Log.info("house", "house/09: Socks inside the attic's trunks %s" % [in_trunks])
	_check(in_trunks.values().all(func(n: int) -> bool: return n >= 3 and n <= 7), "each attic trunk holds about 5 Socks inside, as the old game (Q2576: %s)" % [in_trunks])
	# The laying time of the whole house in one frame (core/52's [later]): every generator again.
	var t0 := Time.get_ticks_usec()
	for floor_name: String in GENERATORS:
		var made := _generator(house, floor_name).get_node("Generated") as GeneratedSocks
		_generator(house, floor_name).records(made.seed, cat, mess.lying_boxes(made.first, made.first + made.socks))
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	Log.info("house", "house/05: the house's %d generated Socks are laid in %.0f ms" % [total, ms])
	_check(total > 900, "the house's floors hold %d Socks, laid in %.0f ms in one frame" % [total, ms])
	for c: Array in CABINETS:
		var root := house.get_node_or_null("Cabinets/" + String(c[0])) as Node3D
		var cab := root.get_node_or_null("Cabinet") as Cabinet if root != null else null
		_check(cab != null and (cab.pool.has(cab.collection) or cab.pool.is_empty() and cab.collection == c[1]), "the %s Cabinet holds %s of its pool %s (core/135 draws it)" % [c[0], cab.collection, cab.pool])
		if root != null:
			_check(root.global_position.distance_to(Vector3(c[2], c[3], c[4])) < 0.01 and absf(angle_difference(root.rotation.y, c[5])) < 0.01,
					"the %s Cabinet stands at the old spot, its back to the wall (%s)" % [c[0], root.global_position])
		if cab != null:
			_check(cab.hands == LevelRuntime.of(house).hands and cab.bank != null, "the %s Cabinet shelves through the house's Hands and pays its Coins" % c[0])


func case_h05_stair_treads() -> void:
	var house := await _level_up()
	var mess := LevelRuntime.of(house).mess
	var trails := 0
	var flat := 0
	for floor_name: String in GENERATORS:
		var gen := _generator(house, floor_name)
		var made := gen.get_node("Generated") as GeneratedSocks
		var laying := gen.lay(made.seed, mess.lying_boxes(made.first, made.first + made.socks))
		for row: Dictionary in laying.rows:
			if int(row["kind"]) != SockArea.Kind.TRAIL:
				continue
			trails += 1
			var pose: Transform3D = row["pose"]
			var hit := PhysicsQueries.ray(house, pose.origin + Vector3.UP * 0.01, pose.origin + Vector3.DOWN * 0.02, SockTrail.LAYER_TREADS)
			if pose.basis.y.normalized().dot(Vector3.UP) > 0.999 and not hit.is_empty():
				flat += 1
	_same(trails, 12, "the stairs hold the old 6 trail Socks and 6 more on single steps")
	_same(flat, trails, "every one lies flat on a tread")
	var player := LevelRuntime.of(house).player
	_check(player.collision_mask & SockTrail.LAYER_TREADS == 0, "the player does not collide with the treads: it walks the ramp")
	var tread := house.get_node("Shell/Ground/Stair/StairU/Treads") as StaticBody3D
	_check(tread.collision_layer == SockTrail.LAYER_TREADS and tread.collision_mask == 0, "the stair's treads are on their own layer only")


## Whether the lying Sock `sock` is open to the eye: no other Sock rests over it (a Heap's top) and no
## piece of the house is over it. core/60: the probe once started 6 cm over the Sock's origin, inside the
## Sock stacked on it in a Heap, so a covered Sock passed for a top one.
func _open_sock(mess: Mess, sock: int) -> bool:
	if mess.state_of(sock) != Mess.State.LYING or not mess.resting_on(mess.box_of(sock)).is_empty():
		return false
	var box := mess.box_of(sock)
	var top := Vector3(box.get_center().x, box.end.y + 0.002, box.get_center().z)
	return PhysicsQueries.ray(mess, top, top + Vector3.UP * 2.2, Mess.LAYER_HOUSE | Mess.LAYER_LYING).is_empty()


## A place 1-1.6 m from Sock `sock` on the floor at `floor_y` (the ground floor's by default) where the
## player stands and the crosshair, aimed at its middle, rests on it (AimFinder: no other Sock in front), or INF.
func _spot_aiming(mess: Mess, sock: int, floor_y := 0.0) -> Vector3:
	var target := _sock_centre(mess, sock)
	var probe := BoxShape3D.new()
	probe.size = Vector3(0.6, 1.5, 0.6)
	for r: float in [1.0, 1.3, 1.6]:
		for k in 12:
			var a := TAU * k / 12.0
			var at := Vector3(target.x + cos(a) * r, floor_y, target.z + sin(a) * r)
			var floor_hit := PhysicsQueries.ray(mess, at + Vector3.UP * 1.0, at + Vector3.DOWN * 0.3, Mess.LAYER_HOUSE)
			if floor_hit.is_empty() or absf((floor_hit["position"] as Vector3).y - floor_y) > 0.05:
				continue
			if not PhysicsQueries.overlap_rids(mess, probe, Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.85), Mess.LAYER_HOUSE | PLAYER_BODY, 1).is_empty():
				continue
			var eye := at + Vector3.UP * EYE_HEIGHT
			if AimFinder.find(mess, mess, eye, (target - eye).normalized(), AIM_REACH, [])["sock"] == sock:
				return at
	return Vector3.INF


func case_real_path_kitchen_loop() -> void:
	var house := await _level_up()
	await _open_floors(house)  # the kitchen's Cabinet unlocks with Stage 2 (core/91)
	var runtime := LevelRuntime.of(house)
	var mess := runtime.mess
	var hands := runtime.hands
	var player := runtime.player
	var made := _generator(house, "Ground").get_node("Generated") as GeneratedSocks
	# A food Sock on top of a Heap in the kitchen (core/60: lying on another Sock, none over it) whose
	# mate lies open too, each with a place to stand where the crosshair rests on it.
	var first := -1
	var mate := -1
	var spots: Array[Vector3] = []
	for sock in range(made.first, made.first + made.socks):
		var at := mess.pose_of(sock).origin
		if mess.design_of(sock).collection != &"food" or not KITCHEN.has_point(Vector2(at.x, at.z)) \
				or at.y <= HEAP_TOP_LOWEST or at.y > HEAP_TOP_HIGHEST or not _open_sock(mess, sock):
			continue
		var other := -1
		for o in range(made.first, made.first + made.socks):
			if o != sock and mess.designs[o] == mess.designs[sock]:
				other = o
		if other < 0 or not _open_sock(mess, other):
			continue
		var s1 := _spot_aiming(mess, sock)
		var s2 := _spot_aiming(mess, other)
		if s1 != Vector3.INF and s2 != Vector3.INF:
			first = sock
			mate = other
			spots = [s1, s2]
			break
	_check(first >= 0, "a food Sock lies on top of a kitchen Heap, its mate open (%d, %d)" % [first, mate])
	if first < 0:
		return
	player.capture_mouse()   # the mouse is the player's: buttons act (R01)
	_stand_player(player, spots[0])
	await _aim_player(player, _sock_centre(mess, first))
	_check(player.aimed_sock == first, "the crosshair rests on the Heap's top Sock (%d, aimed %d)" % [first, player.aimed_sock])
	await _press_action(&"pick")
	await _until(func() -> bool: return hands.active_of(1) == first, "the Heap's top Sock to be in the Hands")
	await _physics_ticks(25)
	_stand_player(player, spots[1])
	await _aim_player(player, _sock_centre(mess, mate))
	await _press_action(&"pick")
	await _until(func() -> bool: return mess.is_pair(first) or mess.is_pair(mate), "its mate to fuse into a Pair")
	var pair := first if mess.is_pair(first) else mate
	var root := house.get_node("Cabinets/Kitchen") as Node3D
	var cab := root.get_node("Cabinet") as Cabinet
	_stand_player(player, root.global_transform * Vector3(0.0, 0.0, 1.2))
	var front := root.get_node("Drawer1/Looks/Slide/Front") as Node3D
	await _aim_player(player, front.global_position + root.global_basis.z * 0.02)
	await _press_action(&"pick")
	await _until(func() -> bool: return cab.contents(0).has(pair), "the Pair to be shelved in the kitchen's Cabinet")
	_check(mess.state_of(pair) == Mess.State.SHELVED and hands.items_of(1).is_empty(), "the Pair is shelved and the Hands are empty")
	_check(runtime.bank.of_player(1) > 0, "the player earned Coins (%d)" % runtime.bank.of_player(1))


func _sock_centre(mess: Mess, sock: int) -> Vector3:
	return mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)


func _stand_player(player: Player, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim_player(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press_action(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


# --- Laid without a freeze (house/09) ------------------------------------------------------------

## The loading screen's words (Q2579: "Loading the house...", a New Game too).
const LOADING_TEXT := "Loading the house..."


func case_real_path_loading_screen() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	var screen := rt.loading
	var mess := rt.mess
	var player := rt.player
	var spots := mess.count()
	_check(screen.is_showing() and screen.text() == LOADING_TEXT, "F5: the loading screen says \"%s\"" % screen.text())
	_check(mess.is_laying() and get_viewport().disable_3d, "the house's Socks are being laid; the level's 3D is not drawn")
	_check(not rt.parts.is_settled(), "a joining Guest would wait")
	var start := player.global_position
	Input.action_press(&"move_forward")
	var counts: Dictionary[int, bool] = {}
	var went_down := false
	var last := 0.0
	var moved_while := 0.0
	var frames := 0
	var give_up := Time.get_ticks_msec() + int(LAYING_S * 1000.0)
	while screen.is_showing() and (frames < 3000 or Time.get_ticks_msec() < give_up):
		await get_tree().process_frame
		frames += 1
		counts[mess.count()] = true
		if screen.shown_progress() < last:
			went_down = true
		last = screen.shown_progress()
		if mess.is_laying():
			moved_while = maxf(moved_while, player.global_position.distance_to(start))
	_check(not screen.is_showing(), "the loading screen goes once the Socks are laid (%d frames)" % frames)
	_check(screen.frames > 1, "the laying took %d frames, a slice each" % screen.frames)
	_check(not went_down and is_equal_approx(last, 1.0), "the bar only fills, to the end (%.2f)" % last)
	var full := mess.count()
	_check(full > spots + 900 and counts.keys().all(func(n: int) -> bool: return n == spots or n == full),
			"the %d Socks appear all at once (counts seen %s)" % [full - spots, counts.keys()])
	_check(moved_while < 0.01, "the player stands at the spawn while the Socks are laid, walk pressed (%.3f m)" % moved_while)
	_check(not get_viewport().disable_3d and rt.parts.is_settled(), "the level draws again; a Guest may join")
	var lifted_at := player.global_position
	var walked := await _until(func() -> bool: return player.global_position.distance_to(lifted_at) > 0.3, "the player to walk")
	Input.action_release(&"move_forward")
	_check(walked, "then the player walks")
	var laying_longest := 0
	for k in screen.slices.size() - 1:
		laying_longest = maxi(laying_longest, screen.slices[k])
	Log.info("house", "house/09: the house's Socks laid in %d frames, the longest slice of laying %.1f ms (budget %.1f ms), the reveal %.1f ms, the longest frame %.1f ms" % [
			screen.frames, laying_longest / 1000.0, screen.tuning.slice_ms, screen.slices[-1] / 1000.0, screen.longest_frame / 1000.0])



func case_h09_slices_within_budget() -> void:
	# The wall time of a slice is the laying's work plus whatever the machine did meanwhile: in a VM a
	# busy host takes the core away mid-unit without the guest seeing a wait (its own CPU clock counts
	# it as run), so a floor cell of well under a millisecond can take 15 ms (maintenance/13). The same seed lays the same units in the same
	# order however the frames slice them, so each slice is judged by its units' least time over
	# H09_LAYINGS layings: the work the laying put in that slice, which a busy moment cannot add to.
	var units: Array[PackedInt32Array] = []
	var ends: Array[PackedInt32Array] = []
	var walls: Array[PackedInt32Array] = []
	var budget := 0.0
	for k in H09_LAYINGS:
		SliceClock.keep_record(true)
		_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
		add_child(_level)
		var screen := LevelRuntime.of(_level).loading
		await _until(func() -> bool: return not screen.is_showing(), "the house's Socks to be laid", 3000)
		budget = screen.tuning.slice_ms
		units.append(SliceClock.units)
		ends.append(SliceClock.slice_ends)
		walls.append(screen.slices)
		_check(SliceClock.slice_ends.size() == screen.slices.size(), "laying %d: every slice is recorded (%d of %d)" % [
				k + 1, SliceClock.slice_ends.size(), screen.slices.size()])
		SliceClock.keep_record(false)
		_level.free()
		_level = null
		await get_tree().process_frame
	var sizes := units.map(func(u: PackedInt32Array) -> int: return u.size())
	var same: bool = sizes.all(func(n: int) -> bool: return n == sizes[0]) and sizes[0] > 0
	_check(same, "every laying runs the same units (%s)" % [sizes])
	if not same:
		return
	var least := units[0].duplicate()
	for u in units:
		for i in least.size():
			least[i] = mini(least[i], u[i])
	# The last slice is the reveal (every Sock joins the Mess and is drawn, all at once, Q2523), not laying.
	var over: Array[float] = []
	var longest := 0
	var longest_wall := 0
	var slices := 0
	for k in H09_LAYINGS:
		var from := 0
		for s in ends[k].size() - 1:
			var work := 0
			for i in range(from, ends[k][s]):
				work += least[i]
			from = ends[k][s]
			longest = maxi(longest, work)
			longest_wall = maxi(longest_wall, walls[k][s])
			slices += 1
			if work / 1000.0 > budget:
				over.append(work / 1000.0)
	Log.info("house", "house/09: %d layings, %d slices of laying, %d units; the longest slice's work %.1f ms (budget %.0f ms), the longest slice's wall time %.1f ms" % [
			H09_LAYINGS, slices, least.size(), longest / 1000.0, budget, longest_wall / 1000.0])
	_check(over.is_empty(), "no slice of laying does more than %.0f ms of work (%d of %d do: %s)" % [
			budget, over.size(), slices, over.slice(0, 10)])


func case_h09_same_seed_sliced() -> void:
	# The Laundry day's draw (core/93) switches the unused bins' shapes off; it lands before the sliced laying but
	# after the laying at once, which would move the Socks. This case is about the laying, so neither house draws.
	var at_once := _house_view("AtOnce", func(house: Node3D) -> void:
		house.get_node("LaundryDay").free()
		(house.get_node("Runtime") as LevelRuntime).load_screen = false)
	var a := LevelRuntime.of(at_once)
	_check(not a.mess.is_laying() and not a.loading.is_showing(), "with no loading screen the Socks are laid before the level is ready")
	# As laid, before a tick of the Mess (a Sock with nothing under it falls at the next tick, core/55).
	var a_designs := a.mess.designs.duplicate()
	var a_poses := a.mess.poses.duplicate()
	var sliced := _house_view("Sliced", func(house: Node3D) -> void: house.get_node("LaundryDay").free())
	var b := LevelRuntime.of(sliced)
	# Its screen's slices (8 ms, more frames than its own 14), taken here so the records are read the moment the last is laid.
	b.loading.set_process(false)
	var frames := 0
	var done := false
	while not done and frames < 6000:
		await get_tree().process_frame
		frames += 1
		done = b.mess.lay_step(Time.get_ticks_usec() + 8000)
	var b_designs := b.mess.designs.duplicate()
	var b_poses := b.mess.poses.duplicate()
	b.loading.set_process(true)
	_check(done and frames > 50, "the other house laid them over %d frames" % frames)
	_check(a_designs.size() > 900 and a_designs == b_designs, "the same Designs in the same order (%d and %d Socks)" % [a_designs.size(), b_designs.size()])
	var differ: Array[int] = []
	for sock in mini(a_designs.size(), b_designs.size()):
		if not Mess.unpack(a_poses, sock).is_equal_approx(Mess.unpack(b_poses, sock)):
			differ.append(sock)
	_check(a_poses == b_poses, "every Sock lies at the same pose (%d differ: %s)" % [differ.size(), differ.slice(0, 8)])
	for floor_name: String in GENERATORS:
		var ga := _generator(at_once, floor_name).get_node("Generated") as GeneratedSocks
		var gb := _generator(sliced, floor_name).get_node("Generated") as GeneratedSocks
		_check(ga.seed == gb.seed and ga.first == gb.first and ga.socks == gb.socks,
				"%s: the same seed and records (%d from %d)" % [floor_name, gb.socks, gb.first])


## A house in its own world (a SubViewport) and MultiplayerAPI, `setup` called on it before it
## enters the tree; dropped with the co-op branches.
func _house_view(label: String, setup: Callable) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	setup.call(house)
	view.add_child(house)
	_branches.append(node)
	return house


func case_h09_trail_stays_on_treads() -> void:
	var house := await _level_up()
	var mess := LevelRuntime.of(house).mess
	var trails := 0
	for floor_name: String in GENERATORS:
		for node in _generator(house, floor_name).get_children():
			if node is SockTrail:
				trails += (node as SockTrail).socks
	var first := _on_treads(mess)
	await _physics_ticks(120)
	var after := _on_treads(mess)
	_check(first.size() == trails, "the %d trail Socks lie flat on the treads (%d do)" % [trails, first.size()])
	_check(after == first, "after 120 ticks every one still lies on its tread (%d of %d)" % [after.size(), first.size()])


## The lying Socks whose middle has a stair's tread just under it (within 1 cm), by id.
func _on_treads(mess: Mess) -> Array[int]:
	var out: Array[int] = []
	for sock in mess.count():
		if mess.state_of(sock) != Mess.State.LYING:
			continue
		var p := mess.pose_of(sock).origin
		var hit := PhysicsQueries.ray(mess, p + Vector3.UP * 0.005, p + Vector3.DOWN * 0.01, SockTrail.LAYER_TREADS)
		if not hit.is_empty() and (hit["collider"] as Node).name == SockTrail.TREADS:
			out.append(sock)
	return out



# --- The house's run (core/91) -------------------------------------------------------------------

## Unlock stages of the house's Cabinets (the old `hidden_until`: the garage with Stage 2; every other
## Cabinet with its floor's Stage).
const UNLOCK_STAGES := {"Laundry": 1, "Garage": 2, "Kitchen": 2, "Living": 2, "KidsNorth": 3, "KidsEast": 3,
		"LoftWest": 4, "LoftEast": 4}
## The floor locks: [node, the floor it shuts, its middle (x, y, z), the side players come from (+z or -z)].
const LOCKS: Array[Array] = [
	["Ground", 1, Vector3(5.875, 0.0, 5.45), 1.0],
	["First", 2, Vector3(5.875, 3.0, 5.45), 1.0],
	["Attic", 3, Vector3(4.625, 3.0, 5.4), -1.0],
]
const TITLE_SCENE := "res://game/ui/title/title.tscn"
## A Sock lies on a high top at least this far over the basement floor (StagePlan.high_spot).
const HIGH := 1.7
const BASEMENT_TOP := -0.5

var _title: TitleScreen = null
var _lobby: LobbyScreen = null


## Every floor opened as the Fixes would (the zoo's "Fit now" answer, the Host's), the locks' leaves
## swung open.
func _open_floors(house: Node) -> void:
	var rt := LevelRuntime.of(house)
	var stages := house.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return stages.stage >= 0, "the run to start")
	while stages.stage < stages.plan.size() - 1:
		rt.parts.apply(stages.fit_now_answer())
	for lock in stages.floor_locks():
		var anim := lock.leaf().animator()
		await _until(func() -> bool: return not lock.is_locked() and (anim == null or not anim.is_playing()),
				"floor %d's lock to swing open" % lock.floor, 900)


func case_r01_run_placed() -> void:
	var house := await _level_up()
	var stages := house.get_node("Run/Stages") as Stages
	_check(stages.plan == load("res://game/run/house_stage_plan.tres"), "Run/Stages reads the house's plan")
	await _until(func() -> bool: return stages.stage == 0, "the house's run to start")
	var locks := stages.floor_locks()
	_check(locks.size() == LOCKS.size(), "the house has %d floor locks (%d)" % [LOCKS.size(), locks.size()])
	for rec: Array in LOCKS:
		var root := house.get_node_or_null("FloorLocks/" + String(rec[0])) as Node3D
		_check(root != null, "FloorLocks/%s stands in the house" % rec[0])
		if root == null:
			continue
		var lock := root.get_node("Padlock/FloorLock") as FloorLock
		_check(lock.floor == int(rec[1]) and lock.is_locked(), "%s shuts floor %d and is locked (%d, %s)" % [rec[0], rec[1], lock.floor, lock.is_locked()])
		var mid: Vector3 = rec[2]
		_check(root.global_position.distance_to(mid) < 0.01, "%s stands at %s (%s)" % [rec[0], mid, root.global_position])
		var side := float(rec[3])
		for up: float in [0.5, 1.5]:
			var from := mid + Vector3(0, up, 0.6 * side)
			var hit := _hit(from, mid + Vector3(0, up, -0.6 * side))
			_check(not hit.is_empty() and root.is_ancestor_of(hit["collider"] as Node),
					"%s shuts the way %.1f m up (hit %s)" % [rec[0], up, (hit["collider"] as Node).get_path() if not hit.is_empty() else "nothing"])
	var door := house.get_node("FloorLocks/Ground") as Node3D
	var gate := house.get_node("FloorLocks/Attic") as Node3D
	_check(door.scene_file_path.ends_with("floor_lock.tscn") and (house.get_node("FloorLocks/First") as Node).scene_file_path.ends_with("floor_lock.tscn")
			and gate.scene_file_path.ends_with("floor_lock_gate.tscn"), "the ground's and the first floor's are doors, the attic's the gate")
	for spot: String in UNLOCK_STAGES:
		var cab := house.get_node("Cabinets/%s/Cabinet" % spot) as Cabinet
		var want := int(UNLOCK_STAGES[spot])
		_check(cab.unlock_stage == want and cab.locked == (want > 1), "%s unlocks with Stage %d (%d, locked %s)" % [spot, want, cab.unlock_stage, cab.locked])
		_check(cab.sheeted() == (spot == "Garage"), "%s stands %s" % [spot, "sheeted" if spot == "Garage" else "unsheeted"])
	for floor_name: String in GENERATORS:
		var gen := _generator(house, floor_name)
		_check(not gen.lays_at_start and gen.floor == FLOORS.find(float(FLOOR_Y[floor_name])), "%s's generator: floor %d, not laid at start" % [floor_name, gen.floor])
	var kinds: Array[String] = []
	for node in house.get_node("Run/MachineParts").get_children():
		var part := node.get_node("MachinePart") as MachinePart
		kinds.append(String(part.kind.id))
	var want_kinds: Array[String] = []
	for st: Stage in stages.plan.stages:
		want_kinds.append(String(st.part.id))
	_check(kinds == want_kinds, "the four Machine Parts lie under Run/MachineParts, one per Stage (%s)" % [kinds])
	var slot := house.get_node("Washer/PartSlot/MachinePartSlot") as MachinePartSlot
	_check(slot.stages == stages and slot.aim_body.collision_layer == 0, "the washer's MachinePartSlot reads the run; it takes no aim while no Part is out")
	var bar := LevelRuntime.of(house).player.get_node("Hud/StageBar") as StageBar
	_check(bar.visible and bar.text() == "Stage 1: Basement  0/%d" % stages.bar_numbers().y, "the HUD's Stage bar shows Stage 1 (%s)" % bar.text())


## A house in this tree as a New Game of the Solo World (from the title): the run starts and lays
## Stage 1. `setup` runs on it before it enters the tree.
func _new_game_house(setup := Callable()) -> Node3D:
	SockGenerator.start_all = false
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	var rt := LevelRuntime.of(_level)
	rt.world = Worlds.pick_solo()
	rt.from_title = true
	if setup.is_valid():
		setup.call(_level)
	add_child(_level)
	return _level


## The Socks of the Mess, by where they lie: {"count", "basement", "simple", "high"} (high: over HIGH above
## the basement floor and off the stair).
func _socks_by_place(mess: Mess) -> Dictionary:
	var out := {"count": 0, "basement": 0, "simple": 0, "high": 0}
	for sock in mess.count():
		if mess.state_of(sock) == Mess.State.GONE:
			continue
		var at := mess.pose_of(sock).origin
		out["count"] += 1
		if at.y < BASEMENT_TOP:
			out["basement"] += 1
		if mess.design_of(sock).collection == &"simple":
			out["simple"] += 1
		if at.y >= FLOORS[0] + HIGH and at.y < BASEMENT_TOP:
			out["high"] += 1
	return out


func case_r02_new_game_lays_stage1() -> void:
	var house := _new_game_house()
	var rt := LevelRuntime.of(house)
	var spawner := house.get_node("Run/StageSpawner") as StageSpawner
	var stages := house.get_node("Run/Stages") as Stages
	_check(rt.loading.is_showing() and rt.mess.layer == spawner, "the New Game shows the loading screen; Stage 1 is the Mess's layer")
	var filled := 0.0
	var frames := 0
	while not rt.loading.is_lifted() and frames < 6000:
		filled = maxf(filled, rt.mess.lay_progress())
		await get_tree().process_frame
		frames += 1
	_check(rt.loading.is_lifted() and filled > 0.1, "Stage 1 laid behind the screen, its bar filling (to %.2f over %d frames)" % [filled, frames])
	_check(stages.holding and rt.mess.count() == 0, "held for the First wash: none lie yet (%d)" % rt.mess.count())
	await _first_wash_done(house)
	_check(stages.stage == 0 and stages.first_laid and stages.due.is_empty(), "Stage 1 began and landed (stage %d, laid %s, due %d)" % [stages.stage, stages.first_laid, stages.due.size()])
	var by := _socks_by_place(rt.mess)
	var least := stages.plan.pairs_of(0, stages.pairs_per_drawer) * 2
	_check(int(by["count"]) >= least and int(by["count"]) == stages.spawned.size() * 2, "Stage 1's Pairs lie in the Mess (%d Socks, at least %d)" % [by["count"], least])
	_check(by["basement"] == by["count"] and by["simple"] == by["count"], "every one Simple, on the basement (%s)" % [by])
	_check(int(by["high"]) < roundi(stages.spawned.size() * stages.plan.high_share),
			"alone, no high pass: fewer on a top over %.1f m than its share (%d)" % [HIGH, by["high"]])


func case_r03_high_spots_two_players() -> void:
	var house := _new_game_house(func(h: Node3D) -> void:
		(h.get_node("Run/StageSpawner") as StageSpawner).present = func() -> int: return 2)
	var rt := LevelRuntime.of(house)
	await _until(rt.loading.is_lifted, "Stage 1 to be laid", 6000, LAYING_S)
	await _first_wash_done(house)
	var by := _socks_by_place(rt.mess)
	var stages := house.get_node("Run/Stages") as Stages
	var share := stages.plan.high_share
	var want := roundi(stages.spawned.size() * share)
	_check(want >= 1 and int(by["high"]) >= want and int(by["high"]) <= 2 * want + 2,
			"with two players a few Socks lie on a top over %.1f m (%d of %d; the share's %d Pairs)" % [HIGH, by["high"], by["count"], want])
	var on_top := 0
	for sock in rt.mess.count():
		var at := rt.mess.pose_of(sock).origin
		if at.y >= FLOORS[0] + HIGH and at.y < BASEMENT_TOP:
			var hit := _hit(at + Vector3.UP * 0.05, at + Vector3.DOWN * 0.5)
			if not hit.is_empty():
				on_top += 1
	_check(on_top == by["high"], "each lies on something under it, not in the air (%d of %d)" % [on_top, by["high"]])


## The title in this tree; its way in (and the Lobby's) put the scene here: the Lobby as `_lobby`, a level as `_level`.
func _open_title() -> void:
	_title = (load(TITLE_SCENE) as PackedScene).instantiate() as TitleScreen
	_title.go_into = func(path: String, _heading: String, setup: Callable) -> void:
		var root := (load(path) as PackedScene).instantiate()
		if setup.is_valid():
			setup.call(root)
		if _title != null:
			_title.queue_free()
		_title = null
		if _lobby != null:
			_lobby.queue_free()
		_lobby = null
		if root is LobbyScreen:
			_lobby = root as LobbyScreen
			add_child(root)
		else:
			_level = root as Node3D
			add_child(root)
	add_child(_title)


func _click(control: Control) -> void:
	await _frames(2)
	var at := control.get_global_rect().get_center()
	await _click_at(control, at)


func _click_at(control: Control, at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = pressed
		control.get_viewport().push_input(ev, true)
	await _frames(2)


func _ui_key(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await _frames(2)


func case_real_path_new_game_from_title() -> void:
	SockGenerator.start_all = false
	_open_title()
	await _click(_title.get_node("%Solo") as Control)
	await _until(func() -> bool: return _lobby != null, "the title's Solo to open the Lobby")
	await _frames(3)
	await _click(_lobby.get_node("%NewGame") as Control)
	var pairs := _lobby.pairs_slider()
	_check(_lobby.asking() and pairs.is_visible_in_tree(), "New Game opens the New Game page with the Pairs per Drawer slider (a debug build)")
	# The slider by the mouse (its left end) and two steps of the arrow keys.
	var track := pairs.slider().get_global_rect()
	await _click_at(pairs.slider(), Vector2(track.position.x + 2.0, track.get_center().y))
	await _ui_key(&"ui_right")
	await _ui_key(&"ui_right")
	var per := pairs.value()
	_check(per >= 2 and per <= 5 and _lobby.link.lobby.pairs_per_drawer == per, "the slider is moved down to %d Pairs per Drawer (the Lobby's %d)" % [per, _lobby.link.lobby.pairs_per_drawer])
	await _click(_lobby.get_node("%AskYes") as Control)
	await _until(func() -> bool: return _level != null, "Start to load the house")
	var rt := LevelRuntime.of(_level)
	await _until(rt.loading.is_lifted, "Stage 1 to be laid behind the loading screen", 6000, LAYING_S)
	await _until(func() -> bool: return rt.player.is_on_floor(), "the player to stand in the house")
	var house := _level
	await _first_wash_done(house)
	var stages := house.get_node("Run/Stages") as Stages
	var mess := rt.mess
	_check(stages.stage == 0 and stages.pairs_per_drawer == per, "the run began at Stage 1 with the slider's %d Pairs per Drawer (%d)" % [per, stages.pairs_per_drawer])
	var by := _socks_by_place(mess)
	_check(int(by["count"]) > 0 and by["basement"] == by["count"], "only the basement holds Socks (%s)" % [by])
	var garage := house.get_node("Cabinets/Garage/Cabinet") as Cabinet
	_check(garage.locked and garage.sheeted() and (house.get_node("Cabinets/Garage/DustSheet") as Node3D).is_visible_in_tree(), "the garage Cabinet stands sheeted")
	var bar := rt.player.get_node("Hud/StageBar") as StageBar
	var takes := 2 * per
	_check(bar.text() == "Stage 1: Basement  0/%d" % takes, "the Stage bar counts the laundry's two Rows (%s)" % bar.text())
	# Up the stair: the ground floor's door stops the player at the top of the flight.
	var player := rt.player
	player.rotation.y = PI
	await _go(player, Vector2(2.4, 4.1), "the player walks to the laundry's doorway")
	await _go(player, Vector2(4.6, 4.1), "the player walks through it into the stair lobby")
	await _walk(&"move_forward", func() -> bool: return player.global_position.z > 7.7 and player.is_on_floor(), "the player to climb to the half landing")
	await _walk(&"move_left", func() -> bool: return player.global_position.x > 5.8, "the player to cross the landing")
	var z := await _walk_to_stop(player, &"move_back", 2)
	var eye := player.global_position + Vector3(0, 1.0, 0)
	var ahead := _hit(eye, eye + Vector3(0, 0, -1.0))
	var door := house.get_node("FloorLocks/Ground")
	_check(z > 5.45 and player.global_position.y < -0.05 and not ahead.is_empty() and door.is_ancestor_of(ahead["collider"] as Node),
			"the ground floor's door stops the player at the top of the flight (z %.2f, y %.2f, ahead %s)" % [z, player.global_position.y, (ahead["collider"] as Node).name if not ahead.is_empty() else "nothing"])
	# Back down: a Pair of Stage 1 clicked into the laundry Cabinet.
	var first := -1
	var mate := -1
	var spots: Array[Vector3] = []
	# A Sock the crosshair can rest on from a standing place is reachable (`_spot_aiming`); a roof over it (a shelf, a
	# table) is no matter, so a layout moved by another solid in the room (the Laundry bins, core/93) still has a Pair.
	for sock in mess.count():
		if mess.state_of(sock) != Mess.State.LYING:
			continue
		for o in mess.count():
			if o != sock and mess.designs[o] == mess.designs[sock] and mess.state_of(o) == Mess.State.LYING:
				var s1 := _spot_aiming(mess, sock, FLOORS[0])
				var s2 := _spot_aiming(mess, o, FLOORS[0])
				if s1 != Vector3.INF and s2 != Vector3.INF:
					first = sock
					mate = o
					spots = [s1, s2]
				break
		if first >= 0:
			break
	_check(first >= 0, "a Pair of Stage 1 lies open in the basement (%d, %d)" % [first, mate])
	if first < 0:
		return
	var hands := rt.hands
	var me := player.player_id()
	player.capture_mouse()
	_stand_player(player, spots[0])
	await _aim_player(player, _sock_centre(mess, first))
	await _press_action(&"pick")
	await _until(func() -> bool: return hands.active_of(me) == first, "the first Sock to be in the Hands")
	await _physics_ticks(25)
	_stand_player(player, spots[1])
	await _aim_player(player, _sock_centre(mess, mate))
	await _press_action(&"pick")
	await _until(func() -> bool: return mess.is_pair(first) or mess.is_pair(mate), "its mate to fuse into a Pair")
	var pair := first if mess.is_pair(first) else mate
	var root := house.get_node("Cabinets/Laundry") as Node3D
	var cab := root.get_node("Cabinet") as Cabinet
	_stand_player(player, root.global_transform * Vector3(0.0, 0.0, 1.2))
	await _aim_player(player, (root.get_node("Drawer1/Looks/Slide/Front") as Node3D).global_position + root.global_basis.z * 0.02)
	await _press_action(&"pick")
	await _until(func() -> bool: return cab.shelved().has(pair), "the Pair to be shelved in the laundry Cabinet")
	await _until(func() -> bool: return bar.text() == "Stage 1: Basement  1/%d" % takes, "the Stage bar to move to 1/%d" % takes)
	_check(bar.ratio() > 0.0, "the bar's fill moved (%.2f)" % bar.ratio())
