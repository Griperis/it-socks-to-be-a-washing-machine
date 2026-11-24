## Who this player is, across sessions: the one player id (Q2458) and the name. Off Steam the id is a
## long random id, 128 bits as 32 hex characters (Q2224), made once and kept in `user://profile.json`;
## on Steam (M4) the Steam ID goes in the same field. Everyone is named "Player" until the lobby
## (Q2440). `--profile=<tag>` keeps another file, `profile_<tag>.json`, so two copies on one PC are two
## players (dev). The peer id is never here: it is a live field of one connection only.
class_name PlayerProfile
extends RefCounted

const FOLDER := "user://"
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


## The profile of `tag` ("" is the player's own): read from its file, or made and written there.
static func load_or_make(tag: String) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.path = file_of(tag)
	var text := FileAccess.get_file_as_string(p.path) if FileAccess.file_exists(p.path) else ""
	var data: Variant = JSON.parse_string(text) if text != "" else null
	if data is Dictionary and is_id((data as Dictionary).get("id")):
		p.id = String(data["id"])
		p.name = clean_name(data.get("name", NAME))
		p.address = String(data.get("address", "")).strip_edges().left(ADDRESS_MAX) if data.get("address") is String else ""
		return p
	p.id = new_id()
	p.save()
	return p


## A profile only in memory, with a new id (a test's machine, or a Session nobody gave one).
static func fresh() -> PlayerProfile:
	var p := PlayerProfile.new()
	p.id = new_id()
	return p


## The file of `tag`: profile.json, or profile_<tag>.json (letters, digits, '-' and '_' kept).
static func file_of(tag: String) -> String:
	var safe := ""
	for c in tag:
		if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") or c == "-" or c == "_":
			safe += c
	return FOLDER + ("profile.json" if safe == "" else "profile_%s.json" % safe)


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


func save() -> void:
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		Log.warn("net", "cannot write the profile %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return
	f.store_string(JSON.stringify({"id": id, "name": name, "address": address}, "\t"))
