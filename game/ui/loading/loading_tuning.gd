## The loading screen's motion (the old loading_screen.gd and data/tuning/fade.json): one .tres beside it.
class_name LoadingTuning
extends Resource

## How long the game fades in from the backdrop's colour once loaded (Q1262).
@export_range(0.0, 3.0, 0.05, "suffix:s") var fade_seconds := 0.5 # placeholder: the old fade.seconds (Q1262)
## How fast the sock tumbles, in radians a second.
@export_range(0.0, 20.0, 0.1) var tumble_speed := 4.0 # placeholder: the old loading_screen.gd
## How far it bobs, in pixels.
@export_range(0.0, 40.0, 0.5, "suffix:px") var bob_px := 8.0 # placeholder: the old loading_screen.gd
