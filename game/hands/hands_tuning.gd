## How the Hands pick, hold and drop: one .tres beside it (hands_tuning.tres), edited in the
## inspector. Every number is today's value from the old game (data/tuning/hands.json, held.json,
## the rig's constants), not a decision.
class_name HandsTuning
extends Resource

@export_group("Pick")
## How far the crosshair reaches a Sock or a spot to drop on, from the eyes.
@export_range(0.5, 6.0, 0.1, "suffix:m") var reach := 2.5 # placeholder: the designer's number (today's value from the old game)
## How much farther than `reach` the Host lets a player's feet be from what they pick or drop
## on: the eyes stand above the feet, and a Guest's place reaches the Host a little late.
@export_range(0.0, 2.0, 0.1, "suffix:m") var reach_slack := 1.0 # placeholder: the Host's allowance, not felt in play
## The shortest time between two picks; a click sooner does nothing.
@export_range(0.0, 2.0, 0.05, "suffix:s") var grab_interval := 0.35 # placeholder: the designer's number (today's value from the old game)
## How many items the Hands hold (a Pair counts as one). The zoo's player holds 3 (Q2244).
@export_range(1, 12, 1) var capacity := 1 # placeholder: the designer's number (today's value from the old game)

@export_group("Drop")
## A press of the drop button shorter than this is a drop (a longer one is the Throw's, core/08).
@export_range(0.05, 1.0, 0.05, "suffix:s") var tap := 0.25 # placeholder: the designer's number (today's value from the old game)
## The steepest top a drop may land on.
@export_range(0.0, 60.0, 1.0, "suffix:°") var drop_slope := 25.0 # placeholder: the designer's number (today's value from the old game)
## The narrowest gap the crosshair sees a drop spot through.
@export_range(0.0, 0.3, 0.01, "suffix:m") var drop_gap := 0.08 # placeholder: the designer's number (today's value from the old game)
## How high over its spot a dropped Sock is let go.
@export_range(0.0, 0.2, 0.01, "suffix:m") var drop_lift := 0.03 # placeholder: the designer's number (today's value from the old game)
## How long a dropped Sock flicks from the hand to its spot before it falls.
@export_range(0.0, 0.5, 0.01, "suffix:s") var flick := 0.1 # placeholder: the designer's number (today's value from the old game)
## A falling Sock that has not come to rest after this long is put down where it is (T13).
@export_range(1.0, 20.0, 0.5, "suffix:s") var settle_limit := 6.0 # placeholder: the designer's number (today's value from the old game)

## How long a refusal ("Hands full", "Can't drop there") stays on screen.
@export_range(0.2, 5.0, 0.1, "suffix:s") var refusal_time := 1.5 # placeholder: the designer's number (the old HUD's wobble and fade are a look ticket)

@export_group("Holding")
## Where the active item hangs, in the camera's space (x right, y up, -z ahead), before `depth`.
@export var active_pos := Vector3(0.2, -0.13, -0.55) # placeholder: the old held.json, compared with held-sock.png (Q2246)
@export_range(0.05, 2.0, 0.05) var active_scale := 0.6 # placeholder: the old held.json (Q2246)
## Where the first tucked item hangs, and the step to the next one.
@export var tucked_pos := Vector3(-0.3, -0.3, -0.55) # placeholder: the old held.json (Q2246)
@export var tucked_step := Vector3(0.075, 0.0, 0.0) # placeholder: the old held.json (Q2246)
@export_range(0.05, 2.0, 0.05) var tucked_scale := 0.3 # placeholder: the old held.json (Q2246)
## Every held item is drawn at this share of its apparent distance and size (it looks the same),
## so it sits inside the player's body and does not sink into a wall as easily.
@export_range(0.1, 1.0, 0.05) var depth := 0.5 # placeholder: the old held.json (Q2246)

@export_group("Zoom and turn")
## The field of view while the zoom button is held, and how long the view takes to get there.
@export_range(20.0, 90.0, 1.0, "suffix:°") var zoom_fov := 50.0 # placeholder: the designer's number (Q2234, today's value from the old game)
@export_range(0.0, 1.0, 0.01, "suffix:s") var zoom_time := 0.15 # placeholder: the designer's number (Q2234, today's value from the old game)
## Where the active item comes to while zoomed, and its size there.
@export var zoom_pos := Vector3(0.0, -0.02, -0.4) # placeholder: the old held.json (Q2246)
@export_range(0.1, 4.0, 0.05) var zoom_scale := 1.6 # placeholder: the old held.json (Q2246)
## Seconds for one turn of the active item while the turn button is held.
@export_range(0.2, 10.0, 0.1, "suffix:s") var turn_time := 2.0 # placeholder: the designer's number (today's value from the old game)
