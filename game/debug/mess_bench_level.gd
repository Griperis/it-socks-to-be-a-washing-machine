## The Mess benchmark's level (core/31, B1; mess_bench_level.tscn): a floor, a low-walled pen under
## the heap station's own spout, a Door, a drawer and one real Mess with its Parts. The runner makes
## a fresh one per scenario: prepare() writes the Socks that lie there before it starts (stacked by
## rule, no physics), act() does the scenario's act through the game's own seams (the spout's
## `more`, a throw's change, the Openables' use), and acting() says while it still runs.
class_name MessBenchLevel
extends Node3D

## The player the acts are done as (the Host, alone).
const BY := Parts.HOST

@export var mess: Mess
@export var parts: Parts
@export var spout: HeapSpout
@export var door: Openable
@export var drawer: Openable
## Where the idle scenarios' field of Socks lies, where a heap is stacked (under the spout), and
## where a burst's Throws leave from.
@export var field: Marker3D
@export var heap: Marker3D
@export var thrower: Marker3D

@export_group("Stacks")
## A stacked Sock's room on the floor (the largest Size's box and a gap) and a layer's height.
@export var pitch := Vector2(0.4, 0.25)
@export var layer := 0.036
## How many layers the idle field and a heap have.
@export_range(1, 32, 1) var field_layers := 3
@export_range(1, 32, 1) var heap_layers := 8

@export_group("Burst")
## How fast a burst's Socks are thrown, and how far apart they leave.
@export_range(0.5, 30.0, 0.5, "suffix:m/s") var throw_speed := 7.0
@export_range(0.2, 2.0, 0.05, "suffix:m") var throw_gap := 0.45
@export_group("")

var _rng := RandomNumberGenerator.new()
var _held := PackedInt32Array()
## A sweep's steps left: open both, then shut both.
var _sweeps := 0


## Before the level enters the tree: the Socks of scenario `s` that lie (or are held, to be thrown)
## from the start become the Mess's records, the same every run with the same `dice`.
func prepare(s: MessBenchScenario, dice: int) -> void:
	_rng.seed = dice
	match s.kind:
		MessBenchScenario.Kind.IDLE:
			_stack(s.lying, field.position, field_layers, AABB())
		MessBenchScenario.Kind.POUR:
			_stack(s.lying, heap.position, heap_layers, AABB())
		MessBenchScenario.Kind.BURST:
			_stack(s.lying, heap.position, heap_layers, AABB())
			for i in s.count:
				_held.append(_add(i, Mess.State.HELD, Transform3D.IDENTITY))
		MessBenchScenario.Kind.SWEEP:
			# Round the Door, but not where its shut leaf stands; before the drawer, not in its chest.
			var half := s.lying / 2
			_stack(half, (door.get_parent() as Node3D).position, 2, AABB(Vector3(-1.0, -1.0, -0.14), Vector3(2.0, 3.0, 0.28)))
			_stack(s.lying - half, (drawer.get_parent() as Node3D).position, 2, AABB(Vector3(-5.0, -1.0, -5.0), Vector3(10.0, 3.0, 5.3)))


## Scenario `s`'s act starts now (the level is in the tree, its Parts bound).
func act(s: MessBenchScenario) -> void:
	match s.kind:
		MessBenchScenario.Kind.POUR:
			var tuning := spout.tuning.duplicate() as HeapTuning
			tuning.batch = s.count
			spout.tuning = tuning
			parts.ask(Command.new(&"more", BY, spout.id, {}))
		MessBenchScenario.Kind.BURST:
			_throw_all()
		MessBenchScenario.Kind.SWEEP:
			_sweeps = 2
			_use_openables()


## Whether the act still runs: the spout has Socks to pour, a Door or drawer moves or has yet to shut.
func acting() -> bool:
	return spout.pending() > 0 or _sweeps > 0 or door.is_moving() or drawer.is_moving()


func _physics_process(_delta: float) -> void:
	if _sweeps > 0 and not door.is_moving() and not drawer.is_moving():
		_use_openables()


func _use_openables() -> void:
	_sweeps -= 1
	if _sweeps < 0:
		return
	door.use(BY)
	drawer.use(BY)


## Every held Sock is thrown at the heap in one tick, as the Hands' throw answer writes it
## (Mess.thrown_patch): side by side from the thrower's place, each with its own small turn.
func _throw_all() -> void:
	var side := int(ceil(sqrt(float(_held.size()))))
	var target := heap.global_position + Vector3.UP * 0.2
	for i in _held.size():
		var from := thrower.global_position + Vector3((i % side - (side - 1) * 0.5) * throw_gap,
				(i / side) * throw_gap, 0.0)
		var aim := (target + Vector3(_rng.randf_range(-0.6, 0.6), 0.0, _rng.randf_range(-0.6, 0.6)) - from).normalized()
		var spin := Vector3(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-3.0, 3.0), _rng.randf_range(-3.0, 3.0))
		var pose := Transform3D(Basis.from_euler(Vector3(0.0, _rng.randf() * TAU, 0.0)), from)
		# A flat arc: aimed a little over the heap.
		var vel := (aim + Vector3.UP * 0.25).normalized() * throw_speed
		parts.apply({"ok": true, "kind": &"throw", "by": BY, "to": mess.id,
				"changes": {mess.id: mess.thrown_patch(_held[i], pose, vel, spin, BY)}})


## `n` lying Socks stacked round `centre`: a grid `pitch` apart, `layers` high, each flat, turned
## end for end at random and a hair askew; cells inside `skip` (a box round `centre`) stay empty.
func _stack(n: int, centre: Vector3, layers: int, skip: AABB) -> void:
	if n <= 0:
		return
	var per_layer := int(ceil(float(n) / layers))
	var cols := maxi(1, int(ceil(sqrt(per_layer * pitch.y / pitch.x))))
	var placed := 0
	for level in layers:
		var want := mini(per_layer, n - placed)
		var cell := 0
		var got := 0
		while got < want:
			var col := cell % cols
			var row := cell / cols
			cell += 1
			# The rows grow away from the centre on both sides in turn, so a stack stays round it.
			var z := ((row + 1) / 2) * pitch.y * (1.0 if row % 2 == 1 else -1.0)
			var at := Vector3((col - (cols - 1) * 0.5) * pitch.x, level * layer, z)
			if skip.has_volume() and skip.has_point(at):
				continue
			var turn := Basis.from_euler(Vector3(0.0, (_rng.randi() % 2) * PI + _rng.randf_range(-0.04, 0.04), 0.0))
			_add(placed, Mess.State.LYING, Transform3D(turn, centre + at))
			got += 1
			placed += 1


## One more record: both Socks of each Design of the catalogue in turn. Returns its Sock id.
func _add(i: int, state: Mess.State, pose: Transform3D) -> int:
	var catalogue := mess.catalogue
	var sock := mess.designs.size()
	mess.designs.append(catalogue.designs[(i / 2) % catalogue.designs.size()].id)
	mess.states.append(state)
	mess.mates.append(-1)
	mess.poses.append_array(Mess.pack(pose))
	return sock
