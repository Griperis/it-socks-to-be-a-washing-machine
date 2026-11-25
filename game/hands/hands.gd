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
##
## The Hand-off (core/42, list 02 approved with Q2588-Q2590): `hand_off` gives the active item to a
## Teammate the giver aims at; the Host-only `catch` is the same rule for a Throw below full charge
## that hits a Teammate (Knockdowns' hit test asks it). A Pair always goes over; a loose Sock only when
## it completes a Pair in the receiver's Hands (take_refusal(): "Not their mate" to the giver, the
## Sock stays; a refused catch bounces off, with no Command). Taken, it goes in as a pick does (a Pair
## made there leads at the end of the Hands, active); with no room it lies at the receiver's feet
## ("full": the receiver reads "Hands full"). Nobody takes from another's Hands (Q244); a knocked-down
## Teammate is never handed to (Q2589). The answer names the "giver" (-1 for a catch), the
## "receiver" and the "item".
##
## Carried things (core/78): a Carriable takes the whole Hands. carries() names the one player `by`
## carries; while they carry it no Sock or Pair comes in (a pick is refused "full", a Hand-off or a
## catch lies at their feet), and a carried thing's put down is checked as a drop's place
## (spot_refusal()). body_frame() is where a carrier's body is drawn on this machine (its hold slot
## rides it).
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
## Why a Hand-off or a catch is refused: the loose Sock completes no Pair there, the receiver is
## knocked down, the giver aimed at themselves.
const NOT_MATE := "not_mate"
const DOWN := "down"
const SELF := "self"
## The Hand-off's verbs: a player's, and the Host's own for a Throw that hits a Teammate.
const HAND_OFF := &"hand_off"
const CATCH := &"catch"
## How far over and under a receiver's feet the Host looks for the floor an item laid there lies on.
const FLOOR_PROBE := 0.5
const HAND_OFF_DEFAULT := preload("res://game/hands/hand_off_tuning.tres")
## A Teammate's stand and crouch heights (their own MoveTuning is on their machine).
const MOVE_DEFAULT := preload("res://game/player/move_tuning.tres")
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
## The Hand-off's numbers (hand_off_tuning.tres when empty).
@export var hand_off_tuning: HandOffTuning

@export_group("State")
## Each player's held Sock ids, newest last: {key: PackedInt32Array}. The key is the player id from the
## Roster (Z1: the same on every machine, a rejoin and a late joiner included), or the peer number
## while nobody's Roster names them (alone).
@export var held := {}
## Each player's active item, an index into their held ids: {key: int}.
@export var active := {}
## When each player's last pick was granted, on the Host's clock: {key: float}.
@export var grabbed_at := {}
@export_group("")

## The level's Roster, found once (null alone, or with none).
var _roster: Roster
var _roster_looked := false
## The last player id seen on each peer: the key still holds once the Roster is cleared.
var _ids: Dictionary[int, String] = {}
## A Teammate's numbers built from the Roster (D13), by player id, and what they were built from.
var _teammate_tuning: Dictionary[String, HandsTuning] = {}
var _teammate_sent: Dictionary[String, Dictionary] = {}
var _teammate_base: HandsTuning
## The level's Knockdowns (who is down), found once among the Parts.
var _knockdowns: Knockdowns

## The Host's clock in seconds (physics time since the level started): what the grab interval is
## measured on. Only the Host reads it.
var clock := 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	clock += delta


## The key player `by` (a peer number) is kept under in the State: their player id once a Roster
## names them, else the peer number (Z1).
func key_of(by: int) -> Variant:
	var r := _roster_of()
	var pid := r.id_of(by) if r != null else ""
	if pid != "":
		_ids[by] = pid
		return pid
	if _ids.has(by):
		return _ids[by]
	return by


## Player `by`'s held Sock ids, newest last.
func items_of(by: int) -> PackedInt32Array:
	var key: Variant = key_of(by)
	if held.has(key):
		return held[key]
	return held.get(by, PackedInt32Array())


## Player `by`'s active Sock, or -1 with empty Hands.
func active_of(by: int) -> int:
	var items := items_of(by)
	var i := int(active.get(key_of(by), active.get(by, items.size() - 1)))
	return items[i] if i >= 0 and i < items.size() else -1


## The index of player `by`'s active item in items_of(), or -1.
func active_index(by: int) -> int:
	var items := items_of(by)
	var i := int(active.get(key_of(by), active.get(by, items.size() - 1)))
	return i if i >= 0 and i < items.size() else -1


## The numbers that hold for player `by`: their player's HandsTuning when it is on this machine
## (alone, always); a Teammate's own, as they sent it at their join and the Host wrote it into the
## Roster (D13), clamped to what Upgrades can make them (HandsTuning.clamped()); else these Hands' own.
func tuning_of(by: int) -> HandsTuning:
	var player := _player_of(by)
	if player != null and player.hands_tuning != null:
		return player.hands_tuning
	var r := _roster_of()
	var pid := r.id_of(by) if r != null else ""
	var sent: Variant = r.entry_of(by).get("hands") if pid != "" else null
	if sent is Dictionary:
		if not _teammate_tuning.has(pid) or _teammate_sent.get(pid) != sent or _teammate_base != _own_tuning():
			_teammate_base = _own_tuning()
			_teammate_tuning[pid] = _teammate_base.clamped(sent)
			_teammate_sent[pid] = (sent as Dictionary).duplicate()
		return _teammate_tuning[pid]
	return _own_tuning()


## The level's Roster (found once among the Parts), or null.
func _roster_of() -> Roster:
	if _roster != null and is_instance_valid(_roster):
		return _roster
	if parts == null:
		return null
	if not _roster_looked or _roster == null:
		_roster_looked = true
		_roster = parts.find(func(part: Part) -> bool: return part is Roster) as Roster
	return _roster


## These Hands' own numbers: the floor and ceiling of a Teammate's (HandsTuning.clamped()).
func own_tuning() -> HandsTuning:
	return _own_tuning()


## These Hands' own numbers (a default when none is set).
func _own_tuning() -> HandsTuning:
	if tuning == null:
		tuning = HandsTuning.new()
	return tuning


## The player asks to pick Sock `sock`. `seq` (Parts.next_seq()): a Guest's ghost waits on the
## answer that echoes it (coop/09); every ask below takes one the same way.
func pick(by: int, sock: int, seq := 0) -> void:
	_ask(Command.new(&"pick", by, id, {"sock": sock}), seq)


## The player asks to make the next (`step` 1) or the previous (-1) item active.
func cycle(by: int, step: int, seq := 0) -> void:
	_ask(Command.new(&"cycle", by, id, {"step": step}), seq)


## The player asks to drop the active item where the crosshair meets a top at `point` (`normal` its
## up), both in the level.
func drop(by: int, point: Vector3, normal: Vector3, seq := 0) -> void:
	_ask(Command.new(&"drop", by, id, {"point": point, "normal": normal}), seq)


## The player asks to throw the active item along `dir` (a unit vector, the aim) with `charge` (0
## to 1, how full the ring was). The Host decides where it leaves and how fast.
func throw(by: int, dir: Vector3, charge: float, seq := 0) -> void:
	_ask(Command.new(&"throw", by, id, {"dir": dir, "charge": charge}), seq)


## The player asks to hand their active item to Teammate `to` (a peer number), whom they aim at.
func hand_off(by: int, to: int, seq := 0) -> void:
	_ask(Command.new(HAND_OFF, by, id, {"to": to}), seq)


func _ask(cmd: Command, seq: int) -> void:
	cmd.seq = seq
	parts.ask(cmd)


## The Mess draws a Teammate's let-go Sock from their avatar's hand (worn_start_of(), coop/13).
func _ready() -> void:
	if mess != null:
		mess.worn_start = worn_start_of


## What a Guest may send: a Sock id, a step, a spot, a direction and a charge. A pick at most 10 a
## second, a throw at most the tuning's `throw_rate`.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		&"pick": {"args": {"sock": {"type": TYPE_INT, "min": 0, "max": 1 << 30}}},
		&"cycle": {"args": {"step": {"type": TYPE_INT, "min": -1, "max": 1}}},
		&"drop": {"args": {"point": TYPE_VECTOR3, "normal": {"type": TYPE_VECTOR3, "min": -1.01, "max": 1.01}}},
		&"throw": {"args": {"dir": {"type": TYPE_VECTOR3, "min": -1.01, "max": 1.01},
				"charge": {"type": TYPE_FLOAT, "min": 0.0, "max": 1.0}}, "rate": _own_tuning().throw_rate},
		HAND_OFF: {"args": {"to": {"type": TYPE_INT, "min": 1, "max": 2147483647}}},
	}


## Why player `by` may not pick Sock `sock` now, or "" when they may.
func pick_refusal(by: int, sock: int) -> String:
	if mess == null or sock < 0 or sock >= mess.count() \
			or not (mess.state_of(sock) == Mess.State.LYING or mess.is_moving(sock)):
		return GONE
	var t := tuning_of(by)
	var since := clock - float(grabbed_at.get(key_of(by), grabbed_at.get(by, -INF)))
	if since >= 0.0 and since < t.grab_interval:
		return SOON
	if not parts.near_point(by, mess.where_of(sock), t.reach + t.reach_slack):
		return FAR
	if carries(by) != null or (items_of(by).size() >= t.capacity and mate_held(by, sock) < 0):
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
	return spot_refusal(by, point, normal)


## Why nothing player `by` holds may be put down at `point` (a top whose up is `normal`), or "": within
## reach, a top flat enough, and a top really there (a Sock's drop and a carried thing's put down).
func spot_refusal(by: int, point: Vector3, normal: Vector3) -> String:
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
			var stamp := {"grabbed_at": _with(_without(grabbed_at, cmd.by), key_of(cmd.by), clock)}
			var lead := mate_held(cmd.by, sock)
			# The run's tallies (core/83): a Sock out of the Mess is picked, and made when it fused a Pair.
			var tallies := RunTallies.of(self)
			var loose := 0 if mess.is_pair(sock) else 1
			if lead >= 0:
				# R04: the Pair goes to the end of the Hands and is the active item.
				var held_items := items_of(cmd.by).duplicate()
				held_items.remove_at(held_items.find(lead))
				held_items.append(lead)
				var fused := {"ok": true, "paired": lead, "changes": {
					mess.id: mess.paired_patch(lead, sock),
					id: _patch(cmd.by, held_items, held_items.size() - 1, stamp)}}
				if tallies != null:
					fused["changes"][tallies.id] = tallies.picked_patch(cmd.by, loose, 1)
				return fused
			var items := items_of(cmd.by).duplicate()
			items.append(sock)
			var taken := {"ok": true, "changes": {
				mess.id: mess.held_patch(sock),
				id: _patch(cmd.by, items, items.size() - 1, stamp)}}
			if tallies != null:
				taken["changes"][tallies.id] = tallies.picked_patch(cmd.by, loose, 0)
			return taken
		&"cycle":
			var step: Variant = cmd.args.get("step")
			if not (step is int) or step == 0:
				return refuse("wrong")
			var items := items_of(cmd.by)
			if items.size() < 2:
				return refuse("one")
			return grant({"active": _with(_without(active, cmd.by), key_of(cmd.by), wrapi(active_index(cmd.by) + int(step), 0, items.size()))})
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
		HAND_OFF:
			var to: Variant = cmd.args.get("to")
			if not (to is int):
				return refuse("wrong")
			var why := hand_off_refusal(cmd.by, to)
			if why != "":
				return refuse(why)
			return _give(cmd.by, to, active_of(cmd.by), _feet_of(cmd.by))
		CATCH:
			return _decide_catch(cmd)
	return refuse("wrong")


# --- Carried things (core/78) -------------------------------------------------------------------

## The thing player `by` carries in these Hands' level, or null. A carried thing takes the whole Hands.
func carries(by: int) -> Carriable:
	if not is_inside_tree() or parts == null:
		return null
	for node in get_tree().get_nodes_in_group(Carriable.GROUP):
		var c := node as Carriable
		if c != null and c.holder == by and c.parts == parts:
			return c
	return null


## Where player `by`'s body is drawn on this machine: {"feet" (the level's), "yaw" (radians, the way
## the body faces), "drop" (how far a Crouch lowers it now, metres)}; their own player's as drawn this
## frame (between physics ticks, turned by the look as it is now), a Teammate's avatar's here; {} when
## this machine draws no body of theirs.
func body_frame(by: int) -> Dictionary:
	var player := _player_of(by)
	if player != null:
		var mt := player.tuning if player.tuning != null else MOVE_DEFAULT
		return {"feet": player.get_global_transform_interpolated().origin, "yaw": player.global_rotation.y,
				"drop": player.own_body().crouch * (mt.stand_height - mt.crouch_height)}
	var avatar := _avatar_of(by)
	if avatar != null:
		return {"feet": avatar.global_position, "yaw": avatar.global_rotation.y,
				"drop": avatar.crouch * (MOVE_DEFAULT.stand_height - MOVE_DEFAULT.crouch_height)}
	return {}


# --- The Hand-off (core/42) ----------------------------------------------------------------------

## The Hand-off's numbers (a default when none is set).
func hand_off_numbers() -> HandOffTuning:
	if hand_off_tuning == null:
		hand_off_tuning = HAND_OFF_DEFAULT
	return hand_off_tuning


## Why player `by` may not hand their active item to `to` now, or "" when they may (lines 11-17, 40,
## Q2589): something held, `to` another player this level can place, not knocked down, within reach
## (the Host's view of a Guest is a little old: the slack and the body's radius over the reach), and
## the item one `to` may take (take_refusal()).
func hand_off_refusal(by: int, to: int) -> String:
	var sock := active_of(by)
	if sock < 0:
		return NOTHING
	if to == by:
		return SELF
	var at: Variant = _feet_or_null(to)
	if not (at is Vector3):
		return GONE
	if is_down(to):
		return DOWN
	var t := tuning_of(by)
	if not parts.near_point(by, at, t.reach + t.reach_slack + hand_off_numbers().body_radius):
		return FAR
	return take_refusal(to, sock)


## Why player `to` may not be given item `sock` (a held or flying Sock or Pair), or "" when they may:
## a Pair always goes over (Q663); a loose Sock only when it completes a Pair there, their loose mate
## held (Q652, Q658). Room is not asked here: with none it lies at their feet.
func take_refusal(to: int, sock: int) -> String:
	if mess == null or sock < 0 or sock >= mess.count():
		return GONE
	if mess.is_pair(sock) or mate_held(to, sock) >= 0:
		return ""
	return NOT_MATE


## Whether player `to` has room for item `sock` in their Hands (line 18): a Pair needs a free place;
## a loose Sock pairs with its held mate or needs a free place.
func can_take(to: int, sock: int) -> bool:
	if carries(to) != null:
		return false
	if not mess.is_pair(sock) and mate_held(to, sock) >= 0:
		return true
	return items_of(to).size() < tuning_of(to).capacity


## Whether player `peer` is knocked down now (the level's Knockdowns; never, with none), or out of play
## in a washing machine's drum (core/98): nothing is handed or caught to them.
func is_down(peer: int) -> bool:
	var kd := _knockdowns_of()
	return kd != null and (kd.is_down(peer) or kd.is_washed(peer))


func _knockdowns_of() -> Knockdowns:
	if _knockdowns != null and is_instance_valid(_knockdowns):
		return _knockdowns
	if parts == null:
		return null
	_knockdowns = parts.find(func(part: Part) -> bool: return part is Knockdowns) as Knockdowns
	return _knockdowns


## The Host-only catch (line 33-36): Throw `sock` below full charge hit Teammate `to` at `at` (the
## hit test of Knockdowns asks it only when take_refusal() allows it; a refused one bounces there).
func _decide_catch(cmd: Command) -> Dictionary:
	var sock: Variant = cmd.args.get("sock")
	var to: Variant = cmd.args.get("to")
	var at: Variant = cmd.args.get("at")
	if cmd.by != Parts.HOST or not (sock is int) or not (to is int) or not (at is Vector3) or not (at as Vector3).is_finite():
		return refuse("wrong")
	if mess == null or sock < 0 or sock >= mess.count() or mess.state_of(sock) != Mess.State.FLYING or not mess.is_throw(sock):
		return refuse(GONE)
	var thrower := int((mess.throws[sock] as Dictionary).get("by", Mess.NOBODY))
	if to == thrower:
		return refuse(SELF)
	if not (_feet_or_null(to) is Vector3):
		return refuse(GONE)
	if is_down(to):
		return refuse(DOWN)
	var why := take_refusal(to, sock)
	if why != "":
		return refuse(why)
	var from: Variant = _feet_or_null(thrower)
	var ev := _give(Mess.NOBODY, to, sock, from if from is Vector3 else at)
	ev["thrower"] = thrower
	ev["at"] = at
	return ev


## The answer that gives item `sock` to player `to`, out of `giver`'s Hands (Mess.NOBODY: a caught
## Throw), `toward` where it came from (lines 18-24): pairing with their held loose mate (the Pair
## leads at the end of their Hands, active: "paired" names it), or into a free place at the end,
## active; with no room it lies at their feet, square to where it came from ("full", "laid_at").
func _give(giver: int, to: int, sock: int, toward: Vector3) -> Dictionary:
	var ev := {"ok": true, "giver": giver, "receiver": to, "item": sock}
	var p := {"held": held.duplicate(), "active": active.duplicate()}
	if giver != Mess.NOBODY:
		var left_items := items_of(giver).duplicate()
		left_items.remove_at(left_items.find(sock))
		_set_items(p, giver, left_items)
	var changes := {id: p}
	var lead := mate_held(to, sock)
	if lead >= 0:
		var to_items := items_of(to).duplicate()
		to_items.remove_at(to_items.find(lead))
		to_items.append(lead)
		_set_items(p, to, to_items)
		changes[mess.id] = mess.paired_patch(lead, sock)
		ev["paired"] = lead
	elif can_take(to, sock):
		var to_items := items_of(to).duplicate()
		to_items.append(sock)
		_set_items(p, to, to_items)
		if mess.state_of(sock) != Mess.State.HELD:
			changes[mess.id] = mess.held_patch(sock)
	else:
		var pose := lay_pose(to, sock, toward)
		changes[mess.id] = mess.lying_patch(sock, pose)
		ev["full"] = true
		ev["laid_at"] = pose.origin
	if changes.has(mess.id):
		# A caught Throw is over (a pick's or pairing's row keeps its record's launch).
		((changes[mess.id] as Dictionary)[Mess.LAUNCHES] as Dictionary).erase(sock)
	ev["changes"] = changes
	return ev


## Where item `sock` lies when laid at player `to`'s feet (lines 23, 24): flat on the floor under
## them, turned across the way from `toward` to them as a drop lies across the view (no turn button,
## Q2304), by the Mess's rule for something put down (Mess.put_down()).
func lay_pose(to: int, sock: int, toward: Vector3) -> Transform3D:
	var at: Variant = _feet_or_null(to)
	var feet: Vector3 = at if at is Vector3 else toward
	var hit := PhysicsQueries.ray(self, feet + Vector3.UP * FLOOR_PROBE, feet + Vector3.DOWN * FLOOR_PROBE, Mess.LAYER_HOUSE)
	if not hit.is_empty():
		feet = hit["position"]
	var way := feet - toward
	way.y = 0.0
	var yaw := atan2(-way.x, -way.z) if way.length() > 0.001 else 0.0
	var lift := Vector3.UP * SockDress.ball_radius(mess.design_of(sock)) if mess.is_pair(sock) else Vector3.ZERO
	var put := mess.put_down(sock, Transform3D(Basis(Vector3.UP, yaw), feet + lift))
	return put["pose"]


## Where player `by` stands as this machine knows it (Parts.where), or null when it cannot place them.
func _feet_or_null(by: int) -> Variant:
	if parts == null or not parts.where.is_valid():
		var player := _player_of(by)
		return player.global_position if player != null else null
	return parts.where.call(by)


## Where player `by` stands, or the origin when this machine cannot place them.
func _feet_of(by: int) -> Vector3:
	var at: Variant = _feet_or_null(by)
	return at if at is Vector3 else Vector3.ZERO


## Sets player `by`'s held items to `items` in patch `p` ({"held", "active"}), the newest active (as
## _patch() does for one player).
func _set_items(p: Dictionary, by: int, items: PackedInt32Array) -> void:
	var key: Variant = key_of(by)
	var h: Dictionary = p["held"]
	var a: Dictionary = p["active"]
	h.erase(by)
	a.erase(by)
	if items.is_empty():
		h.erase(key)
		a.erase(key)
	else:
		h[key] = items
		a[key] = items.size() - 1


## Where the item player `by` handed off was drawn on this machine as it left their Hands (line 25),
## in the level: their own first-person hand or their worn Hands on their avatar here (each HeldView
## still draws it until its next refresh), else their avatar's HoldPoint, else their eyes.
func handed_from(by: int, sock: int) -> Vector3:
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(HeldView.GROUP):
			var view := node as HeldView
			if view != null and view.hands == self and view.me == by:
				var at: Variant = view.drawn_of(sock)
				if at is Transform3D:
					return (at as Transform3D).origin
	var worn: Variant = worn_start_of(by, sock)
	if worn is Transform3D:
		return (worn as Transform3D).origin
	return eyes_of(by)


## The answer that lets player `by`'s active item go with `launch` (launch_of() or drop_of()): it flies
## in the Mess, the others stay in the Hands and the newest is active. `drop`: a drop, not a Throw.
func _let_go(by: int, launch: Dictionary, drop: bool) -> Dictionary:
	var sock := active_of(by)
	var items := items_of(by).duplicate()
	items.remove_at(active_index(by))
	return {"ok": true, "launch": launch, "changes": {
		mess.id: mess.thrown_patch(sock, launch["from"], launch["vel"], launch["spin"], by, drop, {}, float(launch.get("charge", -1.0))),
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
	var dropped := {}
	for i in items.size():
		var round_feet := Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * (t.leave_spread if i > 0 else 0.0)
		var pose := Transform3D(Basis(Vector3.UP, i * 2.4), feet + round_feet + Vector3.UP * t.leave_height)
		dropped = mess.thrown_patch(items[i], pose, Vector3.ZERO, Vector3.ZERO, by, true, dropped)
	return {"ok": true, "dropped_at": feet, "changes": {
		mess.id: dropped,
		id: _patch(by, PackedInt32Array(), -1)}}


## What a save keeps: who holds what and which is active; not the Host's clock (`grabbed_at`).
func save_state() -> Dictionary:
	return {"held": held, "active": active}


## The Host, after a load (Q2559, Q295): nobody holds anything offline, so every player's Hands but
## the Host's (`host`, its player id) drop where that player last stood (their Roster spot), as a
## leaver's do; they come back empty-handed.
func loaded(host: String) -> Dictionary:
	var r := _roster_of()
	var keep_held := {}
	var keep_active := {}
	var dropped := {}
	var t := _own_tuning()
	var gone := false
	for key: Variant in held:
		if str(key) == host or (key is int and int(key) == Parts.HOST):
			keep_held[key] = held[key]
			if active.has(key):
				keep_active[key] = active[key]
			continue
		gone = true
		var items: PackedInt32Array = held[key]
		var entry: Dictionary = r.players.get(str(key), {}) if r != null else {}
		var feet: Vector3 = entry.get("at", mess.return_pose(items[0]).origin if not items.is_empty() else Vector3.ZERO)
		for i in items.size():
			var round_feet := Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * (t.leave_spread if i > 0 else 0.0)
			var pose := Transform3D(Basis(Vector3.UP, i * 2.4), feet + round_feet + Vector3.UP * t.leave_height)
			dropped = mess.thrown_patch(items[i], pose, Vector3.ZERO, Vector3.ZERO, Mess.NOBODY, true, dropped)
	if not gone:
		return {}
	var changes := {id: {"held": keep_held, "active": keep_active, "grabbed_at": {}}}
	if not dropped.is_empty():
		changes[mess.id] = dropped
	return {"ok": true, "changes": changes}


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
## flies along that old aim. "charge" goes with it: a full one can knock a Teammate down (coop/10).
## Worked out alike on the Host and on the thrower's own machine (a Guest's Throw ghost, Q2573).
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
	return {"from": from, "vel": vel, "spin": t.spin, "charge": charge}


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


## Where player `by`'s active item leaves their Hands, looking along `dir`: their own hand as their
## own screen shows it (own_hand_of(), on every machine alike: the Host lets a Guest's Throw go where
## the Guest's ghost leaves, coop/13, Q2573), or, when a wall is between the eyes and the hand or the
## hand is inside one (T04), on the eye-line `throw_clear` body depths short of the wall, turned as in
## the hand.
func start_of(by: int, dir: Vector3) -> Transform3D:
	var eyes := eyes_of(by)
	var hand := own_hand_of(by, dir)
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
	return own_hand_of(by, dir)


## Where player `by`'s active item hangs on their own screen, looking along `dir` from their eyes
## (eyes_of(): their avatar's on another machine), unscaled: where it leaves their Hands on every
## machine (start_of()).
func own_hand_of(by: int, dir: Vector3) -> Transform3D:
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


## Where Teammate `by`'s Sock `sock` hangs on their avatar here (its HoldPoint, the worn hang:
## HeldView.worn_pose()), unscaled, whether or not their worn view still draws it; null for a player
## on this machine or one with no avatar here. Their Throw or drop leaves their own hand (start_of())
## but is drawn here from this place, easing onto its body (Mess, coop/13; Q2439).
func worn_start_of(by: int, sock: int) -> Variant:
	if not is_inside_tree() or sock < 0 or _plays_here(by):
		return null
	var avatar := _avatar_of(by)
	if avatar == null or avatar.looks == null:
		return null
	var at := avatar.looks.avatar_hold() * HeldView.worn_pose(mess, sock)
	return Transform3D(at.basis.orthonormalized(), at.origin)


## Where player `by`'s eyes are: their player's when it is on this machine (alone, always), else
## their avatar's here (a Guest's on the Host, a Teammate's on a Guest: G15, Z2), else the tuning's
## `eyes_fallback` above where they stand.
func eyes_of(by: int) -> Vector3:
	var player := _player_of(by)
	if player != null:
		return player.eyes()
	var avatar := _avatar_of(by)
	if avatar != null:
		return avatar.eyes()
	var at: Variant = parts.where.call(by) if parts != null and parts.where.is_valid() else null
	return (at as Vector3 if at is Vector3 else Vector3.ZERO) + Vector3.UP * tuning_of(by).eyes_fallback


## Player `by`'s own body when it is on this machine (what their let-go Sock leaves through), else none.
func _body_of(by: int) -> Array[RID]:
	var player := _player_of(by)
	var out: Array[RID] = []
	if player != null:
		out.append(player.get_rid())
	return out


## Player `by`'s avatar in this Hands' own level on this machine, or null (alone, none).
func _avatar_of(by: int) -> Avatar:
	if not is_inside_tree():
		return null
	var level := LevelRuntime.level_of(self)
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var avatar := node as Avatar
		if avatar != null and avatar.peer() == by and not avatar.is_queued_for_deletion() \
				and (level == null or level.is_ancestor_of(avatar)):
			return avatar
	return null


## Player `by` when they play on this machine (alone, always), else null. With two zoos in one tree
## (a co-op test), each its own machine with its own MultiplayerAPI, a player of the other is not one.
func _player_of(by: int) -> Player:
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(PLAYERS):
			var player := node as Player
			if player != null and player.player_id() == by and player.multiplayer == multiplayer:
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
	var key: Variant = key_of(by)
	var h := _without(held, by)
	var a := _without(active, by)
	if items.is_empty():
		h.erase(key)
		a.erase(key)
	else:
		h[key] = items
		a[key] = index
	var patch := {"held": h, "active": a}
	patch.merge(more)
	return patch


## `d` without the peer-number key `by` (a key from before a Roster named them).
static func _without(d: Dictionary, by: int) -> Dictionary:
	var out := d.duplicate()
	out.erase(by)
	return out


static func _with(d: Dictionary, key: Variant, value: Variant) -> Dictionary:
	var out := d.duplicate()
	out[key] = value
	return out
