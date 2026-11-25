## The game's voice system, one autoload named `Voices` (core/85, `docs/architecture/voice.md` "Playing",
## "Cutscenes"). It plays the lines a Part's answer gives and decides nothing of the game: a line reaches it
## only from a speaker Part's `_show()` (or the Cutscene's start), on every machine alike.
##
## One channel per speaker and one for cutscenes. The rule of priority (V4): a line asked while a voice of
## higher or equal priority talks on another channel is dropped (or, when it `waits`, waits for it up to
## `VoiceTuning.wait_hold`); a higher one cuts the lower (its `finished` fires with `skipped`, its speaker
## rests). The same channel: the new line replaces the old. A comment sounds in 3D from its `VoiceSource` on
## the Voice bus (MuffledVoice behind a shut Door); a cutscene line is flat on Voice, heard and subtitled by
## all. While the cutscene channel plays the Music bus is ducked (V5). Subtitles show a segment begun and not
## ended, lingering, while the local camera is within the speaker's earshot and level band (V8), when
## `display/subtitles` is on.
extends Node

## A line began (its take), a new segment began (the cutscene camera cuts on it), a line ended (`skipped`:
## cut by a higher voice, stopped, or skipped by the Host).
signal started(line: VoiceLine, take: int)
signal segment_changed(line: VoiceLine, index: int)
signal finished(line: VoiceLine, skipped: bool)

const TUNING := preload("res://game/voice/voice_tuning.tres")
const SUBTITLES := preload("res://game/voice/subtitles.tscn")
## The cutscene channel's id.
const CUTSCENE := &"cutscene"
## The bus the cutscene's duck rides on, by an amplify effect.
const MUSIC_BUS := &"Music"
## The subtitles' canvas layer: above the HUD, below the menus; on top of everything in a cutscene.
const LAYER := 2
const CUTSCENE_LAYER := 26

var tuning: VoiceTuning = TUNING

var _book: VoiceBook = null
var _channels: Dictionary[StringName, VoiceChannel] = {}
## Lines that wait: {"line", "take", "speaker", "source", "until"}.
var _waiting: Array[Dictionary] = []
## The cutscene's lines still to play: {"line", "take", "speaker", "source"}.
var _queue: Array[Dictionary] = []
var _clock := 0.0
var _layer: CanvasLayer
var _subtitles: Subtitles
## The share of the music heard now (1: untouched).
var _duck := 1.0
var _amp: AudioEffectAmplify = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.name = "VoiceLayer"
	_layer.layer = LAYER
	add_child(_layer)
	_subtitles = SUBTITLES.instantiate() as Subtitles
	_layer.add_child(_subtitles)


## Every spoken line of the game (loaded once).
func book() -> VoiceBook:
	if _book == null:
		_book = VoiceBook.load_book()
	return _book


## Plays `line`'s take `take` from `source` (its speaker's Looks): comments in 3D, or flat as a cutscene's.
## True when it started now; false when a higher voice dropped it, or it waits.
func say(line: VoiceLine, take: int, source: VoiceSource, as_cutscene := false) -> bool:
	if line == null or source == null or source.speaker == null:
		return false
	return _ask(line, take, source.speaker, source, as_cutscene)


## Plays every line of the cutscene `trigger`, of every speaker, in `order`, one after the other, flat on the
## cutscene channel. `takes`: the take of each line (the Host's answer carries them; missing: the first).
## `sources`: a speaker's id -> its VoiceSource, for a speaker with more than one in the tree; else the
## first source of the speaker found. True when the first line started.
func play_cutscene(trigger: VoiceTrigger, takes: Array = [], sources: Dictionary = {}) -> bool:
	stop_cutscene()
	var lines := book().cutscene_lines(trigger.id)
	for i in lines.size():
		var speaker := book().speaker_of(lines[i])
		var source: VoiceSource = sources.get(speaker.id) if speaker != null else null
		if source == null and speaker != null:
			source = source_of(speaker.id)
		_queue.append({"line": lines[i], "take": int(takes[i]) if i < takes.size() else 0, "speaker": speaker, "source": source})
	return _next_cutscene_line()


## A cutscene is playing (its channel, or a line still to come).
func cutscene_playing() -> bool:
	return not _queue.is_empty() or _active(CUTSCENE)


## The speaker `id` is talking: its line, with the tail.
func talking(speaker: StringName) -> bool:
	return _active(speaker)


## The line `speaker`'s channel plays, or null.
func line_of(speaker: StringName) -> VoiceLine:
	return _channels[speaker].line if _active(speaker) else null


## The channel of `speaker` (a test reads its clock, its bus, its segment), or null before its first line.
func channel(speaker: StringName) -> VoiceChannel:
	return _channels.get(speaker)


## Stops `speaker`'s line (it fires `finished` with skipped).
func stop(speaker: StringName) -> void:
	if speaker == CUTSCENE:
		stop_cutscene()
	elif _active(speaker):
		_finish(_channels[speaker], true)


## The Host's skip: the cutscene ends for everyone at once, its lines still to come never play.
func stop_cutscene() -> void:
	_queue.clear()
	_waiting.assign(_waiting.filter(func(w: Dictionary) -> bool: return not w["cutscene"]))
	if _active(CUTSCENE):
		_finish(_channels[CUTSCENE], true)


## The share of the music heard now: 1 untouched, `tuning.duck_level` ducked.
func duck() -> float:
	return _duck


## The subtitles' row text for `channel_id` ("" for none).
func subtitle_text(channel_id: StringName) -> String:
	return _subtitles.text_of(channel_id)


func subtitles() -> Subtitles:
	return _subtitles


## The first VoiceSource of speaker `id` in the tree, or null.
func source_of(id: StringName) -> VoiceSource:
	for node in get_tree().get_nodes_in_group(VoiceSource.GROUP):
		var s := node as VoiceSource
		if s != null and s.speaker != null and s.speaker.id == id:
			return s
	return null


## The rule a talking voice's subtitle follows: `at` is within `earshot` metres of `centre` and within
## `band` metres of its height (the same floor).
static func within_earshot(at: Vector3, centre: Vector3, earshot: float, band: float) -> bool:
	return at.distance_to(centre) <= earshot and absf(at.y - centre.y) <= band


## Everything stopped and forgotten, with no signal (a test between cases, a new level).
func reset() -> void:
	_queue.clear()
	_waiting.clear()
	for c: VoiceChannel in _channels.values():
		if c.active:
			c.stop()
			if is_instance_valid(c.source):
				c.source.rest()
	if _subtitles != null:
		_subtitles.clear_all()
	_duck = 1.0
	_apply_duck()
	_clock = 0.0


func _process(delta: float) -> void:
	_clock += delta
	var goal := tuning.duck_level if cutscene_playing() else 1.0
	_duck = move_toward(_duck, goal, delta * (1.0 - tuning.duck_level) / tuning.duck_seconds)
	_apply_duck()
	_layer.layer = CUTSCENE_LAYER if cutscene_playing() else LAYER
	_try_waiting()
	for c: VoiceChannel in _channels.values():
		if c.active:
			_step(c, delta)


func _exit_tree() -> void:
	_duck = 1.0
	_apply_duck()


## The rule of priority, then the start.
func _ask(line: VoiceLine, take: int, speaker: VoiceSpeaker, source: VoiceSource, as_cutscene: bool) -> bool:
	var channel_id := CUTSCENE if as_cutscene else speaker.id
	var priority := tuning.cutscene_priority if as_cutscene else speaker.priority
	if _blocked(channel_id, priority):
		if line.waits:
			_waiting.append({"line": line, "take": take, "speaker": speaker, "source": source,
					"cutscene": as_cutscene, "until": _clock + tuning.wait_hold})
		return false
	for c: VoiceChannel in _channels.values():
		if c.active and c.id != channel_id and c.priority < priority:
			_finish(c, true)
	if _active(channel_id):
		_finish(_channels[channel_id], true)
	_start(channel_id, line, take, speaker, source, as_cutscene, priority)
	return true


## Whether a voice of higher or equal priority talks on another channel.
func _blocked(channel_id: StringName, priority: int) -> bool:
	for c: VoiceChannel in _channels.values():
		if c.active and c.id != channel_id and c.priority >= priority:
			return true
	return false


func _start(channel_id: StringName, line: VoiceLine, take: int, speaker: VoiceSpeaker, source: VoiceSource,
		as_cutscene: bool, priority: int) -> void:
	var c: VoiceChannel = _channels.get(channel_id)
	if c == null:
		c = VoiceChannel.new()
		c.id = channel_id
		c.name = String(channel_id).to_pascal_case()
		add_child(c)
		_channels[channel_id] = c
	var tail := tuning.cutscene_tail if as_cutscene else speaker.tail
	c.begin(line, take, speaker, source, as_cutscene, priority, tail)
	if source != null:
		source.act(c.current_take())
	started.emit(line, c.take)
	_step(c, 0.0)


func _step(c: VoiceChannel, delta: float) -> void:
	c.elapsed += delta
	if c.is_over():
		_finish(c, false)
		return
	c.follow()
	var begun := c.begun_segment()
	if begun != c.segment:
		c.segment = begun
		if begun >= 0:
			segment_changed.emit(c.line, begun)
	_show_subtitle(c)


func _show_subtitle(c: VoiceChannel) -> void:
	var key: StringName = &""
	var t := c.current_take()
	if t != null and _heard(c) and Settings.get_bool(Settings.SUBTITLES):
		var i := c.shown_segment(c.speaker.linger if c.speaker != null else 0.0)
		if i >= 0:
			key = t.segments[i].key
	if key == c.shown_key:
		return
	c.shown_key = key
	if key == &"":
		_subtitles.clear(c.id)
	else:
		_subtitles.show_line(c.id, c.priority, c.speaker.icon if c.speaker != null else null, tr(key))


## Whether the local camera is where this line's subtitle may show.
func _heard(c: VoiceChannel) -> bool:
	if c.cutscene or c.source == null or not is_instance_valid(c.source) or c.speaker == null:
		return true
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return true
	return within_earshot(camera.global_position, c.source.global_position, c.speaker.earshot, c.speaker.level_band)


func _finish(c: VoiceChannel, skipped: bool) -> void:
	var line := c.line
	c.stop()
	_subtitles.clear(c.id)
	c.shown_key = &""
	if is_instance_valid(c.source):
		c.source.rest()
	finished.emit(line, skipped)
	if c.id == CUTSCENE and not skipped:
		_next_cutscene_line()


func _next_cutscene_line() -> bool:
	while not _queue.is_empty():
		var next: Dictionary = _queue.pop_front()
		if _ask(next["line"], next["take"], next["speaker"], next["source"], true):
			return true
	return false


func _try_waiting() -> void:
	var still: Array[Dictionary] = []
	for w in _waiting:
		if _clock > float(w["until"]):
			continue
		var as_cutscene: bool = w["cutscene"]
		var speaker: VoiceSpeaker = w["speaker"]
		var priority := tuning.cutscene_priority if as_cutscene else speaker.priority
		if _blocked(CUTSCENE if as_cutscene else speaker.id, priority):
			still.append(w)
		else:
			_ask(w["line"], w["take"], speaker, w["source"], as_cutscene)
	_waiting = still


func _active(channel_id: StringName) -> bool:
	var c: VoiceChannel = _channels.get(channel_id)
	return c != null and c.active


## The duck: an amplify effect on the Music bus (the slider keeps working, the Muffled bus sends into it).
func _apply_duck() -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus < 0:
		return
	if _amp == null or not _has_effect(bus):
		_amp = null
		for i in AudioServer.get_bus_effect_count(bus):
			if AudioServer.get_bus_effect(bus, i) is AudioEffectAmplify:
				_amp = AudioServer.get_bus_effect(bus, i) as AudioEffectAmplify
		if _amp == null:
			_amp = AudioEffectAmplify.new()
			AudioServer.add_bus_effect(bus, _amp)
	_amp.volume_db = linear_to_db(maxf(_duck, 0.0001))


func _has_effect(bus: int) -> bool:
	for i in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) == _amp:
			return true
	return false
