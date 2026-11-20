## Every Sock Design of the game, by id (designs.tres beside it, edited in the inspector, Q2248).
## The Designs are kept in id order, so a Design's id is its place in the list.
class_name DesignCatalogue
extends Resource

@export var designs: Array[SockDesign] = []
## Each Collection's colour, by its id (the old game's data/designs.json): the pairing moment's
## sparkles and ring (P05).
@export var collection_colours: Dictionary[StringName, Color] = {}


## The Design with this id, or null.
func design(id: int) -> SockDesign:
	if id < 0 or id >= designs.size():
		return null
	var d := designs[id]
	return d if d != null and d.id == id else _find(id)


## The colour of Collection `collection`, or the old warm gold for one without.
func collection_colour(collection: StringName) -> Color:
	return collection_colours.get(collection, Color(1.0, 0.8, 0.4))


func size() -> int:
	return designs.size()


func _find(id: int) -> SockDesign:
	for d in designs:
		if d != null and d.id == id:
			return d
	return null
