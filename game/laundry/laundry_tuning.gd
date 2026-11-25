## The Laundry day's numbers (core/90; the old data/tuning laundry.* values). One .tres beside it
## (laundry_tuning.tres), edited in the inspector.
class_name LaundryTuning
extends Resource

## How many bins a World uses (the draw clamps it to 1..spots, core/93).
@export_range(1, 7, 1) var bins_per_world := 3 # placeholder: ported (laundry.bins_per_world), until the designer plays it
## How long a bin takes to tip into the washing machine, out and back.
@export_range(0.1, 10.0, 0.1, "suffix:s") var tip_seconds := 1.4 # placeholder: ported (laundry.tip_seconds)
## The washer's pile after the first bin is loaded, as a share of full (core/93 reads it).
@export_range(0.0, 1.0, 0.01) var pile_min := 0.4 # placeholder: ported (laundry.pile_min)
