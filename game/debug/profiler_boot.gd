## The first autoload (listed before `Profily` in project.godot): configures Profily before its
## _ready reads its settings, and turns F3 (`toggle_profiler`) into Profiler.toggle() anywhere in
## the game. Removed with the add-on by kit/tools/setup.py --profily=no.
extends Node


func _init() -> void:
	Profiler.configure()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_profiler"):
		if Profiler.toggle():
			get_viewport().set_input_as_handled()
