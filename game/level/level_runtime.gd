## The full game setup every level shares (Q2517): the player, the Mess with its Hands, Knockdowns and
## Coins, the Parts, the Avatars and the Net, in one sealed scene (`level_runtime.tscn`). A level is
## its own geometry and look, a `Spawn` marker and one instance of it; no level overrides a node inside
## it. What differs per level is set on the instance (below).
##
## The Session and its Roster are the game link's (GameLink, core/62): the one whoever started the
## game made (the title), found with GameLink.of(), else a private one this runtime makes (F5, the zoo,
## `--scene=`, a test), so a level is never without one: beside the level when the level is the scene
## the machine runs (F5: where a title puts its link, so the Session's path is the same, core/68), else
## under this runtime; it goes when the level does. The level's Parts read through
## to the link's, and the Session uses them while the level is in the tree.
##
## Before any of its nodes is ready it puts the player on the level's spawn, points the Mess at the
## level's return spot, gives the Parts the whole level to bind, the Net the level's word and the
## nodes that need the Session or the Roster the link's (an export cannot name a node outside its
## scene). On the Host every synchronizer of the level shows a Guest nothing until that Guest's house
## is ready (Session.sees_house()). Code finds these nodes through it: `LevelRuntime.of(node)` from the
## level or anything in it.
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

## The World this level plays (core/58), set by the title before the level enters the tree; null
## plays the level as built and saves nothing (F5, the zoo, tests, `--scene=`).
var world: WorldSlot = null
## Started from the title (not the command line): how the Net starts (`--host`, `--join=<where>`,
## or nothing for alone), and a Guest whose session ends goes back to the title.
var from_title := false
var launch := PackedStringArray()

const SPAWN := ^"Spawn"
const RETURN_SPOT := ^"ReturnSpot"
## The metadata a synchronizer of the level carries once it has the house filter.
const HOUSE_GATE := &"house_gate"

## The game link this level plays through (set as it enters the tree).
var link: GameLink = null


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
	# A loaded World's Socks come from its save: the generators lay nothing (Q2579).
	mess.skip_generated = world != null and not world.is_new
	if has_node(^"LoadingScreen") and (launch_joins() or (not from_title and _joins_by_command_line())):
		loading.set_heading(LoadingScreen.JOINING)
	parts.level = level
	net.place = place_name
	autosave.world = world
	_take_link()
	var tree := get_tree()
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)


func _ready() -> void:
	_gate_synchronizers(get_parent())


func _exit_tree() -> void:
	var tree := get_tree()
	if tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)
	if link != null and is_instance_valid(link):
		link.session.detach_level(parts)
		if link.made_by == self and link.get_parent() != self:
			# Its own link beside the level goes with it, under another name at once: a level that comes
			# in this frame makes or finds a link of its own at that path.
			link.name = &"GameLinkGone"
			link.session.leave()
			link.queue_free()


## The link: the game's (GameLink.of()), else a private one under this runtime. Its Session takes the
## level's Parts, and the nodes that need it are pointed at it.
func _take_link() -> void:
	if link == null or not is_instance_valid(link) or link.is_queued_for_deletion():
		link = GameLink.of(self)
	if link == null:
		link = GameLink.make()
		link.made_by = self
		var level := get_parent()
		var home := GameLink.machine_root(self)
		if GameLink.is_shown_by(level, home) and not home.has_node(NodePath(GameLink.NAME)):
			home.add_child(link)
		if link.get_parent() == null:
			add_child(link)
			move_child(link, 0)  # the first child leaves the tree last: the Autosave saves through it first
	var s := link.session
	avatars.roster = link.roster
	avatars.session = s
	net.session = s
	autosave.session = s
	esc_menu.session = s
	s.attach_level(parts)


## Every synchronizer of the level, now and later, asks the Session whether a Guest may see it.
func _gate_synchronizers(node: Node) -> void:
	if node is MultiplayerSynchronizer:
		_gate(node as MultiplayerSynchronizer)
	for child in node.get_children():
		_gate_synchronizers(child)


func _on_node_added(node: Node) -> void:
	if node is MultiplayerSynchronizer and is_inside_tree() and get_parent().is_ancestor_of(node):
		_gate(node as MultiplayerSynchronizer)


func _gate(sync: MultiplayerSynchronizer) -> void:
	if sync.has_meta(HOUSE_GATE):
		return
	sync.set_meta(HOUSE_GATE, true)
	sync.add_visibility_filter(_sees_house)


func _sees_house(peer: int) -> bool:
	return link == null or not is_instance_valid(link) or link.session.sees_house(peer)


func _joins_by_command_line() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--join="):
			return true
	return false


## Whether the title started this level as a Guest (launch has `--join=`).
func launch_joins() -> bool:
	for arg in launch:
		if arg.begins_with("--join="):
			return true
	return false


## The local body.
var player: Player:
	get: return get_node(^"Player") as Player
## The avatars of the players in a session.
var players: Node3D:
	get: return get_node(^"Players") as Node3D
var avatars: Avatars:
	get: return get_node(^"Avatars") as Avatars
## The link's Session and Roster (null before the level enters the tree).
var session: Session:
	get: return link.session if link != null and is_instance_valid(link) else null
var roster: Roster:
	get: return link.roster if link != null and is_instance_valid(link) else null
var net: LevelNet:
	get: return get_node(^"Net") as LevelNet
var parts: Parts:
	get: return get_node(^"Parts") as Parts
var autosave: Autosave:
	get: return get_node(^"Autosave") as Autosave
var esc_menu: EscMenu:
	get: return get_node(^"EscMenu") as EscMenu
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
