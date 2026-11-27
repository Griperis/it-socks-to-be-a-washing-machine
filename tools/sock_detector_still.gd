## assets/26's line-up: the Sock detector's Looks framed as the old game's line-up of it (the old
## make_sock_detector.py through appliance_family.lineup(): a 70 mm lens across a 480 x 400 frame; its face from
## above the grip, its right side, three-quarter; docs/art/sock_detector/final_lineup.png in reference/it-socks).
## `--scene=res://tools/sock_detector_still.tscn`, then the shot hook `sock_detector:<view>`
## (tools/shots/sets/sock-detector.txt).
extends Node3D

## The views: the camera's direction from the model's middle (the old Blender directions turned into Godot's,
## (x, z, -y)): the face from above the grip, the right side, three-quarter.
const VIEWS: Array[Vector3] = [Vector3(0.0, 1.0, 0.45), Vector3(1.0, 0.3, 0.0), Vector3(0.75, 0.75, 0.8)]
## The model's middle and the camera's distance (its bounding sphere, radius 0.12 m, filling the frame as the old).
const CENTRE := Vector3(0.0, 0.019, -0.002)
const DISTANCE := 0.55

@onready var _camera: Camera3D = $Camera


## Frames view `index` of VIEWS.
func show_view(index: int) -> void:
	_camera.position = CENTRE + VIEWS[index].normalized() * DISTANCE
	var up := Vector3.UP if absf(VIEWS[index].normalized().y) < 0.95 else Vector3.FORWARD
	_camera.look_at(CENTRE, up)
