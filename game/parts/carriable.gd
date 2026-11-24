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
class_name Carriable
extends Part

## How far from the thing a player may stand to pick it up, and how far from the player it may be
## put down, in metres (Parts.near(); checked only once the game sets Parts.where).
@export var reach := 3.0

@export_group("State")
## Who holds it: a player's id, or 0 when it lies at `at`.
@export var holder := 0
## Where it lies. INF means "where it stands in the scene", so placing it in the editor is enough.
@export var at := Vector3.INF
## Its turn about the up axis where it lies, in radians.
@export var yaw := 0.0
@export_group("")


## The player's use button picks it up.
func use(by: int) -> void:
	pick(by)


func pick(by: int) -> void:
	parts.ask(Command.new(&"pick", by, id))


func drop(by: int, where: Vector3, turn: float) -> void:
	parts.ask(Command.new(&"drop", by, id, {"at": where, "yaw": turn}))


## A Guest picks with no args, and drops at a place with a turn. The place is checked in decide():
## within `reach` of where the Host knows the player to stand.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		&"pick": {"args": {}},
		&"drop": {"args": {"at": TYPE_VECTOR3, "yaw": {"type": TYPE_FLOAT, "min": -TAU, "max": TAU}}},
	}


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		&"pick":
			if holder != 0:
				return refuse("gone")
			if not parts.near(cmd.by, get_parent(), reach):
				return refuse("far")
			if parts.find(func(p: Part) -> bool: return p is Carriable and (p as Carriable).holder == cmd.by) != null:
				return refuse("full")
			var thing := get_parent() as Node3D
			if not at.is_finite() and thing != null:
				return grant({"holder": cmd.by, "at": thing.position, "yaw": thing.rotation.y})
			return grant({"holder": cmd.by})
		&"drop":
			var where: Variant = cmd.args.get("at")
			var turn: Variant = cmd.args.get("yaw", 0.0)
			if holder != cmd.by or not (where is Vector3) or not (turn is float or turn is int):
				return refuse("wrong")
			# A Guest may put it down only near where it stands, not anywhere in the level.
			if not parts.near_point(cmd.by, _to_level(where), reach):
				return refuse("far")
			return grant({"holder": 0, "at": where, "yaw": float(turn)})
	return refuse("wrong")


## `at` is in the thing's parent's space; a player's place (Parts.where) is in the level's.
func _to_level(spot: Vector3) -> Vector3:
	var thing := get_parent() as Node3D
	var base := thing.get_parent() as Node3D if thing != null else null
	return base.global_transform * spot if base != null and base.is_inside_tree() else spot


## A player who leaves holding it lets it go where it last lay (a pick of an editor-placed thing
## writes that place into `at`).
func left(by: int) -> Dictionary:
	return grant({"holder": 0}) if holder == by else {}


## The Host, after a load: nobody holds it (nothing is held offline); it lies where it was.
func loaded(_host: String) -> Dictionary:
	return grant({"holder": 0}) if holder != 0 else {}


## The holder owns the thing's motion (the Host while it lies); placed where it lies. While held it
## stays where the holder's hands put it.
func _show(_now: bool) -> void:
	var thing := get_parent() as Node3D
	if thing == null:
		return
	var mover := holder if holder != 0 else Parts.HOST
	if thing.get_multiplayer_authority() != mover:
		thing.set_multiplayer_authority(mover)
	if holder == 0 and at.is_finite():
		thing.position = at
		thing.rotation.y = yaw
