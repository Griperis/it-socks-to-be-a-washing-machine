## One Collection's Cabinet (core/04): it takes that Collection's Pairs into its drawers and pays the
## shelver. The drawers are its children `Drawer1..DrawerN` (bottom first), instances of
## drawer.tscn, each opened and shut by the kit's own Openable. This Part holds the Collection,
## whether the Cabinet is locked, how many Rows (drawers, from the bottom) are in use, and the shelf:
## each drawer's shelved Pairs (their leads), in the order they went in.
##
## A click on a drawer (click()) while holding Pairs, or on a locked Cabinet, asks `shelve`; with
## empty Hands (or only loose Socks) it is the drawer's own Openable.use (C04). A granted `shelve`
## changes five Parts in one answer: the Hands (the Pairs leave, the rest kept: C02), the Mess (the
## leads go SHELVED), this shelf (the aimed drawer, then the nearest with room, the lower of two as
## near: C03), each drawer used (opens) and the Coins (10 x rarity a Pair, paid once per drawer used:
## C05, I.12). A thrown Pair that touches its own Cabinet is shelved by the Host's `thrown_shelve`
## (T05); any other touch asks nothing and the body bounces (T06, T07). No icon shows the
## Collection: the refusal tells it (C11).
class_name Cabinet
extends Part

## Why a shelve is refused, and what the player's HUD says for it.
const FAR := "far"
const LOCKED := "locked"
const WRONG := "wrong"
const FULL := "full"
const SAYS := {WRONG: "Wrong Cabinet", LOCKED: "Cabinet locked", FULL: "Cabinet full"}
## The drawers' node names (1 is the bottom) and the slot points in a drawer's Looks (1 to 25 in the
## model; Q2256: the capacity is the tuning's, a drawer draws only as many Pairs as it has slots).
const DRAWER := "Drawer%d"
const SLOT := "Slot%02d"
## What a shelved Pair's sock ball is called under its slot point.
const BALL := &"Ball"
## A shelved ball rests on the tray's floor, this high in the drawer (the old CabinetDrawer's), and
## the k-th is turned about the up axis by k golden angles, so no two lie alike.
const TRAY_FLOOR_Y := 0.04
const TURN := 2.39996
## The most drawers a shelve may aim at (a Guest's arg bound).
const DRAWERS_MAX := 64

## Links the wiring check lets stay empty: a Cabinet finds the level's Hands and Coins by group.
const WIRING_OPTIONAL := ["hands", "coins"]

@export var tuning: CabinetTuning
## The level's Hands (their Mess is the Mess) and Coins; empty, the first of each group.
@export var hands: Hands
@export var coins: Coins

@export_group("State")
## The Collection whose Pairs this Cabinet takes (a SockDesign.collection).
@export var collection := &"simple"
## A locked Cabinet takes nothing and its drawers stay shut (C08).
@export var locked := false
## How many drawers, from the bottom, are in use (Stage growth is M4).
@export_range(0, 64, 1) var rows := 2 # placeholder: the designer's number (today's start, Stage growth in M4)
## Each drawer's shelved Pairs (their lead Sock ids), bottom drawer first, in the order they went
## in: an Array of PackedInt32Array.
@export var shelf := []
@export_group("")

var _mess: Mess


func _ready() -> void:
	var mess := mess_of()
	if mess != null and not mess.flight_touched.is_connected(_on_flight_touched):
		mess.flight_touched.connect(_on_flight_touched)


## The Hands this Cabinet takes Pairs from.
func hands_of() -> Hands:
	if hands == null and is_inside_tree():
		hands = get_tree().get_first_node_in_group(Hands.GROUP) as Hands
	return hands


## The Coins it pays into.
func coins_of() -> Coins:
	if coins == null and is_inside_tree():
		coins = get_tree().get_first_node_in_group(Coins.GROUP) as Coins
	return coins


## The Mess whose Pairs it takes.
func mess_of() -> Mess:
	if _mess == null:
		var h := hands_of()
		_mess = h.mess if h != null else null
	return _mess


func tuning_of() -> CabinetTuning:
	if tuning == null:
		tuning = CabinetTuning.new()
	return tuning


## The Cabinet a part belongs to: itself, or the Cabinet whose drawer an Openable is; else null.
static func of(part: Part) -> Cabinet:
	if part is Cabinet:
		return part as Cabinet
	if part == null or part.get_parent() == null or part.get_parent().get_parent() == null:
		return null
	return Parts.part_of(part.get_parent().get_parent()) as Cabinet


## How many drawers it has (its Drawer1..N).
func drawer_count() -> int:
	var n := 0
	while get_parent() != null and get_parent().has_node(NodePath(DRAWER % (n + 1))):
		n += 1
	return n


## Drawer `index`'s Openable (0 is the bottom drawer), or null.
func drawer(index: int) -> Openable:
	if index < 0 or get_parent() == null:
		return null
	return get_parent().get_node_or_null(NodePath((DRAWER % (index + 1)) + "/Openable")) as Openable


## The index of the drawer whose Openable `openable` is, or -1.
func index_of(openable: Part) -> int:
	for i in drawer_count():
		if drawer(i) == openable:
			return i
	return -1


## The Pairs (leads) shelved in drawer `index`, in order.
func contents(index: int) -> PackedInt32Array:
	if index < 0 or index >= shelf.size() or not (shelf[index] is PackedInt32Array):
		return PackedInt32Array()
	return shelf[index]


## Every shelved Pair's lead, bottom drawer first.
func shelved() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in shelf.size():
		out.append_array(contents(i))
	return out


## How many drawers take Pairs now: the Rows, never more than the drawers there are.
func rows_in_use() -> int:
	return clampi(rows, 0, drawer_count())


## The drawer the next Pair aimed at drawer `aimed` goes into, with `counts` Pairs in each drawer:
## `aimed` while it has room, else the nearest with room, of two as near the lower (C03); aimed
## above the Rows, the search starts at the top Row. -1 when every Row is full.
func next_drawer(aimed: int, counts: Array[int]) -> int:
	var n := rows_in_use()
	var cap := tuning_of().drawer_capacity
	aimed = clampi(aimed, 0, maxi(n - 1, 0))
	for step in n:
		for index: int in [aimed - step, aimed + step]:
			if index >= 0 and index < n and counts[index] < cap:
				return index
	return -1


## Room left in all its Rows.
func room() -> int:
	var cap := tuning_of().drawer_capacity
	var left := 0
	for i in rows_in_use():
		left += maxi(cap - contents(i).size(), 0)
	return left


## Whether the Pair led by `sock` is of this Cabinet's Collection.
func takes(sock: int) -> bool:
	var mess := mess_of()
	var design := mess.design_of(sock) if mess != null else null
	return design != null and design.collection == collection


## Player `by`'s held Pairs (their leads) of this Cabinet's Collection, in the order held.
func held_pairs(by: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var h := hands_of()
	var mess := mess_of()
	if h == null or mess == null:
		return out
	for item in h.items_of(by):
		if mess.is_pair(item) and takes(item):
			out.append(item)
	return out


## Whether player `by` holds any Pair at all (of any Collection).
func holds_pair(by: int) -> bool:
	var h := hands_of()
	var mess := mess_of()
	if h == null or mess == null:
		return false
	for item in h.items_of(by):
		if mess.is_pair(item):
			return true
	return false


## A click on drawer `index` by player `by`: with Pairs held (or on a locked Cabinet) it asks to
## shelve into that drawer; with none it opens or shuts a drawer in use, as the drawer's own use.
func click(by: int, index: int) -> void:
	if locked or holds_pair(by):
		parts.ask(Command.new(&"shelve", by, id, {"drawer": maxi(index, 0)}))
	elif index >= 0 and index < rows_in_use():
		drawer(index).use(by)


## The use button on the Cabinet's body (between the drawers): a shelve into the bottom drawer
## with Pairs held; with none, nothing.
func use(by: int) -> void:
	if locked or holds_pair(by):
		click(by, 0)


## A Guest asks to shelve into a drawer, at most 5 a second; `thrown_shelve` is the Host's alone.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {&"shelve": {"args": {"drawer": {"type": TYPE_INT, "min": 0, "max": DRAWERS_MAX}}, "rate": 5}}


## Why player `by` may not shelve now, or "" when they may.
func shelve_refusal(by: int) -> String:
	var t := tuning_of()
	if parts != null and not parts.near(by, get_parent(), t.reach + t.reach_slack):
		return FAR
	# The old game's order (Q2285): Pairs held but none of this Collection say so before a lock.
	if held_pairs(by).is_empty() and holds_pair(by):
		return WRONG
	if locked:
		return LOCKED
	if held_pairs(by).is_empty():
		return WRONG
	if room() <= 0:
		return FULL
	return ""


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		&"shelve":
			var aimed: Variant = cmd.args.get("drawer")
			if not (aimed is int):
				return refuse("wrong")
			var why := shelve_refusal(cmd.by)
			if why != "":
				return refuse(why)
			return _shelve(held_pairs(cmd.by), aimed, cmd.by, true)
		&"thrown_shelve":
			var sock: Variant = cmd.args.get("sock")
			var thrower: Variant = cmd.args.get("thrower")
			if cmd.by != Parts.HOST or not (sock is int) or not (thrower is int):
				return refuse("wrong")
			if not _shelves_thrown(sock):
				return refuse("wrong")
			return _shelve(PackedInt32Array([sock]), 0, thrower, false)
	return refuse("wrong")


## Whether a flying Pair led by `sock` would shelve itself on touching this Cabinet: its own
## Collection's, unlocked, with room (T05; else it bounces: T06, T07).
func _shelves_thrown(sock: int) -> bool:
	var mess := mess_of()
	return mess != null and mess.is_pair(sock) and mess.state_of(sock) == Mess.State.FLYING \
			and takes(sock) and not locked and room() > 0


## The answer that shelves `leads` (in order) starting at drawer `aimed`, paying player `by`; with
## `from_hands` they leave `by`'s Hands. What finds no room stays where it is.
func _shelve(leads: PackedInt32Array, aimed: int, by: int, from_hands: bool) -> Dictionary:
	var mess := mess_of()
	var t := tuning_of()
	var counts: Array[int] = []
	var new_shelf := []
	for i in drawer_count():
		counts.append(contents(i).size())
		new_shelf.append(contents(i).duplicate())
	var taken := PackedInt32Array()
	var paid: Array[Dictionary] = []
	var total := 0
	for lead in leads:
		var index := next_drawer(aimed, counts)
		if index < 0:
			break
		counts[index] += 1
		var into: PackedInt32Array = new_shelf[index]
		into.append(lead)
		new_shelf[index] = into
		taken.append(lead)
		var coins_for := t.pay_for(int(mess.design_of(lead).rarity))
		total += coins_for
		if paid.is_empty() or int(paid.back()["drawer"]) != index:
			paid.append({"drawer": index, "coins": 0})
		paid.back()["coins"] = int(paid.back()["coins"]) + coins_for
	# A drawer is left only once it is full, so each drawer used is one payment (I.12).
	var changes := {id: {"shelf": new_shelf}, mess.id: mess.shelved_patch(taken)}
	if from_hands:
		changes[hands_of().id] = hands_of().taken_patch(by, taken)
	var bank := coins_of()
	if bank != null and total > 0:
		changes[bank.id] = bank.paid_patch(by, total)
	for p in paid:
		var openable := drawer(int(p["drawer"]))
		if openable != null and not openable.open:
			changes[openable.id] = {"open": true}
	return {"ok": true, "shelved": taken, "paid": paid, "payee": by, "changes": changes}


## The Host: a falling body touched something. A thrown Pair of this Collection touching this
## Cabinet asks `thrown_shelve` after the physics step (no body is swapped inside it).
func _on_flight_touched(sock: int, other: Node) -> void:
	if parts == null or not parts.is_host() or other == null or not _owns(other):
		return
	var mess := mess_of()
	if not mess.throws.has(sock) or not _shelves_thrown(sock):
		return
	var thrower := int((mess.throws[sock] as Dictionary).get("by", Parts.HOST))
	parts.ask.call_deferred(Command.new(&"thrown_shelve", Parts.HOST, id, {"sock": sock, "thrower": thrower}))


func _owns(node: Node) -> bool:
	var root := get_parent()
	return root != null and (node == root or root.is_ancestor_of(node))


## Draws each drawer's shelved Pairs as sock balls at its slot points, in shelving order; a drawer
## holding more Pairs than it has slots draws the first ones.
func _show(_now: bool) -> void:
	var mess := mess_of()
	for i in drawer_count():
		var looks := get_parent().get_node_or_null(NodePath((DRAWER % (i + 1)) + "/Looks"))
		if looks == null:
			continue
		var held := contents(i)
		var j := 0
		while true:
			var slot := looks.find_child(SLOT % (j + 1), true, false) as Node3D
			if slot == null:
				break
			var want := held[j] if j < held.size() else -1
			var ball := slot.get_node_or_null(NodePath(BALL)) as Node3D
			if ball != null and int(ball.get_meta(Mess.SOCK_META, -1)) != want:
				slot.remove_child(ball)
				ball.queue_free()
				ball = null
			if ball == null and want >= 0 and mess != null:
				ball = SockDress.make(mess.design_of(want), SockDress.LYING, true)
				ball.name = BALL
				ball.set_meta(Mess.SOCK_META, want)
				slot.add_child(ball)
				ball.position = Vector3(0.0, TRAY_FLOOR_Y + SockDress.ball_radius(mess.design_of(want)) - slot.position.y, 0.0)
				ball.rotation.y = fposmod(j * TURN, TAU)
			j += 1
