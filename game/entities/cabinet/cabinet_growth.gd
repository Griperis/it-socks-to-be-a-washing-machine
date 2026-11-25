## How a Cabinet stands at its Rows and grows (core/81, docs/architecture/stages.md "Rows and Cabinets"):
## the Cabinet scene holds six Drawer modules (a Looks segment and a Drawer each) and shows the first
## `rows` of them: the rest hidden, their collision off. When `rows` grows in an answer each new module
## falls in on top (the old Cabinet.grow_to), a `drawer_thunk` and a dust puff at its seam as it lands;
## on a load, a join or a first showing it stands there at once. Looks only: the state is the Cabinet's.
class_name CabinetGrowth
extends RefCounted

## The old stacking (old cabinet.gd BASE_H, SEGMENT_H, assets/11): module i (0 the bottom) stands at
## BASE_H + i * SEGMENT_H, its Drawer 0.01 above it, the top on the stack; the shell is 0.05 taller.
const BASE_H := 0.10
const SEGMENT_H := 0.30
const DRAWER_LIFT := 0.01
const SHELL_EXTRA := 0.05
const DUST_PUFF := preload("res://game/entities/cabinet/dust_puff.tscn")
## Where a dust puff starts: a little toward the front of the seam.
const DUST_Z := 0.05
const LAYER_META := &"cabinet_growth_layer"

var _cabinet: Cabinet
## The Rows standing now (-1: none shown yet).
var _shown := -1
var _tween: Tween = null
var _looks_id := 0
## How many Drawer modules have fallen in (a test reads it).
var drops := 0


func _init(cabinet: Cabinet) -> void:
	_cabinet = cabinet


## Whether a Drawer drop is still playing.
func growing() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## The Rows standing (the dropping ones counted), -1 before the first showing.
func shown() -> int:
	return _shown


## Brings the Cabinet to `rows`: at once when `now` or the first time or fewer; a Cabinet that had Rows
## and gains some drops them in (a Cabinet first unlocked, with none shown before, stands at once).
func follow(rows: int, now: bool) -> void:
	var root := _cabinet.get_parent() as Node3D
	if root == null or not root.is_node_ready():
		return
	rows = clampi(rows, 0, _cabinet.drawer_count())
	var looks := _looks_of(root)
	var looks_id := looks.get_instance_id() if looks != null else 0
	if rows > _shown and _shown > 0 and not now:
		stand(_shown)  # an unfinished drop lands at once
		_grow_to(root, rows)
	elif rows != _shown or (looks_id != _looks_id and not growing()):
		stand(rows)
	_looks_id = looks_id


## Stands at `rows` at once.
func stand(rows: int) -> void:
	var root := _cabinet.get_parent() as Node3D
	if _tween != null:
		_tween.kill()
		_tween = null
	_shown = clampi(rows, 0, _cabinet.drawer_count())
	for i in _cabinet.drawer_count():
		_show_drawer(root, i, i < _shown)
	_fit_shell(root, _shown)
	_place(root, -1, 0.0)


func _grow_to(root: Node3D, count: int) -> void:
	var t := _cabinet.tuning_of()
	var from := _shown
	if _tween != null:
		_tween.kill()
	_shown = count
	_fit_shell(root, count)
	_place(root, -1, 0.0)
	_set_top(root, from, 0.0)
	_tween = _cabinet.create_tween()
	_tween.tween_interval(t.drop_delay)
	for k in range(from, count):
		if k > from:
			_tween.tween_interval(t.drop_gap)
		_tween.tween_callback(func() -> void:
			_show_drawer(root, k, true)
			_place(root, k, t.drop_height))
		_tween.tween_method(func(off: float) -> void: _place(root, k, off), t.drop_height, 0.0, t.drop_time) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_tween.tween_callback(_land.bind(root, k))
	_tween.tween_callback(func() -> void:
		_place(root, -1, 0.0)
		_tween = null)


## Drawer `k` landed: the thunk at its top seam and a dust puff from it.
func _land(root: Node3D, k: int) -> void:
	drops += 1
	var top := BASE_H + (k + 1) * SEGMENT_H
	Sounds.play_at(&"drawer_thunk", root.to_global(Vector3(0.0, top, 0.0)))
	var puff := DUST_PUFF.instantiate() as GPUParticles3D
	var t := _cabinet.tuning_of()
	puff.amount = t.dust_amount
	(puff.process_material as ParticleProcessMaterial).color = t.dust_colour
	puff.position = Vector3(0.0, top - SEGMENT_H, DUST_Z)
	puff.finished.connect(puff.queue_free)
	root.add_child(puff)
	puff.emitting = true


func _looks_of(root: Node3D) -> Node3D:
	return root.get_node_or_null(NodePath(Cabinet.LOOKS)) as Node3D


func _segment(root: Node3D, i: int) -> Node3D:
	var looks := _looks_of(root)
	return looks.get_node_or_null(NodePath("Segment%d" % (i + 1))) as Node3D if looks != null else null


## Shows or hides module `i`: its Drawer (hidden ones out of reach) and its Looks segment.
func _show_drawer(root: Node3D, i: int, on: bool) -> void:
	var drawer := root.get_node_or_null(NodePath(Cabinet.DRAWER % (i + 1))) as Node3D
	if drawer != null:
		drawer.visible = on
		_reach(drawer, on)
	var seg := _segment(root, i)
	if seg != null:
		seg.visible = on


## Collision on (its layers as authored) or off for every body under `node`.
func _reach(node: Node, on: bool) -> void:
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		if on:
			if body.has_meta(LAYER_META):
				body.collision_layer = int(body.get_meta(LAYER_META))
				body.remove_meta(LAYER_META)
		elif not body.has_meta(LAYER_META):
			body.set_meta(LAYER_META, body.collision_layer)
			body.collision_layer = 0
	for child in node.get_children():
		_reach(child, on)


## The shell (its collision) as tall as `count` modules.
func _fit_shell(root: Node3D, count: int) -> void:
	var shape_node := root.get_node_or_null(^"Shape") as CollisionShape3D
	if shape_node == null or not (shape_node.shape is BoxShape3D):
		return
	var total := BASE_H + count * SEGMENT_H + SHELL_EXTRA
	var box := shape_node.shape as BoxShape3D
	if not box.resource_local_to_scene:  # the scene's shape is shared by every instance
		box = box.duplicate() as BoxShape3D
		box.resource_local_to_scene = true
		shape_node.shape = box
	box.size.y = total
	shape_node.position.y = total / 2.0


## Module `k` (its segment and Drawer) `off` over its place, the top riding on it; -1 stands every
## shown module in its place and the top on the stack.
func _place(root: Node3D, k: int, off: float) -> void:
	for i in _cabinet.drawer_count():
		var lift := off if i == k else 0.0
		var drawer := root.get_node_or_null(NodePath(Cabinet.DRAWER % (i + 1))) as Node3D
		if drawer != null:
			drawer.position.y = BASE_H + i * SEGMENT_H + DRAWER_LIFT + lift
		var seg := _segment(root, i)
		if seg != null:
			seg.position.y = BASE_H + i * SEGMENT_H + lift
	if k < 0:
		_set_top(root, _shown, 0.0)
	else:
		_set_top(root, k + 1, off)


func _set_top(root: Node3D, count: int, off: float) -> void:
	var looks := _looks_of(root)
	var top := looks.get_node_or_null(^"Top") as Node3D if looks != null else null
	if top != null:
		top.position.y = BASE_H + count * SEGMENT_H + off
