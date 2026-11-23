## The Sock generator station's button (core/52): clicked like a drawer, it asks the generator's Part
## to lay its Socks again from the next seed. It has no state of its own; GeneratedSocks answers.
class_name RegenerateButton
extends Part

@export var generated: GeneratedSocks


## The player's click (a left click on a thing that is not a Sock uses it) asks for a regeneration.
func use(by: int) -> void:
	if generated == null or parts == null:
		return
	parts.ask(Command.new(&"regenerate", by, generated.id, {}))


## The crosshair's words.
func prompt_title() -> String:
	return "New seed"


## Nothing is ever asked of the button itself.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
