## Every number of the spray of Socks out of the washing machine's door (core/89; the old game's
## data/tuning/first_wash.json "spit", FirstWashSpit's constants). One .tres beside it
## (sock_spray_tuning.tres), edited in the inspector. Its own Resource so the spray can be tweaked alone.
class_name SockSprayTuning
extends Resource

## How many Socks fly.
@export_range(1, 2000, 1) var count := 500 # placeholder: ported (spit.count), until the designer plays it
## How fast a Sock leaves the door.
@export_range(0.1, 20.0, 0.1, "suffix:m/s") var speed := 2.6 # placeholder: ported (spit.speed)
## How much each Sock's speed varies, as a share of `speed`.
@export_range(0.0, 1.0, 0.01) var speed_jitter := 0.35 # placeholder: ported (spit.speed_jitter, 35 %)
## The half-angle of the cone the Socks fly in, sideways (up and down it is half of it).
@export_range(0.0, 90.0, 0.5, "suffix:deg") var spread_deg := 24.0 # placeholder: ported (spit.spread_deg)
## How far up from the door's direction the cone is aimed.
@export_range(-45.0, 90.0, 0.5, "suffix:deg") var up_deg := 35.0 # placeholder: ported (spit.up_deg)
## Over how long the Socks leave the door one after another.
@export_range(0.1, 10.0, 0.1, "suffix:s") var window := 1.8 # placeholder: ported (spit.window)
## How long the whole effect lasts (the door swings open before it and shut over its end).
@export_range(0.5, 20.0, 0.1, "suffix:s") var length := 3.6 # placeholder: ported (spit.length)
## How long the washer's door takes to open (the washer's swing, called by the First wash).
@export_range(0.0, 5.0, 0.05, "suffix:s") var door_open := 0.4 # placeholder: ported (spit.door_open)
## How long the door takes to shut again, over the last of `length`.
@export_range(0.0, 5.0, 0.05, "suffix:s") var door_close := 0.6 # placeholder: ported (spit.door_close)
## How fast a Sock turns about its own axes.
@export_range(0.0, 30.0, 0.1, "suffix:rad/s") var spin := 8.0 # placeholder: ported (spit.spin)
@export_range(0.0, 30.0, 0.1, "suffix:m/s2") var gravity := 9.8 # placeholder: ported (spit.gravity)
## How much of its fall speed a Sock keeps going up off the floor.
@export_range(0.0, 1.0, 0.01) var bounce := 0.35 # placeholder: ported (spit.bounce)
## How much of its sideways speed a Sock keeps at each bounce.
@export_range(0.0, 1.0, 0.01) var floor_grip := 0.7 # placeholder: ported (FirstWashSpit._process, 0.7)
## A bounce that goes up slower than this is the Sock's last: it lies flat.
@export_range(0.0, 2.0, 0.01, "suffix:m/s") var rest_speed := 0.3 # placeholder: ported (FirstWashSpit._process, 0.3)
## The seed of the Designs drawn and every Sock's throw: every machine draws the same spray.
@export var seed := 7 # placeholder: ported (spit.seed)
