## The zoo's stations, one scene file each: every `game/zoo/stations/*.tscn` is instanced under this
## node when the zoo enters the tree, in file-name order. Adding a station is adding one file; the
## zoo scene is never edited for it, so two branches that each add a station never collide.
##
## A station's node is named after its scene's root, and that name is part of the id of every Part
## on it (`Stations/<Root>/...`): the same on every machine, since the files and their order are.
## Where it stands: a station whose root sits at the origin gets the next free place on the grid
## (file-name order, COLUMNS a row, the first row in front of the spawn); a root moved off the
## origin in its own scene stays where it was put.
class_name ZooStations
extends Node3D

const FOLDER := "res://game/zoo/stations"
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
		add_child(station)
