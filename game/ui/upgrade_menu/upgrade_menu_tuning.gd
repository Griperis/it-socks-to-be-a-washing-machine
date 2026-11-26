## The Upgrade menu's numbers (docs/architecture/economy.md "The Upgrade menu"): the old menu's sizes and
## timings, every one a placeholder in the old game too. One .tres beside it, edited in the inspector.
## Its looks (colours, frames, fonts) are the Theme's variations, and a button's lift, glow and shake are
## the clips of `upgrade_button.tscn` (Q2697), not here.
class_name UpgradeMenuTuning
extends Resource

## A button's cell, in px (square).
@export_range(32.0, 256.0, 1.0, "suffix:px") var cell := 92.0 # placeholder: the old UM CELL
## The gap between two cells, in px.
@export_range(0, 64, 1, "suffix:px") var gap := 8 # placeholder: the old UM GAP
## The tip card's width.
@export_range(100.0, 800.0, 1.0, "suffix:px") var tip_width := 360.0 # placeholder: the old UM TIP_WIDTH
## The tip card's distance from its button, and from the screen's edge.
@export_range(0.0, 64.0, 1.0, "suffix:px") var tip_gap := 10.0 # placeholder: the old UM tooltip offset
@export_range(0.0, 64.0, 1.0, "suffix:px") var tip_margin := 8.0 # placeholder: the old UM tooltip margin
## How long a teammate's "<name> bought <Upgrade>" line stays.
@export_range(0.0, 10.0, 0.1, "suffix:s") var news_time := 2.0 # placeholder: the old HUD show_message's 2 s
