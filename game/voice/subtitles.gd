## The subtitles (core/85, V6): one row per speaker talking now, bottom centre, the highest priority at the
## bottom, the old look made Theme styles (`SubtitleLabel`, `SubtitleIcon`). It shows what `Voices` tells it
## and decides nothing; the text it is given is already through `tr()`.
class_name Subtitles
extends Control

const ROW := preload("res://game/voice/subtitle_row.tscn")

@onready var _rows: VBoxContainer = $Rows


## Shows `text` on the row of `channel` (made when it is new), with `icon` (null: the plain disc).
func show_line(channel: StringName, priority: int, icon: Texture2D, text: String) -> void:
	var row := row_of(channel)
	if row == null:
		row = ROW.instantiate() as SubtitleRow
		row.channel = channel
		_rows.add_child(row)
	row.priority = priority
	row.set_content(icon, text)
	_stack()


## Takes the row of `channel` away.
func clear(channel: StringName) -> void:
	var row := row_of(channel)
	if row != null:
		_rows.remove_child(row)
		row.queue_free()


func clear_all() -> void:
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()


## The row of `channel`, or null.
func row_of(channel: StringName) -> SubtitleRow:
	for row in _rows.get_children():
		if (row as SubtitleRow).channel == channel and not row.is_queued_for_deletion():
			return row as SubtitleRow
	return null


## The text shown for `channel`, "" for none.
func text_of(channel: StringName) -> String:
	var row := row_of(channel)
	return "" if row == null else row.text()


## How many rows show.
func row_count() -> int:
	var n := 0
	for row in _rows.get_children():
		if not row.is_queued_for_deletion():
			n += 1
	return n


## Rows by priority, the highest last (at the bottom).
func _stack() -> void:
	var rows: Array[Node] = _rows.get_children()
	rows.sort_custom(func(a: Node, b: Node) -> bool: return (a as SubtitleRow).priority < (b as SubtitleRow).priority)
	for i in rows.size():
		_rows.move_child(rows[i], i)
