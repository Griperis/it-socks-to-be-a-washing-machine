## Carried things in the Hands (core/78, the carry seam of the Machine Parts and the Laundry bin), played
## alone: the zoo with its Handling station (the stand-in crate, a Carriable on the bin's HoldSlot) and
## its Hand-off station (the stand-in Teammates: peer 6 holds a Brown Sock, peer 7 holds nothing), the
## game's player a Host of one. Lines are the behaviour lists' (04 "The Laundry bins", 03 "A Stage
## completes"): the pick, the carry, the right click, the Teammate, the leaver and the load.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Handling", "HandOff"]
const HANDLING := "Stations/Handling"
const HAND_OFF := "Stations/HandOff"
const CRATE := HANDLING + "/Crate"
## The stand-ins' peer ids: the one holding a Brown Sock, and the empty-handed one.
const HOLDER := 6
const OPEN := 7
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"move_forward", &"crouch"]

var _holder_node: Node = null
var _zoo: Node3D = null
var _events: Array[Dictionary] = []
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: a left click on the crate carries it at the bin's slot (0.45 m up, 0.72 m ahead), it follows a walk and a turn, a right click on the floor lays it at the crosshair turned as it was held, its Looks eased from the Hands; pick and drop heard"},
		{"name": "hands_full", "method": "case_hands_full", "world": false,
				"title": "carrying, a Sock click is refused Hands full and the Sock stays; holding a Sock, a click on the crate is refused Hands full and it stays"},
		{"name": "carry", "method": "case_carry", "world": false,
				"title": "carried: the crate is not aimed, shows its name with no key and the corner says Drop; it goes down with the Crouch to 0.25 m; the carrier walks at the normal pace (Q2628); a right click at nowhere says Can't drop there and keeps it"},
		{"name": "teammate", "method": "case_teammate", "world": false,
				"title": "a right click aimed at a Teammate with empty Hands puts the crate in theirs (drawn at their slot); aimed at one with full Hands it lies at their feet and they read Hands full, the giver nothing"},
		{"name": "leaver_and_load", "method": "case_leaver_and_load", "world": false,
				"title": "a leaver's carried crate lies where they stood; a save and load lays a carried crate where it was last laid"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _holder_node != null:
		_holder_node.free()
		_holder_node = null
	_events.clear()
	_heard.clear()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var crate := _crate()
	var thing := _thing()
	var player := _player()
	var start := thing.global_position
	await _stand_facing(start + Vector3(0.0, 0.0, 1.3), start + Vector3.UP * 0.17)
	_check(player.aimed_part() == crate, "the crosshair is on the crate")
	_check(player.hud().prompt_text().contains("Crate"), "the crosshair names it (%s)" % player.hud().prompt_text())
	_heard.clear()
	await _press(&"pick")
	await _until(func() -> bool: return crate.holder == 1, "line: a left click with empty Hands carries it", 30)
	_check(_heard_flat(&"pick"), "the pick is heard (%s)" % [_heard])
	await _frames(2)
	_check(_at_slot(), "it rides the bin's slot in front of the carrier (%s, want %s)" % [thing.global_position, _slot_now()])
	# A walk and a turn: it follows the drawn body.
	Input.action_press(&"move_forward")
	await _physics_ticks(20)
	Input.action_release(&"move_forward")
	await _physics_ticks(4)
	player.rotation.y += 1.4
	await _frames(2)
	_check(_at_slot(), "it follows the walk and the turn (%s, want %s)" % [thing.global_position, _slot_now()])
	# Down at the crosshair, turned as held.
	var yaw := player.rotation.y
	var feet := player.global_position
	var spot := feet + Basis(Vector3.UP, yaw) * Vector3(0.0, 0.0, -1.4)
	spot.y = 0.0
	await _look_at(spot)
	_check(player.crosshair_colour() == Player.CROSSHAIR_OK, "the crosshair is white on the floor")
	_heard.clear()
	await _press(&"drop_throw")
	await _until(func() -> bool: return crate.holder == 0, "a right click puts it down", 30)
	var lying := thing.global_position
	_check(Vector2(lying.x - spot.x, lying.z - spot.z).length() < 0.12, "it lies at the crosshair (%s, aimed %s)" % [lying, spot])
	_near(lying.y, 0.0, 0.02, "it lies on the floor")
	_near(angle_difference(thing.global_rotation.y, wrapf(yaw, -PI, PI)), 0.0, 0.01, "turned as it was held")
	_check(_heard_flat(&"drop"), "the drop is heard (%s)" % [_heard])
	await _frames(1)
	var looks := thing.get_node("Looks") as Node3D
	_check(crate.putting() and looks.global_position.distance_to(lying) > 0.05, "its Looks eases from the Hands (the shared put)")
	await _until(func() -> bool: return not crate.putting(), "the put to end", 30)
	_check(looks.global_position.distance_to(lying) < 0.001, "the put ends where it lies")
	await _physics_ticks(2)
	_check(not (thing.get_node("Shape") as CollisionShape3D).disabled, "its shape is back on, lying")
	await _stand_facing(lying + Vector3(0.0, 0.0, 1.3), lying + Vector3.UP * 0.17)
	_check(player.aimed_part() == crate, "lying, it is aimed again")


func case_hands_full() -> void:
	await _build()
	var crate := _crate()
	var player := _player()
	var sock := _spot_sock(HANDLING, "Floor")
	await _pick_crate()
	await _aim_sock(sock)
	_check(player.aimed_sock == sock, "the crosshair is on a Sock")
	await _press(&"pick")
	await _frames(2)
	_check(player.message() == Player.HANDS_FULL, "a Sock click is refused Hands full (%s)" % player.message())
	_check(not _hands().items_of(1).has(sock) and crate.holder == 1, "the Sock stays, the crate is still carried")
	_check(_hands().pick_refusal(1, sock) == Hands.FULL, "the Host refuses it too: full")
	# Holding a Sock, the crate refuses.
	await _put_crate_ahead()
	await _physics_ticks(30)
	await _aim_sock(sock)
	await _press(&"pick")
	await _until(func() -> bool: return _hands().items_of(1).has(sock), "the Sock to be picked", 30)
	await _physics_ticks(30)
	var thing := _thing()
	await _stand_facing(thing.global_position + Vector3(0.0, 0.0, 1.3), thing.global_position + Vector3.UP * 0.17)
	await _press(&"pick")
	await _frames(2)
	_check(crate.holder == 0 and player.message() == Player.HANDS_FULL, "with a Sock held a click on the crate is refused Hands full (%s)" % player.message())
	crate.pick(1)
	_check(crate.holder == 0 and _last_refusal() == Carriable.FULL, "the Host refuses it too: full")


func case_carry() -> void:
	await _build()
	var crate := _crate()
	var thing := _thing()
	var player := _player()
	await _pick_crate()
	await _physics_ticks(2)
	_check(player.aimed_part() != crate, "carried, it is never aimed")
	_check(player.hud().prompt_text().contains("Crate"), "carried, the crosshair names it (%s)" % player.hud().prompt_text())
	_check(player.hud().hints_text().contains(Prompts.DROP) and not player.hud().hints_text().contains("Throw"),
			"the corner says Drop, no Throw (%s)" % player.hud().hints_text())
	# Crouched, it goes down to the floor clearance.
	Input.action_press(&"crouch")
	await _until(func() -> bool: return player.own_body().crouch >= 1.0, "the crouch to settle", 120)
	await _frames(2)
	_near(thing.global_position.y - player.global_position.y, crate.slot.floor_clearance, 0.01, "crouched, it rides at the floor clearance")
	Input.action_release(&"crouch")
	await _until(func() -> bool: return player.own_body().crouch <= 0.0, "the stand", 120)
	await _frames(2)
	_near(thing.global_position.y - player.global_position.y, crate.slot.at.y, 0.01, "standing, at 0.45 m again")
	# Q2628: no slower than the normal pace.
	Input.action_press(&"move_forward")
	await _physics_ticks(10)
	var pace := Vector2(player.velocity.x, player.velocity.z).length()
	Input.action_release(&"move_forward")
	_near(pace, player.tuning.walk_speed, 0.01, "the carrier walks at the normal pace (%.2f m/s)" % pace)
	await _physics_ticks(5)
	# Aimed at nothing: Can't drop there, still carried.
	var head := player.get_node("Head") as Node3D
	head.rotation.x = 1.3
	await _physics_ticks(2)
	_check(player.crosshair_colour() == Player.CROSSHAIR_NO, "the crosshair is red at nothing")
	await _press(&"drop_throw")
	_check(crate.holder == 1 and player.message() == Player.CANT_DROP, "Can't drop there; still carried (%s)" % player.message())


func case_teammate() -> void:
	await _build()
	var crate := _crate()
	var thing := _thing()
	var player := _player()
	await _pick_crate()
	var open := _avatar(OPEN)
	await _face_mate(open)
	await _until(func() -> bool: return player.aimed_mate == OPEN, "the empty-handed Teammate is aimed", 20)
	_heard.clear()
	await _press(&"drop_throw")
	await _until(func() -> bool: return crate.holder == OPEN, "into their empty Hands", 20)
	await _frames(2)
	var want: Transform3D = crate.carry_pose(OPEN)
	_check(thing.global_position.distance_to(want.origin) < 0.01, "drawn at their slot (%s, want %s)" % [thing.global_position, want.origin])
	_check(_heard_flat(&"drop"), "the giver's drop is heard (%s)" % [_heard])
	_check(player.message() == "", "the giver reads nothing")
	_check(_hands().carries(OPEN) == crate, "their Hands carry it")
	# Their Hands are full now: a Sock handed or caught lies at their feet.
	_check(not _hands().can_take(OPEN, _spot_sock(HAND_OFF, "Mate")), "a carrier takes no Sock")

	# A Teammate with full Hands: at their feet, they read Hands full.
	await _build()
	crate = _crate()
	thing = _thing()
	player = _player()
	await _pick_crate()
	var holder := _avatar(HOLDER)
	await _face_mate(holder)
	await _until(func() -> bool: return player.aimed_mate == HOLDER, "the full-handed Teammate is aimed", 20)
	var yaw := crate.yaw
	await _press(&"drop_throw")
	await _until(func() -> bool: return crate.holder == 0, "it goes down", 20)
	var ev := _last(Carriable.HAND_OFF)
	_check(ev.get("full", false) and int(ev.get("receiver", 0)) == HOLDER, "the answer says full, for them")
	var feet := holder.global_position
	var lying := thing.global_position
	_check(Vector2(lying.x - feet.x, lying.z - feet.z).length() < 0.01, "it lies at their feet (%s, feet %s)" % [lying, feet])
	_near(angle_difference(thing.global_rotation.y, yaw), 0.0, 0.01, "at the turn it last lay (the old)")
	_check(player.message() != Player.HANDS_FULL, "the giver does not read Hands full")


func case_leaver_and_load() -> void:
	await _build()
	var crate := _crate()
	var thing := _thing()
	await _pick_crate()
	var open := _avatar(OPEN)
	await _face_mate(open)
	await _until(func() -> bool: return _player().aimed_mate == OPEN, "the Teammate is aimed", 20)
	await _press(&"drop_throw")
	await _until(func() -> bool: return crate.holder == OPEN, "the Teammate carries it", 20)
	var turn := crate.yaw
	_parts().left(OPEN)
	_check(crate.holder == 0, "their leaving lets it go")
	var feet := open.global_position
	var lying := thing.global_position
	_check(Vector2(lying.x - feet.x, lying.z - feet.z).length() < 0.01 and absf(lying.y) < 0.02,
			"it lies where they stood (%s, feet %s)" % [lying, feet])
	_near(angle_difference(thing.global_rotation.y, turn), 0.0, 0.01, "at the turn it last lay (the old)")
	_check(_last_left().get("ok", false), "the leave is one answer")

	# Last laid at B, carried again, saved and loaded: it lies at B.
	await _physics_ticks(5)
	await _stand_facing(lying + Vector3(0.0, 0.0, 1.3), lying + Vector3.UP * 0.17)
	await _press(&"pick")
	await _until(func() -> bool: return crate.holder == 1, "carried again", 30)
	var saved := _parts().save_snapshot()
	var versions := _parts().save_versions()
	_player().global_position += Vector3(1.0, 0.0, 0.5)
	await _frames(2)
	_parts().load_save(saved, versions, "")
	await _frames(2)
	_check(crate.holder == 0, "a load lets it go (nothing is held offline)")
	_check(thing.global_position.distance_to(lying) < 0.01, "it lies where it was last laid (%s, last %s)" % [thing.global_position, lying])


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
	if _holder_node != null:
		_holder_node.free()
	_events.clear()
	_holder_node = Node.new()
	_holder_node.name = "Alone"
	add_child(_holder_node)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder_node.add_child(_zoo)
	_parts().applied.connect(func(ev: Dictionary) -> void: _events.append(ev))
	# The stand-in takes its Sock once the camera comes near (HandOffStandIn.wake_range).
	_player().global_position = (_zoo.get_node(HAND_OFF) as Node3D).global_position + Vector3(0.0, 0.0, 3.0)
	await _until(func() -> bool: return _player().is_on_floor() and _avatar(HOLDER) != null and _hands().items_of(HOLDER).size() == 1,
			"the zoo to stand, the Teammate to hold its Sock", 300)
	_player().capture_mouse()


## Stands in front of the crate where it lies and picks it up with the left click.
func _pick_crate() -> void:
	var at := _thing().global_position
	await _stand_facing(at + Vector3(0.0, 0.0, 1.3), at + Vector3.UP * 0.17)
	await _press(&"pick")
	await _until(func() -> bool: return _crate().holder == 1, "the crate to be carried", 30)


## Puts the carried crate down on the floor 1.4 m ahead.
func _put_crate_ahead() -> void:
	var player := _player()
	var spot := player.global_position + Basis(Vector3.UP, player.rotation.y) * Vector3(0.0, 0.0, -1.4)
	spot.y = 0.0
	await _look_at(spot)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _crate().holder == 0, "the crate to go down", 30)


func _aim_sock(sock: int) -> void:
	var at := _mess().box_of(sock).get_center()
	await _stand_facing(Vector3(at.x, 0.0, at.z + 1.0), at)


## Stands the player `away` m in front of Teammate `mate` (on their +z side), looking at their chest.
func _face_mate(mate: Avatar, away := 1.5) -> void:
	var feet := mate.global_position
	await _stand_facing(Vector3(feet.x, 0.0, feet.z + away), feet + Vector3.UP * 1.1)


## Stands the player at `feet`, looking at `target`.
func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	await _look_at(target)


## Turns the body and pitches the head at `target`, as the mouse would.
func _look_at(target: Vector3) -> void:
	var player := _player()
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


## Presses an action for two physics ticks, then lets it go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


## Where the slot is now from the player's drawn body.
func _slot_now() -> Vector3:
	var pose: Variant = _crate().carry_pose(1)
	return (pose as Transform3D).origin if pose is Transform3D else Vector3.INF


## Whether the crate is at the bin's slot of the player standing still: 0.45 m up, 0.72 m ahead.
func _at_slot() -> bool:
	var player := _player()
	var want := player.global_position + Basis(Vector3.UP, player.rotation.y) * Vector3(0.0, 0.45, -0.72)
	return _thing().global_position.distance_to(want) < 0.01 and _thing().global_position.distance_to(_slot_now()) < 0.01


func _heard_flat(sound: StringName) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and not bool(e[1]):
			return true
	return false


func _last(kind: StringName) -> Dictionary:
	for i in range(_events.size() - 1, -1, -1):
		if StringName(_events[i].get("kind", &"")) == kind and _events[i].get("ok", false):
			return _events[i]
	return {}


func _last_left() -> Dictionary:
	for i in range(_events.size() - 1, -1, -1):
		if StringName(_events[i].get("kind", &"")) == &"left" and StringName(_events[i].get("to", &"")) == _crate().id:
			return _events[i]
	return {}


func _last_refusal() -> String:
	for i in range(_events.size() - 1, -1, -1):
		if not _events[i].get("ok", false):
			return String(_events[i].get("reason", ""))
	return ""


func _spot_sock(station: String, spot: String) -> int:
	return (_zoo.get_node(station + "/Spots/" + spot) as SockSpot).sock


func _avatar(peer: int) -> Avatar:
	return _zoo.get_node_or_null(HAND_OFF + ("/Holder/%d" if peer == HOLDER else "/Open/%d") % peer) as Avatar


func _crate() -> Carriable:
	return _zoo.get_node(CRATE + "/Carriable") as Carriable


func _thing() -> Node3D:
	return _zoo.get_node(CRATE) as Node3D


func _mess() -> Mess:
	return LevelRuntime.of(_zoo).mess


func _hands() -> Hands:
	return LevelRuntime.of(_zoo).hands


func _parts() -> Parts:
	return LevelRuntime.of(_zoo).parts


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
