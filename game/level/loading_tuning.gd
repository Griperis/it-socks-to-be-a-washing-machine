## The loading screen's numbers (house/09, Q2542). One .tres beside it (loading_tuning.tres).
class_name LoadingTuning
extends Resource

## The laying's slice of a frame: each frame lays until this much time has gone, then lets the frame
## draw.
@export_range(1.0, 100.0, 0.5, "suffix:ms") var slice_ms := 14.0 # placeholder: the old loading.json frame_ms
## The screen stays this many frames after the Socks are laid, so the level has drawn behind it.
@export_range(0, 10) var hide_frames := 2 # placeholder: the old main.gd _hide_loading_after_frames
