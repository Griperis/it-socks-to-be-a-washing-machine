## The Lobby's stats card (core/143, docs/architecture/wardrobe.md "The Lobby", the old LobbyStatsCard): a cream
## card beside the focused figure with the player's name (28 px) and their five Lifetime tallies (22 px), thousands
## apart. It never takes the mouse (the figure under it keeps it). The Lobby shows, fills and places it; the look
## is the scene's.
class_name LobbyStatsCard
extends PanelContainer

## The id of the player on the card, or "" while it is hidden.
var shown := ""

@onready var _name: Label = %Name


func _ready() -> void:
	for tally in PlayerProfile.TALLIES:
		(get_node("Box/%s/Caption" % tally) as Label).text = LobbyWords.TALLY_NAMES[tally]


## Shows `who` (player `id`) with their `tallies` ({tally name: int}; a missing one reads 0).
func show_player(id: String, who: String, tallies: Dictionary) -> void:
	shown = id
	_name.text = who
	for tally in PlayerProfile.TALLIES:
		(get_node("Box/%s/Value" % tally) as Label).text = thousands(clampi(int(tallies.get(tally, 0)), 0, PlayerProfile.TALLY_MAX))
	visible = true
	reset_size()


func hide_card() -> void:
	shown = ""
	visible = false


## The name as shown.
func name_text() -> String:
	return _name.text


## The tally `tally` as it reads on the card.
func tally_text(tally: String) -> String:
	return (get_node("Box/%s/Value" % tally) as Label).text


## 1234567 -> "1,234,567".
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out
