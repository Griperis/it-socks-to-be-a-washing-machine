## One pad rumble, edited in the inspector: how hard each motor turns (0 to 1) and for how long.
## PadRumble plays it on every connected pad.
class_name RumbleCue
extends Resource

## The weak (high) motor and the strong (low) motor.
@export_range(0.0, 1.0, 0.05) var weak := 0.0
@export_range(0.0, 1.0, 0.05) var strong := 0.0
@export_range(0.0, 2.0, 0.05, "suffix:s") var seconds := 0.0
