## The Stacking station's stand-in Teammates (core/41): real Avatars, puppets on this machine (their
## names are peer ids no player has), so a player alone can climb, ride and step off a back. They are
## moved only through the pose a real Teammate's synchronizer writes. `carrier` stands beside the ledge;
## while the local player rides it, it walks its loop at a carrier's pace (a walk, a crouch, a stand), and
## once nobody rides it it walks on until it is home again. `still` stands under the low board, where
## there is no room for a rider. The numbers label shows the station's numbers, read from the tuning at
## load (Q2337).
class_name StackStandIn
extends Node3D

const LABEL := preload("res://game/zoo/zoo_label.tscn")

## Where a review session's carrier (the Host's player) stands, from the station along the zoo's axes:
## off the pad, clear of the stand-ins (review()).
const REVIEW_SPOT := Vector3(3.5, 0.0, -2.5)

## The phases of one round while ridden, in order.
const WALK := &"walk"
const CROUCH := &"crouch"
const STAND := &"stand"

@export var carrier: Avatar
@export var still: Avatar
@export var stacking: StackingTuning
@export var moving: MoveTuning
## Where the station's numbers lie (in this node's parent's space).
@export var numbers_at := Vector3(-2.5, 0.01, 2.6)
## Their Player colours (the Roster's third and fourth) and the name on their tags.
@export var carrier_colour := Color("e8c35a")
@export var still_colour := Color("9a7fd1")
@export var tag := "Player"
## The loop: its centre (in this node's space); the carrier's home is its point nearest the ledge.
@export var centre := Vector3(1.2, 0.0, 0.0)
@export_range(0.3, 5.0, 0.1, "suffix:m") var radius := 1.2
## How long each phase lasts while ridden, in order: walk, crouch, stand.
@export var phases: Array[float] = [4.0, 1.5, 1.5]

## The phase now, and seconds into the ridden round.
var phase := STAND
var clock := 0.0
## Where on the loop the carrier is (radians; PI is home).
var angle := PI


func _ready() -> void:
	for pair: Array in [[carrier, carrier_colour], [still, still_colour]]:
		var a: Avatar = pair[0]
		if a != null and a.looks != null:
			a.looks.colour = pair[1]
			a.looks.player_name = tag
	if stacking != null:
		var numbers := LABEL.instantiate() as Label3D
		numbers.name = "Numbers"
		numbers.text = describe(stacking, moving)
		numbers.pixel_size = 0.004
		numbers.width = 900.0
		numbers.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		numbers.position = numbers_at
		get_parent().add_child.call_deferred(numbers)
	_place()


## The station's numbers, as the label shows them.
static func describe(t: StackingTuning, m: MoveTuning) -> String:
	var walk := m.walk_speed if m != null else 4.0
	return "\n".join([
		"Back: a disc %.2f m round, %.2f m thick, %.2f m under the top of the body" % [t.back_radius * 2.0, t.back_thickness, t.ride_sink],
		"Climb: a jump within %.2f m, clearing the back by %.2f m, steered at %.1f a second" % [t.climb_reach, t.climb_clear, t.climb_steer],
		"Carry: %.0f%% of the pace (%.1f m/s walking), at most %d high" % [t.carry_speed * 100.0, walk * t.carry_speed, t.max_high],
		"Push: nearer than %.2f m, at %.1f a second; slip off a lying body at %.1f m/s" % [t.push_apart, t.push_rate, t.slip_speed],
	])


func _physics_process(delta: float) -> void:
	if carrier == null:
		return
	var ridden := ridden_now()
	if ridden:
		var total := 0.0
		for p: float in phases:
			total += p
		clock = fmod(clock + delta, maxf(total, 0.1))
		phase = WALK if clock < phases[0] else (CROUCH if clock < phases[0] + phases[1] else STAND)
	elif angle != PI:
		phase = WALK  # home again first
	else:
		phase = STAND
		clock = 0.0
	carrier.pose_crouch = 1.0 if phase == CROUCH else 0.0
	if phase == WALK:
		var pace := (moving.walk_speed if moving != null else 4.0) * (stacking.carry_speed if ridden else 1.0)
		var was := angle
		angle = fmod(angle + pace / radius * delta, TAU)
		if not ridden and was < PI and angle >= PI:
			angle = PI
	_place()


## Whether this machine's player stands on the carrier's back now.
func ridden_now() -> bool:
	if carrier.back == null or not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group(&"local_input"):
		var p := node as Player
		if p != null and p.stack().ride == carrier.back:
			return true
	return false


## The carrier on the loop at `angle`, facing along it.
func _place() -> void:
	if carrier == null:
		return
	carrier.pose_position = centre + Vector3(cos(angle), 0.0, sin(angle)) * radius
	var along := Vector3(-sin(angle), 0.0, cos(angle))
	carrier.pose_yaw = atan2(-along.x, -along.z)


## For a review session of two game processes (kit/tools/net_shot.sh, a Host and a Guest in the zoo),
## from its expr command: scene().get_node("Stations/Stacking/Teammates").review("<arg>"). "a" (the
## Host): its player at REVIEW_SPOT facing -z, its full body shown, a camera from its side, as the
## carrier's own machine sees the stack; "b" (the Guest): its player 0.7 m behind, facing it, ready to
## climb by its jump key; "b_view": the Guest's camera from the same side and its full body, as the
## rider's machine sees it; "walk" / "stop": the Host's player walks forward / stops.
func review(arg: String) -> String:
	var world := LevelRuntime.level_of(self)
	var player := LevelRuntime.of(world).player
	var at: Vector3 = (get_parent() as Node3D).global_position + REVIEW_SPOT
	match arg:
		"a":
			player.global_position = at
			player.rotation.y = 0.0
			player.reset_physics_interpolation()
			show_body(player)
			camera(world, at + Vector3(-3.8, 2.4, -0.6), at + Vector3(0.0, 1.3, -1.0))
		"b":
			player.global_position = at + Vector3(0.0, 0.0, 0.7)
			player.rotation.y = 0.0
			player.reset_physics_interpolation()
		"b_view":
			show_body(player)
			camera(world, at + Vector3(-3.8, 2.4, -0.6), at + Vector3(0.0, 1.3, -1.0))
		"walk":
			Input.action_press(Player.MOVE_FORWARD)
		"stop":
			Input.action_release(Player.MOVE_FORWARD)
	return "%s at %s riding %s" % [arg, player.global_position, player.riding()]


## Shows `player`'s full body (the mirror's, as a Teammate sees it) instead of the belly cut for its
## eyes. A mirror in the zoo hides that body each frame while it does not render, so it is shown again
## just before each frame is drawn.
static func show_body(player: Player) -> void:
	var body := player.mirror_body()
	player.own_body().visible = false
	RenderingServer.frame_pre_draw.connect(func() -> void:
		if is_instance_valid(body) and not player.own_body().visible:
			body.visible = true
			body.colour = player.own_body().colour
			body.look_pitch = player.own_body().look_pitch
			body.set_crouch(player.own_body().crouch))


## A camera at `from` looking at `to`, made current.
static func camera(world: Node, from: Vector3, to: Vector3) -> void:
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = 50.0
	cam.global_position = from
	cam.look_at(to)
	cam.reset_physics_interpolation()
	cam.make_current()
