## The Machine Parts' numbers (core/79; the old data/tuning parts.* values and part_view.gd's). One .tres
## beside it (machine_part_tuning.tres), edited in the inspector. The lying spin and bob are keys of
## each Looks' `lying` animation, not numbers here.
class_name MachinePartTuning
extends Resource

## How far in front of the Cabinet that took the last Pair a popped Part lands.
@export_range(0.0, 4.0, 0.05, "suffix:m") var ahead := 1.5 # placeholder: ported (parts.ahead)
## How long the pop from the Cabinet's top takes.
@export_range(0.05, 3.0, 0.05, "suffix:s") var pop_seconds := 0.7 # placeholder: ported (parts.pop_time)
## How high over the Cabinet's top the pop's arc peaks.
@export_range(0.0, 3.0, 0.05, "suffix:m") var arc := 0.6 # placeholder: ported (parts.pop_height)
## The glow disc's, the sparkle's and the burst's colour.
@export var glow_colour := Color(0.55, 0.85, 1.0) # placeholder: ported (part_view.gd GLOW)
## How many sparks the burst on landing has.
@export_range(1, 64, 1) var sparks := 18 # placeholder: ported (part_view.gd burst count)
