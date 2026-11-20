## A button of the heap station (core/20, H02, H03): clicked like a drawer, it asks the spout for
## its verb ("more" or "respill"). It has no state of its own; the spout answers.
class_name HeapButton
extends Part

## What a click asks the spout: &"more" (one more batch) or &"respill" (clear and pour afresh).
@export var verb := &"more"
@export var spout: HeapSpout


## The player's click (a left click on a thing that is not a Sock uses it) asks the spout.
func use(by: int) -> void:
	if spout == null or parts == null:
		return
	parts.ask(Command.new(verb, by, spout.id, {}))


## Nothing is ever asked of the button itself.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
