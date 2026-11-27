## The Sock encyclopedia in the house (core/139, docs/architecture/gifts.md "In the house", the old BookMenu): the
## pages over the play view, opened by E while the book is the active Hands item, on this machine for its own player.
## The pages are the reader's own profile (Worlds.profile_of), so every reader sees their own. While open the
## player's input is held and the mouse is free; the world runs on. The arrows, A / D and the wheel turn the
## pages; Esc, E or the close key shuts it; it shuts itself when the book leaves the Hands. It comes back on
## the page it was left at. A child of the book's scene: the book's Carriable asks it (`held_use`).
class_name EncyclopediaMenu
extends CanvasLayer

const PAGE := preload("res://game/ui/encyclopedia/encyclopedia.tscn")
const CANCEL := &"ui_cancel"
const USE := &"interact"
## The keys that turn a page back and on: the walk keys (A / D), the arrows and the wheel.
const BACK: Array[StringName] = [&"move_left", &"ui_left", &"hands_prev"]
const ON: Array[StringName] = [&"move_right", &"ui_right", &"hands_next"]

## The book it reads for.
@export var carriable: Carriable

var player: Player = null
var _page: EncyclopediaPage = null
var _last_page := 0
var _mouse_before := Input.MOUSE_MODE_VISIBLE
## The frame it opened on: the E press that opened it does not shut it.
var _opened_frame := -1
var _by_use := false


func _ready() -> void:
	visible = false
	set_process(false)


func is_open() -> bool:
	return visible


## The pages on show, or null when shut.
func page() -> EncyclopediaPage:
	return _page


## The player's use key while the book is their active item: on their own machine the pages open.
func held_use(by: int) -> bool:
	if not is_inside_tree() or by != multiplayer.get_unique_id():
		return false
	var who := _player_of()
	if who != null:
		open(who)
	return who != null


## Opens over the game for `who` (this machine's player).
func open(who: Player) -> void:
	if visible or who == null:
		return
	player = who
	visible = true
	_opened_frame = Engine.get_process_frames()
	_page = PAGE.instantiate() as EncyclopediaPage
	_page.profile = Worlds.profile_of(self)
	_page.closed.connect(_on_page_closed)
	add_child(_page)
	_page.show_page(_last_page)
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.set_input_blocked(true)
	Sounds.play(&"menu_open")
	set_process(true)


## Shuts it. `by_use`: E shut it; the player gets their input back two physics frames later, so that same
## press does not read the book again (the player reads E as "just pressed" on the next physics frame).
func close(by_use := false) -> void:
	if not visible:
		return
	_by_use = by_use
	if is_instance_valid(_page):
		_page.close()
	else:
		_finish()


func _on_page_closed() -> void:
	if is_instance_valid(_page):
		_last_page = _page.page
	_page = null
	_finish()


func _finish() -> void:
	visible = false
	set_process(false)
	var f := get_viewport().gui_get_focus_owner() if get_viewport() != null else null
	if f != null:
		f.release_focus()
	Input.mouse_mode = _mouse_before
	Sounds.play(&"menu_close")
	var who := player
	if _by_use and is_inside_tree():
		await get_tree().physics_frame
		await get_tree().physics_frame
	_by_use = false
	if who != null and is_instance_valid(who) and not visible:
		who.set_input_blocked(false)


## It shuts itself when the book leaves the reader's Hands (put down, handed over, knocked down).
func _process(_delta: float) -> void:
	if not visible or carriable == null or not is_instance_valid(carriable):
		return
	var h := carriable.hands()
	if h == null or player == null or h.one_slot_active(player.player_id()) != carriable:
		close()


## Esc (a pad's B) and E shut it, the keys turn the pages: before anything else hears them.
func _input(event: InputEvent) -> void:
	if not visible or event.is_echo() or not is_instance_valid(_page):
		return
	if event.is_action_pressed(CANCEL):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed(USE) and Engine.get_process_frames() != _opened_frame:
		get_viewport().set_input_as_handled()
		close(true)
	elif _pressed(event, BACK):
		get_viewport().set_input_as_handled()
		_page.step(-1)
	elif _pressed(event, ON):
		get_viewport().set_input_as_handled()
		_page.step(1)


static func _pressed(event: InputEvent, actions: Array[StringName]) -> bool:
	for a in actions:
		if event.is_action_pressed(a):
			return true
	return false


## This machine's player.
func _player_of() -> Player:
	for node in get_tree().get_nodes_in_group(&"local_input"):
		if node is Player and node.multiplayer == multiplayer:
			return node as Player
	return null
