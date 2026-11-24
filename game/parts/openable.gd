## The ability to be opened and shut (a door, a drawer, a lid). Put it on the thing's scene as a
## child of the root, beside the thing's Looks: a child scene named "Looks" whose AnimationPlayer
## has an animation "open" (shut at its start, open at its end). The state is the truth; the
## animation only shows it, so any Looks with that animation can replace another. A Looks may also
## have "shut" (open to shut, its own easing): it is played to shut instead of "open" backwards.
class_name Openable
extends Part

## The animation every Looks of an openable thing has.
const ANIMATION := &"open"
## An animation a Looks may also have: open at its start, shut at its end, played to shut instead of
## "open" backwards (its own easing, core/09 D12).
const SHUT := &"shut"
## How finely "shut" is searched for the pose "open" has now, when a swing turns back.
const MATCH_STEPS := 60
## Where the Looks sits, from this part.
const LOOKS := ^"../Looks"
## Every Openable is in this group: the Mess sweeps the Socks in the way of the moving ones (core/13, M09).
const GROUP := &"openables"

## How far from the thing a player may stand to use it, in metres (Parts.near(); checked only once
## the game sets Parts.where).
@export var reach := 4.0
## The sound events it plays from where it stands when it opens or shuts by use ("door_open",
## "door_close"); empty is silent. A state arriving whole (a load, a late Guest) makes no sound.
@export var open_sound: StringName = &""
@export var close_sound: StringName = &""
## How far over the thing's place the sounds come from, in metres (a room Door sounds 1 m up, where its leaf is
## held, as the old game's did; 0, the thing's own place, for the rest).
@export_range(0.0, 3.0, 0.05, "suffix:m") var sound_height := 0.0
## What the player's prompt calls it while it is shut or open: "Open the <noun>", "Shut the <noun>"
## (the old room Door, core/15 A03). Empty, the prompt is its title.
@export var noun := ""
## Its own name on the prompt ("Cupboard A Drawer", Q2388); empty, the name of the thing it is on.
@export var title := ""

@export_group("State")
## Open or shut. Tick it to place the thing open; while playing only the Host's answer changes it.
@export var open := false
## A locked one refuses to open.
@export var locked := false
@export_group("")

var _looks: Node
var _animator: AnimationPlayer
## Whether the state was open when it was last shown: a sound plays only when it turns over.
var _was_open := false


func _enter_tree() -> void:
	add_to_group(GROUP)


## Whether it is swinging or sliding now (its animation plays).
func is_moving() -> bool:
	var player := animator()
	return player != null and player.is_playing()


## The bodies of its Looks that move as it opens (a door's leaf, a drawer's slide): what pushes the
## Socks in their way.
func movers() -> Array[AnimatableBody3D]:
	var out: Array[AnimatableBody3D] = []
	var looks := get_node_or_null(LOOKS)
	if looks != null:
		for node in looks.find_children("*", "AnimatableBody3D", true, false):
			out.append(node as AnimatableBody3D)
	return out


## The player's use button: ask to turn it the other way. The Command carries the wanted value, so
## of two players pressing at once the second is refused "already" instead of undoing the first.
func use(by: int) -> void:
	parts.ask(Command.new(&"open", by, id, {"open": not open}))


## The Host, after a load (Q2559): it starts shut, so what rode out in an open drawer slides back with
## it as on any shut. A locked one stays locked.
func loaded(_host: String) -> Dictionary:
	return grant({"open": false}) if open else {}


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
	# A patch that leaves `open` as it was (a lock, say) replays no swing and no sound.
	if not now and open == _was_open:
		return
	if not now:
		_make_sound()
	_was_open = open
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
	if player.has_animation(SHUT):
		_swing(player)
		return
	# Mid-swing the pose is where the animation is; at rest it is the other end (the state before).
	var from := player.current_animation_position if player.is_playing() and player.current_animation == ANIMATION \
			else length - end
	player.play(ANIMATION, 0.0, 1.0 if open else -1.0, not open)
	player.seek(from, true)


## The sound of turning over, from the thing's place.
func _make_sound() -> void:
	var event := open_sound if open else close_sound
	var spot := get_parent() as Node3D
	if event != &"" and spot != null and spot.is_inside_tree():
		Sounds.play_at(event, spot.global_position + Vector3.UP * sound_height)


## With a Looks that has its own "shut" (a drawer easing out both ways, core/09 D12): plays "open"
## or "shut" forwards, from the time in it whose pose matches the pose now, so a reverse mid-swing
## stays smooth.
func _swing(player: AnimationPlayer) -> void:
	var to := ANIMATION if open else SHUT
	var other := SHUT if open else ANIMATION
	var from := 0.0
	if player.is_playing() and player.current_animation == other:
		from = _matching(player.get_animation(other), player.current_animation_position, player.get_animation(to))
	elif player.is_playing() and player.current_animation == to:
		from = player.current_animation_position
	player.play(to)
	player.seek(from, true)


## The time in `to` whose first track has the value `from`'s first track has at time `t`; without a
## value track to compare, the same share of its length.
static func _matching(from: Animation, t: float, to: Animation) -> float:
	var share := t / maxf(from.length, 0.0001)
	if from.get_track_count() == 0 or to.get_track_count() == 0 or from.track_get_type(0) != Animation.TYPE_VALUE \
			or to.track_get_type(0) != Animation.TYPE_VALUE:
		return to.length * (1.0 - share)
	var want: Variant = from.value_track_interpolate(0, t)
	var best := to.length * (1.0 - share)
	var best_gap := INF
	for i in MATCH_STEPS + 1:
		var at := to.length * float(i) / float(MATCH_STEPS)
		var have: Variant = to.value_track_interpolate(0, at)
		var gap := INF
		if want is Vector3 and have is Vector3:
			gap = (want as Vector3).distance_to(have as Vector3)
		elif (want is float or want is int) and (have is float or have is int):
			gap = absf(float(want) - float(have))
		if gap < best_gap:
			best_gap = gap
			best = at
	return best


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
