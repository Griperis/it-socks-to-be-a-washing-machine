## Counts this machine's player's Lifetime tallies into their profile (docs/architecture/wardrobe.md "The
## Lifetime tallies"). A Node of `run.tscn` on every machine: it hears applied answers only (a Parts'
## `applied`, the Bank's `paid`, the Stages' `stage_completed`), so a World that loads, a join snapshot and the
## level's starting state (a Parts not settled) count nothing, and a Guest counts from its join on.
## `collections_completed` is counted by core/137, which makes its event.
class_name TallyRecorder
extends Node

## Counted into this profile; null reads `Worlds.profile()` (the one the Session plays under).
var profile: PlayerProfile = null

var _watched: Array[Parts] = []


func _ready() -> void:
	var stages := get_node_or_null("../Stages") as Stages
	if stages != null:
		stages.stage_completed.connect(_on_stage_completed)
	var tree := get_tree()
	tree.node_added.connect(_on_node_added)
	for node in tree.root.find_children("*", "Parts", true, false):
		_watch(node)
	for node in tree.get_nodes_in_group(Bank.GROUP):
		_watch(node)


func _on_node_added(node: Node) -> void:
	_watch(node)


func _watch(node: Node) -> void:
	if node is Parts:
		var p := node as Parts
		if not _watched.has(p):
			_watched.append(p)
			p.applied.connect(_on_applied.bind(p))
	elif node is Bank:
		var b := node as Bank
		if not b.paid.is_connected(_on_paid):
			b.paid.connect(_on_paid.bind(b))


func _profile() -> PlayerProfile:
	return profile if profile != null else Worlds.profile()


## This machine's own peer number (1 offline: a Host of one).
func _me() -> int:
	return multiplayer.get_unique_id()


func _counting(parts: Parts) -> bool:
	return parts != null and parts.is_settled()


func _count(tally: String, n: int) -> void:
	if n <= 0:
		return
	_profile().count(tally, n)
	# Each count checks the Achievements (core/145) of the game link this level plays through.
	var achievements := Achievements.of(self)
	if achievements != null:
		achievements.check(_profile())


## Every machine: a shelve answer (any shelver's, the whole team counts, Q896), or the Laundry day ending.
func _on_applied(ev: Dictionary, parts: Parts) -> void:
	if not ev.get("ok", false) or not _counting(parts):
		return
	if ev.has("shelved"):
		_count(PlayerProfile.PAIRS_SHELVED, (ev["shelved"] as Variant).size())
	var changes: Variant = ev.get("changes", {})
	if changes is Dictionary:
		for n in get_tree().get_nodes_in_group(LaundryDay.GROUP):
			var day := n as LaundryDay
			if day != null and day.parts == parts and (changes as Dictionary).has(day.id) \
					and bool(((changes as Dictionary)[day.id] as Dictionary).get("ended", false)):
				_count(PlayerProfile.GAMES_FINISHED, 1)


## The local player's payout, bonuses and refunds included, when it is decided (not when the flight lands).
func _on_paid(player: int, amount: int, _at: Node3D, _bonus: bool, bank: Bank) -> void:
	if player == _me() and _counting(bank.parts):
		_count(PlayerProfile.COINS_EARNED, amount)


func _on_stage_completed(_stage: int, _cabinet: StringName) -> void:
	var stages := get_node_or_null("../Stages") as Stages
	if stages == null or _counting(stages.parts):
		_count(PlayerProfile.FLOORS_COMPLETED, 1)
