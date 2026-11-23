## The numbers of a Guest's looks-only ghosts (Q2220, Q2221, Q2473) and of a Throw's stamped stream
## (coop/09): one .tres beside it (ghost_tuning.tres), edited in the inspector. Every number is the old
## game's (data/tuning/release.json, cloth.json, flight.gd, flights.gd) or an answer's, not a decision.
class_name GhostTuning
extends Resource

@export_group("Stream")
## How far behind the Host's clock a Guest plays a thrown body (the old Flight.STREAM_LAG).
@export_range(0.0, 0.5, 0.01, "suffix:s") var stream_lag := 0.1 # placeholder: the old flight.gd STREAM_LAG
## Past the newest row a Guest's copy goes on along its velocity at most this long.
@export_range(0.0, 0.5, 0.01, "suffix:s") var stream_extrapolate := 0.1 # placeholder: coop/01's spike

@export_group("Answer")
## A pick, drop or Throw with no answer after this long goes back, with "refuse" (Q2477).
@export_range(0.5, 10.0, 0.1, "suffix:s") var answer_timeout := 2.0 # placeholder: Q2477's 2 s (the refusal text's time)

@export_group("Throw and drop ghost")
## A ghost's drawn offset moves `1 - exp(-3 dt / predict_blend)` of the way to how the Host's body
## differs at the same moment of the flight: 95 per cent in this long (G04, G11).
@export_range(0.01, 1.0, 0.01, "suffix:s") var predict_blend := 0.2 # placeholder: the old release.json predict_blend
## A Throw's ghost is drawn from the first-person hand and eases onto its body, which flies the Host's
## launch from the avatar's hand, in this long (Q2481, coop/11).
@export_range(0.0, 1.0, 0.01, "suffix:s") var hand_over_time := 0.2 # placeholder: Q2481's 0.2 s
## The ghost lies at the Host's rest once nearer than this, or after `settle_wait` (G07).
@export_range(0.0001, 0.05, 0.0001, "suffix:m") var settle_close := 0.002 # placeholder: the old thrown_item.gd
@export_range(0.1, 5.0, 0.1, "suffix:s") var settle_wait := 2.0 # placeholder: the old flights.gd
## At the rest the ghost's cloth lies flat first, waiting at most this long (G08: the old flights.gd).
@export_range(0.0, 5.0, 0.1, "suffix:s") var flat_wait := 1.5 # placeholder: the old flights.gd
## Once the Mess draws the Sock, the ghost's Looks stays this many frames more: no blank frame (G08).
@export_range(0, 10, 1) var keep_frames := 3 # placeholder: the old flights.gd
## A ghost's flight poses kept, for comparing at a moment of the flight (G06).
@export_range(10, 400, 1) var keep_poses := 90 # placeholder: the old flight.gd

@export_group("Pick ghost")
## A refused pick's ghost flies back to where the Sock lay (or to the winner's Hands) this long, on
## this arc (F01, F02: the old cloth.json flight_time, flight_arc).
@export_range(0.05, 2.0, 0.01, "suffix:s") var fly_back_time := 0.45 # placeholder: the old cloth.json flight_time
@export_range(0.0, 1.0, 0.01, "suffix:m") var fly_back_arc := 0.22 # placeholder: the old cloth.json flight_arc
