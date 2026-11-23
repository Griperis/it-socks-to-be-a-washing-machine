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
