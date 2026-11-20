## The crosshair (core/18, the old hud.gd): two crisp bars, 18 by 2 px, around the exact screen centre (a text "+" sits
## off-centre in its box). The bars are white at alpha 0.9; the player tints the whole crosshair through `modulate` (red
## where a drop would be refused). The bars are real nodes of crosshair.tscn.
class_name Crosshair
extends Control

## The bars' size, in pixels: length and thickness.
const LENGTH := 18.0
const THICKNESS := 2.0

@onready var _horizontal: ColorRect = %Horizontal
@onready var _vertical: ColorRect = %Vertical


## The two bars' rectangles, relative to the screen centre (a test checks the size and the centring).
func bars() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for bar: ColorRect in [_horizontal, _vertical]:
		out.append(Rect2(bar.position, bar.size))
	return out
