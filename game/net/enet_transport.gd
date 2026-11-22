## The transport by address over ENet (LAN and direct IP; tests and CI). The only file that names
## ENet or reads an address. It holds ENet's packet throttle at full on every peer, at both ends,
## the moment each connects: left alone it sinks to nothing at 60 frames a second and ENet then drops
## 31 of every 32 unreliable packets, so a Teammate's pose would come twice a second
## (docs/research/coop-flight-sync.md condition 1).
class_name EnetTransport
extends NetTransport

## ENet's throttle held at full: measured over 5 s, rising by the whole scale, never falling.
const THROTTLE_INTERVAL_MS := 5000
const THROTTLE_DECELERATION := 0

## The port a join uses when `where` names none (the Session sets its own port here).
var default_port := 24565
## Whether each peer's throttle is held at full (a test of ENet's own throttle switches it off).
var full_throttle := true


func host(port: int, slots: int) -> Error:
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_server(port, slots)
	if err != OK:
		return err
	_hold(enet)
	peer = enet
	return OK


func join(where: String) -> Error:
	var target := split_address(where, default_port)
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_client(String(target[0]), int(target[1]))
	if err != OK:
		return err
	_hold(enet)
	peer = enet
	return OK


func describe() -> String:
	return "port %d" % local_port() if peer != null else ""


## The port this Host listens on (after host(0), the one the system chose); 0 when not hosting.
func local_port() -> int:
	var enet := peer as ENetMultiplayerPeer
	return enet.host.get_local_port() if enet != null and enet.host != null else 0


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


## Every peer of `enet` gets the full throttle as it connects (the Host's Guests; a Guest's Host).
func _hold(enet: ENetMultiplayerPeer) -> void:
	if not full_throttle:
		return
	enet.peer_connected.connect(func(id: int) -> void:
		var link := enet.get_peer(id)
		if link != null:
			link.throttle_configure(THROTTLE_INTERVAL_MS, ENetPacketPeer.PACKET_THROTTLE_SCALE, THROTTLE_DECELERATION))
