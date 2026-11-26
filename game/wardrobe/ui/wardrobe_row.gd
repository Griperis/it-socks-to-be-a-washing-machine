## One slot's row on the Wardrobe page (core/142, docs/architecture/wardrobe.md "The Wardrobe page"): its
## heading over "N/M unlocked", then "<", the name box and ">". It steps through "None" and the pieces the
## page gives it (the owned listed pieces of its slot), wrapping, on a click of an arrow or A / D (the walk keys) on
## a focused arrow; each step says `stepped` with the piece now chosen (&"" for none). The look is the scene's; the page
## fills it (fill()).
class_name WardrobeRow
extends HBoxContainer

signal stepped(slot: WardrobePiece.Slot, piece: StringName)

const NONE := "None"
const COUNT := "%d/%d unlocked"
## The actions that step a row from a focused arrow (A and D).
const LEFT := &"move_left"
const RIGHT := &"move_right"

## The slot it steps through.
@export var slot := WardrobePiece.Slot.HAT
## Its heading ("Hats", "Clothes", "Socks", "Trail").
@export var title := "":
	set(value):
		title = value
		if is_node_ready():
			_heading.text = title

## "None" (&"") first, then the pieces it offers.
var entries: Array[StringName] = [&""]
## Which entry it is on.
var index := 0

@onready var _heading: Label = %Heading
@onready var _count: Label = %Count
@onready var _name: Label = %Name
@onready var _prev: Button = %Prev
@onready var _next: Button = %Next


func _ready() -> void:
	_heading.text = title
	_prev.pressed.connect(step.bind(-1))
	_next.pressed.connect(step.bind(1))
	_prev.gui_input.connect(_key_input.bind(_prev))
	_next.gui_input.connect(_key_input.bind(_next))
	_show()


## Offers `pieces` (after "None"), on `worn` (kept in the list though not offered), with "`have`/`of` unlocked".
func fill(pieces: Array[StringName], worn: StringName, have: int, of: int) -> void:
	entries = [&""]
	entries.append_array(pieces)
	if worn != &"" and not entries.has(worn):
		entries.append(worn)
	index = maxi(entries.find(worn), 0)
	_count.text = COUNT % [have, of]
	_show()


## One entry on (`dir` 1) or back (-1), wrapping; says `stepped` when that is another entry.
func step(dir: int) -> void:
	if entries.size() < 2:
		return
	index = posmod(index + dir, entries.size())
	_show()
	stepped.emit(slot, entries[index])


## The entry it is on (&"" for none).
func piece() -> StringName:
	return entries[index]


## What the name box reads now.
func shown_name() -> String:
	return _name.text


## What the count reads now.
func count_text() -> String:
	return _count.text


## The arrows (the pad's stops; a test clicks them).
func prev_key() -> Button:
	return _prev


func next_key() -> Button:
	return _next


func _show() -> void:
	if not is_node_ready():
		return
	var id := entries[index]
	_name.text = Wardrobe.piece_name(id) if id != &"" else NONE


## The walk keys (A and D unless rebound) on a focused arrow step its row (either arrow, the old WardrobeView);
## only a key: the pad's stick and D-pad keep moving the focus.
func _key_input(event: InputEvent, arrow: Button) -> void:
	if not (event is InputEventKey) or event.is_echo():
		return
	if event.is_action_pressed(LEFT):
		step(-1)
	elif event.is_action_pressed(RIGHT):
		step(1)
	else:
		return
	arrow.accept_event()
