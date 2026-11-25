## The Laundry bin's state and looks (core/90, run-ends.md "The Laundry bins (the entity)"): a Part
## beside the thing's Carriable. `used`: the World uses this spot (a bin it does not use is hidden, has
## no collision and is not aimed); `full`: it still holds the laundry (true until the washer loads it).
## Both are written by the Host's answers only (the Laundry day, core/93, or the zoo's pillar); the bin
## decides nothing itself. Carrying is the Carriable's.
##
## Looks only: its heap (`Contents`) follows `full` as the blend shape `empty` = 1 - fill, eased at
## `FILL_RATE` a second, hidden when empty (the old laundry_view.gd _show_fills); `tip()` turns the
## Looks toward the washer and plays the `tip` animation; `set_drawn(false)` hides it from the draw
## (the Cutscene frame's, carried or lying); its crosshair words are "Laundry bin, dirty" / ", empty".
## The graybox heap has no blend shape: it is scaled by the fill instead, until the model (assets/13).
class_name LaundryBin
extends Part

## Every bin is in this group (the Laundry day and the Cutscene frame look there).
const GROUP := &"laundry_bins"
## The washer is in this group: `tip()` leans toward it.
const WASHER_GROUP := &"washer"
const DIRTY := "Laundry bin, dirty"
const EMPTY := "Laundry bin, empty"
## How fast the heap eases to the state, in fills a second (the old 0.8).
const FILL_RATE := 0.8
## The heap, the turn and the tip animation, from the Looks root.
const HEAP := ^"Aim/Tip/Contents"
const AIM := ^"Aim"
const TIP := &"tip"

## The Carriable beside it (it carries its name on the crosshair).
@export var carriable: Carriable
@export var tuning: LaundryTuning
## The spot by the washer: the draw always uses it (core/93).
@export var always := false

@export_group("State")
## The World uses this spot.
@export var used := true
## It holds the laundry.
@export var full := true
@export_group("")

## The fill the heap shows now (it eases to the state's).
var _shown := 1.0
var _drawn := true
## The shapes it switched off while unused.
var _off_shapes: Array[CollisionShape3D] = []


func _enter_tree() -> void:
	add_to_group(GROUP)


func prompt_title() -> String:
	return DIRTY if full else EMPTY


## Nothing is asked of the bin: its state is written by the Laundry day's answer.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


## The fill the heap shows now, 0..1.
func shown_fill() -> float:
	return _shown


## Whether the heap is drawn now.
func heap_visible() -> bool:
	var heap := _heap()
	return heap != null and heap.visible


## Whether the bin is drawn (false in a cutscene; nothing synced changes).
func drawn() -> bool:
	return _drawn


## Draw the bin, or not (the Cutscene frame hides every bin, carried or lying, and brings it back as it was).
func set_drawn(on: bool) -> void:
	_drawn = on
	_apply_visible()


## Looks only: lean toward the washer and tip into it, over `tuning.tip_seconds`.
func tip() -> void:
	var looks := _looks()
	if looks == null:
		return
	var aim := looks.get_node_or_null(AIM) as Node3D
	var thing := get_parent() as Node3D
	var washer := get_tree().get_first_node_in_group(WASHER_GROUP) as Node3D if is_inside_tree() else null
	if aim != null and washer != null and thing != null:
		var toward := thing.global_basis.inverse() * (washer.global_position - thing.global_position)
		toward.y = 0.0
		if toward.length() > 0.01:
			aim.rotation.y = atan2(-toward.x, -toward.z)
	var player := looks.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	if player != null:
		var seconds := tuning.tip_seconds if tuning != null else 1.4
		player.play(TIP, -1.0, player.get_animation(TIP).length / maxf(seconds, 0.01))


## Whether it is tipping now.
func tipping() -> bool:
	var looks := _looks()
	var player := looks.get_node_or_null(^"AnimationPlayer") as AnimationPlayer if looks != null else null
	return player != null and player.is_playing()


func _show(now: bool) -> void:
	if carriable != null:
		carriable.title = prompt_title()
	_apply_visible()
	_apply_shapes()
	var want := 1.0 if full else 0.0
	if now:
		_shown = want
		_apply_fill()
	set_process(not is_equal_approx(_shown, want))


func _process(delta: float) -> void:
	var want := 1.0 if full else 0.0
	_shown = move_toward(_shown, want, delta * FILL_RATE)
	_apply_fill()
	if is_equal_approx(_shown, want):
		set_process(false)


func _apply_visible() -> void:
	var thing := get_parent() as Node3D
	if thing != null:
		thing.visible = used and _drawn


## An unused bin has no collision (so it is never aimed); a used one gets its shapes back.
func _apply_shapes() -> void:
	var thing := get_parent() as Node3D
	if thing == null:
		return
	if used:
		for shape in _off_shapes:
			if is_instance_valid(shape):
				shape.set_deferred(&"disabled", false)
		_off_shapes.clear()
	elif _off_shapes.is_empty():
		for node in thing.find_children("*", "CollisionShape3D", true, false):
			var shape := node as CollisionShape3D
			if not shape.disabled:
				shape.set_deferred(&"disabled", true)
				_off_shapes.append(shape)


func _apply_fill() -> void:
	var heap := _heap()
	if heap == null:
		return
	heap.visible = _shown > 0.001
	var shape := heap.find_blend_shape_by_name(&"empty") if heap.mesh != null else -1
	if shape >= 0:
		heap.set_blend_shape_value(shape, 1.0 - _shown)
	else:
		heap.scale = Vector3(1.0, maxf(_shown, 0.001), 1.0)


func _looks() -> Node3D:
	var thing := get_parent() as Node3D
	return thing.get_node_or_null(^"Looks") as Node3D if thing != null else null


func _heap() -> MeshInstance3D:
	var looks := _looks()
	return looks.get_node_or_null(HEAP) as MeshInstance3D if looks != null else null
