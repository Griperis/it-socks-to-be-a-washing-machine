## The Upgrade menu's numbers (docs/architecture/economy.md "The Upgrade menu"): the old menu's sizes and
## timings, every one a placeholder in the old game too. One .tres beside it, edited in the inspector.
## Its looks (colours, frames, fonts) are the Theme's variations, not here.
class_name UpgradeMenuTuning
extends Resource

## A button's cell, in px (square).
@export_range(32.0, 256.0, 1.0, "suffix:px") var cell := 92.0 # placeholder: the old UM CELL
## The gap between two cells, in px.
@export_range(0, 64, 1, "suffix:px") var gap := 8 # placeholder: the old UM GAP
## How far a hovered or focused button lifts.
@export_range(0.0, 40.0, 0.5, "suffix:px") var lift := 5.0 # placeholder: the old UM LIFT
## How much it grows.
@export_range(1.0, 2.0, 0.01) var grow := 1.08 # placeholder: the old UM GROW
## How long the lift, growth and glow take.
@export_range(0.0, 1.0, 0.01, "suffix:s") var glow_time := 0.1 # placeholder: the old UM GLOW_TIME
## The shake's swings, in radians, one after another.
@export var shake_angles: PackedFloat32Array = PackedFloat32Array([0.07, -0.07, 0.05, -0.05, 0.025, 0.0]) # placeholder: the old UM SHAKE_ANGLES
## How long each swing takes.
@export_range(0.0, 0.5, 0.005, "suffix:s") var shake_step := 0.045 # placeholder: the old UM SHAKE_STEP
## The tip card's width.
@export_range(100.0, 800.0, 1.0, "suffix:px") var tip_width := 360.0 # placeholder: the old UM TIP_WIDTH
## The tip card's distance from its button, and from the screen's edge.
@export_range(0.0, 64.0, 1.0, "suffix:px") var tip_gap := 10.0 # placeholder: the old UM tooltip offset
@export_range(0.0, 64.0, 1.0, "suffix:px") var tip_margin := 8.0 # placeholder: the old UM tooltip margin
## How long a teammate's "<name> bought <Upgrade>" line stays.
@export_range(0.0, 10.0, 0.1, "suffix:s") var news_time := 2.0 # placeholder: the old HUD show_message's 2 s
