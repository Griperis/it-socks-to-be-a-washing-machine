## Every player's Hands as one Part, keyed by player id (1 alone, Q2212): the Socks each holds, in
## the order picked (newest last), and which one is active. Every change is a Command the Host
## answers: `pick` a lying Sock, `cycle` the active item, `drop` the active item on a spot. A pick
## and a drop each change two Parts in one answer: the Sock's record in the Mess and these Hands.
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
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(PLAYERS):
			var player := node as Player
			if player != null and player.player_id() == by and player.hands_tuning != null:
				return player.hands_tuning
	return tuning if tuning != null else HandsTuning.new()


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


## What a Guest may send: a Sock id, a step, a spot. A pick at most 10 a second.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		&"pick": {"args": {"sock": {"type": TYPE_INT, "min": 0, "max": 1 << 30}}},
		&"cycle": {"args": {"step": {"type": TYPE_INT, "min": -1, "max": 1}}},
		&"drop": {"args": {"point": TYPE_VECTOR3, "normal": {"type": TYPE_VECTOR3, "min": -1.01, "max": 1.01}}},
	}


## Why player `by` may not pick Sock `sock` now, or "" when they may.
func pick_refusal(by: int, sock: int) -> String:
	if mess == null or sock < 0 or sock >= mess.count() or mess.state_of(sock) != Mess.State.LYING:
		return GONE
	var t := tuning_of(by)
	var since := clock - float(grabbed_at.get(by, -INF))
	if since >= 0.0 and since < t.grab_interval:
		return SOON
	if not parts.near_point(by, mess.pose_of(sock).origin, t.reach + t.reach_slack):
		return FAR
	if items_of(by).size() >= t.capacity:
		return FULL
	return ""


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
			var items := items_of(cmd.by).duplicate()
			items.append(sock)
			return {"ok": true, "changes": {
				mess.id: mess.held_patch(sock),
				id: _patch(cmd.by, items, items.size() - 1, {"grabbed_at": _with(grabbed_at, cmd.by, clock)})}}
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
			var sock := active_of(cmd.by)
			var items := items_of(cmd.by).duplicate()
			items.remove_at(active_index(cmd.by))
			return {"ok": true, "changes": {
				mess.id: mess.flying_patch(sock, _let_go(cmd.by, point)),
				id: _patch(cmd.by, items, items.size() - 1)}}
	return refuse("wrong")


## The pose a dropped Sock is let go at: flat, `drop_lift` over its spot, its length across the
## dropper's view.
func _let_go(by: int, point: Vector3) -> Transform3D:
	var t := tuning_of(by)
	var yaw := 0.0
	if parts.where.is_valid():
		var at: Variant = parts.where.call(by)
		if at is Vector3:
			var to := point - (at as Vector3)
			yaw = atan2(-to.x, -to.z)
	return Transform3D(Basis(Vector3.UP, yaw), point + Vector3.UP * t.drop_lift)


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
