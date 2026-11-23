## The old house's 67 furniture pieces (assets/04 F02-F04): each a scene with its model's Looks, its old
## collision on the house layer, its openings the cupboard way (an Openable, a Looks whose moving parts
## are AnimatableBody3Ds named as in the old model, "open" and "shut" as the old swing) and its Sock
## spots; origins at the floor centre of the bounding box, +Z front; every surface wears the shared
## library; the Furniture station lines them all up from the folder. The real path: the player walks to
## the kitchen cupboard in the station, uses its door and sees it swing open onto the shelf inside.
extends TestSuite

const FOLDER := "res://game/furniture"
const STATION := "res://game/zoo/stations/furniture.tscn"
const LAYOUT := "res://game/zoo/furniture/furniture_line_up_layout.tres"
const PLAYER := "res://game/player/player.tscn"
const LIBRARY := "res://game/materials/"
## The old manifest's numbers (docs/migration/assets-inventory.md section 2): 67 pieces; 28 containers
## (every moving part but the piano's 88 keys opens one); 31 such parts; the spots joined as the old
## game joined them (tools/furniture_from_old.py): 584 rects.
const PIECES := 67
## The car's old Cabin is one opening per door since assets/09: 29 openings.
const OPENINGS := 29
const MOVING := 31
const KEYS := 88
const SPOT_RECTS := 584
## The old swing (game/house/openable.gd of the reference): 0.35 s.
const SWING := 0.35
const TEMP := "user://furniture_test"

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Furniture station the player walks to the kitchen cupboard, uses its door: it swings open by its old angle and the inside is in sight"},
		{"name": "f02_pieces", "method": "case_f02_pieces", "world": false,
				"title": "F02: every old piece is a scene: a StaticBody3D on the house layer with its collision, its model's Looks, its openings and their Looks to the contracts"},
		{"name": "f02_openings", "method": "case_f02_openings", "world": false,
				"title": "F02: the openings are the old containers with their named moving parts (Door, Drawer_n, Lid, ...), each with collision; the piano keeps its 88 keys"},
		{"name": "f02_swing", "method": "case_f02_swing", "world": false,
				"title": "F02: open turns a hinge by its old angle about its old axis and slides a drawer its old distance, in the old 0.35 s; shut brings it back"},
		{"name": "f02_player_boxes", "method": "case_f02_player_boxes", "world": false,
				"title": "F02 (Q2397): the player meets the old coarse player boxes and walks past a chair without snagging; a Sock passes them and lands on the seat"},
		{"name": "f02_spots", "method": "case_f02_spots", "world": false,
				"title": "F02: the Sock spots are rects on the piece's tops, inside its footprint and under its headroom, on no physics layer"},
		{"name": "f02_materials", "method": "case_f02_materials", "world": false,
				"title": "F02: every surface of every piece wears a material of the shared library"},
		{"name": "f04_origins", "method": "case_f04_origins", "world": false,
				"title": "F04: every piece's origin is the floor centre of its bounding box, the size its old footprint and height, +Z front"},
		{"name": "f03_station", "method": "case_f03_station", "world": false,
				"title": "F03: the Furniture station shows every piece once, its name in front, on the station's pad and ground"},
		{"name": "f03_from_data", "method": "case_f03_from_data", "world": false,
				"title": "F03 (Q2337): a new piece scene in the folder appears in the line-up with no other change"},
		{"name": "h09_insides_on_floors", "method": "case_h09_insides_on_floors", "world": false,
				"title": "house/09: every opening's Inside box has its bottom on the piece's collision floor (within the Sock generator's rest slack), so Socks can be laid inside"},
	]


func _before_case() -> void:
	for a: StringName in [&"move_forward", &"interact"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


static func _scene(path: String) -> StaticBody3D:
	return (load(path) as PackedScene).instantiate() as StaticBody3D


## Every opening holder of a piece: a child holding an Openable.
static func _openings(piece: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child in piece.get_children():
		if child.get_node_or_null("Openable") is Openable:
			out.append(child as Node3D)
	return out


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	station.name = "Furniture"
	_level.add_child(station)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	await _frames(1)
	var line_up := station.get_node("LineUp") as FurnitureLineUp
	var cupboard := line_up.piece("kitchen_cupboard")
	_check(cupboard != null, "the line-up has the kitchen cupboard")
	if cupboard == null:
		return
	var door := cupboard.get_node("Door") as Node3D
	var openable := door.get_node("Openable") as Openable
	var leaf := door.get_node("Looks/Door") as AnimatableBody3D
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	# In the gap before the cupboard's row (the row in front stands row_gap away).
	player.position = cupboard.to_global(Vector3(0.0, 0.0, 1.15))
	player.rotation.y = 0.0
	_level.add_child(player)
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return cupboard.to_local(player.global_position).z < 1.05, "the player to walk up to the cupboard")
	Input.action_release(&"move_forward")
	await _physics_ticks(10)
	# Look at the door's middle, as the mouse would.
	var target := cupboard.to_global(Vector3(0.0, 0.3, 0.28))
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(3)
	var inside := cupboard.to_global(Vector3(0.0, 0.15, 0.0))   # inside, over its bottom (0.1)
	var eye := player.camera().global_position
	var before := PhysicsQueries.ray(_level, eye, inside, 1)
	_check(not before.is_empty() and before["collider"] == leaf, "shut, the door is between the player and the inside (%s at %s; eye %s)"
			% [before.get("collider"), cupboard.to_local(before.get("position", Vector3.ZERO)), cupboard.to_local(eye)])
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return openable.open, "the door to open")
	await _until(func() -> bool: return not openable.is_moving(), "its swing to end", 120)
	await _physics_ticks(2)
	_near(leaf.rotation.y, deg_to_rad(-100.0), 0.01, "the door stands open by the old 100 degrees")
	var after := PhysicsQueries.ray(_level, eye, inside, 1)
	_check(after.is_empty() or after["collider"] != leaf, "open, the inside is in sight")


# --- F02 -----------------------------------------------------------------------------------------

func case_f02_pieces() -> void:
	var paths := FurnitureLineUp.pieces()
	_check(paths.size() == PIECES, "every old piece has a scene (%d of %d)" % [paths.size(), PIECES])
	for path in paths:
		var stem := path.get_file().get_basename()
		var piece := _scene(path)
		_check(piece != null, "%s is a StaticBody3D" % stem)
		if piece == null:
			continue
		_check(piece.collision_layer == Mess.LAYER_HOUSE and piece.collision_mask == 0, "%s is on the house layer" % stem)
		var shapes := piece.find_children("Shape*", "CollisionShape3D", false, false)
		_check(not shapes.is_empty(), "%s has its collision" % stem)
		var looks := piece.get_node_or_null("Looks") as Node3D
		_check(looks != null and looks.scene_file_path == "%s/looks/looks_%s.tscn" % [FOLDER, stem], "%s wears its Looks" % stem)
		if looks != null:
			_check(looks.get_node_or_null("Body") is MeshInstance3D, "%s's Looks has its Body" % stem)
		for o in _openings(piece):
			var ol := o.get_node_or_null("Looks")
			_check(ol != null and ol.scene_file_path.begins_with(FOLDER + "/parts/looks_%s_" % stem), "%s/%s has its Looks" % [stem, o.name])
			if ol == null:
				continue
			var anim := ol.get_node_or_null("AnimationPlayer") as AnimationPlayer
			_check(anim != null and anim.has_animation(Openable.ANIMATION) and anim.has_animation(Openable.SHUT)
					and anim.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS,
					"%s/%s opens and shuts on physics frames" % [stem, o.name])
			_check(ol.get_node_or_null("Outline") is Outline, "%s/%s has an Outline" % [stem, o.name])
		piece.free()


func case_f02_openings() -> void:
	var openings := 0
	var moving := 0
	var keys := 0
	for path in FurnitureLineUp.pieces():
		var piece := _scene(path)
		var stem := path.get_file().get_basename()
		for o in _openings(piece):
			openings += 1
			for body: Node in o.get_node("Looks").find_children("*", "AnimatableBody3D", false, false):
				moving += 1
				var name := String(body.name)
				_check(name.begins_with("Door") or name.begins_with("Drawer_") or name in ["Lid", "Flap", "Boot"],
						"%s/%s is named as in the old model" % [stem, name])
				_check(body.get_node_or_null("Mesh") is MeshInstance3D, "%s/%s has its mesh" % [stem, name])
				_check(not body.find_children("Shape*", "CollisionShape3D", false, false).is_empty(), "%s/%s has collision" % [stem, name])
				_check((body as AnimatableBody3D).collision_layer == Mess.LAYER_HOUSE, "%s/%s is on the house layer" % [stem, name])
			var inside := o.get_node_or_null("Inside") as Area3D
			_check(inside != null and inside.collision_layer == 0, "%s/%s has its inside, on no layer" % [stem, o.name])
		for k: Node in piece.get_node("Looks").get_children():
			if String(k.name).begins_with("Key_"):
				keys += 1
				_check(int(k.get_meta(&"midi", -1)) == String(k.name).trim_prefix("Key_").to_int(), "%s carries its note" % k.name)
		piece.free()
	_check(openings == OPENINGS, "the old containers are the openings (%d of %d)" % [openings, OPENINGS])
	_check(moving == MOVING, "with every old moving part (%d of %d)" % [moving, MOVING])
	_check(keys == KEYS, "the piano keeps its keys (%d of %d)" % [keys, KEYS])


func case_f02_swing() -> void:
	_level = _scene(FOLDER.path_join("kitchen_cupboard.tscn"))
	add_child(_level)
	await _physics_ticks(3)
	var cases := [["Door", "Door", "rotation", Vector3(0.0, deg_to_rad(-100.0), 0.0)],
			["Drawer_1", "Drawer_1", "position", Vector3(0.0, 0.7, 0.2601 + 0.38)]]
	for c: Array in cases:
		var ol := _level.get_node("%s/Looks" % c[0])
		var anim := ol.get_node("AnimationPlayer") as AnimationPlayer
		var body := ol.get_node(String(c[1])) as Node3D
		var shut_at: Vector3 = body.get(c[2])
		_near(anim.get_animation(Openable.ANIMATION).length, SWING, 0.001, "%s swings in the old time" % c[0])
		anim.play(Openable.ANIMATION)
		anim.seek(SWING, true)
		await _physics_ticks(1)
		_check((body.get(c[2]) as Vector3).is_equal_approx(c[3]), "%s opens to %s (%s)" % [c[0], c[3], body.get(c[2])])
		anim.play(Openable.SHUT)
		anim.seek(SWING, true)
		await _physics_ticks(1)
		_check((body.get(c[2]) as Vector3).is_equal_approx(shut_at), "%s shuts back" % c[0])
		# Easing out: past the middle of the way at the middle of the time, as the old sine.
		anim.play(Openable.ANIMATION)
		anim.seek(SWING / 2.0, true)
		anim.pause()
		await _physics_ticks(1)
		var half := (body.get(c[2]) as Vector3 - shut_at).length() / (c[3] as Vector3 - shut_at).length()
		_check(half > 0.65 and half < 0.75, "%s eases out (%.2f of the way at half time)" % [c[0], half])


func case_f02_player_boxes() -> void:
	# Every piece but a rug has its player boxes on the layer only players meet.
	for path in FurnitureLineUp.pieces():
		var piece := _scene(path)
		var body := piece.get_node_or_null("PlayerBody") as StaticBody3D
		if piece.get_meta(&"rug", false):
			_check(body == null, "%s, a rug, is walked over" % piece.name)
		else:
			_check(body != null and body.collision_layer == Player.BLOCK_LAYER and body.get_child_count() > 0, "%s has its player boxes" % piece.name)
		piece.free()
	_level = Node3D.new()
	_level.name = "Level"
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 0.2, 10)
	shape.shape = box
	shape.position = Vector3(0, -0.1, 0)
	ground.add_child(shape)
	_level.add_child(ground)
	var chair := _scene(FOLDER.path_join("dining_chair.tscn"))
	_level.add_child(chair)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	player.position = Vector3(-0.6, 0.0, 0.9)
	player.rotation.y = 0.0
	_level.add_child(player)
	add_child(_level)
	_check(player.collision_mask & Player.BLOCK_LAYER != 0 and player.collision_mask & Mess.LAYER_HOUSE != 0, "the player meets the house and the player boxes")
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand")
	# Forward and right: into the chair's front at a slant, along it and past it.
	Input.action_press(&"move_forward")
	Input.action_press(&"move_right")
	var touched := [false]
	var passed := await _until(func() -> bool:
		for i in player.get_slide_collision_count():
			if player.get_slide_collision(i).get_collider() == chair.get_node("PlayerBody"):
				touched[0] = true
		return player.global_position.x > 0.9, "the player to slide past the chair", 300)
	Input.action_release(&"move_forward")
	Input.action_release(&"move_right")
	_check(passed and touched[0], "the player met the chair's player boxes and slid on past it (%s, met %s)" % [player.global_position, touched[0]])
	_check(player.global_position.y < 0.05, "on the floor, not up on the chair (%s)" % player.global_position)
	# A Sock-sized body on the Socks' layers falls through the player boxes onto the seat.
	var flight := (load("res://game/sock/flight.tscn") as PackedScene).instantiate() as RigidBody3D
	var mask := flight.collision_mask
	flight.free()
	var sock := RigidBody3D.new()
	sock.collision_layer = Mess.LAYER_FLIGHT
	sock.collision_mask = mask
	var cs := CollisionShape3D.new()
	var sb := BoxShape3D.new()
	sb.size = Vector3(0.25, 0.03, 0.1)
	cs.shape = sb
	sock.add_child(cs)
	sock.position = Vector3(0.0, 1.4, 0.05)
	_level.add_child(sock)
	await _physics_ticks(5)
	await _until(func() -> bool: return sock.linear_velocity.length() < 0.01, "the Sock to come to rest", 400)
	var seat := (chair.get_node("Spots").get_child(0) as Node3D)
	var seat_y := seat.position.y - ((seat.get_node("Box") as CollisionShape3D).shape as BoxShape3D).size.y / 2.0
	_near(sock.position.y, seat_y + 0.015, 0.03, "the Sock lies on the seat (seat top %.3f)" % seat_y)


func case_f02_spots() -> void:
	var total := 0
	for path in FurnitureLineUp.pieces():
		var piece := _scene(path)
		var stem := path.get_file().get_basename()
		var fp: Array = piece.get_meta(&"footprint")
		var spots := piece.get_node_or_null("Spots")
		if spots != null:
			for top: Node in spots.get_children():
				total += 1
				var area := top as Area3D
				var box := (area.get_node("Box") as CollisionShape3D).shape as BoxShape3D
				var lo := area.position - box.size / 2.0
				var hi := area.position + box.size / 2.0
				_check(area.collision_layer == 0 and area.collision_mask == 0 and not area.monitoring, "%s/%s is on no layer" % [stem, top.name])
				_check(lo.x >= -float(fp[0]) / 2.0 - 0.05 and hi.x <= float(fp[0]) / 2.0 + 0.05 and lo.z >= -float(fp[1]) / 2.0 - 0.05
						and hi.z <= float(fp[1]) / 2.0 + 0.05, "%s/%s lies in the footprint" % [stem, top.name])
				_check(lo.y >= 0.05 and box.size.y >= 0.12 - 0.001, "%s/%s is a top over the floor with headroom" % [stem, top.name])
		piece.free()
	_check(total == SPOT_RECTS, "the old spots, joined (%d of %d)" % [total, SPOT_RECTS])


func case_f02_materials() -> void:
	for path in FurnitureLineUp.pieces():
		var piece := _scene(path)
		for mi: Node in piece.find_children("*", "MeshInstance3D", true, false):
			if mi.get_parent() is Mirror:
				continue  # the wall mirror's glass is the device's own shader (assets/07)
			var mesh := (mi as MeshInstance3D).mesh
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				_check(mat != null and mat.resource_path.begins_with(LIBRARY), "%s %s surface %d wears the library (%s)"
						% [path.get_file(), mi.name, s, mat.resource_path if mat != null else "none"])
		piece.free()


# --- F04 -----------------------------------------------------------------------------------------

func case_f04_origins() -> void:
	for path in FurnitureLineUp.pieces():
		var piece := _scene(path)
		var stem := path.get_file().get_basename()
		var box := AABB()
		var first := true
		for mi: Node in piece.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var xf := Transform3D()
			var n: Node = m
			while n != piece:
				xf = (n as Node3D).transform * xf
				n = n.get_parent()
			var b := xf * m.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		var fp: Array = piece.get_meta(&"footprint")
		_near(box.position.y, 0.0, 0.01, "%s stands on its origin" % stem)
		_near(box.get_center().x, 0.0, 0.02, "%s is centred across" % stem)
		_near(box.get_center().z, 0.0, 0.02, "%s is centred front to back" % stem)
		_near(box.size.x, float(fp[0]), 0.03, "%s is its old width" % stem)
		_near(box.size.z, float(fp[1]), 0.03, "%s is its old depth" % stem)
		_near(box.end.y, float(piece.get_meta(&"height")), 0.03, "%s is its old height" % stem)
		piece.free()


# --- F03 -----------------------------------------------------------------------------------------

func case_f03_station() -> void:
	_level = (load(STATION) as PackedScene).instantiate() as Node3D
	add_child(_level)
	await _frames(1)
	var line_up := _level.get_node("LineUp") as FurnitureLineUp
	var pad := _level.get_node("Pad") as MeshInstance3D
	var pbox := pad.global_transform * pad.get_aabb()
	var ground := (_level.get_node("Ground/Shape") as CollisionShape3D)
	var gbox := ground.global_transform * (ground.shape as BoxShape3D).get_debug_mesh().get_aabb()
	var paths := FurnitureLineUp.pieces()
	_check(line_up.get_child_count() == paths.size(), "the line-up shows every piece once (%d of %d)" % [line_up.get_child_count(), paths.size()])
	for path in paths:
		var stem := path.get_file().get_basename()
		var p := line_up.piece(stem)
		_check(p != null and p.scene_file_path == path, "the line-up shows %s" % stem)
		if p == null:
			continue
		var fp: Array = p.get_meta(&"footprint")
		for corner: Vector3 in [Vector3(-float(fp[0]) / 2.0, 0.0, -float(fp[1]) / 2.0), Vector3(float(fp[0]) / 2.0, 0.0, float(fp[1]) / 2.0)]:
			var at := p.to_global(corner)
			_check(at.x > pbox.position.x and at.x < pbox.end.x and at.z > pbox.position.z and at.z < pbox.end.z, "%s stands on the pad" % stem)
			_check(at.x > gbox.position.x and at.x < gbox.end.x and at.z > gbox.position.z and at.z < gbox.end.z, "%s stands on the ground" % stem)
		var title := p.get_node_or_null("Name") as Label3D
		_check(title != null and title.text == p.name and title.position.z > float(fp[1]) / 2.0, "%s has its name in front" % stem)


func case_f03_from_data() -> void:
	_remove_temp()
	DirAccess.make_dir_recursive_absolute(TEMP)
	for stem: String in ["trunk", "doormat"]:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(FOLDER.path_join(stem + ".tscn")), ProjectSettings.globalize_path(TEMP.path_join(stem + ".tscn")))
	var fresh := StaticBody3D.new()
	fresh.name = "BrandNew"
	fresh.set_meta(&"footprint", [0.5, 0.5])
	var packed := PackedScene.new()
	packed.pack(fresh)
	ResourceSaver.save(packed, TEMP.path_join("brand_new.tscn"))
	fresh.free()
	_level = Node3D.new()
	var line_up := FurnitureLineUp.new()
	line_up.layout = load(LAYOUT) as FurnitureLineUpLayout
	line_up.folder = TEMP
	_level.add_child(line_up)
	add_child(_level)
	await _frames(1)
	_check(line_up.piece("brand_new") != null, "the new piece stands in the line-up")
	_check(line_up.piece("trunk") != null and line_up.piece("doormat") != null, "beside the others")
	_check(line_up.get_child_count() == 3, "and nothing else (%d)" % line_up.get_child_count())
	_level.free()
	_level = null
	_remove_temp()


func _remove_temp() -> void:
	var dir := DirAccess.open(TEMP)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	DirAccess.remove_absolute(TEMP)


# --- Insides (house/09) --------------------------------------------------------------------------

## Every opening's Inside, shut, at the origin: a ray down through the middle of its floor and of each
## of its four quarters, from 5 cm over the box's bottom, meets the piece's collision (the house layer)
## within the generator's rest slack of the bottom: what the laying's rays need to lay a Sock inside.
func case_h09_insides_on_floors() -> void:
	var slack := (load("res://game/mess/sock_generator_tuning.tres") as SockGeneratorTuning).rest_slack
	var insides := 0
	var off: Array[String] = []
	for path in FurnitureLineUp.pieces():
		var piece := _scene(path)
		add_child(piece)
		for o in _openings(piece):
			var inside := o.get_node_or_null("Inside") as Area3D
			if inside == null:
				continue
			for shape_node in inside.get_children():
				var shape := shape_node as CollisionShape3D
				if shape == null or not (shape.shape is BoxShape3D):
					continue
				insides += 1
				var size := (shape.shape as BoxShape3D).size
				var gaps: Array[float] = []
				for q: Vector2 in [Vector2.ZERO, Vector2(-0.25, -0.25), Vector2(0.25, -0.25), Vector2(-0.25, 0.25), Vector2(0.25, 0.25)]:
					var bottom := shape.global_transform * Vector3(q.x * size.x, -size.y * 0.5, q.y * size.z)
					var hit := PhysicsQueries.ray(piece, bottom + Vector3.UP * 0.05, bottom + Vector3.DOWN * 0.5, Mess.LAYER_HOUSE)
					gaps.append(bottom.y - (hit["position"] as Vector3).y if not hit.is_empty() else INF)
				if gaps.any(func(g: float) -> bool: return absf(g) > slack):
					off.append("%s/%s: %s" % [path.get_file().get_basename(), o.name, gaps])
		remove_child(piece)
		piece.free()
	for line in off:
		Log.info("furniture", "house/09: an Inside off its floor: " + line)
	_check(insides == OPENINGS, "every opening has its Inside box (%d of %d)" % [insides, OPENINGS])
	_check(off.is_empty(), "every Inside's bottom lies on its piece's floor within %.2f m (%d do not: %s)" % [slack, off.size(), off])
