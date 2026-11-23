## The co-op link of one machine: the only node with RPCs (Godot finds an RPC by node path, so it
## sits at the same path on every machine). The Host opens for Guests and a Guest joins it through the
## `transport` (NetTransport: ENet by address now, Steam at M4); this file names no transport's peer
## type and reads no address. Commands go up, the Host's answers come down, and a Guest the gate
## admits gets the whole state first. Playing alone needs none of it: with no peer, Parts is a Host
## of one.
##
## It lives in the game link (GameLink, core/62) for the whole game, so a scene change keeps the
## connection: it works with two Parts, the link's (`link_parts`: the Roster) and the loaded level's
## (`level_parts`, null between levels), and `parts` is the one in use (the level's, which reads
## through to the link's, else the link's).
##
## The gate: Godot starts replicating (spawns, synchronizers) and accepting RPCs the moment a peer is
## admitted, so nobody is admitted before the gate's checks. SceneMultiplayer's auth_callback holds
## each new connection: the Guest sends its word (send_auth): its PROTOCOL as 4 bytes, then its player
## id (the profile's, never the peer id), its name, its Hands' numbers an Upgrade changes
## (HandsTuning.to_sent(), D13: the Host clamps them to what Upgrades can make them and writes them
## into the Roster) and, when it already has a level, that level's layout hash. The Host answers
## ACCEPTED and admits it (complete_auth), or REFUSED and a reason byte and never admits it, so a
## refused Guest receives no spawn, no synchronized value and no RPC. A Guest is refused when its
## PROTOCOL differs, or its layout differs from the Host's level ("Another version of the game"), when
## the game is full, or when its player id already plays ("You are already in this game"). Once both
## sides complete, peer_connected fires: the Host writes the player into the Roster (one answer) and
## sends the link's snapshot (`linked`). From M4 the word carries Steam's auth ticket too (Q2458); no
## token before (Q2449).
##
## The house handshake (core/62): when a Guest's level is bound and its starting state made, it sends
## `house_ready` with its PROTOCOL and its level's layout hash (a Guest that joined from inside the
## Host's level, its layout in its gate word, has said it at the gate and is welcomed once the Host's
## level is settled). The Host refuses a mismatch ("Another
## version of the game", the Guest goes alone), else waits until its own level is settled and sends
## that level's snapshot (`welcomed`). Until then the Host sends that Guest nothing of the level: no
## answer about a level Part, no spawn, no synchronized value (LevelRuntime's visibility filter asks
## sees_house()), and drops a Command for a level Part (reason "not_ready", counted, never printed).
##
## Guarding: every any_peer RPC checks its packet before anything reads it. A Guest's Command, in
## this order: its wire shape (Command.shape_error()), its target is a part Parts bound (an id under
## the level or the link: `..` or an absolute path names none), a level Part only once that Guest's
## house is ready, the part accepts() the verb, the args match the verb's declared args exactly, and
## the player is within the verb's rate.
## A bad packet is dropped and counted (`dropped`, per player and reason; stats["bad_packets"] in
## all), printed at most once a second per player and reason, and never crashes or kicks anyone.
## The Host's own Commands skip these checks; every Command still goes through decide().
class_name Session
extends Node

## A Guest has the Host's level snapshot: it plays in the Host's level.
signal welcomed
## A Guest has the Host's link snapshot (the Roster): it is in the game, its level may still load.
signal linked
## The Host: Guest `peer` came into this machine's level (its house_ready was handled) or left it
## (sees_house() changed for it): the Avatars spawn its avatar only while it is in.
signal house_changed(peer: int)
## The session is over for this machine; `text` says why.
signal ended(text: String)

## The wire's version: a Guest on another one is refused at the gate. Bump it whenever an RPC, a
## synchronized property, a spawnable scene or the shape of a Command, an event, a snapshot or the
## gate's word changes. The word's first 4 bytes (the PROTOCOL) never move, so any two builds can
## tell they differ.
const PROTOCOL := 15  # 15: core/41, an avatar's Back and riding pose (riding, ride_offset); a jump cue. 14: core/62, the game link: the layout leaves the gate's word for house_ready, the link's snapshot
## The gate's answers: one byte, and after REFUSED one byte saying why.
const ACCEPTED := 1
const REFUSED := 0
const WHY_VERSION := 1
const WHY_FULL := 2
const WHY_ALREADY := 3
const PORT := 24565
## The most Commands of one verb one Guest may send in a second, when the part declares no "rate".
const RATE := 10
## What a player is told (Q2444, Q2445, Q2447: the old texts, "Host" capitalised).
const WRONG_BUILD := "Another version of the game"
const FULL := "The game is full (%d players)"
const ALREADY := "You are already in this game"
const HOST_QUIT := "The Host ended the session"
const UNREACHABLE := "Could not reach %s"

## The game link's Parts (the Roster's); a Session with none (a test's) works with a level's alone.
@export var link_parts: Parts
## Who plays: written here on the Host when a player is admitted, and by Parts.left() when one goes.
## Optional: without one the Session still gates and relays.
@export var roster: Roster
@export var tuning: CoopTuning
## The port to open; 0 opens on a free one (tests do; read it back after host()).
@export var port := PORT

## A test run sets it (tests/hooks.gd, coop/12): every Host listens on a port the system picks and reads it
## back, so two test runs at once never clash on `port`.
static var free_port := false

## Links the wiring check lets stay empty: the code below has a fallback.
const WIRING_OPTIONAL := ["roster", "tuning", "link_parts"]

## The loaded level's Parts (attach_level()), null between levels.
var level_parts: Parts = null
## The Parts in use: the level's (which reads through to the link's), else the link's. Setting it
## attaches a level's (a test's bare Session).
var parts: Parts:
	get: return level_parts if level_parts != null else link_parts
	set(value): attach_level(value)

## How this machine reaches the others.
var transport: NetTransport = EnetTransport.new()
## Who this machine's player is; host() or join() makes one in memory when none was given.
var profile: PlayerProfile = null
## What this machine says at the gate as its PROTOCOL (a test stands in for another build with it).
var protocol := PROTOCOL
var stats := {"bad_packets": 0}
## What was dropped, per player and reason: {peer: {"args": 2, "rate": 5}}. Reasons: "protocol",
## "gate" (an unreadable word), "layout", "already", "full" (refused at the gate or at house_ready),
## "not in the game", "shape", "no part", "not_ready" (a level Part before house_ready), "verb",
## "args", "rate", "house" (an unreadable house_ready).
var dropped: Dictionary[int, Dictionary] = {}

var _peer: MultiplayerPeer = null
## The Host: who passed the gate and is not in yet: {peer: {"id": player id, "name": String}}.
var _waiting: Dictionary[int, Dictionary] = {}
## The Host: the player id on each admitted peer (a live field: never saved, never a key).
var _players: Dictionary[int, String] = {}
## Guests the gate admitted, who got the link snapshot; only they receive events.
var _guests: Dictionary[int, bool] = {}
## The Host: Guests whose house_ready was handled and who got the level snapshot (they play in it).
var _in_house: Dictionary[int, bool] = {}
## The Host: Guests whose house_ready waits for this machine's level to settle.
var _house_waiting: Dictionary[int, bool] = {}
## A Guest: it has the link snapshot.
var _in_game := false
## A Guest: the level whose house_ready was sent (or is waiting to be), so it is sent once.
var _house_asked: Parts = null
## The Parts whose `applied` this Session relays (the one in use while online).
var _listening: Parts = null
## Per Guest and verb: [the start of this second in ms, Commands in it].
var _rates: Dictionary[int, Dictionary] = {}
## Per Guest and reason: when a drop was last printed, in ms.
var _said: Dictionary[int, Dictionary] = {}
## A Guest: where it is joining until the welcome.
var _joining := ""
## A Guest: gives the join up after join_timeout with no welcome.
var _give_up := Timer.new()
## Set while this node leaves the tree: closing then writes nothing.
var _leaving := false


func _ready() -> void:
	if tuning == null:
		tuning = CoopTuning.new()
	_give_up.name = "GiveUp"
	_give_up.one_shot = true
	_give_up.timeout.connect(_on_unreachable)
	add_child(_give_up)


## Opens the game for Guests. Call it once the level and its Parts are ready.
func host() -> Error:
	_prepare()
	if free_port:
		port = 0
	var err := transport.host(port, tuning.max_players * 2)
	if err != OK:
		Log.error("net", "cannot listen on port %d (%s)" % [port, error_string(err)])
		return err
	_peer = transport.peer
	if transport.local_port() > 0:
		port = transport.local_port()
	var sm := _scene_multiplayer()
	sm.auth_callback = _gate
	sm.auth_timeout = tuning.auth_timeout
	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.connect(_on_peer_joined)
	multiplayer.peer_disconnected.connect(_on_peer_left)
	_listen(parts)
	if roster != null:
		parts.apply(roster.joined(profile.id, Roster.HOST, profile.name, _clamped_hands(_own_hands())))
	_note("hosting on %s" % transport.describe(), false)
	return OK


## Playing alone (a Host of one, core/58): this machine's player is in its own Roster under its
## profile's id, as when it hosts, so its Hands and Coins are kept by its player id, never its peer
## number, and a save keeps where it stands. Nothing while a session is open.
func enter_alone() -> void:
	if is_online() or roster == null:
		return
	if profile == null:
		profile = PlayerProfile.fresh()
	parts.apply(roster.joined(profile.id, Roster.HOST, profile.name, _clamped_hands(_own_hands())))


## Joins the Host at `where` (opaque to this file: "ip" or "ip:port" for ENet). From now on this
## machine's Commands go up to the Host. With no welcome in CoopTuning.join_timeout, or when the
## transport gives up first, it ends with "Could not reach <where>".
func join(where: String) -> Error:
	_prepare()
	var err := transport.join(where)
	if err != OK:
		return err
	_peer = transport.peer
	var sm := _scene_multiplayer()
	sm.auth_callback = _gate
	sm.auth_timeout = tuning.auth_timeout
	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_authenticating.connect(_on_authenticating)
	multiplayer.server_disconnected.connect(_on_host_gone)
	multiplayer.connection_failed.connect(_on_unreachable)
	_set_relay(_send_up)
	_listen(parts)
	_joining = where
	_give_up.start(tuning.join_timeout)
	return OK


## This player's id: 1 on the Host and when playing alone, the peer id on a Guest.
## Out of the tree (a level's own link as the level leaves) it is the Host's id: nobody else is left.
func me() -> int:
	return multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST


func is_online() -> bool:
	return _peer != null


## Whether this machine is a Guest still waiting for the Host's welcome.
func is_joining() -> bool:
	return _joining != ""


## Leaves: a Host's Guests hear the Host quit; a Guest's machine is a Host of one again, with nobody
## in its Roster.
func close() -> void:
	if _peer == null:
		return
	_peer.close()
	# Also when something wraps our peer (a test's delay): the machine is alone again either way.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_scene_multiplayer().auth_callback = Callable()
	for pair: Array in [[multiplayer.peer_connected, _on_peer_joined], [multiplayer.peer_disconnected, _on_peer_left],
			[multiplayer.peer_authenticating, _on_authenticating], [multiplayer.server_disconnected, _on_host_gone],
			[multiplayer.connection_failed, _on_unreachable]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])
	_listen(null)
	var was_guest := parts != null and parts.relay.is_valid()
	_set_relay(Callable())
	if was_guest and not _leaving:
		parts.went_alone()  # coop/12: its looks-only bodies become its own
	_peer = null
	transport.peer = null
	_joining = ""
	_give_up.stop()
	_waiting.clear()
	_players.clear()
	_guests.clear()
	_in_house.clear()
	_house_waiting.clear()
	_in_game = false
	_house_asked = null
	_rates.clear()
	_said.clear()
	if roster != null and not _leaving and not roster.players.is_empty() and parts != null and parts.of(roster.id) == roster:
		parts.apply(roster.cleared())


## A level comes in (LevelRuntime, as it enters the tree): its Parts read through to the link's and
## become the ones in use. Online, a Guest's Commands go up from it and, once it is settled, its
## house_ready goes to the Host.
func attach_level(p: Parts) -> void:
	if p == level_parts:
		return
	if level_parts != null:
		detach_level(level_parts)
	level_parts = p
	if p == null:
		return
	if link_parts != null and p != link_parts:
		p.link = link_parts
	if _peer == null:
		return
	_listen(parts)
	if not multiplayer.is_server():
		p.relay = _send_up
		_house_step()


## A level goes (LevelRuntime, as it leaves the tree): the link's Parts are in use again. The Host
## stops sending any Guest the level; a Guest tells the Host its house is gone.
func detach_level(p: Parts) -> void:
	if p == null or p != level_parts:
		return
	level_parts = null
	if _peer == null:
		return
	p.relay = Callable()
	_listen(parts)
	if multiplayer.is_server():
		_in_house.clear()
		_house_waiting.clear()
	else:
		_house_asked = null
		if _in_game and is_inside_tree():
			_house_left.rpc_id(1)


## The Host: whether this machine may send Guest `peer` anything of its level (its house_ready was
## handled). True on a Guest and alone: a Guest sends its own avatar to the Host, who has a house.
## LevelRuntime's visibility filter on every synchronizer of the level asks it.
func sees_house(peer: int) -> bool:
	if _peer == null or not multiplayer.is_server() or peer == Parts.HOST:
		return true
	return _in_house.has(peer)


## Whether Guest `peer`'s house_ready was handled (the Host).
func in_house(peer: int) -> bool:
	return _in_house.has(peer)


## The hash of the sorted Part ids `p` binds: what both machines' scenes must declare alike.
static func layout_of(p: Parts) -> String:
	var ids := PackedStringArray()
	for k in p.ids():
		ids.append(String(k))
	ids.sort()
	return "\n".join(ids).sha256_text()


func _prepare() -> void:
	if profile == null:
		profile = PlayerProfile.fresh()


## The layout hash of this machine's level, or "" with none bound.
func _level_layout() -> String:
	return layout_of(level_parts) if level_parts != null and level_parts.is_bound else ""


## The Parts in use relay their answers to the Guests (the Host) and nobody else's.
func _listen(p: Parts) -> void:
	if _listening != null and is_instance_valid(_listening) and _listening.applied.is_connected(_on_applied):
		_listening.applied.disconnect(_on_applied)
	_listening = p
	if p != null:
		p.applied.connect(_on_applied)


## A Guest's way up, on the link's Parts and the level's alike.
func _set_relay(c: Callable) -> void:
	for p: Parts in [link_parts, level_parts]:
		if p != null:
			p.relay = c


# --- The gate (both sides) ----------------------------------------------------------------------

## What the other side said at the gate. The Host reads a Guest's word and admits it or refuses it;
## a Guest reads the Host's answer. Until both sides call complete_auth(), nothing replicates and no
## RPC passes; a peer never admitted is dropped after SceneMultiplayer.auth_timeout.
func _gate(peer: int, data: PackedByteArray) -> void:
	var sm := _scene_multiplayer()
	if multiplayer.is_server():
		var why := _refusal(peer, data)
		if why != 0:
			sm.send_auth(peer, PackedByteArray([REFUSED, why]))
			return
		sm.send_auth(peer, PackedByteArray([ACCEPTED]))
		sm.complete_auth(peer)
	elif peer == 1:
		if data.size() == 1 and data[0] == ACCEPTED:
			sm.complete_auth(peer)
		else:
			_end.call_deferred(_refusal_text(data[1] if data.size() == 2 else WHY_VERSION))


## The Host: why a Guest's gate word is refused (a WHY_ code), or 0 when it may come in (it then
## waits in _waiting for peer_connected). Every refusal is counted.
func _refusal(peer: int, data: PackedByteArray) -> int:
	var theirs := int(data.decode_u32(0)) if data.size() >= 4 else -1
	if theirs != PROTOCOL:
		_drop(peer, "protocol", "%s, not %d" % [str(theirs) if theirs >= 0 else "%d bytes" % data.size(), PROTOCOL])
		return WHY_VERSION
	var said: Variant = bytes_to_var(data.slice(4)) if data.size() > 4 else null
	var word: Dictionary = said if said is Dictionary else {}
	if not PlayerProfile.is_id(word.get("id")) or not (word.get("name") is String) \
			or (word.has("layout") and not (word["layout"] is String)):
		_drop(peer, "gate", "an unreadable word of %d bytes" % data.size())
		return WHY_VERSION
	# A Guest that already has a level is checked against this machine's now: it never enters the
	# Roster when its house_ready would be refused anyway.
	var mine := _level_layout()
	if word.has("layout") and mine != "" and String(word["layout"]) != mine:
		_drop(peer, "layout", "another scene layout")
		return WHY_VERSION
	var pid := String(word["id"])
	if _plays(pid):
		_drop(peer, "already", pid.left(12))
		return WHY_ALREADY
	if 1 + _players.size() + _waiting.size() >= tuning.max_players:
		_drop(peer, "full", "%d players" % tuning.max_players)
		return WHY_FULL
	var hands: Variant = word.get("hands", {})
	if not (hands is Dictionary) or (hands as Dictionary).size() > Command.ARGS_MAX:
		_drop(peer, "gate", "unreadable Hands numbers")
		return WHY_VERSION
	_waiting[peer] = {"id": pid, "name": PlayerProfile.clean_name(word["name"]), "hands": _clamped_hands(hands),
			"in_level": word.has("layout") and mine != ""}
	return 0


## A player's Hands numbers as the Host keeps them: clamped to what the Upgrades can make them by this
## level's Hands (HandsTuning.clamped()), only the known names; {} with no Hands here.
func _clamped_hands(sent: Dictionary) -> Dictionary:
	var hands := parts.find(func(part: Part) -> bool: return part is Hands) as Hands if parts != null else null
	if hands == null:
		return {}
	return hands.own_tuning().clamped(sent).to_sent()


## This machine's own player's Hands numbers (HandsTuning.to_sent()), or {} with no player here.
func _own_hands() -> Dictionary:
	for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player != null and player.multiplayer == multiplayer and player.hands_tuning != null:
			return player.hands_tuning.to_sent()
	return {}


## Whether player id `pid` plays now or waits at the gate (the Host's own id included).
func _plays(pid: String) -> bool:
	if pid == profile.id or _players.values().has(pid):
		return true
	for w: Dictionary in _waiting.values():
		if String(w["id"]) == pid:
			return true
	return roster != null and roster.is_live(pid)


func _refusal_text(why: int) -> String:
	match why:
		WHY_FULL:
			return FULL % tuning.max_players
		WHY_ALREADY:
			return ALREADY
	return WRONG_BUILD


## A Guest: the Host's connection waits at the gate; say this machine's word.
func _on_authenticating(peer: int) -> void:
	if peer != 1:
		return
	var word := PackedByteArray()
	word.resize(4)
	word.encode_u32(0, protocol)
	var said := {"id": profile.id, "name": profile.name, "hands": _own_hands()}
	var layout := _level_layout()
	if layout != "":
		said["layout"] = layout
	word.append_array(var_to_bytes(said))
	_scene_multiplayer().send_auth(peer, word)


func _scene_multiplayer() -> SceneMultiplayer:
	return multiplayer as SceneMultiplayer


# --- Host ----------------------------------------------------------------------------------------

## A Guest passed the gate: the Roster takes it in (every Guest already in hears that), then it gets
## the link's state, its own entry in it, then every event about the link. The level's state waits for
## its house_ready (_house_ready()). A Guest whose word already named this machine's level layout
## (it joined from inside that level: the command line, the title's Join today) has said its house is
## ready at the gate: once this machine's level is settled (its Socks laid, house/09) it is taken in and
## gets the link's and the level's snapshot together, as one welcome.
func _on_peer_joined(peer: int) -> void:
	if not multiplayer.is_server() or _guests.has(peer) or not _waiting.has(peer):
		return
	var level := level_parts
	var in_level := bool(_waiting[peer].get("in_level", false)) and level != null
	while in_level and not level.is_settled():
		await level.settled
		if not _waiting.has(peer) or not is_inside_tree() or level_parts != level:
			return
	var who: Dictionary = _waiting[peer]
	_waiting.erase(peer)
	_players[peer] = String(who["id"])
	if roster != null:
		parts.apply(roster.joined(String(who["id"]), peer, String(who["name"]), who.get("hands", {})))
	_guests[peer] = true
	var snap := link_parts.snapshot() if link_parts != null else {}
	_linked.rpc_id(peer, snap)
	_note("%d joined (%s, colour %d, link snapshot %d bytes)" % [peer, String(who["id"]).left(12),
			roster.colour_index_of(peer) if roster != null else -1, var_to_bytes(snap).size()], false)
	if in_level:
		_take_into_house(peer, level)


## A Guest's level is bound and settled (the house handshake): its PROTOCOL and layout must be this
## machine's level's, else it is refused as another version. Then, once this machine's own level is
## settled (its Socks laid, house/09), it gets the level's whole state and from now on everything of
## it.
@rpc("any_peer", "call_remote", "reliable")
func _house_ready(protocol_said: Variant, layout: Variant) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not _guests.has(peer):
		_drop(peer, "not in the game", "")
		return
	if not (protocol_said is int) or not (layout is String) or String(layout).length() > 128:
		_drop(peer, "house", "an unreadable house_ready")
		return
	if _in_house.has(peer) or _house_waiting.has(peer) or level_parts == null:
		return
	if int(protocol_said) != PROTOCOL:
		_drop(peer, "protocol", "%d at house_ready, not %d" % [int(protocol_said), PROTOCOL])
		_house_refused.rpc_id(peer, WHY_VERSION)
		return
	var level := level_parts
	_house_waiting[peer] = true
	while not level.is_bound:
		await level.bound
		if not _house_waiting.has(peer) or level_parts != level or not is_inside_tree():
			return
	if String(layout) != layout_of(level):
		_house_waiting.erase(peer)
		_drop(peer, "layout", "another level layout at house_ready")
		_house_refused.rpc_id(peer, WHY_VERSION)
		return
	while not level.is_settled():
		await level.settled
		if not _house_waiting.has(peer) or level_parts != level or not is_inside_tree():
			return
	_house_waiting.erase(peer)
	_take_into_house(peer, level)


## The Host: Guest `peer`'s house is ready and this machine's `level` settled: it gets the level's whole
## state and from now on everything of it.
func _take_into_house(peer: int, level: Parts) -> void:
	if not _guests.has(peer) or _in_house.has(peer):
		return
	_in_house[peer] = true
	var snap := level.snapshot()
	_welcome.rpc_id(peer, snap)
	house_changed.emit(peer)
	_note("%d is in the level (snapshot %d bytes)" % [peer, var_to_bytes(snap).size()], false)


## A Guest's level went (a scene change): it is sent nothing of this machine's level until its next
## house_ready.
@rpc("any_peer", "call_remote", "reliable")
func _house_left() -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not _guests.has(peer):
		_drop(peer, "not in the game", "")
		return
	_house_waiting.erase(peer)
	if _in_house.erase(peer):
		house_changed.emit(peer)


## A Guest's Command: checked (see the top), then answered for the Guest who sent it (first to
## arrive wins).
@rpc("any_peer", "call_remote", "reliable")
func _command(wire: Variant) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not _guests.has(peer):
		_drop(peer, "not in the game", "")
		return
	var cmd := Command.from_wire(wire, peer)
	if cmd == null:
		_drop(peer, "shape", Command.shape_error(wire))
		return
	var part := parts.of(cmd.to) if parts != null else null
	if part == null:
		_drop(peer, "no part", String(cmd.to).left(60))
		return
	if not _in_house.has(peer) and not _is_link_part(cmd.to):
		_count(peer, "not_ready")
		return
	var verb: Dictionary = part.accepts().get(cmd.kind, {})
	if verb.is_empty():
		_drop(peer, "verb", "%s does not accept %s" % [cmd.to, String(cmd.kind).left(40)])
		return
	var why := Command.args_error(cmd.args, verb.get("args", {}))
	if why != "":
		_drop(peer, "args", "%s: %s" % [cmd.kind, why])
		return
	var rate := int(verb.get("rate", RATE))
	if not _rate_ok(peer, cmd.kind, rate):
		_drop(peer, "rate", "more than %d %s a second" % [rate, cmd.kind])
		return
	parts.apply(parts.answer(cmd))


## The Host's answer goes to every Guest; a refusal changes nothing, so it goes to the asker alone
## (I13, F07), and to nobody when the asker is the Host.
## A Guest whose house is not ready yet hears only answers about the link's parts.
func _on_applied(ev: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var link_only := _about_link_only(ev)
	if not ev.get("ok", false):
		var asker := int(ev.get("by", 0))
		if _guests.has(asker) and (link_only or _in_house.has(asker)):
			_event.rpc_id(asker, ev)
		return
	for peer: int in _guests:
		if link_only or _in_house.has(peer):
			_event.rpc_id(peer, ev)


## Whether answer `ev` changes (or names) only the link's parts.
func _about_link_only(ev: Dictionary) -> bool:
	var changes: Variant = ev.get("changes")
	if changes is Dictionary and not (changes as Dictionary).is_empty():
		for id: Variant in changes:
			if not _is_link_part(StringName(id)):
				return false
		return true
	return _is_link_part(StringName(ev.get("to", &"")))


## Whether `id` names one of the link's parts (there is a link and it is not the level's).
func _is_link_part(id: StringName) -> bool:
	if link_parts == null:
		return false
	if level_parts != null:
		return level_parts.is_link_part(id)
	return link_parts.of(id) != null


## A Guest went: each part lets go of what it held (Parts.left: its Hands drop where it stood, the
## Roster keeps where that was), then the peer is forgotten.
func _on_peer_left(peer: int) -> void:
	_rates.erase(peer)
	_said.erase(peer)
	_waiting.erase(peer)
	_in_house.erase(peer)
	_house_waiting.erase(peer)
	if _guests.erase(peer):
		parts.left(peer)
		_note("%d left" % peer, false)
	_players.erase(peer)


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
func _count(peer: int, reason: String) -> Dictionary:
	stats["bad_packets"] = int(stats["bad_packets"]) + 1
	var counts: Dictionary = dropped.get_or_add(peer, {})
	counts[reason] = int(counts.get(reason, 0)) + 1
	return counts


## A packet from `peer` was dropped: counted under `reason`, printed at most once a second per
## player and reason.
func _drop(peer: int, reason: String, detail: String) -> void:
	var counts := _count(peer, reason)
	var said: Dictionary = _said.get_or_add(peer, {})
	var now := Time.get_ticks_msec()
	if now - int(said.get(reason, -1000)) < 1000:
		return
	said[reason] = now
	_note("dropped a packet from peer %d: %s%s; %d so far" % [peer, reason,
			" (%s)" % detail if detail != "" else "", int(counts[reason])], true)


# --- Guest ---------------------------------------------------------------------------------------

func _send_up(cmd: Command) -> void:
	_command.rpc_id(1, cmd.to_wire())


## The Host's answer to anyone's Command.
@rpc("authority", "call_remote", "reliable")
func _event(ev: Dictionary) -> void:
	parts.apply(ev)


## The link's whole state (the Roster), once, after the gate admitted this Guest: it is in the game.
## Its level, once ready, says so (house_ready).
@rpc("authority", "call_remote", "reliable")
func _linked(snap: Dictionary) -> void:
	_give_up.stop()
	_in_game = true
	if link_parts != null:
		link_parts.load_snapshot(snap)
	linked.emit()
	_house_step()


## The level's whole state, once, after the Host handled this Guest's house_ready.
@rpc("authority", "call_remote", "reliable")
func _welcome(snap: Dictionary) -> void:
	_joining = ""
	_give_up.stop()
	if parts != null:
		parts.load_snapshot(snap)
	welcomed.emit()


## The Host refused this Guest's house (another PROTOCOL or level layout).
@rpc("authority", "call_remote", "reliable")
func _house_refused(why: int) -> void:
	_end.call_deferred(_refusal_text(why))


## A Guest in the game: once its level is bound and settled, it tells the Host (once per level).
func _house_step() -> void:
	var level := level_parts
	if not _in_game or level == null or _house_asked == level or multiplayer.is_server():
		return
	_house_asked = level
	while not level.is_bound:
		await level.bound
		if _house_asked != level or not is_inside_tree():
			return
	while not level.is_settled():
		await level.settled
		if _house_asked != level or not is_inside_tree():
			return
	if _peer == null or level_parts != level:
		return
	_house_ready.rpc_id(1, protocol, layout_of(level))


func _on_host_gone() -> void:
	_end(HOST_QUIT)


## No welcome in join_timeout, or the transport could not reach the Host (ENet's own give-up).
func _on_unreachable() -> void:
	if _joining != "":
		_end(UNREACHABLE % _joining)


## Once per session: alone again, and why.
func _end(text: String) -> void:
	if _peer == null:
		return
	close()
	_note("ended: %s" % text, false)
	ended.emit(text)


## One line about the session, into the game's log (area "net").
func _note(text: String, warning: bool) -> void:
	if warning:
		Log.warn("net", text)
	else:
		Log.info("net", text)


func _exit_tree() -> void:
	_leaving = true
	close()
	_leaving = false
