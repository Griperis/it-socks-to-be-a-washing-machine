## Who stands on whom, as this machine sees it (core/41). Nothing about a stack is sent or decided
## (Q2591): every machine reads it from where the players' bodies are drawn here. A Teammate stands on a
## back when their feet are within `seen_height` of its top and within its radius plus `seen_slack` of
## it along the floor. Every player has an Avatar on every machine in co-op (this machine's own is hidden
## at the local body), so the avatars are the players.
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


## Whether feet at `at` stand on a back whose top is `top`, as drawn here.
static func on_back(at: Vector3, top: Vector3, t: StackingTuning) -> bool:
	return absf(at.y - top.y) <= t.seen_height \
			and Vector2(at.x - top.x, at.z - top.z).length() <= t.back_radius + t.seen_slack


## The player `a` stands on (the nearest back their feet are on), or null.
static func under(a: Avatar, all: Array[Avatar], t: StackingTuning) -> Avatar:
	if a.is_down():
		return null
	var at := feet(a)
	var best: Avatar = null
	var best_d := INF
	for b in all:
		if b == a or b.is_down():
			continue
		var top := back_top(b, t)
		if not on_back(at, top, t):
			continue
		var d := Vector2(at.x - top.x, at.z - top.z).length()
		if d < best_d:
			best_d = d
			best = b
	return best


## How many players high the stack is up to `a` (1 on the floor, 2 on a back, ...), list 6.
static func level(a: Avatar, all: Array[Avatar], t: StackingTuning) -> int:
	var n := 1
	var at := a
	while n <= DEPTH:
		var below := under(at, all, t)
		if below == null or below == a:
			break
		n += 1
		at = below
	return n


## Whether `a`'s back holds anyone now: not while they lie down, nor on top of a full stack (lists 4, 6).
## In the drum (list 5) waits for the washing machine.
static func holds(a: Avatar, all: Array[Avatar], t: StackingTuning) -> bool:
	return not a.is_down() and level(a, all, t) < t.max_high


## The Teammates standing right on a back whose top is `top` (not lying down, not `except`).
static func riders_at(top: Vector3, all: Array[Avatar], t: StackingTuning, except: Avatar = null) -> Array[Avatar]:
	var out: Array[Avatar] = []
	for b in all:
		if b != except and not b.is_down() and on_back(feet(b), top, t):
			out.append(b)
	return out


## How tall the stack on a back whose top is `top` is, over the top of the body under it: the tallest
## rider and what stands on them, each `ride_sink` lower (list 29), over at most DEPTH levels.
static func load_on(top: Vector3, all: Array[Avatar], t: StackingTuning, except: Avatar = null, depth := 0) -> float:
	var most := 0.0
	if depth > DEPTH:
		return most
	for r in riders_at(top, all, t, except):
		most = maxf(most, height(r) - t.ride_sink + load_on(back_top(r, t), all, t, r, depth + 1))
	return most
