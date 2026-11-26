## The Wardrobe's hats and clothes (assets/18): the 78 pieces' Looks, the old models in
## game/wardrobe/looks/, each put on an AvatarLooks as wardrobe.md "The dressed Avatar" says (a hat under
## HatPoint, clothes under the Body skinned to its Skeleton3D) without an error; the clothes keep their
## Crouch and Swish keys; the rare touches play from the Looks' own autoplay `touch` clip and Drops.
## A look ticket (Q2421): no real-path case; the designer judges the line-up.
extends TestSuite

const LOOKS := "res://game/wardrobe/looks/"
const AVATAR := "res://game/parts/avatar/looks_avatar.tscn"
## Ten basic pieces and the 17 Collections' two hats and two clothes (no Secrets, Q2682).
const COUNT := 78
const HATS := 40
## The pieces whose old glb has the "SwishL" and "SwishR" keys.
const SWISH: Array[StringName] = [&"antenna_band", &"bee_wings", &"hero_cape", &"jetpack", &"tiger_tail"]
## The old touches (data/tuning/wardrobe.json "touches") of these hats and clothes, by kind.
const WAVE: Array[StringName] = [&"fruit_basket_backpack", &"ivy_wrap", &"onion_layers", &"bubble_tea_backpack",
		&"balloon_backpack", &"tool_belt", &"softener_cape"]
const GLOW: Array[StringName] = [&"calculator_chestplate", &"robot_chest_panel", &"porthole_helmet"]
const DROPS: Array[StringName] = [&"detergent_cap_crown", &"hose_scarf"]


func cases() -> Array[Dictionary]:
	return [
		{"name": "dress_every_piece", "method": "case_dress", "world": false,
				"title": "every hat and clothes Looks goes on an AvatarLooks without an error: a hat in the HatPoint's frame, clothes skinned to the Avatar's bones keeping their Crouch (and Swish) keys"},
		{"name": "touches", "method": "case_touches", "world": false,
				"title": "the rare touches play from the Looks alone: a wave moves the Touch key, a glow pulses the _glow surfaces (in turn where the old cycled), drops fall from a GPUParticles3D"},
	]


func _ids() -> PackedStringArray:
	var out := PackedStringArray()
	for f: String in ResourceLoader.list_directory(LOOKS):
		if f.ends_with(".tscn"):
			out.append(f.get_basename())
	return out


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
	for id: StringName in WAVE + GLOW:
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
			if glows.size() > 1:
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
