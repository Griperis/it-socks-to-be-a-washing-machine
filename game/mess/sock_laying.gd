## One run of the Sock generator's laying (core/52): every area's Socks fitted to its places by rays and
## overlap tests in the physics space, no physics step (so the editor's preview and the game agree), then
## the trails. Each area draws from its own dice (the seed and its name), so changing one area never
## moves another's Socks; a later area only avoids the Socks of the ones before it. Places are fitted
## for the biggest Sock's box (SockGeneratorTuning.place_box), so the result does not depend on which
## Design takes a place. Designs and Mates come after (pair_up()).
##
## A row is {"pose": Transform3D (the Sock's box's bottom middle, its length along x), "kind": SockArea.Kind,
## "ground": where it would lie with nothing under it (its surface's height and the gap)}.
@tool
class_name SockLaying
extends RefCounted

## The cells of the hash of laid boxes (m) and of a Heap's height map (m).
const HASH := 0.5
const CELL := 0.04
## A Sock's ends are looked at this far along its half length.
const ENDS := 0.85
## How far a Sock lying along a place may turn off it (radians; old SockLayout: 0.2 under, 0.15 inside).
const ALONG_JITTER := 0.2
## A Heap's Socks may press this deep into each other (Jolt's slop, Q2499); a flat area's none.
const HEAP_PRESS := 0.02

var tuning: SockGeneratorTuning
## What the queries ask through (a node in the level's world).
var node: Node3D
## Every row laid so far.
var rows: Array[Dictionary] = []
## How many Socks were asked and how many found no place, by area name (for the log and the tests).
var asked := 0
var left_out: Dictionary[String, int] = {}
## Why tries failed, by "<kind>/<reason>" (the old SockLayout's report).
var fails: Dictionary[String, int] = {}
## How many Socks meant to hide found every hidden place full and went to open floor, by area name.
var hidden_to_floor: Dictionary[String, int] = {}
## The kind being tried (for the report).
var _trying := ""

## Laid boxes by hash cell: [size, middle's transform] each (with the boxes that were there before).
var _laid: Dictionary[Vector2i, Array] = {}
## The boxes that were there before (the Mess's other lying Socks, their real boxes).
var _before: Array[Array] = []
## A Heap's height map: the top of what lies over each CELL, by [floor bucket, cell x, cell z].
var _height: Dictionary[Vector3i, float] = {}
var _box := BoxShape3D.new()
var _rng := RandomNumberGenerator.new()


func _init(with: SockGeneratorTuning, query_node: Node3D, before: Array[Array]) -> void:
	tuning = with
	node = query_node
	_before = before
	for b: Array in before:
		_add_box(b[0], b[1])


## Lays `area`'s Socks (its places from SockPlaces), its dice from `seed`.
func lay_area(area: SockArea, places: SockPlaces, seed: int) -> void:
	_rng.seed = hash([seed, String(area.name)])
	var socks := area.pairs * 2
	asked += socks
	var hidden := roundi(socks * area.hidden_share) if not places.hidden_places.is_empty() else 0
	var open: Array[Dictionary] = places.top_places.duplicate()
	open.append_array(places.floor_places)
	var open_sums := _sums(open)
	var hidden_sums := _sums(places.hidden_places)
	var floor_sums := _sums(places.floor_places)
	var heaps: Array[Vector3] = []
	if area.heap and not places.floor_places.is_empty():
		var n := maxi(1, roundi(tuning.heaps_per_100 * (socks - hidden) / 100.0))
		for i in n:
			var cell: Dictionary = places.floor_places[_weighted(floor_sums)]
			heaps.append((cell["space"] as Transform3D).origin)
	var missed := 0
	for i in socks:
		var pose: Variant = null
		var place: Dictionary = {}
		var group: Array[Dictionary] = places.hidden_places if i < hidden else open
		var sums := hidden_sums if i < hidden else open_sums
		# Its place, then other places of its own kind of place (hidden or open), each tried a few times.
		for pick in tuning.repicks + 1:
			if pose != null or sums.is_empty():
				break
			place = group[_weighted(sums)]
			var in_heap: bool = place["kind"] == SockArea.Kind.FLOOR and not heaps.is_empty() and _rng.randf() < tuning.heap_share
			if in_heap:
				pose = _lay_in_heap(area, places, heaps[_rng.randi_range(0, heaps.size() - 1)])
			for t in tuning.tries:
				if pose != null:
					break
				pose = _fit(area, places, place, area.heap and place["kind"] == SockArea.Kind.FLOOR)
		# No room in its place: the open floor of its area, at an even draw.
		var floor_try := 0
		while pose == null and floor_try < tuning.floor_tries and not places.floor_places.is_empty():
			floor_try += 1
			place = places.floor_places[_rng.randi_range(0, places.floor_places.size() - 1)]
			pose = _fit(area, places, place, area.heap)
		if pose == null:
			missed += 1
			continue
		if i < hidden and place["kind"] == SockArea.Kind.FLOOR:
			hidden_to_floor[String(area.name)] = hidden_to_floor.get(String(area.name), 0) + 1
		rows.append({"pose": pose, "kind": place["kind"], "ground": _ground})
	if missed > 0:
		left_out[String(area.name)] = missed


## Lays a trail's Socks evenly from its foot to its top, each across the line.
func lay_trail(trail: SockTrail, seed: int, keep_out: Array[Array]) -> void:
	_rng.seed = hash([seed, String(trail.name)])
	var ends := trail.ends()
	var line := ends[1] - ends[0]
	var flat_dir := Vector3(line.x, 0.0, line.z).normalized()
	if flat_dir.length_squared() < 0.5:
		flat_dir = Vector3.FORWARD
	var across := flat_dir.cross(Vector3.UP).normalized()
	asked += trail.socks
	var missed := 0
	for j in trail.socks:
		var at := ends[0] + line * ((j + 0.5) / float(trail.socks))
		var pose: Variant = null
		_trying = "TRAIL"
		for t in tuning.tries:
			var off := 0.0 if t == 0 else _rng.randf_range(-trail.spread, trail.spread)
			var p := at + across * off
			var yaw := atan2(-across.z, across.x) + _rng.randf_range(-0.15, 0.15) + (PI if _rng.randf() < 0.5 else 0.0)
			pose = _rest(p + Vector3.UP * 1.0, p + Vector3.DOWN * 1.0, yaw, NAN, keep_out, false, true)
			if pose != null:
				break
		if pose == null:
			missed += 1
			continue
		rows.append({"pose": pose, "kind": SockArea.Kind.TRAIL, "ground": _ground})
	if missed > 0:
		left_out[String(trail.name)] = missed


## Gives the rows' Socks their Pairs (Q2525): each Pair's two rows about a Mate distance apart in a
## straight line, from `mate_min` for the first Pair to `mate_max` for the last (a shuffled order), the
## longest placed first, its mate the best of `mate_tries` free rows. Returns [row a, row b] per Pair;
## an odd row is left out.
func pair_up(seed: int) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "mates"])
	var n := rows.size() / 2
	var dists: Array[float] = []
	for k in n:
		dists.append(lerpf(tuning.mate_min, tuning.mate_max, float(k) / maxf(1.0, n - 1.0)))
	for k in range(n - 1, 0, -1):
		var j := rng.randi_range(0, k)
		var tmp := dists[k]
		dists[k] = dists[j]
		dists[j] = tmp
	var order: Array[int] = []
	for k in n:
		order.append(k)
	order.sort_custom(func(a: int, b: int) -> bool: return dists[a] > dists[b] or (dists[a] == dists[b] and a < b))
	var free: Array[int] = []
	for i in rows.size():
		free.append(i)
	var out: Array[Vector2i] = []
	out.resize(n)
	for k in order:
		var a := _take(free, rng.randi_range(0, free.size() - 1))
		var at := (rows[a]["pose"] as Transform3D).origin
		var best := -1
		var best_err := INF
		for t in mini(tuning.mate_tries, free.size()):
			var c := rng.randi_range(0, free.size() - 1)
			var err := absf(at.distance_to((rows[free[c]]["pose"] as Transform3D).origin) - dists[k])
			if err < best_err:
				best_err = err
				best = c
				if err < tuning.mate_slack:
					break
		out[k] = Vector2i(a, _take(free, best))
	return out


## One try at `place`: a random point of it, turned at random (or along it), rested on what the rays find.
func _fit(_area: SockArea, places: SockPlaces, place: Dictionary, heap: bool) -> Variant:
	_trying = SockArea.Kind.keys()[int(place["kind"])]
	var rect: Rect2 = place["rect"]
	var space: Transform3D = place["space"]
	var along: float = place["along"]
	var yaw_local := _rng.randf() * TAU
	if along >= 0.0:
		yaw_local = along + _rng.randf_range(-ALONG_JITTER, ALONG_JITTER) + (PI if _rng.randf() < 0.5 else 0.0)
	var half := tuning.place_box * 0.5
	if place["kind"] == SockArea.Kind.INSIDE:
		# Its whole turned box within the inside's floor plan (clear of the walls).
		var e := Vector2(absf(cos(yaw_local)) * half.x + absf(sin(yaw_local)) * half.z, absf(sin(yaw_local)) * half.x + absf(cos(yaw_local)) * half.z)
		var inner := rect.grow_individual(-e.x, -e.y, -e.x, -e.y)
		if inner.size.x < 0.0 or inner.size.y < 0.0:
			return _fail("too_long")
		rect = inner
	var q := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
	var yaw := yaw_local + _yaw_of(space.basis)
	var from := space * Vector3(q.x, float(place["from"]), q.y)
	var to := space * Vector3(q.x, -SockPlaces.RAY_DOWN, q.y)
	return _rest(from, to, yaw, space.origin.y, places.keep_out, heap, false)


## A Heap Sock: near a Heap's middle (a normal spread), rolled down the Heap where it is steeper than
## the repose, onto open floor only.
func _lay_in_heap(area: SockArea, places: SockPlaces, middle: Vector3) -> Variant:
	_trying = "HEAP"
	var off := Vector3(_rng.randfn(0.0, 1.0), 0.0, _rng.randfn(0.0, 1.0)) * tuning.heap_spread
	var p := middle + off
	var floor_y := middle.y
	if not _open(area, places, p):
		p = middle
	var bucket := roundi(floor_y * 10.0)
	var here := _heap_at(bucket, p, floor_y)
	for step in tuning.roll_steps:
		if here <= floor_y + 0.001:
			break
		var turn := _rng.randf() * TAU
		var lower: Array[Array] = []
		for k in 6:
			var dir := Vector3(cos(turn + k * TAU / 6.0), 0.0, sin(turn + k * TAU / 6.0))
			var c := p + dir * tuning.roll
			var h := _heap_at(bucket, c, floor_y)
			if h < here - tuning.roll * tuning.repose and _open(area, places, c):
				lower.append([h, c])
		if lower.is_empty():
			break
		lower.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		p = lower[0][1]
		here = float(lower[0][0])
	var yaw := _rng.randf() * TAU
	return _rest(Vector3(p.x, floor_y + SockPlaces.FLOOR_RAY, p.z), Vector3(p.x, floor_y - SockPlaces.RAY_DOWN, p.z),
			yaw, floor_y, places.keep_out, true, false)


## Whether level point `p` lies in one of the area's open floor cells.
func _open(area: SockArea, places: SockPlaces, p: Vector3) -> bool:
	var g := tuning.floor_grid
	var local := area.global_transform.affine_inverse() * p
	var nx := maxi(1, floori(area.size.x / g))
	var nz := maxi(1, floori(area.size.z / g))
	var cell := Vector2i(floori((local.x + nx * g * 0.5) / g), floori((local.z + nz * g * 0.5) / g))
	return places.cells.has(cell)


## Rests a Sock turned `yaw` on what a ray from `from` to `to` finds (and two more under its ends): its
## pose, or null when it would hang, lie off its place's surface `rest` (NAN: anywhere), meet the house,
## a box kept clear or another Sock. `heap`: it may lie on the Socks under it (the height map).
## `trail`: it lies along a slope up to the trail's tilt instead of flat.
func _rest(from: Vector3, to: Vector3, yaw: float, rest: float, keep_out: Array[Array], heap: bool, trail: bool) -> Variant:
	var mid := PhysicsQueries.ray(node, from, to, Mess.LAYER_HOUSE)
	if mid.is_empty():
		return _fail("no_surface")
	var hit: Vector3 = mid["position"]
	var normal: Vector3 = (mid["normal"] as Vector3).normalized()
	if not is_nan(rest) and absf(hit.y - rest) > tuning.rest_slack:
		return _fail("off_surface")
	var up := Vector3.UP
	if trail:
		if normal.y < cos(deg_to_rad(tuning.trail_tilt)):
			return _fail("steep")
		up = normal
	elif normal.y < SockPlaces.FLAT:
		return _fail("steep")
	var length := Basis(Vector3.UP, yaw) * Vector3.RIGHT
	length = (length - up * length.dot(up)).normalized()
	var basis := Basis(length, up, length.cross(up)).orthonormalized()
	var half := tuning.place_box * 0.5
	if not trail:
		for s: float in [-1.0, 1.0]:
			var e := hit + length * half.x * ENDS * s
			var end_hit := PhysicsQueries.ray(node, Vector3(e.x, from.y, e.z), Vector3(e.x, to.y, e.z), Mess.LAYER_HOUSE)
			if end_hit.is_empty() or absf((end_hit["position"] as Vector3).y - hit.y) > tuning.end_step:
				return _fail("hangs")
	var y := hit.y
	var bucket := roundi(hit.y * 10.0)
	if heap:
		y = maxf(y, _support(basis, hit))
		if y - hit.y > tuning.heap_max:
			return _fail("heap_full")
	var pose := Transform3D(basis, Vector3(hit.x, y, hit.z) + up * tuning.gap)
	var centre := pose * Transform3D(Basis.IDENTITY, Vector3(0.0, half.y, 0.0))
	# The house: the box lifted a little off what holds it.
	_box.size = tuning.place_box - Vector3(0.004, 0.004, 0.004)
	var lifted := Transform3D(centre.basis, centre.origin + up * 0.003)
	if not PhysicsQueries.overlap_colliders(node, _box, lifted, Mess.LAYER_HOUSE, 1).is_empty():
		return _fail("house")
	for k: Array in keep_out:
		if MessBodies.boxes_meet(tuning.place_box, centre, k[0], k[1]):
			return _fail("kept_out")
	if _meets_laid(centre, heap):
		return _fail("sock")
	_add_box(tuning.place_box, centre)
	_mark(bucket, basis, pose)
	_ground = hit.y + tuning.gap
	return pose


## A try failed for `why` (counted by the kind being tried); null.
func _fail(why: String) -> Variant:
	var key := "%s/%s" % [_trying, why]
	fails[key] = fails.get(key, 0) + 1
	return null


## Whether a box at `centre` meets a Sock laid before (closer than the spacing for a flat area; deeper
## than a Heap's press in a Heap).
func _meets_laid(centre: Transform3D, heap: bool) -> bool:
	var spacing := 0.0 if heap else _spacing
	var size := tuning.place_box + Vector3(spacing * 2.0, 0.0, spacing * 2.0)
	var c := _hash_cell(centre.origin)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for b: Array in _laid.get(c + Vector2i(dx, dz), []):
				var depth := MessBodies.overlap_depth(size, centre, b[0], b[1])
				if depth > (HEAP_PRESS if heap else 0.0):
					return true
	return false


## The spacing of the area being laid (set by the generator before each area).
var _spacing := 0.0
## The height the last rested Sock would have with nothing under it (its row's "ground").
var _ground := 0.0


## Once each row's Sock is known (core/55, Q2531): a Heap's Socks were stacked on the place box,
## the biggest Sock's, so a smaller Sock under one, or one whose leg and foot miss the one above, left
## it hanging. Each stacked row (in the order laid) comes down onto the leg and foot boxes under it
## (`parts`, one list per row: MessBodies.parts_at its Size, [size, centre] in its own space; empty:
## a row not laid), or to its ground; x, z and its turn stay. A row only ever comes down (its boxes lie
## inside the place box), so it meets nothing it did not meet before.
func restack(parts: Array[Array]) -> void:
	for i in rows.size():
		var pose: Transform3D = rows[i]["pose"]
		var ground: float = rows[i]["ground"]
		if pose.origin.y <= ground + 0.0005:
			continue
		var y := ground
		for j in i:
			var other: Transform3D = rows[j]["pose"]
			if absf(float(rows[j]["ground"]) - ground) > 0.05 or other.origin.y >= pose.origin.y:
				continue
			for pj: Array in parts[j]:
				var under := other * Transform3D(Basis.IDENTITY, pj[1])
				var size_j: Vector3 = pj[0]
				if _over(pose, parts[i], under, size_j):
					y = maxf(y, under.origin.y + size_j.y * 0.5 + tuning.gap)
		for b: Array in _before:
			var middle: Transform3D = b[1]
			var size: Vector3 = b[0]
			var bottom := middle.origin.y - size.y * 0.5
			if bottom < ground - 0.05 or bottom >= pose.origin.y:
				continue
			if _over(pose, parts[i], middle, size):
				y = maxf(y, middle.origin.y + size.y * 0.5 + tuning.gap)
		rows[i]["pose"] = Transform3D(pose.basis, Vector3(pose.origin.x, minf(y, pose.origin.y), pose.origin.z))


## Whether a Sock at `pose` made of `parts` lies over (its footprint meets) the box `size` at `middle`.
static func _over(pose: Transform3D, parts: Array, middle: Transform3D, size: Vector3) -> bool:
	var flat := Vector3(size.x, 0.001, size.z)
	for part: Array in parts:
		var at := pose * Transform3D(Basis.IDENTITY, part[1])
		at.origin.y = middle.origin.y
		var tall := Vector3((part[0] as Vector3).x, 20.0, (part[0] as Vector3).z)
		if MessBodies.boxes_meet(tall, at, flat, middle):
			return true
	return false


## Sets the spacing two Socks of the next area keep.
func set_spacing(spacing: float) -> void:
	_spacing = spacing


func _add_box(size: Vector3, centre: Transform3D) -> void:
	var c := _hash_cell(centre.origin)
	if not _laid.has(c):
		_laid[c] = []
	_laid[c].append([size, centre])


func _hash_cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / HASH), floori(p.z / HASH))


## The top of the highest laid Sock whose box a Sock turned `basis` at `at` would lie over (a Heap
## Sock rests on it, flat).
func _support(basis: Basis, at: Vector3) -> float:
	var top := -INF
	var tall := Vector3(tuning.place_box.x, 20.0, tuning.place_box.z)
	var c := _hash_cell(at)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for b: Array in _laid.get(c + Vector2i(dx, dz), []):
				var other: Transform3D = b[1]
				if other.origin.y < at.y - 0.05:
					continue
				if MessBodies.boxes_meet(tall, Transform3D(basis, Vector3(at.x, other.origin.y, at.z)), b[0], other):
					top = maxf(top, other.origin.y + (b[0] as Vector3).y * 0.5)
	return top


## The highest the height map holds under a Sock's footprint (turned `basis`, its middle at `at`) on `bucket`.
func _footprint_top(bucket: int, basis: Basis, at: Vector3) -> float:
	var top := -INF
	for cell in _cells_under(basis, at):
		top = maxf(top, _height.get(Vector3i(bucket, cell.x, cell.y), -INF))
	return top


## A laid Sock's top over every cell under it (grown by half a cell, so a later one finds it).
func _mark(bucket: int, basis: Basis, pose: Transform3D) -> void:
	var top := pose.origin.y + tuning.place_box.y
	for cell in _cells_under(basis, pose.origin):
		var key := Vector3i(bucket, cell.x, cell.y)
		_height[key] = maxf(_height.get(key, -INF), top)


func _cells_under(basis: Basis, at: Vector3) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var half := tuning.place_box * 0.5 + Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	var ax := Vector2(basis.x.x, basis.x.z).normalized()
	var az := Vector2(basis.z.x, basis.z.z).normalized()
	var reach := Vector2(half.x, half.z).length()
	for cx in range(floori((at.x - reach) / CELL), floori((at.x + reach) / CELL) + 1):
		for cz in range(floori((at.z - reach) / CELL), floori((at.z + reach) / CELL) + 1):
			var d := Vector2((cx + 0.5) * CELL - at.x, (cz + 0.5) * CELL - at.z)
			if absf(d.dot(ax)) <= half.x and absf(d.dot(az)) <= half.z:
				out.append(Vector2i(cx, cz))
	return out


## The heap's height round point `p` (its cell and a hand's breadth round it), at least the floor.
func _heap_at(bucket: int, p: Vector3, floor_y: float) -> float:
	var h := floor_y
	for off: Vector2 in [Vector2.ZERO, Vector2(0.08, 0.0), Vector2(-0.08, 0.0), Vector2(0.0, 0.08), Vector2(0.0, -0.08)]:
		h = maxf(h, _height.get(Vector3i(bucket, floori((p.x + off.x) / CELL), floori((p.z + off.y) / CELL)), -INF))
	return h


static func _yaw_of(basis: Basis) -> float:
	return atan2(-basis.x.z, basis.x.x)


func _weighted(sums: PackedFloat64Array) -> int:
	return mini(sums.bsearch(_rng.randf() * sums[-1]), sums.size() - 1)


static func _sums(places: Array[Dictionary]) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	var total := 0.0
	for p in places:
		total += maxf(float(p["weight"]), 0.0)
		out.append(total)
	if total <= 0.0:
		return PackedFloat64Array()
	return out


static func _take(pool: Array[int], k: int) -> int:
	var out := pool[k]
	pool[k] = pool[-1]
	pool.pop_back()
	return out
