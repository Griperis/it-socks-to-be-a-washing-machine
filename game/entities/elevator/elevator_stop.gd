## One stop of the Elevator (docs/architecture/elevator.md "The shape"): the hatch, the brass call button, the padlock
## sign and the "OUT OF ORDER" plaque of one floor, dropped by hand as a child of the Elevator at the floor's height
## with its `floor` set in the inspector (the letters' column and the station's board are built from the stops).
## Its origin is the floor, in the hatch's face plane across the opening's middle, facing +Z (the shaft behind).
##
## Its decided state is its hatch's `Openable` (written only in the Elevator's answers); its clickables are the
## `ElevatorControl`s of the hatch (first, so the hatch's body is aimed through it) and of the button. This script is
## looks only: it shows its floor's call set, puts the button's aim body and the outlines on the Looks' meshes, and
## plays the signs' clips the Elevator asks for (show_signs()).
class_name ElevatorStop
extends Node3D

## The letters of the floors by `HouseLights.floors` index, as the Looks names its call sets (`call_b`, ...).
const LETTERS: Array[String] = ["b", "g", "1", "a"]
## The Looks' clips (looks_contract.json).
const OUT_OF_ORDER := &"out_of_order"
const REPAIRED := &"repaired"
const LOCKED := &"locked"
const UNLOCK := &"unlock"
const PRESS := &"press"

## The floor it stands at (0 the basement, 1 the ground floor, 2 the first floor, 3 the attic).
@export_range(0, 3, 1) var floor := 1
## The hatch's ability to open and shut (driven by the Elevator).
@export var hatch: Openable
## The button's aim body, put on the Looks' button of this floor at ready.
@export var button_aim: Node3D
## The outlines of the hatch's panel and of the button (their meshes found in the Looks at ready).
@export var hatch_outline: Outline
@export var button_outline: Outline
## Where the car's floor stands at this stop (only its height is read: the car stays in the shaft).
@export var car_floor: Marker3D
## The strip over the hatch's sill that a shutting hatch pushes into the car (core/156).
@export var sill: CollisionShape3D

## The signs as last shown: null before the first show.
var _was_broken: Variant = null
var _was_locked: Variant = null


## The button's aim body is put on its floor's button before anything enters the physics space, so a level's
## Socks laid before its ready (a New Game) meet it where they meet it later (house_test h09).
func _enter_tree() -> void:
	var button := _button_mesh()
	if button == null or button_aim == null:
		return
	var local := Transform3D.IDENTITY
	var node: Node = button
	while node != null and node != self:
		if node is Node3D:
			local = (node as Node3D).transform * local
		node = node.get_parent()
	button_aim.position = local.origin


func _ready() -> void:
	var looks := get_node_or_null(^"Looks")
	if looks == null:
		return
	var mine := LETTERS[clampi(floor, 0, LETTERS.size() - 1)]
	for l in LETTERS:
		var calls := looks.find_child("call_" + l, true, false) as Node3D
		if calls != null:
			calls.visible = l == mine
	var button := _button_mesh()
	if button != null:
		if button_outline != null:
			button_outline.meshes = [button_outline.get_path_to(button)]
	var panel := looks.find_child("hatch", true, false) as MeshInstance3D
	if panel != null and hatch_outline != null:
		hatch_outline.meshes = [hatch_outline.get_path_to(panel)]


## The Looks' call button of this floor, or null.
func _button_mesh() -> MeshInstance3D:
	var looks := get_node_or_null(^"Looks")
	if looks == null:
		return null
	return looks.find_child("button_" + LETTERS[clampi(floor, 0, LETTERS.size() - 1)], true, false) as MeshInstance3D


## The AnimationPlayer of the Looks that has `clip`, or null.
func player_of(clip: StringName) -> AnimationPlayer:
	var looks := get_node_or_null(^"Looks")
	if looks == null:
		return null
	for node in looks.find_children("*", "AnimationPlayer", true, false):
		if (node as AnimationPlayer).has_animation(clip):
			return node as AnimationPlayer
	return null


## Looks only: the plaque while the Elevator is out of order, the padlock while this floor is locked (and the
## Elevator works). A change plays its clip; `now` (a load, a join, the first show) jumps to its end.
func show_signs(broken: bool, locked: bool, now: bool) -> void:
	if _was_broken == null or bool(_was_broken) != broken:
		_play(OUT_OF_ORDER if broken else REPAIRED, now or _was_broken == null)
	if _was_locked == null or bool(_was_locked) != locked:
		_play(LOCKED if locked else UNLOCK, now or _was_locked == null)
	_was_broken = broken
	_was_locked = locked


## Looks only: the call button dips (an answered click on it).
func press() -> void:
	var player := player_of(PRESS)
	if player != null:
		player.stop()
		player.play(PRESS)


## Where the hatch's middle is (the bell and the hatch's sounds).
func hatch_spot() -> Vector3:
	var body := get_node_or_null(^"Looks/Hatch") as Node3D
	return body.global_position if body != null else global_position + Vector3.UP


## Where the call button is (its click).
func button_spot() -> Vector3:
	return button_aim.global_position if button_aim != null else hatch_spot()


## The height of the car's floor at this stop, in the world.
func car_height() -> float:
	return car_floor.global_position.y if car_floor != null else global_position.y


## The sill's strip, in the world.
func sill_box() -> AABB:
	return Elevator.box_of(sill)


func _play(clip: StringName, now: bool) -> void:
	var player := player_of(clip)
	if player == null:
		return
	player.play(clip)
	if now:
		player.seek(player.get_animation(clip).length, true)
		player.pause()
