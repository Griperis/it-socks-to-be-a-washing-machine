## The Collections station's Encyclopedia pillar (core/136): the player's use (E) on it opens the encyclopedia pages
## on the zoo's profile, on a layer of its own. Looks only: it asks nothing of the Host and holds no state.
class_name EncyclopediaPillar
extends Part

const PAGE := preload("res://game/ui/encyclopedia/encyclopedia.tscn")

## The page on show, or null.
var page: EncyclopediaPage = null


func prompt_title() -> String:
	return "Sock encyclopedia"


func use(_by: int) -> void:
	if is_instance_valid(page):
		return
	page = PAGE.instantiate() as EncyclopediaPage
	page.profile = Worlds.profile()
	var layer := CanvasLayer.new()
	layer.name = "Pages"
	add_child(layer)
	layer.add_child(page)
	page.tree_exited.connect(layer.queue_free)


## A pillar decides nothing.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
