## The guards of one Session: a Guest's Command checked before the Host answers it, and every dropped packet
## counted and printed at most once a second.
##
## Every any_peer RPC checks its packet before anything reads it. A Guest's Command, in this order: its wire
## shape (Command.shape_error()), its target is a part Parts bound (an id under the level or the link: `..`
## or an absolute path names none), a level Part only once that Guest's house is ready, the part accepts()
## the verb, the args match the verb's declared args exactly, and the player is within the verb's rate
## ("rate" in accepts(), else Session.RATE). A bad packet is dropped and counted (Session.dropped, per player
## and reason; stats["bad_packets"] in all), printed at most once a second per player and reason, and never
## crashes or kicks anyone. The Host's own Commands skip these checks; every Command still goes through
## decide().
class_name SessionGuard
extends RefCounted

var _s: Session
## Per Guest and verb: [the start of this second in ms, Commands in it].
var _rates: Dictionary[int, Dictionary] = {}
## Per Guest and reason: when a drop was last printed, in ms.
var _said: Dictionary[int, Dictionary] = {}


func _init(session: Session) -> void:
	_s = session


func clear() -> void:
	_rates.clear()
	_said.clear()


func forget(peer: int) -> void:
	_rates.erase(peer)
	_said.erase(peer)


## The Host: Guest `peer`'s Command `wire`: checked (see the top), then answered for the Guest who sent it
## (first to arrive wins).
func command(peer: int, wire: Variant) -> void:
	var s := _s
	if not s.multiplayer.is_server() or not s._guests.has(peer):
		drop(peer, "not in the game", "")
		return
	var cmd := Command.from_wire(wire, peer)
	if cmd == null:
		drop(peer, "shape", Command.shape_error(wire))
		return
	var parts := s.parts
	var part := parts.of(cmd.to) if parts != null else null
	if part == null:
		drop(peer, "no part", String(cmd.to).left(60))
		return
	if not s._house.has(peer) and not s._relay.is_link_part(cmd.to):
		count(peer, "not_ready")
		return
	var verb: Dictionary = part.accepts().get(cmd.kind, {})
	if verb.is_empty():
		drop(peer, "verb", "%s does not accept %s" % [cmd.to, String(cmd.kind).left(40)])
		return
	var why := Command.args_error(cmd.args, verb.get("args", {}))
	if why != "":
		drop(peer, "args", "%s: %s" % [cmd.kind, why])
		return
	var rate := int(verb.get("rate", Session.RATE))
	if not _rate_ok(peer, cmd.kind, rate):
		drop(peer, "rate", "more than %d %s a second" % [rate, cmd.kind])
		return
	parts.apply(parts.answer(cmd))


## Counts one `verb` from `peer` in the current second; false once it is over `limit`.
func _rate_ok(peer: int, verb: StringName, limit: int) -> bool:
	var now := Time.get_ticks_msec()
	var verbs: Dictionary = _rates.get_or_add(peer, {})
	var r: Array = verbs.get(verb, [now, 0])
	if now - int(r[0]) >= 1000:
		r = [now, 0]
	r[1] = int(r[1]) + 1
	verbs[verb] = r
	return int(r[1]) <= limit


## A packet from `peer` was dropped: counted (dropped, stats), never printed. Returns that peer's counts.
func count(peer: int, reason: String) -> Dictionary:
	_s.stats["bad_packets"] = int(_s.stats["bad_packets"]) + 1
	var counts: Dictionary = _s.dropped.get_or_add(peer, {})
	counts[reason] = int(counts.get(reason, 0)) + 1
	return counts


## A packet from `peer` was dropped: counted under `reason`, printed at most once a second per
## player and reason.
func drop(peer: int, reason: String, detail: String) -> void:
	var counts := count(peer, reason)
	var said: Dictionary = _said.get_or_add(peer, {})
	var now := Time.get_ticks_msec()
	if now - int(said.get(reason, -1000)) < 1000:
		return
	said[reason] = now
	_s._note("dropped a packet from peer %d: %s%s; %d so far" % [peer, reason,
			" (%s)" % detail if detail != "" else "", int(counts[reason])], true)
