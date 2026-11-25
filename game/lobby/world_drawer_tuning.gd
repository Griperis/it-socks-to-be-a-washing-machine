## The World drawer's numbers (docs/architecture/lobby.md "Core/65"): one .tres beside it.
class_name WorldDrawerTuning
extends Resource

## How long the drawer slides open or shut, in seconds (the old 0.25 s, cubic ease-out).
@export_range(0.05, 2.0, 0.05, "suffix:s") var slide_seconds := 0.25 # placeholder: the old number, until the designer tunes it
## The drawer's width in pixels.
@export_range(200.0, 900.0, 10.0, "suffix:px") var width := 520.0 # placeholder: the old number, until the designer tunes it
