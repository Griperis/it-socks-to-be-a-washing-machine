## A box drawn like the keycap icons (the old UiBits.KeycapStyle): a `face` with the ink outline on
## a solid block in the `shade` colour seen from up-left; the block shows `lip` pixels below the face
## and to its right, and its rounded corners follow the face's. `pressed` sinks the face onto the
## block, leaving a third of the lip. The menus' panels and keycaps on the Theme are these.
@tool
class_name KeycapStyle
extends StyleBox

const INK := Color("#3b2a22")

@export var face_colour := Color("#fff4e0"):
	set(v):
		face_colour = v
		_rebuild()
@export var shade_colour := Color("#e6d3b3"):
	set(v):
		shade_colour = v
		_rebuild()
@export_range(0, 40, 1) var lip := 6:
	set(v):
		lip = v
		_rebuild()
@export_range(0, 60, 1) var radius := 12:
	set(v):
		radius = v
		_rebuild()
@export_range(0, 10, 1) var border := 3:
	set(v):
		border = v
		_rebuild()
## Padding round the content on every side, above the lip.
@export_range(0, 80, 1) var margin := 12:
	set(v):
		margin = v
		_rebuild()
@export var pressed := false:
	set(v):
		pressed = v
		_rebuild()

var _face: StyleBoxFlat
var _ink: StyleBoxFlat
var _side: StyleBoxFlat


func _init() -> void:
	_rebuild()


## How far the face sits down-right of the box's top-left corner.
func sink() -> float:
	return lip - roundf(lip / 3.0) if pressed else 0.0


func _rebuild() -> void:
	_face = _flat(face_colour, radius, border)
	_ink = _flat(INK, radius, 0)
	_side = _flat(shade_colour, maxi(radius - border, 0), 0)
	var d := sink()
	content_margin_left = margin + d
	content_margin_right = margin + lip - d
	content_margin_top = margin + d
	content_margin_bottom = margin + lip - d
	emit_changed()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var size := rect.size - Vector2(lip, lip)
	var from := sink()
	# The block is the face's box swept diagonally from the face back to the lip: the ink silhouette
	# first and then the shade inside it, so no line crosses it.
	var steps := maxi(int(ceilf((lip - from) * 2.0)), 1)
	for pass_box: Array in [[_ink, 0.0], [_side, float(border)]]:
		var box: StyleBoxFlat = pass_box[0]
		var inset: float = pass_box[1]
		for i in range(steps, -1, -1):
			var t := lerpf(from, lip, float(i) / steps)
			box.draw(to_canvas_item, Rect2(rect.position + Vector2(t, t), size).grow(-inset))
	_face.draw(to_canvas_item, Rect2(rect.position + Vector2(from, from), size))


static func _flat(colour: Color, r: int, b: int) -> StyleBoxFlat:
	var f := StyleBoxFlat.new()
	f.bg_color = colour
	f.border_color = INK
	f.set_border_width_all(b)
	f.set_corner_radius_all(r)
	f.anti_aliasing = true
	return f
