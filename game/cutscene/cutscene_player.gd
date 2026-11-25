## Shows the level's cutscene on this machine (core/88, docs/architecture/run-ends.md "The Cutscene frame"):
## looks only, on every machine alike, from the `Cutscenes` Part's state. Nothing synced changes here.
##
## On a start it closes the ESC menu, turns the local player's input off, hides the HUD and draws no Sock,
## Pair, item, Laundry bin (`LaundryBin.set_drawn()`) or avatar (Q1425, Q1426); its own camera takes the
## view at the washer's `Shots/Wide` marker and the screen opens out of black over the shared fade. The
## script's beats run on its clock (methods of the washer's Looks), then its voice line through
## `Voices.play_cutscene` (`lead_in` after the lead; the tail and the music duck are `Voices`'), the camera
## cutting at each `segment_changed`: the wide shot for a line's first segment, then the close and the wide in
## turn (`index % 2`, the old rule). Without a line it holds the wide shot for the script's no-voice length.
## The Host's screen alone shows "[Space] Skip" bottom right; its skip key (or the pad's Start) asks `skip`.
##
## When its timeline runs out it fades to black and holds there; the Host asks `end`. At the Host's end
## (this machine's timeline may not have run out: the skip) every machine respawns its own player at the
## washer's `Spawns` (side by side by the Roster's order; the knockdowns are ended by the same answer), gives
## the HUD, the input and the drawing back, and fades in. A Guest that joined during it holds black and
## spawns after it at the laundry (Q864).
class_name CutscenePlayer
extends Node

## The cutscene began, and its view came back (or it ended on black: `hold_black`).
signal began(script: CutsceneScript)
signal ended
## The timeline reached its fade to black (or the Host's skip ended it first): once per cutscene. The Fix scene's
## floor opens here (core/92), under the black.
signal fading

## The skip's input action (Space, the pad's Start: Q862, Q1395) and its words.
const SKIP := &"skip_cutscene"
const SKIP_WORDS := "Skip"
## The washer's two shots, by the cut rule's index.
const WIDE := 0
const CLOSE := 1
const SHOTS: Array[NodePath] = [^"Shots/Wide", ^"Shots/Close"]
const SPAWNS := ^"Spawns"

enum Phase {
	## Nothing plays.
	IDLE,
	## The timeline runs.
	PLAYING,
	## The timeline ran out: black until the Host's end.
	HOLDING,
	## Joined during it: black until the Host's end, then a spawn at the laundry.
	LATE,
	## Ended on black (`hold_black`) until `release()`.
	BLACK,
}

@export var tuning: CutsceneTuning

@onready var camera: Camera3D = %Camera
@onready var _overlay: CanvasLayer = %Overlay
@onready var _fade: ColorRect = %Fade
@onready var _skip: Control = %Skip
@onready var _key: TextureRect = %Key

var phase := Phase.IDLE
## The script playing (or held), its clock and its whole length, the fade out included.
var script_now: CutsceneScript = null
var elapsed := 0.0
var length := 0.0
## Whether it plays a voice line, and when the line starts and ends (the tail included) on its clock.
var voiced := false
var voice_at := 0.0
var voice_end := 0.0
## The shot now (WIDE or CLOSE) and how many cuts this cutscene made.
var shot := WIDE
var cuts := 0

var _cutscenes: Cutscenes = null
var _serial := -1
var _voice_started := false
var _beats_done: Dictionary[int, bool] = {}
var _end_asked := -1
var _faded := false
var _fade_tween: Tween = null


func _ready() -> void:
	if tuning == null:
		tuning = CutsceneTuning.new()
	_overlay.visible = false
	_skip.visible = false


## The Cutscenes Part's state arrived (`now`: whole, a late joiner's snapshot or a bind).
func follow(cutscenes: Cutscenes, now: bool) -> void:
	_cutscenes = cutscenes
	if cutscenes.is_playing():
		if cutscenes.serial == _serial:
			return
		_serial = cutscenes.serial
		if now and not _is_host():
			_hold_late(cutscenes)
		else:
			_begin(cutscenes)
	elif phase in [Phase.PLAYING, Phase.HOLDING, Phase.LATE]:
		_finish()


## Whether a cutscene holds this machine's view (playing, held black or ended on black).
func is_on() -> bool:
	return phase != Phase.IDLE


## The skip hint's words as the screen shows them ("[Space] Skip"), "" when it is hidden.
func skip_text() -> String:
	if not (_overlay.visible and _skip.visible):
		return ""
	return Prompt.of(SKIP_WORDS, Prompts.keys(SKIP, _pad())).text()


## The fade's black now, 0 clear to 1 black.
func black() -> float:
	return _fade.color.a if _overlay.visible else 0.0


## After an end on black (`hold_black`): the view, the HUD and the input come back, fading in.
func release() -> void:
	if phase != Phase.BLACK:
		return
	_give_back()


func _process(delta: float) -> void:
	match phase:
		Phase.PLAYING:
			_tick(delta)
			if _is_host() and Input.is_action_just_pressed(SKIP):
				_ask(Cutscenes.SKIP)
		Phase.HOLDING, Phase.LATE:
			if phase == Phase.HOLDING and _is_host() and Input.is_action_just_pressed(SKIP):
				_ask(Cutscenes.SKIP)
			# The Host's timeline ran out (or this machine decides alone now: its Host quit).
			if _is_host() and _cutscenes != null and _cutscenes.is_playing() and _end_asked != _serial:
				_end_asked = _serial
				_ask(Cutscenes.END)


func _tick(delta: float) -> void:
	elapsed += delta
	_run_beats()
	if voiced and not _voice_started and elapsed >= voice_at:
		_voice_started = true
		Voices.play_cutscene(script_now.voice, Array(_cutscenes.takes), _sources())
	var fade := maxf(tuning.fade_seconds, 0.001)
	var opening := 1.0 - elapsed / fade
	var closing := (elapsed - (length - fade)) / fade
	_set_black(clampf(maxf(opening, closing), 0.0, 1.0))
	if closing >= 0.0:
		_fade_out()
	if elapsed >= length:
		_set_black(1.0)
		phase = Phase.HOLDING


func _begin(cutscenes: Cutscenes) -> void:
	var s := cutscenes.script_now()
	if s == null:
		Log.error("cutscene", "no cutscene script at %s" % cutscenes.playing)
		return
	script_now = s
	phase = Phase.PLAYING
	elapsed = 0.0
	cuts = 0
	_voice_started = false
	_faded = false
	_beats_done.clear()
	var line_seconds := _voice_seconds(s, cutscenes.takes)
	voiced = line_seconds > 0.0
	if voiced:
		voice_at = s.lead + tuning.lead_in
		voice_end = voice_at + line_seconds
	else:
		voice_at = -1.0
		voice_end = maxf(s.no_voice_seconds - tuning.fade_seconds, s.lead)
	length = voice_end + s.after_voice_seconds + tuning.fade_seconds
	_hide(true)
	_washer_look(s)
	_take_view()
	_skip.visible = _is_host()
	_key.texture = _skip_texture()
	if not Voices.segment_changed.is_connected(_on_segment):
		Voices.segment_changed.connect(_on_segment)
	began.emit(s)


func _fade_out() -> void:
	if not _faded:
		_faded = true
		fading.emit()


func _hold_late(cutscenes: Cutscenes) -> void:
	script_now = cutscenes.script_now()
	phase = Phase.LATE
	voiced = false
	_hide(true)
	if script_now != null:
		_washer_look(script_now)
	_take_view()
	_skip.visible = false
	_set_black(1.0)


## The Host's end: everyone respawns, then the view comes back (or stays black for `hold_black`).
func _finish() -> void:
	var was := phase
	if was != Phase.LATE:
		_fade_out()
	if Voices.segment_changed.is_connected(_on_segment):
		Voices.segment_changed.disconnect(_on_segment)
	if _voice_started and Voices.cutscene_playing():
		Voices.stop_cutscene()
	_voice_started = false
	_washer_look(null)
	if script_now == null or script_now.respawn or was == Phase.LATE:
		_respawn.call_deferred()
	if script_now != null and script_now.hold_black and was != Phase.LATE:
		phase = Phase.BLACK
		_skip.visible = false
		_set_black(1.0)
		ended.emit()
		return
	_give_back()


func _give_back() -> void:
	phase = Phase.IDLE
	_hide(false)
	_skip.visible = false
	if camera.current:
		camera.clear_current(false)
	var runtime := LevelRuntime.of(self)
	if runtime != null:
		runtime.player.camera().make_current()
	_set_black(1.0)
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_black, 1.0, 0.0, maxf(tuning.fade_seconds, 0.001))
	_fade_tween.tween_callback(func() -> void: _overlay.visible = false)
	ended.emit()


## Draws or hides what a cutscene leaves out on this machine, and takes or gives the player's input and HUD.
func _hide(on: bool) -> void:
	var runtime := LevelRuntime.of(self)
	if runtime == null:
		return
	if on and runtime.esc_menu != null:
		runtime.esc_menu.close()
	runtime.player.set_cutscene(on)
	var net_hud := runtime.get_node_or_null(^"Net/Hud") as CanvasLayer
	if net_hud != null:
		net_hud.visible = not on
	runtime.players.visible = not on
	runtime.mess.set_drawn(not on)
	for node in get_tree().get_nodes_in_group(LaundryBin.GROUP):
		var bin := node as LaundryBin
		if bin != null and LevelRuntime.of(bin) == runtime:
			bin.set_drawn(not on)


## The washer's Looks shows the cutscene's `WasherCutsceneLook` (its repair and damage share, core/87), or
## the run's mood again (null). A Looks without `set_cutscene` is left as it is.
func _washer_look(s: CutsceneScript) -> void:
	var washer := Washer.of_level(self)
	if washer == null or washer.looks == null or not washer.looks.has_method(&"set_cutscene"):
		return
	var look: WasherCutsceneLook = null
	if s != null and s.voice != null and washer.tuning != null:
		for l in washer.tuning.cutscene_looks:
			if l != null and l.trigger == s.voice.id:
				look = l
	washer.looks.call(&"set_cutscene", look)


## The cutscene's camera takes the view at the wide shot, black over it.
func _take_view() -> void:
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null
	_overlay.visible = true
	_set_black(1.0)
	_cut(WIDE)
	camera.make_current()


func _cut(which: int) -> void:
	shot = which
	cuts += 1
	var washer := Washer.of_level(self)
	var thing := washer.get_parent() if washer != null else null
	var marker := thing.get_node_or_null(SHOTS[which]) as Node3D if thing != null else null
	if marker == null:
		return
	camera.global_transform = marker.global_transform
	if marker is WasherShot:
		camera.fov = (marker as WasherShot).fov


## The cut rule (washer.md): the wide shot for a line's first segment, then `index % 2`.
func _on_segment(_line: VoiceLine, index: int) -> void:
	if phase != Phase.PLAYING:
		return
	_cut(WIDE if index < 1 else index % 2)


func _run_beats() -> void:
	for i in script_now.beats.size():
		if _beats_done.has(i):
			continue
		var beat: Array = script_now.beats[i]
		if beat.size() < 2:
			_beats_done[i] = true
			continue
		var at: float = voice_end if str(beat[0]) == CutsceneScript.AFTER_VOICE else float(beat[0])
		if elapsed < at:
			continue
		_beats_done[i] = true
		_beat(StringName(str(beat[1])), beat[2] if beat.size() > 2 and beat[2] is Array else [])


## A beat calls the washer's Looks (W2), or the washer itself for what is not its face (the spray, core/92);
## one neither has is logged, not fatal.
func _beat(beat: StringName, args: Array) -> void:
	var washer := Washer.of_level(self)
	var looks: Node = washer.looks if washer != null else null
	if looks != null and looks.has_method(beat):
		looks.callv(beat, args)
	elif washer != null and washer.has_method(beat):
		washer.callv(beat, args)
	else:
		Log.warn("cutscene", "the washer's Looks has no beat %s" % beat)


## Seconds of every line of the script's trigger at the takes given, each with the cutscene's tail; 0 for none.
func _voice_seconds(s: CutsceneScript, takes: PackedInt32Array) -> float:
	if s.voice == null:
		return 0.0
	var total := 0.0
	var lines := Voices.book().cutscene_lines(s.voice.id)
	for i in lines.size():
		var line := lines[i]
		if line.takes.is_empty():
			continue
		var take := clampi(takes[i] if i < takes.size() else 0, 0, line.takes.size() - 1)
		total += line.takes[take].duration + Voices.tuning.cutscene_tail
	return total


## The speaker's face in this level (two levels share the tree in a co-op test).
func _sources() -> Dictionary:
	var washer := Washer.of_level(self)
	if washer == null or washer.speaker == null or washer.looks == null:
		return {}
	return {washer.speaker.id: washer.looks}


## The local player stands at the washer's spawn of its place in the Roster, every knockdown over.
func _respawn() -> void:
	var runtime := LevelRuntime.of(self)
	var washer := Washer.of_level(self)
	var thing := washer.get_parent() if washer != null else null
	var spawns := thing.get_node_or_null(SPAWNS) if thing != null else null
	if runtime == null or spawns == null:
		return
	var markers: Array[Node3D] = []
	for child in spawns.get_children():
		if child is Node3D:
			markers.append(child as Node3D)
	if markers.is_empty():
		return
	var peers := runtime.roster.peers() if runtime.roster != null else PackedInt32Array()
	var place := maxi(peers.find(runtime.player.player_id()), 0)
	runtime.player.respawn_at(markers[place % markers.size()].global_transform)


func _ask(kind: StringName) -> void:
	if _cutscenes == null or _cutscenes.parts == null:
		return
	_cutscenes.parts.ask(Command.new(kind, Parts.HOST, _cutscenes.id, {"serial": _serial}))


func _is_host() -> bool:
	return _cutscenes != null and _cutscenes.parts != null and _cutscenes.parts.is_host()


func _set_black(a: float) -> void:
	_fade.color.a = a


func _pad() -> bool:
	var runtime := LevelRuntime.of(self)
	return runtime != null and runtime.player.hud().pad


func _skip_texture() -> Texture2D:
	var keys := Prompts.keys(SKIP, _pad())
	return UiIcons.texture(keys[0]) if not keys.is_empty() else null
