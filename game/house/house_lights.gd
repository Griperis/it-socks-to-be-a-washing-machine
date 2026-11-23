## The house's lamp rules (house/06, Q2515; old room.gd `_build_light`, `_layer_by_level`, `_apply_day`).
## It sits on the `Lights` node. Each light says the levels it lights in its metadata `lit_levels` (indices
## into `floors`: its room's level, a stair room's light its own and the next one up). Each level has a
## render layer of its own: a light lights only its levels' layers and layer 1, so no light shines through a
## floor, shadowed or not. Drawn things lying within one level go on that level's layer (the nodes of
## `layered`); whatever spans levels or moves between them (slabs, stair solids, Socks, players) stays on
## layer 1, which every light lights. By day only the lamps that light the basement alone are lit.
class_name HouseLights
extends Node3D


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
## False by day: only the day level's lamps are lit. True: every lamp is (the day cycle will set it).
var night := false:
	set(value):
		night = value
		if is_node_ready():
			_switch()


func _ready() -> void:
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


## Sets each light's cull mask from its levels, and shows it by the hour.
func _switch() -> void:
	for node in get_children():
		var light := node as Light3D
		if light == null:
			continue
		light.light_cull_mask = lit_layers(level_mask(lit_levels(light)))
		light.visible = night or lit_by_day(light)


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
