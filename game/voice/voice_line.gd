## One spoken line inside a speaker's bank (core/84): the bake's copy of its entry in
## `game/voice/lines/<speaker>.json`, with the triggers resolved and every take baked. Edit the JSON, not this.
class_name VoiceLine
extends Resource

@export var id: StringName = &""
## Empty: it never plays in a game (the Voice station still plays it).
@export var triggers: Array[VoiceTrigger] = []
## The comment sets it may play in; empty = any.
@export var sets: PackedInt32Array = PackedInt32Array()
## One string key a segment, `VO_<ID>_<n>`.
@export var keys: PackedStringArray = PackedStringArray()
@export var takes: Array[VoiceTake] = []
## Its place within a cutscene trigger.
@export var order := 0
## A story beat that waits instead of being dropped (V4).
@export var waits := false
@export var placeholder := false
## What the bake found, for the Voice station to show: "text TODO", "keys differ", "timing guessed".
@export var marks: PackedStringArray = PackedStringArray()


## Whether the game moment `trigger_id` may give this line.
func has_trigger(trigger_id: StringName) -> bool:
	for t: VoiceTrigger in triggers:
		if t != null and t.id == trigger_id:
			return true
	return false
