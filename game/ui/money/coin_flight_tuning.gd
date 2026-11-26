## The Coins' and Drawers' flight to the HUD counters (docs/architecture/economy.md "The HUD counters
## and the flight"): the old data/tuning/coins.json. Seconds and screen pixels. One .tres beside it
## (coin_flight_tuning.tres). The Host's Bank reads the times too: Coins are spendable once landed (Q2672).
class_name CoinFlightTuning
extends Resource

@export_group("Times")
## The "+N" holds this long before it bursts.
@export_range(0.0, 5.0, 0.01, "suffix:s") var hold := 0.5 # placeholder: the old coins.json hold
## The "+N" grows in.
@export_range(0.0, 2.0, 0.01, "suffix:s") var pop_in := 0.12 # placeholder: the old coins.json pop_in
## The icons spread out of the "+N".
@export_range(0.0, 2.0, 0.01, "suffix:s") var burst := 0.2 # placeholder: the old coins.json burst_time
## One icon's flight to the counter.
@export_range(0.0, 5.0, 0.01, "suffix:s") var flight := 0.45 # placeholder: the old coins.json flight
## The whole payout, whatever its size: the icons' launches are spread to end in it.
@export_range(0.0, 10.0, 0.01, "suffix:s") var total := 1.5 # placeholder: the old coins.json total
## A bonus's Coins (no "+N", Q2668) start landing this much later than a "+N"'s.
@export_range(0.0, 5.0, 0.01, "suffix:s") var bonus_delay := 0.35 # placeholder: the old coins.json bonus_delay

@export_group("Sizes")
## How far the icons spread out of the "+N".
@export_range(0.0, 400.0, 1.0, "suffix:px") var radius := 70.0 # placeholder: the old coins.json burst_radius
## A flying icon's side.
@export_range(4.0, 200.0, 1.0, "suffix:px") var icon := 34.0 # placeholder: the old coins.json coin_px
## A flying icon's size as it reaches the counter.
@export_range(0.1, 2.0, 0.01) var land_scale := 0.75 # placeholder: the old CoinFlight _fly_step
## How far above the Coins' "+N" the Drawers' one pops.
@export_range(0.0, 400.0, 1.0, "suffix:px") var drawer_rise := 80.0 # placeholder: the old coins.json drawer_rise
## A "+N" is kept this far inside the screen.
@export_range(0.0, 200.0, 1.0, "suffix:px") var margin := 16.0 # placeholder: the old CoinFlight _on_screen
## How far above the drawer the "+N" pops, in metres.
@export_range(0.0, 2.0, 0.01, "suffix:m") var over_drawer := 0.2 # placeholder: the old rig _drawer_point

@export_group("Counter")
## The counter's icon grows to this on each landing, easing back.
@export_range(1.0, 3.0, 0.01) var pulse := 1.35 # placeholder: the old hud.gd pulse
## The pulse's way back.
@export_range(0.01, 2.0, 0.01, "suffix:s") var pulse_time := 0.17 # placeholder: the old hud.gd pulse decay (6 per second)


## When the first Coin of a payout lands, after it is paid; a bonus's `bonus_delay` later.
func first_landing(bonus: bool) -> float:
	return hold + burst + flight + (bonus_delay if bonus else 0.0)


## The time over which a payout's Coins land, one after another.
func spread() -> float:
	return maxf(0.0, total - hold - burst - flight)


## When the `k`-th of `amount` Coins lands, after the first one.
func landing_after(k: int, amount: int) -> float:
	return spread() * float(k) / float(amount - 1) if amount > 1 else 0.0
