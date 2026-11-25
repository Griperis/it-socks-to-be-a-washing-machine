## One speaker (core/84, Q2609): `game/voice/speakers/<speaker>.tres`, edited in the inspector. Its recordings
## are `assets/voice/<id>/`, its lines `game/voice/lines/<id>.json`. The defaults are the washer's numbers
## (docs/architecture/washer.md "Numbers"), every one a placeholder as in the old tuning.
class_name VoiceSpeaker
extends Resource

## The folder name of its recordings and lines.
@export var id: StringName = &""
## The subtitle row's icon (V6); none shows the Theme's plain disc.
@export var icon: Texture2D
## Higher cuts lower (V4): cutscene 30, washer 20, Old Tree 10.
@export var priority := 20 # placeholder: the old priority (cutscene > washer > Old Tree, Q2548)
## Heard from its VoiceSource in 3D (a comment), else flat.
@export var positional := true
@export_range(0.1, 50.0, 0.1, "suffix:m") var unit_size := 6.0 # placeholder: the old voice.comment unit size
@export_range(1.0, 200.0, 1.0, "suffix:m") var max_distance := 30.0 # placeholder: the old voice.comment max distance
## The subtitle shows while the local camera is within this distance (V8) ...
@export_range(0.0, 100.0, 0.5, "suffix:m") var earshot := 12.0 # placeholder: the old voice.earshot
## ... and within this height of the speaker (the same floor).
@export_range(0.0, 20.0, 0.1, "suffix:m") var level_band := 2.0 # placeholder: the old voice.level_band
## Every take plays at this level; no level adjustment anywhere else (Q2638).
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var voice_db := 0.0 # placeholder: 0 dB, the old +6 dB not carried over (Q2638)
## Seconds between two of its lines given by a trigger.
@export_range(0.0, 600.0, 1.0, "suffix:s") var cooldown := 120.0 # placeholder: the old voice.cooldown
## The mood a new line's `moods` is seeded with (one of `acting.moods`).
@export var default_mood: StringName = &"calming" # placeholder: the old brows.py default mood
@export var acting: VoiceActing
## A line counts as finished this long after its last word.
@export_range(0.0, 5.0, 0.01, "suffix:s") var tail := 0.27 # placeholder: the old 0.3 of the 0.9 s tail for a comment
## A segment stays shown this long past its end.
@export_range(0.0, 2.0, 0.01, "suffix:s") var linger := 0.25 # placeholder: the old subtitle linger
