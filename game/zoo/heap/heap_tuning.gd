## The heap station's numbers (core/20, Q2334-Q2336): the batch a click pours and how the spout
## lets it in. One .tres beside it (heap_tuning.tres), edited in the inspector.
class_name HeapTuning
extends Resource

## How many Socks one click on "More" (or "Respill") pours: both Socks of each Design, so an even number.
@export_range(2, 10000, 2) var batch := 500 # placeholder: the designer's "about 500" (Q2334), until play
## How many Socks enter in one physics tick at most (a wave), while the moving budget has room.
@export_range(1, 256, 1) var per_tick := 40 # placeholder: ported (SockPour per_tick), until play
## How many places a wave tries for each Sock that enters before it waits for the next tick.
@export_range(1, 8, 1) var tries := 2 # placeholder: ported (SockPour.POUR_TRIES)
## Where a Sock's middle may start, in the spout's own space: the pour's column under it.
@export var area := AABB(Vector3(-0.6, -0.8, -0.6), Vector3(1.2, 0.8, 1.2)) # placeholder: until play
## The sideways push a poured Sock starts with, at most this fast either way.
@export_range(0.0, 3.0, 0.05, "suffix:m/s") var push := 0.3 # placeholder: ported (SockPour's release)
## With Socks left to pour and room in the budget but no free place for this long, the rest are dropped.
@export_range(0.5, 30.0, 0.5, "suffix:s") var give_up := 6.0 # placeholder: ported (SockPour.POUR_MAX)
## How far from the station's middle a player may stand to press its buttons (Parts.near()).
@export_range(0.5, 20.0, 0.5, "suffix:m") var reach := 8.0 # placeholder: until play
