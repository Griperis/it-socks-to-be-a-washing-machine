## Settings: the player's options, kept as JSON at `user://settings.json`. Register it as an
## autoload named `Settings` (copy this folder to `game/settings/`; see templates/README.md).
##
## A key is "section/name" ("audio/master_volume"). Values are PLAIN data only: bool, int, float,
## String, Vector2, Color, and Arrays or Dictionaries of those. Never an Object (a Resource, a Node, an
## InputEvent): a settings file can come from someone else, and an object read from a file brings
## its script. That decides the file format. `ConfigFile`, `str_to_var` and
## `FileAccess.get_var(true)` build an `Object(...)` they find in the text WHILE they parse it,
## its script's `_init` included (measured on 4.7): a type check afterwards is too late. This file
## is JSON, each value written with `JSON.from_native` and read with `JSON.to_native`, which keep
## int, float, Vector2, Color and typed arrays apart and refuse objects unless asked.
##
## What the engine owns (window mode, vsync, master volume) is applied here, on load and on every
## change. Every other key is only kept: the game reads it with `get_bool/get_int/...` and listens to
## `changed`. A game adds its own keys with `register()` (defaults), before the first read.
extends Node

## A setting changed (by `set_value`, a reset, or a load): the key, e.g. "audio/master_volume".
signal changed(key: String)

const DEFAULT_PATH := "user://settings.json"
## The keys the engine owns, with their defaults. window_mode: "windowed", "fullscreen" (the
## desktop-sized borderless window) or "exclusive" (exclusive fullscreen). master_volume: 0.0 to 1.0.
const BUILT_IN := {
	"display/window_mode": "windowed",
	"display/vsync": true,
	"audio/master_volume": 1.0,
}

## How `JSON.from_native` marks a String, an int, a float, a StringName and a NodePath.
const NATIVE_PREFIX: Array[String] = ["s:", "i:", "f:", "sn:", "np:"]

## Where the file lives. A test sets its own path before the node enters the tree.
var path := DEFAULT_PATH
## Write the file after every change (off in a test that must not touch the disk).
var autosave := true

var _defaults := {}
var _values := {}


func _init() -> void:
	register(BUILT_IN)


func _ready() -> void:
	# Keeps working while the tree is paused (an options screen opened from the pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_file()


# --- Defaults and plain access -------------------------------------------------------------------


## Declares keys and their defaults ({"game/difficulty": 1, ...}). The default's type is the key's
## type: a loaded or set value of another type is turned into it when it can be, else dropped.
func register(defaults: Dictionary) -> void:
	for key: String in defaults:
		if not _valid_key(key) or not is_plain(defaults[key]):
			Log.error("settings", "register: '%s' is not a section/name key with a plain default" % key)
			continue
		_defaults[key] = defaults[key]


## The value of `key`: what was set, else its default, else `fallback`.
func get_value(key: String, fallback: Variant = null) -> Variant:
	if _values.has(key):
		return _values[key]
	return _defaults.get(key, fallback)


func get_bool(key: String) -> bool:
	return bool(get_value(key, false))


func get_int(key: String) -> int:
	return int(get_value(key, 0))


func get_float(key: String) -> float:
	return float(get_value(key, 0.0))


func get_string(key: String) -> String:
	return str(get_value(key, ""))


## Sets `key`; false (and an error) when the value is not plain data or has the wrong type.
## Applies it when the engine owns it, emits `changed`, and saves when `autosave`.
func set_value(key: String, value: Variant) -> bool:
	if not _valid_key(key):
		Log.error("settings", "set_value: '%s' is not a section/name key" % key)
		return false
	if not is_plain(value):
		Log.error("settings", "set_value: '%s' must be plain data, not an Object" % key)
		return false
	var fixed: Variant = _fit(key, value)
	if fixed == null:
		Log.error("settings", "set_value: '%s' has the wrong type (%s)" % [key, type_string(typeof(value))])
		return false
	if get_value(key) == fixed and typeof(get_value(key)) == typeof(fixed):
		return true
	_values[key] = fixed
	_apply(key)
	changed.emit(key)
	if autosave:
		save()
	return true


## Puts one key back to its default (it leaves the file).
func reset_key(key: String) -> void:
	if not _values.has(key):
		return
	_values.erase(key)
	_apply(key)
	changed.emit(key)
	if autosave:
		save()


## Puts every key back to its default.
func reset_to_defaults() -> void:
	var keys := _values.keys()
	_values.clear()
	for key: String in keys:
		_apply(key)
		changed.emit(key)
	if autosave:
		save()


## The keys that start with `prefix` ("input/") and hold a value now.
func keys_under(prefix: String) -> Array[String]:
	var out: Array[String] = []
	for key: String in _values:
		if key.begins_with(prefix):
			out.append(key)
	return out


# --- The three the engine owns -------------------------------------------------------------------

var window_mode: String:
	get: return get_string("display/window_mode")
	set(v): set_value("display/window_mode", v)

var vsync: bool:
	get: return get_bool("display/vsync")
	set(v): set_value("display/vsync", v)

## 0.0 (silent) to 1.0 (full), on the Master bus.
var master_volume: float:
	get: return get_float("audio/master_volume")
	set(v): set_value("audio/master_volume", clampf(v, 0.0, 1.0))


## Applies every engine-owned key (after a load).
func apply_all() -> void:
	for key: String in BUILT_IN:
		_apply(key)


func _apply(key: String) -> void:
	match key:
		"display/window_mode":
			match window_mode:
				"fullscreen":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				"exclusive":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
				_:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"display/vsync":
			DisplayServer.window_set_vsync_mode(
					DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		"audio/master_volume":
			var bus := AudioServer.get_bus_index("Master")
			AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume))
			AudioServer.set_bus_mute(bus, master_volume <= 0.0)


# --- The file ------------------------------------------------------------------------------------


## Writes every set value; OK or the error. The text goes to a temp file that then takes the real
## file's place, so a crash or a full disk mid-write leaves the old settings, never half a file.
func save() -> Error:
	var out := {}
	for key: String in _values:
		out[key] = JSON.from_native(_values[key])
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(out, "\t", true) + "\n")
	f.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


## Reads the file (a missing or unreadable one is fine: defaults). Anything that is not plain data,
## or has the wrong type for a registered key, is dropped. Applies the engine-owned keys. Emits
## `changed` for every key it set.
func load_file() -> void:
	_values.clear()
	var json := JSON.new()
	# JSON.parse reports a broken file as a result; JSON.parse_string would log an engine error.
	if FileAccess.file_exists(path) and json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		for key: Variant in data:
			if not key is String or not _valid_key(key):
				continue
			var value: Variant = _decode(data[key])
			if value == null or not is_plain(value):
				continue
			var fixed: Variant = _fit(key, value)
			if fixed != null:
				_values[key] = fixed
	apply_all()
	for key: String in _values:
		_apply(key)
		changed.emit(key)


## One value of the file as plain data, or null when it is not. What `JSON.from_native` wrote comes
## back through `JSON.to_native`, which builds no object; a number or a text typed in by hand is
## taken as it is; an object's encoding ({"type": ..., "props": [...]}) and a container typed by a
## script are dropped before the decoder ever sees them.
static func _decode(encoded: Variant) -> Variant:
	if encoded is bool or encoded is float or encoded is int:
		return encoded
	if encoded is String and not NATIVE_PREFIX.any(func(p: String) -> bool: return (encoded as String).begins_with(p)):
		return encoded
	if _names_object(encoded):
		return null
	return JSON.to_native(encoded)


## Whether a parsed JSON value holds, anywhere, the encoding of an Object or of a script-typed container.
static func _names_object(encoded: Variant) -> bool:
	if encoded is Array:
		return (encoded as Array).any(_names_object)
	if encoded is Dictionary:
		var d: Dictionary = encoded
		if d.has("props"):
			return true
		for k: String in ["elem_type", "key_type", "value_type"]:
			if str(d.get(k, "")).contains("/"):
				return true
		return d.values().any(_names_object)
	return false


## Whether `value` is plain data all the way down: no Object, Callable, Signal or RID anywhere.
static func is_plain(value: Variant) -> bool:
	match typeof(value):
		TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID:
			return false
		TYPE_ARRAY:
			for item: Variant in value:
				if not is_plain(item):
					return false
		TYPE_DICTIONARY:
			for k: Variant in value:
				if not is_plain(k) or not is_plain(value[k]):
					return false
	return true


func _valid_key(key: String) -> bool:
	var at := key.find("/")
	return at > 0 and at < key.length() - 1


## `value` as the type the key's default has (an int where a float is meant becomes one), or null
## when it cannot be. A key with no default keeps whatever plain type it came with.
func _fit(key: String, value: Variant) -> Variant:
	if not _defaults.has(key):
		return value
	var want := typeof(_defaults[key])
	if typeof(value) == want:
		return value
	if want == TYPE_FLOAT and typeof(value) == TYPE_INT:
		return float(value)
	# A whole number typed by hand into the file reads as a float.
	if want == TYPE_INT and typeof(value) == TYPE_FLOAT and value == floorf(value):
		return int(value)
	return null
