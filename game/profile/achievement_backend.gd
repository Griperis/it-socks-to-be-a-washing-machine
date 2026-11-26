## The seam between the Achievements and a store of them (docs/architecture/wardrobe.md "Achievements", ADR9): the
## profile's own (LocalAchievementBackend, always on), Steam's mirror later (batch D, Q1957, Q2616), a fake in tests.
## Nothing extends a backend that extends this (Q2251).
@abstract
class_name AchievementBackend
extends RefCounted


## Achievement `id` was earned on this machine.
@abstract func unlock(id: StringName) -> void


## Whether this store has `id`.
@abstract func is_unlocked(id: StringName) -> bool


## Every id this store has.
@abstract func unlocked_ids() -> PackedStringArray


## Writes what is pending (the game quits, a batch of unlocks ended).
@abstract func flush() -> void
