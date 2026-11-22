## coop/06: the local player's own body in first person, the sock creature's Looks with only its belly
## and feet (the old avatar.gd's first person). What the cut looks like is the designer's to judge from
## the stills in builds/review-own-body/ (Q2421); these cases check what the camera is given.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const LOOKS := "res://game/parts/avatar/looks_avatar.tscn"

var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "look_down", "method": "case_look_down", "world": false,
				"title": "real path: in the zoo the player clicks and moves the mouse down; the camera sees the belly's outside and the two feet in the player's colour, no capsule, no pupils, no shadow"},
		{"name": "crouch", "method": "case_crouch", "world": false,
				"title": "real path: holding crouch takes the own belly's Crouch shape key to 1, letting go back to 0"},
		{"name": "cut", "method": "case_cut", "world": false,
				"title": "the own belly is the player surface below belly_cut, closed at the cut (no hole), keeping the Crouch key, set back belly_back behind the eyes, the feet where they stand"},
		{"name": "no_double", "method": "case_no_double", "world": false,
				"title": "hosting, the local player's network Avatar stays hidden on its own machine and the own body wears the Host's colour"},
	]


func _before_case() -> void:
	Input.action_release(&"crouch")
	if _zoo != null:
		var session := _zoo.get_node_or_null("Session") as Session
		if session != null:
			session.close()
		_zoo.free()
		_zoo = null


func _build() -> Player:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := _zoo.get_node("Player") as Player
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand on the floor")
	await _frames(2)
	return player


## A real left click (captures the mouse) and a mouse move, through the viewport.
func _mouse_look(dx: float, dy: float) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	var up := click.duplicate() as InputEventMouseButton
	up.pressed = false
	Input.parse_input_event(up)
	await _physics_ticks(2)
	var ev := InputEventMouseMotion.new()
	ev.relative = Vector2(dx, dy)
	Input.parse_input_event(ev)
	await _frames(2)


func case_look_down() -> void:
	var player := await _build()
	var head := player.get_node("Head") as Node3D
	await _mouse_look(0.0, 100000.0)
	_check(head.rotation.x < -deg_to_rad(80.0), "the mouse down tilts the look straight down (%.1f deg)" % rad_to_deg(head.rotation.x))
	_check(player.get_node_or_null("Mesh") == null, "the player has no capsule mesh")
	var own := player.own_body()
	_check(own != null and own.first_person and own.is_visible_in_tree(), "the player has its own body, in first person, shown")
	await _until(func() -> bool: return own.bend > own.tuning.bend_down * 0.9, "the own body to bend with the look down")
	var camera := player.camera()
	var belly := own.body()
	var box := belly.global_transform * belly.get_aabb()
	_check(camera.is_position_in_frustum(box.get_center()), "the camera sees the belly")
	for foot: MeshInstance3D in own.feet():
		_check(foot.is_visible_in_tree() and camera.is_position_in_frustum(foot.global_position), "the camera sees %s" % foot.name)
		_check(foot.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s casts no shadow" % foot.name)
	_check(belly.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "the belly casts no shadow")
	var colour := (_zoo.get_node("Session/Roster") as Roster).tuning.colour(0)
	for i: int in belly.mesh.get_surface_count():
		var paint := belly.get_surface_override_material(i) as BaseMaterial3D
		_check(paint != null and paint.cull_mode == BaseMaterial3D.CULL_BACK, "belly surface %d draws its outside only" % i)
		_check(paint != null and paint.albedo_color == colour, "belly surface %d is the player's colour" % i)
	var feet_paint := own.feet()[0].get_surface_override_material(0) as BaseMaterial3D
	_check(feet_paint != null and feet_paint.albedo_color == colour.darkened(own.tuning.trim_darken), "the feet are the colour darkened, as a Teammate's")
	for n: String in ["PupilL", "PupilR"]:
		_check(not (own.find_child(n, true, false) as Node3D).is_visible_in_tree(), "%s is hidden" % n)
	_check(own.tag() == null or not own.tag().visible, "no name tag")
	_near(own.pupil_turn(0), 0.0, 0.001, "the hidden pupils do not turn")


func case_crouch() -> void:
	var player := await _build()
	var own := player.own_body()
	var key := own.body().find_blend_shape_by_name(&"Crouch")
	_check(key >= 0, "the own belly keeps the Crouch shape key")
	Input.action_press(&"crouch")
	await _until(func() -> bool: return own.body().get_blend_shape_value(key) >= 0.999, "the belly's Crouch to reach 1")
	_check(player.crouching, "the player crouches")
	Input.action_release(&"crouch")
	await _until(func() -> bool: return own.body().get_blend_shape_value(key) <= 0.001, "the belly's Crouch to go back to 0")


func case_cut() -> void:
	var own := (load(LOOKS) as PackedScene).instantiate() as AvatarLooks
	own.first_person = true
	var whole := (load(LOOKS) as PackedScene).instantiate() as AvatarLooks
	add_child(own)
	add_child(whole)
	var belly := own.body().mesh as ArrayMesh
	_check(belly.get_surface_count() == 1 and belly.surface_get_name(0) == "player", "the belly is the player surface alone")
	_check(belly.surface_get_material(0).resource_name == "player", "with the player material")
	_check(belly.get_blend_shape_count() == 1 and belly.get_blend_shape_name(0) == &"Crouch", "keeping the Crouch key")
	var top := _drawn_top(belly)
	_near(top, own.tuning.belly_cut, 0.002, "it ends at belly_cut (top %.3f)" % top)
	_check(whole.body().mesh.get_aabb().end.y > 1.5, "the whole body is untouched (top %.2f)" % whole.body().mesh.get_aabb().end.y)
	# The player surface has its own openings where the trim fills it (the heel patch, below the cut,
	# at the back), as in the old game; the cut itself must be closed.
	var open := _open_edges(belly, own.tuning.belly_cut - 0.05)
	_check(open == 0, "the cut is closed: no edge near it without a second face (%d open)" % open)
	_near(own.swaying().position.z - whole.swaying().position.z, own.tuning.belly_back, 0.0001, "the belly sits belly_back further back")
	for i: int in 2:
		var a := own.feet()[i].global_position
		var b := whole.feet()[i].global_position
		_check(a.distance_to(b) < 0.0001, "%s stands where a Teammate's does (%s vs %s)" % [own.feet()[i].name, a, b])
	own.free()
	whole.free()


func case_no_double() -> void:
	var player := await _build()
	var session := _zoo.get_node("Session") as Session
	session.port = 0
	session.profile = PlayerProfile.fresh()
	_check((_zoo.get_node("Net") as ZooNet).start(["--host"]) == OK, "the zoo hosts")
	var avatars := _zoo.get_node("Avatars") as Avatars
	await _until(func() -> bool: return avatars.of(multiplayer.get_unique_id()) != null, "the local player's avatar to spawn")
	await _frames(2)
	var mine := avatars.of(multiplayer.get_unique_id())
	_check(not mine.is_visible_in_tree(), "the local player's network Avatar is hidden here")
	var roster := _zoo.get_node("Session/Roster") as Roster
	var colour := roster.colour_of(multiplayer.get_unique_id())
	var paint := player.own_body().body().get_surface_override_material(0) as BaseMaterial3D
	_check(paint != null and paint.albedo_color == colour, "the own body wears this machine's Roster colour")


## The highest vertex `mesh`'s surface 0 draws (its arrays keep the vertices it no longer uses).
func _drawn_top(mesh: ArrayMesh) -> float:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var top := -INF
	for i: int in (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array):
		top = maxf(top, verts[i].y)
	return top


## How many edges of `mesh`'s surface 0 (by position) above `above` metres have one face only: a
## hole's rim.
func _open_edges(mesh: ArrayMesh, above: float) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var count: Dictionary[String, int] = {}
	for t: int in range(0, idx.size(), 3):
		for k: int in 3:
			var a := _key(verts[idx[t + k]])
			var b := _key(verts[idx[t + (k + 1) % 3]])
			if a == b or minf(verts[idx[t + k]].y, verts[idx[t + (k + 1) % 3]].y) < above:
				continue
			var e := a + "|" + b if a < b else b + "|" + a
			count[e] = count.get(e, 0) + 1
	var open := 0
	for e: String in count:
		if count[e] < 2:
			open += 1
	return open


static func _key(v: Vector3) -> String:
	return "%d,%d,%d" % [roundi(v.x * 10000.0), roundi(v.y * 10000.0), roundi(v.z * 10000.0)]

