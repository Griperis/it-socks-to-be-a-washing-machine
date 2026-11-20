## Every loose Sock of the level as one Part (coop-structure section 5): one record a Sock, by id,
## in packed arrays (its Design, its state, its pose). A Sock is LYING (drawn and aimable), HELD (in
## somebody's Hands: the Hands Part says whose) or FLYING (a falling body the Host owns, after a
## drop, a Throw or a wake). The Hands change it with their own answers (a pick, a drop, a throw);
## the Host alone writes a Sock lying again when its body comes to rest or leaves the level's
## bounds (`rest`), and wakes lying Socks a fast body hits (`wake`), both Host-only Commands.
##
## A Pair (core/03) is two Sock records: its lead (the Sock held first) is where the Pair is, LYING,
## HELD or FLYING like any Sock, drawn as one sock ball; the other is IN_PAIR, never drawn, aimed or
## simulated on its own. `mates` names each one's mate. So every Design keeps exactly two records
## (I.1). Pairs form only in the Hands' pick answer (paired_patch()) and are never split. When a
## pick takes a lying Sock or Pair away, the Host lets the lying Socks and Pairs that rested on it
## fall (P08, M07: `fall`, a Host-only Command); a moving Door or drawer wakes the Socks in its way
## (M09: `wake`, like a hit).
##
## A shelved Pair (core/04) has its lead SHELVED (its mate stays IN_PAIR): in a Cabinet's drawer,
## drawn by the drawer, never by the Mess, and never taken out again. Only a Cabinet's answer
## writes it (shelved_patch()). A thrown body's touches are told to whoever listens
## (`flight_touched`, the Host's): a Cabinet shelves a Pair that touched it.
##
## Two tiers (core/13, Q2305): a lying Sock is a static body made in the physics server plus an
## instance of a floor cell's MultiMesh, with no node (MessBodies, MessDrawing); only where it matters
## is it a full Looks scene: lent to the aimed Sock (looks_of), the Hands' own (HeldView) and the
## flying Socks nearest the camera (core/09's flying_cap, for their cloth). A moving Sock is a body
## counted against the moving budget (MessTuning): woken Socks wait their turn, nearest the players
## first; drops and Throws never wait.
##
## Records come and go during play only through the Host's own Commands (core/20): `add` appends
## falling Socks (a spout's pour, launched at once with their own push), `take_out` makes loose
## lying or falling ones GONE (never drawn, aimed or simulated; ids stay as they are, and trailing
## GONE records are cut off). The answer's change carries the records, so a Guest sees them too.
class_name Mess
extends Part

## The Host: a falling body of Sock `sock` (a Pair's lead) touched `other`. Thrown or not; a
## listener decides nothing in the handler, it asks a Command.
signal flight_touched(sock: int, other: Node)

enum State { LYING, HELD, FLYING, IN_PAIR, SHELVED, GONE }

## The physics layers (bits): the house and its furniture, a falling Sock, a lying Sock. The
## player's body collides with the house only, so it walks over Socks; the crosshair sees the house
## and lying Socks, never a falling one.
const LAYER_HOUSE := 1
const LAYER_FLIGHT := 2
const LAYER_LYING := 4
const AIM_MASK := LAYER_HOUSE | LAYER_LYING
## Floats in one pose: a Transform3D (basis columns x, y, z, then the origin).
const POSE := 12
## The metadata a falling body carries: its Sock id.
const SOCK_META := &"sock"
## How near another lying Sock must be to count as touching one (T11).
const TOUCH_MARGIN := 0.01
## The name of a falling body (a Guest's spawned copy is found by it), and of its Looks child.
const FLIGHT_NAME := "Flight%d"
const LOOKS := ^"Looks"
## The thrower of a poured Sock's launch (`add`): no player, so no body lets it through.
const NOBODY := -1

const FLIGHT_SCENE := MessMoving.FLIGHT_SCENE
const CLOTH_TUNING := preload("res://game/sock/sock_cloth_tuning.tres")

## The Designs a Sock's record names.
@export var catalogue: DesignCatalogue
## The flick before a dropped Sock falls, a Throw's drag and the hit's wake.
@export var tuning: HandsTuning
## The two tiers' numbers: the moving budget, the wakes, the rest rule, the bodies, the drawing.
@export var bodies: MessTuning = preload("res://game/mess/mess_tuning.tres")
## Where the SockSpots placed in the editor are (their children); they become the starting Socks.
@export var spots: Node3D
## Where lying Socks are drawn, and where the Host adds falling ones (a MultiplayerSpawner's
## spawn path in co-op, M0.6).
@export var lying: Node3D
@export var flights: Node3D
## The playable space, in the space of `lying` (the level's or the station's, set per level in the
## editor): a falling body outside it is put down at once at `return_spot` (T14). No volume: no bounds.
@export var bounds := AABB()
## Where a Sock that left `bounds`, or would end inside a wall, is put down lying (T08, T14).
@export var return_spot: Marker3D

@export_group("State")
## Each Sock's Design id, by Sock id.
@export var designs := PackedInt32Array()
## Each Sock's State, by Sock id.
@export var states := PackedByteArray()
## Each Sock's pose in the level (POSE floats a Sock): where it lies, or where it was let go.
@export var poses := PackedFloat32Array()
## The launch of each thrown Sock still in the air: {Sock id: {"vel": Vector3, "spin": Vector3,
## "by": the thrower's player id}}. A dropped or woken Sock has none; a poured one has its push, by NOBODY.
@export var throws := {}
## Each Sock's mate once paired, else -1, by Sock id (both ways: a Pair's lead and its IN_PAIR Sock).
@export var mates := PackedInt32Array()
@export_group("")

## The lying tier: the static bodies and the drawn instances (made once inside the tree).
var _lying_bodies: MessBodies
var _drawing: MessDrawing
## The records as they were last shown (what _show compares with).
var _shown_states := PackedByteArray()
var _shown_poses := PackedFloat32Array()
## The lying Socks lent their Looks scene now (looks_of), by Sock id.
var _lent: Dictionary[int, Node3D] = {}
## The Host's moving Socks: the falling bodies, the budget and the wakes.
var _moving := MessMoving.new(self)
## More nodes of SockSpots, handed over before this Mess is ready by a scene that joins the level
## (a zoo station, whose own Mess steps aside for the zoo's: ZooStations): read after `spots`, in order.
var more_spots: Array[Node3D] = []


## Before the level binds: the SockSpots (of `spots`, then of `more_spots`) become the starting
## records (as if placed in the inspector), and hide. A snapshot (a late Guest, a load) replaces them whole.
func _ready() -> void:
	if not designs.is_empty():
		return
	var holders: Array[Node3D] = [spots]
	holders.append_array(more_spots)
	for holder in holders:
		if holder != null:
			_add_spots(holder)


func _add_spots(holder: Node3D) -> void:
	for node in holder.get_children():
		var spot := node as SockSpot
		if spot == null:
			continue
		spot.sock = designs.size()
		designs.append(spot.design)
		states.append(State.LYING)
		mates.append(-1)
		poses.append_array(pack(spot.global_transform))
		spot.visible = false


## Back in the tree after leaving it (bound before): every Sock is shown again.
func _enter_tree() -> void:
	if parts != null and _lying_bodies == null and not designs.is_empty():
		_show.call_deferred(true)


## Leaving the tree, the lying bodies and drawings go with it (they are not nodes of the tree).
func _exit_tree() -> void:
	_moving.clear()
	if _lying_bodies != null:
		_lying_bodies.clear()
	if _drawing != null:
		_drawing.clear()
	_lying_bodies = null
	_drawing = null
	_shown_states = PackedByteArray()
	_shown_poses = PackedFloat32Array()


## How many Socks there are (every id from 0 to count() - 1).
func count() -> int:
	return designs.size()


func state_of(sock: int) -> State:
	return states[sock] as State if sock >= 0 and sock < states.size() else State.HELD


func design_of(sock: int) -> SockDesign:
	if sock < 0 or sock >= designs.size() or catalogue == null:
		return null
	return catalogue.design(designs[sock])


## The Sock's mate (the other Sock of its Pair), or -1 while it is loose.
func mate_of(sock: int) -> int:
	return mates[sock] if sock >= 0 and sock < mates.size() else -1


## Whether `sock` is a Pair's lead: where the Pair is, drawn as a sock ball.
func is_pair(sock: int) -> bool:
	return mate_of(sock) >= 0 and state_of(sock) != State.IN_PAIR


## How many records Design `design` has (two for a Design of the level, paired or not: I.1).
func count_of(design: int) -> int:
	return designs.count(design)


## Where the Sock lies, or where it was let go, in the level (a Pair's: its ball's centre).
func pose_of(sock: int) -> Transform3D:
	return unpack(poses, sock)


## The lying Sock whose body `rid` is (what the crosshair rests on: RayCast3D.get_collider_rid()), or -1.
func sock_at(rid: RID) -> int:
	if _lying_bodies == null or not rid.is_valid():
		return -1
	var sock := _lying_bodies.sock_of(rid)
	return sock if sock >= 0 and state_of(sock) == State.LYING else -1


## Whether lying Sock `sock` is shown now: as an instance of its cell or as its lent Looks.
func is_drawn(sock: int) -> bool:
	return _drawing != null and (_drawing.is_drawn(sock) or _lent.has(sock))


## The Looks scene of lying Sock `sock`, lent to it now if it had none (the outline plays there,
## M03): from now on it is drawn as that scene, not as an instance, until return_looks(). Null when
## the Sock does not lie.
func looks_of(sock: int) -> Node3D:
	if _lent.has(sock):
		return _lent[sock]
	if _drawing == null or not _drawing.is_drawn(sock) or state_of(sock) != State.LYING:
		return null
	var pair := is_pair(sock)
	var design := design_of(sock)
	var looks := SockDress.make(design, SockDress.LYING, pair)
	looks.name = "Sock%d" % sock
	_container(lying).add_child(looks)
	looks.global_transform = pose_of(sock) * Transform3D(Basis.from_scale(Vector3.ONE * _scale(design)))
	looks.reset_physics_interpolation()
	_drawing.undraw(sock)
	_drawing.flush()
	_lent[sock] = looks
	return looks


## Lying Sock `sock` gives its lent Looks back: drawn as an instance again, with no pop.
func return_looks(sock: int) -> void:
	if not _lent.has(sock):
		return
	_lent[sock].queue_free()
	_lent.erase(sock)
	if state_of(sock) == State.LYING and _lying_bodies != null and _lying_bodies.has(sock):
		_draw_lying(sock)
		_drawing.flush()


## How many lying Socks are drawn as instances now.
func drawn_count() -> int:
	return _drawing.drawn_count() if _drawing != null else 0


## How many lying bodies there are now.
func body_count() -> int:
	return _lying_bodies.size() if _lying_bodies != null else 0


## The falling body of a Sock (the Host's), or null.
func flight_of(sock: int) -> RigidBody3D:
	return _moving.flight_of(sock)


## How many Socks move now (falling bodies), and how many wait to.
func moving_count() -> int:
	return _moving.moving_count()


func waiting_count() -> int:
	return _moving.waiting_count()


## The change that takes a lying Sock into somebody's Hands (part of the Hands' pick answer).
func held_patch(sock: int) -> Dictionary:
	var s := states.duplicate()
	s[sock] = State.HELD
	return {"states": s, "throws": _without_throw(sock)}


## The change that fuses lying Sock `picked` with its held mate `lead` into one Pair (part of the
## Hands' pick answer, P01): `picked` goes IN_PAIR, the two name each other, the lead stays held.
func paired_patch(lead: int, picked: int) -> Dictionary:
	var s := states.duplicate()
	s[picked] = State.IN_PAIR
	var m := mates.duplicate()
	m[lead] = picked
	m[picked] = lead
	return {"states": s, "mates": m, "throws": _without_throw(picked)}


## The change that lets a held Sock go at `pose` (part of the Hands' drop answer): it falls from
## there. A Pair's ball is let go with its bottom at the pose, its centre a radius higher.
func flying_patch(sock: int, pose: Transform3D) -> Dictionary:
	if is_pair(sock):
		pose.origin += Vector3.UP * SockDress.ball_radius(design_of(sock))
	var s := states.duplicate()
	s[sock] = State.FLYING
	return {"states": s, "poses": _with_pose(sock, pose), "throws": _without_throw(sock)}


## The change that throws a held Sock (part of the Hands' throw answer): it leaves `pose` at once,
## no flick, with velocity `vel` and turn `spin`, thrown by player `by`.
func thrown_patch(sock: int, pose: Transform3D, vel: Vector3, spin: Vector3, by: int) -> Dictionary:
	var s := states.duplicate()
	s[sock] = State.FLYING
	var t := throws.duplicate()
	t[sock] = {"vel": vel, "spin": spin, "by": by}
	return {"states": s, "poses": _with_pose(sock, pose), "throws": t}


## The change that puts held or flying Pairs (their leads `leads`) into a Cabinet's drawer (part
## of the Cabinet's shelve answer): each lead goes SHELVED, its mate stays IN_PAIR, a throw is over.
func shelved_patch(leads: PackedInt32Array) -> Dictionary:
	var s := states.duplicate()
	var t := throws.duplicate()
	for sock in leads:
		s[sock] = State.SHELVED
		t.erase(sock)
	return {"states": s, "throws": t}


## Only the Host's own `rest`, `wake` and `fall` (no Guest may send one: nothing in accepts()).
## `wake` (a hit, a moving Door) and `fall` (what held it up was picked) start lying Socks or Pairs
## moving: "sock", one, or "socks", the ones the Host starts this tick (its args never travel; the
## answer's change does).
func decide(cmd: Command) -> Dictionary:
	if cmd.by != Parts.HOST:
		return refuse("wrong")
	match cmd.kind:
		&"rest":
			var sock: Variant = cmd.args.get("sock")
			var at: Variant = cmd.args.get("at")
			var rot: Variant = cmd.args.get("rot")
			if not (sock is int) or not (at is Vector3) or not (rot is Vector3) or state_of(sock) != State.FLYING:
				return refuse("wrong")
			var s := states.duplicate()
			s[sock] = State.LYING
			return grant({"states": s, "poses": _with_pose(sock, Transform3D(Basis.from_euler(rot), at)),
					"throws": _without_throw(sock)})
		&"wake", &"fall":
			var socks := PackedInt32Array()
			var one: Variant = cmd.args.get("sock")
			var many: Variant = cmd.args.get("socks")
			if one is int:
				socks.append(one)
			elif many is PackedInt32Array:
				socks = many
			var s := states.duplicate()
			var any := false
			for sock in socks:
				if state_of(sock) == State.LYING:
					s[sock] = State.FLYING
					any = true
			if not any:
				return refuse("wrong")
			return grant({"states": s})
		&"add":
			return _decide_add(cmd.args)
		&"take_out":
			return _decide_take_out(cmd.args)
	return refuse("wrong")


## `add` (Host-only): "designs" (PackedInt32Array), "poses" (PackedFloat32Array, POSE floats each),
## "vels" and "spins" (PackedVector3Array, one each): new FLYING records at the end, launched at
## once with that push (a throw by NOBODY).
func _decide_add(args: Dictionary) -> Dictionary:
	var ds: Variant = args.get("designs")
	var ps: Variant = args.get("poses")
	var vs: Variant = args.get("vels")
	var ss: Variant = args.get("spins")
	if not (ds is PackedInt32Array) or not (ps is PackedFloat32Array) or not (vs is PackedVector3Array) \
			or not (ss is PackedVector3Array):
		return refuse("wrong")
	var add_designs: PackedInt32Array = ds
	var n := add_designs.size()
	if n == 0 or (ps as PackedFloat32Array).size() != n * POSE or (vs as PackedVector3Array).size() != n \
			or (ss as PackedVector3Array).size() != n:
		return refuse("wrong")
	for design in add_designs:
		if catalogue == null or catalogue.design(design) == null:
			return refuse("wrong")
	var first := count()
	var d := designs.duplicate()
	d.append_array(add_designs)
	var s := states.duplicate()
	s.resize(first + n)
	var m := mates.duplicate()
	m.resize(first + n)
	var p := poses.duplicate()
	p.append_array(ps)
	var t := throws.duplicate()
	for i in n:
		s[first + i] = State.FLYING
		m[first + i] = -1
		t[first + i] = {"vel": (vs as PackedVector3Array)[i], "spin": (ss as PackedVector3Array)[i], "by": NOBODY}
	return grant({"designs": d, "states": s, "mates": m, "poses": p, "throws": t})


## `take_out` (Host-only): "socks" (PackedInt32Array): those lying or falling go GONE, a Pair only
## when both its Socks are named; held and shelved ones stay. Trailing GONE records are cut off.
func _decide_take_out(args: Dictionary) -> Dictionary:
	var named: Variant = args.get("socks")
	if not (named is PackedInt32Array):
		return refuse("wrong")
	var asked: Dictionary[int, bool] = {}
	for sock: int in named:
		asked[sock] = true
	var s := states.duplicate()
	var t := throws.duplicate()
	var any := false
	for sock: int in named:
		if sock < 0 or sock >= count() or state_of(sock) not in [State.LYING, State.FLYING]:
			continue
		var mate := mate_of(sock)
		if mate >= 0 and not asked.has(mate):
			continue
		s[sock] = State.GONE
		t.erase(sock)
		if mate >= 0:
			s[mate] = State.GONE
		any = true
	if not any:
		return refuse("already")
	var keep := s.size()
	while keep > 0 and s[keep - 1] == State.GONE:
		keep -= 1
	return grant({"states": s.slice(0, keep), "designs": designs.slice(0, keep), "mates": mates.slice(0, keep),
			"poses": poses.slice(0, keep * POSE), "throws": t})


## The lying Socks touching lying Sock `sock`, at most the tuning's wake_count (T11).
func touching(sock: int) -> PackedInt32Array:
	var most := tuning.wake_count if tuning != null else 8
	if _lying_bodies == null:
		return PackedInt32Array()
	return _lying_bodies.touching(sock, TOUCH_MARGIN, most)


## The lying Socks and Pairs resting on the place `under` (a box in the level), lowest first, at
## most the tuning's pick_wakes (M07).
func resting_on(under: AABB) -> PackedInt32Array:
	if _lying_bodies == null:
		return PackedInt32Array()
	var t := bodies_tuning()
	return _lying_bodies.above(under, t.wake_margin, t.pick_column, t.above_slack, t.pick_wakes)


## The box lying Sock `sock` takes in the level, or an empty one.
func box_of(sock: int) -> AABB:
	return _lying_bodies.bounds_of(sock) if _lying_bodies != null else AABB()


## Whether `point` (in the level) is inside the playable space (always, with no bounds).
func in_bounds(point: Vector3) -> bool:
	if not bounds.has_volume():
		return true
	var local := lying.global_transform.affine_inverse() * point if lying != null else point
	return bounds.has_point(local)


## The Host: lying Socks `socks` wait their turn to move, started by Command `kind` (&"wake" or
## &"fall"), nearest the players first (M05).
func queue_wake(socks: PackedInt32Array, kind: StringName) -> void:
	_moving.queue_wake(socks, kind)


## Every Sock is drawn as its record says: lying Socks as bodies and instances, held ones not at
## all (the Hands draw them), a falling one as the Host's body: a dropped one let go after the
## flick, a thrown or woken one (or any when `now`) at once. Only the Socks whose record changed
## since the last time are touched, records added or cut off included; `now` shows every one.
func _show(now: bool) -> void:
	if not is_inside_tree():
		return
	if _lying_bodies == null:
		_drawing = MessDrawing.new(_container(lying) as Node3D, bodies_tuning())
		_lying_bodies = MessBodies.new(self, _drawing.sock_points())
		now = true
	var changed: PackedInt32Array
	if now:
		for sock: int in _lent.keys():
			return_looks(sock)
		changed = PackedInt32Array(range(count()))
		_moving.clear()
		_lying_bodies.clear()
		for sock in range(count(), _shown_states.size()):
			_drawing.undraw(sock)
		for sock in count():
			_drawing.undraw(sock)
		_shown_states = PackedByteArray()
		_shown_states.resize(count())
		_shown_states.fill(255)
	else:
		var found: Dictionary[int, bool] = {}
		var common := mini(_shown_states.size(), count())
		_changed(_shown_states, states, 1, 0, common, found)
		_changed(_shown_poses, poses, POSE, 0, common, found)
		for sock in range(common, _shown_states.size()):
			_cut_off(sock)
		_shown_states.resize(count())
		for sock in range(common, count()):
			_shown_states[sock] = 255
			found[sock] = true
		changed = PackedInt32Array(found.keys())
	var woken: Dictionary[int, bool] = {}
	for sock in changed:
		var was := _shown_states[sock]
		if _lying_bodies.has(sock):
			if state_of(sock) in [State.HELD, State.IN_PAIR] and _is_host():
				_moving.note_taken(_lying_bodies.bounds_of(sock))
			if state_of(sock) == State.FLYING and was == State.LYING:
				woken[sock] = true
			if _lent.has(sock):
				_lent[sock].queue_free()
				_lent.erase(sock)
			_drawing.undraw(sock)
			_lying_bodies.remove(sock)
		_moving.forget(sock)
	for sock in changed:
		match state_of(sock):
			State.LYING:
				_lie(sock)
			State.FLYING:
				if _is_host():
					_moving.start(sock, woken.has(sock), now)
	_shown_states = states.duplicate()
	_shown_poses = poses.duplicate()
	_drawing.flush()


## A record cut off the end (`take_out`): its body, drawing, lent Looks and flight go.
func _cut_off(sock: int) -> void:
	if _lent.has(sock):
		_lent[sock].queue_free()
		_lent.erase(sock)
	_drawing.undraw(sock)
	if _lying_bodies.has(sock):
		_lying_bodies.remove(sock)
	_moving.forget(sock)


## The Host: starts the Socks woken by a hit, a pick or a moving Door as the budget allows, lets
## flicked Socks go, and writes a fallen one lying where its body rests (M06: under the rest speed
## and spin for the rest time), or at the return spot when it left the bounds (T14) or would lie
## inside a wall (T08). Every machine: the flights nearest the camera get their Looks.
func _physics_process(delta: float) -> void:
	if _lying_bodies == null:
		return
	give_looks()
	if _is_host() and parts != null:
		_moving.tick(delta)


## Every machine, each frame: the flights with no Looks are drawn as instances where their bodies are.
func _process(_delta: float) -> void:
	if _drawing == null:
		return
	_drawing.flush()
	var rows: Dictionary[StringName, Array] = {}
	for body in _flight_nodes():
		if body.has_node(LOOKS):
			continue
		var sock := _sock_of_flight(body)
		var design := design_of(sock)
		var shape := MessDrawing.shape_of(design, is_pair(sock))
		if not rows.has(shape):
			rows[shape] = []
		rows[shape].append([body.get_global_transform_interpolated().orthonormalized(), design])
	_drawing.draw_flying(rows)


func _is_host() -> bool:
	return parts == null or parts.is_host()


## The two tiers' numbers (a default when none is set).
func bodies_tuning() -> MessTuning:
	if bodies == null:
		bodies = MessTuning.new()
	return bodies


## A lying Sock gets its body where its record says, and is drawn there (a Pair as its ball).
func _lie(sock: int) -> void:
	var design := design_of(sock)
	var pair := is_pair(sock)
	_lying_bodies.place(sock, pose_of(sock), pair, _scale(design), SockDress.ball_radius(design))
	_draw_lying(sock)


func _draw_lying(sock: int) -> void:
	var design := design_of(sock)
	_drawing.draw(sock, pose_of(sock), MessDrawing.shape_of(design, is_pair(sock)), design)


## Every machine: while fewer than the cloth's flying_cap flights have a Looks (core/09), the
## nearest the camera without one gets it; none is taken from a flight that has one (no pop).
func give_looks() -> void:
	var cap := CLOTH_TUNING.flying_cap if CLOTH_TUNING != null else 4
	var without: Array[RigidBody3D] = []
	var have := 0
	for body in _flight_nodes():
		if body.has_node(LOOKS):
			have += 1
		else:
			without.append(body)
	if have >= cap or without.is_empty():
		return
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera != null and without.size() > cap - have:
		var eye := camera.global_position
		without.sort_custom(func(a: RigidBody3D, b: RigidBody3D) -> bool:
			return a.global_position.distance_squared_to(eye) < b.global_position.distance_squared_to(eye))
	for i in mini(cap - have, without.size()):
		var body := without[i]
		var sock := _sock_of_flight(body)
		var looks := SockDress.make(design_of(sock), SockDress.LYING, is_pair(sock))
		looks.name = String(LOOKS)
		body.add_child(looks)


## Where the falling bodies go (the spawner's path in co-op).
func flight_holder() -> Node:
	return _container(flights)


## The lying Socks `shape` at `xform` overlaps, at most `most`.
func lying_overlapping(shape: Shape3D, xform: Transform3D, most: int) -> PackedInt32Array:
	return _lying_bodies.overlapping(shape, xform, most) if _lying_bodies != null else PackedInt32Array()


## The falling bodies under `flights` on this machine (the Host's own, or a Guest's spawned copies).
func _flight_nodes() -> Array[RigidBody3D]:
	var out: Array[RigidBody3D] = []
	var holder := _container(flights)
	for child in holder.get_children():
		var body := child as RigidBody3D
		if body != null and not body.is_queued_for_deletion() and String(body.name).begins_with("Flight"):
			out.append(body)
	return out


## The Sock a falling body is: its metadata (the Host's), else its name (a spawned copy).
func _sock_of_flight(body: RigidBody3D) -> int:
	if body.has_meta(SOCK_META):
		return int(body.get_meta(SOCK_META))
	var digits := String(body.name).trim_prefix("Flight")
	return int(digits) if digits.is_valid_int() else -1


static func _scale(design: SockDesign) -> float:
	return design.size_scale() if design != null else 1.0


## The records `lo` to `hi` (stride floats or bytes each) that differ between `a` and `b`, into
## `out`: the halves are compared whole (native), so a few changes cost a few compares, not one a record.
static func _changed(a: Variant, b: Variant, stride: int, lo: int, hi: int, out: Dictionary[int, bool]) -> void:
	if hi <= lo or a.slice(lo * stride, hi * stride) == b.slice(lo * stride, hi * stride):
		return
	if hi - lo == 1:
		out[lo] = true
		return
	var mid := (lo + hi) / 2
	_changed(a, b, stride, lo, mid, out)
	_changed(a, b, stride, mid, hi, out)


func _container(node: Node3D) -> Node:
	return node if node != null else self


func _without_throw(sock: int) -> Dictionary:
	var t := throws.duplicate()
	t.erase(sock)
	return t


func _with_pose(sock: int, pose: Transform3D) -> PackedFloat32Array:
	var p := poses.duplicate()
	var row := pack(pose)
	for i in POSE:
		p[sock * POSE + i] = row[i]
	return p


## A pose as POSE floats.
static func pack(t: Transform3D) -> PackedFloat32Array:
	var b := t.basis
	return PackedFloat32Array([b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, t.origin.x, t.origin.y, t.origin.z])


## The pose of record `i` in `rows` (POSE floats a record).
static func unpack(rows: PackedFloat32Array, i: int) -> Transform3D:
	var o := i * POSE
	if i < 0 or o + POSE > rows.size():
		return Transform3D.IDENTITY
	return Transform3D(Vector3(rows[o], rows[o + 1], rows[o + 2]), Vector3(rows[o + 3], rows[o + 4], rows[o + 5]),
			Vector3(rows[o + 6], rows[o + 7], rows[o + 8]), Vector3(rows[o + 9], rows[o + 10], rows[o + 11]))
