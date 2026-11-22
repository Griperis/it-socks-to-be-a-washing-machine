## Every player's Hands as one Part, keyed by player id (1 alone, Q2212): the Socks each holds, in
## the order picked (newest last), and which one is active. Every change is a Command the Host
## answers: `pick` a lying Sock, `cycle` the active item, `drop` the active item on a spot, `throw`
## the active item along a direction (core/08). A pick, a drop and a throw each change two Parts in
## one answer: the Sock's record in the Mess and these Hands.
##
## Pairs (core/03): picking a loose Sock whose loose mate (same Design) is held fuses the two at once
## into one Pair in that place, which becomes the active item (P01); it is never refused "full" (P02).
## A held Pair never takes a third Sock (P03) and is never split. A Pair is held, dropped and thrown
## as its lead Sock's id, one item.
##
## The refusals the player sees before asking (the crosshair's red, "Hands full", "Can't drop
## there") come from the same checks decide() makes: pick_refusal() and drop_refusal().
class_name Hands
extends Part

## The group the level's Hands are in: the player finds them there.
const GROUP := &"hands"
## The group of local players whose HandsTuning the Hands read for their capacity and reach.
const PLAYERS := &"hands_players"
## Why a Command is refused: too far, the Sock is not lying, the Hands are full, too soon after the
## last pick, nothing held, no spot a drop may rest on.
const FAR := "far"
const GONE := "gone"
const FULL := "full"
const SOON := "soon"
const NOTHING := "nothing"
const NO_SPOT := "no_spot"
## How far over and under a drop's spot the Host looks for the top it would rest on.
const SPOT_PROBE := 0.05
## How far along the aim a Throw looks for the point the crosshair is on.
const AIM_FAR := 200.0
## The probe of _on_lying, made once.
var _probe := _make_probe()

## The level's loose Socks.
@export var mess: Mess
## The numbers of a player the Hands cannot find a tuning for (a Guest's, until M0.6).
@export var tuning: HandsTuning

@export_group("State")
## Each player's held Sock ids, newest last: {player id: PackedInt32Array}.
@export var held := {}
## Each player's active item, an index into their held ids: {player id: int}.
@export var active := {}
## When each player's last pick was granted, on the Host's clock: {player id: float}.
@export var grabbed_at := {}
@export_group("")

## The Host's clock in seconds (physics time since the level started): what the grab interval is
## measured on. Only the Host reads it.
var clock := 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	clock += delta


## Player `by`'s held Sock ids, newest last.
func items_of(by: int) -> PackedInt32Array:
	return held.get(by, PackedInt32Array())


## Player `by`'s active Sock, or -1 with empty Hands.
func active_of(by: int) -> int:
	var items := items_of(by)
	var i := int(active.get(by, items.size() - 1))
	return items[i] if i >= 0 and i < items.size() else -1


## The index of player `by`'s active item in items_of(), or -1.
func active_index(by: int) -> int:
	var items := items_of(by)
	var i := int(active.get(by, items.size() - 1))
	return i if i >= 0 and i < items.size() else -1


## The numbers that hold for player `by`: their player's HandsTuning when it is on this machine
## (alone, always), else these Hands' own.
func tuning_of(by: int) -> HandsTuning:
	var player := _player_of(by)
	if player != null and player.hands_tuning != null:
		return player.hands_tuning
	return _own_tuning()


## These Hands' own numbers (a default when none is set).
func _own_tuning() -> HandsTuning:
	if tuning == null:
		tuning = HandsTuning.new()
	return tuning


## The player asks to pick Sock `sock`.
func pick(by: int, sock: int) -> void:
	parts.ask(Command.new(&"pick", by, id, {"sock": sock}))


## The player asks to make the next (`step` 1) or the previous (-1) item active.
func cycle(by: int, step: int) -> void:
	parts.ask(Command.new(&"cycle", by, id, {"step": step}))


## The player asks to drop the active item where the crosshair meets a top at `point` (`normal` its
## up), both in the level.
func drop(by: int, point: Vector3, normal: Vector3) -> void:
	parts.ask(Command.new(&"drop", by, id, {"point": point, "normal": normal}))


## The player asks to throw the active item along `dir` (a unit vector, the aim) with `charge` (0
## to 1, how full the ring was). The Host decides where it leaves and how fast.
func throw(by: int, dir: Vector3, charge: float) -> void:
	parts.ask(Command.new(&"throw", by, id, {"dir": dir, "charge": charge}))


## What a Guest may send: a Sock id, a step, a spot, a direction and a charge. A pick at most 10 a
## second, a throw at most the tuning's `throw_rate`.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		&"pick": {"args": {"sock": {"type": TYPE_INT, "min": 0, "max": 1 << 30}}},
		&"cycle": {"args": {"step": {"type": TYPE_INT, "min": -1, "max": 1}}},
		&"drop": {"args": {"point": TYPE_VECTOR3, "normal": {"type": TYPE_VECTOR3, "min": -1.01, "max": 1.01}}},
		&"throw": {"args": {"dir": {"type": TYPE_VECTOR3, "min": -1.01, "max": 1.01},
				"charge": {"type": TYPE_FLOAT, "min": 0.0, "max": 1.0}}, "rate": _own_tuning().throw_rate},
	}


## Why player `by` may not pick Sock `sock` now, or "" when they may.
func pick_refusal(by: int, sock: int) -> String:
	if mess == null or sock < 0 or sock >= mess.count() \
			or not (mess.state_of(sock) == Mess.State.LYING or mess.is_moving(sock)):
		return GONE
	var t := tuning_of(by)
	var since := clock - float(grabbed_at.get(by, -INF))
	if since >= 0.0 and since < t.grab_interval:
		return SOON
	if not parts.near_point(by, mess.where_of(sock), t.reach + t.reach_slack):
		return FAR
	if items_of(by).size() >= t.capacity and mate_held(by, sock) < 0:
		return FULL
	return ""


## The held loose Sock that lying Sock `sock` would fuse with if player `by` picked it (same Design,
## both loose: I.4), or -1. A held Pair is never one (P03).
func mate_held(by: int, sock: int) -> int:
	if mess == null or mess.mate_of(sock) >= 0 or sock < 0 or sock >= mess.count():
		return -1
	for item in items_of(by):
		if item != sock and mess.mate_of(item) < 0 and mess.designs[item] == mess.designs[sock]:
			return item
	return -1


## Why player `by` may not drop their active item at `point` (a top whose up is `normal`), or ""
## when they may: something held, within reach, a top flat enough, and a top really there.
func drop_refusal(by: int, point: Vector3, normal: Vector3) -> String:
	if active_of(by) < 0:
		return NOTHING
	var t := tuning_of(by)
	if not point.is_finite() or not normal.is_finite() or normal.is_zero_approx():
		return NO_SPOT
	if not parts.near_point(by, point, t.reach + t.reach_slack):
		return FAR
	if _on_lying(point):
		return ""
	if normal.normalized().y < cos(deg_to_rad(t.drop_slope)):
		return NO_SPOT
	if not _top_at(point, t.drop_slope):
		return NO_SPOT
	return ""


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		&"pick":
			var sock: Variant = cmd.args.get("sock")
			if not (sock is int):
				return refuse("wrong")
			var why := pick_refusal(cmd.by, sock)
			if why != "":
				return refuse(why)
			var stamp := {"grabbed_at": _with(grabbed_at, cmd.by, clock)}
			var lead := mate_held(cmd.by, sock)
			if lead >= 0:
				# R04: the Pair goes to the end of the Hands and is the active item.
				var held_items := items_of(cmd.by).duplicate()
				held_items.remove_at(held_items.find(lead))
				held_items.append(lead)
				return {"ok": true, "paired": lead, "changes": {
					mess.id: mess.paired_patch(lead, sock),
					id: _patch(cmd.by, held_items, held_items.size() - 1, stamp)}}
			var items := items_of(cmd.by).duplicate()
			items.append(sock)
			return {"ok": true, "changes": {
				mess.id: mess.held_patch(sock),
				id: _patch(cmd.by, items, items.size() - 1, stamp)}}
		&"cycle":
			var step: Variant = cmd.args.get("step")
			if not (step is int) or step == 0:
				return refuse("wrong")
			var items := items_of(cmd.by)
			if items.size() < 2:
				return refuse("one")
			return grant({"active": _with(active, cmd.by, wrapi(active_index(cmd.by) + int(step), 0, items.size()))})
		&"drop":
			var point: Variant = cmd.args.get("point")
			var normal: Variant = cmd.args.get("normal")
			if not (point is Vector3) or not (normal is Vector3):
				return refuse("wrong")
			var why := drop_refusal(cmd.by, point, normal)
			if why != "":
				return refuse(why)
			return _let_go(cmd.by, drop_of(cmd.by, point), true)
		&"throw":
			var dir: Variant = cmd.args.get("dir")
			var charge: Variant = cmd.args.get("charge")
			if not (dir is Vector3) or not (charge is float) or not (dir as Vector3).is_finite() \
					or not is_equal_approx((dir as Vector3).length(), 1.0) or charge < 0.0 or charge > 1.0:
				return refuse("wrong")
			if active_of(cmd.by) < 0:
				return refuse(NOTHING)
			return _let_go(cmd.by, launch_of(cmd.by, (dir as Vector3).normalized(), charge), false)
	return refuse("wrong")


## The answer that lets player `by`'s active item go with `launch` (launch_of() or drop_of()): it flies
## in the Mess, the others stay in the Hands and the newest is active. `drop`: a drop, not a Throw.
func _let_go(by: int, launch: Dictionary, drop: bool) -> Dictionary:
	var sock := active_of(by)
	var items := items_of(by).duplicate()
	items.remove_at(active_index(by))
	return {"ok": true, "launch": launch, "changes": {
		mess.id: mess.thrown_patch(sock, launch["from"], launch["vel"], launch["spin"], by, drop),
		id: _patch(by, items, items.size() - 1)}}


## The Host: player `by` left (coop/03, Q2446). Everything in their Hands drops where they last
## stood, for everyone, in this one answer: each item is let go `leave_height` over their feet, the
## first right there and each next `leave_spread` round them (the old Landings.around), and falls as a
## drop does; their Hands are emptied. The answer carries "dropped_at" (their feet), where every
## machine hears the drop once (Hearing).
func left(by: int) -> Dictionary:
	var items := items_of(by)
	if items.is_empty():
		return {}
	var at: Variant = parts.where.call(by) if parts != null and parts.where.is_valid() else null
	var feet: Vector3 = at if at is Vector3 else Vector3.ZERO
	var t := tuning_of(by)
	var states := mess.states.duplicate()
	var poses := mess.poses.duplicate()
	var throws := mess.throws.duplicate()
	for i in items.size():
		var sock := items[i]
		var round_feet := Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * (t.leave_spread if i > 0 else 0.0)
		var pose := Transform3D(Basis(Vector3.UP, i * 2.4), feet + round_feet + Vector3.UP * t.leave_height)
		states[sock] = Mess.State.FLYING
		var row := Mess.pack(pose)
		for k in Mess.POSE:
			poses[sock * Mess.POSE + k] = row[k]
		throws[sock] = {"vel": Vector3.ZERO, "spin": Vector3.ZERO, "by": by, "drop": true}
	return {"ok": true, "dropped_at": feet, "changes": {
		mess.id: {"states": states, "poses": poses, "throws": throws},
		id: _patch(by, PackedInt32Array(), -1)}}


## The change that takes Socks `socks` out of player `by`'s Hands, the others kept in their order and
## the newest active (part of a Cabinet's shelve answer, core/04).
func taken_patch(by: int, socks: PackedInt32Array) -> Dictionary:
	var items := PackedInt32Array()
	for item in items_of(by):
		if not socks.has(item):
			items.append(item)
	return _patch(by, items, items.size() - 1)


## Where and how a Throw by player `by` along `dir` with `charge` leaves: {"from": the pose it leaves
## at (the hand's, never through a wall), "vel", "spin"}. Below the tap charge it is the lob (T02);
## above, faster the fuller the charge (T03). Its speed is the charge's, its direction the arc from
## where it leaves to the point the crosshair is on (Q2356), the low or the high one, whichever is
## nearer the old aim (along `dir`, the lob lifted); an aim at nothing, or out of the arc's reach,
## flies along that old aim.
func launch_of(by: int, dir: Vector3, charge: float) -> Dictionary:
	var t := tuning_of(by)
	var vel := dir * lerpf(t.min_speed, t.max_speed, charge)
	if charge < t.tap_charge:
		vel = dir * t.lob_speed + Vector3.UP * t.lob_lift
	var eyes := eyes_of(by)
	var from := start_of(by, dir)
	var hit := PhysicsQueries.ray(self, eyes, eyes + dir * AIM_FAR, Mess.AIM_MASK, _body_of(by))
	if not hit.is_empty():
		var aimed := Arc.aimed(from.origin, hit["position"], vel.length(), _gravity(), t.thrown_linear_damp, vel)
		if aimed != Vector3.ZERO:
			vel = aimed
	return {"from": from, "vel": vel, "spin": t.spin}


## Where and how a drop by player `by` on `point` leaves (Q2367): {"from": the pose it is let go at
## (the hand's, never through a wall), "vel": the drift that lets it fall on its own onto `point`,
## "spin": the turn that lays it flat by then, its length across the view, as the old drop lay}.
## A Pair's ball lands with its bottom on the point. When its fall from the hand would meet something
## first (a shelf seen through a cupboard's door, a table's edge) or drift faster than `drop_drift`,
## it is let go farther along the eye-line, at the first place whose fall is clear and slow enough,
## so it still lands where it was aimed.
func drop_of(by: int, point: Vector3) -> Dictionary:
	var eyes := eyes_of(by)
	var to := point
	var sock := active_of(by)
	var pair := mess.is_pair(sock)
	var t := tuning_of(by)
	if pair:
		to += Vector3.UP * SockDress.ball_radius(mess.design_of(sock))
	var dir := (point - eyes).normalized() if not point.is_equal_approx(eyes) else Vector3.FORWARD
	var from := start_of(by, dir)
	var damp := t.pair_linear_damp if pair else mess.bodies_tuning().woken_linear_damp
	var vel := Arc.dropped(from.origin, to, _gravity(), damp)
	var near := eyes.distance_to(from.origin)
	var far := eyes.distance_to(point) - t.drop_closest
	var step := 1
	while (Vector2(vel.x, vel.z).length() > t.drop_drift or not _falls_clear(by, from.origin, vel, to, damp)) \
			and step <= t.drop_tries and far > near:
		var at := eyes + dir * lerpf(near, far, float(step) / t.drop_tries)
		from = Transform3D(from.basis, at)
		vel = Arc.dropped(at, to, _gravity(), damp)
		step += 1
	var spin := Vector3.ZERO
	if not pair:
		var ticks := Arc.path(from.origin, vel, to.y, _gravity(), damp).size() - 1
		spin = Arc.turn_to(from.basis, Basis(Vector3.UP, atan2(-dir.x, -dir.z)), ticks,
				mess.bodies_tuning().woken_angular_damp)
	return {"from": from, "vel": vel, "spin": spin}


## Whether a body let go at `from` with `vel` falls to `to` meeting nothing on the way (its middle
## and its hanging lower end), the last `drop_closest` before it lands not counted.
func _falls_clear(by: int, from: Vector3, vel: Vector3, to: Vector3, damp: float) -> bool:
	var me := _body_of(by)
	var closest := tuning_of(by).drop_closest
	var low := Vector3.DOWN * SockDress.BOX.x * 0.5
	var points := Arc.path(from, vel, to.y, _gravity(), damp)
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		if b.distance_to(to) < closest:
			return true
		for off: Vector3 in [Vector3.ZERO, low]:
			if (b + off).y < to.y + 0.01:
				continue  # its lower end reaches the spot's level: that is its landing
			if not PhysicsQueries.ray(self, a + off, b + off, Mess.AIM_MASK, me).is_empty():
				return false
	return true


## Where player `by`'s active item leaves their Hands, looking along `dir`: the hand's pose (hand_of),
## or, when a wall is between the eyes and the hand or the hand is inside one (T04), on the
## eye-line `throw_clear` body depths short of the wall, turned as in the hand.
func start_of(by: int, dir: Vector3) -> Transform3D:
	var eyes := eyes_of(by)
	var hand := hand_of(by, dir)
	var out := hand.origin - eyes
	var me := _body_of(by)
	var clear := tuning_of(by).throw_clear
	var blocked := PhysicsQueries.ray(self, eyes, eyes + out.normalized() * (out.length() + clear), Mess.LAYER_HOUSE, me)
	if blocked.is_empty() and not PhysicsQueries.inside(self, hand.origin, Mess.LAYER_HOUSE, me):
		return hand
	var at := eyes + dir * out.length()
	var hit := PhysicsQueries.ray(self, eyes, at + dir * clear, Mess.LAYER_HOUSE, me)
	if not hit.is_empty():
		at = eyes + dir * maxf(0.0, eyes.distance_to(hit["position"]) - clear * 1.5)
	return Transform3D(hand.basis, at)


## Where player `by`'s active item hangs as they see it, looking along `dir` from their eyes: the
## HeldView's active place at its full apparent distance (the drawn one is `depth` nearer and as
## much smaller, so it looks the same), turned as it hangs, unscaled: the pose its body takes.
## The zoom and the turn button are looks only and not in it.
func hand_of(by: int, dir: Vector3) -> Transform3D:
	var worn: Variant = worn_hand_of(by)
	if worn is Transform3D:
		return worn
	var t := tuning_of(by)
	var up := Vector3.UP if absf(dir.normalized().y) < 0.999 else Vector3.BACK
	var view := Basis.looking_at(dir, up)
	var eyes := eyes_of(by)
	var sock := active_of(by)
	if mess.is_pair(sock):
		return Transform3D(view, eyes + view * t.active_pos)
	var design := mess.design_of(sock)
	var half := SockDress.BOX.x * 0.5 * (design.size_scale() if design != null else 1.0) * t.active_scale
	return Transform3D(view * HeldView.HANG, eyes + view * (t.active_pos + (Vector3.UP + HeldView.HANG.x) * half))


## Where Teammate `by`'s active item hangs on this machine, at their avatar's HoldPoint (its worn
## HeldView), unscaled; null for a player on this machine or one with no worn view here. A Teammate's
## Throw and drop leave from there at once (coop/05, Q2439).
func worn_hand_of(by: int) -> Variant:
	if not is_inside_tree() or _plays_here(by):
		return null
	var sock := active_of(by)
	for node in get_tree().get_nodes_in_group(HeldView.GROUP):
		var view := node as HeldView
		if view == null or not view.worn or view.me != by or view.hands != self:
			continue
		var at: Variant = view.drawn_of(sock)
		if at is Transform3D:
			return Transform3D((at as Transform3D).basis.orthonormalized(), (at as Transform3D).origin)
	return null


## Where player `by`'s eyes are: their player's when it is on this machine (alone, always), else
## the tuning's `eyes_fallback` above where they stand.
func eyes_of(by: int) -> Vector3:
	var player := _player_of(by)
	if player != null:
		return player.eyes()
	var at: Variant = parts.where.call(by) if parts != null and parts.where.is_valid() else null
	return (at as Vector3 if at is Vector3 else Vector3.ZERO) + Vector3.UP * tuning_of(by).eyes_fallback


## Player `by`'s own body when it is on this machine (what their let-go Sock leaves through), else none.
func _body_of(by: int) -> Array[RID]:
	var player := _player_of(by)
	var out: Array[RID] = []
	if player != null:
		out.append(player.get_rid())
	return out


## Player `by` when they play on this machine (alone, always), else null.
func _player_of(by: int) -> Player:
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(PLAYERS):
			var player := node as Player
			if player != null and player.player_id() == by:
				return player
	return null


## Whether player `by` plays in this Hands' own level on this machine (with two zoos in one tree, a
## player of the other zoo does not).
func _plays_here(by: int) -> bool:
	for node in get_tree().get_nodes_in_group(PLAYERS):
		var player := node as Player
		if player != null and player.player_id() == by and (owner == null or player.owner == owner):
			return true
	return false


static func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))


## Whether `point` is on a lying Sock or Pair (within SPOT_PROBE of its body): a drop there is allowed
## anywhere on it, with no slope test (R05, the old rig_drop.gd).
func _make_probe() -> SphereShape3D:
	var probe := SphereShape3D.new()
	probe.radius = SPOT_PROBE
	return probe


func _on_lying(point: Vector3) -> bool:
	if mess == null or not is_inside_tree():
		return false
	for rid in PhysicsQueries.overlap_rids(self, _probe, Transform3D(Basis.IDENTITY, point), Mess.LAYER_LYING, 8):
		if mess.sock_at(rid) >= 0:
			return true
	return false


## Whether a top a drop rests on is at `point`: straight down from just over it, the first thing
## met is right there and flat enough.
func _top_at(point: Vector3, slope: float) -> bool:
	if not is_inside_tree():
		return true
	var hit := PhysicsQueries.ray(self, point + Vector3.UP * SPOT_PROBE, point + Vector3.DOWN * SPOT_PROBE, Mess.AIM_MASK)
	return not hit.is_empty() and (hit["normal"] as Vector3).y >= cos(deg_to_rad(slope)) - 0.001


## The change to player `by`'s Hands: their items and active index, and any `more` fields.
func _patch(by: int, items: PackedInt32Array, index: int, more := {}) -> Dictionary:
	var h := held.duplicate()
	var a := active.duplicate()
	if items.is_empty():
		h.erase(by)
		a.erase(by)
	else:
		h[by] = items
		a[by] = index
	var patch := {"held": h, "active": a}
	patch.merge(more)
	return patch


static func _with(d: Dictionary, key: Variant, value: Variant) -> Dictionary:
	var out := d.duplicate()
	out[key] = value
	return out
