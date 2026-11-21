## The house kit's sizes (house/01, house/02): one .tres beside it (house_kit_sizes.tres), edited in
## the inspector. The pieces in pieces/ are made from it by house_kit_build.gd; after a change here,
## run that script again (its header says how). The numbers are the old house's on the half-metre
## grid (Q2175, Q2325, Q2343; the plan: docs/architecture/house-kit-plan.md).
class_name HouseKitSizes
extends Resource

@export_group("Grid")
## Godot's own snap step every piece's origin sits on (Q2175, Q2327).
@export_range(0.25, 1.0, 0.25, "suffix:m") var grid := 0.5
## Floor top to the next floor's top: the old house's 2.9 m on every floor, nudged to the grid.
@export_range(2.0, 4.0, 0.5, "suffix:m") var storey := 3.0
## Wall lengths of the straight pieces (Q2326).
@export var lengths: Array[float] = [0.5, 1.0, 2.0]
## Floor and ceiling tile sides (Q2326).
@export var tiles: Array[float] = [0.5, 1.0, 2.0]
## The no-z-fight rule (K14, Q2358): what stands on a floor starts this far under the floor line,
## inside the floor tile, and a wall ends this far under the next floor line, so no face of it lies
## in a tile's face. Walls, newels, stair steps and the balustrade use it.
@export_range(0.005, 0.05, 0.005, "suffix:m") var sink := 0.02
## The same for trim (skirting, casings) and, deeper, for the door linings, so trim never shares a
## face plane with the wall or with another trim.
@export_range(0.002, 0.05, 0.001, "suffix:m") var trim_sink := 0.01
@export_range(0.002, 0.05, 0.001, "suffix:m") var lining_sink := 0.015

@export_group("Walls")
## The old house's outside wall.
@export_range(0.05, 0.5, 0.01, "suffix:m") var exterior := 0.2
## The old house's partition between rooms.
@export_range(0.05, 0.5, 0.01, "suffix:m") var partition := 0.12
## How far a corner's or a T's arms reach from the join, on the grid.
@export_range(0.25, 1.0, 0.25, "suffix:m") var arm := 0.5
## The old rooms' skirting (make_flat.py SKIRTING): its height and how far it stands off the wall.
@export_range(0.05, 0.3, 0.01, "suffix:m") var skirting_height := 0.12
@export_range(0.005, 0.05, 0.001, "suffix:m") var skirting_depth := 0.022

@export_group("Floors")
## A floor tile, down from its top at the piece's origin.
@export_range(0.02, 0.3, 0.01, "suffix:m") var floor_thickness := 0.1
## A ceiling tile, right under the floor tile of the same square: 0.2 m keeps the old 2.7 m clear
## height on the basement and ground floors (Q2353).
@export_range(0.02, 0.5, 0.01, "suffix:m") var ceiling_thickness := 0.2
## The first floor's ceiling, under the attic floor: 0.3 m keeps its old 2.6 m (Q2353).
@export_range(0.02, 0.5, 0.01, "suffix:m") var attic_ceiling_thickness := 0.3
## The elevator shaft's hole in a 1 m tile (x, z from the tile's origin, plan K09). Its east side
## runs 0.01 m into the x 4 partition, so the hole's side never lies in the partition's face (K14,
## house/03): the shaft stays 0.7 m wide inside, from x 3.24 to the partition's face.
@export var shaft_hole := Rect2(0.24, 0.3, 0.71, 0.7)
## The Cellar hatch's hole, in the middle of a tile this big (plan K09).
@export_range(0.5, 3.0, 0.5, "suffix:m") var hatch_tile := 1.5
@export var hatch_hole := Rect2(0.375, 0.375, 0.75, 0.75)

@export_group("Openings")
## The old house's doorways, inside and front (all 0.9 x 2.1 m).
@export_range(0.5, 1.0, 0.05, "suffix:m") var door_width := 0.9
@export_range(1.8, 2.5, 0.05, "suffix:m") var door_height := 2.1
## The door pieces' lengths, the doorway in their middle.
@export var door_lengths: Array[float] = [1.0, 1.5]
## The off-centre door piece (Q2351): its length and where its doorway starts along it.
@export var door_offset := Vector2(1.5, 0.15)
## The off-centre doorway and the elevator's hatch in one partition (house/03: on the first floor's
## x 4 partition D8's piece and the hatch's would overlap): its length, and where the hatch's 1 m
## (elevator_hatch) starts along it.
@export var door_offset_hatch := Vector2(2.0, 1.0)
## The garage door's opening: width, height, its piece's length.
@export var garage_door := Vector3(2.4, 2.1, 2.5)
## The old jamb linings and casings (make_house.py make_door_frames).
@export_range(0.005, 0.05, 0.005, "suffix:m") var lining := 0.015
@export_range(0.02, 0.15, 0.01, "suffix:m") var casing := 0.07
## house/01's window piece (window_exterior): 1.0 m wide from 0.9 to 2.1 m in a 2 m wall.
@export_range(0.5, 1.8, 0.1, "suffix:m") var window_width := 1.0
@export_range(0.0, 2.0, 0.05, "suffix:m") var window_sill := 0.9
@export_range(1.0, 2.6, 0.05, "suffix:m") var window_head := 2.1
## The old window frame (make_house.py make_windows): its bars, the middle bar over this width.
@export_range(0.02, 0.15, 0.01, "suffix:m") var window_bar := 0.06
@export_range(0.5, 2.0, 0.1, "suffix:m") var mullion_over := 1.0
## Every wall window of the plan, (width, sill, head, piece length), old widths (Q2355).
## placeholder: the designer chooses this set or windows_grid on the comparison still (Q2355)
@export var windows_old: Array[Vector4] = [
	Vector4(0.5, 1.3, 2.0, 1.0), Vector4(0.8, 0.9, 2.1, 1.5), Vector4(1.0, 1.1, 2.15, 1.5),
	Vector4(1.0, 1.75, 2.45, 1.5), Vector4(1.1, 0.9, 2.1, 1.5), Vector4(1.1, 0.9, 2.15, 1.5),
	Vector4(1.2, 0.9, 2.1, 1.5), Vector4(1.2, 0.9, 2.15, 1.5), Vector4(1.2, 1.75, 2.45, 1.5),
	Vector4(1.4, 0.9, 2.1, 1.5), Vector4(1.4, 0.9, 2.15, 1.5), Vector4(1.5, 0.9, 2.1, 2.0),
	Vector4(2.0, 0.9, 2.15, 2.5), Vector4(2.4, 0.9, 2.15, 2.5),
]
## The same windows with their widths rounded to 0.5 m (Q2355).
## placeholder: the designer chooses this set or windows_old (Q2355)
@export var windows_grid: Array[Vector4] = [
	Vector4(0.5, 1.3, 2.0, 1.0), Vector4(1.0, 0.9, 2.1, 1.5), Vector4(1.0, 0.9, 2.15, 1.5),
	Vector4(1.0, 1.1, 2.15, 1.5), Vector4(1.0, 1.75, 2.45, 1.5), Vector4(1.5, 0.9, 2.1, 2.0),
	Vector4(1.5, 0.9, 2.1, 2.5), Vector4(1.5, 0.9, 2.15, 2.5), Vector4(2.0, 0.9, 2.15, 2.5),
	Vector4(2.5, 0.9, 2.15, 3.5),
]
## Frosted ones (the bathroom's), in both sets.
@export var windows_frosted: Array[Vector4] = [Vector4(1.0, 1.3, 2.0, 1.5)]
## The stair window, over the half landing, in a wall two storeys high (plan W12).
@export var stair_window := Vector4(1.5, 2.4, 3.5, 2.5)
## The first floor's elevator hatch through a 1 m partition: from, to along it, sill, head (plan K09).
@export var elevator_hatch := Vector4(0.38, 0.92, 0.8, 1.38)

@export_group("Stairs")
## house/01's straight flights, kept for its first room.
## Across a flight (the old flights were 1.1 m).
@export_range(0.5, 2.0, 0.5, "suffix:m") var stair_width := 1.0 # placeholder: house/01's straight flight, the agent's number
## Steps of a full flight, one storey: 16 rise 0.1875 m each.
@export_range(8, 24, 2) var stair_steps := 16
## A straight flight's step depth.
@export_range(0.2, 0.35, 0.05, "suffix:m") var stair_going := 0.25 # placeholder: house/01's straight flight, the agent's number
## house/01's landing.
@export var landing := Vector2(2.0, 1.0) # placeholder: house/01's landing, the agent's number
## The U stair's well between the partitions' centre lines, from its first riser to the outer
## wall's centre line (plan K10).
@export var stair_well := Vector2(2.5, 3.0)
## The half landing's depth (Q2350: 0.9 m, so 33.3 degrees).
@export_range(0.5, 1.5, 0.05, "suffix:m") var half_landing := 0.9
## The newel wall between the flights.
@export_range(0.05, 0.3, 0.01, "suffix:m") var newel := 0.12
## An upper flight's step: this deep under its tread (the old 0.36).
@export_range(0.1, 0.6, 0.01, "suffix:m") var step_depth := 0.36

@export_group("Roof")
## The knee walls over the attic floor (the old 0.4 m).
@export_range(0.0, 1.5, 0.05, "suffix:m") var knee := 0.4
## Q2354: 40 degrees.
@export_range(20.0, 60.0, 0.5, "suffix:deg") var pitch := 40.0
## From the outer wall's centre line to the ridge (half the 8.5 m depth).
@export_range(1.0, 8.0, 0.25, "suffix:m") var roof_span := 4.25
## The roof slab, across the slope (the old 0.22 m).
@export_range(0.05, 0.5, 0.01, "suffix:m") var roof_thickness := 0.22
## The eave beyond the wall's centre line (the old 0.45 m beyond the inside face) and the verge beyond
## the gable's.
@export_range(0.0, 1.0, 0.05, "suffix:m") var eave := 0.35
@export_range(0.0, 1.0, 0.05, "suffix:m") var verge := 0.35
## The dormer: between its cheeks' centre lines, and its flat ceiling over the attic floor.
@export var dormer := Vector2(2.0, 2.2)
## Its window (width, sill, head), old width; the grid set's width (Q2355).
@export var dormer_window := Vector3(1.2, 0.9, 1.95)
@export_range(0.5, 2.0, 0.5, "suffix:m") var dormer_window_grid := 1.0
## A gable, wall line to wall line, and its window (width, sill, head, centre from its start).
@export_range(2.0, 12.0, 0.5, "suffix:m") var gable_length := 8.5
@export var gable_window := Vector4(0.7, 0.8, 1.7, 2.5)
@export_range(0.5, 2.0, 0.5, "suffix:m") var gable_window_grid := 0.5
## The roof posts: 0.16 m square, centred this far into their piece, standing this far from the
## wall line under the slope (the old posts, plan K11).
@export var post_at := Vector2(0.25, 0.25)
@export_range(0.05, 0.3, 0.01, "suffix:m") var post_side := 0.16
@export_range(0.5, 4.0, 0.25, "suffix:m") var post_from_wall := 1.75


## The height of one step of a flight.
func step_rise() -> float:
	return storey / stair_steps


## The roof's rise per metre of run.
func slope() -> float:
	return tan(deg_to_rad(pitch))


## The roof slab's underside over the attic floor at `z` metres from the wall's centre line: the knee
## height at the wall's inside face.
func roof_under(z: float) -> float:
	return knee + (z - exterior / 2) * slope()
