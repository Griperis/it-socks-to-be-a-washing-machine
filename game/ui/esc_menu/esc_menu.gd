## The ESC menu (the old session menu; the kit's pause/ template): Esc in play opens it over the game
## and nothing pauses (Q253: the world runs on, only this player freezes). Alone it offers Back to
## title and Quit game, a Host End session (it asks first, Q315), a Guest Leave, each a red exit
## keycap; and Options and Back. Every way out of a World the Host or a player alone keeps saves first
## (Autosave.save_now()). The look is the scene's, on the Theme; all wording is placeholder.
class_name EscMenu
extends CanvasLayer

signal opened
signal closed

## The group whose nodes are told `set_input_blocked(bool)` when the menu opens and closes.
const INPUT_GROUP := &"local_input"
const TOGGLE := &"ui_cancel"
## The title's line after a way out of one's own: none.
const NO_NOTICE := ""
const TITLE := "res://game/ui/title/title.tscn"
const OPTIONS := preload("res://game/ui/options/options.tscn")

@export var autosave: Autosave
@export var session: Session
@export var net: LevelNet

## How a way out leaves the level: func(notice: String). A test swaps it to stay put.
var go_to_title := func(notice: String) -> void: _to_title(notice)
## How Quit game closes the game. A test swaps it to stay put.
var quit_game := func() -> void: get_tree().quit()

var _mouse_before := Input.MOUSE_MODE_VISIBLE
var _options: Control = null

@onready var _menu: Control = %Menu
@onready var _back_to_title: Button = %BackToTitle
@onready var _quit: Button = %QuitGame
@onready var _end_session: Button = %EndSession
@onready var _leave: Button = %Leave
@onready var _options_button: Button = %Options
@onready var _back: CloseButton = %Back
@onready var _ask: Control = %Ask
@onready var _end: Button = %End


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_back_to_title.pressed.connect(back_to_title)
	_quit.pressed.connect(quit)
	_end_session.pressed.connect(_ask_end)
	_end.pressed.connect(end_session)
	_leave.pressed.connect(leave)
	_options_button.pressed.connect(_open_options)
	_back.pressed.connect(_escape)
	if net != null:
		net.ended_to_title.connect(func(text: String) -> void: go_to_title.call(text))


func is_open() -> bool:
	return visible


## Opens over the game: the keys for this machine's part (alone, Host, Guest), the mouse free, the
## player's input held.
func open() -> void:
	if visible:
		return
	var online := session != null and session.is_online()
	var host := online and session.parts.is_host()
	_back_to_title.visible = not online
	_quit.visible = not online
	_end_session.visible = host
	_leave.visible = online and not host
	_show_ask(false)
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group(INPUT_GROUP, &"set_input_blocked", true)
	_first_key().grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	if is_instance_valid(_options):
		_options.queue_free()
	visible = false
	Input.mouse_mode = _mouse_before
	get_tree().call_group(INPUT_GROUP, &"set_input_blocked", false)
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Alone: saves, then the title.
func back_to_title() -> void:
	_save()
	go_to_title.call(NO_NOTICE)


## Alone: saves, then the game closes.
func quit() -> void:
	_save()
	quit_game.call()


## The Host, after its question: saves, ends the session (every Guest goes to its title), then the
## title.
func end_session() -> void:
	_save()
	if session != null:
		session.close()
	go_to_title.call(NO_NOTICE)


## A Guest leaves (nothing to save: only the Host saves), then the title.
func leave() -> void:
	if session != null:
		session.close()
	go_to_title.call(NO_NOTICE)


## Whether End session's question shows.
func asking() -> bool:
	return _ask.visible


func _ask_end() -> void:
	_show_ask(true)


func _show_ask(on: bool) -> void:
	_ask.visible = on
	_menu.visible = not on
	if on:
		_back.key().grab_focus()


func _first_key() -> Button:
	for b: Button in [_back_to_title, _end_session, _leave]:
		if b.visible:
			return b
	return _back.key()


func _save() -> void:
	if autosave != null:
		autosave.save_now()


func _to_title(notice: String) -> void:
	close()
	Worlds.notice = notice
	SceneChanger.change_to(TITLE)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(TOGGLE):
		return
	get_viewport().set_input_as_handled()
	_escape(true)


## Esc, a pad's B and the close key alike: the question goes first, else the menu closes (`toggles`:
## the Esc key also opens it).
func _escape(toggles := false) -> void:
	if asking():
		_show_ask(false)
	elif toggles:
		toggle()
	else:
		close()


func _open_options() -> void:
	if is_instance_valid(_options):
		return
	_options = OPTIONS.instantiate() as Control
	add_child(_options)
