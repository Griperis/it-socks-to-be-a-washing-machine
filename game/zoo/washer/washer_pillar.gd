## A pillar of the washer station (core/86): the player's use (E) on it asks the station's run stand-in one of its
## Commands (a mood level, a Stage, "Break it" and "Fix it", a cutscene) or fires one comment trigger at the washing
## machine as the game does (cooldown, chance, the picker). It holds no state.
class_name WasherPillar
extends Part

## The station sets the Part it asks when it builds the pillar.
const WIRING_OPTIONAL := ["asks"]

## The Part it asks: the washing machine (`talk`) or the station's WasherRun.
@export var asks: Part
## The Command's verb and its args; "Break it" and "Fix it" flip `on`.
@export var verb: StringName = &""
@export var args: Dictionary = {}
## What the prompt says.
@export var title := ""
## The args are `{"on": not broken}` (Break it / Fix it), `asks` being the WasherRun.
@export var flips_broken := false


func prompt_title() -> String:
	return title


func use(by: int) -> void:
	if parts == null or asks == null:
		return
	var sent := args.duplicate()
	if flips_broken and asks is WasherRun:
		sent["on"] = not (asks as WasherRun).broken
	parts.ask(Command.new(verb, by, asks.id, sent))


## A pillar decides nothing: the Part it asks does.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
