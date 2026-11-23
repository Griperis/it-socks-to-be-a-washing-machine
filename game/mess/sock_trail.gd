## A trail of Socks up a flight of stairs (core/52, Q2528, the old stair trail, Q441): `socks` Socks
## spread evenly from this node (the foot) to `to` (the top, in its own space), each laid across the
## line on whatever the house has under it: flat on a step where the stair piece has treads (house/05,
## Q2530), else on the walking ramp, leaned with it. A child of a SockGenerator (at any depth). Its Socks
## are not part of any area's count. In the editor it draws its line.
@tool
class_name SockTrail
extends Node3D

## The physics layer of a stair piece's treads (its `Treads` body, tools/house_kit_build.gd): thin boxes
## on the steps' tops that only a trail's Socks rest on; the player and the Mess meet the walking ramps.
const LAYER_TREADS := 128

## How many Socks lie on the trail.
@export_range(0, 200, 1) var socks := 6:
	set(value):
		socks = value
		_changed()
## The trail's top, in this node's own space (its foot is the origin).
@export var to := Vector3(0.0, 2.8, -4.0):
	set(value):
		to = value
		_changed()
## How far either side of the line a Sock may lie when the line's own spot has no room.
@export_range(0.0, 2.0, 0.05, "suffix:m") var spread := 0.3:
	set(value):
		spread = value
		_changed()

var _line: MeshInstance3D


func _enter_tree() -> void:
	set_notify_transform(true)
	if Engine.is_editor_hint():
		show_line(true)


## The trail's foot and top in the level.
func ends() -> Array[Vector3]:
	return [global_position, global_transform * to]


## Shows or hides the line (the editor always; a shot of the preview asks).
func show_line(on: bool) -> void:
	if on and _line == null:
		_line = SockPreview.line_mesh(SockPreview.KIND_COLOURS[SockArea.Kind.TRAIL])
		add_child(_line, false, INTERNAL_MODE_BACK)
	if _line != null:
		_line.visible = on
		SockPreview.set_line(_line, Vector3.ZERO, to)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_changed()


func _changed() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	show_line(true)
	var gen := SockGenerator.of(self)
	if gen != null:
		gen.preview_later()
