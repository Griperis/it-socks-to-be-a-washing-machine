## The game's player: a first-person body. It walks (move_*, at the pace of walking or crouching), looks
## (the mouse once a click has captured it, ui_cancel lets it go; the right stick), jumps and crouches.
## Interact uses the Part the crosshair is on, through Parts like any player's input (alone this player
## is the Host of one). Its Hands (core/02) are the level's Hands Part: it aims (the crosshair outlines
## a lying Sock in reach, and turns red where a drop may not go), asks to pick, cycle and drop, and
## shows what it holds in its HeldView; zoom and turn are looks of this machine. The drop button held
## past the tap with something in the Hands charges a Throw (core/08: the ring round the crosshair
## fills) and its release asks to throw along the aim; no cancel. In co-op it is the
## local player: Avatars copies its body to the others.
class_name Player
extends CharacterBody3D

## The input actions it reads (project.godot [input]), named once: a misspelt one is one line to fix.
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_FORWARD := &"move_forward"
const MOVE_BACK := &"move_back"
const JUMP := &"jump"
const CROUCH := &"crouch"
const LOOK_LEFT := &"look_left"
const LOOK_RIGHT := &"look_right"
const LOOK_UP := &"look_up"
const LOOK_DOWN := &"look_down"
const INTERACT := &"interact"
const LET_MOUSE_GO := &"ui_cancel"
const PICK := &"pick"
const DROP_THROW := &"drop_throw"
const ZOOM := &"zoom"
const TURN := &"turn"
const HANDS_NEXT := &"hands_next"
const HANDS_PREV := &"hands_prev"
## What a refusal says (the old game's words).
const HANDS_FULL := "Hands full"
const CANT_DROP := "Can't drop there"
## The crosshair where a drop may go (and always with empty Hands), and where it may not.
const CROSSHAIR_OK := Color.WHITE
const CROSSHAIR_NO := Color(1.0, 0.25, 0.2)

@export var tuning: MoveTuning
## How its Hands pick, hold and drop; its capacity is here (the zoo's player holds 3, Q2244).
@export var hands_tuning: HandsTuning

@onready var _head: Node3D = %Head
@onready var _camera: Camera3D = %Camera
@onready var _shape: CollisionShape3D = %Shape
@onready var _mesh: MeshInstance3D = %Mesh
@onready var _aim: RayCast3D = %Aim
@onready var _held_view: HeldView = %HeldView
@onready var _crosshair: Label = %Crosshair
@onready var _message: Label = %Message
@onready var _size: Label = %Size
@onready var _ring: PowerRing = %Ring

## True while a menu has the player's input (set_input_blocked()).
var _input_blocked := false
## True while this player has the mouse captured (L03): the look turns only then. Kept here as well as
## in Input.mouse_mode, which a headless run does not hold.
var _captured := false
## True while crouched (C01).
var crouching := false
## The lying Sock the crosshair rests on, or -1; the one drawn outlined.
var aimed_sock := -1
var _outlined := -1
## Whether a drop would be refused where the crosshair is now (the crosshair is red).
var drop_refused := false
## The Hands it last bound to, and the Parts whose answers it listens to.
var _hands: Hands = null
var _listening: Parts = null
## Physics time, when the drop button went down (-1: not down), how far the view is zoomed (0 to 1),
## and how long the HUD's refusal stays.
var _time := 0.0
var _drop_down_at := -1.0
var _zoom := 0.0
var _message_left := 0.0
## T01: whether a Throw is charging, and how full its ring is (0 to 1 over the charge time).
var charging := false
var charge := 0.0


func _ready() -> void:
	_aim.add_exception(self)
	# Each body sizes its own capsule: the scene's shapes are shared between instances.
	_shape.shape = _shape.shape.duplicate()
	_mesh.mesh = _mesh.mesh.duplicate()
	_camera.fov = tuning.fov
	_apply_height(tuning.stand_height)
	_camera.global_transform = Transform3D(_head.global_basis, _head.global_position)
	add_to_group(&"local_input")
	add_to_group(Hands.PLAYERS)
	if hands_tuning == null:
		hands_tuning = HandsTuning.new()
	_aim.target_position = Vector3(0.0, 0.0, -hands_tuning.reach)
	_aim.collision_mask = Mess.AIM_MASK
	_held_view.tuning = hands_tuning
	_held_view.base_fov = tuning.fov
	_message.visible = false
	_size.visible = false


## A menu over the game (the pause template tells the group `local_input`): while blocked the
## player reads no walk, jump, look, use or Hands input; it still falls and still holds what it holds.
func set_input_blocked(on: bool) -> void:
	_input_blocked = on


## This machine's player id: who its Commands come from.
func player_id() -> int:
	return multiplayer.get_unique_id()


## The level's Hands, or null where there are none (the movement station alone). Where several
## stations each have their own (the zoo), the Hands whose Mess's bounds the player stands in.
func hands() -> Hands:
	if _hands == null or not is_instance_valid(_hands) or not _hands.is_inside_tree() or not _stands_in(_hands):
		var found: Hands = null
		if is_inside_tree():
			for node in get_tree().get_nodes_in_group(Hands.GROUP):
				var h := node as Hands
				if found == null or (_stands_in(h) and not _stands_in(found)):
					found = h
		if found != _hands:
			_hands = found
			_held_view.hands = _hands
	if _hands != null and _hands.parts != null and _listening != _hands.parts:
		if _listening != null and is_instance_valid(_listening) and _listening.applied.is_connected(_on_applied):
			_listening.applied.disconnect(_on_applied)
		_listening = _hands.parts
		_listening.applied.connect(_on_applied)
	return _hands


## Whether the player stands inside the bounds of the Mess of `h` (always, with no bounds set).
func _stands_in(h: Hands) -> bool:
	return h != null and (h.mess == null or h.mess.in_bounds(global_position))


func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return
	if event is InputEventMouseButton and event.is_pressed() and not _captured:
		_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(LET_MOUSE_GO):
		_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and _captured:
		var motion := event as InputEventMouseMotion
		var step := tuning.look_sensitivity * tuning.look_scale * zoom_slow()
		_turn(-motion.relative.x * step, -motion.relative.y * step * (-1.0 if tuning.invert_y else 1.0))
	if event.is_action_pressed(HANDS_NEXT) or event.is_action_pressed(HANDS_PREV):
		var h := hands()
		if h != null and h.items_of(player_id()).size() > 1:
			h.cycle(player_id(), 1 if event.is_action_pressed(HANDS_NEXT) else -1)


## Turns the body sideways by `yaw` and tilts the head by `pitch` (radians), the tilt kept to the limit.
func _turn(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	var limit := deg_to_rad(tuning.pitch_limit)
	_head.rotation.x = clampf(_head.rotation.x + pitch, -limit, limit)


func _physics_process(delta: float) -> void:
	var walk := Vector2.ZERO if _input_blocked else Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK)
	_update_crouch(not _input_blocked and Input.is_action_pressed(CROUCH))
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	elif not _input_blocked and not crouching and Input.is_action_just_pressed(JUMP):
		velocity.y = tuning.jump_speed
	var pace := tuning.walk_speed * (tuning.crouch_speed_factor if crouching else 1.0)
	var direction := global_basis * Vector3(walk.x, 0.0, walk.y)
	velocity.x = direction.x * pace
	velocity.z = direction.z * pace
	move_and_slide()
	_time += delta
	if not _input_blocked and Input.is_action_just_pressed(INTERACT):
		interact()
	_update_hands(delta)


## C01, C02: down at once; up only when the crouched body could move up into the standing height.
func _update_crouch(want: bool) -> void:
	if not want and crouching and test_move(global_transform, Vector3.UP * (tuning.stand_height - tuning.crouch_height)):
		want = true
	if want != crouching:
		crouching = want
		_apply_height(tuning.crouch_height if crouching else tuning.stand_height)


## Sizes the capsule, its mesh and the eyes for a body `height` tall, the origin at the feet.
func _apply_height(height: float) -> void:
	var capsule := _shape.shape as CapsuleShape3D
	capsule.radius = tuning.radius
	capsule.height = height
	var mesh := _mesh.mesh as CapsuleMesh
	mesh.radius = tuning.radius
	mesh.height = height
	_shape.position.y = height * 0.5
	_mesh.position.y = height * 0.5
	_head.position.y = height - tuning.eye_below_top


## L04: the camera is top-level, drawn every frame at the head's interpolated place but turned by the
## look as it is now, so a mouse turn never waits for a physics tick. The right stick turns here too (P01).
func _process(delta: float) -> void:
	_update_zoom(delta)
	if not _input_blocked:
		var stick := Input.get_vector(LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN)
		if stick != Vector2.ZERO:
			var step := deg_to_rad(tuning.pad_look_speed) * delta * zoom_slow()
			_turn(-stick.x * step, -stick.y * step * (-1.0 if tuning.invert_y else 1.0))
	_camera.global_transform = Transform3D(_head.global_basis, _head.get_global_transform_interpolated().origin)


## What interact does: uses the Part it aims at.
func interact() -> Part:
	return use_aimed()


## Uses the Part the crosshair is on, as this player; returns it, or null when it aims at none. A
## Cabinet's drawer is clicked through its Cabinet (core/04: with Pairs held the click shelves).
func use_aimed() -> Part:
	_aim.force_raycast_update()
	var part := part_of(_aim.get_collider() as Node)
	if part != null:
		var cabinet := Cabinet.of(part)
		if cabinet != null and cabinet != part:
			cabinet.click(player_id(), cabinet.index_of(part))
		else:
			part.use(player_id())
	return part


## H21: the zoom eases the view in while held and back out when let go.
func _update_zoom(delta: float) -> void:
	var want := 1.0 if not _input_blocked and Input.is_action_pressed(ZOOM) else 0.0
	_zoom = move_toward(_zoom, want, delta / maxf(hands_tuning.zoom_time, 0.001))
	_camera.fov = lerpf(tuning.fov, hands_tuning.zoom_fov, smoothstep(0.0, 1.0, _zoom))


## How much the zoom slows the look: the view's width now over its unzoomed width.
func zoom_slow() -> float:
	return tan(deg_to_rad(_camera.fov) * 0.5) / tan(deg_to_rad(tuning.fov) * 0.5)


## The aim, the outline, the buttons of the Hands and what the HUD says, once a physics frame.
func _update_hands(delta: float) -> void:
	var h := hands()
	_message_left = maxf(_message_left - delta, 0.0)
	_message.visible = _message_left > 0.0
	if h == null:
		return
	var me := player_id()
	_aim.force_raycast_update()
	aimed_sock = h.mess.sock_at(_aim.get_collider()) if h.mess != null else -1
	_outline(h.mess, aimed_sock)
	var holding := h.active_of(me) >= 0
	drop_refused = holding and drop_refusal(h) != ""
	_crosshair.modulate = CROSSHAIR_NO if drop_refused else CROSSHAIR_OK
	_held_view.me = me
	_held_view.turning = not _input_blocked and Input.is_action_pressed(TURN)
	var design := h.mess.design_of(h.active_of(me)) if holding and h.mess != null else null
	_size.visible = design != null
	_size.text = design.size_letter() if design != null else ""
	if _input_blocked:
		# A menu opening mid-charge drops the charge without a throw.
		_drop_down_at = -1.0
		_set_charge(false)
		return
	if Input.is_action_just_pressed(PICK):
		if aimed_sock >= 0:
			_pick(h, aimed_sock)
		else:
			# D08, C01: a left click on a thing that is not a Sock uses it (a drawer, a Door, a cupboard).
			use_aimed()
	if Input.is_action_just_pressed(DROP_THROW):
		_drop_down_at = _time
	if _drop_down_at >= 0.0 and not charging and holding and _time - _drop_down_at >= hands_tuning.tap:
		_set_charge(true)
	if charging:
		charge = minf(1.0, charge + delta / maxf(hands_tuning.charge_time, 0.01))
		_ring.value = charge
	if Input.is_action_just_released(DROP_THROW) and _drop_down_at >= 0.0:
		var tapped := _time - _drop_down_at < hands_tuning.tap
		_drop_down_at = -1.0
		if charging:
			_throw(h)
		elif tapped:
			_drop(h)


## T01: starts a charge (the ring shows, empty) or ends one (the ring hides).
func _set_charge(on: bool) -> void:
	charging = on
	charge = 0.0
	_ring.value = 0.0
	_ring.visible = on


## T01-T03: asks to throw the active item along the aim with the charge the ring shows.
func _throw(h: Hands) -> void:
	var power := charge
	_set_charge(false)
	if h.active_of(player_id()) >= 0:
		h.throw(player_id(), aim_dir(), power)


## Where the eyes are, in the level: where a Throw leaves from.
func eyes() -> Vector3:
	return _head.global_position


## Where the crosshair points, a unit vector in the level.
func aim_dir() -> Vector3:
	return -_head.global_basis.z.normalized()


## The Throw's ring round the crosshair.
func ring() -> PowerRing:
	return _ring


## H01-H04: asks to pick the aimed Sock; what the Host would refuse shows first ("Hands full"; a
## click sooner than the grab interval does nothing, with no message).
func _pick(h: Hands, sock: int) -> void:
	var why := h.pick_refusal(player_id(), sock)
	if why == Hands.FULL:
		say(HANDS_FULL)
	elif why == "":
		h.pick(player_id(), sock)


## H07, H08, H28: drops the active item where the crosshair is, or says why not; empty Hands do nothing.
func _drop(h: Hands) -> void:
	if h.active_of(player_id()) < 0:
		return
	var spot := drop_spot()
	if spot.is_empty() or h.drop_refusal(player_id(), spot["point"], spot["normal"]) != "":
		say(CANT_DROP)
		return
	h.drop(player_id(), spot["point"], spot["normal"])


## Why a drop where the crosshair is would be refused now, or "" (the Host's own check).
func drop_refusal(h: Hands) -> String:
	var spot := drop_spot()
	if spot.is_empty():
		return Hands.NO_SPOT
	return h.drop_refusal(player_id(), spot["point"], spot["normal"])


## Where the crosshair meets a top within reach, seen through a gap no narrower than the drop gap:
## {"point", "normal"} in the level, or {} when it meets nothing.
func drop_spot() -> Dictionary:
	return PhysicsQueries.ball_hit(self, _head.global_position, -_head.global_basis.z * hands_tuning.reach,
			hands_tuning.drop_gap, Mess.AIM_MASK, [get_rid()])


## Shows a refusal on the HUD for a moment.
func say(text: String) -> void:
	_message.text = text
	_message_left = hands_tuning.refusal_time
	_message.visible = true


## What the HUD's refusal says now ("" when none shows).
func message() -> String:
	return _message.text if _message.visible else ""


## What the HUD shows for the held Sock's Size ("" with none).
func size_shown() -> String:
	return _size.text if _size.visible else ""


## The crosshair's colour now.
func crosshair_colour() -> Color:
	return _crosshair.modulate


## The HeldView (what the Hands show on this machine).
func held_view() -> HeldView:
	return _held_view


## The camera (the zoom changes its field of view).
func camera() -> Camera3D:
	return _camera


## The outline plays on the aimed Sock's Looks and leaves the one aimed before.
func _outline(mess: Mess, sock: int) -> void:
	if mess == null:
		return
	if _outlined != sock and _outlined >= 0:
		var old := mess.looks_of(_outlined)
		if old != null:
			SockDress.play(old, SockDress.LYING)
	_outlined = sock
	var looks := mess.looks_of(sock) if sock >= 0 else null
	if looks != null and SockDress.state_of(looks) != SockDress.AIMED:
		SockDress.play(looks, SockDress.AIMED)


## A refusal the Host answered to this player shows on the HUD.
func _on_applied(ev: Dictionary) -> void:
	if ev.get("ok", false) or int(ev.get("by", 0)) != player_id() or _hands == null:
		return
	var to := _hands.parts.of(StringName(ev.get("to", &""))) if _hands.parts != null else null
	if to is Cabinet:
		var text := String(Cabinet.SAYS.get(String(ev.get("reason", "")), ""))
		if text != "":
			say(text)
		return
	if StringName(ev.get("to", &"")) != _hands.id:
		return
	match String(ev.get("reason", "")):
		Hands.FULL:
			say(HANDS_FULL)
		Hands.NO_SPOT, Hands.FAR:
			if StringName(ev.get("kind", &"")) == &"drop":
				say(CANT_DROP)


## The Part of the thing `node` belongs to: the first part of the closest entity root above it
## (Parts.part_of(): a direct climb, cheap every frame), or null for the floor.
static func part_of(node: Node) -> Part:
	return Parts.part_of(node)
