## An opened present's last second on a machine that is not the opener's (core/138, docs/architecture/gifts.md
## "Opening"): a box Looks wrapped in the present's Collection rides its carrier's hold point and plays the Looks'
## `open` clip (the old wobble, crouch, hop, the lid's flight, the shrink and the 28-speck burst), scaled to
## PresentTuning.shake by its speed, with the `gift_rattle` at the box; then it frees itself. Looks only: the save
## and the snapshot never see it.
class_name PresentOpening
extends Node3D

const OPEN := &"open"
const SLOT := preload("res://game/gifts/present_hold.tres")
## The shake's length the `open` clip is keyed at (its pop comes at this second).
const KEYED_SHAKE := 1.0
## Where the rattle sounds from, over the box's underside.
const RATTLE_UP := 0.15

## The Hands whose body frame of `by` it follows (null: it stays where it was put).
var hands: Hands
## The carrier's peer.
var by := 0

@onready var _looks: Node3D = $Looks
@onready var _anim: AnimationPlayer = $Looks/AnimationPlayer


## Starts the opening of a present of Collection `collection` carried by `carrier` in `level_hands`, first drawn
## at `at` (global); call it once it is in the tree.
func start(level_hands: Hands, carrier: int, collection: StringName, at: Transform3D, tuning: PresentTuning) -> void:
	hands = level_hands
	by = carrier
	global_transform = at
	_follow()
	var col := Collections.of(collection)
	if col != null:
		Present.wrap_looks(_looks, col, tuning)
	_anim.speed_scale = KEYED_SHAKE / maxf(tuning.shake, 0.01)
	_anim.play(OPEN)
	_anim.animation_finished.connect(func(_clip: StringName) -> void: queue_free(), CONNECT_ONE_SHOT)
	Sounds.play_at(&"gift_rattle", global_position + Vector3.UP * RATTLE_UP)


## Whether the box has popped yet.
func popped() -> bool:
	return not _anim.is_playing() or _anim.current_animation_position >= KEYED_SHAKE


func _process(_delta: float) -> void:
	_follow()


## Rides the carrier's hold point as this machine draws their body.
func _follow() -> void:
	if hands == null or not is_instance_valid(hands):
		return
	var body := hands.body_frame(by)
	if not body.is_empty():
		global_transform = SLOT.pose(body["feet"], float(body["yaw"]), float(body["drop"]))
