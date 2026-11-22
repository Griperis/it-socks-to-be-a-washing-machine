## Who plays in this Session, as one Part (coop-structure-for-the-port.md section 2 "Roster"): an
## entry per player id (Q2458), with the peer it plays on now (0 once it left), its name, its Player
## colour (an index into CoopTuning.colours) and where it stands at its join or last stood. The Host is
## entry peer 1 with the first colour; each joiner takes the next free one (Q2441). An entry stays
## after its player leaves, for the Session: the same id coming back stands where it left and keeps its
## colour while that is free (Q2448). It is in the join snapshot; the Avatars spawner spawns by it.
##
## Only the Host's answers write it: joined() when the gate admitted a player, left() when one went.
## No Guest may ask anything of it (accepts() is empty).
class_name Roster
extends Part

## The kinds of its answers, for the HUD's toasts and the Avatars.
const JOINED := &"joined"
const LEFT := &"left"
## The Host's peer id.
const HOST := 1

## Shown on every machine whenever the roster changed (an answer or a snapshot).
signal changed

@export var tuning: CoopTuning

@export_group("State")
## {player id: {"peer": int, "name": String, "colour": int, "at": Vector3, "yaw": float, "hands": the
## numbers of their Hands an Upgrade changes, clamped by the Host (D13)}}.
@export var players := {}
@export_group("")

## The Host's answer to "where does player `by` stand and face": (by: int) -> Transform3D, or null
## when it cannot say (the zoo sets it). Unset, the Parts' `where` gives the place, facing -z.
var pose_of: Callable


func _ready() -> void:
	if tuning == null:
		tuning = CoopTuning.new()


func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func _show(_now: bool) -> void:
	changed.emit()


# --- Reading -------------------------------------------------------------------------------------

## The entry of the player on peer `peer` now, or {}.
func entry_of(peer: int) -> Dictionary:
	if peer == 0:
		return {}
	for pid: Variant in players:
		if int((players[pid] as Dictionary).get("peer", 0)) == peer:
			return players[pid]
	return {}


## The player id on peer `peer` now, or "".
func id_of(peer: int) -> String:
	for pid: Variant in players:
		if int((players[pid] as Dictionary).get("peer", 0)) == peer and peer != 0:
			return String(pid)
	return ""


## The peers of the players in the Session now, the Host first.
func peers() -> PackedInt32Array:
	var out := PackedInt32Array()
	for pid: Variant in players:
		var peer := int((players[pid] as Dictionary).get("peer", 0))
		if peer != 0:
			out.append(peer)
	out.sort()
	return out


## Whether player id `pid` plays now.
func is_live(pid: String) -> bool:
	return int((players.get(pid, {}) as Dictionary).get("peer", 0)) != 0


## The name of the player on `peer`, or "Player".
func name_of(peer: int) -> String:
	return String(entry_of(peer).get("name", PlayerProfile.NAME))


## The Player colour of the player on `peer`, or white for nobody.
func colour_of(peer: int) -> Color:
	var e := entry_of(peer)
	return tuning.colour(int(e["colour"])) if not e.is_empty() else Color.WHITE


## The colour index of the player on `peer`, or -1.
func colour_index_of(peer: int) -> int:
	return int(entry_of(peer).get("colour", -1))


## The first colour not taken by a player in the Session, starting at `wanted` and wrapping round.
func free_colour(wanted: int) -> int:
	var count := maxi(tuning.colours.size(), 1)
	var taken := {}
	for pid: Variant in players:
		var e: Dictionary = players[pid]
		if int(e.get("peer", 0)) != 0:
			taken[int(e.get("colour", -1))] = true
	for i in count:
		var c := posmod(wanted + i, count)
		if not taken.has(c):
			return c
	return posmod(wanted, count)


# --- The Host's answers --------------------------------------------------------------------------

## The Host: player id `pid` on `peer`, named `who`, joins. A new id takes the next free colour and
## stands beside the Host (the Host itself where it stands); an id that played before stands where it
## left and keeps its colour while free. `hands`: their Hands' numbers as the Host clamped them.
## Returns the answer, for Parts.apply().
func joined(pid: String, peer: int, who: String, hands := {}) -> Dictionary:
	var all := players.duplicate(true)
	var before: Dictionary = all.get(pid, {})
	var entry := {"peer": peer, "name": PlayerProfile.clean_name(who)}
	if not hands.is_empty():
		entry["hands"] = hands
	if before.is_empty():
		entry["colour"] = free_colour(0)
		var spot := _spot_for(peer)
		entry["at"] = spot.origin
		entry["yaw"] = spot.basis.get_euler().y
	else:
		entry["colour"] = free_colour(int(before.get("colour", 0)))
		entry["at"] = before.get("at", Vector3.ZERO)
		entry["yaw"] = before.get("yaw", 0.0)
	all[pid] = entry
	var ev := grant({"players": all})
	ev.merge({"kind": JOINED, "by": peer, "to": id, "player": pid})
	return ev


## The Host: player `by` left. Their entry stays for the Session, with no peer and where they last
## stood. The answer names their player id ("player"), so the toast still finds their name.
func left(by: int) -> Dictionary:
	var pid := id_of(by)
	if pid == "":
		return {}
	var all := players.duplicate(true)
	var entry: Dictionary = all[pid]
	entry["peer"] = 0
	var pose: Variant = _pose(by)
	if pose != null:
		entry["at"] = (pose as Transform3D).origin
		entry["yaw"] = (pose as Transform3D).basis.get_euler().y
	var ev := grant({"players": all})
	ev["player"] = pid
	return ev


## The Session is over on this machine (alone again): nobody is in it. Returns the answer.
func cleared() -> Dictionary:
	var ev := grant({"players": {}})
	ev.merge({"kind": &"cleared", "by": HOST, "to": id})
	return ev


## Where a new player on `peer` stands: the Host where it stands; the k-th other live player beside
## the Host, `beside` metres to its right, then its left, then twice as far right, and so on.
func _spot_for(peer: int) -> Transform3D:
	var host_pose: Variant = _pose(HOST)
	var at: Transform3D = host_pose if host_pose != null else Transform3D.IDENTITY
	if peer == HOST:
		return at
	var flat := Basis(Vector3.UP, at.basis.get_euler().y)
	var others := peers().size() - (1 if peers().has(HOST) else 0)
	var k := others + 1
	var side := 1.0 if k % 2 == 1 else -1.0
	var steps := float(ceili(k / 2.0))
	return Transform3D(flat, at.origin + flat.x * tuning.beside * steps * side)


## Where player `by` stands and faces, as this machine knows it, or null.
func _pose(by: int) -> Variant:
	if pose_of.is_valid():
		var p: Variant = pose_of.call(by)
		if p is Transform3D:
			return p
	if parts != null and parts.where.is_valid():
		var at: Variant = parts.where.call(by)
		if at is Vector3:
			return Transform3D(Basis.IDENTITY, at)
	return null
