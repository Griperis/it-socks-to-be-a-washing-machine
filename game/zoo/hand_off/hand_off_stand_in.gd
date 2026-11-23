## A Hand-off station's stand-in Teammate (core/42, as Q2468): a real Avatar, a puppet on this machine
## (its name is a peer id no player has), so a Hand-off and a catch can be tried playing alone. It is
## driven only through what a real Teammate sends: its pose. On the Host it asks once, as a Teammate's
## pick does, for the Sock of `holds` once the camera comes near (retrying each second until it holds
## it), so the player has a
## mate to complete there. Knocked down, its pose stays at its ragdoll's feet as KnockStandIn's does.
## The zoo's reach rule finds it in TeammateStandIn's group.
class_name HandOffStandIn
extends Node3D

## Links the wiring check lets stay empty: an empty-handed stand-in holds nothing.
const WIRING_OPTIONAL := ["holds"]

## The stand-in's Avatar.
@export var avatar: Avatar
## Its Player colour and the name on its tag.
@export var colour := Color("e3b448")
@export var tag := "Player"
## The Sock spot whose Sock it takes at the start (empty: it starts empty-handed).
@export var holds: SockSpot
## It takes that Sock only once the camera is this near (as the Avatar station's walker: the zoo's
## other stations and their tests see the Sock lie where its spot puts it).
@export_range(1.0, 1000.0, 0.5, "suffix:m") var wake_range := 8.0

var _held_once := false
var _next_try := 0.0


func _ready() -> void:
	if avatar == null:
		return
	avatar.add_to_group(TeammateStandIn.GROUP)
	if avatar.looks != null:
		avatar.looks.colour = colour
		avatar.looks.player_name = tag


func _physics_process(delta: float) -> void:
	if avatar == null:
		return
	if avatar.is_down():
		var space := avatar.get_parent() as Node3D
		var feet := avatar.ragdoll.floor_under(avatar.ragdoll.feet())
		avatar.pose_position = space.to_local(feet) if space != null else feet
	_take(delta)


## Until it has held the Sock of `holds` once, the Host asks for it once a second.
func _take(delta: float) -> void:
	_next_try -= delta
	if _held_once or _next_try > 0.0 or holds == null or holds.sock < 0 or avatar.held == null:
		return
	var hands := avatar.held.hands
	if hands == null or hands.parts == null or not hands.parts.is_host():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam.global_position.distance_to(global_position) > wake_range:
		return
	if hands.items_of(avatar.peer()).has(holds.sock):
		_held_once = true
		return
	_next_try = 1.0
	hands.pick(avatar.peer(), holds.sock)
