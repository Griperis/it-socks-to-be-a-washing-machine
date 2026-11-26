## The Socks in this player's Hands, drawn in front of the camera (a child of it). The active item
## hangs big right of centre, the others tucked small to the left (H06). While zoomed (H21) the
## tucked items keep their screen size and place and the active one comes close and large; while
## turning (H22) the active item spins about its long axis and keeps its angle when let go. A
## dropped or thrown Sock's body leaves from where it hung (Q2356, Q2367): its drawn Looks takes over
## there, growing from the hand's size to its own over `let_go_grow`. A held
## Pair is one sock ball, `ball_scale` times a Sock's size (P06); a Sock that becomes a Pair in
## these Hands plays the pairing moment (pair_moment.tscn, P05) at the ball's place, over a hidden
## ball, once; a whole Pair picked up plays none, and a Pair let go ends its moment.
##
## When the active item changes (the wheel, a pick, a drop, a pairing) every held item glides to its
## new place (D08); the turn and the zoom go on top, unglided. A picked item flies up from where it
## lay on a small hop (D09), and the pairing moment's second Sock flies in from where it lay the same
## way (D10). A held Sock's cloth bends by itself (SockCloth, D01-D03); a thrown one leaves with the
## bend it had here (core/27 P08), and the held readout follows the active Sock's sway (P03, sway()).
##
## Worn (coop/05, Q2464): a Teammate's Hands, hung from `anchor` (their avatar's HoldPoint) instead of
## in front of a camera: true size, the active item right at the HoldPoint and the others clustered
## close round it, a `worn_step` further each, left then right; a held Sock by its cuff, toe down, its
## side to the front; a Pair as the ball just under it. Others never see the turn or the zoom (Q2454),
## and a pairing there plays no moment: the ball flies in from where the picked mate lay and, as it
## reaches the hand, a small sparkle burst and ring play there (MateSparkle, behaviour 60).
##
## Handed over or caught (core/42): the item flies in the same way, from where pick_from() says (the
## giver's hand as drawn on this machine, or where the Throw hit), flat and turned at random.
##
## A Guest's guesses (coop/09, GuestGhosts asks them): a pick's ghost flies up from where the Sock lay
## to the active place (or to its held mate) at once and becomes the held item on the Host's answer
## with no pop, or flies back (F01-F03); a Throw's or a drop's item is hidden at once and shown again
## if refused (Q2476); the wheel's turn shows at once and goes back if refused (Q2475).
##
## Looks of this machine only: it reads the Hands and the Mess, never writes them. Ported from the
## old game's held_view.gd (its layout numbers, its depth trick, its zoom, its glide and fly-up).
class_name HeldView
extends Node3D

## A refused pick's ghost has flown back and is gone: the Sock may be drawn where it is again.
signal ghost_returned(sock: int)

## The group every HeldView is in: a Cabinet finds there where a shelved Pair was drawn (D11).
const GROUP := &"held_views"
## A held Sock hangs by its cuff, toe down, turned a little to show its side (the old HANG).
const HANG := Basis(Vector3.UP, 0.35) * Basis(Vector3.UP, -PI / 2.0) * Basis(Vector3.BACK, -PI / 2.0)
## The pairing moment (P05): its AnimationPlayer's `pair` plays the fly, line-up, fold, roll and pop
## in its first PAIR_TIME seconds, at the ball's place and size. Loaded when first needed, not preloaded:
## the scene holds a Sock whose SockCloth checks for a HeldView, and that loop breaks an exported build.
const MOMENT_PATH := "res://game/sock/pair_moment.tscn"
const PAIR := &"pair"
const PAIR_TIME := 0.5
## The time of `pair` at which the ball pops (the burst starts): "pop" plays then, flat.
const POP_AT := 0.455
## The moment's second Sock reaches its line-up place at this time of `pair`: its fly-in ends (D10).
const FLY_IN_END := 0.2
## What that Sock flies under: Mate/FlyIn holds its Looks.
const FLY_IN := ^"Mate/FlyIn"

## The sparkle at a Teammate's hand when their pick makes a Pair.
const MATE_SPARKLE := preload("res://game/hands/mate_sparkle.tscn")
## The match cue's glow on a held Sock (core/131).
const SOCK_GLOW := preload("res://game/hands/sock_glow.tscn")
## A Teammate's worn Hands (old held.json "worn_step", HV:338-344): a hung item hangs from the anchor.
const WORN_HANG := Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.BACK, -PI / 2.0)

## Worn on a Teammate's avatar, at `anchor`, rather than in front of the camera.
@export var worn := false
## How far each further worn item sits from the active one, times its tucked place plus one; x goes
## left for the first, right for the second, and so on.
@export var worn_step := Vector3(0.07, 0.02, 0.05)
## The numbers of the held layout, the glide and the fly-up.
@export var tuning: HandsTuning

## What it shows: whose Hands, and the field of view the layout is drawn for.
var hands: Hands
var me := 1
## Worn: the node it hangs from each frame (the avatar's HoldPoint).
var anchor: Node3D
var base_fov := 75.0
## True while the turn button is held.
var turning := false
## How many pairing moments have started here (P05: once per pairing).
var moments_played := 0
## Worn: how many sparkles played at the hand (behaviour 60: once per pairing).
var sparkles := 0
## Worn: the held Socks that just became a Pair here, by Sock id: their ball flies in from the mate.
var _paired_here: Dictionary[int, bool] = {}

## The Looks of each held Sock, and each one's turn about its long axis, by Sock id.
var _looks: Dictionary[int, Node3D] = {}
var _spin: Dictionary[int, float] = {}
## Which held items are drawn as a Pair's ball, and the pairing moment playing over each, by Sock id.
var _balls: Dictionary[int, bool] = {}
var _moments: Dictionary[int, Node3D] = {}
## Where each held item hangs before its turn and the zoom: what glides (D08), by Sock id.
var _drawn: Dictionary[int, Transform3D] = {}
## Each item flying up into the Hands: {"from": its pose where it lay, in the level; "t": 0 to 1} (D09).
var _flying: Dictionary[int, Dictionary] = {}
## Each pairing moment's second Sock flying in: its pose where it lay, in the level (D10), by Pair id.
var _fly_in: Dictionary[int, Transform3D] = {}
## Each Sock let go whose body's Looks grows from the hand's size to its own, by Sock id: {"from":
## the share of its own size it starts at; "t": seconds gone}.
var _growing: Dictionary[int, Dictionary] = {}
## Each held Sock's bones as its cloth last drew them, in its skeleton's space (P03, P08), by Sock id.
var _bent: Dictionary[int, Array] = {}
## Each held Sock's SockCloth (null for a Pair's ball), found once when its Looks is made, and the bone
## nearest its Looks' middle, found once when it first sways, by Sock id.
var _cloths: Dictionary[int, SockCloth] = {}
var _nearest: Dictionary[int, int] = {}
## Which held Socks have been the active one: only their bones are noted as the skeleton is drawn.
var _was_active: Dictionary[int, bool] = {}
## How many times a skeleton was drawn and its bones noted (a timing case counts these).
var bends_noted := 0
## How many recursive searches for a SockCloth the held view has made.
var cloth_searches := 0
## Whether the Hands have been drawn once: what they hold from the start does not fly up.
var _seen := false
## A Guest's pick ghosts not answered yet, by Sock id: their Looks (flying up as `_flying` says).
var _ghosts: Dictionary[int, Node3D] = {}
## Refused pick ghosts flying back: {"looks", "from": where it was, "t": 0 to 1, "time", "arc"}.
var _backs: Dictionary[int, Dictionary] = {}
## Where a picked mate's ghost was when its Pair's moment started: its fly-in starts there (D08).
var _fly_in_from: Dictionary[int, Transform3D] = {}
## The match glows playing, by Sock (core/131).
var _glows: Dictionary[int, SockGlow] = {}
## Held items let go by a Guest's Throw or drop not answered yet: not drawn (G01, E01).
var _hidden: Dictionary[int, bool] = {}
## A Guest's turn of the wheel not answered yet: the active index shown, or -1 (E06).
var _guess_active := -1
## Items handed over or caught into these Hands since the last refresh: where each flies in from, in
## the level, by Sock id (core/42).
var _pick_from: Dictionary[int, Vector3] = {}


func _enter_tree() -> void:
	add_to_group(GROUP)


func _process(delta: float) -> void:
	if worn and anchor != null:
		global_transform = anchor.global_transform
	_grow(delta)  # first: a Sock let go in this refresh is drawn at the hand's size on its first frame
	refresh(delta)


## Brings the drawn items in line with the Hands and places them: `delta` turns the active one and
## moves the glide and the flights (0 puts every item at its place at once).
func refresh(delta := 0.0) -> void:
	var items := hands.items_of(me) if hands != null else PackedInt32Array()
	var had := _looks.keys()
	for sock: int in _looks.keys():
		if not items.has(sock):
			_let_go(sock)
	for sock in items:
		var pair := hands.mess.is_pair(sock)
		if _looks.has(sock) and pair and not _balls.has(sock):
			# A held Sock became a Pair here: its ball, under the moment, in the ball's place at once
			# (worn: no moment, the ball alone).
			_looks[sock].queue_free()
			_forget(sock)
			if not worn:
				_start_moment(sock)
			else:
				_paired_here[sock] = true
		if not _looks.has(sock):
			var looks := SockDress.make(hands.mess.design_of(sock), SockDress.HELD, pair)
			looks.name = "Held%d" % sock
			add_child(looks)
			_looks[sock] = looks
			if pair:
				_balls[sock] = true
			else:
				_cloths[sock] = _find_cloth(looks)
				_watch_bend(sock, looks)
			# Worn, a pairing here: the held Sock stayed and became the Pair (its mate flew in), or the
			# picked one is the Pair and its held mate went.
			var mate := hands.mess.mate_of(sock) if pair else -1
			var stayed := _paired_here.has(sock)
			if stayed or (worn and pair and _seen and mate >= 0 and had.has(mate)):
				_paired_here.erase(sock)
				var lay := mate if stayed else sock
				if tuning != null and lay >= 0:
					_flying[sock] = {"from": _lay_pose(lay), "t": 0.0, "sparkle": true}
				else:
					_sparkle.call_deferred(sock)
			elif _seen and not _moments.has(sock) and tuning != null:
				_flying[sock] = {"from": _lay_pose(sock), "t": 0.0}
	_seen = hands != null
	var active := hands.active_index(me) if hands != null else -1
	if _guess_active >= 0 and _guess_active < items.size():
		active = _guess_active
	if active >= 0 and active < items.size():
		_was_active[items[active]] = true
	if turning and not worn and active >= 0 and tuning != null:
		var sock := items[active]
		_spin[sock] = wrapf(_spin.get(sock, 0.0) + TAU / maxf(tuning.turn_time, 0.05) * delta, -PI, PI)
	var follow := 1.0
	if delta > 0.0 and tuning != null:
		follow = 1.0 - exp(-tuning.follow_rate * delta)
	for i in items.size():
		var sock := items[i]
		var laid := _layout(i, active, sock)
		_drawn[sock] = _drawn[sock].interpolate_with(laid, follow) if _drawn.has(sock) else laid
		if _close(_drawn[sock], laid):
			_drawn[sock] = laid
		var looks := _looks[sock]
		looks.transform = _finish(_drawn[sock], i == active, sock)
		if _flying.has(sock):
			_fly_up(sock, looks, delta)
		var moment: Node3D = _moments.get(sock)
		looks.visible = moment == null and not _hidden.has(sock)
		if moment != null:
			moment.transform = looks.transform
			_place_fly_in(sock, moment)
	_place_ghosts(items, delta)
	_pick_from.clear()


## Whether every held item is at its place: no glide or flight under way.
func settled() -> bool:
	if not _flying.is_empty() or not _fly_in.is_empty() or not _ghosts.is_empty() or not _backs.is_empty():
		return false
	if hands == null:
		return true
	var items := hands.items_of(me)
	var active := hands.active_index(me)
	for i in items.size():
		var sock := items[i]
		if not _drawn.has(sock):
			return false
		if _drawn[sock] != _layout(i, active, sock):
			return false
	return true


## Whether held item `sock` is flying up from where it lay (D09).
func flying_up(sock: int) -> bool:
	return _flying.has(sock)


## Where held item `sock` is drawn now, in the level, or null: a Cabinet flies a shelved Pair from
## there (D11).
func drawn_of(sock: int) -> Variant:
	var looks: Node3D = _looks.get(sock)
	return looks.global_transform if looks != null and looks.is_inside_tree() else null


## The Looks of a held Sock, or null.
func looks_of(sock: int) -> Node3D:
	return _looks.get(sock)


## Whether held item `sock` is drawn as a Pair's ball.
func is_ball(sock: int) -> bool:
	return _balls.has(sock)


## The pairing moment playing over held Pair `sock`, or null.
func moment_of(sock: int) -> Node3D:
	return _moments.get(sock)


## How far a held Sock is turned about its long axis, in radians.
func spin_of(sock: int) -> float:
	return _spin.get(sock, 0.0)


## How far the zoom has gone: 0 unzoomed, 1 at the zoom's field of view.
func zoom_amount() -> float:
	var camera := get_parent() as Camera3D
	if camera == null or tuning == null:
		return 0.0
	var full := tan(deg_to_rad(tuning.zoom_fov) * 0.5)
	var base := tan(deg_to_rad(base_fov) * 0.5)
	if is_equal_approx(full, base):
		return 0.0
	return clampf((base - tan(deg_to_rad(camera.fov) * 0.5)) / (base - full), 0.0, 1.0)


## How much smaller, and nearer the view's centre, the items are drawn so the zoom neither enlarges
## them nor moves them across the screen.
func zoom_factor() -> float:
	var camera := get_parent() as Camera3D
	if camera == null:
		return 1.0
	return tan(deg_to_rad(camera.fov) * 0.5) / tan(deg_to_rad(base_fov) * 0.5)


## Where held item `i` (Sock `sock`) is drawn once its glide is over, in the camera's space, scale
## included.
func target(i: int, active: int, sock: int) -> Transform3D:
	return _finish(_layout(i, active, sock), i == active, sock)


## Where held item `i` hangs before its turn and the zoom: what glides (D08).
func _layout(i: int, active: int, sock: int) -> Transform3D:
	if worn:
		return _worn_layout(i, active, sock)
	if tuning == null:
		return Transform3D.IDENTITY
	var design := hands.mess.design_of(sock)
	var anchor := tuning.active_pos
	var size := tuning.active_scale
	if i != active:
		anchor = tuning.tucked_pos + tuning.tucked_step * float(i if i < active or active < 0 else i - 1)
		size = tuning.tucked_scale
	var s := (design.size_scale() if design != null else 1.0) * size * tuning.depth
	if hands.mess.is_pair(sock):
		return Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s * tuning.ball_scale), anchor * tuning.depth)
	var half := SockDress.BOX.x * 0.5 * s
	var grip := anchor * tuning.depth + Vector3.UP * half
	return Transform3D(HANG.scaled(Vector3.ONE * s), grip + HANG.x * half)


## Where worn item `i` hangs from the anchor, true size: the active one right there, the others a
## `worn_step` further each, left then right (the old _worn_target()).
func _worn_layout(i: int, active: int, sock: int) -> Transform3D:
	var at := Vector3.ZERO
	if i != active:
		var j := i if i < active or active < 0 else i - 1
		at = worn_step * float(j + 1) * Vector3(-1.0 if j % 2 == 0 else 1.0, 1.0, 1.0)
	return worn_pose(hands.mess, sock, at)


## Where Sock `sock` of `mess` hangs worn, `at` from the anchor (the HoldPoint), true size: a Sock by
## its cuff, toe down; a Pair's ball with its top there. A Teammate's Throw or drop is drawn from it on
## their avatar (Hands.worn_start_of(), coop/13).
static func worn_pose(mess: Mess, sock: int, at := Vector3.ZERO) -> Transform3D:
	var design := mess.design_of(sock)
	var s := design.size_scale() if design != null else 1.0
	if mess.is_pair(sock):
		var radius := SockDress.ball_radius(design) if design != null else 0.0
		return Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), at + Vector3.DOWN * radius)
	var half := SockDress.BOX.x * 0.5 * s
	return Transform3D(WORN_HANG.scaled(Vector3.ONE * s), at + WORN_HANG.x * half)


## `rest` (where an item hangs) turned about its long axis by its spin and placed for the zoom: the
## active item comes close and large, every item keeps its screen size and place.
func _finish(rest: Transform3D, is_active: bool, sock: int) -> Transform3D:
	if tuning == null or worn:
		return rest
	var grip := rest.origin
	if not hands.mess.is_pair(sock):
		grip = rest.origin - rest.basis.x * (SockDress.BOX.x * 0.5)
	var turned := rest
	var spin: float = _spin.get(sock, 0.0)
	if spin != 0.0:
		var rot := Basis(rest.basis.x.normalized(), spin)
		turned = Transform3D(rot * rest.basis, grip + rot * (rest.origin - grip))
	var k := zoom_factor()
	var still := _zoomed(turned, k)
	var z := zoom_amount()
	if not is_active or z <= 0.0:
		return still
	var grow := tuning.zoom_scale / maxf(tuning.active_scale, 0.01)
	var at := tuning.zoom_pos * tuning.depth + (turned.origin - rest.origin) * grow
	return still.interpolate_with(_zoomed(Transform3D(turned.basis.scaled(Vector3.ONE * grow), at), k), z)


## Where Sock `sock` lay in the level, drawn at its Size: where a pick flies from. An item handed over
## or caught (core/42 lines 25, 26, 34) flies from where pick_from() said instead, flat, turned at
## random about the up axis.
func _lay_pose(sock: int) -> Transform3D:
	var design := hands.mess.design_of(sock)
	var size := design.size_scale() if design != null else 1.0
	if _pick_from.has(sock):
		var at: Vector3 = _pick_from[sock]
		_pick_from.erase(sock)
		return Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * size), at)
	return hands.mess.pose_of(sock).scaled_local(Vector3.ONE * size)


## core/42: item `sock` comes into these Hands from `at` in the level (a Teammate's hand, where a
## Throw hit), not from where it lay: told before the next refresh, which flies it from there.
func pick_from(sock: int, at: Vector3) -> void:
	_pick_from[sock] = at


## core/42: tells every HeldView of `hands` that shows player `me`'s Hands on this machine (their own,
## or their worn one on their avatar) that item `sock` comes in from `at`.
static func fly_from(hands: Hands, me: int, sock: int, at: Vector3) -> void:
	if hands == null or not hands.is_inside_tree():
		return
	for node in hands.get_tree().get_nodes_in_group(GROUP):
		var view := node as HeldView
		if view != null and view.hands == hands and view.me == me:
			view.pick_from(sock, at)


## Moves a picked item along its fly-up: from where it lay to its place (which follows the view) in
## `pick_time`, eased in and out, on a hop of `pick_hop` (D09). Then the glide has it.
func _fly_up(sock: int, looks: Node3D, delta: float) -> void:
	var fly := _flying[sock]
	var u := minf(1.0, float(fly["t"]) + delta / maxf(tuning.pick_time, 0.01))
	fly["t"] = u
	if u >= 1.0:
		_flying.erase(sock)
		if fly.get("sparkle", false):
			_sparkle(sock)
		return
	var to := looks.global_transform
	var eased := smoothstep(0.0, 1.0, u)
	var from: Transform3D = fly["from"]
	var at := from.interpolate_with(to, eased)
	at.origin = from.origin.lerp(to.origin, eased) + Vector3.UP * (tuning.pick_hop * 4.0 * u * (1.0 - u))
	looks.global_transform = at


## A Teammate's new Pair `sock` reached their hand: the sparkle burst and ring there, in its
## Collection's colour.
func _sparkle(sock: int) -> void:
	var looks: Node3D = _looks.get(sock)
	if looks == null or not is_inside_tree():
		return
	var colour := Color(1.0, 0.8, 0.4)
	var design := hands.mess.design_of(sock)
	if design != null and hands.mess.catalogue != null:
		colour = hands.mess.catalogue.collection_colour(design.collection)
	var fx := MATE_SPARKLE.instantiate() as MateSparkle
	fx.position = looks.position
	add_child(fx)
	fx.play(colour)
	sparkles += 1


## The match cue (core/131; the old Q666): held loose Sock `sock` glows a warm white, `strength` (0..1)
## bright, fading out over `seconds`. Whether one was there to glow.
func glow(sock: int, seconds: float, strength: float) -> bool:
	var looks: Node3D = _looks.get(sock)
	if looks == null or _balls.has(sock):
		return false
	var old: Variant = _glows.get(sock)
	if old != null and is_instance_valid(old):
		(old as SockGlow).queue_free()
	var fx := SOCK_GLOW.instantiate() as SockGlow
	add_child(fx)
	fx.play(looks, seconds, strength)
	_glows[sock] = fx
	return true


## Whether held Sock `sock` glows with the match cue now.
func glowing(sock: int) -> bool:
	var fx: Variant = _glows.get(sock)
	return fx != null and is_instance_valid(fx) and (fx as SockGlow).glowing()


## Places the pairing moment's second Sock while it flies in: its FlyIn starts where the Sock lay
## and comes to nothing by FLY_IN_END of the moment, eased, on the pick's hop (D10).
func _place_fly_in(sock: int, moment: Node3D) -> void:
	if not _fly_in.has(sock):
		return
	var fly_in := moment.get_node_or_null(FLY_IN) as Node3D
	var player := moment.get_node(^"AnimationPlayer") as AnimationPlayer
	if fly_in == null or tuning == null:
		_fly_in.erase(sock)
		return
	var u := clampf(player.current_animation_position / FLY_IN_END, 0.0, 1.0) if player.is_playing() else 1.0
	if u >= 1.0:
		fly_in.transform = Transform3D.IDENTITY
		_fly_in.erase(sock)
		return
	var mate := fly_in.get_parent() as Node3D
	var from := _fly_in[sock]
	var eased := smoothstep(0.0, 1.0, u)
	var to := mate.global_transform
	var at := from.interpolate_with(to, eased)
	at.origin = from.origin.lerp(to.origin, eased) + Vector3.UP * (tuning.pick_hop * 4.0 * u * (1.0 - u))
	fly_in.global_transform = at


## Drops everything the held view keeps of held Sock `sock`'s drawn Looks (the moment, the fly-in and
## the growth are another's: they outlive it).
func _forget(sock: int) -> void:
	_looks.erase(sock)
	_bent.erase(sock)
	_spin.erase(sock)
	_balls.erase(sock)
	_drawn.erase(sock)
	_flying.erase(sock)
	_cloths.erase(sock)
	_nearest.erase(sock)
	_was_active.erase(sock)


## The SockCloth under `looks`, or null.
func _find_cloth(looks: Node3D) -> SockCloth:
	cloth_searches += 1
	var found := looks.find_children("*", "SockCloth", true, false)
	return found[0] as SockCloth if not found.is_empty() else null


## A Sock left the Hands: let go (dropped or thrown), its body is where it hung and its body's Looks
## takes over at the hand's size, growing to its own; otherwise (a pairing, a shelve) it simply goes.
func _let_go(sock: int) -> void:
	_hidden.erase(sock)
	var looks := _looks[sock]
	var pair := _balls.has(sock)
	var bend := bend_of(sock)
	_forget(sock)
	_end_moment(sock)
	looks.queue_free()
	var mess := hands.mess if hands != null else null
	if mess == null or mess.state_of(sock) != Mess.State.FLYING or tuning == null or tuning.let_go_grow <= 0.0:
		return
	var from := 1.0 if worn else tuning.active_scale * (tuning.ball_scale if pair else 1.0)
	_growing[sock] = {"from": from, "t": 0.0}
	var throw: Dictionary = mess.throws.get(sock, {})
	if not pair and not bend.is_empty() and not throw.is_empty() and not throw.get("drop", false):
		_growing[sock]["bend"] = bend
	_grow(0.0)


## Whether Sock `sock`, let go, is still drawn growing from the hand's size.
func growing(sock: int) -> bool:
	return _growing.has(sock)


## Grows each let-go Sock's body Looks from the hand's size to its own over `let_go_grow`, about its
## body's origin; a body drawn without a Looks (past the flying cap) is drawn at its own size.
func _grow(delta: float) -> void:
	for sock: int in _growing.keys():
		var g := _growing[sock]
		g["t"] = float(g["t"]) + delta
		var mess := hands.mess if hands != null else null
		var body := mess.moving_body(sock) if mess != null else null
		var own := body.get_node_or_null(^"Looks") as Node3D if body != null else null
		var design := mess.design_of(sock) if mess != null else null
		var size := design.size_scale() if design != null else 1.0
		var u := clampf(float(g["t"]) / tuning.let_go_grow, 0.0, 1.0) if tuning != null and tuning.let_go_grow > 0.0 else 1.0
		if own != null and g.has("bend"):
			# P08: the thrown Sock's own cloth starts from the bend it had in the hand, once.
			var cloth := own.find_children("*", "SockCloth", true, false)
			if not cloth.is_empty():
				(cloth[0] as SockCloth).carry(g["bend"])
			g.erase("bend")
		if own == null or u >= 1.0:
			if own != null:
				own.scale = Vector3.ONE * size
			if own != null or u >= 1.0:
				_growing.erase(sock)
			continue
		var e := 1.0 - (1.0 - u) * (1.0 - u)
		own.scale = Vector3.ONE * size * lerpf(float(g["from"]), 1.0, e)


## Starts the pairing moment over Pair `sock`'s place: the two Socks and the ball drawn as its
## Design, the sparkles and the ring in its Collection's colour, drawn at the tuning's length. Its
## second Sock flies in from where it lay (D10).
func _start_moment(sock: int) -> void:
	_end_moment(sock)
	var moment := (load(MOMENT_PATH) as PackedScene).instantiate() as Node3D
	moment.name = "Moment%d" % sock
	var design := hands.mess.design_of(sock)
	# The scene's stand-in Looks become the Design's own: its shape for the two Socks, its ball.
	for path: NodePath in [^"Held/Looks", ^"Mate/FlyIn/Looks", ^"Ball"]:
		SockDress.swap(moment.get_node(path) as Node3D, design, SockDress.HELD, path == ^"Ball")
	var colour := Color(1.0, 0.8, 0.4)
	if design != null and hands.mess.catalogue != null:
		colour = hands.mess.catalogue.collection_colour(design.collection)
	var burst := moment.get_node(^"Burst") as GPUParticles3D
	(burst.process_material as ParticleProcessMaterial).color = colour
	var ring := moment.get_node(^"Ring") as MeshInstance3D
	(ring.material_override as StandardMaterial3D).albedo_color = Color(colour, 0.8)
	add_child(moment)
	var player := moment.get_node(^"AnimationPlayer") as AnimationPlayer
	player.speed_scale = PAIR_TIME / maxf(tuning.moment if tuning != null else PAIR_TIME, 0.01)
	player.animation_finished.connect(func(_name: StringName) -> void: _end_moment(sock), CONNECT_ONE_SHOT)
	player.play(PAIR)
	get_tree().create_timer(POP_AT / maxf(player.speed_scale, 0.01)).timeout.connect(_pop.bind(moment))
	_moments[sock] = moment
	moments_played += 1
	var mate := hands.mess.mate_of(sock)
	if _seen and mate >= 0:
		var from: Transform3D = _fly_in_from.get(mate, _lay_pose(mate))
		_fly_in_from.erase(mate)
		_fly_in[sock] = from * (moment.get_node(^"Mate/FlyIn/Looks") as Node3D).transform.affine_inverse()


## The ball of `moment` pops: its sound, unless the moment ended first.
func _pop(moment: Variant) -> void:
	if is_instance_valid(moment) and (moment as Node3D).is_inside_tree():
		Sounds.play(&"pop")


## Ends Pair `sock`'s pairing moment, if one plays: its ball shows as it is.
func _end_moment(sock: int) -> void:
	var moment: Node3D = _moments.get(sock)
	_moments.erase(sock)
	_fly_in.erase(sock)
	if moment != null and is_instance_valid(moment):
		moment.queue_free()
	var looks: Node3D = _looks.get(sock)
	if looks != null:
		looks.visible = true


## Whether a glide from `a` is close enough to `b` to end there (a tenth of a millimetre).
static func _close(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) < 0.0001 and a.basis.x.distance_to(b.basis.x) < 0.0001 \
			and a.basis.y.distance_to(b.basis.y) < 0.0001 and a.basis.z.distance_to(b.basis.z) < 0.0001


## `t` drawn `k` times smaller, its origin pulled towards the view's centre line by `k`: the same
## projected size and place when the field of view changes by `k`.
static func _zoomed(t: Transform3D, k: float) -> Transform3D:
	return Transform3D(t.basis.scaled(Vector3.ONE * k), Vector3(t.origin.x * k, t.origin.y * k, t.origin.z))


## Notes held Sock `sock`'s bones each time its skeleton is drawn: the cloth's bend shows only then.
func _watch_bend(sock: int, looks: Node3D) -> void:
	var skeleton := looks.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		return
	skeleton.skeleton_updated.connect(func() -> void:
		if _looks.get(sock) != looks or not _was_active.has(sock):
			return
		bends_noted += 1
		var poses: Array[Transform3D] = []
		for b in skeleton.get_bone_count():
			poses.append(skeleton.get_bone_global_pose(b))
		_bent[sock] = poses)


## Held Sock `sock`'s cloth bend as it was last drawn: each chain bone's pose rotation (its parent's
## frame), by bone; empty when it has not been drawn bent yet, or is a Pair.
func bend_of(sock: int) -> Dictionary[int, Quaternion]:
	var out: Dictionary[int, Quaternion] = {}
	var looks: Node3D = _looks.get(sock)
	var poses: Array = _bent.get(sock, [])
	var cloth: SockCloth = _cloths.get(sock)
	if looks == null or poses.is_empty() or cloth == null:
		return out
	var skeleton := cloth.get_skeleton()
	for b in cloth.chain():
		var parent := skeleton.get_bone_parent(b)
		var above: Transform3D = poses[parent] if parent >= 0 else Transform3D.IDENTITY
		out[b] = (above.affine_inverse() * (poses[b] as Transform3D)).basis.get_rotation_quaternion()
	return out


## How far the active held Sock's sway has moved its middle on screen, as a shift in view direction
## (x right, y up, over the depth): the held readout moves with it (P03, the old info_sway()). Zero
## for a Pair, empty Hands, or a Sock not drawn bent yet.
func sway() -> Vector2:
	var camera := get_parent() as Camera3D
	if hands == null or camera == null:
		return Vector2.ZERO
	var items := hands.items_of(me)
	var active := hands.active_index(me)
	if active < 0 or active >= items.size():
		return Vector2.ZERO
	var off := sway_offset(items[active])
	if off == Vector3.ZERO:
		return Vector2.ZERO
	var looks: Node3D = _looks[items[active]]
	var still := camera.to_local(looks.global_position)
	var swung := camera.to_local(looks.global_position + off)
	if still.z > -0.0001 or swung.z > -0.0001:
		return Vector2.ZERO
	return Vector2(swung.x, swung.y) / -swung.z - Vector2(still.x, still.y) / -still.z


## How far the cloth's bend has moved held Sock `sock`'s middle (its Looks' origin), in the level:
## the bone nearest it carries it from its rest place to where the bend has it (the old sway_offset()).
func sway_offset(sock: int) -> Vector3:
	var looks: Node3D = _looks.get(sock)
	var poses: Array = _bent.get(sock, [])
	var cloth: SockCloth = _cloths.get(sock)
	if looks == null or poses.is_empty() or cloth == null or not looks.is_inside_tree():
		return Vector3.ZERO
	var skeleton := cloth.get_skeleton()
	var skel := skeleton.global_transform
	var at := skel.affine_inverse() * looks.global_position
	if not _nearest.has(sock):
		var near := -1
		for b in cloth.chain():
			if near < 0 or skeleton.get_bone_global_rest(b).origin.distance_to(at) \
					< skeleton.get_bone_global_rest(near).origin.distance_to(at):
				near = b
		_nearest[sock] = near
	var near := _nearest[sock]
	if near < 0:
		return Vector3.ZERO
	var bent := (poses[near] as Transform3D) * skeleton.get_bone_global_rest(near).affine_inverse()
	return skel * (bent * at) - looks.global_position


# --- A Guest's guesses (coop/09) -----------------------------------------------------------------

## A Guest picked Sock `sock`: its ghost flies up at once from where it is drawn now (lying, or its
## moving body: D10) to the active place, or to the held loose mate it would pair with (D08), on the
## pick's time and hop (D02). Nothing in the Hands changes until the answer (D03).
func ghost_pick(sock: int) -> void:
	if hands == null or _ghosts.has(sock) or tuning == null:
		return
	_end_back(sock)
	var looks := SockDress.make(hands.mess.design_of(sock), SockDress.HELD, hands.mess.is_pair(sock))
	looks.name = "Ghost%d" % sock
	add_child(looks)
	_ghosts[sock] = looks
	var from: Variant = hands.mess.drawn_flight_of(sock)
	_flying[sock] = {"from": from if from is Transform3D else _lay_pose(sock), "t": 0.0}
	_place_ghosts(hands.items_of(me), 0.0)


## Whether a pick ghost of Sock `sock` waits on its answer.
func has_ghost(sock: int) -> bool:
	return _ghosts.has(sock)


## The Host granted the pick of `sock`: its ghost becomes the held item where it is now, its fly-up
## carrying on (no pop, D04); a picked mate's ghost becomes the start of its Pair's fly-in (D08).
func adopt_pick(sock: int) -> void:
	var looks: Node3D = _ghosts.get(sock)
	if looks == null:
		return
	_ghosts.erase(sock)
	if not hands.items_of(me).has(sock) or _looks.has(sock):
		# Paired into a held Sock: the moment's fly-in starts where the ghost is.
		if looks.is_inside_tree():
			_fly_in_from[sock] = looks.global_transform
		_flying.erase(sock)
		looks.queue_free()
		return
	_looks[sock] = looks
	looks.name = "Held%d" % sock
	if hands.mess.is_pair(sock):
		_balls[sock] = true
	else:
		_cloths[sock] = _find_cloth(looks)
		_watch_bend(sock, looks)


## The Host refused the pick of `sock` (or never answered): its ghost flies back to where the Sock
## lies or moves, or into the Teammate's Hands that won it (F01, F03), in `time` on an arc of `arc`
## (F02), then goes and ghost_returned is said.
func ghost_back(sock: int, time: float, arc: float) -> void:
	var looks: Node3D = _ghosts.get(sock)
	_ghosts.erase(sock)
	_flying.erase(sock)
	if looks == null or not looks.is_inside_tree():
		if looks != null:
			looks.queue_free()
		ghost_returned.emit(sock)
		return
	_backs[sock] = {"looks": looks, "from": looks.global_transform, "t": 0.0, "time": time, "arc": arc}


## Whether a refused pick ghost of Sock `sock` is flying back.
func flying_back(sock: int) -> bool:
	return _backs.has(sock)


## Where pick ghost (or flying-back ghost) `sock` is drawn now, in the level, or null.
func ghost_pose(sock: int) -> Variant:
	var looks: Node3D = _ghosts.get(sock)
	if looks == null and _backs.has(sock):
		looks = _backs[sock]["looks"]
	return looks.global_transform if looks != null and looks.is_inside_tree() else null


## Every guess dropped at once (the session ended): ghosts gone, hidden items shown, the turn undone.
func clear_guesses() -> void:
	for sock: int in _ghosts.keys():
		_ghosts[sock].queue_free()
		_flying.erase(sock)
		ghost_returned.emit(sock)
	_ghosts.clear()
	for sock: int in _backs.keys():
		_end_back(sock)
	_hidden.clear()
	_guess_active = -1


## A Guest let held item `sock` go (a Throw or a drop): hidden at once until the answer (G01, E01).
func hide_item(sock: int) -> void:
	_hidden[sock] = true
	var looks: Node3D = _looks.get(sock)
	if looks != null:
		looks.visible = false


## A refused (or unanswered) let-go: the item shows in its place again at once (Q2476).
func show_item(sock: int) -> void:
	_hidden.erase(sock)
	var looks: Node3D = _looks.get(sock)
	if looks != null:
		looks.visible = not _moments.has(sock)


## Whether held item `sock` is hidden by a let-go not answered yet.
func is_hidden(sock: int) -> bool:
	return _hidden.has(sock)


## A Guest turned the wheel by `step`: the active item shown changes at once (E06, Q2475).
func guess_cycle(step: int) -> void:
	var items := hands.items_of(me) if hands != null else PackedInt32Array()
	if items.size() < 2:
		return
	_guess_active = wrapi(shown_active() + step, 0, items.size())


## The wheel's answer came (granted: the Hands say so now; refused: back, silently).
func clear_guess() -> void:
	_guess_active = -1


## The active index shown now, a guess included.
func shown_active() -> int:
	if _guess_active >= 0:
		return _guess_active
	return hands.active_index(me) if hands != null else -1


## Places the pick ghosts on their way up and the refused ones flying back.
func _place_ghosts(items: PackedInt32Array, delta: float) -> void:
	for sock: int in _ghosts:
		var looks := _ghosts[sock]
		var mate := hands.mate_held(me, sock) if hands != null else -1
		if mate >= 0 and _looks.has(mate):
			looks.transform = _looks[mate].transform
		else:
			looks.transform = _finish(_layout(items.size(), items.size(), sock), true, sock)
		if _flying.has(sock):
			_fly_up(sock, looks, delta)
	for sock: int in _backs.keys():
		var back := _backs[sock]
		var looks: Node3D = back["looks"]
		var u := minf(1.0, float(back["t"]) + delta / maxf(float(back["time"]), 0.01))
		back["t"] = u
		if u >= 1.0 or not looks.is_inside_tree():
			_end_back(sock)
			continue
		var to := _back_target(sock)
		var from: Transform3D = back["from"]
		var at := from.interpolate_with(to, u)
		at.origin = from.origin.lerp(to.origin, u) + Vector3.UP * (float(back["arc"]) * 4.0 * u * (1.0 - u))
		looks.global_transform = at


## Where a refused pick ghost of `sock` flies back to now: into the Hands of the Teammate holding it
## (their worn view on this machine, F03), else where it lies or moves (F01).
func _back_target(sock: int) -> Transform3D:
	for node in get_tree().get_nodes_in_group(GROUP):
		var view := node as HeldView
		if view == null or view == self or not view.worn or view.hands != hands:
			continue
		var at: Variant = view.drawn_of(sock)
		if at is Transform3D:
			return at
	var moving: Variant = hands.mess.drawn_flight_of(sock)
	return moving if moving is Transform3D else _lay_pose(sock)


func _end_back(sock: int) -> void:
	var back: Dictionary = _backs.get(sock, {})
	_backs.erase(sock)
	if back.is_empty():
		return
	(back["looks"] as Node3D).queue_free()
	ghost_returned.emit(sock)
