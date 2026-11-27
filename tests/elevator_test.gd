## The Elevator (core/155, docs/architecture/elevator.md): the car, the calls, the hatches, the locks and out of
## order. The real path is the house from a New Game: the player's left click on the ground floor's call button reads
## "Out of order (...)", and once Elevator Repair is bought and the ground floor is open, a click on the basement's
## button shuts the kitchen hatch and after `hatch_time` + `floor_time` opens the basement's with the bell there. The
## rules are played in the Elevator station (its own run and Upgrades) on a floor with the game's player and a Parts,
## as floor_lock_test does; the co-op case is two houses in one process (coop_fix_scene_test's frame).
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const STATION := "res://game/zoo/stations/elevator.tscn"
const PLAYER := "res://game/player/player.tscn"
const ENTITY := "res://game/entities/elevator/elevator.tscn"
const STOP := "res://game/entities/elevator/elevator_stop.tscn"
const ELEVATOR := "Systems/Elevator/Elevator/Elevator"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
const OUT_OF_ORDER := "Out of order (needs the Elevator Repair upgrade)"
const LOCKED := "Elevator locked"
const LAYING_S := 20.0
const NET_WAIT_S := 30.0
const FPS := 60
## In the kitchen and in the basement, in front of the stop's call button (the hatches face west).
const BY_GROUND := Vector3(2.45, 0.0, 5.6)
const BY_BASEMENT := Vector3(2.45, -3.0, 5.6)
## In the station, by the lower hatch.
const BY_LOWER := Vector3(2.4, 0.0, 0.6)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _parts: Parts = null
var _heard: Array[Array] = []
var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the house from a New Game the left click on the ground floor's call button reads \"Out of order (needs the Elevator Repair upgrade)\" and the plaque shows; after the real buy of Elevator Repair and the ground floor's opening, a click on the basement's button shuts the kitchen hatch (its clip, hatch_close) and after hatch_time + floor_time the basement's opens with the bell heard there"},
		{"name": "calls", "method": "case_calls", "world": false,
				"title": "a call while riding turns the car (the newest wins) and it arrives at the new floor; the hatch where the car stands opens and shuts on a click (\"Shut the hatch\" / \"Open the hatch\"); the button opens a shut hatch and never shuts it; the button's click sounds from the answer"},
		{"name": "locks", "method": "case_locks", "world": false,
				"title": "in a run, until Repair the stops wear the plaque and read and refuse \"Out of order (...)\"; repaired, a locked floor's stop shows its padlock and reads and refuses \"Elevator locked\" (all of them before the ground floor opens); when the floor opens its padlock plays unlock; the letters show the car's floor lit and a locked floor locked"},
		{"name": "fast", "method": "case_fast", "world": false,
				"title": "Fast Elevator level 2 makes a floor 1.0 s (2.0, 1.5, 1.0 s on the card); Elevator Repair and Fast Elevator are no longer \"Coming soon\""},
		{"name": "save_mid_ride", "method": "case_save_mid_ride", "world": false,
				"title": "a World saved mid-ride and loaded into a fresh station resumes the ride where it got and ends it at its floor, the hatches as they were"},
		{"name": "no_run", "method": "case_no_run", "world": false,
				"title": "an Elevator in a level with no Stages (the zoo) is never out of order and has no locked floor: its button calls the car"},
		{"name": "guest", "method": "case_guest", "world": false,
				"title": "co-op: a late Guest sees the car where it is and the hatches as they are; a Guest's click waits for the Host's answer, its button sound comes from the answer, and both machines see the hatch shut and the ride"},
	]


func _before_case() -> void:
	wait_floor_s = 0.0
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if Sounds.played.is_connected(_on_played):
		Sounds.played.disconnect(_on_played)
	_heard.clear()
	_free_level()
	_drop_branches()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	var stages := _level.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return rt.loading.is_lifted() and stages.stage == 0, "the house's New Game to start", 900, LAYING_S)
	_player = rt.player
	_player.capture_mouse()
	var e := _level.get_node(ELEVATOR) as Elevator
	var ground := e.stops()[1]
	var basement := e.stops()[0]
	_check(e.stop == 1 and e.phase == Elevator.Phase.OPEN and ground.hatch.open and not basement.hatch.open,
			"a New Game: the car stands open at the kitchen, empty (%d, %d)" % [e.stop, e.phase])
	# Out of order: the plaque, the words.
	_stand(BY_GROUND)
	await _aim(ground.button_spot())
	_check(_player.aimed_part() == ground.get_node("Button/Control"), "the crosshair is on the ground floor's call button (%s)" % _player.aimed_part())
	_check(_player.hud().prompt_text().contains(OUT_OF_ORDER), "it reads \"%s\" (%s)" % [OUT_OF_ORDER, _player.hud().prompt_text()])
	await _press(&"pick")
	await _until(func() -> bool: return _player.message() == OUT_OF_ORDER, "the click to be refused \"%s\"" % OUT_OF_ORDER, 60)
	_check(e.stop == 1 and e.phase == Elevator.Phase.OPEN, "the car did not move")
	_check((ground.get_node("Looks/Hatch/Signs/out_of_order") as Node3D).visible, "the plaque shows on the kitchen hatch")
	# The real buy of Elevator Repair, and the ground floor opens.
	var ups := Upgrades.of(e)
	rt.parts.apply(rt.bank.grant(rt.bank.drawers_patch(1)))
	rt.parts.ask(Command.new(Upgrades.BUY, 1, ups.id, {"upgrade": "elevator_repair"}))
	_check(int(ups.house.get("elevator_repair", 0)) == 1 and not e.is_broken(), "Elevator Repair is bought")
	await _until(func() -> bool: return not (ground.get_node("Looks/Hatch/Signs/out_of_order") as Node3D).visible, "the plaque to go", 120)
	rt.parts.ask(Command.new(&"fit_now", Parts.HOST, stages.id, {}))
	await _until(func() -> bool: return stages.stage == 1, "the ground floor to open")
	_check(not e.is_locked(0) and not e.is_locked(1), "the basement and the ground floor are open to it")
	# A left click on the basement's call button.
	_stand(BY_BASEMENT)
	await _aim(basement.button_spot())
	_check(_player.aimed_part() == basement.get_node("Button/Control"), "the crosshair is on the basement's call button")
	_check(_player.hud().prompt_text().contains(ElevatorControl.CALL), "it reads \"Call the Elevator\" (%s)" % _player.hud().prompt_text())
	Sounds.played.connect(_on_played)
	await _press(&"pick")
	await _until(func() -> bool: return not ground.hatch.open, "the kitchen hatch to shut", 30)
	var animator := ground.hatch.animator()
	_check(animator.current_animation == Openable.SHUT and animator.is_playing(), "its shut clip plays (%s)" % animator.current_animation)
	_check(_heard_at(&"hatch_close") != Vector3.INF, "hatch_close sounds")
	_check(_heard_at(&"elevator_button").distance_to(basement.button_spot()) < 0.2, "the button's click sounds at the basement's button")
	var ticks := 0
	while not basement.hatch.open and ticks < 600:
		await _physics_ticks(1)
		ticks += 1
	var want := (e.tuning.hatch_time + e.tuning.floor_time) * Engine.physics_ticks_per_second
	_check(basement.hatch.open and absf(ticks - want) <= 4.0, "the basement hatch opens after hatch_time + floor_time (%d ticks, %d wanted)" % [ticks, want])
	_check(e.stop == 0 and e.phase == Elevator.Phase.OPEN, "the car stands open at the basement")
	var bell := _heard_at(&"elevator_bell")
	_check(bell.distance_to(basement.hatch_spot()) < 0.1, "the bell is heard at the basement's hatch (%s)" % bell)
	_check(_heard_at(&"hatch_open").distance_to(basement.global_position) < 1.5, "hatch_open sounds there")
	_check(absf((e.car as Node3D).global_position.y - basement.car_height()) < 0.01, "the car is drawn at the basement")


# --- Rules (the Elevator station) ----------------------------------------------------------------

func case_calls() -> void:
	await _build()
	await _switch("Repair")
	await _switch("OpenUpper")
	var e := _elevator()
	var lower := e.stops()[0]
	var upper := e.stops()[1]
	_check(e.stop == 0 and e.phase == Elevator.Phase.OPEN and lower.hatch.open, "the car stands open at the lower stop")
	Sounds.played.connect(_on_played)
	_button(upper).use(1)
	_check(e.phase == Elevator.Phase.CLOSING and e.bound == 1 and not lower.hatch.open, "a call from upstairs shuts the lower hatch first")
	_check(_heard_at(&"elevator_button").distance_to(upper.button_spot()) < 0.2, "the button's click sounds from the answer at the upper button")
	await _until(func() -> bool: return e.phase == Elevator.Phase.RIDING, "the car to depart", 60)
	_check(e.stop == 1, "riding, it is drawn at the floor it is bound for")
	await _physics_ticks(30)
	var at := e.position_now()
	_check(at > 0.15 and at < 0.4, "a quarter of the way up after half a second (%.2f)" % at)
	_button(lower).use(1)
	_check(e.phase == Elevator.Phase.RIDING and e.bound == 0, "a call while riding turns the car for the newer call")
	_near(e.position_now(), at, 0.02, "from where it got")
	_near(e.left_now(), at * e.floor_seconds(), 0.05, "and it rides back the way it came")
	await _until(func() -> bool: return e.phase == Elevator.Phase.OPEN, "the car to arrive", 120)
	_check(e.stop == 0 and lower.hatch.open and not upper.hatch.open, "it arrives at the lower stop and its hatch opens")
	var creaks := _heard.filter(func(h: Array) -> bool: return h[0] == &"elevator_creak")
	_check(creaks.size() == 1 and (creaks[0][1] as Vector3).y > lower.car_height() and (creaks[0][1] as Vector3).y < upper.car_height(),
			"the rope creaks once in the 1 s ride (every 0.7 s), in the shaft where the ride has got to (%s)" % [creaks])
	_check(_heard_at(&"elevator_bell").distance_to(lower.hatch_spot()) < 0.1, "the bell rings at the lower hatch")
	# The hatch where it stands: open and shut by a click.
	var hatch := lower.get_node("Control") as ElevatorControl
	_check(hatch.prompt_title() == "Shut the hatch", "the open hatch reads \"Shut the hatch\" (%s)" % hatch.prompt_title())
	hatch.use(1)
	_check(e.phase == Elevator.Phase.SHUT and not lower.hatch.open, "a click shuts it")
	_check(hatch.prompt_title() == "Open the hatch", "the shut hatch reads \"Open the hatch\"")
	hatch.use(1)
	_check(e.phase == Elevator.Phase.OPEN and lower.hatch.open, "a click opens it")
	hatch.use(1)
	_check(not lower.hatch.open, "shut again")
	# The button opens a shut hatch, never shuts it.
	_heard.clear()
	_button(lower).use(1)
	_check(e.phase == Elevator.Phase.OPEN and lower.hatch.open, "the button opens the shut hatch where the car stands")
	_button(lower).use(1)
	_check(e.phase == Elevator.Phase.OPEN and lower.hatch.open, "the button never shuts it")
	_check(_heard.filter(func(h: Array) -> bool: return h[0] == &"elevator_button").size() == 2, "each click sounds the button")
	# A hatch elsewhere calls the car.
	var far := upper.get_node("Control") as ElevatorControl
	_check(far.prompt_title() == ElevatorControl.CALL, "a hatch where the car is not reads \"Call the Elevator\"")
	far.use(1)
	_check(e.phase == Elevator.Phase.CLOSING and e.bound == 1, "a click on it calls the car")


func case_locks() -> void:
	await _build()
	var e := _elevator()
	var lower := e.stops()[0]
	var upper := e.stops()[1]
	await _physics_ticks(5)
	_check(e.is_broken(), "in the station's run, without Repair, it is out of order")
	_check(_plaque(lower).visible and _plaque(upper).visible, "every stop wears the plaque")
	_check(not _padlock(lower).visible, "and no padlock while it is out of order")
	_check(_button(lower).prompt_title() == OUT_OF_ORDER and (lower.get_node("Control") as ElevatorControl).prompt_title() == OUT_OF_ORDER,
			"its button and hatch read \"%s\"" % OUT_OF_ORDER)
	_stand(BY_LOWER)
	await _aim(lower.button_spot())
	await _press(&"interact")
	await _until(func() -> bool: return _player.message() == OUT_OF_ORDER, "E on the button to be refused \"%s\"" % OUT_OF_ORDER, 60)
	_check(e.phase == Elevator.Phase.OPEN and e.stop == 0, "nothing moved")
	await _switch("Repair")
	await _until(func() -> bool: return not _plaque(lower).visible and not _plaque(upper).visible, "the plaques to go", 120)
	await _until(func() -> bool: return _padlock(lower).visible and _padlock(upper).visible,
			"both padlocks to show: before the ground floor opens the whole Elevator is locked", 120)
	_check(_button(upper).prompt_title() == LOCKED and _button(lower).prompt_title() == LOCKED, "the stops read \"%s\"" % LOCKED)
	var refusals: Array[String] = []
	e.refused.connect(func(_by: int, words: String) -> void: refusals.append(words))
	_button(upper).use(1)
	_check(refusals == [LOCKED] and e.phase == Elevator.Phase.OPEN, "a call is refused \"%s\" (%s)" % [LOCKED, refusals])
	var letters := e.letters.get_children()
	_check(letters.size() == 2 and letters[0].name == "LetterB" and letters[1].name == "LetterG"
			and (letters[0] as Node3D).position.y < (letters[1] as Node3D).position.y, "the car's letters: B under G")
	_check(_letter_clip(letters[1]) == &"locked" and _letter_clip(letters[0]) == &"locked", "a locked floor's letter plays locked")
	var unlocks := (lower.player_of(ElevatorStop.UNLOCK))
	await _switch("OpenUpper")
	_check(unlocks.current_animation == ElevatorStop.UNLOCK and unlocks.is_playing(), "the floor opens: its padlock plays unlock")
	await _until(func() -> bool: return not _padlock(lower).visible and not _padlock(upper).visible, "the padlocks to go", 120)
	_check(_letter_clip(letters[0]) == &"lit" and _letter_clip(letters[1]) == &"dark", "the car's floor's letter is lit, the other dark")
	_button(upper).use(1)
	_check(e.phase == Elevator.Phase.CLOSING, "now a call is answered")


func case_fast() -> void:
	var fast := Upgrades.find_upgrade(&"fast_elevator")
	var repair := Upgrades.find_upgrade(&"elevator_repair")
	_check(repair.stat != null and fast.stat != null and repair.stat.kind == UpgradeStat.Kind.FLAG, "Elevator Repair and Fast Elevator have their stats")
	_check([fast.stat.text_at(0), fast.stat.text_at(1), fast.stat.text_at(2)] == ["2.0 s", "1.5 s", "1.0 s"],
			"the card reads 2.0, 1.5 and 1.0 s (%s)" % [[fast.stat.text_at(0), fast.stat.text_at(1), fast.stat.text_at(2)]])
	await _build()
	var e := _elevator()
	var ups := Upgrades.of(e)
	_check(ups == _station.get_node("Socks/Upgrades"), "the Elevator reads its station's own Upgrades")
	_check(ups.refusal(repair, 1, 99) != Upgrades.SOON and ups.refusal(fast, 1, 99) != Upgrades.SOON, "neither is \"Coming soon\"")
	await _switch("Repair")
	await _switch("OpenUpper")
	_near(e.floor_seconds(), 2.0, 0.001, "a floor takes 2.0 s")
	await _switch("FastElevator")
	_near(e.floor_seconds(), 1.5, 0.001, "1.5 s at level 1")
	await _switch("FastElevator")
	_near(e.floor_seconds(), 1.0, 0.001, "1.0 s at level 2")
	_button(e.stops()[1]).use(1)
	await _until(func() -> bool: return e.phase == Elevator.Phase.RIDING, "the car to depart", 60)
	var ticks := 0
	while e.phase == Elevator.Phase.RIDING and ticks < 300:
		await _physics_ticks(1)
		ticks += 1
	_check(absi(ticks - Engine.physics_ticks_per_second) <= 3, "the ride of a floor takes 1.0 s (%d ticks)" % ticks)


func case_save_mid_ride() -> void:
	await _build()
	await _switch("Repair")
	await _switch("OpenUpper")
	var e := _elevator()
	_button(e.stops()[1]).use(1)
	await _until(func() -> bool: return e.phase == Elevator.Phase.RIDING, "the car to depart", 60)
	await _physics_ticks(60)
	var left := e.left_now()
	var saved := _parts.save_snapshot()
	var versions := _parts.save_versions()
	_check(saved.has(String(e.id)) and absf(float(saved[String(e.id)]["time_left"]) - left) < 0.05, "the save keeps the live time left (%.2f)" % left)
	await _build()
	e = _elevator()
	_parts.load_save(saved, versions, "host")
	_check(e.phase == Elevator.Phase.RIDING and e.stop == 1 and e.bound == 1, "loaded, it rides to the upper floor")
	_near(e.left_now(), left, 0.05, "from where it got")
	_check(not e.stops()[0].hatch.open and not e.stops()[1].hatch.open, "both hatches shut, as they were")
	await _until(func() -> bool: return e.phase == Elevator.Phase.OPEN, "the ride to end", 200)
	_check(e.stop == 1 and e.stops()[1].hatch.open, "it ends at its floor, the hatch there open")


func case_no_run() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var root := (load(ENTITY) as PackedScene).instantiate() as Node3D
	for at: int in [0, 1]:
		var s := (load(STOP) as PackedScene).instantiate() as ElevatorStop
		s.name = "Stop%d" % at
		s.floor = at
		s.position = Vector3(-0.35, 3.0 * at, 0.0)
		root.add_child(s)
	_level.add_child(root)
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	await _until(func() -> bool: return _parts.is_bound, "the Parts to bind")
	var e := root.get_node("Elevator") as Elevator
	_check(not e.is_broken() and not e.is_locked(0) and not e.is_locked(1), "no Stages: never out of order, no locked floor")
	_check(not _plaque(e.stops()[0]).visible and not _padlock(e.stops()[1]).visible, "no plaque, no padlock")
	_button(e.stops()[0]).use(1)
	_check(e.phase == Elevator.Phase.CLOSING and e.bound == 0, "its button calls the car")


# --- Co-op ---------------------------------------------------------------------------------------

func case_guest() -> void:
	wait_floor_s = NET_WAIT_S
	var host := _branch("Host")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host house hosts")
	var hstages := host.get_node("Run/Stages") as Stages
	await _wait(func() -> bool: return LevelRuntime.of(host).loading.is_lifted() and hstages.stage == 0, "the Host's run to start", FPS * 40)
	var hp := LevelRuntime.of(host).parts
	hp.where = Callable()  # the players' places are the Host's player's and the Guest's synced body: not this case's
	var he := host.get_node(ELEVATOR) as Elevator
	var hups := Upgrades.of(he)
	hp.apply(hups.grant({"house": {"elevator_repair": 1}}))
	hp.ask(Command.new(&"fit_now", Parts.HOST, hstages.id, {}))
	_button(he.stops()[0]).use(Parts.HOST)
	await _wait(func() -> bool: return he.phase == Elevator.Phase.OPEN and he.stop == 0, "the Host's car to reach the basement", FPS * 6)
	var guest := _branch("Guest")
	await _frames(2)
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the guest joins")
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined"), "the Guest to be welcomed", FPS * 40)
	var ge := guest.get_node(ELEVATOR) as Elevator
	await _wait(func() -> bool: return ge.stop == 0, "the late Guest to hold the car", FPS * 10)
	_check(ge.phase == Elevator.Phase.OPEN and ge.stops()[0].hatch.open and not ge.stops()[1].hatch.open,
			"the late Guest sees the car open at the basement and the kitchen hatch shut")
	_check(absf((ge.car as Node3D).global_position.y - ge.stops()[0].car_height()) < 0.01, "and the car drawn there")
	# The Guest calls the car up from the kitchen.
	Sounds.played.connect(_on_played)
	_button(ge.stops()[1]).use(gs.me())
	_check(ge.phase == Elevator.Phase.OPEN and _heard_at(&"elevator_button") == Vector3.INF, "the Guest's click waits for the answer: nothing moved or sounded yet")
	await _wait(func() -> bool: return ge.phase == Elevator.Phase.CLOSING and he.phase == Elevator.Phase.CLOSING, "both machines to see the hatch shutting", FPS * 5)
	_check(not ge.stops()[0].hatch.open, "the basement hatch shuts on the Guest")
	_check(_heard.filter(func(h: Array) -> bool: return h[0] == &"elevator_button").size() >= 2, "the button sounds from the answer on both machines")
	await _wait(func() -> bool: return ge.phase == Elevator.Phase.OPEN and ge.stop == 1, "the Guest to see the car arrive in the kitchen", FPS * 6)
	_check(ge.stops()[1].hatch.open, "the kitchen hatch opens on the Guest")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
	_free_level()
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
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = Vector3(0.0, 0.0, 3.0)
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	var stages := _station.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return _player.is_on_floor() and _parts.is_bound and stages.stage == 0, "the player to stand and the station's run to start")


func _free_level() -> void:
	if _level != null:
		_level.free()
		_level = null


func _elevator() -> Elevator:
	return _station.get_node("Elevator/Elevator") as Elevator


func _button(s: ElevatorStop) -> ElevatorControl:
	return s.get_node("Button/Control") as ElevatorControl


func _plaque(s: ElevatorStop) -> Node3D:
	return s.get_node("Looks/Hatch/Signs/out_of_order") as Node3D


func _padlock(s: ElevatorStop) -> Node3D:
	return s.get_node("Looks/Hatch/Signs/lock_sign") as Node3D


func _letter_clip(letter: Node) -> StringName:
	return (letter.get_node("Looks/AnimationPlayer") as AnimationPlayer).assigned_animation


## A station switch pressed by the player's use (its Part asks the Host).
func _switch(name_: String) -> void:
	(_station.get_node(name_ + "/ElevatorSwitch") as ElevatorSwitch).use(1)
	await _physics_ticks(1)


func _on_played(event: StringName, _spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([event, at])


## Where `event` was last heard, or INF.
func _heard_at(event: StringName) -> Vector3:
	for i in range(_heard.size() - 1, -1, -1):
		if _heard[i][0] == event:
			return _heard[i][1]
	return Vector3.INF


func _stand(spot: Vector3) -> void:
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _aim(target: Vector3) -> void:
	var head := _player.get_node("Head") as Node3D
	var to := target - _player.global_position
	_player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(3)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


## A house in a machine of its own (its own MultiplayerAPI and 3D world).
func _branch(label: String) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	view.add_child(house)
	_branches.append(node)
	return house


func _drop_branches() -> void:
	for node in _branches:
		var view := node.get_node_or_null("View")
		var house: Node = view.get_child(0) if view != null and view.get_child_count() > 0 else null
		var session := LevelRuntime.of(house).session if house != null else null
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
