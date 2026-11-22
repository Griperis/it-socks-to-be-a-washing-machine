## The numbers of a knockdown and a drag (coop/10, docs/migration/m06-lists/04-knockdown.md "Numbers"):
## one .tres beside it (knockdown_tuning.tres), edited in the inspector. Every number is the old
## game's (data/tuning/knockdown.json, drag.json, ragdoll.gd), a placeholder there, except `seconds`
## (Q985); none is a decision of this port.
class_name KnockdownTuning
extends Resource

@export_group("Hit")
## The Throw charge that knocks a Teammate down (the full ring).
@export_range(0.0, 1.0, 0.01) var min_charge := 1.0 # placeholder: the old knockdown.json min_charge
## The body's radius a Flight's ball is tested against, and the bones' capsule radius.
@export_range(0.1, 1.0, 0.01, "suffix:m") var body_radius := 0.3 # placeholder: the old players.json body_radius
## The share of its speed a knocking item keeps as it bounces back off the body (sideways only).
@export_range(0.0, 1.0, 0.01) var bounce := 0.05 # placeholder: the old knockdown.json bounce

@export_group("Down")
## How long a knocked player lies, getting up included (decided, Q985).
@export_range(0.5, 30.0, 0.1, "suffix:s") var seconds := 5.5
## The blend up from the lying pose to standing, at the end of `seconds` (Q2488).
@export_range(0.05, 3.0, 0.05, "suffix:s") var rise_time := 0.6 # placeholder: the old knockdown.json rise_time

@export_group("Fall")
## The top of the body moves along the push this fast; each bone by its height over `top`.
@export_range(0.0, 20.0, 0.1, "suffix:m/s") var push_speed := 3.0 # placeholder: the old knockdown.json push_speed
## A hit high on the body pushes harder: from 1 - high_kick at the feet to 1 + high_kick at the top.
@export_range(0.0, 1.0, 0.05) var high_kick := 0.5 # placeholder: the old knockdown.json high_kick
## The turn about the up axis at the body's edge, times how far off centre it hit.
@export_range(0.0, 20.0, 0.1, "suffix:rad/s") var spin := 3.0 # placeholder: the old knockdown.json spin
## The height the push is measured against (the old ragdoll.gd TOP).
@export_range(0.5, 3.0, 0.05, "suffix:m") var top := 1.7 # placeholder: the old ragdoll.gd TOP

@export_group("View")
## The knocked player's eyes over the feet along the top bone (the old ragdoll.gd EYE).
@export_range(0.5, 3.0, 0.05, "suffix:m") var eye := 1.6 # placeholder: the old ragdoll.gd EYE
## The view stops this short of a wall between the body's middle and the eyes.
@export_range(0.0, 1.0, 0.05, "suffix:m") var wall_gap := 0.3 # placeholder: the old knockdown.json wall_gap
## The vignette (Q2490): how dark its edge gets, and where from the middle (0) to the corner (1) it starts.
@export_range(0.0, 1.0, 0.05) var vignette_dark := 0.7 # placeholder: waits for the designer's still (Q2490)
@export_range(0.0, 1.0, 0.05) var vignette_start := 0.45 # placeholder: waits for the designer's still (Q2490)

## How long "<Name> knocked you down" stays on the knocked player's screen.
@export_range(0.5, 10.0, 0.1, "suffix:s") var message_time := 2.0 # placeholder: the co-op toast time (CoopTuning)

@export_group("Sync")
## A Guest's ragdoll eases toward the Host's newest pose this much a second (the old ragdoll.gd).
@export_range(1.0, 60.0, 0.5, "suffix:1/s") var ease := 12.0 # placeholder: the old ragdoll.gd

@export_group("Get up")
## The feet are dropped onto the floor by a ray from this far above them to this far below.
@export_range(0.0, 2.0, 0.05, "suffix:m") var floor_above := 0.5 # placeholder: the old rig_knockdown.gd
@export_range(0.0, 3.0, 0.05, "suffix:m") var floor_below := 1.0 # placeholder: the old rig_knockdown.gd

@export_group("Drag")
## The dragger walks at this share of their pace.
@export_range(0.05, 1.0, 0.05) var drag_speed := 0.6 # placeholder: the old drag.json speed
## The feet are held this high over the dragger's feet and this far behind their middle.
@export_range(0.0, 2.0, 0.05, "suffix:m") var hold_height := 0.4 # placeholder: the old drag.json hold_height
@export_range(0.0, 2.0, 0.05, "suffix:m") var hold_behind := 0.6 # placeholder: the old drag.json hold_behind
## The spring that pulls the feet to the hold (critically damped), per second squared per metre.
@export_range(1.0, 400.0, 1.0) var pull := 60.0 # placeholder: the old drag.json pull
## Further than this from the hold, once it was within it, the drag ends ("apart").
@export_range(0.5, 10.0, 0.1, "suffix:m") var break_distance := 2.0 # placeholder: the old drag.json break_distance
## The presses of the jump key that free a dragged player.
@export_range(1, 100, 1) var struggle_presses := 10 # placeholder: the old drag.json struggle_presses
## A "drag_scrape" plays each time the feet move this far along the floor.
@export_range(0.05, 5.0, 0.05, "suffix:m") var scrape_every := 0.5 # placeholder: the old drag.json scrape_every
## How near a lying body's middle line the aim must pass, and how far it may be, to grab it.
@export_range(0.5, 10.0, 0.1, "suffix:m") var grab_reach := 2.5 # placeholder: the Hands' reach (the old rig_aim.gd)
