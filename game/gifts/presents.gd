## The Stage presents of a level (core/137, docs/architecture/gifts.md "The drop", "The heap"): where they lie
## and what a drop adds. A Part of the level's `Run` (and of the Gifts station), beside the SpawnedParts its
## presents are rows of; it keeps no state of its own (each present's is its own Parts', in its row).
##
## The Host's run asks drop_changes() inside the Stage's `complete` answer (Stages), so the presents come in the
## same answer as the Stage's end and the Machine Part's pop can keep clear of them: for each player in the
## Session, one present per Collection completed in the Stage, its piece by PresentDraw, each at a spot of the
## heap round the level's PresentSpot marker (placed by hand at the Old Tree's south foot): the free spots of a
## hex grid `apart` across, turned at random, nearest first, at least 0.9 x `apart` from a box already lying,
## nudged 5 % at random (the old GI:202-226). The answer carries `presents_dropped` so every machine plays the
## boxes' drop; a box that came by a snapshot or a load just lies.
class_name Presents
extends Part

const GROUP := &"presents"
## The answer's key: {Presents id: PackedInt32Array of the new rows' ids}.
const DROPPED := "presents_dropped"
const SCENE := "res://game/gifts/present.tscn"
## The old heap: the free spots of a 7 x 7 hex grid, no closer than this share of `apart` to a lying box,
## nudged up to this share of it.
const GRID := 3
const CLEAR := 0.9
const NUDGE := 0.05
## How long a drop counts as fresh for a box whose node comes after the answer (a Guest's spawn).
const FRESH_MS := 2000
const UNLOCKS := preload("res://game/collections/collection_unlocks.tres")

## The rows its presents are.
@export var spawned: SpawnedParts
## The marker the heap lies round (the level's author places it); none: no present drops.
@export var spot: Marker3D
## The run whose unlocked Collections a draw uses (none: the start set and this machine's profile's).
@export var stages: Stages
@export var tuning: PresentTuning

## The Host's rng for the draw and the heap.
var _rng := RandomNumberGenerator.new()
## Rows dropped lately, by id: the tick they were dropped (a node coming after the answer still drops).
var _fresh: Dictionary[int, int] = {}


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if tuning == null:
		tuning = PresentTuning.new()
	_rng.randomize()


## The Presents whose SpawnedParts made `node`'s present (its row's parent), or null.
static func of(node: Node) -> Presents:
	if node == null or not node.is_inside_tree():
		return null
	var thing := node.get_parent()
	var holder := thing.get_parent() if thing != null else null
	for n in node.get_tree().get_nodes_in_group(GROUP):
		var p := n as Presents
		if p != null and p.spawned != null and p.spawned == holder:
			return p
	return null


## Nobody asks it: its drop is in another Part's answer.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func save_state() -> Dictionary:
	return {}


# --- The drop (the Host) -------------------------------------------------------------------------

## The changes and the event of a drop for `completed` (each player in the Session gets one present per
## Collection of it with pieces), `keep_clear` more spots (the level's) the heap keeps off: {"changes",
## DROPPED: {...}, "spots": Array[Vector3]}; {} when nothing drops (no Collection, no marker, no rows).
func drop(completed: Array[StringName], keep_clear: Array[Vector3] = []) -> Dictionary:
	if spawned == null or spot == null or completed.is_empty():
		return {}
	var drawn := PresentDraw.draw(completed, players(), waiting(), unlocked(), tuning.rare_weight, _rng)
	if drawn.is_empty():
		return {}
	var lying := lying_spots()
	lying.append_array(keep_clear)
	var spots := heap(spot.global_position, drawn.size(), lying, tuning.apart, _rng)
	var patch := {}
	var ids := PackedInt32Array()
	for i in drawn.size():
		var d := drawn[i]
		var states := {
			"Carriable": {"holder": 0, "at": spots[i], "yaw": 0.0},
			"Present": {"for_player": d["for"], "piece": d["piece"], "collection": d["collection"]},
		}
		ids.append(int(patch.get("next_id", spawned.next_id)))
		patch = spawned.add_patch(SCENE, states, patch)
	return {"changes": {spawned.id: patch}, DROPPED: {String(id): ids}, "spots": spots}


## The players in the Session now, the Host first: [{"id": player id, "peer": int, "owned": pieces}].
func players() -> Array:
	var out := []
	var roster := _roster()
	if roster != null and not roster.peers().is_empty():
		for peer in roster.peers():
			var pid := roster.id_of(peer)
			out.append({"id": pid, "peer": peer, "owned": roster.owned_of(pid)})
		return out
	out.append({"id": str(Parts.HOST), "peer": Parts.HOST, "owned": Wardrobe.owned(Worlds.profile().pieces)})
	return out


## The pieces already waiting in boxes, by player id (a box lying or carried counts: no second copy).
func waiting() -> Dictionary:
	var out := {}
	if spawned == null:
		return out
	for row: Dictionary in spawned.rows:
		if String(row.get("scene", "")) != SCENE:
			continue
		var present: Dictionary = (row.get("states", {}) as Dictionary).get("Present", {})
		var pid := String(present.get("for_player", ""))
		var had: PackedStringArray = out.get(pid, PackedStringArray())
		had.append(String(present.get("piece", "")))
		out[pid] = had
	return out


## The Collections a present's lacked piece may come from: the Host's unlocked set (the one the New Game's
## draw used; the lead's reading of Q2673), never a held-back one.
func unlocked() -> Array[StringName]:
	var all: Array[StringName] = []
	if stages != null:
		all = stages.unlocked_collections()
	else:
		all.append_array(UNLOCKS.start)
		for c in Worlds.profile().collections:
			if not all.has(c):
				all.append(c)
	var out: Array[StringName] = []
	for c in all:
		var col := Collections.of(c)
		if col != null and not col.held_back:
			out.append(c)
	return out


## Where its presents lie now (the level's), carried ones left out.
func lying_spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if spawned == null:
		return out
	for row: Dictionary in spawned.rows:
		var node := spawned.node_of(int(row.get("id", 0))) as Node3D
		var carriable := node.get_node_or_null(^"Carriable") as Carriable if node != null else null
		if node is Node3D and node.get_node_or_null(^"Present") is Present and carriable != null \
				and carriable.holder == 0 and node.is_inside_tree():
			out.append(node.global_position)
	return out


## Where `n` boxes lie in the loose heap round `centre` (the old GI:202-226): the free spots of a hex grid
## `apart` across turned at random, nearest the centre first, each at least 0.9 x `apart` from every spot in
## `lying` (and from each other), nudged up to 5 % of `apart` at random; the centre for any left over.
static func heap(centre: Vector3, n: int, lying: Array[Vector3], apart: float, rng: RandomNumberGenerator) -> Array[Vector3]:
	var turn := Basis(Vector3.UP, rng.randf() * TAU)
	var slots: Array[Vector3] = []
	for i in range(-GRID, GRID + 1):
		for j in range(-GRID, GRID + 1):
			slots.append(turn * Vector3((float(i) + float(j) * 0.5) * apart, 0.0, float(j) * 0.866 * apart))
	slots.sort_custom(func(x: Vector3, y: Vector3) -> bool: return x.length() < y.length())
	var out: Array[Vector3] = []
	var taken: Array[Vector3] = lying.duplicate()
	for slot in slots:
		if out.size() >= n:
			break
		var p := centre + slot
		if taken.any(func(q: Vector3) -> bool: return Vector2(q.x - p.x, q.z - p.z).length() < apart * CLEAR):
			continue
		p += Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)) * apart * NUDGE
		out.append(p)
		taken.append(p)
	while out.size() < n:
		out.append(centre)
	return out


## The spot nearest `centre` clear of every present lying and `also` (the Machine Part's pop, the old
## CA:439-479); `centre` itself when nothing lies near.
func clear_spot(centre: Vector3, also: Array[Vector3] = []) -> Vector3:
	var lying := lying_spots()
	lying.append_array(also)
	if not lying.any(func(q: Vector3) -> bool: return Vector2(q.x - centre.x, q.z - centre.z).length() < tuning.apart * CLEAR):
		return centre
	return heap(centre, 1, lying, tuning.apart, _rng)[0]


# --- Every machine -------------------------------------------------------------------------------

## Whether row `row` was dropped in an answer this machine applied lately (its box plays the drop).
func fresh(row: int) -> bool:
	var at: int = _fresh.get(row, -1)
	return at >= 0 and Time.get_ticks_msec() - at < FRESH_MS


func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_on_applied):
		parts.applied.connect(_on_applied)


## A drop reached this machine: its boxes already here drop now, the rest as their nodes come.
func _on_applied(ev: Dictionary) -> void:
	if not ev.get("ok", false) or not (ev.get(DROPPED) is Dictionary):
		return
	var ids: Variant = (ev[DROPPED] as Dictionary).get(String(id))
	if not (ids is PackedInt32Array) or spawned == null:
		return
	var now := Time.get_ticks_msec()
	for row: int in ids:
		_fresh[row] = now
		var node := spawned.node_of(row)
		var present := node.get_node_or_null(^"Present") as Present if node != null else null
		if present != null:
			present.dropped()


func _roster() -> Roster:
	return parts.find(func(p: Part) -> bool: return p is Roster) as Roster if parts != null else null
