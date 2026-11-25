## One place of the Lobby (docs/architecture/lobby.md "Core/66", the old lobby/06): the box round a figure
## of the stage, and under its pedestal one row: the HOST mark (the Host's only), the name in the player's
## colour and, in co-op, the Ready mark (a gold disc with a tick, or an empty ring with a dash: icon only).
## A free place says "Waiting for a player" and takes neither the mouse nor the pad. The mouse over the box,
## or the pad's selection on it, focuses the place (`focused()`, `focus_changed`). A view: the Lobby says
## what to show and where the figure falls (`lay_out`).
class_name LobbyPlace
extends Control

## The mouse came or went, or the pad's selection did: the Lobby looks again who is focused.
signal focus_changed

## The theme variations of the Ready mark (game/look/theme.tres): a gold disc with a tick, or an empty ring with a dash.
const READY_ON := &"ReadyCircle"
const READY_OFF := &"ReadyCircleOff"

## Which pedestal of the stage this place is.
var index := 0
var tuning: LobbyTuning = null

var _hovered := false
var _free := true
var _blocked := false

@onready var _row: HBoxContainer = %Row
@onready var _host: Label = %HostMark
@onready var _name: Label = %Name
@onready var _mark: PanelContainer = %Ready
@onready var _tick: Label = %Tick
@onready var _waiting: Label = %Waiting


func _ready() -> void:
	_host.text = LobbyWords.HOST_MARK
	_waiting.text = LobbyWords.WAITING_PLAYER
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	focus_entered.connect(focus_changed.emit)
	focus_exited.connect(focus_changed.emit)
	show_free()


## A player stands here. `with_ready`: co-op (Solo has no Ready).
func show_player(who: String, colour: Color, is_host: bool, with_ready: bool, is_ready: bool) -> void:
	_free = false
	_host.visible = is_host
	_name.visible = true
	_name.text = who
	_name.add_theme_color_override(&"font_color", colour)
	_waiting.visible = false
	_mark.visible = with_ready
	_mark.theme_type_variation = READY_ON if is_ready else READY_OFF
	_tick.text = LobbyWords.READY_TICK if is_ready else LobbyWords.NOT_READY_DASH
	_tick.add_theme_color_override(&"font_color", Color(0.13, 0.1, 0.08) if is_ready else Color(0.75, 0.68, 0.58))
	_apply_focus_rules()


## The place is free: "Waiting for a player", no focus.
func show_free() -> void:
	_free = true
	_host.visible = false
	_name.visible = false
	_mark.visible = false
	_waiting.visible = true
	_hovered = false
	_apply_focus_rules()
	focus_changed.emit()


## Whether nobody stands here.
func is_free() -> bool:
	return _free


## A page lies over the Lobby: nothing is focused while it does.
func set_blocked(on: bool) -> void:
	_blocked = on
	_apply_focus_rules()


## Whether this place is the focused one: the mouse over its box or the pad's selection on it.
func focused() -> bool:
	return not _free and not _blocked and (_hovered or has_focus())


## Puts the box over the figure (`box`, in the Lobby's pixels) and the name row `label_gap` px under it, centred.
func lay_out(box: Rect2, label_gap: float) -> void:
	position = box.position
	size = box.size
	var row_size := _row.get_combined_minimum_size()
	_row.size = row_size
	_row.position = Vector2((size.x - row_size.x) * 0.5, size.y + label_gap)


## The row as words, left to right: the HOST mark, the name, the Ready mark; a free place's words.
func texts() -> String:
	var words := PackedStringArray()
	for label: Label in [_host, _name, _tick, _waiting]:
		if label.visible and (label != _tick or _mark.visible) and label.text != "":
			words.append(label.text)
	return " ".join(words)


func _apply_focus_rules() -> void:
	var live := not _free and not _blocked
	mouse_filter = Control.MOUSE_FILTER_STOP if live else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if live else Control.FOCUS_NONE


func _hover(on: bool) -> void:
	_hovered = on and not _free
	focus_changed.emit()
