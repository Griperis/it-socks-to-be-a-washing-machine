## How the washer looks in one cutscene (docs/architecture/washer.md "How it looks, by state"): while the
## cutscene plays these set its repair and its damage instead of the run's mood (one place, where the old
## had two). The cutscene frame (core/88) reads them; core/87 shows the damage.
class_name WasherCutsceneLook
extends Resource

## The cutscene trigger it is for (the file's stem in `game/voice/triggers/`).
@export var trigger: StringName = &""
## The drum light's repair, 0 dim and flickering to 1 healthy.
@export_range(0.0, 1.0, 0.05) var repair := 0.0 # placeholder: the old RI:116-125 level, waiting for the designer's balance
## The share of the sparks and smoke the mood would give (1 full, 0 none).
@export_range(0.0, 1.0, 0.05) var damage := 1.0 # placeholder: the old TB cutscene_scale (Q1427)
