## The match cue's glow on one of your own held Socks (core/131; the old held_view.gd glow(), Q666): a
## warm white added over its meshes, `strength` bright at the start and fading out over `seconds`. The
## fade is the scene's `glow` clip keying `amount` from 1 to 0; this plays it at the speed that takes
## `seconds`, and frees itself, taking the glow off the meshes, when it is over.
class_name SockGlow
extends Node

## How much of the glow is left (the clip keys it, 1 to 0).
@export_range(0.0, 1.0, 0.01) var amount := 1.0:
	set(value):
		amount = value
		_apply()
## The overlay drawn over each mesh (made per glow by the scene: local to it).
@export var material: StandardMaterial3D

@onready var _anim: AnimationPlayer = $AnimationPlayer

var _strength := 0.6
var _meshes: Array[GeometryInstance3D] = []


## Glows `looks` for `seconds`, `strength` bright at the peak.
func play(looks: Node3D, seconds: float, strength: float) -> void:
	_strength = clampf(strength, 0.0, 1.0)
	_collect(looks)
	for m in _meshes:
		m.material_overlay = material
	_apply()
	_anim.animation_finished.connect(func(_name: StringName) -> void: _end())
	_anim.speed_scale = _anim.get_animation(&"glow").length / maxf(seconds, 0.05)
	_anim.play(&"glow")


## Whether it still glows.
func glowing() -> bool:
	return amount * _strength > 0.001 and not is_queued_for_deletion()


func _apply() -> void:
	if material != null:
		material.albedo_color.a = amount * _strength


func _end() -> void:
	for m in _meshes:
		if is_instance_valid(m) and m.material_overlay == material:
			m.material_overlay = null
	queue_free()


## The meshes of the Looks the glow goes on (not an outline's copies).
func _collect(node: Node) -> void:
	if node.is_in_group(Outline.COPY) or node.is_in_group(Outline.SKIP):
		return
	var g := node as GeometryInstance3D
	if g != null:
		_meshes.append(g)
	for c in node.get_children():
		_collect(c)
