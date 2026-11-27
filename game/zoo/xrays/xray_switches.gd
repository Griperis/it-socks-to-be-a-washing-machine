## The X-rays station's row of Upgrade switches (core/182, Q2337: built from the data at load): for each
## X-ray ability (XRays.listed()), one XRayUpgradeSwitch per Upgrade whose stat is one of the ability's
## (owned, All-Hands, duration, cooldown), in the order of their cells, a row per ability. A new ability
## file or Upgrade shows its switches here with no other change. Made before the level's Parts bind, the
## same on every machine (the files sorted), so each switch is a Part like any placed one.
class_name XRaySwitches
extends Node3D

const SWITCH := preload("res://game/zoo/xrays/xray_upgrade_switch.tscn")

## The level's Upgrades the switches change.
@export var upgrades: Upgrades
## The distance between two switches of a row, and between two rows, in metres.
@export var gap := 1.0
@export var row_gap := 1.4


func _ready() -> void:
	var all := Upgrades.listed()
	var row := 0
	for ability in XRays.listed():
		var i := 0
		for u in of_ability(ability, all):
			var s := SWITCH.instantiate() as Node3D
			s.name = String(u.id()).to_pascal_case()
			s.position = Vector3(i * gap, 0.0, row * row_gap)
			var part := s.get_node("XRayUpgradeSwitch") as XRayUpgradeSwitch
			part.upgrade = u
			part.upgrades = upgrades
			add_child(s)
			i += 1
		row += 1


## The Upgrades among `all` whose stat is one of `ability`'s, in the order of their cells.
static func of_ability(ability: XRayAbility, all: Array[Upgrade]) -> Array[Upgrade]:
	var stats: Array[UpgradeStat] = [ability.owned, ability.all_hands, ability.duration, ability.cooldown]
	var out: Array[Upgrade] = []
	for u in all:
		if u.stat != null and stats.has(u.stat):
			out.append(u)
	out.sort_custom(func(a: Upgrade, b: Upgrade) -> bool: return a.cell.y < b.cell.y if a.cell.y != b.cell.y else a.cell.x < b.cell.x)
	return out
