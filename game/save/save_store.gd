## Where save files live: the one seam every save read and write goes through (Q2564,
## docs/research/steam-cloud-saves.md). `Save` keeps the versions, the backup rule, the damaged file
## and the worker thread and only calls a store; a store keeps named text files. A backend extends
## this one step: LocalFileStore (files under `user://`, the game's) and MemoryStore (tests). A
## Steam Remote Storage or another store's backend would be one more file.
##
## A name is a relative path of lowercase letters, digits, `_`, `-` and `/`, ending in `.json`
## (`worlds/<player id>/solo.json`). Those are the synced files (Steam Auto-Cloud's pattern, written
## in docs/architecture/saves.md). What a backend keeps beside one (the half-written copy, the backup,
## the damaged file) is named by a suffix after `.json`, so the pattern never matches it: synced()
## says which is which, and a test ties every name a store writes to it.
@abstract
class_name SaveStore
extends RefCounted

## The suffixes of the local-only files kept beside a synced one.
const TEMP := ".tmp"
const BACKUP := ".bak"
const DAMAGED := ".damaged"
## The synced files' extension: the Auto-Cloud pattern is `*.json` under `worlds/`.
const SYNCED_EXT := ".json"


## The text of file `name`: {"ok", "text", "reason"}.
@abstract func read(name: String) -> Dictionary


## The text of file `name`'s backup (the file before the last write): {"ok", "text", "reason"}.
@abstract func read_backup(name: String) -> Dictionary


## Writes `text` as file `name`, whole. `keep_old`: the file there now becomes the backup (only when
## it reads, Save decides); else the backup is left as it is. On any failure the old file stays:
## {"ok", "reason"}.
@abstract func write(name: String, text: String, keep_old: bool) -> Dictionary


## Whether file `name` (or its backup) is there.
@abstract func has(name: String) -> bool


## The synced files directly in `folder` ("worlds/<player id>"), names relative to the store, sorted.
@abstract func list(folder: String) -> PackedStringArray


## File `name`, its backup and its half-written copy go (a damaged copy stays).
@abstract func delete(name: String) -> void


## File `name` reads neither way: it is kept as `<name>.damaged` (for a tester to send) and goes.
@abstract func keep_damaged(name: String) -> void


## Every name this store holds now, synced and local-only (a test checks them against the pattern).
@abstract func all_names() -> PackedStringArray


## The writes and deletes until end_batch() form one change (Steam's file-write batch hint when a
## Steam backend is present; nothing for a local folder).
func begin_batch() -> void:
	pass


func end_batch() -> void:
	pass


## Whether `name` is a file name a store accepts: lowercase letters, digits, `_`, `-`, `/` between
## parts, one `.json` at the end, at most 200 characters.
static func valid(name: String) -> bool:
	if name.length() > 200 or not name.ends_with(SYNCED_EXT) or name.begins_with("/") or name.contains("//"):
		return false
	var stem := name.trim_suffix(SYNCED_EXT)
	if stem == "" or stem.contains("."):
		return false
	for c in stem:
		if not ((c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_" or c == "-" or c == "/"):
			return false
	return true


## Whether `name` is a synced file (Steam Auto-Cloud's pattern: under `worlds/`, ending in `.json`).
## Every local-only name (`.tmp`, `.bak`, `.damaged`) is not.
static func synced(name: String) -> bool:
	return name.begins_with("worlds/") and name.ends_with(SYNCED_EXT) and valid(name)


static func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "text": ""}
