## What the Final screen shows, as plain data (run-ends.md "The Final screen"): a column per player in the
## game at the end and the World totals. `make()` builds it from the run's RunRecord and the players' listing
## (RunTallies.listing(): the Roster's order), `of()` from a running level. A player who left before the end
## has no column, but their Pairs are in the record and so in the totals (Q2630). The zoo's station builds it
## from a made-up record the same way.
class_name FinalSummary
extends RefCounted

## One per player: {"id", "name", "colour", "pairs": [[Design id, Coins paid], ...] in shelving order, "earned"}.
var columns: Array[Dictionary] = []
## What FinalTotal.source names, each a whole number: "play_time" (seconds), "coins_earned", "stages".
var values: Dictionary[StringName, int] = {}


## The summary of `shelved` (RunRecord.shelved: [player id, Design id, Coins paid] rows) for the players of `listing` who are still in the game. `earned` is the Coins the
## listing says a player earned (the Pairs' Coins and any bonus beside them).
static func make(shelved: Array, listing: Array[Dictionary], play_time: int, stages: int) -> FinalSummary:
	var s := FinalSummary.new()
	for e: Dictionary in listing:
		if bool(e.get("left", false)):
			continue
		var rows: Array = []
		var paid := 0
		for row: Array in shelved:
			if row[0] == e["id"]:
				rows.append([int(row[1]), int(row[2])])
				paid += int(row[2])
		s.columns.append({"id": e["id"], "name": String(e["name"]), "colour": e["colour"], "pairs": rows,
				"earned": maxi(int(e.get("coins", paid)), paid)})
	var coins := 0
	for row: Array in shelved:
		coins += int(row[2])
	s.values = {&"play_time": play_time, &"coins_earned": coins, &"stages": stages}
	return s


## The summary of the run of `level` (a LevelRuntime): its record, tallies, Stages and play time.
static func of(level: Node) -> FinalSummary:
	var tree := level.get_tree()
	var record := tree.get_first_node_in_group(RunRecord.GROUP) as RunRecord
	var tallies := tree.get_first_node_in_group(RunTallies.GROUP) as RunTallies
	var stages := tree.get_first_node_in_group(Stages.GROUP) as Stages
	var autosave := level.get("autosave") as Autosave
	var seconds := int(autosave.world.record.play_time) if autosave != null and autosave.world != null else 0
	var listing: Array[Dictionary] = []
	if tallies != null:
		listing = tallies.listing()
	return make(record.shelved if record != null else [], listing, seconds, completed(stages))


## How many Stages are done: the current one counts once its bar is full.
static func completed(stages: Stages) -> int:
	if stages == null or stages.stage < 0:
		return 0
	return stages.stage + (0 if stages.phase == Stages.Phase.PLAYING else 1)
