## The washing machine's Part (docs/architecture/washer.md "The entity", core/86): the speaker's Part and the
## Host's comment director. `talk {trigger}` (any machine; a Guest's stare asks the same) is decided here, on
## the Host: nothing before the First wash has broken it (Q2636), no comment while a cutscene plays, the
## speaker's cooldown, the trigger's chance, the run's comment set, then the picker (Q2637); the answer is
## `{line, take}` or a silent no. Every machine's `_show()` then plays it through `Voices` from the Looks.
##
## State on the Part is what everyone must see or hear the same: the last line said (`serial` moves with
## every answer, so the same line twice is two answers). Whether it is broken, how angry it is and which
## comment set it draws from are read from its run (`stages`), never kept here. It keeps nothing in a save (the
## old saved none); the director's memory (the picker, the clock of the last comment) is the Host's and starts
## fresh on a load.
##
## Its Looks, `WasherLooks`, is never written by anything else: `_show()` and the run's changes only set
## its mood (`damage`, `repair`) for core/87's broken look.
class_name Washer
extends Part

## Every washing machine is in this group (a Laundry bin's `tip()` leans toward it).
const GROUP := &"washer"
## Links the wiring check lets stay empty: a level may have no run (`stages`).
const WIRING_OPTIONAL := ["stages"]
## The prompt: the name for the crosshair; it has no use of its own.
const TITLE := "Washing machine"
const TALK := &"talk"

## Whose lines these are, its numbers, and its face.
@export var speaker: VoiceSpeaker
@export var tuning: WasherTuning
@export var looks: WasherLooks
## The run it reads (the house's `Run/Stages`): any Part with the Stages reads `wants_first_wash()`,
## `under_way()`, `comment_set()`, `parts_missing()`, `part_total()` and `last_pair_in()`. May be empty: then it is
## broken, calm, draws from any set and its senses are off.
@export var stages: Part
## The spray of Socks out of its door (the Fix scene's spit, core/92) and the door's middle it leaves from.
@export var sock_spray: SockSpray
@export var porthole: Marker3D

@export_group("State")
## What was said last: the line, its take, and a count that moves with every answer.
@export var line: StringName = &""
@export var take := 0
@export var serial := 0
@export_group("")

## The Host's memory of what it said (no save keeps it): the picker and when the last comment was given,
## in seconds of `Time`.
var picker := VoicePicker.new()
var last_at := -INF

var _shown := 0
var _look_key := ""
var _spit: Tween = null
var _following: CutscenePlayer = null
var _flickering := false


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


## The washing machine of the level `node` is in (two levels share the tree in a co-op test), or null.
static func of_level(node: Node) -> Washer:
	if not node.is_inside_tree():
		return null
	var runtime := LevelRuntime.of(node)
	for thing in node.get_tree().get_nodes_in_group(GROUP):
		for child in thing.get_children():
			if child is Washer and LevelRuntime.of(child) == runtime:
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


## A click with a carried Laundry bin loads the machine (core/93, "[LMB] Load the washing machine"): the Laundry
## day decides; with no bin carried it does nothing, as the old `hint_only`.
func use(by: int) -> void:
	var day := LaundryDay.of(self)
	if parts != null and day != null:
		parts.ask(Command.new(LaundryDay.LOAD, by, day.id))


## Only the left click uses it (the load); the use key does nothing.
func click_only() -> bool:
	return true


func accepts() -> Dictionary[StringName, Dictionary]:
	return {TALK: {"args": {"trigger": {"type": TYPE_STRING, "max": 64}}, "rate": 5}}


func decide(cmd: Command) -> Dictionary:
	if speaker == null or cmd.kind != TALK:
		return refuse("wrong")
	return _talk(StringName(str(cmd.args.get("trigger", ""))))


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


## Whether the First wash has broken it (Q2636): before, the machine looks fine and says nothing. The run says
## whether the First wash is still to come (its level's `LaundryDay.first_wash` PENDING); no run, or none to come:
## broken.
func is_broken() -> bool:
	return not bool(_read(&"wants_first_wash", false))


## Whether the machine cannot take a Part or a body now: a cutscene plays or someone spins in its drum.
func busy() -> bool:
	var frame := Cutscenes.of(self) if is_inside_tree() else null
	if frame != null and frame.is_playing():
		return true
	for wash in WasherWash.in_level(self):
		if wash.get_parent() == get_parent() and wash.busy():
			return true
	return false


## A cutscene beat (`spray`, core/92): the door swings open over `SockSprayTuning.door_open`, the Socks spray out of
## it, and it shuts again over the last `door_close` of the spray's length (old FirstWashSpit; looks only, on every
## machine). A skip ends it early (`_spit_end`).
func spray() -> void:
	if sock_spray == null or porthole == null or sock_spray.tuning == null:
		return
	var thing := get_parent() as Node3D
	var t := sock_spray.tuning
	sock_spray.play(porthole.global_position, porthole.global_basis.z, thing.global_position.y if thing != null else 0.0)
	Sounds.play_at(&"socks_pour", porthole.global_position)  # the old rogue_machine.gd:300
	if looks == null:
		return
	if _spit != null:
		_spit.kill()
	_spit = create_tween()
	_spit.tween_property(looks, "door", 1.0, t.door_open)
	_spit.tween_interval(maxf(t.length - t.door_open - t.door_close, 0.0))
	_spit.tween_property(looks, "door", 0.0, t.door_close)


## The cutscene ended (maybe by the skip): the spray is gone and the door shut.
func _spit_end() -> void:
	if _spit != null:
		_spit.kill()
		_spit = null
	if sock_spray != null:
		sock_spray.stop()
	if looks != null:
		looks.door = 0.0


## Whether a comment for `trigger` (any when null) may be given now: it is broken, no cutscene plays and
## the cooldown has passed. The senses ask it before they ask for an idle comment.
func could_speak(trigger: VoiceTrigger = null) -> bool:
	if not is_broken() or Voices.cutscene_playing() or ending():
		return false
	return trigger != null and trigger.ignores_cooldown or _now() - last_at >= speaker.cooldown


## The comment set the picker draws from: the run's current Stage's, or the Laundry day's after the last Fix;
## 0 (any) when nothing says.
func comment_set() -> int:
	return int(_read(&"comment_set", 0))


## How angry it is, 0 calm to `mood_total()` the angriest: the Parts the run still lacks once the First wash
## has broken it, none before and none once fixed.
func mood_level() -> int:
	return clampi(int(_read(&"parts_missing", 0)), 0, mood_total())


## The number of steps the angriest level has: the run's Parts.
func mood_total() -> int:
	return maxi(int(_read(&"part_total", 1)), 1)


## Whether the run's last Pair went in (the senses say nothing then, Q1413).
func last_pair_in() -> bool:
	return bool(_read(&"last_pair_in", false))


## The run's answer to the read `what` (a method of Stages, or of the Part standing in for it), or `none` with
## no run.
func _read(what: StringName, none: Variant) -> Variant:
	if stages == null or not is_inside_tree():
		return none
	return stages.call(what)


## Whether the Final wash has begun in this level (core/96): the senses are off and it comments no more.
func ending() -> bool:
	var day := LaundryDay.of(self) if is_inside_tree() else null
	return day != null and day.final_started


## Whether the senses are on: a staged run (core/71) is under way, and the Final wash has not begun.
func senses_on() -> bool:
	if ending():
		return false
	return bool(_read(&"under_way", false))


func _show(now: bool) -> void:
	_follow_cutscenes()
	_apply_mood()
	if now or serial == _shown:
		_shown = serial
		return
	_shown = serial
	if line != &"" and looks != null:
		Voices.say(Voices.book().find_line(speaker.id, line), take, looks)


func _follow_cutscenes() -> void:
	var frame := Cutscenes.of(self) if is_inside_tree() else null
	var player: CutscenePlayer = frame.player if frame != null else null
	if player != null and player != _following:
		_following = player
		player.ended.connect(_spit_end)


func _process(_delta: float) -> void:
	# The run moves without this Part's state changing: keep the mood in step with it.
	var key := "%d/%d/%s" % [mood_level(), mood_total(), is_broken()]
	if key != _look_key:
		_apply_mood()
	_flicker_room()


## Looks only: the mood into the Looks' damage and repair (core/87 shows them).
func _apply_mood() -> void:
	# A cutscene's look (the CutscenePlayer's `looks.set_cutscene`) holds damage and repair until it ends; the
	# key is left behind, so the run's mood is applied the frame after.
	var frame := Cutscenes.of(self) if is_inside_tree() else null
	if frame != null and frame.is_playing():
		return
	_look_key = "%d/%d/%s" % [mood_level(), mood_total(), is_broken()]
	if looks == null:
		return
	var level := mood_level()
	var angry := level > 0
	looks.damage = float(level) / float(mood_total()) if angry else 0.0
	looks.repair = 1.0 - looks.damage


## Looks only: from the First wash's break to the cutscene's end the level's lamps within
## `room_flicker_range` flicker with the drum light (the old rogue_machine.gd:284-289, room.gd:326).
func _flicker_room() -> void:
	var on := looks != null and looks.room_flickering()
	if not on and not _flickering:
		return
	_flickering = on
	var thing := get_parent() as Node3D
	var runtime := LevelRuntime.of(self)
	for node in get_tree().get_nodes_in_group(HouseLights.GROUP):
		var lights := node as HouseLights
		if lights == null or LevelRuntime.of(lights) != runtime or thing == null:
			continue
		if on:
			lights.set_flicker(thing.global_position, tuning.room_flicker_range if tuning != null else 4.0, looks.flicker())
		else:
			lights.set_flicker(Vector3.ZERO, 0.0, 1.0)


## The trigger file `id`, or null.
static func trigger_of(id: StringName) -> VoiceTrigger:
	var path := "res://game/voice/triggers/%s.tres" % id
	return load(path) as VoiceTrigger if not String(id).is_empty() and ResourceLoader.exists(path) else null


func _said(said: VoiceLine, take_index: int) -> Dictionary:
	return grant({"line": said.id, "take": take_index, "serial": serial + 1})


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
