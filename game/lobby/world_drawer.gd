## The World drawer of the Lobby (docs/architecture/lobby.md "Core/65", Q2582, Q2586, Q2587): a panel
## sliding in over the right of the Lobby, which keeps its layout and takes no click the panel does not
## cover, with every World as a row, the Host's New game, the question before a Delete and the "full"
## page. A view of the Worlds the Host says (LobbyState.worlds): a key only says what was pressed
## (the signals); the Lobby asks the Host's answer. A Guest's drawer is the same list read-only.
class_name WorldDrawer
extends Control

## The Host chose a World's row.
signal choose_world(slot: String)
## The Host pressed New game.
signal new_game_pressed
## The Host answered "Delete" to the question.
signal delete_confirmed(slot: String)
## The Host pressed Invite friends (shown only when the transport can invite).
signal invite_pressed
## The Host moved the New Game's "Pairs per Drawer" slider (debug builds, core/91).
signal pairs_moved(value: int)
## The drawer opened or shut (pressed or set): the pad's route changes with it.
signal open_changed
## The full page was closed without a delete (its close key or Esc).
signal full_closed

const ROW := preload("res://game/lobby/world_row.tscn")

@export var tuning: WorldDrawerTuning = preload("res://game/lobby/world_drawer_tuning.tres")

var _open := false
var _tween: Tween = null
var _rows: Array = []
var _chosen := ""
var _host := false
var _locked := false
var _colour_of := func(_i: int) -> Color: return Color.WHITE
var _delete_slot := ""

@onready var _key: Button = %Key
@onready var _panel: Control = %Panel
@onready var _list: VBoxContainer = %Rows
@onready var _new: Button = %NewGame
@onready var _invite: Button = %Invite
@onready var _pairs: PairsSlider = %Pairs
@onready var _ask: Control = %DeleteAsk
@onready var _ask_question: Label = %Question
@onready var _ask_yes: Button = %AskDelete
@onready var _ask_close: CloseButton = %AskClose
@onready var _full: Control = %Full
@onready var _full_line: Label = %FullLine
@onready var _full_list: VBoxContainer = %FullRows
@onready var _full_close: CloseButton = %FullClose


func _ready() -> void:
	_words()
	_panel.custom_minimum_size.x = tuning.width
	_invite.pressed.connect(invite_pressed.emit)
	_key.pressed.connect(toggle)
	_new.pressed.connect(new_game_pressed.emit)
	_pairs.moved.connect(pairs_moved.emit)
	_ask_yes.pressed.connect(_confirm_delete)
	_ask_close.pressed.connect(func() -> void: _show_ask(false))
	_full_close.pressed.connect(close_full)
	resized.connect(_settle)
	_ask.visible = false
	_full.visible = false
	move_child(_ask, -1)  # the question lies over the full page too
	_settle()


func _words() -> void:
	_key.text = LobbyWords.DRAWER_HEADING
	($Panel/Box/Heading as Label).text = LobbyWords.DRAWER_HEADING
	($Panel/Box/WorldLabel as Label).text = LobbyWords.DRAWER_WORLD
	_new.text = LobbyWords.NEW_GAME
	_invite.text = LobbyWords.INVITE
	($DeleteAsk/Center/Panel/Box/Heading as Label).text = LobbyWords.DELETE_HEADING
	_ask_yes.text = LobbyWords.DELETE
	($Full/Center/Panel/Box/Heading as Label).text = LobbyWords.NEW_GAME_HEADING


## Whether the Host's "Invite friends" key shows (the transport can invite and this is the Host's drawer).
func set_can_invite(on: bool) -> void:
	_invite.visible = on


## The World settings key (the pad's route starts the drawer's column there).
func key() -> Button:
	return _key


## The pad's rows inside the open drawer, top to bottom: each World row's keys, New game, its slider, Invite friends.
## Only the ones on the route (visible and enabled).
func pad_rows() -> Array:
	var out: Array = []
	for row in row_nodes():
		out.append(LobbyPad.live([row.choose_key(), row.delete_key()]))
	out.append(LobbyPad.live([_new]))
	out.append(LobbyPad.live([_pairs.slider()]))
	out.append(LobbyPad.live([_invite]))
	return out.filter(func(r: Variant) -> bool: return not (r as Array).is_empty())


## Whether the drawer is open (or sliding open).
func is_open() -> bool:
	return _open


## Opens or shuts it with the slide from where it is; `instant`: at once (the Lobby's start).
func set_open(on: bool, instant := false) -> void:
	var changed := _open != on
	_open = on
	if changed:
		open_changed.emit.call_deferred()
	if _tween != null:
		_tween.kill()
		_tween = null
	if instant or not is_inside_tree():
		_settle()
		return
	_tween = create_tween()
	_tween.tween_property(_panel, "position:x", _target_x(), tuning.slide_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func toggle() -> void:
	set_open(not _open)


## Whether the panel is at rest (not sliding).
func is_settled() -> bool:
	return _tween == null or not _tween.is_running()


## The panel's left edge now, in this control's own pixels.
func panel_x() -> float:
	return _panel.position.x


## The panel's whole rectangle on screen.
func panel_rect() -> Rect2:
	return _panel.get_global_rect()


## Shows the Worlds: `rows` (Worlds.rows() as the Host said them), the chosen slot, whether this is the
## Host's drawer (keys) and whether the keys are locked (the house is loading). `colour_of`: index -> Color.
## `pairs`: the New Game's Pairs per Drawer, shown on the debug slider while New game is chosen.
func show_rows(rows: Array, chosen: String, host: bool, locked: bool, colour_of: Callable, pairs := StagePlan.PAIRS_AT) -> void:
	_rows = rows
	_chosen = chosen
	_host = host
	_locked = locked
	_colour_of = colour_of
	_fill(_list, false)
	if _full.visible:
		_fill(_full_list, true)
	var in_rows := rows.any(func(r: Variant) -> bool: return String((r as Dictionary)["slot"]) == chosen)
	_new.visible = host
	_new.disabled = locked
	var new_chosen := chosen != "" and not in_rows
	_new.text = LobbyWords.NEW_GAME_ON if new_chosen else LobbyWords.NEW_GAME
	_pairs.visible = PairsSlider.in_build() and new_chosen
	_pairs.show_value(pairs, host and not locked)


## The New Game's "Pairs per Drawer" slider (shown in debug builds while New game is chosen).
func pairs() -> PairsSlider:
	return _pairs


## The "full" page over the Lobby: the co-op Worlds to delete one of; `coop_slots` is how many there are.
func show_full(coop_slots: int) -> void:
	_full_line.text = LobbyWords.FULL_LINE % coop_slots
	_full.visible = true
	_fill(_full_list, true)


## The "full" page goes (a delete went on, or it was closed).
func hide_full() -> void:
	_show_ask(false)
	_full.visible = false


func close_full() -> void:
	hide_full()
	full_closed.emit()


## Whether the full page or the delete question lies over the Lobby.
func dialog_open() -> bool:
	return _ask.visible or _full.visible


## Esc: the question first, then the full page. True when something closed.
func close_dialog() -> bool:
	if _ask.visible:
		_show_ask(false)
		return true
	if _full.visible:
		close_full()
		return true
	return false


## The question's text, "" when it is not showing.
func ask_text() -> String:
	return _ask_question.text if _ask.visible else ""


## The rows now listed in the drawer (or the full page's), as their nodes.
func row_nodes(in_full := false) -> Array[WorldRow]:
	var out: Array[WorldRow] = []
	for c in (_full_list if in_full else _list).get_children():
		if not c.is_queued_for_deletion():
			out.append(c as WorldRow)
	return out


func _fill(into: VBoxContainer, coop_only: bool) -> void:
	for c in into.get_children():
		into.remove_child(c)
		c.queue_free()
	for r: Variant in _rows:
		var row: Dictionary = r
		if coop_only and String(row["slot"]) == Worlds.SOLO:
			continue
		var node := ROW.instantiate() as WorldRow
		into.add_child(node)
		node.fill(row, _chosen, _host and not _locked, not coop_only, tuning, _colour_of)
		var slot := String(row["slot"])
		node.choose.connect(func() -> void: choose_world.emit(slot))
		node.delete.connect(func() -> void: _ask_delete(slot, String(row["name"])))


func _ask_delete(slot: String, row_name: String) -> void:
	_delete_slot = slot
	_ask_question.text = LobbyWords.DELETE_ASK % row_name
	_show_ask(true)


func _confirm_delete() -> void:
	var slot := _delete_slot
	_show_ask(false)
	delete_confirmed.emit(slot)


func _show_ask(on: bool) -> void:
	_ask.visible = on
	if on:
		_ask_yes.grab_focus()


func _target_x() -> float:
	return size.x - tuning.width if _open else size.x


func _settle() -> void:
	if _tween != null and _tween.is_running():
		return
	_panel.position.x = _target_x()
