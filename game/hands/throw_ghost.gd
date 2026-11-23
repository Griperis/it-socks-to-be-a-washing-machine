## A Guest's own Throw or drop, drawn at once (Q2221, Q2473; list 03 G02-G13, E01-E03): a looks-only
## body on Mess.LAYER_GHOST that touches the static house only, flying from the hand with the launch
## this machine works out itself, and the Sock's Looks drawn on it. It never wakes, rests, puts or
## writes anything (G10, I2): GuestGhosts makes it, the Mess holds its own drawing of the Sock back
## meanwhile, and it goes when told.
##
## Once the Host's body exists here (the stamped copy of a Throw, or a drop's own local body), the
## ghost flies on its own body, full physics, compared with the Host's at the same moment of the flight
## (G03, G05, Q2573). Once the two part (farther than `part_distance` or turned more than `part_turn`),
## it is corrected to the Host's from then on: each tick its drawn offset moves
## `1 - exp(-3 dt / predict_blend)` of the way to that difference, position and turn (G04, G11). Until
## then it is drawn right on its body. When the Host's body has come to rest, the
## ghost eases onto the rest pose, nearer than `settle_close` or after `settle_wait` (G07); then its
## cloth lies flat first (at most `flat_wait`; it flattens by itself under the cloth's `flat_speed`,
## G09, being a falling body's Looks), the Mess draws the Sock and the ghost's Looks stays
## `keep_frames` more frames, so no frame is blank and nothing pops (G08).
##
## A Throw's ghost body flies the Host's launch (the same body, shape, mass, material, damping and
## numbers: coop/11), from the first-person hand, where the Host lets the Guest's Throw go too
## (Hands.start_of(), coop/13): it is the Host's flight until something only one of them meets.
class_name ThrowGhost
extends Node3D

const FLIGHT_SCENE := preload("res://game/sock/flight.tscn")
const BALL_FLIGHT_SCENE := preload("res://game/sock/ball_flight.tscn")

## The ghost has come to rest on the Host's pose (or was told to end): the Mess may draw the Sock.
signal settled(sock: int)

var sock := -1
var mess: Mess
var tuning: GhostTuning
## The share of its own size it starts at (the hand's), growing to its own over `grow_time`.
var grow_from := 1.0
var grow_time := 0.1
## Whether it is a drop (its Host body is a local body here, not a stamped copy).
var drop := false
## Set when the Host granted it: from then on the Sock's record and body lead it.
var answered := false

var _body: RigidBody3D
var _looks: Node3D
## This ghost's flight poses: [seconds since release, Transform3D], oldest first (G06).
var _poses: Array[Array] = []
var _age := 0.0
## The physics tick whose step is the body's first: its age counts the steps it has taken, as a
## FlightRow's flight time counts the Host body's from its launch pose (coop/11: counting this node's
## own ticks put it a step behind when it was made inside a physics tick).
var _born := 0
## The drawn offset from the ghost's body: a move and a turn.
var _off := Vector3.ZERO
var _turn := Quaternion.IDENTITY
## Whether it has parted from the Host's body (Q2573): from then on it is corrected to it.
var _parted := false
## Its body's place and speed the tick before: a step Jolt pushed it into the floor by is undone, as a
## flight's (MessMoving.undo_push(), core/50; coop/13).
var _was := Transform3D.IDENTITY
var _was_speed := 0.0
## When the Host's local body (a drop's) was first seen, in this ghost's age.
var _ref_seen := -1.0
## Easing onto the Host's rest: the time it has eased, or -1 before.
var _resting := -1.0
var _rest_pose := Transform3D.IDENTITY
var _done := false
## G08: seconds waited for the cloth to lie flat at the rest (-1 before), and the frames the Looks still
## stays once the Mess draws the Sock (-1 before).
var _flat_waited := -1.0
var _keep := -1


## A ghost of Sock `p_sock` of `p_mess`, let go at `from` with `vel` and `spin` under `holder`.
static func make(p_mess: Mess, p_sock: int, launch: Dictionary, holder: Node, p_drop: bool) -> ThrowGhost:
	var g := ThrowGhost.new()
	g.name = "ThrowGhost%d" % p_sock
	g.sock = p_sock
	g.mess = p_mess
	g.tuning = p_mess.ghost_tuning()
	g.drop = p_drop
	holder.add_child(g)
	g._launch(launch)
	return g


func _launch(launch: Dictionary) -> void:
	top_level = true
	var pair := mess.is_pair(sock)
	var design := mess.design_of(sock)
	_body = (BALL_FLIGHT_SCENE if pair else FLIGHT_SCENE).instantiate() as RigidBody3D
	_body.name = "Body"
	_body.top_level = true
	_body.collision_layer = Mess.LAYER_GHOST
	_body.collision_mask = Mess.LAYER_HOUSE
	_body.contact_monitor = false
	MessMoving.fit(_body, design)
	var hands := mess.tuning
	var t := mess.bodies_tuning()
	# As the Host's body (MessMoving._launch, coop/11): a drop slides and drags as a woken Sock (a
	# Pair's ball as a Pair); a Throw bounces and drags as a Throw, a Pair's from its first touch.
	_body.physics_material_override = MessMoving.let_go_material(t, drop)
	_body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	_body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	if drop:
		_body.linear_damp = hands.pair_linear_damp if pair else t.woken_linear_damp
		_body.angular_damp = hands.pair_angular_damp if pair else t.woken_angular_damp
	else:
		_body.linear_damp = hands.thrown_linear_damp
		_body.angular_damp = hands.thrown_angular_damp
		if pair:
			_body.contact_monitor = true
			_body.max_contacts_reported = 1
			_body.body_entered.connect(_on_pair_touch, CONNECT_ONE_SHOT)
	_body.linear_velocity = launch["vel"]
	_body.angular_velocity = launch["spin"]
	MessMoving.switch_ccd(_body, _body.linear_velocity.length(), t)
	if not pair:
		_body.inertia = MessMoving.turn_inertia(_body.mass, SockDress.box(design), t.turn_weight)
	_body.transform = launch["from"]
	_was = launch["from"]
	_was_speed = _body.linear_velocity.length()
	_born = Engine.get_physics_frames() + (0 if Engine.is_in_physics_frame() else 1)
	add_child(_body)
	_body.reset_physics_interpolation()
	_looks = SockDress.make(design, SockDress.LYING, pair)
	_looks.name = "Looks"
	# A falling body's Looks: its cloth bends in flight and lies flat when slow, as a flight's (G09).
	_body.add_child(_looks)
	_poses.append([0.0, _body.global_transform])
	_draw(0.0)


## A thrown Pair's ball drags as a Pair from its first touch, as the Host's (MessMoving._damp_pair).
func _on_pair_touch(_other: Node) -> void:
	_body.linear_damp = mess.tuning.pair_linear_damp
	_body.angular_damp = mess.tuning.pair_angular_damp


## The ghost's body (tests read where it is).
func body() -> RigidBody3D:
	return _body


## Where the ghost is drawn now, in the level (its Size included).
func drawn() -> Transform3D:
	return _looks.global_transform if _looks != null and _looks.is_inside_tree() else Transform3D.IDENTITY


## The drawn offset from the ghost's own body now (G04).
func offset() -> Vector3:
	return _off


## The ghost's drawn Looks (null once gone).
func looks() -> Node3D:
	return _looks if _looks != null and is_instance_valid(_looks) else null


## The ghost's cloth, or null (a Pair's ball has none).
func cloth() -> SockCloth:
	var l := looks()
	if l == null:
		return null
	var found := l.find_children("*", "SockCloth", true, false)
	return found[0] as SockCloth if not found.is_empty() else null


## Whether its cloth lies flat (no bend left), or it has none.
func is_flat() -> bool:
	var c := cloth()
	return c == null or not c.active or c.influence <= 0.001


func _process(_delta: float) -> void:
	if _keep < 0:
		return
	if _keep == 0:
		queue_free()
		return
	_keep -= 1


func _physics_process(delta: float) -> void:
	if _done or _body == null:
		return
	if _flat_waited >= 0.0:
		_wait_flat(delta)
		return
	_age = maxf(0.0, float(Engine.get_physics_frames() - _born) / float(Engine.physics_ticks_per_second))
	if not _body.freeze:
		var back: Variant = MessMoving.undo_push(self, _body, _was, _was_speed, delta, mess.bodies_tuning())
		_was = back if back is Transform3D else _body.global_transform
		_was_speed = _body.linear_velocity.length()
	MessMoving.switch_ccd(_body, _body.linear_velocity.length(), mess.bodies_tuning())
	_poses.append([_age, _body.global_transform])
	while _poses.size() > tuning.keep_poses:
		_poses.pop_front()
	var k := 1.0 - exp(-3.0 * delta / maxf(tuning.predict_blend, 0.001))
	if not answered:
		_draw(delta)
		return
	var state := mess.state_of(sock) if sock < mess.count() else Mess.State.GONE
	var ref := mess.moving_body(sock) if state == Mess.State.FLYING else null
	if _resting >= 0.0 or (state == Mess.State.LYING and ref == null):
		_settle(delta, k)
		return
	if state in [Mess.State.HELD, Mess.State.SHELVED, Mess.State.GONE, Mess.State.IN_PAIR]:
		# G12: caught, shelved or binned on the Host: gone at once.
		end()
		return
	if ref != null:
		var at := _ref_time(ref)
		var mine: Variant = _pose_at(at)
		if at >= 0.0 and mine is Transform3D:
			var host := ref.global_transform.orthonormalized()
			var own := (mine as Transform3D).orthonormalized()
			var diff := (host.basis.get_rotation_quaternion() * own.basis.get_rotation_quaternion().inverse()).normalized()
			if not _parted and (host.origin.distance_to(own.origin) > tuning.part_distance \
					or rad_to_deg(diff.get_angle()) > tuning.part_turn):
				_parted = true
			if _parted:
				_off = _off.lerp(host.origin - own.origin, k)
				_turn = _turn.slerp(diff, k)
	_draw(delta)


## How far into its flight the Host's body `ref` is drawn here: a Throw's copy by its stamped row
## (FlightRow.flight_time()), a drop's local body by the time since it was first seen.
func _ref_time(ref: RigidBody3D) -> float:
	var row := FlightRow.of(ref)
	if row != null and not drop:
		return row.flight_time()
	if _ref_seen < 0.0:
		_ref_seen = _age
	return _age - _ref_seen


## This ghost's pose `t` seconds after release, from its kept poses, or null before the first.
func _pose_at(t: float) -> Variant:
	if _poses.is_empty() or t < 0.0:
		return null
	if t <= float(_poses[0][0]):
		return _poses[0][1]
	for i in range(_poses.size() - 1):
		var a: Array = _poses[i]
		var b: Array = _poses[i + 1]
		if t <= float(b[0]):
			var w := (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			return (a[1] as Transform3D).interpolate_with(b[1], w)
	return _poses[-1][1]


## G07: the Host's body rests; the ghost is drawn at the rest pose less what is left of the
## difference, which eases away, and ends once nearer than `settle_close` or after `settle_wait`.
func _settle(delta: float, k: float) -> void:
	if _resting < 0.0:
		_resting = 0.0
		_rest_pose = mess.pose_of(sock).orthonormalized()
		var now := _drawn_pose()
		_off = now.origin - _rest_pose.origin
		_turn = (now.basis.get_rotation_quaternion() * _rest_pose.basis.get_rotation_quaternion().inverse()).normalized()
		_body.freeze = true
	_resting += delta
	_off = _off.lerp(Vector3.ZERO, k)
	_turn = _turn.slerp(Quaternion.IDENTITY, k)
	var at := Transform3D(Basis(_turn) * _rest_pose.basis, _rest_pose.origin + _off)
	_place(at, delta)
	if _off.length() < tuning.settle_close or _resting >= tuning.settle_wait:
		_flat_waited = 0.0
		_wait_flat(0.0)


## G08: at the rest, the cloth lies flat first (at most `flat_wait`), then the Mess draws the Sock and
## the Looks stays `keep_frames` frames more.
func _wait_flat(delta: float) -> void:
	_flat_waited += delta
	_place(_rest_pose, delta)
	if not is_flat() and _flat_waited < tuning.flat_wait:
		return
	_done = true
	settled.emit(sock)
	_keep = tuning.keep_frames


## The ghost's body pose with the offset on it.
func _drawn_pose() -> Transform3D:
	var own := _body.global_transform.orthonormalized()
	return Transform3D(Basis(_turn) * own.basis, own.origin + _off)


## Whether it has parted from the Host's body and is corrected to it (Q2573; tests read it).
func parted() -> bool:
	return _parted


func _draw(delta: float) -> void:
	_place(_drawn_pose(), delta)


func _place(at: Transform3D, delta: float) -> void:
	if _looks == null:
		return
	var design := mess.design_of(sock)
	var size := SockDress.scale_of(design)
	var u := clampf(_age / grow_time, 0.0, 1.0) if grow_time > 0.0 else 1.0
	var e := 1.0 - (1.0 - u) * (1.0 - u)
	_looks.global_transform = at.scaled_local(Vector3.ONE * size * lerpf(grow_from, 1.0, e))
	if delta == 0.0:
		_looks.reset_physics_interpolation()


## Whether the ghost has ended.
func is_done() -> bool:
	return _done


## Ends the ghost: it goes and settled is said (the Mess may draw the Sock again).
func end() -> void:
	if _done:
		return
	_done = true
	settled.emit(sock)
	queue_free()
