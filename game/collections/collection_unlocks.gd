## The rule that unlocks Collections across games (core/125, Q1439, Q1440, Q1465): the set a first game has, the
## fixed order the next ones follow, and how many a finished game adds. Edited on `collection_unlocks.tres`.
class_name CollectionUnlocks
extends Resource

## Unlocked in a first game.
@export var start: Array[StringName] = []
## The Collections unlocked one after another, a finished game at a time. A new Collection unlocks by being
## added here.
@export var order: Array[StringName] = []
## How many a finished game unlocks.
@export var per_finished_game := 1


## The Collections a finished game unlocks for a player who has `unlocked`: the next `per_finished_game` of
## `order` not yet in it (none once all are).
func next_after(unlocked: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in order:
		if out.size() >= per_finished_game:
			break
		if not unlocked.has(id) and not start.has(id):
			out.append(id)
	return out
