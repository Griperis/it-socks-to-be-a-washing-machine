## Both currencies as one Part (docs/architecture/economy.md "`Bank`'s state and verbs"): each player's
## Coins, keyed by player id (the Roster's, Q2458; the peer number only while no Roster names them, so
## a Guest's Coins wait for them in a saved World), and the team's Drawers. No verb pays by itself:
## every payout is a patch inside another Part's answer (a Cabinet's shelve, a floor's opening), so a
## shelve, its Coins, its Drawers and its tallies are one answer. Such an answer notes its payouts
## (note()); every machine turns them into `paid` and `drawers_paid` for the HUD's flight.
##
## Coins still flying are not spendable yet (Q2672): the Host keeps each payout's landing in `recent`
## on its own clock (not saved: a load or a join lands them at once), so spendable() is the landed ones.
##
## Its own verbs: `welcome` (the Host, for a player id it has never seen: the average of the present
## players' Coins, rounded down, Q1249) and `cheat` (the Host in a debug build, F9: +1000, no flight,
## Q292; a Guest's press asks nothing).
class_name Bank
extends Part

## A payout to `player` (a peer number) of `amount` Coins, popping over drawer `at_drawer` (null: none);
## `bonus` (a Stage bonus) has no "+N": the counter counts up (Q2668). Every machine, from the answer.
signal paid(player: int, amount: int, at_drawer: Node3D, bonus: bool)
## The team earned `amount` Drawers by `player`'s filled drawer `at_drawer`. Every machine.
signal drawers_paid(player: int, amount: int, at_drawer: Node3D)
## The debug cheat gave `player` `amount` Coins. Every machine.
signal cheated(player: int, amount: int)

## The group the level's Bank is in: a Cabinet finds it there when none is set.
const GROUP := &"bank"
## Where an answer lists its payouts for the flight: [{"player", "coins", "drawers", "at", "bonus"}].
const PAYOUTS := "bank"
const WELCOME := &"welcome"
const CHEAT := &"cheat"
## The input action of the debug cheat (F9).
const CHEAT_ACTION := &"debug_cheat_coins"
## The cheat's message: the amount and the Coins' name.
const CHEAT_SAYS := "Debug: +%d %s"

@export var tuning: EconomyTuning = preload("res://game/economy/economy_tuning.tres")
## The flight's times: when a payout's Coins land, so when they may be spent.
@export var flight: CoinFlightTuning = preload("res://game/ui/money/coin_flight_tuning.tres")
@export var coins_currency: Currency = preload("res://game/economy/coins.tres")
@export var drawers_currency: Currency = preload("res://game/economy/drawers.tres")

@export_group("State")
## Each player's Coins: {player id: int}.
@export var coins := {}
## The team's Drawers.
@export var drawers := 0
## The payouts still flying, on the Host's clock: {player id: [[first landing, amount], ...]}. Not saved.
@export var recent := {}
@export_group("")

## The Host's clock in seconds (physics time since the level started): what `recent` is measured on.
var clock := 0.0

var _roster: Roster
## The last player id seen on each peer: the key still holds once the Roster is cleared.
var _ids: Dictionary[int, String] = {}


func _enter_tree() -> void:
	add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	clock += delta


## The Bank of `node`'s level (the one sharing its Parts), else the first in the tree, or null.
static func of(node: Node) -> Bank:
	if node == null or not node.is_inside_tree():
		return null
	var first: Bank = null
	var p: Parts = (node as Part).parts if node is Part else null
	for b in node.get_tree().get_nodes_in_group(GROUP):
		if first == null:
			first = b as Bank
		if p != null and (b as Bank).parts == p:
			return b as Bank
	return first


# --- Reading -------------------------------------------------------------------------------------

## Player `by`'s (a peer number) Coins, the flying ones included.
func of_player(by: int) -> int:
	return int(coins.get(key_of(by), coins.get(by, 0)))


## The Coins player `by` may spend now: the landed ones (Q2672). Read on the Host.
func spendable(by: int) -> int:
	return of_player(by) - in_flight(by)


## The Coins of player `by` still flying on the Host's clock.
func in_flight(by: int) -> int:
	var n := 0
	for entry: Variant in recent.get(key_of(by), recent.get(by, [])):
		n += _left_of(entry as Array)
	return n


## Whether player `by` may spend `amount` Coins now (a purchase's check, core/129).
func can_spend(by: int, amount: int) -> bool:
	return spendable(by) >= amount


## The key player `by` (a peer number) is kept under: their player id once the Roster names them,
## else the peer number.
func key_of(by: int) -> Variant:
	var roster := _roster_of()
	var pid := roster.id_of(by) if roster != null else ""
	if pid != "":
		_ids[by] = pid
		return pid
	return _ids.get(by, by)


## The peers of the players in the game now (the Roster's), or the Host alone with no Roster.
func present() -> PackedInt32Array:
	var roster := _roster_of()
	if roster != null and not roster.peers().is_empty():
		return roster.peers()
	return PackedInt32Array([Parts.HOST])


# --- Patches (parts of another Part's answer) ----------------------------------------------------

## The change that pays player `by` `amount` more Coins, landing as a payout of the flight (`bonus`: a
## Stage bonus, `bonus_delay` later). `into`: a patch of this Bank already in the answer, added to.
func paid_patch(by: int, amount: int, bonus := false, into := {}) -> Dictionary:
	var patch := into.duplicate()
	var c: Dictionary = (into.get("coins", coins) as Dictionary).duplicate()
	var key: Variant = key_of(by)
	var total := int(c.get(key, c.get(by, 0))) + amount
	c.erase(by)
	c[key] = total
	patch["coins"] = c
	var r: Dictionary = (into.get("recent", recent) as Dictionary).duplicate(true)
	var flying: Array = []
	for entry: Variant in r.get(key, r.get(by, [])):
		if _left_of(entry as Array) > 0:
			flying.append(entry)
	r.erase(by)
	if amount > 0:
		flying.append([clock + flight.first_landing(bonus), amount])
	if flying.is_empty():
		r.erase(key)
	else:
		r[key] = flying
	patch["recent"] = r
	return patch


## The change that adds `amount` Drawers to the team's.
func drawers_patch(amount: int, into := {}) -> Dictionary:
	var patch := into.duplicate()
	patch["drawers"] = int(into.get("drawers", drawers)) + amount
	return patch


## The change that takes `spent_coins` of player `by`'s Coins and `spent_drawers` of the team's (a
## purchase, core/129: checked with can_spend() first).
func spent_patch(by: int, spent_coins: int, spent_drawers: int, into := {}) -> Dictionary:
	var patch := paid_patch(by, -spent_coins, false, into)
	patch["drawers"] = int(into.get("drawers", drawers)) - spent_drawers
	return patch


## Notes a payout in answer `ev` for every machine's flight: player `by` (a peer number), `paid_coins`
## Coins and `paid_drawers` Drawers at the drawer whose Openable is `at` (null: none), `bonus` a Stage
## bonus.
static func note(ev: Dictionary, by: int, paid_coins: int, paid_drawers: int, at: Part, bonus: bool) -> void:
	var list: Array = ev.get(PAYOUTS, [])
	list.append({"player": by, "coins": paid_coins, "drawers": paid_drawers,
			"at": at.id if at != null else &"", "bonus": bonus})
	ev[PAYOUTS] = list


# --- Verbs ---------------------------------------------------------------------------------------

func decide(cmd: Command) -> Dictionary:
	if cmd.by != Parts.HOST:
		return refuse("wrong")
	match cmd.kind:
		WELCOME:
			var pid := String(cmd.args.get("player", ""))
			if pid == "" or coins.has(pid):
				return refuse("already")
			return grant({"coins": _welcomed(coins, pid)})
		CHEAT:
			if not OS.is_debug_build():
				return refuse("wrong")
			# No flight: the Coins are spendable at once (nothing goes into `recent`).
			var ev := grant({"coins": paid_patch(Parts.HOST, tuning.cheat_coins)["coins"]})
			ev["cheat"] = tuning.cheat_coins
			return ev
	return refuse("wrong")


## The Host's F9 in a debug build asks the cheat; a Guest's asks nothing (Q292).
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or parts == null or not parts.is_host() or not event.is_action_pressed(CHEAT_ACTION):
		return
	if not is_inside_tree() or multiplayer.get_unique_id() != Parts.HOST:
		return
	parts.ask(Command.new(CHEAT, Parts.HOST, id, {}))


## What a save keeps: the Coins and the Drawers; never what is still flying.
func save_state() -> Dictionary:
	return {"coins": coins, "drawers": drawers}


## What a joining Guest receives: nothing flying (a join lands them at once).
func whole_state() -> Dictionary:
	return {"coins": coins, "drawers": drawers}


## A load lands every flying Coin at once.
func restored(saved: Dictionary) -> Dictionary:
	var state := saved.duplicate()
	state["recent"] = {}
	return state


## The Host, after a load: every player in the game whose id the save never knew is welcomed.
func loaded(_host: String) -> Dictionary:
	var roster := _roster_of()
	if roster == null:
		return {}
	var c := coins
	var changed := false
	for pid: Variant in roster.players:
		if roster.is_live(String(pid)) and not c.has(String(pid)):
			c = _welcomed(c, String(pid))
			changed = true
	return grant({"coins": c}) if changed else {}


## Bound: it hears every applied answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_on_applied):
		parts.applied.connect(_on_applied)


## Every machine: an answer's payouts become signals. The Host welcomes a player id the Roster just
## took in that it has never seen.
func _on_applied(ev: Dictionary) -> void:
	if not ev.get("ok", false):
		return
	for p: Variant in ev.get(PAYOUTS, []):
		var payout := p as Dictionary
		var at := _drawer_of(StringName(payout.get("at", &"")))
		var by := int(payout.get("player", Parts.HOST))
		if int(payout.get("coins", 0)) > 0:
			paid.emit(by, int(payout["coins"]), at, bool(payout.get("bonus", false)))
		if int(payout.get("drawers", 0)) > 0:
			drawers_paid.emit(by, int(payout["drawers"]), at)
	if StringName(ev.get("kind", &"")) == CHEAT and StringName(ev.get("to", &"")) == id:
		cheated.emit(int(ev.get("by", Parts.HOST)), int(ev.get("cheat", 0)))
	var roster := _roster_of()
	if parts.is_host() and roster != null and StringName(ev.get("to", &"")) == roster.id \
			and StringName(ev.get("kind", &"")) == Roster.JOINED:
		var pid := String(ev.get("player", ""))
		if pid != "" and not coins.has(pid):
			parts.ask.call_deferred(Command.new(WELCOME, Parts.HOST, id, {"player": pid}))


## `c` with player id `pid` given the average of the other present players' Coins, rounded down.
func _welcomed(c: Dictionary, pid: String) -> Dictionary:
	var sum := 0
	var n := 0
	var roster := _roster_of()
	if roster != null:
		for other: Variant in roster.players:
			if String(other) != pid and roster.is_live(String(other)):
				sum += int(c.get(String(other), 0))
				n += 1
	var out := c.duplicate()
	out[pid] = sum / n if n > 0 else 0
	return out


## The drawer whose Openable has id `openable`, or null.
func _drawer_of(openable: StringName) -> Node3D:
	if openable == &"" or parts == null:
		return null
	var part := parts.of(openable)
	return part.get_parent() as Node3D if part != null else null


## How many of a payout's Coins ([first landing, amount]) are still flying on the clock.
func _left_of(entry: Array) -> int:
	if entry.size() < 2:
		return 0
	var first := float(entry[0])
	var amount := int(entry[1])
	if amount <= 0 or clock < first:
		return maxi(amount, 0)
	var spread := flight.spread()
	if amount == 1 or spread <= 0.0:
		return 0
	var landed := floori((clock - first) / spread * float(amount - 1)) + 1
	return clampi(amount - landed, 0, amount)


## The level's Roster, or null (found once).
func _roster_of() -> Roster:
	if (_roster == null or not is_instance_valid(_roster)) and parts != null:
		_roster = parts.find(func(part: Part) -> bool: return part is Roster) as Roster
	return _roster
