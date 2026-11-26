## The Final screen (core/95, run-ends.md "The Final screen"), in its zoo station: the 2-player pillar opened by the
## game's player with E, any key to skip to the totals, the columns of the players in the game at the end (a
## leaver has none, their Pairs count in the totals), the pop schedule, the long name, Continue, Esc.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["FinalScreen"]
const STATION := "Stations/FinalScreen"
const ACTIONS: Array[StringName] = [&"interact", &"ui_cancel"]

var _holder: Node = null
var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: E on the 2-player pillar opens the screen with two columns and the player held; a key skips to the totals: both scores read their final Coins, the totals show, Continue waits"},
		{"name": "leaver_and_totals", "method": "case_leaver_and_totals", "world": false,
				"title": "a player who left has no column, their Pairs count in the totals; the totals read Play time h:mm:ss, Coins earned and Stages from final_totals.tres; no titles of who did what"},
		{"name": "schedule", "method": "case_schedule", "world": false,
				"title": "the pop schedule is slow then a fast stream with a longer hold after a rare Pair; Pairs pop in order on the clock, the count and the bonus follow; the totals wait for the last column"},
		{"name": "unlock_strip", "method": "case_unlock_strip", "world": false,
				"title": "the pillar with an unlock shows the strip: a plural heading and a cell per Collection that pop one after another once the totals show, in the Collection's name; a skip shows them at once; a screen with none hides the strip"},
		{"name": "long_name_and_esc", "method": "case_long_name_and_esc", "world": false,
				"title": "a long name is clipped inside its column; Esc does not open the Esc menu over the screen; Continue is only a signal here and the station closes the screen, giving the player back"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _holder != null:
		_holder.free()
		_holder = null
		_zoo = null


func case_real_path() -> void:
	await _build()
	var station := _station()
	var screen := _screen()
	var pillar := station.pillars["2 players"]
	var player := _player()
	_check(not screen.is_open(), "the screen is shut before the press")
	var body := pillar.get_parent() as Node3D
	await _stand_facing(body.global_position + Vector3(0.0, -0.5, 1.5), body.global_position + Vector3.UP * 0.5)
	_check(player.aimed_part() == pillar, "the crosshair is on the 2-player pillar")
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return screen.is_open(), "E opens the screen")
	_check(screen.columns.size() == 2, "a column per player (%d)" % screen.columns.size())
	_check(player.input_blocked(), "the player is held")
	_check(not screen.totals_shown() and not screen.continue_button().visible, "the totals and Continue wait")
	_check(screen.columns[0].name_text() == "Mum" and screen.columns[1].name_text() == "Dad", "the names, in the Roster's order")
	await _key(KEY_SPACE)
	await _until(func() -> bool: return screen.totals_shown(), "a key skips to the totals")
	var summary := _summary("2 players")
	for i in 2:
		var c := screen.columns[i]
		_check(c.shown == c.pairs.size() and c.score_text() == str(int(summary.columns[i]["earned"])),
				"column %d shows its final Coins (%s of %d)" % [i, c.score_text(), int(summary.columns[i]["earned"])])
		_check(c.count_text() == "%d / %d Pairs" % [c.pairs.size(), c.pairs.size()], "and its count (%s)" % c.count_text())
	_check(screen.columns[0].bonus_text() == "+%d bonus" % screen.columns[0].bonus() and screen.columns[0].bonus() > 0,
			"the first player's Coins beyond their Pairs land as a +N bonus (%s)" % screen.columns[0].bonus_text())
	_check(screen.columns[1].bonus_text() == "", "the other has none")
	await _until(func() -> bool: return screen.finale_started() and screen.continue_button().visible, "the totals count up, the finale starts and Continue shows")
	_check(not screen.unlocked_strip().visible, "the unlock strip stays hidden while empty")


func case_unlock_strip() -> void:
	await _build()
	var screen := _screen()
	screen.open(_summary("1 player"))
	await _frames(2)
	_check(not screen.unlocked_strip().visible and screen.unlock_cells().is_empty(), "a game that unlocked nothing has no strip")
	screen.close()
	var summary := _summary("with an unlock")
	_check(summary.unlocked == [&"space", &"fruit"], "the pillar carries two unlocked Collections")
	screen.open(summary)
	await _frames(2)
	var cells := screen.unlock_cells()
	_check(screen.unlocked_strip().visible and cells.size() == 2, "the strip has a cell each")
	_check((cells[0].get_node("Body/Name") as Label).text == Collections.of(&"space").name, "the first cell names Space")
	_check((screen.get_node("%Heading") as Label).text == "New Collections unlocked", "the heading is plural")
	_check(screen.unlocks_shown() == 0, "nothing pops before the totals")
	var tuning := screen.tuning
	screen.advance(100.0)
	_check(screen.totals_shown() and screen.unlocks_shown() == 0, "the totals show and the strip waits its delay")
	screen.advance(tuning.unlock_delay + 0.01)
	_check(screen.unlocks_shown() == 1, "the first cell pops after the delay (%d)" % screen.unlocks_shown())
	screen.advance(tuning.unlock_gap + 0.01)
	_check(screen.unlocks_shown() == 2, "the second pops a gap later (%d)" % screen.unlocks_shown())
	screen.close()
	screen.open(summary)
	await _frames(2)
	screen.skip()
	_check(screen.unlocks_shown() == 2, "a skip shows both at once")
	_check((screen.unlock_cells()[1].get_node("Body") as Control).scale == Vector2.ONE, "the cell is whole")
	screen.close()


func case_leaver_and_totals() -> void:
	await _build()
	var screen := _screen()
	var summary := _summary("left")
	_check(summary.columns.size() == 2, "the summary has a column for each of the two who stayed (%d)" % summary.columns.size())
	var all := 0
	for row: Array in _all_rows("left"):
		all += int(row[2])
	_check(int(summary.values[&"coins_earned"]) == all, "the Coins earned count the leaver's Pairs too (%d of %d)" % [summary.values[&"coins_earned"], all])
	var stayed := 0
	for c: Dictionary in summary.columns:
		stayed += int((c["pairs"] as Array).size())
	_check(stayed < _all_rows("left").size(), "the leaver's Pairs are in the record but in no column")
	screen.open(summary)
	await _frames(2)
	_check(screen.columns.size() == 2, "the screen has two columns, none for the player who left")
	screen.skip()
	await _frames(2)
	await _until(func() -> bool: return screen.total_texts()[0] == "Play time 1:23:45", "the totals count up to the play time")
	_check(screen.total_texts() == ["Play time 1:23:45", "Coins earned %d" % all, "Stages 4"], "the three totals (%s)" % [screen.total_texts()])
	_check(screen.find_children("*", "Label", true, false).filter(func(n: Node) -> bool: return String((n as Label).text).contains("most")).is_empty(),
			"no who-did-what titles")
	screen.close()
	var level_summary := FinalSummary.of(LevelRuntime.of(_zoo))
	_check(level_summary.values.has(&"play_time") and level_summary.values.has(&"coins_earned") and level_summary.values.has(&"stages"),
			"FinalSummary.of(level) answers every total")


func case_schedule() -> void:
	var t := FinalScreenTuning.new()
	var times := FinalColumn.schedule([false, false, false], t)
	_near(times[0], t.start_delay, 0.0001, "the first Pair pops after start_delay")
	_near(times[1] - times[0], t.first_gap, 0.0001, "the first gap is first_gap")
	var long: Array = []
	long.resize(20)
	long.fill(false)
	var many := FinalColumn.schedule(long, t)
	_near(many[17] - many[16], t.fast_gap, 0.0001, "after ramp_pairs the gap is fast_gap")
	_check(many[2] - many[1] < many[1] - many[0], "the gaps shrink")
	var rare := FinalColumn.schedule([false, true, false], t)
	_near(rare[2] - rare[1], _gap(t, 1) + t.rare_pause, 0.0001, "a rare Pair holds rare_pause more")
	await _build()
	var screen := _screen()
	var summary := _summary("1 player")
	screen.open(summary)
	screen.set_process(false)
	var c := screen.columns[0]
	screen.advance(t.start_delay - 0.05)
	_check(c.shown == 0 and c.score_text() == "0", "nothing has popped before the first Pair")
	screen.advance(0.1)
	_check(c.shown == 1 and c.count_text() == "1 / %d Pairs" % c.pairs.size(), "the first Pair pops on its time (%s)" % c.count_text())
	var seen := 1
	for i in 600:
		screen.advance(0.05)
		_check(c.shown >= seen, "Pairs only come in order")
		seen = c.shown
		if c.shown == c.pairs.size() and c.settled == c.pairs.size():
			break
	_check(c.shown == c.pairs.size(), "every Pair pops in the end (%d)" % c.shown)
	_check(not screen.totals_shown() or screen.clock >= c.end, "the totals wait for the column to end")
	screen.advance(t.totals_delay + 0.1)
	_check(screen.totals_shown(), "then they show")
	screen.close()


func case_long_name_and_esc() -> void:
	await _build()
	var screen := _screen()
	var runtime := LevelRuntime.of(_zoo)
	screen.open(_summary("long name"))
	await _frames(3)
	var c := screen.columns[1]
	var label := c.find_child("Name", true, false) as Label
	_check(c.name_text() == FinalScreenStation.LONG_NAME, "the whole name is kept")
	_check(label.clip_text and label.size.x <= c.size.x, "it is clipped inside its column (%.0f of %.0f)" % [label.size.x, c.size.x])
	_check(absf(screen.columns[0].size.x - c.size.x) < 1.0, "and the columns stay as wide as each other")
	_check(not runtime.esc_menu.is_open(), "the Esc menu is shut")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await _frames(3)
	_check(not runtime.esc_menu.is_open(), "Esc does not open it over the screen")
	screen.skip()
	var closed := [false]
	screen.taken_down.connect(func() -> void: closed[0] = true)
	var pressed := [false]
	screen.continue_pressed.connect(func() -> void: pressed[0] = true)
	await _until(func() -> bool: return screen.continue_button().visible, "Continue to show")
	screen.continue_button().pressed.emit()
	_check(pressed[0], "Continue says it was pressed")
	_check(closed[0] and not screen.is_open(), "the station closes the screen")
	_check(not _player().input_blocked(), "the player is given back")


func _gap(t: FinalScreenTuning, k: int) -> float:
	var s := clampf(float(k) / float(t.ramp_pairs), 0.0, 1.0)
	s = s * s * (3.0 - 2.0 * s)
	return lerpf(t.first_gap, t.fast_gap, s)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	var up := InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	Input.parse_input_event(up)
	await _frames(1)


func _build() -> void:
	_holder = Node.new()
	_holder.name = "Alone"
	add_child(_holder)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder.add_child(_zoo)
	_player().global_position = (_zoo.get_node(STATION) as Node3D).global_position + Vector3(0.0, 0.0, 5.0)
	await _until(func() -> bool: return _player().is_on_floor(), "the zoo to stand", 300)
	_player().capture_mouse()


func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var head := player.get_node("Head") as Node3D
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _station() -> FinalScreenStation:
	return _zoo.get_node(STATION) as FinalScreenStation


func _screen() -> FinalScreen:
	return _station().screen


func _summary(key: String) -> FinalSummary:
	return _station().pillars[key].summary


func _all_rows(key: String) -> Array:
	var rows := []
	for c: Dictionary in _summary(key).columns:
		rows.append_array(c["pairs"] as Array)
	# The leaver's Pairs are not in a column: the record the station made is rebuilt the same way.
	var leaver := FinalScreenStation.made_up([["Ana", 18], ["Ben", 26], ["Gone", 14]])
	var all := []
	for c: Dictionary in leaver.columns:
		for p: Array in c["pairs"]:
			all.append([c["id"], p[0], p[1]])
	return all if key == "left" else rows


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
