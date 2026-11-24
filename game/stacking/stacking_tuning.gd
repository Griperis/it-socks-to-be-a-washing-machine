## Stacking on a Teammate's back and the soft push between standing players (core/41, list
## docs/migration/m3-lists/01-player-stacking.md): one .tres beside it, edited in the inspector. Every
## number is today's value from the old game (data/tuning/stacking.json, players.json), not a decision.
class_name StackingTuning
extends Resource

## The most players one stack holds (list 6): the top one's back holds no one.
@export_range(1, 6, 1) var max_high := 3 # placeholder: the designer's number (the old game's, Q2590)
## The share of the pace a carrier keeps while anyone stands on their back (list 28).
@export_range(0.1, 1.0, 0.05) var carry_speed := 0.5 # placeholder: the designer's number (the old game's, Q2590)
## The back disc (list 1): its radius and how thick it is.
@export_range(0.1, 1.0, 0.05, "suffix:m") var back_radius := 0.3 # placeholder: the designer's number (the old game's)
@export_range(0.02, 0.5, 0.01, "suffix:m") var back_thickness := 0.1 # placeholder: the designer's number (the old game's)
## How far under the top of the body the back sits (list 2): a rider stands this much lower.
@export_range(0.0, 1.0, 0.05, "suffix:m") var ride_sink := 0.3 # placeholder: the designer's number (the old game's)
## Feet this far under a back's top or higher meet it (list 9); lower they pass through (list 10).
@export_range(0.0, 0.3, 0.01, "suffix:m") var touch_slack := 0.05 # placeholder: the designer's number (the old game's)
## A floor contact on a back with an upward normal over this rides it (list 20).
@export_range(0.0, 1.0, 0.05) var ride_normal := 0.7 # placeholder: the designer's number (the old game's)
## A jump within this of a back (centre to centre, along the floor) is a climb (list 13).
@export_range(0.1, 3.0, 0.05, "suffix:m") var climb_reach := 0.9 # placeholder: the designer's number (the old game's)
## How far a climb clears the back, and the room it needs over a crouched body (lists 13, 14).
@export_range(0.0, 1.0, 0.05, "suffix:m") var climb_clear := 0.15 # placeholder: the designer's number (the old game's)
## The room check starts this far over the back's top (list 13).
@export_range(0.0, 0.2, 0.01, "suffix:m") var room_start := 0.02 # placeholder: the designer's number (the old game's)
## How fast a climber steers over the back's middle: the offset times this, per second (list 16).
@export_range(0.0, 30.0, 0.5, "suffix:/s") var climb_steer := 8.0 # placeholder: the designer's number (the old game's)
## The soft push (Q263, lists 45-48): nearer than this, centre to centre, pushes...
@export_range(0.0, 2.0, 0.05, "suffix:m") var push_apart := 0.6 # placeholder: the designer's number (the old game's players.json)
## ...at (push_apart - gap) times this, in m/s.
@export_range(0.0, 30.0, 0.5, "suffix:/s") var push_rate := 8.0 # placeholder: the designer's number (the old game's players.json)
## Two players exactly on each other (closer than this) step apart by their ids (list 46).
@export_range(0.0001, 0.1, 0.0001, "suffix:m") var push_same := 0.001 # placeholder: the designer's number (the old game's)
## A player who lands on a knocked-down body slips off it at this speed (list 32)...
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var slip_speed := 2.5 # placeholder: the designer's number (the old game's players.json)
## ...where the contact's upward normal is at least this.
@export_range(0.0, 1.0, 0.05) var slip_normal := 0.3 # placeholder: the designer's number (the old game's)
