## Where a Machine Part goes in (core/79, docs/architecture/stages.md "Its verbs"): placed on the washing
## machine (the zoo's stand-in is a box). A player carrying the current Stage's Part clicks it and the Part
## is fitted: the Part is put away, the machine is a Fix calmer and its floor opens (`Stages.fit_answer()`,
## at once while the Stage names no `fix_cutscene`: core/92 sets it). The washer is core/73's: while it is
## `busy()` (someone in its drum, a cutscene) the fit is refused "The washing machine is busy".
## It keeps no state; the answer's changes are the Part's (hidden) and the run's (its phase).
class_name MachinePartSlot
extends Part

## The verb a player asks.
const FIT := &"fit"
const FIT_SOUND := &"part_fit"
const BUSY := "busy"
const NOT_CARRIED := "not_carried"
## What a refusal reads to the player who asked (Player reads it).
const SAYS := {BUSY: "The washing machine is busy"}
## The washer is in this group: it answers `busy()`.
const WASHER_GROUP := &"washer"
## The zoo's box is aimed as itself: it needs no aim body.
const WIRING_OPTIONAL := ["aim_body"]

## The run whose Part it takes.
@export var stages: Stages
## How far from it a player may stand to fit, in metres.
@export var reach := 4.0
## A body over the machine that takes the crosshair only while the Stage's Part is out (the house's washer,
## core/91: the Washer, its first Part, is aimed the rest of the time); it is on `aim_layer` then, on none
## otherwise. Unset: the slot's own thing is always aimed (the zoo's box).
@export var aim_body: CollisionObject3D
@export_flags_3d_physics var aim_layer := Mess.LAYER_HOUSE


func _ready() -> void:
	set_physics_process(aim_body != null)
	_aim_now()


func _physics_process(_delta: float) -> void:
	_aim_now()


## The aim body is on its layer exactly while a Part is out (read every frame: an answer, a load and a join alike).
func _aim_now() -> void:
	if aim_body == null:
		return
	var want := aim_layer if stages != null and stages.stage >= 0 and stages.phase == Stages.Phase.PART_OUT else 0
	if aim_body.collision_layer != want:
		aim_body.collision_layer = want


## On the washer (an aim body) it reads as the washer does, named with no key; the zoo's box reads nothing.
func prompt_title() -> String:
	return Washer.TITLE if aim_body != null else ""


func hint_only() -> bool:
	return aim_body != null


func click_only() -> bool:
	return true


func use(by: int) -> void:
	parts.ask(Command.new(FIT, by, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {FIT: {"args": {}, "rate": 4}}


## Whether the washer cannot take a Part now (the washer's `busy()` when there is one).
func busy() -> bool:
	if not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group(WASHER_GROUP):
		if node.has_method(&"busy") and node.call(&"busy"):
			return true
	return false


## Looks only: `part_fit` plays at the machine on every machine when the Part goes in.
func _show(_now: bool) -> void:
	if stages != null and not stages.part_fitted.is_connected(_on_fitted):
		stages.part_fitted.connect(_on_fitted)


func _on_fitted(_stage: int) -> void:
	var thing := get_parent() as Node3D
	if thing != null and thing.is_inside_tree():
		Sounds.play_at(FIT_SOUND, thing.global_position)


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != FIT or stages == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	var mine := _carried_by(cmd.by)
	if mine == null:
		return refuse(NOT_CARRIED)
	if busy():
		return refuse(BUSY)
	var answer := stages.fit_answer()
	if not answer.get("ok", false):
		return answer
	(answer["changes"] as Dictionary)[mine.carriable.id] = {"holder": 0}
	return answer


## The MachinePart player `by` carries that is this Stage's, or null.
func _carried_by(by: int) -> MachinePart:
	var current := stages.current()
	if current == null or current.part == null or stages.phase != Stages.Phase.PART_OUT:
		return null
	for node in get_tree().get_nodes_in_group(MachinePart.GROUP):
		var part := node as MachinePart
		if part != null and part.parts == parts and part.carriable != null and part.carriable.holder == by \
				and part.kind != null and part.kind.id == current.part.id:
			return part
	return null
