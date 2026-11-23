## Every player's Coins as one Part, keyed by player id (the Roster's, Q2458; the peer number only
## while no Roster names them): what each has been paid, so a Guest's Coins wait for them in a saved
## World and come back on their next join. Coins are
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

var _roster: Roster
## The last player id seen on each peer: the key still holds once the Roster is cleared.
var _ids: Dictionary[int, String] = {}


func _enter_tree() -> void:
	add_to_group(GROUP)


## Player `by`'s (a peer number) Coins.
func of_player(by: int) -> int:
	return int(coins.get(key_of(by), coins.get(by, 0)))


## The change that pays player `by` `amount` more Coins (part of another Part's answer).
func paid_patch(by: int, amount: int) -> Dictionary:
	var c := coins.duplicate()
	var total := of_player(by) + amount
	c.erase(by)
	c[key_of(by)] = total
	return {"coins": c}


## The key player `by` (a peer number) is kept under: their player id once the Roster names them,
## else the peer number.
func key_of(by: int) -> Variant:
	if (_roster == null or not is_instance_valid(_roster)) and parts != null:
		_roster = parts.find(func(part: Part) -> bool: return part is Roster) as Roster
	var pid := _roster.id_of(by) if _roster != null else ""
	if pid != "":
		_ids[by] = pid
		return pid
	return _ids.get(by, by)


## Nobody asks the Coins anything: they change only inside another Part's answer.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
