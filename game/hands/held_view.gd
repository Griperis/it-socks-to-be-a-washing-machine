## The Socks in this player's Hands, drawn in front of the camera (a child of it). The active item
## hangs big right of centre, the others tucked small to the left (H06). While zoomed (H21) the
## tucked items keep their screen size and place and the active one comes close and large; while
## turning (H22) the active item spins about its long axis and keeps its angle when let go. A
## dropped Sock flicks from the hand to its spot (H10) before the Mess lets its body fall. A held
## Pair is one sock ball, `ball_scale` times a Sock's size (P06); a Sock that becomes a Pair in
## these Hands plays the pairing moment (pair_moment.tscn, P05) at the ball's place, over a hidden
## ball, once; a whole Pair picked up plays none, and a Pair let go ends its moment.
##
## Looks of this machine only: it reads the Hands and the Mess, never writes them. Ported from the
## old game's held_view.gd (its layout numbers, its depth trick and its zoom), without the cloth.
class_name HeldView
extends Node3D

## A held Sock hangs by its cuff, toe down, turned a little to show its side (the old HANG).
const HANG := Basis(Vector3.UP, 0.35) * Basis(Vector3.UP, -PI / 2.0) * Basis(Vector3.BACK, -PI / 2.0)
## The pairing moment (P05): its AnimationPlayer's `pair` plays the fly, line-up, fold, roll and pop
## in its first PAIR_TIME seconds, at the ball's place and size.
const MOMENT := preload("res://game/sock/pair_moment.tscn")
const PAIR := &"pair"
const PAIR_TIME := 0.5

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


func _process(delta: float) -> void:
	refresh(delta)


## Brings the drawn items in line with the Hands and places them; `delta` turns the active one.
func refresh(delta := 0.0) -> void:
	var items := hands.items_of(me) if hands != null else PackedInt32Array()
	for sock: int in _looks.keys():
		if not items.has(sock):
			_let_go(sock)
	for sock in items:
		var pair := hands.mess.is_pair(sock)
		if _looks.has(sock) and pair and not _balls.has(sock):
			# A held Sock became a Pair here: its ball, under the moment.
			_looks[sock].queue_free()
			_looks.erase(sock)
			_start_moment(sock)
		if not _looks.has(sock):
			var looks := SockDress.make(hands.mess.design_of(sock), SockDress.HELD, pair)
			looks.name = "Held%d" % sock
			add_child(looks)
			_looks[sock] = looks
			if pair:
				_balls[sock] = true
	var active := hands.active_index(me) if hands != null else -1
	if turning and active >= 0 and tuning != null:
		var sock := items[active]
		_spin[sock] = wrapf(_spin.get(sock, 0.0) + TAU / maxf(tuning.turn_time, 0.05) * delta, -PI, PI)
	for i in items.size():
		var sock := items[i]
		_looks[sock].transform = target(i, active, sock)
		var moment: Node3D = _moments.get(sock)
		_looks[sock].visible = moment == null
		if moment != null:
			moment.transform = _looks[sock].transform


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


## Where held item `i` (Sock `sock`) is drawn, in the camera's space, scale included.
func target(i: int, active: int, sock: int) -> Transform3D:
	if tuning == null:
		return Transform3D.IDENTITY
	var design := hands.mess.design_of(sock)
	var anchor := tuning.active_pos
	var size := tuning.active_scale
	if i != active:
		anchor = tuning.tucked_pos + tuning.tucked_step * float(i if i < active or active < 0 else i - 1)
		size = tuning.tucked_scale
	var s := (design.size_scale() if design != null else 1.0) * size * tuning.depth
	var half := SockDress.BOX.x * 0.5 * s
	var grip := anchor * tuning.depth + Vector3.UP * half
	var rest := Transform3D(HANG.scaled(Vector3.ONE * s), grip + HANG.x * half)
	if hands.mess.is_pair(sock):
		grip = anchor * tuning.depth
		rest = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s * tuning.ball_scale), grip)
	var turned := rest
	var spin: float = _spin.get(sock, 0.0)
	if spin != 0.0:
		var rot := Basis(rest.basis.x.normalized(), spin)
		turned = Transform3D(rot * rest.basis, grip + rot * (rest.origin - grip))
	var k := zoom_factor()
	var still := _zoomed(turned, k)
	var z := zoom_amount()
	if i != active or z <= 0.0:
		return still
	var grow := tuning.zoom_scale / maxf(tuning.active_scale, 0.01)
	var at := tuning.zoom_pos * tuning.depth + (turned.origin - rest.origin) * grow
	return still.interpolate_with(_zoomed(Transform3D(turned.basis.scaled(Vector3.ONE * grow), at), k), z)


## A Sock left the Hands: dropped, it flicks to where it is let go and vanishes as its body
## appears there; otherwise it simply goes.
func _let_go(sock: int) -> void:
	var looks := _looks[sock]
	_looks.erase(sock)
	_spin.erase(sock)
	_balls.erase(sock)
	_end_moment(sock)
	looks.visible = true
	var mess := hands.mess if hands != null else null
	if mess == null or mess.state_of(sock) != Mess.State.FLYING or tuning == null or tuning.flick <= 0.0:
		looks.queue_free()
		return
	var from := looks.global_transform
	looks.top_level = true
	looks.global_transform = from
	var design := mess.design_of(sock)
	var to := mess.pose_of(sock).scaled_local(Vector3.ONE * (design.size_scale() if design != null else 1.0))
	var tween := looks.create_tween()
	tween.tween_property(looks, ^"global_transform", to, tuning.flick)
	tween.tween_callback(looks.queue_free)


## Starts the pairing moment over Pair `sock`'s place: the two Socks and the ball tinted as its
## Design, the sparkles and the ring in its Collection's colour, drawn at the tuning's length.
func _start_moment(sock: int) -> void:
	_end_moment(sock)
	var moment := MOMENT.instantiate() as Node3D
	moment.name = "Moment%d" % sock
	var design := hands.mess.design_of(sock)
	for path: NodePath in [^"Held/Looks", ^"Mate/Looks", ^"Ball"]:
		var looks := moment.get_node(path) as Node3D
		SockDress.tint(looks, design)
		SockDress.play(looks, SockDress.HELD)
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
	_moments[sock] = moment
	moments_played += 1


## Ends Pair `sock`'s pairing moment, if one plays: its ball shows as it is.
func _end_moment(sock: int) -> void:
	var moment: Node3D = _moments.get(sock)
	_moments.erase(sock)
	if moment != null and is_instance_valid(moment):
		moment.queue_free()
	var looks: Node3D = _looks.get(sock)
	if looks != null:
		looks.visible = true


## `t` drawn `k` times smaller, its origin pulled towards the view's centre line by `k`: the same
## projected size and place when the field of view changes by `k`.
static func _zoomed(t: Transform3D, k: float) -> Transform3D:
	return Transform3D(t.basis.scaled(Vector3.ONE * k), Vector3(t.origin.x * k, t.origin.y * k, t.origin.z))
