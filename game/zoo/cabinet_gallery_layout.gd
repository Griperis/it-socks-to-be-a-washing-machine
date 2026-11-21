## How the Cabinet station lines up every Collection's Cabinet (assets/02, K02): metres, all
## placeholders for the designer's eye. Edited in the inspector (cabinet_gallery_layout.tres beside it).
class_name CabinetGalleryLayout
extends Resource

## Cabinets in a row.
@export_range(1, 32, 1) var per_row := 5
## From one Cabinet's centre to the next along a row, and from one row to the next (metres).
@export_range(0.5, 6.0, 0.1, "suffix:m") var spacing := 1.9
@export_range(0.5, 6.0, 0.1, "suffix:m") var row_pitch := 2.6
## The size of the Collection's name standing above each Cabinet.
@export var name_pixel_size := 0.004
@export_range(0.0, 3.0, 0.05, "suffix:m") var name_height := 1.35
