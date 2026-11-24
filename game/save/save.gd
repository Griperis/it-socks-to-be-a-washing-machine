## Save: the game's save files, as JSON text, through one SaveStore (the autoload `Save`). The kit's
## save template (kit/skills/godot-game-dev/templates/save/), copied in and amended with the old
## game's safety (docs/architecture/saves.md, Q2553-Q2557):
##
## - A file is `{"version", "saved_at", "data"}`; `data` is plain data through `JSON.from_native`
##   (int stays int, Vector3 stays Vector3, a PackedByteArray becomes Base64). An Object in a file
##   is never built: a save can come from someone else.
## - `version` is the file's shape. An older file is brought forward by the registered steps
##   (register_migration()); a newer one is refused, never guessed at. Each Part's own state has its
##   own version too (Part.save_version(), Parts.load_save()).
## - The old file becomes the backup only when it reads, so a broken file never replaces a good
##   backup (the kit template's follow-up, fixed here). A file that does not read falls back to its
##   backup; when neither reads it is kept as `<name>.damaged` and the answer says "damaged".
## - write_later() makes the text and writes it on a worker thread (the data copied first); the next
##   write, a read or a delete waits for it. Nothing here asserts: every call answers
##   {"ok": bool, "reason": String, ...} and the game decides what to tell the player.
extends Node

## A file was written, or could not be (the old one stays): on the main thread.
signal written(name: String)
signal write_failed(name: String, reason: String)

## Where the files are. Tests put a MemoryStore here (tests/hooks.gd); the game keeps `user://`.
var store: SaveStore = LocalFileStore.new("user://")
## The shape of the file now. Files with a lower number are migrated, with a higher one refused.
var version := 1

## How a byte array is written in the file: this, then its Base64.
const BYTES := "b64:"

## from version -> Callable(data: Dictionary) -> Dictionary, the data as the next version has it.
var _migrations: Dictionary[int, Callable] = {}
## The worker's task, -1 when none runs; its file and answer once done.
var _task := -1
var _task_name := ""
var _task_result := {}
var _last := {"ok": true, "reason": ""}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## The game closes: a write still running finishes first.
func _exit_tree() -> void:
	wait()


## A write the worker finished is reported on the main thread, the frame after.
func _process(_delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		wait()


## The step from `from_version` to the next: it gets the whole data and returns it changed.
func register_migration(from_version: int, step: Callable) -> void:
	_migrations[from_version] = step


## Back to no steps and version 1 (a test's made-up version goes).
func reset() -> void:
	wait()
	_migrations.clear()
	version = 1
	store = MemoryStore.new()
	_last = {"ok": true, "reason": ""}


## Writes `data` (plain data: no Object, Callable or RID) as file `name` now, on this thread.
func write_now(name: String, data: Dictionary) -> Dictionary:
	wait()
	var r := _write(name, data)
	_report(name, r)
	return r


## Writes `data` as file `name` on a worker thread: the data is copied here, the text is made and
## written there. A write still running is waited for first.
func write_later(name: String, data: Dictionary) -> void:
	wait()
	_task_name = name
	_task_result = {}
	_task = WorkerThreadPool.add_task(_work.bind(name, data.duplicate(true)), false, "save %s" % name)


## Whether a write runs now.
func busy() -> bool:
	return _task >= 0


## Waits for a write still running; its answer (or the last write's).
func wait() -> Dictionary:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_last = _task_result
		_report(_task_name, _task_result)
	return _last


## File `name`'s data, migrated to `version`: {"ok", "reason", "data", "saved_at", "from_backup",
## "missing" (no file), "damaged" (a file that read neither way, now kept as `.damaged` unless `keep_damaged`
## is false: the Lobby's list only looks, a damaged World stays used until it is deleted), "newer"}.
func read(name: String, keep_damaged := true) -> Dictionary:
	wait()
	var got := store.read(name)
	var first := decode(String(got["text"])) if got["ok"] else _no(String(got["reason"]))
	if first["ok"] or first.get("newer", false):
		return first
	var back_file := store.read_backup(name)
	var back := decode(String(back_file["text"])) if back_file["ok"] else _no(String(back_file["reason"]))
	if back["ok"]:
		back["from_backup"] = true
		return back
	if got["ok"]:
		if keep_damaged:
			store.keep_damaged(name)
		first["damaged"] = true
		Log.warn("save", "%s reads neither way: kept as %s" % [name, name + SaveStore.DAMAGED])
	elif back_file["ok"]:
		first["damaged"] = true
	else:
		first["missing"] = true
	return first


## Whether file `name` (or its backup) is there.
func has(name: String) -> bool:
	wait()
	return store.has(name)


## File `name` goes, with its backup and half-written copy.
func delete(name: String) -> void:
	wait()
	store.begin_batch()
	store.delete(name)
	store.end_batch()


## The text of a file of `data` at this version.
func encode(data: Dictionary) -> String:
	return JSON.stringify({"version": version, "saved_at": Time.get_datetime_string_from_system(true),
			"data": JSON.from_native(_bytes_out(data))}, "\t")


## A file's text read back and migrated: {"ok", "reason", "data", "saved_at", "version" (as written),
## "from_backup": false}; "newer" when it is from a newer build.
func decode(text: String) -> Dictionary:
	var json := JSON.new()
	# JSON.parse answers with a result; JSON.parse_string would log an engine error for a cut-off file.
	if text == "" or json.parse(text) != OK or not json.data is Dictionary:
		return _no("the save does not read")
	var file: Dictionary = json.data
	if not file.get("version") is float or not file.has("data") or _names_object(file["data"]):
		return _no("the save does not read")
	var at := int(file["version"])
	var written_at := at
	if at > version:
		var newer := _no("the save is from a newer version of the game (%d, this one reads up to %d)" % [at, version])
		newer["newer"] = true
		return newer
	var data: Variant = _bytes_in(JSON.to_native(file["data"]))
	if not data is Dictionary:
		return _no("the save does not read")
	while at < version:
		if not _migrations.has(at):
			return _no("the save is version %d and nothing brings it to %d" % [at, at + 1])
		data = _migrations[at].call(data)
		if not data is Dictionary:
			return _no("the step from version %d did not return the data" % at)
		at += 1
	return {"ok": true, "reason": "", "data": data, "saved_at": str(file.get("saved_at", "")),
			"version": written_at, "from_backup": false}


func _work(name: String, data: Dictionary) -> void:
	_task_result = _write(name, data)


## The write itself (any thread): the text, then the store; the old file is kept as the backup only
## when it reads.
func _write(name: String, data: Dictionary) -> Dictionary:
	if not _plain(data):
		return _no("the data is not plain (an Object, Callable or RID in it)")
	var text := encode(data)
	var old := store.read(name)
	var keep_old: bool = old["ok"] and decode(String(old["text"]))["ok"]
	store.begin_batch()
	var r := store.write(name, text, keep_old)
	store.end_batch()
	return r


func _report(name: String, r: Dictionary) -> void:
	_last = r
	if r.get("ok", false):
		written.emit(name)
	else:
		Log.warn("save", "could not save %s: %s" % [name, r.get("reason", "")])
		write_failed.emit(name, String(r.get("reason", "")))


## Every PackedByteArray in `value` as the text "b64:<Base64>" (JSON.from_native would write each
## byte as a number: the Mess's packed state four times as big).
static func _bytes_out(value: Variant) -> Variant:
	match typeof(value):
		TYPE_PACKED_BYTE_ARRAY:
			return BYTES + Marshalls.raw_to_base64(value)
		TYPE_ARRAY:
			return (value as Array).map(_bytes_out)
		TYPE_DICTIONARY:
			var d := {}
			for k: Variant in value:
				d[k] = _bytes_out(value[k])
			return d
	return value


## _bytes_out() undone.
static func _bytes_in(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING:
			return Marshalls.base64_to_raw((value as String).substr(BYTES.length())) if (value as String).begins_with(BYTES) else value
		TYPE_ARRAY:
			return (value as Array).map(_bytes_in)
		TYPE_DICTIONARY:
			var d := {}
			for k: Variant in value:
				d[k] = _bytes_in(value[k])
			return d
	return value


static func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


## Whether `value` is plain data all the way down: no Object, Callable, Signal or RID anywhere.
static func _plain(value: Variant) -> bool:
	match typeof(value):
		TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID:
			return false
		TYPE_ARRAY:
			return (value as Array).all(_plain)
		TYPE_DICTIONARY:
			return (value as Dictionary).keys().all(_plain) and (value as Dictionary).values().all(_plain)
	return true


## Whether a parsed JSON value holds, anywhere, the encoding of an Object ({"type", "props"}) or of a
## container typed by a script: such a file is dropped before the decoder sees it.
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
