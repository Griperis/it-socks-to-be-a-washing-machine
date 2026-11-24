## The ping's emoji wheel (core/43 lines 9-15; the old ping_wheel.gd, Q300, Q301): while the middle
## button is held past the tap, five cream keycaps stand in a ring round the crosshair, Here at the top,
## then Help, Yes, No and Nice clockwise, over a soft dark disc. The mouse (or a pad's right stick) steers
## a pointer out from the centre instead of turning the view; the slice it points toward is chosen
## (orange, bigger, a line out to it). Letting go places the chosen emoji (the Pinger asks); let go with
## the pointer still in the centre, nothing is placed. A node of the player's HUD: only its player sees it.
class_name PingWheel
extends Control

## The names under the keycaps, in Pings.EMOJIS order (line 9).
const NAMES: Array[String] = ["Here", "Help", "Yes", "No", "Nice"]

@export var tuning: PingTuning
## A keycap's look, and a chosen one's (line 13).
@export var plain: StyleBox
@export var chosen_style: StyleBox
## The ink of the rims, the accent of a chosen slice and the cancel, the cream of the centre ring and
## the disc's colour (the old UiBits INK, ACCENT, CREAM, OUTLINE).
@export var ink := Color(0.231373, 0.164706, 0.133333)
@export var accent := Color(0.94902, 0.607843, 0.294118)
@export var cream := Color(1.0, 0.956863, 0.878431)
@export var disc := Color(0.1, 0.07, 0.05)

## The slice chosen now (an index into Pings.EMOJIS), or -1 (the centre: a cancel).
var chosen := -1
## Where the pointer is, in pixels from the centre (the mouse's motion since the wheel opened).
var pointer := Vector2.ZERO
## How many hover ticks and clicks it played (a test reads them).
var ticks := 0
var clicks := 0

var _keys: Array[PanelContainer] = []


func _ready() -> void:
	if tuning == null:
		tuning = PingTuning.new()
	visible = false
	for i in NAMES.size():
		var key := get_node("Slice%d" % i) as PanelContainer
		var icon := key.get_node(^"Column/Icon") as TextureRect
		icon.texture = UiIcons.texture("emoji_" + Pings.EMOJIS[i])
		icon.custom_minimum_size = Vector2.ONE * tuning.wheel_icon
		(key.get_node(^"Column/Name") as Label).text = NAMES[i]
		_keys.append(key)
	resized.connect(_lay_out)


## Opens the wheel with the pointer in the centre (nothing chosen, line 4).
func open() -> void:
	pointer = Vector2.ZERO
	chosen = -1
	visible = true
	_lay_out()


## Closes the wheel; returns the emoji chosen (an index into Pings.EMOJIS) or -1 for a cancel. A slice
## chosen plays the menus' click; a cancel is silent (line 14).
func close() -> int:
	var out := chosen
	if visible and chosen >= 0:
		Sounds.play(UiSounds.CLICK)
		clicks += 1
	visible = false
	pointer = Vector2.ZERO
	chosen = -1
	return out


func is_open() -> bool:
	return visible


## The mouse moved by `relative` pixels while the wheel is open (line 11): the pointer follows, never
## further out than the keycaps, and the slice it points toward is chosen; a new slice plays the menus'
## hover tick (line 14).
func steer(relative: Vector2) -> void:
	pointer = (pointer + relative).limit_length(tuning.wheel_radius)
	var was := chosen
	chosen = slice_at(pointer, NAMES.size(), tuning.wheel_dead)
	if chosen != was:
		_lay_out()
		if chosen >= 0:
			Sounds.play(UiSounds.HOVER)
			ticks += 1
	queue_redraw()


## A pad's right stick points at `dir` (length 0 to 1, y down; line 8): the pointer sits at that
## direction on the ring's radius; the stick inside the deadzone is the centre (a cancel).
func aim(dir: Vector2) -> void:
	var at := Vector2.ZERO if dir.length() < tuning.wheel_deadzone else dir.limit_length(1.0) * tuning.wheel_radius
	pointer = Vector2.ZERO
	steer(at)


## The slice the direction `v` (pixels from the centre, y down) points toward: 0 straight up, then
## clockwise in `count` equal slices; -1 nearer the centre than `dead` (line 12).
static func slice_at(v: Vector2, count: int, dead: float) -> int:
	if v.length() < dead:
		return -1
	var a := fposmod(atan2(v.x, -v.y), TAU)
	return int(roundf(a / (TAU / count))) % count


## The middle of slice `i`'s keycap, in pixels from the centre, `radius` out.
static func slice_offset(i: int, count: int, radius: float) -> Vector2:
	var a := TAU * i / count
	return Vector2(sin(a), -cos(a)) * radius


## The keycap of slice `i` (a test or a shot reads it).
func key(i: int) -> PanelContainer:
	return _keys[i]


## The crosshair, in this Control's own pixels: the screen's middle.
func _centre() -> Vector2:
	return get_viewport_rect().size * 0.5 - position


func _lay_out() -> void:
	var centre := _centre()
	for i in _keys.size():
		var k := _keys[i]
		k.add_theme_stylebox_override(&"panel", chosen_style if i == chosen else plain)
		k.reset_size()
		k.pivot_offset = k.size * 0.5
		k.scale = Vector2.ONE * (tuning.wheel_chosen_scale if i == chosen else 1.0)
		k.position = centre + slice_offset(i, _keys.size(), tuning.wheel_radius) - k.size * 0.5
	queue_redraw()


## The soft dark disc behind the keycaps, the centre ring (orange while the pointer is in it: a cancel)
## and the pointer's line out toward the chosen slice (lines 10, 13).
func _draw() -> void:
	var t := tuning
	var c := _centre()
	draw_circle(c, t.wheel_disc, Color(disc, t.wheel_disc_alpha))
	draw_circle(c, t.wheel_centre, ink, false, 9.0, true)
	draw_circle(c, t.wheel_centre, accent if chosen < 0 else cream, false, 4.5, true)
	if chosen >= 0:
		var dir := slice_offset(chosen, _keys.size(), 1.0) if pointer.length() < 0.001 else pointer.normalized()
		var tip := c + dir * (t.wheel_radius - t.wheel_line_short)
		var from := c + dir * t.wheel_centre
		draw_line(from, tip, ink, 9.0, true)
		draw_line(from, tip, accent, 4.5, true)
