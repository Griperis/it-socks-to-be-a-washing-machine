## A Guest's own Throw or drop, drawn at once (Q2221, Q2473; list 03 G02-G13, E01-E03): a looks-only
## body on Mess.LAYER_GHOST that touches the static house only, flying from the hand with the launch
## this machine works out itself, and the Sock's Looks drawn on it. It never wakes, rests, puts or
## writes anything (G10, I2): GuestGhosts makes it, the Mess holds its own drawing of the Sock back
## meanwhile, and it goes when told.
##
## Once the Host's body exists here (the stamped copy of a Throw, or a drop's own local body), the
## ghost stays drawn on its own body all the way, moved only by how the Host's body differs at the same
## moment of the flight (G03, G05): each tick its offset moves `1 - exp(-3 dt / predict_blend)` of the
## way to that difference, position and turn (G04, G11). When the Host's body has come to rest, the
## ghost eases onto the rest pose and is done once nearer than `settle_close` or after `settle_wait`
## (G07).
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
## The drawn offset from the ghost's body: a move and a turn.
var _off := Vector3.ZERO
var _turn := Quaternion.IDENTITY
## When the Host's local body (a drop's) was first seen, in this ghost's age.
var _ref_seen := -1.0
## Easing onto the Host's rest: the time it has eased, or -1 before.
var _resting := -1.0
var _rest_pose := Transform3D.IDENTITY
var _done := false


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
	_body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	_body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	if drop or pair:
		_body.linear_damp = hands.pair_linear_damp if pair else t.woken_linear_damp
		_body.angular_damp = hands.pair_angular_damp if pair else t.woken_angular_damp
	else:
		_body.linear_damp = hands.thrown_linear_damp
		_body.angular_damp = hands.thrown_angular_damp
	_body.linear_velocity = launch["vel"]
	_body.angular_velocity = launch["spin"]
	if not pair:
		_body.inertia = MessMoving.turn_inertia(_body.mass, SockDress.box(design), t.turn_weight)
	_body.transform = launch["from"]
	add_child(_body)
	_body.reset_physics_interpolation()
	_looks = SockDress.make(design, SockDress.LYING, pair)
	_looks.name = "Looks"
	_looks.top_level = true
	add_child(_looks)
	_poses.append([0.0, _body.global_transform])
	_draw(0.0)


## The ghost's body (tests read where it is).
func body() -> RigidBody3D:
	return _body


## Where the ghost is drawn now, in the level (its Size included).
func drawn() -> Transform3D:
	return _looks.global_transform if _looks != null and _looks.is_inside_tree() else Transform3D.IDENTITY


## The drawn offset from the ghost's own body now (G04).
func offset() -> Vector3:
	return _off


func _physics_process(delta: float) -> void:
	if _done or _body == null:
		return
	_age += delta
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
			_off = _off.lerp(host.origin - own.origin, k)
			var diff := (host.basis.get_rotation_quaternion() * own.basis.get_rotation_quaternion().inverse()).normalized()
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
		end()


## The ghost's body pose with the offset on it.
func _drawn_pose() -> Transform3D:
	var own := _body.global_transform.orthonormalized()
	return Transform3D(Basis(_turn) * own.basis, own.origin + _off)


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
