## The house handshake of one Session, both sides: who may be sent this machine's level, and when a Guest is
## taken into it with the level's snapshot.
##
## The handshake (core/62): when a Guest's level is bound and its starting state made, it sends `house_ready`
## with its PROTOCOL, its level's layout hash. A Guest that joined
## from inside the Host's level, its layout in its gate word, has said it at the gate and is welcomed once
## the Host's level is settled. The Host refuses a mismatch ("Another version of the game", the Guest goes
## alone), else waits until its own level is settled and sends that level's snapshot (`welcomed`). Until
## then the Host sends that Guest nothing of the level: no answer about a level Part, no spawn, no
## synchronized value (LevelRuntime's visibility filter asks Session.sees_house()), and drops a Command for
## a level Part (reason "not_ready", counted, never printed).
class_name SessionHouse
extends RefCounted

## A Guest: it has the link snapshot.
var in_game := false

var _s: Session
## The Host: Guests whose house_ready was handled and who got the level snapshot (they play in it).
var _in_house: Dictionary[int, bool] = {}
## The Host: Guests whose house_ready waits for this machine's level to settle.
var _waiting: Dictionary[int, bool] = {}
## The Host: Guests whose house_ready came while this machine had no level (its house still loading
## after Start): {peer: layout}, answered when a level attaches.
var _early: Dictionary[int, String] = {}
## A Guest: the other Guests the Host says are in its house (`_houses`), the only ones this machine's
## own avatar is synchronized to (a Guest still loading has nowhere to put it: core/68).
var _seen: Dictionary[int, bool] = {}
## A Guest: the level whose house_ready was sent (or is waiting to be), so it is sent once.
var _asked: Parts = null


func _init(session: Session) -> void:
	_s = session


func clear() -> void:
	_in_house.clear()
	_waiting.clear()
	_early.clear()
	_seen.clear()
	in_game = false
	_asked = null


## Online, not peer 1: the Host asks whether that Guest is in; a Guest whether the Host said so.
func sees(peer: int) -> bool:
	if not _s.multiplayer.is_server():
		return _seen.has(peer)
	return _in_house.has(peer)


## Whether Guest `peer`'s house_ready was handled (the Host).
func has(peer: int) -> bool:
	return _in_house.has(peer)


## The Guests in this machine's house (the Host).
func inside() -> PackedInt32Array:
	return PackedInt32Array(_in_house.keys())


## A Guest `peer` went: forgotten here. Whether it was in the house.
func forget(peer: int) -> bool:
	_waiting.erase(peer)
	_early.erase(peer)
	return _in_house.erase(peer)


## Online, a level came in: a Guest says its house_ready once it is settled; the Host answers the
## house_ready that came while it had none.
func level_attached() -> void:
	if not _s.multiplayer.is_server():
		step()
		return
	var early := _early.duplicate()
	_early.clear()
	for peer: int in early:
		if _s._guests.has(peer):
			_take(peer, early[peer])


## Online, the level went: the Host sends nobody its level; a Guest tells the Host its house is gone.
func level_detached() -> void:
	if _s.multiplayer.is_server():
		var had := not _in_house.is_empty()
		_in_house.clear()
		_waiting.clear()
		if had:
			tell()
	else:
		_asked = null
		if in_game and _s.is_inside_tree():
			_s._house_left.rpc_id(1)


## The Host: Guest `peer`'s level is bound and settled: its PROTOCOL and layout must be this machine's
## level's, else it is refused as another version. Then, once this machine's own level is settled (its
## Socks laid, house/09), it gets the level's whole state and from now on everything of it.
func ready_said(peer: int, protocol_said: Variant, layout: Variant) -> void:
	if not _s.multiplayer.is_server() or not _s._guests.has(peer):
		_s._guard.drop(peer, "not in the game", "")
		return
	if not (protocol_said is int) or not (layout is String) or String(layout).length() > 128:
		_s._guard.drop(peer, "house", "an unreadable house_ready")
		return
	if _in_house.has(peer) or _waiting.has(peer):
		return
	if int(protocol_said) != Session.PROTOCOL:
		_s._guard.drop(peer, "protocol", "%d at house_ready, not %d" % [int(protocol_said), Session.PROTOCOL])
		_s._house_refused.rpc_id(peer, Session.WHY_VERSION)
		return
	if _s.level_parts == null:
		# This machine's house is still loading (both load at Start, core/63): it is answered when it comes.
		_early[peer] = String(layout)
		return
	_take(peer, String(layout))


## The Host: Guest `peer`'s house is ready with `layout`, and this machine has a level: once that level
## is bound its layout is checked, and once it is settled the Guest is taken in.
func _take(peer: int, layout: String) -> void:
	var s := _s
	var level := s.level_parts
	_waiting[peer] = true
	while not level.is_bound:
		await level.bound
		if not is_instance_valid(s) or not _waiting.has(peer) or s.level_parts != level or not s.is_inside_tree():
			return
	if layout != Session.layout_of(level):
		_waiting.erase(peer)
		s._guard.drop(peer, "layout", "another level layout at house_ready")
		s._house_refused.rpc_id(peer, Session.WHY_VERSION)
		return
	while not level.is_settled():
		await level.settled
		if not is_instance_valid(s) or not _waiting.has(peer) or s.level_parts != level or not s.is_inside_tree():
			return
	_waiting.erase(peer)
	take_into(peer, level)


## The Host: Guest `peer`'s house is ready and this machine's `level` settled: it gets the level's whole
## state and from now on everything of it.
func take_into(peer: int, level: Parts) -> void:
	if not _s._guests.has(peer) or _in_house.has(peer):
		return
	_in_house[peer] = true
	var snap := level.snapshot()
	_s._welcome.rpc_id(peer, snap)
	_s.house_changed.emit(peer)
	tell()
	_s._note("%d is in the level (snapshot %d bytes)" % [peer, var_to_bytes(snap).size()], false)


## The Host: every Guest hears who is in this machine's house (after the spawns that Guest's coming in
## sent: house_changed comes first), so a Guest's own avatar goes only to the Guests that can show it.
func tell() -> void:
	var now_inside := inside()
	for peer: int in _s._guests:
		_s._houses.rpc_id(peer, now_inside)


## The Host: Guest `peer`'s level went (a scene change): it is sent nothing of this machine's level until
## its next house_ready.
func left(peer: int) -> void:
	if not _s.multiplayer.is_server() or not _s._guests.has(peer):
		_s._guard.drop(peer, "not in the game", "")
		return
	_waiting.erase(peer)
	_early.erase(peer)
	if _in_house.erase(peer):
		_s.house_changed.emit(peer)
		tell()


## A Guest: the Guests in the Host's house now (the Host's tell()).
func houses_said(said: Variant) -> void:
	_seen.clear()
	if not (said is PackedInt32Array) or (said as PackedInt32Array).size() > _s.tuning.max_players:
		return
	for peer in said as PackedInt32Array:
		_seen[peer] = true


## A Guest in the game: once its level is bound and settled, it tells the Host (once per level).
func step() -> void:
	var s := _s
	var level := s.level_parts
	if not in_game or level == null or _asked == level or s.multiplayer.is_server():
		return
	_asked = level
	while not level.is_bound:
		await level.bound
		if not is_instance_valid(s) or _asked != level or not s.is_inside_tree():
			return
	while not level.is_settled():
		await level.settled
		if not is_instance_valid(s) or _asked != level or not s.is_inside_tree():
			return
	if s._peer == null or s.level_parts != level:
		return
	s._house_ready.rpc_id(1, s.protocol, Session.layout_of(level))
