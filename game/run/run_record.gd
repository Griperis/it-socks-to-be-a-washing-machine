## Every Pair shelved this run, for the Final screen (docs/architecture/run-ends.md "RunRecord"):
## `[player id, Design, Coins paid]` in the order they went in, the Coins that shelving paid (the
## personal Coins, bonuses left out). A Part of the level's `Run`; the Cabinet's shelve answer carries
## its patch, so every machine has it, a save and a late Guest receive it, and a leaver's Pairs stay.
## Batch B adds the pieces won and the Gifts opened.
class_name RunRecord
extends Part

## Every RunRecord is in this group; a thing finds its level's by `of()`.
const GROUP := &"run_record"

@export_group("State")
## [[player id (or peer number), Design index, Coins paid], ...]
@export var shelved := []
@export_group("")


func _enter_tree() -> void:
	add_to_group(GROUP)


## The RunRecord of `part`'s level (the one sharing its Parts), or null.
static func of(part: Part) -> RunRecord:
	if part == null or not part.is_inside_tree():
		return null
	for node in part.get_tree().get_nodes_in_group(GROUP):
		if (node as RunRecord).parts == part.parts:
			return node as RunRecord
	return null


## Nobody asks the record anything: it changes only inside the Cabinet's answer.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


## The change that appends `entries` ([[Design, Coins paid], ...]) for player key `key` (RunTallies.key_of).
func shelved_patch(key: Variant, entries: Array) -> Dictionary:
	var all := shelved.duplicate(true)
	for e: Array in entries:
		all.append([key, int(e[0]), int(e[1])])
	return {"shelved": all}


## How many Pairs player key `key` shelved, and the Coins they paid.
func count_of(key: Variant) -> Vector2i:
	var n := Vector2i.ZERO
	for row: Array in shelved:
		if row[0] == key:
			n += Vector2i(1, int(row[2]))
	return n
