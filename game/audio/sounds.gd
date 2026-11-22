## The game's sound system, one autoload named `Sounds`. Code asks for a sound by its name from the
## catalogue (sound_catalogue.tres): `Sounds.play(&"pick")` for a flat one (the player's own, the UI),
## `Sounds.play_at(&"drawer_open", where)` for a world one. Which of the two a name takes is its
## SoundEvent's `spatial` flag; a name the catalogue does not know, or the wrong one of the two, is an
## error (and a test reads the game's code for them).
##
## A play picks one of the event's clips at random and jitters its pitch, through Godot's
## AudioStreamRandomizer. A world sound fades with distance (unit size 3 m, gone at 20 m) and plays
## muffled (the Muffled* buses: -9 dB, 900 Hz low-pass) when a shut Door lies between the listener's
## camera and it. Eight flat and eight world voices are used in turn, as in the old game.
##
## Buses are default_bus_layout.tres: Master, SFX, Ambient, Music, UI (their mix is the layout's
## volume) and Muffled copies of the last three that send into them. The player's volume per bus is
## a setting ("audio/<bus>_volume", 0 to 1, default 1), multiplied onto the layout's mix.
extends Node

## A sound was started: its name, whether it is a world one, where (the origin for a flat one), the
## bus it went to (a Muffled one when a Door is between).
signal played(event: StringName, spatial: bool, at: Vector3, bus: StringName)

const CATALOGUE := preload("res://game/audio/sound_catalogue.tres")
## The bus layout (the project setting audio/buses/default_bus_layout).
const LAYOUT := "res://default_bus_layout.tres"
## Voices of each kind.
const VOICES := 8
const MUFFLED := "Muffled"
## The volume settings, by bus.
const VOLUME_KEYS := {
	&"Master": "audio/master_volume",
	&"SFX": "audio/sfx_volume",
	&"Ambient": "audio/ambient_volume",
	&"Music": "audio/music_volume",
	&"UI": "audio/ui_volume",
}
## How many walls and doors one look from the listener to a sound goes through at most.
const MUFFLE_HOPS := 6
## How far past a thing the next look starts.
const HOP_STEP := 0.02
## A hit this close to the sound's own place is the thing that makes it (a Door's close sound is at
## the shut Door): it does not muffle it.
const OWN_HIT := 0.08

var catalogue: SoundCatalogue = CATALOGUE

var _flat: Array[AudioStreamPlayer] = []
var _world: Array[AudioStreamPlayer3D] = []
var _next_flat := 0
var _next_world := 0
## When each event last played, on the clock (seconds), for its min_gap.
var _last_at: Dictionary[StringName, float] = {}
var _loops: Dictionary[StringName, AudioStreamPlayer] = {}
var _randomizers: Dictionary[StringName, AudioStream] = {}
## The layout file's own level of each bus, in dB: the mix the volume settings are multiplied onto.
var _mix_db: Dictionary[StringName, float] = {}
## The voice last started, for a test and for whoever wants to watch it.
var last_voice: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var flat := AudioStreamPlayer.new()
		add_child(flat)
		_flat.append(flat)
		var world := AudioStreamPlayer3D.new()
		world.unit_size = catalogue.unit_size
		world.max_distance = catalogue.max_distance
		add_child(world)
		_world.append(world)
	# The mix is read from the layout file itself: Settings has already set Master to its own slider.
	var layout := load(LAYOUT) as AudioBusLayout
	for bus: StringName in VOLUME_KEYS:
		var index := AudioServer.get_bus_index(bus)
		_mix_db[bus] = float(layout.get("bus/%d/volume_db" % index))
		Settings.register({VOLUME_KEYS[bus]: 1.0})
	Settings.register({PadRumble.SETTING: true})
	Settings.changed.connect(_on_setting)
	apply_volumes()


func has_event(name: StringName) -> bool:
	return catalogue.has(name)


## Plays a flat event: the player's own sounds, the UI.
func play(name: StringName) -> void:
	var e := _asked(name, false)
	if e == null or _too_soon(e):
		return
	var voice := _flat[_next_flat]
	_next_flat = (_next_flat + 1) % VOICES
	voice.stream = _stream_of(e)
	voice.bus = e.bus
	voice.volume_db = e.volume_db
	voice.pitch_scale = 1.0
	voice.play()
	last_voice = voice
	played.emit(name, false, Vector3.ZERO, voice.bus)


## Plays a world event from `where` (a point of the level), muffled when a shut Door is between.
## `strength` (0 soft to 1 hard, a bounce's hit speed) makes it quieter and lower the softer it is, by
## the event's soft_db, soft_pitch and hard_pitch; the default 1 plays it as the event says.
func play_at(name: StringName, where: Vector3, strength := 1.0) -> void:
	_play_world(_asked(name, true), name, where, strength)


## Plays a player's own flat event as a Teammate's, from `where` (their body): the same clips and
## level as one's own, but in the world, fading with distance and muffled behind a shut Door like any
## world sound (Q2452, Q2453).
func play_from(name: StringName, where: Vector3) -> void:
	_play_world(_asked(name, false), name, where, 1.0)


func _play_world(e: SoundEvent, name: StringName, where: Vector3, strength: float) -> void:
	if e == null or _too_soon(e):
		return
	strength = clampf(strength, 0.0, 1.0)
	var voice := _world[_next_world]
	_next_world = (_next_world + 1) % VOICES
	voice.stream = _stream_of(e)
	voice.bus = MUFFLED + e.bus if is_muffled(where) and AudioServer.get_bus_index(MUFFLED + e.bus) >= 0 else e.bus
	voice.volume_db = e.volume_db + lerpf(e.soft_db, 0.0, strength)
	voice.pitch_scale = lerpf(e.soft_pitch, e.hard_pitch, strength)
	voice.global_position = where
	voice.play()
	last_voice = voice
	played.emit(name, true, where, voice.bus)


## Starts a flat looping event (an ambience) and returns its player; the same name again returns the
## one already playing.
func start_loop(name: StringName) -> AudioStreamPlayer:
	if _loops.has(name):
		return _loops[name]
	var e := _asked(name, false)
	if e == null:
		return null
	var voice := AudioStreamPlayer.new()
	voice.stream = _stream_of(e)
	voice.bus = e.bus
	voice.volume_db = e.volume_db
	add_child(voice)
	voice.play()
	_loops[name] = voice
	played.emit(name, false, Vector3.ZERO, voice.bus)
	return voice


func is_looping(name: StringName) -> bool:
	return _loops.has(name)


func stop_loop(name: StringName) -> void:
	var voice: AudioStreamPlayer = _loops.get(name)
	if voice != null:
		_loops.erase(name)
		voice.queue_free()


## Whether a shut Door lies between the listener's camera and `where`: the camera looks toward it,
## thing by thing, and meets one of the catalogue's muffling entities that is not open.
func is_muffled(where: Vector3) -> bool:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return false
	var from := camera.global_position
	for hop in MUFFLE_HOPS:
		var hit := PhysicsQueries.ray(self, from, where, Mess.LAYER_HOUSE)
		if hit.is_empty() or (hit["position"] as Vector3).distance_to(where) < OWN_HIT:
			return false
		var part := Parts.part_of(hit["collider"] as Node)
		if part is Openable and not (part as Openable).open and catalogue.muffling_scenes.has(part.get_parent().scene_file_path):
			return true
		from = (hit["position"] as Vector3) + (where - from).normalized() * HOP_STEP
	return false


## Every bus at the layout's mix times the player's volume setting.
func apply_volumes() -> void:
	for bus: StringName in VOLUME_KEYS:
		var index := AudioServer.get_bus_index(bus)
		var slider := clampf(Settings.get_float(VOLUME_KEYS[bus]), 0.0, 1.0)
		AudioServer.set_bus_volume_db(index, _mix_db[bus] + linear_to_db(maxf(slider, 0.0001)))
		AudioServer.set_bus_mute(index, slider <= 0.0)


## The layout's own level of a bus in dB, before the setting.
func mix_db(bus: StringName) -> float:
	return _mix_db[bus]


## Stops everything and starts the voices over (a test between cases).
func reset() -> void:
	for name: StringName in _loops.keys():
		stop_loop(name)
	for voice: AudioStreamPlayer in _flat:
		voice.stop()
	for voice: AudioStreamPlayer3D in _world:
		voice.stop()
	_next_flat = 0
	_next_world = 0
	last_voice = null
	_last_at.clear()


## Whether `e` played less than its min_gap ago (then this play is dropped); else notes this one.
func _too_soon(e: SoundEvent) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if e.min_gap > 0.0 and now - float(_last_at.get(e.event, -INF)) < e.min_gap:
		return true
	_last_at[e.event] = now
	return false


func _on_setting(key: String) -> void:
	if key.begins_with("audio/"):
		apply_volumes()


func _asked(name: StringName, spatial: bool) -> SoundEvent:
	var e := catalogue.find(name)
	if e == null:
		Log.error("sounds", "no event named '%s' in the catalogue" % name)
	elif e.spatial != spatial:
		Log.error("sounds", "'%s' is %s, asked %s" % [name, "a world sound (play_at)" if e.spatial else "a flat sound (play)", "from a spot" if spatial else "flat"])
		return null
	elif e.clips.is_empty():
		return null  # an event with no pick is silent on purpose (amb_room), no error
	return e


## The stream a play uses: a randomizer over the clips (a random one, its pitch jittered), or the
## one clip set to loop.
func _stream_of(e: SoundEvent) -> AudioStream:
	if _randomizers.has(e.event):
		return _randomizers[e.event]
	var stream: AudioStream
	if e.loop:
		stream = e.clips[0].duplicate() as AudioStream
		if "loop" in stream:
			stream.set("loop", true)
	else:
		var r := AudioStreamRandomizer.new()
		r.random_pitch = 1.0 + catalogue.pitch_jitter
		r.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM
		for i in e.clips.size():
			r.add_stream(i, e.clips[i])
		stream = r
	_randomizers[e.event] = stream
	return stream
