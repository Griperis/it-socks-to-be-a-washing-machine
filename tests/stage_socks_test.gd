## A Stage's Socks (core/77): the Stages station's mini run (Cabinet A Simple on the ground, Cabinet B Sport
## sheeted on the platform, two Pairs a Drawer). Stage 1's Socks are laid after a New Game's start on the
## ground; "Fit now" lays Stage 2's in even shares over both floors; each Design spawns once, by the old
## rule; a load lays what is still due; a level that wants a First wash holds Stage 1's records until
## `lay_first`. The real path is the player's: the last Pair shelved by the Cabinet's click, E on "Fit now",
## up onto the platform and a pick by input.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's own Socks: Simple Pairs of Designs 0..5 are records 0..11, Sport the next four.
const SPOTS := 16
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
const BY_SWITCHES := Vector3(0.25, 0.0, 2.8)
## The platform's top (station space).
const PLATFORM_Y := 0.6

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _stages: Stages = null
var _spawner: StageSpawner = null
var _a: Cabinet = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: Stage 1's Socks lie on the ground; the player shelves the last Pair and presses E on \"Fit now\": Stage 2's Socks land on both floors in even shares and the player picks one up on the platform"},
		{"name": "designs", "method": "case_designs", "world": false,
				"title": "the old rule: Stage 1 spawns Cabinet A's Rows' Designs, the lesson's first and none of the locked Cabinet's; Stage 2 the Stage's Pairs; no Design twice, the same on a second reckoning"},
		{"name": "load_due", "method": "case_load_due", "world": false,
				"title": "a load with Designs due lays the rest: one already lying is dropped from due, never laid twice"},
		{"name": "held", "method": "case_held", "world": false,
				"title": "a level that wants a First wash holds Stage 1's records (saved state) and no Sock lies until lay_first reveals them all"},
		{"name": "records_for", "method": "case_records_for", "world": false,
				"title": "records_for lays one Pair for each Design given, the same from the same seed, the high spots never changing the count"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	_check(_stages.first_laid and _stages.due.is_empty() and not _stages.holding, "Stage 1's Socks landed, nothing due, nothing held")
	var stage_one := _mess.count() - SPOTS
	_check(stage_one == 8, "Stage 1 laid its 4 Pairs (%d Socks)" % stage_one)
	var high := 0
	for sock in range(SPOTS, _mess.count()):
		if _mess.pose_of(sock).origin.y > 0.3:
			high += 1
	_check(high == 0, "Stage 1's Socks all lie on the ground floor (%d up)" % high)
	# The bar's four Pairs: three by the Cabinet's helper, the last by the player's own click.
	for i in 3:
		await _shelve_pair(2 * i, 0 if i < 2 else 1)
	await _shelve_pair_by_input(6)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	_stand(BY_SWITCHES)
	await _aim(_player, _button("FitNow"))
	await _press(&"interact")
	await _until(func() -> bool: return _stages.stage == 1, "the next floor to open")
	await _until(func() -> bool: return _stages.due.is_empty(), "Stage 2's Socks to land")
	var first := SPOTS + stage_one
	var added := _mess.count() - first
	_check(added == 12, "Stage 2 laid its 6 Pairs (%d Socks)" % added)
	var on_ground := 0
	var on_platform := 0
	var one_up := -1
	for sock in range(first, _mess.count()):
		if _mess.pose_of(sock).origin.y > PLATFORM_Y - 0.05:
			on_platform += 1
			if one_up < 0 and not _mess.is_pair(sock):
				one_up = sock
		else:
			on_ground += 1
	_check(on_ground == 6 and on_platform == 6, "even shares: 6 Socks on each floor (%d ground, %d platform)" % [on_ground, on_platform])
	# Up on the platform the player picks one by input.
	_check(one_up >= 0, "a platform Sock to pick")
	var at := _centre(one_up)
	_player.global_position = at + Vector3(0.0, 0.0, 0.6)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await _physics_ticks(5)
	await _aim(_player, at)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) >= first, "the player to hold a Sock of Stage 2's")


# --- Rules ---------------------------------------------------------------------------------------

func case_designs() -> void:
	await _build()
	var cat := _mess.catalogue
	var spawned := _stages.spawned
	_check(spawned.size() == 4, "Stage 1 spawns the 4 Pairs its Rows take (%d)" % spawned.size())
	var lesson := Stages.lesson_designs(cat)
	_check(spawned.size() >= 2 and spawned[0] == lesson[0] and spawned[1] == lesson[1], "the washer lesson's two Designs come first (%s vs %s)" % [spawned, lesson])
	var all_simple := true
	for d in spawned:
		all_simple = all_simple and cat.design(d).collection == &"simple"
	_check(all_simple, "no Design of the locked Sport Cabinet spawns in Stage 1")
	var same := _stages.stage_designs(0, {_a: 2}, 2, PackedInt32Array())
	_check(same == spawned, "the same reckoning twice gives the same Designs (%s)" % same)
	for i in 4:
		await _shelve_pair(2 * i, 0 if i < 2 else 1)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	await _fit_now()
	await _until(func() -> bool: return _stages.stage == 1 and _stages.due.is_empty(), "Stage 2's Socks to land")
	_check(_stages.spawned.size() == 4 + 6, "Stage 2 spawns the Stage's 6 Pairs (%d in all)" % _stages.spawned.size())
	var seen := {}
	var twice := 0
	for d in _stages.spawned:
		twice += 1 if seen.has(d) else 0
		seen[d] = true
	_check(twice == 0, "each Design spawned once a run (%d twice)" % twice)
	var sport := 0
	for d in _stages.spawned.slice(4):
		sport += 1 if cat.design(d).collection == &"sport" else 0
	_check(sport >= 4, "Stage 2 gives Cabinet B's two Rows their Designs (%d Sport)" % sport)


func case_load_due() -> void:
	await _build()
	var fresh := PackedInt32Array([20, 21])
	var due := PackedInt32Array([0, 20, 21])
	_stages.write({"due": due}, false)
	var before := _mess.count()
	var answer := _stages.loaded("1")
	var still: PackedInt32Array = (answer["changes"] as Dictionary)[_stages.id]["due"]
	_check(still == fresh, "Design 0 already lies, so only the other two stay due (%s)" % still)
	_parts.apply(answer)
	await _until(func() -> bool: return _stages.due.is_empty(), "the rest to be laid")
	_check(_mess.count() == before + 4, "two Pairs were laid, none twice (%d new Socks)" % (_mess.count() - before))
	_check(_mess.count_of(20) == 2 and _mess.count_of(21) == 2, "each of them lies as one Pair")


func case_held() -> void:
	await _build(true)
	_check(_stages.holding, "a level that wants a First wash holds Stage 1's Socks")
	_check(_stages.held_designs.size() == 8 and _stages.held_poses.size() == 8 * Mess.POSE, "its 4 Pairs' records are held (%d)" % _stages.held_designs.size())
	_check(_mess.count() == SPOTS, "no Sock of Stage 1 lies (%d records)" % _mess.count())
	_check(not _stages.first_laid and _stages.due.is_empty(), "laid but not revealed")
	_check(_stages.state_names().has("held_designs") and _stages.state_names().has("held_poses"), "the held records are saved state")
	_parts.ask(Command.new(&"lay_first", Parts.HOST, _stages.id, {}))
	await _physics_ticks(2)
	_check(not _stages.holding and _stages.first_laid and _stages.held_designs.is_empty(), "lay_first lets them go")
	_check(_mess.count() == SPOTS + 8, "all of them lie (%d records)" % _mess.count())
	var lying := 0
	for sock in range(SPOTS, _mess.count()):
		lying += 1 if _mess.state_of(sock) == Mess.State.LYING else 0
	_check(lying == 8, "lying, none held or in the air (%d)" % lying)


func case_records_for() -> void:
	await _build()
	var gen := _station.get_node("Generators/Ground") as SockGenerator
	var designs := PackedInt32Array([30, 31, 32])
	var one := gen.records_for(designs, 7, _mess.catalogue)
	var two := gen.records_for(designs, 7, _mess.catalogue)
	_check((one["designs"] as PackedInt32Array).size() == 6, "one Pair for each Design given (%d Socks)" % (one["designs"] as PackedInt32Array).size())
	_check(one["poses"] == two["poses"] and one["designs"] == two["designs"], "the same seed gives the same records")
	var tall := gen.records_for(designs, 7, _mess.catalogue, [], 1, 1.7)
	_check((tall["designs"] as PackedInt32Array).size() == 6, "a high spot asked, none to be had: the count never changes")
	var set := {}
	for d in one["designs"] as PackedInt32Array:
		set[d] = true
	_check(set.size() == 3 and set.has(30) and set.has(31) and set.has(32), "each Design given, once as a Pair")
	var other := gen.records_for(designs, 8, _mess.catalogue)
	_check(other["poses"] != one["poses"], "another seed lays them elsewhere")


# --- Set-up --------------------------------------------------------------------------------------

## The station on a floor with the game's player and a Parts; `first_wash`: a stand-in LaundryDay that wants one.
func _build(first_wash := false) -> void:
	if _level != null:
		_level.free()
		_level = null
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_station.position = Vector3.ZERO
	if first_wash:
		var wanter := Node.new()
		wanter.name = "FirstWashStandIn"
		var script := GDScript.new()
		script.source_code = "extends Node\nfunc wants_first_wash() -> bool:\n\treturn true\n"
		script.reload()
		wanter.set_script(script)
		wanter.add_to_group(Stages.FIRST_WASH_GROUP)
		_station.add_child(wanter)
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = Vector3(-1.6, 0.0, 1.2)
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_stages = _station.get_node("Run/Stages") as Stages
	_spawner = _station.get_node("Run/StageSpawner") as StageSpawner
	_a = _station.get_node("CabinetA/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and _stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")
	await _until(func() -> bool: return _stages.due.is_empty(), "Stage 1's Socks to be laid")
	await _physics_ticks(2)


## Pairs Sock `sock` with its mate (the next id) by the Hands' Command and shelves the Pair into Cabinet
## A's drawer `drawer` by the Cabinet's click.
func _shelve_pair(sock: int, drawer: int) -> void:
	for s: int in [sock, sock + 1]:
		_hands.clock += 10.0
		_hands.pick(1, s)
		await _physics_ticks(1)
	var before := _a.shelved().size()
	_a.click(1, drawer)
	await _until(func() -> bool: return _a.shelved().size() == before + 1, "the Pair %d to be shelved" % sock)
	await _physics_ticks(1)


## The Pair of Sock `sock` shelved into Cabinet A's second Row by the player's own clicks.
func _shelve_pair_by_input(sock: int) -> void:
	_stand(Vector3(-1.6, 0.0, 1.2))
	await _aim(_player, _centre(sock))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == sock, "the Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(sock + 1))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(sock), "the mate to fuse into a Pair")
	_stand(BY_CABINET)
	var front := _a.get_parent().get_node("Drawer2/Looks/Slide/Front") as Node3D
	await _aim(_player, front.global_position + Vector3(0.3, 0.0, 0.0))
	await _press(&"pick")
	await _until(func() -> bool: return _a.contents(1).size() == 2, "the last Pair to be shelved")


func _fit_now() -> void:
	(_station.get_node("FitNow/StagesSwitch") as StagesSwitch).use(1)
	await _physics_ticks(1)


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _button(switch: String) -> Vector3:
	return (_station.get_node("%s/Looks/Button" % switch) as Node3D).global_position


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
