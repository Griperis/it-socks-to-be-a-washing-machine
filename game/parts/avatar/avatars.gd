## The players' avatars: one Avatar per player under the spawn path (a `Players` Node3D at the
## origin), named by the player's peer id. Godot's spawner makes each one on every machine, a late
## Guest included; the Host decides who has one. Put it at the same path on every machine, beside
## Players. The Host calls host() once the Session listens; a Guest needs no call. Alone, nothing
## happens.
##
## With a `roster`, the Host spawns by it: an avatar for each player in the Session, standing where
## the Roster says (the spawn data carries the place, so it never shows at the origin first), and a
## leaver's goes when the Roster lets them go. Without one, by the peers the gate admits.
class_name Avatars
extends MultiplayerSpawner

## The avatar scene: an Avatar root with its Sync.
@export var avatar_scene: PackedScene
## The local player's body, which this machine's own avatar copies (and hides behind).
@export var local_body: Node3D
## Who plays; empty spawns by the peers instead.
@export var roster: Roster

## Links the wiring check lets stay empty: the code below has a fallback.
const WIRING_OPTIONAL := ["roster"]


func _ready() -> void:
	spawn_function = _make
	multiplayer.server_disconnected.connect(clear)


## The Host: an avatar for itself now and for every player who comes in; a leaver's goes.
func host() -> void:
	if roster != null:
		roster.changed.connect(_follow_roster)
		_follow_roster()
		return
	_add(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_add)
	multiplayer.peer_disconnected.connect(_remove)


## The avatar of player `id` (a peer id) on this machine, or null.
func of(id: int) -> Avatar:
	var players := get_node_or_null(spawn_path)
	return players.get_node_or_null(str(id)) as Avatar if players != null else null


## Every avatar goes, and the Host stops adding them: after the session closes or ends.
func clear() -> void:
	for pair: Array in [[multiplayer.peer_connected, _add], [multiplayer.peer_disconnected, _remove]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])
	if roster != null and roster.changed.is_connected(_follow_roster):
		roster.changed.disconnect(_follow_roster)
	var players := get_node_or_null(spawn_path)
	if players == null:
		return
	for child in players.get_children():
		child.queue_free()


## The Host: an avatar for each peer in the Roster now, at its entry's place; none for anyone else.
func _follow_roster() -> void:
	var live := roster.peers()
	for peer in live:
		if of(peer) == null:
			var e := roster.entry_of(peer)
			spawn({"peer": peer, "at": e.get("at", Vector3.ZERO), "yaw": float(e.get("yaw", 0.0))})
	var players := get_node_or_null(spawn_path)
	if players == null:
		return
	for child in players.get_children():
		if not child.is_queued_for_deletion() and not live.has(String(child.name).to_int()):
			child.queue_free()


func _add(id: int) -> void:
	if of(id) == null:
		spawn({"peer": id})


func _remove(id: int) -> void:
	var avatar := of(id)
	if avatar != null:
		avatar.queue_free()


## Runs on every machine with the Host's data: {"peer": a player's peer id, and optionally "at": a
## finite Vector3, "yaw": a finite float}. Anything else makes nothing.
func _make(data: Variant) -> Node:
	var d: Dictionary = data if data is Dictionary else {}
	var peer: Variant = d.get("peer")
	var at: Variant = d.get("at", Vector3.ZERO)
	var yaw: Variant = d.get("yaw", 0.0)
	if not (peer is int) or int(peer) < 1 or not (at is Vector3) or not (at as Vector3).is_finite() \
			or not (yaw is float) or not is_finite(yaw):
		Log.error("avatars", "refused spawn data %s" % str(data).left(40))
		return null
	var avatar := avatar_scene.instantiate() as Avatar
	avatar.name = str(peer)
	avatar.pose_position = at
	avatar.pose_yaw = yaw
	avatar.roster = roster
	if int(peer) == multiplayer.get_unique_id():
		avatar.follow = local_body
		avatar.visible = false
	return avatar
