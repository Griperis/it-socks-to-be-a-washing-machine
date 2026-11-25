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
## This file holds the public calls, every RPC (each a thin line into a helper) and the session's
## life. The work is in plain helpers beside it, one concern each (docs/architecture/coop.md "Adding a
## verb"): SessionPeer (open, join, close), SessionGate (the gate, a Guest coming into the game and
## going), SessionHouse (the house handshake), SessionGuard (a Guest's Command checked, drops counted),
## SessionRelay (answers down, Commands up).
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
const PROTOCOL := 21  # 21: core/76, the run's Stages and the zoo's StagesSwitch verb; 20: core/43, the Pings part and its ping verb; 19: core/65, LobbyState.worlds and its worlds verb (the Host's World list); 17: core/41, an avatar's Back and riding pose (pose_riding, pose_ride_offset), its jump count (pose_jumps), a child Back in the avatar scene; 14: core/62, the game link: the layout leaves the gate's word for house_ready, the link's snapshot; 15: core/63, LobbyState in the link; 16: core/42, the Hands' hand_off verb and its answer; 18: core/68, house_ready carries the Hands numbers, the Guests in the house (_houses), the avatar's Gate
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
## Guests the gate admitted, who got the link snapshot; only they receive events.
var _guests: Dictionary[int, bool] = {}
## A Guest: where it is joining until the welcome.
var _joining := ""
## A Guest: gives the join up after join_timeout with no welcome.
var _give_up := Timer.new()
## Set while this node leaves the tree: closing then writes nothing.
var _leaving := false
## The helpers (see the top); each works on this Session's fields.
var _gate := SessionGate.new(self)
var _house := SessionHouse.new(self)
var _guard := SessionGuard.new(self)
var _relay := SessionRelay.new(self)
var _link := SessionPeer.new(self)


func _ready() -> void:
	if tuning == null:
		tuning = CoopTuning.new()
	_give_up.name = "GiveUp"
	_give_up.one_shot = true
	_give_up.timeout.connect(_on_unreachable)
	add_child(_give_up)


## Opens the game for Guests. Call it once the level and its Parts are ready.
func host() -> Error:
	return _link.host()


## Playing alone (a Host of one, core/58): this machine's player is in its own Roster under its
## profile's id, as when it hosts, so its Hands and Coins are kept by its player id, never its peer
## number, and a save keeps where it stands. Nothing while a session is open.
func enter_alone() -> void:
	if is_online() or roster == null:
		return
	if profile == null:
		profile = PlayerProfile.fresh()
	parts.apply(roster.joined(profile.id, Roster.HOST, profile.name, _gate.clamped_hands(_gate.own_hands())))


## Joins the Host at `where` (opaque to this file: "ip" or "ip:port" for ENet). From now on this
## machine's Commands go up to the Host. With no welcome in CoopTuning.join_timeout, or when the
## transport gives up first, it ends with "Could not reach <where>".
func join(where: String) -> Error:
	return _link.join(where)


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
	_link.close()


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
	_relay.listen(parts)
	if not multiplayer.is_server():
		p.relay = _relay.send_up
	_house.level_attached()


## A level goes (LevelRuntime, as it leaves the tree): the link's Parts are in use again. The Host
## stops sending any Guest the level; a Guest tells the Host its house is gone.
func detach_level(p: Parts) -> void:
	if p == null or p != level_parts:
		return
	level_parts = null
	if _peer == null:
		return
	p.relay = Callable()
	_relay.listen(parts)
	_house.level_detached()


## Whether this machine may send `peer` anything of its level: on the Host, once that Guest's
## house_ready was handled; on a Guest (its own avatar), to the Host always and to another Guest once
## the Host said that one is in its house (core/68). True alone. LevelRuntime's visibility filter on
## every synchronizer of the level asks it.
func sees_house(peer: int) -> bool:
	return _peer == null or peer == Parts.HOST or _house.sees(peer)


## Whether Guest `peer`'s house_ready was handled (the Host).
func in_house(peer: int) -> bool:
	return _house.has(peer)


## The hash of the sorted Part ids `p` binds: what both machines' scenes must declare alike.
static func layout_of(p: Parts) -> String:
	var ids := PackedStringArray()
	for k in p.ids():
		ids.append(String(k))
	ids.sort()
	return "\n".join(ids).sha256_text()


## The layout hash of this machine's level, or "" with none bound.
func _level_layout() -> String:
	return layout_of(level_parts) if level_parts != null and level_parts.is_bound else ""


func _scene_multiplayer() -> SceneMultiplayer:
	return multiplayer as SceneMultiplayer


# --- The RPCs: one line each into a helper -------------------------------------------------------

## A Guest's level is bound and settled (SessionHouse.ready_said).
@rpc("any_peer", "call_remote", "reliable")
func _house_ready(protocol_said: Variant, layout: Variant, hands: Variant) -> void:
	_house.ready_said(multiplayer.get_remote_sender_id(), protocol_said, layout, hands)


## A Guest's level went (a scene change): it is sent nothing of this machine's level until its next
## house_ready.
@rpc("any_peer", "call_remote", "reliable")
func _house_left() -> void:
	_house.left(multiplayer.get_remote_sender_id())


## A Guest's Command: checked (SessionGuard), then answered for the Guest who sent it.
@rpc("any_peer", "call_remote", "reliable")
func _command(wire: Variant) -> void:
	_guard.command(multiplayer.get_remote_sender_id(), wire)


## The Host's answer to anyone's Command.
@rpc("authority", "call_remote", "reliable")
func _event(ev: Dictionary) -> void:
	parts.apply(ev)


## The link's whole state (the Roster), once, after the gate admitted this Guest: it is in the game.
## Its level, once ready, says so (house_ready).
@rpc("authority", "call_remote", "reliable")
func _linked(snap: Dictionary) -> void:
	_give_up.stop()
	_house.in_game = true
	if link_parts != null:
		link_parts.load_snapshot(snap)
	linked.emit()
	_house.step()


## The level's whole state, once, after the Host handled this Guest's house_ready.
@rpc("authority", "call_remote", "reliable")
func _welcome(snap: Dictionary) -> void:
	_joining = ""
	_give_up.stop()
	if parts != null:
		parts.load_snapshot(snap)
	welcomed.emit()


## The Guests in the Host's house now (SessionHouse.tell).
@rpc("authority", "call_remote", "reliable")
func _houses(inside: Variant) -> void:
	_house.houses_said(inside)


## The Host refused this Guest's house (another PROTOCOL or level layout).
@rpc("authority", "call_remote", "reliable")
func _house_refused(why: int) -> void:
	_end.call_deferred(_gate.refusal_text(why))


# --- The session's life --------------------------------------------------------------------------

## A Guest passed the gate (SessionGate.joined).
func _on_peer_joined(peer: int) -> void:
	_gate.joined(peer)


## A Guest went (SessionGate.left).
func _on_peer_left(peer: int) -> void:
	_gate.left(peer)


## A Guest: the Host's connection waits at the gate; say this machine's word.
func _on_authenticating(peer: int) -> void:
	_gate.say_word(peer)


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
	leave()


## Closes as the node leaving the tree does: nothing is written on the way (its link goes too).
func leave() -> void:
	_leaving = true
	close()
	_leaving = false
