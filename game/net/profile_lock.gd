## Two copies of a debug build on one PC share `user://`, so both would read `profile.json` and be one
## player (Q2458), and the Host would refuse the other's join. Each running copy takes a profile of its own
## instead (the old game's ProfileLock, lobby/04): the first keeps "" (`profile.json`), a second takes "2"
## (`profile_2.json`), then "3" and so on. A copy holds its profile with "<profile>.lock" beside it: its process
## id and a time stamp it renews while it runs and removes on quit. A lock whose stamp is old (a crash, a kill)
## is free again, so a copy alone gets its own profile back. The stamp is the test, not the process id: Godot
## can only tell whether its own child processes run. A release build never does this (one player, one profile).
class_name ProfileLock
extends Node

## The most profiles one PC's copies take; more copies share the last.
const SLOTS := 8
## How often the running copy renews its stamp, and how old a stamp may be before its lock is free (seconds).
const RENEW := 2.0
const STALE := 30.0

## The lock this process holds (one per process).
static var held: ProfileLock = null

var lock_path := ""
var _since := 0.0


## The tag of slot `n` (1 first): "" then "2", "3"...
static func tag_of(n: int) -> String:
	return "" if n <= 1 else str(n)


## The lock file beside the profile of `tag` in `folder`.
static func lock_of(tag: String, folder: String) -> String:
	return PlayerProfile.file_of(tag, folder).get_basename() + ".lock"


## Whether a lock reading `text` ("<pid> <unix time>") is held against process `own` at `now`: another
## process's, stamped within STALE.
static func holds(text: String, own: int, now: float) -> bool:
	var bits := text.strip_edges().split(" ", false)
	if bits.size() != 2 or not bits[0].is_valid_int() or not bits[1].is_valid_float():
		return false
	return bits[0].to_int() != own and absf(now - bits[1].to_float()) < STALE


## The first tag no other running copy holds, now held by process `own` (its lock written).
static func pick(folder: String, own: int, now: float) -> String:
	for n in range(1, SLOTS + 1):
		var lock := lock_of(tag_of(n), folder)
		if n < SLOTS and FileAccess.file_exists(lock) and holds(FileAccess.get_file_as_string(lock), own, now):
			continue
		stamp(lock, own, now)
		return tag_of(n)
	return tag_of(1)


static func stamp(lock: String, own: int, now: float) -> void:
	var f := FileAccess.open(lock, FileAccess.WRITE)
	if f != null:
		f.store_string("%d %d" % [own, int(now)])


## The lock node of `tag`, to go under the tree's root: it keeps the stamp fresh and shows which player this
## copy is in the window title.
static func keep(tree: SceneTree, tag: String, folder: String) -> void:
	if held != null:
		return
	held = ProfileLock.new()
	held.name = "ProfileLock"
	held.lock_path = lock_of(tag, folder)
	tree.root.add_child.call_deferred(held)
	if tag != "":
		tree.root.title = "%s (Player %s)" % [tree.root.title, tag]


func _process(delta: float) -> void:
	_since += delta
	if _since >= RENEW:
		_since = 0.0
		stamp(lock_path, OS.get_process_id(), Time.get_unix_time_from_system())


func _exit_tree() -> void:
	if FileAccess.file_exists(lock_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lock_path))
	if held == self:
		held = null
