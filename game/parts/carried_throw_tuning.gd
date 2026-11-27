## The numbers of a thrown carried thing's flight (the thrown-knock rule, core/163): how it bounces off
## the house and when it lies, the old game's flight (data/tuning/upgrades.json "throw", flight.gd,
## flight_rules.gd item_throw). One .tres beside it (carried_throw_tuning.tres), edited in the inspector.
## The Throw's speeds and charge are the Hands' (HandsTuning, with the Upgrades); none are here.
class_name CarriedThrowTuning
extends Resource

## How much of its speed into a surface it keeps, bounced back off it (the old restitution).
@export_range(0.0, 1.0, 0.01) var restitution := 0.35 # placeholder: the old upgrades.json throw.restitution
## How much of its speed along a surface it loses at a touch (the old friction).
@export_range(0.0, 1.0, 0.01) var friction := 0.6 # placeholder: the old upgrades.json throw.friction
## Slower than this after touching a floor (a top whose up is over `floor_up`), it lies there (the old rest_speed).
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var rest_speed := 0.6 # placeholder: the old upgrades.json throw.rest_speed
## A touched surface whose normal's up is over this is a floor (the old flight.gd 0.7).
@export_range(0.0, 1.0, 0.01) var floor_up := 0.7 # placeholder: the old flight.gd 0.7
## After this many bounces it lies on the first top under where it touched (technical: never for ever).
@export_range(0, 20, 1) var most_bounces := 6 # placeholder: technical, the old flight had no count
## A flight longer than this is lost: it comes back lying in front of the washer.
@export_range(1.0, 60.0, 0.5, "suffix:s") var most_seconds := 10.0 # placeholder: technical, the old flight.gd max_age
## The tumble it is thrown with, each axis drawn by the Host between minus and plus this (rad/s): the
## old item_throw's tip of the Radio.
@export var spin_tip := Vector3(4.0, 2.0, 4.0) # placeholder: the old radio_rules.gd item_throw tip (4, 2, 4)
