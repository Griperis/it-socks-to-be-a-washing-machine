## Every Sock Design of the game, by id (designs.tres beside it, edited in the inspector, Q2248).
## The Designs are kept in id order, so a Design's id is its place in the list.
class_name DesignCatalogue
extends Resource

@export var designs: Array[SockDesign] = []


## The Design with this id, or null.
func design(id: int) -> SockDesign:
	if id < 0 or id >= designs.size():
		return null
	var d := designs[id]
	return d if d != null and d.id == id else _find(id)


func size() -> int:
	return designs.size()


func _find(id: int) -> SockDesign:
	for d in designs:
		if d != null and d.id == id:
			return d
	return null
