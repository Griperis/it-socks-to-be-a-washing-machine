## The floor locks (core/80, docs/architecture/stages.md "The floor locks"): the plank door and the baby gate
## shut the way up to a floor until the Stage that opens it; the padlock is its own aim target ("Please the
## washing machine", no key), the leaf stops the player and the crosshair, and the opening (padlock pop, chain,
## swing, lamps, the Cabinet's dust sheet) shows on every machine, as a state arriving whole shows it at once.
## Played in the Stages station (the door in its back wall, the gate on the platform, Cabinet B under its
## sheet) on a floor with the game's player and a Parts, as machine_part_test does.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
const GATE := "Gate"
const DOOR := "Door"
## On the ramp just under the gate, facing it (the gate stands at the platform's front edge).
const BY_GATE := Vector3(4.0, 0.5, -0.7)
const BY_FIT_NOW := Vector3(0.25, 0.0, 2.8)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _parts: Parts = null
var _stages: Stages = null
var _lights: HouseLights = null
var _heard: Array[StringName] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player aims at the gate's padlock (outlined, \"Please the washing machine\", no key), presses E on Fit now; the padlock pops, the gate swings open and the player walks through onto the platform"},
		{"name": "locked_stops", "method": "case_locked_stops", "world": false,
				"title": "a locked leaf stops the player and the crosshair (no prompt, no outline on it), and the gate's blocker reaches the ceiling; the door has none"},
		{"name": "swing_sweeps", "method": "case_swing_sweeps", "world": false,
				"title": "the leaf is an Openable whose moving body the Mess sweeps Socks with; it swings about 90 degrees after the 0.8 s hold, with padlock_pop, chain_drop and lock_door_open once each"},
		{"name": "load_shows", "method": "case_load_shows", "world": false,
				"title": "a snapshot of an opened run loaded into a fresh station shows the leaf open, the padlock and chain gone, the blocker off, with no animation and no sound; a locked one shows them in place"},
		{"name": "lamps", "method": "case_lamps", "world": false,
				"title": "a locked floor's lamps stay off; an opened floor's fade in over 0.6 s, stay lit by day for 6 s and fade back over 1.2 s; other floors are not touched"},
		{"name": "floor_opens_all", "method": "case_floor_opens_all", "world": false,
				"title": "the Stage that opens the floor unlocks the door and the gate and pulls Cabinet B's dust sheet; the pillar locks them again"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if Sounds.played.is_connected(_on_played):
		Sounds.played.disconnect(_on_played)
	_heard.clear()
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var lock := _lock(GATE)
	_stand(BY_GATE)
	await _aim(_player, _padlock_at(GATE))
	await _physics_ticks(25)
	_check(_player.aimed_part() == lock, "the crosshair is on the padlock")
	var text := _player.hud().prompt_text()
	_check(text == "Please the washing machine", "it reads the hint with no key (%s)" % text)
	_check(_player.aimed_outline != null and _player.aimed_outline.shown, "the padlock is outlined")
	_check(_player.aimed_outline.get_parent().get_parent() == _station.get_node(GATE), "it is the padlock's own outline")
	# Fit now: the zoo's switch that fits the Part and opens the floor.
	_stand(BY_FIT_NOW)
	await _aim(_player, (_station.get_node("FitNow/Looks/Button") as Node3D).global_position)
	await _physics_ticks(5)
	Sounds.played.connect(_on_played)
	await _press(&"interact")
	await _until(func() -> bool: return _stages.stage == 1, "the floor to open", 60)
	_check(not _lock(GATE).is_locked() and _lock(GATE).leaf().open, "the gate's leaf is unlocked and open")
	await _until(func() -> bool: return _heard.has(&"padlock_pop"), "the padlock to pop")
	await _until(func() -> bool: return not _lock(GATE).leaf().is_moving() and _heard.has(&"lock_door_open"), "the leaf to finish swinging", 600)
	_check(_leaf_angle(GATE) > 1.4, "the leaf stands open (%.2f rad)" % _leaf_angle(GATE))
	# Walk through onto the platform.
	_stand(BY_GATE)
	await _aim(_player, Vector3(4.0, 0.9, -3.0))
	Input.action_press(&"move_forward")
	var through := await _until(func() -> bool: return _player.global_position.z < -2.2, "the player to walk through the gate", 1200)
	Input.action_release(&"move_forward")
	var blocking := _player.get_last_slide_collision()
	_check(through and _player.global_position.y > 0.5, "and stands on the platform (%s) stopped by %s; blocker layer %d, leaf body at %s basis x %s" % [_player.global_position, blocking.get_collider().get_path() if blocking != null else "nothing", (_station.get_node(GATE + "/Blocker") as StaticBody3D).collision_layer, (_station.get_node(GATE + "/Looks/leaf") as Node3D).global_position, (_station.get_node(GATE + "/Looks/leaf") as Node3D).global_basis.x])


# --- Rules ---------------------------------------------------------------------------------------

func case_locked_stops() -> void:
	await _build()
	var aim := _player.get_node("%Aim") as RayCast3D
	# The crosshair on the gate's leaf: it stops the ray, but nothing is aimed or outlined.
	_stand(Vector3(4.3, 0.5, -0.8))
	await _aim(_player, Vector3(4.3, 0.95, -1.5))
	await _physics_ticks(5)
	var hit := aim.get_collider() as Node
	_check(hit != null and (hit == _station.get_node(GATE + "/Looks/leaf") or hit == _station.get_node(GATE + "/Blocker")),
			"the ray stops on the gate (its leaf or its blocker): %s" % [hit.get_path() if hit != null else "nothing"])
	_check(_player.aimed_part() == null and _player.aimed_outline == null, "no part and no outline while it is locked")
	_check(_player.hud().prompt_text() == "", "no prompt on the leaf (%s)" % _player.hud().prompt_text())
	# The door's leaf stops it too (the door has no blocker).
	_stand(Vector3(-4.3, 0.0, -3.4))
	await _aim(_player, Vector3(-4.3, 1.0, -4.2))
	await _physics_ticks(5)
	hit = aim.get_collider() as Node
	_check(hit != null and hit == _station.get_node(DOOR + "/Looks/leaf"), "the ray stops on the door's leaf")
	_check(_player.aimed_part() == null and _player.hud().prompt_text() == "", "and nothing is aimed")
	# The player is stopped.
	_stand(Vector3(4.0, 0.5, -0.8))
	await _aim(_player, Vector3(4.0, 0.9, -3.0))
	Input.action_press(&"move_forward")
	await _physics_ticks(90)
	Input.action_release(&"move_forward")
	_check(_player.global_position.z > -1.5, "the locked gate stops the player (z %.2f)" % _player.global_position.z)
	var blocker := _station.get_node(GATE + "/Blocker") as StaticBody3D
	var box := blocker.get_node("Shape").shape as BoxShape3D
	var top: float = blocker.get_node("Shape").global_position.y + box.size.y * 0.5
	_check(top >= _station.get_node(GATE).global_position.y + 2.69, "the gate's blocker reaches the ceiling (top %.2f)" % top)
	_check(_station.get_node_or_null(DOOR + "/Blocker") == null, "the door has none")
	_check(blocker.collision_layer == Mess.LAYER_HOUSE, "and it is on the house layer")


func case_swing_sweeps() -> void:
	await _build()
	Sounds.played.connect(_on_played)
	var leaf := _lock(DOOR).leaf()
	var movers := leaf.movers()
	_check(leaf.is_in_group(Openable.GROUP) and movers.size() == 1, "the leaf is an Openable with one moving body")
	var body := movers[0]
	var before := body.global_transform
	_parts.ask(Command.new(&"zoo_fit_now", Parts.HOST, _stages.id))
	await _until(func() -> bool: return leaf.open, "the leaf to be told open", 60)
	await _until(func() -> bool: return leaf.is_moving() and body.global_transform != before, "the leaf to start swinging")
	# The hold: nothing swings for the first 0.8 s.
	_check(_leaf_angle(DOOR) < 0.05, "the leaf holds before it swings (%.2f rad)" % _leaf_angle(DOOR))
	await _until(func() -> bool: return not leaf.is_moving(), "the swing to end", 600)
	_near(_leaf_angle(DOOR), PI * 0.5, 0.02, "it ends a quarter turn over the flight")
	for event: StringName in [&"padlock_pop", &"chain_drop", &"lock_door_open"]:
		_same(_heard.count(event), 2, "%s plays once for each of the two locks" % event)
	_check(_heard.find(&"padlock_pop") < _heard.find(&"chain_drop") and _heard.find(&"chain_drop") < _heard.find(&"lock_door_open"), "in that order (%s)" % [_heard])


func case_load_shows() -> void:
	await _build()
	var snap_locked := _parts.snapshot()
	_parts.ask(Command.new(&"zoo_fit_now", Parts.HOST, _stages.id))
	await _until(func() -> bool: return _stages.stage == 1 and not _lock(GATE).leaf().is_moving() and not _lock(DOOR).leaf().is_moving(),
			"the floor to open and the leaves to stop", 600)
	await _physics_ticks(60)
	var snap_open := _parts.snapshot()
	await _build()
	Sounds.played.connect(_on_played)
	_parts.load_snapshot(snap_open)
	await _physics_ticks(3)
	for name_: String in [GATE, DOOR]:
		var lock := _lock(name_)
		_check(not lock.is_locked() and lock.leaf().open and not lock.leaf().is_moving(), "%s stands open at once" % name_)
		_near(_leaf_angle(name_), PI * 0.5, 0.02, "%s's leaf is at its end pose" % name_)
		var looks := _station.get_node(name_ + "/Looks")
		_check(not (looks.get_node("padlock") as Node3D).visible and not (looks.get_node("chain") as Node3D).visible, "%s's padlock and chain are gone" % name_)
		_check((lock.aim.collision_layer == 0), "%s's padlock cannot be aimed" % name_)
	_check((_station.get_node(GATE + "/Blocker") as StaticBody3D).collision_layer == 0, "the gate's blocker is off")
	_check(not (_station.get_node("CabinetB/DustSheet") as DustSheet).visible, "Cabinet B's sheet is gone")
	_check(_heard.is_empty(), "no sound played")
	# A locked snapshot shows them in place.
	_parts.load_snapshot(snap_locked)
	await _physics_ticks(3)
	_check(_lock(GATE).is_locked() and (_station.get_node(GATE + "/Looks/padlock") as Node3D).visible, "a locked snapshot shows the padlock in place")
	_check((_station.get_node(GATE + "/Blocker") as StaticBody3D).collision_layer == Mess.LAYER_HOUSE, "and the blocker on")
	_check(_heard.is_empty(), "still no sound")


func case_lamps() -> void:
	var lights := HouseLights.new()
	add_child(lights)
	var low := _lamp(lights, PackedInt32Array([0]))
	var hall := _lamp(lights, PackedInt32Array([1]))
	var stairs := _lamp(lights, PackedInt32Array([1, 2]))
	var up := _lamp(lights, PackedInt32Array([2]))
	lights.night = true
	lights.set_level_dark(1, true)
	lights.set_level_dark(2, true)
	_check(low.visible and not hall.visible and not up.visible and not stairs.visible, "at night only the open floor's lamps are on")
	lights.set_level_dark(2, false)
	_check(stairs.visible and up.visible and not hall.visible, "a lamp lighting an open floor too stays on")
	lights.night = false
	lights.set_level_dark(2, true)
	_check(low.visible == lights.lit_by_day(low), "by day the rule is the old one")
	lights.reveal(1, 0.6, 6.0, 1.2)
	_check(lights.dark_levels & 2 == 0 and lights.dark_levels & 4 != 0, "revealing floor 1 lights it, floor 2 stays dark")
	lights._process(0.3)
	_near(hall.light_energy, 1.0, 0.01, "halfway through the fade in the lamp is half lit (of its 2.0)")
	_check(hall.visible, "and it is on")
	lights._process(0.4)
	_near(hall.light_energy, 2.0, 0.001, "lit")
	lights._process(5.0)
	_near(hall.light_energy, 2.0, 0.001, "and stays lit by day")
	_check(not up.visible, "the floor above is still dark")
	lights._process(1.5)
	_check(hall.light_energy < 2.0 and hall.light_energy > 0.0 and hall.visible, "it fades back")
	lights._process(1.0)
	_check(not hall.visible, "and follows the day's rule again: off by day (%s)" % hall.light_energy)
	_check(not lights.is_processing(), "nothing runs when no reveal is left")
	lights.free()


func case_floor_opens_all() -> void:
	await _build()
	var sheet := _station.get_node("CabinetB/DustSheet") as DustSheet
	_check(sheet.visible and _lock(DOOR).is_locked() and _lock(GATE).is_locked(), "before: sheet draped, both locks shut")
	_parts.ask(Command.new(&"zoo_fit_now", Parts.HOST, _stages.id))
	await _until(func() -> bool: return _stages.stage == 1, "the floor to open", 60)
	_check(not _lock(DOOR).is_locked() and not _lock(GATE).is_locked(), "both locks are open")
	await _until(func() -> bool: return not sheet.visible, "the sheet to be pulled off", 300)
	await _until(func() -> bool: return not _lock(DOOR).leaf().is_moving() and not _lock(GATE).leaf().is_moving(), "the leaves to stop", 600)
	# The pillar locks them again; the leaves swing back and the padlocks hang again.
	var pillar := _station.get_node("Locks/LockSwitch") as LockSwitch
	_check(pillar.prompt_title() == LockSwitch.LOCK_TITLE, "the pillar offers to lock them")
	_parts.ask(Command.new(&"switch", Parts.HOST, pillar.id))
	await _until(func() -> bool: return _lock(DOOR).is_locked() and _lock(GATE).is_locked(), "both locks to shut again")
	await _until(func() -> bool: return not _lock(GATE).leaf().is_moving(), "the gate to swing back", 600)
	_check(_leaf_angle(GATE) < 0.02, "the leaf is shut")
	_check((_station.get_node(GATE + "/Looks/padlock") as Node3D).visible and (_station.get_node(GATE + "/Looks/padlock") as Node3D).scale.x > 0.99, "the padlock hangs again")
	_check(pillar.prompt_title() == LockSwitch.OPEN_TITLE, "and the pillar offers to open them")


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
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
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_FIT_NOW
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_stages = _station.get_node("Run/Stages") as Stages
	var mess := _station.get_node("Socks/Mess") as Mess
	await _until(func() -> bool: return _player.is_on_floor() and mess.looks_of(0) != null and _stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")


func _lock(name_: String) -> FloorLock:
	return _station.get_node(name_ + "/Padlock/FloorLock") as FloorLock


## The padlock's spot at rest, in the world.
func _padlock_at(name_: String) -> Vector3:
	return (_station.get_node(name_ + "/Looks/padlock") as Node3D).global_position


## How far the leaf has swung about its pin, radians.
func _leaf_angle(name_: String) -> float:
	return absf((_station.get_node(name_ + "/Looks/leaf") as Node3D).rotation.y)


func _lamp(lights: HouseLights, levels: PackedInt32Array) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	lamp.light_energy = 2.0
	lamp.set_meta(&"lit_levels", levels)
	lights.add_child(lamp)
	lights._switch()
	return lamp


func _on_played(event: StringName, _spatial: bool, _at: Vector3, _bus: StringName) -> void:
	_heard.append(event)


func _stand(spot: Vector3) -> void:
	_player.global_position = spot  # the station is at the level's origin
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
