## The Laundry day (core/93, run-ends.md "The Laundry bins" and "The Laundry day"): the bins placed in the house and
## drawn from the World's seed, the load and its refusals in order, the pile and the tally, the ending's wait counted
## by the Host and kept in a save. Lines are the behaviour list's (04 "The Laundry bins", "The Laundry day").
## The real path: in the house with the last Fix set, the player carries a bin to the washing machine and clicks.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const STATION := "Stations/Laundry"
const KEEP := ["Laundry"]
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact"]
## The seven old spots, by room name (old layout `laundry_bins`).
const SPOTS := ["Laundry", "Bathroom", "Bedroom", "Kids", "Kitchen", "Living", "Loft"]

var _holder: Node = null
var _house: Node3D = null
var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the house with the last Fix done the player carries a bin to the washing machine and clicks: the bar reads Wash clothes 1/3, the bin is empty in the Hands, a second click reads That bin is empty; before the last Fix it reads Fix the washing machine first"},
		{"name": "draw", "method": "case_draw", "world": false,
				"title": "the house has seven spots under LaundryBins, the one by the washer always; a New Game draws bins_per_world of them from the seed, the same every time, clamped to 1..spots"},
		{"name": "refusals", "method": "case_refusals", "world": false,
				"title": "the load refuses in order: no bin carried, the First wash playing (busy), the last Fix not done, an empty bin, the ending's wait running (The washing machine is busy); while the First wash is pending the bin starts it (core/94)"},
		{"name": "pile_and_wait", "method": "case_pile_and_wait", "world": false,
				"title": "the pile behind the porthole is 0.4 after the first bin and grows evenly to 1; the last bin starts the wait, which the Host counts down and the snapshot carries, and at 0 the Final wash is asked once"},
		{"name": "station", "method": "case_station", "world": false,
				"title": "the Laundry station: the Last Fix done pillar sets the switch, the Final wash pillar loads all but one bin and then the last; the label reads loaded/total"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _holder != null:
		_holder.free()
		_holder = null
	_house = null
	_zoo = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _house_up()
	var runtime := LevelRuntime.of(_house)
	var player := runtime.player
	var day := _day()
	await _until(func() -> bool: return day.drawn, "the draw", 300)
	_check(day.total() == 3, "three bins are in use (%d)" % day.total())
	var hands := runtime.hands
	# Carry the bin by the washer.
	var bin := _house.get_node("LaundryBins/Laundry/LaundryBin") as LaundryBin
	var thing := bin.get_parent() as Node3D
	_check(bin.used and bin.full and bin.always, "the bin by the washer is used, full and always")
	await _stand_facing(player, thing.global_position + Vector3(1.0, 0.0, 0.0), thing.global_position + Vector3.UP * 0.26)
	_check(player.aimed_part() == bin.carriable, "the crosshair is on the bin")
	await _press(&"pick")
	await _until(func() -> bool: return hands.carries(1) == bin.carriable, "the bin to be carried", 60)
	# The washing machine, before the last Fix.
	var washer_thing := _house.get_node("Washer") as Node3D
	var washer := washer_thing.get_node("Washer") as Washer
	await _stand_facing(player, washer_thing.global_position + Vector3(1.9, 0.0, 0.0), washer_thing.global_position + Vector3.UP * 0.5)
	_check(player.aimed_part() == washer, "the crosshair is on the washing machine")
	_check(not player.hud().prompt_text().contains("Load the washing machine"), "before the last Fix it does not offer the load (%s)" % player.hud().prompt_text())
	await _press(&"pick")
	await _until(func() -> bool: return player.hud().refusal_text() == "Fix the washing machine first", "the refusal Fix the washing machine first", 60)
	_check(bin.full and day.loaded_bins == 0 and hands.carries(1) == bin.carriable, "nothing moved")
	# The last Fix is done (the run's phase).
	var stages := _house.get_node("Run/Stages") as Stages
	runtime.parts.apply({"ok": true, "changes": {stages.id: {"phase": Stages.Phase.FIXED}}})
	var bar := player.get_node("Hud/StageBar") as StageBar
	await _until(func() -> bool: return bar.text() == "Wash clothes 0/3", "the bar to fold into Wash clothes 0/3 (%s)" % bar.text(), 200)
	await _until(func() -> bool: return not bar.folding(), "the fold to end", 200)
	_check(player.hud().prompt_text().contains("Load the washing machine"), "it reads Load the washing machine (%s)" % player.hud().prompt_text())
	await _press(&"pick")
	await _until(func() -> bool: return day.loaded_bins == 1, "the bin to load the machine", 60)
	_check(not bin.full, "the bin is empty")
	_check(hands.carries(1) == bin.carriable, "it is still in the Hands")
	await _until(func() -> bool: return bar.text() == "Wash clothes 1/3", "the bar to read Wash clothes 1/3 (%s)" % bar.text(), 200)
	_check(bin.tipping() or bin.shown_fill() < 1.0, "the bin tips")
	_check(is_equal_approx(washer.looks.pile, day.tuning.pile_min), "the pile behind the porthole is pile_min (%s)" % washer.looks.pile)
	await _press(&"pick")
	await _until(func() -> bool: return player.hud().refusal_text() == "That bin is empty", "the refusal That bin is empty", 60)
	_check(day.loaded_bins == 1, "still one bin loaded")


# --- The draw ------------------------------------------------------------------------------------

func case_draw() -> void:
	await _house_up()
	var day := _day()
	await _until(func() -> bool: return day.drawn, "the draw", 300)
	var spots := _house.get_node("LaundryBins")
	var names: Array[String] = []
	for c in spots.get_children():
		names.append(String(c.name))
	names.sort()
	var want := SPOTS.duplicate()
	want.sort()
	_check(names == want, "the seven old spots stand under LaundryBins (%s)" % [names])
	var always: Array[String] = []
	for bin in day.bins():
		if bin.always:
			always.append(String(bin.get_parent().name))
	_check(always == ["Laundry"], "the one by the washer is always (%s)" % [always])
	_check(day.total() == 3, "bins_per_world of them are used (%d)" % day.total())
	var laundry := _house.get_node("LaundryBins/Laundry/LaundryBin") as LaundryBin
	_check(laundry.used and (laundry.get_parent() as Node3D).visible, "the one by the washer is used and drawn")
	for bin in day.bins():
		if not bin.used:
			_check(not (bin.get_parent() as Node3D).visible and bin.full, "an unused spot is hidden (%s)" % bin.get_parent().name)
	# The same draw again from the seed; a clamp to the spots and to one.
	var first := _used_names(day)
	var parts := LevelRuntime.of(_house).parts
	parts.apply({"ok": true, "changes": {day.id: {"drawn": false}}})
	var again := day.decide(Command.new(LaundryDay.DRAW, Parts.HOST, day.id, {}))
	_check(again.get("ok", false), "a draw is granted before one is made")
	var drawn_again: Array[String] = []
	for id: Variant in again["changes"]:
		var change := again["changes"][id] as Dictionary
		if change.get("used", false):
			drawn_again.append(String(parts.of(StringName(id)).get_parent().name))
	drawn_again.sort()
	_check(drawn_again == first, "the same seed draws the same bins (%s, then %s)" % [first, drawn_again])
	day.tuning = day.tuning.duplicate() as LaundryTuning
	day.tuning.bins_per_world = 99
	_check(_count_used(day.decide(Command.new(LaundryDay.DRAW, Parts.HOST, day.id, {}))) == 7, "more than the spots is clamped to every spot")
	day.tuning.bins_per_world = 0
	_check(_count_used(day.decide(Command.new(LaundryDay.DRAW, Parts.HOST, day.id, {}))) == 1, "none is clamped to one, the one by the washer")
	_check(not day.decide(Command.new(LaundryDay.DRAW, 2, day.id, {})).get("ok", false), "a Guest cannot ask for a draw")
	parts.apply({"ok": true, "changes": {day.id: {"drawn": true}}})
	_check(day.decide(Command.new(LaundryDay.DRAW, Parts.HOST, day.id, {})).get("reason", "") == "already", "a drawn World is not drawn again")


# --- The refusals --------------------------------------------------------------------------------

func case_refusals() -> void:
	await _house_up()
	var day := _day()
	await _until(func() -> bool: return day.drawn, "the draw", 300)
	var runtime := LevelRuntime.of(_house)
	var parts := runtime.parts
	var bin := _house.get_node("LaundryBins/Laundry/LaundryBin") as LaundryBin
	var load_cmd := Command.new(LaundryDay.LOAD, 1, day.id, {})
	_check(day.decide(load_cmd).get("reason", "") == LaundryDay.NOT_CARRIED, "no bin carried: refused")
	parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 1}}})
	parts.apply({"ok": true, "changes": {day.id: {"first_wash": LaundryDay.FirstWash.PENDING}}})
	_check(day.decide(load_cmd).get("ok", false) and day.decide(load_cmd).get("first_wash", false), "the First wash pending: the bin starts it")
	parts.apply({"ok": true, "changes": {day.id: {"first_wash": LaundryDay.FirstWash.PLAYING}}})
	_check(day.decide(load_cmd).get("reason", "") == LaundryDay.BUSY, "the First wash playing: busy")
	parts.apply({"ok": true, "changes": {day.id: {"first_wash": LaundryDay.FirstWash.DONE}}})
	_check(day.decide(load_cmd).get("reason", "") == LaundryDay.UNFIXED, "the last Fix not done: Fix the washing machine first")
	var stages := _house.get_node("Run/Stages") as Stages
	parts.apply({"ok": true, "changes": {stages.id: {"phase": Stages.Phase.FIXED}}})
	parts.apply({"ok": true, "changes": {bin.id: {"full": false}}})
	_check(day.decide(load_cmd).get("reason", "") == LaundryDay.EMPTY, "an empty bin: That bin is empty")
	parts.apply({"ok": true, "changes": {bin.id: {"full": true}, day.id: {"ending_left": 1.0}}})
	_check(day.decide(load_cmd).get("reason", "") == LaundryDay.BUSY, "the ending's wait running: The washing machine is busy")
	parts.apply({"ok": true, "changes": {day.id: {"ending_left": -1.0}}})
	_check(day.decide(load_cmd).get("ok", false), "all clear: granted")
	_check(LaundryDay.SAYS[LaundryDay.UNFIXED] == "Fix the washing machine first" and LaundryDay.SAYS[LaundryDay.EMPTY] == "That bin is empty"
			and LaundryDay.SAYS[LaundryDay.BUSY] == "The washing machine is busy", "the old words")
	var far := Command.new(LaundryDay.LOAD, 1, day.id, {})
	parts.where = func(_by: int) -> Vector3: return Vector3(50.0, -3.0, 50.0)
	_check(day.decide(far).get("reason", "") == "far", "far from the machine: refused")
	parts.where = Callable()


# --- The pile and the wait -----------------------------------------------------------------------

func case_pile_and_wait() -> void:
	await _house_up()
	var day := _day()
	await _until(func() -> bool: return day.drawn, "the draw", 300)
	var runtime := LevelRuntime.of(_house)
	var parts := runtime.parts
	var washer := (_house.get_node("Washer/Washer") as Washer)
	var stages := _house.get_node("Run/Stages") as Stages
	parts.apply({"ok": true, "changes": {stages.id: {"phase": Stages.Phase.FIXED}}})
	_near(day.pile_of(0, 3), 0.0, 0.0001, "no bin: no pile")
	_near(day.pile_of(1, 3), 0.4, 0.0001, "one of three: pile_min")
	_near(day.pile_of(2, 3), 0.7, 0.0001, "two of three: evenly")
	_near(day.pile_of(3, 3), 1.0, 0.0001, "the last: full")
	var moved := [0]
	day.bar_changed.connect(func() -> void: moved[0] += 1)
	var used := day.used_bins()
	var pours: Array = []
	for i in used.size():
		var bin := used[i]
		parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 1}}})
		var answer := day.decide(Command.new(LaundryDay.LOAD, 1, day.id, {}))
		_check(answer.get("ok", false), "bin %d loads" % (i + 1))
		parts.apply(answer.merged({"kind": LaundryDay.LOAD, "by": 1, "to": day.id}))
		pours.append(washer.looks.pile)
		parts.apply({"ok": true, "changes": {bin.carriable.id: {"holder": 0}}})
	_near(pours[0], 0.4, 0.0001, "the pile after the first bin")
	_near(pours[1], 0.7, 0.0001, "the pile after the second")
	_near(pours[2], 1.0, 0.0001, "the pile after the last")
	_check(moved[0] >= 3, "the tally told the bar each time (%d)" % moved[0])
	_check(day.loaded_bins == 3 and is_equal_approx(day.ending_left, day.tuning.tip_seconds), "the last bin starts the wait (%s)" % day.ending_left)
	_check(day.bar_numbers() == Vector2i(3, 3), "the bar's numbers are 3/3")
	# The Host counts it down; what a save and a late Guest receive is the live value.
	await _physics_ticks(30)
	var live := float(day.whole_state()["ending_left"])
	_check(live < day.tuning.tip_seconds - 0.3 and live > 0.0, "the saved wait is the live one (%s)" % live)
	_check(not day.final_started, "the Final wash is not asked yet")
	var fresh := day.whole_state()
	day.write(fresh, true)
	_near(day.wait_left(), live, 0.0001, "a load or a join restarts the wait from it")
	await _until(func() -> bool: return day.final_started, "the Final wash to be asked at 0", 200)
	_check(day.ending_left < 0.0 and day.wait_left() < 0.0, "the wait is over")
	_check(not day.decide(Command.new(LaundryDay.FINAL_WASH, 1, day.id, {})).get("ok", false), "a Guest cannot ask for the Final wash")
	_check(not day.decide(Command.new(LaundryDay.FINAL_WASH, Parts.HOST, day.id, {})).get("ok", false), "and it is asked once")


# --- The station ---------------------------------------------------------------------------------

func case_station() -> void:
	_holder = Node.new()
	add_child(_holder)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder.add_child(_zoo)
	var runtime := LevelRuntime.of(_zoo)
	var player := runtime.player
	var station := _zoo.get_node(STATION) as Node3D
	await _until(func() -> bool: return player.is_on_floor(), "the zoo to stand", 300)
	player.capture_mouse()
	var day := station.get_node("LaundryDay/Day") as LaundryDay
	var label := station.get_node("Tally") as Label3D
	await _physics_ticks(2)
	_check(label.text.contains("0/3 loaded") and label.text.contains("not done"), "the label reads loaded/total (%s)" % label.text)
	var fix := station.get_node("LastFixPillar") as Node3D
	await _stand_facing(player, fix.global_position + Vector3(0.0, -0.5, 1.4), fix.global_position)
	await _press(&"interact")
	var run := station.get_node("Run") as LaundryRun
	_check(day.stages == run, "the station's Laundry day reads its stand-in run")
	await _until(func() -> bool: return run.fixed and day.fixed(), "the Last Fix done pillar to set the switch", 60)
	await _physics_ticks(2)
	_check(label.text.contains("last Fix done"), "the label says so (%s)" % label.text)
	var final := station.get_node("FinalPillar") as Node3D
	await _stand_facing(player, final.global_position + Vector3(0.0, -0.5, 1.4), final.global_position)
	await _press(&"interact")
	await _until(func() -> bool: return day.loaded_bins == 2, "the Final wash pillar to load all but one", 60)
	_check(day.ending_left < 0.0, "no wait yet")
	await _press(&"interact")
	await _until(func() -> bool: return day.loaded_bins == 3 and day.wait_left() >= 0.0, "the next press to load the last and start the wait", 60)
	await _until(func() -> bool: return day.final_started, "the wait to end in the Final wash", 200)
	await _physics_ticks(2)
	_check(label.text.contains("run ended"), "the label shows the end at once (%s)" % label.text)
	_check(not LevelRuntime.of(_zoo).final_screen.is_open(), "and no Final screen opens over the zoo")


# --- Helpers -------------------------------------------------------------------------------------

func _house_up() -> void:
	_holder = Node.new()
	add_child(_holder)
	_house = (load(HOUSE) as PackedScene).instantiate() as Node3D
	_holder.add_child(_house)
	var runtime := LevelRuntime.of(_house)
	await _until(runtime.loading.is_lifted, "the house's Socks to be laid", 900, 20.0)
	await _until(func() -> bool: return runtime.player.is_on_floor(), "the player to stand in the house", 900)
	runtime.player.capture_mouse()
	# The Laundry day comes after the First wash (core/94's suite plays it).
	runtime.parts.apply({"ok": true, "changes": {_day().id: {"first_wash": LaundryDay.FirstWash.DONE}}})


func _day() -> LaundryDay:
	return _house.get_node("LaundryDay/Day") as LaundryDay


func _used_names(day: LaundryDay) -> Array[String]:
	var out: Array[String] = []
	for bin in day.used_bins():
		out.append(String(bin.get_parent().name))
	out.sort()
	return out


func _count_used(answer: Dictionary) -> int:
	var n := 0
	for id: Variant in answer.get("changes", {}):
		if (answer["changes"][id] as Dictionary).get("used", false):
			n += 1
	return n


func _stand_facing(player: Player, feet: Vector3, target: Vector3) -> void:
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var head := player.get_node("Head") as Node3D
	var look := target - player.global_position
	player.rotation.y = atan2(-look.x, -look.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)
