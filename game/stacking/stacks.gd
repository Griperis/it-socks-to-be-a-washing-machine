## Who stands on whom, as this machine sees it (core/41). Nothing about a stack is decided: each player's
## pose says whose back they stand on (Avatar.pose_riding, Q2592), written by their own machine from the
## back their body stands on. Every player has an Avatar on every machine in co-op (this machine's own is
## hidden at the local body, its pose this player's), so the avatars are the players.
class_name Stacks
extends RefCounted

## The most levels a stack is walked through (the old game's 4).
const DEPTH := 4


## The avatars that share `node`'s machine (with two zoos in one tree, its own zoo's), not leaving.
static func peers(node: Node) -> Array[Avatar]:
	var out: Array[Avatar] = []
	if node == null or not node.is_inside_tree():
		return out
	for n in node.get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := n as Avatar
		if a != null and not a.is_queued_for_deletion() and a.multiplayer == node.multiplayer:
			out.append(a)
	return out


## Where `a`'s feet are on this machine: the local body for this machine's own avatar, else as drawn.
static func feet(a: Avatar) -> Vector3:
	var own := a.follow as Node3D
	return own.global_position if own != null and is_instance_valid(own) else a.global_position


## How tall `a`'s body is now: crouched or standing as its pose says, at once (list 3).
static func height(a: Avatar) -> float:
	var t := a.tuning if a.tuning != null else AvatarTuning.new()
	return lerpf(t.stand_height, t.crouch_height, a.pose_crouch)


## The top of `a`'s back: `ride_sink` under the top of its body (list 2).
static func back_top(a: Avatar, t: StackingTuning) -> Vector3:
	return feet(a) + Vector3.UP * (height(a) - t.ride_sink)


## The player `a` stands on: the one its pose says it rides (Q2592), when they are here and up; or null.
static func under(a: Avatar, all: Array[Avatar]) -> Avatar:
	if a.is_down() or a.pose_riding < 0:
		return null
	for b in all:
		if b != a and b.peer() == a.pose_riding and not b.is_down():
			return b
	return null


## How many players high the stack is up to `a` (1 on the floor, 2 on a back, ...), list 6.
static func level(a: Avatar, all: Array[Avatar]) -> int:
	var n := 1
	var at := a
	while n <= DEPTH:
		var below := under(at, all)
		if below == null or below == a:
			break
		n += 1
		at = below
	return n


## Whether `a`'s back holds anyone now: not while they lie down, nor on top of a full stack (lists 4, 6).
## In the drum (list 5) waits for the washing machine.
static func holds(a: Avatar, all: Array[Avatar], t: StackingTuning) -> bool:
	return not a.is_down() and level(a, all) < t.max_high


## The players standing right on player `peer`'s back, as their poses say (not lying down).
static func riders_of(peer: int, all: Array[Avatar]) -> Array[Avatar]:
	var out: Array[Avatar] = []
	for b in all:
		if b.peer() != peer and b.pose_riding == peer and not b.is_down():
			out.append(b)
	return out


## How tall the stack on player `peer`'s back is, over the top of their body: the tallest rider and
## what stands on them, each `ride_sink` lower (list 29), over at most DEPTH levels.
static func load_of(peer: int, all: Array[Avatar], t: StackingTuning, depth := 0) -> float:
	var most := 0.0
	if depth > DEPTH:
		return most
	for r in riders_of(peer, all):
		most = maxf(most, height(r) - t.ride_sink + load_of(r.peer(), all, t, depth + 1))
	return most
