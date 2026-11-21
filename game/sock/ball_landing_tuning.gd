## How a Pair's sock ball lands (core/16 P04, the old sock_ball.gd and data/tuning/ball.json): one
## .tres beside it (ball_landing_tuning.tres), edited in the inspector.
class_name BallLandingTuning
extends Resource

@export_group("Squash")
## How far the ball squashes as it touches down and again as it settles: 0 round, 0.28 to 72 % of
## its height (and half as much wider), about its bottom, along world up.
@export_range(0.0, 0.9, 0.01) var squash := 0.28 # placeholder: the old ball.json squash
## How long each squash lasts, out and back on a sine.
@export_range(0.01, 1.0, 0.01, "suffix:s") var squash_time := 0.16 # placeholder: the old ball.json squash_time

@export_group("Hop")
## How high the drawn ball hops after it touches down (the body rolls on beneath it), in m at
## Size medium; it starts with the first squash and the second squash plays as it comes down.
@export_range(0.0, 0.5, 0.005, "suffix:m") var bounce_height := 0.04 # placeholder: the old ball.json bounce_height
## How long the hop lasts.
@export_range(0.01, 1.0, 0.01, "suffix:s") var bounce_time := 0.2 # placeholder: the old ball.json bounce_time
## How far a ball that flies to a set rest (a shelved one, core/27 P10) lands short of it and rolls
## on to it during the hop, in m; less than half the flight's length when that is short. A falling
## body rolls by physics instead.
@export_range(0.0, 0.5, 0.005, "suffix:m") var roll_distance := 0.12 # placeholder: the old ball.json roll_distance

@export_group("Touch")
## A falling ball counts as touching down when, falling at least `touch_speed`, its fall is checked
## by at least `touch_change` in one physics tick (it hit something under it).
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var touch_speed := 0.4 # placeholder: new (the port's ball falls as a body), not felt in play
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var touch_change := 0.3 # placeholder: new (the port's ball falls as a body), not felt in play
