## A pillar of the Voice station (core/85): the player's use (E) on it asks its speaker's stand-in to say one line,
## fire one comment trigger as the game does, or play one cutscene. The radio's pillar switches a hum on the Music
## bus, to hear the cutscene's duck. Its words are its prompt.
class_name VoicePillar
extends Part

enum Kind { LINE, COMMENT, CUTSCENE, RADIO }

## The radio asks no stand-in, and `_ask` has a fallback for none.
const WIRING_OPTIONAL := ["stand_in"]

@export var kind := Kind.LINE
## The stand-in asked (not the radio's).
@export var stand_in: VoiceStandIn
## The line's id, or the trigger's.
@export var target: StringName = &""
## What the prompt says.
@export var title := ""
## The radio's hum.
@export var hum: AudioStream

@export_group("State")
## The radio is on.
@export var on := false
@export_group("")

var _player: AudioStreamPlayer


func prompt_title() -> String:
	return "Radio: %s" % ("on" if on else "off") if kind == Kind.RADIO else title


func use(by: int) -> void:
	if parts == null:
		return
	match kind:
		Kind.RADIO:
			parts.ask(Command.new(&"radio", by, id, {"on": not on}))
		Kind.LINE:
			_ask(by, &"say_line", &"line")
		Kind.COMMENT:
			_ask(by, &"talk", &"trigger")
		Kind.CUTSCENE:
			_ask(by, &"cutscene", &"trigger")


func accepts() -> Dictionary[StringName, Dictionary]:
	return {&"radio": {"args": {"on": TYPE_BOOL}, "rate": 5}} if kind == Kind.RADIO else {}


func decide(cmd: Command) -> Dictionary:
	var to: Variant = cmd.args.get("on")
	if kind != Kind.RADIO or cmd.kind != &"radio" or not (to is bool) or to == on:
		return refuse("wrong")
	return grant({"on": to})


func _show(now: bool) -> void:
	if kind != Kind.RADIO:
		return
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.bus = &"Music"
		_player.stream = hum
		add_child(_player)
	if on and not _player.playing and _player.is_inside_tree():
		_player.play()
	elif not on:
		_player.stop()
	if not now and is_inside_tree():
		Sounds.play(&"pick")


func _ask(by: int, verb: StringName, arg: StringName) -> void:
	if stand_in != null:
		parts.ask(Command.new(verb, by, stand_in.id, {String(arg): String(target)}))
