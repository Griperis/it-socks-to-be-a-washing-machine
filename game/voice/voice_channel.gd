## One line playing (core/85): the channel of a speaker, or the cutscene's. It holds the sound (flat on the
## Voice bus, or in 3D at the speaker's `VoiceSource`, on MuffledVoice behind a shut Door), the line's
## clock and which segment it is at. `Voices` makes the channels and decides who may talk; a channel
## decides nothing. Looks only.
class_name VoiceChannel
extends Node

const VOICE_BUS := &"Voice"
const MUFFLED_BUS := &"MuffledVoice"

## A speaker's id, or `Voices.CUTSCENE`.
var id: StringName = &""
var priority := 0
var active := false
var line: VoiceLine = null
var take := 0
## Whose line it is, and whose face acts it (null: no face, a cutscene line of a speaker with none here).
var speaker: VoiceSpeaker = null
var source: VoiceSource = null
var cutscene := false
## Seconds into the take.
var elapsed := 0.0
## Seconds past the last word before the line is finished.
var tail := 0.0
## The bus the sound is on now.
var bus: StringName = VOICE_BUS
## The segment last begun (-1: none yet), and the key shown on the row now ("" for none).
var segment := -1
var shown_key: StringName = &""

var _flat: AudioStreamPlayer
var _world: AudioStreamPlayer3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Starts `line`'s take `take_index`.
func begin(p_line: VoiceLine, take_index: int, p_speaker: VoiceSpeaker, p_source: VoiceSource, as_cutscene: bool,
		p_priority: int, p_tail: float) -> void:
	line = p_line
	take = clampi(take_index, 0, maxi(p_line.takes.size() - 1, 0))
	speaker = p_speaker
	source = p_source
	cutscene = as_cutscene
	priority = p_priority
	tail = p_tail
	elapsed = 0.0
	segment = -1
	shown_key = &""
	active = true
	_play_sound()


## The take now playing.
func current_take() -> VoiceTake:
	return line.takes[take] if line != null and take < line.takes.size() else null


## Whether the sound is in 3D at the speaker (a comment), not flat.
func is_positional() -> bool:
	return not cutscene and speaker != null and speaker.positional and source != null


## Stops the sound and the line.
func stop() -> void:
	active = false
	if _flat != null:
		_flat.stop()
	if _world != null:
		_world.stop()


## Whether the sound is sounding (a stream was started and has not ended).
func sounding() -> bool:
	return (_flat != null and _flat.playing) or (_world != null and _world.playing)


## The volume the sound plays at, in dB.
func volume_db() -> float:
	if _world != null and is_positional():
		return _world.volume_db
	return _flat.volume_db if _flat != null else 0.0


## Moves the 3D sound to its speaker and picks its bus again (a Door may have shut or opened).
func follow() -> void:
	if _world == null or not is_positional() or not is_instance_valid(source):
		return
	_world.global_position = source.global_position
	bus = MUFFLED_BUS if Sounds.is_muffled(source.global_position) else VOICE_BUS
	_world.bus = bus


## The index of the segment begun and not ended (lingering `linger` s past its end), -1 for none: what the
## subtitle shows. The latest one begun wins.
func shown_segment(linger: float) -> int:
	var t := current_take()
	if t == null:
		return -1
	for i in range(t.segments.size() - 1, -1, -1):
		var s := t.segments[i]
		if elapsed >= s.start and elapsed <= s.end + linger:
			return i
	return -1


## The index of the last segment begun, -1 before the first.
func begun_segment() -> int:
	var t := current_take()
	var at := -1
	if t != null:
		for i in t.segments.size():
			if elapsed >= t.segments[i].start:
				at = i
	return at


## Whether the line is over: its last word and the tail.
func is_over() -> bool:
	var t := current_take()
	return t == null or elapsed >= t.duration + tail


func _play_sound() -> void:
	var t := current_take()
	var stream: AudioStream = t.stream if t != null else null
	var db := speaker.voice_db if speaker != null else 0.0
	if is_positional():
		if _world == null:
			_world = AudioStreamPlayer3D.new()
			add_child(_world)
		_world.unit_size = speaker.unit_size
		_world.max_distance = speaker.max_distance
		_world.volume_db = db
		_world.stream = stream
		follow()
		if stream != null:
			_world.play()
	else:
		bus = VOICE_BUS
		if _flat == null:
			_flat = AudioStreamPlayer.new()
			add_child(_flat)
		_flat.bus = bus
		_flat.volume_db = db
		_flat.stream = stream
		if stream != null:
			_flat.play()
