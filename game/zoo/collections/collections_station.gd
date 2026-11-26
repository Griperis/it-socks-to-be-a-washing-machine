## The Collections station (core/125, Q2337): one row per `SockCollection` file, built from the folder when the
## station enters the tree, so a new file appears with no other change. Each row shows the place of the Collection
## in `collection_unlocks.tres` ("start", or its number in the order) and "held back".
class_name CollectionsStation
extends Node3D

const ROW := preload("res://game/zoo/collections/collection_row.tscn")
const UNLOCKS := preload("res://game/collections/collection_unlocks.tres")

## The distance between two rows, metres.
@export var row_pitch := 0.5
## Where the rows go.
@export var wall: Node3D

var _rows: Dictionary[StringName, CollectionRow] = {}


func _enter_tree() -> void:
	if not _rows.is_empty() or wall == null:
		return
	build()


## The row of Collection `id`, or null.
func row_of(id: StringName) -> CollectionRow:
	return _rows.get(id)


func build() -> void:
	var y := 0.0
	for c in Collections.all():
		var row := ROW.instantiate() as CollectionRow
		row.position = Vector3(0.0, y, 0.0)
		wall.add_child(row)
		row.fill(c, _place(c.id))
		_rows[c.id] = row
		y -= row_pitch


func _place(id: StringName) -> String:
	if UNLOCKS.start.has(id):
		return "start"
	var at := UNLOCKS.order.find(id)
	return "unlock %d" % (at + 1) if at >= 0 else ""
