## The Throw's ring round the crosshair (T01): a thin circle that fills clockwise from the top while
## the drop button is held past the tap with something in the Hands; hidden while not charging.
## The old game's look (Q2260): 26 px radius, a 5 px line, a faint white track, cream to orange.
class_name PowerRing
extends Control

const RADIUS := 26.0
const WIDTH := 5.0
const SEGMENTS := 48
const TRACK := Color(1.0, 1.0, 1.0, 0.25)
const EMPTY := Color(1.0, 0.95, 0.8, 0.95)
const FULL := Color(1.0, 0.55, 0.25, 0.95)

## How full the ring is, 0 to 1.
var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, SEGMENTS, TRACK, WIDTH, true)
	if value > 0.0:
		draw_arc(Vector2.ZERO, RADIUS, -PI / 2.0, -PI / 2.0 + TAU * value, SEGMENTS, EMPTY.lerp(FULL, value), WIDTH, true)
