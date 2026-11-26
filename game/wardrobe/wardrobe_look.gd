## A look (core/128, docs/architecture/wardrobe.md "The pieces as data"): what a creature wears, as a plain
## Dictionary {hat, clothes, socks, trail} of piece ids (&"" for an empty slot). Static helpers only.
class_name WardrobeLook
extends RefCounted

## The look's keys, in the order of `WardrobePiece.Slot`.
const SLOTS: Array[StringName] = [&"hat", &"clothes", &"socks", &"trail"]


## The key of `slot` in a look.
static func key(slot: WardrobePiece.Slot) -> StringName:
	return SLOTS[slot]


## A look with every slot empty.
static func empty() -> Dictionary[StringName, StringName]:
	var out: Dictionary[StringName, StringName] = {}
	for k in SLOTS:
		out[k] = &""
	return out


## Every slot, holding a known piece of that slot or &"": unknown ids, wrong slots and other keys go.
static func clean(look: Dictionary) -> Dictionary[StringName, StringName]:
	var out := empty()
	for i: int in SLOTS.size():
		var id := StringName(str(look.get(SLOTS[i], look.get(String(SLOTS[i]), ""))))
		var piece := Wardrobe.of(id)
		if piece != null and int(piece.slot) == i:
			out[SLOTS[i]] = id
	return out


## `look` cleaned, with every piece not in `owned` taken off.
static func allowed(look: Dictionary, owned: PackedStringArray) -> Dictionary[StringName, StringName]:
	var out := clean(look)
	for k in SLOTS:
		if out[k] != &"" and not owned.has(String(out[k])):
			out[k] = &""
	return out
