## The Radio carried and thrown (core/163; tv-and-radio.md "The Radio as a carried thing", devices.md "The
## thrown-knock rule" and "The held thing's input"), played alone: the zoo's TV and Radio station (the real
## Radio, two Socks lying on it), the encyclopedia book put beside it, its Hand-off station (stand-in
## Teammates: peer 6 holds a Sock, peer 7 nothing) and its Knockdown station (stand-in peer 5); the house for
## the lost Radio. Lines are list 13's (R20-R29) and the Answers Q2700, Q2704.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const HOUSE := "res://game/house/house.tscn"
const RADIO_SCENE := "res://game/entities/radio/radio.tscn"
const PROBE := preload("res://tests/support/held_input_probe.gd")
const KEEP := ["TvRadio", "HandOff", "Knockdown"]
const STATION := "Stations/TvRadio"
const RADIO := STATION + "/Radio"
const BOOK_SCENE := "res://game/entities/encyclopedia_book/encyclopedia_book.tscn"
const HAND_OFF := "Stations/HandOff"
const KNOCKDOWN := "Stations/Knockdown"
const HOLDER := 6
const OPEN := 7
const MATE := 5
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]

var _holder_node: Node = null
var _zoo: Node3D = null
var _house: Node = null
var _events: Array[Dictionary] = []
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the TV and Radio station a left click carries the Radio (the two Socks lying on it fall, Q2704), it rides in front of the carrier with its shapes off; the right button held to a full ring and let go toward the floor throws it (throw heard): it flies, lands with radio_land there and lies on the floor near where it was aimed, aimable again"},
		{"name": "hands_full", "method": "case_hands_full", "world": false,
				"title": "R20: with a Sock in the Hands, or the encyclopedia book, a click on the Radio reads Hands full and it stays; carrying it, a Sock click reads Hands full; a right tap puts it down where aimed, facing back at the carrier (R23)"},
		{"name": "held_input", "method": "case_held_input", "world": false,
				"title": "the held thing's input: carrying the Radio, E, the left button, the right button (with its held time) and the wheel go first to what is beside its Carriable; a used right tap is not a put down; unused, the default stands"},
		{"name": "teammate", "method": "case_teammate", "world": false,
				"title": "R24, R27: an aimed right tap hands the Radio into an empty-handed Teammate's Hands; into full Hands it lies at their feet; a leaver lets it go at their feet"},
		{"name": "knock", "method": "case_knock", "world": false,
				"title": "R26, Q2700: a full-charge Throw of the Radio at a Teammate knocks them down and bounces off in the same answer; it hits nobody again and lands"},
		{"name": "weak_bounce", "method": "case_weak_bounce", "world": false,
				"title": "R26, Q2700: a Throw under the full ring that hits a Teammate knocks nobody and bounces off to their feet, never caught (they hold nothing after)"},
		{"name": "saved", "method": "case_saved", "world": false,
				"title": "R29: a save mid-air keeps its flight (a load flies it on and it lands); a snapshot carries how long it has flown; a Guest's carried Radio is saved lying where they stood"},
		{"name": "lost_in_house", "method": "case_lost_in_house", "world": false,
				"title": "R28, Q2559: in the house, a Radio flying out of the level comes back lying in front of the washer (the return spot), with the lost pop"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_all()
	_events.clear()
	_heard.clear()
	PadRumble.reset()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var radio := _radio()
	var thing := _thing()
	var player := _player()
	var mess := _mess()
	var on_it := [_spot_sock("OnRadio"), _spot_sock("OnRadioTop")]
	for s: int in on_it:
		_check(mess.state_of(s) == Mess.State.LYING and mess.box_of(s).position.y > 0.1, "a Sock lies on the Radio (%s)" % mess.box_of(s))
	var start := thing.global_position
	await _stand_facing(start + Vector3(0.0, 0.0, 1.2), start + Vector3(0.0, 0.03, 0.05))
	_check(player.aimed_part() == radio and player.aimed_sock < 0, "the crosshair is on the Radio (sock %d)" % player.aimed_sock)
	_check(player.hud().prompt_text().contains("Radio"), "the crosshair names it Radio (%s)" % player.hud().prompt_text())
	await _press(&"pick")
	await _until(func() -> bool: return radio.holder == 1, "R20: a left click with empty Hands carries it", 30)
	await _until(func() -> bool: return mess.state_of(on_it[0]) != Mess.State.LYING or mess.box_of(on_it[0]).position.y < 0.05,
			"Q2704: the Socks lying on it fall", 120)
	await _until(func() -> bool: return mess.state_of(on_it[0]) == Mess.State.LYING and mess.state_of(on_it[1]) == Mess.State.LYING,
			"the fallen Socks to lie again", 600)
	for s: int in on_it:
		_check(mess.box_of(s).position.y < 0.06, "a fallen Sock lies on the floor now (%s)" % mess.box_of(s))
	await _frames(2)
	var pose: Variant = radio.carry_pose(1)
	_check(pose is Transform3D and thing.global_position.distance_to((pose as Transform3D).origin) < 0.01, "it rides its hold slot")
	_check((thing.get_node("Shape") as CollisionShape3D).disabled, "carried, its shape is off")
	# A full-charge Throw toward the floor 3 m ahead.
	var feet := player.global_position
	var aim := feet + Basis(Vector3.UP, player.rotation.y) * Vector3(0.0, 0.0, -3.0)
	aim.y = 0.0
	await _look_at(aim)
	_heard.clear()
	await _throw(1.0)
	await _until(func() -> bool: return radio.flying(), "R25: let go at a full ring, it flies", 10)
	_check(radio.holder == 0 and _hands().carries(1) == null, "it left the Hands")
	_check(_heard_flat(&"throw"), "the Throw is heard (%s)" % [_heard])
	_check(PadRumble.last == PadRumble.THROW, "the Throw's buzz")
	await _physics_ticks(4)
	_check(thing.global_position.y > 0.3 and thing.global_position.distance_to(feet) > 0.4, "it flies through the air (%s)" % thing.global_position)
	await _until(func() -> bool: return not radio.flying(), "it lands", 300)
	var lying := thing.global_position
	_near(lying.y, 0.0, 0.02, "it lies on the floor")
	_check(Vector2(lying.x - aim.x, lying.z - aim.z).length() < 1.5, "near where it was aimed (%s, aimed %s)" % [lying, aim])
	var land := _last(Carriable.LAND)
	_check(not land.is_empty() and _heard_at(&"radio_land", land.get("landed_at", Vector3.INF)), "radio_land is heard where it lands (%s)" % [_heard])
	await _physics_ticks(3)
	_check(not (thing.get_node("Shape") as CollisionShape3D).disabled, "lying, its shape is back")
	await _stand_facing(lying + Vector3(0.0, 0.0, 1.2), lying + Vector3.UP * 0.08)
	_check(player.aimed_part() == radio, "lying, it is aimed again")


func case_hands_full() -> void:
	await _build()
	var radio := _radio()
	var player := _player()
	var thing := _thing()
	# A Sock in the Hands.
	# Both Socks off it into the Hands (the top one first).
	for spot: String in ["OnRadioTop", "OnRadio"]:
		var sock := _spot_sock(spot)
		var at := _mess().box_of(sock).get_center()
		await _stand_facing(Vector3(at.x, 0.0, at.z + 1.0), at)
		await _press(&"pick")
		await _until(func() -> bool: return _hands().items_of(1).has(sock), "a Sock picked", 30)
		await _physics_ticks(30)
	await _stand_facing(thing.global_position + Vector3(0.0, 0.0, 1.2), thing.global_position + Vector3(0.0, 0.03, 0.05))
	_check(player.aimed_part() == radio, "the crosshair is on the Radio")
	await _press(&"pick")
	await _frames(2)
	_check(radio.holder == 0 and player.message() == Player.HANDS_FULL, "with a Sock held: Hands full (%s)" % player.message())
	_check(radio.pick_refusal(1) == Carriable.FULL, "the Host refuses it too")
	# The book in the Hands.
	await _build()
	radio = _radio()
	player = _player()
	thing = _thing()
	var book := _zoo.get_node(STATION + "/Book/Carriable") as Carriable
	_parts().apply(book.grant({"holder": 1}))
	await _physics_ticks(2)
	await _stand_facing(thing.global_position + Vector3(0.0, 0.0, 1.2), thing.global_position + Vector3.UP * 0.08)
	await _press(&"pick")
	await _frames(2)
	_check(radio.holder == 0 and player.message() == Player.HANDS_FULL, "with the book held: Hands full (%s)" % player.message())
	_parts().apply(book.grant({"holder": 0}))
	await _physics_ticks(2)
	# Carrying it: a Sock click reads Hands full; a right tap puts it down facing back.
	await _pick_radio()
	var lying_sock := _spot_sock("OnRadio")
	await _until(func() -> bool: return _mess().state_of(lying_sock) == Mess.State.LYING and _mess().box_of(lying_sock).position.y < 0.06, "the Sock fallen off it to lie", 600)
	var sat := _mess().box_of(lying_sock).get_center()
	await _stand_facing(Vector3(sat.x + 0.8, 0.0, sat.z + 0.8), sat)
	if player.aimed_sock == lying_sock:
		await _press(&"pick")
		await _frames(2)
		_check(player.message() == Player.HANDS_FULL and radio.holder == 1, "carrying, a Sock click reads Hands full")
	_check(_hands().pick_refusal(1, lying_sock) == Hands.FULL, "carrying, the Hands refuse a Sock: full")
	var spot := player.global_position + Basis(Vector3.UP, player.rotation.y) * Vector3(0.0, 0.0, -1.3)
	spot.y = 0.0
	await _look_at(spot)
	var yaw := player.rotation.y
	await _press(&"drop_throw")
	await _until(func() -> bool: return radio.holder == 0, "R23: a right tap puts it down", 30)
	_check(not radio.flying(), "a tap is no Throw")
	_check(Vector2(thing.global_position.x - spot.x, thing.global_position.z - spot.z).length() < 0.15, "where aimed (%s, %s)" % [thing.global_position, spot])
	_near(angle_difference(thing.global_rotation.y, wrapf(yaw, -PI, PI)), 0.0, 0.01, "facing back at the carrier (its front, +z, toward them)")


func case_held_input() -> void:
	await _build()
	var radio := _radio()
	var probe := PROBE.new()
	probe.name = "Probe"
	_thing().add_child(probe)
	await _pick_radio()
	probe.calls.clear()
	await _press(&"interact")
	_check(probe.got(&"interact", true) and probe.got(&"interact", false), "E pressed and released go to it (%s)" % [probe.calls])
	await _press(&"pick")
	_check(probe.got(&"pick", true) and probe.got(&"pick", false), "the left button goes to it")
	var wheel := InputEventAction.new()
	wheel.action = &"hands_next"
	wheel.pressed = true
	Input.parse_input_event(wheel)
	await _physics_ticks(2)
	_check(probe.got(&"hands_next", true), "the wheel goes to it")
	# Unused, a right tap is the default put down; its release carries the held time.
	await _look_at(_player().global_position + Basis(Vector3.UP, _player().rotation.y) * Vector3(0.0, -1.6, -1.3))
	await _press(&"drop_throw")
	await _until(func() -> bool: return radio.holder == 0, "unused, a right tap puts it down", 30)
	var released := probe.calls.filter(func(c: Array) -> bool: return c[1] == &"drop_throw" and not c[2])
	_check(released.size() == 1 and float(released[0][3]) > 0.0, "the release carries its held time (%s)" % [released])
	# Used, a right tap is not a put down.
	await _pick_radio()
	probe.uses = [&"drop_throw"]
	await _press(&"drop_throw")
	await _physics_ticks(5)
	_check(radio.holder == 1, "a used right press keeps it in the Hands")


func case_teammate() -> void:
	await _build()
	var radio := _radio()
	var player := _player()
	await _wake_hand_off()
	await _pick_radio()
	var open := _avatar(OPEN)
	await _face_mate(open)
	await _until(func() -> bool: return player.aimed_mate == OPEN, "the empty-handed Teammate is aimed", 20)
	await _press(&"drop_throw")
	await _until(func() -> bool: return radio.holder == OPEN, "R24: into their empty Hands", 30)
	# A leaver lets it go at their feet.
	_parts().left(OPEN)
	_check(radio.holder == 0, "R27: their leaving lets it go")
	var feet := open.global_position
	_check(Vector2(_thing().global_position.x - feet.x, _thing().global_position.z - feet.z).length() < 0.01, "at their feet")
	# Into full Hands: at their feet, Hands full for them.
	await _build()
	radio = _radio()
	player = _player()
	await _wake_hand_off()
	await _pick_radio()
	var holder := _avatar(HOLDER)
	await _face_mate(holder)
	await _until(func() -> bool: return player.aimed_mate == HOLDER, "the full-handed Teammate is aimed", 20)
	await _press(&"drop_throw")
	await _until(func() -> bool: return radio.holder == 0, "it goes down", 30)
	var ev := _last(Carriable.HAND_OFF)
	_check(ev.get("full", false) and int(ev.get("receiver", 0)) == HOLDER, "R24: at their feet, Hands full for them")
	var hf := holder.global_position
	_check(Vector2(_thing().global_position.x - hf.x, _thing().global_position.z - hf.z).length() < 0.01, "it lies at their feet")


func case_knock() -> void:
	await _build()
	var radio := _radio()
	var kd := _kd()
	await _pick_radio()
	await _until(func() -> bool: return kd.avatar_of(MATE) != null, "the stand-in", 60)
	var mate := kd.avatar_of(MATE)
	await _stand_facing(mate.global_position + Vector3(0.0, 0.0, 1.6), mate.global_position + Vector3.UP * 1.0)
	await _until(func() -> bool: return kd.avatar_of(MATE) != null, "the stand-in to stay", 10)
	await _throw(1.0)
	await _until(func() -> bool: return radio.flying(), "it flies", 10)
	await _until(func() -> bool: return kd.is_down(MATE), "Q2700: a full-charge Radio knocks the Teammate down", 90)
	var hit := _last(Knockdowns.KNOCK)
	_check(int(hit.get("thrower", 0)) == 1 and int(hit.get("target", 0)) == MATE, "the knock is the player's on the stand-in")
	_check((hit.get("changes", {}) as Dictionary).has(radio.id), "the bounce is in the knock's answer")
	_check(bool(radio.flight.get("hit", false)) and int(radio.flight.get("bounces", 0)) >= 1, "it bounces off the body and hits nobody again")
	var v := radio.flight_velocity(0.0)
	_check(Vector2(v.x, v.z).length() < 1.0, "C27: it bounces back off slowly (%.2f m/s)" % Vector2(v.x, v.z).length())
	_check(not _player().knocked, "the thrower is never hit")
	await _until(func() -> bool: return not radio.flying(), "it lands", 300)
	_check(radio.holder == 0 and kd.knocks == 1, "it lies; one knock")


func case_weak_bounce() -> void:
	await _build()
	var radio := _radio()
	var kd := _kd()
	await _pick_radio()
	await _until(func() -> bool: return kd.avatar_of(MATE) != null, "the stand-in", 60)
	var mate := kd.avatar_of(MATE)
	await _stand_facing(mate.global_position + Vector3(0.0, 0.0, 1.6), mate.global_position + Vector3.UP * 1.0)
	await _throw(0.5)
	await _until(func() -> bool: return kd.bounces == 1, "a weaker Throw hits the Teammate and bounces off", 90)
	await _until(func() -> bool: return not radio.flying(), "it lands", 300)
	_check(not kd.is_down(MATE) and kd.knocks == 0, "Q2700: a weaker one knocks nobody")
	_check(radio.holder == 0 and _hands().carries(MATE) == null, "never caught")
	var feet := mate.global_position
	var lying := _thing().global_position
	_check(Vector2(lying.x - feet.x, lying.z - feet.z).length() < 1.2, "it lies at their feet (%s, feet %s)" % [lying, feet])


func case_saved() -> void:
	await _build()
	var radio := _radio()
	var player := _player()
	await _pick_radio()
	await _look_at(player.global_position + Basis(Vector3.UP, player.rotation.y) * Vector3(0.0, 0.0, -4.0))
	await _throw(1.0)
	await _until(func() -> bool: return radio.flying(), "it flies", 10)
	await _physics_ticks(6)
	var snap := _parts().snapshot()
	var saved := _parts().save_snapshot()
	var versions := _parts().save_versions()
	var mine: Dictionary = saved.get(radio.id, {})
	_check((mine.get("flight", {}) as Dictionary).get("age", 0.0) > 0.05, "the save keeps its flight with its age (%s)" % [mine.get("flight")])
	var joined: Dictionary = snap.get(radio.id, {})
	_check(not (joined.get("flight", {}) as Dictionary).is_empty(), "a late joiner's snapshot carries it mid-air")
	await _until(func() -> bool: return not radio.flying(), "it lands", 300)
	_parts().load_save(saved, versions, "")
	await _frames(2)
	_check(radio.flying() and radio.flight_age() > 0.05, "loaded, it flies on mid-air")
	await _until(func() -> bool: return not radio.flying(), "and lands", 300)
	_near(_thing().global_position.y, 0.0, 0.02, "on the floor")
	# A Guest's carried Radio is saved lying where they stood.
	await _wake_hand_off()
	await _pick_radio()
	var open := _avatar(OPEN)
	await _face_mate(open)
	await _until(func() -> bool: return player.aimed_mate == OPEN, "the Teammate is aimed", 20)
	await _press(&"drop_throw")
	await _until(func() -> bool: return radio.holder == OPEN, "the Teammate carries it", 30)
	var kept: Dictionary = _parts().save_snapshot().get(radio.id, {})
	var feet := open.global_position
	var at: Vector3 = _thing().get_parent().global_transform * Vector3(kept.get("at", Vector3.INF))
	_check(int(kept.get("holder", -1)) == 0 and Vector2(at.x - feet.x, at.z - feet.z).length() < 0.01,
			"saved lying where they stood (%s, feet %s)" % [kept, feet])


func case_lost_in_house() -> void:
	_holder_node = Node.new()
	_holder_node.name = "House"
	add_child(_holder_node)
	_house = (load(HOUSE) as PackedScene).instantiate()
	var thing := (load(RADIO_SCENE) as PackedScene).instantiate() as Node3D
	thing.name = "Radio"
	_house.get_node("Systems/Devices").add_child(thing)
	var runtime := LevelRuntime.of(_house)
	_holder_node.add_child(_house)
	await _until(func() -> bool: return runtime.loading.is_lifted() and runtime.parts.is_bound and runtime.player.is_on_floor(), "the house to start", 3000)
	runtime.parts.applied.connect(func(ev: Dictionary) -> void: _events.append(ev))
	var radio := thing.get_node("Carriable") as Carriable
	var back := _house.get_node("ReturnSpot") as Node3D
	# Flying out over the level's edge, past its bounds.
	var out := runtime.mess.bounds.end + Vector3(0.5, -6.0, 0.5)
	runtime.parts.apply(radio.grant({"holder": 0, "flight": {"from": out, "vel": Vector3(1.0, 0.0, 1.0), "t0": 0.0, "by": 1,
			"charge": 1.0, "spin": Vector3.ZERO, "bounces": 0, "hit": false}}))
	_heard.clear()
	await _until(func() -> bool: return not radio.flying(), "the lost Radio to come back", 120)
	var lying := thing.global_position
	var spot := back.global_position
	_check(Vector2(lying.x - spot.x, lying.z - spot.z).length() < 0.05, "R28: back lying in front of the washer (%s, the spot %s)" % [lying, spot])
	_check(_heard_at(&"lost_pop", lying), "the lost pop there (%s)" % [_heard])
	_check(not _heard_at(&"radio_land", lying), "no landing clunk for a lost one")


# --- Helpers -------------------------------------------------------------------------------------

func _free_all() -> void:
	if _holder_node != null:
		_holder_node.free()
		_holder_node = null
	_zoo = null
	_house = null


func _build() -> void:
	_free_all()
	_events.clear()
	_holder_node = Node.new()
	_holder_node.name = "Alone"
	add_child(_holder_node)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	var book := (load(BOOK_SCENE) as PackedScene).instantiate() as Node3D
	book.name = "Book"
	book.position = Vector3(-1.5, 0.0, 0.0)
	_zoo.get_node(STATION).add_child(book)
	_holder_node.add_child(_zoo)
	_parts().applied.connect(func(ev: Dictionary) -> void: _events.append(ev))
	_player().global_position = (_zoo.get_node(STATION) as Node3D).global_position + Vector3(0.0, 0.0, 3.0)
	await _until(func() -> bool: return _player().is_on_floor() and _mess().looks_of(_spot_sock("OnRadio")) != null,
			"the zoo to stand, the Socks on the Radio to lie", 300)
	_player().capture_mouse()


## Stands in front of the Radio where it lies and picks it up with the left click.
func _pick_radio() -> void:
	var at := _thing().global_position
	await _stand_facing(at + Vector3(0.0, 0.0, 1.2), at + Vector3(0.0, 0.03, 0.05))
	await _press(&"pick")
	await _until(func() -> bool: return _radio().holder == 1, "the Radio to be carried", 30)


## Brings the player to the Hand-off station so its stand-ins wake (the holder takes its Sock).
func _wake_hand_off() -> void:
	_player().global_position = (_zoo.get_node(HAND_OFF) as Node3D).global_position + Vector3(0.0, 0.0, 3.0)
	await _until(func() -> bool: return _avatar(HOLDER) != null and _avatar(OPEN) != null and _hands().items_of(HOLDER).size() == 1,
			"the Teammates to stand, one holding its Sock", 300)


func _throw(charge: float) -> void:
	var player := _player()
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return player.charging and player.charge >= charge, "the ring to reach %.1f" % charge, 200)
	Input.action_release(&"drop_throw")
	await _physics_ticks(1)


func _face_mate(mate: Avatar, away := 1.5) -> void:
	var feet := mate.global_position
	await _stand_facing(Vector3(feet.x, 0.0, feet.z + away), feet + Vector3.UP * 1.1)


func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	await _look_at(target)


func _look_at(target: Vector3) -> void:
	var player := _player()
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _heard_flat(sound: StringName) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and not bool(e[1]):
			return true
	return false


func _heard_at(sound: StringName, at: Variant) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and bool(e[1]) and at is Vector3 and (e[2] as Vector3).distance_to(at) < 0.3:
			return true
	return false


func _last(kind: StringName) -> Dictionary:
	for i in range(_events.size() - 1, -1, -1):
		if StringName(_events[i].get("kind", &"")) == kind and _events[i].get("ok", false):
			return _events[i]
	return {}


func _spot_sock(spot: String) -> int:
	return (_zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _avatar(peer: int) -> Avatar:
	return _zoo.get_node_or_null(HAND_OFF + ("/Holder/%d" if peer == HOLDER else "/Open/%d") % peer) as Avatar


func _radio() -> Carriable:
	return _zoo.get_node(RADIO + "/Carriable") as Carriable


func _thing() -> Node3D:
	return _zoo.get_node(RADIO) as Node3D


func _kd() -> Knockdowns:
	return _parts().find(func(p: Part) -> bool: return p is Knockdowns) as Knockdowns


func _mess() -> Mess:
	return LevelRuntime.of(_zoo).mess


func _hands() -> Hands:
	return LevelRuntime.of(_zoo).hands


func _parts() -> Parts:
	return LevelRuntime.of(_zoo).parts


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
