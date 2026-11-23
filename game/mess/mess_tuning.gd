## How the Mess's two tiers behave (core/13): the moving budget, the wakes, the rest rule, the bodies
## and the drawing. One .tres beside it (mess_tuning.tres), edited in the inspector. A number marked
## "ported" is the old game's (data/tuning/mess.json, release.json, SockWorld's and SockBodies'
## constants), not a decision; every one waits for the stress test (Q2306).
class_name MessTuning
extends Resource

@export_group("Budget")
## How many Socks may move at once (bodies), Throws and drops included.
@export_range(16, 4096, 1) var moving_budget := 512 # placeholder: ported (SockWorld.MOVING_BUDGET), until a stress test
## The share of the budget only drops and Throws may use: they never wait.
@export_range(0, 512, 1) var throw_reserve := 32 # placeholder: ported (SockWorld.RESERVED), until a stress test
## How many woken Socks start moving in one physics tick at most; the rest wait their turn.
@export_range(1, 256, 1) var start_cap := 16 # placeholder: ported (SockWorld.PROMOTE_CAP), until a stress test
## How many moving Socks come to rest in one physics tick at most.
@export_range(1, 256, 1) var stop_cap := 8 # placeholder: ported (SockWorld.DEMOTE_CAP), until a stress test
## Under pressure (Socks waiting, the budget full) a moving Sock slower than this may be made to rest.
@export_range(0.0, 5.0, 0.01, "suffix:m/s") var pressure_speed := 0.3 # placeholder: ported (SockBodies.PRESSURE_SPEED)
## Those are made to rest in bands of speed (up to `pressure_speed` in this many), the slowest band
## first and the farthest from the players first within a band.
@export_range(1, 100, 1) var pressure_bands := 15 # placeholder: ported (SockBodies' 15 bands)

@export_group("Waking")
## How many lying Socks and Pairs over a picked one wake at most (M07).
@export_range(0, 512, 1) var pick_wakes := 40 # placeholder: ported (SockWorld.PICK_WAKES)
## How high over a picked Sock the Socks resting on it are looked for (a room's height).
@export_range(0.1, 10.0, 0.1, "suffix:m") var pick_column := 2.5 # placeholder: ported (SockBodies.COLUMN)
## How far round a picked Sock's footprint the column reaches.
@export_range(0.0, 0.2, 0.005, "suffix:m") var wake_margin := 0.02 # placeholder: ported (SockBodies.WAKE_MARGIN)
## How far under the picked Sock's top a Sock's bottom may be and still count as lying on it (one
## beside it, on the floor, stays).
@export_range(0.0, 0.1, 0.001, "suffix:m") var above_slack := 0.01 # placeholder: until play
## How far under a laid Sock something must be for it to count as resting (core/55, Q2531): farther,
## it wakes and falls.
@export_range(0.0, 0.1, 0.001, "suffix:m") var support_reach := 0.01 # placeholder: the ticket's 1 cm, until play
## How many lying Socks a moving Door or drawer wakes in one tick at most (M09).
@export_range(1, 512, 1) var sweep_cap := 32 # placeholder: ported (SockWorld.SWEEP_CAP)
## How far round a moving Door's or drawer's shapes a lying Sock counts as in its way or on it.
@export_range(0.0, 0.2, 0.005, "suffix:m") var sweep_margin := 0.02 # placeholder: until play
## How near another lying Sock must be to count as touching one a fast body hit (T11).
@export_range(0.0, 0.1, 0.001, "suffix:m") var touch_margin := 0.01 # placeholder: ported (SockBodies' touch margin)

@export_group("Rest")
## A moving Sock rests after it has stayed under this speed and turn for `rest_time`.
@export_range(0.0, 2.0, 0.01, "suffix:m/s") var rest_speed := 0.05 # placeholder: ported (mess.json rest_speed)
@export_range(0.0, 10.0, 0.05, "suffix:rad/s") var rest_spin := 0.5 # placeholder: ported (SockWorld.REST_SPIN)
@export_range(0.0, 3.0, 0.05, "suffix:s") var rest_time := 0.3 # placeholder: ported (mess.json rest_time)
## A Pair's ball rests under these instead (a damped ball still creeps on a soft slope).
@export_range(0.0, 2.0, 0.01, "suffix:m/s") var pair_rest_speed := 0.25 # placeholder: ported (SockFlights.PAIR_REST_SPEED)
@export_range(0.0, 20.0, 0.1, "suffix:rad/s") var pair_rest_spin := 3.0 # placeholder: ported (SockFlights.PAIR_REST_SPIN)
## A body the physics has put to sleep rests at once, once it has moved for this long (a body just
## launched may start asleep for a tick).
@export_range(0.0, 1.0, 0.01, "suffix:s") var asleep_rest_after := 0.1 # placeholder: until play
## A Guest: a Sock its own falling copy showed glides from where that copy was onto the Host's rest pose
## in this long, instead of snapping there (Q2577); its lying body is at the rest pose at once.
@export_range(0.0, 1.0, 0.01, "suffix:s") var rest_glide := 0.2 # placeholder: Q2577's "about 0.2 s"

@export_group("Lost")
## A lost Sock or Pair (out of bounds, or resting inside a wall) comes back at the return spot,
## scattered within this radius round it (core/16 P12, the old lost.json scatter).
@export_range(0.0, 2.0, 0.01, "suffix:m") var return_scatter := 0.2 # placeholder: the old lost.json scatter
## One whose middle (a Pair's bottom) rests at least this far under a floor's top, and no deeper than
## `sunk_depth`, is pushed up onto that floor where it is, with no pop (P13, the old lost.json sunk).
@export_range(0.0, 0.5, 0.005, "suffix:m") var sunk := 0.02 # placeholder: the old lost.json sunk
## Deeper than this under a floor's top it is lost and comes back at the return spot.
@export_range(0.0, 2.0, 0.01, "suffix:m") var sunk_depth := 0.3 # placeholder: the old lost.json below
## What counts as a floor's top for that: its up at least this (the cosine of its steepest slope).
@export_range(0.0, 1.0, 0.01) var floor_up := 0.7 # placeholder: ported (hands_rules.gd's floor test)

@export_group("Pushed out of a leaf")
## A Sock or Pair that would rest with its middle inside a Door's or drawer's leaf is pushed out of
## it to the side the leaf swept from (core/39, Q2428): all of it ends this far clear of the leaf's face.
@export_range(0.0, 0.5, 0.005, "suffix:m") var leaf_clearance := 0.02 # placeholder: until the designer plays it (core/39)
## How it moves out: it flies on from just past the face at this speed, away from the leaf, and
## rests where it comes to rest; 0 puts it down past the face at once.
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var leaf_push_speed := 0.4 # placeholder: until the designer plays it (core/39)
## How many times one flight is pushed out so; after that it is put down past the face at once.
@export_range(1, 10, 1) var leaf_push_tries := 3 # placeholder: until the designer plays it (core/39)

@export_group("Pushed into the floor")
## A flight that one physics step moves farther than its own speed and turn explain, by more than this,
## leaving the middle of its leg or foot inside the house, was pushed there by Jolt's position solve, not
## flown (core/50: a Sock was so pushed 0.17 m to 0.24 m into the zoo's 0.2 m floor in one step, and
## then held under it by the floor's bottom face).
@export_range(0.0, 0.5, 0.005, "suffix:m") var push_slack := 0.05 # placeholder: core/50, until the designer plays it
## How far from its middle a turning Sock's ends move per radian, for that (about half its leg).
@export_range(0.0, 1.0, 0.01, "suffix:m") var push_reach := 0.2 # placeholder: core/50, half a Sock's 0.35 m leg rounded up
## Such a flight goes back where it was the step before, this much higher, its fall and turn stopped:
## at exactly the same place Jolt pushes it in again the next step.
@export_range(0.0, 0.1, 0.001, "suffix:m") var push_lift := 0.01 # placeholder: core/50, the least that broke the repeat in the replay

@export_group("Bodies")
## A woken Sock's slide and drag (M10).
@export_range(0.0, 2.0, 0.01) var woken_friction := 0.9 # placeholder: ported (mess.json friction)
@export_range(0.0, 10.0, 0.05) var woken_linear_damp := 0.6 # placeholder: ported (mess.json linear_damp)
@export_range(0.0, 20.0, 0.1) var woken_angular_damp := 3.0 # placeholder: ported (mess.json angular_damp)
## A dropped or thrown Sock's or Pair's bounce and slide (M10; its drag is the Throw's, HandsTuning).
@export_range(0.0, 1.0, 0.01) var released_bounce := 0.35 # placeholder: ported (Flight.restitution)
@export_range(0.0, 2.0, 0.01) var released_friction := 0.6 # placeholder: ported (Flight.friction)
## How many times its flat box's own turning inertia a flying Sock has (core/23 F1): 1 is a rigid
## board, which an edge landing or a touch off its middle spins up to 40 rad/s or more (a flip a
## frame); more turns it as a soft thing would, its throw's spin and its topple flat slower too.
@export_range(1.0, 20.0, 0.1) var turn_weight := 3.0 # placeholder: until the designer's go on the core/23 strips
## A flying body this fast sweeps its way (continuous collision); under `ccd_off` it no longer does
## (the old SockWorld.CCD_ON, CCD_OFF): a 2 cm Sock moving most of its thickness a tick could pass
## through a thin part, and a slow one swept into its contacts is kicked into a spin.
@export_range(0.0, 10.0, 0.05, "suffix:m/s") var ccd_on := 1.0 # placeholder: ported (SockWorld.CCD_ON)
@export_range(0.0, 10.0, 0.05, "suffix:m/s") var ccd_off := 0.5 # placeholder: ported (SockWorld.CCD_OFF)
## A Sock's leg and foot boxes are at least this thick from its bottom up (the old SockWorld.MIN_THICK);
## read once a run, when the first Mess fits them.
@export_range(0.005, 0.1, 0.001, "suffix:m") var min_thick := 0.024 # placeholder: ported (SockWorld.MIN_THICK)

@export_group("Drawing")
## The floor grid lying Socks are drawn in, one MultiMesh per cell and kind (M02, Q2310).
@export_range(1.0, 64.0, 0.5, "suffix:m") var cell_size := 8.0 # placeholder: the designer's 8 m (Q2310), until play
## How far from the camera a cell's lying Socks are still drawn.
@export_range(5.0, 500.0, 1.0, "suffix:m") var draw_range := 60.0 # placeholder: until play

@export_group("Sound")
## A hit at least this fast (the body's speed just before the step it touched in) plays "bounce"
## (the old game's 1.5 m/s into a surface; the speed along the surface's normal is not read).
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var bounce_speed := 1.5 # placeholder: ported (flight.gd), until the designer listens
## The hit speed at which "bounce" is at its loudest and highest; a slower hit is softer, lower.
@export_range(1.0, 30.0, 0.5, "suffix:m/s") var bounce_hard_speed := 8.0 # placeholder: until the designer listens (Q2371)
