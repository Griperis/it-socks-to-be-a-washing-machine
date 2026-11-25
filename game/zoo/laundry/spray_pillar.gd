## The Laundry station's Spray pillar (core/89): used with the use key (E), it plays the station's
## SockSpray from the Porthole marker out along the marker's forward. Looks only: it asks nothing of
## the Host and writes no state, so every player of the zoo sees their own spray (the real First
## wash plays it on every machine from one Host answer, core/94).
class_name SprayPillar
extends Part

@export var spray: SockSpray
## The door's middle (a Marker3D): the spray leaves it along its forward (-Z).
@export var porthole: Marker3D
## How high the floor is, in the station's space.
@export var floor_height := 0.0 # placeholder: the station's pad is flat at 0


func use(_by: int) -> void:
	if spray == null or porthole == null:
		return
	var forward := -porthole.global_basis.z
	spray.play(porthole.global_position, forward, (owner as Node3D).to_global(Vector3(0.0, floor_height, 0.0)).y)


func prompt_title() -> String:
	return "Spray Socks"


## Nothing is ever asked of the pillar.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
