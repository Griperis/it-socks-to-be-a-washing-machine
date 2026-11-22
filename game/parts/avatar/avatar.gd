## A player's body as the other machines see it: the sock creature (its Looks) at the pose its player
## sends. Its name is the player's peer id, and that player is its multiplayer authority, set in
## _enter_tree() on every machine before the Sync child enters the tree. The Sync (a
## MultiplayerSynchronizer) carries the pose (position, yaw, pitch, crouch) from the owner to everyone
## else every network frame, unreliably (Q2223): the next pose replaces a lost one, and a lost packet
## never holds up the Commands (which are reliable). A late Guest gets the pose with the spawn.
##
## On every machine that receives a pose, a pose that is not finite or lies outside the tuning's area
## is dropped in its setter: the old value stays (the Host's copy included, so a forged pose goes no
## further on it). On the owner's own machine the avatar is hidden and copies `follow`, the local
## player's body.
##
## Elsewhere it is a puppet: the drawn position, yaw and pitch ease toward the pose at `follow` a
## second, the crouch at `crouch_follow` (Q2450); a pose further than `snap` from the last one stands
## there at once (Q2451). Its Looks gets the drawn pitch and crouch and the nearest player's eyes (Q2455)
## and derives every motion from them (Q2461). Its colour and name tag come from the Roster (Q2462);
## its held things hang at its Looks' HoldPoint in its worn HeldView (Q2464). It never reads input.
class_name Avatar
extends Node3D

## The group every avatar is in: the Hands find a Guest's eyes there (coop/09, G15).
const GROUP := &"avatars"

@export var tuning: AvatarTuning

@export_group("Pose")
## Where its player stands, as the owner sent it (under Players, which sits at the origin).
@export var pose_position := Vector3.ZERO:
	set(value):
		if not _takes(value.is_finite() and _tuning().holds(value)):
			return
		if value.distance_to(pose_position) > _tuning().snap:
			_jumped = true
		pose_position = value
## Its player's turn about the up axis, in radians.
@export var pose_yaw := 0.0:
	set(value):
		if _takes(is_finite(value)):
			pose_yaw = value
## Its player's look up (+) or down (-), in radians.
@export var pose_pitch := 0.0:
	set(value):
		if _takes(is_finite(value) and absf(value) <= deg_to_rad(_tuning().pitch_limit) + 0.001):
			pose_pitch = value
## 1 while its player crouches, 0 standing.
@export var pose_crouch := 0.0:
	set(value):
		if _takes(is_finite(value) and value >= 0.0 and value <= 1.0):
			pose_crouch = value
@export_group("")

## On the owner's machine: the local player's body this avatar copies every frame. Set by Avatars.
var follow: Node3D
## Who plays: its colour and name come from here. Set by Avatars; null leaves it white and unnamed.
var roster: Roster
## The drawn look pitch (radians) and crouch (0 to 1), easing toward the pose.
var pitch := 0.0
var crouch := 0.0
## How many poses this copy dropped (not finite, or outside the area).
var dropped := 0

## A pose further than `snap` from the last one came: the next frame stands there at once.
var _jumped := false

@onready var looks := get_node_or_null(^"Looks") as AvatarLooks
@onready var held := get_node_or_null(^"Held") as HeldView


func _enter_tree() -> void:
	add_to_group(GROUP)
	set_multiplayer_authority(String(name).to_int())


## A spawn sets the pose before _ready: stand there at once instead of gliding from the origin.
func _ready() -> void:
	if tuning == null:
		tuning = AvatarTuning.new()
	_snap()
	if looks != null:
		looks.seed_idle(str(name))
	if held != null and is_multiplayer_authority():
		# This machine's own player sees their Hands in front of the camera, never here.
		held.queue_free()
		held = null
	if held != null:
		held.me = peer()
		held.anchor = looks.hold_point() if looks != null else self
		held.hands = _find_hands()
	if roster != null:
		roster.changed.connect(_dress)
	_dress()


## Its player's peer id.
func peer() -> int:
	return String(name).to_int()


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		# The owner's own copy is hidden and only stands where the pose is.
		_copy_follow()
		position = pose_position
		rotation.y = pose_yaw
		pitch = pose_pitch
		crouch = pose_crouch
		return
	if _jumped:
		_snap()
	else:
		var k := minf(1.0, tuning.follow * delta)
		position = position.lerp(pose_position, k)
		rotation.y = lerp_angle(rotation.y, pose_yaw, k)
		pitch = lerpf(pitch, pose_pitch, k)
	crouch = move_toward(crouch, pose_crouch, tuning.crouch_follow * delta)
	if looks != null:
		looks.look_pitch = pitch
		looks.set_crouch(crouch)
		looks.watch = nearest_eyes()


## Where the nearest other player's eyes are, within the look range of this body, or null with
## nobody near. Every player has an avatar here (this machine's own too, hidden at its body).
func nearest_eyes() -> Variant:
	var best: Variant = null
	var best_d := tuning.look_range
	var parent := get_parent()
	if parent == null:
		return null
	for node in parent.get_children():
		var other := node as Avatar
		if other == null or other == self or other.is_queued_for_deletion():
			continue
		var d := global_position.distance_to(other.global_position)
		if d <= best_d:
			best_d = d
			best = other.eyes()
	return best


## Where this player's eyes are now, as drawn: the feet, plus the body's height at its crouch, less
## the eyes' distance under the top.
func eyes() -> Vector3:
	var height := lerpf(tuning.stand_height, tuning.crouch_height, crouch)
	return global_position + Vector3.UP * (height - tuning.eye_below_top)


## The owner's copy: the pose is the local body's, as it is now.
func _copy_follow() -> void:
	if follow == null:
		return
	pose_position = follow.global_position
	pose_yaw = follow.global_rotation.y
	var head := follow.get_node_or_null(^"Head") as Node3D  # the Player's look pitch
	if head != null:
		pose_pitch = head.rotation.x
	var player := follow as Player
	if player != null:
		pose_crouch = 1.0 if player.crouching else 0.0


## Stands at the pose at once. With physics interpolation on, a jump needs reset_physics_interpolation().
func _snap() -> void:
	_jumped = false
	position = pose_position
	rotation.y = pose_yaw
	pitch = pose_pitch
	crouch = pose_crouch
	reset_physics_interpolation()
	if looks != null:
		looks.look_pitch = pitch
		looks.set_crouch(crouch)


## Whether a setter takes a new pose value: always on the owner's copy and before the tree (a spawn),
## and on a receiving copy only when `good`.
func _takes(good: bool) -> bool:
	if good or not is_inside_tree() or is_multiplayer_authority():
		return good or not is_inside_tree()
	dropped += 1
	return false


func _tuning() -> AvatarTuning:
	if tuning == null:
		tuning = AvatarTuning.new()
	return tuning


## Its colour and name from the Roster, once its player has an entry there.
func _dress() -> void:
	if looks == null or roster == null:
		return
	var known := not roster.entry_of(peer()).is_empty()
	looks.colour = roster.colour_of(peer()) if known else Color.WHITE
	looks.player_name = roster.name_of(peer()) if known else ""


## The Hands of this avatar's level: with two zoos in one tree, the one whose scene holds this avatar.
func _find_hands() -> Hands:
	var found: Hands = null
	for node in get_tree().get_nodes_in_group(Hands.GROUP):
		var h := node as Hands
		if found == null or (h.owner != null and h.owner.is_ancestor_of(self)):
			found = h
	return found
