## assets/28's line-up: the Radio's Looks framed as the old game's line-up of it (the old
## appliance_family.lineup(): a 70 mm lens on a 300 x 340 frame, the model's bounding sphere filling 1.08 of it;
## front, three-quarter, the right side and three-quarter from behind; docs/art/radio/final_lineup.png in
## reference/it-socks), then the face close up off and on with the needle at a channel's mark. The clips pose it.
## `--scene=res://tools/radio_still.tscn`, then the shot hook `radio:<view>` (tools/shots/sets/radio.txt).
extends Node3D

## The views: the camera's direction from `at` (Blender's line-up turned into Godot's: front is +Z), its distance,
## the glow clip, and where the `dial` clip is seeked (the needle's share of its travel).
const VIEWS: Array[Dictionary] = [
	{"dir": Vector3(0.0, 0.18, 1.0)},
	{"dir": Vector3(0.75, 0.45, 1.0)},
	{"dir": Vector3(1.0, 0.15, 0.0)},
	{"dir": Vector3(-0.7, 0.4, -1.0)},
	{"dir": Vector3(0.0, 0.1, 1.0), "at": Vector3(0.0, 0.08, 0.05), "distance": 0.58, "glow": &"off", "dial": 0.0},
	{"dir": Vector3(0.0, 0.1, 1.0), "at": Vector3(0.0, 0.08, 0.05), "distance": 0.58, "glow": &"on", "dial": 0.5},
]
## The Looks' middle and the camera's distance for the whole radio (its bounding sphere at 1.5 times, radius
## 0.155 m, at 1.08 of a 28.8 degree vertical field: the old 70 mm lens on a portrait frame).
const CENTRE := Vector3(0.0, 0.081, -0.006)
const DISTANCE := 0.65

@onready var _camera: Camera3D = $Camera
@onready var _looks: Node3D = $Looks


## Frames view `index` of VIEWS and poses the Looks for it.
func show_view(index: int) -> void:
	var view: Dictionary = VIEWS[index]
	var at: Vector3 = view.get("at", CENTRE)
	_camera.position = at + (view["dir"] as Vector3).normalized() * float(view.get("distance", DISTANCE))
	_camera.look_at(at)
	var player := _looks.get_node(^"AnimationPlayer") as AnimationPlayer
	if view.has("glow"):
		player.play(view["glow"] as StringName)
		player.seek(0.05, true)
		player.pause()
	if view.has("dial"):
		# The dial clip moves only the needle, so the glow just posed stays.
		player.play(&"dial")
		player.seek(float(view["dial"]), true)
		player.pause()
