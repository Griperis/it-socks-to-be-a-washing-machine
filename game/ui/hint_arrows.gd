## The off-screen hint arrows (core/43 lines 44-53; the old hint_arrows.gd, progression/76, Q1513-Q1519):
## a small arrow at the screen's edge for each target that is off screen (behind the camera too),
## pointing toward it, in the target's colour, an emoji beside it when the target has one; it hides while
## the target is on screen. At most `max_arrows`, the higher priority first, then the nearest. An arrow
## that would cover a part of the HUD slides along the edge until it clears (Q1537). Direction only.
##
## It knows no feature: a piece that wants arrows adds a source (add_source()), a func() returning
## Array[Dictionary] of {"at": Vector3, "colour": Color} with an optional "priority" (int, 0 by default)
## and "emoji" (a Pings.EMOJIS name). Pings are its only source now (PingMarks); the X-rays, Mate Radar
## and the Laundry bin come in M4 and M5. It lives in the HUD, local to its player, changing no state;
## the list is asked every frame and redrawn only when it changed (line 52).
class_name HintArrows
extends Control

@export var tuning: HintArrowTuning

## The camera the arrows are relative to (the Hud sets it).
var camera: Camera3D
## The parts of the HUD an arrow keeps clear of: func() -> Array[Rect2] in this Control's pixels.
var keep_clear := Callable()
## Where the arrows get their targets.
var _sources: Array[Callable] = []
var _shown: Array[Dictionary] = []


func _ready() -> void:
	if tuning == null:
		tuning = HintArrowTuning.new()


## Another piece's targets point arrows from now on (line 53).
func add_source(source: Callable) -> void:
	if not _sources.has(source):
		_sources.append(source)


func _process(_delta: float) -> void:
	refresh()


## Where a target at `world` sits for a camera at `cam` with vertical field of view `fov` (degrees) on a
## screen of `size` px (line 45): {"on_screen", "tip": the arrow's tip on the rectangle `margin_px` inside
## the edge, along the target's direction from the screen's middle, "angle": the way it points
## (radians, 0 right, clockwise on screen)}. Straight behind the camera points down.
static func locate(cam: Transform3D, fov: float, world: Vector3, size: Vector2, margin_px: float) -> Dictionary:
	var l := cam.affine_inverse() * world
	var on_screen := false
	if l.z < -0.001:
		var h := tan(deg_to_rad(fov) * 0.5)
		var aspect := size.x / maxf(size.y, 1.0)
		on_screen = absf(l.x / -l.z / (h * aspect)) <= 1.0 and absf(l.y / -l.z / h) <= 1.0
	var d := Vector2(l.x, -l.y)
	if d.length() < 0.0001:
		d = Vector2.DOWN
	d = d.normalized()
	var half := size * 0.5 - Vector2(margin_px, margin_px)
	half = Vector2(maxf(half.x, 1.0), maxf(half.y, 1.0))
	var t := INF
	if absf(d.x) > 0.0001:
		t = minf(t, half.x / absf(d.x))
	if absf(d.y) > 0.0001:
		t = minf(t, half.y / absf(d.y))
	return {"on_screen": on_screen, "tip": size * 0.5 + d * t, "angle": d.angle()}


## The box round an arrow whose tip is at `tip`, pointing `angle`, `length` long, `side` wide each way.
static func arrow_bounds(tip: Vector2, angle: float, length: float, side: float) -> Rect2:
	var dir := Vector2.from_angle(angle)
	var base := tip - dir * length
	var across := dir.orthogonal() * length * side
	return Rect2(tip, Vector2.ZERO).expand(base + across).expand(base - across)


## The point `s` px along the edge inset by `margin_px`, from its top-left corner clockwise (wraps).
static func edge_point(size: Vector2, margin_px: float, s: float) -> Vector2:
	var w := maxf(size.x - 2.0 * margin_px, 1.0)
	var h := maxf(size.y - 2.0 * margin_px, 1.0)
	s = fposmod(s, 2.0 * (w + h))
	var o := Vector2(margin_px, margin_px)
	if s < w:
		return o + Vector2(s, 0.0)
	s -= w
	if s < h:
		return o + Vector2(w, s)
	s -= h
	if s < w:
		return o + Vector2(w - s, h)
	s -= w
	return o + Vector2(0.0, h - s)


## How far along that edge (edge_point()) the point `p` on it lies.
static func edge_param(size: Vector2, margin_px: float, p: Vector2) -> float:
	var w := maxf(size.x - 2.0 * margin_px, 1.0)
	var h := maxf(size.y - 2.0 * margin_px, 1.0)
	var q := p - Vector2(margin_px, margin_px)
	var m := minf(minf(absf(q.y), absf(q.y - h)), minf(absf(q.x), absf(q.x - w)))
	if m == absf(q.y):
		return clampf(q.x, 0.0, w)
	if m == absf(q.x - w):
		return w + clampf(q.y, 0.0, h)
	if m == absf(q.y - h):
		return w + h + (w - clampf(q.x, 0.0, w))
	return 2.0 * w + h + (h - clampf(q.y, 0.0, h))


## Where an arrow wanted at `tip` really goes (line 51): there if it covers none of `rects` (each grown by
## `pad`), else the nearest spot along the edge, `step` px a try either way, round the corners too,
## where it covers none, keeping its direction; where the whole edge is taken it stays put.
static func slide_clear(tip: Vector2, angle: float, length: float, side: float, size: Vector2, margin_px: float,
		rects: Array[Rect2], pad: float, step: float) -> Vector2:
	if _is_clear(arrow_bounds(tip, angle, length, side), rects, pad):
		return tip
	var s0 := edge_param(size, margin_px, tip)
	var total := 2.0 * (maxf(size.x - 2.0 * margin_px, 1.0) + maxf(size.y - 2.0 * margin_px, 1.0))
	var k := 1
	while k * step <= total * 0.5:
		for sign_: float in [1.0, -1.0]:
			var p := edge_point(size, margin_px, s0 + sign_ * k * step)
			if _is_clear(arrow_bounds(p, angle, length, side), rects, pad):
				return p
		k += 1
	return tip


static func _is_clear(box: Rect2, rects: Array[Rect2], pad: float) -> bool:
	for r in rects:
		if box.intersects(r.grow(pad)):
			return false
	return true


## The arrows to draw now (lines 44, 50): [{"tip", "angle", "colour", "emoji", "priority", "dist"}] for
## the targets off screen, the higher priority first, then the nearest, at most `max_arrows`.
func arrows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if camera == null or not camera.is_inside_tree():
		return out
	var t := tuning
	var size := get_viewport_rect().size
	var cam := camera.global_transform
	var rects: Array[Rect2] = []
	if keep_clear.is_valid():
		rects.assign(keep_clear.call())
	var scored: Array[Dictionary] = []
	for src in _sources:
		if not src.is_valid():
			continue
		for target: Dictionary in src.call():
			var at := target["at"] as Vector3
			var loc := locate(cam, camera.fov, at, size, t.margin)
			if bool(loc["on_screen"]):
				continue
			loc["tip"] = slide_clear(loc["tip"], float(loc["angle"]), t.size, t.side, size, t.margin, rects, t.clear_pad, t.slide_step)
			loc["colour"] = target["colour"]
			loc["dist"] = cam.origin.distance_squared_to(at)
			loc["priority"] = int(target.get("priority", 0))
			loc["emoji"] = String(target.get("emoji", ""))
			scored.append(loc)
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["priority"]) != int(b["priority"]):
			return int(a["priority"]) > int(b["priority"])
		return float(a["dist"]) < float(b["dist"]))
	for loc: Dictionary in scored.slice(0, maxi(t.max_arrows, 0)):
		out.append(loc)
	return out


## What is drawn, asked every frame; redrawn only when it changed. With the HUD hidden nothing (line 52).
func refresh() -> void:
	var layer := get_canvas_layer_node()
	var now: Array[Dictionary] = []
	if is_visible_in_tree() and (layer == null or layer.visible):
		now = arrows()
	if now != _shown:
		_shown = now
		queue_redraw()


## How many arrows show now, and which.
func count() -> int:
	return _shown.size()


func shown() -> Array[Dictionary]:
	return _shown


## Each arrow (line 46): a filled arrowhead with a notch in its back, outlined; the emoji's icon beside
## it, behind its notch, nearer the screen's middle (line 47).
func _draw() -> void:
	var t := tuning
	for a in _shown:
		var tip := a["tip"] as Vector2
		var dir := Vector2.from_angle(float(a["angle"]))
		var side := dir.orthogonal()
		var base := tip - dir * t.size
		var pts := PackedVector2Array([tip, base + side * t.size * t.side, base + dir * t.size * t.notch,
				base - side * t.size * t.side])
		draw_colored_polygon(pts, a["colour"] as Color)
		var ring := pts.duplicate()
		ring.append(pts[0])
		draw_polyline(ring, t.outline_colour, t.outline, true)
		var emoji := String(a.get("emoji", ""))
		if emoji != "":
			var tex := UiIcons.texture("emoji_" + emoji)
			if tex != null:
				var box := Vector2.ONE * t.size
				var mid := base - dir * (t.size * 0.2 + box.x * 0.5)
				draw_texture_rect(tex, Rect2(mid - box * 0.5, box), false)
