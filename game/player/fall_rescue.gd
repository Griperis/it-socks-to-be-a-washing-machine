## The test of "out of the map" (Player._out_of_map): below the lowest floor by `depth`, farther than
## `reach` from the centre on any axis, or a position that is not finite.
class_name FallRescue
extends RefCounted


static func out_of_map(at: Vector3, floor_y: float, centre: Vector3, depth: float, reach: float) -> bool:
	if not (is_finite(at.x) and is_finite(at.y) and is_finite(at.z)):
		return true
	var off := (at - centre).abs()
	return at.y < floor_y - depth or off.x > reach or off.y > reach or off.z > reach
