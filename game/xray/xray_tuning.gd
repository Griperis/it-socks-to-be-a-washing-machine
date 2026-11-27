## The X-rays' own numbers (docs/architecture/x-rays.md "How it is authored"; the old
## data/tuning/xray.json): how much larger a mate's glowing copy is drawn, and how long the screen tint
## fades out over the end of a show. One .tres beside it (xray_tuning.tres), edited in the inspector.
class_name XRayTuning
extends Resource

## A Mess mate's glowing copy, this many times its size (core/183).
@export_range(1.0, 2.0, 0.01) var glow_scale := 1.08 # placeholder: the old xray_view.gd GLOW_SCALE
## The screen tint fades from full to none over the show's last this many seconds (core/185).
@export_range(0.0, 10.0, 0.1, "suffix:s") var screen_fade := 3.0 # placeholder: the old xray.json screen_fade
