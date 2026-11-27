## assets/23's line-up: the wall clock's Looks framed as the old game's line-up of it (the old
## appliance_family.lineup(): a 70 mm lens on a portrait frame, the model's bounding sphere filling 1.08 of it; front,
## three-quarter, the right side and three-quarter from behind, the hands at 10:10; docs/art/clock/final_lineup.png in
## reference/it-socks), then the dial close up at 15:45. The hands are turned as the old Room._show_time turned them.
## `--scene=res://tools/wall_clock_still.tscn`, then the shot hook `wall_clock:<view>` (tools/shots/sets/clock.txt);
## a view `old<n>` shows the old glb instead, when a copy of it sits at OLD (review material only, never committed).
extends Node3D

## A copy of the old game's assets/clock/clock.glb, for the old-beside-port strip.
const OLD := "res://assets/clock/old/clock_old.glb"
## The views: the camera's direction from `at`, its distance and the hour the hands show.
const VIEWS: Array[Dictionary] = [
	{"dir": Vector3(0.0, 0.18, 1.0)},
	{"dir": Vector3(0.75, 0.45, 1.0)},
	{"dir": Vector3(1.0, 0.15, 0.0)},
	{"dir": Vector3(-0.7, 0.4, -1.0)},
	{"dir": Vector3(0.0, 0.0, 1.0), "distance": 0.6, "hour": 15.75},
]
## The clock's middle (its back hangs at HANG, 0.0275 m to the dial side) and the camera's distance for the whole
## clock (its bounding sphere, radius 0.256 m, at 1.08 of a 28.8 degree vertical field).
const HANG := Vector3(0.0, 1.0, 0.0)
const CENTRE := Vector3(0.0, 1.0, 0.0275)
const DISTANCE := 1.08
## The hour of the old line-up.
const LINEUP_HOUR := 10.0 + 10.0 / 60.0

@onready var _camera: Camera3D = $Camera
@onready var _looks: Node3D = $Looks


## Frames view `which` ("<n>", or "old<n>" for the old glb) of VIEWS and turns the hands to its hour.
func show_view(which: String) -> void:
	var clock: Node3D = _looks
	if which.begins_with("old"):
		which = which.trim_prefix("old")
		_looks.visible = false
		clock = (load(OLD) as PackedScene).instantiate() as Node3D
		clock.position = HANG
		add_child(clock)
	var view: Dictionary = VIEWS[int(which)]
	var at: Vector3 = view.get("at", CENTRE)
	_camera.position = at + (view["dir"] as Vector3).normalized() * float(view.get("distance", DISTANCE))
	_camera.look_at(at)
	var hour := float(view.get("hour", LINEUP_HOUR))
	(clock.find_child("hour_hand", true, false) as Node3D).rotation.z = -TAU * fposmod(hour, 12.0) / 12.0
	(clock.find_child("minute_hand", true, false) as Node3D).rotation.z = -TAU * fposmod(hour, 1.0)
