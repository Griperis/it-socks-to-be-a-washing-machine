## The Laundry station's pillars for the run's ends (core/93, core/94): "Last Fix done" (a switch: sets the stand-in
## for the last Fix, the machine fixed), "Final wash" (the first press loads every bin but one, the next loads the
## last, which starts the ending's wait) and "First wash" (PENDING again with a few Socks held round the washer; a
## bin clicked into the washer lets them in, with no cutscene). Zoo only: each asks the station's LaundryDay its own zoo Command.
class_name LaundryPillar
extends Part

enum Kind { LAST_FIX, FINAL_WASH, FIRST_WASH }

@export var day: LaundryDay
@export var kind := Kind.LAST_FIX


func prompt_title() -> String:
	if kind == Kind.LAST_FIX:
		return "Last Fix done: on" if day != null and day.zoo_fixed else "Last Fix done: off"
	if kind == Kind.FIRST_WASH:
		return "First wash: pending" if day != null and day.first_wash != LaundryDay.FirstWash.DONE else "First wash: reset"
	return "Final wash: load the bins"


func use(by: int) -> void:
	if day == null or parts == null:
		return
	if kind == Kind.LAST_FIX:
		parts.ask(Command.new(LaundryDay.ZOO_LAST_FIX, by, day.id, {"on": not day.zoo_fixed}))
	elif kind == Kind.FIRST_WASH:
		parts.ask(Command.new(LaundryDay.ZOO_FIRST_WASH, by, day.id))
	else:
		parts.ask(Command.new(LaundryDay.ZOO_FINAL, by, day.id))


## Nothing is ever asked of the pillar.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
