## A player's body as the other machines see it: the sock creature (its Looks) at the pose its player
## sends. Its name is the player's peer id, and that player is its multiplayer authority, set in
## _enter_tree() on every machine before the Sync child enters the tree. The Sync (a
## MultiplayerSynchronizer) carries the pose (position, yaw, pitch, crouch) from the owner to everyone
## else every network frame, unreliably (Q2223): the next pose replaces a lost one, and a lost packet
## never holds up the Commands (which are reliable). A late Guest gets the pose with the spawn.
##
## On every machine that receives a pose, a pose that is not finite or lies outside the tuning's area
## is dropped in its setter: the old value stays (the Host's copy included, so a forged pose goes no
## further on it). On the owner's own machine the avatar is hidden and copies `follow`, the local
## player's body.
##
## Elsewhere it is a puppet: the drawn position, yaw and pitch ease toward the pose at `follow` a
## second, the crouch at `crouch_follow` (Q2450); a pose further than `snap` from the last one stands
## there at once (Q2451). Its Looks gets the drawn pitch and crouch and the nearest player's eyes (Q2455)
## and derives every motion from them (Q2461). Its colour and name tag come from the Roster (Q2462);
## its held things hang at its Looks' HoldPoint in its worn HeldView (Q2464). It never reads input.
##
## Knocked down (coop/10): on every machine it follows the level's Knockdowns each frame. Its Ragdoll
## lies down from the knock (the Host simulates it, the others ease to the Host's pose), gets up at the
## rise, stands at the end; meanwhile its Looks copies the ragdoll and its Mate capsule (what a falling
## ragdoll bumps on a standing player) is off. A body lying with a dragger plays "drag_scrape" at its
## feet each `scrape_every` they slide, and lets the dragger walk through it.
##
## Its Back (core/41) is its player's back on this machine: the disc a Teammate climbs and stands on,
## where the body is drawn here. Riding (Q2592): the pose says whose back its player stands on and where
## from their feet; every other machine draws it at that player's drawn feet plus the offset.
class_name Avatar
extends Node3D

## The group every avatar is in: the Hands find a Guest's eyes there (coop/09, G15).
const GROUP := &"avatars"

@export var tuning: AvatarTuning

@export_group("Pose")
## Where its player stands, as the owner sent it (under Players, which sits at the origin).
@export var pose_position := Vector3.ZERO:
	set(value):
		if not _takes(value.is_finite() and _tuning().holds(value)):
			return
		if value.distance_to(pose_position) > _tuning().snap:
			_jumped = true
		pose_position = value
## Its player's turn about the up axis, in radians.
@export var pose_yaw := 0.0:
	set(value):
		if _takes(is_finite(value)):
			pose_yaw = value
## Its player's look up (+) or down (-), in radians.
@export var pose_pitch := 0.0:
	set(value):
		if _takes(is_finite(value) and absf(value) <= deg_to_rad(_tuning().pitch_limit) + 0.001):
			pose_pitch = value
## 1 while its player crouches, 0 standing.
@export var pose_crouch := 0.0:
	set(value):
		if _takes(is_finite(value) and value >= 0.0 and value <= 1.0):
			pose_crouch = value
## The player whose back its player stands on (their peer id), -1 for none (core/41, Q2592).
@export var pose_riding := -1:
	set(value):
		if _takes(value >= -1):
			pose_riding = value
## Where its player stands from the feet of the player they ride, as drawn on its owner's machine.
@export var pose_ride_offset := Vector3.ZERO:
	set(value):
		if _takes(value.is_finite() and value.length() <= _tuning().ride_reach):
			pose_ride_offset = value
## How many jumps its player has made (climbs too): each new one is heard at its body (Q2593).
@export var pose_jumps := 0:
	set(value):
		if _takes(value >= 0):
			pose_jumps = value
@export_group("")

## On the owner's machine: the local player's body this avatar copies every frame. Set by Avatars.
var follow: Node3D
## Who plays: its colour and name come from here. Set by Avatars; null leaves it white and unnamed.
var roster: Roster
## The drawn look pitch (radians) and crouch (0 to 1), easing toward the pose.
var pitch := 0.0
var crouch := 0.0
## How many poses this copy dropped (not finite, or outside the area).
var dropped := 0

## A pose further than `snap` from the last one came: the next frame stands there at once.
var _jumped := false
## The level's Knockdowns (found once), who drags this body now and the bodies let through for them,
## and how far its feet slid since the last scrape.
var _knockdowns: Knockdowns
var _dragger := -1
var _drag_bodies: Array[CollisionObject3D] = []
var _slid := 0.0
var _last_feet := Vector3.INF
## How many drag scrapes it played (a test reads it).
var scrapes := 0

@onready var looks := get_node_or_null(^"Looks") as AvatarLooks
@onready var held := get_node_or_null(^"Held") as HeldView
@onready var ragdoll := get_node_or_null(^"Ragdoll") as Ragdoll
@onready var mate := get_node_or_null(^"Mate") as CollisionObject3D
## While its player rides another here: where it is drawn from that player's drawn feet, easing toward
## the sent offset (INF: not riding here).
var _ride_drawn := Vector3.INF

## Its player's back, which Teammates stand on (core/41; it places itself each physics frame).
@onready var back := get_node_or_null(^"Back") as Back


func _enter_tree() -> void:
	add_to_group(GROUP)
	set_multiplayer_authority(String(name).to_int())


## A spawn sets the pose before _ready: stand there at once instead of gliding from the origin.
func _ready() -> void:
	if tuning == null:
		tuning = AvatarTuning.new()
	_snap()
	if looks != null:
		looks.seed_idle(str(name))
	if held != null and is_multiplayer_authority():
		# This machine's own player sees their Hands in front of the camera, never here.
		held.queue_free()
		held = null
	if held != null:
		held.me = peer()
		held.anchor = looks.hold_point() if looks != null else self
		held.hands = _find_hands()
	if roster != null:
		roster.changed.connect(_dress)
	_dress()


## Its player's peer id.
func peer() -> int:
	return String(name).to_int()


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		# The owner's own copy is hidden and only stands where the pose is.
		_copy_follow()
		position = pose_position
		rotation.y = pose_yaw
		pitch = pose_pitch
		crouch = pose_crouch
		_follow_knockdown()
		return
	var k := minf(1.0, tuning.follow * delta)
	var carrier := carrier_here()
	if carrier != null:
		_ride(carrier, k)
	elif _jumped:
		_snap()
	else:
		_ride_drawn = Vector3.INF
		position = position.lerp(pose_position, k)
	if carrier != null or not _jumped:
		rotation.y = lerp_angle(rotation.y, pose_yaw, k)
		pitch = lerpf(pitch, pose_pitch, k)
	crouch = move_toward(crouch, pose_crouch, tuning.crouch_follow * delta)
	if looks != null:
		looks.look_pitch = pitch
		looks.set_crouch(crouch)
		looks.watch = nearest_eyes()
	_follow_knockdown()


# --- Riding (core/41, Q2592) -----------------------------------------------------------------------

## The avatar of the player its player rides, when that player has one here beside it; else null.
func carrier_here() -> Avatar:
	if pose_riding < 0 or pose_riding == peer() or get_parent() == null:
		return null
	var a := get_parent().get_node_or_null(str(pose_riding)) as Avatar
	return a if a != null and not a.is_queued_for_deletion() else null


## Drawn on the carrier's back: the carrier's drawn feet plus an offset that eases toward the sent one,
## so the rider moves with the carrier at once and only its own steps on the back glide.
func _ride(carrier: Avatar, k: float) -> void:
	var base := Stacks.feet(carrier)
	if _ride_drawn == Vector3.INF:
		_ride_drawn = global_position - base
	_ride_drawn = _ride_drawn.lerp(pose_ride_offset, k)
	global_position = base + _ride_drawn
	_jumped = false


# --- Knocked down (coop/10) ----------------------------------------------------------------------

## Whether its player lies down now (getting up included) on this machine.
func is_down() -> bool:
	return ragdoll != null and ragdoll.phase != Ragdoll.Phase.UP


## The ragdoll follows its player's knockdown here: down at a new knock, up at the rise, standing at the end.
func _follow_knockdown() -> void:
	if ragdoll == null:
		return
	var kd := _find_knockdowns()
	var e := kd.entry_of(peer()) if kd != null else {}
	if e.is_empty():
		if ragdoll.phase != Ragdoll.Phase.UP:
			ragdoll.stand()
			_set_dragger(-1, kd)
			if looks != null:
				looks.end_ragdoll()
			if mate != null:
				mate.collision_layer = Ragdoll.MATE_LAYER
		return
	var n := int(e.get("n", 0))
	if ragdoll.phase == Ragdoll.Phase.UP or ragdoll.serial != n:
		ragdoll.knock(n, Transform3D(Basis(Vector3.UP, float(e.get("yaw", 0.0))), e.get("at", Vector3.ZERO)),
				e.get("push", Vector3.FORWARD), float(e.get("high", 0.5)), float(e.get("side", 0.0)))
		if e.get("pose") is PackedByteArray:
			ragdoll.take(e["pose"])
		_let_through_inside()
		if mate != null:
			mate.collision_layer = 0
		_last_feet = Vector3.INF
	if kd.is_rising(peer()) and ragdoll.phase == Ragdoll.Phase.DOWN:
		ragdoll.rise(_world_yaw())
	_set_dragger(kd.dragger_of(peer()), kd)
	_scrape(kd)
	if looks != null:
		looks.copy_ragdoll(ragdoll.motions())


## E53, E54: the falling body never bumps its own player's walking body, nor a Teammate who stood inside
## it when it was hit (within 2 body radii sideways and the body's height up).
func _let_through_inside() -> void:
	var own := follow as CollisionObject3D
	if own != null:
		ragdoll.except_with(own)
	var parent := get_parent()
	if parent == null:
		return
	var reach := 2.0 * (ragdoll.tuning.body_radius if ragdoll.tuning != null else 0.3)
	for node in parent.get_children():
		var other := node as Avatar
		if other == null or other == self or other.mate == null:
			continue
		var d := other.global_position - global_position
		if Vector2(d.x, d.z).length() <= reach and absf(d.y) <= tuning.stand_height:
			ragdoll.except_with(other.mate)
			var body := other.follow as CollisionObject3D
			if body != null:
				ragdoll.except_with(body)


## H100: the dragger's walking body and Mate pass through the body they pull, on every machine. They
## still do after the drag, until it stands: let go, the body lies round the dragger's legs, and would
## otherwise be flung out of them.
func _set_dragger(by: int, kd: Knockdowns) -> void:
	if by == _dragger:
		return
	_drag_bodies.clear()
	_dragger = by
	if by < 0 or kd == null:
		return
	var a := kd.avatar_of(by)
	if a != null and a.mate != null:
		_drag_bodies.append(a.mate)
	if a != null and a.follow is CollisionObject3D:
		_drag_bodies.append(a.follow as CollisionObject3D)
	for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player != null and player.player_id() == by and player.multiplayer == multiplayer and not _drag_bodies.has(player):
			_drag_bodies.append(player)
	for body in _drag_bodies:
		ragdoll.except_with(body)


## H103: a dragged body's feet scrape the floor: "drag_scrape" there each scrape_every they slide.
func _scrape(kd: Knockdowns) -> void:
	var at := ragdoll.feet()
	if _dragger < 0 or _last_feet == Vector3.INF:
		_last_feet = at
		_slid = 0.0
		return
	_slid += Vector2(at.x - _last_feet.x, at.z - _last_feet.z).length()
	_last_feet = at
	if _slid >= kd.tuning.scrape_every:
		_slid = 0.0
		scrapes += 1
		Sounds.play_at(&"drag_scrape", at)


## Its player's turn about the up axis in the world.
func _world_yaw() -> float:
	var space := get_parent() as Node3D
	var b := Basis(Vector3.UP, pose_yaw)
	if space != null:
		b = space.global_basis * b
	return b.get_euler().y


## The Knockdowns of this avatar's level (with two zoos in one tree, the one whose scene holds it).
func _find_knockdowns() -> Knockdowns:
	if _knockdowns != null and is_instance_valid(_knockdowns):
		return _knockdowns
	for node in get_tree().get_nodes_in_group(Knockdowns.GROUP):
		var k := node as Knockdowns
		if _knockdowns == null or _holds(k):
			_knockdowns = k
	return _knockdowns


## Where the nearest other player's eyes are, within the look range of this body, or null with
## nobody near. Every player has an avatar here (this machine's own too, hidden at its body).
func nearest_eyes() -> Variant:
	var best: Variant = null
	var best_d := tuning.look_range
	var parent := get_parent()
	if parent == null:
		return null
	for node in parent.get_children():
		var other := node as Avatar
		if other == null or other == self or other.is_queued_for_deletion():
			continue
		var d := global_position.distance_to(other.global_position)
		if d <= best_d:
			best_d = d
			best = other.eyes()
	return best


## Where this player's eyes are now, as drawn: the feet, plus the body's height at its crouch, less
## the eyes' distance under the top.
func eyes() -> Vector3:
	var height := lerpf(tuning.stand_height, tuning.crouch_height, crouch)
	return global_position + Vector3.UP * (height - tuning.eye_below_top)


## The owner's copy: the pose is the local body's, as it is now.
func _copy_follow() -> void:
	if follow == null:
		return
	pose_position = follow.global_position
	pose_yaw = follow.global_rotation.y
	var head := follow.get_node_or_null(^"Head") as Node3D  # the Player's look pitch
	if head != null:
		pose_pitch = head.rotation.x
	var player := follow as Player
	if player != null:
		pose_crouch = 1.0 if player.crouching else 0.0
		pose_jumps = player.jumps
		var ride := player.stack().ride if player.stack() != null else null
		if ride != null and is_instance_valid(ride) and ride.avatar != null:
			pose_riding = ride.avatar.peer()
			pose_ride_offset = follow.global_position - Stacks.feet(ride.avatar)
		else:
			pose_riding = -1
			pose_ride_offset = Vector3.ZERO


## Stands at the pose at once. With physics interpolation on, a jump needs reset_physics_interpolation().
func _snap() -> void:
	_jumped = false
	position = pose_position
	rotation.y = pose_yaw
	pitch = pose_pitch
	crouch = pose_crouch
	reset_physics_interpolation()
	if looks != null:
		looks.look_pitch = pitch
		looks.set_crouch(crouch)


## Whether a setter takes a new pose value: always on the owner's copy and before the tree (a spawn),
## and on a receiving copy only when `good`.
func _takes(good: bool) -> bool:
	if good or not is_inside_tree() or is_multiplayer_authority():
		return good or not is_inside_tree()
	dropped += 1
	return false


func _tuning() -> AvatarTuning:
	if tuning == null:
		tuning = AvatarTuning.new()
	return tuning


## Its colour and name from the Roster, once its player has an entry there.
func _dress() -> void:
	if looks == null or roster == null:
		return
	var known := not roster.entry_of(peer()).is_empty()
	looks.colour = roster.colour_of(peer()) if known else Color.WHITE
	looks.player_name = roster.name_of(peer()) if known else ""


## Whether the level of `node` (a Knockdowns, a Hands) holds this avatar.
func _holds(node: Node) -> bool:
	var level := LevelRuntime.level_of(node)
	return level != null and level.is_ancestor_of(self)


## The Hands of this avatar's level: with two zoos in one tree, the one whose scene holds this avatar.
func _find_hands() -> Hands:
	var found: Hands = null
	for node in get_tree().get_nodes_in_group(Hands.GROUP):
		var h := node as Hands
		if found == null or _holds(h):
			found = h
	return found
