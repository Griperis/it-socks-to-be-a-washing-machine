## A level's run as data (docs/architecture/stages.md "How it is authored"): its Stages in unlock
## order, the Rows a Cabinet unlocks with and gains per floor, the World's Drawer size, the share of a
## Stage's Socks on high spots in co-op, and the Stage bar's three phases. A level names its plan on
## its Run's Stages.
class_name StagePlan
extends Resource

## The Drawer size every Stage's `pairs` is given at (Q668: they scale by size / 25).
const PAIRS_AT := 25

## The Stages, the first the basement's.
@export var stages: Array[Stage] = []
## The Rows a Cabinet unlocks with.
@export_range(1, 16, 1) var start_rows := 2 # placeholder: the old T:stages start_rows (balance round Q967)
## The Rows every unlocked Cabinet gains when a floor opens.
@export_range(0, 16, 1) var rows_per_stage := 1 # placeholder: the old T:stages rows_per_stage (balance round Q967)
## The Pairs a Drawer holds in a World started from this plan (the debug slider overrides it, Q668).
@export_range(1, 25, 1) var pairs_per_drawer := 25 # placeholder: the old drawer size (balance round Q967)
## The share of a Stage's Socks laid on high spots with 2 or more players (Q664).
@export_range(0.0, 1.0, 0.01) var high_share := 0.05 # placeholder: the old T:stages high_share (Q967)
## How far over its floor a high spot is at least.
@export_range(0.0, 5.0, 0.1, "suffix:m") var high_spot := 1.7 # placeholder: the old T:stages high_spot (Q967)
## The bar before the First wash ("Wash the laundry", Q2625).
@export var goal_phase: StageBarPhase
## The bar while a Stage counts ("Stage %d: %s  %d/%d").
@export var stage_phase: StageBarPhase
## The bar in the Laundry day, after the last Fix ("Wash clothes %d/%d", Q2621).
@export var after_phase: StageBarPhase
## The washer's comment set in the Laundry day (Q2635).
@export_range(0, 16, 1) var laundry_day_comment_set := 4


## How many Stages the run has.
func size() -> int:
	return stages.size()


## Stage `index` (0 is the basement's), or null.
func stage(index: int) -> Stage:
	return stages[index] if index >= 0 and index < stages.size() else null


## The fewest Pairs Stage `index` spawns in a World of `per_drawer` Pairs per Drawer: its `pairs`
## scaled by per_drawer / 25, rounded up (CA:253-256).
func pairs_of(index: int, per_drawer: int) -> int:
	var s := stage(index)
	return 0 if s == null else ceili(float(s.pairs) * per_drawer / PAIRS_AT)
