## The Wardrobe in the house (core/142, docs/architecture/wardrobe.md "The Wardrobe page", the old WardrobeMenu):
## the Wardrobe page over the play view, opened by the Wardrobe Station for this machine's player. While open the
## player's input is held and the mouse is free (as under the Upgrade menu, core/129); the world runs on;
## `menu_open` and `menu_close` play. Esc (a pad's B), E or the close key shuts it.
class_name WardrobeMenu
extends CanvasLayer

signal opened
signal closed

const CANCEL := &"ui_cancel"
const USE := &"interact"

var player: Player = null

var _mouse_before := Input.MOUSE_MODE_VISIBLE
## The frame it opened on: the E press that opened it does not shut it.
var _opened_frame := -1

@onready var _page: WardrobePage = %Page


func _ready() -> void:
	visible = false
	_page.closed.connect(close)


func is_open() -> bool:
	return visible


## The page.
func page() -> WardrobePage:
	return _page


## Opens over the game for `who` (this machine's player), showing the page of the player on `peer` from
## `roster`, asking through `parts`.
func open(who: Player, roster: Roster, parts: Parts, peer: int) -> void:
	if visible or who == null or roster == null:
		return
	player = who
	visible = true
	_opened_frame = Engine.get_process_frames()
	_page.bind(roster, parts, peer)
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.set_input_blocked(true)
	Sounds.play(&"menu_open")
	if PadFocus.pad_used:
		_page.focus_first()
	opened.emit()


## Shuts it. `by_use`: E shut it; the player is given back their input two physics frames later, so that same
## press does not use the wardrobe again (the player reads E as "just pressed" on the next physics frame).
func close(by_use := false) -> void:
	if not visible:
		return
	visible = false
	_page.unbind()
	var f := get_viewport().gui_get_focus_owner() if get_viewport() != null else null
	if f != null:
		f.release_focus()
	Input.mouse_mode = _mouse_before
	Sounds.play(&"menu_close")
	closed.emit()
	var who := player
	if by_use:
		await get_tree().physics_frame
		await get_tree().physics_frame
	if who != null and is_instance_valid(who) and not visible:
		who.set_input_blocked(false)


## Esc, a pad's B or E shuts it before anything else hears it.
func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed(CANCEL):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed(USE) and Engine.get_process_frames() != _opened_frame:
		get_viewport().set_input_as_handled()
		close(true)
