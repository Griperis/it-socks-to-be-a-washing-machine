## The voice system's numbers that are not one speaker's (core/85): the music duck of a cutscene, the
## cutscene's tail and priority, how long a line that waits may wait. `game/voice/voice_tuning.tres`.
class_name VoiceTuning
extends Resource

## The Music bus is held to this share of itself while the cutscene channel plays (V5).
@export_range(0.0, 1.0, 0.01) var duck_level := 0.25 # placeholder: the old audio.cutscene_duck_level
## How long the duck takes to go down, and to come back.
@export_range(0.01, 5.0, 0.01, "suffix:s") var duck_seconds := 0.5 # placeholder: the old audio.cutscene_duck_seconds
## A cutscene line counts as finished this long after its last word (a comment's is its speaker's `tail`).
@export_range(0.0, 5.0, 0.01, "suffix:s") var cutscene_tail := 0.9 # placeholder: the old voice.tail
## What a cutscene's line is worth against the speakers' priority (V4: cutscene 30, washer 20, Old Tree 10).
@export var cutscene_priority := 30 # placeholder: the old order, cutscene > washer > Old Tree (Q2548)
## A line that `waits` (a story beat) is dropped after waiting this long for a higher voice to end.
@export_range(0.0, 120.0, 0.5, "suffix:s") var wait_hold := 10.0 # placeholder: the old game dropped every blocked line; this hold is the lead's reading (batch-a-review.md)
