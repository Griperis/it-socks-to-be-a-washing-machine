## The Tab overlay (docs/architecture/stages.md "The tallies, the Whiteboard and Tab"): the same sheet
## as the board's face, at `overlay_height` of the screen's height in its grey frame, shown while the
## `whiteboard_overlay` action (Tab, the pad's Select) is held. It never opens over a menu (the player's
## input is held by one) and closes when one opens. It lives on the player's HUD and decides nothing.
class_name TabOverlay
extends Control

@export var tuning: WhiteboardTuning

@onready var _frame: ColorRect = %Frame
@onready var _sheet: WhiteboardSheet = %Sheet

var _player: Player = null


func _ready() -> void:
	if tuning == null:
		tuning = WhiteboardTuning.new()
	visible = false


func _process(_delta: float) -> void:
	var want := Input.is_action_pressed(&"whiteboard_overlay") and not _menu_open()
	if want != visible:
		visible = want
		if want:
			_sheet.refresh()
	if visible:
		_layout()


## Whether the overlay is up.
func is_shown() -> bool:
	return visible


## The sheet it shows.
func sheet() -> WhiteboardSheet:
	return _sheet


## Whether a menu has the player's input (the Esc menu and the like hold it).
func _menu_open() -> bool:
	if _player == null:
		var node := get_parent()
		while node != null and not node is Player:
			node = node.get_parent()
		_player = node as Player
	return _player != null and _player.input_blocked()


func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var h := screen.y * tuning.overlay_height
	var w := minf(h * WhiteboardSheet.BASE.x / WhiteboardSheet.BASE.y, screen.x * 0.95)
	h = w * WhiteboardSheet.BASE.y / WhiteboardSheet.BASE.x
	var at := (screen - Vector2(w, h)) / 2.0
	_sheet.position = at
	_sheet.size = Vector2(w, h)
	var border := maxf(6.0, h * 0.012)
	_frame.position = at - Vector2(border, border)
	_frame.size = Vector2(w, h) + Vector2(border, border) * 2.0
