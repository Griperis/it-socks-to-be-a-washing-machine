## assets/27's line-up: the TV's Looks framed as the old game's line-up of it (the old
## appliance_family.lineup(): a 70 mm lens on a 480 x 420 frame, the model's bounding sphere filling 1.08 of it;
## front, three-quarter, the right side and three-quarter from behind; docs/art/tv/final_lineup.png in
## reference/it-socks), then the panel close up posed by the Looks' clips: off (collapsing to its line), static, on (with a stand-in picture
## in the glass's feed, where TvScreen's SubViewport will go), and the standby lamp close up while on.
## `--scene=res://tools/tv_still.tscn`, then the shot hook `tv:<view>` (tools/shots/sets/tv.txt).
extends Node3D

## The views: the camera's direction from `at` (Blender's line-up turned into Godot's: front is +Z), its distance,
## the clip that poses it and the time it is seeked to.
const VIEWS: Array[Dictionary] = [
	{"dir": Vector3(0.0, 0.18, 1.0)},
	{"dir": Vector3(0.75, 0.45, 1.0)},
	{"dir": Vector3(1.0, 0.15, 0.0)},
	{"dir": Vector3(-0.7, 0.4, -1.0)},
	{"dir": Vector3(0.0, 0.1, 1.0), "at": PANEL, "distance": 2.6, "clip": &"off", "time": 0.15},
	{"dir": Vector3(0.0, 0.1, 1.0), "at": PANEL, "distance": 2.6, "clip": &"static", "time": 0.4},
	{"dir": Vector3(0.0, 0.1, 1.0), "at": PANEL, "distance": 2.6, "clip": &"on", "time": 0.25},
	{"dir": Vector3(0.0, 0.1, 1.0), "at": LAMP, "distance": 0.25, "clip": &"on", "time": 0.25},
]
## The Looks' middle and the camera's distance for the whole TV (its bounding sphere, radius 0.99 m, at 1.08 of a
## 28.8 degree horizontal field: the old 70 mm lens on a landscape frame).
const CENTRE := Vector3(0.0, 0.61, -0.005)
const DISTANCE := 4.17
## The panel's middle and the standby lamp in its chin (Godot space; make_tv.py).
const PANEL := Vector3(0.0, 0.89, 0.0)
const LAMP := Vector3(0.0, 0.576, -0.02)

@export var stand_in_picture: Texture2D

@onready var _camera: Camera3D = $Camera
@onready var _looks: Node3D = $Looks


## Frames view `index` of VIEWS and poses the Looks for it.
func show_view(index: int) -> void:
	var view: Dictionary = VIEWS[index]
	var at: Vector3 = view.get("at", CENTRE)
	_camera.position = at + (view["dir"] as Vector3).normalized() * float(view.get("distance", DISTANCE))
	_camera.look_at(at)
	if view.has("clip"):
		var glass := _looks.get_node(^"Model/Glass") as MeshInstance3D
		(glass.material_override as ShaderMaterial).set_shader_parameter(&"feed", stand_in_picture)
		var player := _looks.get_node(^"AnimationPlayer") as AnimationPlayer
		# From on, so off collapses the picture and on and static open it as they would from the knob.
		# advance(), not seek(): the clips' power track captures the value it starts from, as the knob plays them.
		if view["clip"] == &"off":
			player.play(&"on")
			player.advance(0.25)
		player.play(view["clip"] as StringName)
		player.advance(float(view["time"]))
		player.pause()
