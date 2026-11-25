## The Laundry station's pillars for the run's ends (core/93, core/94): "Last Fix done" (a switch: the machine
## fixed), "Final wash" (the first press loads every bin but one, the next loads the last, which starts the ending's
## wait) and "First wash" (PENDING again with a few Socks held round the washer; a bin clicked into the washer lets
## them in, with no cutscene). Each asks the station's run stand-in (LaundryRun) its own Command.
class_name LaundryPillar
extends Part

enum Kind { LAST_FIX, FINAL_WASH, FIRST_WASH }

@export var run: LaundryRun
@export var kind := Kind.LAST_FIX


func prompt_title() -> String:
	if kind == Kind.LAST_FIX:
		return "Last Fix done: on" if run != null and run.fixed else "Last Fix done: off"
	if kind == Kind.FIRST_WASH:
		var day := run.day if run != null else null
		return "First wash: pending" if day != null and day.first_wash != LaundryDay.FirstWash.DONE else "First wash: reset"
	return "Final wash: load the bins"


func use(by: int) -> void:
	if run == null or parts == null:
		return
	if kind == Kind.LAST_FIX:
		parts.ask(Command.new(LaundryRun.LAST_FIX, by, run.id, {"on": not run.fixed}))
	elif kind == Kind.FIRST_WASH:
		parts.ask(Command.new(LaundryRun.FIRST_WASH, by, run.id))
	else:
		parts.ask(Command.new(LaundryRun.FINAL, by, run.id))


## Nothing is ever asked of the pillar.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
