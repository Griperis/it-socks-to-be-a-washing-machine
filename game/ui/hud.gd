## The player's screen (core/15, the old hud.gd): the crosshair and its red, the crosshair's prompt
## row at 58 % of the height (32 pt), the aimed Sock's row at 63 % (28 pt: the pick key and the Size
## letter in its box, then Sock Sense's readout), the message at 70 % (28 pt), the key hints bottom
## right (24 pt), and the held readout beside the held item (28 pt: the boxed Size, or with Sock
## Smarts the Collection, Design name, Sock or Pair, n/capacity and the wheel). The rows are nodes of
## player.tscn under this layer; each is rebuilt only when what it says changed (A08). Every row
## reads back as plain text for tests (A13). It shows what the player tells it; it decides nothing.
class_name Hud
extends CanvasLayer

## The text sizes (the old HUD's): prompts, rows, hints. Keys are drawn 1.5 times the text, icons 1.3.
const PROMPT_FONT := 32
const ROW_FONT := 28
const HINT_FONT := 24
const KEY_SCALE := 1.5
const ICON_SCALE := 1.3
## The theme variations of each text (game/look/theme.tres).
const PROMPT_LABEL := &"PromptLabel"
const ROW_LABEL := &"RowLabel"
const HINT_LABEL := &"HintLabel"
const SIZE_BOX := &"SizeBox"
const SIZE_LETTER := &"SizeLetter"
## The crosshair where a drop may go, and where it may not (the old REFUSE red; the bars carry the
## alpha 0.9, A10).
const CROSSHAIR_OK := Color.WHITE
const CROSSHAIR_NO := Color(0.95, 0.25, 0.2)

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

var _sig: Dictionary[String, String] = {"prompt": "", "aimed": "", "sense": "", "held": "", "hints": ""}
var _text: Dictionary[String, String] = {"prompt": "", "aimed": "", "sense": "", "held": "", "hints": ""}
var _held_size := ""
var _blocked := false


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
		_prompts.add_child(_prompt_row(p, PROMPT_FONT, PROMPT_LABEL))


## The aimed Sock or Pair: the pick key `key` and Size `letter` in its box; "" shows nothing (A01, A02).
func show_aimed(letter: String, key: String) -> void:
	if not _changed("aimed", "%s|%s" % [key, letter]):
		return
	_clear(_aimed)
	_text["aimed"] = ""
	if letter == "":
		return
	if key != "":
		_aimed.add_child(_icon(key, ROW_FONT * KEY_SCALE))
	_aimed.add_child(_size_box(letter))
	_text["aimed"] = ("%s " % Prompt.cap_text(key) if key != "" else "") + "[%s]" % letter


## Sock Sense (A15): the aimed loose Sock as the Hands would show it once picked (`pair` when it
## would fuse with a held mate), `count` "held/capacity" then; a null `design` clears it.
func show_sense(design: SockDesign, pair := false, count := "", wheel := false) -> void:
	var sig := "" if design == null else "%d|%s|%s|%s" % [design.id, pair, count, wheel]
	if not _changed("sense", sig):
		return
	_clear(_sense)
	_text["sense"] = "" if design == null else _fill_readout(_sense, design, pair, count, wheel, false)


## The held readout (A14 and the base): with nothing held (`design` null) nothing; without Sock
## Smarts only the boxed Size; with it the full readout.
func show_held(design: SockDesign, pair := false, count := "", wheel := false, smarts := false) -> void:
	var sig := "" if design == null else "%d|%s|%s|%s|%s" % [design.id, pair, count, wheel, smarts]
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
		_hints.add_child(_prompt_row(p, HINT_FONT, HINT_LABEL))


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
	box.add_child(_icon(UiIcons.or_simple(String(design.collection)), ROW_FONT * ICON_SCALE))
	box.add_child(_label(design.name, ROW_LABEL))
	box.add_child(_icon("ball" if pair else "sock", ROW_FONT * ICON_SCALE))
	box.add_child(_label(count, ROW_LABEL))
	var text := "[%s] %s %s %s (%s)" % [letter, "Pair" if pair else "Sock", count, design.name, design.collection]
	if wheel:
		var wheel_keys := Prompts.keys(Player.HANDS_NEXT, pad)
		if not wheel_keys.is_empty():
			box.add_child(_icon(wheel_keys[0], ROW_FONT * KEY_SCALE))
			text += " " + Prompt.cap_text(wheel_keys[0])
	return text


## One Prompt as KEY, ICON, Name; a Prompt with no keys and no icon is the bare name.
func _prompt_row(p: Prompt, font: int, variation: StringName) -> Control:
	if p.keys.is_empty() and p.icon == "":
		return _label(p.title, variation)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", 6)
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
## active item (pulled in by the zoom like the item), pulled left when it would leave the screen.
func _place_held() -> void:
	if camera == null or held_view == null or hands_tuning == null or _held.get_child_count() == 0:
		return
	var depth := hands_tuning.depth
	var rest := (hands_tuning.active_pos + tuning.info_offset) * depth
	var z := held_view.zoom_amount()
	if z > 0.0:
		rest = rest.lerp((hands_tuning.zoom_pos + tuning.zoom_info_offset) * depth, z)
	var k := held_view.zoom_factor()
	var point := camera.unproject_position(camera.global_transform * Vector3(rest.x * k, rest.y * k, rest.z))
	var at := point - Vector2(0.0, _held.size.y * 0.5)
	at.x = minf(at.x, _held.get_viewport_rect().size.x - _held.size.x - tuning.edge_margin)
	_held.position = at.round()
