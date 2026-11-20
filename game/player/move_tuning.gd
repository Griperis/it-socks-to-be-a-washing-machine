## How the player walks, jumps, crouches and looks: one .tres beside it, edited in the inspector.
## Every number is today's value from the old game, not a decision (see move_tuning.tres).
class_name MoveTuning
extends Resource

@export_range(0.5, 12.0, 0.1, "suffix:m/s") var walk_speed := 4.0
## Share of the walking pace while crouched.
@export_range(0.1, 1.0, 0.05) var crouch_speed_factor := 0.5
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var jump_speed := 5.5
## The player's own gravity (the world keeps Godot's 9.8, as in the old game).
@export_range(1.0, 40.0, 0.5, "suffix:m/s²") var gravity := 20.0
## Radians turned per pixel the mouse moves.
@export_range(0.0005, 0.01, 0.0005) var look_sensitivity := 0.0025
## The Options screen's sensitivity multiplier (written in M4).
@export_range(0.1, 5.0, 0.05) var look_scale := 1.0
## The Options screen's Invert Y (written in M4).
@export var invert_y := false
## Right stick turn rate at full tilt, straight, no curve.
@export_range(10.0, 720.0, 5.0, "suffix:°/s") var pad_look_speed := 170.0
@export_range(10.0, 89.0, 1.0, "suffix:°") var pitch_limit := 85.0
@export_range(0.5, 3.0, 0.05, "suffix:m") var stand_height := 1.7
@export_range(0.5, 3.0, 0.05, "suffix:m") var crouch_height := 1.0
## The eyes' distance under the top of the body.
@export_range(0.0, 0.5, 0.05, "suffix:m") var eye_below_top := 0.1
@export_range(0.1, 1.0, 0.05, "suffix:m") var radius := 0.35
@export_range(30.0, 120.0, 1.0, "suffix:°") var fov := 75.0
