## The heap station's spout (core/20, H01-H03, H07): it pours batches of real Mess Socks onto the
## pad. A button's Command ("more", "respill") is answered here: the answer only counts the batches
## asked and the respills, on every machine. The Host alone then pours: each physics tick a wave of
## at most HeapTuning.per_tick Socks, while the general share of the moving budget has room, each at
## a free place of the spout's column with a random turn and a small sideways push, as one `add`
## Command of the Mess (the old game's SockPour). A respill first asks the Mess to `take_out` the
## heap's Socks (every record from `first` on that lies or falls). Nothing of a pour is saved.
class_name HeapSpout
extends Part

## What the physics query of a free place sees: the house, falling and lying Socks.
const ROOM_MASK := Mess.LAYER_HOUSE | Mess.LAYER_FLIGHT | Mess.LAYER_LYING

## The Mess the Socks join (the zoo's one in the zoo, the station's own alone).
@export var mess: Mess
@export var tuning: HeapTuning = preload("res://game/zoo/heap/heap_tuning.tres")

@export_group("State")
## How many batches the buttons asked for, and how many respills: counted up by the Host's answers.
@export var asked := 0
@export var respills := 0
## The first Mess record the spout poured (the heap's Socks are every record from here on), or -1.
@export var first := -1
@export_group("")

## The Host: the Designs still to pour (popped from the back), and the next Design of the walk.
var _queue := PackedInt32Array()
var _next_design := 0
## The counts this machine has acted on, and whether a respill waits for the next tick.
var _seen_asked := 0
var _seen_respills := 0
var _respill := false
## How long no Sock found a place while the budget had room.
var _stuck := 0.0
var _rng := RandomNumberGenerator.new()
var _box := BoxShape3D.new()


func _ready() -> void:
	_rng.seed = 2034


## A Guest may press each button at most twice a second; neither verb takes args.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {&"more": {"args": {}, "rate": 2}, &"respill": {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if mess == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), tuning.reach):
		return refuse("far")
	var start := first if first >= 0 else mess.count()
	match cmd.kind:
		&"more":
			return grant({"asked": asked + 1, "first": start})
		&"respill":
			return grant({"respills": respills + 1, "first": start})
	return refuse("wrong")


## How many Socks the Host still has to pour.
func pending() -> int:
	return _queue.size()


## On the Host a new count queues its batch (a respill also clears the heap first, next tick);
## arriving whole (bind, a late Guest) it is only noted.
func _show(now: bool) -> void:
	if now or parts == null or not parts.is_host():
		_seen_asked = asked
		_seen_respills = respills
		return
	if respills > _seen_respills:
		_seen_respills = respills
		_queue = PackedInt32Array()
		_respill = true
		_queue_batch()
	while _seen_asked < asked:
		_seen_asked += 1
		_queue_batch()


## Both Socks of each next Design of the catalogue (it walks the catalogue a Design at a time and
## starts again at its end: Designs repeat in the zoo, Q2290), the batch's worth.
func _queue_batch() -> void:
	var cat := mess.catalogue if mess != null else null
	if cat == null or cat.size() == 0:
		return
	var batch := PackedInt32Array()
	while batch.size() < tuning.batch:
		var design := cat.design(_next_design % cat.size())
		_next_design += 1
		if design == null:
			continue
		batch.append(design.id)
		batch.append(design.id)
	batch.reverse()
	batch.append_array(_queue)
	_queue = batch


func _physics_process(delta: float) -> void:
	if parts == null or mess == null or not parts.is_host():
		return
	if _respill:
		_respill = false
		_take_out()
	if _queue.is_empty():
		_stuck = 0.0
		return
	var t := mess.bodies_tuning()
	var room := mini(tuning.per_tick, t.moving_budget - t.throw_reserve - mess.moving_count())
	if room <= 0:
		return
	var designs := PackedInt32Array()
	var poses := PackedFloat32Array()
	var vels := PackedVector3Array()
	var spins := PackedVector3Array()
	var tries := room * tuning.tries
	var column := (get_parent() as Node3D).global_transform
	while designs.size() < room and tries > 0 and not _queue.is_empty():
		tries -= 1
		var id := _queue[_queue.size() - 1]
		var size := SockDress.box(mess.catalogue.design(id))
		var a := tuning.area
		var centre := column * (a.position + Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * a.size)
		var turn := Basis.from_euler(Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU))
		_box.size = size
		if not PhysicsQueries.overlap_rids(self, _box, Transform3D(turn, centre), ROOM_MASK, 1).is_empty():
			continue
		_queue.resize(_queue.size() - 1)
		designs.append(id)
		# A record's pose is its box's bottom middle.
		poses.append_array(Mess.pack(Transform3D(turn, centre - turn * Vector3(0.0, size.y * 0.5, 0.0))))
		vels.append(Vector3(_rng.randf_range(-tuning.push, tuning.push), 0.0, _rng.randf_range(-tuning.push, tuning.push)))
		spins.append(Vector3.ZERO)
	if designs.is_empty():
		_stuck += delta
		if _stuck > tuning.give_up:
			print("heap: no room for %d more Socks, given up" % _queue.size())
			_queue = PackedInt32Array()
		return
	_stuck = 0.0
	parts.ask(Command.new(&"add", Parts.HOST, mess.id, {"designs": designs, "poses": poses, "vels": vels, "spins": spins}))


## The heap's Socks (every record from `first` on) leave the Mess.
func _take_out() -> void:
	if first < 0 or first >= mess.count():
		return
	var socks := PackedInt32Array(range(first, mess.count()))
	parts.ask(Command.new(&"take_out", Parts.HOST, mess.id, {"socks": socks}))
