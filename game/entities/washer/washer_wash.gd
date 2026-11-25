## The washing machine's knockdown wash (core/98, docs/architecture/washer.md "The knockdown wash"): who spins
## in its drum now, as one Part of the washer. A body let go within reach of the `Door` while the machine is
## free goes in (the Host's answer to the dragger's `let_go`, written by `Knockdowns`, which ends the body's
## knockdown in the same answer); it spins `wash_seconds` out of play; then the Host's `end` lays the player
## down again as they tumble out of the door, head first (`Knockdowns.tumble()`). One at a time: while it
## washes someone or a cutscene plays, a body let go at the door just lies there (Q758). A cutscene's end
## ends a wash (Cutscenes), a leaver's wash ends too; neither tumbles. Not saved (a load starts empty).
##
## Every machine counts the spin on its own clock, as `Knockdowns` counts a knockdown (`left_of()`); the
## Host asks for the end when it runs out, never while a cutscene plays. What is seen and heard (the slide,
## the door, the blob, the spinning view) is its `WashView`'s, looks only.
class_name WasherWash
extends Part

## Every washer's wash is in this group.
const GROUP := &"washer_washes"
## The Host's word that the spin ran out (Host-only).
const END := &"end"
## A body let go this far above or below the door's floor is not by it (the old by_door).
const REACH_UP := 1.0

## The washer's numbers, the `Door` marker (the middle of its front on the floor, +Z out of it) and the face
## that shows it.
@export var tuning: WasherTuning
@export var door: Marker3D
@export var view: WashView

@export_group("State")
## Who spins in the drum (their peer), 0 for nobody.
@export var peer := 0
## How long they still spin, in seconds when written (every machine counts it on its own clock).
@export var spin_left := 0.0
## Where the body lay when it was let go: where the slide in starts. And who let go of it.
@export var from := Vector3.ZERO
@export var by := 0
## Moves with every wash that starts, and `out_serial` with every one that ends by the burst (the door
## bursts and the player fades in only then).
@export var serial := 0
@export var out_serial := 0
@export_group("")

var _left := 0.0
var _seen := -1
var _asked := -1


func _enter_tree() -> void:
	add_to_group(GROUP)


## The washes of the level `node` is in (one per washing machine).
static func in_level(node: Node) -> Array[WasherWash]:
	var out: Array[WasherWash] = []
	if not node.is_inside_tree():
		return out
	var runtime := LevelRuntime.of(node)
	for n in node.get_tree().get_nodes_in_group(GROUP):
		var w := n as WasherWash
		if w != null and LevelRuntime.of(w) == runtime:
			out.append(w)
	return out


## Nothing is kept in a save: a load has nobody in the drum.
func save_state() -> Dictionary:
	return {}


## Everything is the Host's: a Guest asks nothing of it.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {}


## How long the spin still runs on this machine's clock; 0 with nobody in.
func left_of() -> float:
	return maxf(_left, 0.0) if peer != 0 else 0.0


## Whether something spins in the drum or a cutscene plays: a body let go at the door only lies there.
func busy() -> bool:
	var frame := Cutscenes.of(self)
	return peer != 0 or (frame != null and frame.is_playing())


## Whether a body let go with its feet at `feet` (world) lies by the door: on its floor, in front of the
## machine and within the tuning's reach of the door's front.
func by_door(feet: Vector3) -> bool:
	if door == null or tuning == null:
		return false
	var d := feet - door.global_position
	var front := front_of()
	if absf(d.y) > REACH_UP or d.dot(front) < -0.1:
		return false
	return Vector2(d.x, d.z).length() <= tuning.wash_reach


## The way the machine faces (the door's +Z), along the floor.
func front_of() -> Vector3:
	var z := door.global_basis.z if door != null else Vector3.BACK
	var flat := Vector3(z.x, 0.0, z.z)
	return flat.normalized() if flat.length() > 0.0001 else Vector3.BACK


## The Host, in the let go's answer: the patch that sends `target` in, or {} when the machine is busy (the body
## just lies there). Reads only.
func take_in(target: int, feet: Vector3, dragger := 0) -> Dictionary:
	if busy() or tuning == null:
		return {}
	return {"peer": target, "spin_left": tuning.wash_seconds, "from": feet, "by": dragger, "serial": serial + 1}


## The patch that ends the wash with nobody tumbling out (a cutscene's end, a leaver): the Cutscenes Part's
## answer carries it; {} when nobody spins.
func clear() -> Dictionary:
	return {} if peer == 0 else {"peer": 0, "spin_left": 0.0}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != END:
		return refuse("wrong")
	if cmd.by != Parts.HOST:
		return refuse("wrong")
	if peer == 0 or int(cmd.args.get("serial", serial)) != serial:
		return refuse("already")
	var runtime := LevelRuntime.of(self)
	var kd := runtime.knockdowns if runtime != null else null
	if kd == null or tuning == null or door == null:
		return refuse("wrong")
	# The body starts at the porthole's foot just out of the door, tipped forward out of it.
	var front := front_of()
	var at: Vector3 = door.global_position + front * tuning.out_gap + Vector3.UP * tuning.out_up
	var yaw := atan2(-front.x, -front.z)
	var ev := grant({"peer": 0, "spin_left": 0.0, "out_serial": out_serial + 1})
	ev["changes"][kd.id] = kd.tumble(peer, by, at, yaw, front, tuning.out_side, tuning.out_tilt,
			front * tuning.out_speed + Vector3.UP * tuning.out_lift, tuning.wash_out_seconds)
	ev["washed"] = peer
	return ev


## A leaver's wash ends, with no tumble.
func left(by: int) -> Dictionary:
	if peer == 0 or by != peer:
		return {}
	return grant({"peer": 0, "spin_left": 0.0})


## A late joiner's copy carries what is left of the spin.
func whole_state() -> Dictionary:
	var d := state()
	d["spin_left"] = left_of()
	return d


func _show(now: bool) -> void:
	if serial != _seen:
		_seen = serial
		_left = spin_left if peer != 0 else 0.0
	elif now and peer != 0:
		_left = spin_left
	if view != null:
		view.follow(self, now)


func _physics_process(delta: float) -> void:
	if peer == 0:
		return
	_left -= delta
	# The Host brings the player out when the spin has run out; a cutscene's end ends the wash instead.
	if _left <= 0.0 and _asked != serial and parts != null and parts.is_host():
		var frame := Cutscenes.of(self)
		if frame != null and frame.is_playing():
			return
		_asked = serial
		parts.ask(Command.new(END, Parts.HOST, id, {"serial": serial}))
