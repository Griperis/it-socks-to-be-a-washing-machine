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
##
## Knocked down (coop/10): while the level's Knockdowns says it is down its input is frozen as by a menu
## (a charge is dropped, a drag let go), save the jump key, which struggles while it is dragged; its body
## stays at its ragdoll's feet, the camera rides the ragdoll's head (stopping wall_gap short of a wall),
## its own body copies the ragdoll and a vignette darkens the edges; the HUD stays. With empty Hands, a
## lying Teammate under the crosshair wins the left button over a Sock or a thing (Q2493): held, it drags
## them by the feet at drag_speed of the pace, let go it drops them.
##
## Stacking (core/41): its Stack (PlayerStack) does its side of standing on a Teammate's back: it meets a
## back only from above, rides one it stands on (staying crouched, so it cannot jump off), climbs onto one
## with a jump near it (tucked into a crouch), walks at carry_speed with anyone on its own back and stands
## up only with room for them; and the soft push between standing players (Q263).
##
## The Hand-off (core/42): holding something, a Teammate under the crosshair in reach (AimFinder.mate(),
## nearer than the aimed Sock) is aimed: their avatar shows its Outline, the crosshair is never red,
## the corner still says "Drop", and a short right click asks to hand them the active item instead of
## a drop. What the Host answers shows here: "Not their mate" to the giver, "Paired!" or "Hands full"
## to the receiver.
##
## Pings (core/43): its Pinger reads the middle button (a tap pings, a hold opens the emoji wheel);
## while the wheel is open the mouse and the right stick steer its pointer, not the view.
class_name Player
extends CharacterBody3D

## The input actions it reads (project.godot [input]), named once: a misspelt one is one line to fix.
## The physics layer only players meet (assets/04, Q2397): furniture's coarse player boxes, which Socks
## pass through to the pieces' own shapes. The player's mask is the house layer, this, the ragdolls'
## and the Teammates' backs (Back.LAYER, core/41).
const BLOCK_LAYER := 8
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_FORWARD := &"move_forward"
const MOVE_BACK := &"move_back"
const JUMP := &"jump"
const CROUCH := &"crouch"
## Held, the walk runs (core/130): only once Sprint is bought.
const SPRINT := &"sprint"
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
## What the giver reads when a loose Sock completes no Pair in the Teammate's Hands (the old game.gd NOT_MATE).
const NOT_THEIR_MATE := "Not their mate"
## What the message row says when a pick completes a Pair (the old game.gd, core/16 P02).
const PAIRED := "Paired!"
## What the knocked player reads (the old teammate_news_installer.gd, Q2494): the thrower's name, then this.
const KNOCKED_YOU := "knocked you down"
const KNOCKED_BY_UNKNOWN := "A teammate"
## The crosshair where a drop may go (and always with empty Hands), and where it may not (the Hud's).
static var CROSSHAIR_OK := Hud.CROSSHAIR_OK
static var CROSSHAIR_NO := Hud.CROSSHAIR_NO
## The outline's "full" tint, on an aimed drawer with no room for the held Pairs (Q221).
const FULL_OUTLINE := preload("res://game/outline/full.tres")

@export var tuning: MoveTuning
## How its Hands pick, hold and drop; its capacity is here (the zoo's player holds 3, Q2244). Where the
## level has its own Upgrades Part, the levels grow it and three more from here (Hands.tuning_of()).
@export var hands_tuning: HandsTuning
## The Upgrades that change what its screen shows (Sock Smarts, Sock Sense; core/15). Each player
## keeps its own copy.
@export var upgrades: PlayerUpgrades
## The stats of Footwork (the walk's factor) and Sprint (held Shift runs), read from the level's
## Upgrades when they are used (core/130); a level without an Upgrades Part walks at its own pace.
@export var walk_stat: UpgradeStat = preload("res://game/economy/stats/walk_speed.tres")
@export var sprint_stat: UpgradeStat = preload("res://game/economy/stats/sprint.tres")

@onready var _head: Node3D = %Head
@onready var _camera: Camera3D = %Camera
@onready var _shape: CollisionShape3D = %Shape
@onready var _own_body: AvatarLooks = %OwnBody
## The player's full body as a wall mirror shows it (assets/07, Q2505): hidden, and on a render layer
## this player's camera skips, while no mirror renders.
@onready var _mirror_body: AvatarLooks = %MirrorBody
@onready var _aim: RayCast3D = %Aim
@onready var _held_view: HeldView = %HeldView
@onready var _hud: Hud = %Hud
@onready var _ring: PowerRing = %Ring
## A Guest's looks-only guesses of its own pick, drop, Throw and wheel (coop/09).
@onready var _ghosts: GuestGhosts = %Ghosts
## The knocked view's vignette (Q2490).
@onready var _vignette: ColorRect = %Vignette
## Its side of stacking and the soft push (core/41).
@onready var _stack: PlayerStack = %Stack
## The middle button's pings and the emoji wheel (core/43).
@onready var _pinger: Pinger = %Pinger

## True while a menu (set_input_blocked()), a cutscene (set_cutscene(), core/88) or a washing machine's
## drum (set_washed(), core/98) has the player's input.
var _input_blocked: bool:
	get: return _menu_blocked or _cutscene or _washed
var _menu_blocked := false
var _cutscene := false
## In a washing machine's drum (core/98): held still at `_wash_hold`, out of play.
var _washed := false
var _wash_hold := Vector3.ZERO
## True while this player has the mouse captured (L03): the look turns only then. Kept here as well as
## in Input.mouse_mode, which a headless run does not hold.
var _captured := false
## True from the click that captured the mouse to the next physics frame: that frame's presses are
## the click's own and do nothing (R01).
var _swallow_press := false
## True while crouched (C01).
var crouching := false
## How many times it has jumped (climbs too): its Avatar's pose carries it, so Teammates hear each one.
var jumps := 0
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
## coop/10: the level's Knockdowns, whether this player lies down now, the lying body (a peer) the
## crosshair is on (-1: none), whether the left button holds a grab, and how far from the body's middle
## the eyes may be this tick (a wall between: wall_gap short of it).
var _knockdowns: Knockdowns
var knocked := false
var aimed_body := -1
## core/42: the Teammate (a peer) a short right click would hand the active item to now, or -1.
var aimed_mate := -1
var _grab_held := false
var _eye_reach := INF


func _ready() -> void:
	_aim.add_exception(self)
	# A Teammate's back carries a rider by what it moved (PlayerStack), never as a moving floor.
	platform_floor_layers = platform_floor_layers & ~Back.LAYER
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


## Whether a menu holds the player's input now (the Tab overlay stays shut while one does).
func input_blocked() -> bool:
	return _input_blocked


## A menu over the game (the pause template tells the group `local_input`): while blocked the
## player reads no walk, jump, look, use or Hands input; it still falls and still holds what it holds.
func set_input_blocked(on: bool) -> void:
	_menu_blocked = on
	if on:
		_let_go_body()  # H97: a menu lets go of a dragged body


## A cutscene plays (core/88, the CutscenePlayer): the input is off as under a menu (a menu closing in it
## gives none back), a charge is dropped, a drag let go, and the HUD hidden; off, both come back.
func set_cutscene(on: bool) -> void:
	_cutscene = on
	_hud.visible = not on and not _washed
	if on:
		_set_charge(false)
		_let_go_body()


## In a washing machine's drum (core/98, the washer's `WashView`): the body is held still at `hold`, out of
## the way, the input and the HUD are off (Q991); off, the HUD comes back (a cutscene's keeps it off).
## The view is the WashView's own camera meanwhile.
func set_washed(on: bool, hold := Vector3.ZERO) -> void:
	_washed = on
	_wash_hold = hold
	_hud.visible = not on and not _cutscene
	if on:
		_set_charge(false)
		_let_go_body()
		_stack.drop()
		crouching = false
		_apply_height(tuning.stand_height)
		velocity = Vector3.ZERO
		global_position = hold
		reset_physics_interpolation()


## Whether this player spins in a drum now.
func is_washed() -> bool:
	return _washed


## Whether a cutscene has this player's input.
func in_cutscene() -> bool:
	return _cutscene


## Stands the body at `at` (a cutscene's respawn by the washer, core/88): still, standing, off any back,
## looking along the marker's -Z with the head level.
func respawn_at(at: Transform3D) -> void:
	_stack.drop()
	velocity = Vector3.ZERO
	crouching = false
	_apply_height(tuning.stand_height)
	global_position = at.origin
	var forward := -at.basis.z
	rotation.y = atan2(-forward.x, -forward.z)
	_head.rotation.x = 0.0
	reset_physics_interpolation()


## This machine's player id: who its Commands come from.
func player_id() -> int:
	return multiplayer.get_unique_id()


## Footwork's factor on the walk for this player now: 1 with no Upgrades Part in the level.
func walk_factor() -> float:
	var levels := _levels()
	return levels.value(walk_stat, player_id()) if levels != null else 1.0


## Whether this player has bought Sprint (nobody sprints without it, Q1343).
func can_sprint() -> bool:
	var levels := _levels()
	return levels != null and levels.value(sprint_stat, player_id()) >= 1.0


## The level's Upgrades this player's levels are read from (bound as the Hands are found), or null.
func _levels() -> Upgrades:
	var h := hands()
	var levels := upgrades.levels if upgrades != null else null
	if levels == null or not is_instance_valid(levels) or h == null or levels.parts != h.parts:
		return null  # a level without its own Upgrades Part walks at its own pace
	return levels


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
	if _hands != null and upgrades != null:
		# core/129: Sock Smarts and Sense bought at the Old Tree, read from this level's Upgrades.
		if upgrades.levels == null or not is_instance_valid(upgrades.levels) or upgrades.levels.parts != _hands.parts:
			upgrades.levels = Upgrades.of(_hands)
		upgrades.player = player_id()
	return _hands


func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return
	if knocked and (event is InputEventMouseMotion or event.is_action_pressed(HANDS_NEXT) or event.is_action_pressed(HANDS_PREV)):
		return  # F68: the look follows the ragdoll, not the mouse
	if event is InputEventMouseButton and event.is_pressed() and not _captured:
		# L03, R01: the click that captures does nothing else; the wheel never captures.
		if not _is_wheel(event as InputEventMouseButton):
			capture_mouse()
			_swallow_press = true
	elif event.is_action_pressed(LET_MOUSE_GO):
		_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and _captured and _pinger.steering():
		_pinger.steer((event as InputEventMouseMotion).relative)  # core/43 line 4: the wheel, not the view
	elif event is InputEventMouseMotion and _captured:
		var motion := event as InputEventMouseMotion
		var step := tuning.look_sensitivity * Settings.get_float(Settings.MOUSE_SPEED) * zoom_slow()
		_turn(-motion.relative.x * step, -motion.relative.y * step * _y_sign())
	if _captured and (event.is_action_pressed(HANDS_NEXT) or event.is_action_pressed(HANDS_PREV)):
		var h := hands()
		if h != null and h.items_of(player_id()).size() > 1:
			var step := 1 if event.is_action_pressed(HANDS_NEXT) else -1
			if _ghosts.active():
				_ghosts.cycle(step)
			else:
				h.cycle(player_id(), step)


## This player takes the mouse (a click does it; the pause menu and tests too): from now on the look
## turns and the buttons act.
func capture_mouse() -> void:
	_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## The look's up-down sign: Options' Invert Y (a setting of this machine).
func _y_sign() -> float:
	return -1.0 if Settings.get_bool(Settings.INVERT_Y) else 1.0


static func _is_wheel(event: InputEventMouseButton) -> bool:
	return event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]


## Turns the body sideways by `yaw` and tilts the head by `pitch` (radians), the tilt kept to the limit.
func _turn(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	var limit := deg_to_rad(tuning.pitch_limit)
	_head.rotation.x = clampf(_head.rotation.x + pitch, -limit, limit)


func _physics_process(delta: float) -> void:
	var kd := knockdowns()
	var down := kd != null and kd.is_down(player_id())
	if down != knocked:
		_set_knocked(down)
	if _washed:
		velocity = Vector3.ZERO
		global_position = _wash_hold
		_time += delta
		return
	if knocked:
		_stack.drop()
		_lie(kd)
		_fall_while_down(kd)
		_time += delta
		_update_hands(delta)
		return
	if _out_of_map():
		_put_back()
		return
	_stack.before_move()
	var walk := Vector2.ZERO if _input_blocked else Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK)
	_update_crouch(not _input_blocked and Input.is_action_pressed(CROUCH))
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	elif not _input_blocked and not crouching and Input.is_action_just_pressed(JUMP):
		_jump()
	var pace := tuning.walk_speed * walk_factor() * _stack.carry
	if crouching:
		pace *= tuning.crouch_speed_factor  # crouching cancels a sprint (the old player.gd)
	elif not _input_blocked and Input.is_action_pressed(SPRINT) and can_sprint():
		pace *= tuning.sprint_multiplier
	if kd != null and kd.dragging_of(player_id()) >= 0:
		pace *= kd.tuning.drag_speed  # H95
	var direction := global_basis * Vector3(walk.x, 0.0, walk.y)
	var extra := _stack.extra_velocity()
	velocity.x = direction.x * pace + extra.x
	velocity.z = direction.z * pace + extra.z
	move_and_slide()
	_stack.after_move()
	_time += delta
	if not _input_blocked and Input.is_action_just_pressed(INTERACT):
		interact()
	_update_hands(delta)


# --- Out of the map ------------------------------------------------------------------------------

## Whether the body is below the level's lowest floor by `fall_depth`, farther than `fall_reach` from
## its centre on any axis, or not finite.
func _out_of_map(at := global_position) -> bool:
	var runtime := LevelRuntime.of(self)
	if runtime == null:
		return false
	var frame := runtime.map_frame()
	return FallRescue.out_of_map(at, frame["floor"], frame["centre"], tuning.fall_depth, tuning.fall_reach)


## A knocked-down body (it follows its ragdoll) out of the map has its knockdown ended, as a cutscene's end
## does; the body then stands and the check above puts it back.
func _fall_while_down(kd: Knockdowns) -> void:
	var rag := own_ragdoll()
	var at := rag.feet() if rag != null and rag.phase != Ragdoll.Phase.UP else global_position
	if _out_of_map(at) or _out_of_map():
		kd.stand(player_id())


## Puts the body back at the washer's spawn (the level's Spawn without one) and logs where it was.
func _put_back() -> void:
	var runtime := LevelRuntime.of(self)
	var at: Variant = runtime.respawn_point()
	if at == null:
		return
	Log.warn("player", "out of the map at %s: put back" % [global_position], {"from": global_position})
	respawn_at(at as Transform3D)


# --- Knocked down (coop/10) ----------------------------------------------------------------------

## The level's Knockdowns (with two zoos in one tree, this player's own), or null.
func knockdowns() -> Knockdowns:
	if _knockdowns == null or not is_instance_valid(_knockdowns):
		if not is_inside_tree():
			return null
		for node in get_tree().get_nodes_in_group(Knockdowns.GROUP):
			var k := node as Knockdowns
			if _knockdowns == null or (owner != null and k.owner == owner):
				_knockdowns = k
	return _knockdowns


## This player's own ragdoll (its avatar's on this machine), or null: alone it has none.
func own_ragdoll() -> Ragdoll:
	var kd := knockdowns()
	return kd.ragdoll_of(player_id()) if kd != null else null


## Down (F68, L145): the charge goes, a drag is let go, the vignette shows. Up: the own body stands, the
## view returns to the head.
func _set_knocked(on: bool) -> void:
	knocked = on
	_eye_reach = INF
	if on:
		_drop_down_at = -1.0
		_set_charge(false)
		_let_go_body()
		crouching = false
		_apply_height(tuning.stand_height)
		var t := knockdowns().tuning
		var mat := _vignette.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter(&"dark", t.vignette_dark)
			mat.set_shader_parameter(&"start", t.vignette_start)
	else:
		_own_body.end_ragdoll()
		reset_physics_interpolation()
	_vignette.visible = on


## One tick lying: the body stays at the ragdoll's feet (G85, K142), the eyes' wall test runs (F70,
## F71), and the jump key struggles while dragged (H105).
func _lie(kd: Knockdowns) -> void:
	velocity = Vector3.ZERO
	var rag := own_ragdoll()
	if rag != null and rag.phase != Ragdoll.Phase.UP:
		global_position = rag.floor_under(rag.feet())
		var middle := rag.point_at(tuning.stand_height * 0.5)
		var eye := rag.point_at(kd.tuning.eye)
		var hit := PhysicsQueries.ray(self, middle, eye, Mess.LAYER_HOUSE, [get_rid()])
		_eye_reach = maxf(0.0, middle.distance_to(hit["position"]) - kd.tuning.wall_gap) if not hit.is_empty() else INF
	if not _input_blocked and kd.dragger_of(player_id()) >= 0 and Input.is_action_just_pressed(JUMP):
		kd.struggle(player_id())


## F69, F72: the camera on the ragdoll's head as drawn, the pitch it had, never past the wall test.
func _knocked_camera() -> void:
	var rag := own_ragdoll()
	if rag == null or rag.phase == Ragdoll.Phase.UP:
		return
	var moves := rag.motions()
	_own_body.copy_ragdoll(moves)
	var t := knockdowns().tuning
	var head := moves[Ragdoll.BONES - 1]
	var middle := moves[1] * (Vector3.UP * tuning.stand_height * 0.5)
	var eye := head * (Vector3.UP * t.eye)
	if middle.distance_to(eye) > _eye_reach:
		eye = middle + (eye - middle).normalized() * _eye_reach
	_camera.global_transform = Transform3D(head.basis.orthonormalized() * Basis(Vector3.RIGHT, _head.rotation.x), eye)


## The camera, now (a test's still or check reads it).
func view() -> Transform3D:
	return _camera.global_transform


## Lets go of the body this player drags, or of a grab not answered yet.
func _let_go_body() -> void:
	var kd := knockdowns()
	var held := _grab_held
	_grab_held = false
	if kd != null and (held or kd.dragging_of(player_id()) >= 0):
		kd.let_go(player_id())


## A jump from the floor (heard as "jump", flat; Teammates hear it at its body); near a Teammate's back it is a climb (core/41, lists 13-15): fast enough to
## clear the back, tucked into a crouch at once, steered over the back until it lands.
func _jump() -> void:
	velocity.y = tuning.jump_speed
	jumps += 1
	Sounds.play(&"jump")  # every jump, a climb too (Q2593); its Avatar's pose carries the count
	var to := _stack.climb_target()
	if to != null:
		velocity.y = _stack.climb_speed(to)
		_stack.climb_to = to
		crouching = true
		_apply_height(tuning.crouch_height)


## C01, C02: down at once; up only when the crouched body could move up into the standing height, with
## the stack on its back too (core/41, list 29). A rider or a climber stays crouched (list 22).
func _update_crouch(want: bool) -> void:
	if not want and crouching and (_stack.keeps_crouched() or test_move(global_transform,
			Vector3.UP * (tuning.stand_height - tuning.crouch_height + _stack.load_height))):
		want = true
	if want != crouching:
		crouching = want
		_apply_height(tuning.crouch_height if crouching else tuning.stand_height)


## How tall the body is now (crouched or standing), from the feet.
func body_height() -> float:
	return (_shape.shape as CapsuleShape3D).height


## Whether it stands on a Teammate's back now (core/41).
func riding() -> bool:
	return _stack.ride != null


## Its side of stacking (core/41).
func stack() -> PlayerStack:
	return _stack


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
	if knocked:
		_knocked_camera()
		return
	if not _input_blocked:
		var stick := Input.get_vector(LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN)
		if _pinger.steering():
			if _hud.pad:
				_pinger.aim_stick(stick)  # core/43 line 8: the right stick steers the wheel
		elif stick != Vector2.ZERO:
			var step := deg_to_rad(tuning.pad_look_speed) * Settings.get_float(Settings.PAD_SPEED) * delta * zoom_slow()
			_turn(-stick.x * step, -stick.y * step * _y_sign())
	_drive_own_body(delta)
	_camera.global_transform = Transform3D(_head.global_basis, _head.get_global_transform_interpolated().origin)


## The own body bends with the look and eases into the crouch, as a Teammate's avatar does.
func _drive_own_body(delta: float) -> void:
	_own_body.look_pitch = _head.rotation.x
	_own_body.set_crouch(move_toward(_own_body.crouch, 1.0 if crouching else 0.0, delta * _own_body.tuning.crouch_follow))
	if _mirror_body.visible:
		_mirror_body.look_pitch = _own_body.look_pitch
		_mirror_body.set_crouch(_own_body.crouch)
		if _mirror_body.colour != _own_body.colour:
			_mirror_body.colour = _own_body.colour


## The player's own body seen from their eyes (the sock creature's Looks in first person).
func own_body() -> AvatarLooks:
	return _own_body


## The player's full body that only a wall mirror shows (Mirror).
func mirror_body() -> AvatarLooks:
	return _mirror_body


## What interact does: uses the Part it aims at, unless the left click alone uses it (a piano key).
func interact() -> Part:
	_aim.force_raycast_update()
	var part := aimed_part()
	if part != null and part.click_only():
		return null
	return use_aimed()


## Uses the Part the crosshair is on, as this player; returns it, or null when it aims at none. A
## Cabinet's drawer is clicked through its Cabinet (core/04: with Pairs held the click shelves).
func use_aimed() -> Part:
	_aim.force_raycast_update()
	var part := aimed_part()
	if part != null:
		var cabinet := Cabinet.of(part)
		if cabinet != null and cabinet != part:
			cabinet.click(player_id(), cabinet.index_of(part))
		elif part is Carriable:
			_pick_carriable(part as Carriable)
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
	# core/78: a carried thing takes the whole Hands; it is put down or handed over, never thrown.
	var carried := h.carries(me)
	var socks := h.active_of(me) >= 0
	var holding := socks or carried != null
	var kd := knockdowns()
	aimed_body = kd.aimed_body(eyes(), aim_dir(), me) if kd != null and not holding and _acting() else -1
	aimed_mate = _mate_aimed(h, found, kd) if holding and _acting() and (carried == null or carried.handable) else -1
	# H91, Q2498: a lying body under the crosshair wins over a Sock or a thing, and shows its Outline;
	# core/42 line 30: so does a Teammate a Hand-off would go to.
	aimed_sock = found["sock"] if aimed_body < 0 and aimed_mate < 0 else -1
	_outline(h.mess, aimed_sock)
	var body := kd.avatar_of(aimed_body) if aimed_body >= 0 and kd != null else null
	if aimed_mate >= 0:
		body = _avatar_here(aimed_mate)
	_outline_thing(Outline.of(body) if body != null else _aimed_outline(h.mess, aimed_sock, found["lying"]))
	_tick_spot = {}
	_tick_refusal = ""
	if holding and aimed_mate < 0:
		# Line 31: with a Teammate aimed the crosshair is never red (a Hand-off is possible).
		_tick_spot = drop_spot(found)
		_tick_refusal = _refusal_of(h, _tick_spot)
	drop_refused = _tick_refusal != ""
	_held_view.me = me
	_held_view.turning = _acting() and Input.is_action_pressed(TURN)
	_update_screen(h)
	_pinger.tick(delta, _acting() and not _swallow_press)
	if not _acting():
		# A menu opening or the mouse let go mid-charge drops the charge without a throw.
		_drop_down_at = -1.0
		_set_charge(false)
		_swallow_press = false
		if _grab_held:
			_let_go_body()
		return
	if _swallow_press:
		_swallow_press = false
		return
	if _grab_held and Input.is_action_just_released(PICK):
		_let_go_body()  # H96
	if Input.is_action_just_pressed(PICK) and aimed_body >= 0:
		# H93, Q2493: a lying body under the crosshair wins the click over a Sock or a thing.
		_grab_held = true
		kd.grab(me, aimed_body)
	elif Input.is_action_just_pressed(PICK):
		if aimed_sock >= 0:
			_pick(h, aimed_sock)
		else:
			# D08, C01: a left click on a thing that is not a Sock uses it (a drawer, a Door, a cupboard).
			use_aimed()
	if Input.is_action_just_pressed(DROP_THROW):
		_drop_down_at = _time
	if carried != null:
		if Input.is_action_just_released(DROP_THROW) and _drop_down_at >= 0.0:
			_drop_down_at = -1.0
			_put_carried(carried)
		return
	if _drop_down_at >= 0.0 and not charging and socks and _time - _drop_down_at >= hands_tuning.tap:
		_set_charge(true)
	if charging:
		charge = minf(1.0, charge + delta / maxf(h.tuning_of(player_id()).charge_time, 0.01))  # Quick Charge
		_ring.value = charge
	if Input.is_action_just_released(DROP_THROW) and _drop_down_at >= 0.0:
		var tapped := _time - _drop_down_at < hands_tuning.tap
		_drop_down_at = -1.0
		if charging:
			_throw(h)
		elif tapped and aimed_mate >= 0:
			_hand_off(h, aimed_mate)
		elif tapped:
			_drop(h)


## Whether the buttons of the Hands, the zoom and the turn act: not under a menu, and only with the
## mouse captured (L03, R01).
func _acting() -> bool:
	return _captured and not _input_blocked and not knocked


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
	if _ghosts.active():
		_ghosts.throw(aim_dir(), power)
	elif h.active_of(player_id()) >= 0:
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
	if _ghosts.active() and why == Hands.SOON:
		why = ""  # a Guest's copy has the Host's clock wrong; its ghosts keep the interval (D06)
	if why == Hands.FULL:
		say(HANDS_FULL)
	elif why == "" and _ghosts.active():
		_ghosts.pick(sock)
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
	if _ghosts.active():
		_ghosts.drop(spot["point"], spot["normal"])
	else:
		h.drop(player_id(), spot["point"], spot["normal"])


## core/42 lines 6-10: hands the active item to Teammate `to`, never also a drop. A Guest's waits for
## the Host's answer with nothing shown (no guess, line 10), back to "refuse" after the timeout.
func _hand_off(h: Hands, to: int) -> void:
	if h.active_of(player_id()) < 0:
		return
	if _ghosts.active():
		_ghosts.hand_off(to)
	else:
		h.hand_off(player_id(), to)


## core/42 lines 1-5: the Teammate under the crosshair a Hand-off would go to, nearer than the Sock
## the crosshair is on (line 2), or -1.
func _mate_aimed(h: Hands, found: Dictionary, kd: Knockdowns) -> int:
	var mate := AimFinder.mate(self, eyes(), aim_dir(), hands_tuning.reach, player_id(), h.hand_off_numbers(), kd, [get_rid()])
	var peer := int(mate["peer"])
	if peer >= 0 and int(found["sock"]) >= 0 and eyes().distance_to(found["point"]) < float(mate["along"]):
		return -1
	return peer


## Teammate `peer`'s avatar in this player's level, or null.
func _avatar_here(peer: int) -> Avatar:
	var level := LevelRuntime.level_of(self)
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and not a.is_queued_for_deletion() and (level == null or level.is_ancestor_of(a)):
			return a
	return null


## Why a drop where the crosshair is would be refused now, or "" (the Host's own check).
func drop_refusal(h: Hands) -> String:
	return _refusal_of(h, drop_spot())


func _refusal_of(h: Hands, spot: Dictionary) -> String:
	if spot.is_empty():
		return Hands.NO_SPOT
	if h.carries(player_id()) != null:
		return h.spot_refusal(player_id(), spot["point"], spot["normal"])
	return h.drop_refusal(player_id(), spot["point"], spot["normal"])


## core/78: the carried thing's right click: aimed at a Teammate (when it may be handed over), into
## their Hands; else down where the crosshair is, at the turn it is held, or "Can't drop there".
func _put_carried(carried: Carriable) -> void:
	var me := player_id()
	if aimed_mate >= 0:
		carried.hand_off(me, aimed_mate)
		return
	var spot := _tick_spot
	if spot.is_empty() or _tick_refusal != "":
		say(CANT_DROP)
		return
	carried.put_down(me, spot["point"], spot["normal"], carried.held_yaw(me))


## core/78: a left click on a lying Carriable: with anything in the Hands "Hands full" at once (the
## Host's own check), else it asks to pick it up.
func _pick_carriable(carriable: Carriable) -> void:
	var why := carriable.pick_refusal(player_id())
	if why == Carriable.FULL:
		say(HANDS_FULL)
	elif why == "":
		carriable.pick(player_id())


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
		part = aimed_part()
	var items := h.items_of(me) if h != null else PackedInt32Array()
	var carried := h.carries(me) if h != null else null
	var target := Prompts.target(part, _hud.pad)
	if part is Carriable or carried != null:
		# core/78: a carried thing is named with no key; a lying one shows the click only to empty Hands.
		target = Prompts.carry_target(part as Carriable, carried, items.is_empty() and carried == null, _hud.pad)
		if carried != null and part is MachinePartSlot:
			target.append(Prompts.fit_prompt(carried, _hud.pad))  # core/79: the click that fits the Part
		elif carried != null and part is Washer:
			var day := LaundryDay.of(self)
			if day != null and day.offers(carried):
				target.append(Prompts.load_prompt(_hud.pad))  # core/93: the click that loads the machine
	if aimed_body >= 0:
		target.clear()
		target.append(Prompts.drag_prompt(_hud.pad))
	_hud.show_target(target)
	var capacity := h.tuning_of(me).capacity if h != null else 0
	var hints := Prompts.hints(items.size(), _hud.pad, _pinger.can_ping(), carried != null, can_sprint())
	var kd := knockdowns()
	if kd != null and kd.dragger_of(me) >= 0:
		hints.clear()
		hints.append(Prompts.struggle_hint(_hud.pad))  # H105, Q2489: the hint only
	_hud.show_hints(hints)
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


## The middle button's pings (core/43).
func pinger() -> Pinger:
	return _pinger


## A Guest's guesses of its own actions (coop/09).
func ghosts() -> GuestGhosts:
	return _ghosts


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
	return Outline.of(_aim.get_collider() as Node) if _aim_open() else null


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
		Hearing.applied(ev, player_id(), _hands.parts, _ghosts.answered(ev))
	_knock_news(ev)
	_hand_off_news(ev)
	_carry_news(ev)
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
	if to is MachinePartSlot:
		var words := String(MachinePartSlot.SAYS.get(String(ev.get("reason", "")), ""))
		if words != "":
			say(words)
		return
	if to is LaundryDay:
		var said := String(LaundryDay.SAYS.get(String(ev.get("reason", "")), ""))
		if said != "":
			say(said)
		return
	if StringName(ev.get("to", &"")) != _hands.id:
		return
	match String(ev.get("reason", "")):
		Hands.FULL:
			say(HANDS_FULL)
		Hands.NO_SPOT, Hands.FAR:
			if StringName(ev.get("kind", &"")) == &"drop":
				say(CANT_DROP)


## core/42: a Hand-off or a catch answered. The item's flight into the receiver's Hands starts where it
## left (line 25: the giver's hand as drawn here; line 34: where a Throw hit), on every machine; the
## receiver reads "Paired!" (line 20) or "Hands full" (lines 23, 36); the giver of a refused loose Sock
## reads "Not their mate" (line 14). Nobody else reads anything (lines 23, 35, 43).
func _hand_off_news(ev: Dictionary) -> void:
	var kind := StringName(ev.get("kind", &""))
	if _hands == null or StringName(ev.get("to", &"")) != _hands.id or not (kind in [Hands.HAND_OFF, Hands.CATCH]):
		return
	var me := player_id()
	if not ev.get("ok", false):
		if kind == Hands.HAND_OFF and int(ev.get("by", 0)) == me and String(ev.get("reason", "")) == Hands.NOT_MATE:
			say(NOT_THEIR_MATE)
		return
	var item := int(ev.get("item", -1))
	if not ev.get("full", false) and item >= 0:
		var at: Variant = ev.get("at")
		var from: Vector3 = at if kind == Hands.CATCH and at is Vector3 else _hands.handed_from(int(ev.get("giver", -1)), item)
		HeldView.fly_from(_hands, int(ev.get("receiver", 0)), item, from)
	if int(ev.get("receiver", 0)) != me:
		return
	if ev.get("full", false):
		say(HANDS_FULL)
	elif ev.has("paired"):
		say_paired()


## core/78: a Carriable's answer. Refused to this player: "Hands full" for a pick into busy Hands, "Can't
## drop there" for a put down the Host would not take. Handed to this player with no room: "Hands full"
## (the giver reads nothing).
func _carry_news(ev: Dictionary) -> void:
	if _hands == null or _hands.parts == null or not (_hands.parts.of(StringName(ev.get("to", &""))) is Carriable):
		return
	var me := player_id()
	var kind := StringName(ev.get("kind", &""))
	if ev.get("ok", false):
		if kind == Carriable.HAND_OFF and ev.get("full", false) and int(ev.get("receiver", 0)) == me:
			say(HANDS_FULL)
		return
	if int(ev.get("by", 0)) != me:
		return
	match String(ev.get("reason", "")):
		Carriable.FULL:
			say(HANDS_FULL)
		Hands.NO_SPOT, Hands.FAR:
			if kind == &"drop":
				say(CANT_DROP)


## coop/10: "<Name> knocked you down" for the knocked player alone (F78, Q2494); a grab granted after
## the button came up lets go at once (H96).
func _knock_news(ev: Dictionary) -> void:
	var kd := knockdowns()
	if kd == null or not ev.get("ok", false) or StringName(ev.get("to", &"")) != kd.id:
		return
	var kind := StringName(ev.get("kind", &""))
	if kind == Knockdowns.KNOCK and int(ev.get("target", 0)) == player_id():
		var thrower := int(ev.get("thrower", 0))
		var roster := kd.parts.find(func(part: Part) -> bool: return part is Roster) as Roster if kd.parts != null else null
		var known := roster != null and not roster.entry_of(thrower).is_empty()
		announce(roster.name_of(thrower) if known else KNOCKED_BY_UNKNOWN, roster.colour_of(thrower) if known else Color.WHITE,
				KNOCKED_YOU, kd.tuning.message_time)
	elif kind == Knockdowns.GRAB and int(ev.get("by", 0)) == player_id() and not _grab_held:
		kd.let_go(player_id())


## The Part the crosshair rests on now, or null: none, or one that may not be aimed at now (a Cabinet
## or its drawer under the dust sheet, Q2513).
func aimed_part() -> Part:
	return part_of(_aim.get_collider() as Node) if _aim_open() else null


## Whether what the aim ray meets may be aimed at: its Part, and that drawer's Cabinet, say so.
func _aim_open() -> bool:
	var part := part_of(_aim.get_collider() as Node)
	if part == null:
		return true
	var cabinet := Cabinet.of(part)
	return part.aimable() and (cabinet == null or cabinet.aimable())


## The Part of the thing `node` belongs to: the first part of the closest entity root above it
## (Parts.part_of(): a direct climb, cheap every frame), or null for the floor.
static func part_of(node: Node) -> Part:
	return Parts.part_of(node)
