## A Pair's sock ball landing (core/16 P04, the old sock_ball.gd:263-345): when its falling body
## touches down, the drawn ball squashes about its bottom along world up, hops while the body rolls
## on beneath it, and squashes again as it comes down. Looks only: the body (the Host's flight, or a
## Guest's copy) moves as physics moves it; this changes only how its Looks' Body is drawn.
## The motion plays in an AnimationPlayer (the project's rule), its keys made from the tuning, on
## this node's `squash` and `hop`; each physics tick they are put on the Body.
class_name BallLanding
extends Node

## The animation the landing plays.
const LAND := &"land"
## How many keys a sine of the squash or the hop is drawn with.
const KEYS := 9

## The numbers (ball_landing_tuning.tres).
@export var tuning: BallLandingTuning
## The ball's radius at its Size, in m: the squash is about its bottom.
@export var radius := 0.042
## How squashed it is now (0 round, `tuning.squash` the deepest), and how high it hops now, in m at
## Size medium. The AnimationPlayer writes them.
@export var squash := 0.0:
	set(value):
		squash = value
		_apply()
@export var hop := 0.0:
	set(value):
		hop = value
		_apply()

## How many times it has touched down and played (one landing a flight; tests read it).
var landings := 0
## The deepest squash and the highest hop drawn so far (tests and shots read them).
var deepest := 0.0
var highest := 0.0

## The Body's own transform, round and at rest (what the squash and hop are put on).
var rest := Transform3D.IDENTITY

## The landing Animation of each set of tuning numbers, made once ({numbers: Animation}).
static var _made: Dictionary[String, Animation] = {}

var _player: AnimationPlayer
var _last_vy := 0.0
var _body: Node3D


func _ready() -> void:
	if tuning == null:
		tuning = BallLandingTuning.new()
	_body = get_parent().get_node_or_null(^"Body") as Node3D
	if _body != null:
		rest = _body.transform
	_player = AnimationPlayer.new()
	_player.name = "Landing"
	add_child(_player)
	_player.root_node = ^".."
	var library := AnimationLibrary.new()
	library.add_animation(LAND, landing_of(tuning))
	_player.add_animation_library(&"", library)
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	var body := _falling()
	_last_vy = _vy(body) if body != null else 0.0
	# With no falling body (a Cabinet flier moved by a tween) there is nothing to watch.
	set_physics_process(body != null)


## The landing Animation of `t`, made once per set of numbers.
static func landing_of(t: BallLandingTuning) -> Animation:
	var key := "%s|%s|%s|%s" % [t.bounce_time, t.squash_time, t.squash, t.bounce_height]
	if not _made.has(key):
		_made[key] = landing(t)
	return _made[key]


## The landing's animation from `t`: the first squash and the hop from its start, the second squash
## as the hop comes down; on `squash` and `hop` of the node it plays on.
static func landing(t: BallLandingTuning) -> Animation:
	var anim := Animation.new()
	anim.length = t.bounce_time + t.squash_time
	var squashes := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(squashes, NodePath(".:squash"))
	var hops := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(hops, NodePath(".:hop"))
	for start: float in [0.0, t.bounce_time]:
		for i in KEYS:
			var u := float(i) / float(KEYS - 1)
			anim.track_insert_key(squashes, start + u * t.squash_time, t.squash * sin(u * PI))
	for i in KEYS:
		var u := float(i) / float(KEYS - 1)
		anim.track_insert_key(hops, u * t.bounce_time, 4.0 * t.bounce_height * u * (1.0 - u))
	return anim


## Whether the landing is playing now.
func playing() -> bool:
	return _player != null and _player.is_playing()


## Plays the landing now (a touchdown does it on its own).
func land() -> void:
	landings += 1
	_player.stop()
	_player.play(LAND)
	# One landing a flight: nothing more to watch for in the physics step.
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	var body := _falling()
	if body != null:
		var vy := _vy(body)
		if landings == 0 and _last_vy <= -tuning.touch_speed and vy - _last_vy >= tuning.touch_change:
			land()
		_last_vy = vy


## How fast `body` falls: its own velocity, or on a Guest the Host's body's as its stamped copy plays
## it (the copy is frozen, its own velocity zero: coop/14).
static func _vy(body: RigidBody3D) -> float:
	var row := FlightRow.of(body)
	if row != null and not row.host_side:
		return row.velocity.y
	return body.linear_velocity.y


## The falling body its Looks rides on, or null (held, lying, in a drawer).
func _falling() -> RigidBody3D:
	var looks := get_parent()
	return looks.get_parent() as RigidBody3D if looks != null else null


## Puts `squash` and `hop` on the Looks' Body: squashed about the ball's bottom along world up,
## lifted by the hop, whatever way the rolling ball is turned (the old _apply_squash()).
func _apply() -> void:
	var looks := get_parent() as Node3D
	if _body == null or looks == null or not looks.is_inside_tree():
		return
	deepest = maxf(deepest, squash)
	highest = maxf(highest, hop)
	if is_zero_approx(squash) and is_zero_approx(hop):
		_body.transform = rest
		return
	# In the Looks' own space, from its turn and scale only (not where it is), so the body moving
	# on in the physics step after this does not shift the squash's bottom.
	var turn := looks.global_transform.basis
	var size := turn.get_scale().x
	var back := turn.inverse()
	var press := Basis.from_scale(Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5))
	var local := back * press * turn
	var bottom := back * (Vector3.DOWN * radius)
	_body.transform = Transform3D(local, bottom - local * bottom + back * (Vector3.UP * hop * size)) * rest
