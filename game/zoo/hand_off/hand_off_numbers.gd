## The Hand-off station's numbers board (core/42; Q2421: look and feel numbers get no test, the station
## shows them): a zoo label lying on the pad, built at load from the level's own Hands (their
## HandOffTuning and HandsTuning) and the Knockdowns' hit test, so a changed number shows here with no
## other change (Q2337).
class_name HandOffNumbers
extends Node3D

const LABEL := preload("res://game/zoo/zoo_label.tscn")

## The board's label, made at load.
var label: Label3D


func _ready() -> void:
	label = LABEL.instantiate() as Label3D
	label.pixel_size = 0.003
	add_child(label)
	_fill.call_deferred()


## The board's lines, from the level's numbers once the whole level is ready.
func _fill() -> void:
	var runtime := LevelRuntime.of(self)
	var hands := runtime.hands if runtime != null else null
	var kd := runtime.knockdowns if runtime != null else null
	var h := hands.own_tuning() if hands != null else HandsTuning.new()
	var o := hands.hand_off_numbers() if hands != null else HandOffTuning.new()
	var k := kd.tuning if kd != null and kd.tuning != null else KnockdownTuning.new()
	label.text = "\n".join([
		"Aim: reach %.1f m, shortened by a wall; body %.2f m round, from %.2f m over the feet" % [h.reach, o.body_radius, o.feet_lift],
		"Flight into the Hands: %.2f s, arc %.2f m" % [h.pick_time, h.pick_hop],
		"Catch: a Throw under %.0f%% charge; hit body %.2f m round" % [k.min_charge * 100.0, k.body_radius],
		"Refused catch bounces at %.2f of its speed" % o.bounce,
	])
