## The Achievements kept in the player's profile (id -> unix time earned): always on, in every build (ADR9). The
## profile is the store the game reads; a Steam mirror (batch D) joins it behind the same seam.
class_name LocalAchievementBackend
extends AchievementBackend

## Whose profile.
var profile: PlayerProfile


func _init(p: PlayerProfile = null) -> void:
	profile = p


func unlock(id: StringName) -> void:
	if profile != null:
		profile.earn(String(id))


func is_unlocked(id: StringName) -> bool:
	return profile != null and profile.achievements.has(String(id))


func unlocked_ids() -> PackedStringArray:
	return PackedStringArray(profile.achievements.keys()) if profile != null else PackedStringArray()


func flush() -> void:
	if profile != null:
		profile.flush()
