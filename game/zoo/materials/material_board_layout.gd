## How the Materials station's board lays out the shared material library (assets/04 F01): metres, all
## placeholders for the designer's eye. Edited in the inspector (material_board_layout.tres beside it).
class_name MaterialBoardLayout
extends Resource

## Swatches in a row; a row of single materials breaks after this many.
@export_range(1, 16, 1) var per_row := 8
## From one swatch's centre to the next along a row, and from one row to the next (metres).
@export_range(0.2, 2.0, 0.05, "suffix:m") var pitch := 0.55
@export_range(0.2, 2.0, 0.05, "suffix:m") var row_pitch := 0.62
## Rows in a block before the next block starts to the right, and from one block to the next.
@export_range(1, 32, 1) var rows_per_block := 10
@export_range(1.0, 10.0, 0.1, "suffix:m") var block_pitch := 5.4
## The height of the first row's swatches over the station's floor.
@export_range(0.0, 10.0, 0.05, "suffix:m") var top := 6.3
## From a row's name (at the row's left) to its first swatch.
@export_range(0.0, 3.0, 0.05, "suffix:m") var name_width := 1.0
## A swatch sphere's diameter.
@export_range(0.05, 1.0, 0.01, "suffix:m") var swatch_size := 0.32
## The pixel size of a row's name and of the text under each swatch.
@export var name_pixel_size := 0.0022
@export var label_pixel_size := 0.0009
