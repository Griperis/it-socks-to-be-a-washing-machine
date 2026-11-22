## coop/10 played alone (list 04, approved by Q2496): the zoo with its Knockdown station, the game's player
## a Host of one, and the station's stand-in Teammate (peer 5), moved only as a real Teammate's pose
## moves it. A full-charge Throw knocks it down as a Godot physical-bone ragdoll; a weaker one never does;
## it gets up 5.5 s later where it lies; with empty Hands the player drags it by the feet. Lines are named
## by their section letter and number in docs/migration/m06-lists/04-knockdown.md.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Knockdown"]
const STATION := "Stations/Knockdown"
## The stand-in Teammate's peer id.
const MATE := 5
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"move_back", &"move_forward", &"jump"]

var _holder: Node = null
var _zoo: Node3D = null
var _events: Array[Dictionary] = []
## Every spatial sound played: [name, where].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path_alone", "method": "case_real_path_alone", "world": false,
				"title": "coop/10 real path alone: pick a Sock at the station, hold the right button to a full ring, release at the stand-in: it falls as a ragdoll (A1, A2, E39-E42, E61, E64), the item bounces back (C27), knockdown is heard at the hit (M148), it stands up 5.5 s later where it lies, facing its way (G79-G86), and can be knocked again at once (G87)"},
		{"name": "weak_throw", "method": "case_weak_throw", "world": false,
				"title": "coop/10 A1: a Throw under the full ring hits the stand-in and knocks nobody down"},
		{"name": "drag_alone", "method": "case_drag_alone", "world": false,
				"title": "coop/10 H91-H96, H99, H103, H104: aim at the lying stand-in with empty Hands: Hold: Drag; the held left button drags it by the feet at 0.6 of the pace, scraping; let go it lies; a drag ends as it rises"},
		{"name": "commands", "method": "case_commands", "world": false,
				"title": "coop/10 B16, B17, B26, H94, H112: the Host refuses a knock of the thrower, of a body already down, of nobody; a grab with full Hands, of a standing body, twice; a struggle of nobody dragged"},
		{"name": "mate_capsule", "method": "case_mate_capsule", "world": false,
				"title": "coop/10 E49, E52: a standing avatar's Mate capsule is on the Mate layer and off while it lies; the player bumps the lying body instead of walking through it"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _holder != null:
		_holder.free()
		_holder = null
	_events.clear()
	_heard.clear()
	PadRumble.reset()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	if spatial:
		_heard.append([sound, at])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path_alone() -> void:
	await _build()
	var kd := _kd()
	var mate := _mate()
	var hands := _hands()
	var sock := _spot_sock("SockA")
	await _pick(sock)
	var player := _player()
	var yaw_before := mate.pose_yaw
	await _stand_facing(mate.global_position + Vector3(0.0, 0.0, 1.3), mate.global_position + Vector3.UP * 1.25)
	await _throw(1.0)
	await _until(func() -> bool: return hands.items_of(1).is_empty(), "the Sock to leave the Hands", 10)
	await _until(func() -> bool: return kd.is_down(MATE), "A2: the full-charge Throw of a loose Sock knocks the stand-in down", 90)
	var hit := _last(Knockdowns.KNOCK)
	_check(int(hit.get("thrower", 0)) == 1 and int(hit.get("target", 0)) == MATE, "the knock is the player's on the stand-in")
	var body := _mess().moving_body(sock)
	if body != null:
		var v := body.linear_velocity
		_check(Vector2(v.x, v.z).length() < 0.6, "C27: the item bounces back off the body slowly (%.2f m/s sideways)" % Vector2(v.x, v.z).length())
	_check(_heard_at(&"knockdown", hit.get("at", Vector3.INF), 0.05), "M148: knockdown is heard at the hit point (%s)" % [_heard])
	_check(PadRumble.last != PadRumble.KNOCK, "M149: no knock rumble here: the stand-in was knocked, not this player")
	_near(kd.left_of(MATE), 5.5, 0.2, "E39: down for 5.5 s")
	await _frames(2)
	_check(mate.ragdoll.phase == Ragdoll.Phase.DOWN and mate.ragdoll.simulating, "E40, K141: the ragdoll exists and the Host simulates it")
	_check(mate.looks.ragdolled, "E42, E64: the Looks copies the ragdoll")
	_check(mate.mate.collision_layer == 0, "E52: its Mate capsule is off while it lies")
	_check(not player.knocked, "B16: the thrower is not knocked")
	await _until(func() -> bool: return _topple(mate) > 45.0, "E61: the body lies over past 45 degrees", 150)
	print("KNOCK alone: lies over %.0f degrees, feet %s" % [_topple(mate), mate.ragdoll.feet()])
	await _until(func() -> bool: return mate.ragdoll.phase == Ragdoll.Phase.RISING, "G80: the rise starts at 0.6 s left", 400)
	_near(kd.left_of(MATE), 0.6, 0.1, "G80: at 0.6 s left")
	var lay := mate.ragdoll.feet()
	await _until(func() -> bool: return mate.ragdoll.phase == Ragdoll.Phase.UP, "G86: it stands at the end", 60)
	_check(not mate.looks.ragdolled, "G86: the avatar stands again")
	_check(mate.mate.collision_layer == Ragdoll.MATE_LAYER, "E52: its Mate capsule is back")
	var stood := mate.global_position
	_check(Vector2(stood.x - lay.x, stood.z - lay.z).length() < 0.3 and absf(stood.y) < 0.05,
			"G82, G85: it stands where its feet lay, on the floor (%s, lay %s)" % [stood, lay])
	_near(mate.pose_yaw, yaw_before, 0.001, "G83: facing its own way")
	_parts().ask(Command.new(Knockdowns.KNOCK, Parts.HOST, kd.id, {"target": MATE, "thrower": 1,
			"push": Vector3.FORWARD, "high": 0.5, "side": 0.0, "at": mate.global_position}))
	_check(kd.is_down(MATE), "G87: no immunity: it is knocked again at once")


func case_weak_throw() -> void:
	await _build()
	var kd := _kd()
	var mate := _mate()
	var sock := _spot_sock("SockB")
	await _pick(sock)
	await _stand_facing(mate.global_position + Vector3(0.0, 0.0, 1.0), mate.global_position + Vector3.UP * 1.3)
	await _throw(0.6)
	var passed := false
	for _i in 90:
		await _physics_ticks(1)
		var b := _mess().moving_body(sock)
		if b != null and Knockdowns.touches(b.global_position, 0.15, mate.global_position, 1.7, 0.3):
			passed = true
	_check(passed, "the weaker Throw passes through the stand-in's body")
	_check(not kd.is_down(MATE) and kd.knocks == 0, "A1: a weaker Throw never knocks down")


func case_drag_alone() -> void:
	await _build()
	var kd := _kd()
	var mate := _mate()
	var player := _player()
	_knock_mate(Vector3.FORWARD)
	await _physics_ticks(90)
	var mid := mate.ragdoll.point_at(0.8)
	await _stand_facing(mid + Vector3(1.4, 0.0, 0.0) - Vector3.UP * mid.y, mid)
	await _until(func() -> bool: return player.aimed_body == MATE, "H92: the lying body is the aimed one", 20)
	await _physics_ticks(2)
	_check(player.hud().prompt_text().contains(Prompts.DRAG), "H91: the crosshair says Hold: Drag (%s)" % player.hud().prompt_text())
	Input.action_press(&"pick")
	await _until(func() -> bool: return kd.dragger_of(MATE) == 1, "H93, H95: the left button grabs the body", 10)
	await _physics_ticks(3)
	_check(_mess().states.count(Mess.State.HELD) == 0, "H93: the click picked nothing else")
	var from := player.global_position
	var feet_from := mate.ragdoll.feet()
	Input.action_press(&"move_back")
	await _physics_ticks(60)
	Input.action_release(&"move_back")
	var walked := from.distance_to(player.global_position)
	_near(walked, player.tuning.walk_speed * kd.tuning.drag_speed * 1.0, 0.35, "H95: the dragger walks at 0.6 of the pace (%.2f m in 1 s)" % walked)
	var hold: Vector3 = kd.hold_of(1)
	await _physics_ticks(20)
	_check(mate.ragdoll.feet().distance_to(feet_from) > 0.8, "H99: the feet are pulled after the dragger (%.2f m)" % mate.ragdoll.feet().distance_to(feet_from))
	_check(mate.ragdoll.feet().distance_to(kd.hold_of(1)) < 0.8, "H98, H99: the feet are near the hold point (%.2f m from %s)" % [mate.ragdoll.feet().distance_to(kd.hold_of(1)), hold])
	_check(mate.scrapes >= 1 and _heard_count(&"drag_scrape") >= 1, "H103: drag_scrape plays as the feet slide (%d)" % mate.scrapes)
	Input.action_release(&"pick")
	await _until(func() -> bool: return kd.dragger_of(MATE) == -1, "H96: let go, the body drops", 10)
	_check(String(_last(Knockdowns.LET_GO).get("why", "")) == Knockdowns.DROP, "H108: the drag ended by a drop")
	await _stand_facing(mate.ragdoll.point_at(0.8) + Vector3(1.4, 0.0, 0.0) - Vector3.UP * mate.ragdoll.point_at(0.8).y, mate.ragdoll.point_at(0.8))
	await _until(func() -> bool: return player.aimed_body == MATE, "the lying body aimed again", 20)
	Input.action_press(&"pick")
	await _until(func() -> bool: return kd.dragger_of(MATE) == 1, "grabbed again (%s)" % [_events.slice(-3)], 10)
	await _until(func() -> bool: return kd.is_rising(MATE), "the rise", 400)
	await _until(func() -> bool: return not kd.drags.has(MATE), "H104: the drag ends as it rises", 5)
	_check(String(_last(Knockdowns.RELEASE).get("why", "")) == Knockdowns.UP, "H108: the drag ended by the rise (up)")
	Input.action_release(&"pick")


func case_commands() -> void:
	await _build()
	var kd := _kd()
	var parts := _parts()
	var mate := _mate()
	var knock := func(target: int, thrower: int) -> Dictionary:
		return parts.answer(Command.new(Knockdowns.KNOCK, Parts.HOST, kd.id, {"target": target, "thrower": thrower,
				"push": Vector3.FORWARD * 3.0, "high": 4.0, "side": -9.0, "at": mate.global_position}))
	_check(str(knock.call(MATE, MATE).get("reason", "")) == Knockdowns.SELF, "B16: the thrower is never knocked")
	_check(str(knock.call(77, 1).get("reason", "")) == Knockdowns.GONE, "B26: nobody of that peer, no knock")
	var guest_knock := parts.answer(Command.new(Knockdowns.KNOCK, 7, kd.id, {"target": MATE, "thrower": 7,
			"push": Vector3.FORWARD, "high": 0.5, "side": 0.0, "at": Vector3.ZERO}))
	_check(not guest_knock.get("ok", false), "B23: only the Host decides a knock")
	var ev: Dictionary = knock.call(MATE, 1)
	_check(ev.get("ok", false), "a knock of the stand-in is granted")
	var entry: Dictionary = ev["changes"][kd.id]["down"][MATE]
	_check((entry["push"] as Vector3).is_equal_approx(Vector3.FORWARD) and is_equal_approx(float(entry["high"]), 1.0)
			and is_equal_approx(float(entry["side"]), -1.0), "B25: push made unit along the floor, high and side clamped")
	parts.apply(ev)
	_check(str(knock.call(MATE, 1).get("reason", "")) == Knockdowns.ALREADY, "B17: a body already down is not knocked again")
	_check(str(parts.answer(Command.new(Knockdowns.STRUGGLE, MATE, kd.id, {})).get("reason", "")) == Knockdowns.NOTHING, "a struggle of nobody dragged is refused")
	_check(str(parts.answer(Command.new(Knockdowns.GRAB, 1, kd.id, {"target": 1})).get("reason", "")) == Knockdowns.SELF, "H94: nobody grabs themselves")
	_check(str(parts.answer(Command.new(Knockdowns.GRAB, 1, kd.id, {"target": 9})).get("reason", "")) == Knockdowns.NOT_DOWN, "H94: a standing body is not grabbed")
	var sock := _spot_sock("SockA")
	await _pick(sock)
	_player().global_position = mate.ragdoll.feet() + Vector3(1.0, 0.0, 0.0)
	await _physics_ticks(2)
	_check(str(parts.answer(Command.new(Knockdowns.GRAB, 1, kd.id, {"target": MATE})).get("reason", "")) == Knockdowns.HANDS, "H94: not with something in the Hands")
	_hands().drop(1, _player().global_position + Vector3(0.0, 0.0, -0.6), Vector3.UP)
	await _until(func() -> bool: return _hands().items_of(1).is_empty(), "the Hands to empty", 30)
	var grant := parts.answer(Command.new(Knockdowns.GRAB, 1, kd.id, {"target": MATE}))
	_check(grant.get("ok", false), "a grab with empty Hands, near, is granted (%s)" % str(grant.get("reason", "")))
	_player().set("_grab_held", true)  # the left button is held (else the answer lets go at once, H96)
	parts.apply(grant)
	_check(str(parts.answer(Command.new(Knockdowns.GRAB, 9, kd.id, {"target": MATE})).get("reason", "")) == Knockdowns.TAKEN, "H112: a body dragged already is taken")
	_player().global_position = Vector3(50.0, 0.0, 50.0)
	await _physics_ticks(2)
	parts.apply(parts.answer(Command.new(Knockdowns.LET_GO, 1, kd.id, {})))
	_check(str(parts.answer(Command.new(Knockdowns.GRAB, 1, kd.id, {"target": MATE})).get("reason", "")) == Knockdowns.FAR, "H94: not from far away")


func case_mate_capsule() -> void:
	await _build()
	var mate := _mate()
	var player := _player()
	_check(mate.mate.collision_layer == Ragdoll.MATE_LAYER and mate.mate.collision_mask == 0, "E52: the standing body's Mate capsule is on the Mate layer and meets nothing itself")
	_check(player.collision_mask & Ragdoll.LAYER, "E49: the player's body meets lying bodies")
	_knock_mate(Vector3.FORWARD)
	await _physics_ticks(100)
	_check(mate.mate.collision_layer == 0, "E52: off while it lies")
	var mid := mate.ragdoll.point_at(0.6)
	player.global_position = Vector3(mid.x + 1.5, 0.0, mid.z)
	player.velocity = Vector3.ZERO
	await _stand_facing(player.global_position, Vector3(mid.x, 1.6, mid.z))
	Input.action_press(&"move_forward")
	await _physics_ticks(60)
	Input.action_release(&"move_forward")
	var gap := Vector2(player.global_position.x - mid.x, player.global_position.z - mid.z).length()
	_check(gap > 0.3 or player.global_position.y > 0.2, "E49: the player bumps the lying body instead of walking through it (%.2f m from its middle, %.2f up)" % [gap, player.global_position.y])


# --- Helpers -------------------------------------------------------------------------------------

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
	_parts().applied.connect(func(ev: Dictionary) -> void: _events.append(ev))
	await _until(func() -> bool: return _player().is_on_floor() and _mess().looks_of(_spot_sock("SockA")) != null and _mate() != null,
			"the zoo to stand, its Socks to lie")
	_player().capture_mouse()


func _knock_mate(push: Vector3) -> void:
	var mate := _mate()
	_parts().ask(Command.new(Knockdowns.KNOCK, Parts.HOST, _kd().id, {"target": MATE, "thrower": 1,
			"push": push, "high": 0.8, "side": 0.0, "at": mate.global_position + Vector3.UP * 1.3}))


func _pick(sock: int) -> void:
	var at := _mess().box_of(sock).get_center()
	await _stand_facing(Vector3(at.x, 0.0, at.z + 1.0), at)
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _until(func() -> bool: return _hands().items_of(1).has(sock), "Sock %d to be picked" % sock, 60)


## Stands the player at `feet`, looking at `target`.
func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var head := player.get_node("Head") as Node3D
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


## Holds the drop button until the ring shows `charge`, then lets go.
func _throw(charge: float) -> void:
	var player := _player()
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return player.charging and player.charge >= charge, "the ring to reach %.1f" % charge, 200)
	Input.action_release(&"drop_throw")
	await _physics_ticks(1)


## How far the body lies over: the line from its feet to its head's top against upright, in degrees.
func _topple(a: Avatar) -> float:
	return rad_to_deg((a.ragdoll.point_at(1.7) - a.ragdoll.feet()).angle_to(Vector3.UP))


func _heard_at(sound: StringName, at: Variant, within: float) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and at is Vector3 and (e[1] as Vector3).distance_to(at) <= within:
			return true
	return false


func _heard_count(sound: StringName) -> int:
	var n := 0
	for e: Array in _heard:
		if StringName(e[0]) == sound:
			n += 1
	return n


func _last(kind: StringName) -> Dictionary:
	for i in range(_events.size() - 1, -1, -1):
		if StringName(_events[i].get("kind", &"")) == kind and _events[i].get("ok", false):
			return _events[i]
	return {}


func _spot_sock(spot: String) -> int:
	return (_zoo.get_node(STATION + "/Spots/" + spot) as SockSpot).sock


func _kd() -> Knockdowns:
	return _zoo.get_node("Socks/Knockdowns") as Knockdowns


func _mess() -> Mess:
	return _zoo.get_node("Socks/Mess") as Mess


func _hands() -> Hands:
	return _zoo.get_node("Socks/Hands") as Hands


func _parts() -> Parts:
	return _zoo.get_node("Parts") as Parts


func _player() -> Player:
	return _zoo.get_node("Player") as Player


func _mate() -> Avatar:
	return _zoo.get_node_or_null(STATION + "/Teammate/5") as Avatar
