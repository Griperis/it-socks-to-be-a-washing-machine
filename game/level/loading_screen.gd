## The loading screen, one scene for every wait (house/09, Q2542; the old look, core/58, Q2575): the
## title's dark backdrop, a cream card with a tumbling sock in its fixed square, the heading ("Loading
## the house...", a New Game too, Q2579; "Joining..." for a Guest) and a bar that never goes back.
##
## In a level (LevelRuntime.load_screen) it covers the window while the level's generated Socks are
## laid a slice per frame: each frame it lays for `tuning.slice_ms`, the level's 3D is not drawn
## meanwhile, the local player stands frozen at the spawn and a joining Guest waits
## (Parts.unsettle()); the bar fills as the old (0.1 once the places are found, then the share of the
## Socks laid). When the Socks are laid they appear all at once (Q2523) and `tuning.hide_frames` frames
## later the screen lifts: the card goes and the backdrop fades out over `tuning.fade_seconds`, input
## not held. A Guest's snapshot ends the wait too (the Host's Socks replace this machine's); a loaded
## World lays nothing (LevelRuntime skips the generators), so the screen never shows in it.
##
## With no Mess (SceneChanger's, while the level's scene loads on a worker thread) it shows from the
## start and is driven from outside: set_progress(), then finish() or a hand-over to the level's own.
class_name LoadingScreen
extends CanvasLayer

## The screen lifted: the Socks are in the Mess (or a snapshot came), or finish() was called.
signal lifted

## The words of a load and of a Guest's join (Q2579). placeholder: the old wording.
const LOADING := "Loading the house..."
const JOINING := "Joining..."

@export var mess: Mess
@export var parts: Parts
## The local player, frozen while it shows.
@export var player: Node
@export var tuning: LoadingTuning

## What this load measured (the Built log's numbers, the tests): the frames it laid in, each frame's
## slice of laying, the longest slice and the longest frame from one slice's start to the next (µs).
var frames := 0
var slices := PackedInt32Array()
var longest_slice := 0
var longest_frame := 0
## The heading to show (set before or after the screen is ready).
var heading_text := LOADING:
	set(v):
		heading_text = v
		if _text != null:
			_text.text = v
## Freed once faded (SceneChanger's own screen); a level's stays, hidden.
var free_when_faded := false

@onready var _back: ColorRect = %Back
@onready var _card: Control = %Card
@onready var _sock: TextureRect = %Sock
@onready var _bar: ProgressBar = %Progress
@onready var _text: Label = %Text

var _player_mode := Node.PROCESS_MODE_INHERIT
var _player_disable := CollisionObject3D.DISABLE_MODE_REMOVE
var _waiting := false
var _laying := false
var _lifted := false
var _hide_in := -1
var _last_start := 0
var _time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tuning == null:
		tuning = LoadingTuning.new()
	_text.text = heading_text
	_bar.value = 0.0
	_bar.visible = false
	if mess == null:
		# SceneChanger's: up at once, driven from outside.
		visible = true
		return
	visible = false
	set_process(false)
	if not mess.is_laying():
		_lifted = true
		return
	_waiting = true
	_laying = true
	visible = true
	_bar.visible = true
	if parts != null:
		parts.unsettle(self)
	if player != null:
		# Its body stays in the physics space as it was (the laying sees it, as in one frame).
		if player is CollisionObject3D:
			_player_disable = (player as CollisionObject3D).disable_mode
			(player as CollisionObject3D).disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
		_player_mode = player.process_mode
		player.process_mode = Node.PROCESS_MODE_DISABLED
	get_viewport().disable_3d = true
	set_process(true)


## Whether the screen still covers the level (laying, or the frames after); a fading one does not.
func is_showing() -> bool:
	return visible and not _lifted


## Whether the screen lifted (or never showed): the level plays (a shot waits on it).
func is_lifted() -> bool:
	return not is_showing()


## What it says.
func text() -> String:
	return _text.text


func set_heading(t: String) -> void:
	heading_text = t


## The bar's fill (0..1).
func shown_progress() -> float:
	return _bar.value


## Whether the bar shows (only while the wait can tell how far it is).
func bar_shown() -> bool:
	return _bar.visible


## How far the wait is, 0 to 1: the bar shows, and never goes back.
func set_progress(ratio: float) -> void:
	_bar.visible = true
	_bar.value = maxf(_bar.value, clampf(ratio, 0.0, 1.0))


## The wait is over: a measured bar shows full, the card goes and the backdrop fades out; nothing
## under it is held back meanwhile.
func finish() -> void:
	if _lifted and not visible:
		return
	_end_wait()
	_lifted = true
	if _bar.visible:
		_bar.value = 1.0
	_card.visible = false
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lifted.emit()
	var tween := create_tween()
	tween.tween_property(_back, "modulate:a", 0.0, tuning.fade_seconds)
	tween.tween_callback(_faded)


func _faded() -> void:
	visible = false
	set_process(false)
	if free_when_faded:
		queue_free()


func _process(delta: float) -> void:
	_time += delta
	_sock.rotation = _time * tuning.tumble_speed
	_sock.position.y = (_sock.get_parent() as Control).size.y * 0.5 - _sock.size.y * 0.5 \
			+ sin(_time * tuning.tumble_speed * 0.5) * tuning.bob_px
	if not _laying or _lifted:
		return
	if _hide_in >= 0:
		_hide_in -= 1
		if _hide_in < 0:
			_laying = false
			finish()
		return
	var t0 := Time.get_ticks_usec()
	if _last_start > 0:
		longest_frame = maxi(longest_frame, t0 - _last_start)
	_last_start = t0
	var done := mess.lay_step(t0 + int(tuning.slice_ms * 1000.0))
	var took := Time.get_ticks_usec() - t0
	longest_slice = maxi(longest_slice, took)
	slices.append(took)
	frames += 1
	if mess.starting != null or mess.layer != null:
		set_progress(mess.lay_progress())
	if done:
		set_progress(1.0)
		_end_wait()
		_hide_in = tuning.hide_frames


## The Socks are in (or a snapshot replaced them): the level draws again, the player moves and a
## waiting Guest gets its snapshot.
func _end_wait() -> void:
	if not _waiting:
		return
	_waiting = false
	get_viewport().disable_3d = false
	if player != null and is_instance_valid(player):
		player.process_mode = _player_mode
		if player is CollisionObject3D:
			(player as CollisionObject3D).disable_mode = _player_disable
	if parts != null:
		parts.settle(self)


func _exit_tree() -> void:
	_end_wait()
