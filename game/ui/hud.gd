## The player's screen (core/15, the old hud.gd): the crosshair and its red, the crosshair's prompt
## row at 58 % of the height (32 pt), the aimed Sock's row at 63 % (28 pt: the pick key and the Size
## letter in its box, then Sock Sense's readout), the message at 70 % (28 pt), the key hints bottom
## right (24 pt), and the held readout beside the held item (28 pt: the boxed Size, or with Sock
## Smarts the Collection, Design name, Sock or Pair, n/capacity and the wheel). The rows are nodes of
## player.tscn under this layer; each is rebuilt only when what it says changed (A08). Every row
## reads back as plain text for tests (A13). It shows what the player tells it; it decides nothing.
class_name Hud
extends CanvasLayer

## The game's one Theme (the project's): the texts' sizes and the HUD's colours and spacing are read
## from it.
const THEME := preload("res://game/look/theme.tres")
## Keys are drawn 1.5 times their text's size, icons 1.3.
const KEY_SCALE := 1.5
const ICON_SCALE := 1.3
## The theme variations of each text (game/look/theme.tres): prompts, rows, hints (the old HUD's 32,
## 28 and 24 pt).
const PROMPT_LABEL := &"PromptLabel"
const ROW_LABEL := &"RowLabel"
const HINT_LABEL := &"HintLabel"
const SIZE_BOX := &"SizeBox"
const SIZE_LETTER := &"SizeLetter"
## The theme type holding the HUD's colours and the gap between a prompt's key, icon and name.
const HUD_TYPE := &"Hud"

## The crosshair where a drop may go, and where it may not (the theme's Hud `plain` and `refusal`:
## the old REFUSE red; the bars carry the alpha 0.9, A10).
static var CROSSHAIR_OK := THEME.get_color(&"plain", HUD_TYPE)
static var CROSSHAIR_NO := THEME.get_color(&"refusal", HUD_TYPE)
## The message's colours: a refusal in the old REFUSE red, anything else white (the old _show_line).
static var MESSAGE_REFUSAL := THEME.get_color(&"refusal", HUD_TYPE)
static var MESSAGE_PLAIN := THEME.get_color(&"plain", HUD_TYPE)

@export var tuning: HudTuning

## Whether the pad was the last thing pressed: the keycaps show its glyphs.
var pad := false
## How many times each row was rebuilt: "prompt", "aimed", "sense", "held", "hints" (A08).
var rebuilds: Dictionary[String, int] = {"prompt": 0, "aimed": 0, "sense": 0, "held": 0, "hints": 0}
## What the held readout is placed beside: the camera, the HeldView and the Hands' numbers (the player
## sets them).
var camera: Camera3D
var held_view: HeldView
var hands_tuning: HandsTuning

@onready var _crosshair: Crosshair = $Crosshair
@onready var _prompts: HBoxContainer = $PromptRow/Prompts
@onready var _aimed: HBoxContainer = $AimedRow/Row/Aimed
@onready var _sense: HBoxContainer = $AimedRow/Row/Sense
@onready var _hints: HBoxContainer = $Hints
@onready var _held: HBoxContainer = $HeldInfo
@onready var _message_row: Control = $MessageRow
@onready var _message: Label = $MessageRow/Message

var _sig: Dictionary[String, String] = {"prompt": "", "aimed": "", "sense": "", "held": "", "hints": ""}
var _text: Dictionary[String, String] = {"prompt": "", "aimed": "", "sense": "", "held": "", "hints": ""}
var _held_size := ""
var _blocked := false
var _message_tween: Tween = null
var _wobbling := false
var _refusal := false
## A teammate's line: their name in their colour, then the rest in white (made at its first use).
var _named: HBoxContainer = null
var _named_name: Label = null
var _named_rest: Label = null


func _ready() -> void:
	if tuning == null:
		tuning = HudTuning.new()
	_crosshair.modulate = CROSSHAIR_OK


## The last input decides keyboard or pad keycaps (the old Controls.pad_active).
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad = false


func _process(_delta: float) -> void:
	_place_held()


# --- What the player tells it ----------------------------------------------------------------------

## The crosshair's prompts, one after the other (A03).
func show_target(prompts: Array[Prompt]) -> void:
	if not _changed("prompt", Prompt.signature_of(prompts)):
		return
	_clear(_prompts)
	_text["prompt"] = Prompt.joined(prompts, "   ")
	for p in prompts:
		_prompts.add_child(_prompt_row(p, PROMPT_LABEL))


## The aimed Sock or Pair: the pick key `key` and Size `letter` in its box; "" shows nothing (A01, A02).
func show_aimed(letter: String, key: String) -> void:
	if not _changed("aimed", "%s|%s" % [key, letter]):
		return
	_clear(_aimed)
	_text["aimed"] = ""
	if letter == "":
		return
	if key != "":
		_aimed.add_child(_icon(key, _font(ROW_LABEL) * KEY_SCALE))
	_aimed.add_child(_size_box(letter))
	_text["aimed"] = ("%s " % Prompt.cap_text(key) if key != "" else "") + "[%s]" % letter


## Sock Sense (A15): the aimed loose Sock as the Hands would show it once picked (`pair` when it
## would fuse with a held mate), `count` "held/capacity" then; a null `design` clears it.
func show_sense(design: SockDesign, pair := false, count := "", wheel := false) -> void:
	var sig := "" if design == null else "%d|%s|%s|%s|%s" % [design.id, pair, count, wheel, pad]
	if not _changed("sense", sig):
		return
	_clear(_sense)
	_text["sense"] = "" if design == null else _fill_readout(_sense, design, pair, count, wheel, false)


## The held readout (A14 and the base): with nothing held (`design` null) nothing; without Sock
## Smarts only the boxed Size; with it the full readout.
func show_held(design: SockDesign, pair := false, count := "", wheel := false, smarts := false) -> void:
	var sig := "" if design == null else "%d|%s|%s|%s|%s|%s" % [design.id, pair, count, wheel, smarts, pad]
	if not _changed("held", sig):
		return
	_clear(_held)
	_text["held"] = ""
	_held_size = "" if design == null else design.size_letter()
	if design == null:
		return
	if smarts:
		_text["held"] = _fill_readout(_held, design, pair, count, wheel, true)
	else:
		_held.add_child(_size_box(design.size_letter()))
		_text["held"] = "[%s]" % design.size_letter()
	_held.reset_size()
	_place_held()


## The corner's key hints (A04-A07).
func show_hints(prompts: Array[Prompt]) -> void:
	if not _changed("hints", Prompt.signature_of(prompts)):
		return
	_clear(_hints)
	_text["hints"] = Prompt.joined(prompts, "  ")
	for p in prompts:
		_hints.add_child(_prompt_row(p, HINT_LABEL))


## The message row says `text` (the player keeps it up for its time and hides it): a `refusal` in
## red, turning to and fro about its middle and dying down (core/16 P01); anything else white,
## popping in (P02, Q2370).
func say(text: String, refusal: bool) -> void:
	if _named != null:
		_named.visible = false
	_message.text = text
	_message.add_theme_color_override(&"font_color", MESSAGE_REFUSAL if refusal else MESSAGE_PLAIN)
	_message.visible = true
	_refusal = refusal
	if _message_tween != null:
		_message_tween.kill()
	_message_row.rotation = 0.0
	_message_row.scale = Vector2.ONE
	_wobbling = refusal
	_message_tween = create_tween()
	if refusal:
		_message_tween.tween_method(_wobble_at, 0.0, tuning.wobble_time, tuning.wobble_time)
	else:
		_message_row.scale = Vector2.ONE * tuning.pop_from
		_message_tween.tween_method(_pop_at, tuning.pop_from, tuning.pop_peak, tuning.pop_rise) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_message_tween.tween_method(_pop_at, tuning.pop_peak, 1.0, tuning.pop_settle) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_message_tween.tween_callback(_still)


## The message row says a teammate's line (coop/03, Q2442, the old show_named): `who` in their
## `colour`, then `rest` in white ("Player joined", "Player left"), popping in as a plain line does;
## it replaces whatever the row said.
func say_named(who: String, colour: Color, rest: String) -> void:
	say(rest, false)
	_message.visible = false
	if _named == null:
		_named = HBoxContainer.new()
		_named.name = "Named"
		_named.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_named.add_theme_constant_override(&"separation", THEME.get_constant(&"separation", HUD_TYPE))
		_named_name = _label("", ROW_LABEL)
		_named_rest = _label("", ROW_LABEL)
		_named_rest.add_theme_color_override(&"font_color", MESSAGE_PLAIN)
		_named.add_child(_named_name)
		_named.add_child(_named_rest)
		_message_row.add_child(_named)
	_named_name.text = who
	_named_name.add_theme_color_override(&"font_color", colour)
	_named_rest.text = rest
	_named.visible = true


## The message's turn `t` seconds into a refusal: `sin(t * TAU * rate) * turn`, dying down linearly
## (the old hud.gd _wobble()), about the row's middle.
func _wobble_at(t: float) -> void:
	_centre_pivot()
	var left := clampf(1.0 - t / maxf(tuning.wobble_time, 0.001), 0.0, 1.0)
	_message_row.rotation = sin(t * TAU * tuning.wobble_rate) * tuning.wobble_turn * left


func _pop_at(size: float) -> void:
	_centre_pivot()
	_message_row.scale = Vector2.ONE * size


func _still() -> void:
	_message_row.rotation = 0.0
	_message_row.scale = Vector2.ONE
	_wobbling = false


func _centre_pivot() -> void:
	_message_row.pivot_offset = _message_row.size * 0.5


## Hides the message row (its time is up).
func hide_message() -> void:
	_message.visible = false
	if _named != null:
		_named.visible = false


## What the message row says now, or "" when hidden.
func message_text() -> String:
	if _named != null and _named.visible:
		return "%s %s" % [_named_name.text, _named_rest.text]
	return _message.text if _message.visible else ""


## The colour of a teammate's name on the message row, or transparent when no teammate's line shows.
func message_name_colour() -> Color:
	if _named == null or not _named.visible:
		return Color.TRANSPARENT
	return _named_name.get_theme_color(&"font_color")


## What the message row says now when it is a refusal, or "" (none, or "Paired!").
func refusal_text() -> String:
	return message_text() if _refusal else ""


## The message's colour (MESSAGE_REFUSAL or MESSAGE_PLAIN).
func message_colour() -> Color:
	return _message.get_theme_color(&"font_color")


## How far the message row is turned now, in radians (a refusal's wobble).
func message_turn() -> float:
	return _message_row.rotation


## How big the message row is drawn now (1 at rest; "Paired!" pops).
func message_size() -> float:
	return _message_row.scale.x


## Whether a refusal is still wobbling.
func wobbling() -> bool:
	return _wobbling


## The crosshair turns red while a drop would be refused where it points, and white again (A09).
func show_blocked(on: bool) -> void:
	if on == _blocked:
		return
	_blocked = on
	_crosshair.modulate = CROSSHAIR_NO if on else CROSSHAIR_OK


# --- Read back as plain text (A13) -----------------------------------------------------------------

## "[E] Open the Door", or "".
func prompt_text() -> String:
	return _text["prompt"]


## "[LMB] [L]", or "".
func aimed_text() -> String:
	return _text["aimed"]


## "[L] Pair 2/3 Name (simple) [WHEEL]", or "".
func sense_text() -> String:
	return _text["sense"]


## "[L]" without Sock Smarts, "[L] Sock 1/3 Name (simple)" with it, or "".
func hands_text() -> String:
	return _text["held"]


## "[RMB] Drop / hold: Throw  [SPACE] Jump  ...".
func hints_text() -> String:
	return _text["hints"]


## The held item's Size letter, or "".
func held_size() -> String:
	return _held_size


## Whether the crosshair shows red.
func blocked() -> bool:
	return _blocked


## The crosshair's colour as drawn: its bars' colour (alpha 0.9) times its tint.
func crosshair_colour() -> Color:
	return _crosshair.bar_colour() * _crosshair.modulate


## The crosshair's tint (white, or red where a drop is refused).
func crosshair_tint() -> Color:
	return _crosshair.modulate


## The rows' nodes, for tests and shots: "prompt", "aimed", "sense", "held", "hints".
func row(which: String) -> HBoxContainer:
	return {"prompt": _prompts, "aimed": _aimed, "sense": _sense, "held": _held, "hints": _hints}[which]


# --- Building --------------------------------------------------------------------------------------

func _changed(which: String, sig: String) -> bool:
	if sig == _sig[which]:
		return false
	_sig[which] = sig
	rebuilds[which] += 1
	return true


## The held or aimed readout of `design` into `box`: its boxed Size (when `with_size`), its
## Collection icon and Design name, the Sock icon (the ball for a Pair), `count` and, when `wheel`,
## the wheel key. Returns the same as plain text.
func _fill_readout(box: HBoxContainer, design: SockDesign, pair: bool, count: String, wheel: bool, with_size: bool) -> String:
	var letter := design.size_letter()
	if with_size:
		box.add_child(_size_box(letter))
	box.add_child(_icon(UiIcons.or_simple(String(design.collection)), _font(ROW_LABEL) * ICON_SCALE))
	box.add_child(_label(design.name, ROW_LABEL))
	box.add_child(_icon("ball" if pair else "sock", _font(ROW_LABEL) * ICON_SCALE))
	box.add_child(_label(count, ROW_LABEL))
	var text := "[%s] %s %s %s (%s)" % [letter, "Pair" if pair else "Sock", count, design.name, design.collection]
	if wheel:
		var wheel_keys := Prompts.keys(Player.HANDS_NEXT, pad)
		if not wheel_keys.is_empty():
			box.add_child(_icon(wheel_keys[0], _font(ROW_LABEL) * KEY_SCALE))
			text += " " + Prompt.cap_text(wheel_keys[0])
	return text


## The font size of text variation `variation` in the theme.
static func _font(variation: StringName) -> int:
	return THEME.get_font_size(&"font_size", variation)


## One Prompt as KEY, ICON, Name in text `variation`; a Prompt with no keys and no icon is the bare name.
func _prompt_row(p: Prompt, variation: StringName) -> Control:
	if p.keys.is_empty() and p.icon == "":
		return _label(p.title, variation)
	var font := _font(variation)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", THEME.get_constant(&"separation", HUD_TYPE))
	for k in p.keys:
		line.add_child(_icon(k, font * KEY_SCALE))
	if p.icon != "":
		line.add_child(_icon(UiIcons.or_simple(p.icon), font * ICON_SCALE))
	line.add_child(_label(p.title, variation))
	return line


func _icon(key: String, px: float) -> TextureRect:
	var t := TextureRect.new()
	t.name = "Icon_" + key
	t.texture = UiIcons.texture(key)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _label(text: String, variation: StringName) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The Size letter in its small rounded box (the old UiBits.size_box at 28 pt).
func _size_box(letter: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.name = "SizeBox"
	box.theme_type_variation = SIZE_BOX
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_label(letter, SIZE_LETTER))
	return box


func _clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


## The held readout's left edge, vertically centred, at the screen point of the place right of the
## active item (pulled in by the zoom like the item, moved by its cloth sway: core/27 P03), pulled
## left when it would leave the screen.
func _place_held() -> void:
	if camera == null or held_view == null or hands_tuning == null or _held.get_child_count() == 0:
		return
	var depth := hands_tuning.depth
	var rest := (hands_tuning.active_pos + tuning.info_offset) * depth
	var z := held_view.zoom_amount()
	if z > 0.0:
		rest = rest.lerp((hands_tuning.zoom_pos + tuning.zoom_info_offset) * depth, z)
	var k := held_view.zoom_factor()
	# The active Sock's cloth sway carries it as far on screen as it swung the Sock's middle (P03).
	var sway := held_view.sway()
	var p := Vector3(rest.x * k + sway.x * -rest.z, rest.y * k + sway.y * -rest.z, rest.z)
	var point := camera.unproject_position(camera.global_transform * p)
	var at := point - Vector2(0.0, _held.size.y * 0.5)
	at.x = minf(at.x, _held.get_viewport_rect().size.x - _held.size.x - tuning.edge_margin)
	_held.position = at.round()
