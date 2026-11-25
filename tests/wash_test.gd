## The knockdown wash (core/98, docs/architecture/washer.md "The knockdown wash", list 05 "The knockdown
## wash") played alone: the zoo with its Knockdown station and the washing machine in it. The real path: the
## stand-in Teammate lies by the machine, the player aims at it with empty Hands, holds the left button to
## drag it by the feet, and lets go within 1.5 m of the door; the body goes in (hidden, out of play), the
## drum sloshes, 3 s later the door bursts and it tumbles out head first, knocked down 2 s, and gets up.
## The washed player's own view (the local player held in the drum, their view turning, the HUD hidden, the
## fade) is checked by the Host's own answer for the local player, as the station has one stand-in only.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Knockdown"]
const STATION := "Stations/Knockdown"
const MATE := 5
const SILENT := "res://tests/fixtures/cutscene_silent.tres"
const ACTIONS: Array[StringName] = [&"pick", &"move_back", &"move_forward"]

var _holder: Node = null
var _zoo: Node3D = null
var _events: Array[Dictionary] = []
var _heard: Array[StringName] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "core/98 real path: drag the lying Teammate to the door and let go with the left button: the body goes in (hidden, out of play, sloshing, the slam), spins 3 s, the door bursts open and it tumbles out head first in front of the door, knocked down 2 s, and gets up"},
		{"name": "lies_there", "method": "case_lies_there", "world": false,
				"title": "core/98 a body let go far from the door only lies there; one let go at a busy machine's door (someone spins, or a cutscene plays) only lies there, silently"},
		{"name": "own_view", "method": "case_own_view", "world": false,
				"title": "core/98 the washed player's own view: held in the machine, input and HUD off, the drum's camera turning, black over the last 0.4 s, then out: knocked down, their camera back, fading in over 0.6 s"},
		{"name": "ends", "method": "case_ends", "world": false,
				"title": "core/98 a cutscene's end ends a wash with no tumble (respawn at the washer's spawn, Q759); a leaver's wash ends too; nothing is saved"},
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


func _on_played(sound: StringName, _spatial: bool, _at: Vector3, _bus: StringName) -> void:
	_heard.append(sound)


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var kd := _kd()
	var mate := _mate()
	var wash := _wash()
	var view := _view()
	var player := _player()
	_check(not kd.is_washed(MATE) and not wash.busy(), "nobody spins at first")
	var door := _door()
	var front := wash.front_of()
	# The Teammate lies 2.4 m out from the door, as the network would have moved it there, and is knocked down.
	await _put_mate(door + front * 2.4)
	await _physics_ticks(3)
	_parts().ask(Command.new(Knockdowns.KNOCK, Parts.HOST, kd.id, {"target": MATE, "thrower": 1,
			"push": front, "high": 0.8, "side": 0.0, "at": mate.global_position + Vector3.UP * 1.3}))
	await _until(func() -> bool: return kd.is_down(MATE), "the Teammate to be knocked down", 30)
	await _physics_ticks(60)
	var mid := mate.ragdoll.point_at(0.8)
	await _stand_facing(mid - front * 1.2 - Vector3.UP * mid.y, mid)
	await _until(func() -> bool: return player.aimed_body == MATE, "the lying body to be the aimed one", 30)
	Input.action_press(&"pick")
	await _until(func() -> bool: return kd.dragger_of(MATE) == 1, "the left button grabs the body", 20)
	# Walk back toward the door: the feet are pulled after the dragger. Let go once they are by the door.
	Input.action_press(&"move_back")
	await _until(func() -> bool: return wash.by_door(mate.ragdoll.feet()), "the dragged feet to come within 1.5 m of the door", 400)
	Input.action_release(&"move_back")
	Input.action_release(&"pick")
	await _until(func() -> bool: return wash.peer == MATE, "the let go by the door sends the body in", 30)
	var go := _last(Knockdowns.LET_GO)
	_check(String(go.get("why", "")) == Knockdowns.WASH, "the drag ended by the wash")
	var spun_at := Engine.get_physics_frames()
	_check(not kd.is_down(MATE) and kd.is_washed(MATE), "its knockdown gave way to the wash: out of play")
	await _physics_ticks(2)
	_check(not mate.visible and mate.washed, "its avatar is not drawn")
	_check(mate.mate.collision_layer == 0, "its Mate capsule is off: nothing to bump")
	_check(_hands().is_down(MATE), "nothing can be handed to it")
	_check(kd.decide(Command.new(Knockdowns.GRAB, 1, kd.id, {"target": MATE})).get("reason", "") == Knockdowns.NOT_DOWN,
			"nothing can grab it")
	_check(kd.decide(Command.new(Knockdowns.KNOCK, Parts.HOST, kd.id, {"target": MATE, "thrower": 1, "push": front,
			"high": 0.5, "side": 0.0, "at": door})).get("reason", "") == Knockdowns.ALREADY, "nothing can hit it")
	_check(view.sloshing(), "the drum sloshes")
	_check(view.going_in() and view.slider.visible, "it slides in as a blob in its colour")
	await _until(func() -> bool: return view.slams >= 1, "the door slams shut", 60)
	_check(_heard.has(&"wash_slam"), "wash_slam is heard at the porthole")
	await _until(func() -> bool: return view.blob.visible, "the blob tumbles behind the porthole", 60)
	_check(view.looks.spin > 1.0, "the drum turns at 1.2 turns a second (%.2f)" % view.looks.spin)
	_check(wash.busy(), "the machine is busy meanwhile")
	await _until(func() -> bool: return wash.peer == 0, "the spin to run out", 400)
	var spun := float(Engine.get_physics_frames() - spun_at) / Engine.physics_ticks_per_second
	_near(spun, 3.0, 0.45, "it spun 3 s (%.2f)" % spun)
	await _until(func() -> bool: return kd.is_down(MATE), "they tumble out knocked down", 30)
	_check(not view.sloshing(), "the slosh stops")
	_check(view.bursting(), "the door bursts open")
	_check(_heard.count(&"wash_slam") >= 2, "the slam is heard again at the burst")
	_check(mate.visible and not mate.washed, "its avatar is drawn again")
	_near(kd.left_of(MATE), 2.0, 0.2, "knocked down for 2 s")
	await _physics_ticks(4)
	_check(mate.ragdoll.phase == Ragdoll.Phase.DOWN and mate.ragdoll.simulating, "the Host simulates the tumble")
	var entry := kd.entry_of(MATE)
	var feet0: Vector3 = entry["at"]
	var out0 := (feet0 - door).dot(front)
	_check(out0 > 0.1 and out0 < 0.6, "the feet start just out of the door's front (%.2f m)" % out0)
	await _physics_ticks(10)
	var tilt := rad_to_deg((mate.ragdoll.point_at(1.7) - mate.ragdoll.feet()).angle_to(Vector3.UP))
	_check(tilt > 45.0, "it comes out tipped over, head first (%.0f degrees)" % tilt)
	var head := mate.ragdoll.point_at(1.7)
	_check((head - mate.ragdoll.feet()).dot(front) > 0.3, "the head leads out of the door")
	await _until(func() -> bool: return mate.ragdoll.feet().distance_to(feet0) > 0.8, "every bone is flung out of the door", 90)
	_check((mate.ragdoll.feet() - door).dot(front) > 0.6, "it lies in front of the door")
	await _until(func() -> bool: return mate.ragdoll.phase == Ragdoll.Phase.UP and not kd.is_down(MATE), "it gets up", 400)
	_check(not wash.busy(), "the machine is free again")
	await _until(func() -> bool: return not view.bursting(), "the door swings shut", 120)


func case_lies_there() -> void:
	await _build()
	var kd := _kd()
	var mate := _mate()
	var wash := _wash()
	var door := _door()
	var front := wash.front_of()
	# Far from the door.
	await _put_mate(door + front * 3.4)
	await _physics_ticks(3)
	_parts().ask(Command.new(Knockdowns.KNOCK, Parts.HOST, kd.id, {"target": MATE, "thrower": 1,
			"push": front, "high": 0.8, "side": 0.0, "at": mate.global_position + Vector3.UP * 1.3}))
	await _until(func() -> bool: return kd.is_down(MATE), "knocked down", 30)
	await _physics_ticks(60)
	var mid := mate.ragdoll.point_at(0.8)
	await _stand_facing(mid - front * 1.2 - Vector3.UP * mid.y, mid)
	await _until(func() -> bool: return _player().aimed_body == MATE, "the lying body to be the aimed one", 30)
	Input.action_press(&"pick")
	await _until(func() -> bool: return kd.dragger_of(MATE) == 1, "grabbed", 20)
	Input.action_release(&"pick")
	await _until(func() -> bool: return kd.dragger_of(MATE) == -1, "let go", 20)
	_check(String(_last(Knockdowns.LET_GO).get("why", "")) == Knockdowns.DROP, "a drop far from the door is a drop")
	_check(wash.peer == 0 and kd.is_down(MATE), "it only lies there")
	# By the door of a busy machine: someone spins already.
	_parts().apply(wash.grant(wash.take_in(1, door + front * 0.5)))
	_check(wash.busy() and wash.peer == 1, "someone spins")
	var rag := mate.ragdoll
	_check(wash.take_in(MATE, rag.feet()).is_empty(), "a second body is not taken in")
	_parts().apply(wash.grant({"peer": 0, "spin_left": 0.0}))
	# By the door while a cutscene plays.
	_parts().apply(_rt().cutscenes.start(SILENT))
	_check(wash.busy() and wash.take_in(MATE, door).is_empty(), "no body goes in while a cutscene plays")
	await _physics_ticks(2)
	_check(wash.peer == 0 and kd.is_down(MATE), "it only lies there, silently")
	_check(not _heard.has(&"wash_slam"), "no slam was heard")


func case_own_view() -> void:
	await _build()
	var kd := _kd()
	var wash := _wash()
	var view := _view()
	var player := _player()
	var door := _door()
	var front := wash.front_of()
	_stand_at(door + front * 1.0)
	await _physics_ticks(3)
	var hud: Hud = player.hud()
	_check(hud.visible, "the HUD shows")
	# The Host's answer for the local player's own wash (the station's one stand-in cannot drag it).
	_parts().apply(wash.grant(wash.take_in(1, door + front * 0.6)))
	await _physics_ticks(2)
	_check(player.is_washed() and view.is_local(), "the player is held in the drum")
	_check(not hud.visible, "the HUD is hidden (Q991)")
	_check(view.camera.current, "the view is the drum's")
	_check(player.global_position.distance_to(wash.get_parent().global_position) < 0.05, "the body is held in the machine")
	var eye := view.camera.global_position
	var thing := wash.get_parent() as Node3D
	_check(eye.distance_to(thing.global_transform * Vector3(0.0, 0.42, 0.12)) < 0.01, "the eyes sit in the drum")
	var up0 := view.camera.global_basis.y
	await _physics_ticks(20)
	_check(view.camera.global_basis.y.angle_to(up0) > 0.5, "the view turns with the drum")
	_check(view.black() < 0.05, "the screen is clear while it spins")
	await _until(func() -> bool: return wash.left_of() < 0.2, "the last 0.4 s of the wash", 400)
	_check(view.black() > 0.4, "the screen is going black (%.2f)" % view.black())
	await _until(func() -> bool: return wash.peer == 0, "the spin to run out", 100)
	await _physics_ticks(2)
	_check(kd.is_down(1) and player.knocked, "the player tumbles out knocked down")
	_check(not player.is_washed() and not view.camera.current, "the drum's view is gone")
	_check(player.camera().current, "their own camera is back")
	_check(hud.visible, "the HUD returns")
	_check(view.black() > 0.5, "the screen fades in from black (%.2f)" % view.black())
	_near(kd.left_of(1), 2.0, 0.2, "knocked down for 2 s")
	await _until(func() -> bool: return view.black() < 0.02, "the fade in to finish", 120)


func case_ends() -> void:
	await _build()
	var kd := _kd()
	var wash := _wash()
	var door := _door()
	var front := wash.front_of()
	var rt := _rt()
	_parts().apply(wash.grant(wash.take_in(1, door + front * 0.6)))
	await _physics_ticks(2)
	_check(wash.peer == 1, "the local player spins")
	_parts().apply(rt.cutscenes.start(SILENT))
	await _until(func() -> bool: return rt.cutscene_player.phase == CutscenePlayer.Phase.HOLDING, "the cutscene's timeline to run out", 400)
	_check(wash.peer == 1, "the wash is held while a cutscene plays (no tumble)")
	_check(not kd.is_down(1), "nobody lies down")
	await _until(func() -> bool: return rt.cutscene_player.phase == CutscenePlayer.Phase.IDLE, "the Host's end", 60)
	await _physics_ticks(3)
	_check(wash.peer == 0 and not kd.is_down(1), "the cutscene's end ended the wash with no tumble (Q759)")
	_check(not _player().is_washed() and _player().hud().visible, "the player and the HUD are back")
	var spawns := wash.get_parent().get_node("Spawns")
	var at_spawn := false
	for s: Node3D in spawns.get_children():
		at_spawn = at_spawn or s.global_position.distance_to(_player().global_position) < 0.3
	_check(at_spawn, "the player stands at a washer spawn")
	# A leaver's wash ends with no tumble too.
	_parts().apply(wash.grant(wash.take_in(7, door + front * 0.6)))
	_check(wash.peer == 7, "a Teammate spins")
	_parts().left(7)
	_check(wash.peer == 0 and not kd.is_down(7), "a leaver's wash ended with no tumble")
	_check(wash.save_state().is_empty(), "nothing is saved")


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
	await _until(func() -> bool: return _player().is_on_floor() and _mate() != null, "the zoo to stand")
	_player().capture_mouse()


func _put_mate(at: Vector3) -> void:
	var mate := _mate()
	var space := mate.get_parent() as Node3D
	mate.pose_position = space.to_local(Vector3(at.x, 0.0, at.z))
	await _until(func() -> bool: return Vector2(mate.global_position.x - at.x, mate.global_position.z - at.z).length() < 0.05,
			"the Teammate to stand where it was put")


func _stand_at(feet: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


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


func _last(kind: StringName) -> Dictionary:
	for i in range(_events.size() - 1, -1, -1):
		if StringName(_events[i].get("kind", &"")) == kind and _events[i].get("ok", false):
			return _events[i]
	return {}


func _door() -> Vector3:
	return (_zoo.get_node(STATION + "/Washer/Door") as Node3D).global_position


func _wash() -> WasherWash:
	return _zoo.get_node(STATION + "/Washer/Wash") as WasherWash


func _view() -> WashView:
	return _zoo.get_node(STATION + "/Washer/WashView") as WashView


func _rt() -> LevelRuntime:
	return LevelRuntime.of(_zoo)


func _kd() -> Knockdowns:
	return _rt().knockdowns


func _hands() -> Hands:
	return _rt().hands


func _parts() -> Parts:
	return _rt().parts


func _player() -> Player:
	return _rt().player


func _mate() -> Avatar:
	return _zoo.get_node_or_null(STATION + "/Teammate/5") as Avatar
