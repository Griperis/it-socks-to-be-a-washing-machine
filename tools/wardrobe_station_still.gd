## assets/20's line-up: the Wardrobe Station's Looks framed as the old game's line-up of it (the old
## tools/blender/make_wardrobe_station.py lineup(): a 50 mm lens on a 300 x 400 frame, the wardrobe filling 1.08 of
## the height; shut from the front, open from three-quarter and from the front, shut from the side and from behind;
## docs/art/wardrobe_station/final_lineup.png in reference/it-socks). The doors are posed by the Looks' own clips.
## `--scene=res://tools/wardrobe_station_still.tscn`, then the shot hook `wardrobe_station:<view>`
## (tools/shots/sets/wardrobe-station.txt).
extends Node3D

## The old views: the camera's direction from the wardrobe's middle (Blender's turned into Godot's: front is +Z) and
## whether the doors stand open.
const VIEWS: Array[Dictionary] = [
	{"dir": Vector3(0.0, 0.25, 1.0), "open": false},
	{"dir": Vector3(0.8, 0.45, 1.0), "open": true},
	{"dir": Vector3(0.0, 0.15, 1.0), "open": true},
	{"dir": Vector3(1.0, 0.2, -0.05), "open": false},
	{"dir": Vector3(-0.7, 0.4, -1.0), "open": false},
]
const HEIGHT := 1.92
const CENTRE := Vector3(0.0, HEIGHT / 2.0, 0.05)
## The camera's distance, fitted to the old picture (the wardrobe about 250 of the frame's 400 px tall) with a 50 mm
## lens on a 36 mm sensor fitted to the frame's width, the Camera's horizontal 39.6 degree fov here.
const DISTANCE := 3.2

@onready var _camera: Camera3D = $Camera
@onready var _player: AnimationPlayer = $Looks/AnimationPlayer


## Frames view `index` of VIEWS and poses the doors for it.
func show_view(index: int) -> void:
	var view: Dictionary = VIEWS[index]
	_camera.position = CENTRE + (view["dir"] as Vector3).normalized() * DISTANCE
	_camera.look_at(CENTRE)
	var clip := &"open" if view["open"] else &"shut"
	_player.play(clip)
	_player.seek(_player.current_animation_length, true)
