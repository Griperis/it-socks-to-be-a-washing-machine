## What "settles correctly" and "glitches" mean as counts (core/31, B3): the limits MessWatch counts
## against, in the Mess benchmark and in the suite. One .tres beside it (mess_checks.tres).
class_name MessChecks
extends Resource

@export_group("A rest")
## A Sock that comes to rest while still turning faster than this is a "hot rest": it was written
## lying mid-turn (a rest forced by pressure, or a body Jolt put to sleep).
@export_range(0.0, 20.0, 0.1, "suffix:rad/s") var hot_spin := 2.0 # placeholder: until the designer has seen the benchmark's report
## ...or while still moving faster than this.
@export_range(0.0, 5.0, 0.01, "suffix:m/s") var hot_speed := 0.35 # placeholder: until the designer has seen the benchmark's report
## A Sock written lying farther than this from where its body was the tick before jumped (a snap of
## the rest rule: a push up onto a floor); one that came back at the return spot counts as lost instead.
@export_range(0.0, 1.0, 0.001, "suffix:m") var jump := 0.01 # placeholder: until the designer has seen the benchmark's report

@export_group("A flight")
## A moving Sock turning faster than this flips (Jolt's own limit is about 47 rad/s).
@export_range(1.0, 60.0, 0.5, "suffix:rad/s") var flip_spin := 25.0 # placeholder: until the designer has seen the benchmark's report
## A Sock woken this many times or more in one run jitters between lying and moving.
@export_range(2, 50, 1) var jitter_wakes := 3 # placeholder: until the designer has seen the benchmark's report

@export_group("A heap at rest")
## A lying Sock whose lowest point is this far under the floor has sunk.
@export_range(0.0, 0.5, 0.001, "suffix:m") var sunk := 0.015 # placeholder: until the designer has seen the benchmark's report
## A lying Sock whose middle is this deep inside another lying Sock's box is inside it.
@export_range(0.0, 0.05, 0.001, "suffix:m") var inside := 0.006 # placeholder: until the designer has seen the benchmark's report
## The heap counts as settled once nothing has moved or waited for this long.
@export_range(0.1, 5.0, 0.1, "suffix:s") var quiet := 0.5 # placeholder: until the designer has seen the benchmark's report
