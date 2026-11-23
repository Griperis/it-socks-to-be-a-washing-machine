## The game's link (docs/architecture/lobby.md "Core/62", Q2582): the co-op connection and who plays,
## for a whole game, beside the current scene and not inside it, so a scene change keeps the
## connection. It holds the `Session` (the one RPC node), its `Roster` and the link's own `Parts`,
## which bind the Parts that outlive a scene (the Roster now).
##
## Not an autoload: a test runs two or three machines in one process, so whoever starts a game makes
## one (the title, beside itself: under the tree's root in the game, which SceneChanger leaves alone)
## and code finds it with `GameLink.of(node)`. A level with no link (F5, the zoo, `--scene=`, a test)
## makes a private one under its runtime (LevelRuntime), so a level is never without one. Back at the
## title the game is over: the title frees the link it finds beside itself.
##
## The link's Parts name their parts as they were named inside the level runtime (`Runtime/` and the
## path from the link: the Roster is `Runtime/Session/Roster`), so the saved ids and the save's shape
## do not change.
class_name GameLink
extends Node

const SCENE := "res://game/net/game_link.tscn"
## Its name wherever it is put: Godot finds an RPC by node path, so every machine's is named alike.
const NAME := &"GameLink"
## What the link's Parts put before each id (see the top).
const ID_PREFIX := "Runtime/"
## Every link in the tree (the test hooks free the ones a case left).
const GROUP := &"game_links"

var session: Session:
	get: return get_node(^"Session") as Session
var roster: Roster:
	get: return get_node(^"Session/Roster") as Roster
var parts: Parts:
	get: return get_node(^"Parts") as Parts


func _enter_tree() -> void:
	add_to_group(GROUP)


## A new link, not in the tree yet.
static func make() -> GameLink:
	var link := (load(SCENE) as PackedScene).instantiate() as GameLink
	link.name = NAME
	return link


## The link `node` plays through (`node` is a level, anything in it, or a scene beside the link), or
## null. Walks up the parents and looks at their children, as LevelRuntime.of(); inside the tree a
## link on another MultiplayerAPI (another machine of a test) is never the answer.
static func of(node: Node) -> GameLink:
	var n := node
	while n != null:
		if n is GameLink and _usable(n as GameLink, node):
			return n as GameLink
		for child in n.get_children():
			if child is GameLink and _usable(child as GameLink, node):
				return child as GameLink
		n = n.get_parent()
	return null


## The link beside `node` (one of its siblings), made there when there is none: what the title does
## when a game starts (Solo, Host, Join).
static func open_beside(node: Node) -> GameLink:
	var home := node.get_parent()
	var link := home.get_node_or_null(NodePath(NAME)) as GameLink
	if link != null and not link.is_queued_for_deletion():
		return link
	link = make()
	home.add_child(link)
	return link


## The game is over: the link beside `node` goes (its Session closes as it leaves the tree).
static func close_beside(node: Node) -> void:
	var home := node.get_parent()
	if home == null:
		return
	var link := home.get_node_or_null(NodePath(NAME)) as GameLink
	if link == null:
		return
	home.remove_child(link)
	link.queue_free()


## Whether this link is a level's own (made by its runtime), not one made by whoever started the game.
func is_private() -> bool:
	return get_parent() is LevelRuntime


static func _usable(link: GameLink, asker: Node) -> bool:
	if link.is_queued_for_deletion():
		return false
	if asker.is_inside_tree() and link.is_inside_tree() and asker.multiplayer != link.multiplayer:
		return false
	return true
