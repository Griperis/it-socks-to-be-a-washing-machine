## One cutscene as data (core/88, docs/architecture/run-ends.md "The Cutscene frame"): a `.tres` the sequence
## that starts it names (core/92's Fix, core/94's First wash, core/96's Final wash), played by every machine's
## `CutscenePlayer` from the Host's answer. The shots are the washer's markers, not the script's.
##
## The timeline: `lead` seconds of beats, then the voice line `lead_in` later (CutsceneTuning), then
## `after_voice_seconds` of the beats timed "after_voice", then the fade to black. Without a line (none
## recorded, a test) the lead and the line together hold the wide shot for `no_voice_seconds`.
class_name CutsceneScript
extends Resource

## The beat timed at the end of the line (or of the no-voice hold).
const AFTER_VOICE := "after_voice"
## A beat's time or argument written "$name" is the property `name` of `numbers` (core/94).
const NUMBER := "$"

## Each beat: `[time in seconds from the start, or "after_voice" plus an optional offset, beat name, args]`.
## A beat name is a method of the washer's Looks (`calm_wash`, `break`, `door_open`, `door_close`,
## `happy_wash`, `spray`; washer.md "W2"), called with `args` (an Array) on every machine.
@export var beats: Array[Array] = []
## The CUTSCENE trigger whose lines it plays (voice.md); empty for none.
@export var voice: VoiceTrigger
## Seconds of beats before the line (the First wash's calm wash).
@export_range(0.0, 30.0, 0.1, "suffix:s") var lead := 0.0
## The Resource whose numbers the beats name ("$wash_seconds": the First wash's FirstWashTuning), so they are
## edited in one place; none for a script whose numbers are its own.
@export var numbers: Resource
## When set, the lead is this number of `numbers` instead of `lead` (the First wash: its `wash_seconds`).
@export var lead_from: StringName = &""
## Seconds of the "after_voice" beats before the fade (the spray).
@export_range(0.0, 30.0, 0.1, "suffix:s") var after_voice_seconds := 0.0
## At the Host's end everyone respawns at the washer's Spawns (false for the Final wash).
@export var respawn := true
## The Host's end leaves the screen black and the player held (the Final wash: the Final screen follows,
## core/96 lets it go with `CutscenePlayer.release()`).
@export var hold_black := false
## Its length without a line, the lead included (the old 5, 5.5, 6.5, 7.5, 8.5, 10 s by level).
@export_range(0.5, 60.0, 0.5, "suffix:s") var no_voice_seconds := 5.0 # placeholder: the old TR seconds, until the designer plays it


## The seconds of beats before the line: `lead`, or `numbers`' `lead_from`.
func lead_seconds() -> float:
	if numbers != null and lead_from != &"" and lead_from in numbers:
		return float(numbers.get(lead_from))
	return lead


## A beat's time or argument as played: "$name" is `numbers`' property `name` (null when it has none),
## anything else is itself.
func value(v: Variant) -> Variant:
	if v is String and (v as String).begins_with(NUMBER):
		var key := (v as String).substr(NUMBER.length())
		return numbers.get(key) if numbers != null and key in numbers else null
	return v


## The script at `path`: a CutsceneScript file, or a CUTSCENE trigger's file played plainly (the washer
## station's pillars, which play every trigger found at load, Q2337). Null for anything else.
static func at_path(path: String, washer: Washer = null) -> CutsceneScript:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res := load(path)
	if res is CutsceneScript:
		return res as CutsceneScript
	if res is VoiceTrigger and (res as VoiceTrigger).kind == VoiceTrigger.Kind.CUTSCENE:
		return plain(res as VoiceTrigger, washer)
	return null


## The trigger's lines alone: no beats, the wide shot, its no-voice length the washer's for that cutscene
## (`WasherTuning.no_voice_seconds` at the trigger's place in `cutscene_looks`).
static func plain(trigger: VoiceTrigger, washer: Washer = null) -> CutsceneScript:
	var s := CutsceneScript.new()
	s.voice = trigger
	var tuning := washer.tuning if washer != null else null
	if tuning != null and not tuning.no_voice_seconds.is_empty():
		var level := 0
		for i in tuning.cutscene_looks.size():
			var look := tuning.cutscene_looks[i]
			if look != null and look.trigger == trigger.id:
				level = i
		s.no_voice_seconds = tuning.no_voice_seconds[clampi(level, 0, tuning.no_voice_seconds.size() - 1)]
	return s
