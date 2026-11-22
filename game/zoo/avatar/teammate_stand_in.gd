## The Avatar station's stand-in Teammates (coop/05, Q2468): two real Avatars, puppets on this machine
## (their names are peer ids no player has), so the waddle, bend, squash, crouch, colour, name tag and
## held Socks show when playing alone. They are driven only through the pose a real Teammate's
## synchronizer writes (pose_position, pose_yaw, pose_pitch, pose_crouch); the Avatar has no other way
## in. `still` stands where it is placed; `walker` goes round a loop: a walk round the circle (taking the
## station's Sock while it lies there, held from then on), a crouch, a look up, a look down, a hop.
## Their colours and tags are set here, as the Roster sets a real player's. The walker plays only
## while the camera is within `wake_range`.
class_name TeammateStandIn
extends Node3D

## The group the walker is in: the zoo's reach rule finds it there (ZooNet.where()).
const GROUP := &"stand_in_teammates"
## The phases of one round, in order.
const WALK := &"walk"
const CROUCH := &"crouch"
const LOOK_UP := &"look_up"
const LOOK_DOWN := &"look_down"
const HOP := &"hop"

## The Avatar that stands still, and the one that walks the loop.
@export var still: Avatar
@export var walker: Avatar
## Their Player colours (coral and teal, the Roster's first two) and the name on their tags.
@export var still_colour := Color("f08a7a")
@export var walker_colour := Color("4fb3a9")
@export var tag := "Player"
## The loop: its centre (in this node's space), its radius and the walking speed (3 m/s is a full waddle).
@export var centre := Vector3.ZERO
@export_range(0.3, 5.0, 0.1, "suffix:m") var radius := 1.2
@export_range(0.1, 6.0, 0.1, "suffix:m/s") var speed := 3.0
## How long each phase lasts, in order: walk, crouch, look up, look down, hop.
@export var phases: Array[float] = [4.0, 1.5, 1.5, 1.5, 0.8]
## How high the hop goes.
@export_range(0.0, 3.0, 0.05, "suffix:m") var hop_height := 0.6
## The walker plays only while the camera is this near (the zoo's other stations and their tests
## see it stand still, its Sock lying).
@export_range(1.0, 1000.0, 1.0, "suffix:m") var wake_range := 10.0
## The Sock spot the walker takes (empty: none).
@export var sock_spot: SockSpot

## Seconds into the current round.
var clock := 0.0
## The phase now.
var phase := WALK
## Where on the circle the walker is (radians).
var angle := 0.0

var _picked := false
var _next_try := 0.0


func _ready() -> void:
	for pair: Array in [[still, still_colour], [walker, walker_colour]]:
		var a: Avatar = pair[0]
		if a != null and a.looks != null:
			a.looks.colour = pair[1]
			a.looks.player_name = tag
	if walker != null:
		walker.add_to_group(GROUP)
		_place(0.0)


func _process(delta: float) -> void:
	if walker == null or not awake():
		return
	var total := 0.0
	for p: float in phases:
		total += p
	clock = fmod(clock + delta, maxf(total, 0.1))
	var names: Array[StringName] = [WALK, CROUCH, LOOK_UP, LOOK_DOWN, HOP]
	var start := 0.0
	var into := 0.0
	for i in names.size():
		var length: float = phases[i] if i < phases.size() else 0.0
		if clock < start + length or i == names.size() - 1:
			phase = names[i]
			into = clock - start
			break
		start += length
	walker.pose_crouch = 1.0 if phase == CROUCH else 0.0
	walker.pose_pitch = deg_to_rad(80.0) if phase == LOOK_UP else (deg_to_rad(-80.0) if phase == LOOK_DOWN else 0.0)
	var lift := 0.0
	if phase == WALK:
		angle = fmod(angle + speed / radius * delta, TAU)
		_take_sock(delta)
	elif phase == HOP:
		var u := clampf(into / maxf(phases[4], 0.05), 0.0, 1.0)
		lift = hop_height * 4.0 * u * (1.0 - u)
	_place(lift)


## Whether the camera is near enough for the walker to play.
func awake() -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam != null and cam.global_position.distance_to(global_position) <= wake_range


## The walker on the circle at `angle`, `lift` over the floor, facing along it.
func _place(lift: float) -> void:
	var at := centre + Vector3(cos(angle), 0.0, sin(angle)) * radius + Vector3.UP * lift
	walker.pose_position = at
	# Facing the way round (-z forward): the tangent of the circle, counter-clockwise seen from above.
	var along := Vector3(-sin(angle), 0.0, cos(angle))
	walker.pose_yaw = atan2(-along.x, -along.z)


## While walking, until it holds it, the walker asks for the station's Sock once a second, as a
## Teammate's pick does (it lies there until somebody takes it).
func _take_sock(delta: float) -> void:
	_next_try -= delta
	if _picked or _next_try > 0.0 or sock_spot == null or walker.held == null:
		return
	var hands := walker.held.hands
	if hands == null or hands.parts == null:
		return  # the station alone, outside the zoo, has no Parts to ask
	if hands.items_of(walker.peer()).has(sock_spot.sock):
		_picked = true
		return
	_next_try = 1.0
	hands.pick(walker.peer(), sock_spot.sock)
