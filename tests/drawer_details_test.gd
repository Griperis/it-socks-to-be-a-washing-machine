## The Cabinet's small motions (core/09): a Pair shelved by a click flies into its slot (D11), and a
## drawer eases out both ways (D12). Every case plays the station scene
## game/zoo/stations/cabinet.tscn on a floor, with the game's player and a Parts (a Host of one), as
## the zoo does; the shelve and the open are the real click on a drawer.
extends TestSuite

const STATION := "res://game/zoo/stations/cabinet.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick"]
## A Simple Sock and its mate, by id (the order of the station's SockSpots).
const S0 := 0
const S0_MATE := 1
## Where the player stands (station space): before the Socks, and before the drawers.
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
const BY_DRAWERS := Vector3(-1.0, 0.0, -0.4)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _cabinet: Cabinet = null
var _parts: Parts = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "d11_shelving_flight", "method": "case_d11", "world": false,
				"title": "D11: a Pair shelved by a click flies from the Hands into its slot in 0.45 s, and the drawer shows its ball when it has landed"},
		{"name": "d12_drawer_slide", "method": "case_d12", "world": false,
				"title": "D12: a drawer eases out both ways, and turning back mid-slide stays smooth"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


func case_d11() -> void:
	await _build()
	await _pair(S0, S0_MATE)
	var view := _player.held_view()
	await _until(view.settled, "the Pair to be in its place in the Hands", 120)
	await _click_drawer(0)
	await _until(func() -> bool: return _cabinet.shelved().has(S0), "the Pair to be shelved")
	var flier := _cabinet.get_parent().get_node_or_null(NodePath("Flight%d" % S0)) as Node3D
	var slot := _cabinet.get_parent().get_node("Drawer1/Looks").find_child(Cabinet.SLOT % 1, true, false) as Node3D
	var ball := slot.get_node(NodePath(Cabinet.BALL)) as Node3D
	_check(flier != null and _cabinet.flights_into(0) == 1, "a ball flies into the drawer")
	_check(not ball.visible, "the drawer's ball waits for it")
	if flier == null:
		return
	var start := flier.global_position
	await _physics_ticks(10)
	_check(flier.global_position.distance_to(ball.global_position) < start.distance_to(ball.global_position), "it flies towards its slot")
	_check(flier.global_position.y > ball.global_position.y, "on an arc above it")
	# The flight, then its landing in the slot (core/27 P10: the hop and the second squash).
	var frames := int((_cabinet.tuning_of().flight_time + Cabinet.BALL_LANDING.bounce_time + Cabinet.BALL_LANDING.squash_time) * 60.0)
	await _until(func() -> bool: return _cabinet.flights_into(0) == 0, "the ball to land", frames + 6)
	_check(ball.visible, "landed, the drawer shows its ball")
	_check(not is_instance_valid(flier) or flier.is_queued_for_deletion(), "and the flying one is gone")


func case_d12() -> void:
	await _build()
	var drawer := _cabinet.drawer(0)
	var slide := _cabinet.get_parent().get_node("Drawer1/Looks/Slide") as Node3D
	var player := drawer.animator()
	await _click_drawer(0)
	await _until(func() -> bool: return drawer.open, "the drawer to open")
	await _until(func() -> bool: return not player.is_playing(), "the slide to end", 60)
	var steps: Array[float] = []
	drawer.use(1)
	await _until(func() -> bool: return not drawer.open, "the drawer to shut")
	_check(player.current_animation == Openable.SHUT, "shutting plays its own \"shut\"")
	var last := slide.position.z
	while player.is_playing():
		await _physics_ticks(1)
		if last - slide.position.z > 0.0001:
			steps.append(last - slide.position.z)
		last = slide.position.z
	_check(steps.size() > 4 and steps[0] > steps[-1] * 2.0, "it eases out as it shuts (first step %.4f, last %.4f)" % [steps[0] if steps.size() > 0 else 0.0, steps[-1] if steps.size() > 0 else 0.0])
	_near(slide.position.z, 0.0, 0.001, "and ends shut")
	drawer.use(1)
	await _until(func() -> bool: return drawer.open, "the drawer to open again")
	await _physics_ticks(6)
	var most := 0.0
	last = slide.position.z
	drawer.use(1)
	for i in 8:
		await _physics_ticks(1)
		most = maxf(most, absf(slide.position.z - last))
		last = slide.position.z
	_check(most < 0.06, "turned back mid-slide it moves on smoothly (largest step %.4f m)" % most)
	_check(slide.position.z < 0.4 and slide.position.z >= -0.001, "on its way shut")


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
	_hands = _station.get_node("Socks/Hands") as Hands
	_cabinet = _station.get_node("Cabinet/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


## Puts the player at `spot` in station space.
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


## Takes Sock `sock` into the Hands by the Hands' own Command, past the grab interval.
func _take(sock: int) -> void:
	_hands.clock += 10.0
	_hands.pick(1, sock)
	await _physics_ticks(1)
	_check(_hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d is taken" % sock)


## Takes a Sock and its mate: one Pair in the Hands.
func _pair(sock: int, mate: int) -> void:
	await _take(sock)
	await _take(mate)
	_check(_mess.is_pair(sock), "Socks %d and %d fused into a Pair" % [sock, mate])


## Stands before the drawers, aims at drawer `index`'s front and left-clicks.
func _click_drawer(index: int) -> void:
	_stand(BY_DRAWERS)
	var front := _cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	await _aim(_player, front.global_position + Vector3(0.3, 0.0, 0.0))
	await _press(&"pick")
