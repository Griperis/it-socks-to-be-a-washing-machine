## The relay of one Session: a Guest's Commands go up, the Host's answers go down to the Guests that may
## hear them (a refusal to its asker alone; a Guest whose house is not ready only answers about the link).
class_name SessionRelay
extends RefCounted

var _s: Session
## The Parts whose `applied` this Session relays (the one in use while online).
var _listening: Parts = null


func _init(session: Session) -> void:
	_s = session


## The Parts in use relay their answers to the Guests (the Host) and nobody else's.
func listen(p: Parts) -> void:
	if _listening != null and is_instance_valid(_listening) and _listening.applied.is_connected(on_applied):
		_listening.applied.disconnect(on_applied)
	_listening = p
	if p != null:
		p.applied.connect(on_applied)


## A Guest's way up, on the link's Parts and the level's alike.
func set_relay(c: Callable) -> void:
	for p: Parts in [_s.link_parts, _s.level_parts]:
		if p != null:
			p.relay = c


## A Guest: Command `cmd` goes up to the Host (a Parts' relay).
func send_up(cmd: Command) -> void:
	_s._command.rpc_id(1, cmd.to_wire())


## The Host's answer goes to every Guest; a refusal changes nothing, so it goes to the asker alone
## (I13, F07), and to nobody when the asker is the Host.
## A Guest whose house is not ready yet hears only answers about the link's parts.
func on_applied(ev: Dictionary) -> void:
	var s := _s
	if not s.multiplayer.is_server():
		return
	var link_only := _about_link_only(ev)
	if not ev.get("ok", false):
		var asker := int(ev.get("by", 0))
		if s._guests.has(asker) and (link_only or s._house.has(asker)):
			s._event.rpc_id(asker, ev)
		return
	for peer: int in s._guests:
		if link_only or s._house.has(peer):
			s._event.rpc_id(peer, ev)


## Whether answer `ev` changes (or names) only the link's parts.
func _about_link_only(ev: Dictionary) -> bool:
	var changes: Variant = ev.get("changes")
	if changes is Dictionary and not (changes as Dictionary).is_empty():
		for id: Variant in changes:
			if not is_link_part(StringName(id)):
				return false
		return true
	return is_link_part(StringName(ev.get("to", &"")))


## Whether `id` names one of the link's parts (there is a link and it is not the level's).
func is_link_part(id: StringName) -> bool:
	var link_parts := _s.link_parts
	if link_parts == null:
		return false
	if _s.level_parts != null:
		return _s.level_parts.is_link_part(id)
	return link_parts.of(id) != null
