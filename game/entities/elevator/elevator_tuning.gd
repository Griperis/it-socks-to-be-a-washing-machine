## The Elevator's numbers (docs/architecture/elevator.md "How it is authored"; the old data/tuning/elevator.json and
## the riders' `ride`), edited in the inspector (elevator_tuning.tres beside it). The Host's timers read
## `hatch_time` and `floor_time`; the hatch's clips are played at the speed that fits `hatch_time`, so the number
## lives here only. The motion of the riders (the climb, the curl, the squeeze) is the clips' keys, not here.
class_name ElevatorTuning
extends Resource

## A hatch slides shut before the car leaves (and open when it arrives) in this long.
@export_range(0.05, 3.0, 0.05, "suffix:s") var hatch_time := 0.5 # placeholder: the designer's number (the old elevator.json hatch_time)
## The ride takes this long a floor, before Fast Elevator (Q512: about 2).
@export_range(0.1, 10.0, 0.1, "suffix:s") var floor_time := 2.0 # placeholder: the designer's number (the old elevator.json floor_time)
## The rope and pulley creak this often while the car rides.
@export_range(0.1, 5.0, 0.05, "suffix:s") var creak_every := 0.7 # placeholder: the designer's number (the old elevator.json creak_every)
## How near the open hatch a player stands to climb in (core/157).
@export_range(0.5, 4.0, 0.1, "suffix:m") var reach := 1.6 # placeholder: the designer's number (the old ride reach)
## Riders the car takes before Roomy Car (core/157, core/158).
@export_range(1, 4, 1) var seats := 2 # placeholder: the designer's number (the old ride seats)
## A rider comes out this far in front of the hatch (core/157).
@export_range(0.2, 2.0, 0.05, "suffix:m") var exit_gap := 0.8 # placeholder: the designer's number (the old ride exit_gap)
## A rider's eyes over the car's floor (core/157).
@export_range(0.1, 0.6, 0.01, "suffix:m") var eye_height := 0.3 # placeholder: the designer's number (the old ride eye_height)
## The floor letters' column on the car's side wall: the space between two letters, B the lowest.
@export_range(0.05, 0.3, 0.01, "suffix:m") var letter_step := 0.12 # placeholder: the designer's number (the old elevator_letter.gd column)
