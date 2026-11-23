## The Sock generator's numbers for a whole level (core/52, Q2518-Q2528): how a Sock is fitted to its
## place, the Mates' distance, the Heaps, the thinning away from the washer, the under-furniture strips.
## One .tres beside it (sock_generator_tuning.tres), edited in the inspector. A number marked "ported" is
## the old game's (SockLayout's constants, data/tuning/mess.json "spill"), not a decision. The numbers of
## one area (its count, weights, hidden share, Heap) are on the area; its exclusion rules on its
## SockAreaRules.
@tool
class_name SockGeneratorTuning
extends Resource

@export_group("Fitting")
## The box every place is fitted for: the biggest Sock's (a Large crew, SockDress.BOX x 1.25), so a
## place never depends on the Design that takes it (the preview is exact before Designs are drawn).
@export var place_box := Vector3(0.375, 0.0325, 0.225) # placeholder: the biggest Size's box, until Sizes change
## How many points of its place a Sock tries before it goes to the open floor of its area.
@export_range(1, 64, 1) var tries := 8 # placeholder: ported (SockLayout.TRIES)
## How many other places of its own sort (hidden: inside and under; open: floor and tops) a Sock tries
## when its own has no room, before the open floor (Q2521 keeps the hidden share).
@export_range(0, 64, 1) var repicks := 6 # placeholder: ported (SockLayout.MOVES, which went to open floor at once)
## How many more tries on its area's open floor before it is left out (and named in the log).
@export_range(0, 256, 1) var floor_tries := 48 # placeholder: ported (SockLayout.MOVES x TRIES)
## A Sock's two ends may lie at most this much higher or lower than its middle: more and it would hang.
@export_range(0.0, 0.2, 0.005, "suffix:m") var end_step := 0.03 # placeholder: ported (SockLayout.END_STEP)
## Its middle may rest at most this far over or under the place's own surface (a rug; not a leg's foot).
@export_range(0.0, 0.2, 0.005, "suffix:m") var rest_slack := 0.03 # placeholder: ported (SockLayout.REST_SLACK)
## How high over what holds it a Sock is laid (none would touch it).
@export_range(0.0, 0.01, 0.0005, "suffix:m") var gap := 0.0005 # placeholder: ported (SockLayout.GAP)
## The open floor's grid: each cell's middle is tried once for open floor, a Sock lies at a random point of its cell.
@export_range(0.05, 1.0, 0.05, "suffix:m") var floor_grid := 0.2 # placeholder: ported (SockLayout.FLOOR_GRID)
## A stair trail's Sock lies on a surface at most this steep (the kit's stairs collide as a ramp).
@export_range(0.0, 60.0, 1.0, "suffix:deg") var trail_tilt := 40.0 # placeholder: until the house's stairs are walked

@export_group("Mates")
## A Pair's two Socks lie this far apart in a straight line, from the first Pair laid to the last (Q2525).
@export_range(0.0, 20.0, 0.1, "suffix:m") var mate_min := 0.4 # placeholder: ported (mess.mate_distance_min)
@export_range(0.0, 20.0, 0.1, "suffix:m") var mate_max := 6.0 # placeholder: ported (mess.mate_distance_max)
## How many free places a Sock's mate tries; one within `mate_slack` of its distance is taken at once.
@export_range(1, 1024, 1) var mate_tries := 96 # placeholder: ported (SockLayout._assign's 96)
@export_range(0.0, 2.0, 0.05, "suffix:m") var mate_slack := 0.25 # placeholder: ported (SockLayout.MATE_SLACK)

@export_group("Heaps")
## An area flagged "heap" (Q2526) gathers its open floor Socks into this many Heaps per 100 of them (at least one).
@export_range(0.0, 50.0, 0.1) var heaps_per_100 := 3.6 # placeholder: ported (28 Heaps for about 780 floor Socks)
## The share of its floor Socks that go to a Heap, and how far round a Heap's middle they fall (a normal spread).
@export_range(0.0, 1.0, 0.01) var heap_share := 0.55 # placeholder: ported (mess.spill.heap_share)
@export_range(0.0, 2.0, 0.01, "suffix:m") var heap_spread := 0.22 # placeholder: ported (mess.spill.heap_spread)
## A Heap Sock rolls down while the Heap is steeper than this (a tangent), in steps of `roll`, at most `roll_steps`.
@export_range(0.0, 2.0, 0.05) var repose := 0.4 # placeholder: ported (SockLayout.REPOSE)
@export_range(0.01, 1.0, 0.01, "suffix:m") var roll := 0.12 # placeholder: ported (SockLayout.ROLL)
@export_range(0, 64, 1) var roll_steps := 12 # placeholder: ported (SockLayout.ROLL_STEPS)
## A Heap grows at most this high over its floor; then its next Socks go elsewhere.
@export_range(0.05, 2.0, 0.05, "suffix:m") var heap_max := 0.4 # placeholder: ported (SockLayout.HEAP_MAX)

@export_group("Thinning")
## Open floor and tops thin out with the distance from the washer marker: exp(-distance / falloff),
## never under `fade_floor` (Q2528; a straight line until the house is walked).
@export_range(0.1, 100.0, 0.1, "suffix:m") var fade_falloff := 5.0 # placeholder: ported (mess.spill.gradient_falloff)
@export_range(0.0, 1.0, 0.01) var fade_floor := 0.2 # placeholder: ported (mess.spill.gradient_floor)

@export_group("Under furniture")
## A Sock under furniture lies in a strip along an edge that faces open floor (Q2528): this deep under
## furniture lower than `low_furniture`, else `strip_high`.
@export_range(0.02, 1.0, 0.01, "suffix:m") var strip_low := 0.15 # placeholder: ported (mess.spill.edge_band_low)
@export_range(0.02, 1.0, 0.01, "suffix:m") var strip_high := 0.35 # placeholder: ported (mess.spill.edge_band_high)
@export_range(0.05, 2.0, 0.01, "suffix:m") var low_furniture := 0.4 # placeholder: ported (mess.spill.low_furniture)
## An edge faces open floor when at least 2 of 3 points this far out from it are open floor.
@export_range(0.05, 2.0, 0.01, "suffix:m") var strip_probe := 0.35 # placeholder: ported (SockLayout._edge_bands)
