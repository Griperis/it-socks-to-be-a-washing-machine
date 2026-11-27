## assets/24's line-up: the Sock vacuum's Looks framed as the old game's line-up of it (the old
## appliance_family.lineup(): a 70 mm lens on a 360 x 420 frame, the model's bounding sphere filling 1.08 of it;
## front, three-quarter, the right side and three-quarter from behind; docs/art/sock_vacuum/final_lineup.png in
## reference/it-socks), then the nozzle's pod close up, the pour, the full gauge with the suction's streaks and
## motes, and the hose at rest and in its tug. The clips pose it.
## `--scene=res://tools/sock_vacuum_still.tscn`, then the shot hook `sock_vacuum:<view>`
## (tools/shots/sets/sock-vacuum.txt).
extends Node3D

## The views: the camera's direction from `at` (Blender's line-up turned into Godot's: front is +Z), its distance,
## the Looks clip and where it is seeked, how high the Looks is lifted (the pour is a carried container's), whether
## the suction shows and whether the hose is shown instead (its port end, then its middle, from above).
const VIEWS: Array[Dictionary] = [
	{"dir": Vector3(0.0, 0.18, 1.0)},
	{"dir": Vector3(0.75, 0.45, 1.0)},
	{"dir": Vector3(1.0, 0.15, 0.0)},
	{"dir": Vector3(-0.7, 0.4, -1.0)},
	{"dir": Vector3(-1.0, 0.35, 0.45), "at": Vector3(-0.31, 0.45, 0.0), "distance": 1.1},
	{"dir": Vector3(1.0, 0.25, 0.35), "clip": &"pour", "seek": 0.25, "lift": 0.5, "at": Vector3(-0.04, 0.75, 0.1)},
	{"dir": Vector3(-0.8, 0.35, 1.0), "clip": &"fill", "seek": 1.0, "suck": true, "at": Vector3(-0.1, 0.3, 0.45),
			"distance": 2.4},
	{"dir": Vector3(0.5, 1.0, 0.2), "hose": true, "at": Vector3(0.0, 0.0, -0.45), "distance": 1.2},
	{"dir": Vector3(0.5, 1.0, 0.2), "hose": true, "at": Vector3(0.0, 0.0, -2.5), "distance": 1.6, "tug": 0.0167},
]
## The model's middle and the camera's distance for the whole container (its bounding sphere, radius 0.5 m, at
## 1.08 of a 28.8 degree vertical field: the old 70 mm lens on a portrait frame).
const CENTRE := Vector3(-0.04, 0.35, -0.02)
const DISTANCE := 2.1
## The nozzle as if held for the suction's view: in front of the container, its mouth aimed 64 degrees down and
## forward at the floor 0.7 m ahead, where the motes rise (the old moved their patch onto the holder's floor).
const HELD := Transform3D(Basis(Vector3.RIGHT, -1.117011), Vector3(-0.1, 0.6, 0.55))

@onready var _camera: Camera3D = $Camera
@onready var _looks: Node3D = $Looks
@onready var _hose: Node3D = get_node_or_null(^"Hose") as Node3D


## Frames view `index` of VIEWS and poses the Looks (or the hose) for it.
func show_view(index: int) -> void:
	var view: Dictionary = VIEWS[index]
	var at: Vector3 = view.get("at", CENTRE)
	_camera.position = at + (view["dir"] as Vector3).normalized() * float(view.get("distance", DISTANCE))
	_camera.look_at(at)
	var hose_view: bool = view.get("hose", false)
	_looks.visible = not hose_view
	_looks.position.y = float(view.get("lift", 0.0))
	if _hose != null:
		_hose.visible = hose_view
		var tug := _hose.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
		if tug != null and view.has("tug"):
			tug.play(&"tug")
			tug.seek(float(view["tug"]), true)
			tug.pause()
	var player := _looks.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	if player != null and view.has("clip"):
		player.play(view["clip"] as StringName)
		player.seek(float(view["seek"]), true)
		player.pause()
	if view.get("suck", false):
		(_looks.get_node(^"Tip/Model/Nozzle") as Node3D).transform = HELD
		for path: NodePath in [^"Tip/Model/Nozzle/NozzleMouth/Streaks", ^"Tip/Model/Nozzle/NozzleMouth/Motes"]:
			(_looks.get_node(path) as GPUParticles3D).emitting = true
