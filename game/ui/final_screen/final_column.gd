## One player's column on the Final screen (run-ends.md "The Final screen"; the old ending_screen.gd's column): the
## name in the player's colour, the Coins icon and score, "n / total Pairs", "+N bonus", and a Sock stage where the
## Pairs that player shelved pop in one by one as Sock previews (a Sock of the Pair's Design seen from above, fitted
## to its grid cell, in shelving order). The screen steps it on a clock; it plays nothing itself but says which
## sound it wants (`cue`). One MultiMesh per Collection draws the previews, as the Sock spray does.
class_name FinalColumn
extends PanelContainer

## A sound of the screen's is wanted: a SoundEvent name.
signal cue(event: StringName)

## Pixels of the stage's picture that make a metre (the camera's size follows).
const PPM := 220.0
const CAMERA_HEIGHT := 3.0
const PAD := 12.0

static var _spark_material: StandardMaterial3D = null

var tuning: FinalScreenTuning = null
## The player's colour, name and Pairs ([[Design id, Coins paid], ...]) and the Coins they earned.
var colour := Color.WHITE
var player_name := ""
var pairs: Array = []
var earned := 0
var catalogue: DesignCatalogue = null
var stage_size := Vector2(300, 400)
## When each Pair pops, and when the column is done (seconds on the screen's clock).
var times := PackedFloat32Array()
var end := 0.0
## How many Pairs have popped, how many have landed, the score on show and the one it counts toward.
var shown := 0
var settled := 0
var score := 0.0
var target := 0

var _designs: Array[SockDesign] = []
var _mm: Array[MultiMesh] = []
var _row: Array[int] = []
var _rest: Array[Vector3] = []
var _fit: Array[float] = []
var _mesh_at: Dictionary[MultiMesh, Transform3D] = {}
var _centre: Dictionary[MultiMesh, Vector3] = {}
var _bonus := 0

@onready var _name: Label = %Name
@onready var _score: Label = %Score
@onready var _count: Label = %Count
@onready var _bonus_label: Label = %Bonus
@onready var _stage: SubViewportContainer = %Socks
@onready var _viewport: SubViewport = %Stage
@onready var _camera: Camera3D = %Camera
@onready var _root: Node3D = %SockRoot


## Fills the column from `entry` (a FinalSummary column) and lays the Pairs out; call it before it enters the tree.
func setup(entry: Dictionary, size_of_stage: Vector2, tune: FinalScreenTuning, designs: DesignCatalogue) -> void:
	tuning = tune
	catalogue = designs
	stage_size = size_of_stage
	colour = entry["colour"]
	player_name = String(entry["name"])
	pairs = entry["pairs"]
	earned = int(entry["earned"])
	var paid := 0
	for p: Array in pairs:
		paid += int(p[1])
	_bonus = maxi(0, earned - paid)


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(colour, 0.22)
	style.border_color = colour
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size.x = stage_size.x + PAD * 2.0
	_name.text = player_name
	(%Coins as TextureRect).texture = UiIcons.texture("coins")
	_name.add_theme_color_override("font_color", colour)
	_stage.custom_minimum_size = stage_size
	_viewport.size = Vector2i(stage_size)
	_camera.size = stage_size.y / PPM
	_place_socks()
	_schedule()
	_refresh_labels()


## The seconds each Pair pops at (Q1844): the first after `start_delay`, then the gap before the next shrinks from
## `first_gap` to `fast_gap` over `ramp_pairs` Pairs (slow, then a fast stream); a rare Pair adds `rare_pause`.
## `rare` is true for each Pair that is a rare Design.
static func schedule(rare: Array, t: FinalScreenTuning) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var at := t.start_delay
	var ramp := float(maxi(t.ramp_pairs, 1))
	for k in rare.size():
		out.append(at)
		var s := clampf(k / ramp, 0.0, 1.0)
		s = s * s * (3.0 - 2.0 * s)
		at += lerpf(t.first_gap, t.fast_gap, s)
		if bool(rare[k]):
			at += t.rare_pause
	return out


## The grid that fits `n` cells into `w` x `h` best: Vector3(columns, rows, the cell's side in pixels).
static func grid(n: int, w: float, h: float) -> Vector3:
	var best := Vector3(1, maxi(n, 1), 0.0)
	for cols in range(1, maxi(n, 1) + 1):
		var rows := (n + cols - 1) / cols
		var cell := minf(w / cols, h / rows)
		if cell > best.z:
			best = Vector3(cols, rows, cell)
	return best


## Whether Pair `k` is of a rare Design.
func is_rare(k: int) -> bool:
	return _designs[k].rarity >= SockDesign.Rarity.RARE


## The text of the count line now ("3 / 12 Pairs", empty for a column with no Pairs) and of the bonus.
func count_text() -> String:
	return _count.text


func bonus_text() -> String:
	return _bonus_label.text


func score_text() -> String:
	return _score.text


func name_text() -> String:
	return _name.text


func bonus() -> int:
	return _bonus


## Every Pair's preview is a hidden instance of its Collection's MultiMesh until it pops.
func _place_socks() -> void:
	var g := grid(pairs.size(), stage_size.x, stage_size.y)
	var cols := int(g.x)
	var cell := g.z
	var rows := int(g.y)
	var origin := (stage_size - Vector2(cols * cell, rows * cell)) * 0.5
	var counts: Dictionary[StringName, int] = {}
	var made: Dictionary[StringName, MultiMesh] = {}
	for p: Array in pairs:
		var d := catalogue.design(int(p[0]))
		_designs.append(d)
		counts[d.collection] = counts.get(d.collection, 0) + 1
	var next: Dictionary[StringName, int] = {}
	for k in pairs.size():
		var d := _designs[k]
		if not made.has(d.collection):
			var found := MessDrawing.body_mesh(SockLook.scene(d))
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.use_custom_data = true
			mm.mesh = found[0]
			mm.instance_count = counts[d.collection]
			var holder := MultiMeshInstance3D.new()
			holder.name = "Socks_%s" % String(d.collection)
			holder.multimesh = mm
			holder.material_override = SockLook.instance_material(d.collection)
			holder.custom_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 4, 40))
			_root.add_child(holder)
			made[d.collection] = mm
			_mesh_at[mm] = found[1]
			var box: AABB = (mm.mesh as Mesh).get_aabb()
			var middle: Vector3 = (found[1] as Transform3D) * box.get_center()
			_centre[mm] = Vector3(middle.x, 0.0, middle.z)
		var m := made[d.collection]
		var row: int = next.get(d.collection, 0)
		next[d.collection] = row + 1
		var long := ((m.mesh as Mesh).get_aabb().size * 1.0)
		var wide := maxf(maxf(long.x, long.z), 0.01)
		var fit := minf(1.0, (cell * 0.86 / PPM) / wide)
		fit = minf(fit * d.size_scale(), cell * 0.95 / PPM / wide)
		var mid := origin + Vector2((k % cols) + 0.5, (k / cols) + 0.5) * cell
		_mm.append(m)
		_row.append(row)
		_fit.append(fit)
		_rest.append(Vector3((mid.x - stage_size.x * 0.5) / PPM, 0.0, (mid.y - stage_size.y * 0.5) / PPM))
		m.set_instance_color(row, d.colour)
		m.set_instance_custom_data(row, MessDrawing.look_data(d))
		m.set_instance_transform(row, Transform3D(Basis.from_scale(Vector3.ZERO), _rest[k]))


## The pop times and when this column is done.
func _schedule() -> void:
	var rare: Array = []
	for k in pairs.size():
		rare.append(is_rare(k))
	times = schedule(rare, tuning)
	end = tuning.start_delay if times.is_empty() else times[times.size() - 1] + tuning.pop_time


## Moves the column to second `clock` of the screen's clock, `delta` after the last step. `silent`: nothing is
## said and nothing sparkles (a skip).
func advance(clock: float, delta: float, silent := false) -> void:
	var pop := maxf(tuning.pop_time, 0.01)
	while shown < pairs.size() and times[shown] <= clock:
		var k := shown
		target += int(pairs[k][1])
		if not silent:
			if is_rare(k):
				_sparkle(_rest[k], colour, 0.9)
				cue.emit(&"final_rare")
			else:
				cue.emit(&"final_pop")
		shown += 1
	var fly := tuning.fly_from * stage_size.y / PPM
	for k in range(settled, shown):
		var age := (clock - times[k]) / pop
		if age >= 1.0:
			_place(k, _rest[k], 1.0, 0.0)
			if k == settled:
				settled += 1
			continue
		_place(k, _rest[k] + Vector3(0, 0, -fly * (1.0 - _ease_out(age))), maxf(_back_out(age), 0.01), (1.0 - age) * 1.2)
	while settled < shown and clock - times[settled] >= pop:
		settled += 1
	if shown >= pairs.size():
		target = earned  # the bonuses (floors, batches, refunds) land after the last Pair
	_count_score(delta, silent)


## Everything in place at once: every Pair landed, the score final.
func finish() -> void:
	advance(INF, 0.0, true)
	for k in range(0, pairs.size()):
		_place(k, _rest[k], 1.0, 0.0)
	settled = pairs.size()
	score = float(target)
	_refresh_labels()


## A burst of the finale over the stage.
func burst(at: Vector3, count: int, tint: Color, spread: float) -> void:
	_spark(at, count, 0.05, spread, 1.4, tint)


## A width of the stage in metres, a height in metres (the finale throws bursts in them).
func stage_metres() -> Vector2:
	return stage_size / PPM


func _count_score(delta: float, silent: bool) -> void:
	if score < target:
		var before := int(score)
		var step := maxf(float(target) - score, 1.0) * minf(1.0, delta * tuning.count_speed)
		score = minf(float(target), score + maxf(step, 1.0 * delta))
		if int(score) != before and not silent:
			cue.emit(&"final_tick")
	_refresh_labels()


func _refresh_labels() -> void:
	if _score == null:
		return
	_score.text = str(int(score))
	_count.text = "%d / %d Pairs" % [shown, pairs.size()] if not pairs.is_empty() else ""
	_bonus_label.text = ("+%d bonus" % _bonus) if shown >= pairs.size() and _bonus > 0 else ""


func _place(k: int, at: Vector3, scale: float, turn: float) -> void:
	var m := _mm[k]
	var basis := Basis(Vector3.UP, turn).scaled(Vector3.ONE * _fit[k] * scale)
	var local := Transform3D(Basis.IDENTITY, -_centre[m]) * _mesh_at[m]
	m.set_instance_transform(_row[k], Transform3D(basis, at) * local)


static func _back_out(k: float) -> float:
	var c := 1.70158
	return 1.0 + (c + 1.0) * pow(k - 1.0, 3.0) + c * pow(k - 1.0, 2.0)


static func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)


## A sparkle at `at` in the stage, in the player's colour mixed with gold.
func _sparkle(at: Vector3, tint: Color, scale: float) -> void:
	_spark(at, 18, 0.03 * scale, 0.5 * scale, 0.7, tint.lerp(Color(1.0, 0.8, 0.4), 0.6))


## One-shot bits thrown from `at`, drawn flat to the camera; they free themselves.
func _spark(at: Vector3, count: int, size: float, spread: float, life: float, tint: Color) -> void:
	if _spark_material == null:
		_spark_material = StandardMaterial3D.new()
		_spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_spark_material.vertex_color_use_as_albedo = true
		_spark_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_spark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var bits := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size * 2.0
	quad.material = _spark_material
	bits.mesh = quad
	bits.amount = count
	bits.one_shot = true
	bits.explosiveness = 1.0
	bits.lifetime = life
	bits.direction = Vector3(0, 1, 0)
	bits.spread = 180.0
	bits.initial_velocity_min = spread * 0.4
	bits.initial_velocity_max = spread
	bits.gravity = Vector3.ZERO
	bits.color = tint
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	bits.color_ramp = fade
	bits.position = at + Vector3(0, 0.2, 0)
	_root.add_child(bits)
	bits.emitting = true
	get_tree().create_timer(life + 0.2).timeout.connect(bits.queue_free)
