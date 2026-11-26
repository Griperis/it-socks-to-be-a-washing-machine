## The economy's numbers (docs/architecture/economy.md "Numbers"): the two Stage bonuses (Q2667) and the
## debug cheat. One .tres beside it (economy_tuning.tres), edited in the inspector.
class_name EconomyTuning
extends Resource

## Coins every player in the game gets when a floor opens (and at the last Fix).
@export_range(0, 10000, 1) var floor_bonus := 100 # placeholder: the old T:payout floor_complete
## Coins whoever fills a Cabinet's current Rows gets, once per Rows count.
@export_range(0, 10000, 1) var cabinet_bonus := 50 # placeholder: the old T:payout cabinet_batch
## Coins the Host's debug F9 gives (debug builds only).
@export_range(0, 100000, 1) var cheat_coins := 1000 # placeholder: the old T:debug cheat_coins
## How long the cheat's message shows.
@export_range(0.0, 10.0, 0.1, "suffix:s") var cheat_message_time := 2.0 # placeholder: the port's message time
