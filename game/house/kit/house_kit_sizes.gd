## The house kit's sizes (house/01): one .tres beside it (house_kit_sizes.tres), edited in the
## inspector. The pieces in pieces/ are made from it by house_kit_build.gd; after a change here,
## run that script again (its header says how). Walls, storey and openings are the old house's,
## nudged to the half-metre grid (Q2175, Q2325); the stair's numbers are the agent's.
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

@export_group("Walls")
## The old house's outside wall.
@export_range(0.05, 0.5, 0.01, "suffix:m") var exterior := 0.2
## The old house's partition between rooms.
@export_range(0.05, 0.5, 0.01, "suffix:m") var partition := 0.12
## How far a corner's or a T's arms reach from the join, on the grid.
@export_range(0.25, 1.0, 0.25, "suffix:m") var arm := 0.5

@export_group("Floors")
## A floor tile, down from its top at the piece's origin.
@export_range(0.02, 0.3, 0.01, "suffix:m") var floor_thickness := 0.1
## A ceiling tile, under the floor tile of the same grid square (its top one floor thickness
## below the origin), so a storey line holds a floor tile and a ceiling tile, each its own material.
@export_range(0.02, 0.3, 0.01, "suffix:m") var ceiling_thickness := 0.1

@export_group("Openings")
## The old house's doorways, inside and front (all 0.9 x 2.1 m), in a 1 m wall piece.
@export_range(0.5, 1.0, 0.05, "suffix:m") var door_width := 0.9
@export_range(1.8, 2.5, 0.05, "suffix:m") var door_height := 2.1
## The old house's most common window (1.0 m wide; sill 0.9 m and head 2.1 m over the floor on
## the first floor, 2.15 m on the ground floor), in a 2 m wall piece.
@export_range(0.5, 1.8, 0.1, "suffix:m") var window_width := 1.0
@export_range(0.0, 2.0, 0.05, "suffix:m") var window_sill := 0.9
@export_range(1.0, 2.6, 0.05, "suffix:m") var window_head := 2.1

@export_group("Stairs")
## Across a flight (the old flights were 1.1 m).
@export_range(0.5, 2.0, 0.5, "suffix:m") var stair_width := 1.0 # placeholder: the agent's number, the designer's to set
## Steps of a full flight, one storey: 16 rise 0.1875 m each.
@export_range(8, 24, 2) var stair_steps := 16 # placeholder: the agent's number, the designer's to set
## A step's depth: 16 x 0.25 m is a 4 m run, about 37 degrees (the old ramps were 31).
@export_range(0.2, 0.35, 0.05, "suffix:m") var stair_going := 0.25 # placeholder: the agent's number, the designer's to set
## The half-storey landing two half flights turn on (a U stair like the old house's).
@export var landing := Vector2(2.0, 1.0) # placeholder: the agent's number, the designer's to set


## The height of one step of a flight.
func step_rise() -> float:
	return storey / stair_steps
