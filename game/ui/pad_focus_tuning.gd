## The lit look of a control the pad or keyboard selects (core/75; the old data/tuning/pad.json focus_*, Q2647). One .tres
## beside it (pad_focus_tuning.tres), edited in the inspector. To add a button, add a Button in the editor: nothing else
## (no script, no call); a control that lights itself gets the meta `own_lit`. Every number is the old game's, not a decision.
class_name PadFocusTuning
extends Resource

## How far the selected control lifts.
@export_range(0.0, 30.0, 0.5, "suffix:px") var lift := 5.0 # placeholder: the old pad.json focus_lift
## Its scale about its centre.
@export_range(1.0, 1.5, 0.01) var grow := 1.08 # placeholder: the old pad.json focus_grow
## Seconds to light and to go out.
@export_range(0.0, 1.0, 0.01, "suffix:s") var time := 0.1 # placeholder: the old pad.json focus_time
## The glow behind it: colour, alpha, spread and the corner radius of its box.
@export var glow_colour := Color("f6c443") # placeholder: the old pad.json focus_glow, the gold
@export_range(0.0, 1.0, 0.01) var glow_alpha := 0.85 # placeholder: the old pad.json focus_glow_alpha
@export_range(0, 64, 1, "suffix:px") var glow_size := 16 # placeholder: the old pad.json focus_glow_size
@export_range(0, 40, 1, "suffix:px") var glow_radius := 14 # placeholder: the old pad_focus.gd corner radius
