## The Upgrades one player has that change what the screen shows (core/15, Q2360): Sock Smarts (the
## held item's full readout) and Sock Sense (the aimed loose Sock's readout, needs Smarts). Read by
## this machine's HUD only. Bought at the Old Tree (core/129): in a level with an Upgrades Part the
## player's bought levels turn them on (`levels`, set by the player as its Hands bind); the zoo's
## switches still toggle the flags (A16), and either turns a readout on.
class_name PlayerUpgrades
extends Resource

## Sock Smarts: the held item shows its Collection, Design name, Sock or Pair, and n/capacity.
@export var sock_smarts := false
## Sock Sense: the aimed loose Sock shows the readout the Hands would show once it is picked.
@export var sock_sense := false
## The stats the bought Upgrades name.
@export var smarts_stat: UpgradeStat = preload("res://game/economy/stats/sock_smarts.tres")
@export var sense_stat: UpgradeStat = preload("res://game/economy/stats/sock_sense.tres")

## The level's Upgrades the bought levels are read from (null: the flags alone), and whose.
var levels: Upgrades = null
var player := Parts.HOST


## Whether Sock Smarts is on.
func smarts() -> bool:
	return sock_smarts or _bought(smarts_stat)


## Whether Sock Sense is on: it needs Smarts (the old upgrades.gd).
func sense() -> bool:
	return (sock_sense or _bought(sense_stat)) and smarts()


func _bought(stat: UpgradeStat) -> bool:
	return levels != null and is_instance_valid(levels) and levels.value(stat, player) >= 1.0
