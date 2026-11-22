## The players' avatars: one Avatar per player under the spawn path (a `Players` Node3D at the
## origin), named by the player's id. Godot's spawner makes each one on every machine, a late Guest
## included; the Host decides who has one. Put it at the same path on every machine, beside Players.
## The Host calls host() once the Session listens; a Guest needs no call. Alone, nothing happens.
class_name Avatars
extends MultiplayerSpawner

## The avatar scene: an Avatar root with its Sync.
@export var avatar_scene: PackedScene
## The local player's body, which this machine's own avatar copies (and hides behind).
@export var local_body: Node3D


func _ready() -> void:
	spawn_function = _make
	multiplayer.server_disconnected.connect(clear)


## The Host: an avatar for itself now and for every player the gate admits; a leaver's goes.
func host() -> void:
	_add(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_add)
	multiplayer.peer_disconnected.connect(_remove)


## The avatar of player `id` on this machine, or null.
func of(id: int) -> Avatar:
	var players := get_node_or_null(spawn_path)
	return players.get_node_or_null(str(id)) as Avatar if players != null else null


## Every avatar goes, and the Host stops adding them: after the session closes or ends.
func clear() -> void:
	for pair: Array in [[multiplayer.peer_connected, _add], [multiplayer.peer_disconnected, _remove]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])
	var players := get_node_or_null(spawn_path)
	if players == null:
		return
	for child in players.get_children():
		child.queue_free()


func _add(id: int) -> void:
	if of(id) == null:
		spawn(id)


func _remove(id: int) -> void:
	var avatar := of(id)
	if avatar != null:
		avatar.queue_free()


## Runs on every machine with the Host's data: a player id. Anything else makes nothing.
func _make(data: Variant) -> Node:
	if not (data is int) or int(data) < 1:
		Log.error("avatars", "refused spawn data %s" % str(data).left(40))
		return null
	var avatar := avatar_scene.instantiate() as Avatar
	avatar.name = str(data)
	if int(data) == multiplayer.get_unique_id():
		avatar.follow = local_body
		avatar.visible = false
	return avatar
