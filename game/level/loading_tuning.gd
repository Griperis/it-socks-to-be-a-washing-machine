## The loading screen's numbers (house/09, Q2542; its look core/58, Q2575). One .tres beside it
## (loading_tuning.tres).
class_name LoadingTuning
extends Resource

## The laying's slice of a frame: each frame lays until this much time has gone, then lets the frame
## draw.
@export_range(1.0, 100.0, 0.5, "suffix:ms") var slice_ms := 14.0 # placeholder: the old loading.json frame_ms
## The screen stays this many frames after the Socks are laid, so the level has drawn behind it.
@export_range(0, 10) var hide_frames := 2 # placeholder: the old main.gd _hide_loading_after_frames
## Then the game fades in from the backdrop's colour over this long, over everything, input not held (Q1262).
@export_range(0.0, 3.0, 0.05, "suffix:s") var fade_seconds := 0.5 # placeholder: the old fade.seconds (Q1262)
## How fast the sock tumbles, in radians a second.
@export_range(0.0, 20.0, 0.1) var tumble_speed := 4.0 # placeholder: the old loading_screen.gd
## How far it bobs, in pixels.
@export_range(0.0, 40.0, 0.5, "suffix:px") var bob_px := 8.0 # placeholder: the old loading_screen.gd
## The share of the bar the scene's own load fills before the laying takes it on (SceneChanger).
@export_range(0.0, 0.5, 0.01) var load_share := 0.1 # placeholder: the old bar's 0.1 once the places are found
