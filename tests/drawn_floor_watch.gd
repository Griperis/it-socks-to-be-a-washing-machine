## core/70: every frame, after the Mess has placed its flying Socks' drawings and before the frame is
## drawn, whether a flying Sock is drawn with the middle of a leg, a foot or a Pair's ball inside the
## house (under the floor). A body Jolt's position solve pushes into the floor in a step reaches its node
## only at the next tick's sync, and the Mess puts it back in that tick (core/50), so no frame should.
## core/100 (Q2604, the old game's Jolt default slop): a middle under a floor's top by less than the rest
## rule's `sunk` is not counted, as the rest rule lets such a Sock lie (P13): a Sock pressed under a heap
## sinks so within Jolt's 0.02 m penetration slop, its middle up to about 1 cm under. Only deeper (a push
## the Mess missed) or inside a wall counts.
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
			if shape != null and _under(to_drawn * shape.global_position):
				under += 1
				if notes.size() < 5:
					notes.append("frame %d: a body drawn at y %.3f" % [frames, drawn.origin.y])
				break


## Whether `middle` is inside the house deeper than the rest rule lets a Sock lie (Mess._on_floor):
## inside a wall, or under a floor's top by `sunk` or more.
func _under(middle: Vector3) -> bool:
	if not PhysicsQueries.inside(mess, middle, Mess.LAYER_HOUSE):
		return false
	var t := mess.bodies_tuning()
	var hit := PhysicsQueries.ray(mess, middle + Vector3.UP * t.sunk_depth, middle, Mess.LAYER_HOUSE)
	if hit.is_empty() or (hit["normal"] as Vector3).y <= t.floor_up:
		return true
	return (hit["position"] as Vector3).y - middle.y >= t.sunk - 0.0001
