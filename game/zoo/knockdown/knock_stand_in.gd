## The Knockdown station's stand-in Teammate (coop/10, as Q2468): a real Avatar, a puppet on this
## machine (its name is a peer id no player has), so a knockdown and a drag can be tried playing alone.
## It is driven only through what a real Teammate sends: its pose (pose_position, pose_yaw). While it lies
## down its pose stays at its ragdoll's feet, as a real Teammate's machine keeps its body there (K142), so
## it gets up where it lies. The zoo's reach rule finds it in TeammateStandIn's group.
class_name KnockStandIn
extends Node3D

## The stand-in's Avatar.
@export var avatar: Avatar
## Its Player colour (the Roster's third, amber) and the name on its tag.
@export var colour := Color("e3b448")
@export var tag := "Player"


func _ready() -> void:
	if avatar == null:
		return
	avatar.add_to_group(TeammateStandIn.GROUP)
	if avatar.looks != null:
		avatar.looks.colour = colour
		avatar.looks.player_name = tag


func _physics_process(_delta: float) -> void:
	if avatar == null or not avatar.is_down():
		return
	var space := avatar.get_parent() as Node3D
	var feet := avatar.ragdoll.floor_under(avatar.ragdoll.feet())
	avatar.pose_position = space.to_local(feet) if space != null else feet
