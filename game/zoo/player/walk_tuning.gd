## How the graybox player walks and looks: one .tres beside it, edited in the inspector.
class_name WalkTuning
extends Resource

@export_range(0.5, 12.0, 0.1, "suffix:m/s") var walk_speed := 4.0
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var jump_speed := 4.5
## Radians turned per pixel the mouse moves.
@export_range(0.0005, 0.01, 0.0005) var look_sensitivity := 0.003
