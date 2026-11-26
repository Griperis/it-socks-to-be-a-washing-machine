## The Gifts station's shelf (core/137, Q2337): one GiftRow per Collection a present can be wrapped in
## (`Collections.shown()`), built when the station enters the tree, so a new Collection or piece file appears with
## no other change. Rows go `row_pitch` apart along +z, `per_column` to a column, columns `column_pitch` apart.
class_name GiftShelf
extends Node3D

const ROW := preload("res://game/zoo/gifts/gift_row.tscn")

@export var row_pitch := 1.0
@export var per_column := 8
@export var column_pitch := 5.5

var _rows: Dictionary[StringName, GiftRow] = {}


func _enter_tree() -> void:
	if _rows.is_empty():
		build()


## The row of Collection `id`, or null.
func row_of(id: StringName) -> GiftRow:
	return _rows.get(id)


func build() -> void:
	var i := 0
	for c in Collections.shown():
		var row := ROW.instantiate() as GiftRow
		row.position = Vector3(float(i / per_column) * column_pitch, 0.0, float(i % per_column) * row_pitch)
		add_child(row)
		row.fill(c)
		_rows[c.id] = row
		i += 1
