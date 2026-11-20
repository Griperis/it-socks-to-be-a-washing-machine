## Plays one looping flat event (an ambience on the Ambient bus) while it is in the tree. Drop it in
## a level and name the event in the inspector.
class_name AmbientLoop
extends Node

## The catalogue name of the loop.
@export var event: StringName = &"amb_room"


func _enter_tree() -> void:
	Sounds.start_loop(event)


func _exit_tree() -> void:
	Sounds.stop_loop(event)
