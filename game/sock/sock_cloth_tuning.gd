## How a Sock's cloth bends (core/09, D01-D07): one .tres beside it (sock_cloth_tuning.tres), edited in
## the inspector. The bend is Godot's SpringBoneSimulator3D on the Looks' skeleton (Q2286, Q2287);
## its knobs differ in kind from the old game's springs (data/tuning/cloth.json), so `stiffness`,
## `gravity` and `radius` are tuned by eye, and the rest are the old game's numbers.
class_name SockClothTuning
extends Resource

@export_group("Bend")
## How hard each bone pulls back to its rest direction, per second (the node's own stiffness).
## Raised from core/09's 2 so it flaps less and a steady walk sways little (core/16 P06, Q2366).
@export_range(0.0, 20.0, 0.05) var stiffness := 5.0 # placeholder: tuned by eye to flap less (the designer's go on the core/16 cloth strip)
## How fast the chain droops, in m/s at a Sock's medium Size (the node's gravity is a speed, not an
## acceleration); a held Sock, drawn smaller, droops by the same share of its length.
@export_range(0.0, 20.0, 0.05, "suffix:m/s") var gravity := 3.0 # placeholder: tuned by eye to the old droop and lag (the designer's go on the cloth strip)
## How much of each tick's swing is thrown away: 1 never swings past its balance point (D01).
@export_range(0.0, 1.0, 0.01) var drag := 1.0 # placeholder: the old game's "fully damped" (D01)
## How thick each joint is against the ground (the Sock's half thickness).
@export_range(0.0, 0.05, 0.001, "suffix:m") var radius := 0.012 # placeholder: tuned by eye (the Sock's half thickness)

@export_group("Flying")
## A dropped or thrown Sock slower than this lies flat (D04).
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var flat_speed := 0.6 # placeholder: the old cloth.json
## How long the bend takes to blend in or out (lying flat, switched on): the old settle time.
@export_range(0.01, 2.0, 0.01, "suffix:s") var blend_time := 0.3 # placeholder: the old cloth.json settle_time
## How many flying Socks bend at once, the nearest to the camera (D07).
@export_range(0, 32, 1) var flying_cap := 4 # placeholder: the old cloth.json
## Within this height over the ground (at a Sock's medium Size) a flying Sock's whole bend
## straightens, to none at the surface, so no part dips under it (core/16 P07; the old
## `_ground_room()` halved it until no probe point was under the floor).
@export_range(0.0, 1.0, 0.01, "suffix:m") var ground_room := 0.15 # placeholder: about half a Sock's length, by eye (the designer's go on the cloth strip)
## How far under a flying Sock the ground it may land on is looked for.
@export_range(0.1, 10.0, 0.1, "suffix:m") var ground_probe := 3.0 # placeholder: not felt in play
