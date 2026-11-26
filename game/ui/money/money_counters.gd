## The Coins and Drawers counters at the HUD's top left (docs/architecture/economy.md "The HUD counters and
## the flight"): this machine's player's Coins and the team's Drawers, each minus what still flies on this
## machine (looks only: the level's Bank holds the decided numbers). A payout to this machine's player
## flies by its `flight`: a shelve's "+N" over the drawer that took it (Coins), 80 px higher in the House
## blue (Drawers, with the pad's "done" buzz); a bonus counts up with no "+N" (Q2668). A landing pulses
## the counter's icon and plays `coins` (Coins) or `drawer_clack` (Drawers). A teammate's payout only
## moves the Drawers counter. A load or a join shows the totals at once, nothing flying.
class_name MoneyCounters
extends HBoxContainer

## Links the wiring check lets stay empty: the Upgrade menu's header has no flight of its own.
const WIRING_OPTIONAL := ["flight"]

## Where payouts fly (the HUD's); none: the counters show the Bank's numbers as they are.
@export var flight: CoinFlight
## Says the debug cheat's message to this machine's player ("Debug: +1000 Coins": the HUD's does).
@export var says_cheat := false

## The Player whose numbers it shows when it is not on that Player's HUD (the Upgrade menu's header).
var for_player: Player = null
## A flight whose Coins still flying it holds back without paying into it (the Upgrade menu's header
## shows what the HUD's counters show).
var holds_back: CoinFlight = null

@onready var coins: MoneyCounter = $Coins
@onready var drawers: MoneyCounter = $Drawers

var _bank: Bank = null


func _ready() -> void:
	if flight != null:
		flight.targets[coins.currency] = coins.icon
		flight.targets[drawers.currency] = drawers.icon
		flight.landed.connect(_on_landed)


func _process(_delta: float) -> void:
	var b := bank()
	visible = b != null
	if b == null:
		return
	var shown := flight if flight != null else holds_back
	coins.show_amount(b.of_player(_me()) - (shown.pending(coins.currency) if shown != null else 0))
	drawers.show_amount(b.drawers - (shown.pending(drawers.currency) if shown != null else 0))


## The Bank it shows: the level's of this machine's player (its Hands' Parts), else the first one.
func bank() -> Bank:
	if _bank != null and is_instance_valid(_bank) and _bank.is_inside_tree():
		return _bank
	_bank = null
	var player := _player()
	var hands := player.hands() if player != null else null
	var found: Bank = null
	for node in get_tree().get_nodes_in_group(Bank.GROUP):
		var b := node as Bank
		if found == null or (hands != null and b.parts == hands.parts and b.parts != null):
			found = b
	if found == null:
		return null
	_bank = found
	_bank.paid.connect(_on_paid)
	_bank.drawers_paid.connect(_on_drawers_paid)
	_bank.cheated.connect(_on_cheated)
	return _bank


func _on_paid(player: int, amount: int, at_drawer: Node3D, bonus: bool) -> void:
	if player != _me() or flight == null:
		return
	if bonus:
		flight.pay_bonus(amount, coins.currency)
	else:
		flight.pay(_point_of(at_drawer, 0.0), amount, coins.currency)


func _on_drawers_paid(player: int, amount: int, at_drawer: Node3D) -> void:
	if player != _me() or flight == null:
		return
	PadRumble.play(PadRumble.DONE)
	flight.pay(_point_of(at_drawer, flight.tuning.drawer_rise), amount, drawers.currency)


func _on_cheated(player: int, amount: int) -> void:
	var p := _player()
	if says_cheat and player == _me() and p != null and _bank != null:
		p.notice(Bank.CHEAT_SAYS % [amount, coins.currency.name], _bank.tuning.cheat_message_time)


func _on_landed(currency: Currency, _count: int) -> void:
	if currency == coins.currency:
		coins.pulse(flight.tuning.pulse, flight.tuning.pulse_time)
		Sounds.play(&"coins")
	else:
		Sounds.play(&"drawer_clack")


## Where on screen a payout at `drawer` pops: over its front, `over_drawer` up, `rise` pixels higher;
## the screen's centre when it is behind the camera or there is no drawer.
func _point_of(drawer: Node3D, rise: float) -> Vector2:
	var at := get_viewport_rect().size * 0.5
	var cam := get_viewport().get_camera_3d()
	if drawer != null and is_instance_valid(drawer) and cam != null:
		var front := drawer.get_node_or_null(^"Looks/Slide/Front") as Node3D
		var over := (front if front != null else drawer).global_position + Vector3.UP * flight.tuning.over_drawer
		if not cam.is_position_behind(over):
			at = cam.unproject_position(over)
	return at + Vector2.UP * rise


## This machine's player id.
func _me() -> int:
	return multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST


## The Player whose HUD this is, or null.
func _player() -> Player:
	if for_player != null and is_instance_valid(for_player):
		return for_player
	var n := get_parent()
	while n != null and not (n is Player):
		n = n.get_parent()
	return n as Player
