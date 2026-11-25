## How the Sounds station lays out its buttons (core/22): metres, all placeholders for the designer's
## eye. Edited in the inspector (sounds_layout.tres beside it).
class_name SoundsLayout
extends Resource

## The side of a button's box.
@export var button_size := 0.3
## Buttons in a row.
@export var per_row := 10
## From one button to the next in a row, and from one row to the row behind it.
@export var column_pitch := 0.75
@export var row_pitch := 0.8
## Extra length between one group's rows and the next group's.
@export var group_gap := 0.4
## Where the first button of the first group (front row, left end) stands, in the station's space.
@export var origin := Vector3(-3.0, 0.0, 0.9)
## How far in front of its box (towards the player) a button's name lies, and how left of the first
## column a group's name stands.
@export var label_offset := 0.3
@export var group_offset := 0.9
@export var label_pixel_size := 0.0025
@export var group_pixel_size := 0.006
## The colour of a flat event's box and of a world one's (the old pillars' blue and orange).
@export var flat_colour := Color(0.45, 0.65, 0.85)
@export var world_colour := Color(0.9, 0.65, 0.3)
