## The washing machine's Part (docs/architecture/washer.md "The entity", core/86): the speaker's Part and the
## Host's comment director. `talk {trigger}` (any machine; a Guest's stare asks the same) is decided here, on
## the Host: nothing before the First wash has broken it (Q2636), no comment while a cutscene plays, the
## speaker's cooldown, the trigger's chance, the run's comment set, then the picker (Q2637); the answer is
## `{line, take}` or a silent no. Every machine's `_show()` then plays it through `Voices` from the Looks.
##
## State on the Part is what everyone must see or hear the same: the last line said (`serial` moves with
## every answer, so the same line twice is two answers), whether it is broken (a stand-in for core/72's
## `LaundryDay.first_wash`: core/94 gives it the First wash's state), and the zoo's two overrides. It keeps
## nothing in a save (the old saved none); the director's memory (the picker, the clock of the last comment)
## is the Host's and starts fresh on a load.
##
## Its Looks, `WasherLooks`, is never written by anything else: `_show()` and the run's changes only set
## its mood (`damage`, `repair`) for core/87's broken look.
class_name Washer
extends Part

## Every washing machine is in this group (a Laundry bin's `tip()` leans toward it).
const GROUP := &"washer"
## Links the wiring check lets stay empty: the washer station has no run (`stages`), the zoo sets the Stage.
const WIRING_OPTIONAL := ["stages"]
## The prompt: the name for the crosshair; it has no use of its own.
const TITLE := "Washing machine"
const TALK := &"talk"
const SAY_LINE := &"say_line"
const ZOO_MOOD := &"zoo_mood"
const ZOO_STAGE := &"zoo_stage"
const ZOO_BROKEN := &"zoo_broken"

## Whose lines these are, its numbers, and its face.
@export var speaker: VoiceSpeaker
@export var tuning: WasherTuning
@export var looks: WasherLooks
## The run it reads the Stage and the Parts fitted from (the house's `Run/Stages`); none in the zoo's
## washer station, which sets them by pillar.
@export var stages: Stages
## The plan the zoo's Stage pillars read the comment sets from (the station's; the run's own is `stages.plan`).
@export var zoo_plan: StagePlan
## In the zoo's washer station: the zoo-only Commands are granted and the senses are on.
@export var zoo := false

@export_group("State")
## What was said last: the line, its take, and a count that moves with every answer.
@export var line: StringName = &""
@export var take := 0
@export var serial := 0
## The First wash has broken it (a stand-in until core/94: `LaundryDay.first_wash` past PENDING). Before it
## the machine looks fine and says nothing.
@export var broken := false
## The zoo's mood level 0..`tuning.zoo_levels`, or -1 to read the run.
@export var zoo_mood := -1
## The zoo's Stage 0.., or one past the last for the Laundry day, or -1 to read the run.
@export var zoo_stage := -1
@export_group("")

## The Host's memory of what it said (no save keeps it): the picker and when the last comment was given,
## in seconds of `Time`.
var picker := VoicePicker.new()
var last_at := -INF

var _shown := 0
var _look_key := ""


func _enter_tree() -> void:
	var thing := get_parent()
	if thing != null:
		thing.add_to_group(GROUP)


## True for the washing machine's root node or any node of it (a Part's thing, its Looks): what the
## Fit and Load prompts of core/71 and core/72 ask.
static func is_washer(node: Node) -> bool:
	while node != null:
		if node.is_in_group(GROUP) or node is Washer:
			return true
		node = node.get_parent()
	return false


## The washing machine standing in `tree`, or null.
static func of(tree: SceneTree) -> Washer:
	for node in tree.get_nodes_in_group(GROUP):
		for child in node.get_children():
			if child is Washer:
				return child as Washer
	return null


## Nothing is kept in a save (the old saved none): a load starts the machine quiet and, until core/94, fine.
func save_state() -> Dictionary:
	return {}


func prompt_title() -> String:
	return TITLE


## Named for the crosshair and outlined, with no key: E does nothing at it (the old `hint_only`).
func hint_only() -> bool:
	return true


func accepts() -> Dictionary[StringName, Dictionary]:
	var trigger := {"type": TYPE_STRING, "max": 64}
	var out: Dictionary[StringName, Dictionary] = {TALK: {"args": {"trigger": trigger}, "rate": 5}}
	if zoo:
		out[SAY_LINE] = {"args": {"line": trigger}, "rate": 5}
		out[ZOO_MOOD] = {"args": {"level": {"type": TYPE_INT, "min": -1, "max": 64}}, "rate": 5}
		out[ZOO_STAGE] = {"args": {"stage": {"type": TYPE_INT, "min": -1, "max": 64}}, "rate": 5}
		out[ZOO_BROKEN] = {"args": {"on": TYPE_BOOL}, "rate": 5}
	return out


func decide(cmd: Command) -> Dictionary:
	if speaker == null:
		return refuse("wrong")
	match cmd.kind:
		TALK:
			return _talk(StringName(str(cmd.args.get("trigger", ""))))
		SAY_LINE:
			if not zoo:
				return refuse("wrong")
			var said := Voices.book().find_line(speaker.id, StringName(str(cmd.args.get("line", ""))))
			return refuse("wrong") if said == null else _said(said, picker.take_of(said))
		ZOO_MOOD:
			var level: Variant = cmd.args.get("level")
			if not zoo or not (level is int) or level > _zoo_levels():
				return refuse("wrong")
			return grant({"zoo_mood": level})
		ZOO_STAGE:
			var stage: Variant = cmd.args.get("stage")
			if not zoo or not (stage is int):
				return refuse("wrong")
			return grant({"zoo_stage": stage})
		ZOO_BROKEN:
			var on: Variant = cmd.args.get("on")
			if not zoo or not (on is bool) or on == broken:
				return refuse("wrong")
			return grant({"broken": on})
	return refuse("wrong")


## The comment director (the Host's): a grant with the line and take, or a silent no.
func _talk(trigger_id: StringName) -> Dictionary:
	var trigger := trigger_of(trigger_id)
	if trigger == null or trigger.kind != VoiceTrigger.Kind.COMMENT:
		return refuse("wrong")
	if not could_speak(trigger):
		return refuse("quiet")
	if picker.rng.randf() >= trigger.chance:
		return refuse("quiet")
	var pick := picker.pick(Voices.book().lines_of(speaker.id), trigger.id, comment_set())
	if pick.is_empty():
		return refuse("quiet")
	last_at = _now()  # the Host's own memory: not state
	return _said(pick["line"], int(pick["take"]))


## Whether a comment for `trigger` (any when null) may be given now: it is broken, no cutscene plays and
## the cooldown has passed. The senses ask it before they ask for an idle comment.
func could_speak(trigger: VoiceTrigger = null) -> bool:
	if not broken or Voices.cutscene_playing():
		return false
	return trigger != null and trigger.ignores_cooldown or _now() - last_at >= speaker.cooldown


## The comment set the picker draws from: the zoo's Stage, else the run's current Stage's, or the Laundry
## day's after the last Fix; 0 (any) when nothing says.
func comment_set() -> int:
	var plan := _plan()
	var at := zoo_stage
	if at < 0 and stages != null and plan != null and stages.stage >= 0:
		at = plan.size() if stages.phase == Stages.Phase.FIXED else stages.stage
	if at < 0 or plan == null:
		return 0
	if at >= plan.size():
		return plan.laundry_day_comment_set
	var s := plan.stage(at)
	return s.comment_set if s != null else 0


## The plan the comment sets come from: the run's, or the zoo's.
func _plan() -> StagePlan:
	return stages.plan if stages != null and stages.plan != null else zoo_plan


## How angry it is, 0 calm to `mood_total()` the angriest: the zoo's pillar, else one per Part not yet
## fitted once the First wash has broken it, none before and none once fixed.
func mood_level() -> int:
	if zoo_mood >= 0:
		return zoo_mood
	if not broken or stages == null or stages.plan == null:
		return 0
	return clampi(stages.plan.size() - stages.fitted_count(), 0, stages.plan.size())


## The number of steps the angriest level has.
func mood_total() -> int:
	if zoo_mood >= 0 or stages == null or stages.plan == null:
		return _zoo_levels()
	return maxi(stages.plan.size(), 1)


## Whether the senses are on: the zoo's washer station always, else a staged run (core/71) is under way.
func senses_on() -> bool:
	return zoo or (stages != null and stages.stage >= 0)


func _show(now: bool) -> void:
	_apply_mood()
	if now or serial == _shown:
		_shown = serial
		return
	_shown = serial
	if line != &"" and looks != null:
		Voices.say(Voices.book().find_line(speaker.id, line), take, looks)


func _process(_delta: float) -> void:
	# The run moves without this Part's state changing: keep the mood in step with it.
	var key := "%d/%d/%s" % [mood_level(), mood_total(), broken]
	if key != _look_key:
		_apply_mood()


## Looks only: the mood into the Looks' damage and repair (core/87 shows them).
func _apply_mood() -> void:
	_look_key = "%d/%d/%s" % [mood_level(), mood_total(), broken]
	if looks == null:
		return
	var level := mood_level()
	var angry := (broken or zoo_mood >= 0) and level > 0
	looks.damage = float(level) / float(mood_total()) if angry else 0.0
	looks.repair = 1.0 - looks.damage


## The trigger file `id`, or null.
static func trigger_of(id: StringName) -> VoiceTrigger:
	var path := "res://game/voice/triggers/%s.tres" % id
	return load(path) as VoiceTrigger if not String(id).is_empty() and ResourceLoader.exists(path) else null


func _said(said: VoiceLine, take_index: int) -> Dictionary:
	return grant({"line": said.id, "take": take_index, "serial": serial + 1})


func _zoo_levels() -> int:
	return tuning.zoo_levels if tuning != null else 5


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
