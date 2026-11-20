## The placeholder main scene: a square to click and a label that counts the clicks.
## Replace it with the game's first scene (docs/llm/mvp/issues/01-first-playable.md).
extends Control

const COLOURS: Array[Color] = [Color(0.3, 0.7, 0.4), Color(0.8, 0.5, 0.2), Color(0.3, 0.5, 0.9)]

var clicks := 0

@onready var square: ColorRect = $Square
@onready var label: Label = $Label


func _ready() -> void:
	square.gui_input.connect(_on_square_input)
	_show()


func _on_square_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		click()


## One click on the square: what a real left click on it does.
func click() -> void:
	clicks += 1
	_show()


## What kit/tools/net_shot.gd writes to its state file for this screen: the facts a reviewer checks.
func net_shot_state() -> Dictionary:
	return {"clicks": clicks}


func _show() -> void:
	label.text = "It runs" if clicks == 0 else "It runs (clicked %d)" % clicks
	square.color = COLOURS[clicks % COLOURS.size()]
