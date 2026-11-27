## Which room Doors start shut at a New Game (house/08, Q518, Q2528): a share of them, picked from a seed,
## never the ones named in `keep_open`. One shared .tres (door_shut_rules.tres); a level that needs other
## numbers makes its own copy unique in the inspector.
class_name DoorShutRules
extends Resource

## The share of the house's Doors that start shut, rounded to a whole number of Doors (the old game: about a
## third, 3 of its 8).
@export_range(0.0, 1.0, 0.001) var share := 0.333 # placeholder: ported (doors.json shut_share, Q518)
## Doors that always start open, by name: the way from the laundry room to the garage, so the Old Tree's calls
## carry (the old TREE_PATH). Names are the Door nodes' under the level's `Doors`.
@export var keep_open: Array[String] = ["LaundryLobby", "LobbyGarage"] # placeholder: waits for the Old Tree (M4)
## The seed the Doors are picked from (the level's own, as a generator's).
@export var seed := 1 # placeholder: until the designer picks a seed for the house
## A new seed at every start (a New Game), as the Sock generator's switch of the same name: the choice is then
## made from the clock, and a Guest's snapshot replaces it with the Host's.
@export var new_seed_each_start := false
