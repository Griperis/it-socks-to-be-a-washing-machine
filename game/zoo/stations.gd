## The zoo's stations: each is an instance of one scene in `game/zoo/stations/`, placed by hand under
## this node in `zoo.tscn` (the designer drags it on the 0.5 m grid). Nothing here finds or places a
## station; a new station is its own scene file plus one instance in the zoo scene (the zoo suite
## fails for a file nobody instanced).
##
## A station's node is named after its scene's root, and that name is part of the id of every Part
## on it (`Stations/<Root>/...`).
##
## One Mess, one Hands and one Coins for the whole zoo (Q2284): a station's own `Socks` gives way to
## the zoo's `socks` before the station is added (_join_socks()), so what is held at one station is
## still held at the next. A station played alone keeps its own.
class_name ZooStations
extends Node3D

## The node a station keeps its own Mess, Hands and Coins under (and the zoo its own).
const SOCKS := ^"Socks"
## Its Mess, under it.
const MESS := ^"Mess"

## The zoo's Socks: the level's one Mess, Hands and Coins (its LevelRuntime's). Empty, every station
## keeps its own.
var socks: Node


## Before any child is ready and before the level's Parts bind: the instances already under this
## node join the zoo's socks, in tree order, so the Mess lists their spots the same on every machine.
func _enter_tree() -> void:
	var runtime := LevelRuntime.of(get_parent())
	if socks == null and runtime != null:
		socks = runtime.socks
	for station in get_children():
		if station is Node3D:
			_join_socks(station)


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
