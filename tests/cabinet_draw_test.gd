## The New Game's draw (core/135): CabinetDraw fills every spot from its pool with unlocked, not held-back
## Collections, none twice, the shared pools solved by backtracking, the same seed drawing the same; the
## house's eight Cabinets carry the old room pools and its first start draws them. The real path of the
## station's New run is in stages_test.gd.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const START: Array[StringName] = [&"simple", &"sport", &"patterns", &"animals", &"superhero", &"winter", &"nature", &"food"]

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "rules", "method": "case_rules", "world": false,
				"title": "a draw gives one unlocked Collection per spot, never one twice, from its own pool, and the same seed draws the same"},
		{"name": "backtracking", "method": "case_backtracking", "world": false,
				"title": "shared pools are solved by backtracking (a greedy pick that would starve a tight spot is undone); the Lost Socks and locked Collections are never drawn"},
		{"name": "problems", "method": "case_problems", "world": false,
				"title": "problems() names why a draw cannot fill the spots (a pool with nothing unlocked, too few Collections), and a failed draw gives nothing"},
		{"name": "house", "method": "case_house", "world": false,
				"title": "the house's first start draws all eight Cabinets from the old room pools with the start set, never one twice, the same seed the same draw"},
	]


func _after_case() -> void:
	if _level != null:
		_level.free()
		_level = null


func _is(got: Array[StringName], want: Array) -> bool:
	return got.size() == want.size() and Array(got) == want


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func case_rules() -> void:
	var pools := [[&"simple"], [&"sport", &"animals", &"nature"], [&"animals", &"nature", &"superhero", &"space"]]
	for n in 20:
		var got := CabinetDraw.draw(pools, START, _rng(n))
		_check(got.size() == 3, "three spots drawn (seed %d)" % n)
		if got.size() != 3:
			continue
		_check(got[0] == &"simple" and pools[1].has(got[1]) and pools[2].has(got[2]), "each from its pool (%s)" % [got])
		_check(got[1] != got[2] and START.has(got[2]), "never one twice, only unlocked (%s)" % [got])
	_check(CabinetDraw.draw(pools, START, _rng(5)) == CabinetDraw.draw(pools, START, _rng(5)), "the same seed draws the same")
	var seen := {}
	for n in 40:
		seen[CabinetDraw.draw(pools, START, _rng(n))[1]] = true
	_check(seen.size() > 1, "different seeds draw differently (%s)" % [seen.keys()])
	_check(CabinetDraw.draw(pools, START, _rng(1), [&"sport"]).size() == 3 and CabinetDraw.draw(pools, START, _rng(1), [&"sport"])[1] != &"sport", "a Collection another spot keeps is not drawn")
	await _frames(1)


func case_backtracking() -> void:
	# Spot 0 may take sport or animals, spot 1 only sport: whichever spot 0 tries first, the fill must exist.
	var pools := [[&"animals", &"sport"], [&"sport"]]
	for n in 20:
		var got := CabinetDraw.draw(pools, START, _rng(n))
		_check(_is(got, [&"animals", &"sport"]), "the tight spot keeps its only Collection (%s)" % [got])
	var unlocked: Array[StringName] = START.duplicate()
	unlocked.append(&"space")
	var wide := [[&"space", &"sport", &"fruit"], [&"sport", &"animals"], [&"animals"]]
	for n in 20:
		var got := CabinetDraw.draw(wide, unlocked, _rng(n))
		_check(_is(got, [&"space", &"sport", &"animals"]), "a shared pool is solved (%s)" % [got])
	var with_lost := CabinetDraw.draw([[&"lost", &"simple"]], [&"lost", &"simple"], _rng(3))
	_check(_is(with_lost, [&"simple"]), "the Lost Socks are never drawn (%s)" % [with_lost])
	await _frames(1)


func case_problems() -> void:
	_check(CabinetDraw.problems([[&"simple"], [&"sport", &"space"]], START).is_empty(), "a fillable draw has no problems")
	var none := CabinetDraw.problems([[&"simple"], [&"space"]], START)
	_check(none.size() == 1 and none[0].contains("spot 1") and none[0].contains("space"), "a pool with nothing unlocked is named (%s)" % [none])
	var twice := CabinetDraw.problems([[&"simple"], [&"simple"]], START)
	_check(twice.size() == 1 and twice[0].contains("without a repeat"), "too few Collections for the spots is named (%s)" % [twice])
	_check(CabinetDraw.draw([[&"simple"], [&"simple"]], START, _rng(1)).is_empty(), "a failed draw gives nothing")
	_check(CabinetDraw.draw([], START, _rng(1)).is_empty(), "no spots, no draw")
	await _frames(1)


func case_house() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var stages := _level.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return stages.stage == 0, "the house's run to start", 900, 120.0)
	var cabinets := stages.cabinets()
	_check(cabinets.size() == 8, "eight Cabinets (%d)" % cabinets.size())
	var seen := {}
	for cab in cabinets:
		_check(not cab.pool.is_empty() and cab.pool.has(cab.collection), "%s drew %s from its pool %s" % [cab.get_parent().name, cab.collection, cab.pool])
		_check(START.has(cab.collection), "%s is unlocked" % cab.collection)
		_check(not seen.has(cab.collection), "%s drawn once" % cab.collection)
		seen[cab.collection] = true
	var again := stages.draw_collections()
	var same := true
	for cab in cabinets:
		same = same and again.get(cab) == cab.collection
	_check(same, "the World's seed draws the same again")
