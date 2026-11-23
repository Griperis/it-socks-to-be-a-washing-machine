## A box no generated Sock may touch (core/52, Q2527), placed by hand: a doorway, a path, a spot to keep
## clear. Its origin is its middle. A child of a SockGenerator (at any depth); in the editor it draws
## itself as a translucent red box.
@tool
class_name SockExclusion
extends Node3D

## The box's full size.
@export var size := Vector3(1.0, 2.0, 1.0):
	set(value):
		size = value.max(Vector3(0.05, 0.05, 0.05))
		_changed()

var _box: MeshInstance3D


func _enter_tree() -> void:
	set_notify_transform(true)
	if Engine.is_editor_hint():
		show_box(true)


## The box as [its full size, its middle's transform in the level].
func box() -> Array:
	return [size, global_transform]


## Shows or hides the translucent box (the editor always; a shot of the preview asks).
func show_box(on: bool) -> void:
	if on and _box == null:
		_box = SockPreview.box_mesh(size, SockPreview.EXCLUSION_COLOUR)
		add_child(_box, false, INTERNAL_MODE_BACK)
	if _box != null:
		_box.visible = on
		(_box.mesh as BoxMesh).size = size


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_changed()


func _changed() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	show_box(true)
	var gen := SockGenerator.of(self)
	if gen != null:
		gen.preview_later()
