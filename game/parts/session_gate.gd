## The gate of one Session and who is in the game: a Guest's word read and admitted or refused, an admitted
## Guest taken into the Roster with the link's snapshot, a leaver forgotten, the Hands numbers a player brings.
##
## Godot starts replicating (spawns, synchronizers) and accepting RPCs the moment a peer is admitted, so
## nobody is admitted before the gate's checks. SceneMultiplayer's auth_callback (answer()) holds each new
## connection: the Guest sends its word (say_word()): its PROTOCOL as 4 bytes, then its player id (the
## profile's, never the peer id), its name, its Hands' numbers an Upgrade changes (HandsTuning.to_sent(),
## D13: the Host clamps them to what Upgrades can make them and writes them into the Roster) and, when it
## already has a level, that level's layout hash. The Host answers ACCEPTED and admits it (complete_auth),
## or REFUSED and a reason byte and never admits it, so a refused Guest receives no spawn, no synchronized
## value and no RPC. A Guest is refused when its PROTOCOL differs, or its layout differs from the Host's
## level ("Another version of the game"), when the game is full, or when its player id already plays ("You
## are already in this game"). Once both sides complete, peer_connected fires: the Host writes the player
## into the Roster (one answer) and sends the link's snapshot (`linked`). From M4 the word carries Steam's
## auth ticket too (Q2458); no token before (Q2449).
class_name SessionGate
extends RefCounted

var _s: Session
## The Host: who passed the gate and is not in yet: {peer: {"id": player id, "name": String}}.
var _waiting: Dictionary[int, Dictionary] = {}
## The Host: the player id on each admitted peer (a live field: never saved, never a key).
var _players: Dictionary[int, String] = {}


func _init(session: Session) -> void:
	_s = session


func clear() -> void:
	_waiting.clear()
	_players.clear()


## A Guest went: each part lets go of what it held (Parts.left: its Hands drop where it stood, the
## Roster keeps where that was), then the peer is forgotten.
func left(peer: int) -> void:
	var s := _s
	s._guard.forget(peer)
	_waiting.erase(peer)
	var was_in := s._house.forget(peer)
	if s._guests.erase(peer):
		if was_in:
			s._house.tell()
		s.parts.left(peer)
		s._note("%d left" % peer, false)
	_players.erase(peer)


## What the other side said at the gate. The Host reads a Guest's word and admits it or refuses it;
## a Guest reads the Host's answer. Until both sides call complete_auth(), nothing replicates and no
## RPC passes; a peer never admitted is dropped after SceneMultiplayer.auth_timeout.
func answer(peer: int, data: PackedByteArray) -> void:
	var sm := _s._scene_multiplayer()
	if _s.multiplayer.is_server():
		var why := _refusal(peer, data)
		if why != 0:
			sm.send_auth(peer, PackedByteArray([Session.REFUSED, why]))
			return
		sm.send_auth(peer, PackedByteArray([Session.ACCEPTED]))
		sm.complete_auth(peer)
	elif peer == 1:
		if data.size() == 1 and data[0] == Session.ACCEPTED:
			sm.complete_auth(peer)
		else:
			_s._end.call_deferred(refusal_text(data[1] if data.size() == 2 else Session.WHY_VERSION))


## The Host: why a Guest's gate word is refused (a WHY_ code), or 0 when it may come in (it then
## waits in _waiting for peer_connected). Every refusal is counted.
func _refusal(peer: int, data: PackedByteArray) -> int:
	var guard := _s._guard
	var theirs := int(data.decode_u32(0)) if data.size() >= 4 else -1
	if theirs != Session.PROTOCOL:
		guard.drop(peer, "protocol", "%s, not %d" % [str(theirs) if theirs >= 0 else "%d bytes" % data.size(), Session.PROTOCOL])
		return Session.WHY_VERSION
	var said: Variant = bytes_to_var(data.slice(4)) if data.size() > 4 else null
	var word: Dictionary = said if said is Dictionary else {}
	if not PlayerProfile.is_id(word.get("id")) or not (word.get("name") is String) \
			or (word.has("layout") and not (word["layout"] is String)):
		guard.drop(peer, "gate", "an unreadable word of %d bytes" % data.size())
		return Session.WHY_VERSION
	# A Guest that already has a level is checked against this machine's now: it never enters the
	# Roster when its house_ready would be refused anyway.
	var mine := _s._level_layout()
	if word.has("layout") and mine != "" and String(word["layout"]) != mine:
		guard.drop(peer, "layout", "another scene layout")
		return Session.WHY_VERSION
	var pid := String(word["id"])
	if _plays(pid):
		guard.drop(peer, "already", pid.left(12))
		return Session.WHY_ALREADY
	if 1 + _players.size() + _waiting.size() >= _s.tuning.max_players:
		guard.drop(peer, "full", "%d players" % _s.tuning.max_players)
		return Session.WHY_FULL
	var hands: Variant = word.get("hands", {})
	if not (hands is Dictionary) or (hands as Dictionary).size() > Command.ARGS_MAX:
		guard.drop(peer, "gate", "unreadable Hands numbers")
		return Session.WHY_VERSION
	_waiting[peer] = {"id": pid, "name": PlayerProfile.clean_name(word["name"]), "hands": clamped_hands(hands),
			"in_level": word.has("layout") and mine != ""}
	return 0


## Whether player id `pid` plays now or waits at the gate (the Host's own id included).
func _plays(pid: String) -> bool:
	if pid == _s.profile.id or _players.values().has(pid):
		return true
	for w: Dictionary in _waiting.values():
		if String(w["id"]) == pid:
			return true
	return _s.roster != null and _s.roster.is_live(pid)


## What a refused player is told for a WHY_ code.
func refusal_text(why: int) -> String:
	match why:
		Session.WHY_FULL:
			return Session.FULL % _s.tuning.max_players
		Session.WHY_ALREADY:
			return Session.ALREADY
	return Session.WRONG_BUILD


## A Guest: the Host's connection waits at the gate; say this machine's word.
func say_word(peer: int) -> void:
	if peer != 1:
		return
	var word := PackedByteArray()
	word.resize(4)
	word.encode_u32(0, _s.protocol)
	var said := {"id": _s.profile.id, "name": _s.profile.name, "hands": own_hands()}
	var layout := _s._level_layout()
	if layout != "":
		said["layout"] = layout
	word.append_array(var_to_bytes(said))
	_s._scene_multiplayer().send_auth(peer, word)


## A player's Hands numbers as the Host keeps them: clamped to what the Upgrades can make them by this
## level's Hands (HandsTuning.clamped()), only the known names; {} with no Hands here.
func clamped_hands(sent: Dictionary) -> Dictionary:
	var parts := _s.parts
	var hands := parts.find(func(part: Part) -> bool: return part is Hands) as Hands if parts != null else null
	if hands == null:
		return {}
	return hands.own_tuning().clamped(sent).to_sent()


## This machine's own player's Hands numbers (HandsTuning.to_sent()), or {} with no player here.
func own_hands() -> Dictionary:
	for node in _s.get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player != null and player.multiplayer == _s.multiplayer and player.hands_tuning != null:
			return player.hands_tuning.to_sent()
	return {}


## The Host: a Guest passed the gate: the Roster takes it in (every Guest already in hears that), then it
## gets the link's state, its own entry in it, then every event about the link. The level's state waits
## for its house_ready (SessionHouse). A Guest whose word already named this machine's level layout (it
## joined from inside that level: the command line, the title's Join today) has said its house is ready at
## the gate: once this machine's level is settled (its Socks laid, house/09) it is taken in and gets the
## link's and the level's snapshot together, as one welcome.
func joined(peer: int) -> void:
	var s := _s
	if not s.multiplayer.is_server() or s._guests.has(peer) or not _waiting.has(peer):
		return
	var level := s.level_parts
	var in_level := bool(_waiting[peer].get("in_level", false)) and level != null
	while in_level and not level.is_settled():
		await level.settled
		if not is_instance_valid(s) or not _waiting.has(peer) or not s.is_inside_tree() or s.level_parts != level:
			return
	var who: Dictionary = _waiting[peer]
	_waiting.erase(peer)
	_players[peer] = String(who["id"])
	if s.roster != null:
		s.parts.apply(s.roster.joined(String(who["id"]), peer, String(who["name"]), who.get("hands", {})))
	s._guests[peer] = true
	var snap := s.link_parts.snapshot() if s.link_parts != null else {}
	s._linked.rpc_id(peer, snap)
	s._houses.rpc_id(peer, s._house.inside())
	s._note("%d joined (%s, colour %d, link snapshot %d bytes)" % [peer, String(who["id"]).left(12),
			s.roster.colour_index_of(peer) if s.roster != null else -1, var_to_bytes(snap).size()], false)
	if in_level:
		s._house.take_into(peer, level)
