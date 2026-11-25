## One game moment that may speak (core/84): a file in `game/voice/triggers/`, so the folder is the trigger
## list. A line names triggers by id (the file's stem) in its JSON; the bake checks them. The code that owns
## the moment holds the file as a typed export, so a missing file is a load error, not silence.
class_name VoiceTrigger
extends Resource

enum Kind {
	## A line picked by the speaker's director, with its cooldown and chance.
	COMMENT,
	## Every line with this trigger, of every speaker, in `order`, played as a cutscene.
	CUTSCENE,
}

## The file's stem.
@export var id: StringName = &""
## Whose moment it is (a cutscene trigger's lines may be of several speakers).
@export var speaker: VoiceSpeaker
@export var kind := Kind.COMMENT
## The share of asks that speak (1, but the washer's stare 0.5).
@export_range(0.0, 1.0, 0.05) var chance := 1.0
@export var ignores_cooldown := false
## What fires it (the seam), for the designer.
@export_multiline var note := ""
