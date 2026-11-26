## Stage presents' numbers (core/137, docs/architecture/gifts.md "The box's Looks"; the old data/tuning
## gifts.json and wrapping.json). One .tres beside it (present_tuning.tres), edited in the inspector. The drop,
## the turn and the bob are keys of the Looks' clips, not numbers here.
class_name PresentTuning
extends Resource

## How much a RARE piece weighs in a present's draw against 1 for any other.
@export_range(0.0, 4.0, 0.05) var rare_weight := 0.25 # placeholder: the old gifts.rare_weight
## The Coins an opened present pays when its piece is already owned (core/138 pays it).
@export_range(0, 1000, 1) var refund := 75 # placeholder: the old gifts.refund
## How far apart the boxes of the heap lie (its hex grid's step).
@export_range(0.1, 2.0, 0.01, "suffix:m") var apart := 0.42 # placeholder: the old gifts.apart
## How long an opened box shakes before it pops (core/138).
@export_range(0.1, 5.0, 0.05, "suffix:s") var shake := 1.0 # placeholder: the old gifts.shake
## How long the opener's reveal stays after the pop (core/138).
@export_range(0.5, 10.0, 0.1, "suffix:s") var preview := 3.0 # placeholder: the old gifts.preview
## How many times the Collection's icon repeats across a face of the paper.
@export_range(0.5, 8.0, 0.1) var tiles := 2.0 # placeholder: the old wrapping.tiles
## How strongly the icon's ink shows on the paper.
@export_range(0.0, 1.0, 0.01) var ink_strength := 0.85 # placeholder: the old wrapping.ink_strength
