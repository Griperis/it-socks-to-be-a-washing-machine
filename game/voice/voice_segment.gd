## One subtitle segment of a take (core/84): when it shows, in the take's own time, and its string key in
## `voice_lines.csv`. Written by the bake (`tools/voice_bake.sh`); every take of a line has the same keys in
## the same order.
class_name VoiceSegment
extends Resource

## Seconds from the take's start.
@export var start := 0.0
@export var end := 0.0
## `VO_<LINE>_<n>`, shown through `tr()`.
@export var key: StringName = &""
