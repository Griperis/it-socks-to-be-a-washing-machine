## The First wash's numbers (core/94; the old data/tuning/first_wash.json). One .tres beside it
## (first_wash_tuning.tres), edited in the inspector; `first_wash.tres` reads them by name ("$wash_seconds",
## "$bubbles"), so a change here changes the cutscene with no other edit.
class_name FirstWashTuning
extends Resource

## Part 1's calm wash before the machine breaks (the drum turning, the bubbles); the line starts after it.
@export_range(0.5, 30.0, 0.1, "suffix:s") var wash_seconds := 3.0 # placeholder: the old first_wash.json wash_seconds, until the designer plays it
## How many bubbles rise out of the porthole in the calm wash.
@export_range(1, 200, 1) var bubbles := 40 # placeholder: the old first_wash.json bubbles, until the designer plays it
