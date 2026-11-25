## A test-side stand-in for core/72's First wash and core/93's LaundryDay as the Stage bar sees them:
## `goal_pending()` for the goal phase, and the `laundry_bins` provider with numbers a case sets.
extends Node

signal bar_changed

var pending := false
var numbers := Vector2i(0, 3)


func _enter_tree() -> void:
	add_to_group(StageBar.GOAL_GROUP)
	add_to_group(StageBarPhase.SOURCES)


func goal_pending() -> bool:
	return pending


func bar_source() -> StringName:
	return &"laundry_bins"


func bar_numbers() -> Vector2i:
	return numbers


func set_numbers(n: Vector2i) -> void:
	numbers = n
	bar_changed.emit()
