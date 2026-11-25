## A pillar of the Final screen station (core/95): the player's use (E) on it opens the station's Final screen on the
## pillar's made-up summary. Looks only: it asks nothing of the Host and holds no state.
class_name FinalPillar
extends Part

## The station sets these when it builds the pillar.
const WIRING_OPTIONAL := ["screen"]

@export var screen: FinalScreen
## What the prompt says.
@export var title := ""
## What the screen shows (the station made it up from the catalogue).
var summary: FinalSummary = null


func prompt_title() -> String:
	return title


func use(_by: int) -> void:
	if screen != null and summary != null and not screen.is_open():
		screen.open(summary)


## A pillar decides nothing.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
