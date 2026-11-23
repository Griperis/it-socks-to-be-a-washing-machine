## The local player's side of stacking (core/41, list docs/migration/m3-lists/01-player-stacking.md) and
## the soft push (Q263): a child of the Player, which calls it around its own move each physics frame.
## Every machine does this for its own player only, from the Teammates as drawn here (Q2591: nothing is
## sent or decided).
##
## Before the move: the body meets a Teammate's back only from above (feet at its top less
## `touch_slack` or higher, or the back it rides), else passes through it (lists 9-11); never its own
## (list 8). Riding a back, the body moves by what the back moved since the last frame (list 21). With
## anyone on its back the pace is `carry_speed` (list 28) and standing up needs room for the stack too
## (list 29). A jump near a back that holds riders, higher than half a jump and with room over it for a
## crouched body, is a climb (lists 13-15); in the air the climber steers over its middle until it lands
## (lists 16, 17). After the move: the back under the feet is the one ridden (lists 20, 35, 38); a body
## landed on a lying one slips off it (list 32). The push: a Teammate nearer than `push_apart` at about
## the same height pushes this player away; a body this player drags does not (lists 45-49).
class_name PlayerStack
extends Node

@export var tuning: StackingTuning

## The back this player stands on, or null; where it was at the last frame.
var ride: Back = null
var _ride_at := Vector3.ZERO
## The back a climb is steering onto, until the climber lands; null otherwise.
var climb_to: Back = null
## The share of the pace left (carry_speed while anyone stands on this player's back), and how tall
## the stack on the back is over the top of the body (m).
var carry := 1.0
var load_height := 0.0
## The slip off a lying body this frame (m/s along the floor).
var slip := Vector3.ZERO

var _player: Player
## The Teammates on this machine, found once a frame (before_move()).
var _all: Array[Avatar] = []
## The backs this body passes through now (by instance id).
var _through: Dictionary[int, Back] = {}


func _ready() -> void:
	_player = get_parent() as Player
	if tuning == null:
		tuning = StackingTuning.new()


## Before the body's own move: who is here, which backs it meets, the ride's carry, the load.
func before_move() -> void:
	_all = Stacks.peers(_player)
	_meet_backs()
	_carry_ride()
	var riders := Stacks.riders_at(top(), _all, tuning, own_avatar())
	carry = tuning.carry_speed if not riders.is_empty() else 1.0
	load_height = Stacks.load_on(top(), _all, tuning, own_avatar())


## Lying down or a menu that ends play: no ride, no climb.
func drop() -> void:
	ride = null
	climb_to = null
	slip = Vector3.ZERO


## Whether the player must stay crouched: while climbing and while riding (list 22).
func keeps_crouched() -> bool:
	return ride != null or climb_to != null


## The top of this player's own back (list 2), from the body as it is now.
func top() -> Vector3:
	return _player.global_position + Vector3.UP * (_player.body_height() - tuning.ride_sink)


## This machine's own avatar (hidden at the local body), or null alone.
func own_avatar() -> Avatar:
	var me := _player.player_id()
	for a in _all:
		if a.peer() == me:
			return a
	return null


## The Teammates' avatars (not this player's own).
func _others() -> Array[Avatar]:
	var me := _player.player_id()
	return _all.filter(func(a: Avatar) -> bool: return a.peer() != me)


## Lists 8-11: through every back but one met from above or ridden.
func _meet_backs() -> void:
	var feet := _player.global_position.y
	var me := _player.player_id()
	var seen: Dictionary[int, bool] = {}
	for a in _all:
		var back := a.back
		if back == null:
			continue
		var id := back.get_instance_id()
		seen[id] = true
		var touch := a.peer() != me and (back == ride or feet >= back.top().y - tuning.touch_slack)
		if touch and _through.has(id):
			_player.remove_collision_exception_with(back)
			_through.erase(id)
		elif not touch and not _through.has(id):
			_player.add_collision_exception_with(back)
			_through[id] = back
	for id: int in _through.keys():
		if not seen.has(id):
			_through.erase(id)  # its avatar went (list 37)


## List 21: the body moves by what the ridden back moved since the last frame; a back that went or
## holds no one any more lets the rider fall (lists 4, 32, 37).
func _carry_ride() -> void:
	if ride == null:
		return
	if not is_instance_valid(ride) or not ride.is_inside_tree() or not ride.holds():
		ride = null
		return
	var at := ride.top()
	_player.global_position += at - _ride_at
	_ride_at = at


## Lists 13, 19: the back a jump now climbs onto, or null for an ordinary jump: the nearest within
## `climb_reach` along the floor that holds riders, higher over the feet than half an ordinary jump
## reaches, with room over it for a crouched body under the ceiling and furniture.
func climb_target() -> Back:
	var me := _player.global_position
	var move := _player.tuning
	var apex := move.jump_speed * move.jump_speed / (2.0 * move.gravity)
	var best: Back = null
	var best_d := tuning.climb_reach
	for a in _others():
		var back := a.back
		if back == null or not back.holds():
			continue
		var at := back.top()
		var d := Vector2(at.x - me.x, at.z - me.z).length()
		if d > best_d or at.y - me.y <= apex * 0.5 or not room_over(at):
			continue
		best_d = d
		best = back
	return best


## Whether a crouched body fits standing on a back whose top is `at` (list 13c).
func room_over(at: Vector3) -> bool:
	var from := at + Vector3.UP * tuning.room_start
	var to := at + Vector3.UP * (_player.tuning.crouch_height + tuning.climb_clear)
	return PhysicsQueries.ray(_player, from, to, Mess.LAYER_HOUSE | Player.BLOCK_LAYER, [_player.get_rid()]).is_empty()


## List 14: the jump speed that clears `back` by `climb_clear`, never under an ordinary jump.
func climb_speed(back: Back) -> float:
	var move := _player.tuning
	var high := back.top().y - _player.global_position.y + tuning.climb_clear
	return maxf(move.jump_speed, sqrt(2.0 * move.gravity * maxf(high, 0.0)))


## What is added to the walk along the floor this frame: the push, the slip and a climb's steering.
func extra_velocity() -> Vector3:
	var out := push() + slip
	if climb_to != null and is_instance_valid(climb_to):
		var off := climb_to.top() - _player.global_position
		out += Vector3(off.x, 0.0, off.z) * tuning.climb_steer
	return out


## Lists 45-49: each Teammate standing nearer than `push_apart` at about the same height pushes this
## player away at (push_apart - gap) * push_rate; exactly on each other the lower id goes right.
func push() -> Vector3:
	var out := Vector3.ZERO
	var me := _player.global_position
	var my_id := _player.player_id()
	var kd := _player.knockdowns()
	var level := _player.tuning.crouch_height * 0.5
	for a in _others():
		var them := Stacks.feet(a)
		if absf(them.y - me.y) > level:
			continue  # one stands on, or climbs onto, the other (list 48)
		if kd != null and kd.dragger_of(a.peer()) == my_id:
			continue  # the body this player drags (list 49)
		var off := Vector3(me.x - them.x, 0.0, me.z - them.z)
		var gap := off.length()
		if gap >= tuning.push_apart:
			continue
		var dir := off / gap if gap > tuning.push_same else Vector3.RIGHT * (1.0 if my_id < a.peer() else -1.0)
		out += dir * (tuning.push_apart - gap) * tuning.push_rate
	return out


## After the body's own move: the back under the feet is ridden (a climb ends on any floor), and a body
## standing on a lying one slips off it.
func after_move() -> void:
	var under: Back = null
	slip = Vector3.ZERO
	for i in _player.get_slide_collision_count():
		var c := _player.get_slide_collision(i)
		var body := c.get_collider() as CollisionObject3D
		if body == null:
			continue
		if body is Back and _player.is_on_floor() and c.get_normal().y > tuning.ride_normal and under == null:
			under = body as Back
		elif body.collision_layer & Ragdoll.LAYER and c.get_normal().y >= tuning.slip_normal and slip == Vector3.ZERO:
			var away := _player.global_position - body.global_position
			away.y = 0.0
			if away.length() < 0.01:
				away = Vector3(c.get_normal().x, 0.0, c.get_normal().z)
			if away.length() < 0.01:
				away = _player.global_basis.z
			slip = away.normalized() * tuning.slip_speed
	if _player.is_on_floor():
		climb_to = null
		# Standing still on a back the body only snaps to it (no collision is reported): it keeps the
		# back it stands on.
		if under == null and ride != null and is_instance_valid(ride) and ride.holds() and _stands_on(ride):
			under = ride
	if under != ride:
		ride = under
		if ride != null:
			_ride_at = ride.top()


## Whether the feet are on `back` now: at its top, and over the disc as far as the body's round bottom
## reaches.
func _stands_on(back: Back) -> bool:
	var off := _player.global_position - back.top()
	return absf(off.y) <= tuning.touch_slack and Vector2(off.x, off.z).length() <= tuning.back_radius + _player.tuning.radius
