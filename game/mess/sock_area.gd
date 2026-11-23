## A box a level designer drops over a room or a floor (core/52, Q2518): the Sock generator finds every
## landing place under it by itself (open floor, furniture tops, insides, under-gaps; furniture inside
## it joins automatically) and lays this area's Pairs there. Its origin is the middle of its bottom face,
## which sits on the floor it covers; it turns about up only. A child of a SockGenerator (at any depth).
## In the editor it draws itself as a translucent box and the generator draws the landing points.
@tool
class_name SockArea
extends Node3D

## The four kinds of landing place (and a SockTrail's): what the preview tints and the weights name.
enum Kind { FLOOR, TOP, INSIDE, UNDER, TRAIL }

## The box: its width (x), height (y, up from the floor) and depth (z).
@export var size := Vector3(4.0, 2.4, 4.0):
	set(value):
		size = value.max(Vector3(0.1, 0.1, 0.1))
		_changed()
## How many Pairs this area lays (Q2520): split over its places by each place's size times its kind's weight.
@export_range(0, 2000, 1) var pairs := 20:
	set(value):
		pairs = value
		_changed()
## The share of its Socks laid hidden, inside and under furniture (Q2521); the rest on open floor and tops.
@export_range(0.0, 1.0, 0.01) var hidden_share := 0.3:
	set(value):
		hidden_share = value
		_changed()
## Each kind's weight (a furniture piece may override its own with the metadata `sock_weight`).
@export_range(0.0, 10.0, 0.05) var floor_weight := 1.0:
	set(value):
		floor_weight = value
		_changed()
@export_range(0.0, 10.0, 0.05) var top_weight := 1.0:
	set(value):
		top_weight = value
		_changed()
@export_range(0.0, 10.0, 0.05) var inside_weight := 1.0:
	set(value):
		inside_weight = value
		_changed()
@export_range(0.0, 10.0, 0.05) var under_weight := 1.0:
	set(value):
		under_weight = value
		_changed()
## Its open floor Socks pile into Heaps by the old roll-down rule (Q2526); otherwise they lie flat and spaced.
@export var heap := false:
	set(value):
		heap = value
		_changed()
## Where its Socks may not land (Q2527): the old rules as numbers.
@export var rules: SockAreaRules = preload("res://game/mess/sock_area_rules.tres"):
	set(value):
		rules = value
		_changed()

## The editor's translucent box (an internal child, never saved).
var _box: MeshInstance3D


func _enter_tree() -> void:
	set_notify_transform(true)
	if Engine.is_editor_hint():
		show_box(true)


## The weight of places of `kind` in this area.
func weight_of(kind: Kind) -> float:
	match kind:
		Kind.FLOOR:
			return floor_weight
		Kind.TOP:
			return top_weight
		Kind.INSIDE:
			return inside_weight
		Kind.UNDER:
			return under_weight
	return 1.0


## Whether level point `p` lies in the box.
func has_point(p: Vector3) -> bool:
	var local := global_transform.affine_inverse() * p
	return absf(local.x) <= size.x * 0.5 and absf(local.z) <= size.z * 0.5 and local.y >= -0.01 and local.y <= size.y


## The box as [its full size, its middle's transform in the level].
func box() -> Array:
	return [size, global_transform * Transform3D(Basis.IDENTITY, Vector3(0.0, size.y * 0.5, 0.0))]


## Shows or hides the translucent box (the editor always; a shot of the preview asks).
func show_box(on: bool) -> void:
	if on and _box == null:
		_box = SockPreview.box_mesh(size, SockPreview.AREA_COLOUR)
		add_child(_box, false, INTERNAL_MODE_BACK)
	if _box != null:
		_box.visible = on
		(_box.mesh as BoxMesh).size = size
		_box.position = Vector3(0.0, size.y * 0.5, 0.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_changed()


## The editor: the box follows and the generator's preview is drawn again.
func _changed() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	show_box(true)
	var gen := SockGenerator.of(self)
	if gen != null:
		gen.preview_later()
