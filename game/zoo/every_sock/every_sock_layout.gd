## How the every-Sock station lays out the catalogue (core/12): metres, all placeholders for the
## designer's eye. Edited in the inspector (every_sock_layout.tres beside it).
class_name EverySockLayout
extends Resource

## Designs in a row.
@export var per_row := 25
## Across a Design's cell, and from one row to the next (metres).
@export var cell_width := 1.0
@export var row_pitch := 0.7
## The distance between a Design's two Socks (centre to centre).
@export var mate_gap := 0.4
## Extra length between one Collection's rows and the next.
@export var collection_gap := 0.5
## How far in front of its Socks (towards the player) a label lies.
@export var label_offset := 0.3
## How far left of the first cell the Collection's name stands.
@export var name_offset := 2.2
@export var label_pixel_size := 0.002
@export var name_pixel_size := 0.012
