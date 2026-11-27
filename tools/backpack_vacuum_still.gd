## assets/25's line-up: the Backpack vacuum's Looks framed as the old game's stills of it (the old
## appliance_family.lineup(): a 70 mm lens on a portrait frame; reference/it-socks
## assets/vacuum_devices/backpack_vacuum_lineup.png and make_backpack_vacuum.py still()): front, three-quarter, the
## right side and three-quarter from behind lying, then the dial close up empty and at 0.6, the old second pose (the
## nozzle lifted out of its clips, the needle full) and worn on an Avatar's back. The clips pose it.
## `--scene=res://tools/backpack_vacuum_still.tscn`, then the shot hook `backpack_vacuum:<view>`
## (tools/shots/sets/backpack-vacuum.txt).
extends Node3D

## The views: the camera's direction from `at` (the old Blender directions turned into Godot's: front is +Z), its
## distance, the Looks clip and where it is seeked (`fill` after the pose clip), whether the nozzle is lifted out of its
## clips (the old still's second pose) and whether it is worn on the Avatar.
const VIEWS: Array[Dictionary] = [
	{"dir": Vector3(0.0, 0.18, 1.0)},
	{"dir": Vector3(0.75, 0.45, 1.0)},
	{"dir": Vector3(1.0, 0.15, 0.0)},
	{"dir": Vector3(-0.7, 0.4, -1.0)},
	{"dir": Vector3(1.0, 0.05, 0.15), "at": Vector3(0.204, 0.405, 0.02), "distance": 0.45},
	{"dir": Vector3(1.0, 0.05, 0.15), "at": Vector3(0.204, 0.405, 0.02), "distance": 0.45, "fill": 0.6},
	{"dir": Vector3(0.75, 0.45, 1.0), "fill": 1.0, "lifted": true},
	{"dir": Vector3(0.75, 0.3, 1.0), "at": Vector3(0.0, 0.85, 0.15), "distance": 4.4, "worn": true},
]
## The model's middle and the camera's distance for the whole backpack (straps and nozzle within the frame).
const CENTRE := Vector3(0.02, 0.3, 0.0)
const DISTANCE := 1.9
## Worn: the Looks' origin from the wearer's feet (the old WORN_AT), unturned.
const WORN_AT := Vector3(0.0, 0.52, 0.43)
## The old still's lift of the nozzle out of its clips (Blender (0.12, -0.06, 0.16)).
const LIFT := Vector3(0.12, 0.16, 0.06)

@onready var _camera: Camera3D = $Camera
@onready var _looks: Node3D = $Looks
@onready var _avatar: Node3D = $Avatar


## Frames view `index` of VIEWS and poses the Looks for it.
func show_view(index: int) -> void:
	var view: Dictionary = VIEWS[index]
	var at: Vector3 = view.get("at", CENTRE)
	_camera.position = at + (view["dir"] as Vector3).normalized() * float(view.get("distance", DISTANCE))
	_camera.look_at(at)
	var worn: bool = view.get("worn", false)
	_avatar.visible = worn
	_looks.position = WORN_AT if worn else Vector3.ZERO
	var player := _looks.get_node(^"AnimationPlayer") as AnimationPlayer
	player.play(&"worn" if worn else &"lying")
	player.advance(0.0)
	if view.has("fill"):
		player.play(&"fill")
		player.seek(float(view["fill"]), true)
		player.pause()
	if view.get("lifted", false):
		var nozzle := _looks.get_node(^"Model/Nozzle") as Node3D
		nozzle.position += LIFT
