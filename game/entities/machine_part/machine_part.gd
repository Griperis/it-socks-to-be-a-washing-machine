## One of the washing machine's Parts as a thing (core/79, docs/architecture/stages.md "Machine Parts"):
## the Part a Stage earns, its kind's Looks, the glow disc, the sparkle and the pop out of a Cabinet's
## top. It keeps no state of its own: whether it lies or is carried is its Carriable's (`holder`, `at`),
## and whether it is out at all is read from the run (it is drawn only while it is the current Stage's
## Part and `Stages.phase` is PART_OUT; fitted, it is hidden). Called the MachinePart so it never reads as
## a scene `Part`.
##
## Looks only: the kind's Looks takes the place of the scene's `Looks`; `lying` (the spin and the bob, keys
## of the Looks' AnimationPlayer) plays only while it lies (carried or popping, `RESET` puts the turn and
## the bob back to 0, as the old); the glow disc and the sparkle show only while it lies; on the run's
## `stage_completed` the Looks flies from the top of the Cabinet that took the last Pair to where the
## Host put it (`pop_changes()`), `part_pop` at the top and a burst of sparks on landing, on every machine.
## A Guest who joins or a World that loads sees it lying, with no pop.
class_name MachinePart
extends Part

## Every Machine Part is in this group (the run finds the Stage's Part there).
const GROUP := &"machine_parts"
## The Looks' names (assets/12's contract: `Part`, `Model`, `Outline`, `AnimationPlayer`, `lying`).
const LOOKS := &"Looks"
const PLAYER := ^"AnimationPlayer"
const LYING := &"lying"
const RESET := &"RESET"
## How far over and under the landing spot the floor is looked for.
const FLOOR_ABOVE := 1.2
const FLOOR_BELOW := 3.0
## The sounds (sound_catalogue.tres).
const POP_SOUND := &"part_pop"
## The top of a Cabinet over its root when its Looks has no `Top`.
const TOP_HEIGHT := 1.05

## Which Part it is (set on the instance placed under the run's `MachineParts`).
@export var kind: MachinePartKind
## The Carriable beside it: it carries the Part's name on the crosshair.
@export var carriable: Carriable
@export var tuning: MachinePartTuning

## Whether it is drawn and aimable now.
var _out := false
## The kind whose Looks is on the thing.
var _dressed: MachinePartKind
## The pop: seconds so far (-1: none), and the Cabinet's top it began from.
var _pop_time := -1.0
var _pop_from := Vector3.ZERO
## The shapes it switched off while it is not out.
var _off_shapes: Array[CollisionShape3D] = []
var _stages: Stages


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	# Its sibling Looks can be swapped only once the root is ready.
	var root := get_parent()
	if root.is_node_ready():
		dress()
	elif not root.ready.is_connected(dress):
		root.ready.connect(dress, CONNECT_ONE_SHOT)
	_apply_visible()  # hidden until its Stage's Part is out
	_refresh()


func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func save_state() -> Dictionary:
	return {}


## Whether it is drawn now (the current Stage's, out of its Cabinet, not yet fitted).
func out() -> bool:
	return _out


## Whether it is flying out of the Cabinet now.
func popping() -> bool:
	return _pop_time >= 0.0


## Whether it lies (drawn, in nobody's Hands, not flying): the glow, the sparkle and `lying` show.
func lying() -> bool:
	return _out and not popping() and (carriable == null or carriable.holder == 0)


## The Looks scene on the thing now (the kind's), for the tests.
func looks() -> Node3D:
	var thing := get_parent()
	return thing.get_node_or_null(NodePath(LOOKS)) as Node3D if thing != null else null


## Puts the kind's Looks on the thing in place of the one there (same name, same place among its
## siblings). Looks only; a Looks already the kind's is kept.
func dress() -> void:
	var root := get_parent() as Node3D
	if root == null or kind == null or kind.looks == null or _dressed == kind:
		return
	var old := root.get_node_or_null(NodePath(LOOKS)) as Node3D
	var fresh := kind.looks.instantiate() as Node3D
	fresh.name = LOOKS
	if old != null:
		fresh.transform = old.transform
		var at := old.get_index()
		root.remove_child(old)
		old.queue_free()
		root.add_child(fresh)
		root.move_child(fresh, at)
	else:
		root.add_child(fresh)
	_dressed = kind
	_play_motion()
	if carriable != null:
		carriable.title = kind.name
	_apply_effects()


## The Host: where the Part lands when the Stage completes in front of Cabinet `cabinet`: `ahead` m
## out from its front on the floor (one ray), as the changes of its Carriable, laying it there. The
## Part's own space is its parent's. Empty when the Part has no Carriable.
func pop_changes(cabinet: Cabinet) -> Dictionary:
	var thing := get_parent() as Node3D
	var root := cabinet.get_parent() as Node3D if cabinet != null else null
	if carriable == null or thing == null or root == null or not root.is_inside_tree():
		return {}
	var numbers := tuning if tuning != null else MachinePartTuning.new()
	var spot := root.global_transform * Vector3(0.0, 0.0, numbers.ahead)
	var hit := PhysicsQueries.ray(root, spot + Vector3.UP * FLOOR_ABOVE, spot + Vector3.DOWN * FLOOR_BELOW, Mess.LAYER_HOUSE)
	if not hit.is_empty():
		spot = hit["position"]
	else:
		spot.y = root.global_position.y
	var base := thing.get_parent() as Node3D
	var local := base.global_transform.affine_inverse() * spot if base != null and base.is_inside_tree() else spot
	return {carriable.id: {"holder": 0, "at": local, "yaw": 0.0}}


## The point on top of Cabinet `cabinet` the Part pops out of (its Looks' `Top`, else the shell's top).
static func top_of(cabinet: Cabinet) -> Vector3:
	var root := cabinet.get_parent() as Node3D
	if root == null:
		return Vector3.ZERO
	var top := root.get_node_or_null(^"Looks/Top") as Node3D
	var height := top.global_position.y - root.global_position.y if top != null and top.is_inside_tree() else TOP_HEIGHT
	return root.global_position + Vector3(0.0, height, 0.0)


## The pose of a Part `k` (0..1) of the way from the Cabinet's top `from` to where it lies `to`: a hop
## up out of the top, an arc peaking `height` over it, a little bounce at the end (the old pop_pose).
static func pop_pose(from: Vector3, to: Vector3, k: float, height: float) -> Vector3:
	k = clampf(k, 0.0, 1.0)
	var flat := from.lerp(to, ease(k, 0.8))
	var lift := 4.0 * k * (1.0 - k) * height + (from.y - to.y) * (1.0 - k)
	return Vector3(flat.x, to.y + lift, flat.z)


## Every machine, as the run's Stage completes: the Part flies from the top of `cabinet`.
func _on_stage_completed(_stage: int, cabinet: StringName) -> void:
	_refresh()
	if not _out or _stages == null:
		return
	var cab := _stages.cabinet_of(cabinet)
	if cab == null:
		return
	_pop_from = top_of(cab)
	_pop_time = 0.0
	Sounds.play_at(POP_SOUND, _pop_from)
	_apply_effects()
	_play_motion()
	_fly()


func _process(delta: float) -> void:
	_refresh()
	if _pop_time < 0.0:
		return
	var numbers := tuning if tuning != null else MachinePartTuning.new()
	var carried := carriable != null and (carriable.holder != 0 or carriable.putting())
	_pop_time += delta
	if carried or not _out:
		_end_pop(false)
	elif _pop_time >= numbers.pop_seconds:
		_end_pop(true)
	else:
		_fly()


## The Looks drawn where the pop has got to.
func _fly() -> void:
	var thing := get_parent() as Node3D
	var skin := looks()
	if thing == null or skin == null or not thing.is_inside_tree():
		return
	var numbers := tuning if tuning != null else MachinePartTuning.new()
	var at := pop_pose(_pop_from, thing.global_position, _pop_time / maxf(numbers.pop_seconds, 0.01), numbers.arc)
	skin.global_position = at


## The pop is over (landed: the burst; picked up first: nothing).
func _end_pop(landed: bool) -> void:
	_pop_time = -1.0
	var skin := looks()
	var carried := carriable != null and (carriable.holder != 0 or carriable.putting())
	if skin != null and not carried:
		skin.transform = Transform3D.IDENTITY
	if landed:
		var burst := get_parent().get_node_or_null(^"Burst") as GPUParticles3D
		if burst != null:
			burst.restart()
			burst.emitting = true
	_apply_effects()
	_play_motion()


## Whether it is out now, from the run: drawn, aimable. Called every frame (four Parts: cheap), so a
## load, a join and an answer all show the same.
func _refresh() -> void:
	var want := false
	var stages := _find_stages()
	if stages != null and kind != null and stages.stage >= 0 and stages.phase == Stages.Phase.PART_OUT:
		var stage := stages.current()
		want = stage != null and stage.part != null and stage.part.id == kind.id
	if want != _out:
		_out = want
		_apply_visible()
	_apply_effects()
	_play_motion()


## Where in the `lying` loop this Part starts, 0..1, from its kind.
func _phase() -> float:
	return float(absi(hash(String(kind.id))) % 1000) / 1000.0 if kind != null else 0.0


func _find_stages() -> Stages:
	if _stages != null and is_instance_valid(_stages):
		return _stages
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group(Stages.GROUP):
		var s := node as Stages
		if s != null and s.parts == parts:
			_stages = s
			if not s.stage_completed.is_connected(_on_stage_completed):
				s.stage_completed.connect(_on_stage_completed)
			break
	return _stages


func _apply_visible() -> void:
	var thing := get_parent() as Node3D
	if thing == null:
		return
	thing.visible = _out
	if _out:
		for shape in _off_shapes:
			if is_instance_valid(shape):
				shape.set_deferred(&"disabled", false)
		_off_shapes.clear()
	elif _off_shapes.is_empty():
		for node in thing.find_children("*", "CollisionShape3D", true, false):
			var shape := node as CollisionShape3D
			if not shape.disabled:
				shape.set_deferred(&"disabled", true)
				_off_shapes.append(shape)


## The glow disc and the sparkle show while it lies; their colour is the tuning's.
func _apply_effects() -> void:
	var thing := get_parent()
	if thing == null:
		return
	var on := lying()
	var colour := tuning.glow_colour if tuning != null else Color(0.55, 0.85, 1.0)
	var glow := thing.get_node_or_null(^"Glow") as MeshInstance3D
	if glow != null:
		glow.visible = on
		var material := glow.material_override as StandardMaterial3D
		if material != null and not material.albedo_color.is_equal_approx(Color(colour, 0.8)):
			material.albedo_color = Color(colour, 0.8)
	var sparkle := thing.get_node_or_null(^"Sparkle") as GPUParticles3D
	if sparkle != null and sparkle.emitting != on:
		sparkle.emitting = on
	var burst := thing.get_node_or_null(^"Burst") as GPUParticles3D
	if burst != null:
		burst.amount = tuning.sparks if tuning != null else 18


## `lying` plays while it lies; otherwise `RESET` (the turn and the bob back to 0).
func _play_motion() -> void:
	var skin := looks()
	var player := skin.get_node_or_null(PLAYER) as AnimationPlayer if skin != null else null
	if player == null:
		return
	if lying():
		if player.current_animation != LYING or not player.is_playing():
			player.play(LYING)
			# The old bob ran on each Part's own phase: this one starts its loop at its own.
			player.seek(player.get_animation(LYING).length * _phase(), true)
	elif player.current_animation != RESET:
		player.play(RESET)
