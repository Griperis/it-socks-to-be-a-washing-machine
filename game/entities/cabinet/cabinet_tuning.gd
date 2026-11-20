## How a Cabinet takes Pairs and pays for them: one .tres beside it (cabinet_tuning.tres), edited in
## the inspector. Every number is today's value from the old game (data/tuning/drawers.json,
## payout.json), not a decision. A Door's swing (0.6 s) and a drawer's slide (0.3 s) are the length
## of the "open" animation in their Looks (Q2213), not numbers here.
class_name CabinetTuning
extends Resource

## How many Pairs one drawer holds before it is full (Q2256: a tuning field, not the model's 25
## slot points; a drawer holding more than its slots draws the first ones).
@export_range(1, 100, 1) var drawer_capacity := 25 # placeholder: the designer's number (today's value from the old game)
## Coins a shelved Pair pays, times its rarity's factor (C05).
@export_range(0, 1000, 1) var coins_per_pair := 10 # placeholder: the designer's number (today's value from the old game)
## The rarity factors, by SockDesign.Rarity: common, uncommon, rare.
@export var rarity_factors: Array[int] = [1, 2, 5] # placeholder: the designer's number (today's value from the old game)
## How far a player's feet may be from the Cabinet to shelve by a click.
@export_range(0.5, 6.0, 0.1, "suffix:m") var reach := 2.5 # placeholder: the designer's number (today's value from the old game)
## How much farther than `reach` the Host lets a player be: the eyes stand above the feet, and a
## Guest's place reaches the Host a little late.
@export_range(0.0, 2.0, 0.1, "suffix:m") var reach_slack := 1.0 # placeholder: the Host's allowance, not felt in play


## The Coins one Pair of a Design of rarity `rarity` pays.
func pay_for(rarity: int) -> int:
	var factor := rarity_factors[rarity] if rarity >= 0 and rarity < rarity_factors.size() else 1
	return coins_per_pair * factor
