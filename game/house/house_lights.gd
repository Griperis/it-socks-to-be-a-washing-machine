## The house's lamp rules (house/06, Q2515; old room.gd `_build_light`, `_layer_by_level`, `_apply_day`).
## It sits on the `Lights` node. Each light says the levels it lights in its metadata `lit_levels` (indices
## into `floors`: its room's level, a stair room's light its own and the next one up). Each level has a
## render layer of its own: a light lights only its levels' layers and layer 1, so no light shines through a
## floor, shadowed or not. Drawn things lying within one level go on that level's layer (the nodes of
## `layered`); whatever spans levels or moves between them (slabs, stair solids, Socks, players) stays on
## layer 1, which every light lights. By day only the lamps that light the basement alone are lit.
class_name HouseLights
extends Node3D

## Every HouseLights is in this group (a floor lock finds it to reveal its floor, core/80).
const GROUP := &"house_lights"

## The first render layer's bit of the levels: bit LEVEL_LAYER + the level's index (the old game's layers 16-20).
const LEVEL_LAYER := 15
## How many level layers (the fifth is the Lost Sock Grotto's, when it comes).
const LEVEL_LAYERS := 5
## How close (m) to a level's cut a thing's bounds may reach and still count as on one level.
const LEVEL_SLACK := 0.03

## Where each level's floor is (y, from the plan).
@export var floors: PackedFloat32Array = PackedFloat32Array([-3.0, 0.0, 3.0, 6.0])
## A level ends this far under the next floor: halfway through the slab (old: the midpoint of the gap).
@export_range(0.0, 0.5, 0.01) var cut_below_floor := 0.1 # placeholder: half the old slab, from the plan's slab thickness
## The level whose own lamps stay lit by day (the basement's, house/30).
@export var day_level := 0
## The nodes whose drawn things are put on level layers (the shell, the furniture, the Cabinets, the Doors).
@export var layered: Array[NodePath] = []
## The reveal of an opened floor (progression/03, Q638; the old room.gd reveal_level): its lamps fade in over
## `reveal_fade`, stay lit by day for `reveal_hold`, then fade back over `reveal_fade_out` to the day's rule.
@export_group("Reveal")
@export_range(0.0, 3.0, 0.05, "suffix:s") var reveal_fade := 0.6 # placeholder: FloorLockTuning gives it on each reveal
@export_range(0.0, 30.0, 0.5, "suffix:s") var reveal_hold := 6.0 # placeholder: FloorLockTuning gives it on each reveal
@export_range(0.0, 6.0, 0.05, "suffix:s") var reveal_fade_out := 1.2 # placeholder: FloorLockTuning gives it on each reveal
@export_group("")
## False by day: only the day level's lamps are lit. True: every lamp is (the day cycle will set it).
var night := false:
	set(value):
		night = value
		if is_node_ready():
			_switch()


## The levels (bits, by level index) whose lamps stay off: the locked floors (core/80).
var dark_levels := 0
## The washing machine's flicker (core/94; the old room.gd:184-188, :326): the lamps within `flicker_range` (m)
## of `flicker_at` light at `flicker` (0..1) of their level; a range of 0 flickers none.
var flicker := 1.0
var flicker_at := Vector3.ZERO
var flicker_range := 0.0
## Level -> the clock (seconds of this node's frames) when its reveal began.
var _reveals: Dictionary[int, float] = {}
var _clock := 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	set_process(false)
	_switch()
	_layer_by_level.call_deferred()


## The render layers of the levels `levels` (indices into `floors`).
static func level_mask(levels: PackedInt32Array) -> int:
	var m := 0
	for i in levels:
		if i >= 0 and i < LEVEL_LAYERS:
			m |= 1 << (LEVEL_LAYER + i)
	return m


## The cull mask of a light that lights the levels `mask` (level_mask()): every layer but the other levels'.
static func lit_layers(mask: int) -> int:
	var all_levels := ((1 << LEVEL_LAYERS) - 1) << LEVEL_LAYER
	return (0xFFFFFFFF & ~all_levels) | mask


## The level (index) whose band holds height `y`: a level ends `cut_below_floor` under the next floor.
func level_index(y: float) -> int:
	var i := 0
	for k in range(1, floors.size()):
		if y > floors[k] - cut_below_floor:
			i += 1
	return i


## The levels (indices) light `light` lights, from its metadata.
func lit_levels(light: Light3D) -> PackedInt32Array:
	return light.get_meta(&"lit_levels", PackedInt32Array()) as PackedInt32Array


## Whether `light` is lit by day: it lights the day level and no other.
func lit_by_day(light: Light3D) -> bool:
	var levels := lit_levels(light)
	return levels.size() == 1 and levels[0] == day_level


## Floor `level`'s lamps stay off while it is locked (core/80), or follow the hour again once it is not.
## The reveal of the floor that was waiting is the lock's own call (reveal()).
func set_level_dark(level: int, dark: bool) -> void:
	if level < 0 or level >= LEVEL_LAYERS:
		return
	if dark:
		dark_levels |= 1 << level
		_reveals.erase(level)
	else:
		dark_levels &= ~(1 << level)
	_switch()


## Floor `level` opened: its lamps come on, fading in, and stay lit by day for a while (fade and hold
## in seconds; the Resource of the lock gives them).
func reveal(level: int, fade := -1.0, hold := -1.0, fade_out := -1.0) -> void:
	if level < 0 or level >= LEVEL_LAYERS:
		return
	reveal_fade = reveal_fade if fade < 0.0 else fade
	reveal_hold = reveal_hold if hold < 0.0 else hold
	reveal_fade_out = reveal_fade_out if fade_out < 0.0 else fade_out
	dark_levels &= ~(1 << level)
	_reveals[level] = _clock
	set_process(true)
	_switch()


## How lit (0..1) the reveal of `level` holds its lamps now; 0 when it has none or is over.
func reveal_amount(level: int) -> float:
	if not _reveals.has(level):
		return 0.0
	var t := _clock - _reveals[level]
	if t < reveal_fade:
		return t / maxf(reveal_fade, 0.0001)
	if t < reveal_fade + reveal_hold:
		return 1.0
	return clampf(1.0 - (t - reveal_fade - reveal_hold) / maxf(reveal_fade_out, 0.0001), 0.0, 1.0)


## Whether `light` is off for good now: it lights levels and every one of them is locked.
func is_dark(light: Light3D) -> bool:
	var levels := lit_levels(light)
	if levels.is_empty():
		return false
	for l in levels:
		if not (dark_levels & (1 << l)):
			return false
	return true


func _process(delta: float) -> void:
	_clock += delta
	for level: int in _reveals.keys():
		if _clock - _reveals[level] >= reveal_fade + reveal_hold + reveal_fade_out:
			_reveals.erase(level)
	_switch()
	if _reveals.is_empty():
		set_process(false)


## The lamps within `range` of `at` light at `level` of their level (the First wash's break); a `range` of 0
## ends it.
func set_flicker(at: Vector3, range: float, level: float) -> void:
	if is_equal_approx(level, flicker) and at.is_equal_approx(flicker_at) and is_equal_approx(range, flicker_range):
		return
	flicker = level
	flicker_at = at
	flicker_range = range
	_switch()


## Whether `light` is one the flicker reaches now.
func flickers(light: Light3D) -> bool:
	return flicker_range > 0.0 and light.global_position.distance_to(flicker_at) < flicker_range


## Sets each light's cull mask from its levels, and shows it by the hour, the locks and the reveals.
func _switch() -> void:
	for node in get_children():
		var light := node as Light3D
		if light == null:
			continue
		light.light_cull_mask = lit_layers(level_mask(lit_levels(light)))
		if not light.has_meta(&"base_energy"):
			light.set_meta(&"base_energy", light.light_energy)
		var base := float(light.get_meta(&"base_energy"))
		var on := night or lit_by_day(light)
		var lit := 1.0
		if is_dark(light):
			on = false
		else:
			var r := 0.0
			for level in lit_levels(light):
				r = maxf(r, reveal_amount(level))
			if r > 0.0 and not on:
				lit = r  # a lamp the hour keeps off: the reveal fades it in and out
				on = true
		if is_inside_tree() and flickers(light):
			lit *= flicker
		var energy := base * lit
		if not is_equal_approx(light.light_energy, energy):
			light.light_energy = energy
		light.visible = on


## Puts each drawn thing of `layered` that lies within one level on that level's layer. Things that span
## levels, things already on a layer of their own (a mirror's glass), lights and probes stay as they are.
func _layer_by_level() -> void:
	for path in layered:
		var root := get_node_or_null(path)
		if root == null:
			continue
		for vi: Node in root.find_children("*", "VisualInstance3D", true, false):
			var v := vi as VisualInstance3D
			if v.layers != 1 or v is Light3D or v is ReflectionProbe:
				continue
			var box := v.global_transform * v.get_aabb()
			var lo := level_index(box.position.y + LEVEL_SLACK)
			var hi := level_index(box.end.y - LEVEL_SLACK)
			if lo == hi:
				v.layers = level_mask(PackedInt32Array([lo]))
