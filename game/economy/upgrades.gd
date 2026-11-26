## The Upgrades bought (docs/architecture/economy.md "`Upgrades`' state and verbs"), beside the Bank: each
## player's Personal levels (keyed by player id, as the Bank keeps Coins, so a Guest's wait for them in a
## saved World) and the team's House levels, and the `buy` verb. The Upgrades themselves are data: every
## `.tres` in `game/economy/upgrades/` (listed()), each at its cell of the menu.
##
## `buy` is refused, in the old order, when the Upgrade is unknown, hidden (co-op only in single player:
## Solo, not a Host before anyone joins, Q1357, Q1399), at its top level, not built ("Coming soon", no
## stat, Q1272, Q2669), locked (a need below its level) or too dear (the buyer's landed Coins, Q2672, or
## the team's Drawers); else one answer pays through the Bank's `spent_patch` and raises the level.
##
## A feature reads an effect with value(stat, player): the stat's value at the summed levels of every
## Upgrade naming it (Personal ones the player's, House ones the team's). Every machine turns applied
## answers into `bought`, tells everyone but the buyer "<name> bought <Upgrade>" (Q243), and watches for
## its own player's Upgrades becoming buyable (`affordable`).
class_name Upgrades
extends Part

## Player `player` (a peer number) bought the next level of `upgrade`. Every machine, from the answer.
signal bought(player: int, upgrade: Upgrade)
## This machine's player `player` can buy `upgrade` now, and could not at the last look.
signal affordable(player: int, upgrade: Upgrade)
## The Host refused player `player`'s purchase of `upgrade` (null: unknown), saying `says`. Every machine.
signal refused(player: int, upgrade: Upgrade, says: String)

## The group the level's Upgrades are in.
const GROUP := &"upgrades"
## Where the Upgrades are: every resource file in it is one, its id its stem.
const FOLDER := "res://game/economy/upgrades/"
const BUY := &"buy"
const SET_LEVEL := &"set_level"
## The refusals, in the order they are tested.
const UNKNOWN := "wrong"
const HIDDEN := "hidden"
const MAXED := "maxed"
const SOON := "soon"
const LOCKED := "locked"
const POOR := "poor"
## The old words of the refusals ("poor" names its currency and the price: NEED).
const SAYS := {HIDDEN: "Co-op only", MAXED: "Maxed out", SOON: "Coming soon", LOCKED: "Locked"}
const NEED := "Need %s %d"
## The teammate line's rest after the name, and the name when the Roster has none.
const BOUGHT := "bought %s"
const TEAMMATE := "A teammate"
## How often each machine looks whether its player can buy something new, in seconds.
const CHECK_EVERY := 0.25

## The Bank that is paid from (its Coins keys are this Part's player keys too).
@export var bank: Bank
## The teammate line's time.
@export var menu_tuning: UpgradeMenuTuning = preload("res://game/ui/upgrade_menu/upgrade_menu_tuning.tres")

@export_group("State")
## Each player's Personal levels: {player id: {upgrade id: level}}.
@export var personal := {}
## The team's House levels: {upgrade id: level}.
@export var house := {}
## The zoo's "Co-op" switch: counts as co-op though alone (shows the co-op-only Upgrades). Not saved.
@export var coop := false
@export_group("")

## The Upgrades in FOLDER, read once per run (sorted by file name).
static var _listed: Array[Upgrade] = []

## The ids this machine's player could buy at the last look (null before the first).
var _buyable: Variant = null
var _since_check := 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


## The Upgrades of `node`'s level (the one sharing its Parts), else the first in the tree, or null.
static func of(node: Node) -> Upgrades:
	if node == null or not node.is_inside_tree():
		return null
	var first: Upgrades = null
	var p: Parts = (node as Part).parts if node is Part else null
	for u in node.get_tree().get_nodes_in_group(GROUP):
		if first == null:
			first = u as Upgrades
		if p != null and (u as Upgrades).parts == p:
			return u as Upgrades
	return first


## Every Upgrade in the folder, sorted by file name: a new `.tres` dropped there is listed with no
## other change (ResourceLoader.list_directory() lists an exported build's remapped files too).
static func listed() -> Array[Upgrade]:
	if _listed.is_empty():
		var files := Array(ResourceLoader.list_directory(FOLDER))
		files.sort()
		for f: String in files:
			if f.ends_with(".tres") or f.ends_with(".res"):
				var u := load(FOLDER + f) as Upgrade
				if u != null:
					_listed.append(u)
	return _listed


## The Upgrade whose id is `id`, or null.
static func find_upgrade(id: StringName) -> Upgrade:
	for u in listed():
		if u.id() == id:
			return u
	return null


# --- Reading -------------------------------------------------------------------------------------

## Player `by`'s (a peer number) level of `upgrade`: theirs for a Personal one, the team's for a House one.
func level(upgrade: Upgrade, by: int) -> int:
	if upgrade == null:
		return 0
	var id := String(upgrade.id())
	if upgrade.is_house():
		return int(house.get(id, 0))
	return int(_levels_of(personal, by).get(id, 0))


## The value of `stat` for player `by`: at the summed levels of every Upgrade naming it.
func value(stat: UpgradeStat, by: int) -> float:
	return stat.value_at(stat_level(stat, by)) if stat != null else 0.0


## The summed levels for player `by` of every Upgrade naming `stat`.
func stat_level(stat: UpgradeStat, by: int) -> int:
	var n := 0
	for u in listed():
		if u.stat == stat:
			n += level(u, by)
	return n


## Whether the game counts as co-op: the zoo's switch, a session open (a Host before anyone joins
## too, Q1399, or a Guest), or more than one player in the Roster.
func is_coop() -> bool:
	if coop:
		return true
	var link := GameLink.of(self)
	if link == null:
		return false
	return (link.session != null and link.session.is_online()) or (link.roster != null and link.roster.peers().size() > 1)


## Whether `upgrade` shows and may be bought here (a co-op-only one only in co-op).
func shown(upgrade: Upgrade) -> bool:
	return upgrade != null and (not upgrade.coop_only or is_coop())


## Whether player `by` has every Upgrade `upgrade` needs at the level it needs.
func is_open(upgrade: Upgrade, by: int) -> bool:
	for need: Upgrade in upgrade.needs:
		if level(need, by) < int(upgrade.needs[need]):
			return false
	return true


## Why player `by` may not buy the next level of `upgrade` with `funds` of its money ("" when they
## may): the refusals in their old order.
func refusal(upgrade: Upgrade, by: int, funds: int) -> String:
	if upgrade == null:
		return UNKNOWN
	if not shown(upgrade):
		return HIDDEN
	var lv := level(upgrade, by)
	if lv >= upgrade.top():
		return MAXED
	if upgrade.stat == null:
		return SOON
	if not is_open(upgrade, by):
		return LOCKED
	if funds < upgrade.price_after(lv):
		return POOR
	return ""


## The money player `by` may spend on `upgrade` now, on the Host: the landed Coins (Q2672) or the
## team's Drawers.
func funds(upgrade: Upgrade, by: int) -> int:
	if bank == null:
		return 0
	return bank.drawers if upgrade.is_house() else bank.spendable(by)


## The money this machine shows player `by` (looks only: the Coins minus what still flies here).
func shown_funds(upgrade: Upgrade, by: int) -> int:
	if bank == null:
		return 0
	return bank.drawers if upgrade.is_house() else bank.of_player(by) - bank.in_flight(by)


## What the buyer reads for a refusal `why` of `upgrade` at `price`: the old words, "Need Coins 120"
## for one too dear; "" for none.
func says(why: String, upgrade: Upgrade, price: int) -> String:
	if why == POOR and upgrade != null and bank != null:
		var currency := bank.drawers_currency if upgrade.is_house() else bank.coins_currency
		return NEED % [currency.name if currency != null else "", price]
	return String(SAYS.get(why, ""))


# --- Verbs ---------------------------------------------------------------------------------------

## This machine's player asks to buy the next level of `upgrade`.
func ask_buy(upgrade: Upgrade, by: int) -> void:
	parts.ask(Command.new(BUY, by, id, {"upgrade": String(upgrade.id())}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {BUY: {"args": {"upgrade": {"type": TYPE_STRING, "max": 64}}, "rate": 10}}


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		BUY:
			return _decide_buy(cmd)
		SET_LEVEL:
			if cmd.by != Parts.HOST:
				return refuse("wrong")
			var u := find_upgrade(StringName(String(cmd.args.get("upgrade", ""))))
			if u == null:
				return refuse(UNKNOWN)
			var to := clampi(int(cmd.args.get("level", 0)), 0, u.top())
			return grant(_level_patch(u, int(cmd.args.get("player", Parts.HOST)), to))
	return refuse("wrong")


func _decide_buy(cmd: Command) -> Dictionary:
	var u := find_upgrade(StringName(String(cmd.args.get("upgrade", ""))))
	var price := u.price_after(level(u, cmd.by)) if u != null else -1
	var why := refusal(u, cmd.by, funds(u, cmd.by) if u != null else 0) if bank != null else UNKNOWN
	var ev: Dictionary
	if why != "":
		ev = refuse(why)
	else:
		ev = grant(_level_patch(u, cmd.by, level(u, cmd.by) + 1))
		var house_buy := u.is_house()
		(ev["changes"] as Dictionary)[bank.id] = bank.spent_patch(cmd.by, 0 if house_buy else price, price if house_buy else 0)
	ev["upgrade"] = String(cmd.args.get("upgrade", ""))
	ev["price"] = price
	return ev


## The change that sets player `by`'s level of `upgrade` (the team's for a House one) to `to`.
func _level_patch(upgrade: Upgrade, by: int, to: int) -> Dictionary:
	var uid := String(upgrade.id())
	if upgrade.is_house():
		var h := house.duplicate()
		h[uid] = to
		return {"house": h}
	var p := personal.duplicate(true)
	var key: Variant = bank.key_of(by) if bank != null else by
	var mine: Dictionary = (p.get(key, p.get(by, {})) as Dictionary).duplicate()
	p.erase(by)
	mine[uid] = to
	p[key] = mine
	return {"personal": p}


## What a save keeps: the levels; never the zoo's switch.
func save_state() -> Dictionary:
	return {"personal": personal, "house": house}


## Bound: it hears every applied answer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_on_applied):
		parts.applied.connect(_on_applied)


## Every machine: a purchase answered becomes `bought` or `refused`; everyone but the buyer reads
## "<name> bought <Upgrade>".
func _on_applied(ev: Dictionary) -> void:
	if StringName(ev.get("to", &"")) != id or StringName(ev.get("kind", &"")) != BUY:
		return
	var by := int(ev.get("by", Parts.HOST))
	var u := find_upgrade(StringName(String(ev.get("upgrade", ""))))
	if not ev.get("ok", false):
		refused.emit(by, u, says(String(ev.get("reason", "")), u, int(ev.get("price", 0))))
		return
	bought.emit(by, u)
	if by != _me():
		_tell_teammate(by, u)


func _tell_teammate(by: int, upgrade: Upgrade) -> void:
	var player := _local_player()
	if player == null or upgrade == null:
		return
	var link := GameLink.of(self)
	var roster := link.roster if link != null else null
	var who := TEAMMATE
	var colour := Color.WHITE
	if roster != null and not roster.entry_of(by).is_empty():
		who = roster.name_of(by)
		colour = roster.colour_of(by)
	player.announce(who, colour, BOUGHT % upgrade.title, menu_tuning.news_time)


## Every machine: now and then, whether its own player can buy an Upgrade it could not before.
func _process(delta: float) -> void:
	_since_check += delta
	if _since_check < CHECK_EVERY or parts == null:
		return
	_since_check = 0.0
	var me := _me()
	var now := {}
	for u in listed():
		if refusal(u, me, shown_funds(u, me)) == "":
			now[u.id()] = true
	if _buyable is Dictionary:
		for u in listed():
			if now.has(u.id()) and not (_buyable as Dictionary).has(u.id()):
				affordable.emit(me, u)
	_buyable = now


## This machine's player id.
func _me() -> int:
	return multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST


## This machine's Player (the one on this Part's multiplayer), or null.
func _local_player() -> Player:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group(&"local_input"):
		if node is Player and node.multiplayer == multiplayer:
			return node as Player
	return null


## The levels of player `by` in `levels` (keyed as the Bank keys Coins).
func _levels_of(levels: Dictionary, by: int) -> Dictionary:
	var key: Variant = bank.key_of(by) if bank != null else by
	return levels.get(key, levels.get(by, {})) as Dictionary
