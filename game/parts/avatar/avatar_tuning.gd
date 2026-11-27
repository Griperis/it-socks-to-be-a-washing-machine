## How a Teammate's avatar follows their pose and moves (coop/05): one .tres beside it
## (avatar_tuning.tres), edited in the inspector. Read by the Avatar (the follow, the pose bounds) and
## its AvatarLooks (every motion derived from the drawn movement). The numbers are the old game's
## (data/tuning/avatar.json, rig.gd), kept by Q2450, Q2451 and Q2461.
class_name AvatarTuning
extends Resource

@export_group("Follow")
## How much of the way to the newest pose the drawn position, yaw and pitch move each second
## (`min(1, follow * delta)` a frame; Q2450).
@export_range(1.0, 60.0, 0.5, "suffix:/s") var follow := 12.0
## How fast the drawn crouch moves toward the sent one, per second (Q2450).
@export_range(0.5, 30.0, 0.5, "suffix:/s") var crouch_follow := 6.0
## A pose further than this from the last one, in one update, is a jump: the body stands there at
## once (Q2451).
@export_range(0.1, 10.0, 0.1, "suffix:m") var snap := 1.0
## The farthest a rider's sent place may be from the feet of the player they ride (core/41, Q2592); a
## pose further off is dropped.
@export_range(0.5, 5.0, 0.1, "suffix:m") var ride_reach := 2.5 # placeholder: the designer's number (a guard: a stack of three is 1.4 m a step)
## The area a pose may name: the zoo's stations (x and z; batch C's run out to x = 298, core/182) widened by `margin` on every side, and this
## height range. A pose outside it, or not a finite number, is dropped where it arrives.
@export var area := Rect2(-20.0, -60.0, 330.0, 80.0)
@export_range(0.0, 100.0, 1.0, "suffix:m") var margin := 30.0
@export var height_range := Vector2(-50.0, 100.0)
## The pitch a pose may name, either way (the player's own pitch limit).
@export_range(10.0, 90.0, 1.0, "suffix:°") var pitch_limit := 85.0

@export_group("Waddle")
## A move further than this in one frame is a teleport: no waddle, no squash (avatar.gd TELEPORT).
@export_range(0.1, 10.0, 0.1, "suffix:m") var teleport := 1.0
## Seconds the speed along the floor is smoothed over.
@export_range(0.01, 1.0, 0.01, "suffix:s") var waddle_smooth := 0.1
## The speed at which the waddle is full.
@export_range(0.1, 10.0, 0.1, "suffix:m/s") var walk_speed := 3.0
## How fast the waddle share follows the speed, per second.
@export_range(0.1, 20.0, 0.1, "suffix:/s") var walk_rate := 4.0
## Metres walked per full waddle (both feet).
@export_range(0.1, 5.0, 0.05, "suffix:m") var stride := 0.9
## How far each foot rocks about x and about z at a full waddle.
@export_range(0.0, 90.0, 0.5, "suffix:°") var foot_swing := 22.0
@export_range(0.0, 90.0, 0.5, "suffix:°") var foot_roll := 8.0
## How far the body rises at each step, and rocks side to side.
@export_range(0.0, 0.5, 0.005, "suffix:m") var bob := 0.035
@export_range(0.0, 30.0, 0.5, "suffix:°") var sway := 3.0

@export_group("Look bend")
## How far the top of the sock curls forward looking straight down, and leans back looking up.
@export_range(0.0, 90.0, 1.0, "suffix:°") var bend_down := 36.0
@export_range(0.0, 90.0, 1.0, "suffix:°") var bend_up := 24.0
## How fast the bend eases toward the look, per second.
@export_range(0.1, 30.0, 0.1, "suffix:/s") var bend_speed := 8.0

@export_group("Squash")
## How much taller it stretches leaving the floor, and shorter it squishes landing a full fall.
@export_range(0.0, 1.0, 0.01) var squash_stretch := 0.2
@export_range(0.0, 1.0, 0.01) var squash_squish := 0.45
## The fall height of a full squish, and the least one that squishes at all.
@export_range(0.1, 10.0, 0.05, "suffix:m") var squash_full_fall := 1.5
@export_range(0.0, 2.0, 0.01, "suffix:m") var squash_min_fall := 0.15
## The rise that counts as a jump, and the seconds the rise is smoothed over.
@export_range(0.1, 20.0, 0.1, "suffix:m/s") var squash_takeoff_speed := 3.0
@export_range(0.005, 1.0, 0.005, "suffix:s") var squash_smooth := 0.05
## The spring back: wobbles a second, and its damping (0 wobbles on, 1 settles at once).
@export_range(0.1, 20.0, 0.1, "suffix:/s") var squash_freq := 3.0
@export_range(0.0, 1.0, 0.01) var squash_damping := 0.35
## The gravity the fall height is worked out with (the player's).
@export_range(1.0, 60.0, 0.5, "suffix:m/s²") var gravity := 20.0

@export_group("Pupils")
## Another player within this range has the pupils turn to their eyes (the nearest wins).
@export_range(0.0, 30.0, 0.5, "suffix:m") var look_range := 6.0
## The furthest a pupil turns off its rest, and how fast it follows, per second.
@export_range(0.0, 60.0, 1.0, "suffix:°") var look_max := 28.0
@export_range(0.1, 30.0, 0.1, "suffix:/s") var look_speed := 6.0
## A target further off the rest than this (behind the creature) is not looked at.
@export_range(0.0, 180.0, 1.0, "suffix:°") var look_cone := 100.0
## With nobody near: how far the idle drift goes sideways (half that up or down), and how often it
## changes (times 0.6 to 1.4).
@export_range(0.0, 30.0, 0.5, "suffix:°") var wander := 8.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var wander_time := 1.6
## A player's eyes are this far under the top of their body (standing or crouched).
@export_range(0.0, 0.5, 0.05, "suffix:m") var eye_below_top := 0.1
@export_range(0.5, 3.0, 0.05, "suffix:m") var stand_height := 1.7
@export_range(0.5, 3.0, 0.05, "suffix:m") var crouch_height := 1.0

@export_group("First person")
## The own body (coop/06, Q2466): only the body below this height is drawn, looking down.
@export_range(0.0, 1.7, 0.01, "suffix:m") var belly_cut := 0.8
## How far that belly sits behind the eyes, so its front curve shows looking down.
@export_range(0.0, 1.0, 0.01, "suffix:m") var belly_back := 0.22

@export_group("Colour and tag")
## How much darker than the player colour the trim (cuff stripes, heel patch, feet) is.
@export_range(0.0, 1.0, 0.01) var trim_darken := 0.35
## How much lighter than the player colour the name tag is.
@export_range(0.0, 1.0, 0.01) var tag_lighten := 0.35


## Whether `at` is a place a pose may name.
func holds(at: Vector3) -> bool:
	var wide := area.grow(margin)
	return at.is_finite() and wide.has_point(Vector2(at.x, at.z)) and at.y >= height_range.x and at.y <= height_range.y
