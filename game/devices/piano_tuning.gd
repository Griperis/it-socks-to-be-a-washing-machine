## The piano's keys (assets/07, the old piano.json; the notes' ring and fade are the "piano"
## instrument's, in the sound catalogue). Edited in the inspector (piano_tuning.tres beside it).
class_name PianoTuning
extends Resource

## Seconds a played key takes to go down, and to come back up.
@export_range(0.0, 1.0, 0.01, "suffix:s") var dip_time := 0.04 # placeholder: the designer's number (ported from the old game, piano.json dip_time)
@export_range(0.0, 1.0, 0.01, "suffix:s") var rise_time := 0.16 # placeholder: the designer's number (ported from the old game, piano.json rise_time)
## How far from a key a player may stand to play it, in metres.
@export_range(0.5, 10.0, 0.1, "suffix:m") var reach := 4.0 # placeholder: the old Station reach, until the designer sets one
## How many keys one Guest may play a second (a fast run of notes stays under it).
@export_range(1, 60, 1) var rate := 20 # placeholder: not in the old game (it had no limit)
