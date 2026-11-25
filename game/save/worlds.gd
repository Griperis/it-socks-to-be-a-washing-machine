## The Worlds on this machine (the autoload `Worlds`; Q2554: the old slots without the Group lock):
## one Solo World and up to SaveTuning.coop_slots co-op Worlds, each its own file
## `worlds/<player id>/<slot>.json` in Save's store (Q2566: each player's own folder). Until the Lobby
## piece (Q2561) Solo continues the Solo World or starts one, and Host the last-played co-op World
## or a New Game in a free slot. A World's file that fell back to its backup, or read neither way,
## leaves the title one line to say so (take_notice()).
extends Node

const SOLO := "solo"
const COOP := "coop%d"
const FOLDER := "worlds"
const LEVEL := "res://game/house/house.tscn"
## The title's one-time lines (Q1188, Q1189, Q1502, Q1503). placeholder: the old wording.
const FROM_BACKUP := "Loaded your previous save"
const DAMAGED := "Your laundry got lost in the wash. Starting fresh."
const NEWER := "This World was saved by a newer version of It Socks"
const FULL := "All %d co-op Worlds are used: delete one first"
## A row's words (the old title's). placeholder: the old wording.
const SOLO_WORLD := "Solo World"
const NO_GROUP := "No Group yet"
const NUMBERED_WORLD := "World %d"
## The two forms of a co-op World's row name (Q2587): the members' names, or "World <n>" (the details and the
## members' colours sit under it). The Lobby look's first still shows both; the designer judges.
enum NameForm {MEMBERS, NUMBERED}
## The form in use; placeholder until the designer judges the still.
static var name_form := NameForm.MEMBERS
const DAMAGED_WORLD := "Damaged World"
## A finished World's row begins its details with this (core/97). placeholder: the old wording.
const FINISHED := "Finished"

var tuning: SaveTuning = preload("res://game/save/save_tuning.tres")
## What the title shows once when it comes back ("" for nothing): why a session ended, a save that
## fell back. take_notice() reads and clears it.
var notice := ""
## `--new-game` (debug builds): Solo and Host start a New Game over their World.
var new_game := false

var _profile: PlayerProfile = null


func _ready() -> void:
	new_game = OS.is_debug_build() and OS.get_cmdline_user_args().has("--new-game")


## The player the Worlds are kept under: `user://profile.json`, or `--profile=<tag>`'s.
func profile() -> PlayerProfile:
	if _profile == null:
		var tag := ""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--profile="):
				tag = arg.trim_prefix("--profile=")
		_profile = PlayerProfile.load_or_make(tag)
	return _profile


## Another player's Worlds from now on (a test's in-memory profile).
func use_profile(p: PlayerProfile) -> void:
	_profile = p


## Back to a fresh start (tests): no notice, no flag, a fresh in-memory profile.
func reset() -> void:
	notice = ""
	new_game = false
	_profile = PlayerProfile.fresh()


## The file of `slot` in Save's store.
func file_of(slot: String) -> String:
	return "%s/%s/%s.json" % [FOLDER, profile().id.to_lower(), slot]


func coop_slots() -> PackedStringArray:
	var out := PackedStringArray()
	for i in tuning.coop_slots:
		out.append(COOP % (i + 1))
	return out


## The title's line, once.
func take_notice() -> String:
	var n := notice
	notice = ""
	return n


## The Solo World: the saved one, or a New Game when there is none (or `--new-game`). null when it
## cannot be played (a newer build's file): the notice says why.
func pick_solo() -> WorldSlot:
	return _pick(SOLO, false)


## The World a Host plays: the last-played co-op World that reads, else a New Game in a free co-op
## slot. `from_command_line` (`--host`): the newest co-op World, else the Solo World, else a New Game.
func pick_host(from_command_line := false) -> WorldSlot:
	var newest := ""
	var newest_at := -1
	for slot in coop_slots():
		var got := Save.read(file_of(slot), false)
		if got["ok"]:
			var rec := WorldRecord.from_dict(_world_of(got))
			if rec.last_played > newest_at:
				newest_at = rec.last_played
				newest = slot
	if newest == "" and from_command_line and Save.has(file_of(SOLO)):
		newest = SOLO
	if newest == "":
		newest = free_coop_slot()
		if newest == "":
			notice = FULL % tuning.coop_slots
			return null
	return _pick(newest, true)


## The World in `slot` as a Solo player (`hosting` false) or a Host plays it; `fresh`: a New Game there
## whatever is saved (the Lobby's New Game, after it asked). null when it cannot be played.
func pick_slot(slot: String, hosting: bool, fresh := false) -> WorldSlot:
	return _pick(slot, hosting, fresh)


## A co-op slot with no file, or "" when every one is used.
func free_coop_slot() -> String:
	for slot in coop_slots():
		if not Save.has(file_of(slot)):
			return slot
	return ""


## A World goes: its file, its backup and its half-written copy (Q1647).
func delete(slot: String) -> void:
	Save.delete(file_of(slot))


## Each World's row for a menu (the Lobby piece shows them): {"slot", "name", "details", "damaged",
## "last_played", "colours"}, the Solo World first, then the co-op Worlds newest first.
func rows() -> Array[Dictionary]:
	var solo: Array[Dictionary] = []
	var coop: Array[Dictionary] = []
	for slot: String in [SOLO] + Array(coop_slots()):
		if not Save.has(file_of(slot)):
			continue
		var got := Save.read(file_of(slot), false)
		if not got["ok"]:
			(solo if slot == SOLO else coop).append({"slot": slot, "name": DAMAGED_WORLD, "details": "", "damaged": true, "last_played": 0, "colours": [], "members": []})
			continue
		var rec := WorldRecord.from_dict(_world_of(got))
		var row := {"slot": slot, "name": display_name(slot, rec), "details": row_details(rec), "damaged": false,
				"last_played": rec.last_played, "colours": member_colours(rec), "members": Array(member_names(rec)),
				"finished": rec.finished}
		(solo if slot == SOLO else coop).append(row)
	coop.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["last_played"]) > int(b["last_played"]))
	return solo + coop


## The one place a World's row name is made (the drawer's rows, the Lobby's card; Q2587): "Solo World",
## or a co-op World's players' names (or "No Group yet"). Judged at the Lobby look's first still: the
## likely other form is "World <n>" with the World's state details, which changes this function only.
static func display_name(slot: String, rec: WorldRecord) -> String:
	if slot == SOLO:
		return SOLO_WORLD
	if name_form == NameForm.NUMBERED:
		return NUMBERED_WORLD % (int(slot.trim_prefix("coop")) if slot.begins_with("coop") else 0)
	var names := member_names(rec)
	return ", ".join(names) if not names.is_empty() else NO_GROUP


## The names of a World's members, in order (the "i" page lists them).
static func member_names(rec: WorldRecord) -> PackedStringArray:
	var names := PackedStringArray()
	for pid: Variant in rec.members:
		names.append(String((rec.members[pid] as Dictionary).get("name", PlayerProfile.NAME)))
	return names


## The colour index of each member of a World, in the order of their names (a row's swatches).
static func member_colours(rec: WorldRecord) -> Array:
	var out := []
	for pid: Variant in rec.members:
		out.append(int((rec.members[pid] as Dictionary).get("colour", 0)))
	return out


## A row's details: "<floor> · played <h>h <mm>m · last <date time>"; a World whose run ended (Q2631) says
## "Finished" in the floor's place.
static func row_details(rec: WorldRecord) -> String:
	var mins := int(rec.play_time / 60.0)
	var when := Time.get_datetime_string_from_unix_time(rec.last_played, true) if rec.last_played > 0 else "-"
	if rec.finished:
		return "%s · played %dh %02dm · last %s" % [FINISHED, mins / 60, mins % 60, when]
	return "%s · played %dh %02dm · last %s" % [rec.floor_name if rec.floor_name != "" else "-", mins / 60, mins % 60, when]


func _pick(slot: String, hosting: bool, fresh := false) -> WorldSlot:
	var w := WorldSlot.new()
	w.slot = slot
	w.file = file_of(slot)
	w.hosting = hosting
	w.profile = profile()
	w.record.kind = WorldRecord.SOLO if slot == SOLO else WorldRecord.COOP
	w.record.level = LEVEL
	if new_game or fresh:
		return w
	var got := Save.read(w.file)
	if got["ok"]:
		var data: Dictionary = got["data"]
		w.record = WorldRecord.from_dict(_world_of(got))
		if w.record.level == "":
			w.record.level = LEVEL
		var p: Variant = data.get("parts", {})
		var v: Variant = data.get("versions", {})
		w.parts = p if p is Dictionary else {}
		w.versions = v if v is Dictionary else {}
		w.is_new = false
		if got.get("from_backup", false):
			notice = FROM_BACKUP
	elif got.get("newer", false):
		notice = NEWER
		return null
	elif got.get("damaged", false):
		notice = DAMAGED
	return w


static func _world_of(got: Dictionary) -> Dictionary:
	var data: Dictionary = got.get("data", {})
	var world: Variant = data.get("world", {})
	return world if world is Dictionary else {}
