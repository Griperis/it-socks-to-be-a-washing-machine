## One mark of a Trail (core/128, Q2680): the root of every `trails/<id>.tscn`. The mark's look is the
## editor nodes under it (one-shot GPUParticles3D with no shadow, an AnimationPlayer's autoplay `mark`
## clip where it has staged motion); this script moves nothing: it frees the mark after `life`. The
## Dresser keeps at most `max_marks` of one creature's marks alive, the oldest freed first.
class_name TrailMark
extends Node3D

## Seconds a mark lasts.
@export_range(0.1, 30.0, 0.1, "suffix:s") var life := 3.0
## The most marks of this Trail one creature keeps.
@export_range(1, 200, 1) var max_marks := 30

## Seconds since it was laid.
var age := 0.0


## Laid `seconds` ago (a Trail's sample already laid when it opens): its particles are run that far
## ahead. Call before it enters the tree.
func laid_ago(seconds: float) -> void:
	age = seconds
	for p: Node in find_children("*", "GPUParticles3D", true, false):
		(p as GPUParticles3D).preprocess = seconds


func _ready() -> void:
	if age > 0.0:
		for a: Node in find_children("*", "AnimationPlayer", true, false):
			var player := a as AnimationPlayer
			if player.current_animation != &"":
				player.seek(age, true)


func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
