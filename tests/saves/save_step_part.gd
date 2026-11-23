## A Part for tests/save_test.gd S09 only: its save is at version 2, where version 1 called its one
## field `old`; upgrade_save() renames it, as a real Part's step would.
class_name SaveStepPart
extends Part

@export_group("State")
@export var count := 0
@export_group("")


func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func save_version() -> int:
	return 2


func upgrade_save(state: Dictionary, from: int) -> Dictionary:
	if from == 1 and state.has("old"):
		state["count"] = state["old"]
		state.erase("old")
	return state
