## The Collections station's Encyclopedia pillar (core/136): the player's use (E) on it opens the encyclopedia pages
## on the zoo's profile, on the pillar scene's own `Pages` layer. Looks only: it asks nothing of the Host and holds no state.
class_name EncyclopediaPillar
extends Part

const PAGE := preload("res://game/ui/encyclopedia/encyclopedia.tscn")

## Where the page goes (the pillar scene's CanvasLayer).
@export var host: Node
## The page on show, or null.
var page: EncyclopediaPage = null


func prompt_title() -> String:
	return "Sock encyclopedia"


func use(_by: int) -> void:
	if host == null or is_instance_valid(page):
		return
	page = PAGE.instantiate() as EncyclopediaPage
	page.profile = Worlds.profile()
	host.add_child(page)


## A pillar decides nothing.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
