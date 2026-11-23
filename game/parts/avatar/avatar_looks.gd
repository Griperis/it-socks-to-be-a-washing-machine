## The avatar's Looks: the old game's sock creature (assets/avatar/avatar.glb, coop/04), moving as the
## old game's avatar.gd did (coop/05, Q2461), every number from the AvatarTuning. It only shows: the
## Avatar feeds it the drawn pitch, crouch and who to look at; the rest it derives from how it moves.
##
## - Walking: the speed along the floor (x and z), smoothed, sets how much it waddles: the feet rock
##   about x and z in turn, the Body bobs and sways. The feet stay on the floor while the Body moves
##   (held against it: they are the model's children of the Body).
## - The look bend: looking down the top of the sock curls forward over the belly, looking up it leans
##   back; each of the three spine joints turns a third, pivoting where the Crouch took it. The pupils,
##   HoldPoint, Head (the name tag) and HatPoint ride the bones their `bend_weights` extras name.
## - Crouch: the body's `Crouch` shape key, and the points moved by their `crouch_offset` extras.
## - Squash and stretch: a stretch tall as it leaves the floor, a squish flat as it lands (by the fall
##   height), springing back; the whole Looks scales about the feet, keeping its volume.
## - Pupils: turned to `watch` (the nearest player's eyes, within range and in front), else drifting.
## - Colour: the `player` surface takes `colour`, the `trim` (body and feet) that colour darkened; the
##   name tag over the Head says `player_name` in the colour lightened (none without a name).
## - First person (coop/06, Q2466): the local player's own body seen from their eyes, the same Looks
##   with `first_person` set. Only the feet and the belly below `belly_cut` (BellyMesh, made at load),
##   set back by `belly_back` so its front curve shows looking down, its outside alone drawn; no
##   pupils (they do not turn), no name tag, no shadow. The Player drives its pitch and crouch.
## - Knocked down (coop/10): copy_ragdoll() places the whole creature by the ragdoll's Root and bends
##   it by the other three bones, so the pupils, HoldPoint, Head (the name tag) and HatPoint ride along;
##   the walk, bend, crouch and squash stop and are reset while it lies, and come back at end_ragdoll().
## The nodes the avatar's behaviour may lean on are named in looks_contract.json beside it.
class_name AvatarLooks
extends Node3D

## The body's surfaces that take the player's colour, and a darker shade of it.
const TINTED := &"player"
const TRIM := &"trim"
## The skinned body inside the model.
const BODY := ^"Body/Armature/Skeleton3D/Avatar"

@export var tuning: AvatarTuning

## The player's colour on the body. White shows the model as made (the trim too).
@export var colour := Color.WHITE:
	set(value):
		colour = value
		if is_node_ready():
			_tint()
## The player's own body seen from their eyes (set before it enters the tree).
@export var first_person := false
## The name over the head; empty shows no tag.
@export var player_name := "":
	set(value):
		player_name = value
		if is_node_ready():
			_tint()

## The look pitch (radians, + up): the bend eases toward it.
var look_pitch := 0.0
## Where the nearest player's eyes are (global), or null: the pupils turn there.
var watch: Variant = null
## 0 standing, 1 crouched (set_crouch()).
var crouch := 0.0
## How far it bends now, in degrees: + curls forward over the belly, - leans back.
var bend := 0.0
## 0 standing still, 1 waddling fully.
var walk := 0.0
## Whether it copies a ragdoll now (copy_ragdoll()).
var ragdolled := false

var _body: Node3D
var _mesh: MeshInstance3D
var _skeleton: Skeleton3D
var _tag: Label3D
var _feet: Array[MeshInstance3D] = []
## Where each foot's ankle stands in the Looks' space.
var _feet_rest: Array[Vector3] = []
var _pupils: Array[Node3D] = []
var _blend := -1
var _body_rest := Vector3.ZERO
## Node -> [its standing position, its full move at Crouch, its rest rotation, its bend_weights].
var _drops: Dictionary[Node3D, Array] = {}
var _pupil_rest: Array[Quaternion] = []
var _pupil_look: Array[Quaternion] = []
var _bone_rest: Array[Transform3D] = []
var _joint_crouch: Array[Vector3] = []
var _moves: Array[Transform3D] = []
var _posed := Vector2.INF
var _phase := 0.0
var _speed := 0.0
var _last := Vector3.INF
var _wander := Vector2.ZERO
var _wander_left := 0.0
var _rng := RandomNumberGenerator.new()
var _last_y := INF
var _rise := 0.0
var _fall := 0.0
var _squash := 0.0
var _squash_speed := 0.0
var _airborne := false


func _ready() -> void:
	if tuning == null:
		tuning = AvatarTuning.new()
	_body = get_node(^"Body") as Node3D
	_mesh = body()
	_skeleton = _mesh.get_parent() as Skeleton3D
	_tag = _body.get_node_or_null(^"Head/NameTag") as Label3D
	for side: String in ["L", "R"]:
		var foot := _body.get_node(NodePath("Foot" + side)) as MeshInstance3D
		_feet.append(foot)
		_feet_rest.append((_body.transform * foot.transform).origin)
		_pupils.append(_body.get_node(NodePath("Pupil" + side)) as Node3D)
	var joints: Array = ((_skeleton.get_parent() as Node).get_meta("extras", {}) as Dictionary).get("bend_crouch_offset", [])
	for b: int in _skeleton.get_bone_count():
		_bone_rest.append(_skeleton.get_bone_global_rest(b))
		var j: Array = joints[b] if b < joints.size() else [0.0, 0.0, 0.0]
		_joint_crouch.append(Vector3(float(j[0]), float(j[1]), float(j[2])))
		_moves.append(Transform3D.IDENTITY)
	for p: Node3D in _pupils:
		_pupil_rest.append(p.quaternion)
		_pupil_look.append(p.quaternion)
	for n: Node3D in [hold_point(), head(), _body.get_node(^"HatPoint") as Node3D] + _pupils:
		var extras: Dictionary = n.get_meta("extras", {})
		var off: Array = extras.get("crouch_offset", [0.0, -float(extras.get("crouch_drop", 0.0)), 0.0])
		var w: Array = extras.get("bend_weights", [1.0])
		_drops[n] = [n.position, Vector3(float(off[0]), float(off[1]), float(off[2])), n.quaternion, PackedFloat32Array(w)]
	if first_person:
		_make_first_person()
	_blend = _mesh.find_blend_shape_by_name(&"Crouch")
	_body_rest = _body.position
	_tint()


## The own body: the belly alone (keeping the Crouch shape key), set back behind the eyes; the feet
## stay where they stand (their rest is taken before). No pupils, no tag, no shadows.
func _make_first_person() -> void:
	_mesh.mesh = BellyMesh.cut(_mesh.mesh as ArrayMesh, tuning.belly_cut, TINTED)
	_body.position.z += tuning.belly_back
	for i: int in _feet.size():
		_feet[i].position.z -= tuning.belly_back  # held where they stand (the waddle keeps them there)
	for p: Node3D in _pupils:
		p.visible = false
	if _tag != null:
		_tag.visible = false
	for m: GeometryInstance3D in [_mesh] + _feet:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The body mesh, skinned to the four-bone spine.
func body() -> MeshInstance3D:
	return get_node(BODY) as MeshInstance3D


## Where held things hang (the Teammate's worn HeldView follows it).
func hold_point() -> Node3D:
	return get_node(^"Body/HoldPoint") as Node3D


## Where the HoldPoint is as an avatar of this body draws it: the first-person body's own is set
## back by `belly_back` with the Body (coop/11: a Guest's Throw starts where the Host's avatar holds it).
func avatar_hold() -> Transform3D:
	var at := hold_point().global_transform
	if not first_person:
		return at
	return at.translated(-(global_basis * Vector3(0.0, 0.0, tuning.belly_back)))


## The top of the cuff, where the name tag floats.
func head() -> Node3D:
	return get_node(^"Body/Head") as Node3D


## The name tag, or null.
func tag() -> Label3D:
	return _tag


## The two feet (left, right), which rock while it walks.
func feet() -> Array[MeshInstance3D]:
	return _feet


## The Body: everything that bobs and sways (all but the feet).
func swaying() -> Node3D:
	return _body


## Seeds the pupils' idle drift from the player's id, so one player idles the same way every time.
func seed_idle(text: String) -> void:
	_rng.seed = hash(text)


## Crouches by `weight` (0 standing, 1 crouched): the shape key, and the points moving with it.
func set_crouch(weight: float) -> void:
	crouch = clampf(weight, 0.0, 1.0)
	if ragdolled:
		return  # a lying body copies its ragdoll (copy_ragdoll())
	if _blend >= 0:
		_mesh.set_blend_shape_value(_blend, crouch)
	_pose()


## How far pupil `i` turns off its rest now (the bend aside), in degrees.
func pupil_turn(i: int) -> float:
	return rad_to_deg((_pupil_rest[i] * Vector3.FORWARD).angle_to(_pupil_look[i] * Vector3.FORWARD))


func _process(delta: float) -> void:
	if delta <= 0.0 or not is_visible_in_tree():
		return
	if ragdolled:
		_look(delta)
		return
	_waddle(delta)
	_bend(delta)
	_squash_jump(delta)
	_look(delta)


# --- Colour and tag ------------------------------------------------------------------------------

func _tint() -> void:
	for mi: MeshInstance3D in [_mesh] + _feet:
		for i: int in mi.mesh.get_surface_count():
			var made := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if made == null or not made.resource_name in [TINTED, TRIM]:
				continue
			var own_belly := first_person and mi == _mesh
			if colour == Color.WHITE and not own_belly:
				mi.set_surface_override_material(i, null)  # as made
				continue
			var paint := made.duplicate() as BaseMaterial3D
			if colour != Color.WHITE:
				paint.albedo_color = colour if made.resource_name == TINTED else colour.darkened(tuning.trim_darken)
			if own_belly:
				paint.cull_mode = BaseMaterial3D.CULL_BACK  # the cut belly's outside only
			mi.set_surface_override_material(i, paint)
	if _tag != null:
		_tag.text = player_name
		_tag.visible = player_name != "" and not first_person
		_tag.modulate = colour.lightened(tuning.tag_lighten)


# --- Walking -------------------------------------------------------------------------------------

## The feet rock about x and z in turn and the Body bobs and sways, as far as it walks: the speed is
## how far it moved along the floor, smoothed, so it holds at any frame rate.
func _waddle(delta: float) -> void:
	var at := global_position
	var moved := 0.0
	if _last != Vector3.INF:
		moved = Vector2(at.x - _last.x, at.z - _last.z).length()
		if moved > tuning.teleport:
			moved = 0.0  # a teleport, not a walk
	_last = at
	_speed = lerpf(_speed, moved / delta, 1.0 - exp(-delta / tuning.waddle_smooth))
	walk = move_toward(walk, clampf(_speed / tuning.walk_speed, 0.0, 1.0), delta * tuning.walk_rate)
	_phase = fmod(_phase + _speed * delta / tuning.stride * TAU, TAU)
	var s := sin(_phase)
	var swing := deg_to_rad(tuning.foot_swing) * walk
	var roll := deg_to_rad(tuning.foot_roll) * walk
	_body.position = _body_rest + Vector3.UP * tuning.bob * absf(s) * walk
	_body.rotation.z = deg_to_rad(tuning.sway) * s * walk
	# The feet are the model's, under the Body: they are held where they stand on the floor, against
	# the Body's bob and sway, and only rock.
	var back := _body.transform.affine_inverse()
	_feet[0].transform = back * Transform3D(Basis.from_euler(Vector3(swing * s, 0.0, roll * s)), _feet_rest[0])
	_feet[1].transform = back * Transform3D(Basis.from_euler(Vector3(-swing * s, 0.0, roll * s)), _feet_rest[1])


# --- The look bend -------------------------------------------------------------------------------

## The bend the look `pitch` (radians, + up) asks for, in degrees.
func bend_for(pitch: float) -> float:
	var share := clampf(pitch / deg_to_rad(tuning.pitch_limit), -1.0, 1.0)
	return -share * (tuning.bend_down if share < 0.0 else tuning.bend_up)


func _bend(delta: float) -> void:
	var want := bend_for(look_pitch)
	if absf(want - bend) < 0.001:
		return
	bend = lerpf(bend, want, minf(1.0, delta * tuning.bend_speed))
	_pose()


## Each bone's move (skeleton space) at a bend of `degrees` and a crouch of `weight`: Root stays,
## each joint turns a third of the bend about x, pivoting where the Crouch took it.
func bend_moves(degrees: float, weight: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = [Transform3D.IDENTITY]
	var per := -deg_to_rad(degrees) / float(maxi(1, _bone_rest.size() - 1))
	for b: int in range(1, _bone_rest.size()):
		var c := _bone_rest[b].origin + _joint_crouch[b] * weight
		var turn := Transform3D(Basis(Vector3.RIGHT, per), c) * Transform3D(Basis.IDENTITY, -c)
		out.append(out[b - 1] * turn)
	return out


func _pose() -> void:
	if Vector2(bend, crouch) == _posed:
		return
	_posed = Vector2(bend, crouch)
	_moves = bend_moves(bend, crouch)
	for b: int in _moves.size():
		_skeleton.set_bone_global_pose(b, _moves[b] * _bone_rest[b])
	for n: Node3D in _drops:
		var d: Array = _drops[n]
		var at := (d[0] as Vector3) + (d[1] as Vector3) * crouch
		n.position = _ride(d[3], at)
		var i := _pupils.find(n)
		n.quaternion = _turn(d[3]) * (_pupil_look[i] if i >= 0 else (d[2] as Quaternion))


## Where a point at `at` (body space, unbent) goes with the bones in `weights`, as the skin does.
func _ride(weights: PackedFloat32Array, at: Vector3) -> Vector3:
	var out := Vector3.ZERO
	for b: int in mini(weights.size(), _moves.size()):
		out += weights[b] * (_moves[b] * at)
	return out


## How a node riding the bones in `weights` turns with them.
func _turn(weights: PackedFloat32Array) -> Quaternion:
	var v := Vector3.ZERO
	for b: int in mini(weights.size(), _moves.size()):
		var q := _moves[b].basis.get_rotation_quaternion()
		if q.w < 0.0:
			q = -q
		var angle := q.get_angle()
		if angle > 0.000001:
			v += weights[b] * q.get_axis() * angle
	return Quaternion(v.normalized(), v.length()) if v.length() > 0.000001 else Quaternion.IDENTITY


# --- Knocked down (coop/10) --------------------------------------------------------------------

## Lies as the ragdoll does: `moves` are how each of the four bones moved from standing at the origin
## to now, in the world (Ragdoll.motions()). The first places the whole creature, the others bend it.
func copy_ragdoll(moves: Array[Transform3D]) -> void:
	if moves.size() < _bone_rest.size():
		return
	if not ragdolled:
		ragdolled = true
		walk = 0.0
		_squash = 0.0
		_squash_speed = 0.0
		scale = Vector3.ONE
		_body.position = _body_rest
		_body.rotation = Vector3.ZERO
		for i: int in _feet.size():
			_feet[i].transform = _body.transform.affine_inverse() * Transform3D(Basis.IDENTITY, _feet_rest[i])
		crouch = 0.0
		if _blend >= 0:
			_mesh.set_blend_shape_value(_blend, 0.0)
	global_transform = moves[0]
	var back := moves[0].affine_inverse()
	for b: int in _bone_rest.size():
		_moves[b] = back * moves[b]
		_skeleton.set_bone_global_pose(b, _moves[b] * _bone_rest[b])
	for n: Node3D in _drops:
		var d: Array = _drops[n]
		n.position = _ride(d[3], d[0] as Vector3)
		var i := _pupils.find(n)
		n.quaternion = _turn(d[3]) * (_pupil_look[i] if i >= 0 else (d[2] as Quaternion))
	_posed = Vector2.INF


## Stands again where its avatar is: the walk, bend, crouch and squash take over.
func end_ragdoll() -> void:
	if not ragdolled:
		return
	ragdolled = false
	transform = Transform3D.IDENTITY
	_last = Vector3.INF
	_last_y = INF
	_posed = Vector2.INF
	set_crouch(crouch)


# --- Squash and stretch --------------------------------------------------------------------------

## Read from how it moves up and down, so a Teammate's avatar, moved by their pose, does it too.
func _squash_jump(delta: float) -> void:
	var y := global_position.y
	var vy := 0.0
	if _last_y != INF and absf(y - _last_y) <= tuning.teleport:
		vy = (y - _last_y) / delta
	_last_y = y
	_rise = lerpf(_rise, vy, 1.0 - exp(-delta / tuning.squash_smooth))
	if not _airborne and _rise > tuning.squash_takeoff_speed:
		_airborne = true
		_squash = tuning.squash_stretch
		_squash_speed = 0.0
	if _rise < 0.0:
		_airborne = false
		_fall = maxf(_fall, -_rise)
	if _fall > 0.0 and _rise > -1.0:  # it stopped falling
		var drop := _fall * _fall / (2.0 * tuning.gravity)
		if drop >= tuning.squash_min_fall:
			_squash = -tuning.squash_squish * clampf(drop / tuning.squash_full_fall, 0.0, 1.0)
			_squash_speed = 0.0
		_fall = 0.0
	var w := TAU * tuning.squash_freq
	_squash_speed += (-w * w * _squash - 2.0 * tuning.squash_damping * w * _squash_speed) * delta
	_squash += _squash_speed * delta
	var tall := 1.0 + _squash
	var wide := 1.0 / sqrt(tall)
	scale = Vector3(wide, tall, wide) if absf(_squash) > 0.0005 else Vector3.ONE


# --- Pupils --------------------------------------------------------------------------------------

## The pupils turn to `watch` when it is in front and within range, at most `look_max` off their
## rest; otherwise they drift a little round it, a new drift every `wander_time` (0.6 to 1.4 times).
func _look(delta: float) -> void:
	if first_person:
		return
	_wander_left -= delta
	if _wander_left <= 0.0:
		_wander_left = tuning.wander_time * _rng.randf_range(0.6, 1.4)
		var wa := deg_to_rad(tuning.wander)
		_wander = Vector2(_rng.randf_range(-wa, wa), _rng.randf_range(-wa * 0.5, wa * 0.5))
	var limit := deg_to_rad(tuning.look_max)
	var near := watch is Vector3 and global_position.distance_to(watch) <= tuning.look_range
	var k := minf(1.0, delta * tuning.look_speed)
	for i: int in _pupils.size():
		var p := _pupils[i]
		var rest := _pupil_rest[i]
		var bent := _turn(_drops[p][3])
		var forward := rest * Vector3.FORWARD
		var to := forward.rotated(Vector3.UP, _wander.x).rotated(rest * Vector3.RIGHT, _wander.y)
		if near:
			var d := bent.inverse() * (_body.to_local(watch) - p.position)
			if d.length() > 0.01 and forward.angle_to(d) <= deg_to_rad(tuning.look_cone):
				to = d.normalized()
		var off_rest := forward.angle_to(to)
		if off_rest > limit:
			to = forward.rotated(forward.cross(to).normalized(), limit)
		var aim := (Quaternion(forward, to) * rest) if off_rest > 0.0001 else rest
		_pupil_look[i] = _pupil_look[i].slerp(aim, k)
		p.quaternion = bent * _pupil_look[i]
