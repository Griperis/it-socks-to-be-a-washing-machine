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
## A press of the drop button shorter than this is a drop; held longer with something in the Hands,
## the Throw's charge starts (T01: the `hold` of core/08's design, one number for both).
@export_range(0.05, 1.0, 0.05, "suffix:s") var tap := 0.25 # placeholder: the designer's number (today's value from the old game)
## The steepest top a drop may land on.
@export_range(0.0, 60.0, 1.0, "suffix:°") var drop_slope := 25.0 # placeholder: the designer's number (today's value from the old game)
## The narrowest gap the crosshair sees a drop spot through.
@export_range(0.0, 0.3, 0.01, "suffix:m") var drop_gap := 0.08 # placeholder: the designer's number (today's value from the old game)
## A thrown or dropped Sock's body leaves from the hand at its full size, where the Hands drew it
## `active_scale` as big: its drawn Looks grows from the hand's size to its own over this long
## (core/23; the old catch_up's size, Q1209, without its move).
@export_range(0.0, 0.5, 0.01, "suffix:s") var let_go_grow := 0.1 # placeholder: until the designer's go on the core/23 strips
## A dropped Sock falls on its own from the hand (Q2367), drifting at most this fast across the
## floor to its spot; a spot it would need more for (far off, or barely below the hand) has it let go
## farther along the eye-line instead.
@export_range(0.2, 10.0, 0.1, "suffix:m/s") var drop_drift := 3.0 # placeholder: until the designer's go on the core/23 strips
## A falling Sock that has not come to rest after this long is put down where it is (T13).
@export_range(1.0, 20.0, 0.5, "suffix:s") var settle_limit := 6.0 # placeholder: the designer's number (today's value from the old game)

## How long a refusal ("Hands full", "Can't drop there") stays on screen.
@export_range(0.2, 5.0, 0.1, "suffix:s") var refusal_time := 2.0 # placeholder: the old HUD's 2 s (core/16 P01, P02; hud.gd _message_timer)

@export_group("Throw")
## How long a charge takes to fill the ring, from the hold to full (T01).
@export_range(0.1, 5.0, 0.05, "suffix:s") var charge_time := 1.2 # placeholder: the designer's number (today's value from the old game; Quick Charge is M4)
## A charge released under this share is the lob (T02).
@export_range(0.0, 1.0, 0.01) var tap_charge := 0.15 # placeholder: the designer's number (today's value from the old game)
## The lob: its speed along the aim, and the speed added straight up (T02).
@export_range(0.0, 20.0, 0.1, "suffix:m/s") var lob_speed := 3.5 # placeholder: the designer's number (today's value from the old game)
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var lob_lift := 2.0 # placeholder: the designer's number (today's value from the old game)
## The speed along the aim at the tap charge and at a full charge (T03; Long Arm is M4).
@export_range(0.0, 30.0, 0.1, "suffix:m/s") var min_speed := 3.0 # placeholder: the designer's number (today's value from the old game)
@export_range(0.0, 30.0, 0.1, "suffix:m/s") var max_speed := 5.0 # placeholder: the designer's number (today's value from the old game)
## The turn a thrown Sock leaves the Hands with.
@export var spin := Vector3(2.0, 1.0, 3.0) # placeholder: the old game's fixed spin (rad/s)
## A thrown Sock's drag in the air (a dropped one has the body's own).
@export_range(0.0, 5.0, 0.01) var thrown_linear_damp := 0.05 # placeholder: the old release.json
@export_range(0.0, 10.0, 0.05) var thrown_angular_damp := 0.8 # placeholder: the old release.json
## A falling body faster than this wakes the lying Sock it hits and up to `wake_count` touching it (T11).
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var wake_speed := 1.5 # placeholder: the designer's number (today's value from the old game)
@export_range(0, 32, 1) var wake_count := 8 # placeholder: the designer's number (today's value from the old game)

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
## How fast the held items glide to their new places when the active item changes, per second (an
## exponential follow, D08).
@export_range(0.0, 60.0, 0.5, "suffix:/s") var follow_rate := 14.0 # placeholder: the old held.json
## How long a picked item flies from where it lay into its place in the Hands, and the hop on the
## way (D09; the pairing moment's second Sock flies the same way, D10).
@export_range(0.05, 2.0, 0.01, "suffix:s") var pick_time := 0.3 # placeholder: the old cloth.json
@export_range(0.0, 1.0, 0.01, "suffix:m") var pick_hop := 0.18 # placeholder: the old held_view.gd's constant

@export_group("Zoom and turn")
## The field of view while the zoom button is held, and how long the view takes to get there.
@export_range(20.0, 90.0, 1.0, "suffix:°") var zoom_fov := 50.0 # placeholder: the designer's number (Q2234, today's value from the old game)
@export_range(0.0, 1.0, 0.01, "suffix:s") var zoom_time := 0.15 # placeholder: the designer's number (Q2234, today's value from the old game)
## Where the active item comes to while zoomed, and its size there.
@export var zoom_pos := Vector3(0.0, -0.02, -0.4) # placeholder: the old held.json (Q2246)
@export_range(0.1, 4.0, 0.05) var zoom_scale := 1.6 # placeholder: the old held.json (Q2246)
## Seconds for one turn of the active item while the turn button is held.
@export_range(0.2, 10.0, 0.1, "suffix:s") var turn_time := 2.0 # placeholder: the designer's number (today's value from the old game)

@export_group("Pairs")
## How long the pairing moment plays (P05): its animation is drawn at this length.
@export_range(0.1, 2.0, 0.05, "suffix:s") var moment := 0.5 # placeholder: the designer's number (today's value from the old game, Q2255)
## A held Pair's sock ball is drawn this many times bigger than a Sock in the same place (P06).
@export_range(0.5, 4.0, 0.05) var ball_scale := 1.6 # placeholder: the old held.json (today's value)
## A dropped or thrown Pair's drag from its first touch, so it stops within a few cm (P07).
@export_range(0.0, 20.0, 0.1) var pair_linear_damp := 2.5 # placeholder: the old release.json
@export_range(0.0, 40.0, 0.5) var pair_angular_damp := 8.0 # placeholder: the old release.json
## How far over and round a picked Sock or Pair a lying Pair is looked for that may have rested on it (P08).
@export_range(0.0, 0.2, 0.005, "suffix:m") var wake_reach := 0.03 # placeholder: the old release.json
## How far under a lying Pair's ball something must lie to still hold it up, else it falls (P08).
@export_range(0.0, 0.05, 0.001, "suffix:m") var wake_gap := 0.006 # placeholder: the old release.json
