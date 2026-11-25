## What each player's run counts (docs/architecture/stages.md "The tallies, the Whiteboard and Tab"):
## Pairs shelved, Pairs made, Socks picked and Coins earned. A Part of the level's `Run`. It decides
## nothing and is asked nothing: the answers that cause a tally (the Cabinet's shelve, the Hands' pick)
## carry its patch, so every machine counts the same, a save and a late Guest receive it with its State,
## and a player who left keeps their row (it is keyed by player id, like the Coins).
class_name RunTallies
extends Part

## Every RunTallies is in this group; a thing finds its level's by `of()`.
const GROUP := &"run_tallies"
## The tally names of a row.
const PAIRS := "pairs"
const MADE := "made"
const SOCKS := "socks"
const COINS := "coins"
## The colour of a row whose player this machine never knew.
const UNKNOWN_COLOUR := Color(0.5, 0.5, 0.55)

## A row of the board changed, or the Roster named someone else (the Whiteboard draws again).
signal changed

@export_group("State")
## {player id (or peer number while no Roster names them): {pairs, made, socks, coins}}.
@export var rows := {}
@export_group("")

var _roster: Roster = null
## The last player id seen on each peer, so the key still holds once the Roster is cleared.
var _ids: Dictionary[int, String] = {}


func _enter_tree() -> void:
	add_to_group(GROUP)


## The RunTallies of `part`'s level (the one sharing its Parts), or null.
static func of(part: Part) -> RunTallies:
	if part == null or not part.is_inside_tree():
		return null
	for node in part.get_tree().get_nodes_in_group(GROUP):
		if (node as RunTallies).parts == part.parts:
			return node as RunTallies
	return null


## Nobody asks the tallies anything: they change only inside another Part's answer.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func _show(_now: bool) -> void:
	changed.emit()


## The key player `by` (a peer number) is counted under: their player id once the Roster names them.
func key_of(by: int) -> Variant:
	var roster := roster_of()
	var pid := roster.id_of(by) if roster != null else ""
	if pid != "":
		_ids[by] = pid
		return pid
	return _ids.get(by, by)


## The level's Roster, or null (found once).
func roster_of() -> Roster:
	if (_roster == null or not is_instance_valid(_roster)) and parts != null:
		_roster = parts.find(func(part: Part) -> bool: return part is Roster) as Roster
		if _roster != null and not _roster.changed.is_connected(_on_roster_changed):
			_roster.changed.connect(_on_roster_changed)
	return _roster


## Player `by`'s tally `name` (0 for a player who counted nothing).
func tally(by: int, name: String) -> int:
	return int((rows.get(key_of(by), rows.get(by, {})) as Dictionary).get(name, 0))


## The change that adds `pairs` shelved and `coins` earned to player `by`'s row (part of the Cabinet's answer).
func shelved_patch(by: int, pairs: int, coins: int) -> Dictionary:
	return _added(by, {PAIRS: pairs, COINS: coins})


## The change for a pick by player `by`: a Sock out of the Mess is `socks`, and `made` when it fused a Pair.
func picked_patch(by: int, socks: int, made: int) -> Dictionary:
	return _added(by, {SOCKS: socks, MADE: made})


## One entry per player the run knows, the Roster's order first then any other row: {"id", "name",
## "colour", "pairs", "made", "socks", "coins", "left"}. A player who left keeps their entry.
func listing() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	var roster := roster_of()
	if roster != null:
		for pid: Variant in roster.players:
			var e: Dictionary = roster.players[pid]
			var colour := roster.tuning.colour(int(e.get("colour", 0))) if roster.tuning != null else UNKNOWN_COLOUR
			out.append(_entry(pid, String(e.get("name", PlayerProfile.NAME)), colour, not roster.is_live(String(pid))))
			seen[pid] = true
	for key: Variant in rows:
		if not seen.has(key):
			out.append(_entry(key, PlayerProfile.NAME, UNKNOWN_COLOUR, roster != null))
	return out


func _on_roster_changed() -> void:
	changed.emit()


func _entry(key: Variant, who: String, colour: Color, left: bool) -> Dictionary:
	var row: Dictionary = rows.get(key, {})
	return {"id": key, "name": who, "colour": colour, "left": left, PAIRS: int(row.get(PAIRS, 0)),
			MADE: int(row.get(MADE, 0)), SOCKS: int(row.get(SOCKS, 0)), COINS: int(row.get(COINS, 0))}


func _added(by: int, add: Dictionary) -> Dictionary:
	var key: Variant = key_of(by)
	var all := rows.duplicate(true)
	var row: Dictionary = all.get(key, all.get(by, {}))
	all.erase(by)
	for name: String in add:
		row[name] = int(row.get(name, 0)) + int(add[name])
	all[key] = row
	return {"rows": all}
