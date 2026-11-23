## The Sock generator's Part (core/52): the seed that made a generator's Socks and which Mess records
## they are. When the level starts the Mess asks make() before it binds (as it reads the SockSpots), on
## every machine; a Guest's snapshot then replaces the Mess and this state whole, so everyone sees the
## Host's Socks (Q839, Q2524). After that only the Host's answer to `regenerate` (a zoo button: a new
## seed, the old Socks out, the new ones in, lying, Q2523) changes them, in one answer.
class_name GeneratedSocks
extends Part

## The group every GeneratedSocks is in, so the Mess finds them before anything binds.
const GROUP := &"generated_socks"

## The Mess the Socks are records of (a zoo station's link is moved to the zoo's by ZooStations).
@export var mess: Mess
## The generator whose areas they come from (its parent, by default).
@export var generator: SockGenerator
## How near a player must stand to the generator to ask a regeneration.
@export_range(0.5, 100.0, 0.5, "suffix:m") var reach := 12.0 # placeholder: the zoo station's size

@export_group("State")
## The seed the Socks were laid from.
@export var seed := 0
## The first of the generator's records in the Mess, and how many there are (-1 and 0 before the start).
@export var first := -1
@export var socks := 0
@export_group("")


func _enter_tree() -> void:
	add_to_group(GROUP)
	if generator == null:
		generator = get_parent() as SockGenerator


## Before the level binds (the Mess's _ready): the seed (the level's, or a new one each start) and the
## starting Socks' records, avoiding the lying boxes `before`. Notes where they will be.
func make(before: Array[Array]) -> Dictionary:
	if generator == null or mess == null:
		return {"designs": PackedInt32Array(), "poses": PackedFloat32Array()}
	seed = randi() if generator.new_seed_each_start else generator.seed
	var made := generator.records(seed, mess.catalogue, before)
	first = mess.count()
	socks = (made["designs"] as PackedInt32Array).size()
	return made


## A Guest may ask a regeneration at most twice a second; it takes no args.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {&"regenerate": {"args": {}, "rate": 2}}


## `regenerate`: the next seed's Socks replace these, lying, in one answer (the Mess's records and this
## state). Refused far from the generator.
func decide(cmd: Command) -> Dictionary:
	if cmd.kind != &"regenerate" or mess == null or generator == null:
		return refuse("wrong")
	if not parts.near(cmd.by, generator, reach):
		return refuse("far")
	var next := seed + 1
	var old := PackedInt32Array(range(first, first + socks)) if first >= 0 else PackedInt32Array()
	var made := generator.records(next, mess.catalogue, mess.lying_boxes(first, first + socks))
	var p := {}
	if not old.is_empty():
		p = mess.taken_out_patch(old)
	var start := int(p.get(Mess.ROW_COUNT, mess.count())) if not p.is_empty() else mess.count()
	var add: PackedInt32Array = made["designs"]
	if not add.is_empty():
		p = mess.added_lying_patch(add, made["poses"], p)
	var ev := grant({"seed": next, "first": start if not add.is_empty() else -1, "socks": add.size()})
	if not p.is_empty():
		(ev["changes"] as Dictionary)[mess.id] = p
	return ev
