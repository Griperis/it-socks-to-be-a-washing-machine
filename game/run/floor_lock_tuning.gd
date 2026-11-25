## The floor locks' opening (docs/architecture/stages.md "The floor locks"; the old locks.json): the padlock's
## pop, the leaf's swing, the floor's lamps. Edited in the inspector (floor_lock_tuning.tres beside it). The
## Looks' animations are keyed with the old numbers and run at the speed that fits these.
class_name FloorLockTuning
extends Resource

## The padlock's pop (up, out, spin and fall) takes this long; the chain drops at 0.75 of it.
@export_range(0.1, 3.0, 0.05, "suffix:s") var pop_time := 0.6 # placeholder: the designer's number (ported from the old game, locks.json pop_time)
## From the padlock's pop to the leaf starting to swing.
@export_range(0.0, 3.0, 0.05, "suffix:s") var swing_delay := 0.8 # placeholder: the designer's number (ported from the old game, locks.json swing_delay)
## The leaf's swing (sine, in and out).
@export_range(0.1, 5.0, 0.05, "suffix:s") var swing_time := 1.4 # placeholder: the designer's number (ported from the old game, locks.json swing_time)
## The opened floor's lamps fade in over this long.
@export_range(0.0, 3.0, 0.05, "suffix:s") var lights_fade := 0.6 # placeholder: the designer's number (ported from the old game, locks.json lights_fade)
## ... stay lit by day this long ...
@export_range(0.0, 30.0, 0.5, "suffix:s") var lights_hold := 6.0 # placeholder: the designer's number (ported from the old game, locks.json lights_hold)
## ... and fade back to the day's rule over this long (the old game: twice the fade in).
@export_range(0.0, 6.0, 0.05, "suffix:s") var lights_fade_out := 1.2 # placeholder: the designer's number (ported from the old game, room.gd reveal: 2 x lights_fade)
