## core/70: every frame, after the Mess has placed its flying Socks' drawings and before the frame is
## drawn, whether a flying Sock is drawn with the middle of a leg, a foot or a Pair's ball inside the
## house (under the floor). A body Jolt's position solve pushes into the floor in a step reaches its node
## only at the next tick's sync, and the Mess puts it back in that tick (core/50), so no frame should.
extends Node

var mess: Mess
## Frames watched, and flying Socks seen drawn inside the house (one per Sock per frame).
var frames := 0
var under := 0
var notes := PackedStringArray()


func _ready() -> void:
	# After every game node's _process (the Mess's writes the flying drawings): the frame as drawn.
	process_priority = 1000


func _process(_delta: float) -> void:
	if mess == null:
		return
	frames += 1
	for body in mess.flight_bodies():
		var drawn := body.get_global_transform_interpolated()
		var to_drawn := drawn * body.global_transform.affine_inverse()
		for child in body.get_children():
			var shape := child as CollisionShape3D
			if shape != null and PhysicsQueries.inside(mess, to_drawn * shape.global_position, Mess.LAYER_HOUSE):
				under += 1
				if notes.size() < 5:
					notes.append("frame %d: a body drawn at y %.3f" % [frames, drawn.origin.y])
				break
