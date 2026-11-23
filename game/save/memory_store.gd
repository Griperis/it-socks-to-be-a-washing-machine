## The save files kept in memory: what tests save into, so no case touches a player's folder. It
## keeps the same names a folder would (the file, its backup, a damaged copy) and can be told to
## fail every write, as a full disk would.
class_name MemoryStore
extends SaveStore

## Every write fails while this is set (the old file stays).
var fail_writes := false
## How many writes succeeded, and the batches begun and ended.
var writes := 0
var batches := 0
## The files by name, the backups and damaged copies under their own names (`<name>.bak`).
var files: Dictionary[String, String] = {}
## How long each write takes, in milliseconds (a slow disk, for the worker-thread case).
var write_ms := 0

var _lock := Mutex.new()


func read(name: String) -> Dictionary:
	return _fetch(name)


func read_backup(name: String) -> Dictionary:
	return _fetch(name + BACKUP)


func write(name: String, text: String, keep_old: bool) -> Dictionary:
	if not valid(name):
		return _no("'%s' is not a save file name" % name)
	if write_ms > 0:
		OS.delay_msec(write_ms)
	if fail_writes:
		return _no("cannot write %s (the disk is full)" % name)
	_lock.lock()
	if files.has(name) and keep_old:
		files[name + BACKUP] = files[name]
	files[name] = text
	writes += 1
	_lock.unlock()
	return {"ok": true, "reason": ""}


func has(name: String) -> bool:
	return files.has(name) or files.has(name + BACKUP)


func list(folder: String) -> PackedStringArray:
	var out := PackedStringArray()
	var prefix := folder.trim_suffix("/") + "/"
	for name: String in files:
		if name.begins_with(prefix) and not name.trim_prefix(prefix).contains("/") and valid(name):
			out.append(name)
	out.sort()
	return out


func delete(name: String) -> void:
	for suffix: String in ["", BACKUP, TEMP]:
		files.erase(name + suffix)


func keep_damaged(name: String) -> void:
	if files.has(name):
		files[name + DAMAGED] = files[name]
		files.erase(name)


func all_names() -> PackedStringArray:
	var out := PackedStringArray(files.keys())
	out.sort()
	return out


func begin_batch() -> void:
	batches += 1


func _fetch(name: String) -> Dictionary:
	_lock.lock()
	var there := files.has(name)
	var text: String = files.get(name, "")
	_lock.unlock()
	if not there:
		return _no("no file %s" % name)
	return {"ok": true, "text": text, "reason": ""}
