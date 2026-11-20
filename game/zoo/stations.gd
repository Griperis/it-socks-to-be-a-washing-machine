## The zoo's stations, one scene file each: every `game/zoo/stations/*.tscn` is instanced under this
## node when the zoo enters the tree, in file-name order. Adding a station is adding one file; the
## zoo scene is never edited for it, so two branches that each add a station never collide.
##
## A station's node is named after its scene's root, and that name is part of the id of every Part
## on it (`Stations/<Root>/...`): the same on every machine, since the files and their order are.
## Where it stands: a station whose root sits at the origin gets the next free place on the grid
## (file-name order, COLUMNS a row, the first row in front of the spawn); a root moved off the
## origin in its own scene stays where it was put.
##
## One Mess, one Hands and one Coins for the whole zoo (Q2284): a station's own `Socks` gives way to
## the zoo's `socks` before the station is added (_join_socks()), so what is held at one station is
## still held at the next. A station played alone keeps its own.
class_name ZooStations
extends Node3D

const FOLDER := "res://game/zoo/stations"
## The node a station keeps its own Mess, Hands and Coins under (and the zoo its own).
const SOCKS := ^"Socks"
## Its Mess, under it.
const MESS := ^"Mess"

## The zoo's Socks: the level's one Mess, Hands and Coins. Empty, every station keeps its own.
@export var socks: Node
## Stations a row, and the step between them in metres (x across, z away from the spawn).
const COLUMNS := 5
const STEP := Vector2(6.0, 5.0)
## The first row's z: just beyond the spawn point's view.
const FIRST_ROW_Z := -1.0

var _filled := false


## The station scenes, sorted by name. ResourceLoader lists them as the game sees them, in the
## editor and in an exported build alike (where a scene's file is stored under another name).
static func scenes() -> PackedStringArray:
	var out := PackedStringArray()
	for f in ResourceLoader.list_directory(FOLDER):
		if f.ends_with(".tscn"):
			out.append(FOLDER.path_join(f))
	out.sort()
	return out


## The grid place of the n-th station that left its place to the zoo (n from 0).
static func place(n: int) -> Vector3:
	@warning_ignore("integer_division")
	var row := n / COLUMNS
	var column := n % COLUMNS
	return Vector3((column - (COLUMNS - 1) * 0.5) * STEP.x, 0.0, FIRST_ROW_Z - row * STEP.y)


## Before any child is ready and before the level's Parts bind: the stations are part of the level
## from its first frame, alone and on every machine of a session.
func _enter_tree() -> void:
	if _filled:
		return
	_filled = true
	var placed := 0
	for path in scenes():
		var scene := load(path) as PackedScene
		if scene == null:
			push_error("zoo: station %s does not load" % path)
			continue
		var station := scene.instantiate() as Node3D
		if station == null:
			push_error("zoo: the root of station %s is not a Node3D" % path)
			continue
		if has_node(NodePath(station.name)):
			push_error("zoo: two stations are named %s (the second is %s): name each scene's root after its feature" % [station.name, path])
			station.queue_free()
			continue
		if station.position.is_zero_approx():
			station.position = place(placed)
			placed += 1
		_join_socks(station)
		add_child(station)


## A station's own Socks give way to the zoo's, before the station enters the tree (so before its
## parts are ready or bound): its SockSpots become records of the zoo's Mess, after those of the
## stations before it; every link of a station node to its own Mess, Hands or Coins (a Cabinet's)
## points at the zoo's node of the same path, and its Socks go. Its empty Lying, Flights and
## spawner stay.
func _join_socks(station: Node3D) -> void:
	var own := station.get_node_or_null(SOCKS)
	if socks == null or own == null:
		return
	var own_mess := own.get_node_or_null(MESS) as Mess
	var mess := socks.get_node_or_null(MESS) as Mess
	if own_mess != null and mess != null and own_mess.spots != null:
		mess.more_spots.append(own_mess.spots)
	_relink(station, own)
	station.remove_child(own)
	own.queue_free()


## Every stored link of `node` and its children (outside `own`) to `own` or a node under it now
## points at the node of the same path under the zoo's Socks, or at nothing.
func _relink(node: Node, own: Node) -> void:
	for p: Dictionary in node.get_property_list():
		if int(p["type"]) != TYPE_OBJECT or not (int(p["usage"]) & PROPERTY_USAGE_STORAGE):
			continue
		var linked := node.get(p["name"]) as Node
		if linked != null and (linked == own or own.is_ancestor_of(linked)):
			node.set(p["name"], socks.get_node_or_null(own.get_path_to(linked)))
	for child in node.get_children():
		if child != own:
			_relink(child, own)
