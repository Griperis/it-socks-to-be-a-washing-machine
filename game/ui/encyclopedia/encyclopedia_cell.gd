## One Design's cell of the encyclopedia (core/136): its name (14 px) at the foot, the Size badge in the
## corner and a `Spot` where the page puts the Design's Sock behind it. The look is the scene's; code fills it.
class_name EncyclopediaCell
extends Control

## What an uncollected Design is named.
const UNKNOWN := "???"

@onready var _name: Label = %Name
@onready var _size: PanelContainer = %Size
@onready var _spot: Control = %Spot


## Shows `design`: its name and Size letter, or "???" (the letter stays) while `collected` is false.
func fill(design: SockDesign, collected: bool) -> void:
	_name.text = design.name if collected else UNKNOWN
	(_size.get_child(0) as Label).text = design.size_letter()


## Where the Sock goes, in the cell's own pixels: the middle of the part above the name.
func sock_centre() -> Vector2:
	return _spot.position + _spot.size * 0.5


## The name shown.
func shown_name() -> String:
	return _name.text
