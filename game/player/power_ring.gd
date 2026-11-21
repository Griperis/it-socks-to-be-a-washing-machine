## The Throw's ring round the crosshair (T01): a thin circle that fills clockwise from the top while
## the drop button is held past the tap with something in the Hands; hidden while not charging.
## The old game's look (Q2260): 26 px radius, a 5 px line, a faint white track, cream to orange.
class_name PowerRing
extends Control

## Its radius and line width in pixels, and how many straight pieces a full circle is drawn with.
@export_range(4.0, 100.0, 0.5, "suffix:px") var radius := 26.0 # placeholder: the old game's look (Q2260)
@export_range(1.0, 20.0, 0.5, "suffix:px") var width := 5.0 # placeholder: the old game's look (Q2260)
@export_range(8, 128, 1) var segments := 48
## The track under it, and its colour empty and full (it shades between them as it fills).
@export var track := Color(1.0, 1.0, 1.0, 0.25) # placeholder: the old game's look (Q2260)
@export var empty := Color(1.0, 0.95, 0.8, 0.95) # placeholder: the old game's look (Q2260)
@export var full := Color(1.0, 0.55, 0.25, 0.95) # placeholder: the old game's look (Q2260)

## How full the ring is, 0 to 1.
var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, segments, track, width, true)
	if value > 0.0:
		draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + TAU * value, segments, empty.lerp(full, value), width, true)
