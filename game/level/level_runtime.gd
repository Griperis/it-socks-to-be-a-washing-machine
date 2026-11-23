## The full game setup every level shares (Q2517): the player, the Mess with its Hands, Knockdowns and
## Coins, the Parts, the Session and its Roster, the Avatars and the Net, in one sealed scene
## (`level_runtime.tscn`). A level is its own geometry and look, a `Spawn` marker and one instance of
## it; no level overrides a node inside it. What differs per level is set on the instance (below).
##
## Before any of its nodes is ready it puts the player on the level's spawn, points the Mess at the
## level's return spot, gives the Parts the whole level to bind and the Net the level's word.
## Code finds these nodes through it: `LevelRuntime.of(node)` from the level or anything in it.
class_name LevelRuntime
extends Node3D

## The marker the player starts on, from this node. Empty: the level's child named `Spawn`.
@export var spawn: NodePath
## Where a Sock that left `mess_bounds` is put down, from this node. Empty: the level's child named
## `ReturnSpot`, else the spawn.
@export var return_spot: NodePath
## The playable volume of the Mess, in the level (Mess.bounds). No volume: no bounds.
@export var mess_bounds := AABB()
## The player's Hands tuning (the zoo's holds 3, Q2244). Empty: the player's own.
@export var hands_tuning: HandsTuning
## The player's Upgrades (the zoo's has them all, core/15). Empty: the player's own.
@export var upgrades: PlayerUpgrades
## The level's word in the corner and the joiner's line (LevelNet.place_name()).
@export var place_name := "house"
## Lays the level's generated Socks a slice per frame behind the loading screen (the house, house/09,
## Q2542); off: all in the start-up frame (the zoo's few).
@export var load_screen := false

const SPAWN := ^"Spawn"
const RETURN_SPOT := ^"ReturnSpot"


## The runtime of the level `node` is in (`node` is the level, the runtime or anything under the
## level), or null. Works before the tree: it walks parents and their children.
static func of(node: Node) -> LevelRuntime:
	var n := node
	while n != null:
		if n is LevelRuntime:
			return n as LevelRuntime
		for child in n.get_children():
			if child is LevelRuntime:
				return child as LevelRuntime
		n = n.get_parent()
	return null


## The level scene `node` belongs to: its owner, or the level the runtime is in when the owner is
## the runtime (what `owner` meant before the runtime was its own scene).
static func level_of(node: Node) -> Node:
	var o := node.owner
	if o is LevelRuntime:
		return o.get_parent()
	return o


func _enter_tree() -> void:
	var level := get_parent()
	var start := _marker(spawn, SPAWN)
	if start != null:
		player.transform = _in_level(start)
	if hands_tuning != null:
		player.hands_tuning = hands_tuning
	if upgrades != null:
		player.upgrades = upgrades
	var back := _marker(return_spot, RETURN_SPOT)
	mess.return_spot = back if back != null else start
	mess.bounds = mess_bounds
	mess.lay_in_slices = load_screen
	parts.level = level
	net.place = place_name


## The local body.
var player: Player:
	get: return get_node(^"Player") as Player
## The avatars of the players in a session.
var players: Node3D:
	get: return get_node(^"Players") as Node3D
var avatars: Avatars:
	get: return get_node(^"Avatars") as Avatars
var session: Session:
	get: return get_node(^"Session") as Session
var roster: Roster:
	get: return get_node(^"Session/Roster") as Roster
var net: LevelNet:
	get: return get_node(^"Net") as LevelNet
var parts: Parts:
	get: return get_node(^"Parts") as Parts
## The node the Mess, Hands, Knockdowns and Coins are under (ZooStations joins stations' to it).
var socks: Node:
	get: return get_node(^"Socks")
var mess: Mess:
	get: return get_node(^"Socks/Mess") as Mess
var hands: Hands:
	get: return get_node(^"Socks/Hands") as Hands
var knockdowns: Knockdowns:
	get: return get_node(^"Socks/Knockdowns") as Knockdowns
var coins: Coins:
	get: return get_node(^"Socks/Coins") as Coins
var spots: Node3D:
	get: return get_node(^"Spots") as Node3D
var lying: Node3D:
	get: return get_node(^"Lying") as Node3D
var flights: Node3D:
	get: return get_node(^"Flights") as Node3D
var loading: LoadingScreen:
	get: return get_node(^"LoadingScreen") as LoadingScreen


## The marker at `path` (from this node), else the level's child named `fallback`, or null.
func _marker(path: NodePath, fallback: NodePath) -> Marker3D:
	if not path.is_empty():
		return get_node_or_null(path) as Marker3D
	return get_parent().get_node_or_null(fallback) as Marker3D


## `node`'s transform in this runtime's space (the level's, since it sits at the level's origin),
## read through its parents so it works before they are in the tree.
func _in_level(node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	var level := get_parent()
	while n != null and n != level:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return transform.affine_inverse() * t
