## Who plays in this Session, as one Part (coop-structure-for-the-port.md section 2 "Roster"): an
## entry per player id (Q2458), with the peer it plays on now (0 once it left), its name, its Player
## colour (an index into CoopTuning.colours) and where it stands at its join or last stood. The Host is
## entry peer 1 with the first colour; each joiner takes the next free one (Q2441). An entry stays
## after its player leaves, for the Session: the same id coming back stands where it left and keeps its
## colour while that is free (Q2448). It is in the join snapshot; the Avatars spawner spawns by it.
##
## Only the Host's answers write it: joined() when the gate admitted a player, left() when one went,
## and its three verbs (core/141,
## docs/architecture/wardrobe.md "What a player owns and wears, in co-op"), each asked by a player for
## itself (the entry is the sender's, never named in the args): `wear` a look (refused unless every piece
## is owned), `colour` a Player colour (refused "taken" while another present player has it), `own` a
## piece (an Achievement's reward). Each entry also keeps the player's `look`, `owned` pieces and
## Lifetime `tallies` as the gate's word brought them (SessionGate.clamped_said()). This machine's
## profile (its Session's) follows its own entry's applied `look` and `colour`, so the next game starts
## in them.
class_name Roster
extends Part

## The kinds of its answers, for the HUD's toasts and the Avatars.
const JOINED := &"joined"
const LEFT := &"left"
## A player's Hands numbers, said with their house_ready (core/68).
## The Host's peer id.
const HOST := 1
## The verbs a player asks for itself (core/141).
const WEAR := &"wear"
const COLOUR := &"colour"
const OWN := &"own"
## The longest piece id a verb carries.
const PIECE_ID_MAX := 64
## How many `own` a Guest may send in a second: an Achievements' batch gives several at once.
const OWN_RATE := 120

## Shown on every machine whenever the roster changed (an answer or a snapshot).
signal changed

@export var tuning: CoopTuning

@export_group("State")
## {player id: {"peer": int, "name": String, "colour": int, "at": Vector3, "yaw": float, "look": {"hat", "clothes",
## "socks", "trail": piece id or ""}, "owned": PackedStringArray of piece ids (the basic ones not
## stored: owned_of() adds them), "tallies": {tally name: int}}}.
@export var players := {}
@export_group("")

## The Host's answer to "where does player `by` stand and face": (by: int) -> Transform3D, or null
## when it cannot say (the zoo sets it). Unset, the Parts' `where` gives the place, facing -z.
var pose_of: Callable


func _ready() -> void:
	if tuning == null:
		tuning = CoopTuning.new()


func accepts() -> Dictionary[StringName, Dictionary]:
	var piece := {"type": TYPE_STRING_NAME, "max": PIECE_ID_MAX}
	var colours := maxi(tuning.colours.size(), 1)
	return {
		WEAR: {"args": {"hat": piece, "clothes": piece, "socks": piece, "trail": piece}},
		COLOUR: {"args": {"index": {"type": TYPE_INT, "min": 0, "max": colours - 1}}},
		OWN: {"args": {"piece": piece}, "rate": OWN_RATE},
	}


## The Host: a player's `wear`, `colour` or `own`, for its own entry (the sender's).
func decide(cmd: Command) -> Dictionary:
	var pid := id_of(cmd.by)
	if pid == "":
		return refuse("wrong")
	match cmd.kind:
		WEAR:
			return _wear(pid, cmd.args)
		COLOUR:
			return _colour(pid, cmd.args.get("index"))
		OWN:
			return _own(pid, cmd.args.get("piece"))
	return refuse("wrong")


func _show(now: bool) -> void:
	if not now:
		_follow_profile()
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


## What the player on `peer` wears ({"hat", "clothes", "socks", "trail"}), or {} for nobody.
func look_of(peer: int) -> Dictionary:
	var look: Variant = entry_of(peer).get("look", {})
	return look if look is Dictionary else {}


## The pieces player id `pid` owns: their entry's, plus every basic piece (Wardrobe.owned(), Q2679).
## The Host's check of a `wear`, and the seam for a present's draw (S-122b).
func owned_of(pid: String) -> PackedStringArray:
	return Wardrobe.owned(_owned_in(players.get(pid, {})))


## The colour index of the player on `peer`, or -1.
func colour_index_of(peer: int) -> int:
	return int(entry_of(peer).get("colour", -1))


## The first colour not taken by a player in the Session, starting at `wanted` and wrapping round.
func free_colour(wanted: int, among: Dictionary = players) -> int:
	var count := maxi(tuning.colours.size(), 1)
	var taken := {}
	for pid: Variant in among:
		var e: Dictionary = among[pid]
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
## left and keeps its colour while free.
## `said`: their profile's `look`, `owned`, `tallies` and `colour` wish as the gate clamped them
## (SessionGate.clamped_said()): the word wins over what the entry had; a new id takes its wished colour
## when free, else the next free. Returns the answer, for Parts.apply().
func joined(pid: String, peer: int, who: String, said := {}) -> Dictionary:
	var all := players.duplicate(true)
	if peer == HOST:
		# This machine's own entry made alone under another profile (a test's) gives way: a peer is one player.
		for other: Variant in all.keys():
			if String(other) != pid and int((all[other] as Dictionary).get("peer", 0)) == HOST:
				all.erase(other)
	var others := all.duplicate()
	others.erase(pid)
	var before: Dictionary = all.get(pid, {})
	var entry := {"peer": peer, "name": PlayerProfile.clean_name(who)}
	entry["look"] = plain_look(said.get("look", before.get("look", {})))
	entry["owned"] = _owned_in(said if said.has("owned") else before)
	var tallies: Variant = said.get("tallies", before.get("tallies", {}))
	entry["tallies"] = (tallies as Dictionary).duplicate() if tallies is Dictionary else {}
	if before.is_empty():
		entry["colour"] = free_colour(int(said.get("colour", 0)), others)
		# With no level (the Lobby) nobody stands anywhere yet: placed() gives the spot in the house.
		if _pose(HOST) != null:
			var spot := _spot_for(peer)
			entry["at"] = spot.origin
			entry["yaw"] = spot.basis.get_euler().y
	else:
		entry["colour"] = free_colour(int(before.get("colour", 0)), others)
		if before.has("at"):
			entry["at"] = before["at"]
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


## What a save keeps (docs/architecture/saves.md): every entry, nobody playing (a load has nobody in
## it until they join), each present player where they stand now and which way they face (Q296: each
## starts the loaded game where they quit).
func save_state() -> Dictionary:
	var all := players.duplicate(true)
	for pid: Variant in all:
		var e: Dictionary = all[pid]
		var peer := int(e.get("peer", 0))
		if peer != 0:
			var pose: Variant = _pose(peer)
			if pose != null:
				e["at"] = (pose as Transform3D).origin
				e["yaw"] = (pose as Transform3D).basis.get_euler().y
		e["peer"] = 0
	return {"players": all}


## A save loads into the live Roster (core/62: the Roster lives for the whole game, so players may be
## in it before the house loads): the present players stay as they are (their live look, owned pieces
## and tallies are their profiles', the word at the gate wins over the save's), each standing where the
## save kept them (Q296); every saved player not here comes back with their spot, colour and Hands; an
## entry the save does not name stays.
func restored(saved: Dictionary) -> Dictionary:
	var kept: Dictionary = saved.get("players", {}) if saved.get("players") is Dictionary else {}
	var all := players.duplicate(true)
	for pid: Variant in kept:
		if not (kept[pid] is Dictionary):
			continue
		var was: Dictionary = kept[pid]
		var now: Dictionary = all.get(pid, {})
		if int(now.get("peer", 0)) == 0:
			var back := was.duplicate(true)
			back["peer"] = 0
			all[pid] = back
		else:
			if was.has("at"):
				now["at"] = was["at"]
			if was.has("yaw"):
				now["yaw"] = was["yaw"]
	return {"players": all}


## The Host, as a house comes in (LevelNet): every present player with no spot yet (they joined in the
## Lobby, where nobody stands) gets one, the Host where it stands and the others beside it in peer
## order, as a join in the house would. Returns the answer, or {} when everyone has a spot.
func placed() -> Dictionary:
	var all := players.duplicate(true)
	var host_pose: Variant = _pose(HOST)
	var at: Transform3D = host_pose if host_pose != null else Transform3D.IDENTITY
	var flat := Basis(Vector3.UP, at.basis.get_euler().y)
	var k := 0
	var changed_any := false
	for peer in peers():
		var pid := id_of(peer)
		var e: Dictionary = all[pid]
		if peer != HOST:
			k += 1
		if e.has("at"):
			continue
		var spot := at
		if peer != HOST:
			var side := 1.0 if k % 2 == 1 else -1.0
			spot = Transform3D(flat, at.origin + flat.x * tuning.beside * float(ceili(k / 2.0)) * side)
		e["at"] = spot.origin
		e["yaw"] = spot.basis.get_euler().y
		changed_any = true
	if not changed_any:
		return {}
	var ev := grant({"players": all})
	ev.merge({"kind": &"placed", "by": HOST, "to": id})
	return ev


## The changes that make `piece` owned by the player on `peer`, for another part's answer to carry
## (S-122c: a present opened puts them in its own answer, beside its own patch, so the piece won reaches
## `owned` with no extra ask): {this part's id: patch}, or {} when the piece is unknown, already owned or
## nobody plays on `peer`. Merge it into the answer's "changes".
func owned_patch(by: int, piece: StringName) -> Dictionary:
	var pid := id_of(by)
	if pid == "" or Wardrobe.of(piece) == null or owned_of(pid).has(String(piece)):
		return {}
	var owned := _owned_in(players[pid])
	owned.append(String(piece))
	return _patched(pid, "owned", owned)["changes"]


## A look as an entry keeps it: every slot, a known piece of that slot or "", as plain Strings.
static func plain_look(look: Variant) -> Dictionary:
	var clean := WardrobeLook.clean(look if look is Dictionary else {})
	var out := {}
	for k in WardrobeLook.SLOTS:
		out[String(k)] = String(clean[k])
	return out


## `look` as WEAR's args (four Strings, every slot).
static func wear_args(look: Dictionary) -> Dictionary:
	return plain_look(look)


## The Session is over on this machine (alone again): nobody is in it. Returns the answer.
func cleared() -> Dictionary:
	var ev := grant({"players": {}})
	ev.merge({"kind": &"cleared", "by": HOST, "to": id})
	return ev


## `wear`: `asked` as the new look of `pid`, refused unless every slot names "" or a known piece of that
## slot the player owns (silent: the Wardrobe only offers owned pieces).
func _wear(pid: String, asked: Dictionary) -> Dictionary:
	var want := {}
	for k in WardrobeLook.SLOTS:
		var v: Variant = asked.get(String(k), "")
		if not (v is String or v is StringName):
			return refuse("wrong")
		want[String(k)] = String(v)
	var allowed := WardrobeLook.allowed(want, owned_of(pid))
	for k in WardrobeLook.SLOTS:
		if String(allowed[k]) != want[String(k)]:
			return refuse("not_owned")
	if plain_look((players[pid] as Dictionary).get("look", {})) == want:
		return refuse("already")
	return _patched(pid, "look", want)


## `colour`: Player colour `index` for `pid`, refused "taken" while another present player has it.
func _colour(pid: String, index: Variant) -> Dictionary:
	if not (index is int) or int(index) < 0 or int(index) >= tuning.colours.size():
		return refuse("wrong")
	for other: Variant in players:
		var e: Dictionary = players[other]
		if String(other) != pid and int(e.get("peer", 0)) != 0 and int(e.get("colour", -1)) == int(index):
			return refuse("taken")
	if int((players[pid] as Dictionary).get("colour", -1)) == int(index):
		return refuse("already")
	return _patched(pid, "colour", int(index))


## `own`: piece `piece` appended to what `pid` owns (an Achievement's reward, asked by its machine).
func _own(pid: String, piece: Variant) -> Dictionary:
	if not (piece is String or piece is StringName) or Wardrobe.of(StringName(piece)) == null:
		return refuse("wrong")
	if owned_of(pid).has(String(piece)):
		return refuse("already")
	var owned := _owned_in(players[pid])
	owned.append(String(piece))
	return _patched(pid, "owned", owned)


## A yes: field `field` of `pid`'s entry becomes `value`; the answer names the player.
func _patched(pid: String, field: String, value: Variant) -> Dictionary:
	var all := players.duplicate(true)
	(all[pid] as Dictionary)[field] = value
	var ev := grant({"players": all})
	ev["player"] = pid
	return ev


## The "owned" of entry `e` (a copy), as stored: no basic pieces added.
static func _owned_in(e: Variant) -> PackedStringArray:
	var owned: Variant = (e as Dictionary).get("owned") if e is Dictionary else null
	if owned is PackedStringArray or owned is Array:
		return PackedStringArray(owned)
	return PackedStringArray()


## After an answer, this machine's profile (its Session's) takes its own entry's look and colour, written
## soon. A snapshot is not an answer: a Guest's colour moved off its wish at its join stays its wish.
func _follow_profile() -> void:
	var session := get_parent() as Session
	var profile := session.profile if session != null else null
	if profile == null or not (players.get(profile.id) is Dictionary):
		return
	var e: Dictionary = players[profile.id]
	var moved := false
	if e.get("look") is Dictionary and e["look"] != profile.look:
		profile.look = (e["look"] as Dictionary).duplicate()
		moved = true
	if e.has("colour") and int(e["colour"]) != profile.colour:
		profile.colour = int(e["colour"])
		moved = true
	if moved:
		profile.save_soon()


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
