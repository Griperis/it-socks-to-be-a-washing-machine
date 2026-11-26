## Which piece each player's Stage present holds (core/137, docs/architecture/gifts.md "The drop"; the old
## GI:79-140 with the designer's G1, Q2673). Rules only: it reads what it is given and decides nothing else.
##
## For each player, for each completed Collection that has pieces: a piece of it the player neither owns nor
## has waiting in another box, a RARE one weighing `rare_weight` against 1. A player who owns (or has
## waiting) every piece of it gets a piece they lack of any other unlocked Collection that is not held back,
## by the same weights; only when they lack no piece of any of them, any piece of the completed one (its
## opening pays the refund). The box is wrapped in the completed Collection whatever piece it holds.
class_name PresentDraw
extends RefCounted


## The presents: [{"for": player id, "piece": StringName, "collection": the completed Collection}], in the
## order of `players`, then of `completed`. `players`: [{"id": player id, "owned": PackedStringArray}];
## `waiting`: {player id: PackedStringArray of pieces already waiting in boxes}; `unlocked`: the Collections
## a lacked piece may come from when a completed one is owned whole.
static func draw(completed: Array[StringName], players: Array, waiting: Dictionary, unlocked: Array[StringName],
		rare_weight: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for who: Dictionary in players:
		var pid := String(who.get("id", ""))
		var had := PackedStringArray(who.get("owned", PackedStringArray()))
		had.append_array(PackedStringArray(waiting.get(pid, PackedStringArray())))
		for c in completed:
			var every := pieces_of(c)
			if every.is_empty():
				continue
			var lacked := _lacked(every, had)
			if lacked.is_empty():
				for other in unlocked:
					if other != c:
						lacked.append_array(_lacked(pieces_of(other), had))
			var piece: StringName
			if not lacked.is_empty():
				piece = weighted(lacked, rare_weight, rng)
			else:
				piece = every[rng.randi_range(0, every.size() - 1)].id
			had.append(String(piece))
			out.append({"for": pid, "piece": piece, "collection": c})
	return out


## The pieces a present of Collection `c` may hold: its shown pieces (none for a held-back Collection, Q2675).
static func pieces_of(c: StringName) -> Array[WardrobePiece]:
	var out: Array[WardrobePiece] = []
	var col := Collections.of(c)
	if col == null or col.held_back:
		return out
	for p in Wardrobe.pieces_of(c):
		if Wardrobe.shown(p):
			out.append(p)
	return out


## One weighted pick from `pieces` (not empty): a RARE piece weighs `rare_weight`, any other 1.
static func weighted(pieces: Array[WardrobePiece], rare_weight: float, rng: RandomNumberGenerator) -> StringName:
	var total := 0.0
	for p in pieces:
		total += _weight(p, rare_weight)
	var roll := rng.randf() * total
	for p in pieces:
		roll -= _weight(p, rare_weight)
		if roll < 0.0:
			return p.id
	return pieces.back().id


static func _weight(p: WardrobePiece, rare_weight: float) -> float:
	return rare_weight if p.rarity == WardrobePiece.Rarity.RARE else 1.0


static func _lacked(pieces: Array[WardrobePiece], had: PackedStringArray) -> Array[WardrobePiece]:
	var out: Array[WardrobePiece] = []
	for p in pieces:
		if not had.has(String(p.id)):
			out.append(p)
	return out
