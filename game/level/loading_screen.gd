## The level's loading screen (house/09, Q2542; the old LoadingScreen, Q356): while the level's
## generated Socks are laid a slice per frame (LevelRuntime.load_screen) it covers the window, says
## "The washer bursts open..." and fills its bar as the old (0.1 once the places are found, then the
## share of the Socks laid). Each frame it lays for `tuning.slice_ms`; the level's 3D is not drawn
## meanwhile, the local player stands frozen at the spawn and a joining Guest waits (Parts.unsettle()).
## When the Socks are laid they appear all at once (Q2523) and the screen goes `tuning.hide_frames`
## frames later. A Guest's snapshot ends the wait too (the Host's Socks replace this machine's).
## A placeholder look on the game's Theme; M4 restyles it.
class_name LoadingScreen
extends CanvasLayer

## The screen went: the Socks are in the Mess (or a snapshot came).
signal lifted

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

@onready var _bar: ProgressBar = %Progress
@onready var _text: Label = %Text

var _player_mode := Node.PROCESS_MODE_INHERIT
var _player_disable := CollisionObject3D.DISABLE_MODE_REMOVE
var _waiting := false
var _hide_in := -1
var _last_start := 0


func _ready() -> void:
	visible = false
	set_process(false)
	if mess == null or not mess.is_laying():
		return
	_waiting = true
	visible = true
	_bar.value = 0.0
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


## Whether the screen still covers the level (laying, or the frames after).
func is_showing() -> bool:
	return visible


## Whether the screen is gone (or never showed): the level plays (a shot waits on it).
func is_lifted() -> bool:
	return not visible


## What it says.
func text() -> String:
	return _text.text


## The bar's fill (0..1).
func shown_progress() -> float:
	return _bar.value


func _process(_delta: float) -> void:
	if _hide_in >= 0:
		_hide_in -= 1
		if _hide_in < 0:
			visible = false
			set_process(false)
			lifted.emit()
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
	if mess.starting != null:
		_bar.value = maxf(_bar.value, mess.starting.progress())
	if done:
		_bar.value = 1.0
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
