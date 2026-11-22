## The small sparkle burst and ring at a Teammate's hand when their pick makes a Pair (coop/05,
## behaviour 60), true size, as the old game's (paired.json mate_burst_*, mate_ring_size, ring_*): the
## specks in the Design's Collection colour, each mixed up to `white` toward white; the ring rushes out
## to its size over `ring_time`, fading from `ring_alpha`. It frees itself when both are over.
class_name MateSparkle
extends Node3D

## How much toward white a speck may be mixed.
@export_range(0.0, 1.0, 0.01) var white := 0.35
## How long the ring takes to rush out, and how opaque it starts.
@export_range(0.05, 2.0, 0.01, "suffix:s") var ring_time := 0.35
@export_range(0.0, 1.0, 0.01) var ring_alpha := 0.8

@onready var _burst := $Burst as GPUParticles3D
@onready var _ring := $Ring as MeshInstance3D


## Plays it in `tint`.
func play(tint: Color) -> void:
	var specks := _burst.process_material as ParticleProcessMaterial
	var mix := Gradient.new()
	mix.set_color(0, tint)
	mix.set_color(1, tint.lerp(Color.WHITE, white))
	var ramp := GradientTexture1D.new()
	ramp.gradient = mix
	specks.color_initial_ramp = ramp
	_burst.restart()
	var mat := _ring.material_override as StandardMaterial3D
	mat.albedo_color = Color(tint, ring_alpha)
	_ring.scale = Vector3.ONE * 0.05
	_ring.visible = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ring, ^"scale", Vector3.ONE, ring_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, ^"albedo_color:a", 0.0, ring_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_interval(maxf(_burst.lifetime - ring_time, 0.0))
	tw.chain().tween_callback(queue_free)
