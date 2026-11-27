## The look of the hour (core/160; docs/architecture/day-and-exterior.md "The shape"; the old day_cycle.gd and
## room.gd `_apply_day`): a view on every machine. It eases the day's keys (`DayKey`, one `.tres` each in `keys`)
## at the Day's shown hour and writes the Sun (direction, colour, energy; hidden at 0: the moon by night), the sky
## material's `phase` and `energy` (only when they moved by `sky_step`: a change re-bakes the sky), the
## Environment's ambient, the basement's fill (its probe's ambient: `basement_ambient` x the sky's energy x the
## ambient) and the lamps' night (`HouseLights.night`, from `lamps_on` to `lamps_off`). The Sun, the sky and the
## fill follow every `sky_every` frames, the ambient and the lamps every `light_every`, everything at once when the
## hour is written (a load, a join, a station's key).
class_name DayLight
extends Node

## The lamps switched on (at dusk) or off (in the morning) as the hour passed; not on the first sample, nor when
## the hour arrived whole (a load or a join switches them silently).
signal lamps_switched(on: bool)

## The house has these at its root (the day's slot cannot link to them: they are outside its scene).
const PICTURE := ^"Picture"
const LIGHTS := ^"Lights"
const WIRING_OPTIONAL := ["picture", "lights", "basement_probe"]

## The hour it shows.
@export var day: Day
## The picture whose Sun, Environment and sky it writes. Empty: the level's `Picture`.
@export var picture: Picture
## The lamps. Empty: the level's `Lights`.
@export var lights: HouseLights
## The basement's fill. Empty: none.
@export var basement_probe: ReflectionProbe
## Where the keys are (every DayKey `.tres` in it, sorted by hour).
@export_dir var keys_folder := "res://game/day/keys"

## The keys, by hour.
var keys: Array[DayKey] = []
## The last sample (sample()): the hour, the direction the light travels, its colour and energy, the sky, the
## ambient, the lamps' factor and whether they are on.
var hour := -1.0
var light_dir := Vector3.DOWN
var light_colour := Color.WHITE
var light_energy := 0.0
var sky_phase := 0.0
var sky_energy := 1.0
var ambient := 0.75
var lamps := 1.0
var lamps_on := false

var _frame := 0
## What was last written: the sky's phase and energy, the fill (-1 before the first write).
var _sky_phase := -1.0
var _sky_energy := -1.0
var _fill := -1.0
## -1 before the first sample, else whether the lamps were on.
var _lamps_were := -1


func _ready() -> void:
	keys = load_keys(keys_folder)
	var level := _level()
	if picture == null and level != null:
		picture = level.get_node_or_null(PICTURE) as Picture
	if lights == null and level != null:
		lights = level.get_node_or_null(LIGHTS) as HouseLights
	if basement_probe != null and day != null:
		basement_probe.ambient_color = day.tuning.basement_tint
	if day != null:
		day.hour_set.connect(_on_hour_set)
	_apply.call_deferred(true, true)


## Every DayKey `.tres` in `folder`, sorted by hour.
static func load_keys(folder: String) -> Array[DayKey]:
	var out: Array[DayKey] = []
	for f: String in ResourceLoader.list_directory(folder):
		if f.ends_with(".tres"):
			var k := load(folder.path_join(f)) as DayKey
			if k != null:
				out.append(k)
	out.sort_custom(func(a: DayKey, b: DayKey) -> bool: return a.hour < b.hour)
	return out


func _process(_delta: float) -> void:
	if day == null:
		return
	_frame += 1
	var t := day.tuning
	var sky := _frame % t.sky_every == 0
	if sky or _frame % t.light_every == 0:
		_apply(sky, false)


func _on_hour_set(now: bool) -> void:
	_apply(true, now)


## Samples the shown hour and writes the ambient and the lamps; the Sun, the sky and the fill too when `sky`.
## `silent`: the lamps switch without lamps_switched.
func _apply(sky: bool, silent: bool) -> void:
	if day == null or not is_inside_tree():
		return
	sample(day.shown_hour())
	var env := picture.environment() if picture != null else null
	if env != null and not is_equal_approx(env.ambient_light_energy, ambient):
		env.ambient_light_energy = ambient
	if lights != null and lights.night != lamps_on:
		lights.night = lamps_on
	var on := int(lamps_on)
	if _lamps_were != on:
		var first := _lamps_were < 0
		_lamps_were = on
		if not first and not silent:
			lamps_switched.emit(lamps_on)
	if not sky:
		return
	var sun := picture.sun if picture != null else null
	if sun != null:
		sun.visible = light_energy > 0.01
		if sun.visible:
			var up := Vector3.UP if absf(light_dir.y) < 0.99 else Vector3.FORWARD
			sun.global_basis = Basis.looking_at(light_dir, up)
			sun.light_color = light_colour
			sun.light_energy = light_energy
	var step := day.tuning.sky_step
	var fill := day.tuning.basement_ambient * sky_energy * ambient
	if basement_probe != null and absf(fill - _fill) > step * 0.1:
		_fill = fill
		basement_probe.ambient_color_energy = fill
	var mat := picture.sky_material() if picture != null else null
	if mat != null and (absf(sky_phase - _sky_phase) > step or absf(sky_energy - _sky_energy) > step):
		_sky_phase = sky_phase
		_sky_energy = sky_energy
		mat.set_shader_parameter(&"phase", sky_phase)
		mat.set_shader_parameter(&"energy", sky_energy)


## Fills the sample's fields for `at` (0 to 24, wraps): the two keys around it eased (smoothstep), the light's
## direction from the tuning's sun path or moon.
func sample(at: float) -> void:
	var h := fposmod(at, 24.0)
	hour = h
	var t := day.tuning if day != null else DayTuning.new()
	lamps_on = t.lamps_lit(h)
	light_dir = -t.to_light(h)
	var n := keys.size()
	if n == 0:
		return
	var i := n - 1
	for k in n:
		if keys[k].hour > h:
			i = k - 1
			break
	var a := keys[(i + n) % n]
	var b := keys[(i + 1) % n]
	var ha := a.hour
	var hb := b.hour
	if hb <= ha:
		hb += 24.0
	var hh := h if h >= ha else h + 24.0
	var w := smoothstep(0.0, 1.0, clampf((hh - ha) / maxf(hb - ha, 0.0001), 0.0, 1.0))
	light_colour = a.light_colour.lerp(b.light_colour, w)
	light_energy = lerpf(a.light_energy, b.light_energy, w)
	sky_phase = lerpf(a.sky_phase, b.sky_phase, w)
	sky_energy = lerpf(a.sky_energy, b.sky_energy, w)
	ambient = lerpf(a.ambient, b.ambient, w)
	lamps = lerpf(a.lamps, b.lamps, w) if lamps_on else 0.0


## The level this view is in (the house: its slot cannot link outside its scene).
func _level() -> Node:
	var runtime := LevelRuntime.of(self)
	return runtime.get_parent() if runtime != null else null
