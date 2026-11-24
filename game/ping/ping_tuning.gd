## The numbers of the pings (core/43, list 03 answered by Q2590): making one, what it reaches, how it
## draws and the emoji wheel. One .tres beside it (ping_tuning.tres), edited in the inspector. Every
## number is the old game's (data/tuning/ping.json and the old pings.gd, ping_wheel.gd), not a decision.
## The Teammate's body the crosshair meets is the Hand-off's (HandOffTuning.body_radius, feet_lift).
class_name PingTuning
extends Resource

@export_group("Making one")
## How long a ping stands, on each machine's own clock (lines 22, 42).
@export_range(0.5, 30.0, 0.1, "suffix:s") var seconds := 4.0 # placeholder: the old ping.json seconds
## How far the crosshair's line reaches for a ping (line 16).
@export_range(1.0, 100.0, 0.5, "suffix:m") var reach := 30.0 # placeholder: the old ping.json range
## A Sock or Pair is found this far past the reach (the old SockWorld.PICK_SLACK, line 16).
@export_range(0.0, 2.0, 0.05, "suffix:m") var pick_slack := 0.5 # placeholder: the old SockWorld.PICK_SLACK
## The Host's check that the spot is in reach of the pinger allows this much more (its view of a
## Guest is a little old, and the eyes stand over the feet).
@export_range(0.0, 10.0, 0.5, "suffix:m") var reach_slack := 3.0 # placeholder: the Host's slack, not the old game's
## The middle button held this long opens the wheel; let go sooner it is a tap (lines 3, 4).
@export_range(0.05, 2.0, 0.01, "suffix:s") var hold := 0.25 # placeholder: the old ping.json hold

@export_group("Highlight")
## The outline, this many times as wide as the crosshair's (line 22).
@export_range(0.5, 6.0, 0.1) var outline_width := 2.2 # placeholder: the old pings.gd OUTLINE_WIDTH
## The outline's render priority: after the aim's outline (line 30).
@export_range(-128, 120, 1) var outline_priority := 110 # placeholder: after aim.tres's 100
## The live copy of a pinged Sock: scaled this much and raised this far over it (line 23).
@export_range(1.0, 1.2, 0.001) var copy_scale := 1.01 # placeholder: the old pings.gd 1.01
@export_range(0.0, 0.05, 0.001, "suffix:m") var copy_raise := 0.002 # placeholder: the old pings.gd 2 mm
## The ring on a bare spot: its band's radii, the ink rim's extra width all round, its height squash
## and how far over the surface it lies (line 25).
@export_range(0.01, 2.0, 0.01, "suffix:m") var ring_inner := 0.2 # placeholder: the old pings.gd RING_INNER
@export_range(0.01, 2.0, 0.01, "suffix:m") var ring_outer := 0.32 # placeholder: the old pings.gd RING_OUTER
@export_range(0.0, 0.2, 0.005, "suffix:m") var ring_rim := 0.02 # placeholder: the old pings.gd 0.02
@export_range(0.05, 1.0, 0.05) var ring_squash := 0.2 # placeholder: the old pings.gd 0.2
@export_range(0.0, 0.1, 0.005, "suffix:m") var ring_raise := 0.01 # placeholder: the old pings.gd 1 cm
## A far ring grows with the distance times this, never under 1 (line 26).
@export_range(0.0, 2.0, 0.01) var ring_grow := 0.25 # placeholder: the old ping.json ring_grow
## A ring is never drawn smaller across than this share of the screen's height (line 26).
@export_range(0.0, 0.5, 0.005) var min_ring := 0.04 # placeholder: the old ping.json min_ring

@export_group("Appearing")
## A ping grows from `pop_from` to full over this (line 27).
@export_range(0.0, 2.0, 0.01, "suffix:s") var pop := 0.15 # placeholder: the old pings.gd POP
@export_range(0.0, 1.0, 0.01) var pop_from := 0.01 # placeholder: the old pings.gd 1 %
## Its last this-many seconds it fades out (lines 28, 35).
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade := 1.0 # placeholder: the old pings.gd FADE

@export_group("Emoji")
## The bubble's own time, inside the ping's (line 35).
@export_range(0.5, 30.0, 0.1, "suffix:s") var bubble_seconds := 3.0 # placeholder: the old ping.json bubble_seconds
## The bubble's height, a share of the screen's height, the same at any distance (line 32).
@export_range(0.01, 0.5, 0.005) var size := 0.12 # placeholder: the old ping.json size
## How far over the pinged thing (halved for a thing, not a spot) the bubble's tail stands (line 33).
@export_range(0.0, 2.0, 0.05, "suffix:m") var lift := 0.3 # placeholder: the old ping.json lift
## Over a Sock's middle, before the lift (line 33).
@export_range(0.0, 0.5, 0.01, "suffix:m") var sock_top := 0.05 # placeholder: the old pings.gd 0.05
## Over a player's `Head` node (lines 33, 37).
@export_range(0.0, 2.0, 0.05, "suffix:m") var head_lift := 0.45 # placeholder: the old ping.json head_lift
## The copy beside the pinger's head: moved this far to the camera's right, at this share of the size (line 37).
@export_range(0.0, 2.0, 0.05, "suffix:m") var head_side := 0.35 # placeholder: the old ping.json head_side
@export_range(0.1, 1.0, 0.05) var head_share := 0.7 # placeholder: the old pings.gd HEAD_SHARE
## The emoji's icon, this share of the bubble (line 31).
@export_range(0.1, 1.0, 0.05) var icon_share := 0.6 # placeholder: the old pings.gd ICON_SHARE
## The wall test from the camera stops this short of the bubble (line 36).
@export_range(0.0, 1.0, 0.01, "suffix:m") var wall_slack := 0.1 # placeholder: the old Pings.blocked slack

@export_group("Wheel")
## The keycaps' middles stand this far from the crosshair; the pointer goes no further (lines 9, 11).
@export_range(40.0, 400.0, 1.0, "suffix:px") var wheel_radius := 150.0 # placeholder: the old ping_wheel.gd RADIUS
## Nearer the centre than this, nothing is chosen (a cancel, line 12).
@export_range(0.0, 200.0, 1.0, "suffix:px") var wheel_dead := 40.0 # placeholder: the old ping_wheel.gd DEAD
## The keycaps' icon size and a chosen keycap's growth (lines 9, 13).
@export_range(8.0, 200.0, 1.0, "suffix:px") var wheel_icon := 56.0 # placeholder: the old ping_wheel.gd ICON
@export_range(1.0, 2.0, 0.01) var wheel_chosen_scale := 1.18 # placeholder: the old ping_wheel.gd CHOSEN_SCALE
## The dark disc's radius and opacity (line 10).
@export_range(0.0, 600.0, 1.0, "suffix:px") var wheel_disc := 220.0 # placeholder: the old ping_wheel.gd RADIUS + 70
@export_range(0.0, 1.0, 0.01) var wheel_disc_alpha := 0.35 # placeholder: the old ping_wheel.gd 0.35
## The centre ring's radius; the pointer's line ends this far short of the keycap's middle (lines 10, 13).
@export_range(0.0, 100.0, 1.0, "suffix:px") var wheel_centre := 24.0 # placeholder: the old ping_wheel.gd DEAD * 0.6
@export_range(0.0, 150.0, 1.0, "suffix:px") var wheel_line_short := 52.0 # placeholder: the old ping_wheel.gd 52
## A pad's right stick nearer its rest than this is the centre (line 8).
@export_range(0.0, 0.9, 0.01) var wheel_deadzone := 0.3 # placeholder: the old pad.json wheel_deadzone
