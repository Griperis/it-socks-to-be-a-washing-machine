## Makes the house kit's pieces (pieces/*.tscn) and the two sample rooms (rooms/*.tscn) from
## house_kit_sizes.tres, and any missing material of the library (materials/*.tres) from the old
## house's colours (house/01, house/02). Run it after a change to the sizes, from the project folder:
##   "$(kit/tools/engine.sh --path)" --headless --path . --script res://tools/house_kit_build.gd
## `-- --only=<prefix>` after it writes only the pieces whose file name starts so (and no room): a
## new piece without renumbering every other file's node ids.
## A piece is a MeshInstance3D root (one mesh in meshes/, its material slots in a fixed order: see
## docs/architecture/house-kit.md "Material slots") with a StaticBody3D "Body" of boxes on the house's
## physics layer. A piece file keeps its uid across rebuilds; a material that exists is never
## rewritten, so the designer's edits to the library stay. Every piece keeps the no-z-fight rule (K14):
## see docs/architecture/house-kit.md "No two faces in one plane".
extends SceneTree

const SIZES := "res://game/house/kit/house_kit_sizes.tres"
const PIECES := "res://game/house/kit/pieces"
const MESHES := "res://game/house/kit/meshes"
const MATERIALS := "res://game/house/kit/materials"
const TEXTURES := "res://game/house/kit/textures"
const ROOMS := "res://game/zoo/house_kit/rooms"
## The house's physics layer, the Mess's LAYER_HOUSE (game/mess/mess.gd): a script run (--script) has no autoloads,
## so naming Mess here, which needs them, would stop the tool compiling.
const LAYER_HOUSE := 1
## How deep a stair's walking ramp is under its top.
const RAMP_DEPTH := 0.3
## The material slots of a wall-like piece: its inside (+Z) face, its outside (-Z) face, trim, glass.
const A := 0
const B := 1
const TRIM := 2
const GLASS := 3

## The library: the old house's materials (make_flat.py and make_house.py of the reference), sRGB
## colour, roughness, then optionally a texture with the metres one repeat covers, or an alpha.
const LIBRARY := {
	"wall_outside": [Color(0.93, 0.90, 0.84), 0.9],
	"wall_kitchen": [Color(0.96, 0.89, 0.77), 0.9],
	"wall_hall": [Color(0.97, 0.86, 0.62), 0.9],
	"wall_bathroom": [Color(0.80, 0.91, 0.88), 0.9],
	"wall_bedroom": [Color(0.94, 0.79, 0.73), 0.9],
	"wall_office": [Color(0.90, 0.86, 0.94), 0.9],
	"wall_kids": [Color(0.98, 0.86, 0.80), 0.9],
	"wall_workshop": [Color(0.86, 0.84, 0.78), 0.9],
	"wall_boiler": [Color(0.84, 0.81, 0.78), 0.9],
	"wall_garage": [Color(0.88, 0.86, 0.80), 0.9],
	"wall_lobby": [Color(0.91, 0.88, 0.82), 0.9],
	"wall_loft": [Color(0.93, 0.85, 0.72), 0.9],
	"wall_tile": [Color(1, 1, 1), 0.3, "wall_tiles.png", 0.6],
	"ceiling": [Color(0.98, 0.95, 0.89), 0.9],
	"trim": [Color(0.98, 0.96, 0.91), 0.55],
	"oak": [Color(0.80, 0.57, 0.34), 0.62],
	"glass": [Color(0.85, 0.93, 0.97), 0.05, 0.25],
	"frosted": [Color(0.92, 0.96, 0.97), 0.4, 0.7],
	"rafter": [Color(0.62, 0.45, 0.30), 0.8],
	"roof_tile": [Color(0.62, 0.30, 0.24), 0.8],
	"wood": [Color(1, 1, 1), 0.6, "planks.png", 2.0],
	"kitchen_tile": [Color(1, 1, 1), 0.5, "kitchen_tiles.png", 1.2],
	"bath_tile": [Color(1, 1, 1), 0.4, "bath_tiles.png", 0.6],
	"basement_tile": [Color(0.72, 0.71, 0.68), 0.7],
	"loft_boards": [Color(0.80, 0.66, 0.48), 0.8],
	# The elevator shaft's walls (make_elevator.py: the old "door" paint) and its hatch's sill.
	"shaft": [Color(0.96, 0.93, 0.87), 0.5],
	"stainless": [Color(0.80, 0.81, 0.82), 0.32],
}
## Library materials that are metal (make_house.py's stainless: metallic 0.85).
const METALLIC := {"stainless": 0.85}
## The bathroom's walls with the old tile wainscot (house/04 D01): the wall paint over the wall tiles,
## a ShaderMaterial on wainscot.gdshader (made when its file does not exist yet).
const WAINSCOT := {"wall_bathroom_tiled": ["wall_bathroom", "wall_tiles.png", 0.6, 0.3]}
## The wainscot's top over the floor line and the trim strip's height over it (make_flat.py make_wall_tiles).
const WAINSCOT_TOP := 1.2
const WAINSCOT_TRIM_HEIGHT := 0.035
const WAINSCOT_SHADER := "res://game/house/kit/wainscot.gdshader"
const EXTERIOR_PAINTS: Array[String] = ["wall_kitchen", "wall_outside", "trim"]
const PARTITION_PAINTS: Array[String] = ["wall_kitchen", "wall_hall", "trim"]

var _sizes: HouseKitSizes
## The piece being made: one SurfaceTool a slot, its collision boxes.
var _st: Array[SurfaceTool] = []
var _paints: Array[String] = []
var _shapes: Array[Transform3D] = []
var _shape_sizes: Array[Vector3] = []
## Slots counted from `base` (the dormer's slab is a roof slab whose slots 0 and 1 are its 4 and 5).
var _offset := 0
## `--only=<prefix>`: the pieces written (empty: all, and the rooms).
var _only := ""


func _init() -> void:
	_sizes = load(SIZES)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
	for name: String in LIBRARY:
		_material(name)
	for name: String in WAINSCOT:
		_wainscot_material(name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOMS))
	_walls()
	_doors()
	_windows()
	_tiles()
	_shafts()
	_stairs()
	_roof()
	_wainscot_trims()
	if _only == "":
		_rooms()
	print("house_kit_build: done")
	quit()


# --- The pieces ----------------------------------------------------------------------------------

func _walls() -> void:
	var s := _sizes
	var e: float = s.exterior
	var p: float = s.partition
	for length: float in s.lengths:
		var tag := _tag(length)
		_straight("wall_exterior_" + tag, length, e, EXTERIOR_PAINTS, false)
		_straight("wall_partition_" + tag, length, p, PARTITION_PAINTS, true)
		# A partition that meets a wall where a T cannot stand (an opening beside the join): it
		# starts at that wall's face, its skirting after that wall's skirting (K04).
		_straight("wall_partition_end_exterior_" + tag, length, p, PARTITION_PAINTS, true, e / 2)
		_straight("wall_partition_end_partition_" + tag, length, p, PARTITION_PAINTS, true, p / 2)
		_straight("knee_exterior_" + tag, length, e, ["wall_loft", "wall_outside", "trim"], false, 0.0, 0.0, s.knee + 0.1)
	# The knee walls' first and last piece between the gables.
	_straight("knee_exterior_start_1m", 1.0, e, ["wall_loft", "wall_outside", "trim"], false, e / 2, 0.0, s.knee + 0.1)
	_straight("knee_exterior_end_1m", 1.0, e, ["wall_loft", "wall_outside", "trim"], false, 0.0, e / 2, s.knee + 0.1)
	_corner("corner_exterior", e, EXTERIOR_PAINTS, false)
	_corner("corner_partition", p, PARTITION_PAINTS, true)
	_corner_open("corner_exterior_open", e, EXTERIOR_PAINTS)
	_t("t_exterior", e, e, EXTERIOR_PAINTS, false)
	_t("t_partition", p, p, PARTITION_PAINTS, true)
	_t("t_exterior_partition", e, p, EXTERIOR_PAINTS, false)


## A straight wall along +X from `from` to `length - to_end`, centred on z 0, its inside (slot A) at
## +Z: skirting on A (and on B for a partition). `top` is its height over the floor line.
func _straight(file: String, length: float, t: float, paints: Array[String], both: bool,
		from := 0.0, to_end := 0.0, top := -1.0) -> void:
	var s := _sizes
	var y1: float = (s.storey if top < 0.0 else top) - (s.sink if top < 0.0 else 0.0)
	_begin(paints)
	var box := _aabb(from, length - to_end, -s.sink, y1, -t / 2, t / 2)
	_box(box, _wall_pick, true)
	var d: float = s.skirting_depth if from > 0.0 else 0.0
	var d_end: float = s.skirting_depth if to_end > 0.0 else 0.0
	_skirting(Vector3(from + d, 0, t / 2), Vector3.RIGHT, Vector3.BACK, length - to_end - d_end - from - d)
	if both:
		_skirting(Vector3(from + d, 0, -t / 2), Vector3.RIGHT, Vector3.FORWARD, length - to_end - d_end - from - d)
	_col(box)
	_save(file)


## An L of two arms from the join, along +X and +Z, its outside corner closed: the outer corner of
## a building seen from outside (slot B), the inner corner from inside (slot A).
func _corner(file: String, t: float, paints: Array[String], outer_skirting: bool) -> void:
	var s := _sizes
	var a: float = s.arm
	var y0: float = -s.sink
	var y1: float = s.storey - s.sink
	var d: float = s.skirting_depth
	_begin(paints)
	var arm_x := _aabb(-t / 2, a, y0, y1, -t / 2, t / 2)
	var arm_z := _aabb(-t / 2, t / 2, y0, y1, t / 2, a)
	var pick := _corner_pick(t)
	_box(arm_x, pick)
	_box(arm_z, pick)
	_skirting(Vector3(t / 2, 0, t / 2), Vector3.RIGHT, Vector3.BACK, a - t / 2)
	_skirting(Vector3(t / 2, 0, t / 2 + d), Vector3.BACK, Vector3.RIGHT, a - t / 2 - d)
	if outer_skirting:
		_skirting(Vector3(-t / 2 - d, 0, -t / 2), Vector3.RIGHT, Vector3.FORWARD, a + t / 2 + d)
		_skirting(Vector3(-t / 2, 0, -t / 2), Vector3.BACK, Vector3.LEFT, a + t / 2)
	_col(arm_x)
	_col(arm_z)
	_save(file)


## A corner without its +X arm (house/03): a wall piece runs along +X from the join line in its
## place, for an opening that reaches the corner (the bedroom's west window, W15, runs to the south
## wall's line). The join square's outer half and the +Z arm; its skirting starts after that wall
## piece's, which runs on inside the arm.
func _corner_open(file: String, t: float, paints: Array[String]) -> void:
	var s := _sizes
	var a: float = s.arm
	var y0: float = -s.sink
	var y1: float = s.storey - s.sink
	_begin(paints)
	var outer := _aabb(-t / 2, 0.0, y0, y1, -t / 2, a)
	var inner := _aabb(0.0, t / 2, y0, y1, t / 2, a)
	var pick := _corner_pick(t)
	_box(outer, pick)
	_box(inner, pick)
	_skirting(Vector3(t / 2, 0, t / 2 + s.skirting_depth), Vector3.BACK, Vector3.RIGHT, a - t / 2 - s.skirting_depth)
	_col(outer)
	_col(inner)
	_save(file)


## A corner's slots (`t` thick): its two outer faces (-Z and -X, at the join's outer edge) B, the rest A.
static func _corner_pick(t: float) -> Callable:
	return func(c: Vector3, n: Vector3) -> int:
		if (n.z < -0.5 and absf(c.z + t / 2) < 1e-4) or (n.x < -0.5 and absf(c.x + t / 2) < 1e-4):
			return B
		return A


## A T: the through wall along X both ways from the join (its -Z face slot B), the stem along +Z.
func _t(file: String, through: float, stem: float, paints: Array[String], b_skirting: bool) -> void:
	var s := _sizes
	var a: float = s.arm
	var y0: float = -s.sink
	var y1: float = s.storey - s.sink
	var d: float = s.skirting_depth
	_begin(paints)
	var bar := _aabb(-a, a, y0, y1, -through / 2, through / 2)
	var leg := _aabb(-stem / 2, stem / 2, y0, y1, through / 2, a)
	var pick := func(c: Vector3, n: Vector3) -> int:
		return B if n.z < -0.5 and absf(c.z + through / 2) < 1e-4 else A
	_box(bar, pick)
	_box(leg, pick)
	_skirting(Vector3(-a, 0, through / 2), Vector3.RIGHT, Vector3.BACK, a - stem / 2)
	_skirting(Vector3(stem / 2, 0, through / 2), Vector3.RIGHT, Vector3.BACK, a - stem / 2)
	_skirting(Vector3(-stem / 2, 0, through / 2 + d), Vector3.BACK, Vector3.LEFT, a - through / 2 - d)
	_skirting(Vector3(stem / 2, 0, through / 2 + d), Vector3.BACK, Vector3.RIGHT, a - through / 2 - d)
	if b_skirting:
		_skirting(Vector3(-a, 0, -through / 2), Vector3.RIGHT, Vector3.FORWARD, 2 * a)
	_col(bar)
	_col(leg)
	_save(file)


func _doors() -> void:
	var s := _sizes
	for length: float in s.door_lengths:
		var tag := "" if is_equal_approx(length, 1.0) else "_" + _tag(length)
		var a: float = (length - s.door_width) / 2
		_door("door_exterior" + tag, length, a, s.door_width, s.door_height, s.exterior, EXTERIOR_PAINTS, false)
		_door("door_partition" + tag, length, a, s.door_width, s.door_height, s.partition, PARTITION_PAINTS, true)
	_door("door_partition_offset_" + _tag(s.door_offset.x), s.door_offset.x, s.door_offset.y, s.door_width,
			s.door_height, s.partition, PARTITION_PAINTS, true)
	# The off-centre doorway and the elevator's hatch in one partition (the first floor's x 4, house/03).
	var oh := s.door_offset_hatch
	var eh := s.elevator_hatch
	_door("door_partition_offset_hatch_" + _tag(oh.x), oh.x, s.door_offset.y, s.door_width, s.door_height,
			s.partition, PARTITION_PAINTS, true, Vector4(oh.y + eh.x, oh.y + eh.y, eh.z, eh.w))
	var g := s.garage_door
	_door("door_garage", g.z, (g.z - g.x) / 2, g.x, g.y, s.exterior, ["wall_garage", "wall_outside", "trim"], false)
	_hatch()


## The bathroom's wainscot trim (house/07, Q2538): a raised strip over the tiles, standing off the wall
## as the skirting does, in place of the band the shader once painted. One piece for each stretch of
## the first floor's bathroom (x 6.5 to 10.5, z 0 to 3.5, centre lines): the north and south faces
## between the east and west strips' feet, the east face, the west face either side of its door's
## casing. Named by its length in cm; its origin is where its run starts, its inside faces +Z.
func _wainscot_trims() -> void:
	var s := _sizes
	var e: float = s.exterior
	var p: float = s.partition
	var d: float = s.skirting_depth
	# The west partition's door (door_partition_15m at z 2 to 3.5): its casings' reach.
	var door_from: float = 2.0 + (1.5 - s.door_width) / 2 - s.casing
	var door_to: float = door_from + s.door_width + 2 * s.casing
	var lengths: Array[float] = [4.0 - e / 2 - p / 2 - 2 * d, 3.5 - e / 2 - p / 2, door_from - e / 2, 3.5 - p / 2 - door_to]
	for length: float in lengths:
		_begin(["trim"] as Array[String])
		var h: float = WAINSCOT_TRIM_HEIGHT
		var profile: Array[Vector2] = [Vector2(0, 0), Vector2(d, 0), Vector2(d, h * 0.7), Vector2(d * 0.5, h), Vector2(0, h)]
		var lows: Array[Vector3] = []
		var highs: Array[Vector3] = []
		for q in profile:
			var at := Vector3(0, WAINSCOT_TOP, 0) + Vector3.BACK * q.x + Vector3.UP * q.y
			lows.append(at)
			highs.append(at + Vector3.RIGHT * length)
		_prism(lows, highs, 0)
		_save(wainscot_trim_name(length))


static func wainscot_trim_name(length: float) -> String:
	return "wainscot_trim_%d" % roundi(length * 100.0)


## A wall `length` long with a doorway from `a`, `w` wide and `dh` high: the old jamb linings in its
## reveal and casings round it, on the inside face (both faces of a partition) (K08). `hatch`, when
## given (from, to along the piece, sill, head), is the elevator's hatch through the wall after the
## doorway, bare as in wall_partition_hatch_1m.
func _door(file: String, length: float, a: float, w: float, dh: float, t: float, paints: Array[String], both: bool,
		hatch := Vector4()) -> void:
	var s := _sizes
	var b := a + w
	var y0: float = -s.sink
	var y1: float = s.storey - s.sink
	var ln: float = s.lining
	var cw: float = s.casing
	_begin(paints)
	var walls: Array[AABB] = [_aabb(0, a, y0, y1, -t / 2, t / 2), _aabb(b, length, y0, y1, -t / 2, t / 2),
			_aabb(a, b, dh, y1, -t / 2, t / 2)]
	if hatch.y > 0.0:
		walls[1] = _aabb(b, hatch.x, y0, y1, -t / 2, t / 2)
		walls.append_array([_aabb(hatch.y, length, y0, y1, -t / 2, t / 2), _aabb(hatch.x, hatch.y, y0, hatch.z, -t / 2, t / 2),
				_aabb(hatch.x, hatch.y, hatch.w, y1, -t / 2, t / 2)])
	for box in walls:
		_box(box, _wall_pick, true)
		_col(box)
	var low: float = -s.lining_sink
	_box(_aabb(a, a + ln, low, dh, -t / 2, t / 2), TRIM)
	_box(_aabb(b - ln, b, low, dh, -t / 2, t / 2), TRIM)
	_box(_aabb(a + ln, b - ln, dh - ln, dh, -t / 2, t / 2), TRIM)
	for side: float in ([1.0, -1.0] if both else [1.0]):
		var zf := side * t / 2
		var z0 := minf(zf - side * 0.004, zf + side * 0.018)
		var z1 := maxf(zf - side * 0.004, zf + side * 0.018)
		# Between the skirting's foot and the linings', so a casing's foot shares a plane with neither.
		var foot: float = -(s.trim_sink + s.lining_sink) / 2
		_box(_aabb(a - cw, a + 0.01, foot, dh + cw, z0, z1), TRIM)
		_box(_aabb(b - 0.01, b + cw, foot, dh + cw, z0, z1), TRIM)
		_box(_aabb(a + 0.01, b - 0.01, dh - 0.01, dh + cw, z0, z1), TRIM)
		var out := Vector3.BACK if side > 0 else Vector3.FORWARD
		_skirting(Vector3(0, 0, zf), Vector3.RIGHT, out, a - cw)
		_skirting(Vector3(b + cw, 0, zf), Vector3.RIGHT, out, length - b - cw)
	_save(file)


## The first floor's partition with the elevator's hatch through it (plan K09); the hatch and its
## sill plate are the elevator's.
func _hatch() -> void:
	var s := _sizes
	var t: float = s.partition
	var h := s.elevator_hatch
	var y0: float = -s.sink
	var y1: float = s.storey - s.sink
	_begin(PARTITION_PAINTS)
	for box: AABB in [_aabb(0, h.x, y0, y1, -t / 2, t / 2), _aabb(h.y, 1.0, y0, y1, -t / 2, t / 2),
			_aabb(h.x, h.y, y0, h.z, -t / 2, t / 2), _aabb(h.x, h.y, h.w, y1, -t / 2, t / 2)]:
		_box(box, _wall_pick, true)
		_col(box)
	_skirting(Vector3(0, 0, t / 2), Vector3.RIGHT, Vector3.BACK, 1.0)
	_skirting(Vector3(0, 0, -t / 2), Vector3.RIGHT, Vector3.FORWARD, 1.0)
	_save("wall_partition_hatch_1m")


func _windows() -> void:
	var s := _sizes
	_window("window_exterior", 2.0, s.window_width, s.window_sill, s.window_head, false, s.storey)
	var done := {}
	for spec: Vector4 in s.windows_old + s.windows_grid:
		var file := _window_name(spec, false)
		if not done.has(file):
			done[file] = true
			_window(file, spec.w, spec.x, spec.y, spec.z, false, s.storey)
	for spec: Vector4 in s.windows_frosted:
		_window(_window_name(spec, true), spec.w, spec.x, spec.y, spec.z, true, s.storey)
	var st := s.stair_window
	_window("window_stair", st.w, st.x, st.y, st.z, false, 2 * s.storey)


## "window_120_090_215_15m": width, sill and head in centimetres, the piece's length.
static func _window_name(spec: Vector4, frosted: bool) -> String:
	return "window_%03d_%03d_%03d%s_%s" % [roundi(spec.x * 100), roundi(spec.y * 100), roundi(spec.z * 100),
			"_frosted" if frosted else "", _tag(spec.w)]


## An outside wall `length` long with a window `w` wide in its middle, from `sill` to `head` over
## the floor, in the old frame (K06, K07), `height` high (two storeys for the stair window).
func _window(file: String, length: float, w: float, sill: float, head: float, frosted: bool, height: float) -> void:
	var s := _sizes
	var t: float = s.exterior
	var a := (length - w) / 2
	var b := a + w
	var y0: float = -s.sink
	var y1: float = height - s.sink
	_begin(["wall_kitchen", "wall_outside", "trim", "frosted" if frosted else "glass"])
	for box: AABB in [_aabb(0, a, y0, y1, -t / 2, t / 2), _aabb(b, length, y0, y1, -t / 2, t / 2),
			_aabb(a, b, y0, sill, -t / 2, t / 2), _aabb(a, b, head, y1, -t / 2, t / 2)]:
		_box(box, _wall_pick, true)
		_col(box)
	_frame(a, b, sill, head, t, 0.0, length)
	_skirting(Vector3(0, 0, t / 2), Vector3.RIGHT, Vector3.BACK, length)
	_save(file)


## The old window frame (make_house.py make_windows) in an opening a..b along X, sill..head, in a
## wall t thick whose inside face is +Z: the sill (standing 0.03 m proud outside, so its face is not
## the wall's), the frame bars, a middle bar over mullion_over, flush casings inside, the pane, and
## the pane's collider on the house layer that stops a Sock.
func _frame(a: float, b: float, sill: float, head: float, t: float, lo := -INF, hi := INF) -> void:
	var s := _sizes
	var bar: float = s.window_bar
	var zi := t / 2
	var st := sill + 0.035
	# The sill runs 0.05 m into each jamb, but never to a piece's end (its end face would be the
	# wall's, K14).
	_box(_aabb(maxf(a - 0.05, lo + 0.01), minf(b + 0.05, hi - 0.01), sill, st, -t / 2 - 0.03, zi + 0.05), TRIM)
	var f0 := zi - 0.14
	var f1 := zi - 0.07
	_box(_aabb(a, a + bar, st, head, f0, f1), TRIM)
	_box(_aabb(b - bar, b, st, head, f0, f1), TRIM)
	_box(_aabb(a + bar, b - bar, st, st + bar, f0, f1), TRIM)
	_box(_aabb(a + bar, b - bar, head - bar, head, f0, f1), TRIM)
	if b - a > s.mullion_over + 0.001:
		var c := (a + b) / 2
		_box(_aabb(c - 0.025, c + 0.025, st + bar, head - bar, f0 + 0.01, f1 - 0.01), TRIM)
	_box(_aabb(a - 0.06, a, st, head + 0.06, zi, zi + 0.02), TRIM)
	_box(_aabb(b, b + 0.06, st, head + 0.06, zi, zi + 0.02), TRIM)
	_box(_aabb(a, b, head, head + 0.06, zi, zi + 0.02), TRIM)
	var pane := _aabb(a + bar - 0.01, b - bar + 0.01, st + bar - 0.01, head - bar + 0.01, zi - 0.105, zi - 0.095)
	_box(pane, GLASS)
	_col(_aabb(pane.position.x, pane.end.x, pane.position.y, pane.end.y, f0, zi - 0.095))


func _tiles() -> void:
	var s := _sizes
	var ft: float = s.floor_thickness
	for side: float in s.tiles:
		var tag := _tag(side)
		_tile("floor_" + tag, side, -ft, 0.0, "wood")
		_tile("ceiling_" + tag, side, -ft - s.ceiling_thickness, -ft, "ceiling")
		_tile("ceiling_attic_" + tag, side, -ft - s.attic_ceiling_thickness, -ft, "ceiling")
	_tile("floor_shaft_1m", 1.0, -ft, 0.0, "wood", s.shaft_hole)
	_tile("ceiling_shaft_1m", 1.0, -ft - s.ceiling_thickness, -ft, "ceiling", s.shaft_hole)
	_tile("ceiling_attic_shaft_1m", 1.0, -ft - s.attic_ceiling_thickness, -ft, "ceiling", s.shaft_hole)
	_tile("floor_hatch_" + _tag(s.hatch_tile), s.hatch_tile, -ft, 0.0, "basement_tile", s.hatch_hole)


## A square tile `side` across, +X +Z from the origin, y0..y1, with an optional hole (K09).
func _tile(file: String, side: float, y0: float, y1: float, paint: String, hole := Rect2()) -> void:
	_begin([paint])
	var boxes: Array[AABB] = []
	if hole.size == Vector2.ZERO:
		boxes.append(_aabb(0, side, y0, y1, 0, side))
	else:
		var h0 := hole.position
		var h1 := hole.end
		boxes.append(_aabb(0, h0.x, y0, y1, 0, side))
		boxes.append(_aabb(h1.x, side, y0, y1, 0, side))
		boxes.append(_aabb(h0.x, h1.x, y0, y1, 0, h0.y))
		boxes.append(_aabb(h0.x, h1.x, y0, y1, h1.y, side))
	for box in boxes:
		if box.size.x > 0.001 and box.size.z > 0.001:
			_box(box, 0)
			_col(box)
	_save(file)


## The elevator shaft's walls (house/04 D07), one piece a storey at the shaft tile's origin, inside
## the tiles' hole: the shaft's walls from the floor tile up to the next storey's (they cover the
## holes' edges), the hatch's opening (elevator_hatch) and a stainless sill sticking out of it. The
## east side is the x 4 partition but in the attic. The car, its hatch panel and buttons are the
## elevator's (M5). Slots: 0 the walls, 1 the sill.
func _shafts() -> void:
	var s := _sizes
	var lip: float = s.shaft_lip
	var w: float = s.shaft_wall
	var hole := s.shaft_hole
	# The partition's face (the hole runs 0.01 m into it) and its far face (the first floor's hatch).
	var face: float = hole.end.x - 0.01
	var far: float = 1.0 + s.partition / 2
	_shaft("shaft_hatch_w", true, false, false, Vector2(hole.position.x - lip, hole.position.x + w + 0.02))
	_shaft("shaft_closed", false, false, false, Vector2(face - w, far + lip))
	_shaft("shaft_attic", false, true, true, Vector2(hole.end.x - w - 0.02, hole.end.x + lip))


func _shaft(file: String, west_hatch: bool, east_wall: bool, east_hatch: bool, sill_x: Vector2) -> void:
	var s := _sizes
	var h := s.elevator_hatch
	var w: float = s.shaft_wall
	var hole := s.shaft_hole
	var attic := east_wall
	var x0 := hole.position.x
	var x1: float = hole.end.x if east_wall else hole.end.x - 0.01
	var z0 := hole.position.y
	var z1 := hole.end.y
	var y0: float = -s.sink
	var y1: float = s.attic_shaft if attic else s.storey - s.sink
	_begin(["shaft", "stainless"])
	var boxes: Array[AABB] = [_aabb(x0, x1, y0, y1, z0, z0 + w), _aabb(x0, x1, y0, y1, z1 - w, z1)]
	for side: Array in [[x0, x0 + w, west_hatch], [x1 - w, x1, east_hatch]]:
		if side[0] > x0 and not east_wall:
			continue
		var a: float = side[0]
		var b: float = side[1]
		if side[2]:
			boxes.append_array([_aabb(a, b, y0, y1, z0 + w, h.x), _aabb(a, b, y0, y1, h.y, z1 - w),
					_aabb(a, b, y0, h.z, h.x, h.y), _aabb(a, b, h.w, y1, h.x, h.y)])
		else:
			boxes.append(_aabb(a, b, y0, y1, z0 + w, z1 - w))
	if attic:
		boxes.append(_aabb(x0, x1, y1, y1 + w, z0, z1))
	for box in boxes:
		_box(box, 0)
		_col(box)
	# The sill: 5 mm proud of the opening's foot, so its top lies in no face of the walls.
	var sill := _aabb(sill_x.x, sill_x.y, h.z - 0.025, h.z + 0.005, h.x - w, h.y + w)
	_box(sill, 1)
	_col(sill)
	_save(file)


func _stairs() -> void:
	var s := _sizes
	_flight("stair_full", s.stair_steps)
	@warning_ignore("integer_division")
	_flight("stair_half", s.stair_steps / 2)
	_begin(["wood"])
	var landing := _aabb(0, s.landing.x, -s.sink, s.storey / 2, 0, s.landing.y)
	_box(landing, 0)
	_col(landing)
	_save("landing")
	_u_stair("stair_u", false)
	_u_stair("stair_u_solid", true)
	_newel_top()
	_balustrade()


## house/01's straight flight of `steps` steps rising towards +Z from the origin. It collides through
## one ramp under the steps' middles and a flat box on the top step.
func _flight(file: String, steps: int) -> void:
	var s := _sizes
	var w: float = s.stair_width
	var g: float = s.stair_going
	var r: float = s.step_rise()
	_begin(["wood"])
	for i in steps:
		_box(_aabb(0, w, -s.sink, (i + 1) * r, i * g, (i + 1) * g), 0)
	var top := steps * r
	var run := steps * g
	_ramp(Vector3(w / 2, r / 2, 0.0), Vector3(w / 2, top, run - g / 2), w, false)
	_col(_aabb(0, w, top - RAMP_DEPTH, top, run - g / 2, run))
	_save(file)


## The old U stair of one storey (K10), origin on the well's corner: x 0 the west partition's centre
## line, z 0 the first riser. The west flight rises south to the half landing, the east flight north
## to the next floor; the newel wall between them. `solid`: the lowest storey's, its steps down to
## the floor. The player walks two ramps as the old ones (a plane 1 cm over the nosings).
func _u_stair(file: String, solid: bool) -> void:
	var s := _sizes
	var info := _u_numbers()
	var f: float = info["f"]
	var mid: float = info["mid"]
	var land_z: float = info["land_z"]
	var g: float = info["going"]
	var r: float = info["rise"]
	var back: float = info["back"]
	var half: float = s.storey / 2
	var n: float = s.newel
	var west := Vector2(f, mid - n / 2)
	var east := Vector2(mid + n / 2, s.stair_well.x - f)
	_begin(["oak", "trim"])
	for k in range(1, 8):
		var top := k * r
		_box(_aabb(west.x, west.y, _step_bottom(top, solid), top, (k - 1) * g, k * g), 0)
		top = half + k * r
		_box(_aabb(east.x, east.y, _step_bottom(top, solid), top, land_z - k * g, land_z - (k - 1) * g), 0)
	var landing := _aabb(f, s.stair_well.x - f, -s.sink if solid else half - 0.2, half, land_z, back)
	_box(landing, 0)
	var newel := _aabb(mid - n / 2, mid + n / 2, -s.sink, s.storey - s.sink, 0, land_z)
	_box(newel, 1)
	_ramp(Vector3((west.x + west.y) / 2, 0.0, -g), Vector3((west.x + west.y) / 2, half, land_z), west.y - west.x, true)
	_ramp(Vector3((east.x + east.y) / 2, half, land_z + g), Vector3((east.x + east.y) / 2, s.storey, 0.0), east.y - east.x, true)
	_col(landing)
	_col(newel)
	_save(file)


## The U stair's numbers from the sizes (plan K10).
func _u_numbers() -> Dictionary:
	var s := _sizes
	var back: float = s.stair_well.y - s.exterior / 2
	var land_z: float = back - s.half_landing
	return {"f": s.partition / 2, "mid": s.stair_well.x / 2, "land_z": land_z, "back": back,
			"going": land_z / 7.0, "rise": s.storey / s.stair_steps}


func _step_bottom(top: float, solid: bool) -> float:
	return -_sizes.sink if solid else maxf(-_sizes.sink, top - _sizes.step_depth)


## The attic's end of the newel wall, a handrail high, with its oak cap (the old newel's top).
func _newel_top() -> void:
	var s := _sizes
	var info := _u_numbers()
	var mid: float = info["mid"]
	var land_z: float = info["land_z"]
	var n: float = s.newel
	_begin(["oak", "trim"])
	var wall := _aabb(mid - n / 2, mid + n / 2, -s.sink, 1.0, 0, land_z)
	var cap := _aabb(mid - n / 2 - 0.02, mid + n / 2 + 0.02, 1.0, 1.05, -0.02, land_z)
	_box(wall, 1)
	_box(cap, 0)
	_col(wall)
	_col(cap)
	_save("stair_newel_top")


## The attic's balustrade round the stair void (the old one): west, north over the up flight, east;
## a handrail, a bottom rail and spindles every 0.12 m.
func _balustrade() -> void:
	var s := _sizes
	var info := _u_numbers()
	var f: float = info["f"]
	var back: float = info["back"]
	var w: float = s.stair_well.x
	# The north rail stands 0.01 m back from the void's edge: its foot, under the floor line, would
	# otherwise lie in the floor tile's edge face (K14, house/03).
	var rails: Array[AABB] = [_aabb(f - 0.06, f, 0, 1, 0, back), _aabb(f, info["mid"] - s.newel / 2, 0, 1, -0.07, -0.01),
			_aabb(w - f, w - f + 0.06, 0, 1, 0, back)]
	# The side rails are drawn only as far south as the roof's underside clears the handrail by 5 cm:
	# beyond, under the low slope, they came out through the roof (house/04 D09, the old house's too).
	# Past their ends the slope is too low for a crouching player (1 m tall, 0.35 m round) to reach
	# the void.
	var clear: float = s.stair_well.y - (s.exterior / 2 + (1.05 - s.knee) / s.slope())
	_begin(["oak"])
	for r in rails:
		var x0 := r.position.x
		var x1 := r.end.x
		var z0 := r.position.z
		var z1 := minf(r.end.z, clear)
		_box(_aabb(x0 - 0.01, x1 + 0.01, 0.95, 1.0, z0, z1), 0)
		_box(_aabb(x0, x1, -s.sink, 0.06, z0, z1), 0)
		var along_x := (x1 - x0) > (z1 - z0)
		var start := x0 if along_x else z0
		var end := x1 if along_x else z1
		var t := start + 0.05
		while t < end - 0.02:
			if along_x:
				_box(_aabb(t - 0.015, t + 0.015, 0.06, 0.95, z0 + 0.015, z1 - 0.015), 0)
			else:
				_box(_aabb(x0 + 0.015, x1 - 0.015, 0.06, 0.95, t - 0.015, t + 0.015), 0)
			t += 0.12
		_col(_aabb(x0, x1, -s.sink, 1.0, z0, z1))
	_save("stair_balustrade")


func _roof() -> void:
	var s := _sizes
	for length: float in s.lengths:
		var rafters: Array[float] = []
		var x := 0.5
		while x < length - 0.01:
			rafters.append(x)
			x += 1.0
		_slope("roof_" + _tag(length), 0.0, length, rafters)
	_slope("roof_verge_w", -s.verge, 0.0, [])
	_slope("roof_verge_e", 0.0, s.verge, [])
	_dormer("dormer", s.dormer_window.x)
	_dormer("dormer_grid", s.dormer_window_grid)
	var gw := s.gable_window
	_gable("gable_exterior", gw.x, gw.w)
	_gable("gable_exterior_mirrored", gw.x, s.gable_length - gw.w)
	_gable("gable_exterior_grid", s.gable_window_grid, gw.w)
	_gable("gable_exterior_grid_mirrored", s.gable_window_grid, s.gable_length - gw.w)
	_post()


## One roof slope from x0 to x1 (K11), origin on the outer wall's centre line at the attic floor:
## the slab from the eave (-eave) up to the ridge (roof_span, cut upright so the far slope, the same
## piece turned half round, meets it face to face), half the ridge board, rafters at `rafters`.
## Slots: the rafters' colour under, the tiles over.
func _slope(file: String, x0: float, x1: float, rafters: Array[float]) -> void:
	_begin(["rafter", "roof_tile"])
	_slab(x0, x1, -_sizes.eave, _sizes.roof_span)
	_ridge_board(x0, x1)
	for xr in rafters:
		_rafter(xr)
	_slab_col(x0, x1, -_sizes.eave, _sizes.roof_span)
	_save(file)


func _slab(x0: float, x1: float, za: float, zb: float) -> void:
	var s := _sizes
	var up: float = s.roof_thickness / cos(deg_to_rad(s.pitch))
	var corners: Array[Vector3] = [
		Vector3(x0, s.roof_under(za), za), Vector3(x1, s.roof_under(za), za),
		Vector3(x1, s.roof_under(zb), zb), Vector3(x0, s.roof_under(zb), zb),
	]
	var tops: Array[Vector3] = []
	for c in corners:
		tops.append(c + Vector3(0, up, 0))
	var tile_n := Vector3(0, cos(deg_to_rad(s.pitch)), -sin(deg_to_rad(s.pitch)))
	_prism(corners, tops, func(_c: Vector3, n: Vector3) -> int: return 1 if n.dot(tile_n) > 0.99 else 0)


func _slab_col(x0: float, x1: float, za: float, zb: float) -> void:
	var s := _sizes
	var p := deg_to_rad(s.pitch)
	var up: float = s.roof_thickness / cos(p)
	var zc := (za + zb) / 2
	var basis := Basis(Vector3.RIGHT, Vector3(0, cos(p), -sin(p)), Vector3(0, sin(p), cos(p)))
	var centre := Vector3((x0 + x1) / 2, s.roof_under(zc) + up / 2, zc)
	_shapes.append(Transform3D(basis, centre))
	_shape_sizes.append(Vector3(x1 - x0, s.roof_thickness, (zb - za) / cos(p)))


func _ridge_board(x0: float, x1: float) -> void:
	var s := _sizes
	# Half the old board (0.32 m over the ridge's underside), sitting on the slab's top face so its
	# ends never share a plane with the slab's ends (K14).
	var up: float = s.roof_thickness / cos(deg_to_rad(s.pitch))
	var r: float = s.roof_span
	var top: float = s.roof_under(r) + 0.32
	var section: Array[Vector2] = [Vector2(r - 0.09, s.roof_under(r - 0.09) + up), Vector2(r, s.roof_under(r) + up),
			Vector2(r, top), Vector2(r - 0.09, top)]
	var lows: Array[Vector3] = []
	var highs: Array[Vector3] = []
	for p in section:
		lows.append(Vector3(x0, p.y, p.x))
		highs.append(Vector3(x1, p.y, p.x))
	_prism(lows, highs, 1)


## A rafter at x under the slab, from the wall's inside face to just short of the ridge.
func _rafter(x: float) -> void:
	var s := _sizes
	var za: float = s.exterior / 2
	var zb: float = s.roof_span - 0.05
	var lows: Array[Vector3] = [Vector3(x - 0.04, s.roof_under(za) - 0.12, za), Vector3(x + 0.04, s.roof_under(za) - 0.12, za),
			Vector3(x + 0.04, s.roof_under(zb) - 0.12, zb), Vector3(x - 0.04, s.roof_under(zb) - 0.12, zb)]
	var highs: Array[Vector3] = []
	for c in lows:
		highs.append(c + Vector3(0, 0.13, 0))
	_prism(lows, highs, 0)


## The dormer (K11): cheeks, its front wall over the knee with the window, a flat roof and ceiling,
## and the slope above it to the ridge; between its cheeks' centre lines x 0..dormer.x, in the north
## slope's frame (turned half round like the south slope's pieces). Window `ww` wide.
func _dormer(file: String, ww: float) -> void:
	var s := _sizes
	var w: float = s.dormer.x
	var top: float = s.dormer.y
	var t: float = s.exterior
	var f := t / 2
	var knee_top: float = s.knee + 0.1
	var dz: float = f + (top - s.knee) / s.slope()
	_begin(["wall_loft", "wall_outside", "trim", "glass", "rafter", "roof_tile", "ceiling"])
	var roof := _aabb(-0.2, w + 0.2, top, top + 0.2, -s.eave, dz)
	_box(roof, 5)
	_box(_aabb(f, w - f, top - 0.01, top, f, dz), 6)
	_begin_offset(4)
	_slab(0.0, w, dz, s.roof_span)
	_ridge_board(0.0, w)
	_end_offset()
	for xc: float in [0.0, w]:
		var inward := 1.0 if xc < w / 2 else -1.0
		var tri: Array[Vector2] = [Vector2(-f, knee_top), Vector2(-f, top + 0.1), Vector2(dz, top + 0.1)]
		var lows: Array[Vector3] = []
		var highs: Array[Vector3] = []
		for p in tri:
			lows.append(Vector3(xc - f, p.y, p.x))
			highs.append(Vector3(xc + f, p.y, p.x))
		_prism(lows, highs, func(_c: Vector3, n: Vector3) -> int: return A if n.x * inward > 0.5 else B)
		var za := dz * 0.4
		_col(_aabb(xc - f, xc + f, s.roof_under(za) + 0.1, top + 0.1, za, dz))
	var c := w / 2
	var a := c - ww / 2
	var b := c + ww / 2
	var sill: float = s.dormer_window.y
	var head: float = s.dormer_window.z
	for box: AABB in [_aabb(f, a, knee_top, top + 0.1, -f, f), _aabb(b, w - f, knee_top, top + 0.1, -f, f),
			_aabb(a, b, knee_top, sill, -f, f), _aabb(a, b, head, top + 0.1, -f, f)]:
		_box(box, _wall_pick, true)
		_col(box)
	_frame(a, b, sill, head, t, f, w - f)
	_col(roof)
	_slab_col(0.0, w, dz, s.roof_span)
	_save(file)


## A gable wall from wall line to wall line (K11), +X along, its corners closed (-t/2 .. length+t/2),
## its top inside the roof slab, with its window `ww` wide centred at `c`; skirting inside.
func _gable(file: String, ww: float, c: float) -> void:
	var s := _sizes
	var t: float = s.exterior
	var g: float = s.gable_length
	var sill: float = s.gable_window.y
	var head: float = s.gable_window.z
	var a := c - ww / 2
	var b := c + ww / 2
	var y0: float = -s.sink
	var top := func(x: float) -> float: return s.roof_under(minf(x, g - x)) + 0.1
	_begin(["wall_loft", "wall_outside", "trim", "glass"])
	var cuts: Array[float] = [-t / 2, a, b, g / 2, g + t / 2]
	cuts.sort()
	for i in cuts.size() - 1:
		var x0 := cuts[i]
		var x1 := cuts[i + 1]
		var y_low := y0
		if is_equal_approx(x0, a):
			var below := _aabb(a, b, y0, sill, -t / 2, t / 2)
			_box(below, _wall_pick, true)
			_col(below)
			y_low = head
		# Each strip collides up to its lower top edge, so the box stays inside the drawn wall.
		_col(_aabb(x0, x1, y_low, minf(top.call(x0), top.call(x1)), -t / 2, t / 2))
		var lows: Array[Vector3] = [Vector3(x0, y_low, -t / 2), Vector3(x1, y_low, -t / 2), Vector3(x1, y_low, t / 2), Vector3(x0, y_low, t / 2)]
		var highs: Array[Vector3] = [Vector3(x0, top.call(x0), -t / 2), Vector3(x1, top.call(x1), -t / 2),
				Vector3(x1, top.call(x1), t / 2), Vector3(x0, top.call(x0), t / 2)]
		_prism(lows, highs, _wall_pick, true)
	_frame(a, b, sill, head, t)
	_skirting(Vector3(t / 2, 0, t / 2), Vector3.RIGHT, Vector3.BACK, g - t)
	_save(file)


## A roof post (the old ones), centred post_at into its piece, standing post_from_wall from the wall
## line, up into the slab.
func _post() -> void:
	var s := _sizes
	var h: float = s.post_side / 2
	var p := s.post_at
	var y1: float = s.roof_under(s.post_from_wall)
	_begin(["rafter"])
	_box(_aabb(p.x - h, p.x + h, -s.sink, y1 + 0.05, p.y - h, p.y + h), 0)
	_col(_aabb(p.x - h, p.x + h, -s.sink, y1, p.y - h, p.y + h))
	_save("roof_post")


# --- The sample rooms ---------------------------------------------------------------------------

func _rooms() -> void:
	_u_room()
	_attic_corner()


## The station's room (K13): a slice of the house's hall and landing (x 4..6.5 of the plan) on two
## storeys: the front door, the U stair, the first floor's landing with its north window (W17). The
## ground storey has no floor tiles: in the zoo the zoo floor is its floor (K14).
func _u_room() -> void:
	var s := _sizes
	var h: float = s.storey
	var room := Node3D.new()
	room.name = "URoom"
	var hall := load(MATERIALS.path_join("wall_hall.tres")) as Material
	for y: float in [0.0, h]:
		# The north wall, west to east, inside +Z; stubs either side where the house runs on.
		_put(room, "wall_exterior_05m", Vector3(-0.5, y, 0), 0)
		if y == 0.0:
			_put(room, "wall_exterior_1m", Vector3(0, y, 0), 0)
			_put(room, "door_exterior_15m", Vector3(1.0, y, 0), 0, {0: hall})
		else:
			_put(room, "wall_exterior_05m", Vector3(0, y, 0), 0)
			_put(room, _window_name(Vector4(1.1, 0.9, 2.1, 1.5), false), Vector3(0.5, y, 0), 0, {0: hall})
			_put(room, "wall_exterior_05m", Vector3(2.0, y, 0), 0)
			_put(room, "wall_exterior_05m", Vector3(2.5, y, 0), 0)
		if y == 0.0:
			_put(room, "wall_exterior_05m", Vector3(2.5, y, 0), 0)
		# The south wall's stubs, east to west (turned half round: inside -Z).
		_put(room, "wall_exterior_05m", Vector3(0, y, 8.5), 180)
		_put(room, "wall_exterior_05m", Vector3(3.0, y, 8.5), 180)
		# The partitions either side, south from the north wall's face to the south wall's face.
		for x: float in [0.0, 2.5]:
			var paint := {1: hall} if x == 0.0 else {0: hall}
			_put(room, "wall_partition_end_exterior_2m", Vector3(x, y, 0), -90, paint)
			for z: float in [2.0, 4.0, 6.0]:
				_put(room, "wall_partition_2m", Vector3(x, y, z), -90, paint)
			_put(room, "wall_partition_end_exterior_05m", Vector3(x, y, 8.5), 90, {0: hall} if x == 0.0 else {1: hall})
	_put(room, "window_stair", Vector3(2.5, 0, 8.5), 180, {0: hall})
	_put(room, "stair_u", Vector3(0, 0, 5.5), 0)
	# The landing's floor and the hall's ceiling under it, z 0..5.5.
	var squares: Array = [["2m", 0.0, 0.0], ["2m", 0.0, 2.0], ["1m", 0.0, 4.0], ["1m", 1.0, 4.0]]
	for x: float in [0.0, 0.5, 1.0, 1.5]:
		squares.append(["05m", x, 5.0])
	for z in 11:
		squares.append(["05m", 2.0, z * 0.5])
	for sq: Array in squares:
		_put(room, "floor_" + sq[0], Vector3(sq[1], h, sq[2]), 0)
		_put(room, "ceiling_" + sq[0], Vector3(sq[1], h, sq[2]), 0)
	_save_room(room, "u_room")


## A roof corner with the dormer (K11, the second stop's close-up): a 6 m slice of the attic closed by
## both gables (an open end would show the slab's and the knee walls' cut ends), the knee walls, both
## slopes with their verges, the dormer and a post, on the floor.
func _attic_corner() -> void:
	var s := _sizes
	var d: float = s.gable_length
	var w := 6.0
	var room := Node3D.new()
	room.name = "AtticCorner"
	_put(room, "gable_exterior_mirrored", Vector3(0, 0, d), 90)
	_put(room, "gable_exterior", Vector3(w, 0, 0), -90)
	# The north knee wall, west to east, gable face to gable face.
	_put(room, "knee_exterior_start_1m", Vector3(0, 0, 0), 0)
	_put(room, "knee_exterior_2m", Vector3(1, 0, 0), 0)
	_put(room, "knee_exterior_2m", Vector3(3, 0, 0), 0)
	_put(room, "knee_exterior_end_1m", Vector3(5, 0, 0), 0)
	# The south one, east to west (turned half round: inside -Z).
	_put(room, "knee_exterior_start_1m", Vector3(w, 0, d), 180)
	_put(room, "knee_exterior_1m", Vector3(5, 0, d), 180)
	_put(room, "knee_exterior_2m", Vector3(4, 0, d), 180)
	_put(room, "knee_exterior_1m", Vector3(2, 0, d), 180)
	_put(room, "knee_exterior_end_1m", Vector3(1, 0, d), 180)
	_put(room, "roof_verge_w", Vector3(0, 0, 0), 0)
	for x: float in [0.0, 2.0, 4.0]:
		_put(room, "roof_2m", Vector3(x, 0, 0), 0)
	_put(room, "roof_verge_e", Vector3(w, 0, 0), 0)
	_put(room, "roof_verge_e", Vector3(0, 0, d), 180)
	_put(room, "roof_verge_w", Vector3(w, 0, d), 180)
	_put(room, "roof_2m", Vector3(2, 0, d), 180)
	_put(room, "dormer", Vector3(4, 0, d), 180)
	_put(room, "roof_2m", Vector3(w, 0, d), 180)
	_put(room, "roof_post", Vector3(1.0, 0, s.post_from_wall - s.post_at.y), 0)
	_save_room(room, "attic_corner")



## A piece in a room at `at`, turned `deg` about the vertical, with material overrides {slot: material}.
func _put(room: Node3D, file: String, at: Vector3, deg: float, paints := {}) -> void:
	var scene := load(PIECES.path_join(file + ".tscn")) as PackedScene
	var piece := scene.instantiate() as MeshInstance3D
	piece.position = at
	piece.rotation.y = deg_to_rad(deg)
	for slot: int in paints:
		piece.set_surface_override_material(slot, paints[slot])
	room.add_child(piece, true)
	piece.owner = room


func _save_room(room: Node3D, file: String) -> void:
	var path := ROOMS.path_join(file + ".tscn")
	var uid := ResourceLoader.get_resource_uid(path) if FileAccess.file_exists(path) else ResourceUID.INVALID_ID
	var packed := PackedScene.new()
	packed.pack(room)
	if ResourceSaver.save(packed, path) != OK:
		push_error("house_kit_build: cannot save %s" % path)
	else:
		keep_uid(path, uid)
	room.queue_free()   # never in the tree; gone at the frame end


# --- Geometry -----------------------------------------------------------------------------------

## "05m", "1m", "15m", "2m": a length in a file name.
static func _tag(metres: float) -> String:
	if is_equal_approx(metres, roundf(metres)):
		return "%dm" % int(metres)
	return ("%sm" % str(metres)).replace("0.", "0").replace(".", "")


static func _aabb(x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> AABB:
	return AABB(Vector3(x0, y0, z0), Vector3(x1 - x0, y1 - y0, z1 - z0))


## A wall's slots: the +Z face inside (A), the -Z face outside (B), and every other face split at the
## wall's middle (z 0) so each half of its thickness takes its side's paint.
static func _wall_pick(c: Vector3, n: Vector3) -> int:
	if n.z > 0.5:
		return A
	if n.z < -0.5:
		return B
	return A if c.z >= 0.0 else B


func _begin(paints: Array[String]) -> void:
	_paints = paints
	_st.clear()
	for p in paints:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_st.append(st)
	_shapes.clear()
	_shape_sizes.clear()
	_offset = 0


func _begin_offset(base: int) -> void:
	_offset = base


func _end_offset() -> void:
	_offset = 0


func _col(box: AABB) -> void:
	_shapes.append(Transform3D(Basis.IDENTITY, box.get_center()))
	_shape_sizes.append(box.size)


## A walking ramp from p0 to p1 (the top face 1 cm over them), `width` across X.
func _ramp(p0: Vector3, p1: Vector3, width: float, lift: bool) -> void:
	var up := Vector3(0, 0.01 if lift else 0.0, 0)
	var a := p0 + up
	var b := p1 + up
	var z_axis := (b - a).normalized()
	var y_axis := (Vector3.UP - z_axis * z_axis.dot(Vector3.UP)).normalized()
	var x_axis := y_axis.cross(z_axis)
	var basis := Basis(x_axis, y_axis, z_axis)
	_shapes.append(Transform3D(basis, (a + b) / 2 - y_axis * (RAMP_DEPTH / 2)))
	_shape_sizes.append(Vector3(width, RAMP_DEPTH, a.distance_to(b)))


## A triangle given counter-clockwise seen from outside, into slot `slot`.
func _tri(slot: int, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	var st := _st[slot + _offset]
	# Godot's front faces wind clockwise: emit a, c, b.
	for v: Vector3 in [a, c, b]:
		st.set_normal(n)
		st.set_uv(_uv(v, n))
		st.add_vertex(v)


## A convex planar polygon facing away from `centre`, into the slot `pick` gives for it (an int, or
## a Callable (centre, normal) -> int); `split` cuts a face that crosses z 0 (and does not face
## along Z) into its two halves first.
func _face(poly: Array[Vector3], centre: Vector3, pick: Variant, split := false) -> void:
	var c := Vector3.ZERO
	for v in poly:
		c += v
	c /= poly.size()
	var n := (poly[1] - poly[0]).cross(poly[2] - poly[0]).normalized()
	if n.dot(c - centre) < 0.0:
		poly.reverse()
		n = -n
	if split and absf(n.z) < 0.5:
		var lo := INF
		var hi := -INF
		for v in poly:
			lo = minf(lo, v.z)
			hi = maxf(hi, v.z)
		if lo < -1e-5 and hi > 1e-5:
			for half: float in [-1.0, 1.0]:
				var part: Array[Vector3] = []
				for v in poly:
					part.append(Vector3(v.x, v.y, minf(v.z, 0.0) if half < 0.0 else maxf(v.z, 0.0)))
				_face(part, centre, pick, false)
			return
	var slot: int = pick.call(c, n) if pick is Callable else int(pick)
	for i in range(1, poly.size() - 1):
		_tri(slot, poly[0], poly[i], poly[i + 1])


func _box(b: AABB, pick: Variant, split := false) -> void:
	var p := b.position
	var e := b.end
	var lows: Array[Vector3] = [Vector3(p.x, p.y, p.z), Vector3(e.x, p.y, p.z), Vector3(e.x, p.y, e.z), Vector3(p.x, p.y, e.z)]
	var highs: Array[Vector3] = [Vector3(p.x, e.y, p.z), Vector3(e.x, e.y, p.z), Vector3(e.x, e.y, e.z), Vector3(p.x, e.y, e.z)]
	_prism(lows, highs, pick, split)


## A convex solid between two polygons with matching corners (a box, a sloped strip, a cheek).
func _prism(lows: Array[Vector3], highs: Array[Vector3], pick: Variant, split := false) -> void:
	var centre := Vector3.ZERO
	for v in lows + highs:
		centre += v
	centre /= lows.size() + highs.size()
	_face(lows.duplicate(), centre, pick, split)
	_face(highs.duplicate(), centre, pick, split)
	for i in lows.size():
		var j := (i + 1) % lows.size()
		_face([lows[i], lows[j], highs[j], highs[i]] as Array[Vector3], centre, pick, split)


## The old skirting (make_flat.py SKIRTING) from `start` along `run` for `length`, standing off the
## wall towards `out`; its foot trim_sink under the floor line.
func _skirting(start: Vector3, run: Vector3, out: Vector3, length: float) -> void:
	if length < 0.001:
		return
	var s := _sizes
	var h: float = s.skirting_height
	var d: float = s.skirting_depth
	var foot: float = -s.trim_sink
	var profile: Array[Vector2] = [Vector2(0, foot), Vector2(d, foot), Vector2(d, h * 0.792), Vector2(d * 0.773, h * 0.933),
			Vector2(d * 0.364, h), Vector2(0, h)]
	var lows: Array[Vector3] = []
	var highs: Array[Vector3] = []
	for p in profile:
		var at := start + out * p.x + Vector3.UP * p.y
		lows.append(at)
		highs.append(at + run * length)
	_prism(lows, highs, TRIM)


## Metres across the face: a tiled texture keeps its scale on every piece.
static func _uv(c: Vector3, n: Vector3) -> Vector2:
	if absf(n.x) >= absf(n.y) and absf(n.x) >= absf(n.z):
		return Vector2(c.z, -c.y)
	if absf(n.y) >= absf(n.z):
		return Vector2(c.x, c.z)
	return Vector2(c.x, -c.y)


func _save(file: String) -> void:
	if _only != "" and not file.begins_with(_only):
		return
	var mesh := ArrayMesh.new()
	for i in _st.size():
		var st := _st[i]
		st.set_material(_material(_paints[i]))
		st.index()
		var arrays := st.commit_to_arrays()
		if (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
			push_error("house_kit_build: %s has nothing in slot %d (%s)" % [file, i, _paints[i]])
			return
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(i, _material(_paints[i]))
	var mesh_path := MESHES.path_join(file + ".tres")
	var mesh_uid := ResourceLoader.get_resource_uid(mesh_path) if FileAccess.file_exists(mesh_path) else ResourceUID.INVALID_ID
	mesh.resource_name = file
	if ResourceSaver.save(mesh, mesh_path) != OK:
		push_error("house_kit_build: cannot save %s" % mesh_path)
		return
	keep_uid(mesh_path, mesh_uid)
	var root := MeshInstance3D.new()
	root.name = file.to_pascal_case()
	root.mesh = load(mesh_path)
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = LAYER_HOUSE
	body.collision_mask = 0
	root.add_child(body)
	body.owner = root
	for i in _shapes.size():
		var shape := CollisionShape3D.new()
		shape.name = "Box" if _shapes.size() == 1 else "Box%d" % (i + 1)
		var box := BoxShape3D.new()
		box.size = _shape_sizes[i]
		shape.shape = box
		shape.transform = _shapes[i]
		body.add_child(shape)
		shape.owner = root
	var path := PIECES.path_join(file + ".tscn")
	var uid := ResourceLoader.get_resource_uid(path) if FileAccess.file_exists(path) else ResourceUID.INVALID_ID
	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, path)
	if err != OK:
		push_error("house_kit_build: cannot save %s (%s)" % [path, error_string(err)])
	else:
		keep_uid(path, uid)
	root.queue_free()   # never in the tree; gone at the frame end


## The editor's format (Q2268): the file carries a uid, the same one as before a rebuild, and each
## reference its target's uid (old_house_build.gd uses it too).
static func keep_uid(path: String, uid: int) -> void:
	if uid == ResourceUID.INVALID_ID:
		uid = ResourceUID.create_id()
	ResourceSaver.set_uid(path, uid)
	if ResourceUID.has_id(uid):
		ResourceUID.set_id(uid, path)
	else:
		ResourceUID.add_id(uid, path)
	# A script run writes its references by path only; the editor adds each one's uid.
	var text := FileAccess.get_file_as_string(path)
	var out := PackedStringArray()
	for line in text.split("\n"):
		if line.begins_with("[ext_resource ") and not line.contains(" uid=\""):
			var target := line.get_slice("path=\"", 1).get_slice("\"", 0)
			var id := ResourceLoader.get_resource_uid(target)
			if id != ResourceUID.INVALID_ID:
				line = line.replace(" path=\"", " uid=\"%s\" path=\"" % ResourceUID.id_to_text(id))
		out.append(line)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("keep_uid: cannot write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string("\n".join(out))


## The library's material `name`, made from LIBRARY only when its file does not exist yet.
func _material(name: String) -> Material:
	var path := MATERIALS.path_join(name + ".tres")
	if FileAccess.file_exists(path):
		return load(path)
	var spec: Array = LIBRARY[name]
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_color = spec[0]
	m.roughness = spec[1]
	m.metallic = float(METALLIC.get(name, 0.0))
	if spec.size() > 2 and spec[2] is float:
		m.albedo_color.a = spec[2]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	elif spec.size() > 2:
		m.albedo_texture = load(TEXTURES.path_join(spec[2]))
		# World triplanar: the texture runs on across neighbouring pieces, whatever their turn.
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE / float(spec[3])
	var err := ResourceSaver.save(m, path)
	if err != OK:
		push_error("house_kit_build: cannot save %s (%s)" % [path, error_string(err)])
	else:
		keep_uid(path, ResourceUID.INVALID_ID)
	return load(path)


## A wall paint with the tile wainscot (WAINSCOT: the paint, the tile image, its repeat, its
## roughness), made only when its file does not exist yet; the band takes the trim's colour.
func _wainscot_material(name: String) -> Material:
	var path := MATERIALS.path_join(name + ".tres")
	if FileAccess.file_exists(path):
		return load(path)
	var spec: Array = WAINSCOT[name]
	var paint: Array = LIBRARY[spec[0]]
	var trim: Array = LIBRARY["trim"]
	var m := ShaderMaterial.new()
	m.resource_name = name
	m.shader = load(WAINSCOT_SHADER)
	m.set_shader_parameter("paint", paint[0])
	m.set_shader_parameter("paint_roughness", paint[1])
	m.set_shader_parameter("tiles", load(TEXTURES.path_join(spec[1])))
	m.set_shader_parameter("tile_repeat", spec[2])
	m.set_shader_parameter("tile_roughness", spec[3])
	# make_flat.py make_wall_tiles: to 1.2 m, the trim 0.035 m over it.
	m.set_shader_parameter("top", 1.2)
	# The trim is a raised strip now (wainscot_trim_* pieces), not a painted band.
	m.set_shader_parameter("band", 0.0)
	m.set_shader_parameter("band_colour", trim[0])
	m.set_shader_parameter("band_roughness", trim[1])
	var err := ResourceSaver.save(m, path)
	if err != OK:
		push_error("house_kit_build: cannot save %s (%s)" % [path, error_string(err)])
	else:
		keep_uid(path, ResourceUID.INVALID_ID)
	return load(path)
