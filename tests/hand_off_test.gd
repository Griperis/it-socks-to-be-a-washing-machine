## core/42 played alone (list 02, docs/migration/m3-lists/02-hand-off.md, answered by Q2588-Q2590): the zoo
## with its Hand-off station, the game's player a Host of one, and the station's two stand-in Teammates
## (peer 6 holds a Brown Sock and is full; peer 7 holds nothing), moved only as a real Teammate's pose
## moves them. Lines are named by their number in the list.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["HandOff"]
const STATION := "Stations/HandOff"
## The stand-ins' peer ids: the one holding a Brown Sock, and the empty-handed one.
const HOLDER := 6
const OPEN := 7
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw"]

var _holder_node: Node = null
var _zoo: Node3D = null
var _events: Array[Dictionary] = []
## Every sound played: [name, spatial, where].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "core/42 real path: pick the Brown Sock, aim at the Teammate holding its mate (outlined, crosshair not red, the corner still Drop), a short right click: the Pair is made in their Hands, gone from the player's, flown from the player's hand over 0.3 s with the sparkle at their hand, drop and pair heard (lines 1, 6-9, 12, 18-21, 25-28, 30-32); then a Charcoal Sock: refused, Not their mate, still held, no drop (lines 9, 14, 16)"},
		{"name": "pair_full_and_taken", "method": "case_pair_full_and_taken", "world": false,
				"title": "core/42 lines 11, 18, 20, 23, 24: a Pair handed to the full Teammate lies at their feet across the way it came, no message to the giver; a Pair handed to the empty-handed one goes into their Hands, active"},
		{"name": "aim", "method": "case_aim", "world": false,
				"title": "core/42 lines 1, 2, 4, 7, Q2589: no Teammate is aimed with empty Hands, past the reach, behind a wall, or knocked down; the entry point counts against a Sock behind; the Host refuses a knocked-down receiver"},
		{"name": "catch", "method": "case_catch", "world": false,
				"title": "core/42 lines 33-37, Q2588: a Throw below full charge that hits the Teammate holding its mate is caught into a Pair, flown from where it hit; a Charcoal Sock bounces back at 0.25 of its speed with no word and lands; a Pair thrown at a full Teammate lies at their feet"},
		{"name": "commands", "method": "case_commands", "world": false,
				"title": "core/42 lines 40, 45: the Host refuses a Hand-off with nothing held, to oneself, to nobody, from far away; a catch is the Host's only (not a Guest's verb)"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _holder_node != null:
		_holder_node.free()
		_holder_node = null
	_events.clear()
	_heard.clear()
	PadRumble.reset()


func _on_played(sound: StringName, spatial: bool, at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial, at])


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var hands := _hands()
	var mess := _mess()
	var player := _player()
	var mate := _avatar(HOLDER)
	var lead := _spot_sock("Held")
	var sock := _spot_sock("Mate")
	await _pick(sock)
	await _face_mate(mate)
	await _until(func() -> bool: return player.aimed_mate == HOLDER, "line 1: the Teammate is aimed", 20)
	var outline := Outline.of(mate)
	_check(outline != null and outline.shown and player.aimed_outline == outline, "line 30: the aimed Teammate shows its Outline")
	_check(player.crosshair_colour() == Player.CROSSHAIR_OK, "line 31: the crosshair is not red with a Teammate aimed")
	_check(player.hud().hints_text().contains("Drop"), "line 32: the corner still says Drop (%s)" % player.hud().hints_text())
	var from: Variant = player.held_view().drawn_of(sock)
	_heard.clear()
	await _tap()
	await _until(func() -> bool: return not hands.items_of(1).has(sock), "line 18: the Sock leaves the player's Hands", 20)
	_check(mess.mate_of(lead) == sock and mess.state_of(sock) == Mess.State.IN_PAIR, "line 12: it completes the Pair there")
	var theirs := hands.items_of(HOLDER)
	_check(theirs.size() == 1 and theirs[0] == lead and hands.active_of(HOLDER) == lead, "line 20: the Pair is in their Hands, active (%s)" % [theirs])
	_check(hands.items_of(1).is_empty(), "line 8: one item per click, the Hands empty")
	_check(_last(&"drop").is_empty(), "line 9: never also a drop")
	_check(_heard_flat(&"drop"), "line 19: the giver's drop cue plays (%s)" % [_heard])
	_check(_heard_near(&"pair", mate.global_position + Vector3.UP * Hearing.CUE_HEIGHT, 0.3), "line 21: their pair is heard at them (%s)" % [_heard])
	_check(player.message() == "", "line 43: the giver reads nothing")
	var view := mate.held
	await _frames(1)
	_check(view.flying_up(lead), "line 25: the item flies into their Hands")
	var drawn: Variant = view.drawn_of(lead)
	if from is Transform3D and drawn is Transform3D:
		var gap := (drawn as Transform3D).origin.distance_to((from as Transform3D).origin)
		_check(gap < 0.35, "line 25: it starts from the player's hand (%.2f m off)" % gap)
	var sparkles := view.sparkles
	await _until(func() -> bool: return not view.flying_up(lead), "line 25: the flight ends", 40)
	await _frames(2)
	_check(view.sparkles == sparkles + 1, "line 28: the small sparkle plays once at their hand")

	# Line 14: a loose Sock that completes no Pair there.
	var odd := _spot_sock("Odd")
	await _pick(odd)
	await _face_mate(mate)
	await _until(func() -> bool: return player.aimed_mate == HOLDER, "the Teammate aimed again", 20)
	_heard.clear()
	await _tap()
	await _frames(3)
	_check(hands.items_of(1).has(odd) and mess.state_of(odd) == Mess.State.HELD, "line 14: the Sock stays in the giver's Hands")
	_check(player.message() == Player.NOT_THEIR_MATE, "line 14: the giver reads Not their mate (%s)" % player.message())
	_check(_heard_flat(&"refuse") and not _heard_flat(&"drop"), "line 14: refuse, no drop (%s)" % [_heard])
	_check(_last(&"drop").is_empty(), "line 9: no drop instead")
	_check(outline.shown, "line 16: the outline stays as it was")


func case_pair_full_and_taken() -> void:
	await _build()
	var hands := _hands()
	var mess := _mess()
	var player := _player()
	var full := _avatar(HOLDER)
	await _until(func() -> bool: return hands.items_of(HOLDER).size() == 1, "the full Teammate holds its Sock", 120)
	var a := _spot_sock("PairA")
	await _pick(a)
	await _pick(_spot_sock("PairB"))
	_check(mess.is_pair(a), "the player holds the Forest Pair")
	await _face_mate(full)
	await _until(func() -> bool: return player.aimed_mate == HOLDER, "the full Teammate aimed", 20)
	await _tap()
	await _until(func() -> bool: return mess.state_of(a) == Mess.State.LYING, "line 23: the Pair lies down", 20)
	var lies := mess.pose_of(a).origin
	var feet := full.global_position
	_check(Vector2(lies.x - feet.x, lies.z - feet.z).length() < 0.05, "line 23: at the Teammate's feet (%.2f m)" % Vector2(lies.x - feet.x, lies.z - feet.z).length())
	_near(lies.y, SockDress.ball_radius(mess.design_of(a)), 0.02, "line 23: a lying Pair, on the floor")
	_check(hands.items_of(HOLDER).size() == 1 and hands.items_of(1).is_empty(), "line 23: their Hands as they were, the giver's empty")
	var ev := _last(Hands.HAND_OFF)
	_check(ev.get("full", false) and int(ev.get("receiver", 0)) == HOLDER, "line 23: the answer says no room, for the receiver")
	_check(player.message() == "", "line 23: the giver sees nothing")
	_check(_heard_flat(&"drop"), "line 19: the giver's drop cue plays")
	await _pick(a)
	var open := _avatar(OPEN)
	await _face_mate(open)
	await _until(func() -> bool: return player.aimed_mate == OPEN, "the empty-handed Teammate aimed", 20)
	await _tap()
	await _until(func() -> bool: return hands.items_of(OPEN).has(a), "line 11, 18: the Pair goes into their Hands", 20)
	_check(hands.active_of(OPEN) == a and mess.state_of(a) == Mess.State.HELD, "line 20: held, active")
	await _frames(1)
	_check(open.held.flying_up(a), "line 25: it flies in")


func case_aim() -> void:
	await _build()
	var hands := _hands()
	var player := _player()
	var mate := _avatar(HOLDER)
	await _face_mate(mate)
	await _physics_ticks(3)
	_check(player.aimed_mate == -1, "line 7: with empty Hands no Teammate is aimed")
	await _pick(_spot_sock("Odd"))
	await _face_mate(mate, 2.4)
	await _until(func() -> bool: return player.aimed_mate == HOLDER, "line 1: the entry point within reach counts (2.4 m to the middle)", 20)
	await _face_mate(mate, 3.2)
	await _physics_ticks(2)
	_check(player.aimed_mate == -1, "line 1: past the reach no Teammate")
	# Line 1: a wall in between shortens the reach.
	await _face_mate(mate, 1.6)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 3.0, 0.1)
	shape.shape = box
	wall.add_child(shape)
	wall.collision_layer = Mess.LAYER_HOUSE
	_zoo.add_child(wall)
	wall.global_position = mate.global_position + Vector3(0.0, 1.5, 0.8)
	await _physics_ticks(3)
	_check(player.aimed_mate == -1, "line 1: no Teammate behind a wall")
	wall.free()
	await _physics_ticks(3)
	_check(player.aimed_mate == HOLDER, "the Teammate aimed again with the wall gone")
	# Line 2: a lying Sock nearer than the body wins; the body nearer wins.
	var mate_sock := _spot_sock("Mate")
	var at := _mess().box_of(mate_sock).get_center()
	await _stand_facing(Vector3(at.x, 0.0, at.z + 0.9), at)
	await _physics_ticks(2)
	_check(player.aimed_sock == mate_sock and player.aimed_mate == -1, "line 2: the nearer Sock is aimed, not a Teammate far behind it")
	# Q2589: a knocked-down Teammate is not aimed, and the Host refuses it.
	_parts().ask(Command.new(Knockdowns.KNOCK, Parts.HOST, _kd().id, {"target": HOLDER, "thrower": 1,
			"push": Vector3.FORWARD, "high": 0.5, "side": 0.0, "at": mate.global_position + Vector3.UP}))
	await _physics_ticks(30)
	var mid := mate.ragdoll.point_at(0.6)
	await _stand_facing(Vector3(mid.x, 0.0, mid.z + 1.4), mid)
	await _physics_ticks(3)
	_check(player.aimed_mate == -1, "line 4, Q2589: a knocked-down Teammate is not aimed")
	var refused := _parts().answer(Command.new(Hands.HAND_OFF, 1, hands.id, {"to": HOLDER}))
	_check(not refused.get("ok", true) and str(refused.get("reason", "")) == Hands.DOWN, "Q2589: the Host refuses a knocked-down receiver (%s)" % str(refused.get("reason", "")))


func case_catch() -> void:
	await _build()
	var hands := _hands()
	var mess := _mess()
	var kd := _kd()
	var player := _player()
	var mate := _avatar(HOLDER)
	var lead := _spot_sock("Held")
	await _until(func() -> bool: return hands.items_of(HOLDER).has(lead), "the Teammate holds its Sock", 120)
	# Line 35: a Charcoal Sock bounces off, no word, and lands later.
	var odd := _spot_sock("Odd")
	await _pick(odd)
	await _face_mate(mate, 1.2)
	await _throw(0.6)
	await _until(func() -> bool: return kd.bounces == 1, "line 35: the Throw hits the Teammate and bounces", 90)
	var body := mess.moving_body(odd)
	_check(body != null, "it flies on")
	if body != null:
		var v := body.linear_velocity
		_check(v.z > 0.0 and Vector2(v.x, v.z).length() < 3.0, "line 35: back off the body towards the thrower, slowly (%s)" % v)
	_check(player.message() == "" and hands.items_of(HOLDER).size() == 1, "line 35: nobody reads anything, their Hands as they were")
	_check(not kd.is_down(HOLDER), "line 37: below full charge nobody is knocked down")
	await _until(func() -> bool: return mess.state_of(odd) == Mess.State.LYING, "line 35: it lands like any Flight", 300)
	# Line 34: the Brown mate is caught into a Pair.
	var sock := _spot_sock("Mate")
	await _pick(sock)
	await _face_mate(mate, 1.2)
	await _throw(0.6)
	await _until(func() -> bool: return mess.mate_of(lead) == sock, "line 34: the Throw is caught into a Pair", 90)
	var ev := _last(Hands.CATCH)
	_check(int(ev.get("receiver", 0)) == HOLDER and int(ev.get("thrower", 0)) == 1 and ev.has("paired"), "line 34: the catch answer names receiver, thrower and the Pair")
	_check(hands.items_of(HOLDER).size() == 1 and hands.items_of(HOLDER)[0] == lead, "line 34: the Pair in their Hands")
	_check(mess.moving_body(sock) == null and not mess.throws.has(sock), "line 34: the flight ends (%s %s)" % [mess.moving_body(sock), mess.throws.get(sock)])
	_check(_heard_near(&"pair", mate.global_position + Vector3.UP * Hearing.CUE_HEIGHT, 0.3), "line 34: their pair is heard")
	await _frames(1)
	var drawn: Variant = mate.held.drawn_of(lead)
	if drawn is Transform3D:
		_check((drawn as Transform3D).origin.distance_to(ev.get("at", Vector3.INF)) < 0.35, "line 34: it flies in from where it hit")
	# Line 36: a Pair thrown at the full Teammate lies at their feet.
	var a := _spot_sock("PairA")
	await _pick(a)
	await _pick(_spot_sock("PairB"))
	await _face_mate(mate, 1.2)
	await _throw(0.6)
	await _until(func() -> bool: return _last(Hands.CATCH).get("full", false), "line 36: the caught Pair finds no room", 90)
	_check(mess.state_of(a) == Mess.State.LYING, "line 36: it lies down")
	var lies := mess.pose_of(a).origin
	_check(Vector2(lies.x - mate.global_position.x, lies.z - mate.global_position.z).length() < 0.05, "line 36: at their feet")


func case_commands() -> void:
	await _build()
	var hands := _hands()
	var parts := _parts()
	_check(str(parts.answer(Command.new(Hands.HAND_OFF, 1, hands.id, {"to": HOLDER})).get("reason", "")) == Hands.NOTHING, "line 40: nothing held")
	await _pick(_spot_sock("Odd"))
	_check(str(parts.answer(Command.new(Hands.HAND_OFF, 1, hands.id, {"to": 1})).get("reason", "")) == Hands.SELF, "not to oneself")
	_check(str(parts.answer(Command.new(Hands.HAND_OFF, 1, hands.id, {"to": 99})).get("reason", "")) == Hands.GONE, "line 40: not to nobody")
	_player().global_position = Vector3(10.0, 0.0, 10.0)
	await _physics_ticks(2)
	_check(str(parts.answer(Command.new(Hands.HAND_OFF, 1, hands.id, {"to": HOLDER})).get("reason", "")) == Hands.FAR, "not from far away")
	_check(not hands.accepts().has(Hands.CATCH), "the catch is not a Guest's verb")
	_check(str(parts.answer(Command.new(Hands.CATCH, 9, hands.id, {"sock": 0, "to": HOLDER, "at": Vector3.ZERO})).get("reason", "")) == "wrong", "a catch by a player is refused")
	_check(not hands.accepts().has(&"take"), "line 45: no take verb")


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
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
	_player().global_position = (_zoo.get_node(STATION) as Node3D).global_position + Vector3(0.0, 0.0, 3.0)
	await _until(func() -> bool: return _player().is_on_floor() and _mess().looks_of(_spot_sock("Mate")) != null \
			and _avatar(HOLDER) != null and _hands().items_of(HOLDER).size() == 1,
			"the zoo to stand, its Socks to lie, the Teammate to hold its Sock", 300)
	_player().capture_mouse()


func _pick(sock: int) -> void:
	var at := _mess().box_of(sock).get_center()
	if _mess().state_of(sock) == Mess.State.LYING and _mess().is_pair(sock):
		at = _mess().pose_of(sock).origin
	await _stand_facing(Vector3(at.x, 0.0, at.z + 1.0), at)
	await _until(func() -> bool: return _player().aimed_sock == sock, "the crosshair on Sock %d" % sock, 20)
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _until(func() -> bool: return _hands().items_of(1).has(sock) or _mess().state_of(sock) == Mess.State.IN_PAIR,
			"Sock %d to be picked" % sock, 60)
	await _physics_ticks(int(_player().hands_tuning.grab_interval * 60.0) + 2)


## Stands the player `away` m in front of Teammate `mate` (on their +z side), looking at their chest.
func _face_mate(mate: Avatar, away := 1.5) -> void:
	var feet := mate.global_position
	await _stand_facing(Vector3(feet.x, 0.0, feet.z + away), feet + Vector3.UP * 1.1)


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


## A short click of the right button (under the tap).
func _tap() -> void:
	Input.action_press(&"drop_throw")
	await _physics_ticks(2)
	Input.action_release(&"drop_throw")
	await _physics_ticks(1)


## Holds the right button until the ring shows `charge`, then lets go.
func _throw(charge: float) -> void:
	var player := _player()
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return player.charging and player.charge >= charge, "the ring to reach %.1f" % charge, 200)
	Input.action_release(&"drop_throw")
	await _physics_ticks(1)


func _heard_flat(sound: StringName) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and not bool(e[1]):
			return true
	return false


func _heard_near(sound: StringName, at: Vector3, within: float) -> bool:
	for e: Array in _heard:
		if StringName(e[0]) == sound and bool(e[1]) and (e[2] as Vector3).distance_to(at) <= within:
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
	var node := _zoo.get_node_or_null(STATION + ("/Holder/%d" if peer == HOLDER else "/Open/%d") % peer)
	return node as Avatar


func _kd() -> Knockdowns:
	return LevelRuntime.of(_zoo).knockdowns


func _mess() -> Mess:
	return LevelRuntime.of(_zoo).mess


func _hands() -> Hands:
	return LevelRuntime.of(_zoo).hands


func _parts() -> Parts:
	return LevelRuntime.of(_zoo).parts


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
