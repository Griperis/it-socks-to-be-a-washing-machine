## Where the HUD's held readout sits beside the held item (core/15, the old held.json's info offsets).
## One .tres beside it (hud_tuning.tres), edited in the inspector. The rows' places and sizes are the
## Hud scene's own (anchors and theme variations, Q2363).
class_name HudTuning
extends Resource

## The readout's left edge, from the active item's place, in the camera's space before the depth.
@export var info_offset := Vector3(0.12, 0.0, 0.0) # placeholder: the old held.json (Q2363 kept the old places)
## The same while zoomed, from the zoom's place.
@export var zoom_info_offset := Vector3(0.06, 0.0, 0.0) # placeholder: the old held.json (Q2363 kept the old places)
## How far the readout keeps from the screen's right edge, in pixels.
@export var edge_margin := 8.0 # placeholder: the old hud.gd

@export_group("Message")
## A refusal's red line turns to and fro (core/16 P01, the old hud.gd WOBBLE_*): for this long,
@export_range(0.0, 2.0, 0.01, "suffix:s") var wobble_time := 0.45 # placeholder: the old hud.gd WOBBLE_TIME
## this far each way at first, dying down linearly to nothing,
@export_range(0.0, 0.5, 0.005, "suffix:rad") var wobble_turn := 0.07 # placeholder: the old hud.gd WOBBLE_TURN
## and this many swings a second.
@export_range(0.0, 20.0, 0.1, "suffix:/s") var wobble_rate := 5.0 # placeholder: the old hud.gd WOBBLE_RATE
## "Paired!" pops (core/16 P02, Q2370): it shows at this size, grows to `pop_peak` in `pop_rise`
@export_range(0.0, 2.0, 0.01) var pop_from := 0.6 # placeholder: new (Q2370 "a short pop"), by eye on the still
@export_range(0.5, 3.0, 0.01) var pop_peak := 1.25 # placeholder: new (Q2370 "a short pop"), by eye on the still
@export_range(0.0, 1.0, 0.01, "suffix:s") var pop_rise := 0.08 # placeholder: new (Q2370 "a short pop"), by eye on the still
## and settles to its own size in `pop_settle`.
@export_range(0.0, 1.0, 0.01, "suffix:s") var pop_settle := 0.14 # placeholder: new (Q2370 "a short pop"), by eye on the still
