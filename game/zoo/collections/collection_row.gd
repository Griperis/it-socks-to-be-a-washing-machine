## One row of the Collections station (core/125): a Collection's icon, name, colour, Cabinet name, the three wrapping
## colours, its place in the unlock rule and whether it is held back. Filled from its file by `fill()`.
class_name CollectionRow
extends Node3D

@export var icon: Sprite3D
@export var name_label: Label3D
@export var colour_swatch: MeshInstance3D
@export var cabinet_label: Label3D
@export var paper_swatch: MeshInstance3D
@export var ink_swatch: MeshInstance3D
@export var bow_swatch: MeshInstance3D
@export var place_label: Label3D
@export var held_label: Label3D
## The side of the icon's picture, metres.
@export var icon_size := 0.4


## Shows `c`; `place` is "start", "unlock 3" or "".
func fill(c: SockCollection, place: String) -> void:
	name = String(c.id)
	icon.texture = c.icon
	if c.icon != null:
		icon.pixel_size = icon_size / maxf(c.icon.get_width(), 1.0)
	name_label.text = c.name
	cabinet_label.text = c.cabinet_name
	_paint(colour_swatch, c.colour)
	_paint(paper_swatch, c.paper_colour())
	_paint(ink_swatch, c.ink_colour())
	_paint(bow_swatch, c.bow_colour())
	place_label.text = place
	held_label.visible = c.held_back


func _paint(swatch: MeshInstance3D, colour: Color) -> void:
	(swatch.material_override as StandardMaterial3D).albedo_color = colour
