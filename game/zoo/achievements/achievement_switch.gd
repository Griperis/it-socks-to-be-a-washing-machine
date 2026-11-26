## A zoo switch at the Achievements station (core/145): "Grant all", "Reset" or "+100 Pairs" for this machine's own
## player, on the profile the Achievements decide for (the zoo's). Using it (E) acts on this machine alone, as an
## Achievement is decided per machine (no Command: the switch keeps no state, and its `decide` refuses).
class_name AchievementSwitch
extends Part

enum Act { GRANT_ALL, RESET, ADD_PAIRS }

## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"
const TITLES: Array[String] = ["Grant all", "Reset", "+100 Pairs"]
## What "+100 Pairs" adds to the profile's pairs_shelved.
const PAIRS := 100

@export var act := Act.GRANT_ALL


func prompt_title() -> String:
	return TITLES[act]


func use(by: int) -> void:
	if by != multiplayer.get_unique_id():
		return
	var achievements := Achievements.of(self)
	if achievements == null:
		return
	match act:
		Act.GRANT_ALL:
			achievements.grant_all()
		Act.RESET:
			achievements.reset()
		Act.ADD_PAIRS:
			achievements.current_profile().count(PlayerProfile.PAIRS_SHELVED, PAIRS)
			achievements.check()


func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func _ready() -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = TITLES[act]
