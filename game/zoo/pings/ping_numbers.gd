## The Pings station's numbers board (core/43; Q2421: look and feel numbers get no test, the station
## shows them): a zoo label lying on the pad, built at load from the level's own Pings (their
## PingTuning) and the local player's hint arrows (their HintArrowTuning), so a changed number shows here
## with no other change (Q2337).
class_name PingNumbers
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
	var pings := runtime.pings if runtime != null else null
	var p := pings.tuning if pings != null and pings.tuning != null else PingTuning.new()
	var player := runtime.player if runtime != null else null
	var arrows := player.hud().hint_arrows() if player != null else null
	var a := arrows.tuning if arrows != null and arrows.tuning != null else HintArrowTuning.new()
	label.text = "\n".join([
		"Middle button: a tap under %.2f s highlights, a hold opens the wheel; reach %.0f m" % [p.hold, p.reach],
		"A ping stands %.1f s, pops in over %.2f s, fades over its last %.1f s; one per player" % [p.seconds, p.pop, p.fade],
		"Highlight: outline %.1f times the crosshair's, through walls; a ring %.2f-%.2f m on a bare spot, grows %.2f a metre, at least %.0f%% of the screen" % [p.outline_width, p.ring_inner, p.ring_outer, p.ring_grow, p.min_ring * 100.0],
		"Emoji: bubble %.0f%% of the screen for %.1f s, %.2f m over a spot (half over a thing), %.2f m over a head; the copy beside the head %.0f%%, %.2f m to the side" % [p.size * 100.0, p.bubble_seconds, p.lift, p.head_lift, p.head_share * 100.0, p.head_side],
		"Wheel: keycaps %.0f px out, dead centre %.0f px, chosen grows %.2f; pad stick deadzone %.2f" % [p.wheel_radius, p.wheel_dead, p.wheel_chosen_scale, p.wheel_deadzone],
		"Arrows: %.0f px long, %.0f px from the edge, outline %.1f px, at most %d, pings first then nearest" % [a.size, a.margin, a.outline, a.max_arrows],
	])
