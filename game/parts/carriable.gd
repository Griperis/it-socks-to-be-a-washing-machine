## The ability to be picked up, carried and put down. A player carries one thing at a time. Put it
## on the thing's scene as a child of the root that moves.
##
## Who holds it is decided state (this part). Where it is while carried is motion: the holder's
## machine moves the thing (the game's hands), and a MultiplayerSynchronizer on the thing (on
## change, its position) shows that move on every other machine. The motion's owner follows the
## decided holder: _show() makes the holder the thing's multiplayer authority, and the Host
## (Parts.HOST) when nobody holds it, so an answer, a late Guest's snapshot and a load all set it
## the same way, with no RPC of its own. A Guest's move before its pick is granted is looks only.
## Hands let go before they drop: the holder stops moving the thing in the frame it asks to drop,
## so no move of the old holder's is still in flight when the authority goes back to the Host.
##
## In a level with Hands (core/78, the carry seam of the Machine Parts and the Laundry bin): the
## thing takes the whole Hands. It comes only into empty Hands (no Sock held, nothing else carried:
## else "full"), and while it is carried no Sock, Pair or Guide card comes in (Hands.carries()). Every
## machine draws it at its carrier's hold slot (`slot`, a HoldSlot: the body frame, going down with
## Crouch), each frame after the body is drawn: its own player's body as drawn (steady at the drawn
## camera, not the physics tick), a Teammate's avatar; so it needs no synchronizer of its own. It lies
## where the crosshair put it (the drop's place check is the Hands', Hands.spot_refusal()), at the turn
## it was held (HoldSlot.lying_yaw()); its Looks child is drawn easing from the Hands to there over the
## slot's `put_seconds` (the shared put). The right click aimed at a Teammate (`hand_off`, when
## `handable`) puts it into their empty Hands, else down at their feet ("full": they read "Hands
## full"). A leaver lays it where they stood; a load where it last lay. While carried its shapes are
## off: it never blocks its carrier, the aim or a drop.
##
## A `one_slot` thing (core/139, the encyclopedia book; batch C's guide card is the next) is a Hands item
## in one place instead of the whole Hands: it comes only into empty Hands, then takes one of their
## places (Hands.capacity counts it), is listed and cycled by the wheel with the Socks and Pairs (Hands.list_size()),
## and is drawn at the slot only while it is the active item. Whoever holds it and has it active reads it with the use key
## (`use_held()`: a sibling with `held_use(by) -> bool`, the book's menu); it turns while the turn key is
## held (`turning`, looks only on this machine). It is put down, handed over or let go as any carried
## thing is (the right click, a leaver, a knocked-down player), never thrown.
##
## The `carry_guards` seam (core/137): a sibling Part in the group GUARDS may refuse a pick
## (`pick_refusal(by) -> StringName`, empty to allow: a Teammate's present, "not_yours", said by nobody) and
## hide the thing from a player's crosshair (`aimable_by(by) -> bool`: no outline, no prompt, no click).
##
## The held thing's input (core/163, devices.md): while it is in the Hands, the player's pick, drop_throw
## (with its held time), interact and the wheel go first to held_input(), which asks the siblings that
## answer `held_input(by, action, pressed, held_seconds) -> bool` (the Radio's dial, the nozzle's suck),
## then reads the active book (use_held()); false leaves the player's own default (a right tap puts it
## down, a right hold throws it when `throwable`).
##
## The thrown-knock rule (core/163, devices.md, Q2700): a `throwable` thing leaves the Hands on the right
## button held and released as a Sock's Throw (the Hands' charge time and Throw speed, with the Upgrades),
## `throw {from, vel, charge}` asked by its carrier. It flies on a scripted arc (gravity, no drag) that every
## machine replays from `flight` (from and vel in the level, `t0` on the Host's clock, `by`, `charge`, `spin`
## its tumble; a late joiner's and a save's copy carry `age`), with its shapes off. The Host sweeps the arc
## each physics tick with the thing's own shape against the house: a touch bounces it (a Host-only `bounce
## {from, vel}`, the old restitution and friction) until it touches a floor slowly enough, then it lies on
## the top under it (a Host-only `land {at, yaw}`, `land_sound` heard there, a turn the Host draws as the old
## did). Out of the level's bounds, in a wall, or flying too long, it is lost and comes back lying at the
## Mess's return spot in front of the washer (the lost pop). Knockdowns' hit test reads the things in the
## air (group FLYING, flying_ball()): a full-charge one knocks a Teammate down and bounces off in the same
## answer (bounce_patch()), a weaker one bounces off to their feet; a bounced one hits nobody again. The
## thrower's machine (a Guest) flies it at once from what it asked (a ghost) and eases onto the answer.
## A pick lets the lying Socks that rested on it fall (the Mess's `fall`, as a Sock's pick does).
class_name Carriable
extends Part

## Every Carriable is in this group (Hands.carries() looks there).
const GROUP := &"carriables"
## Every Carriable in the air is in this group (Knockdowns' hit test).
const FLYING := &"carriables_flying"
## The thrown-knock rule's verbs: the carrier's Throw, and the Host's own bounce and landing.
const THROW := &"throw"
const BOUNCE := &"bounce"
const LAND := &"land"
## How far the arc's sweep looks for the top a landing thing lies on, under where it touched (m).
const LAND_PROBE := 50.0
## How far off a surface a bounce starts, so the next sweep does not touch it at once (m).
const BOUNCE_LIFT := 0.02
const THROW_DEFAULT := preload("res://game/parts/carried_throw_tuning.tres")
const GHOSTS_DEFAULT := preload("res://game/hands/ghost_tuning.tres")
## A sibling Part in this group guards its picks and its aim (the carry_guards seam).
const GUARDS := &"carry_guards"
## Why a pick or a hand-off is refused because of the Hands: they hold something.
const FULL := "full"
## The right click aimed at a Teammate: the same verb as the Hand-off of a Sock (core/42), so it is
## heard the same (Hearing).
const HAND_OFF := &"hand_off"
## How far over and under a player's feet a thing laid there looks for the floor.
const FLOOR_PROBE := 0.5

## How far from the thing a player may stand to pick it up, and how far from the player it may be
## put down, in metres (Parts.near(); checked only once the game sets Parts.where). With Hands in the
## level the put down's reach is the Hands' own (HandsTuning.reach and reach_slack).
@export var reach := 3.0
## Where it rides in front of its carrier (one HoldSlot .tres per kind of carried thing).
@export var slot: HoldSlot
## Whether the right click aimed at a Teammate hands it over (on: into their empty Hands, else at
## their feet); off, that click puts it down at the crosshair as any drop.
@export var handable := true
## Its name on the crosshair's row, aimed or carried ("" for none).
@export var title := ""
## The crosshair's words with the click key for empty Hands aimed at it ("Pick up"; "": its `title`).
@export var pick_title := ""
## The crosshair's words with the click key while it is carried ("Open"; "": its `title`, with no key).
@export var carry_title := ""
## Whether it is a Hands item in one place instead of the whole Hands (the book).
@export var one_slot := false

@export_group("Throw")
## Whether the right button held and released throws it (the thrown-knock rule): the Radio, the detector, the Cat.
@export var throwable := false
## Its ball for the hit test against players while it flies, round its middle (m).
@export var radius := 0.15 # placeholder: the old flight's item ball
## The sound every machine hears where it lands from a Throw ("" for none): the Radio's radio_land.
@export var land_sound := &""
## Its flight's numbers (carried_throw_tuning.tres when empty).
@export var throw_tuning: CarriedThrowTuning
@export_group("")

@export_group("State")
## Who holds it: a player's id, or 0 when it lies at `at`.
@export var holder := 0
## Where it lies. INF means "where it stands in the scene", so placing it in the editor is enough.
@export var at := Vector3.INF
## Its turn about the up axis where it lies, in radians.
@export var yaw := 0.0
## Its flight while thrown: {"from", "vel" (the level's), "t0" (the Host's clock), "by", "charge", "spin",
## "bounces", "hit"}; empty while it lies or is carried.
@export var flight := {}
@export_group("")

## The level's Hands, found once among the Parts (null in a level without them).
var _hands: Hands
var _hands_looked := false
## Who held it when it was last shown (a change to 0 starts the put).
var _shown_holder := 0
## The shapes it switched off while carried.
var _off_shapes: Array[CollisionShape3D] = []
## The put: where its Looks was drawn in the Hands, and how much of the ease is left.
var _put_from := Transform3D.IDENTITY
var _put_left := 0.0
var _put_time := 0.0
## While its holder holds the turn key (set by their Player each frame), a one_slot thing turns in the slot.
var turning := false
## How far a one_slot thing is turned in the slot now, radians (looks only, this machine's).
var _spin := 0.0
## This machine's clock (physics seconds since it entered), and when on it the flight shown started.
var _clock := 0.0
var _start := 0.0
## The flight last shown (a new one starts the clock), and whether the Host asked its end or bounce.
var _shown_flight := {}
var _asked := false
## The thrower's own Throw before its answer (a Guest's ghost): {"from", "vel", "spin", "start", "yaw"}.
var _ghost := {}
## How far the drawn flight is off the answer's arc now (the ghost's ease), metres in the level.
var _offset := Vector3.ZERO
## The Host's draws: a flight's tumble and a landing's turn.
var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group(GROUP)


## It draws after the bodies it follows (the player and the avatars move in their own _process).
func _ready() -> void:
	process_priority = 100


func prompt_title() -> String:
	return title


## Whether this machine's player may aim at it: every guard beside it says so.
func aimable() -> bool:
	return aimable_by(multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST)


## Whether player `by`'s crosshair may rest on it (its guards', the carry_guards seam).
func aimable_by(by: int) -> bool:
	for guard in guards():
		if guard.has_method(&"aimable_by") and not bool(guard.call(&"aimable_by", by)):
			return false
	return true


## The Parts beside it that guard its picks and its aim (the group GUARDS).
func guards() -> Array[Node]:
	var out: Array[Node] = []
	var thing := get_parent()
	if thing == null:
		return out
	for node in thing.get_children():
		if node != self and node.is_in_group(GUARDS):
			out.append(node)
	return out


## Picked up by the left click (with empty Hands); the use key does nothing on it.
func click_only() -> bool:
	return true


## The player's use button picks it up.
func use(by: int) -> void:
	pick(by)


func pick(by: int) -> void:
	parts.ask(Command.new(&"pick", by, id))


## `where` in the thing's parent's space; `normal` the up of the top it goes on (the level's).
func drop(by: int, where: Vector3, turn: float, normal := Vector3.UP) -> void:
	parts.ask(Command.new(&"drop", by, id, {"at": where, "yaw": turn, "normal": normal}))


## The player puts it down on the top at `point` (the level's) whose up is `normal`, turned `turn`.
func put_down(by: int, point: Vector3, normal: Vector3, turn: float) -> void:
	drop(by, _from_level(point), turn, normal)


## The player hands it to Teammate `to` (a peer number), whom they aim at.
func hand_off(by: int, to: int) -> void:
	parts.ask(Command.new(HAND_OFF, by, id, {"to": to}))


## A Guest picks with no args, drops at a place with a turn and the top's up, hands to a peer. The
## place is checked in decide(): within reach of where the Host knows the player to stand.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		&"pick": {"args": {}},
		&"drop": {"args": {"at": TYPE_VECTOR3, "yaw": {"type": TYPE_FLOAT, "min": -TAU, "max": TAU},
				"normal": {"type": TYPE_VECTOR3, "min": -1.01, "max": 1.01}}},
		HAND_OFF: {"args": {"to": {"type": TYPE_INT, "min": 1, "max": 2147483647}}},
		THROW: {"args": {"from": TYPE_VECTOR3, "vel": {"type": TYPE_VECTOR3, "min": -100.0, "max": 100.0},
				"charge": {"type": TYPE_FLOAT, "min": 0.0, "max": 1.0}}, "rate": 5},
	}


## Why player `by` may not pick it up now, or "": a guard refuses (its own word: a Teammate's present,
## "not_yours"), someone holds it ("gone"), too far ("far"), or their Hands hold something ("full").
func pick_refusal(by: int) -> String:
	for guard in guards():
		if guard.has_method(&"pick_refusal"):
			var why := String(guard.call(&"pick_refusal", by))
			if why != "":
				return why
	if holder != 0 or not flight.is_empty():
		return "gone"
	if parts != null and not parts.near(by, get_parent(), reach):
		return "far"
	if hands_busy(by):
		return FULL
	return ""


## Whether player `by`'s Hands hold anything: a Sock or a Pair, a one-slot item, or a carried thing.
func hands_busy(by: int) -> bool:
	var h := hands()
	if h != null:
		return h.carries(by) != null or not h.items_of(by).is_empty() or h.one_slot_of(by) != null
	return parts != null and parts.find(func(p: Part) -> bool: return p is Carriable and (p as Carriable).holder == by) != null


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		&"pick":
			var why := pick_refusal(cmd.by)
			if why != "":
				return refuse(why)
			var thing := get_parent() as Node3D
			if not at.is_finite() and thing != null:
				return grant({"holder": cmd.by, "at": thing.position, "yaw": thing.rotation.y})
			return grant({"holder": cmd.by})
		&"drop":
			var where: Variant = cmd.args.get("at")
			var turn: Variant = cmd.args.get("yaw", 0.0)
			var normal: Variant = cmd.args.get("normal", Vector3.UP)
			if holder != cmd.by or not (where is Vector3) or not (turn is float or turn is int) or not (normal is Vector3):
				return refuse("wrong")
			var h := hands()
			if h != null:
				var why := h.spot_refusal(cmd.by, _to_level(where), _normal_to_level(normal))
				if why != "":
					return refuse(why)
			# A Guest may put it down only near where it stands, not anywhere in the level.
			elif not parts.near_point(cmd.by, _to_level(where), reach):
				return refuse("far")
			return grant({"holder": 0, "at": where, "yaw": wrapf(float(turn), -PI, PI)})
		HAND_OFF:
			return _decide_hand_off(cmd)
		THROW:
			return _decide_throw(cmd)
		BOUNCE:
			var from: Variant = cmd.args.get("from")
			var vel: Variant = cmd.args.get("vel")
			if cmd.by != Parts.HOST or not (from is Vector3) or not (vel is Vector3):
				return refuse("wrong")
			if flight.is_empty():
				return refuse("gone")
			return {"ok": true, "changes": bounce_patch(from, vel, bool(cmd.args.get("hit", false)))}
		LAND:
			var spot: Variant = cmd.args.get("at")
			var turn: Variant = cmd.args.get("yaw", 0.0)
			if cmd.by != Parts.HOST or not (spot is Vector3) or not (turn is float):
				return refuse("wrong")
			if flight.is_empty():
				return refuse("gone")
			var ev := grant({"flight": {}, "at": _from_level(spot), "yaw": wrapf(float(turn), -PI, PI)})
			ev["landed_at"] = spot
			if cmd.args.get("returned", false):
				# Lost and back by the washer: the lost pop, as a lost Sock's (Hearing).
				ev[Mess.POPPED] = PackedVector3Array([spot])
			return ev
	return refuse("wrong")


## The carrier's Throw: it leaves the Hands at `from` with `vel` (the carrier's, checked against what their
## Hands may throw and where they stand) and flies; the Host draws its tumble.
func _decide_throw(cmd: Command) -> Dictionary:
	var from: Variant = cmd.args.get("from")
	var vel: Variant = cmd.args.get("vel")
	var charge: Variant = cmd.args.get("charge")
	if holder != cmd.by or not throwable or not flight.is_empty():
		return refuse("wrong")
	if not (from is Vector3) or not (vel is Vector3) or not (charge is float) \
			or not (from as Vector3).is_finite() or not (vel as Vector3).is_finite() or charge < 0.0 or charge > 1.0:
		return refuse("wrong")
	var h := hands()
	if h != null:
		var t := h.tuning_of(cmd.by)
		var fastest := maxf(t.max_speed, Vector2(t.lob_speed, t.lob_lift).length()) + 0.05
		if (vel as Vector3).length() > fastest:
			return refuse("wrong")
		if not parts.near_point(cmd.by, from, t.reach + t.reach_slack):
			return refuse(Hands.FAR)
	elif not parts.near_point(cmd.by, from, reach):
		return refuse(Hands.FAR)
	var tip := _throw_numbers().spin_tip
	var spin := Vector3(_rng.randf_range(-tip.x, tip.x), _rng.randf_range(-tip.y, tip.y), _rng.randf_range(-tip.z, tip.z))
	var f := {"from": from, "vel": vel, "t0": _clock, "by": cmd.by, "charge": float(charge), "spin": spin, "bounces": 0, "hit": false}
	return grant({"holder": 0, "flight": f, "at": _from_level(from), "yaw": held_yaw(cmd.by)})


## The change that bounces it off at `from` (the level's) with `vel`, a new arc of the same Throw (the Host's,
## a touch of the house or a body; Knockdowns puts it in a knock's answer). `hit`: it hit a body and hits
## nobody again. Reads only.
func bounce_patch(from: Vector3, vel: Vector3, hit: bool) -> Dictionary:
	var f := flight.duplicate()
	f["from"] = from
	f["vel"] = vel
	f["t0"] = _clock
	f["bounces"] = int(flight.get("bounces", 0)) + 1
	f["hit"] = hit or bool(flight.get("hit", false))
	return {id: {"flight": f, "at": _from_level(from)}}


## The right click aimed at Teammate `to`: into their empty Hands, else down at their feet at the turn
## it last lay, "full" (the old laundry.gd decide_drop). Refused: not held, not `handable`, aimed at
## themselves, someone this machine cannot place, knocked down, out of reach (as a Sock's Hand-off).
func _decide_hand_off(cmd: Command) -> Dictionary:
	var to: Variant = cmd.args.get("to")
	if holder != cmd.by or not (to is int):
		return refuse("wrong")
	if not handable:
		return refuse("wrong")
	if to == cmd.by:
		return refuse(Hands.SELF)
	var feet: Variant = parts.where.call(to) if parts.where.is_valid() else null
	if not (feet is Vector3):
		return refuse(Hands.GONE)
	var h := hands()
	if h != null:
		if h.is_down(to):
			return refuse(Hands.DOWN)
		var t := h.tuning_of(cmd.by)
		if not parts.near_point(cmd.by, feet, t.reach + t.reach_slack + h.hand_off_numbers().body_radius):
			return refuse(Hands.FAR)
	var ev := {"ok": true, "giver": cmd.by, "receiver": to, "item": -1}
	if not hands_busy(to):
		ev["changes"] = {id: {"holder": to}}
		return ev
	ev["full"] = true
	var lay := _floor_under(feet)
	ev["laid_at"] = lay
	ev["changes"] = {id: {"holder": 0, "at": _from_level(lay)}}
	return ev


## A player who leaves holding it lays it where they stood (on the floor under their last place, at
## the turn it last lay: the old laundry.gd decide_leave), or where it last lay when this machine
## cannot place them.
func left(by: int) -> Dictionary:
	if holder != by:
		return {}
	var feet: Variant = parts.where.call(by) if parts != null and parts.where.is_valid() else null
	if not (feet is Vector3):
		return grant({"holder": 0})
	return grant({"holder": 0, "at": _from_level(_floor_under(feet))})


## The Host, after a load: nobody holds it (nothing is held offline); it lies where it was.
func loaded(_host: String) -> Dictionary:
	return grant({"holder": 0}) if holder != 0 else {}


## The State gained `flight` (core/163): a save without it lies (the scene's empty flight).
func save_version() -> int:
	return 2


## What a save keeps (Q295, R29): a Guest's carried one lies where they stood (on the floor under their
## place); the Host's own carried one lies where it last lay (loaded()); one in the air flies on.
func save_state() -> Dictionary:
	var d := whole_state()
	if holder != 0 and holder != Parts.HOST and parts != null and parts.where.is_valid():
		var feet: Variant = parts.where.call(holder)
		if feet is Vector3:
			d["holder"] = 0
			d["at"] = _from_level(_floor_under(feet))
	return d


## A late joiner's and a save's copy: a flight carries how long it has flown (`age`), so it is seen mid-air.
func whole_state() -> Dictionary:
	var d := state()
	if not flight.is_empty():
		var f := flight.duplicate()
		f["age"] = flight_age()
		d["flight"] = f
	return d


# --- The held thing's input and the Throw (core/163) -------------------------------------------------

## Player `by`'s `action` (Player.PICK, DROP_THROW, INTERACT, HANDS_NEXT, HANDS_PREV), `pressed` or
## released after `held_seconds`, while this is in their Hands: the first sibling whose
## `held_input(by, action, pressed, held_seconds)` uses it, else the use key reads the active book
## (use_held()). Returns whether it was used; false leaves the player's own default.
func held_input(by: int, action: StringName, pressed: bool, held_seconds: float) -> bool:
	var thing := get_parent()
	if thing == null or holder != by:
		return false
	for node in thing.get_children():
		if node != self and node.has_method(&"held_input") \
				and bool(node.call(&"held_input", by, action, pressed, held_seconds)):
			return true
	if action == &"interact" and pressed:
		return use_held(by)
	return false


## Where and how carrier `by` throws it with `charge` (0 to 1), from eyes at `eyes` along the aim `dir`:
## {"from": where it leaves (where their Hands hold it, never through a wall), "vel"}. As a Sock's Throw
## (Hands.launch_of()): below the tap charge the lob, above it faster the fuller the charge (the Hands'
## speeds with the Upgrades), along the arc to the point the crosshair is on.
func launch_of(by: int, eyes: Vector3, dir: Vector3, charge: float) -> Dictionary:
	var h := hands()
	var t := h.tuning_of(by) if h != null else HandsTuning.new()
	var vel := dir * lerpf(t.min_speed, t.max_speed, charge)
	if charge < t.tap_charge:
		vel = dir * t.lob_speed + Vector3.UP * t.lob_lift
	var thing := get_parent() as Node3D
	var pose: Variant = carry_pose(by)
	var from: Vector3 = (pose as Transform3D).origin if pose is Transform3D else (thing.global_position if thing != null else eyes)
	var bodies := _player_rids()
	var wall := PhysicsQueries.ray(self, eyes, from, Mess.LAYER_HOUSE, bodies)
	if not wall.is_empty():
		var out := from - eyes
		from = eyes + out.normalized() * maxf(0.0, eyes.distance_to(wall["position"]) - radius * 1.5)
	var hit := PhysicsQueries.ray(self, eyes, eyes + dir * Hands.AIM_FAR, Mess.AIM_MASK, bodies)
	if not hit.is_empty():
		var aimed := Arc.aimed(from, hit["position"], vel.length(), _gravity(), 0.0, vel)
		if aimed != Vector3.ZERO:
			vel = aimed
	return {"from": from, "vel": vel}


## Carrier `by` throws it: leaving at `from` with `vel` (the level's) and `charge`. A Guest flies it at once
## (looks only) and eases onto the Host's answer.
func throw(by: int, from: Vector3, vel: Vector3, charge: float) -> void:
	if parts == null:
		return
	if not parts.is_host():
		var thing := get_parent() as Node3D
		_ghost = {"from": from, "vel": vel, "start": _clock, "spin": Vector3.ZERO,
				"yaw": thing.global_rotation.y if thing != null else yaw}
	parts.ask(Command.new(THROW, by, id, {"from": from, "vel": vel, "charge": charge}))


## Whether it flies now.
func flying() -> bool:
	return not flight.is_empty()


## How long the flight shown has flown on this machine (s).
func flight_age() -> float:
	return maxf(_clock - _start, 0.0)


## Where its arc puts it `t` seconds into the flight (the level's; its origin, the bottom).
func flight_point(t: float) -> Vector3:
	return Vector3(flight.get("from", Vector3.ZERO)) + Vector3(flight.get("vel", Vector3.ZERO)) * t \
			+ Vector3.DOWN * 0.5 * _gravity() * t * t


## Its velocity `t` seconds into the flight.
func flight_velocity(t: float) -> Vector3:
	return Vector3(flight.get("vel", Vector3.ZERO)) + Vector3.DOWN * _gravity() * t


## Its ball for the hit test now: {"at": its middle, "from": its origin on the arc (the level's), "radius",
## "by": the thrower, "charge", "vel", "hit": it hit a body already}; {} while it does not fly.
func flying_ball() -> Dictionary:
	if flight.is_empty():
		return {}
	var t := flight_age()
	var origin := flight_point(t)
	return {"at": origin + Vector3.UP * radius, "from": origin, "radius": radius, "by": int(flight.get("by", 0)),
			"charge": float(flight.get("charge", 0.0)), "vel": flight_velocity(t), "hit": bool(flight.get("hit", false))}


func _throw_numbers() -> CarriedThrowTuning:
	if throw_tuning == null:
		throw_tuning = THROW_DEFAULT
	return throw_tuning


static func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))


## Every player's body on this machine (players stand on the house layer; a thrown thing passes them:
## Knockdowns' hit test meets them).
func _player_rids() -> Array[RID]:
	var out: Array[RID] = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
		var body := node as CollisionObject3D
		if body != null:
			out.append(body.get_rid())
	var own := get_parent() as CollisionObject3D
	if own != null:
		out.append(own.get_rid())
	return out


# --- The Host's sweep of the arc -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_clock += delta
	if flight.is_empty() or _asked or parts == null or not parts.is_host() or not is_inside_tree():
		return
	var tn := _throw_numbers()
	var t := flight_age()
	var a := flight_point(maxf(t - delta, 0.0))
	var b := flight_point(t)
	var h := hands()
	var mess := h.mess if h != null else null
	if t > tn.most_seconds or (mess != null and not mess.in_bounds(b)):
		_lose()
		return
	var hit := _sweep(a, b)
	if hit.is_empty():
		return
	var p: Vector3 = hit["at"]
	var n: Vector3 = hit["normal"]
	var v := flight_velocity(t)
	var into := v.dot(n)
	if into < 0.0:
		var vn := n * into
		v = (v - vn) * (1.0 - tn.friction) - vn * tn.restitution
	if (n.y > tn.floor_up and v.length() < tn.rest_speed) or int(flight.get("bounces", 0)) >= tn.most_bounces:
		_land_under(p)
		return
	_asked = true
	parts.ask(Command.new(BOUNCE, Parts.HOST, id, {"from": p + n * BOUNCE_LIFT, "vel": v}))


## The first touch of the house by its shape moved from `a` to `b` (its origins, upright at its turn):
## {"at": its origin there, "normal"}, or {}.
func _sweep(a: Vector3, b: Vector3) -> Dictionary:
	if a.is_equal_approx(b) or not is_inside_tree():
		return {}
	var shape: Shape3D
	var shape_at := Transform3D.IDENTITY
	var found := _shape()
	if found.is_empty():
		var ball := SphereShape3D.new()
		ball.radius = radius
		shape = ball
		shape_at = Transform3D(Basis.IDENTITY, Vector3.UP * radius)
	else:
		shape = found[0]
		shape_at = found[1]
	var exclude := _player_rids()
	var hit := PhysicsQueries.cast(self, shape, Transform3D(Basis(Vector3.UP, yaw), a) * shape_at, b - a, Mess.LAYER_HOUSE, exclude)
	if not hit.is_empty():
		return {"at": a + (b - a) * float(hit["safe"]), "normal": hit["normal"]}
	# A cast that starts touching may miss what it touches: the line from its middle down to its bottom's
	# new place catches the floor it would fall through.
	var line := PhysicsQueries.ray(self, a + Vector3.UP * radius, b, Mess.LAYER_HOUSE, exclude)
	if line.is_empty():
		return {}
	var through: Vector3 = line["position"]
	return {"at": Vector3(through.x, maxf(through.y, b.y), through.z), "normal": line["normal"]}


## Its first collision shape and that shape's place in the thing: [Shape3D, Transform3D], or [].
func _shape() -> Array:
	var thing := get_parent()
	if thing == null:
		return []
	for node in thing.find_children("*", "CollisionShape3D", true, false):
		var cs := node as CollisionShape3D
		if cs.shape != null:
			var place := (thing as Node3D).global_transform.affine_inverse() * cs.global_transform if thing is Node3D and cs.is_inside_tree() else cs.transform
			return [cs.shape, Transform3D(place.basis.orthonormalized(), place.origin)]
	return []


## The Host: it lies on the first top under `p` (the old landing: straight down, a turn drawn at random);
## none, or in a wall, it is lost.
func _land_under(p: Vector3) -> void:
	var bodies := _player_rids()
	var top := PhysicsQueries.ray(self, p + Vector3.UP * BOUNCE_LIFT * 10.0, p + Vector3.DOWN * LAND_PROBE, Mess.LAYER_HOUSE, bodies)
	if top.is_empty() or PhysicsQueries.inside(self, p + Vector3.UP * radius, Mess.LAYER_HOUSE, bodies):
		_lose()
		return
	var h := hands()
	var spot: Vector3 = top["position"]
	if h != null and h.mess != null and not h.mess.in_bounds(spot):
		_lose()
		return
	_asked = true
	parts.ask(Command.new(LAND, Parts.HOST, id, {"at": spot, "yaw": _rng.randf_range(-PI, PI), "returned": false}))


## The Host: lost (out of the level, in a wall, flown too long), it comes back lying at the Mess's return
## spot in front of the washer (Q2559), on the floor under it, turned at random.
func _lose() -> void:
	var h := hands()
	var back := h.mess.return_spot if h != null and h.mess != null else null
	var spot := (back.global_position if back != null and back.is_inside_tree() else _to_level(Vector3.ZERO))
	_asked = true
	parts.ask(Command.new(LAND, Parts.HOST, id, {"at": _floor_under(spot), "yaw": _rng.randf_range(-PI, PI), "returned": true}))


## The player's use key while this one_slot thing is their active item: the first sibling of it that
## says `held_use(by)` did something (the book's menu opens). Returns whether one did.
func use_held(by: int) -> bool:
	var thing := get_parent()
	if thing == null or holder != by:
		return false
	for node in thing.get_children():
		if node != self and node.has_method(&"held_use") and bool(node.call(&"held_use", by)):
			return true
	return false


## The level's Hands (found once among the Parts), or null.
func hands() -> Hands:
	if _hands != null and is_instance_valid(_hands):
		return _hands
	if parts == null or _hands_looked or not is_inside_tree():
		return null
	# The Hands' group, not a scan of every part: a level binds hundreds of parts at once.
	for node in get_tree().get_nodes_in_group(Hands.GROUP):
		var h := node as Hands
		if h != null and h.parts == parts:
			_hands = h
			break
	# Not found once every part is bound: the level has none (looked for again only then).
	_hands_looked = _hands == null and parts.is_bound
	return _hands


## The turn it lies at put down by player `by` now (their body's turn as drawn here, by the slot),
## or the turn it lay at last.
func held_yaw(by: int) -> float:
	var h := hands()
	var body := h.body_frame(by) if h != null else {}
	if body.is_empty() or slot == null:
		return yaw
	return slot.lying_yaw(float(body["yaw"]))


## `at` is in the thing's parent's space; a player's place (Parts.where) is in the level's.
func _to_level(spot: Vector3) -> Vector3:
	var base := _base()
	return base.global_transform * spot if base != null else spot


func _from_level(spot: Vector3) -> Vector3:
	var base := _base()
	return base.global_transform.affine_inverse() * spot if base != null else spot


func _normal_to_level(n: Vector3) -> Vector3:
	var base := _base()
	return (base.global_basis * n).normalized() if base != null and not n.is_zero_approx() else n


func _base() -> Node3D:
	var thing := get_parent() as Node3D
	var base := thing.get_parent() as Node3D if thing != null else null
	return base if base != null and base.is_inside_tree() else null


## The floor under `feet` (the house's first top within FLOOR_PROBE over and under), else `feet`.
func _floor_under(feet: Vector3) -> Vector3:
	if not is_inside_tree():
		return feet
	var hit := PhysicsQueries.ray(self, feet + Vector3.UP * FLOOR_PROBE, feet + Vector3.DOWN * FLOOR_PROBE, Mess.LAYER_HOUSE)
	return hit["position"] if not hit.is_empty() else feet


## The holder owns the thing's motion (the Host while it lies); placed where it lies. While held it
## stays where the holder's hands put it; its shapes are off. Put down from a carry, its Looks is
## drawn easing from the Hands to where it lies.
func _show(now: bool) -> void:
	var thing := get_parent() as Node3D
	if thing == null:
		return
	var mover := holder if holder != 0 else Parts.HOST
	if thing.get_multiplayer_authority() != mover:
		_set_mover(thing, mover)
	if holder != 0 and _shown_holder == 0 and flight.is_empty() and not now:
		_let_rested_fall(thing)
	_set_shapes(thing, holder == 0 and flight.is_empty())
	if flight != _shown_flight:
		_shown_flight = flight
		_asked = false
		_offset = Vector3.ZERO
		if not flight.is_empty():
			if now:
				_start = _clock - float(flight.get("age", 0.0))
			elif not _ghost.is_empty() and int(flight.get("by", 0)) == _me():
				# The thrower's own Throw: its arc goes on from the click; the drawn one eases onto it.
				_start = float(_ghost["start"])
				var age := flight_age()
				_offset = Vector3(_ghost["from"]) + Vector3(_ghost["vel"]) * age + Vector3.DOWN * 0.5 * _gravity() * age * age \
						- flight_point(age)
			else:
				_start = _clock
		_ghost = {}
	if not flight.is_empty():
		if not is_in_group(FLYING):
			add_to_group(FLYING)
		_put_left = 0.0
		_shown_holder = 0
		if hands() != null:
			thing.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_draw_flight(thing, 0.0)
		return
	if is_in_group(FLYING):
		remove_from_group(FLYING)
	if holder != 0:
		_put_left = 0.0
		if hands() != null:
			thing.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_shown_holder = holder
		return
	var looks := thing.get_node_or_null(^"Looks") as Node3D
	var was_held := _shown_holder != 0
	_shown_holder = 0
	var from := looks.global_transform if looks != null and looks.is_inside_tree() else Transform3D.IDENTITY
	if at.is_finite():
		thing.position = at
		thing.rotation.y = yaw
	if hands() != null:
		thing.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT
		if thing.is_inside_tree():
			thing.reset_physics_interpolation()
	var seconds := slot.put_seconds if slot != null else 0.0
	if was_held and not now and looks != null and looks.is_inside_tree() and seconds > 0.0:
		_put_from = from
		_put_time = seconds
		_put_left = seconds
		looks.global_transform = from
	elif looks != null:
		_put_left = 0.0
		looks.transform = Transform3D.IDENTITY


## `thing` and everything under it move by `mover`, but a spawned thing's SpawnGate, which stays the Host's
## (SpawnedParts): changing the gate's authority while a late Guest's spawn of a carried thing is pending is an
## engine error (core/137: a present carried as a Guest joins).
func _set_mover(thing: Node3D, mover: int) -> void:
	thing.set_multiplayer_authority(mover, false)
	for child in thing.get_children():
		if child.name != SpawnedParts.GATE:
			child.set_multiplayer_authority(mover, true)


## Its shapes are on while it lies and off while carried (the ones it switched off come back).
func _set_shapes(thing: Node3D, on: bool) -> void:
	if on:
		for shape in _off_shapes:
			if is_instance_valid(shape):
				shape.set_deferred(&"disabled", false)
		_off_shapes.clear()
		return
	if hands() == null or not _off_shapes.is_empty():
		return
	for node in thing.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if not shape.disabled:
			shape.set_deferred(&"disabled", true)
			_off_shapes.append(shape)


## This machine's player id (the Host's alone).
func _me() -> int:
	return multiplayer.get_unique_id() if is_inside_tree() else Parts.HOST


## The Host, as it is picked up: the lying Socks that rested on it fall (Q2704; the Mess's `fall`, the rule
## of a picked Sock, M07), found in the box its shapes take now.
func _let_rested_fall(thing: Node3D) -> void:
	var h := hands()
	if h == null or h.mess == null or parts == null or not parts.is_host() or not thing.is_inside_tree():
		return
	var box := AABB()
	for node in thing.find_children("*", "CollisionShape3D", true, false):
		var cs := node as CollisionShape3D
		if cs.shape == null or not cs.is_inside_tree():
			continue
		var b := cs.global_transform * cs.shape.get_debug_mesh().get_aabb()
		box = b if not box.has_volume() else box.merge(b)
	if box.has_volume():
		var resting := h.mess.resting_on(box)
		if not resting.is_empty():
			h.mess.queue_wake(resting, &"fall")


## Draws it on its arc `ahead` seconds past the last tick: the answer's arc plus what is left of the
## ghost's offset, tumbling by its spin from the turn it left at.
func _draw_flight(thing: Node3D, ahead: float) -> void:
	if not thing.is_inside_tree():
		return
	var t := flight_age() + ahead
	var spin: Vector3 = flight.get("spin", Vector3.ZERO)
	var turn := Basis(Vector3.UP, yaw) * Basis.from_euler(spin * t)
	thing.global_transform = Transform3D(turn, flight_point(t) + _offset)


## Each frame: carried, it rides its carrier's slot as their body is drawn here; just put down, its
## Looks eases to where it lies; thrown, it flies its arc (a Guest thrower's ghost before the answer).
func _process(delta: float) -> void:
	var thing := get_parent() as Node3D
	if thing == null:
		return
	if not flight.is_empty():
		var blend := GHOSTS_DEFAULT.predict_blend
		_offset *= exp(-3.0 * delta / maxf(blend, 0.001))
		_draw_flight(thing, Engine.get_physics_interpolation_fraction() / float(Engine.physics_ticks_per_second))
		return
	if holder != 0 and not _ghost.is_empty():
		var age := _clock - float(_ghost["start"])
		if age > GHOSTS_DEFAULT.answer_timeout:
			_ghost = {}  # no answer (refused): back in the Hands
		else:
			var g_from: Vector3 = _ghost["from"]
			var g_vel: Vector3 = _ghost["vel"]
			thing.global_transform = Transform3D(Basis(Vector3.UP, float(_ghost["yaw"])),
					g_from + g_vel * age + Vector3.DOWN * 0.5 * _gravity() * age * age)
			return
	if holder != 0:
		if one_slot:
			_spin = wrapf(_spin + (TAU / maxf(_turn_seconds(), 0.05) * delta if turning else 0.0), -PI, PI)
			var h := hands()
			thing.visible = h != null and h.one_slot_active(holder) == self
		var pose: Variant = carry_pose(holder)
		if pose is Transform3D:
			thing.global_transform = _spun(pose as Transform3D)
		return
	if one_slot:
		_spin = 0.0
		turning = false
		thing.visible = true
	if _put_left <= 0.0:
		return
	var looks := thing.get_node_or_null(^"Looks") as Node3D
	if looks == null:
		_put_left = 0.0
		return
	_put_left = maxf(_put_left - delta, 0.0)
	var k := smoothstep(0.0, 1.0, 1.0 - _put_left / maxf(_put_time, 0.0001))
	looks.global_transform = _put_from.interpolate_with(thing.global_transform, k)
	if _put_left <= 0.0:
		looks.transform = Transform3D.IDENTITY


## `pose` turned `_spin` about the up axis through the slot's place (a one_slot thing's turn in the hand).
func _spun(pose: Transform3D) -> Transform3D:
	return pose if _spin == 0.0 else Transform3D(Basis(Vector3.UP, _spin) * pose.basis, pose.origin)


## Seconds a full turn takes while the turn key is held: the holder's Hands' own (HandsTuning.turn_time).
func _turn_seconds() -> float:
	var h := hands()
	return h.tuning_of(holder).turn_time if h != null else 2.0


## Where player `by` holds it now as this machine draws them (their slot on their body), or null when
## this machine draws no body of theirs (or the level has no Hands).
func carry_pose(by: int) -> Variant:
	var h := hands()
	var body := h.body_frame(by) if h != null else {}
	if body.is_empty() or slot == null:
		return null
	return slot.pose(body["feet"], float(body["yaw"]), float(body["drop"]))


## Whether the put down's ease still draws its Looks off where it lies.
func putting() -> bool:
	return _put_left > 0.0
