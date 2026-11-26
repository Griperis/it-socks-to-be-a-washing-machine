## The level's saving (docs/architecture/saves.md; Q2555): it loads the World handed to the level and
## keeps it saved. Only the Host, or a player alone, saves (Q249): a Guest's never does.
##
## - The save is the join snapshot written to a file: every Part's save_state() by id (Parts), with
##   the World's record. No feature writes save code.
## - Within `autosave_seconds` of any applied change it saves, the text made and written on a worker
##   thread (Save.write_later()); on every way out (Back to title, Quit game, End session, the
##   window's close) it saves at once (save_now()). Never before the World is loaded.
## - A save that cannot be written keeps the old file, and the HUD says so once until a save works
##   again (Q2556).
## - The Solo World played with a Guest becomes a co-op World in a free slot (Q1646, Q1737).
class_name Autosave
extends Node

## The Host or a player alone loaded a saved World's Parts (restore(); core/134's ProfileRecorder listens).
signal restored

## The HUD's line when a save could not be written (Q2556). placeholder: the designer's wording.
const FAILED := "Could not save the game"

@export var parts: Parts
## The game link's Session (LevelRuntime sets it as it enters the tree: it lives outside the level).
var session: Session
@export var tuning: SaveTuning

## The World this level plays; null saves nothing (LevelRuntime sets it from its own).
var world: WorldSlot = null
## A change not saved yet.
var dirty := false
## The HUD said the save failed; it says it again only after a save worked.
var told_failed := false

var _since := 0.0
var _loaded := false
var _moved_from := ""


func _ready() -> void:
	parts.applied.connect(_on_applied)
	Save.written.connect(_on_written)
	Save.write_failed.connect(_on_failed)


## The Host or a player alone, before anyone enters (LevelNet.start()): the World's saved Parts are
## loaded (Parts.load_save(), with Q2559's resets; `host` is this player's id). From now on it saves.
func restore(host: String) -> void:
	if world == null or _loaded:
		return
	if not world.is_new:
		parts.load_save(world.parts, world.versions, host)
		restored.emit()
	_loaded = true
	dirty = true


## Whether this machine keeps the World saved: a World is loaded here, and it decides (not a Guest).
func saves() -> bool:
	return world != null and _loaded and parts.is_host()


## The file as it would be written now: the World's record and every Part's saved state.
func collect() -> Dictionary:
	var rec := world.record
	rec.last_played = int(Time.get_unix_time_from_system())
	# The World's row names its floor: the run's current Stage's title (a level with no run keeps "").
	var stages := get_tree().get_first_node_in_group(Stages.GROUP) as Stages if is_inside_tree() else null
	if stages != null:
		rec.floor_name = stages.floor_title()
	var roster := session.roster if session != null else null
	if roster != null:
		for pid: Variant in roster.players:
			var e: Dictionary = roster.players[pid]
			rec.members[String(pid)] = {"name": String(e.get("name", PlayerProfile.NAME)), "colour": int(e.get("colour", 0))}
	return {"world": rec.to_dict(), "parts": parts.save_snapshot(), "versions": parts.save_versions()}


## The run ended (core/96): the World's record is finished, its play time stops, and it is saved so. Every machine
## calls it; only the Host's World is kept.
func mark_finished() -> void:
	if world == null or world.record.finished:
		return
	world.record.finished = true
	dirty = true
	if saves():
		save_later()


## Saves at once and waits for the file (every way out). Its answer; ok when nothing is to be saved.
func save_now() -> Dictionary:
	if not saves():
		return {"ok": true, "reason": ""}
	_go_coop_if_shared()
	dirty = false
	_since = 0.0
	return Save.write_now(world.file, collect())


## Saves on the worker thread (the autosave).
func save_later() -> void:
	if not saves():
		return
	_go_coop_if_shared()
	dirty = false
	_since = 0.0
	Save.write_later(world.file, collect())


func _process(delta: float) -> void:
	if not saves():
		return
	if not world.record.finished:
		world.record.play_time += delta
	if dirty:
		_since += delta
		if _since >= tuning.autosave_seconds:
			save_later()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


## The scene leaves with a change not saved (a way out that did not save first): saved now, while the
## Mess still holds its Socks (old maintenance/76).
func _exit_tree() -> void:
	if saves() and dirty:
		save_now()


func _on_applied(ev: Dictionary) -> void:
	if ev.get("ok", false):
		dirty = true


func _on_written(file: String) -> void:
	if world == null or file != world.file:
		return
	told_failed = false
	if _moved_from != "":
		Save.delete(_moved_from)
		_moved_from = ""


func _on_failed(file: String, _reason: String) -> void:
	if world == null or file != world.file or told_failed:
		return
	told_failed = true
	var runtime := LevelRuntime.of(self)
	if runtime != null and runtime.player != null:
		runtime.player.notice(FAILED, tuning.failed_line_seconds)


## The Solo World with a Guest in it becomes a co-op World in a free slot; the Solo file goes once the
## co-op one is written. Full, it stays the Solo World.
func _go_coop_if_shared() -> void:
	if world.slot != Worlds.SOLO or session == null or session.roster == null:
		return
	var guests := Array(session.roster.peers()).filter(func(p: int) -> bool: return p != Roster.HOST)
	if guests.is_empty():
		return
	var folder := world.file.get_base_dir()
	for slot in Worlds.coop_slots():
		var file := folder.path_join(slot + SaveStore.SYNCED_EXT)
		if not Save.has(file):
			_moved_from = world.file
			world.slot = slot
			world.file = file
			world.record.kind = WorldRecord.COOP
			Log.info("save", "the Solo World is played with a Guest: it becomes %s" % slot)
			return
	Log.warn("save", "the Solo World is played with a Guest, but every co-op slot is used: it stays solo")
