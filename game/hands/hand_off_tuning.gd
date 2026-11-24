## The numbers of the Hand-off between players (core/42, list 02 approved with Q2588-Q2590): aiming a
## Teammate and the catch by Throw's bounce. One .tres beside it (hand_off_tuning.tres), edited in the
## inspector. The reach is the Hands' (HandsTuning.reach); the item's flight into the receiver's Hands
## is the pick's (HandsTuning.pick_time, pick_hop); the catch's hit test is the knockdown's
## (KnockdownTuning.body_radius). Every number is the old game's, not a decision.
class_name HandOffTuning
extends Resource

## How far round a Teammate's middle line the crosshair's line counts as on their body (line 1).
@export_range(0.05, 1.0, 0.01, "suffix:m") var body_radius := 0.3 # placeholder: the old players.json body_radius
## Their body's middle line starts this far over their feet and ends at the top of their height (line 1).
@export_range(0.0, 0.5, 0.01, "suffix:m") var feet_lift := 0.1 # placeholder: the old rig_aim.gd's 0.1
## A Throw below full charge that a Teammate may not catch (a loose Sock completing no Pair there)
## bounces back off their body at this share of its speed, sideways turned back, upwards kept (line 35).
@export_range(0.0, 1.0, 0.01) var bounce := 0.25 # placeholder: the old hand_off.json bounce
