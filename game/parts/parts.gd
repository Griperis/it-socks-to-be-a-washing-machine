## Every Part of one level, by id: the one generic piece behind playing alone, co-op, a late Guest
## and saves. On the Host (and alone: a Host of one) it answers Commands and applies the answers;
## on a Guest it sends Commands up (`relay`) and applies the answers that come down. No feature has
## save or net code of its own.
##
## Two kinds (core/62): a level's, and the game link's (GameLink), which binds the Parts that outlive a
## scene (the Roster). A level's Parts reads through to its `link`: of(), find(), ids(), the snapshots,
## the saves, left() and went_alone() see the link's parts as its own, and an answer for one of them is
## applied here like any other. So the save's "parts" dictionary is one, as it was.
class_name Parts
extends Node

## An answer was applied here (granted or refused). The Host's Session sends it on to the Guests;
## sounds and the HUD may listen. Never decide anything in a handler of it.
signal applied(ev: Dictionary)
## bind() found every part (the level is ready): a save may be loaded now.
signal bound
## The last unsettle() was settled: the level's starting state is whole (house/09).
signal settled

## The Host's player id, and the player's id when playing alone.
const HOST := 1

## The metadata name under which bind() leaves, on each entity's root node, that entity's first part.
const ENTITY_META := &"scene_part"

## Links the wiring check (kit/tools/check.sh --wiring) lets stay empty: the code below has a fallback.
const WIRING_OPTIONAL := ["level"]
## The level whose Parts these are; empty means this node's parent.
@export var level: Node
## What every id this Parts gives starts with: the link's is GameLink.ID_PREFIX, so its parts keep the
## ids they had inside the level runtime (a save's ids do not change).
@export var id_prefix := ""

## The game link's Parts, read through by a level's (see the top); null for the link's own and for a
## Parts with no link (a test's).
var link: Parts = null

## A Guest's way up to the Host (Session sets it). Empty on the Host and when playing alone.
var relay: Callable
## The game's answer to "where does player `by` stand": (by: int) -> Vector3, read by a part's
## reach check in decide() (near()). Unset, every player is near everything.
var where: Callable
var _by_id: Dictionary[StringName, Part] = {}
## bind() has run.
var is_bound := false
## The last seq this machine gave a Command (next_seq()).
var _seq := 0
## Who still makes the level's starting state (unsettle()), by node.
var _unsettled: Dictionary[Object, bool] = {}
## The root bind() named every part from (adopt() names a spawned node's parts from it too).
var _root: Node = null
## What every spawned part's id starts with: each SpawnedParts' id and a slash (core/126).
var _spawn_roots: PackedStringArray = []
## The ids adopt() bound (a spawned node's parts), which the layout hash leaves out.
var _adopted: Dictionary[StringName, bool] = {}
## A spawned part's state that came before its node (a snapshot or an answer ahead of the spawn,
## gifts.md "Gotchas"), by id: written when adopt() binds the node.
var _waiting: Dictionary[StringName, Dictionary] = {}


## The level is still making its starting state (house/09: its Socks laid behind the loading screen)
## until `by` calls settle(): a joining Guest's snapshot waits for `settled`.
func unsettle(by: Object) -> void:
	_unsettled[by] = true


func settle(by: Object) -> void:
	if _unsettled.erase(by) and _unsettled.is_empty():
		settled.emit()


## Whether nothing still makes the level's starting state (a snapshot of it is whole).
func is_settled() -> bool:
	return _unsettled.is_empty()


## Binds once the level is ready, so every part's looks are in place for the first _show(true).
func _ready() -> void:
	var root := level if level != null else get_parent()
	if not root.is_node_ready():
		await root.ready
	bind(root)


## Finds every Part under `root`, names it by its path and shows its starting state at once.
## An entity's root is the node its parts are children of; it carries its first declared part in
## ENTITY_META, which part_of() reads.
func bind(root: Node) -> void:
	for old: Part in _by_id.values():
		if is_instance_valid(old) and old.get_parent() != null:
			old.get_parent().remove_meta(ENTITY_META)
	_by_id.clear()
	_adopted.clear()
	_spawn_roots.clear()
	_root = root
	var found := _walk(root, root, [])
	for part in found:
		_name(part, root)
		if part is SpawnedParts:
			_spawn_roots.append(String(part.id) + "/")
	for part in found:
		part._show(true)
	is_bound = true
	bound.emit()


## A node a SpawnedParts made during play (core/126): its parts are bound by path as bind() binds
## placed ones (Run/Spawned/Crate3/Carriable), each written first with `states` (by the part's path
## from `node`: what the spawn carried), then with what came for it before the node (a late Guest's
## snapshot, an answer ahead of the spawn), else shown as they are.
func adopt(node: Node, states: Dictionary = {}) -> void:
	if _root == null or not node.is_inside_tree():
		return
	for part in _walk(node, node, []):
		_name(part, _root)
		_adopted[part.id] = true
		var key := String(node.get_path_to(part))
		var state: Variant = states.get(key)
		var waited: Dictionary = _waiting.get(part.id, {})
		_waiting.erase(part.id)
		if state is Dictionary and not (state as Dictionary).is_empty():
			part.write(state, true)
		if not waited.is_empty():
			part.write(waited, true)
		elif not (state is Dictionary and not (state as Dictionary).is_empty()):
			part._show(true)


## A spawned node goes (its row was removed): its parts are no longer this level's, and nothing waits
## for them.
func release(node: Node) -> void:
	if _root == null:
		return
	for part in _walk(node, node, []):
		if _by_id.get(part.id) == part:
			_by_id.erase(part.id)
		_adopted.erase(part.id)
	if node.is_inside_tree():
		var prefix := id_prefix + String(_root.get_path_to(node)) + "/"
		for id: StringName in _waiting.keys():
			if String(id).begins_with(prefix):
				_waiting.erase(id)
	node.remove_meta(ENTITY_META)


## Whether `id` is (or would be) a spawned node's part: adopted, or under a SpawnedParts.
func is_spawned(id: StringName) -> bool:
	if _adopted.has(id):
		return true
	var text := String(id)
	for prefix in _spawn_roots:
		if text.begins_with(prefix):
			return true
	return false


## Names `part` by its path from `root` and binds it here.
func _name(part: Part, root: Node) -> void:
	part.id = StringName(id_prefix + String(root.get_path_to(part)))
	part.parts = self
	_by_id[part.id] = part
	var thing := part.get_parent()
	if thing != null and not thing.has_meta(ENTITY_META):
		thing.set_meta(ENTITY_META, part)


## A state for spawned part `id` whose node is not here yet: kept (merged) until adopt().
func _wait_for(id: StringName, patch: Dictionary) -> void:
	var held: Dictionary = _waiting.get(id, {})
	held.merge(patch, true)
	_waiting[id] = held


## The part of the thing `node` belongs to (what the player's use button on `node` means): the first
## part declared on the closest entity root at or above `node`, or null for a node of no entity (the
## floor). Climbs only until it meets a root bind() marked: no sibling is scanned, so it is cheap
## enough to call every frame for an aim prompt.
static func part_of(node: Node) -> Part:
	while node != null:
		if node.has_meta(ENTITY_META):
			var part: Variant = node.get_meta(ENTITY_META)
			if is_instance_valid(part):
				return part as Part
		node = node.get_parent()
	return null


## The part with this id (the link's included), or null.
func of(id: StringName) -> Part:
	var part: Part = _by_id.get(id)
	if part == null and _has_link():
		part = link.of(id)
	return part


## Whether the part with this id is the link's (it outlives the level), not the level's own.
func is_link_part(id: StringName) -> bool:
	return not _by_id.has(id) and _has_link() and link.of(id) != null


## The first part for which `test` says true, or null ("what does player 7 carry"). A linear scan,
## O(parts): for a rare question, never per frame (use part_of() for what a player aims at).
func find(test: Callable) -> Part:
	for part: Part in _by_id.values():
		if test.call(part):
			return part
	return link.find(test) if _has_link() else null


## Whether player `by` stands within `reach` of `thing` (where()); true while `where` is unset or
## `thing` is not a Node3D in the tree. A player `where` gives no Vector3 for is out of reach.
func near(by: int, thing: Node, reach: float) -> bool:
	var spot := thing as Node3D
	if not where.is_valid() or spot == null or not spot.is_inside_tree():
		return true
	var at: Variant = where.call(by)
	return at is Vector3 and (at as Vector3).distance_to(spot.global_position) <= reach


## Whether player `by` stands within `reach` of the place `point` (in the level's space): where a
## player wants to put something down. True while `where` is unset.
func near_point(by: int, point: Vector3, reach: float) -> bool:
	if not where.is_valid():
		return true
	var at: Variant = where.call(by)
	return at is Vector3 and (at as Vector3).distance_to(point) <= reach


## Whether this machine decides: the Host, or alone.
func is_host() -> bool:
	return not relay.is_valid()


## A player asks for a change. The Host (or a Host of one) answers it here; a Guest sends it up and
## waits for the answer. Prediction (GuestGhosts, coop/09) is looks only: it never writes state.
func ask(cmd: Command) -> void:
	if relay.is_valid():
		relay.call(cmd)
	else:
		apply(answer(cmd))


## A new number for a Command this machine asks and waits on (Command.seq, coop/09).
func next_seq() -> int:
	_seq = _seq % Command.SEQ_MAX + 1
	return _seq


## The Host's answer to `cmd`. Changes nothing. A Command with a seq has it echoed as "seq".
func answer(cmd: Command) -> Dictionary:
	var part := of(cmd.to)
	var ev := part.decide(cmd) if part != null else {"ok": false, "reason": "wrong"}
	ev.merge({"kind": cmd.kind, "by": cmd.by, "to": cmd.to})
	if cmd.seq > 0:
		ev["seq"] = cmd.seq
	return ev


## Every machine: the only place state changes while playing.
func apply(ev: Dictionary) -> void:
	if ev.get("ok", false):
		var changes: Dictionary = ev["changes"]
		for id: Variant in changes:
			var part := of(StringName(id))
			if part == null and is_spawned(StringName(id)):
				_wait_for(StringName(id), changes[id])
				continue
			if part == null:
				Log.error("parts", "no part %s in this level" % id)
				continue
			part.write(changes[id], false)
	applied.emit(ev)


## This machine stopped being a Guest: every part takes over what it showed as looks only (coop/12).
func went_alone() -> void:
	for part: Part in _all():
		part.went_alone()


## The Host: player `by` left; each part says what that does to it (a carried thing drops).
func left(by: int) -> void:
	for part: Part in _all():
		var ev := part.left(by)
		if not ev.is_empty():
			ev.merge({"kind": &"left", "by": by, "to": part.id})
			apply(ev)


## Every part's state by id, as it is sent whole (Part.whole_state()): what a late Guest receives and
## what a save keeps.
func snapshot() -> Dictionary:
	var d := {}
	for part: Part in _all():
		d[part.id] = part.whole_state()
	return d


## What a save keeps of every part (Part.save_state()), by id as a String; a part that keeps nothing
## is left out.
func save_snapshot() -> Dictionary:
	var d := {}
	for part: Part in _all():
		var s := part.save_state()
		if not s.is_empty():
			d[String(part.id)] = s
	return d


## Each saved part's save_version(), by id as a String.
func save_versions() -> Dictionary:
	var d := {}
	for part: Part in _all():
		d[String(part.id)] = part.save_version()
	return d


## The Host: a save loaded (Parts.save_snapshot() and save_versions() as they were written): each
## part's state is brought to its own version (Part.upgrade_save()), written whole and shown at once;
## an id this level no longer has is skipped (logged). A part merges what was saved into what it
## holds now (Part.restored(): the Roster keeps who is here). Then every part's loaded() reset is
## applied, `host` being the Host's player id.
##
## A SpawnedParts' rows go first: its nodes are spawned (and adopted) before their parts' states
## are written (core/126).
func load_save(saved: Dictionary, versions: Dictionary, host: String) -> void:
	var first := {}
	var rest := {}
	for id: Variant in saved:
		if of(StringName(id)) is SpawnedParts:
			first[id] = saved[id]
		else:
			rest[id] = saved[id]
	for group: Dictionary in [first, rest]:
		var snap := {}
		for id: Variant in group:
			var part := of(StringName(id))
			if part == null or not (saved[id] is Dictionary):
				Log.warn("save", "the save has a part %s this level does not" % id)
				continue
			var state: Dictionary = saved[id]
			var v := int(versions.get(id, 1))
			while v < part.save_version():
				state = part.upgrade_save(state, v)
				v += 1
			snap[id] = part.restored(state)
		load_snapshot(snap)
	for part: Part in _all():
		var ev := part.loaded(host)
		if not ev.is_empty():
			ev.merge({"kind": &"loaded", "by": HOST, "to": part.id})
			apply(ev)


## Every part's id (the link's included).
func ids() -> Array[StringName]:
	var out: Array[StringName] = _by_id.keys()
	if _has_link():
		out.append_array(link.ids())
	return out


## A late Guest, or a save loaded: every part takes its state whole, shown at once. A SpawnedParts
## goes first (the Host spawns its rows' nodes); a spawned part whose node is not here yet (a Guest's
## spawner brings it later) waits for it by id.
func load_snapshot(snap: Dictionary) -> void:
	var later: Array = []
	for id: Variant in snap:
		if of(StringName(id)) is SpawnedParts:
			if snap[id] is Dictionary:
				of(StringName(id)).write(snap[id], true)
		else:
			later.append(id)
	for id: Variant in later:
		if not (snap[id] is Dictionary):
			continue
		var part := of(StringName(id))
		if part != null:
			part.write(snap[id], true)
		elif is_spawned(StringName(id)):
			_wait_for(StringName(id), snap[id])


## Every part under `node`; a game link under the level (a level's private one) binds its own; what a
## SpawnedParts made is adopted, not walked (its spawner's helpers included).
func _walk(node: Node, root: Node, into: Array[Part]) -> Array[Part]:
	if node is GameLink and node != root:
		return into
	if node is Part:
		into.append(node)
	if node is SpawnedParts and node != root:
		return into
	for child in node.get_children():
		_walk(child, root, into)
	return into


## This Parts' own parts, then the link's.
func _all() -> Array[Part]:
	var out: Array[Part] = []
	out.assign(_by_id.values())
	if _has_link():
		out.append_array(link._all())
	return out


func _has_link() -> bool:
	return link != null and is_instance_valid(link) and link != self
