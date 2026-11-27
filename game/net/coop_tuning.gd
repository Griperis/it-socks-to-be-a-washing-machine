## The numbers of joining and the roster (coop/03): one .tres beside it (coop_tuning.tres), edited in
## the inspector. Read by the Session, the Roster and the LevelNet.
class_name CoopTuning
extends Resource

@export_group("Roster")
## The Player colours in their order: the Host takes the first, each joiner the next free one
## (Q275, Q2441): coral, teal, mustard, lilac, mint, sky blue, rose, charcoal.
@export var colours: Array[Color] = [Color("f08a7a"), Color("4fb3a9"), Color("e3b448"), Color("b49ad8"),
		Color("8fd6a8"), Color("86bfe8"), Color("e89ab4"), Color("55595f")]
## Their names, in the same order.
@export var colour_names: Array[String] = ["coral", "teal", "mustard", "lilac", "mint", "sky blue", "rose", "charcoal"]
## The most players at once, the Host included (Q2443); the next is refused "The game is full".
@export_range(1, 8, 1) var max_players := 4
## A new joiner stands this far to the Host's side, facing the same way (Q2448); a second joiner the
## other side, a third twice as far, and so on (the old washer spawn's alternating steps).
@export_range(0.1, 3.0, 0.05, "suffix:m") var beside := 0.6

@export_group("Joining")
## A join with no answer gives up after this long with "Could not reach <where>" (Q2447).
@export_range(0.5, 60.0, 0.5, "suffix:s") var join_timeout := 10.0
## How long the Host waits at the gate for a Guest's word before dropping the connection. It stays
## above a Steam auth ticket's round trip, and under `join_timeout`.
@export_range(1.0, 30.0, 0.5, "suffix:s") var auth_timeout := 8.0 # placeholder: until the Steam lobby (M4) measures a ticket's round trip

@export_group("Toasts")
## "Player joined", "Player left" and "Joined Player's zoo" show this long under the crosshair; a
## later one replaces an earlier one (Q2442, Q492).
@export_range(0.5, 10.0, 0.1, "suffix:s") var toast_time := 2.0


## Player colour `index` (wrapping round the colours).
func colour(index: int) -> Color:
	return colours[posmod(index, colours.size())] if not colours.is_empty() else Color.WHITE
