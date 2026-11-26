## A store of Achievements for tests (core/145): it keeps what it was told in memory and counts its calls, standing
## in for Steam's mirror behind the AchievementBackend seam.
extends AchievementBackend

## Every unlock asked, in order (an id asked twice is here twice).
var asked: Array[StringName] = []
var flushes := 0
var _have: Dictionary[StringName, bool] = {}


func unlock(id: StringName) -> void:
	asked.append(id)
	_have[id] = true


func is_unlocked(id: StringName) -> bool:
	return _have.has(id)


func unlocked_ids() -> PackedStringArray:
	return PackedStringArray(_have.keys())


func flush() -> void:
	flushes += 1
