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
##
## An answer's change of the Mess carries only the records it changed (coop/07, coop-flight-sync
## condition 3): a rows patch (ROWS: the Sock ids, and each one's whole record), the record count
## when it changes, and the launches of the rows that fly. The *_patch functions make one and take
## the patch made so far (`onto`), so one answer may change many Socks. A snapshot (a late Guest, a
## save) stays whole, packed and compressed (whole_state()), a flying Sock with its body's motion.
##
## Moving Socks on every machine (coop/08, docs/migration/coop-mess-sync.md, Q2222, Q2472): when a
## record turns FLYING by a wake, a fall, a pour, a sweep or a drop, each machine starts its own body
## from the record (the Host's decides; a Guest's is looks only, on LAYER_LOOKS, and never wakes,
## rests or writes anything shared), and the Host's rest batch snaps it. Only a Throw's body is the
## Host's alone, under `flights` (the spawner's path), streamed to every Guest as stamped rows played
## 0.1 s behind (FlightRow, coop/09); every other body is under
## this Mess's own holder (bodies_holder()), which no spawner sees. Every machine sweeps its own lying
## Socks with its moving Doors and drawers; a Guest's swept Sock the Host never moved goes back.
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
## A Guest's looks-only falling Sock (coop/08): it touches the house, the lying Socks and the other
## looks-only bodies, never a Throw's copy.
const LAYER_LOOKS := 16
const LOOKS_MASK := LAYER_HOUSE | LAYER_LYING | LAYER_LOOKS
## A Guest's own Throw or drop ghost (coop/09, ThrowGhost, I3): it touches the static house only.
const LAYER_GHOST := 32
const AIM_MASK := LAYER_HOUSE | LAYER_LYING
## What the crosshair looks for a Sock in: a lying one or a moving one (a woken or thrown body, as the
## old game's SOCK_LIVE; a Guest's own body too), never a wall (R03).
const SOCK_MASK := LAYER_LYING | LAYER_FLIGHT | LAYER_LOOKS
## Floats in one pose: a Transform3D (basis columns x, y, z, then the origin).
const POSE := 12
## The metadata a falling body carries: its Sock id.
const SOCK_META := &"sock"
## The name of a falling body (a Guest's spawned copy is found by it): the prefix and the Sock id; and
## the name of its Looks child.
const FLIGHT_PREFIX := "Flight"
const FLIGHT_NAME := FLIGHT_PREFIX + "%d"
const LOOKS := ^"Looks"
## The thrower of a poured Sock's launch (`add`): no player, so no body lets it through.
const NOBODY := -1
## An answer's list of places where a lost Sock or Pair came back (a "pop" plays at each, core/16).
const POPPED := "popped"
## A rows patch's keys: the Sock ids changed, each one's whole record (Design, State, mate, pose:
## aligned with ROWS, POSE floats a pose), the new record count when it changes (records past it are
## cut off; records added are among the rows), and {Sock id: launch} for the rows that fly with one.
## A row with no launch has none after it.
const ROWS := "rows"
const ROW_DESIGNS := "row_designs"
const ROW_STATES := "row_states"
const ROW_MATES := "row_mates"
const ROW_POSES := "row_poses"
const ROW_COUNT := "count"
const LAUNCHES := "launches"
## A whole state packed (whole_state()): the compressed bytes and their size unpacked.
const PACKED := "packed"
const PACKED_SIZE := "packed_size"
## The bytes of one body in flight in a packed whole state: its origin (3 floats), turn (a quaternion)
## and velocity and spin (3 each), as half floats.
const MOTION := 12 + 10 * 2
## The name of the holder of the bodies no spawner sees (bodies_holder()).
const BODIES := "Bodies"

const FLIGHT_SCENE := MessMoving.FLIGHT_SCENE
const CLOTH_TUNING := preload("res://game/sock/sock_cloth_tuning.tres")
const BALL_LANDING := preload("res://game/sock/ball_landing_tuning.tres")

## The Designs a Sock's record names.
@export var catalogue: DesignCatalogue
## A Throw's (and a drop's) drag and the hit's wake.
@export var tuning: HandsTuning
## The two tiers' numbers: the moving budget, the wakes, the rest rule, the bodies, the drawing.
@export var bodies: MessTuning = preload("res://game/mess/mess_tuning.tres")
## A Throw's stream and a Guest's ghosts (coop/09).
@export var ghosts: GhostTuning = preload("res://game/hands/ghost_tuning.tres")
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
## The launch of each thrown or dropped Sock still in the air: {Sock id: {"vel": Vector3, "spin":
## Vector3, "by": the thrower's player id}, a drop's with "drop": true}. A woken Sock has none; a
## poured one has its push, by NOBODY.
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
## The falling bodies on this machine by Sock id (the Host's own, or a Guest's spawned copies), kept
## as they enter and leave `flights` (core/31: no walk over every child for one Sock's body), the
## ones that have a Looks, and each one's shape once drawn as an instance.
var _flight_by_sock: Dictionary[int, RigidBody3D] = {}
var _flight_looks: Dictionary[RigidBody3D, bool] = {}
var _flight_shape: Dictionary[int, StringName] = {}
## Whether the last frame drew any flying Sock as an instance (the next one must clear it).
var _flying_drawn := false
## A Guest: the smallest (this machine's tick - the Host's stamp) seen in any Throw's row: the one-way
## delay estimate every streamed body plays by (FlightRow); a whole state written sets it back.
var stream_offset := INF
## The Socks this machine's ghosts draw themselves (GuestGhosts): the Mess does not draw them, lying or
## flying, until let go (hold_back()).
var _held_back: Dictionary[int, bool] = {}
## The holder of every body but a Throw's (made in _ready, a child of this Mess: no spawner's path).
var _bodies: Node3D
## A whole state's bodies in flight as it was written (a late Guest, a load): {Sock id: [pose,
## velocity, spin]}, read by the next _show() as it starts them, then cleared.
var _motion: Dictionary[int, Array] = {}
## The Host's dice for a lost Sock's return scatter (return_pose()).
var _scatter := RandomNumberGenerator.new()
## More nodes of SockSpots, handed over before this Mess is ready by a scene that joins the level
## (a zoo station, whose own Mess steps aside for the zoo's: ZooStations): read after `spots`, in order.
var more_spots: Array[Node3D] = []


## Before the level binds: the SockSpots (of `spots`, then of `more_spots`) become the starting
## records (as if placed in the inspector), and hide. A snapshot (a late Guest, a load) replaces them whole.
func _ready() -> void:
	assert(tuning != null, "Mess: its HandsTuning (`tuning`) is not set")
	if _bodies == null:
		_bodies = Node3D.new()
		_bodies.name = BODIES
		add_child(_bodies)
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


## The Sock the thing a crosshair line met is (a `PhysicsQueries.ray` hit): a lying Sock by its body, a
## moving one by its falling body; -1 for the house or a Sock that is neither (R03).
func sock_of_hit(hit: Dictionary) -> int:
	if hit.is_empty():
		return -1
	var body := hit.get("collider") as RigidBody3D
	if body != null:
		var sock := _sock_of_flight(body)
		return sock if is_moving(sock) and moving_body(sock) == body else -1
	return sock_at(hit.get("rid", RID()))


## Whether Sock `sock` is a moving body now (woken, dropped, or thrown), which may be
## aimed at and picked mid-air or mid-slide (R03, the old SOCK_LIVE, Q2339). On any machine: a Guest's
## spawned copy counts.
func is_moving(sock: int) -> bool:
	return state_of(sock) == State.FLYING and moving_body(sock) != null


## The falling body of Sock `sock` on this machine (the Host's own, or a Guest's spawned copy), or null.
func moving_body(sock: int) -> RigidBody3D:
	var body: RigidBody3D = _flight_by_sock.get(sock)
	return body if body != null and not body.is_queued_for_deletion() else null


## Where Sock `sock`'s falling body is drawn on this machine now, its Size included, or null: its
## Looks while it has one, else its body. A body already let go this frame still counts (a thrown Pair
## shelved by a Cabinet flies on from where it was: core/27 P11).
func drawn_flight_of(sock: int) -> Variant:
	var body: RigidBody3D = _flight_by_sock.get(sock)
	if body == null or not body.is_inside_tree():
		return null
	var looks := body.get_node_or_null(LOOKS) as Node3D
	if looks != null:
		return looks.global_transform
	return body.global_transform * _sized(design_of(sock))


## Where Sock `sock` is now: its falling body's place while it moves, else where its record puts it.
func where_of(sock: int) -> Vector3:
	var body := moving_body(sock) if state_of(sock) == State.FLYING else null
	return body.global_position if body != null else pose_of(sock).origin


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
	looks.global_transform = pose_of(sock) * _sized(design)
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


## The falling body of a Sock this machine started itself (the Host's, or a Guest's looks-only one), or null.
func flight_of(sock: int) -> RigidBody3D:
	return _moving.flight_of(sock)


## How many Socks move now on this machine (its falling bodies: the heap sign's Moving count, a
## Guest's own included, B14), and how many wait to.
func moving_count() -> int:
	return _moving.moving_count() if _is_host() else _flight_nodes().size()


func waiting_count() -> int:
	return _moving.waiting_count()


## The change that takes a lying Sock into somebody's Hands (part of the Hands' pick answer).
func held_patch(sock: int, onto := {}) -> Dictionary:
	var p := _rows_onto(onto)
	_set_state(p, _row(p, sock), State.HELD)
	return p


## The change that fuses lying Sock `picked` with its held mate `lead` into one Pair (part of the
## Hands' pick answer, P01): `picked` goes IN_PAIR, the two name each other, the lead stays held.
func paired_patch(lead: int, picked: int, onto := {}) -> Dictionary:
	var p := _rows_onto(onto)
	var i := _row(p, picked)
	_set_state(p, i, State.IN_PAIR)
	var j := _row(p, lead)
	var m: PackedInt32Array = p[ROW_MATES]
	m[i] = lead
	m[j] = picked
	p[ROW_MATES] = m
	return p


## The change that throws a held Sock (part of the Hands' throw answer): it leaves `pose` at once,
## no flick, with velocity `vel` and turn `spin`, thrown by player `by` (their body lets it through).
## A Pair's pose is its ball's centre. `drop` (the Hands' drop answer, Q2367): let go, it falls on its
## own to its spot with drift `vel`, and is never shelved by a Cabinet's front.
func thrown_patch(sock: int, pose: Transform3D, vel: Vector3, spin: Vector3, by: int, drop := false, onto := {}) -> Dictionary:
	var p := _rows_onto(onto)
	var i := _row(p, sock)
	_set_state(p, i, State.FLYING)
	_set_pose(p, i, pose)
	var launch := {"vel": vel, "spin": spin, "by": by}
	if drop:
		launch["drop"] = true
	(p[LAUNCHES] as Dictionary)[sock] = launch
	return p


## The Host's rule for where Sock `sock` let down at `t` lies (core/16 P12, P13; the old
## hands_rules.gd:490-510): out of bounds, or inside a wall, it is lost and comes back at the return
## spot scattered within `return_scatter` ("returned": true, a pop plays); its middle (a Pair's
## bottom) under a floor's top by less than `sunk`, it lies as it is (the old flat_layout.gd
## sunk_floor(): still in the room); `sunk` to `sunk_depth` under, it is pushed up onto that floor
## where it is ("returned": false); its middle inside a Door's or drawer's leaf seen moving, it is
## pushed out of the leaf to the side the leaf swept from, all of it `leaf_clearance` clear of the
## leaf's face, and put down there by the same rules (core/39, Q2428: "returned": false, "pushed":
## the flat way out), unless that is lost too; else it lies at `t`.
## Returns {"pose": Transform3D, "returned": bool} (and "pushed": Vector3).
func put_down(sock: int, t: Transform3D) -> Dictionary:
	var pair := is_pair(sock)
	var radius := SockDress.ball_radius(design_of(sock)) if pair else 0.0
	if not in_bounds(t.origin):
		return {"pose": return_pose(sock), "returned": true}
	var centre := t.origin if pair else t * _sock_middle(design_of(sock))
	if not PhysicsQueries.inside(self, centre, LAYER_HOUSE):
		return {"pose": t, "returned": false}
	var leaf := _moving.out_of_leaf(centre)
	if not leaf.is_empty():
		var dir := leaf["dir"] as Vector3
		var by := dir * (float(leaf["exit"]) + _reach(sock, t.basis, dir) + bodies_tuning().leaf_clearance)
		var out := _on_floor(t.translated(by), centre + by, radius, pair) if in_bounds(t.origin + by) else {}
		if not out.is_empty():
			out["pushed"] = leaf["dir"]
			return out
	var down := _on_floor(t, centre, radius, pair)
	return down if not down.is_empty() else {"pose": return_pose(sock), "returned": true}


## How far Sock `sock` turned by `basis` reaches from its middle along flat `dir`: a Pair its ball's
## radius, a loose Sock half its box measured along `dir`.
func _reach(sock: int, basis: Basis, dir: Vector3) -> float:
	if is_pair(sock):
		return SockDress.ball_radius(design_of(sock))
	var box := SockDress.box(design_of(sock)) * 0.5
	var b := basis.orthonormalized()
	return absf(b.x.dot(dir)) * box.x + absf(b.y.dot(dir)) * box.y + absf(b.z.dot(dir)) * box.z


## Put down at `t` with its middle (a Pair's ball centre, `radius`) at `centre`: as it is, out of
## everything; as it is, or pushed up onto the floor, sunk into a floor's top (P13); {} inside a wall.
func _on_floor(t: Transform3D, centre: Vector3, radius: float, pair: bool) -> Dictionary:
	if not PhysicsQueries.inside(self, centre, LAYER_HOUSE):
		return {"pose": t, "returned": false}
	var b := bodies_tuning()
	var low := centre.y - radius
	var hit := PhysicsQueries.ray(self, centre + Vector3.UP * (b.sunk_depth + radius), centre, LAYER_HOUSE)
	if hit.is_empty() or (hit["normal"] as Vector3).y <= b.floor_up:
		return {}
	var top := (hit["position"] as Vector3).y
	var depth := top - low
	if depth >= -0.0001 and depth < b.sunk - 0.0001:
		return {"pose": t, "returned": false}
	if depth >= b.sunk - 0.0001 and depth <= b.sunk_depth:
		var lift := depth if pair else top - t.origin.y
		return {"pose": Transform3D(t.basis, t.origin + Vector3.UP * lift), "returned": false}
	return {}


## Where a lost Sock comes back (P12): at the return spot, turned and scattered at random within
## `return_scatter` round it (a Pair's ball a radius over it); with no spot, at the origin.
func return_pose(sock: int) -> Transform3D:
	var lift := Vector3.UP * SockDress.ball_radius(design_of(sock)) if is_pair(sock) else Vector3.ZERO
	var base := Transform3D.IDENTITY
	if return_spot != null and return_spot.is_inside_tree():
		base = return_spot.global_transform.orthonormalized()
	var r := bodies_tuning().return_scatter * sqrt(_scatter.randf())
	var a := _scatter.randf() * TAU
	var turn := Basis(Vector3.UP, _scatter.randf() * TAU)
	return Transform3D(turn * base.basis, base.origin + Vector3(cos(a), 0.0, sin(a)) * r + lift)


## The middle of a lying Sock of `design`, in its own pose's space (its leg and foot boxes).
static func _sock_middle(design: SockDesign) -> Vector3:
	var sum := Vector3.ZERO
	var parts := MessBodies.parts_at(SockDress.scale_of(design))
	for part: Array in parts:
		sum += part[1] as Vector3
	return sum / maxf(parts.size(), 1)


## The change that puts lying or flying Sock `sock` down at `pose`, lying (a zoo button's answer,
## core/16 Q2369; the Host's `rest` does the same for a flight), added to the patch made so far.
func lying_patch(sock: int, pose: Transform3D, onto := {}) -> Dictionary:
	var p := _rows_onto(onto)
	var i := _row(p, sock)
	_set_state(p, i, State.LYING)
	_set_pose(p, i, pose)
	(p[LAUNCHES] as Dictionary).erase(sock)
	return p


## The change that puts held or flying Pairs (their leads `leads`) into a Cabinet's drawer (part
## of the Cabinet's shelve answer): each lead goes SHELVED, its mate stays IN_PAIR, a throw is over.
func shelved_patch(leads: PackedInt32Array, onto := {}) -> Dictionary:
	var p := _rows_onto(onto)
	for sock in leads:
		_set_state(p, _row(p, sock), State.SHELVED)
		(p[LAUNCHES] as Dictionary).erase(sock)
	return p


## The State a rows patch gives each Sock it names: {Sock id: State} (what a listener of an answer reads).
static func row_states(patch: Dictionary) -> Dictionary[int, int]:
	var out: Dictionary[int, int] = {}
	var rows: PackedInt32Array = patch.get(ROWS, PackedInt32Array())
	var row_states_of: PackedByteArray = patch.get(ROW_STATES, PackedByteArray())
	for i in rows.size():
		out[rows[i]] = row_states_of[i]
	return out


## A copy of rows patch `onto` to add rows to (an empty one when `onto` is empty).
func _rows_onto(onto: Dictionary) -> Dictionary:
	if onto.is_empty():
		return {ROWS: PackedInt32Array(), ROW_DESIGNS: PackedInt32Array(), ROW_STATES: PackedByteArray(),
				ROW_MATES: PackedInt32Array(), ROW_POSES: PackedFloat32Array(), LAUNCHES: {}}
	assert(onto.has(ROWS), "Mess: a patch to add rows to is a rows patch")
	return onto.duplicate(true)


## The index of Sock `sock`'s row in rows patch `p`; a new row, made from its record now (and its
## launch), when the patch has none yet.
func _row(p: Dictionary, sock: int) -> int:
	var rows: PackedInt32Array = p[ROWS]
	var i := rows.find(sock)
	if i >= 0:
		return i
	rows.append(sock)
	p[ROWS] = rows
	var d: PackedInt32Array = p[ROW_DESIGNS]
	d.append(designs[sock])
	p[ROW_DESIGNS] = d
	var s: PackedByteArray = p[ROW_STATES]
	s.append(states[sock])
	p[ROW_STATES] = s
	var m: PackedInt32Array = p[ROW_MATES]
	m.append(mates[sock])
	p[ROW_MATES] = m
	var o: PackedFloat32Array = p[ROW_POSES]
	o.append_array(poses.slice(sock * POSE, sock * POSE + POSE))
	p[ROW_POSES] = o
	if throws.has(sock) and not (p[LAUNCHES] as Dictionary).has(sock):
		(p[LAUNCHES] as Dictionary)[sock] = throws[sock]
	return rows.size() - 1


static func _set_state(p: Dictionary, i: int, state: State) -> void:
	var s: PackedByteArray = p[ROW_STATES]
	s[i] = state
	p[ROW_STATES] = s


static func _set_pose(p: Dictionary, i: int, pose: Transform3D) -> void:
	var o: PackedFloat32Array = p[ROW_POSES]
	var row := pack(pose)
	for k in POSE:
		o[i * POSE + k] = row[k]
	p[ROW_POSES] = o


## The one writer of the Mess's state: a rows patch (an answer) writes only its rows, on every
## machine alike; anything else (a snapshot, a save, a test's set-up) is written whole by field name.
func write(patch: Dictionary, now: bool) -> void:
	if patch.has(PACKED):
		patch = _unpacked(patch)
	if not patch.has(ROWS):
		stream_offset = INF
		super.write(patch, now)
		_motion.clear()
		return
	var n := int(patch.get(ROW_COUNT, count()))
	if n != count():
		for sock in range(n, count()):
			throws.erase(sock)
		designs.resize(n)
		states.resize(n)
		mates.resize(n)
		poses.resize(n * POSE)
	var rows: PackedInt32Array = patch[ROWS]
	var row_designs: PackedInt32Array = patch[ROW_DESIGNS]
	var row_states_of: PackedByteArray = patch[ROW_STATES]
	var row_mates: PackedInt32Array = patch[ROW_MATES]
	var row_poses: PackedFloat32Array = patch[ROW_POSES]
	var launches: Dictionary = patch.get(LAUNCHES, {})
	for i in rows.size():
		var sock := rows[i]
		if sock < 0 or sock >= n:
			Log.error("parts", "%s: a row for Sock %d of %d" % [id, sock, n])
			continue
		designs[sock] = row_designs[i]
		states[sock] = row_states_of[i]
		mates[sock] = row_mates[i]
		for k in POSE:
			poses[sock * POSE + k] = row_poses[i * POSE + k]
		if launches.has(sock):
			throws[sock] = launches[sock]
		else:
			throws.erase(sock)
	_show(now)


## The whole state as it is sent whole (a late Guest, a save; coop/08, A05, A07): the State fields as
## packed arrays, exact (the records written from it equal these), and each body in flight's place
## and motion (MOTION bytes a body: looks only, so its turn and speeds are half floats), through
## var_to_bytes and zstd.
func whole_state() -> Dictionary:
	var socks := PackedInt32Array()
	var motion := PackedByteArray()
	for sock: int in _flight_by_sock:
		var body := moving_body(sock)
		if body == null or state_of(sock) != State.FLYING or not body.has_meta(SOCK_META):
			continue
		socks.append(sock)
		motion.resize(motion.size() + MOTION)
		_pack_motion(motion, socks.size() - 1, body.global_transform, body.linear_velocity, body.angular_velocity)
	var raw := var_to_bytes({"designs": designs, "states": states, "mates": mates, "throws": throws,
			"poses": poses, "moving": socks, "motion": motion})
	return {PACKED: raw.compress(FileAccess.COMPRESSION_ZSTD), PACKED_SIZE: raw.size()}


## A packed whole state (whole_state()) as its fields by name; its bodies in flight are kept for the
## _show() that follows (`_motion`). {} when it does not read.
func _unpacked(patch: Dictionary) -> Dictionary:
	var fields := unpacked(patch)
	if fields.is_empty():
		Log.error("parts", "%s: an unreadable packed state" % id)
		return {}
	_motion = fields["motion"]
	fields.erase("motion")
	return fields


## A packed whole state (whole_state()) read back: the State fields by name, and "motion", each body in
## flight's {Sock id: [pose, velocity, spin]}. {} when it does not read.
static func unpacked(whole: Dictionary) -> Dictionary:
	var bytes: Variant = whole.get(PACKED)
	var size := int(whole.get(PACKED_SIZE, 0))
	if not (bytes is PackedByteArray) or size <= 0:
		return {}
	var plain: Variant = bytes_to_var((bytes as PackedByteArray).decompress(size, FileAccess.COMPRESSION_ZSTD))
	if not (plain is Dictionary) or not (plain as Dictionary).has("poses"):
		return {}
	var d := plain as Dictionary
	var motion: Dictionary[int, Array] = {}
	var socks: PackedInt32Array = d.get("moving", PackedInt32Array())
	var bytes_of: PackedByteArray = d.get("motion", PackedByteArray())
	for i in mini(socks.size(), bytes_of.size() / MOTION):
		motion[socks[i]] = _unpack_motion(bytes_of, i)
	return {"designs": d["designs"], "states": d["states"], "mates": d["mates"], "throws": d["throws"],
			"poses": d["poses"], "motion": motion}


## Body `i`'s place, velocity and spin into `out` (MOTION bytes a body): its origin as floats, its turn
## (a quaternion), velocity and spin as half floats.
static func _pack_motion(out: PackedByteArray, i: int, at: Transform3D, vel: Vector3, spin: Vector3) -> void:
	var o := i * MOTION
	var q := at.basis.orthonormalized().get_rotation_quaternion()
	for k in 3:
		out.encode_float(o + k * 4, at.origin[k])
	var halves := [q.x, q.y, q.z, q.w, vel.x, vel.y, vel.z, spin.x, spin.y, spin.z]
	for k in halves.size():
		out.encode_half(o + 12 + k * 2, halves[k])


## Body `i`'s [pose, velocity, spin] out of `bytes` (_pack_motion()).
static func _unpack_motion(bytes: PackedByteArray, i: int) -> Array:
	var o := i * MOTION
	var h := func(k: int) -> float: return bytes.decode_half(o + 12 + k * 2)
	var q := Quaternion(h.call(0), h.call(1), h.call(2), h.call(3)).normalized()
	var at := Vector3(bytes.decode_float(o), bytes.decode_float(o + 4), bytes.decode_float(o + 8))
	return [Transform3D(Basis(q), at), Vector3(h.call(4), h.call(5), h.call(6)), Vector3(h.call(7), h.call(8), h.call(9))]


## Only the Host's own `rest`, `wake` and `fall` (no Guest may send one: nothing in accepts()).
## `rest` is one batch a tick of every flight that came to rest (coop/07, the old game's settle
## stream): "socks", "ats" and "rots" (one place and turn each), "returned" (those of them that were
## lost and came back). `wake` (a hit, a moving Door) and `fall` (what held it up was picked) start
## lying Socks or Pairs moving: "sock", one, or "socks", the ones the Host starts this tick (its args
## never travel; the answer's change does).
func decide(cmd: Command) -> Dictionary:
	if cmd.by != Parts.HOST:
		return refuse("wrong")
	match cmd.kind:
		&"rest":
			return _decide_rest(cmd.args)
		&"wake", &"fall":
			var socks := PackedInt32Array()
			var one: Variant = cmd.args.get("sock")
			var many: Variant = cmd.args.get("socks")
			if one is int:
				socks.append(one)
			elif many is PackedInt32Array:
				socks = many
			var p := _rows_onto({})
			for sock in socks:
				if state_of(sock) == State.LYING:
					_set_state(p, _row(p, sock), State.FLYING)
			if (p[ROWS] as PackedInt32Array).is_empty():
				return refuse("wrong")
			return grant(p)
		&"add":
			return _decide_add(cmd.args)
		&"take_out":
			return _decide_take_out(cmd.args)
	return refuse("wrong")


## `rest` (Host-only): the flights named lie at their places, in one rows patch; a Sock that does not
## fly now is left out; none flying, a refusal.
func _decide_rest(args: Dictionary) -> Dictionary:
	var socks: Variant = args.get("socks")
	var ats: Variant = args.get("ats")
	var rots: Variant = args.get("rots")
	var back: Variant = args.get("returned", PackedInt32Array())
	if not (socks is PackedInt32Array) or not (ats is PackedVector3Array) or not (rots is PackedVector3Array) \
			or not (back is PackedInt32Array) or (ats as PackedVector3Array).size() != (socks as PackedInt32Array).size() \
			or (rots as PackedVector3Array).size() != (socks as PackedInt32Array).size():
		return refuse("wrong")
	var p := {}
	var popped := PackedVector3Array()
	for i in (socks as PackedInt32Array).size():
		var sock: int = socks[i]
		if state_of(sock) != State.FLYING:
			continue
		var at: Vector3 = ats[i]
		p = lying_patch(sock, Transform3D(Basis.from_euler(rots[i]), at), p)
		if (back as PackedInt32Array).has(sock):
			popped.append(at)
	if p.is_empty():
		return refuse("wrong")
	var ev := grant(p)
	if not popped.is_empty():
		# core/16 P12b: a lost Sock came back; every machine hears a pop there (Hearing).
		ev[POPPED] = popped
	return ev


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
	var s := PackedByteArray()
	s.resize(n)
	s.fill(State.FLYING)
	var m := PackedInt32Array()
	m.resize(n)
	m.fill(-1)
	var launches := {}
	for i in n:
		launches[first + i] = {"vel": (vs as PackedVector3Array)[i], "spin": (ss as PackedVector3Array)[i], "by": NOBODY}
	return grant({ROWS: PackedInt32Array(range(first, first + n)), ROW_DESIGNS: add_designs, ROW_STATES: s,
			ROW_MATES: m, ROW_POSES: ps, LAUNCHES: launches, ROW_COUNT: first + n})


## `take_out` (Host-only): "socks" (PackedInt32Array): those lying or falling go GONE, a Pair only
## when both its Socks are named; held and shelved ones stay. Trailing GONE records are cut off.
func _decide_take_out(args: Dictionary) -> Dictionary:
	var named: Variant = args.get("socks")
	if not (named is PackedInt32Array):
		return refuse("wrong")
	var asked: Dictionary[int, bool] = {}
	for sock: int in named:
		asked[sock] = true
	var gone: Dictionary[int, bool] = {}
	for sock: int in named:
		if sock < 0 or sock >= count() or state_of(sock) not in [State.LYING, State.FLYING]:
			continue
		var mate := mate_of(sock)
		if mate >= 0 and not asked.has(mate):
			continue
		gone[sock] = true
		if mate >= 0:
			gone[mate] = true
	if gone.is_empty():
		return refuse("already")
	var keep := count()
	while keep > 0 and (gone.has(keep - 1) or states[keep - 1] == State.GONE):
		keep -= 1
	var p := _rows_onto({})
	for sock: int in gone:
		if sock < keep:
			_set_state(p, _row(p, sock), State.GONE)
			(p[LAUNCHES] as Dictionary).erase(sock)
	if keep != count():
		p[ROW_COUNT] = keep
	return grant(p)


## The lying Socks touching lying Sock `sock`, at most the tuning's wake_count (T11).
func touching(sock: int) -> PackedInt32Array:
	if _lying_bodies == null:
		return PackedInt32Array()
	return _lying_bodies.touching(sock, bodies_tuning().touch_margin, tuning.wake_count)


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
## all (the Hands draw them), a falling one as the Host's body, at once. Only the Socks whose record changed
## since the last time are touched, records added or cut off included; `now` shows every one.
func _show(now: bool) -> void:
	if not is_inside_tree():
		return
	if _lying_bodies == null:
		_drawing = MessDrawing.new(_container(lying) as Node3D, bodies_tuning())
		_lying_bodies = MessBodies.new(self, _drawing.sock_points(), bodies_tuning().min_thick)
		_watch_flights()
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
			# A record cut off the end (`take_out`).
			_take_down(sock)
			_moving.forget(sock)
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
			_take_down(sock)
		_moving.forget(sock)
	var started := false
	for sock in changed:
		match state_of(sock):
			State.LYING:
				_lie(sock)
			State.FLYING:
				# Every machine starts its own body, but for a Throw on a Guest (the spawner's copy).
				if _is_host() or not is_throw(sock):
					_moving.start(sock, woken.has(sock), _motion.get(sock, []))
					started = true
	if started:
		# Once for every body this change started (a thrown one has its Looks at once: its cloth
		# carries the hand's bend).
		give_looks()
	_shown_states = states.duplicate()
	_shown_poses = poses.duplicate()
	_drawing.flush()


## Sock `sock` no longer lies as it was shown: its lent Looks, its drawing and its body go.
func _take_down(sock: int) -> void:
	if _lent.has(sock):
		_lent[sock].queue_free()
		_lent.erase(sock)
	_drawing.undraw(sock)
	if _lying_bodies.has(sock):
		_lying_bodies.remove(sock)


## The Host: starts the Socks woken by a hit, a pick or a moving Door as the budget allows, and
## writes a fallen one lying where its body rests (M06: under the rest speed
## and spin for the rest time), or at the return spot when it left the bounds (T14) or would lie
## inside a wall (T08). A Guest: its moving Doors and drawers sweep its own lying Socks, looks only.
## Every machine: the flights nearest the camera get their Looks.
func _physics_process(delta: float) -> void:
	if _lying_bodies == null:
		return
	give_looks()
	if parts == null:
		return
	if _is_host():
		_moving.tick(delta)
	else:
		_moving.tick_looks(delta)


## Every machine, each frame: the flights with no Looks are drawn as instances where their bodies
## are. Nothing is built or uploaded while no Sock is drawn so (core/31).
func _process(_delta: float) -> void:
	if _drawing == null:
		return
	_drawing.flush()
	if _flight_by_sock.size() == _flight_looks.size() and not _flying_drawn:
		return
	var poses: Dictionary[StringName, Array] = {}
	var of: Dictionary[StringName, Array] = {}
	for sock: int in _flight_by_sock:
		var body := _flight_by_sock[sock]
		if _flight_looks.has(body) or body.is_queued_for_deletion() or _held_back.has(sock):
			continue
		var design := design_of(sock)
		var shape: StringName = _flight_shape.get(sock, &"")
		if shape == &"":
			shape = MessDrawing.shape_of(design, is_pair(sock))
			_flight_shape[sock] = shape
		if not poses.has(shape):
			poses[shape] = []
			of[shape] = []
		poses[shape].append(body.get_global_transform_interpolated().orthonormalized())
		of[shape].append(design)
	_drawing.draw_flying(poses, of)
	_flying_drawn = not poses.is_empty()


func _is_host() -> bool:
	return parts == null or parts.is_host()


## Whether this machine decides the Mess (the Host, or alone): a Guest's bodies are looks only.
func decides() -> bool:
	return _is_host()


## Whether flying Sock `sock` is a Throw (thrown by a player, not dropped, poured or woken): the one
## body that goes over the spawner (coop/09 streams it); every other is started on each machine.
func is_throw(sock: int) -> bool:
	var launch: Dictionary = throws.get(sock, {})
	return not launch.is_empty() and int(launch.get("by", NOBODY)) != NOBODY and not bool(launch.get("drop", false))


## A Guest's own sweep (coop/08): lying Sock `sock` is taken off the lying tier, its record as it
## is, while its looks-only body moves.
func lift(sock: int) -> void:
	if _lying_bodies != null and _lying_bodies.has(sock):
		_take_down(sock)


## A Guest's looks-only body of a Sock the Host never moved has ended: it lies again where its record
## says (B06).
func lie_again(sock: int) -> void:
	if _lying_bodies != null and state_of(sock) == State.LYING and not _lying_bodies.has(sock):
		_lie(sock)


## The stream's and the ghosts' numbers (a default when none is set).
func ghost_tuning() -> GhostTuning:
	if ghosts == null:
		ghosts = GhostTuning.new()
	return ghosts


## Looks only (a Guest's ghost, coop/09): while `on`, Sock `sock` is not drawn by the Mess, lying or
## flying (its body and record are as they are: it is aimed, picked and rested as ever), because a
## ghost draws it; let go, it is drawn as its record says, at once.
func hold_back(sock: int, on: bool) -> void:
	if on == _held_back.has(sock):
		return
	if on:
		_held_back[sock] = true
		if _drawing != null:
			_drawing.undraw(sock)
			_drawing.flush()
		if _lent.has(sock):
			_lent[sock].visible = false
	else:
		_held_back.erase(sock)
		if _lent.has(sock):
			_lent[sock].visible = true
		elif _drawing != null and state_of(sock) == State.LYING and _lying_bodies != null and _lying_bodies.has(sock):
			_draw_lying(sock)
			_drawing.flush()
	var body := moving_body(sock)
	var looks := body.get_node_or_null(LOOKS) as Node3D if body != null else null
	if looks != null:
		looks.visible = not on


## Whether Sock `sock` is held back from the Mess's drawing now (hold_back()).
func is_held_back(sock: int) -> bool:
	return _held_back.has(sock)


## The two tiers' numbers (a default when none is set).
func bodies_tuning() -> MessTuning:
	if bodies == null:
		bodies = MessTuning.new()
	return bodies


## A lying Sock gets its body where its record says, and is drawn there (a Pair as its ball).
func _lie(sock: int) -> void:
	var design := design_of(sock)
	var pair := is_pair(sock)
	_lying_bodies.place(sock, pose_of(sock), pair, SockDress.scale_of(design), SockDress.ball_radius(design))
	_draw_lying(sock)


func _draw_lying(sock: int) -> void:
	if _held_back.has(sock):
		return
	var design := design_of(sock)
	_drawing.draw(sock, pose_of(sock), MessDrawing.shape_of(design, is_pair(sock)), design)


## Every machine: while fewer than the cloth's flying_cap flights have a Looks (core/09), the
## nearest the camera without one gets it; none is taken from a flight that has one (no pop).
func give_looks() -> void:
	var cap := CLOTH_TUNING.flying_cap
	var have := 0
	for body: RigidBody3D in _flight_looks:
		if not body.is_queued_for_deletion():
			have += 1
	if have >= cap or _flight_by_sock.size() == _flight_looks.size():
		return
	var without: Array[RigidBody3D] = []
	for body in _flight_nodes():
		if not _flight_looks.has(body):
			without.append(body)
	if without.is_empty():
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
		if is_pair(sock):
			# core/16 P04: a falling Pair's drawn ball squashes, hops and squashes as it touches down.
			var landing := BallLanding.new()
			landing.name = "BallLanding"
			landing.tuning = BALL_LANDING
			landing.radius = SockDress.ball_radius(design_of(sock))
			looks.add_child(landing)
		looks.visible = not _held_back.has(sock)
		body.add_child(looks)
		_flight_looks[body] = true


## Where a Throw's body goes (the spawner's path in co-op).
func flight_holder() -> Node:
	return _container(flights)


## Where every other falling body goes (woken, fallen, poured, swept, dropped: no spawner sees it).
func bodies_holder() -> Node:
	return _bodies if _bodies != null else _container(flights)


## Every falling body on this machine (its own, and a Guest's spawned Throw copies).
func flight_bodies() -> Array[RigidBody3D]:
	return _flight_nodes()


## The lying Socks `shape` at `xform` overlaps, at most `most`.
func lying_overlapping(shape: Shape3D, xform: Transform3D, most: int) -> PackedInt32Array:
	return _lying_bodies.overlapping(shape, xform, most) if _lying_bodies != null else PackedInt32Array()


## The falling bodies under `flights` on this machine (the Host's own, or a Guest's spawned copies).
func _flight_nodes() -> Array[RigidBody3D]:
	var out: Array[RigidBody3D] = []
	for body: RigidBody3D in _flight_by_sock.values():
		if not body.is_queued_for_deletion():
			out.append(body)
	return out


## From now on the falling bodies are known as they enter and leave `flights` and this Mess's own
## holder (those there already too).
func _watch_flights() -> void:
	_flight_by_sock.clear()
	_flight_looks.clear()
	_flight_shape.clear()
	var holders: Array[Node] = [_container(flights)]
	if bodies_holder() != holders[0]:
		holders.append(bodies_holder())
	for holder in holders:
		if not holder.child_entered_tree.is_connected(_on_flight_in):
			holder.child_entered_tree.connect(_on_flight_in)
			holder.child_exiting_tree.connect(_on_flight_out)
		for child in holder.get_children():
			_on_flight_in(child)


func _on_flight_in(node: Node) -> void:
	var body := node as RigidBody3D
	if body == null or not String(body.name).begins_with(FLIGHT_PREFIX):
		return
	var sock := _sock_of_flight(body)
	if sock < 0:
		return
	if not _is_host() and not body.has_meta(SOCK_META):
		# coop/09: a Guest's spawned Throw copy never simulates (frozen, kinematic, on the looks layer);
		# its Row plays the Host's stamped rows 0.1 s behind. The Row and its Sync are added here, as
		# it enters and before it is ready, so the spawn's first row reaches it.
		body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		body.freeze = true
		body.collision_layer = LAYER_LOOKS
		body.collision_mask = 0
		FlightRow.attach(body, self, false)
	_flight_by_sock[sock] = body
	_flight_shape.erase(sock)
	if body.has_node(LOOKS):
		_flight_looks[body] = true


## A body that leaves: forgotten, unless a new body of the same Sock took its place already (a rest
## and a wake in one tick).
func _on_flight_out(node: Node) -> void:
	var body := node as RigidBody3D
	if body == null:
		return
	_flight_looks.erase(body)
	var sock := _sock_of_flight(body)
	if _flight_by_sock.get(sock) == body:
		_flight_by_sock.erase(sock)
		_flight_shape.erase(sock)


## The Sock a falling body is: its metadata (the Host's), else its name (a spawned copy).
func _sock_of_flight(body: RigidBody3D) -> int:
	if body.has_meta(SOCK_META):
		return int(body.get_meta(SOCK_META))
	var digits := String(body.name).trim_prefix(FLIGHT_PREFIX)
	return int(digits) if digits.is_valid_int() else -1


## The scale of a Sock of `design`, as a transform its pose is multiplied by.
static func _sized(design: SockDesign) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3.ONE * SockDress.scale_of(design)))


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
