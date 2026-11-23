## The Licence page (the old LicenceView, Q339): one scrolling column built at load from `credits`
## (Q2337: a new entry shows with no other change): the game's lines, the first larger, then each
## work by section with its author, licence and a source link, then "Licences" with the engine's and
## Blender's. A link opens in the browser. Each line is a small scene (licence_line.tscn,
## licence_link.tscn) filled here; the look is theirs, on the Theme.
class_name LicencePage
extends Control

signal closed

const LINE := preload("res://game/ui/licence/licence_line.tscn")
const LINK := preload("res://game/ui/licence/licence_link.tscn")
const HEADING := &"Heading2"
const TITLE := &"Heading1"
const BODY := &"InkLabel"
const LICENCES := "Licences"

@export var credits: Credits

## How a link opens: func(url: String). A test swaps it to stay put.
var open_link := func(url: String) -> void: OS.shell_open(url)

@onready var _column: VBoxContainer = %Column
@onready var _back: Button = %Back


func _ready() -> void:
	_back.pressed.connect(close)
	if credits == null:
		return
	for i in credits.game_lines.size():
		_line(credits.game_lines[i], TITLE if i == 0 else BODY, true)
	for section in credits.sections():
		_line(section, HEADING, false)
		for e in credits.entries:
			if e.section != section:
				continue
			_line("%s, by %s (%s)" % [e.what, e.author, e.licence], BODY, false)
			if e.source != "":
				_link(e.source, e.source)
	_line(LICENCES, HEADING, false)
	for i in credits.licence_names.size():
		_link(credits.licence_names[i], credits.licence_links[i] if i < credits.licence_links.size() else "")


## Every line's text, in order (links too).
func lines() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _column.get_children():
		if c is Label:
			out.append((c as Label).text)
		elif c is LinkButton:
			out.append((c as LinkButton).text)
	return out


## The link buttons, in order.
func links() -> Array[LinkButton]:
	var out: Array[LinkButton] = []
	for c in _column.get_children():
		if c is LinkButton:
			out.append(c as LinkButton)
	return out


func close() -> void:
	closed.emit()
	queue_free()


func _line(text: String, variation: StringName, centred: bool) -> void:
	var l := LINE.instantiate() as Label
	l.text = text
	l.theme_type_variation = variation
	if centred:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(l)


func _link(text: String, url: String) -> void:
	var b := LINK.instantiate() as LinkButton
	b.text = text
	b.pressed.connect(func() -> void: open_link.call(url))
	_column.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
