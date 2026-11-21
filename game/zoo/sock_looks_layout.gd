## How the Sock looks station lays out its line-up (assets/01): metres, placeholders for the
## designer's eye. Edited in the inspector (sock_looks_layout.tres beside it).
class_name SockLooksLayout
extends Resource

## Looks in a row, and the distance between two in a row.
@export var per_row := 9
@export var spacing := 0.55
## From one row to the next, and the extra gap between one group of rows and the next.
@export var row_pitch := 0.42
@export var group_gap := 0.2
## How far in front of its Looks a label lies, and its size.
@export var label_offset := 0.2
@export var label_pixel_size := 0.0012
