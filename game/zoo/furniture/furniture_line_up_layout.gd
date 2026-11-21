## How the Furniture station lines up every piece (assets/04 F03): metres, all placeholders for the
## designer's eye. Edited in the inspector (furniture_line_up_layout.tres beside it).
class_name FurnitureLineUpLayout
extends Resource

## A row ends before it grows wider than this; the next row stands behind it (-Z).
@export_range(2.0, 60.0, 0.5, "suffix:m") var row_width := 12.0
## The gap between two pieces of a row, and between two rows.
@export_range(0.0, 5.0, 0.05, "suffix:m") var gap := 0.8
@export_range(0.0, 5.0, 0.05, "suffix:m") var row_gap := 1.2
## The size of the piece's name in front of it, and how far in front of its footprint it stands.
@export var name_pixel_size := 0.0016
@export_range(0.0, 2.0, 0.05, "suffix:m") var name_ahead := 0.25
