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
## Looks of this machine only: it reads the Hands and the Mess, never writes them. Ported from the
## old game's held_view.gd (its layout numbers, its depth trick, its zoom, its glide and fly-up).
class_name HeldView
extends Node3D

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

## What it shows: whose Hands, the numbers, and the field of view the layout is drawn for.
var hands: Hands
var me := 1
var tuning: HandsTuning
var base_fov := 75.0
## True while the turn button is held.
var turning := false
## How many pairing moments have started here (P05: once per pairing).
var moments_played := 0

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


func _enter_tree() -> void:
	add_to_group(GROUP)


func _process(delta: float) -> void:
	_grow(delta)  # first: a Sock let go in this refresh is drawn at the hand's size on its first frame
	refresh(delta)


## Brings the drawn items in line with the Hands and places them: `delta` turns the active one and
## moves the glide and the flights (0 puts every item at its place at once).
func refresh(delta := 0.0) -> void:
	var items := hands.items_of(me) if hands != null else PackedInt32Array()
	for sock: int in _looks.keys():
		if not items.has(sock):
			_let_go(sock)
	for sock in items:
		var pair := hands.mess.is_pair(sock)
		if _looks.has(sock) and pair and not _balls.has(sock):
			# A held Sock became a Pair here: its ball, under the moment, in the ball's place at once.
			_looks[sock].queue_free()
			_forget(sock)
			_start_moment(sock)
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
			if _seen and not _moments.has(sock) and tuning != null:
				_flying[sock] = {"from": _lay_pose(sock), "t": 0.0}
	_seen = hands != null
	var active := hands.active_index(me) if hands != null else -1
	if active >= 0 and active < items.size():
		_was_active[items[active]] = true
	if turning and active >= 0 and tuning != null:
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
		looks.visible = moment == null
		if moment != null:
			moment.transform = looks.transform
			_place_fly_in(sock, moment)


## Whether every held item is at its place: no glide or flight under way.
func settled() -> bool:
	if not _flying.is_empty() or not _fly_in.is_empty():
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


## `rest` (where an item hangs) turned about its long axis by its spin and placed for the zoom: the
## active item comes close and large, every item keeps its screen size and place.
func _finish(rest: Transform3D, is_active: bool, sock: int) -> Transform3D:
	if tuning == null:
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


## Where Sock `sock` lay in the level, drawn at its Size: where a pick flies from.
func _lay_pose(sock: int) -> Transform3D:
	var design := hands.mess.design_of(sock)
	return hands.mess.pose_of(sock).scaled_local(Vector3.ONE * (design.size_scale() if design != null else 1.0))


## Moves a picked item along its fly-up: from where it lay to its place (which follows the view) in
## `pick_time`, eased in and out, on a hop of `pick_hop` (D09). Then the glide has it.
func _fly_up(sock: int, looks: Node3D, delta: float) -> void:
	var fly := _flying[sock]
	var u := minf(1.0, float(fly["t"]) + delta / maxf(tuning.pick_time, 0.01))
	fly["t"] = u
	if u >= 1.0:
		_flying.erase(sock)
		return
	var to := looks.global_transform
	var eased := smoothstep(0.0, 1.0, u)
	var from: Transform3D = fly["from"]
	var at := from.interpolate_with(to, eased)
	at.origin = from.origin.lerp(to.origin, eased) + Vector3.UP * (tuning.pick_hop * 4.0 * u * (1.0 - u))
	looks.global_transform = at


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
	var looks := _looks[sock]
	var pair := _balls.has(sock)
	var bend := bend_of(sock)
	_forget(sock)
	_end_moment(sock)
	looks.queue_free()
	var mess := hands.mess if hands != null else null
	if mess == null or mess.state_of(sock) != Mess.State.FLYING or tuning == null or tuning.let_go_grow <= 0.0:
		return
	_growing[sock] = {"from": tuning.active_scale * (tuning.ball_scale if pair else 1.0), "t": 0.0}
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
		_fly_in[sock] = _lay_pose(mate) * (moment.get_node(^"Mate/FlyIn/Looks") as Node3D).transform.affine_inverse()


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
