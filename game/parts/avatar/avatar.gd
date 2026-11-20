## A player's body as the other machines see it: a capsule at the pose its player sends. Its name is
## the player's id, and that player is its multiplayer authority, set in _enter_tree() on every
## machine before the Sync child enters the tree. The Sync (a MultiplayerSynchronizer) carries
## pose_position and pose_yaw from the owner to everyone else 20 times a second, unreliably: a
## pose changes every frame, the next one replaces a lost one, and a lost packet never holds up
## the Commands (which are reliable). A late Guest gets the pose with the spawn.
## On the owner's own machine it is hidden and copies `follow`, the local player's body.
class_name Avatar
extends Node3D

## How fast another player's copy glides toward the newest pose, per second.
const GLIDE := 15.0

@export_group("Pose")
## Where its player stands, as the owner sent it (under Players, which sits at the origin).
@export var pose_position := Vector3.ZERO
## Its player's turn about the up axis, in radians.
@export var pose_yaw := 0.0
@export_group("")

## On the owner's machine: the local player's body this avatar copies every frame. Set by Avatars.
var follow: Node3D


func _enter_tree() -> void:
	set_multiplayer_authority(String(name).to_int())


## A spawn sets the pose before _ready: stand there at once instead of gliding from the origin.
func _ready() -> void:
	_snap()


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		if follow != null:
			pose_position = follow.global_position
			pose_yaw = follow.global_rotation.y
		# The owner's own copy is hidden and only stands where the pose is: no glide, and no
		# interpolation reset (that is for a jump someone sees).
		if pose_position.is_finite() and is_finite(pose_yaw):
			position = pose_position
			rotation.y = pose_yaw
		return
	# A pose comes from another machine: one that is not a finite number is ignored.
	if not pose_position.is_finite() or not is_finite(pose_yaw):
		return
	# Smoothing: the place a game replaces (buffered interpolation, animation from measured speed).
	# This one only glides toward the newest pose; it does not predict.
	var weight := 1.0 - exp(-GLIDE * delta)
	position = position.lerp(pose_position, weight)
	rotation.y = lerp_angle(rotation.y, pose_yaw, weight)


## Jumps to the pose. With physics interpolation on, a jump needs reset_physics_interpolation().
func _snap() -> void:
	if not pose_position.is_finite() or not is_finite(pose_yaw):
		return
	position = pose_position
	rotation.y = pose_yaw
	reset_physics_interpolation()
