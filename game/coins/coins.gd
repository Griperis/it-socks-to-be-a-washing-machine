## Every player's Coins as one Part, keyed by player id (1 alone): what each has been paid. Coins are
## a player's own (C05, I.12); only another Part's answer pays them (a Cabinet's shelve), through
## paid_patch(). In M4 this becomes the Players Part with the Personal upgrades; the bank on screen
## and the flying +N are M4's HUD.
class_name Coins
extends Part

## The group the level's Coins are in: a Cabinet finds them there when none is set.
const GROUP := &"coins"

@export_group("State")
## Each player's Coins: {player id: int}.
@export var coins := {}
@export_group("")


func _enter_tree() -> void:
	add_to_group(GROUP)


## Player `by`'s Coins.
func of_player(by: int) -> int:
	return int(coins.get(by, 0))


## The change that pays player `by` `amount` more Coins (part of another Part's answer).
func paid_patch(by: int, amount: int) -> Dictionary:
	var c := coins.duplicate()
	c[by] = of_player(by) + amount
	return {"coins": c}


## Nobody asks the Coins anything: they change only inside another Part's answer.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
