## The Host's laying of a Stage's Socks (docs/architecture/stages.md "A Stage's Socks", core/77): the
## Designs in `Stages.due` are shared out over the open floors in even shares (Q2617: with n floors open
## each lays 1/n, the newest the remainder, dealt in the Designs' order; Stage 1's all to the basement's),
## each floor's generators lay their share from the seed `hash([the World's seed, stage, floor, generator])`
## a slice per frame (SockLayingJob, the same Socks however it is sliced), and the laid records are given
## to the Stages' `land`: they join the Mess lying on every machine, or are held while a New Game waits for
## the First wash. With 2 or more players present `high_share` of them go to tops at least `high_spot`
## over the floor (Q664). A Design a place was not found for is not laid again (logged).
##
## A New Game of a level with a loading screen lays Stage 1's behind it: the spawner is the Mess's `layer`
## (is_busy(), step(), progress()) until they have landed; every other laying runs in `_process`.
class_name StageSpawner
extends Node

## The laying's slice per frame: the loading screen's (placeholder: its slice).
const SLICE_MS := 14.0 # placeholder: LoadingTuning.slice_ms

## The run's Stages (the sibling Stages by default).
@export var stages: Stages
## How many players are present at a spawn: `() -> int`. Unset: the level's Roster (1 with none).
var present: Callable

var _jobs: Array[SockLayingJob] = []
## The Designs each job lays, the Designs asked of the whole laying and the stage it lays.
var _given: Array[PackedInt32Array] = []
var _asked := PackedInt32Array()
var _stage := 0
var _planned := 0
var _made: Array[Dictionary] = []
var _before: Array[Array] = []
var _asked_socks := 0
var _clock := SliceClock.new()
var _mess: Mess
## Registered as the Mess's layer (a New Game behind the loading screen).
var _layered := false


func _enter_tree() -> void:
	if SockGenerator.start_all:
		set_process(false)
		return
	if stages == null:
		stages = get_node_or_null(^"../Stages") as Stages
	var runtime := LevelRuntime.of(self)
	if stages != null and stages.plan != null and stages.plan.size() > 0 and runtime != null and runtime.load_screen \
			and runtime.world != null and runtime.world.is_new and runtime.mess != null:
		runtime.mess.layer = self
		_layered = true


func _exit_tree() -> void:
	var runtime := LevelRuntime.of(self)
	if _layered and runtime != null and runtime.mess != null and runtime.mess.layer == self:
		runtime.mess.layer = null


## Whether there is still laying to wait for (the Mess's layer): the run has not started or Designs are due.
func is_busy() -> bool:
	return stages != null and not SockGenerator.start_all and (stages.stage < 0 or _working() or not stages.due.is_empty())


## One slice of the laying until `until` (Time.get_ticks_usec(); below 0: no limit). Returns whether none is left.
func step(until: int) -> bool:
	_work(until)
	return not is_busy()


## The loading bar's fill (0..1) of the laying in hand.
func progress() -> float:
	if _jobs.is_empty():
		return 0.0
	if _planned < _jobs.size():
		return 0.0
	var tried := 0
	for job in _jobs:
		tried += job.tried()
	return 0.1 + 0.9 * float(tried) / float(maxi(1, _asked_socks))


func _process(_delta: float) -> void:
	if SockGenerator.start_all or stages == null or stages.stage < 0 or (not _working() and stages.due.is_empty()):
		return
	if _layered and _mess_of() != null and _mess_of().layer == self:
		return
	_work(Time.get_ticks_usec() + int(SLICE_MS * 1000.0))


func _working() -> bool:
	return not _jobs.is_empty()


func _is_host() -> bool:
	return stages != null and stages.parts != null and stages.parts.is_host()


func _mess_of() -> Mess:
	if _mess == null and stages != null:
		_mess = stages.mess()
	return _mess


## Lays what is due until `until`, then lands it. Only the Host lays; a Guest gets the Socks from its answer.
func _work(until: int) -> void:
	if not _is_host() or stages.stage < 0:
		return
	if _jobs.is_empty():
		if stages.due.is_empty() or not _begin():
			return
	var clock: SliceClock = null
	if until >= 0:
		_clock.start(until)
		clock = _clock
	while _planned < _jobs.size():
		if not _jobs[_planned].plan(clock):
			return
		_planned += 1
	var m := _mess_of()
	while _made.size() < _jobs.size():
		var job := _jobs[_made.size()]
		if not job.lay(_before, clock) or not job.records(m.catalogue, clock) or not SliceClock.fits(clock, &"boxes", true):
			return
		_made.append(job.made)
		_before.append_array(_boxes(job.made))
	_land()


## Gets ready to lay `Stages.due`: the jobs, floor by floor. Returns false when there is nothing to lay with
## (no Mess, no generator): what is due is dropped so it is not waited for.
@warning_ignore("integer_division")
func _begin() -> bool:
	var m := _mess_of()
	var gens := _generators()
	_stage = stages.stage
	_asked = stages.due.duplicate()
	if m == null or m.catalogue == null or gens.is_empty():
		Log.warn("stages", "Stage %d: no Mess or Sock generator to lay %d Pairs with" % [_stage + 1, _asked.size()])
		_ask_land(PackedInt32Array(), PackedFloat32Array())
		return false
	var by_floor := _open_floors(gens)
	var floors: Array = by_floor.keys()
	var n := floors.size()
	var base := _asked.size() / n
	var shares: Array[PackedInt32Array] = []
	for k in n:
		shares.append(PackedInt32Array())
	for i in _asked.size():
		shares[i % n if i < base * n else n - 1].append(_asked[i])
	var crowd := _players() >= 2
	var plan := stages.plan
	var world_seed := _world_seed()
	_jobs.clear()
	_given.clear()
	_made.clear()
	_planned = 0
	_asked_socks = 0
	for k in n:
		var floor_gens: Array = by_floor[floors[k]]
		var parts: Array[PackedInt32Array] = []
		for g in floor_gens.size():
			parts.append(PackedInt32Array())
		for i in shares[k].size():
			parts[i % floor_gens.size()].append(shares[k][i])
		for g in floor_gens.size():
			if parts[g].is_empty():
				continue
			var high := roundi(parts[g].size() * plan.high_share) if crowd else 0
			var job := SockLayingJob.new(floor_gens[g] as SockGenerator, hash([world_seed, _stage, int(floors[k]), g]),
					parts[g], high, plan.high_spot)
			_jobs.append(job)
			_given.append(parts[g])
			_asked_socks += job.asked()
	_before = m.lying_boxes()
	return true


## The level's generators, in tree order.
func _generators() -> Array[SockGenerator]:
	var out: Array[SockGenerator] = []
	var root := stages.level()
	for node in get_tree().get_nodes_in_group(SockGenerator.GROUP):
		if root == null or root.is_ancestor_of(node):
			out.append(node as SockGenerator)
	out.sort_custom(func(a: SockGenerator, b: SockGenerator) -> bool: return b.is_greater_than(a))
	return out


## The open floors that have a generator, oldest first, each with its generators ({floor: [generators]}).
## A generator with no `floor` takes its place among the level's (the first is the basement's).
func _open_floors(gens: Array[SockGenerator]) -> Dictionary:
	var floor_of := {}
	for i in gens.size():
		floor_of[gens[i]] = gens[i].floor if gens[i].floor >= 0 else i
	var out := {}
	for i in range(0, stages.stage + 1):
		var f := stages.plan.stage(i).floor
		if out.has(f):
			continue
		var here: Array = []
		for g in gens:
			if floor_of[g] == f:
				here.append(g)
		if not here.is_empty():
			out[f] = here
	if out.is_empty():
		out[stages.plan.stage(stages.stage).floor] = gens.duplicate()
	return out


func _players() -> int:
	if present.is_valid():
		return int(present.call())
	var runtime := LevelRuntime.of(self)
	var roster := runtime.roster if runtime != null else null
	if roster == null:
		return 1
	var n := 0
	for p: Variant in roster.players.values():
		if p is Dictionary and int((p as Dictionary).get("peer", 0)) != 0:
			n += 1
	return maxi(n, 1)


func _world_seed() -> int:
	var runtime := LevelRuntime.of(self)
	return runtime.world.record.seed if runtime != null and runtime.world != null else 0


## Every job's records made: land them.
@warning_ignore("integer_division")
func _land() -> void:
	var designs := PackedInt32Array()
	var poses := PackedFloat32Array()
	for made in _made:
		designs.append_array(made["designs"] as PackedInt32Array)
		poses.append_array(made["poses"] as PackedFloat32Array)
	if designs.size() < _asked.size() * 2:
		Log.warn("stages", "Stage %d: %d of %d Pairs found a place" % [_stage + 1, designs.size() / 2, _asked.size()])
	_jobs.clear()
	_given.clear()
	_made.clear()
	_ask_land(designs, poses)


func _ask_land(designs: PackedInt32Array, poses: PackedFloat32Array) -> void:
	stages.parts.ask(Command.new(&"land", Parts.HOST, stages.id,
			{"designs": designs, "poses": poses, "asked": _asked, "stage": _stage}))


## The lying boxes of a job's records, as Mess.lying_boxes() makes them.
func _boxes(made: Dictionary) -> Array[Array]:
	var m := _mess_of()
	var out: Array[Array] = []
	var designs: PackedInt32Array = made["designs"]
	var poses: PackedFloat32Array = made["poses"]
	for i in designs.size():
		var size := SockDress.box(m.catalogue.design(designs[i]) if m.catalogue != null else null)
		out.append([size, Mess.unpack(poses, i) * Transform3D(Basis.IDENTITY, Vector3(0.0, size.y * 0.5, 0.0))])
	return out
