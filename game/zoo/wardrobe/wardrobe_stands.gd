## The Wardrobe station's stands (core/128), built from the pieces' folder at load (Q2337): every piece of
## `Wardrobe.all()` worn by its own AvatarLooks, in its slot's row order, in rows of `columns` from the
## slot's marker (a child of this node named after the slot). A new piece file shows here with no other change.
class_name WardrobeStands
extends Node3D

## The markers each slot's stands start from, in the order of `WardrobePiece.Slot`.
const MARKERS: Array[StringName] = [&"Hats", &"Clothes", &"Socks", &"Trails"]

## One stand.
@export var stand: PackedScene
## Stands in a row, and how far apart along it (x) and between rows (z) per slot.
@export_range(1, 40, 1) var columns := 8
@export var gap := Vector2(0.65, 0.95)
## A Trail's row is deeper: its sample steps behind the creature.
@export var trail_gap := Vector2(0.75, 1.5)


func _ready() -> void:
	for slot: int in MARKERS.size():
		var marker := get_node_or_null(NodePath(String(MARKERS[slot]))) as Node3D
		if marker == null:
			continue
		var g := trail_gap if slot == WardrobePiece.Slot.TRAIL else gap
		var i := 0
		for p in Wardrobe.row(slot as WardrobePiece.Slot):
			var s := stand.instantiate() as PieceStand
			s.position = Vector3(float(i % columns) * g.x, 0.0, floorf(float(i) / float(columns)) * g.y)
			marker.add_child(s)
			s.show_piece(p)
			i += 1


## Every stand, in slot and row order.
func stands() -> Array[PieceStand]:
	var out: Array[PieceStand] = []
	for m: StringName in MARKERS:
		var marker := get_node_or_null(NodePath(String(m)))
		if marker == null:
			continue
		for c: Node in marker.get_children():
			if c is PieceStand:
				out.append(c as PieceStand)
	return out
