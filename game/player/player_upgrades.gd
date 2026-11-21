## The Upgrades one player has that change what the screen shows (core/15, Q2360): Sock Smarts (the
## held item's full readout) and Sock Sense (the aimed loose Sock's readout, needs Smarts). Read by
## this machine's HUD only; M4 wires them to buying, the zoo's switches toggle them (A16).
class_name PlayerUpgrades
extends Resource

## Sock Smarts: the held item shows its Collection, Design name, Sock or Pair, and n/capacity.
@export var sock_smarts := false
## Sock Sense: the aimed loose Sock shows the readout the Hands would show once it is picked.
@export var sock_sense := false


## Whether Sock Smarts is on.
func smarts() -> bool:
	return sock_smarts


## Whether Sock Sense is on: it needs Smarts (the old upgrades.gd).
func sense() -> bool:
	return sock_sense and sock_smarts
