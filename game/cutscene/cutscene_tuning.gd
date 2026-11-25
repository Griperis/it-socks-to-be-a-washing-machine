## The Cutscene frame's numbers (core/88, docs/architecture/run-ends.md "The Cutscene frame"): the shared fade
## and the voice line's lead-in. The line's tail is the voice system's (`VoiceTuning.cutscene_tail`). One .tres
## beside it (cutscene_tuning.tres), edited in the inspector.
class_name CutsceneTuning
extends Resource

## A cutscene opens out of black over this, ends fading to black over it, and the view comes back over it.
@export_range(0.0, 3.0, 0.05, "suffix:s") var fade_seconds := 0.5 # placeholder: the old fade.seconds (Q1262), until the designer plays it
## The line starts this long after the shot opens (after the script's `lead`, the wash where there is one).
@export_range(0.0, 5.0, 0.05, "suffix:s") var lead_in := 0.6 # placeholder: the old voice.lead_in, until the designer plays it
