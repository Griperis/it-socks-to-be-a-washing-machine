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
## How many lying Socks a moving Door or drawer wakes in one tick at most (M09).
@export_range(1, 512, 1) var sweep_cap := 32 # placeholder: ported (SockWorld.SWEEP_CAP)
## How far round a moving Door's or drawer's shapes a lying Sock counts as in its way or on it.
@export_range(0.0, 0.2, 0.005, "suffix:m") var sweep_margin := 0.02 # placeholder: until play

@export_group("Rest")
## A moving Sock rests after it has stayed under this speed and turn for `rest_time`.
@export_range(0.0, 2.0, 0.01, "suffix:m/s") var rest_speed := 0.05 # placeholder: ported (mess.json rest_speed)
@export_range(0.0, 10.0, 0.05, "suffix:rad/s") var rest_spin := 0.5 # placeholder: ported (SockWorld.REST_SPIN)
@export_range(0.0, 3.0, 0.05, "suffix:s") var rest_time := 0.3 # placeholder: ported (mess.json rest_time)
## A Pair's ball rests under these instead (a damped ball still creeps on a soft slope).
@export_range(0.0, 2.0, 0.01, "suffix:m/s") var pair_rest_speed := 0.25 # placeholder: ported (SockFlights.PAIR_REST_SPEED)
@export_range(0.0, 20.0, 0.1, "suffix:rad/s") var pair_rest_spin := 3.0 # placeholder: ported (SockFlights.PAIR_REST_SPIN)

@export_group("Bodies")
## A woken Sock's slide and drag (M10).
@export_range(0.0, 2.0, 0.01) var woken_friction := 0.9 # placeholder: ported (mess.json friction)
@export_range(0.0, 10.0, 0.05) var woken_linear_damp := 0.6 # placeholder: ported (mess.json linear_damp)
@export_range(0.0, 20.0, 0.1) var woken_angular_damp := 3.0 # placeholder: ported (mess.json angular_damp)
## A dropped or thrown Sock's or Pair's bounce and slide (M10; its drag is the Throw's, HandsTuning).
@export_range(0.0, 1.0, 0.01) var released_bounce := 0.35 # placeholder: ported (Flight.restitution)
@export_range(0.0, 2.0, 0.01) var released_friction := 0.6 # placeholder: ported (Flight.friction)

@export_group("Drawing")
## The floor grid lying Socks are drawn in, one MultiMesh per cell and kind (M02, Q2310).
@export_range(1.0, 64.0, 0.5, "suffix:m") var cell_size := 8.0 # placeholder: the designer's 8 m (Q2310), until play
## How far from the camera a cell's lying Socks are still drawn.
@export_range(5.0, 500.0, 1.0, "suffix:m") var draw_range := 60.0 # placeholder: until play
