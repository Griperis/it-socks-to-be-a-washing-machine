## The Voice station's speaker (core/85): a zoo-only Part standing for the speaker's Part (the washer's, core/86)
## until it lands. It has the speaker's co-op shape: a Command goes to the Host, whose `decide()` answers which
## line and which take, and on every machine `_show()` plays that through `Voices` and the Looks' acting.
##   `talk {trigger}`: a comment as the game asks for it (cooldown, chance, the cutscene block, the picker);
##   `say_line {line}`: the station's one extra, any line by its id; `cutscene {trigger}`: a whole cutscene.
## Looks only (`_show`): a line is never state anyone keeps, so a snapshot or a late Guest plays nothing.
class_name VoiceStandIn
extends Part

## Whose lines these are, and where its voice and face are.
@export var speaker: VoiceSpeaker
@export var looks: VoiceSource
## The comment set a `talk` picks in (0: any).
@export var comment_set := 0

@export_group("State")
## What was last said: the line, its take; or the cutscene and each line's take. `serial` moves with every
## answer, so the same line said twice is two answers.
@export var line: StringName = &""
@export var take := 0
@export var cutscene: StringName = &""
@export var takes: PackedInt32Array = PackedInt32Array()
@export var serial := 0
@export_group("")

## The Host's memory of what it said, which no save keeps (a load starts quiet): the picker and when the
## last comment was given, in seconds of `Time`.
var picker := VoicePicker.new()
var last_at := -INF

var _shown := 0


func accepts() -> Dictionary[StringName, Dictionary]:
	var trigger := {"type": TYPE_STRING, "max": 64}
	return {
		&"say_line": {"args": {"line": trigger}, "rate": 5},
		&"talk": {"args": {"trigger": trigger}, "rate": 5},
		&"cutscene": {"args": {"trigger": trigger}, "rate": 2},
	}


func decide(cmd: Command) -> Dictionary:
	if speaker == null:
		return refuse("wrong")
	var book := Voices.book()
	match cmd.kind:
		&"say_line":
			var said := book.find_line(speaker.id, StringName(cmd.args.get("line", "")))
			if said == null:
				return refuse("wrong")
			return _said(said, picker.take_of(said))
		&"talk":
			var trigger := trigger_of(StringName(cmd.args.get("trigger", "")))
			if trigger == null or trigger.kind != VoiceTrigger.Kind.COMMENT:
				return refuse("wrong")
			# A silent no: a cutscene playing, the cooldown, the chance missed, no line (Q2545).
			var now := Time.get_ticks_msec() / 1000.0
			if Voices.cutscene_playing() or (not trigger.ignores_cooldown and now - last_at < speaker.cooldown):
				return refuse("quiet")
			if picker.rng.randf() >= trigger.chance:
				return refuse("quiet")
			var pick := picker.pick(book.lines_of(speaker.id), trigger.id, comment_set)
			if pick.is_empty():
				return refuse("quiet")
			last_at = now  # the Host's own memory: not state
			return _said(pick["line"], int(pick["take"]))
		&"cutscene":
			var trigger := trigger_of(StringName(cmd.args.get("trigger", "")))
			if trigger == null or trigger.kind != VoiceTrigger.Kind.CUTSCENE:
				return refuse("wrong")
			var picked := PackedInt32Array()
			for l in book.cutscene_lines(trigger.id):
				picked.append(picker.take_of(l))
			return grant({"line": &"", "take": 0, "cutscene": trigger.id, "takes": picked, "serial": serial + 1})
	return refuse("wrong")


func _show(now: bool) -> void:
	if now or serial == _shown:
		_shown = serial
		return
	_shown = serial
	if cutscene != &"":
		Voices.play_cutscene(trigger_of(cutscene), Array(takes), {speaker.id: looks})
	elif line != &"":
		Voices.say(Voices.book().find_line(speaker.id, line), take, looks)


## The trigger file `id`, or null.
static func trigger_of(id: StringName) -> VoiceTrigger:
	var path := "res://game/voice/triggers/%s.tres" % id
	return load(path) as VoiceTrigger if not String(id).is_empty() and ResourceLoader.exists(path) else null


func _said(said: VoiceLine, take_index: int) -> Dictionary:
	return grant({"line": said.id, "take": take_index, "cutscene": &"", "takes": PackedInt32Array(), "serial": serial + 1})
