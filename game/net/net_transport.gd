## How this machine reaches the others: the one place that makes the MultiplayerPeer (the seam of
## docs/research/steam-multiplayer.md "The seam"). Session keeps a plain MultiplayerPeer and never
## names a transport's own types, an IP address or a port. ENet (EnetTransport) is the only one now;
## Steam's peer, lobby and ids come in at M4 as one more transport (Q2457).
##
## `where` is opaque: "ip:port" for ENet, a lobby or Steam id later. Only the transport reads it.
@abstract
class_name NetTransport
extends RefCounted

## The peer host() or join() made, or null before either (and after a failure).
var peer: MultiplayerPeer = null


## Opens this machine for Guests. `port` is a hint a transport may ignore; 0 lets it choose.
## `slots` is how many connections it lets wait at the gate at once.
@abstract func host(port: int, slots: int) -> Error


## Starts reaching the Host at `where` (opaque, as the player gave it).
@abstract func join(where: String) -> Error


## Where Guests reach this Host, said for a person ("port 24565"), or "" when nothing is open.
@abstract func describe() -> String


## The number Guests reach this Host on, when the transport has one (ENet's port); 0 otherwise.
func local_port() -> int:
	return 0
