## Every Part of one level, by id: the one generic piece behind playing alone, co-op, a late Guest
## and saves. On the Host (and alone: a Host of one) it answers Commands and applies the answers;
## on a Guest it sends Commands up (`relay`) and applies the answers that come down. No feature has
## save or net code of its own.
class_name Parts
extends Node

## An answer was applied here (granted or refused). The Host's Session sends it on to the Guests;
## sounds and the HUD may listen. Never decide anything in a handler of it.
signal applied(ev: Dictionary)

## The Host's player id, and the player's id when playing alone.
const HOST := 1

## The metadata name under which bind() leaves, on each entity's root node, that entity's first part.
const ENTITY_META := &"scene_part"

## Links the wiring check (kit/tools/check.sh --wiring) lets stay empty: the code below has a fallback.
const WIRING_OPTIONAL := ["level"]
## The level whose Parts these are; empty means this node's parent.
@export var level: Node

## A Guest's way up to the Host (Session sets it). Empty on the Host and when playing alone.
var relay: Callable
## The game's answer to "where does player `by` stand": (by: int) -> Vector3, read by a part's
## reach check in decide() (near()). Unset, every player is near everything.
var where: Callable
var _by_id: Dictionary[StringName, Part] = {}
## The last seq this machine gave a Command (next_seq()).
var _seq := 0


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
	for part in _walk(root, []):
		part.id = StringName(String(root.get_path_to(part)))
		part.parts = self
		_by_id[part.id] = part
		var thing := part.get_parent()
		if thing != null and not thing.has_meta(ENTITY_META):
			thing.set_meta(ENTITY_META, part)
		part._show(true)


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


## The part with this id, or null.
func of(id: StringName) -> Part:
	return _by_id.get(id)


## The first part for which `test` says true, or null ("what does player 7 carry"). A linear scan,
## O(parts): for a rare question, never per frame (use part_of() for what a player aims at).
func find(test: Callable) -> Part:
	for part: Part in _by_id.values():
		if test.call(part):
			return part
	return null


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
			if part == null:
				Log.error("parts", "no part %s in this level" % id)
				continue
			part.write(changes[id], false)
	applied.emit(ev)


## This machine stopped being a Guest: every part takes over what it showed as looks only (coop/12).
func went_alone() -> void:
	for part: Part in _by_id.values():
		part.went_alone()


## The Host: player `by` left; each part says what that does to it (a carried thing drops).
func left(by: int) -> void:
	for part: Part in _by_id.values():
		var ev := part.left(by)
		if not ev.is_empty():
			ev.merge({"kind": &"left", "by": by, "to": part.id})
			apply(ev)


## Every part's state by id, as it is sent whole (Part.whole_state()): what a late Guest receives and
## what a save keeps.
func snapshot() -> Dictionary:
	var d := {}
	for id: StringName in _by_id:
		d[id] = _by_id[id].whole_state()
	return d


## Every part's id.
func ids() -> Array[StringName]:
	return _by_id.keys()


## A late Guest, or a save loaded: every part takes its state whole, shown at once.
func load_snapshot(snap: Dictionary) -> void:
	for id: Variant in snap:
		var part := of(StringName(id))
		if part != null and snap[id] is Dictionary:
			part.write(snap[id], true)


func _walk(node: Node, into: Array[Part]) -> Array[Part]:
	if node is Part:
		into.append(node)
	for child in node.get_children():
		_walk(child, into)
	return into
