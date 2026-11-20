## The co-op link of one machine: the only node with RPCs (Godot finds an RPC by node path, so it
## sits at the same path on every machine). The Host opens an ENet listen server; a Guest joins it
## by address. Commands go up, the Host's answers come down, and a Guest on the right PROTOCOL gets
## the whole state first. Playing alone needs none of it: with no peer, Parts is a Host of one.
##
## The gate: Godot starts replicating (spawns, synchronizers) and accepting RPCs the moment a peer is
## admitted, so nobody is admitted before the PROTOCOL check. SceneMultiplayer's auth_callback holds
## each new connection: the Guest sends its PROTOCOL (send_auth), the Host answers ACCEPTED and
## admits it (complete_auth) or answers REFUSED and never admits it, so a Guest on another build
## receives no spawn, no synchronized value and no RPC. Once both sides complete, peer_connected
## fires and the Host sends the snapshot.
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
## synchronized property, a spawnable scene or the shape of a Command, an event or a snapshot
## changes. The gate's own bytes (below) never change, so any two builds can tell they differ.
const PROTOCOL := 7
## The gate's answers, one byte each; a Guest's word is its PROTOCOL as 4 bytes (encode_u32).
const ACCEPTED := 1
const REFUSED := 0
const PORT := 24565
## The most Commands of one verb one Guest may send in a second, when the part declares no "rate".
const RATE := 10
## Placeholder wording: the designer's to set (designer-grilling).
const WRONG_BUILD := "The Host is playing another version"
const HOST_QUIT := "The Host ended the session"

## The level's Parts.
@export var parts: Parts
## The port to open or join; 0 opens on a free one (tests do; read it back after host()).
@export var port := PORT
## How many Guests may join (the Host is one player more).
@export_range(1, 15) var max_guests := 3  # placeholder: the designer's answer to how many play together

var stats := {"bad_packets": 0}
## What was dropped, per player and reason: {peer: {"args": 2, "rate": 5}}. Reasons: "protocol"
## (refused at the gate), "not in the game", "shape", "no part", "verb", "args", "rate".
var dropped: Dictionary[int, Dictionary] = {}

var _peer: ENetMultiplayerPeer = null
## Guests the gate admitted, who got the snapshot; only they receive events.
var _guests: Dictionary[int, bool] = {}
## Per Guest and verb: [the start of this second in ms, Commands in it].
var _rates: Dictionary[int, Dictionary] = {}
## Per Guest and reason: when a drop was last printed, in ms.
var _said: Dictionary[int, Dictionary] = {}


## Opens the game for Guests. Call it once the level and its Parts are ready.
func host() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_guests)
	if err != OK:
		push_error("session: cannot listen on port %d (%s)" % [port, error_string(err)])
		return err
	_peer = peer
	port = peer.host.get_local_port()
	_scene_multiplayer().auth_callback = _gate
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_joined)
	multiplayer.peer_disconnected.connect(_on_peer_left)
	parts.applied.connect(_on_applied)
	return OK


## An address as a player types it, split into [host, port]: "host", "host:port", an IPv6 address
## bare ("::1", "fe80::2") or in brackets with a port ("[::1]:24565"). Without a port, `fallback`.
static func split_address(address: String, fallback: int) -> Array:
	var text := address.strip_edges()
	if text.begins_with("["):
		var close := text.find("]")
		if close > 0:
			var rest := text.substr(close + 1)
			return [text.substr(1, close - 1), int(rest.trim_prefix(":")) if rest.begins_with(":") and rest.length() > 1 else fallback]
	# One colon is host:port; more than one is a bare IPv6 address, which has no port.
	if text.count(":") == 1:
		return [text.get_slice(":", 0), int(text.get_slice(":", 1))]
	return [text, fallback]


## Joins the Host at "ip", "ip:port" or "[ipv6]:port". From now on this machine's Commands go up
## to the Host.
func join(address: String) -> Error:
	var target := split_address(address, port)
	var ip := String(target[0])
	var at := int(target[1])
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, at)
	if err != OK:
		return err
	_peer = peer
	_scene_multiplayer().auth_callback = _gate
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_authenticating.connect(_on_authenticating)
	multiplayer.server_disconnected.connect(_on_host_gone)
	parts.relay = _send_up
	return OK


## This player's id: 1 on the Host and when playing alone, the peer id on a Guest.
func me() -> int:
	return multiplayer.get_unique_id()


func is_online() -> bool:
	return _peer != null


## Leaves: a Host's Guests hear the Host quit; a Guest's machine is a Host of one again.
func close() -> void:
	if _peer == null:
		return
	_peer.close()
	# Also when something wraps our peer (a test's delay): the machine is alone again either way.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_scene_multiplayer().auth_callback = Callable()
	for pair: Array in [[multiplayer.peer_connected, _on_peer_joined], [multiplayer.peer_disconnected, _on_peer_left],
			[multiplayer.peer_authenticating, _on_authenticating], [multiplayer.server_disconnected, _on_host_gone],
			[parts.applied, _on_applied]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])
	parts.relay = Callable()
	_peer = null
	_guests.clear()
	_rates.clear()
	_said.clear()


# --- The gate (both sides) ----------------------------------------------------------------------

## What the other side said at the gate. The Host reads a Guest's PROTOCOL and admits it or refuses
## it; a Guest reads the Host's answer. Until both sides call complete_auth(), nothing replicates
## and no RPC passes; a peer never admitted is dropped after SceneMultiplayer.auth_timeout.
func _gate(peer: int, data: PackedByteArray) -> void:
	var sm := _scene_multiplayer()
	if multiplayer.is_server():
		var theirs := int(data.decode_u32(0)) if data.size() == 4 else -1
		if theirs != PROTOCOL:
			_drop(peer, "protocol", "%s, not %d" % [str(theirs) if theirs >= 0 else "%d bytes" % data.size(), PROTOCOL])
			sm.send_auth(peer, PackedByteArray([REFUSED]))
			return
		sm.send_auth(peer, PackedByteArray([ACCEPTED]))
		sm.complete_auth(peer)
	elif peer == 1:
		if data.size() == 1 and data[0] == ACCEPTED:
			sm.complete_auth(peer)
		else:
			_end.call_deferred(WRONG_BUILD)


## A Guest: the Host's connection waits at the gate; say this build's PROTOCOL.
func _on_authenticating(peer: int) -> void:
	if peer != 1:
		return
	var word := PackedByteArray()
	word.resize(4)
	word.encode_u32(0, PROTOCOL)
	_scene_multiplayer().send_auth(peer, word)


func _scene_multiplayer() -> SceneMultiplayer:
	return multiplayer as SceneMultiplayer


# --- Host ----------------------------------------------------------------------------------------

## A Guest passed the gate: it gets the whole state, then every event.
func _on_peer_joined(peer: int) -> void:
	if not multiplayer.is_server() or _guests.has(peer):
		return
	_guests[peer] = true
	_welcome.rpc_id(peer, parts.snapshot())


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


func _on_peer_left(peer: int) -> void:
	_rates.erase(peer)
	_said.erase(peer)
	if _guests.erase(peer):
		parts.left(peer)


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
	parts.load_snapshot(snap)
	welcomed.emit()


func _on_host_gone() -> void:
	_end(HOST_QUIT)


func _end(text: String) -> void:
	close()
	_note("ended: %s" % text, false)
	ended.emit(text)


## One line about the session: into the game's log when it has one (the autoload `Log` of the
## log template, asked for by name so this file needs no log to load), else printed.
func _note(text: String, warning: bool) -> void:
	var game_log := get_node_or_null(^"/root/Log")
	if game_log != null and game_log.has_method(&"write"):
		game_log.call(&"warn" if warning else &"info", "net", text)
	else:
		print("session: ", text)


func _exit_tree() -> void:
	close()
