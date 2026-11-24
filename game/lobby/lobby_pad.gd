## The pad's route over the Lobby (docs/architecture/lobby.md "Core/67", the old lobby/06 follow-up): rows of
## controls, Left and Right walk a row (no wrap), Up and Down go to the nearest control of the row above or
## below. The Lobby's rows are: the "i" key and the World settings key; the figures left to right; the bottom
## keys; the drawer is a column of rows at the right that Right of the last figure goes into and Left comes
## back out of. Only what is on the route (visible, enabled, takes focus) is linked.
class_name LobbyPad
extends RefCounted


## Whether `c` can be selected now.
static func on_route(c: Control) -> bool:
	return c != null and c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() \
			and not (c is BaseButton and (c as BaseButton).disabled)


## The controls of `row` that are on the route.
static func live(row: Array) -> Array[Control]:
	var out: Array[Control] = []
	for c: Variant in row:
		if on_route(c as Control):
			out.append(c as Control)
	return out


## Clears every neighbour of `controls`.
static func clear(controls: Array) -> void:
	for c: Variant in controls:
		for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			(c as Control).set_focus_neighbor(side, NodePath())


## Links `rows` (arrays of live controls, empty ones skipped): Left/Right inside a row, Up/Down between rows,
## each landing on the nearest control by its x. A wall stays a wall: the first row's Up and the last row's
## Down point at the control itself, so the selection does not leave the route.
static func link_rows(rows: Array) -> void:
	var on: Array = rows.filter(func(r: Variant) -> bool: return not (r as Array).is_empty())
	for r in on.size():
		var row: Array = on[r]
		for i in row.size():
			var c: Control = row[i]
			c.focus_neighbor_left = c.get_path_to(row[maxi(i - 1, 0)] as Control)
			c.focus_neighbor_right = c.get_path_to(row[mini(i + 1, row.size() - 1)] as Control)
			var above: Array = on[maxi(r - 1, 0)]
			var below: Array = on[mini(r + 1, on.size() - 1)]
			c.focus_neighbor_top = c.get_path_to(_nearest(c, above) if r > 0 else c)
			c.focus_neighbor_bottom = c.get_path_to(_nearest(c, below) if r < on.size() - 1 else c)


## The control of `row` whose centre is nearest `c`'s, sideways.
static func _nearest(c: Control, row: Array) -> Control:
	var at := c.get_global_rect().get_center().x
	var best: Control = row[0]
	for o: Variant in row:
		var control := o as Control
		if absf(control.get_global_rect().get_center().x - at) < absf(best.get_global_rect().get_center().x - at):
			best = control
	return best
