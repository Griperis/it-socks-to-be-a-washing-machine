## Who is knocked down and who drags whom, as one Part (coop/10, list 04 approved by Q2496): every
## player's knockdown, keyed by peer number (it lasts seconds, and a leaver's ends), written only by the
## Host's answers.
##
## The hit (A, B): on the Host, every physics tick, each Throw in the air thrown at full charge
## (`min_charge`) is tested against every player's body (their avatar's newest pose here, or the local
## player): a ball of the item's radius touches a body no lower than its radius under the feet, no higher
## than its radius over the body's height, and within body_radius plus its radius of the body's axis.
## The thrower, a player already down and a Throw that already hit are never knocked; with fewer than two
## bodies nothing is tested. A hit asks `knock` (Host-only: a Guest's is dropped by the Session, the verb
## is not accepted) and bounces the item back off the body (C27). The answer writes the knockdown (its
## fall: push, high, side; where the feet stood, the yaw), drops the knocked player's Hands as a leaver's
## (Hands.left, Q2485, Q2486) and ends a drag the knocked player held.
##
## The catch (core/42, Q2588): the same hit test serves every Throw below full charge. One the hit
## Teammate may take (Hands.take_refusal()) asks the Hands' Host-only `catch`; one they may not
## bounces back off the body at the Hand-off's `bounce` of its speed, upwards kept, with no Command.
##
## Down (E, G): `down` counts on every machine's own clock (left_of()), from `seconds`; from `rise_time`
## left the body gets up, played by every machine itself (Ragdoll.rise()); there is no immunity after
## (Q2487). The ragdoll is the avatar's (Avatar follows this Part each frame).
##
## Drag (H): `grab` a lying body (empty Hands, not down, not already dragged or dragging, within reach;
## never once it rises), `let_go`, and the dragged player's `struggle` presses: `struggle_presses` free
## them and cut their `down` to the rise. On the Host the feet are pulled to the dragger's hold point each
## tick; further than `break_distance` from it, once within it, the Host ends the drag ("apart"); as the
## body rises it ends ("up"), and a knock of the dragger ends it ("knocked"), a leave too ("leave").
##
## The wash (core/98, docs/architecture/washer.md): a body let go within reach of a free washing machine's
## door ends its knockdown and starts the machine's `WasherWash` in the same answer ("wash"); the wash's end
## lays the player down again by `tumble()`. A washed player is out of play: no hit, grab or hand-off finds them.
class_name Knockdowns
extends Part

const GROUP := &"knockdowns"
## The verbs.
const KNOCK := &"knock"
const GRAB := &"grab"
const LET_GO := &"let_go"
const STRUGGLE := &"struggle"
const RELEASE := &"release"
## A player fell out of the map while down: their knockdown ends at once (core/110).
const STAND := &"stand"
## Why a drag ended (the old drags.gd's words).
const DROP := "drop"
const STRUGGLED := "struggle"
const UP := "up"
const APART := "apart"
const KNOCKED := "knocked"
const LEAVE := "leave"
## Why a knockdown ended at a fall out of the map.
const FELL := "fell"
## A let go by the washing machine's door that sends the body in (core/98).
const WASH := "wash"
## Why a Command is refused.
const GONE := "gone"
const SELF := "self"
const ALREADY := "already"
const NOT_DOWN := "not_down"
const STANDING := "standing"
const TAKEN := "taken"
const BUSY := "busy"
const HANDS := "hands"
const FAR := "far"
const NOTHING := "nothing"
## The reach check's slack over grab_reach (the Host's view of a Guest is a little old).
const REACH_SLACK := 1.0

@export var tuning: KnockdownTuning
## The level's Hands: a knocked player's drop as a leaver's, and a dragger's empty Hands.
@export var hands: Hands

@export_group("State")
## Each knocked player's knockdown, by peer: {"left": seconds when written, "at": feet, "yaw",
## "push", "high", "side", "by": the thrower's peer, "n": the knock's serial, "cut": how many times a
## struggle cut it to the rise}; a late joiner's carries what is left and "pose" (Ragdoll.encode()).
@export var down := {}
## Who drags whom: {dragged peer: dragger peer}.
@export var drags := {}
## Each dragged player's struggle presses so far: {dragged peer: int}.
@export var struggles := {}
## The last knock's serial.
@export var serial := 0
@export_group("")

## Every machine: each knock's time left on this machine's clock, and the (serial, cut) last seen.
var _left: Dictionary[int, float] = {}
var _seen: Dictionary[int, Vector2i] = {}
## The Host: the Throws that already hit a body, and the drags whose feet were within the break once.
var _spent: Dictionary[int, bool] = {}
var _held_once: Dictionary[int, bool] = {}
## How many knocks the Host asked (a test reads it).
var knocks := 0
## How many Throws below full charge the Host asked a catch for, and bounced off a body (core/42).
var catches := 0
var bounces := 0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if tuning == null:
		tuning = KnockdownTuning.new()


# --- Questions anyone may ask --------------------------------------------------------------------

## How long player `peer` still lies on this machine's clock; 0 standing.
## Who lies knocked down now is not kept: a loaded World has nobody down (Q2559).
func save_state() -> Dictionary:
	return {}


func left_of(peer: int) -> float:
	return maxf(0.0, float(_left.get(peer, 0.0))) if down.has(peer) else 0.0


## Whether player `peer` is knocked down now (getting up included).
func is_down(peer: int) -> bool:
	return left_of(peer) > 0.0


## Whether player `peer` is getting up now (the last rise_time of their knockdown).
func is_rising(peer: int) -> bool:
	var l := left_of(peer)
	return l > 0.0 and l <= rise_time()


## Whether player `peer` spins in a washing machine's drum of this level now (core/98): out of play.
func is_washed(peer: int) -> bool:
	for wash in WasherWash.in_level(self):
		if wash.peer == peer:
			return true
	return false


## The rise's length, never over the knockdown's.
func rise_time() -> float:
	return minf(tuning.rise_time, tuning.seconds)


## Player `peer`'s knockdown entry, or {} standing.
func entry_of(peer: int) -> Dictionary:
	return down.get(peer, {}) if is_down(peer) else {}


## Who drags player `peer`, or -1: nobody once they rise.
func dragger_of(peer: int) -> int:
	if not drags.has(peer) or not is_down(peer) or is_rising(peer):
		return -1
	return int(drags[peer])


## Whom player `by` drags, or -1.
func dragging_of(by: int) -> int:
	for target: Variant in drags:
		if int(drags[target]) == by and dragger_of(int(target)) == by:
			return int(target)
	return -1


## The lying body (a peer) the aim from `eyes` along `dir` (unit) meets within the reach, or -1: the
## nearest whose middle line (feet to the top of the head) passes within body_radius of the aim. Not
## `me`, not one getting up.
func aimed_body(eyes: Vector3, dir: Vector3, me: int) -> int:
	var best := -1
	var best_along := INF
	for key: Variant in down:
		var peer := int(key)
		if peer == me or not is_down(peer) or is_rising(peer):
			continue
		var rag := ragdoll_of(peer)
		if rag == null:
			continue
		var hit := closest_on_segments(eyes, eyes + dir * tuning.grab_reach, rag.feet(), rag.point_at(tuning.top))
		if hit[0] <= tuning.body_radius and hit[1] < best_along:
			best_along = hit[1]
			best = peer
	return best


## [the least distance between segments p1-q1 and p2-q2, how far along the first it is (m)].
static func closest_on_segments(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> Array[float]:
	var d1 := q1 - p1
	var d2 := q2 - p2
	var r := p1 - p2
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var t := 0.0
	if a <= 0.000001 and e <= 0.000001:
		return [r.length(), 0.0]
	if a <= 0.000001:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c := d1.dot(r)
		if e <= 0.000001:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b := d1.dot(d2)
			var den := a * e - b * b
			s = clampf((b * f - c * e) / den, 0.0, 1.0) if den > 0.000001 else 0.0
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	var c1 := p1 + d1 * s
	var c2 := p2 + d2 * t
	return [c1.distance_to(c2), sqrt(a) * s]


## Whether a ball of radius `r` at `at` touches a standing body whose feet are at `feet`, `height` tall,
## `radius` round its axis (B13).
static func touches(at: Vector3, r: float, feet: Vector3, height: float, radius: float) -> bool:
	if at.y < feet.y - r or at.y > feet.y + height + r:
		return false
	return Vector2(at.x - feet.x, at.z - feet.z).length() <= radius + r


# --- Asking --------------------------------------------------------------------------------------

## Player `by` asks to grab lying player `target` by the feet.
func grab(by: int, target: int) -> void:
	parts.ask(Command.new(GRAB, by, id, {"target": target}))


## Player `by` lets go of the body they drag.
func let_go(by: int) -> void:
	parts.ask(Command.new(LET_GO, by, id, {}))


## Dragged player `by` struggles once (a press of the jump key).
func struggle(by: int) -> void:
	parts.ask(Command.new(STRUGGLE, by, id, {}))


## Player `by` fell out of the map while down: their knockdown and any drag of theirs end at once, as a
## cutscene's end ends them (core/110).
func stand(by: int) -> void:
	parts.ask(Command.new(STAND, by, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		GRAB: {"args": {"target": {"type": TYPE_INT, "min": 1, "max": 2147483647}}},
		LET_GO: {"args": {}},
		STRUGGLE: {"args": {}, "rate": 30},
		STAND: {"args": {}, "rate": 5},
	}


# --- The Host's answers --------------------------------------------------------------------------

func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		KNOCK:
			return _decide_knock(cmd)
		GRAB:
			return _decide_grab(cmd)
		LET_GO:
			var target := dragging_of(cmd.by)
			if target < 0:
				return refuse(NOTHING)
			return _let_go_at(target, cmd.by)
		RELEASE:
			if cmd.by != Parts.HOST or not (cmd.args.get("target") is int):
				return refuse("wrong")
			if not drags.has(int(cmd.args["target"])):
				return refuse(NOTHING)
			return _released(int(cmd.args["target"]), String(cmd.args.get("why", UP)))
		STRUGGLE:
			return _decide_struggle(cmd)
		STAND:
			if not is_down(cmd.by):
				return refuse(NOT_DOWN)
			return left(cmd.by, FELL)
	return refuse("wrong")


func _decide_knock(cmd: Command) -> Dictionary:
	if cmd.by != Parts.HOST:
		return refuse("wrong")
	var target: Variant = cmd.args.get("target")
	var thrower: Variant = cmd.args.get("thrower")
	var push: Variant = cmd.args.get("push")
	var high: Variant = cmd.args.get("high")
	var side: Variant = cmd.args.get("side")
	var at: Variant = cmd.args.get("at")
	if not (target is int) or not (thrower is int) or not (push is Vector3) or not (high is float) \
			or not (side is float) or not (at is Vector3) or not (push as Vector3).is_finite() or not (at as Vector3).is_finite():
		return refuse("wrong")
	var place: Variant = place_of(target)
	if ragdoll_of(target) == null or not (place is Transform3D):
		return refuse(GONE)
	if target == thrower:
		return refuse(SELF)
	if is_down(target) or is_washed(target):
		return refuse(ALREADY)
	# B25: the numbers are made sound here, whoever worked them out.
	var flat := Vector3((push as Vector3).x, 0.0, (push as Vector3).z)
	var feet := place as Transform3D
	var entry := {"left": tuning.seconds, "at": feet.origin, "yaw": feet.basis.get_euler().y,
			"push": flat.normalized() if flat.length() > 0.0001 else Vector3.FORWARD,
			"high": clampf(high, 0.0, 1.0), "side": clampf(side, -1.0, 1.0), "by": thrower, "n": serial + 1, "cut": 0}
	var now_down := _live_down()
	now_down[target] = entry
	var now_drags := drags.duplicate()
	var now_struggles := struggles.duplicate()
	var ended := -1
	for k: Variant in drags:
		if int(drags[k]) == target or int(k) == target:
			ended = int(k)
			now_drags.erase(k)
			now_struggles.erase(k)
	var changes := {id: {"down": now_down, "drags": now_drags, "struggles": now_struggles, "serial": serial + 1}}
	var ev := {"ok": true, "changes": changes, "target": target, "thrower": thrower, "at": at}
	if ended >= 0:
		ev["ended"] = ended
		ev["why"] = KNOCKED
	if hands != null:
		var dropped := hands.left(target)
		if not dropped.is_empty():
			changes.merge(dropped["changes"])
			ev["dropped_at"] = dropped["dropped_at"]
		# core/139: a held one-slot thing (the book) is let go too, where they stood, as a leaver's.
		var book := hands.one_slot_of(target)
		var spilled := book.left(target) if book != null else {}
		if not spilled.is_empty():
			changes.merge(spilled["changes"])
			if not ev.has("dropped_at"):
				var spill_at: Variant = parts.where.call(target) if parts.where.is_valid() else null
				ev["dropped_at"] = spill_at if spill_at is Vector3 else hands.eyes_of(target)
	return ev


func _decide_grab(cmd: Command) -> Dictionary:
	var target: Variant = cmd.args.get("target")
	if not (target is int):
		return refuse("wrong")
	if target == cmd.by:
		return refuse(SELF)
	if is_down(cmd.by):
		return refuse(ALREADY)
	if not is_down(target):
		return refuse(NOT_DOWN)
	if is_rising(target):
		return refuse(STANDING)
	if dragger_of(target) >= 0:
		return refuse(TAKEN)
	if dragging_of(cmd.by) >= 0:
		return refuse(BUSY)
	if hands != null and hands.holds_active(cmd.by):
		return refuse(HANDS)
	var rag := ragdoll_of(target)
	if rag == null:
		return refuse(GONE)
	if not parts.near_point(cmd.by, rag.feet(), tuning.grab_reach + REACH_SLACK) \
			and not parts.near_point(cmd.by, rag.frames()[2].origin, tuning.grab_reach + REACH_SLACK):
		return refuse(FAR)
	var now_drags := drags.duplicate()
	now_drags[target] = cmd.by
	var now_struggles := struggles.duplicate()
	now_struggles[target] = 0
	var ev := grant({"drags": now_drags, "struggles": now_struggles})
	ev["target"] = target
	return ev


func _decide_struggle(cmd: Command) -> Dictionary:
	if dragger_of(cmd.by) < 0:
		return refuse(NOTHING)
	var presses := int(struggles.get(cmd.by, 0)) + 1
	var needed := tuning.struggle_presses
	var now_struggles := struggles.duplicate()
	if presses < needed:
		now_struggles[cmd.by] = presses
		var ev := grant({"struggles": now_struggles})
		ev.merge({"presses": presses, "needed": needed})
		return ev
	# H106: freed, and up at once (cut to the rise).
	var now_drags := drags.duplicate()
	now_drags.erase(cmd.by)
	now_struggles.erase(cmd.by)
	var now_down := _live_down()
	var entry: Dictionary = (now_down[cmd.by] as Dictionary).duplicate()
	entry["cut"] = int(entry.get("cut", 0)) + 1
	now_down[cmd.by] = entry
	var ev := grant({"down": now_down, "drags": now_drags, "struggles": now_struggles})
	ev.merge({"presses": presses, "needed": needed, "freed": true, "target": cmd.by, "why": STRUGGLED})
	return ev


## The answer to a let go of `target`: a drop, or, with its feet by a free washing machine's door, the body
## going in (its knockdown ends, the machine's wash starts: "wash"). A busy machine's door is no door (it
## just lies there, Q758).
func _let_go_at(target: int, cmd_by: int) -> Dictionary:
	var ev := _released(target, DROP)
	var rag := ragdoll_of(target)
	if rag == null:
		return ev
	var feet := rag.feet()
	for wash in WasherWash.in_level(self):
		if not wash.by_door(feet):
			continue
		var patch := wash.take_in(target, feet, cmd_by)
		if patch.is_empty():
			break
		var now_down := _live_down()
		now_down.erase(target)
		(ev["changes"][id] as Dictionary)["down"] = now_down
		ev["changes"][wash.id] = patch
		ev["why"] = WASH
		break
	return ev


## The answer that ends the drag of `target` (`why`).
func _released(target: int, why: String) -> Dictionary:
	var now_drags := drags.duplicate()
	now_drags.erase(target)
	var now_struggles := struggles.duplicate()
	now_struggles.erase(target)
	var ev := grant({"drags": now_drags, "struggles": now_struggles})
	ev.merge({"target": target, "why": why})
	return ev


## The knockdowns still running on the Host's clock (a stood-up one is left out of the next patch).
func _live_down() -> Dictionary:
	var out := {}
	for k: Variant in down:
		if is_down(int(k)):
			out[k] = down[k]
	return out


## The Host: player `by` left (or fell out of the map: `why` FELL). Their knockdown and any drag of theirs end.
func left(by: int, why := LEAVE) -> Dictionary:
	if not down.has(by) and not drags.has(by) and not drags.values().has(by):
		return {}
	var now_down := _live_down()
	now_down.erase(by)
	var now_drags := drags.duplicate()
	var now_struggles := struggles.duplicate()
	for k: Variant in drags:
		if int(k) == by or int(drags[k]) == by:
			now_drags.erase(k)
			now_struggles.erase(k)
	var ev := grant({"down": now_down, "drags": now_drags, "struggles": now_struggles})
	ev["why"] = why
	return ev


## The Host, in a wash's end: the patch that lays player `target` down again as they tumble out (core/98):
## their knockdown, `by` the one who let go of them (an entry like a hit's, with `tilt` forward from upright, a `launch` velocity for every
## bone and `speed` of the push) for `seconds`, never under the rise plus 0.05 s. Reads only.
func tumble(target: int, by: int, at: Vector3, yaw: float, push: Vector3, side: float, tilt: float,
		launch: Vector3, seconds: float) -> Dictionary:
	var entry := {"left": maxf(seconds, rise_time() + 0.05), "at": at, "yaw": yaw, "push": push, "high": 0.5,
			"side": clampf(side, -1.0, 1.0), "by": by, "n": serial + 1, "cut": 0, "tilt": tilt, "launch": launch,
			"speed": 0.0}
	var now_down := _live_down()
	now_down[target] = entry
	return {"down": now_down, "serial": serial + 1}


# --- State shown, and the clocks -----------------------------------------------------------------

## A new knock starts its clock here; a struggle's cut takes it to the rise; one gone stops.
func _show(_now: bool) -> void:
	for k: Variant in down:
		var peer := int(k)
		var e: Dictionary = down[k]
		var seen := Vector2i(int(e.get("n", 0)), int(e.get("cut", 0)))
		var was: Vector2i = _seen.get(peer, Vector2i(-1, -1))
		if seen.x != was.x:
			_left[peer] = float(e.get("left", 0.0))
		elif seen.y != was.y:
			_left[peer] = minf(float(_left.get(peer, 0.0)), rise_time())
		_seen[peer] = seen
	for peer: int in _left.keys():
		if not down.has(peer):
			_left.erase(peer)
			_seen.erase(peer)


## A late joiner's copy: each knockdown with what is left of it, and the ragdoll's pose as it lies.
func whole_state() -> Dictionary:
	var d := state()
	var live := {}
	for k: Variant in down:
		var peer := int(k)
		if not is_down(peer):
			continue
		var e: Dictionary = (down[k] as Dictionary).duplicate()
		e["left"] = left_of(peer)
		var rag := ragdoll_of(peer)
		if rag != null and rag.phase == Ragdoll.Phase.DOWN:
			e["pose"] = Ragdoll.encode(0, rag.frames())
		live[k] = e
	d["down"] = live
	return d


func _physics_process(delta: float) -> void:
	for peer: int in _left.keys():
		_left[peer] = float(_left[peer]) - delta
	if parts == null or not parts.is_host():
		return
	_hits()
	_pull_drags(delta)


# --- The Host's hit test and drags ---------------------------------------------------------------

func _hits() -> void:
	var mess := hands.mess if hands != null else null
	if mess == null:
		return
	for sock: int in _spent.keys():
		if not mess.throws.has(sock) or mess.state_of(sock) != Mess.State.FLYING:
			_spent.erase(sock)
	var bodies := _bodies()
	if bodies.size() < 2:
		return
	var asks: Array[Command] = []
	for key: Variant in mess.throws:
		var sock := int(key)
		var launch: Dictionary = mess.throws[key]
		if _spent.has(sock) or mess.state_of(sock) != Mess.State.FLYING or not mess.is_throw(sock):
			continue
		var full := float(launch.get("charge", 0.0)) >= tuning.min_charge
		var body := mess.moving_body(sock)
		if body == null:
			continue
		var r := SockDress.ball_radius(mess.design_of(sock)) if mess.is_pair(sock) else SockDress.box(mess.design_of(sock)).x * 0.5
		var at := body.global_position
		for b: Array in bodies:
			var peer: int = b[0]
			var feet: Vector3 = b[1]
			var height: float = b[2]
			if peer == int(launch.get("by", 0)) or is_down(peer) or not touches(at, r, feet, height, tuning.body_radius):
				continue
			_spent[sock] = true
			var v := body.linear_velocity
			if not full:
				# core/42 F33-F36: the same hit, below full charge, is a catch by the Hand-off's rule.
				var why := hands.take_refusal(peer, sock)
				if why != "":
					# F35: refused, it bounces back off the body, upwards kept, and falls on; no word.
					var k := hands.hand_off_numbers().bounce
					body.linear_velocity = Vector3(-v.x * k, v.y * k, -v.z * k)
					bounces += 1
				else:
					catches += 1
					asks.append(Command.new(Hands.CATCH, Parts.HOST, hands.id, {"sock": sock, "to": peer, "at": at}))
				break
			var flat := Vector3(v.x, 0.0, v.z)
			var push := flat.normalized() if flat.length() > 0.0001 else Vector3.FORWARD
			var off := Vector3(at.x - feet.x, 0.0, at.z - feet.z)
			var side := clampf(off.cross(push).y / (tuning.body_radius + r), -1.0, 1.0)
			var high := clampf((at.y - feet.y) / maxf(height, 0.01), 0.0, 1.0)
			# C27: it bounces back off the body, sideways only, and falls.
			body.linear_velocity = -flat * tuning.bounce
			knocks += 1
			asks.append(Command.new(KNOCK, Parts.HOST, id, {"target": peer, "thrower": int(launch.get("by", 0)),
					"push": push, "high": high, "side": side, "at": at}))
			break
	# Asked once the walk over the Throws is done: an answer changes the Throws (a catch ends one, a
	# knock lets the knocked player's Hands fall).
	for cmd in asks:
		parts.ask(cmd)


## Every player's standing body here: [peer, feet in the world, height].
func _bodies() -> Array[Array]:
	var out: Array[Array] = []
	var seen: Dictionary[int, bool] = {}
	for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player == null or player.multiplayer != multiplayer or not _in_level(player) or is_washed(player.player_id()):
			continue
		var t := player.tuning
		out.append([player.player_id(), player.global_position, t.crouch_height if player.crouching else t.stand_height])
		seen[player.player_id()] = true
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a == null or a.is_queued_for_deletion() or not _in_level(a) or seen.has(a.peer()) or is_washed(a.peer()):
			continue
		var at := (place_of(a.peer()) as Transform3D).origin
		var t := a.tuning if a.tuning != null else AvatarTuning.new()
		out.append([a.peer(), at, lerpf(t.stand_height, t.crouch_height, a.pose_crouch)])
		seen[a.peer()] = true
	return out


func _pull_drags(delta: float) -> void:
	for key: Variant in drags.keys():
		var target := int(key)
		if not drags.has(key):
			continue
		var dragger := int(drags[key])
		if not is_down(target) or is_rising(target):
			_held_once.erase(target)
			parts.ask(Command.new(RELEASE, Parts.HOST, id, {"target": target, "why": UP}))
			continue
		var hold: Variant = hold_of(dragger)
		var rag := ragdoll_of(target)
		if not (hold is Vector3) or rag == null:
			continue
		rag.pull(hold, tuning.pull, delta)
		if rag.feet().distance_to(hold) <= tuning.break_distance:
			_held_once[target] = true
		elif _held_once.has(target):
			_held_once.erase(target)
			parts.ask(Command.new(RELEASE, Parts.HOST, id, {"target": target, "why": APART}))


## Where dragger `by` holds the feet: hold_height over their feet, hold_behind behind their middle.
func hold_of(by: int) -> Variant:
	var place: Variant = place_of(by)
	if not (place is Transform3D):
		return null
	var t := place as Transform3D
	return t.origin + Vector3.UP * tuning.hold_height + t.basis.z * tuning.hold_behind


## Where player `by` stands and faces in the world: the local player when on this machine, else their
## avatar's newest pose here; null when nobody can place them.
func place_of(by: int) -> Variant:
	for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player != null and player.multiplayer == multiplayer and player.player_id() == by and _in_level(player):
			return Transform3D(Basis(Vector3.UP, player.global_rotation.y), player.global_position)
	var a := avatar_of(by)
	if a == null:
		return null
	var space := a.get_parent() as Node3D
	var t := Transform3D(Basis(Vector3.UP, a.pose_yaw), a.pose_position)
	if space != null:
		t = space.global_transform * t
	return Transform3D(Basis(Vector3.UP, t.basis.get_euler().y), t.origin)


## Player `peer`'s avatar in this level on this machine, or null.
func avatar_of(peer: int) -> Avatar:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and not a.is_queued_for_deletion() and _in_level(a):
			return a
	return null


## Player `peer`'s ragdoll here, or null.
func ragdoll_of(peer: int) -> Ragdoll:
	var a := avatar_of(peer)
	return a.ragdoll if a != null else null


func _in_level(node: Node) -> bool:
	var level := LevelRuntime.level_of(self)
	return level == null or level.is_ancestor_of(node)
