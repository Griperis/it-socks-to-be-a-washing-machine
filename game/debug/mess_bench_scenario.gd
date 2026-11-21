## One scenario of the Mess benchmark (core/31, B1), as data: what lies in the level before it
## starts, what is done, and which part of it is timed. The list is mess_bench_plan.tres.
class_name MessBenchScenario
extends Resource

## What is done: nothing (the lying Socks only), a pour from the spout, a burst of Throws into the
## heap, or a Door and a drawer opened and shut through lying Socks.
enum Kind { IDLE, POUR, BURST, SWEEP }
## Which part is timed: all of it, only while the act runs (the spout still pours), or only from
## the act's end until every Sock lies.
enum Phase { WHOLE, ACTING, SETTLING }

## Its name on the command line (`--only=`) and in the report.
@export var id := &""
## What it measures, in a line.
@export var title := ""
@export var kind := Kind.IDLE
@export var phase := Phase.WHOLE
## How many Socks lie in the level before it starts (stacked by MessBenchLevel, no physics).
@export_range(0, 20000, 1) var lying := 0
## How many Socks the act pours or throws.
@export_range(0, 20000, 1) var count := 0
## How long an IDLE scenario is timed.
@export_range(0.5, 60.0, 0.5, "suffix:s") var seconds := 3.0
## The longest the others may take to come to rest, in game seconds; past it the Socks still
## moving "never settle".
@export_range(1.0, 600.0, 1.0, "suffix:s") var limit := 60.0
## The old game's own number for the nearest scenario of its stress test, for the report ("" for none).
@export var old_game := ""
