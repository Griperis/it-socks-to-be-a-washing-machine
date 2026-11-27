## A clickable of the Elevator (docs/architecture/elevator.md "The shape"; the old ElevatorButton, ElevatorHatch and
## ElevatorLetter in one script): a stop's brass call BUTTON, a stop's HATCH, or a floor LETTER in the car. They
## differ only in the verb they ask and their words, so one Part with no state does the three: `use()` asks the
## Elevator, never writes. A BUTTON or a HATCH calls its stop's floor; a LETTER sends the car to its own `floor`
## (set by the Elevator as it builds the column; the send is core/157's).
class_name ElevatorControl
extends Part

## Which clickable it is.
enum Kind { BUTTON, HATCH, LETTER }

## The old words (EB:8-31, ELT:36, `openable.gd`).
const CALL := "Call the Elevator"
const SEND := "Send the Elevator to %s"
const NOUN := "hatch"
## The floors' glossary names by `HouseLights.floors` index ("Send the Elevator to the first floor").
const FLOORS: Array[String] = ["the basement", "the ground floor", "the first floor", "the attic"]

@export var kind := Kind.BUTTON
## A LETTER's floor; a BUTTON or a HATCH takes its stop's.
@export_range(0, 3, 1) var floor := 0


## The floor it calls or sends to.
func floor_of() -> int:
	var s := stop()
	return s.floor if s != null and kind != Kind.LETTER else floor


## The stop it is on (null for a LETTER).
func stop() -> ElevatorStop:
	var node := get_parent()
	while node != null:
		if node is ElevatorStop:
			return node as ElevatorStop
		node = node.get_parent()
	return null


## The Elevator it asks.
func elevator() -> Elevator:
	return Elevator.of(self)


## The crosshair's words: the refusal while it would be refused ("Out of order (...)", "Elevator locked"), "Open the
## hatch" or "Shut the hatch" on the hatch the car stands behind, else "Call the Elevator" or the send.
func prompt_title() -> String:
	var e := elevator()
	if e == null:
		return ""
	var at := floor_of()
	if e.is_broken():
		return Elevator.SAYS[Elevator.BROKEN]
	if e.is_locked(at):
		return Elevator.SAYS[Elevator.LOCKED]
	match kind:
		Kind.HATCH:
			return Prompts.verb_title(e.hatch_open(at), NOUN) if e.stands_at(at) else CALL
		Kind.LETTER:
			return SEND % FLOORS[clampi(at, 0, FLOORS.size() - 1)]
	return CALL


## The player's click (left click or E): the Elevator asks its verb.
func use(by: int) -> void:
	var e := elevator()
	if e != null:
		e.use_control(self, by)


## Nothing is asked of it: its clicks are the Elevator's verbs.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
