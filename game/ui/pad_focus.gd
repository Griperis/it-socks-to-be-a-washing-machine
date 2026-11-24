## The lit look of the pad's and keyboard's selection (core/75, Q2647; the old PadFocus): the selected control
## lifts, grows about its centre and a soft glow fades in behind it. Only a key or pad selection lights it, never a
## mouse click (Q2648); the Theme's focus style is empty, the lift is the mark. A slider only glows (lifting and
## growing a thin track would pull it off its label).
##
## Adding a button needs nothing: `UiSounds` (the menus' autoload) feeds `on_input` the window's input and
## `on_focus_changed` the root viewport's focus changes, so every focusable button, slider and text field lights.
## To opt a control out set the meta `own_lit` on it (it lights itself, like a Lobby plinth). The lit amount `t` (0 to 1) is a stored value, because a
## container's layout sets a child's position and scale on every re-layout: each tween step and each finished layout
## of the parent (its `sort_children`) apply `t` again.
class_name PadFocus
extends RefCounted

const TUNING := preload("res://game/ui/pad_focus_tuning.tres")
const GLOW := "FocusGlow"
const META_T := &"pad_lit_t"
const META_APPLIED := &"pad_lit_applied"
const META_TWEEN := &"pad_lit_tween"
const META_PARENT := &"pad_lit_parent"
const META_LIT := &"pad_lit"
## A control with this meta lights itself (a Lobby figure's plinth): it is left alone.
const META_OWN := &"own_lit"

## Whether the last press was a key or pad one: a focus that comes now is lit.
static var pad_used := false


## Whether `n` is a control this look is for.
static func is_target(n: Node) -> bool:
	return n is BaseButton or n is Slider or n is LineEdit


## Sets `pad_used` from `event`: a key or pad press sets it, a mouse button clears it, a motion changes nothing.
static func on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		pad_used = false
	elif (event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction) and event.is_pressed():
		pad_used = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		pad_used = true


## Whether `c` is lit now (the tests read it).
static func is_lit(c: Control) -> bool:
	return bool(c.get_meta(META_LIT, false))


## Called by the root viewport's `gui_focus_changed`: puts the light out on the control that had the focus and
## lights the one that has it now, when the last press was a key or pad one. Nothing is done per control.
static func on_focus_changed(c: Control) -> void:
	if is_instance_valid(_current) and _current != c:
		_light(_current, false)
	_current = c
	if c != null and pad_used and is_target(c) and not c.has_meta(META_OWN):
		_prepare(c)
		_light(c, true)


static var _current: Control = null


## Makes the glow behind `c` and the re-apply after its container's layout, once.
static func _prepare(c: Control) -> void:
	if c.has_meta(META_T):
		return
	c.set_meta(META_T, 0.0)
	c.set_meta(META_APPLIED, 0.0)
	var glow := Panel.new()
	glow.name = GLOW
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.show_behind_parent = true
	glow.modulate.a = 0.0
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.set_corner_radius_all(TUNING.glow_radius)
	box.shadow_color = Color(TUNING.glow_colour, TUNING.glow_alpha)
	box.shadow_size = TUNING.glow_size
	glow.add_theme_stylebox_override(&"panel", box)
	c.add_child(glow, false, Node.INTERNAL_MODE_FRONT)
	var parent := c.get_parent() as Container
	if parent != null and not parent.has_meta(META_PARENT):
		parent.set_meta(META_PARENT, true)
		parent.sort_children.connect(_after_parent_layout.bind(parent))


static func _light(c: Control, on: bool) -> void:
	if not c.has_meta(META_T):
		return  # never lit: nothing to put out
	c.set_meta(META_LIT, on)
	c.z_index = 1 if on else 0
	if c.has_meta(META_TWEEN):
		(c.get_meta(META_TWEEN) as Tween).kill()
	var to := 1.0 if on else 0.0
	if not c.is_inside_tree():
		_apply(to, c)
		return
	var tw := c.create_tween()
	tw.tween_method(_apply.bind(c), float(c.get_meta(META_T)), to, TUNING.time)
	c.set_meta(META_TWEEN, tw)


## Every hooked child of `parent`, after its layout.
static func _after_parent_layout(parent: Container) -> void:
	if not is_instance_valid(parent):
		return
	for ch in parent.get_children():
		if ch is Control and ch.has_meta(META_T):
			var c := ch as Control
			c.set_meta(META_APPLIED, 0.0)  # the layout put the position back to its own
			_apply(float(c.get_meta(META_T)), c)


## Sets the look for the lit amount `v`. The lift is a delta on the layout's position, so the part applied
## before is taken off first.
static func _apply(v: float, c: Control) -> void:
	if not is_instance_valid(c):
		return
	c.set_meta(META_T, v)
	for ch in c.get_children(true):
		if ch.name == GLOW:
			(ch as Control).modulate.a = v
	if c is Slider:
		return
	var applied := float(c.get_meta(META_APPLIED))
	c.set_meta(META_APPLIED, TUNING.lift * v)
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2.ONE * lerpf(1.0, TUNING.grow, v)
	c.position.y = c.position.y + applied - TUNING.lift * v
