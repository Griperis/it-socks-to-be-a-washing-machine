## The co-op link of one machine: the only node with RPCs (Godot finds an RPC by node path, so it
## sits at the same path on every machine). The Host opens for Guests and a Guest joins it through the
## `transport` (NetTransport: ENet by address now, Steam at M4); this file names no transport's peer
## type and reads no address. Commands go up, the Host's answers come down, and a Guest the gate
## admits gets the whole state first. Playing alone needs none of it: with no peer, Parts is a Host
## of one.
##
## The gate: Godot starts replicating (spawns, synchronizers) and accepting RPCs the moment a peer is
## admitted, so nobody is admitted before the gate's checks. SceneMultiplayer's auth_callback holds
## each new connection: the Guest sends its word (send_auth): its PROTOCOL as 4 bytes, then the scene
## layout hash, its player id (the profile's, never the peer id) and its name. The Host answers
## ACCEPTED and admits it (complete_auth), or REFUSED and a reason byte and never admits it, so a
## refused Guest receives no spawn, no synchronized value and no RPC. A Guest is refused when its
## PROTOCOL or layout differs ("Another version of the game"), when the game is full, or when its
## player id already plays ("You are already in this game"). Once both sides complete,
## peer_connected fires: the Host writes the player into the Roster (one answer) and sends the
## snapshot. From M4 the word carries Steam's auth ticket too (Q2458); no token before (Q2449).
##
## Guarding: every any_peer RPC checks its packet before anything reads it. A Guest's Command, in
## this order: its wire shape (Command.shape_error()), its target is a part Parts bound (an id under
## the level: `..` or an absolute path names none), the part accepts() the verb, the args match the
## verb's declared args exactly, and the player is within the verb's rate.
## A bad packet is dropped and counted (`dropped`, per player and reason; stats["bad_packets"] in
## all), printed at most once a second per player and reason, and never crashes or kicks anyone.
## The Host's own Commands skip these checks; every Command still goes through decide().
class_name Session
extends Node

## A Guest has the Host's snapshot and is in the game.
signal welcomed
## The session is over for this machine; `text` says why.
signal ended(text: String)

## The wire's version: a Guest on another one is refused at the gate. Bump it whenever an RPC, a
## synchronized property, a spawnable scene or the shape of a Command, an event, a snapshot or the
## gate's word changes. The word's first 4 bytes (the PROTOCOL) never move, so any two builds can
## tell they differ.
const PROTOCOL := 11  # 11: coop/07, a Mess answer carries only the records it changed (rows)
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

## The level's Parts.
@export var parts: Parts
## Who plays: written here on the Host when a player is admitted, and by Parts.left() when one goes.
## Optional: without one the Session still gates and relays.
@export var roster: Roster
@export var tuning: CoopTuning
## The port to open; 0 opens on a free one (tests do; read it back after host()).
@export var port := PORT

## Links the wiring check lets stay empty: the code below has a fallback.
const WIRING_OPTIONAL := ["roster", "tuning"]

## How this machine reaches the others.
var transport: NetTransport = EnetTransport.new()
## Who this machine's player is; host() or join() makes one in memory when none was given.
var profile: PlayerProfile = null
## What this machine says at the gate as its PROTOCOL (a test stands in for another build with it).
var protocol := PROTOCOL
var stats := {"bad_packets": 0}
## What was dropped, per player and reason: {peer: {"args": 2, "rate": 5}}. Reasons: "protocol",
## "gate" (an unreadable word), "layout", "already", "full" (refused at the gate), "not in the
## game", "shape", "no part", "verb", "args", "rate".
var dropped: Dictionary[int, Dictionary] = {}

var _peer: MultiplayerPeer = null
## The hash of the Part paths this scene declares: the contract both machines must share.
var _layout := ""
## The Host: who passed the gate and is not in yet: {peer: {"id": player id, "name": String}}.
var _waiting: Dictionary[int, Dictionary] = {}
## The Host: the player id on each admitted peer (a live field: never saved, never a key).
var _players: Dictionary[int, String] = {}
## Guests the gate admitted, who got the snapshot; only they receive events.
var _guests: Dictionary[int, bool] = {}
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
	parts.applied.connect(_on_applied)
	if roster != null:
		parts.apply(roster.joined(profile.id, Roster.HOST, profile.name))
	_note("hosting on %s" % transport.describe(), false)
	return OK


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
	parts.relay = _send_up
	_joining = where
	_give_up.start(tuning.join_timeout)
	return OK


## This player's id: 1 on the Host and when playing alone, the peer id on a Guest.
func me() -> int:
	return multiplayer.get_unique_id()


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
			[multiplayer.connection_failed, _on_unreachable], [parts.applied, _on_applied]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])
	parts.relay = Callable()
	_peer = null
	transport.peer = null
	_joining = ""
	_give_up.stop()
	_waiting.clear()
	_players.clear()
	_guests.clear()
	_rates.clear()
	_said.clear()
	if roster != null and not _leaving and not roster.players.is_empty() and roster.parts == parts:
		parts.apply(roster.cleared())


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
	_layout = layout_of(parts)


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
	if not PlayerProfile.is_id(word.get("id")) or not (word.get("layout") is String) or not (word.get("name") is String):
		_drop(peer, "gate", "an unreadable word of %d bytes" % data.size())
		return WHY_VERSION
	if String(word["layout"]) != _layout:
		_drop(peer, "layout", "another scene layout")
		return WHY_VERSION
	var pid := String(word["id"])
	if _plays(pid):
		_drop(peer, "already", pid.left(12))
		return WHY_ALREADY
	if 1 + _players.size() + _waiting.size() >= tuning.max_players:
		_drop(peer, "full", "%d players" % tuning.max_players)
		return WHY_FULL
	_waiting[peer] = {"id": pid, "name": PlayerProfile.clean_name(word["name"])}
	return 0


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
	word.append_array(var_to_bytes({"layout": _layout, "id": profile.id, "name": profile.name}))
	_scene_multiplayer().send_auth(peer, word)


func _scene_multiplayer() -> SceneMultiplayer:
	return multiplayer as SceneMultiplayer


# --- Host ----------------------------------------------------------------------------------------

## A Guest passed the gate: the Roster takes it in (every Guest already in hears that), then it gets
## the whole state, its own entry in it, then every event.
func _on_peer_joined(peer: int) -> void:
	if not multiplayer.is_server() or _guests.has(peer) or not _waiting.has(peer):
		return
	var who: Dictionary = _waiting[peer]
	_waiting.erase(peer)
	_players[peer] = String(who["id"])
	if roster != null:
		parts.apply(roster.joined(String(who["id"]), peer, String(who["name"])))
	_guests[peer] = true
	var snap := parts.snapshot()
	_welcome.rpc_id(peer, snap)
	_note("%d joined (%s, colour %d, snapshot %d bytes)" % [peer, String(who["id"]).left(12),
			roster.colour_index_of(peer) if roster != null else -1, var_to_bytes(snap).size()], false)


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
	var part := parts.of(cmd.to)
	if part == null:
		_drop(peer, "no part", String(cmd.to).left(60))
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


func _on_applied(ev: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	for peer: int in _guests:
		_event.rpc_id(peer, ev)


## A Guest went: each part lets go of what it held (Parts.left: its Hands drop where it stood, the
## Roster keeps where that was), then the peer is forgotten.
func _on_peer_left(peer: int) -> void:
	_rates.erase(peer)
	_said.erase(peer)
	_waiting.erase(peer)
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


## A packet from `peer` was dropped: counted under `reason`, printed at most once a second per
## player and reason.
func _drop(peer: int, reason: String, detail: String) -> void:
	stats["bad_packets"] = int(stats["bad_packets"]) + 1
	var counts: Dictionary = dropped.get_or_add(peer, {})
	counts[reason] = int(counts.get(reason, 0)) + 1
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


## The whole state, once, after the gate admitted this Guest.
@rpc("authority", "call_remote", "reliable")
func _welcome(snap: Dictionary) -> void:
	_joining = ""
	_give_up.stop()
	parts.load_snapshot(snap)
	welcomed.emit()


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
