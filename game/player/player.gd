## The game's player: a first-person body. It walks (move_*, at the pace of walking or crouching), looks
## (the mouse once a click has captured it, ui_cancel lets it go; the right stick), jumps and crouches.
## Interact uses the Part the crosshair is on, through Parts like any player's input (alone this player
## is the Host of one). Its Hands (core/02) are the level's Hands Part: it aims (the crosshair outlines
## a lying Sock in reach, and turns red where a drop may not go), asks to pick, cycle and drop, and
## shows what it holds in its HeldView; zoom and turn are looks of this machine. The drop button held
## past the tap with something in the Hands charges a Throw (core/08: the ring round the crosshair
## fills) and its release asks to throw along the aim; no cancel. In co-op it is the
## local player: Avatars copies its body to the others. Its own body (coop/06) is the sock creature's
## Looks in first person: looking down it sees its belly and feet, crouching and bending with it.
class_name Player
extends CharacterBody3D

## The input actions it reads (project.godot [input]), named once: a misspelt one is one line to fix.
## The physics layer only players meet (assets/04, Q2397): furniture's coarse player boxes, which Socks
## pass through to the pieces' own shapes. The player's mask is the house layer and this.
const BLOCK_LAYER := 8
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
## What the message row says when a pick completes a Pair (the old game.gd, core/16 P02).
const PAIRED := "Paired!"
## The crosshair where a drop may go (and always with empty Hands), and where it may not (the Hud's).
static var CROSSHAIR_OK := Hud.CROSSHAIR_OK
static var CROSSHAIR_NO := Hud.CROSSHAIR_NO
## The outline's "full" tint, on an aimed drawer with no room for the held Pairs (Q221).
const FULL_OUTLINE := preload("res://game/outline/full.tres")

@export var tuning: MoveTuning
## How its Hands pick, hold and drop; its capacity is here (the zoo's player holds 3, Q2244).
@export var hands_tuning: HandsTuning
## The Upgrades that change what its screen shows (Sock Smarts, Sock Sense; core/15). Each player
## keeps its own copy.
@export var upgrades: PlayerUpgrades

@onready var _head: Node3D = %Head
@onready var _camera: Camera3D = %Camera
@onready var _shape: CollisionShape3D = %Shape
@onready var _own_body: AvatarLooks = %OwnBody
@onready var _aim: RayCast3D = %Aim
@onready var _held_view: HeldView = %HeldView
@onready var _hud: Hud = %Hud
@onready var _ring: PowerRing = %Ring

## True while a menu has the player's input (set_input_blocked()).
var _input_blocked := false
## True while this player has the mouse captured (L03): the look turns only then. Kept here as well as
## in Input.mouse_mode, which a headless run does not hold.
var _captured := false
## True from the click that captured the mouse to the next physics frame: that frame's presses are
## the click's own and do nothing (R01).
var _swallow_press := false
## True while crouched (C01).
var crouching := false
## The lying Sock the crosshair rests on, or -1; the one drawn outlined.
var aimed_sock := -1
var _outlined := -1
## The Outline of the thing (not a Sock) the crosshair rests on, or null; the one shown (core/11).
var aimed_outline: Outline = null
## Whether a drop would be refused where the crosshair is now (the crosshair is red).
var drop_refused := false
## This physics tick's drop spot ({} for none) and why the Host would refuse it ("" for nothing), found
## once from the tick's aim; a drop click in the same tick uses them.
var _tick_spot: Dictionary = {}
## How many times the aim was looked up (a timing case counts these per tick, not wall time).
var aim_finds := 0
var _tick_refusal := ""
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
	_hud.hide_message()
	upgrades = upgrades.duplicate() as PlayerUpgrades if upgrades != null else PlayerUpgrades.new()
	_hud.camera = _camera
	_hud.held_view = _held_view
	_hud.hands_tuning = hands_tuning


## A menu over the game (the pause template tells the group `local_input`): while blocked the
## player reads no walk, jump, look, use or Hands input; it still falls and still holds what it holds.
func set_input_blocked(on: bool) -> void:
	_input_blocked = on


## This machine's player id: who its Commands come from.
func player_id() -> int:
	return multiplayer.get_unique_id()


## The level's one Hands (the zoo's for every station, Q2284), or null where there are none (the
## movement station alone). Where several levels share the tree (two zoos in a co-op test), the
## Hands of this player's own scene.
func hands() -> Hands:
	if _hands == null or not is_instance_valid(_hands) or not _hands.is_inside_tree():
		var found: Hands = null
		if is_inside_tree():
			for node in get_tree().get_nodes_in_group(Hands.GROUP):
				var h := node as Hands
				if found == null or (owner != null and h.owner == owner and found.owner != owner):
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


func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return
	if event is InputEventMouseButton and event.is_pressed() and not _captured:
		# L03, R01: the click that captures does nothing else; the wheel never captures.
		if not _is_wheel(event as InputEventMouseButton):
			capture_mouse()
			_swallow_press = true
	elif event.is_action_pressed(LET_MOUSE_GO):
		_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and _captured:
		var motion := event as InputEventMouseMotion
		var step := tuning.look_sensitivity * tuning.look_scale * zoom_slow()
		_turn(-motion.relative.x * step, -motion.relative.y * step * (-1.0 if tuning.invert_y else 1.0))
	if _captured and (event.is_action_pressed(HANDS_NEXT) or event.is_action_pressed(HANDS_PREV)):
		var h := hands()
		if h != null and h.items_of(player_id()).size() > 1:
			h.cycle(player_id(), 1 if event.is_action_pressed(HANDS_NEXT) else -1)


## This player takes the mouse (a click does it; the pause menu and tests too): from now on the look
## turns and the buttons act.
func capture_mouse() -> void:
	_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


static func _is_wheel(event: InputEventMouseButton) -> bool:
	return event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]


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


## Sizes the capsule and the eyes for a body `height` tall, the origin at the feet.
func _apply_height(height: float) -> void:
	var capsule := _shape.shape as CapsuleShape3D
	capsule.radius = tuning.radius
	capsule.height = height
	_shape.position.y = height * 0.5
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
	_drive_own_body(delta)
	_camera.global_transform = Transform3D(_head.global_basis, _head.get_global_transform_interpolated().origin)


## The own body bends with the look and eases into the crouch, as a Teammate's avatar does.
func _drive_own_body(delta: float) -> void:
	_own_body.look_pitch = _head.rotation.x
	_own_body.set_crouch(move_toward(_own_body.crouch, 1.0 if crouching else 0.0, delta * _own_body.tuning.crouch_follow))


## The player's own body seen from their eyes (the sock creature's Looks in first person).
func own_body() -> AvatarLooks:
	return _own_body


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
	var want := 1.0 if _acting() and Input.is_action_pressed(ZOOM) else 0.0
	_zoom = move_toward(_zoom, want, delta / maxf(hands_tuning.zoom_time, 0.001))
	_camera.fov = lerpf(tuning.fov, hands_tuning.zoom_fov, smoothstep(0.0, 1.0, _zoom))


## How much the zoom slows the look: the view's width now over its unzoomed width.
func zoom_slow() -> float:
	return tan(deg_to_rad(_camera.fov) * 0.5) / tan(deg_to_rad(tuning.fov) * 0.5)


## The aim, the outline, the buttons of the Hands and what the HUD says, once a physics frame.
func _update_hands(delta: float) -> void:
	var h := hands()
	_message_left = maxf(_message_left - delta, 0.0)
	if _message_left <= 0.0:
		_hud.hide_message()
	if h == null:
		_update_screen(null)
		return
	var me := player_id()
	var found := aim_found(h)
	aimed_sock = found["sock"]
	_outline(h.mess, aimed_sock)
	_outline_thing(_aimed_outline(h.mess, aimed_sock, found["lying"]))
	var holding := h.active_of(me) >= 0
	_tick_spot = {}
	_tick_refusal = ""
	if holding:
		_tick_spot = drop_spot(found)
		_tick_refusal = _refusal_of(h, _tick_spot)
	drop_refused = _tick_refusal != ""
	_held_view.me = me
	_held_view.turning = _acting() and Input.is_action_pressed(TURN)
	_update_screen(h)
	if not _acting():
		# A menu opening or the mouse let go mid-charge drops the charge without a throw.
		_drop_down_at = -1.0
		_set_charge(false)
		_swallow_press = false
		return
	if _swallow_press:
		_swallow_press = false
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


## Whether the buttons of the Hands, the zoom and the turn act: not under a menu, and only with the
## mouse captured (L03, R01).
func _acting() -> bool:
	return _captured and not _input_blocked


## T01: starts a charge (the ring shows, empty) or ends one (the ring hides).
func _set_charge(on: bool) -> void:
	if on and not charging:
		Sounds.play(&"throw_charge")
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
	var spot := _tick_spot
	if spot.is_empty() or _tick_refusal != "":
		say(CANT_DROP)
		return
	h.drop(player_id(), spot["point"], spot["normal"])


## Why a drop where the crosshair is would be refused now, or "" (the Host's own check).
func drop_refusal(h: Hands) -> String:
	return _refusal_of(h, drop_spot())


func _refusal_of(h: Hands, spot: Dictionary) -> String:
	if spot.is_empty():
		return Hands.NO_SPOT
	return h.drop_refusal(player_id(), spot["point"], spot["normal"])


## The Sock or Pair under the crosshair, lying or moving (R02, R03): AimFinder.find()'s answer.
func aim_found(h: Hands) -> Dictionary:
	aim_finds += 1
	return AimFinder.find(self, h.mess, _head.global_position, aim_dir(), hands_tuning.reach, [get_rid()])


## Where the crosshair meets a top within reach, seen through a gap no narrower than the drop gap:
## {"point", "normal"} in the level, or {} when it meets nothing. A lying Sock or Pair under the
## crosshair takes the drop anywhere on it (R05). `found`: the tick's aim_found(), or {} to look it up.
func drop_spot(found: Dictionary = {}) -> Dictionary:
	var h := hands()
	if h != null and h.mess != null:
		if found.is_empty():
			found = aim_found(h)
		if found["sock"] >= 0 and found["lying"]:
			return {"point": found["point"], "normal": Vector3.UP}
	return PhysicsQueries.ball_hit(self, _head.global_position, -_head.global_basis.z * hands_tuning.reach,
			hands_tuning.drop_gap, Mess.AIM_MASK, [get_rid()])


## Shows a refusal on the HUD for a moment: the red line wobbles (core/16 P01).
func say(text: String) -> void:
	Sounds.play(&"refuse")
	_hud.say(text, true)
	_message_left = hands_tuning.refusal_time


## Shows "Paired!" on the HUD for a moment, white, popping in (core/16 P02).
func say_paired() -> void:
	_hud.say(PAIRED, false)
	_message_left = hands_tuning.refusal_time


## Shows a teammate's line on the HUD for `seconds` (coop/03): `who` in `colour`, then `rest`.
func announce(who: String, colour: Color, rest: String, seconds: float) -> void:
	_hud.say_named(who, colour, rest)
	_message_left = seconds


## Shows a plain white line on the HUD for `seconds` ("Joined Player's zoo", why a session ended).
func notice(text: String, seconds: float) -> void:
	_hud.say(text, false)
	_message_left = seconds


## What the HUD's refusal says now ("" when none shows; "Paired!" is read from the Hud).
func message() -> String:
	return _hud.refusal_text()


## What the HUD shows for the held Sock's Size ("" with none).
func size_shown() -> String:
	return _hud.held_size()


## The crosshair's tint now (CROSSHAIR_OK or CROSSHAIR_NO).
func crosshair_colour() -> Color:
	return _hud.crosshair_tint()


## The screen: the prompts, the hints, the readouts and the crosshair.
func hud() -> Hud:
	return _hud


## A01-A16: tells the Hud what the aim and the Hands mean for the screen now; the Hud redraws a row
## only when it changed. `h` is null where there are no Hands (the movement station).
func _update_screen(h: Hands) -> void:
	var me := player_id()
	var mess := h.mess if h != null else null
	_hud.show_blocked(drop_refused)
	var sock := aimed_sock if mess != null else -1
	var aimed := mess.design_of(sock) if sock >= 0 else null
	_hud.show_aimed(aimed.size_letter() if aimed != null else "", _first(Prompts.keys(PICK, _hud.pad)))
	var part: Part = null
	if sock < 0:
		_aim.force_raycast_update()
		part = part_of(_aim.get_collider() as Node)
	_hud.show_target(Prompts.target(part, _hud.pad))
	var items := h.items_of(me) if h != null else PackedInt32Array()
	var capacity := h.tuning_of(me).capacity if h != null else 0
	_hud.show_hints(Prompts.hints(items.size(), _hud.pad))
	# A15: what picking the aimed loose Sock would make the Hands show.
	if aimed != null and upgrades.sense() and not mess.is_pair(sock):
		var pairs := h.mate_held(me, sock) >= 0
		var n := items.size() + (0 if pairs or items.size() >= capacity else 1)
		_hud.show_sense(aimed, pairs, "%d/%d" % [n, capacity], n > 1)
	else:
		_hud.show_sense(null)
	var active := h.active_of(me) if h != null else -1
	var held := mess.design_of(active) if active >= 0 and mess != null else null
	_hud.show_held(held, held != null and mess.is_pair(active), "%d/%d" % [items.size(), capacity],
			items.size() > 1, upgrades.smarts())


static func _first(list: Array[String]) -> String:
	return list[0] if not list.is_empty() else ""


## The HeldView (what the Hands show on this machine).
func held_view() -> HeldView:
	return _held_view


## The camera (the zoom changes its field of view).
func camera() -> Camera3D:
	return _camera


## The outline plays on the aimed Sock's Looks (the Mess lends it, core/13) and the one aimed before
## gives its Looks back.
func _outline(mess: Mess, sock: int) -> void:
	if mess == null:
		return
	if _outlined != sock and _outlined >= 0:
		mess.return_looks(_outlined)
	_outlined = sock
	var looks := mess.looks_of(sock) if sock >= 0 else null
	if looks != null and SockDress.state_of(looks) != SockDress.AIMED:
		SockDress.play(looks, SockDress.AIMED)


## The Outline the crosshair shows besides a lying Sock's: a moving Sock's flight Looks' (O08; a
## flight drawn without a Looks has none), else the aimed thing's (O03), else null.
func _aimed_outline(mess: Mess, sock: int, lying: bool) -> Outline:
	if sock >= 0:
		return Outline.of(mess.flight_of(sock)) if not lying and mess != null else null
	return Outline.of(_aim.get_collider() as Node)


## O01-O04: the thing the crosshair rests on shows its Outline and the one aimed before hides its own.
## An aimed drawer with no room for the held Pairs takes the "full" tint (Q221).
func _outline_thing(outline: Outline) -> void:
	if aimed_outline != outline and is_instance_valid(aimed_outline):
		aimed_outline.shown = false
		aimed_outline.tint = null
	aimed_outline = outline
	if outline == null:
		return
	outline.tint = FULL_OUTLINE if _aims_full_drawer() else null
	if not outline.shown:
		outline.shown = true


## Whether the crosshair is on a Cabinet's drawer with no room while this player holds a Pair.
func _aims_full_drawer() -> bool:
	var part := part_of(_aim.get_collider() as Node)
	var cabinet := Cabinet.of(part)
	if cabinet == null or cabinet == part:
		return false
	return cabinet.holds_pair(player_id()) and not cabinet.has_room(cabinet.index_of(part))


## A refusal the Host answered to this player shows on the HUD.
func _on_applied(ev: Dictionary) -> void:
	if _hands != null:
		Hearing.applied(ev, player_id(), _hands.parts)
	if ev.get("ok", false) and int(ev.get("by", 0)) == player_id() and ev.has("paired") \
			and StringName(ev.get("kind", &"")) == &"pick":
		say_paired()
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
