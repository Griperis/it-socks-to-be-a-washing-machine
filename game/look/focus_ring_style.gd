## The selection ring of every focusable control on the Theme (core/75, designer 2026-11-24): a cream outline
## round the control, drawn only when the last thing the player did was a key or a pad press, never after a mouse
## click. The Theme's `focus` styles are this one resource. It watches the window's input once, when the script
## loads, so it needs no autoload; a flip of the state redraws the controls that show it.
class_name FocusRingStyle
extends StyleBox

const EDGE := 2

## Whether the ring shows now: set by a key or pad event, cleared by a mouse button.
static var shown := false
static var _live: Array[FocusRingStyle] = []

@export var colour := Color(1, 0.94, 0.82, 1)
@export_range(1, 12, 1) var width := 4
## How far outside the control the ring sits.
@export_range(0, 20, 1) var reach := 5
@export_range(0, 40, 1) var radius := 17

var _flat := StyleBoxFlat.new()
## The ink line round the outside of the ring, so it reads on the cream panels too.
var _edge := StyleBoxFlat.new()


## Sets whether the ring shows from the kind of `event`; a mouse motion changes nothing.
static func on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_set_shown(false)
	elif (event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction) and event.is_pressed():
		_set_shown(true)
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		_set_shown(true)


static func _set_shown(on: bool) -> void:
	if on == shown:
		return
	shown = on
	for style in _live:
		style.emit_changed()


func _init() -> void:
	_live.append(self)


func _draw(canvas_item: RID, rect: Rect2) -> void:
	if not shown:
		return
	_flat.draw_center = false
	_flat.border_color = colour
	_flat.set_border_width_all(width)
	_flat.set_corner_radius_all(radius)
	_flat.set_expand_margin_all(reach)
	_flat.anti_aliasing = true
	_flat.draw(canvas_item, rect)
	_edge.draw_center = false
	_edge.border_color = KeycapStyle.INK
	_edge.set_border_width_all(EDGE)
	_edge.set_corner_radius_all(radius + EDGE)
	_edge.set_expand_margin_all(reach + EDGE)
	_edge.anti_aliasing = true
	_edge.draw(canvas_item, rect)
