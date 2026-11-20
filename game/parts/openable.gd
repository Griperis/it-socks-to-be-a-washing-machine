## The ability to be opened and shut (a door, a drawer, a lid). Put it on the thing's scene as a
## child of the root, beside the thing's Looks: a child scene named "Looks" whose AnimationPlayer
## has an animation "open" (shut at its start, open at its end). The state is the truth; the
## animation only shows it, so any Looks with that animation can replace another.
class_name Openable
extends Part

## The animation every Looks of an openable thing has.
const ANIMATION := &"open"
## Where the Looks sits, from this part.
const LOOKS := ^"../Looks"

## How far from the thing a player may stand to use it, in metres (Parts.near(); checked only once
## the game sets Parts.where).
@export var reach := 4.0

@export_group("State")
## Open or shut. Tick it to place the thing open; while playing only the Host's answer changes it.
@export var open := false
## A locked one refuses to open.
@export var locked := false
@export_group("")

var _looks: Node
var _animator: AnimationPlayer


## The player's use button: ask to turn it the other way. The Command carries the wanted value, so
## of two players pressing at once the second is refused "already" instead of undoing the first.
func use(by: int) -> void:
	parts.ask(Command.new(&"open", by, id, {"open": not open}))


## A Guest sends the wanted value, at most 5 presses a second.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {&"open": {"args": {"open": TYPE_BOOL}, "rate": 5}}


func decide(cmd: Command) -> Dictionary:
	var to: Variant = cmd.args.get("open")
	if cmd.kind != &"open" or not (to is bool):
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	if locked:
		return refuse("locked")
	if to == open:
		return refuse("already")
	return grant({"open": to})


## Plays "open" forwards or backwards from wherever the pose is now, so a toggle mid-swing turns
## back smoothly; `now` jumps to the end pose with no animation.
func _show(now: bool) -> void:
	var player := animator()
	if player == null:
		return
	var length := player.get_animation(ANIMATION).length
	var end := length if open else 0.0
	if now:
		player.play(ANIMATION)
		player.seek(end, true)
		player.pause()
		return
	# Mid-swing the pose is where the animation is; at rest it is the other end (the state before).
	var from := player.current_animation_position if player.is_playing() and player.current_animation == ANIMATION \
			else length - end
	player.play(ANIMATION, 0.0, 1.0 if open else -1.0, not open)
	player.seek(from, true)


## The Looks' AnimationPlayer that has "open", or null (no Looks yet: state only). Searched once
## and remembered while it is still inside the same Looks; a swapped Looks is searched again.
func animator() -> AnimationPlayer:
	var looks := get_node_or_null(LOOKS)
	if looks == null:
		return null
	if looks == _looks and is_instance_valid(_animator) and looks.is_ancestor_of(_animator):
		return _animator
	_looks = looks
	_animator = null
	for node in looks.find_children("*", "AnimationPlayer", true, false):
		var player := node as AnimationPlayer
		if player.has_animation(ANIMATION):
			_animator = player
			break
	return _animator
