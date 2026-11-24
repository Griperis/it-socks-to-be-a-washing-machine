## The player's middle button (core/43 lines 1-8, 15-17; the old rig_click.gd middle()): a press counts
## how long it is held; let go within `hold` it is a tap and pings a highlight where the crosshair points;
## held for `hold` the emoji wheel opens round the crosshair and the mouse (or a pad's right stick)
## steers its pointer instead of turning the view; let go, the chosen emoji is pinged there, nothing for
## a pointer still in the centre. R3 on a pad is the same button (line 8). It works in any session, alone
## too (Q2590), only while the player acts (the mouse captured, no menu, not knocked down: lines 1, 6, 7);
## stopping acting closes the wheel with nothing placed. Its Player calls tick() once a physics frame.
class_name Pinger
extends Node

## The input action (project.godot: the middle mouse button and the pad's R3).
const CLICK_MIDDLE := &"click_middle"

@export var tuning: PingTuning
## The HUD's emoji wheel.
@export var wheel: PingWheel

## How long the middle button has been held (-1: not held, or its press no longer counts).
var _held := -1.0
## How many pings it asked, and how many found nothing to ping (a test reads them).
var asked := 0
var missed := 0


func _ready() -> void:
	if tuning == null:
		tuning = PingTuning.new()


## Whether pinging works here (line 2, Q2590): the level has its Pings.
func can_ping() -> bool:
	return _pings() != null


## Whether the wheel has the mouse now (the view does not turn, line 15).
func steering() -> bool:
	return wheel != null and wheel.is_open()


## The mouse moved by `relative` while the wheel is open (line 11).
func steer(relative: Vector2) -> void:
	wheel.steer(relative)


## A pad's right stick at `dir` while the wheel is open (line 8).
func aim_stick(dir: Vector2) -> void:
	wheel.aim(dir)


## One physics frame: `acting` says whether the player's buttons act now.
func tick(delta: float, acting: bool) -> void:
	if not acting or not can_ping():
		_held = -1.0
		_close()
		return
	if Input.is_action_just_pressed(CLICK_MIDDLE):
		_held = 0.0
		return
	if _held < 0.0:
		return
	if Input.is_action_just_released(CLICK_MIDDLE):
		_held = -1.0
		if wheel != null and wheel.is_open():
			var emoji := _close()
			if emoji >= 0:
				ping(emoji)
		else:
			ping(Pings.HIGHLIGHT)
		return
	_held += delta
	if wheel != null and not wheel.is_open() and _held >= tuning.hold:
		wheel.open()


## Pings what the crosshair points at, with `emoji` (an index into Pings.EMOJIS, or Pings.HIGHLIGHT);
## open space pings nothing and says nothing (line 17).
func ping(emoji: int) -> void:
	var player := get_parent() as Player
	var pings := _pings()
	if player == null or pings == null:
		return
	var h := player.hands()
	var aim := PingAim.find(player, pings.mess, player.eyes(), player.aim_dir(), pings.tuning, player.player_id(),
			h.hand_off_numbers() if h != null else null, player.knockdowns(), [player.get_rid()])
	if aim.is_empty():
		missed += 1
		return
	if String(aim["path"]).length() > Command.TEXT_MAX:
		aim["path"] = ""
	asked += 1
	pings.ping(player.player_id(), aim, emoji)


func _close() -> int:
	return wheel.close() if wheel != null and wheel.is_open() else -1


func _pings() -> Pings:
	var runtime := LevelRuntime.of(self)
	return runtime.pings if runtime != null and is_instance_valid(runtime) else null
