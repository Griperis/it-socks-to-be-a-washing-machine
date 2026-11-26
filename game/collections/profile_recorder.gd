## Keeps this machine's player's encyclopedia and unlocked Collections in their profile (docs/architecture/gifts.md
## "The encyclopedia"). A Node of `run.tscn` on every machine: it hears applied answers only, so a join snapshot and
## the level's starting state (a Parts not settled) record nothing, and a Guest records from its join on.
## - A shelve answer adds its Designs to the profile's `designs`.
## - A World loaded by its Host (or Solo) adds the Designs the Cabinets hold (Autosave.restored).
## - The Laundry day's `ended`, applied, unlocks `CollectionUnlocks.next_after(profile.collections)` into the profile
##   and keeps them in `unlocked` for the Final screen's strip (FinalSummary.of).
class_name ProfileRecorder
extends Node

## Every ProfileRecorder is in this group; the Final summary finds its level's.
const GROUP := &"profile_recorder"
const RULE := preload("res://game/collections/collection_unlocks.tres")

## Recorded into this profile; null reads `Worlds.profile()` (the one the Session plays under).
var profile: PlayerProfile = null
## The Collections this run's end unlocked here (empty until it ends, and after a load of an ended World).
var unlocked: Array[StringName] = []

var _watched: Array[Parts] = []


func _ready() -> void:
	add_to_group(GROUP)
	var tree := get_tree()
	tree.node_added.connect(_watch)
	for node in tree.root.find_children("*", "Parts", true, false):
		_watch(node)
	var runtime := LevelRuntime.of(self)
	if runtime != null and runtime.has_node(^"Autosave"):
		runtime.autosave.restored.connect(_on_restored)


func _watch(node: Node) -> void:
	if node is Parts and not _watched.has(node):
		_watched.append(node as Parts)
		(node as Parts).applied.connect(_on_applied.bind(node as Parts))


func _profile() -> PlayerProfile:
	return profile if profile != null else Worlds.profile_of(self)


## The World the Host (or Solo) loaded: every Design on a Cabinet's shelves was in that World.
func _on_restored() -> void:
	var seen := PackedInt32Array()
	for node in get_tree().get_nodes_in_group(Cabinet.GROUP):
		var cab := node as Cabinet
		var mess := cab.mess_of()
		if mess == null:
			continue
		for lead in cab.shelved():
			if mess.design_of(lead) != null:
				seen.append(mess.designs[lead])
	_profile().see_designs(seen)


## Every machine: a shelve answer (any shelver's), or the Laundry day ending.
func _on_applied(ev: Dictionary, parts: Parts) -> void:
	if not ev.get("ok", false) or parts == null or not parts.is_settled():
		return
	var changes: Variant = ev.get("changes", {})
	if not (changes is Dictionary):
		return
	if ev.has("shelved"):
		_record_shelved(ev["shelved"], changes as Dictionary)
	for n in get_tree().get_nodes_in_group(LaundryDay.GROUP):
		var day := n as LaundryDay
		if day != null and day.parts == parts and (changes as Dictionary).has(day.id) \
				and bool(((changes as Dictionary)[day.id] as Dictionary).get("ended", false)):
			_unlock_next()


## The Designs of the leads `shelved` (Mess ids), on the Cabinet whose patch the answer carries.
func _record_shelved(shelved: Variant, changes: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group(Cabinet.GROUP):
		var cab := node as Cabinet
		if not changes.has(cab.id):
			continue
		var mess := cab.mess_of()
		if mess == null:
			return
		var seen := PackedInt32Array()
		for lead: int in shelved:
			if mess.design_of(lead) != null:
				seen.append(mess.designs[lead])
		_profile().see_designs(seen)
		return


func _unlock_next() -> void:
	var p := _profile()
	unlocked = RULE.next_after(p.collections)
	p.unlock_collections(unlocked)
