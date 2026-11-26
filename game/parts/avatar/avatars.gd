## The players' avatars: one Avatar per player under the spawn path (a `Players` Node3D at the
## origin), named by the player's peer id. Godot's spawner makes each one on every machine, a late
## Guest included; the Host decides who has one. Put it at the same path on every machine, beside
## Players. The Host calls host() once the Session listens; a Guest needs no call. Alone, nothing
## happens.
##
## With a `roster`, the Host spawns by it: an avatar for each player in the Session, standing where
## the Roster says (the spawn data carries the place, so it never shows at the origin first), and a
## leaver's goes when the Roster lets them go. Without one, by the peers the gate admits. With a
## `session`, a Guest's avatar is spawned only once that Guest's house is ready (Session.sees_house(),
## core/62): Godot sends a spawn to every peer, and a Guest still loading its level has nowhere to put it.
##
## The local player's own body (coop/06) wears this machine's Roster colour; alone, or before the
## Roster names this machine, the first Player colour (the Host's), as the old game's did.
class_name Avatars
extends MultiplayerSpawner

## The avatar scene: an Avatar root with its Sync.
@export var avatar_scene: PackedScene
## The local player's body, which this machine's own avatar copies (and hides behind).
@export var local_body: Node3D
## Who plays; empty spawns by the peers instead. The game link's Roster (LevelRuntime sets it as it
## enters the tree: it lives outside the level).
var roster: Roster
## The game link's Session, set with the roster: whose house is ready.
var session: Session


func _ready() -> void:
	spawn_function = _make
	multiplayer.server_disconnected.connect(clear)
	if roster != null:
		roster.changed.connect(_tint_own_body)
	_tint_own_body.call_deferred()


## The level leaves while the link stays (a scene change): the Roster and the connection stop calling
## into it.
func _exit_tree() -> void:
	clear()
	if multiplayer != null and multiplayer.server_disconnected.is_connected(clear):
		multiplayer.server_disconnected.disconnect(clear)
	if roster != null and is_instance_valid(roster) and roster.changed.is_connected(_tint_own_body):
		roster.changed.disconnect(_tint_own_body)


## The own body takes this machine's Player colour; it and the mirror body wear this machine's own
## Roster entry's look (core/141; the own body shows only its Socks and Trail, Q888).
func _tint_own_body() -> void:
	var player := local_body as Player
	if player == null or roster == null or player.own_body() == null:
		return
	var me := multiplayer.get_unique_id()
	var known := not roster.entry_of(me).is_empty()
	player.own_body().colour = roster.colour_of(me) if known else roster.tuning.colour(0)
	player.own_body().look = roster.look_of(me)
	if player.mirror_body() != null:
		player.mirror_body().look = roster.look_of(me)


## The Host: an avatar for itself now and for every player who comes in; a leaver's goes.
func host() -> void:
	if roster != null:
		if not roster.changed.is_connected(_follow_roster):
			roster.changed.connect(_follow_roster)
		if session != null and not session.house_changed.is_connected(_on_house_changed):
			session.house_changed.connect(_on_house_changed)
		_follow_roster()
		return
	_add(multiplayer.get_unique_id())
	if not multiplayer.peer_connected.is_connected(_add):
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
	if roster != null and is_instance_valid(roster) and roster.changed.is_connected(_follow_roster):
		roster.changed.disconnect(_follow_roster)
	if session != null and is_instance_valid(session) and session.house_changed.is_connected(_on_house_changed):
		session.house_changed.disconnect(_on_house_changed)
	var players := get_node_or_null(spawn_path)
	if players == null:
		return
	for child in players.get_children():
		child.queue_free()


## The Host: an avatar for each peer in the Roster now, at its entry's place; none for anyone else.
func _follow_roster() -> void:
	var live := roster.peers()
	if session != null:
		live = PackedInt32Array(Array(live).filter(func(p: int) -> bool: return session.sees_house(p)))
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


## Guest `peer` came in or left: its avatar comes or goes, and every avatar's Gate (core/68) shows or
## hides it now, so the spawns go before the Session tells the other Guests (who then send it their
## own poses: it has the avatars by then).
func _on_house_changed(peer: int) -> void:
	_follow_roster()
	var players := get_node_or_null(spawn_path)
	if players == null:
		return
	for child in players.get_children():
		var gate := child.get_node_or_null(^"Gate") as MultiplayerSynchronizer
		if gate != null and gate.is_inside_tree() and gate.is_multiplayer_authority():
			gate.update_visibility(peer)


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
