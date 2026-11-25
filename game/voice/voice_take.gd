## One recording of a line (core/84, Q2547): its stream, its timing and its acting Animation. Written by the
## bake alone. No gain field: every take plays at its speaker's `voice_db` (Q2638).
class_name VoiceTake
extends Resource

@export var stream: AudioStream
## The md5 of the wav the take was timed from; a wav that changed is timed again.
@export var source_md5 := ""
## Seconds.
@export var duration := 0.0
@export var segments: Array[VoiceSegment] = []
## The take's acting (mouth, brows, lean, wiggle, angry, glow): an external file under
## `game/voice/baked/<speaker>/`, played by the speaker's Looks AnimationPlayer with the audio (V2, Q2546).
@export var acting: Animation
