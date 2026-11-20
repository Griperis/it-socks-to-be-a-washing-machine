## Dresses a Sock's Looks (a scene with the contract in looks_contract.json: Body, Outline, an
## AnimationPlayer with lying, held and aimed) as one Design: tinted by its colour, scaled by its
## Size (Q2249). The states play in the Looks' AnimationPlayer, never in code (Q2213). Used by the
## Mess (lying and falling Socks and Pairs) and the HeldView (the Hands). A Pair is drawn as one
## sock ball (looks_ball.tscn, the same contract, its centre at its origin: P06).
class_name SockDress
extends RefCounted

const LOOKS := preload("res://game/sock/looks_graybox.tscn")
const BALL_LOOKS := preload("res://game/sock/looks_ball.tscn")
## The animations every Sock Looks has.
const LYING := &"lying"
const HELD := &"held"
const AIMED := &"aimed"
## The flat Sock's box at Size medium (the graybox crew.glb lying flat, its bottom at y = 0).
const BOX := Vector3(0.3, 0.026, 0.18)
## The sock ball's radius at Size medium (half the height of the old ball_crew_plain.glb, as the old
## SockBall measured it).
const BALL_RADIUS := 0.042

## One tint material per colour, shared by every Sock of that colour.
static var _tints: Dictionary[Color, StandardMaterial3D] = {}


## A new Looks dressed as `design`, playing `state`: a Sock's, or with `ball` a Pair's sock ball.
static func make(design: SockDesign, state: StringName = LYING, ball := false) -> Node3D:
	var looks := (BALL_LOOKS if ball else LOOKS).instantiate() as Node3D
	dress(looks, design)
	play(looks, state)
	return looks


## Tints the Body's meshes by the Design's colour and scales the Looks by its Size.
static func dress(looks: Node3D, design: SockDesign) -> void:
	if design == null:
		return
	looks.scale = Vector3.ONE * design.size_scale()
	tint(looks, design)


## Tints the Body's meshes by the Design's colour, leaving the scale as it is.
static func tint(looks: Node3D, design: SockDesign) -> void:
	if design == null:
		return
	var material: StandardMaterial3D = _tints.get(design.colour)
	if material == null:
		material = StandardMaterial3D.new()
		material.albedo_color = design.colour
		material.roughness = 0.8
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_tints[design.colour] = material
	var body := looks.get_node_or_null(^"Body")
	if body == null:
		return
	for node in body.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = material


## Plays a state of the Looks (LYING, HELD, AIMED) at once.
static func play(looks: Node, state: StringName) -> void:
	var player := looks.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	if player == null or not player.has_animation(state):
		return
	player.play(state)
	player.advance(0.0)


## The state the Looks plays now.
static func state_of(looks: Node) -> StringName:
	var player := looks.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	return player.assigned_animation if player != null else &""


## A Pair's ball radius at its Design's Size.
static func ball_radius(design: SockDesign) -> float:
	return BALL_RADIUS * (design.size_scale() if design != null else 1.0)


## The Sock's collision box at its Design's Size.
static func box(design: SockDesign) -> Vector3:
	return BOX * (design.size_scale() if design != null else 1.0)
