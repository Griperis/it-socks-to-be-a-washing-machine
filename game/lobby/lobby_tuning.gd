## The Lobby look's numbers (docs/architecture/lobby.md "Core/66"; the old lobby.json): the one 3D view's
## camera, the pedestals, the box round a figure and how a free place shows. One .tres beside it.
class_name LobbyTuning
extends Resource

## The camera stands this far in front of the row, this high, looks at this height, sees this many degrees up to down.
@export_range(3.0, 30.0, 0.5, "suffix:m") var camera_distance := 10.0 # placeholder: the old number, until the designer tunes it
@export_range(0.0, 5.0, 0.1, "suffix:m") var camera_height := 1.5 # placeholder: the old number, until the designer tunes it
@export_range(0.0, 3.0, 0.1, "suffix:m") var camera_look_height := 1.1 # placeholder: the old number, until the designer tunes it
@export_range(10.0, 90.0, 1.0, "suffix:deg") var camera_fov := 30.0 # placeholder: the old number, until the designer tunes it
## Metres between two pedestals.
@export_range(1.0, 4.0, 0.1, "suffix:m") var spacing := 2.1 # placeholder: the old number, until the designer tunes it
## The pedestal (a plain cylinder for now, Q1768).
@export_range(0.3, 1.5, 0.05, "suffix:m") var pedestal_radius := 0.75 # placeholder: the old number, until the designer tunes it
@export_range(0.1, 1.0, 0.05, "suffix:m") var pedestal_height := 0.3 # placeholder: the old number, until the designer tunes it
## The box round a figure that takes the mouse and the pad's selection.
@export_range(1.0, 3.0, 0.1, "suffix:m") var figure_height := 1.9 # placeholder: the old number, until the designer tunes it
@export_range(0.5, 2.5, 0.1, "suffix:m") var figure_width := 1.3 # placeholder: the old number, until the designer tunes it
## A free place: how far its pedestal is dimmed toward the backdrop, and how far from the backdrop to grey its silhouette shows.
@export_range(0.0, 1.0, 0.05) var free_dim := 0.45 # placeholder: the old number, until the designer tunes it
@export_range(0.0, 1.0, 0.05) var silhouette_show := 0.35 # placeholder: the old number, until the designer tunes it
## Pixels between the pedestal's foot and the row of its name.
@export_range(0.0, 60.0, 1.0, "suffix:px") var label_gap := 10.0 # placeholder: the old number, until the designer tunes it
## The pedestal's colour, and the focused one's.
@export var pedestal_colour := Color(0.80, 0.74, 0.62) # placeholder: until the designer picks a pedestal
@export var focus_colour := Color(0.96, 0.76, 0.18) # placeholder: the gold of the marks, until the designer picks
## The backdrop the 3D view stands on (the title's dark brown), for dimming.
@export var backdrop := Color(0.168627, 0.129412, 0.109804) # placeholder: the title's backdrop
