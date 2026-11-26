## Who this player is, across sessions: the one player id (Q2458) and the name. Off Steam the id is a
## long random id, 128 bits as 32 hex characters (Q2224), made once and kept in `user://profile.json`;
## on Steam (M4) the Steam ID goes in the same field. Everyone is named "Player" until the lobby
## (Q2440). `--profile=<tag>` keeps another file, `profile_<tag>.json`, so two copies on one PC are two
## players (dev). The peer id is never here: it is a live field of one connection only.
## Version 2 (core/127, docs/architecture/wardrobe.md "The Profile file") adds the colour, the look, the
## owned pieces, the five Lifetime tallies, the Achievements, the encyclopedia and the unlocked Collections;
## a version 1 file reads with them empty.
class_name PlayerProfile
extends RefCounted

## A piece was unlocked here (unlock_piece): the Wardrobe page and the toast listen.
signal piece_unlocked(id: StringName)

const FOLDER := "user://"
const VERSION := 2
## The five Lifetime tallies (wardrobe.md "The Lifetime tallies").
const PAIRS_SHELVED := "pairs_shelved"
const COINS_EARNED := "coins_earned"
const COLLECTIONS_COMPLETED := "collections_completed"
const FLOORS_COMPLETED := "floors_completed"
const GAMES_FINISHED := "games_finished"
const TALLIES: Array[String] = [PAIRS_SHELVED, COINS_EARNED, COLLECTIONS_COMPLETED, FLOORS_COMPLETED, GAMES_FINISHED]
## No tally goes past this (the Host's clamp of a Guest's word, wardrobe.md).
const TALLY_MAX := 999999999
## The tuning (the save gap); a test may set another.
static var tuning: ProfileTuning = preload("res://game/net/profile_tuning.tres")
const NAME := "Player"
## A name is cut at this many letters, and an empty one becomes NAME (the old profile.gd).
const NAME_MAX := 16
## The id's bytes: 128 bits.
const ID_BYTES := 16
## The longest address kept.
const ADDRESS_MAX := 128

## The player id: 32 hex characters off Steam.
var id := ""
var name := NAME
## The last Host's address typed on the title's Join page ("" for none).
var address := ""
## The file it was read from and is kept in; "" for one made only in memory.
var path := ""
## The colour index this player wishes (the Roster gives the next free one when it is taken).
var colour := 0
## What they wear: {hat, clothes, socks, trail} piece ids ({} until the Wardrobe writes it).
var look := {}
## The owned piece ids; the ten basic pieces are never stored (Wardrobe.owned() adds them, Q2679).
var pieces := PackedStringArray()
## The five Lifetime tallies, ints.
var tallies := {}
## Achievement id -> unix time earned.
var achievements := {}
## The encyclopedia: the Design ids seen, sorted.
var designs := PackedInt32Array()
## The unlocked Collections.
var collections: Array[StringName] = []

var _dirty := false
var _waiting := false


## The profile of `tag` ("" is the player's own): read from its file, or made and written there.
static func load_or_make(tag: String, folder := FOLDER) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.path = file_of(tag, folder)
	var text := FileAccess.get_file_as_string(p.path) if FileAccess.file_exists(p.path) else ""
	var json := JSON.new()
	var data: Variant = json.data if text != "" and json.parse(text) == OK else null
	if data is Dictionary and is_id((data as Dictionary).get("id")):
		p.id = String(data["id"])
		p.name = clean_name(data.get("name", NAME))
		p.address = String(data.get("address", "")).strip_edges().left(ADDRESS_MAX) if data.get("address") is String else ""
		p._read_v2(data)
		return p
	p.id = new_id()
	p.collections = collection_start()
	p.save()
	return p


## The Collections a new profile starts with (core/125's CollectionUnlocks.start).
static func collection_start() -> Array[StringName]:
	var out: Array[StringName] = []
	var rule := load("res://game/collections/collection_unlocks.tres") as CollectionUnlocks
	if rule != null:
		out.assign(rule.start)
	return out


## The fields of version 2, each cleaned; a version 1 file has none and keeps them empty.
func _read_v2(data: Dictionary) -> void:
	if int(data.get("version", 1)) < 2:
		return
	colour = maxi(int(data.get("colour", 0)), 0) if data.get("colour") is float else 0
	if data.get("look") is Dictionary:
		for k: Variant in data["look"]:
			if k is String and data["look"][k] is String:
				look[k] = data["look"][k]
	if data.get("pieces") is Array:
		for v: Variant in data["pieces"]:
			if v is String and not pieces.has(v):
				pieces.append(v)
	if data.get("tallies") is Dictionary:
		for t in TALLIES:
			if data["tallies"].get(t) is float:
				tallies[t] = clampi(int(data["tallies"][t]), 0, TALLY_MAX)
	if data.get("achievements") is Dictionary:
		for k: Variant in data["achievements"]:
			if k is String and data["achievements"][k] is float:
				achievements[k] = int(data["achievements"][k])
	if data.get("designs") is Array:
		var seen := {}
		for v: Variant in data["designs"]:
			if v is float and int(v) >= 0:
				seen[int(v)] = true
		var ids := seen.keys()
		ids.sort()
		designs = PackedInt32Array(ids)
	if data.get("collections") is Array:
		for v: Variant in data["collections"]:
			if v is String and not collections.has(StringName(v)):
				collections.append(StringName(v))


## A profile only in memory, with a new id (a test's machine, or a Session nobody gave one).
static func fresh() -> PlayerProfile:
	var p := PlayerProfile.new()
	p.id = new_id()
	return p


## The file of `tag`: profile.json, or profile_<tag>.json (letters, digits, '-' and '_' kept).
static func file_of(tag: String, folder := FOLDER) -> String:
	var safe := ""
	for c in tag:
		if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") or c == "-" or c == "_":
			safe += c
	return folder + ("profile.json" if safe == "" else "profile_%s.json" % safe)


## A new long random id.
static func new_id() -> String:
	return Crypto.new().generate_random_bytes(ID_BYTES).hex_encode()


## Whether `v` is a player id as this build writes one off Steam, or any other plain id a transport
## gives (a Steam ID's digits): a String of 1 to 64 letters and digits.
static func is_id(v: Variant) -> bool:
	if not (v is String) or (v as String).is_empty() or (v as String).length() > 64:
		return false
	for c in v as String:
		if not ((c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")):
			return false
	return true


## A name as the roster keeps it: trimmed, at most NAME_MAX letters, NAME when empty or not text.
static func clean_name(v: Variant) -> String:
	var text := (v as String).strip_edges().left(NAME_MAX) if v is String else ""
	return text if text != "" else NAME


## A name the platform suggests for the field (Steam's persona name at M4, Q2585); "" for none. A
## typed name wins (shown_name). The one seam where a Steam name fills the field.
func suggested_name() -> String:
	return ""


## What the Multiplayer page's field shows: the typed name, else the suggestion, else "" (the
## field's placeholder says "Player").
func shown_name() -> String:
	if name != NAME:
		return name
	var s := suggested_name().strip_edges().left(NAME_MAX)
	return s if s != NAME else ""


## The count of Lifetime tally `name`.
func tally(name_: String) -> int:
	return int(tallies.get(name_, 0))


## Adds `n` to Lifetime tally `name` (one of TALLIES) and marks the file to be written soon.
func count(name_: String, n := 1) -> void:
	if not TALLIES.has(name_) or n <= 0:
		return
	tallies[name_] = clampi(tally(name_) + n, 0, TALLY_MAX)
	save_soon()


## Earns Achievement `id` now; false when it was earned before.
func earn(id: String) -> bool:
	if achievements.has(id):
		return false
	achievements[id] = int(Time.get_unix_time_from_system())
	save_soon()
	return true


## Keeps piece `id` as owned; false when it already was.
func unlock_piece(id: StringName) -> bool:
	if pieces.has(String(id)):
		return false
	pieces.append(String(id))
	save_soon()
	piece_unlocked.emit(id)
	return true


## Marks the file to be written: one write at most every ProfileTuning.save_every seconds however many
## changes came (a Pair shelved never writes a file by itself), and flush() at quit.
func save_soon() -> void:
	_dirty = true
	if _waiting or path == "":
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		flush()
		return
	_waiting = true
	tree.create_timer(tuning.save_every).timeout.connect(_on_gap_over)


## Writes the file now when something changed since it was written.
func flush() -> void:
	if _dirty:
		save()


func _on_gap_over() -> void:
	_waiting = false
	flush()


func save() -> void:
	_dirty = false
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		Log.warn("net", "cannot write the profile %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return
	f.store_string(JSON.stringify(to_dict(), "\t"))


## The file's content.
func to_dict() -> Dictionary:
	return {"version": VERSION, "id": id, "name": name, "address": address, "colour": colour, "look": look,
			"pieces": Array(pieces), "tallies": tallies, "achievements": achievements,
			"designs": Array(designs), "collections": collections.map(func(c: StringName) -> String: return String(c))}
