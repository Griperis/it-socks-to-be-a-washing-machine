## The Laundry station's two pillars for the Laundry day (core/93): "Last Fix done" (a switch: sets the stand-in for
## the last Fix, the machine fixed) and "Final wash" (the first press loads every bin but one, the next loads the
## last, which starts the ending's wait). Zoo only: each asks the station's LaundryDay its own zoo Command.
class_name LaundryPillar
extends Part

enum Kind { LAST_FIX, FINAL_WASH }

@export var day: LaundryDay
@export var kind := Kind.LAST_FIX


func prompt_title() -> String:
	if kind == Kind.LAST_FIX:
		return "Last Fix done: on" if day != null and day.zoo_fixed else "Last Fix done: off"
	return "Final wash: load the bins"


func use(by: int) -> void:
	if day == null or parts == null:
		return
	if kind == Kind.LAST_FIX:
		parts.ask(Command.new(LaundryDay.ZOO_LAST_FIX, by, day.id, {"on": not day.zoo_fixed}))
	else:
		parts.ask(Command.new(LaundryDay.ZOO_FINAL, by, day.id))


## Nothing is ever asked of the pillar.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
