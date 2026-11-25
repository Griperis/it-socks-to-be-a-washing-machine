## A pillar of the washer station (core/86): the player's use (E) on it asks the station's washing machine a
## zoo-only Command (a mood level, a Stage, "Break it" and "Fix it") or fires one comment trigger as the game
## does (cooldown, chance, the picker). It holds no state.
class_name WasherPillar
extends Part

## The station sets the washing machine when it builds the pillar.
const WIRING_OPTIONAL := ["washer"]

## The washing machine it asks.
@export var washer: Washer
## The Command's verb and its args; "Break it" and "Fix it" flip `on`.
@export var verb: StringName = &""
@export var args: Dictionary = {}
## What the prompt says.
@export var title := ""
## The args are `{"on": not washer.broken}` (Break it / Fix it).
@export var flips_broken := false


func prompt_title() -> String:
	return title


func use(by: int) -> void:
	if parts == null or washer == null:
		return
	var sent := args.duplicate()
	if flips_broken:
		sent["on"] = not washer.broken
	parts.ask(Command.new(verb, by, washer.id, sent))


## A pillar decides nothing: the washing machine does.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
