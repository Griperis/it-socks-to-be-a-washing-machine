## The clicks a present's opening and its reveal take for themselves (core/138, docs/architecture/gifts.md
## "Opening"): the carrier's left click that opens it, and every click or pad face button while the reveal shows,
## goes no further (nothing behind picks up, nothing aimed is used). The player reads its buttons by polling in
## its own physics tick, so a taker runs its tick first (BEFORE_PLAYER) and holds the player's input for that one
## tick (swallow()); the walk misses one tick, nothing else.
class_name GiftClicks
extends RefCounted

## A physics priority that runs before the player's (0).
const BEFORE_PLAYER := -10


## The player whose input is `by`'s on this machine in the level of `hands`, or null.
static func player_of(hands: Hands, by: int) -> Player:
	if hands == null or not hands.is_inside_tree():
		return null
	for node in hands.get_tree().get_nodes_in_group(Hands.PLAYERS):
		var p := node as Player
		if p != null and p.player_id() == by and p.hands() == hands:
			return p
	return null


## Whether `player`'s buttons act now (no menu, cutscene or drum holds them, not knocked down).
static func acting(player: Player) -> bool:
	return player != null and not player.input_blocked() and not player.knocked


## Holds `player`'s input for this physics tick: the click read this tick does nothing for them.
static func swallow(player: Player) -> void:
	if player == null or player.input_blocked() or not player.is_inside_tree():
		return
	player.set_input_blocked(true)
	player.get_tree().physics_frame.connect(_let_go.bind(player), CONNECT_ONE_SHOT)


static func _let_go(player: Player) -> void:
	if is_instance_valid(player):
		player.set_input_blocked(false)
