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
## C05, I.12). A thrown Pair that touches one of its own Cabinet's drawer fronts is shelved by the Host's `thrown_shelve`
## (T05); any other touch asks nothing and the body bounces (T06, T07). No icon shows the
## Collection: the refusal tells it (C11).
##
## A Cabinet that wears a dust sheet (a DustSheet child of its root) shows it draped while it is locked
## and pulled off when it is unlocked (assets/07); while sheeted neither it nor its drawers can be aimed
## at (Q2513: no outline, no prompt, no click).
##
## Its Looks and its drawers' Looks are its Collection's (assets/02, K01): `looks_<collection>.tscn`
## in this folder and in the drawer's, swapped in by dress() when the Cabinet is ready and whenever
## its state shows; a Collection without its own Looks keeps the one in the scene.
class_name Cabinet
extends Part

## Why a shelve is refused (too far is the Hands' own Hands.FAR), and what the player's HUD says for it.
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

## Where each Collection's Looks are: the Cabinet's (base, segments, top) and its drawers'.
const CABINET_LOOKS := "res://game/entities/cabinet/looks_%s.tscn"
const DRAWER_LOOKS := "res://game/entities/drawer/looks_%s.tscn"
const LOOKS := &"Looks"
## How a shelving flight lands in its slot: the falling Pair's squash, hop and roll (core/27 P10).
const BALL_LANDING := preload("res://game/sock/ball_landing_tuning.tres")

## A sheeted Cabinet's dust sheet (assets/07, Q2507): a DustSheet child of its root by this name,
## draped while it is locked and pulled off on the unlock.
const DUST_SHEET := ^"../DustSheet"
## Links the wiring check lets stay empty: a Cabinet finds the level's Hands and Coins by group.
const WIRING_OPTIONAL := ["hands", "coins"]
## Every Cabinet is in this group (the run's Stages finds the ones of its level by it).
const GROUP := &"cabinets"

@export var tuning: CabinetTuning
## The level's Hands (their Mess is the Mess) and Coins; empty, the first of each group.
@export var hands: Hands
@export var coins: Coins
## The Stage that unlocks it (1 is the basement's; the garage's 2, Q1463). Read only in a level with a
## run (docs/architecture/stages.md).
@export_range(1, 16, 1) var unlock_stage := 1

@export_group("State")
## The Collection whose Pairs this Cabinet takes (a SockDesign.collection).
@export var collection := &"simple"
## A locked Cabinet takes nothing and its drawers stay shut (C08).
@export var locked := false
## How many drawers, from the bottom, are in use (Stage growth is M4).
@export_range(0, 64, 1) var rows := 2 # placeholder: a level with no run keeps it; a run sets it (StagePlan.start_rows)
## Each drawer's shelved Pairs (their lead Sock ids), bottom drawer first, in the order they went
## in: an Array of PackedInt32Array.
@export var shelf := []
@export_group("")

var _mess: Mess
## Shelving flights still on their way into each drawer, and the balls waiting for them to land, by
## drawer index (D11).
var _pending: Dictionary[int, int] = {}
var _waiting: Dictionary[int, Array] = {}
## The drawers' Openables (bottom first) and each drawer's slot points, found once by dress() and
## again whenever it swaps a Looks.
var _drawers: Array[Openable] = []
var _slots: Array[Array] = []
var _found := false
## The run's Stages of its level (they set it as they enter), or null in a level with no run: the Row's
## capacity is then the tuning's `drawer_capacity`.
var stages: Stages = null
## How it stands at its Rows and drops a new Drawer in (core/81).
var growth := CabinetGrowth.new(self)


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	var mess := mess_of()
	if mess != null and not mess.flight_touched.is_connected(_on_flight_touched):
		mess.flight_touched.connect(_on_flight_touched)
	# Its siblings (the Looks, the drawers) can be swapped only once the Cabinet's root is ready.
	var root := get_parent()
	if root.is_node_ready():
		dress()
	elif not root.ready.is_connected(dress):
		root.ready.connect(dress, CONNECT_ONE_SHOT)


## The Looks scene of Collection `of` for the Cabinet (`for_drawer` false) or a drawer, or "" when
## that Collection has none of its own.
static func looks_path(of: StringName, for_drawer: bool) -> String:
	var path := (DRAWER_LOOKS if for_drawer else CABINET_LOOKS) % of
	return path if ResourceLoader.exists(path) else ""


## Puts its Collection's Looks on the Cabinet and on every drawer, in place of the ones there (same
## name, same place among the siblings). Looks only: a Looks already the Collection's is kept.
func dress() -> void:
	var root := get_parent()
	_put_looks(root, looks_path(collection, false))
	var drawer_looks := looks_path(collection, true)
	_find_drawers()
	for i in _drawers.size():
		# A new drawer Looks starts shut: it is put in its drawer's pose at once.
		if _put_looks(root.get_node(NodePath(DRAWER % (i + 1))), drawer_looks):
			_drawers[i]._show(true)
	_find_slots()


## Finds the drawers once (Drawer1..N, each with its Openable; the first gap ends the row).
func _find_drawers() -> void:
	_drawers.clear()
	var root := get_parent()
	if root == null:
		return
	var n := 1
	while root.has_node(NodePath(DRAWER % n)):
		_drawers.append(root.get_node_or_null(NodePath((DRAWER % n) + "/Openable")) as Openable)
		n += 1
	_found = true


## Finds each drawer's slot points (Slot01..) in its Looks once.
func _find_slots() -> void:
	_slots.clear()
	var root := get_parent()
	for i in _drawers.size():
		var found: Array[Node3D] = []
		var looks := root.get_node_or_null(NodePath((DRAWER % (i + 1)) + "/" + String(LOOKS)))
		if looks != null:
			var j := 1
			var slot := looks.find_child(SLOT % j, true, false) as Node3D
			while slot != null:
				found.append(slot)
				j += 1
				slot = looks.find_child(SLOT % j, true, false) as Node3D
		_slots.append(found)


## The answer that sets the lock and the Rows in use: this Cabinet's state and each drawer's `locked`
## (a drawer is shut to every player while the Cabinet is locked or the drawer is above its Rows: the
## Host refuses an `open` straight at the drawer, R1). Pass it to Parts.load_snapshot or grant it.
func lock_patch(now_locked: bool, now_rows: int) -> Dictionary:
	var changes := {id: {"locked": now_locked, "rows": now_rows}}
	var in_use := clampi(now_rows, 0, drawer_count())
	for i in drawer_count():
		var d := drawer(i)
		if d != null:
			changes[d.id] = {"locked": now_locked or i >= in_use}
	return changes


## Swaps `owner_node`'s Looks for the scene at `path`; true when it did.
func _put_looks(owner_node: Node, path: String) -> bool:
	var old := owner_node.get_node_or_null(NodePath(LOOKS)) as Node3D
	if path.is_empty() or old == null or old.scene_file_path == path:
		return false
	var looks := (load(path) as PackedScene).instantiate() as Node3D
	looks.transform = old.transform
	var at := old.get_index()
	owner_node.remove_child(old)
	old.queue_free()
	looks.name = LOOKS
	owner_node.add_child(looks)
	owner_node.move_child(looks, at)
	return true


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
	assert(tuning != null, "Cabinet: its CabinetTuning (`tuning`) is not set")
	return tuning


## The Cabinet a part belongs to: itself, or the Cabinet whose drawer an Openable is; else null.
static func of(part: Part) -> Cabinet:
	if part is Cabinet:
		return part as Cabinet
	if part == null or part.get_parent() == null or part.get_parent().get_parent() == null:
		return null
	return Parts.part_of(part.get_parent().get_parent()) as Cabinet


## Whether it stands under its dust sheet: a DustSheet child and locked (assets/07).
func sheeted() -> bool:
	return locked and get_node_or_null(DUST_SHEET) is DustSheet


## Under its dust sheet the crosshair passes it by (Q2513, the old cabinet.gd set_covered).
func aimable() -> bool:
	return not sheeted()


## How many drawers it has (its Drawer1..N).
func drawer_count() -> int:
	if not _found:
		_find_drawers()
	return _drawers.size()


## Drawer `index`'s Openable (0 is the bottom drawer), or null.
func drawer(index: int) -> Openable:
	if not _found:
		_find_drawers()
	if index < 0 or index >= _drawers.size():
		return null
	return _drawers[index]


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


## The Pairs a Drawer holds: the run's (its World's Pairs per Drawer) in a level with one, else the
## tuning's.
func per_drawer() -> int:
	return stages.pairs_per_drawer if stages != null and stages.pairs_per_drawer > 0 else tuning_of().drawer_capacity


## How many Designs its Collection has; 0 when unknown (no Mess yet).
func designs_count() -> int:
	var mess := mess_of()
	return mess.catalogue.count_of(collection) if mess != null and mess.catalogue != null else 0


## The Pairs Row `index` takes (0 is the bottom): a Drawer's worth, the Collection's last Row only the
## Designs left (Simple's sixth at 25: 5; CB:203-216), none past it.
func row_capacity(index: int) -> int:
	return row_capacity_at(index, per_drawer())


## Row `index`'s capacity at `per` Pairs per Drawer (a run deciding a new Drawer size).
func row_capacity_at(index: int, per: int) -> int:
	var count := designs_count()
	if count <= 0:
		return per
	return clampi(count - index * per, 0, per)


## Its full height: its Collection's Designs over the Pairs per Drawer, rounded up (Q641).
func full_height() -> int:
	return full_height_at(per_drawer())


## Its full height at `per` Pairs per Drawer.
func full_height_at(per: int) -> int:
	var count := designs_count()
	if count <= 0 or per <= 0:
		return drawer_count()
	return ceili(float(count) / per)


## Whether Row `index` holds all it takes.
func row_full(index: int) -> bool:
	return contents(index).size() >= row_capacity(index)


## How many drawers take Pairs now: the Rows, never more than the drawers there are.
func rows_in_use() -> int:
	return clampi(rows, 0, drawer_count())


## The drawer the next Pair aimed at drawer `aimed` goes into, with `counts` Pairs in each drawer:
## `aimed` while it has room, else the nearest with room, of two as near the lower (C03); aimed
## above the Rows, the search starts at the top Row. -1 when every Row is full.
func next_drawer(aimed: int, counts: Array[int]) -> int:
	var n := rows_in_use()
	aimed = clampi(aimed, 0, maxi(n - 1, 0))
	for step in n:
		for index: int in [aimed - step, aimed + step]:
			if index >= 0 and index < n and counts[index] < row_capacity(index):
				return index
	return -1


## Room left in all its Rows.
func room() -> int:
	var left := 0
	for i in rows_in_use():
		left += maxi(row_capacity(i) - contents(i).size(), 0)
	return left


## Whether drawer `index` takes another Pair: a Row in use, not full (the old game's has_room).
func has_room(index: int) -> bool:
	return index >= 0 and index < rows_in_use() and contents(index).size() < row_capacity(index)


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


## The use button on the Cabinet's body (its frame between the drawers): nothing, only a drawer takes
## a shelve (R07, the old game: only a CabinetDrawer is a Station).
func use(_by: int) -> void:
	pass


## A Guest asks to shelve into a drawer, at most 5 a second; `thrown_shelve` is the Host's alone.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {&"shelve": {"args": {"drawer": {"type": TYPE_INT, "min": 0, "max": DRAWERS_MAX}}, "rate": 5}}


## Why player `by` may not shelve now, or "" when they may.
func shelve_refusal(by: int) -> String:
	var t := tuning_of()
	if parts != null and not parts.near(by, get_parent(), t.reach + t.reach_slack):
		return Hands.FAR
	# The old game's order (Q2285): Pairs held but none of this Collection say so before a lock.
	var none_of_mine := held_pairs(by).is_empty()
	if none_of_mine and holds_pair(by):
		return WRONG
	if locked:
		return LOCKED
	if none_of_mine:
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
	if parts == null or not parts.is_host() or other == null or not _is_drawer_front(other):
		return
	var mess := mess_of()
	if not mess.throws.has(sock) or (mess.throws[sock] as Dictionary).get("drop", false) or not _shelves_thrown(sock):
		return
	var thrower := int((mess.throws[sock] as Dictionary).get("by", Parts.HOST))
	parts.ask.call_deferred(Command.new(&"thrown_shelve", Parts.HOST, id, {"sock": sock, "thrower": thrower}))


## Whether `node` is part of a drawer in use (a drawer front): the Cabinet's top, sides and frame
## are not (R06, the old game's Station boxes).
func _is_drawer_front(node: Node) -> bool:
	var root := get_parent()
	if root == null:
		return false
	for i in rows_in_use():
		var d := drawer(i).get_parent() if drawer(i) != null else null
		if d != null and (node == d or d.is_ancestor_of(node)):
			return true
	return false


## Draws each drawer's shelved Pairs as sock balls at its slot points, in shelving order; a drawer
## holding more Pairs than it has slots draws the first ones. A Pair newly shelved from Hands drawn
## on this machine flies from where they drew it to its slot first, and the drawer shows its new
## balls when all its flights have landed (D11).
func _show(now: bool) -> void:
	if get_parent().is_node_ready():
		dress()
		growth.follow(rows, now)
	var sheet := get_node_or_null(DUST_SHEET) as DustSheet
	if sheet != null and sheet.is_node_ready():
		sheet.follow(locked, now)
	var mess := mess_of()
	if _slots.size() != drawer_count():
		_find_slots()
	for i in _slots.size():
		var held := contents(i)
		var j := 0
		for slot: Node3D in _slots[i]:
			if not is_instance_valid(slot):
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
				var from: Variant = null if now else _drawn_from(want)
				if from is Transform3D:
					_fly(i, j, ball, from)
			j += 1


## How many shelving flights are still on their way into each drawer, by drawer index.
func flights_into(index: int) -> int:
	return _pending.get(index, 0)


## Where Pair `sock` is drawn on this machine now, or null: in Hands here (D11), or flying as a
## thrown body that touched a drawer front (core/27 P11, Q2316: its flight goes on to its slot).
func _drawn_from(sock: int) -> Variant:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group(HeldView.GROUP):
		var at: Variant = (node as HeldView).drawn_of(sock)
		if at is Transform3D:
			return at
	var mess := mess_of()
	return mess.drawn_flight_of(sock) if mess != null else null


## Flies a copy of shelved `ball` (slot `slot` of drawer `index`) from `from` to it, on an arc, in
## `flight_time` plus `flight_step` for each slot before it; the ball itself shows when every
## flight into that drawer has landed (D11). It lands where the ball is then, the drawer sliding:
## `roll_distance` short of it, squashing, then hops and rolls on to it and squashes again
## (core/27 P10, the old sock_ball.gd launch()).
func _fly(index: int, slot: int, ball: Node3D, from: Transform3D) -> void:
	var t := tuning_of()
	var mess := mess_of()
	var design := mess.design_of(int(ball.get_meta(Mess.SOCK_META)))
	var flier := SockDress.make(design, SockDress.LYING, true)
	flier.name = Mess.FLIGHT_NAME % int(ball.get_meta(Mess.SOCK_META))
	flier.top_level = true
	var landing := BallLanding.new()
	landing.name = "BallLanding"
	landing.tuning = BALL_LANDING
	landing.radius = SockDress.ball_radius(design)
	flier.add_child(landing)
	get_parent().add_child(flier)
	flier.global_transform = from
	ball.visible = false
	var waiting: Array = _waiting.get(index, [])
	waiting.append(ball)
	_waiting[index] = waiting
	_pending[index] = int(_pending.get(index, 0)) + 1
	var lt := landing.tuning
	var step := func(u: float) -> void:
		if not is_instance_valid(ball) or not ball.is_inside_tree():
			return
		var to := _short_of(ball.global_transform, from, lt.roll_distance)
		var at := from.interpolate_with(to, u)
		at.origin = from.origin.lerp(to.origin, u) + Vector3.UP * (4.0 * t.flight_arc * u * (1.0 - u))
		flier.global_transform = at
	var roll := func(u: float) -> void:
		if not is_instance_valid(ball) or not ball.is_inside_tree():
			return
		var to := ball.global_transform
		var short := _short_of(to, from, lt.roll_distance)
		var way := to.origin - short.origin
		var axis := Vector3.UP.cross(way).normalized() if way.length() > 0.0001 else Vector3.ZERO
		var size := to.basis.get_scale().x
		var angle := way.length() / maxf(landing.radius * size, 0.001)
		var spin := Basis(axis, angle * (u - 1.0)) if axis != Vector3.ZERO else Basis.IDENTITY
		var turn := to.basis.orthonormalized()
		flier.global_transform = Transform3D((spin * turn).scaled(Vector3.ONE * size), short.origin.lerp(to.origin, u))
	var tween := flier.create_tween()
	tween.tween_method(step, 0.0, 1.0, t.flight_time + t.flight_step * slot)
	tween.tween_callback(landing.land)
	tween.tween_method(roll, 0.0, 1.0, lt.bounce_time)
	tween.tween_interval(lt.squash_time)
	tween.tween_callback(_landed.bind(index, flier))


## Where a ball flying from `from` to rest at `to` lands: `roll` short of it along the flight's flat
## way, less than half that way when it is short; turned and sized as at rest.
static func _short_of(to: Transform3D, from: Transform3D, roll: float) -> Transform3D:
	var flat := Vector3(to.origin.x - from.origin.x, 0.0, to.origin.z - from.origin.z)
	var dir := flat.normalized() if flat.length() > 0.001 else Vector3.ZERO
	return Transform3D(to.basis, to.origin - dir * minf(roll, flat.length() * 0.5))


## A shelving flight into drawer `index` landed: once none is left, its waiting balls show.
func _landed(index: int, flier: Node3D) -> void:
	flier.queue_free()
	_pending[index] = int(_pending.get(index, 1)) - 1
	if _pending[index] > 0:
		return
	_pending.erase(index)
	for ball: Variant in _waiting.get(index, []):
		if is_instance_valid(ball):
			(ball as Node3D).visible = true
	_waiting.erase(index)
