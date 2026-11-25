## Every number of the Final screen's timing (core/95; the old data/tuning/final_screen.json, progression/85,
## Q1835, Q1842-Q1844). One .tres beside it (final_screen_tuning.tres), edited in the inspector. The pieces
## and unlock reveal of batch B add their own numbers here.
class_name FinalScreenTuning
extends Resource

@export_group("The Pairs")
## Seconds before the first Sock preview pops.
@export_range(0.0, 5.0, 0.05, "suffix:s") var start_delay := 0.8 # placeholder: the old start_delay
## The gap before the next Pair pops starts at this and shrinks to `fast_gap` over `ramp_pairs` Pairs (slow, then a fast stream).
@export_range(0.0, 3.0, 0.01, "suffix:s") var first_gap := 0.7 # placeholder: the old first_gap
@export_range(0.0, 1.0, 0.01, "suffix:s") var fast_gap := 0.03 # placeholder: the old fast_gap
@export_range(1, 60, 1) var ramp_pairs := 14 # placeholder: the old ramp_pairs
## A rare Pair holds this long more before the next, and sparkles.
@export_range(0.0, 3.0, 0.05, "suffix:s") var rare_pause := 0.9 # placeholder: the old rare_pause
## How long a preview takes to fly into its place and pop.
@export_range(0.05, 2.0, 0.01, "suffix:s") var pop_time := 0.35 # placeholder: the old pop_time
## How far above its place a preview starts, as a share of the column's stage height.
@export_range(0.0, 1.0, 0.01) var fly_from := 0.25 # placeholder: the old fly_from
## How fast a score catches up with the Coins just added, as a share of the gap per second.
@export_range(0.5, 60.0, 0.5) var count_speed := 9.0 # placeholder: the old count_speed
@export_group("The totals")
## Seconds after the last column finishes before the totals show.
@export_range(0.0, 5.0, 0.05, "suffix:s") var totals_delay := 1.0 # placeholder: the old totals_delay
## How long every total counts up.
@export_range(0.1, 10.0, 0.1, "suffix:s") var count_time := 1.6 # placeholder: the old count_time
## How long the finale's three waves of bursts last.
@export_range(0.1, 10.0, 0.1, "suffix:s") var finale_time := 2.5 # placeholder: the old finale_time
## How many bits one burst of the finale throws.
@export_range(1, 300, 1) var confetti := 40 # placeholder: the old confetti
