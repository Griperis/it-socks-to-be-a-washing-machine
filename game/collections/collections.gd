## Every Collection of the game (core/125): the `SockCollection` files of this folder, in the order of
## `DesignCatalogue.collections()`. A new `.tres` here is a new Collection, with no code.
class_name Collections
extends RefCounted

const FOLDER := "res://game/collections/"
const CATALOGUE := "res://game/sock/designs.tres"

static var _all: Array[SockCollection] = []
static var _by_id: Dictionary[StringName, SockCollection] = {}


## Every Collection, in catalogue order (a file no Design names comes last, by id).
static func all() -> Array[SockCollection]:
	_load()
	return _all


## The Collections a player is shown: all but the held-back ones (Q2675).
static func shown() -> Array[SockCollection]:
	var out: Array[SockCollection] = []
	for c in all():
		if not c.held_back:
			out.append(c)
	return out


## The Collection with this id, or null.
static func of(id: StringName) -> SockCollection:
	_load()
	return _by_id.get(id)


static func _load() -> void:
	if not _all.is_empty():
		return
	var files: Dictionary[StringName, SockCollection] = {}
	for f: String in ResourceLoader.list_directory(FOLDER):
		if not f.ends_with(".tres"):
			continue
		var c := load(FOLDER + f) as SockCollection
		if c != null:
			files[c.id] = c
	var order: Array[StringName] = (load(CATALOGUE) as DesignCatalogue).collections()
	var rest: Array[StringName] = []
	for id in files:
		if not order.has(id):
			rest.append(id)
	rest.sort()
	order.append_array(rest)
	for id in order:
		if files.has(id):
			_by_id[id] = files[id]
			_all.append(files[id])
