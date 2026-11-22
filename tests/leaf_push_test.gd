## A Sock caught by a shutting Door or drawer is pushed out of the leaf (core/39, Q2428): it ends on the
## side the leaf swept from, not at the return spot with a pop; the lost rule (T08) stays for a wall.
## Every case plays the Cabinet station (game/zoo/stations/cabinet.tscn: a Cabinet, a Door, 13 Socks)
## on a floor, with the game's player and a Parts (a Host of one), as the zoo does.
extends TestSuite

const STATION := "res://game/zoo/stations/cabinet.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact"]
## The Socks the real path picks (no two of them mates), from the front, to drop into the Door's swing.
const PICKED: Array[int] = [0, 2, 4]
## Where the player stands (station space): before the Socks, before the Door, and behind the Door
## clear of its swing.
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
const BY_DOOR := Vector3(1.55, 0.0, 0.6)
const BEHIND_DOOR := Vector3(1.75, 0.0, -2.05)
## Where the Socks are dropped, in the Door's swing (the hinge is at x 1.1, z -0.8; open, the leaf
## points to -z).
const DROPS: Array[Vector3] = [Vector3(1.35, 0.0, -1.05), Vector3(1.6, 0.0, -0.95), Vector3(1.85, 0.0, -0.88)]

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _parts: Parts = null
## Where a pop played, from the Parts' answers since the case started.
var _pops := PackedVector3Array()


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player drops Socks in the Door's swing, opens and shuts it with the use key; every Sock lies outside the leaf, none at the return spot, no pop"},
		{"name": "door_leaf", "method": "case_door_leaf", "world": false,
				"title": "a Sock that would rest with its middle in the shut Door's leaf lies past the leaf's face on the side the leaf swept from, wholly clear of it, at its height, with no pop"},
		{"name": "drawer_leaf", "method": "case_drawer_leaf", "world": false,
				"title": "a Sock that would rest with its middle in a shut Cabinet drawer's front lies before the front, the side it slid in from, with no pop"},
		{"name": "wall_still_lost", "method": "case_wall", "world": false,
				"title": "T08 stays: a Sock that would rest inside a wall (the Door's jamb) or out of bounds comes back at the return spot; a flight resting in the jamb pops"},
		{"name": "shallow_floor", "method": "case_shallow", "world": false,
				"title": "a Sock whose middle rests under the floor's top by less than `sunk` lies as it is (the old sunk_floor: still in the room), not lost"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_pops = PackedVector3Array()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	# Hands that hold three, as the zoo's player's (Q2244); pick three Socks with the mouse.
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = PICKED.size()
	_player.held_view().tuning = _player.hands_tuning
	_stand(BY_SOCKS)
	for sock in PICKED:
		await _aim(_player, _middle(sock))
		await _press(&"pick")
		await _until(func() -> bool: return _mess.state_of(sock) == Mess.State.HELD, "Sock %d to be in the Hands" % sock)
		await _physics_ticks(25)
	# Open the Door with the use key.
	var door := _door()
	_stand(BY_DOOR)
	await _aim(_player, _leaf_point())
	await _press(&"interact")
	await _until(func() -> bool: return door.open and not door.animator().is_playing(), "the Door to swing open", 120)
	# Drop each into the swing from behind the Door.
	_stand(BEHIND_DOOR)
	for i in PICKED.size():
		await _aim(_player, _station.to_global(DROPS[i]))
		_check(not _player.drop_refused, "a drop may go at %s" % DROPS[i])
		await _press(&"drop_throw")
		var left := PICKED.size() - i - 1
		await _until(func() -> bool: return _held() == left, "the active Sock to be dropped (%d held)" % _held())
		await _physics_ticks(25)
	await _until(func() -> bool: return _resting(), "the dropped Socks to lie", 600)
	for sock in PICKED:
		var at := _station.to_local(_middle(sock))
		_check(at.z < -0.8 and at.x > 1.1, "Sock %d lies in the Door's swing (%s)" % [sock, at])
	# Shut it with the use key, from where the player stands.
	await _aim(_player, _leaf_point())
	await _press(&"interact")
	await _until(func() -> bool: return not door.open and not door.animator().is_playing(), "the Door to swing shut", 120)
	await _until(func() -> bool: return _resting(), "every Sock to lie again", 900)
	var spot := (_station.get_node("ReturnSpot") as Node3D).global_position
	for sock in PICKED:
		_check(_mess.state_of(sock) == Mess.State.LYING, "Sock %d lies" % sock)
		_check(not _in_leaf(_middle(sock)), "Sock %d lies outside the leaf (%s)" % [sock, _station.to_local(_middle(sock))])
		_check(_mess.pose_of(sock).origin.distance_to(spot) > 0.5, "Sock %d is not at the return spot" % sock)
	_check(_pops.is_empty(), "no pop played (%s)" % [_pops])


# --- The rule ------------------------------------------------------------------------------------

func case_door_leaf() -> void:
	await _build()
	var door := _door()
	await _swing(door, true)
	await _swing(door, false)
	var sock := 0
	# The middle in the shut leaf near the floor, a little off its plane toward the side it shut to.
	var basis := Basis(Vector3.UP, 0.4)
	var middle := _leaf_point() + _station.global_basis * Vector3(0.0, -1.29, 0.01)
	var from := _pose_with_middle(sock, basis, middle)
	var down := _mess.put_down(sock, from)
	_check(not down["returned"], "it is not lost")
	var dir := down.get("pushed", Vector3.ZERO) as Vector3
	var back := _station.global_basis * Vector3.FORWARD
	_check(dir.dot(back) > 0.95, "it is pushed to the side the leaf swept from (%s)" % dir)
	var pose := down["pose"] as Transform3D
	var now := pose * Mess._sock_middle(_mess.design_of(sock))
	_check(not _in_leaf(now), "its middle is out of the leaf")
	var face := _station.to_local(_leaf_point()).z - 0.025
	var reach := _box_reach(sock, basis, back)
	_near(_station.to_local(now).z, face - reach - _mess.bodies_tuning().leaf_clearance, 0.002,
			"all of it is past the leaf's face by the clearance and no more")
	_near(pose.origin.y, from.origin.y, 0.0001, "it stays at its height")


func case_drawer_leaf() -> void:
	await _build()
	var cabinet := _station.get_node("Cabinet/Cabinet") as Cabinet
	var drawer := cabinet.drawer(0)
	var front := cabinet.get_parent().get_node("Drawer1/Looks/Slide/Front") as CollisionShape3D
	var shut_at := front.global_position
	await _swing(drawer, true)
	var outward := front.global_position - shut_at
	outward.y = 0.0
	outward = outward.normalized()
	await _swing(drawer, false)
	var sock := 2
	var basis := Basis(Vector3.UP, 1.2)
	var middle := front.global_position + Vector3(0.0, -0.1, 0.0) - outward * 0.005
	var down := _mess.put_down(sock, _pose_with_middle(sock, basis, middle))
	_check(not down["returned"], "it is not lost")
	var dir := down.get("pushed", Vector3.ZERO) as Vector3
	_check(dir.dot(outward) > 0.95, "it is pushed out before the front, the way the drawer slid in from (%s, %s)" % [dir, outward])
	var now := (down["pose"] as Transform3D) * Mess._sock_middle(_mess.design_of(sock))
	var q := front.global_transform.affine_inverse() * now
	_check(absf(q.z) > (front.shape as BoxShape3D).size.z * 0.5, "its middle is out of the front (%s)" % q)


func case_wall() -> void:
	await _build()
	var door := _door()
	await _swing(door, true)
	await _swing(door, false)
	var jamb := _station.get_node("JambRight") as Node3D
	var sock := 4
	var down := _mess.put_down(sock, _pose_with_middle(sock, Basis.IDENTITY, jamb.global_position))
	var spot := (_station.get_node("ReturnSpot") as Node3D).global_position
	_check(down["returned"] and not down.has("pushed"), "a Sock inside the jamb is lost")
	_check((down["pose"] as Transform3D).origin.distance_to(spot) <= _mess.bodies_tuning().return_scatter + 0.001, "and comes back at the return spot")
	var far := _mess.put_down(sock, Transform3D(Basis.IDENTITY, _station.to_global(Vector3(0.0, -500.0, 0.0))))
	_check(far["returned"], "a Sock out of bounds is lost")
	# A flight let go inside the jamb rests by the Host's own rule: a pop plays.
	var inside := _pose_with_middle(sock, Basis.IDENTITY, jamb.global_position)
	_parts.apply({"ok": true, "kind": &"test", "by": 1, "to": _mess.id,
			"changes": {_mess.id: _mess.thrown_patch(sock, inside, Vector3.ZERO, Vector3.ZERO, Parts.HOST, true)}})
	await _until(func() -> bool: return _mess.state_of(sock) == Mess.State.LYING, "the flight in the wall to rest", 600)
	_check(_pops.size() == 1, "one pop (%d)" % _pops.size())


func case_shallow() -> void:
	await _build()
	var sock := 0
	var before := _mess.pose_of(sock)
	var middle := before * Mess._sock_middle(_mess.design_of(sock))
	var sunk := before.translated(Vector3.DOWN * (middle.y - _level.global_position.y + 0.005))
	var down := _mess.put_down(sock, sunk)
	_check(not down["returned"], "its middle 5 mm into the floor, it is not lost")
	_check((down["pose"] as Transform3D).origin.is_equal_approx(sunk.origin), "it lies as it is")


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
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
	_player.position = _station.position + BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()   # the mouse is the player's: buttons act (R01)
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_parts.applied.connect(_on_applied)
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


func _on_applied(ev: Dictionary) -> void:
	if ev.has(Mess.POPPED):
		_pops.append_array(ev[Mess.POPPED] as PackedVector3Array)


func _door() -> Openable:
	return _station.get_node("Door/Openable") as Openable


## Opens or shuts `openable` by its own Command and waits for its swing or slide to end.
func _swing(openable: Openable, open: bool) -> void:
	_parts.ask(Command.new(&"open", 1, openable.id, {"open": open}))
	await _until(func() -> bool: return openable.open == open and not openable.animator().is_playing(), "the swing to end", 120)
	await _physics_ticks(2)


## A point on the Door's leaf, 1.3 m up its middle (wherever it is in its swing).
func _leaf_point() -> Vector3:
	return (_station.get_node("Door/Looks/Hinge") as Node3D).global_transform * Vector3(0.45, 1.3, 0.0)


## Whether `p` is inside the Door's leaf.
func _in_leaf(p: Vector3) -> bool:
	var shape := _station.get_node("Door/Looks/Hinge/PanelShape") as CollisionShape3D
	var q := shape.global_transform.affine_inverse() * p
	var half := (shape.shape as BoxShape3D).size * 0.5
	return absf(q.x) < half.x and absf(q.y) < half.y and absf(q.z) < half.z


## A lying Sock's middle (as the Mess's lost rule reads it).
func _middle(sock: int) -> Vector3:
	return _mess.pose_of(sock) * Mess._sock_middle(_mess.design_of(sock))


## The pose of Sock `sock` turned by `basis` with its middle at `middle`.
func _pose_with_middle(sock: int, basis: Basis, middle: Vector3) -> Transform3D:
	return Transform3D(basis, middle - basis * Mess._sock_middle(_mess.design_of(sock)))


## Half of a loose Sock's box measured along `dir`.
func _box_reach(sock: int, basis: Basis, dir: Vector3) -> float:
	var half := SockDress.box(_mess.design_of(sock)) * 0.5
	return absf(basis.x.dot(dir)) * half.x + absf(basis.y.dot(dir)) * half.y + absf(basis.z.dot(dir)) * half.z


## How many of the picked Socks are held.
func _held() -> int:
	var n := 0
	for sock in PICKED:
		if _mess.state_of(sock) == Mess.State.HELD:
			n += 1
	return n


## Nothing of the Mess moves or waits to.
func _resting() -> bool:
	return _mess.moving_count() == 0 and _mess.waiting_count() == 0


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Presses an action for two physics ticks, then lets it go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)
