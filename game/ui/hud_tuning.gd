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
