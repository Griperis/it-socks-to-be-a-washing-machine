## Every Sock Design of the game, by id (designs.tres beside it, edited in the inspector, Q2248).
## The Designs are kept in id order, so a Design's id is its place in the list.
class_name DesignCatalogue
extends Resource

@export var designs: Array[SockDesign] = []

## How many Designs each Collection has, counted once (count_of()).
var _counts: Dictionary[StringName, int] = {}


## How many Designs Collection `collection` has (Simple 130, Sport 70: a Cabinet's full height).
func count_of(collection: StringName) -> int:
	if _counts.is_empty():
		for d in designs:
			if d != null:
				_counts[d.collection] = _counts.get(d.collection, 0) + 1
	return _counts.get(collection, 0)


## The Design with this id, or null.
func design(id: int) -> SockDesign:
	if id < 0 or id >= designs.size():
		return null
	var d := designs[id]
	return d if d != null and d.id == id else _find(id)


## The colour of Collection `collection` (its file in game/collections/), or the old warm gold for one without.
func collection_colour(collection: StringName) -> Color:
	var c := Collections.of(collection)
	return c.colour if c != null else Color(1.0, 0.8, 0.4)


## The name of Collection `collection`'s Cabinet ("Simple cabinet"), or the Collection's id.
func cabinet_name(collection: StringName) -> String:
	var c := Collections.of(collection)
	return c.cabinet_name if c != null and c.cabinet_name != "" else String(collection)


func size() -> int:
	return designs.size()


## The Collections in the order their first Design (by id) appears.
func collections() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in size():
		var d := design(id)
		if d != null and not out.has(d.collection):
			out.append(d.collection)
	return out


## How many rows of `per_row` the zoo's line-ups lay `count` things out in.
static func rows_of(count: int, per_row: int) -> int:
	@warning_ignore("integer_division")
	return (count + per_row - 1) / per_row


func _find(id: int) -> SockDesign:
	for d in designs:
		if d != null and d.id == id:
			return d
	return null
