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
## The `carry_guards` seam (core/137): a sibling Part in the group GUARDS may refuse a pick
## (`pick_refusal(by) -> StringName`, empty to allow: a Teammate's present, "not_yours", said by nobody) and
## hide the thing from a player's crosshair (`aimable_by(by) -> bool`: no outline, no prompt, no click).
class_name Carriable
extends Part

## Every Carriable is in this group (Hands.carries() looks there).
const GROUP := &"carriables"
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

@export_group("State")
## Who holds it: a player's id, or 0 when it lies at `at`.
@export var holder := 0
## Where it lies. INF means "where it stands in the scene", so placing it in the editor is enough.
@export var at := Vector3.INF
## Its turn about the up axis where it lies, in radians.
@export var yaw := 0.0
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
	}


## Why player `by` may not pick it up now, or "": a guard refuses (its own word: a Teammate's present,
## "not_yours"), someone holds it ("gone"), too far ("far"), or their Hands hold something ("full").
func pick_refusal(by: int) -> String:
	for guard in guards():
		if guard.has_method(&"pick_refusal"):
			var why := String(guard.call(&"pick_refusal", by))
			if why != "":
				return why
	if holder != 0:
		return "gone"
	if parts != null and not parts.near(by, get_parent(), reach):
		return "far"
	if hands_busy(by):
		return FULL
	return ""


## Whether player `by`'s Hands hold anything: a Sock or a Pair, or a carried thing.
func hands_busy(by: int) -> bool:
	var h := hands()
	if h != null:
		return h.carries(by) != null or not h.items_of(by).is_empty()
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
	return refuse("wrong")


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
	_set_shapes(thing, holder == 0)
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


## Each frame: carried, it rides its carrier's slot as their body is drawn here; just put down, its
## Looks eases to where it lies.
func _process(delta: float) -> void:
	var thing := get_parent() as Node3D
	if thing == null:
		return
	if holder != 0:
		var pose: Variant = carry_pose(holder)
		if pose is Transform3D:
			thing.global_transform = pose
		return
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
