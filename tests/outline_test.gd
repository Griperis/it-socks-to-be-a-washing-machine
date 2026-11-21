## The outline (core/11): one Outline component on anything you can use, shown by the player's aim.
## One case per line of the approved behaviour list (O01-O08) and the real path. Every case plays the
## station scene game/zoo/stations/outline.tscn on a floor, with the game's player and a Parts (a Host
## of one), as the zoo does. The pixels are the shot set `outline`'s (headless draws nothing).
extends TestSuite

const STATION := "res://game/zoo/stations/outline.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact"]
## The station's Socks, by id (the order of its SockSpots): a Sock and its mate, another and its mate.
const SOCK := 0
const MATE := 1
const OTHER := 2
const OTHER_MATE := 3
## Where the player stands (station space): before the Socks, before the Cabinet, before the Door
## and cupboard.
const BY_SOCKS := Vector3(-1.7, 0.0, 1.0)
const BY_CABINET := Vector3(-0.6, 0.0, -0.4)
const BY_DOOR := Vector3(1.4, 0.0, 0.2)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the station the player turns the crosshair onto a lying Sock, a drawer and the Door: each shows its outline as it is aimed, and the one before goes"},
		{"name": "o01_soft_outline", "method": "case_o01", "world": false,
				"title": "O01: the aimed thing's outline is warm white, a stencil mask then three shells fading outward, drawn outside its shape, grown by the distance to the camera (one width near and far)"},
		{"name": "o02_goes_at_once", "method": "case_o02", "world": false,
				"title": "O02: when the crosshair leaves the thing, or it goes out of reach, the outline goes at once"},
		{"name": "o03_every_interactable", "method": "case_o03", "world": false,
				"title": "O03: a lying Sock, a lying Pair, the cupboard, a drawer and the Door are outlined when aimed; the box gets it by the component alone"},
		{"name": "o04_same_but_full", "method": "case_o04", "world": false,
				"title": "O04: every target has the same outline; a drawer with no room for the held Pair has the red full tint, one with room or empty Hands does not"},
		{"name": "o05_moving_shape", "method": "case_o05", "world": false,
				"title": "O05: a skinned Sock's outline bends with its bones, and a sliding drawer's outline slides with it"},
		{"name": "r9_reenter", "method": "case_r9", "world": false,
				"title": "R9: a shown, blend-shaped outline that leaves the tree and comes back goes on following its source's blend shapes"},
		{"name": "o06_no_gaps", "method": "case_o06", "world": false,
				"title": "O06: a box's outline mesh has one normal at each corner, so its shells have no gaps"},
		{"name": "o07_left_out", "method": "case_o07", "world": false,
				"title": "O07: a mesh in the group no_outline is left out, and a drawer outlines exactly the mesh it names, never its shelved balls"},
		{"name": "o08_moving_sock", "method": "case_o08", "world": false,
				"title": "O08: a Sock flying under the crosshair (a flight with a Looks) is outlined like a lying one"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	_stand(BY_SOCKS)
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _sock_outline(SOCK) != null and _sock_outline(SOCK).outlined_count() > 0,
			"the aimed Sock to show its outline")
	var sock_outline := _sock_outline(SOCK)
	_check(SockDress.state_of(sock_outline.get_parent()) == SockDress.AIMED, "the Sock's Looks plays aimed")
	_stand(BY_CABINET)
	await _aim(_drawer_front(1))
	var drawer := _outline_of("Cabinet/Drawer2/Looks/Outline")
	await _until(func() -> bool: return drawer.outlined_count() == 1, "the aimed drawer to show its outline")
	_check(_player.aimed_outline == drawer, "the player's aim names the drawer's outline")
	_check(not is_instance_valid(sock_outline) or sock_outline.outlined_count() == 0, "the Sock's outline went")
	_stand(BY_DOOR)
	await _aim(_door_point())
	var door := _outline_of("Door/Looks/Outline")
	await _until(func() -> bool: return door.outlined_count() == 1, "the aimed Door to show its outline")
	_check(drawer.outlined_count() == 0 and not drawer.visible, "the drawer's outline went")
	_check(_copies_visible(door), "the Door's outline copy is drawn")


# --- The behaviour lines -------------------------------------------------------------------------

func case_o01() -> void:
	await _build()
	_stand(BY_DOOR)
	await _aim(_door_point())
	var door := _outline_of("Door/Looks/Outline")
	await _until(func() -> bool: return door.outlined_count() == 1, "the Door to be outlined")
	var style := door.current_style()
	_check(style == Outline.AIM, "it draws in the aim style")
	_check(style.colour.is_equal_approx(Color(1.0, 0.94, 0.82)), "warm white (%s)" % style.colour)
	var copy := door.copies()[0]
	var mask := copy.material_override as ShaderMaterial
	_check(mask != null and mask.shader == OutlineStyle.MASK_SHADER, "the first pass is the stencil mask")
	_check(mask.shader.code.contains("stencil_mode write"), "the mask writes the shape into the stencil")
	var shells := style.shell_materials()
	_check(shells.size() == 3, "three shells (%d)" % shells.size())
	var grows: Array[float] = []
	var alphas: Array[float] = []
	for s in shells:
		grows.append(float(s.get_shader_parameter(&"grow")))
		alphas.append(float(s.get_shader_parameter(&"strength")))
		_check(Color(s.get_shader_parameter(&"colour")).is_equal_approx(style.colour), "each shell is warm white")
	_check(grows[0] < grows[1] and grows[1] < grows[2], "each shell is wider than the one inside it (%s)" % [grows])
	_check(alphas[0] > alphas[1] and alphas[1] > alphas[2], "each shell is fainter than the one inside it (%s)" % [alphas])
	var code := OutlineStyle.SHELL_SHADER.code
	_check(code.contains("stencil_mode read, compare_not_equal"), "the shells draw only outside the shape")
	_check(code.contains("max(-v.z"), "the growth is times the distance to the camera: one width on screen near and far")


func case_o02() -> void:
	await _build()
	_stand(BY_DOOR)
	await _aim(_door_point())
	var door := _outline_of("Door/Looks/Outline")
	await _until(func() -> bool: return door.outlined_count() == 1, "the Door to be outlined")
	# The crosshair leaves it: up at the sky.
	await _aim(_player.global_position + Vector3(0.0, 20.0, -1.0))
	await _until(func() -> bool: return door.outlined_count() == 0, "the outline to go")
	_check(not door.shown and not _copies_visible(door), "nothing of it is drawn")
	_check(_player.aimed_outline == null, "the aim names no outline")
	# Back on it, then out of reach: the same line, from farther than the reach.
	await _aim(_door_point())
	await _until(func() -> bool: return door.outlined_count() == 1, "the outline to come back")
	var reach := _player.hands_tuning.reach
	_stand(BY_DOOR + Vector3(0.0, 0.0, reach + 0.5))
	await _aim(_door_point())
	await _until(func() -> bool: return door.outlined_count() == 0, "the outline to go out of reach")
	_check(not door.shown, "out of reach it is not shown")


func case_o03() -> void:
	await _build()
	# A lying Sock.
	_stand(BY_SOCKS)
	await _aim(_centre(OTHER))
	await _until(func() -> bool: return _sock_outline(OTHER) != null and _sock_outline(OTHER).outlined_count() > 0,
			"a lying Sock to be outlined")
	# A lying Pair: pair two Socks and drop the Pair on the floor before the player.
	await _take(SOCK)
	await _take(MATE)
	_check(_mess.is_pair(SOCK), "the Sock and its mate are a Pair")
	var spot := _station.to_global(Vector3(-0.8, 0.0, 0.2))
	_hands.drop(1, spot, Vector3.UP)
	await _until(func() -> bool: return _mess.state_of(SOCK) == Mess.State.LYING, "the Pair to lie")
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _sock_outline(SOCK) != null and _sock_outline(SOCK).outlined_count() > 0,
			"the lying Pair to be outlined")
	# The drawer, the Door, the cupboard and the box (no Part: the component alone).
	_stand(BY_CABINET)
	await _aim(_drawer_front(0))
	await _until(func() -> bool: return _outline_of("Cabinet/Drawer1/Looks/Outline").outlined_count() == 1, "a drawer to be outlined")
	_stand(BY_DOOR)
	await _aim(_door_point())
	await _until(func() -> bool: return _outline_of("Door/Looks/Outline").outlined_count() == 1, "the Door to be outlined")
	await _aim(_station.to_global(Vector3(2.2, 1.0, -1.35)))
	var cupboard := _outline_of("Cupboard/Looks/Outline")
	await _until(func() -> bool: return cupboard.outlined_count() >= 1, "the cupboard to be outlined")
	_check(cupboard.outlined_count() == cupboard.sources().size(), "every mesh of the cupboard is outlined")
	_stand(Vector3(-2.0, 0.0, 0.2))
	await _aim((_station.get_node("Box") as Node3D).global_position)
	var box := _outline_of("Box/Outline")
	await _until(func() -> bool: return box.outlined_count() == 1, "the box to be outlined")
	_check(Parts.part_of(_station.get_node("Box")) == null, "the box has no Part: the component alone outlines it")


func case_o04() -> void:
	await _build()
	var styles: Array[OutlineStyle] = []
	_stand(BY_CABINET)
	await _aim(_drawer_front(0))
	var bottom := _outline_of("Cabinet/Drawer1/Looks/Outline")
	await _until(func() -> bool: return bottom.outlined_count() == 1, "a drawer to be outlined")
	styles.append(bottom.current_style())
	_stand(BY_DOOR)
	await _aim(_door_point())
	var door := _outline_of("Door/Looks/Outline")
	await _until(func() -> bool: return door.outlined_count() == 1, "the Door to be outlined")
	styles.append(door.current_style())
	_check(styles[0] == styles[1] and styles[0] == Outline.AIM, "the drawer and the Door have the same outline")
	# Empty Hands at the top drawer (above the Rows: no room): no tint.
	var top := _outline_of("Cabinet/Drawer3/Looks/Outline")
	_stand(BY_CABINET)
	await _aim(_drawer_front(2))
	await _until(func() -> bool: return top.outlined_count() == 1, "the top drawer to be outlined")
	_check(top.current_style() == Outline.AIM, "with empty Hands it says nothing")
	# A Pair held: the top drawer turns red, the bottom one (room) stays warm white.
	_stand(BY_SOCKS)
	await _take(SOCK)
	await _take(MATE)
	_check(_mess.is_pair(SOCK), "a Pair is held")
	_stand(BY_CABINET)
	await _aim(_drawer_front(2))
	await _until(func() -> bool: return top.current_style() == Player.FULL_OUTLINE, "the top drawer to take the full tint")
	_check(top.copies()[0].material_override == Player.FULL_OUTLINE.material(), "its copy draws in red")
	_check(Player.FULL_OUTLINE.colour.r > 0.9 and Player.FULL_OUTLINE.colour.g < 0.4, "the tint is red")
	await _aim(_drawer_front(0))
	await _until(func() -> bool: return bottom.outlined_count() == 1, "the bottom drawer to be outlined")
	_check(bottom.current_style() == Outline.AIM, "a drawer with room has the plain outline")
	_check(top.tint == null and top.outlined_count() == 0, "the top drawer lost its outline and tint")


func case_o05() -> void:
	await _build()
	# A skinned Sock: the copy shares its source's skin and skeleton.
	_stand(BY_SOCKS)
	await _aim(_centre(SOCK))
	await _until(func() -> bool: return _sock_outline(SOCK) != null and _sock_outline(SOCK).outlined_count() > 0,
			"the Sock to be outlined")
	var outline := _sock_outline(SOCK)
	var copy := outline.copies()[0]
	var source := copy.get_parent() as MeshInstance3D
	_check(source != null and source.skin != null, "the Sock's mesh is skinned")
	_check(copy.skin == source.skin, "the outline keeps its skin")
	var skel := source.get_node_or_null(source.skeleton) as Skeleton3D
	_check(skel != null and copy.get_node_or_null(copy.skeleton) == skel, "the outline follows the same bones")
	# A drawer slides open: its outline goes with it.
	_stand(BY_CABINET)
	await _aim(_drawer_front(0))
	var bottom := _outline_of("Cabinet/Drawer1/Looks/Outline")
	await _until(func() -> bool: return bottom.outlined_count() == 1, "the drawer to be outlined")
	var drawer_copy := bottom.copies()[0]
	var shut_at := drawer_copy.global_position
	var mesh := _station.get_node("Cabinet/Drawer1/Looks/Slide/Mesh") as MeshInstance3D
	(_station.get_node("Cabinet/Cabinet") as Cabinet).drawer(0).use(1)
	await _until(func() -> bool: return mesh.global_position.distance_to(shut_at) > 0.3, "the drawer to slide open")
	_near(drawer_copy.global_position.distance_to(mesh.global_position), 0.0, 0.0001, "the outline slid with the drawer")


func case_r9() -> void:
	# A mesh with one blend shape, outlined by an Outline child that is shown.
	var base := BoxMesh.new()
	var arrays := base.get_mesh_arrays()
	var mesh := ArrayMesh.new()
	mesh.add_blend_shape(&"squash")
	var shape: Array = []
	shape.resize(Mesh.ARRAY_MAX)
	for k: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT]:
		shape[k] = arrays[k]
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [shape])
	var holder := Node3D.new()
	add_child(holder)
	var source := MeshInstance3D.new()
	source.mesh = mesh
	holder.add_child(source)
	var outline := Outline.new()
	outline.meshes = [^".."]
	outline.shown = true
	source.add_child(outline)
	await _frames(2)
	_check(outline.outlined_count() == 1 and source.get_blend_shape_count() == 1, "the blend-shaped mesh is outlined")
	_check(outline.is_processing(), "a shown outline of a blend-shaped mesh is processing")
	source.remove_child(outline)
	_check(not outline.is_processing(), "out of the tree it is not")
	source.add_child(outline)
	_check(outline.is_processing(), "back in the tree it processes again")
	holder.free()


func case_o06() -> void:
	var box := BoxMesh.new()
	var smooth := Outline.smoothed(box)
	_check(Outline.smoothed(box) == smooth, "the smoothed mesh is made once per mesh")
	var arrays := smooth.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var at: Dictionary[Vector3, Vector3] = {}
	var one := true
	var corners := 0
	for i in verts.size():
		var k := verts[i].snapped(Vector3.ONE * Outline.WELD)
		if at.has(k):
			one = one and at[k].is_equal_approx(normals[i])
		else:
			at[k] = normals[i]
			corners += 1
	_check(one, "every corner has one normal")
	_check(corners == 8, "a box has 8 corners (%d)" % corners)
	var corner_normal: Vector3 = at[Vector3(0.5, 0.5, 0.5)]
	_check(corner_normal.is_equal_approx(Vector3.ONE.normalized()), "a corner's normal points out of the corner (%s)" % corner_normal)


func case_o07() -> void:
	await _build()
	# The box gets a lid in the group no_outline: it is left out.
	var box := _station.get_node("Box") as Node3D
	var lid := MeshInstance3D.new()
	lid.mesh = BoxMesh.new()
	lid.add_to_group(Outline.SKIP)
	box.add_child(lid)
	var outline := _outline_of("Box/Outline")
	_check(not outline.sources().has(lid), "a mesh in no_outline is left out")
	_check(outline.sources().size() == 1, "only the box itself is outlined (%d)" % outline.sources().size())
	# A drawer names its front: a shelved ball under a slot is never outlined.
	var slot := _station.get_node("Cabinet/Drawer1/Looks/Slide/Slot01") as Node3D
	var ball := MeshInstance3D.new()
	ball.mesh = SphereMesh.new()
	slot.add_child(ball)
	var drawer := _outline_of("Cabinet/Drawer1/Looks/Outline")
	var named := drawer.sources()
	_check(named.size() == 1 and named[0] == _station.get_node("Cabinet/Drawer1/Looks/Slide/Mesh"), "the drawer outlines exactly its named mesh")
	_stand(BY_CABINET)
	await _aim(_drawer_front(0))
	await _until(func() -> bool: return drawer.outlined_count() == 1, "the drawer to be outlined")
	_check(ball.get_child_count(true) == 0, "the ball has no outline copy")


func case_o08() -> void:
	await _build()
	_stand(BY_SOCKS)
	await _take(OTHER)
	# A lob straight up in front of the player.
	await _aim(_player.global_position + Vector3(0.0, 6.0, -1.0))
	_hands.throw(1, _player.aim_dir(), 0.3)
	await _until(func() -> bool:
			var body := _mess.flight_of(OTHER)
			return body != null and body.has_node(Mess.LOOKS), "the thrown Sock to fly with a Looks")
	var seen := false
	for i in 120:
		var body := _mess.flight_of(OTHER)
		if body == null:
			break
		await _aim(body.global_position)
		var looks_outline := Outline.of(body)
		if _player.aimed_sock == OTHER and looks_outline != null and looks_outline.outlined_count() > 0 \
				and _player.aimed_outline == looks_outline:
			seen = true
			break
	_check(seen, "the flying Sock under the crosshair shows its outline")


# --- Helpers -------------------------------------------------------------------------------------

## A floor, the station, a Parts and the player standing at BY_SOCKS.
func _build() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = _station.position + BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	await _until(func() -> bool: return _player.is_on_floor() and _mess.count() == 4, "the player to stand and the Socks to lie")


## Puts the player at `spot` in station space.
func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(target: Vector3) -> void:
	var head := _player.get_node("Head") as Node3D
	var to := target - _player.global_position
	_player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Takes Sock `sock` into the Hands by the Hands' own Command, past the grab interval.
func _take(sock: int) -> void:
	_hands.clock += 10.0
	_hands.pick(1, sock)
	await _physics_ticks(1)
	_check(_hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d is taken" % sock)


func _centre(sock: int) -> Vector3:
	return _mess.box_of(sock).get_center()


## The front of drawer `index` (0 the bottom), in the level.
func _drawer_front(index: int) -> Vector3:
	var slide := _station.get_node("Cabinet/Drawer%d/Looks/Slide" % (index + 1)) as Node3D
	return slide.global_transform * Vector3(0.0, 0.14, 0.25)


func _door_point() -> Vector3:
	return (_station.get_node("Door/Looks/Hinge") as Node3D).global_transform * Vector3(0.45, 1.3, 0.025)


func _outline_of(path: String) -> Outline:
	return _station.get_node(path) as Outline


## The Outline of the Looks a lying Sock is lent now (named Sock<id> under the station's Lying), or
## null while it has none. Never lends one itself.
func _sock_outline(sock: int) -> Outline:
	var looks := _station.get_node_or_null("Lying/Sock%d" % sock)
	return looks.get_node_or_null(^"Outline") as Outline if looks != null else null


func _copies_visible(outline: Outline) -> bool:
	for c in outline.copies():
		if not c.is_visible_in_tree():
			return false
	return outline.copies().size() > 0
