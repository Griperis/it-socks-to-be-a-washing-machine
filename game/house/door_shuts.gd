## Shuts the house's start-shut Doors (house/08, Q518, Q2528, Q2570). Put it as the last child of the
## level's `Doors` node, after the Door instances, which stand open: when the level enters, before the
## Mess lays and before anything binds, it picks `rules.share` of them from the seed (never `rules.keep_open`)
## and sets those shut, so they stand shut with no swing and no sound. Every machine does the same; a Guest's
## snapshot then replaces each Door's state whole, so everyone has the Host's choice.
class_name DoorShuts
extends Node

## The numbers: how many, which stay open, the seed.
@export var rules: DoorShutRules
## The names picked by the last start, for a test and the log.
var shut: PackedStringArray = []


func _ready() -> void:
	if rules == null:
		return
	var doors := {}
	for child in get_parent().get_children():
		var openable := child.get_node_or_null("Openable") as Openable
		if openable != null:
			doors[String(child.name)] = openable
	var seed_value := randi() if rules.new_seed_each_start else rules.seed
	shut = pick(doors.keys(), seed_value, rules)
	for door_name in shut:
		(doors[door_name] as Openable).open = false


## The Doors a start shuts: round(count x share) of the names, from a shuffle of those not kept open by
## `seed_value` (the old Doors.pick_shut: a Fisher-Yates over the list, the first of it).
static func pick(names: Array, seed_value: int, shut_rules: DoorShutRules) -> PackedStringArray:
	var count := roundi(names.size() * clampf(shut_rules.share, 0.0, 1.0))
	var all: Array[String] = []
	for door_name: String in names:
		if not shut_rules.keep_open.has(door_name):
			all.append(door_name)
	all.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(all.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := all[i]
		all[i] = all[j]
		all[j] = t
	return PackedStringArray(all.slice(0, mini(count, all.size())))
