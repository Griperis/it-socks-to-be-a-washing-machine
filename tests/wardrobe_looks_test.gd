## The Wardrobe's pieces as Looks (assets/18, 19): the 78 hats and clothes and the 17 Socks pieces, the
## old models in game/wardrobe/looks/, each put on an AvatarLooks as wardrobe.md "The dressed Avatar" says
## (a hat under HatPoint, clothes under the Body skinned to its Skeleton3D, a Socks pair's sock_l and sock_r
## on FootL and FootR at identity) without an error; the clothes keep their Crouch and Swish keys; the rare
## touches play from the Looks' own autoplay `touch` clip and Drops. The 17 Trails' meshes are mesh
## resources (assets/wardrobe/meshes/<id>_a.res ...) saved by their glbs' import.
## A look ticket (Q2421): no real-path case; the designer judges the line-up.
extends TestSuite

const LOOKS := "res://game/wardrobe/looks/"
const AVATAR := "res://game/parts/avatar/looks_avatar.tscn"
## Ten basic pieces and the 17 Collections' two hats and two clothes (no Secrets, Q2682).
const COUNT := 78
const HATS := 40
## The 17 Collections' Socks pieces (the Lost Socks' held back but made, Q2683).
const SOCKS := 17
## Each Trail's meshes, as many as its old glb holds (the old trail parts, in order).
const TRAILS: Dictionary[StringName, int] = {&"lint_puffs": 3, &"turf_prints": 3, &"sprinkles": 5,
		&"bubblegum_pops": 3, &"paw_prints": 2, &"lightning_sparks": 2, &"snowflakes": 3, &"stardust": 3,
		&"juice_drops": 4, &"falling_leaves": 3, &"sprouting_footprints": 2, &"fizz_bubbles": 3,
		&"floating_digits": 4, &"falling_pixels": 3, &"tyre_tracks": 3, &"oil_drips": 5, &"tumbling_socks": 4}
const MESHES := "res://assets/wardrobe/meshes/"
## The pieces whose old glb has the "SwishL" and "SwishR" keys.
const SWISH: Array[StringName] = [&"antenna_band", &"bee_wings", &"hero_cape", &"jetpack", &"tiger_tail"]
## The old touches (data/tuning/wardrobe.json "touches") of these hats and clothes, by kind.
const WAVE: Array[StringName] = [&"fruit_basket_backpack", &"ivy_wrap", &"onion_layers", &"bubble_tea_backpack",
		&"balloon_backpack", &"tool_belt", &"softener_cape"]
const GLOW: Array[StringName] = [&"calculator_chestplate", &"robot_chest_panel", &"porthole_helmet"]
## The glows whose surfaces pulse together (the old "cycle" off) though they have more than one.
const GLOW_TOGETHER: Array[StringName] = [&"glowing_odd_socks"]
const DROPS: Array[StringName] = [&"detergent_cap_crown", &"hose_scarf"]


func cases() -> Array[Dictionary]:
	return [
		{"name": "dress_every_piece", "method": "case_dress", "world": false,
				"title": "every hat and clothes Looks goes on an AvatarLooks without an error: a hat in the HatPoint's frame, clothes skinned to the Avatar's bones keeping their Crouch (and Swish) keys"},
		{"name": "touches", "method": "case_touches", "world": false,
				"title": "the rare touches play from the Looks alone: a wave moves the Touch key, a glow pulses the _glow surfaces (in turn where the old cycled), drops fall from a GPUParticles3D"},
		{"name": "socks_on_the_feet", "method": "case_socks", "world": false,
				"title": "every Socks piece's Looks has sock_l and sock_r; put on as the Dresser does (its Looks under each foot, only that foot's sock shown, at identity) each sits in its foot's frame, its sole on the floor"},
		{"name": "trail_meshes", "method": "case_trails", "world": false,
				"title": "every Trail's meshes are mesh resources named <id>_a, _b ... (as many as its old glb's parts), each lying on the floor centred on its origin"},
	]


func _ids() -> PackedStringArray:
	var out := PackedStringArray()
	for f: String in ResourceLoader.list_directory(LOOKS):
		if f.ends_with(".tscn") and not _is_socks(f.get_basename()):
			out.append(f.get_basename())
	return out


func _is_socks(id: String) -> bool:
	var piece := Wardrobe.of(StringName(id))
	return piece != null and piece.slot == WardrobePiece.Slot.SOCKS


func _avatar() -> AvatarLooks:
	var a := (load(AVATAR) as PackedScene).instantiate() as AvatarLooks
	add_child(a)
	return a


func case_dress() -> void:
	var ids := _ids()
	_check(ids.size() == COUNT, "%d Looks in %s, found %d" % [COUNT, LOOKS, ids.size()])
	var hats := 0
	var swish: Array[StringName] = []
	for id: String in ids:
		var avatar := _avatar()
		var looks := (load(LOOKS + id + ".tscn") as PackedScene).instantiate() as Node3D
		var meshes := looks.find_children("*", "MeshInstance3D", true, false)
		_check(meshes.size() == 1, "%s has one mesh, found %d" % [id, meshes.size()])
		var mesh := meshes[0] as MeshInstance3D
		var body := avatar.get_node(^"Body") as Node3D
		if mesh.skin == null:
			hats += 1
			var point := body.get_node(^"HatPoint") as Node3D
			point.add_child(looks)
			_check(mesh.global_transform.origin.is_equal_approx(point.global_transform.origin),
					"%s sits in the HatPoint's frame (mesh at %s)" % [id, mesh.global_transform.origin])
		else:
			body.add_child(looks)
			var skeleton := avatar.body().get_parent() as Skeleton3D
			mesh.skeleton = mesh.get_path_to(skeleton)
			_check(mesh.get_node(mesh.skeleton) == skeleton, "%s is skinned to the Avatar's Skeleton3D" % id)
			_check(mesh.find_blend_shape_by_name(&"Crouch") >= 0, "%s keeps its Crouch key" % id)
			for b: int in mesh.skin.get_bind_count():
				_check(skeleton.find_bone(mesh.skin.get_bind_name(b)) >= 0,
						"%s's bone %s is one of the Avatar's" % [id, mesh.skin.get_bind_name(b)])
		if mesh.find_blend_shape_by_name(&"SwishL") >= 0 and mesh.find_blend_shape_by_name(&"SwishR") >= 0:
			swish.append(StringName(id))
		await _frames(1)
		avatar.free()
	_check(hats == HATS, "%d hats and %d clothes, found %d hats" % [HATS, COUNT - HATS, hats])
	swish.sort()
	var want := SWISH.duplicate()
	want.sort()
	_same(swish, want, "the pieces with SwishL and SwishR")


func case_touches() -> void:
	for id: StringName in WAVE + GLOW + GLOW_TOGETHER:
		var avatar := _avatar()
		var looks := (load(LOOKS + id + ".tscn") as PackedScene).instantiate() as Node3D
		var mesh := looks.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		(avatar.get_node(^"Body") as Node3D).add_child(looks)
		var player := looks.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
		_check(player != null and player.autoplay == &"touch", "%s has an autoplay touch clip" % id)
		if player == null:
			avatar.free()
			continue
		_check(player.get_animation(&"touch").loop_mode == Animation.LOOP_LINEAR, "%s's touch loops" % id)
		if id in WAVE:
			var key := mesh.find_blend_shape_by_name(&"Touch")
			_check(key >= 0, "%s has the Touch key" % id)
			await _until(func() -> bool: return mesh.get_blend_shape_value(key) > 0.5, "%s's Touch key to rise" % id)
			await _until(func() -> bool: return mesh.get_blend_shape_value(key) < 0.1, "%s's Touch key to fall back" % id)
		else:
			var glows: Array[int] = []
			for s in mesh.mesh.get_surface_count():
				if mesh.mesh.surface_get_material(s).resource_name.ends_with("_glow"):
					glows.append(s)
			_check(not glows.is_empty(), "%s has _glow surfaces" % id)
			var energy := func(s: int) -> float:
				var m := mesh.get_surface_override_material(s) as BaseMaterial3D
				return m.emission_energy_multiplier if m != null and m.emission_enabled else -1.0
			var first: float = energy.call(glows[0])
			await _until(func() -> bool: return absf(energy.call(glows[0]) - first) > 0.3, "%s's glow to pulse" % id)
			if glows.size() > 1 and id not in GLOW_TOGETHER:
				# Taking turns: at any one time the lamps are not all alike.
				var spread := 0.0
				for s: int in glows:
					spread = maxf(spread, absf(energy.call(s) - energy.call(glows[0])))
				_check(spread > 0.3, "%s's lamps glow in turn (spread %.2f)" % [id, spread])
		avatar.free()
	for id: StringName in DROPS:
		var looks := (load(LOOKS + id + ".tscn") as PackedScene).instantiate() as Node3D
		var drops := looks.find_children("Drops", "GPUParticles3D", true, false)
		_check(drops.size() == 1 and (drops[0] as GPUParticles3D).emitting, "%s drops from one emitting GPUParticles3D" % id)
		looks.free()


func case_socks() -> void:
	var count := 0
	for f: String in ResourceLoader.list_directory(LOOKS):
		var id := f.get_basename()
		if not f.ends_with(".tscn") or not _is_socks(id):
			continue
		count += 1
		var avatar := _avatar()
		var scene := load(LOOKS + f) as PackedScene
		var feet := avatar.feet()
		_check(feet.size() == 2, "the Avatar has two feet")
		for i: int in feet.size():
			var pair := scene.instantiate() as Node3D
			feet[i].add_child(pair)
			var keep := &"sock_r" if i == 1 else &"sock_l"
			var sock := pair.find_child(String(keep), true, false) as MeshInstance3D
			_check(sock != null and sock.mesh != null, "%s has its %s" % [id, keep])
			if sock == null:
				continue
			sock.transform = Transform3D.IDENTITY
			_check(sock.global_transform.origin.is_equal_approx(feet[i].global_transform.origin),
					"%s's %s sits in its foot's frame" % [id, keep])
			var lowest := (sock.global_transform * sock.get_aabb()).position.y
			_check(absf(lowest - avatar.global_position.y) < 0.03,
					"%s's %s has its sole on the floor (lowest %.3f m)" % [id, keep, lowest])
		await _frames(1)
		avatar.free()
	_check(count == SOCKS, "%d Socks Looks, found %d" % [SOCKS, count])


func case_trails() -> void:
	for id: StringName in TRAILS:
		var n := 0
		for letter in "abcdefgh":
			var path := "%s%s_%s.res" % [MESHES, id, letter]
			if not ResourceLoader.exists(path):
				break
			var mesh := load(path) as ArrayMesh
			n += 1
			_check(mesh != null and mesh.get_surface_count() > 0, "%s is a mesh with surfaces" % path)
			if mesh == null:
				continue
			var box := mesh.get_aabb()
			_check(absf(box.position.y) < 0.002, "%s lies on the floor (bottom %.4f)" % [path, box.position.y])
			_check(box.get_center().x * box.get_center().x + box.get_center().z * box.get_center().z < 0.0025,
					"%s is centred on its origin (centre %s)" % [path, box.get_center()])
		_check(n == TRAILS[id], "%s has %d meshes, found %d" % [id, TRAILS[id], n])
