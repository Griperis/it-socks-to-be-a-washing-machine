## Every Wardrobe piece (core/128, docs/architecture/wardrobe.md "The pieces as data"): the
## `WardrobePiece` files of `pieces/`, listed export-safe, each piece's id its file's name. A new `.tres`
## there is a new piece, with no code: the rows, the counts, presents (pieces_of) and the zoo pick it up.
class_name Wardrobe
extends RefCounted

const FOLDER := "res://game/wardrobe/pieces/"
const TUNING := "res://game/wardrobe/wardrobe_tuning.tres"
## What a Socks or Trail piece is previewed on.
const AVATAR := "res://game/parts/avatar/looks_avatar.tscn"
## The two feet a Socks preview keeps of the creature.
const FEET: Array[StringName] = [&"FootL", &"FootR"]

static var _all: Array[WardrobePiece] = []
static var _by_id: Dictionary[StringName, WardrobePiece] = {}
static var _tuning: WardrobeTuning = null


## Every piece, by id.
static func all() -> Array[WardrobePiece]:
	_load()
	return _all


## The piece with this id, or null.
static func of(id: StringName) -> WardrobePiece:
	_load()
	return _by_id.get(id)


## The Wardrobe's numbers.
static func tuning() -> WardrobeTuning:
	if _tuning == null:
		_tuning = load(TUNING) as WardrobeTuning
	return _tuning


## A slot's pieces in the old row order: the basic pieces first by `order`, then each Collection's in
## `Collections.all()` order, then by `order`. Every piece of the slot, shown or not.
static func row(slot: WardrobePiece.Slot) -> Array[WardrobePiece]:
	var out: Array[WardrobePiece] = []
	for p in all():
		if p.slot == slot:
			out.append(p)
	var rank: Dictionary[StringName, int] = {&"": -1}
	var collections := Collections.all()
	for i: int in collections.size():
		rank[collections[i].id] = i
	out.sort_custom(func(a: WardrobePiece, b: WardrobePiece) -> bool:
		var ra: int = rank.get(a.collection, collections.size())
		var rb: int = rank.get(b.collection, collections.size())
		if ra != rb:
			return ra < rb
		if a.order != b.order:
			return a.order < b.order
		return String(a.id) < String(b.id))
	return out


## Whether a piece is in the Wardrobe's rows and counts: listed, and not of a held-back Collection (the
## Lost Socks' six until the Drum, Q2683).
static func shown(piece: WardrobePiece) -> bool:
	if piece == null or not piece.listed:
		return false
	var c := Collections.of(piece.collection) if piece.collection != &"" else null
	return c == null or not c.held_back


## How many pieces a slot's "N/M" counts as M: its shown pieces.
static func counted(slot: WardrobePiece.Slot) -> int:
	return row(slot).filter(shown).size()


## A Collection's pieces (S-122a), in their `order`.
static func pieces_of(collection: StringName) -> Array[WardrobePiece]:
	var out: Array[WardrobePiece] = []
	for p in all():
		if p.collection == collection:
			out.append(p)
	out.sort_custom(func(a: WardrobePiece, b: WardrobePiece) -> bool: return a.order < b.order)
	return out


## How a piece reads: its name, else its id capitalised.
static func piece_name(id: StringName) -> String:
	var p := of(id)
	if p != null and p.name != "":
		return p.name
	return String(id).capitalize()


## The pieces a player owns: `pieces` plus every `owned_from_start` piece (the one place the ten basic
## pieces become owned, so no profile stores them; Q2679).
static func owned(pieces: PackedStringArray) -> PackedStringArray:
	var out := pieces.duplicate()
	for p in all():
		if p.owned_from_start and not out.has(String(p.id)):
			out.append(String(p.id))
	return out


## A piece shown alone (S-122d, the old gift preview): a hat or clothes as its Looks, a Socks piece on
## a pair of bare feet in `tint`, a Trail as its sample stepping on its own; fitted to `preview_fit` at
## its largest side and centred on the returned node (once it is in the tree). An empty node for an
## unknown id.
static func preview(id: StringName, tint := Color.WHITE) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Preview"
	var piece := of(id)
	if piece == null or piece.looks == null:
		return holder
	var fit := Node3D.new()
	fit.name = "Fit"
	holder.add_child(fit)
	var t := tuning()
	match piece.slot:
		WardrobePiece.Slot.HAT, WardrobePiece.Slot.CLOTHES:
			fit.add_child(piece.looks.instantiate())
			holder.ready.connect(_fit.bind(fit, t.preview_fit), CONNECT_ONE_SHOT)
		WardrobePiece.Slot.SOCKS:
			var feet := (load(AVATAR) as PackedScene).instantiate() as AvatarLooks
			feet.colour = tint
			feet.look = {&"socks": id}
			feet.process_mode = Node.PROCESS_MODE_DISABLED  # it stands: no waddle, no glance
			feet.ready.connect(_bare_feet.bind(feet), CONNECT_ONE_SHOT)
			fit.add_child(feet)
			holder.ready.connect(_fit.bind(fit, t.preview_fit), CONNECT_ONE_SHOT)
		WardrobePiece.Slot.TRAIL:
			var sample := (load(AVATAR) as PackedScene).instantiate() as AvatarLooks
			sample.leaves_trail = false
			sample.dresser().demo = true
			sample.look = {&"trail": id}
			(sample.get_node(^"Body") as Node3D).visible = false  # the marks alone
			fit.add_child(sample)
			var length := t.demo_stride * float(t.demo_steps - 1) + 0.3
			var k := t.preview_fit / length * 1.3
			fit.scale = Vector3.ONE * k
			fit.position = -Vector3(t.demo_x, 0.0, t.demo_back - t.demo_stride * float(t.demo_steps - 1) * 0.5) * k
	return holder


## Only the feet show (the body, its pupils and points hidden).
static func _bare_feet(feet: AvatarLooks) -> void:
	for n: Node in feet.swaying().get_children():
		if n is Node3D and not FEET.has(n.name):
			(n as Node3D).visible = false


## Scales `fit` so what it shows is `size` at its largest side, centred on its parent.
static func _fit(fit: Node3D, size: float) -> void:
	var box := bounds(fit)
	var k := size / maxf(maxf(box.size.x, box.size.y), maxf(box.size.z, 0.01))
	fit.scale = Vector3.ONE * k
	fit.position = -box.get_center() * k


## The box round every visible mesh under `root`, in `root`'s own space.
static func bounds(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var todo: Array = [[root, Transform3D.IDENTITY]]
	while not todo.is_empty():
		var item: Array = todo.pop_back()
		var node := item[0] as Node3D
		var at: Transform3D = item[1]
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			var box := at * mi.get_aabb()
			out = box if first else out.merge(box)
			first = false
		for c: Node in node.get_children():
			var c3 := c as Node3D
			if c3 != null and c3.visible:
				todo.append([c3, at * c3.transform])
	return out


static func _load() -> void:
	if not _all.is_empty():
		return
	for f: String in ResourceLoader.list_directory(FOLDER):
		if not f.ends_with(".tres"):
			continue
		var p := load(FOLDER + f) as WardrobePiece
		if p == null:
			continue
		p.id = StringName(f.get_basename())
		_by_id[p.id] = p
		_all.append(p)
