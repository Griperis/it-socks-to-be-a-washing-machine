## The Mess benchmark's plan (core/31, B1): its scenarios, in the order they run, and the numbers
## of a run. One .tres beside it (mess_bench_plan.tres), edited in the inspector: a new scenario is
## a new entry there, no code.
class_name MessBenchPlan
extends Resource

@export var scenarios: Array[MessBenchScenario] = []
## What counts as a fault (MessWatch).
@export var checks: MessChecks = preload("res://game/debug/mess_checks.tres")
## The seed of everything random in a run (the stacks, the spout, the Throws).
@export var dice := 31 # placeholder: any fixed number; the same heap every run
## Ticks the level runs before a scenario acts (the Parts bind, the first frame's work is over).
@export_range(1, 600, 1) var warm_ticks := 30 # placeholder: until the benchmark has run on the designer's PC
## A scenario whose 95th-percentile tick costs more than this fails the run: half of a 60 Hz tick.
@export_range(0.1, 50.0, 0.1, "suffix:ms") var tick_budget := 8.0 # placeholder: until the benchmark has run on the designer's PC
## The same for a scenario with nothing moving (IDLE).
@export_range(0.01, 50.0, 0.01, "suffix:ms") var idle_tick_budget := 0.5 # placeholder: until the benchmark has run on the designer's PC


## The scenario named `id`, or null.
func scenario(id: StringName) -> MessBenchScenario:
	for s in scenarios:
		if s.id == id:
			return s
	return null
