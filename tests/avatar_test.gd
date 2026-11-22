## coop/04: the avatar model, ported as is from the old game (assets/avatar/avatar.glb and feet.glb) and
## worn by the Avatar as its Looks. These cases check the import and the Looks contract (what the
## avatar's behaviour leans on), not the look itself (Q2421): that is the before and after strip in
## builds/review-avatar/.
extends TestSuite

const AVATAR := "res://game/parts/avatar/avatar.tscn"
const FEET := "res://assets/avatar/feet.glb"
const SPIKE := "res://tests/support/ragdoll_spike/ragdoll_spike.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const CONTRACT := "res://game/parts/avatar/looks_contract.json"
const BONES: Array[String] = ["Root", "Spine0", "Spine1", "Spine2"]

var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "model", "method": "case_model", "world": false,
				"title": "the Avatar wears the old sock creature: the contract's nodes, the four-bone spine, the player, trim and eye surfaces, the Crouch key, the extras, facing -z with the cuff rim 1.7 m over its feet"},
		{"name": "colour", "method": "case_colour", "world": false,
				"title": "the player's colour goes on the body's player surface only; the trim, eyes and pupils keep their colours"},
		{"name": "spike_rig", "method": "case_spike_rig", "world": false,
				"title": "the coop/02 ragdoll stand-in has the import's bone names, parents and rest places"},
		{"name": "seen", "method": "case_seen", "world": false,
				"title": "real path: the Host walks forward and the Guest sees the sock creature, white, where the Host's player stands"},
	]


func case_model() -> void:
	var avatar := (load(AVATAR) as PackedScene).instantiate() as Avatar
	add_child(avatar)
	var looks := avatar.get_node_or_null("Looks") as AvatarLooks
	_check(looks != null, "the Avatar's Looks is the sock creature's Looks")
	if looks == null:
		avatar.free()
		return
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	for n: String in contract["nodes"]:
		_check(looks.find_child(n, true, false) != null, "the Looks has %s" % n)
	var skeleton := looks.find_child("Skeleton3D", true, false) as Skeleton3D
	var names: Array[String] = []
	for i: int in skeleton.get_bone_count():
		names.append(skeleton.get_bone_name(i))
		_check(skeleton.get_bone_parent(i) == i - 1, "%s is chained bottom up (parent %d)" % [names[i], skeleton.get_bone_parent(i)])
	_check(names == BONES, "the spine's bones are %s" % [names])
	var body := looks.body()
	_check(body.get_node(body.skeleton) == skeleton, "the body is skinned to the spine")
	var surfaces: Array[String] = []
	for i: int in body.mesh.get_surface_count():
		surfaces.append(body.mesh.surface_get_material(i).resource_name)
	_check(surfaces == ["player", "trim", "eye"], "the body's surfaces in order: %s" % [surfaces])
	_check(body.mesh.get_blend_shape_count() == 1 and body.mesh.get_blend_shape_name(0) == &"Crouch",
			"the body has the Crouch shape key")
	for n: String in ["HoldPoint", "Head", "HatPoint", "PupilL", "PupilR"]:
		var extras: Dictionary = looks.find_child(n, true, false).get_meta("extras", {})
		_check(extras.has("crouch_drop") and extras.has("crouch_offset") and (extras.get("bend_weights", []) as Array).size() == 4,
				"%s carries crouch_drop, crouch_offset and bend_weights (%s)" % [n, extras])
	var arm_extras: Dictionary = looks.find_child("Armature", true, false).get_meta("extras", {})
	_check((arm_extras.get("bend_crouch_offset", []) as Array).size() == 4, "the Armature carries bend_crouch_offset per bone")
	var hat := looks.find_child("HatPoint", true, false) as Node3D
	_near(hat.global_position.y, 1.7, 0.001, "the cuff rim is 1.7 m over the feet")
	var aabb := body.get_aabb()
	_near(aabb.position.y, 0.0, 0.08, "the body stands on its origin (lowest point %.3f)" % aabb.position.y)
	_check(absf(aabb.get_center().x) < 0.05 and absf(aabb.get_center().z) < 0.05, "the body is centred on its origin (%s)" % aabb.get_center())
	for n: String in ["PupilL", "PupilR"]:
		var pupil := looks.find_child(n, true, false) as Node3D
		_check(pupil.global_position.z < 0.0 and (-pupil.global_basis.z).z < -0.8, "%s looks out of its front, -z" % n)
	# The first-person feet are the same feet at the same places.
	var feet := (load(FEET) as PackedScene).instantiate() as Node3D
	for n: String in ["FootL", "FootR"]:
		var a := feet.get_node(n) as Node3D
		var b := looks.find_child(n, true, false) as Node3D
		_check(a.transform.is_equal_approx(b.transform), "%s in feet.glb stands where the avatar's does" % n)
		_check(b.basis.is_equal_approx(Basis.IDENTITY) and is_equal_approx(b.position.y, 0.1), "%s pivots at the ankle, unturned" % n)
	feet.free()
	avatar.free()


func case_colour() -> void:
	var looks := (load("res://game/parts/avatar/looks_avatar.tscn") as PackedScene).instantiate() as AvatarLooks
	add_child(looks)
	var body := looks.body()
	_check(_shown(body, 0).albedo_color == Color.WHITE, "white until a colour is given")
	var made_trim := _shown(body, 1).albedo_color
	var coral := Color(0.95, 0.45, 0.4)
	looks.colour = coral
	_check(_shown(body, 0).albedo_color == coral, "the player surface shows the colour")
	_check(_shown(body, 1).albedo_color == made_trim and _shown(body, 2).albedo_color == body.mesh.surface_get_material(2).albedo_color,
			"the trim and the eyes keep their made colours")
	var pupil := looks.find_child("PupilL", true, false) as MeshInstance3D
	_check(pupil.get_surface_override_material(0) == null, "the pupils keep theirs")
	_check((body.mesh.surface_get_material(0) as BaseMaterial3D).albedo_color == Color.WHITE,
			"the model's own material stays white (another avatar's colour is its own)")
	looks.free()


func case_spike_rig() -> void:
	var avatar := (load(AVATAR) as PackedScene).instantiate() as Node3D
	var model := avatar.find_child("Skeleton3D", true, false) as Skeleton3D
	var spike := (load(SPIKE) as PackedScene).instantiate() as Node3D
	for stand_in: Skeleton3D in [spike.get_node("Ragdoll") as Skeleton3D, spike.get_node("Body") as Skeleton3D]:
		_check(stand_in.get_bone_count() == model.get_bone_count(), "%s has %d bones" % [stand_in.name, stand_in.get_bone_count()])
		for i: int in mini(stand_in.get_bone_count(), model.get_bone_count()):
			_check(stand_in.get_bone_name(i) == model.get_bone_name(i) and stand_in.get_bone_parent(i) == model.get_bone_parent(i),
					"%s bone %d is %s under %d" % [stand_in.name, i, model.get_bone_name(i), model.get_bone_parent(i)])
			var gap := stand_in.get_bone_rest(i).origin.distance_to(model.get_bone_rest(i).origin)
			_check(gap < 0.001, "%s %s rests where the import's does (%.4f m off)" % [stand_in.name, model.get_bone_name(i), gap])
	spike.free()
	avatar.free()


func case_seen() -> void:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := host.get_node("Session") as Session
	hs.port = 0
	_check((host.get_node("Net") as ZooNet).start(["--host"]) == OK, "the host zoo hosts")
	_check((guest.get_node("Net") as ZooNet).start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	var ga := guest.get_node("Avatars") as Avatars
	await _until(func() -> bool: return ga.of(1) != null, "the guest to see the host's avatar")
	var host_player := host.get_node("Player") as Player
	var start := host_player.global_position
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return host_player.global_position.distance_to(start) > 1.0, "the host's player to walk a metre")
	Input.action_release(&"move_forward")
	var seen := ga.of(1)
	await _until(func() -> bool: return seen.global_position.distance_to(host_player.global_position) < 0.05,
			"the guest to see the host's avatar where the host's player stands")
	var looks := seen.get_node_or_null("Looks") as AvatarLooks
	_check(looks != null and looks.is_visible_in_tree() and looks.body().is_visible_in_tree(), "the guest sees the sock creature, not a capsule")
	if looks != null:
		_check(_shown(looks.body(), 0).albedo_color == Color.WHITE, "its body is white until the player colours come (coop/03)")
		_near(seen.rotation.y, host_player.global_rotation.y, 0.05, "it faces the way the host's player faces")
	_drop_branches()


## The material a surface shows: its override, else the model's own.
func _shown(mi: MeshInstance3D, surface: int) -> BaseMaterial3D:
	var over := mi.get_surface_override_material(surface)
	return (over if over != null else mi.mesh.surface_get_material(surface)) as BaseMaterial3D


## One machine: its own SceneMultiplayer and a SubViewport world with a zoo in it (as zoo_test does).
func _branch(label: String) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node: Node in _branches:
		var session := node.get_node_or_null("View/Zoo/Session") as Session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
