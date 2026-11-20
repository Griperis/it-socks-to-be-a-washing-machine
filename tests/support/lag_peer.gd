## A test's slow network: wraps an ENetMultiplayerPeer and holds every packet it receives for
## `lag_ms` before SceneMultiplayer reads it, in order. One on every machine gives a symmetric one-way
## delay. With `loss` (0 to 1) it also drops that share of the unreliable packets it receives, by a
## seeded RNG, as a lossy link does; reliable packets always arrive (ENet resends them). No jitter,
## no reordering. Connects and disconnects pass at once.
## Install it right after Session.host() or join(): multiplayer.multiplayer_peer = LagPeer.new(...).
extends MultiplayerPeerExtension

var inner: ENetMultiplayerPeer
var lag_ms := 50
## The share of received unreliable packets that is dropped.
var loss := 0.0
## How many it dropped so far.
var lost := 0
var _rng := RandomNumberGenerator.new()
## Held packets, oldest first: [due in ms, bytes, from, mode, channel].
var _held: Array[Array] = []


func _init(peer: ENetMultiplayerPeer, delay_ms: int, loss_share := 0.0, loss_seed := 1) -> void:
	inner = peer
	lag_ms = delay_ms
	loss = loss_share
	_rng.seed = loss_seed
	inner.peer_connected.connect(func(id: int) -> void: peer_connected.emit(id))
	inner.peer_disconnected.connect(func(id: int) -> void:
		_held = _held.filter(func(e: Array) -> bool: return int(e[2]) != id)
		peer_disconnected.emit(id))


func _poll() -> void:
	inner.poll()
	while inner.get_available_packet_count() > 0:
		var from := inner.get_packet_peer()
		var mode := inner.get_packet_mode()
		var channel := inner.get_packet_channel()
		if loss > 0.0 and mode != TRANSFER_MODE_RELIABLE and _rng.randf() < loss:
			inner.get_packet()
			lost += 1
			continue
		_held.append([Time.get_ticks_msec() + lag_ms, inner.get_packet(), from, mode, channel])


func _get_available_packet_count() -> int:
	var now := Time.get_ticks_msec()
	var due := 0
	for e: Array in _held:
		if int(e[0]) > now:
			break
		due += 1
	return due


func _get_packet_script() -> PackedByteArray:
	return _held.pop_front()[1]


func _get_packet_peer() -> int:
	return int(_held[0][2]) if not _held.is_empty() else 0


func _get_packet_mode() -> MultiplayerPeer.TransferMode:
	return _held[0][3] if not _held.is_empty() else TRANSFER_MODE_RELIABLE


func _get_packet_channel() -> int:
	return int(_held[0][4]) if not _held.is_empty() else 0


func _put_packet_script(bytes: PackedByteArray) -> Error:
	return inner.put_packet(bytes)


func _get_max_packet_size() -> int:
	return 1 << 24


func _set_transfer_channel(channel: int) -> void:
	inner.transfer_channel = channel


func _get_transfer_channel() -> int:
	return inner.transfer_channel


func _set_transfer_mode(mode: MultiplayerPeer.TransferMode) -> void:
	inner.transfer_mode = mode


func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
	return inner.transfer_mode


func _set_target_peer(peer: int) -> void:
	inner.set_target_peer(peer)


func _get_unique_id() -> int:
	return inner.get_unique_id()


func _is_server() -> bool:
	return inner.get_unique_id() == 1


func _is_server_relay_supported() -> bool:
	return inner.is_server_relay_supported()


func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
	return inner.get_connection_status()


func _disconnect_peer(peer: int, force: bool) -> void:
	inner.disconnect_peer(peer, force)


func _close() -> void:
	inner.close()
