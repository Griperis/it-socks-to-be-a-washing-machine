## Every line of one speaker, baked (core/84): `game/voice/baked/<speaker>.tres`, written by
## `tools/voice_bake.sh` alone from `game/voice/lines/<speaker>.json` and the recordings.
class_name VoiceBank
extends Resource

@export var speaker: VoiceSpeaker
@export var lines: Array[VoiceLine] = []
## The md5 of the speaker's JSON this bank was baked from: a JSON edited since is a VoiceBook load error
## (the bake was not run).
@export var lines_md5 := ""
