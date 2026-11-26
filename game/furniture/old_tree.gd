## The Old Tree as the Upgrade station (docs/architecture/economy.md "The Old Tree, the station", Q2611):
## the crosshair on it outlines the tree and reads "The Old Tree" with the E key; the use key opens this
## machine's Upgrade menu for its own player (no Command: opening a menu decides nothing). Its voice is
## core/132's; nothing on the tree moves (Q2670).
class_name OldTree
extends Part

const TITLE := "The Old Tree"

## This machine's Upgrade menu (a child of the tree's scene).
@export var menu: UpgradeMenu


func prompt_title() -> String:
	return TITLE


## The player `by` used it: on their own machine their menu opens.
func use(by: int) -> void:
	if menu == null or not is_inside_tree() or by != multiplayer.get_unique_id():
		return
	var player := _player_of(by)
	if player != null:
		menu.open(Upgrades.of(self), player)


func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


## This machine's Player (the one on this Part's multiplayer), or null.
func _player_of(_by: int) -> Player:
	for node in get_tree().get_nodes_in_group(&"local_input"):
		if node is Player and node.multiplayer == multiplayer:
			return node as Player
	return null
