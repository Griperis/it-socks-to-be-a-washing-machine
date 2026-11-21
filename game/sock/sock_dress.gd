## Dresses a Sock's Looks (a scene with the contract in looks_contract.json: Body, Outline, an
## AnimationPlayer with lying, held and aimed) as one Design: its Collection's shape model or sock
## ball drawn by the sock shader with its look (SockLook, assets/01), scaled by its Size (Q2249). The
## states play in the Looks' AnimationPlayer, never in code (Q2213). Used by the Mess (lying and
## falling Socks and Pairs) and the HeldView (the Hands). A Pair is drawn as one sock ball (the same
## contract, its centre at its origin: P06).
class_name SockDress
extends RefCounted

## The animations every Sock Looks has.
const LYING := &"lying"
const HELD := &"held"
const AIMED := &"aimed"
## The flat Sock's box at Size medium (the crew model lying flat, its bottom at y = 0): every
## shape's box today.
const BOX := Vector3(0.3, 0.026, 0.18)


## A new Looks dressed as `design`, playing `state`: a Sock's, or with `ball` a Pair's sock ball.
static func make(design: SockDesign, state: StringName = LYING, ball := false) -> Node3D:
	return SockLook.make(design, state, ball)


## Draws the Looks as the Design and scales it by its Size.
static func dress(looks: Node3D, design: SockDesign) -> void:
	SockLook.dress(looks, design, SockLook.is_ball(looks))


## Draws the Looks as the Design, leaving the scale as it is.
static func tint(looks: Node3D, design: SockDesign) -> void:
	SockLook.paint(looks, design, SockLook.is_ball(looks))


## `looks` replaced, in its parent and place, by a new Looks of `design` playing `state` (a Sock's,
## or with `ball` a Pair's ball), its scale kept: a scene's stand-in Looks becomes the Design's shape.
static func swap(looks: Node3D, design: SockDesign, state: StringName, ball := false) -> Node3D:
	var fresh := make(design, state, ball)
	fresh.name = looks.name
	fresh.transform = looks.transform
	var parent := looks.get_parent()
	var at := looks.get_index()
	parent.remove_child(looks)
	looks.queue_free()
	parent.add_child(fresh)
	parent.move_child(fresh, at)
	return fresh


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


## A Pair's ball radius at its Design's Size (its Collection's ball, half its height).
static func ball_radius(design: SockDesign) -> float:
	return SockLook.ball_radius(SockLook.TABLE.cuff_of(design)) * (design.size_scale() if design != null else 1.0)


## The Sock's collision box at its Design's Size.
static func box(design: SockDesign) -> Vector3:
	return BOX * (design.size_scale() if design != null else 1.0)
