## The spray of Socks out of the washing machine's door (core/89, run-ends.md "The spray"; the old
## FirstWashSpit): a large spill of real Sock meshes (the Looks' own, LOD folded) in Designs drawn from
## the catalogue with the tuning's seed, so every machine draws the same one; one MultiMesh per
## Collection; no physics (the old step: gravity, a bounce, then lying flat); gone when the effect ends.
## Looks only: decoration that decides nothing and writes nothing. The door's swing is the washer's.
class_name SockSpray
extends Node3D

## The effect is over (its length ran out); its Socks are already gone.
signal finished

@export var tuning: SockSprayTuning
## The Designs the spray draws from: a new Design shows with no change.
@export var catalogue: DesignCatalogue

var playing := false
var elapsed := 0.0

## Parallel arrays, one entry per Sock: its MultiMesh and row in it, when it leaves, where it is, its
## velocity, spin, turn, size, whether it has left and whether it lies still.
var _mm: Array[MultiMesh] = []
var _row := PackedInt32Array()
var _at := PackedFloat32Array()
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _spin := PackedVector3Array()
var _basis: Array[Basis] = []
var _scale := PackedFloat32Array()
var _still := PackedByteArray()
var _launched := PackedByteArray()
## The mesh's place in its Looks, per MultiMesh.
var _mesh_at: Dictionary[MultiMesh, Transform3D] = {}
var _holders: Array[MultiMeshInstance3D] = []
var _floor_y := 0.0


func _ready() -> void:
	set_process(false)


## Sprays from `from` (the door's middle, world space) out along `forward`, over a floor at `floor_y`.
func play(from: Vector3, forward: Vector3, floor_y: float) -> void:
	stop()
	_floor_y = floor_y
	var rng := RandomNumberGenerator.new()
	rng.seed = tuning.seed
	var fwd := Vector3(forward.x, 0.0, forward.z).normalized()
	var right := fwd.cross(Vector3.UP)
	var n := tuning.count
	var designs := _designs()
	var picks: Array[SockDesign] = []
	for i in n:
		picks.append(designs[rng.randi() % designs.size()] if not designs.is_empty() else null)
	# One MultiMesh per Collection, in the order each is first drawn.
	var made: Dictionary[StringName, Array] = {}
	var counts: Dictionary[StringName, int] = {}
	for d in picks:
		var key := _key(d)
		counts[key] = counts.get(key, 0) + 1
	for key in counts:
		var first := _first_of(picks, key)
		var found := MessDrawing.body_mesh(SockLook.scene(first))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = found[0]
		mm.instance_count = counts[key]
		var holder := MultiMeshInstance3D.new()
		holder.name = "Spray_%s" % String(key)
		holder.multimesh = mm
		holder.material_override = SockLook.instance_material(SockLook.collection_of(first))
		holder.top_level = true
		holder.custom_aabb = AABB(from - Vector3.ONE * 8.0, Vector3.ONE * 16.0)
		holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(holder)
		_holders.append(holder)
		_mesh_at[mm] = found[1]
		made[key] = [mm, 0]
	for i in n:
		var d := picks[i]
		var entry := made[_key(d)]
		var mm: MultiMesh = entry[0]
		var k: int = entry[1]
		entry[1] = k + 1
		var yaw := deg_to_rad(rng.randf_range(-1.0, 1.0) * tuning.spread_deg)
		var pitch := deg_to_rad(tuning.up_deg + rng.randf_range(-1.0, 1.0) * tuning.spread_deg * 0.5)
		var dir := (fwd * cos(yaw) + right * sin(yaw)) * cos(pitch) + Vector3.UP * sin(pitch)
		var speed := tuning.speed * (1.0 + rng.randf_range(-1.0, 1.0) * tuning.speed_jitter)
		_mm.append(mm)
		_row.append(k)
		_at.append(tuning.window * float(i) / float(maxi(n, 1)))
		_pos.append(from)
		_vel.append(dir * speed)
		_spin.append(Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * tuning.spin)
		_basis.append(Basis(Vector3.UP, rng.randf() * TAU))
		_scale.append(SockDress.scale_of(d))
		_still.append(0)
		_launched.append(0)
		mm.set_instance_color(k, d.colour if d != null else Color(0.9, 0.5, 0.5))
		mm.set_instance_custom_data(k, MessDrawing.look_data(d))
		# Hidden (no size) until it leaves the door.
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ZERO), from))
	elapsed = 0.0
	playing = true
	set_process(true)


## The Socks gone, the effect off.
func stop() -> void:
	playing = false
	set_process(false)
	for h in _holders:
		h.queue_free()
	_holders.clear()
	_mm.clear()
	_mesh_at.clear()
	_row.clear()
	_at.clear()
	_pos.clear()
	_vel.clear()
	_spin.clear()
	_basis.clear()
	_scale.clear()
	_still.clear()
	_launched.clear()


## How many Socks have left the door by now.
func flown() -> int:
	var k := 0
	for v in _launched:
		k += v
	return k


## How many Socks lie on the floor, still.
func landed() -> int:
	var k := 0
	for v in _still:
		k += v
	return k


## How many Socks are drawn in all (the MultiMeshes' instances).
func drawn() -> int:
	var k := 0
	for h in _holders:
		k += h.multimesh.instance_count
	return k


## How many MultiMeshes draw the spray (one per Collection).
func groups() -> int:
	return _holders.size()


## The Socks' places now, in order.
func positions() -> PackedVector3Array:
	return _pos


## Sock `i`'s place now.
func position_of(i: int) -> Vector3:
	return _pos[i]


func _process(delta: float) -> void:
	advance(delta)


## The spray goes on by `delta` seconds (a test steps it by hand).
func advance(delta: float) -> void:
	if not playing:
		return
	elapsed += delta
	for i in _pos.size():
		if _still[i] != 0 or elapsed < _at[i]:
			continue
		_launched[i] = 1
		var vel := _vel[i]
		var pos := _pos[i]
		vel.y -= tuning.gravity * delta
		pos += vel * delta
		var b := _basis[i]
		var sp := _spin[i]
		b = b.rotated(Vector3.RIGHT, sp.x * delta).rotated(Vector3.BACK, sp.z * delta).orthonormalized()
		if pos.y <= _floor_y:
			pos.y = _floor_y
			if vel.y < 0.0:
				vel.y = -vel.y * tuning.bounce
				vel.x *= tuning.floor_grip
				vel.z *= tuning.floor_grip
				if vel.y < tuning.rest_speed:
					vel = Vector3.ZERO
					_still[i] = 1
					# It lies flat where it landed, turned the way it was heading.
					b = Basis(Vector3.UP, b.get_euler().y)
		_vel[i] = vel
		_pos[i] = pos
		_basis[i] = b
		var mm := _mm[i]
		mm.set_instance_transform(_row[i], Transform3D(b.scaled(Vector3.ONE * _scale[i]), pos) * _mesh_at[mm])
	if elapsed >= tuning.length:
		stop()
		finished.emit()


func _designs() -> Array[SockDesign]:
	var out: Array[SockDesign] = []
	if catalogue == null:
		return out
	for id in catalogue.size():
		var d := catalogue.design(id)
		if d != null:
			out.append(d)
	return out


func _key(design: SockDesign) -> StringName:
	return MessDrawing.shape_of(design, false)


func _first_of(picks: Array[SockDesign], key: StringName) -> SockDesign:
	for d in picks:
		if _key(d) == key:
			return d
	return null
