## The UI icons (assets/ui/<key>.svg, the old game's drawings in one style) and the keycap lookup the
## prompts use (assets/03, U01-U03). Look a picture up with `UiIcons.texture(key)`; ask which keycaps an
## input action shows with `UiIcons.keys_for_action(action)`. Keys are the old names: "key_lmb",
## "key_e", "pad_a", "upgrade_speed", "menu_play", "emoji_yes", a Collection id, ...
class_name UiIcons
extends RefCounted

const DIR := "res://assets/ui/"
## Keys that share another key's picture (the old Icons.ALIASES).
const ALIASES: Dictionary[String, String] = {"upgrade_carry": "carry", "key_skip": "key_space"}
## The mouse buttons' keycaps.
const MOUSE_KEYS: Dictionary[int, String] = {
	MOUSE_BUTTON_LEFT: "key_lmb",
	MOUSE_BUTTON_RIGHT: "key_rmb",
	MOUSE_BUTTON_MIDDLE: "key_mmb",
	MOUSE_BUTTON_WHEEL_UP: "key_wheel",
	MOUSE_BUTTON_WHEEL_DOWN: "key_wheel",
}
## The pad buttons' glyphs.
const PAD_BUTTONS: Dictionary[int, String] = {
	JOY_BUTTON_A: "pad_a", JOY_BUTTON_B: "pad_b", JOY_BUTTON_X: "pad_x", JOY_BUTTON_Y: "pad_y",
	JOY_BUTTON_LEFT_SHOULDER: "pad_lb", JOY_BUTTON_RIGHT_SHOULDER: "pad_rb",
	JOY_BUTTON_LEFT_STICK: "pad_l3", JOY_BUTTON_RIGHT_STICK: "pad_r3",
	JOY_BUTTON_START: "pad_start", JOY_BUTTON_BACK: "pad_back",
	JOY_BUTTON_DPAD_UP: "pad_dpad_up", JOY_BUTTON_DPAD_DOWN: "pad_dpad_down",
	JOY_BUTTON_DPAD_LEFT: "pad_dpad_left", JOY_BUTTON_DPAD_RIGHT: "pad_dpad_right",
}
## The pad axes' glyphs (a trigger, or a stick).
const PAD_AXES: Dictionary[int, String] = {
	JOY_AXIS_LEFT_X: "pad_stick_l", JOY_AXIS_LEFT_Y: "pad_stick_l",
	JOY_AXIS_RIGHT_X: "pad_stick_r", JOY_AXIS_RIGHT_Y: "pad_stick_r",
	JOY_AXIS_TRIGGER_LEFT: "pad_lt", JOY_AXIS_TRIGGER_RIGHT: "pad_rt",
}
## The keyboard keys that are named by a word rather than their letter.
const KEY_NAMES: Dictionary[int, String] = {
	KEY_SPACE: "space", KEY_CTRL: "ctrl", KEY_SHIFT: "shift", KEY_ESCAPE: "esc",
}

## Each key's icon, or null for a key with none (a miss is kept too: no file lookup twice).
static var _cache: Dictionary[String, Texture2D] = {}


## The icon for `key`, or null when there is none.
static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var file := path_of(key)
	var tex: Texture2D = load(file) if ResourceLoader.exists(file) else null
	_cache[key] = tex
	return tex


static func has(key: String) -> bool:
	return texture(key) != null


## `key` when it has an icon, else "simple": the one fallback every drawing of an icon uses.
static func or_simple(key: String) -> String:
	return key if has(key) else "simple"


## The file of an icon key (an alias gives its target's file).
static func path_of(key: String) -> String:
	return DIR + ALIASES.get(key, key) + ".svg"


## The icon key of an Upgrade row ("upgrade_speed", ...).
static func upgrade(upgrade_name: String) -> String:
	return "upgrade_" + upgrade_name


## Every icon key of the folder, sorted, read from the folder itself (an exported build lists the
## `.import` or `.remap` of each file, so those endings count).
static func all_keys() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(DIR):
		var file := f.trim_suffix(".import").trim_suffix(".remap")
		if file.ends_with(".svg") and not out.has(file.get_basename()):
			out.append(file.get_basename())
	out.sort()
	return out


## The keycap key of one input event ("key_e", "key_lmb", "pad_a"), or "" when it has no picture.
static func key_of_event(event: InputEvent) -> String:
	var key := ""
	if event is InputEventKey:
		var code: int = (event as InputEventKey).physical_keycode
		if code == KEY_NONE:
			code = (event as InputEventKey).keycode
		key = "key_" + KEY_NAMES.get(code, OS.get_keycode_string(code).to_lower())
	elif event is InputEventMouseButton:
		key = MOUSE_KEYS.get((event as InputEventMouseButton).button_index, "")
	elif event is InputEventJoypadButton:
		key = PAD_BUTTONS.get((event as InputEventJoypadButton).button_index, "")
	elif event is InputEventJoypadMotion:
		key = PAD_AXES.get((event as InputEventJoypadMotion).axis, "")
	return key if key != "" and has(key) else ""


## The keycaps an input action shows, in the order of its events, each once. `pad` picks the pad's
## glyphs instead of the keyboard's and the mouse's.
static func keys_for_action(action: StringName, pad := false) -> Array[String]:
	var out: Array[String] = []
	if not InputMap.has_action(action):
		return out
	for e in InputMap.action_get_events(action):
		var key := key_of_event(e)
		if key != "" and key.begins_with("pad_") == pad and not out.has(key):
			out.append(key)
	return out
