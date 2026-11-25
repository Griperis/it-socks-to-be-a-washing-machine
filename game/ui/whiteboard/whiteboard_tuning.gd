## The Whiteboard's numbers (docs/architecture/stages.md "The tallies, the Whiteboard and Tab"): the old
## data/tuning/whiteboard.json. One .tres beside it (whiteboard_tuning.tres), edited in the inspector.
class_name WhiteboardTuning
extends Resource

## The board face's picture, in pixels (4:3, like the face).
@export var resolution := Vector2i(1024, 768) # placeholder: the old whiteboard.json resolution
## The Tab overlay's height as a share of the screen's.
@export_range(0.2, 1.0, 0.05) var overlay_height := 0.8 # placeholder: the old whiteboard.json overlay_height
## How much the board's face lights itself, so the basement's dim lamp still lets it read.
@export_range(0.0, 1.0, 0.05) var glow := 0.2 # placeholder: the old whiteboard.json glow
