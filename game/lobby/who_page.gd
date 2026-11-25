## The "i" page of the Lobby (docs/architecture/lobby.md "Core/66", the old Q1771): a cream page over the Lobby,
## which stays on show behind it veiled at 0.8: "Who was in <World>", one centred name per line (names only,
## no colours: a colour can change), and the close key at its top right; Esc closes it too (the Lobby asks).
class_name WhoPage
extends Control

signal closed

const NAME_ROW := preload("res://game/lobby/who_name.tscn")

@onready var _heading: Label = %Heading
@onready var _names: VBoxContainer = %Names
@onready var _close: CloseButton = %Close


func _ready() -> void:
	_close.pressed.connect(close)
	visible = false


## Opens it for `world_name` with `names`.
func open(world_name: String, names: PackedStringArray) -> void:
	_heading.text = LobbyWords.WHO_HEADING % world_name
	for n in _names.get_children():
		_names.remove_child(n)
		n.queue_free()
	for who in names:
		var l := NAME_ROW.instantiate() as Label
		l.text = who
		_names.add_child(l)
	visible = true
	_close.key().grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## The names as shown, top down.
func shown_names() -> PackedStringArray:
	var out := PackedStringArray()
	for l in _names.get_children():
		if not l.is_queued_for_deletion():
			out.append((l as Label).text)
	return out
