## The Stage bar's sizes and times (docs/architecture/stages.md "How it is authored"): the old hud.gd's
## STAGE_* and FOLD_* numbers. One .tres beside it (stage_bar_tuning.tres), edited in the inspector.
class_name StageBarTuning
extends Resource

@export_group("Layout")
## An icon's side, in pixels.
@export_range(8, 128, 1, "suffix:px") var icon_size := 44 # placeholder: the old hud.gd STAGE_ICON
## How far apart the stacked icons' left edges are.
@export_range(0, 128, 1, "suffix:px") var icon_overlap := 26 # placeholder: the old hud.gd STAGE_OVERLAP
## The track's size.
@export var track_size := Vector2(300.0, 16.0) # placeholder: the old hud.gd STAGE_BAR_SIZE
## The gap between the fill and the track's edge.
@export_range(0, 8, 1, "suffix:px") var fill_inset := 3 # placeholder: the old hud.gd _build_stage_bar
## The fill's colour.
@export var fill_colour := Color("#f29b4b") # placeholder: the old UiBits.ACCENT
## The bar's top gap.
@export_range(0, 64, 1, "suffix:px") var top_gap := 12 # placeholder: the old hud.gd _build_stage_bar

@export_group("Fill")
## The fill moving to a new share.
@export_range(0.0, 2.0, 0.01, "suffix:s") var fill_time := 0.35 # placeholder: the old hud.gd _stage_animate
## A new Stage drains the fill in this long (cubic),
@export_range(0.0, 2.0, 0.01, "suffix:s") var reset_time := 0.6 # placeholder: the old hud.gd STAGE_RESET_TIME
## then the new icons pop in one after another, each growing in
@export_range(0.0, 2.0, 0.01, "suffix:s") var icon_pop_time := 0.4 # placeholder: the old hud.gd _stage_set_icons
## and this long after the one before.
@export_range(0.0, 1.0, 0.01, "suffix:s") var icon_pop_gap := 0.12 # placeholder: the old hud.gd _stage_set_icons

@export_group("Phase change")
## The fold into the next phase: the fill runs full,
@export_range(0.0, 2.0, 0.01, "suffix:s") var fold_fill_time := 0.25 # placeholder: the old hud.gd FOLD_FILL_TIME
## the bar glows,
@export_range(0.0, 2.0, 0.01, "suffix:s") var fold_glow_time := 0.25 # placeholder: the old hud.gd FOLD_GLOW_TIME
## it shrinks into itself with a back ease,
@export_range(0.0, 2.0, 0.01, "suffix:s") var fold_shrink_time := 0.3 # placeholder: the old hud.gd FOLD_SHRINK_TIME
## and the new phase pops in.
@export_range(0.0, 2.0, 0.01, "suffix:s") var fold_pop_time := 0.2 # placeholder: the old hud.gd FOLD_POP_TIME
## The glow's tint (over 1 on purpose: it brightens).
@export var glow_colour := Color(1.7, 1.5, 0.9) # placeholder: the old hud.gd _show_counter
## How small the bar shrinks to.
@export_range(0.0, 1.0, 0.01) var shrink_to := 0.3 # placeholder: the old hud.gd _show_counter
