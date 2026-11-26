## A zoo switch at the Economy station: "+100 Coins" pays the player who presses it, "+5 Drawers" the
## team. It holds no state: its use asks `switch` and the Host answers with the Bank's own patches, noted
## as a payout so the HUD's flight shows it (the "+N" at the screen's centre: no drawer).
class_name MoneySwitch
extends Part

## What a switch pays.
enum Pays { COINS, DRAWERS }

const SWITCH := &"switch"
## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"

## The Bank it pays into.
@export var bank: Bank
@export var pays := Pays.COINS
@export_range(1, 100000, 1) var amount := 100
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	var currency := bank.coins_currency if pays == Pays.COINS else bank.drawers_currency
	return "+%d %s" % [amount, currency.name if currency != null else ""]


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or bank == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	var ev: Dictionary
	if pays == Pays.COINS:
		ev = bank.grant(bank.paid_patch(cmd.by, amount))
		Bank.note(ev, cmd.by, amount, 0, null, false)
	else:
		ev = bank.grant(bank.drawers_patch(amount))
		Bank.note(ev, cmd.by, 0, amount, null, false)
	return ev


func _show(_now: bool) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null and bank != null:
		label.text = prompt_title()
