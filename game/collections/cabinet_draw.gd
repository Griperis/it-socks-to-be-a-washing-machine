## The New Game's draw of each Cabinet spot's Collection (core/135, the old CabinetPools.draw, CPO:193-262):
## one unlocked, not held-back Collection per spot out of the spot's pool, never one twice, the shared
## pools solved by backtracking so every spot is filled. Rules only: the Cabinets' pools go in, the drawn
## Collections come out, random by the `rng` it is given (the same seed draws the same).
class_name CabinetDraw
extends RefCounted


## The Collections a spot with `pool` may draw, in pool order: unlocked, not held back, not in `taken`.
static func candidates(pool: Array[StringName], unlocked: Array[StringName], taken: Array[StringName] = []) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in pool:
		var c := Collections.of(id)
		if c != null and not c.held_back and unlocked.has(id) and not taken.has(id) and not out.has(id):
			out.append(id)
	return out


## Why the draw of `pools` (one pool per spot) cannot fill every spot, one line each; empty when it can.
static func problems(pools: Array, unlocked: Array[StringName], taken: Array[StringName] = []) -> PackedStringArray:
	var out := PackedStringArray()
	var cands := _candidates(pools, unlocked, taken)
	for i in cands.size():
		if (cands[i] as Array).is_empty():
			out.append("spot %d has no unlocked Collection in its pool %s" % [i, pools[i]])
	if out.is_empty() and not cands.is_empty() and _solve(_order(cands), cands, 0, {}).is_empty():
		out.append("the pools cannot fill all %d spots without a repeat (unlocked %s)" % [cands.size(), unlocked])
	return out


## One Collection per spot of `pools` (an Array of pools, each an Array[StringName]), in the spots' order.
## Empty when it cannot be filled (see `problems`) or there are no spots.
static func draw(pools: Array, unlocked: Array[StringName], rng: RandomNumberGenerator, taken: Array[StringName] = []) -> Array[StringName]:
	var out: Array[StringName] = []
	if pools.is_empty() or not problems(pools, unlocked, taken).is_empty():
		return out
	var cands := _candidates(pools, unlocked, taken)
	for list: Array in cands:
		for i in range(list.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp: Variant = list[i]
			list[i] = list[j]
			list[j] = tmp
	var got := _solve(_order(cands), cands, 0, {})
	for i in cands.size():
		out.append(got[i])
	return out


static func _candidates(pools: Array, unlocked: Array[StringName], taken: Array[StringName]) -> Array:
	var out := []
	for pool: Array in pools:
		var typed: Array[StringName] = []
		for id: Variant in pool:
			typed.append(StringName(id))
		out.append(candidates(typed, unlocked, taken))
	return out


## The spots to fill, the fewest choices first (then in spot order): the tight spots take their few
## Collections before a wider pool can.
static func _order(cands: Array) -> Array[int]:
	var out: Array[int] = []
	for i in cands.size():
		out.append(i)
	out.sort_custom(func(a: int, b: int) -> bool:
		var na := (cands[a] as Array).size()
		var nb := (cands[b] as Array).size()
		return na < nb if na != nb else a < b)
	return out


## Depth-first fill of order[at..] (backtracking): spot -> Collection so far. The full fill, or {}.
static func _solve(order: Array[int], cands: Array, at: int, got: Dictionary) -> Dictionary:
	if at >= order.size():
		return got.duplicate()
	var spot := order[at]
	for c: StringName in cands[spot]:
		if got.values().has(c):
			continue
		got[spot] = c
		var done := _solve(order, cands, at + 1, got)
		got.erase(spot)
		if not done.is_empty():
			return done
	return {}
