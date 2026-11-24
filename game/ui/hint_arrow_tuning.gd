## The numbers of the off-screen hint arrows (core/43 lines 44-52; the old data/tuning/hint_arrows.json,
## progression/76). One .tres beside it (hint_arrow_tuning.tres), edited in the inspector. Every number
## is the old game's, not a decision.
class_name HintArrowTuning
extends Resource

## The arrow's length (line 46).
@export_range(4.0, 200.0, 1.0, "suffix:px") var size := 34.0 # placeholder: the old hint_arrows.json size
## How far its tip stays inside the screen's edge (line 45).
@export_range(0.0, 400.0, 1.0, "suffix:px") var margin := 56.0 # placeholder: the old hint_arrows.json margin
## Its outline's width, in the HUD's outline colour (line 46).
@export_range(0.0, 20.0, 0.5, "suffix:px") var outline := 3.0 # placeholder: the old hint_arrows.json outline
## The most arrows shown at once (line 50).
@export_range(0, 32, 1) var max_arrows := 4 # placeholder: the old hint_arrows.json max_arrows
## Room kept round each part of the HUD an arrow must not cover, and its step along the edge (line 51).
@export_range(0.0, 64.0, 1.0, "suffix:px") var clear_pad := 8.0 # placeholder: the old hint_arrows.gd CLEAR_PAD
@export_range(1.0, 64.0, 1.0, "suffix:px") var slide_step := 6.0 # placeholder: the old hint_arrows.gd SLIDE_STEP
## The arrowhead's shape: its side points this share of its length to each side, its notch this share in (line 46).
@export_range(0.05, 1.0, 0.01) var side := 0.4 # placeholder: the old hint_arrows.gd 0.4
@export_range(0.0, 0.9, 0.01) var notch := 0.3 # placeholder: the old hint_arrows.gd 0.3
## The outline's colour (the HUD's outline, the old UiBits.OUTLINE).
@export var outline_colour := Color(0.1, 0.07, 0.05, 1.0) # placeholder: the old UiBits.OUTLINE
