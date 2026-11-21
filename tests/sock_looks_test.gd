## The Sock models and prints (assets/01, S01-S05): every Design drawn by its Collection's shape model
## and the one sock shader, the four shapes on one skeleton, each Pair as its Collection's sock ball,
## the Mess's instance material the same look, the old LODs within the old budgets, and the Sock looks
## station built from the data and seen by the player in the zoo.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const STATION := "res://game/zoo/stations/sock_looks.tscn"
const CATALOGUE := "res://game/sock/designs.tres"
## The old game's shape and cloth per Collection (data/designs.json) and ball per Collection
## (SockBall.cuff()), copied here so a change to the table is a change to the old look.
const OLD_SHAPES := {
	&"simple": &"ankle", &"patterns": &"crew", &"sport": &"tube", &"winter": &"chunky", &"animals": &"crew",
	&"superhero": &"crew", &"food": &"crew", &"space": &"crew", &"lost": &"crew", &"fruit": &"crew",
	&"nature": &"crew", &"vegetables": &"ankle", &"drinks": &"tube", &"math": &"crew", &"tech": &"tube",
	&"transport": &"crew", &"machinery": &"chunky",
}
const OLD_FABRICS := {&"winter": 1, &"machinery": 1, &"animals": 2}
const OLD_CUFFS := {
	&"simple": &"ankle", &"patterns": &"crew_stripe", &"sport": &"tube_rib", &"winter": &"chunky_fold",
	&"animals": &"crew_ears", &"superhero": &"crew_cape", &"food": &"crew_scallop", &"space": &"crew_rolled",
	&"vegetables": &"ankle", &"drinks": &"tube_rib", &"math": &"crew_stripe", &"transport": &"crew_stripe",
	&"machinery": &"chunky_fold",
}
const BONES: Array[StringName] = [&"Cuff", &"Leg", &"Heel", &"Foot", &"Toe"]
## The old budgets (assets/blender_assets/_classes.json): triangles of the close-up.
const SOCK_TRIS := 320
const BALL_TRIS := 540

var _zoo: Node3D = null
var _nodes: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "s01", "method": "case_s01", "world": false,
				"title": "S01: every Design is its Collection's shape model with its colour, pattern, print and cloth through the one sock shader"},
		{"name": "s01_station", "method": "case_s01_station", "world": false,
				"title": "S01: the Sock looks station is built from the data: every Collection, pattern, layout, coat, trim and ball, and a new one appears"},
		{"name": "s01_real_path", "method": "case_s01_real_path", "world": false,
				"title": "S01, real path: the player walks up to the Sock looks station and sees every group of its line-up, each drawn as its Design"},
		{"name": "s02", "method": "case_s02", "world": false,
				"title": "S02: the four shapes share one skeleton (Cuff, Leg, Heel, Foot, Toe), the cloth and the Looks contract"},
		{"name": "s03", "method": "case_s03", "world": false,
				"title": "S03: a Pair is drawn as its Collection's sock ball, centred on its origin, with the Looks contract"},
		{"name": "s04", "method": "case_s04", "world": false,
				"title": "S04: the Mess's instance material is the same shader and fit; the look data is MessDrawing.look_data()"},
		{"name": "s04_tiers", "method": "case_s04_tiers", "world": false,
				"title": "S04: a lying Sock's instance and its lent Looks are the same mesh, place and look; a held and a flying Sock's Looks draw the same"},
		{"name": "s05", "method": "case_s05", "world": false,
				"title": "S05: the old hand-made LODs fold into one mesh per model, within the old budgets (sock 320, ball 540)"},
	]


func _before_case() -> void:
	Input.action_release(&"move_forward")
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
	if _zoo != null:
		_zoo.free()
		_zoo = null


func _keep(n: Node) -> Node:
	_nodes.append(n)
	return n


func _catalogue() -> DesignCatalogue:
	return load(CATALOGUE) as DesignCatalogue


func case_s01() -> void:
	var cat := _catalogue()
	var bad := 0
	for id in cat.size():
		var d := cat.design(id)
		if d == null:
			continue
		var shape: StringName = OLD_SHAPES.get(d.collection, &"crew")
		var m := SockLook.material(d)
		var lk := MessDrawing.look_data(d)
		var fit := SockLook.TABLE.fit(shape)
		var ok: bool = SockLook.TABLE.shape_of(d) == shape \
				and SockLook.scene(d).resource_path == "res://game/sock/looks_%s.tscn" % shape \
				and m.shader == SockLook.SHADER \
				and m.get_shader_parameter(&"base_color") == d.colour \
				and m.get_shader_parameter(&"look") == Vector4(lk.r, lk.g, lk.b, lk.a) \
				and m.get_shader_parameter(&"use_instance") == false \
				and int(m.get_shader_parameter(&"fabric")) == int(OLD_FABRICS.get(d.collection, 0)) \
				and is_equal_approx(float(m.get_shader_parameter(&"print_aspect")), fit.print_aspect) \
				and m.get_shader_parameter(&"patch_split") == fit.patch_split \
				and m.get_shader_parameter(&"prints") == SockLook.PRINTS
		if not ok:
			bad += 1
			if bad <= 3:
				_check(false, "Design %d (%s) is drawn as the old game drew it" % [id, d.collection])
	_check(bad == 0, "all %d Designs are their Collection's shape with their own look (%d wrong)" % [cat.size(), bad])
	var looks := _keep(SockLook.make(cat.design(230))) as Node3D
	var body := looks.get_node("Body")
	var meshes := body.find_children("*", "MeshInstance3D", true, false)
	_check(not meshes.is_empty(), "a Looks has a Body mesh")
	for mi: MeshInstance3D in meshes:
		_check(mi.material_override == SockLook.material(cat.design(230)), "the Body draws with its Design's material")
	_near(looks.scale.x, cat.design(230).size_scale(), 0.0001, "the Looks is scaled by the Design's Size")


func case_s01_station() -> void:
	var st := _keep((load(STATION) as PackedScene).instantiate()) as SockLooksStation
	add_child(st)
	var cat := st.catalogue
	var firsts := {}
	for id in cat.size():
		var d := cat.design(id)
		if not firsts.has(d.collection):
			firsts[d.collection] = id
	var row := st.lineup(&"collections")
	_check(row.size() == firsts.size(), "one Looks per Collection (%d of %d)" % [row.size(), firsts.size()])
	for c: StringName in firsts:
		_check(row.has(firsts[c]), "Collection %s shows its first Design" % c)
	var patterns := st.lineup(&"patterns")
	var kinds := {}
	var layouts := {}
	var patches := {}
	var coat := false
	for id in patterns:
		var d := cat.design(id)
		kinds[d.pattern] = true
		patches[d.patches] = true
		coat = coat or d.coat >= 0
		if d.pattern == &"print":
			layouts[d.layout] = true
	for p in MessDrawing.PATTERNS:
		_check(kinds.has(p), "pattern %s is in the line-up" % p)
	for l in MessDrawing.LAYOUTS:
		_check(layouts.has(l), "print layout %s is in the line-up" % l)
	for p in MessDrawing.PATCHES:
		_check(patches.has(p), "trim patches %s are in the line-up" % p)
	_check(coat, "a coat print is in the line-up")
	var balls := st.lineup(&"balls")
	_check(balls.size() == SockLook.TABLE.cuffs.size(), "one ball per cuff (%d)" % balls.size())
	for id in balls:
		var name := SockLooksStation.looks_name(&"balls", id)
		var l := st.looks.get_node_or_null(name) as Node3D
		_check(l != null and l.scene_file_path == SockLook.scene(cat.design(id), true).resource_path, "ball %s is its Collection's ball Looks" % name)
	_check(st.looks.get_child_count() == row.size() + patterns.size() + balls.size(), "the station holds the whole line-up")
	# A Design of a new Collection appears with no other change.
	var extra := SockDesign.new()
	extra.id = cat.size()
	extra.name = "Test"
	extra.collection = &"test_new"
	cat.designs.append(extra)
	var again := _keep((load(STATION) as PackedScene).instantiate()) as SockLooksStation
	add_child(again)
	cat.designs.pop_back()
	_check(again.looks.get_node_or_null(SockLooksStation.looks_name(&"collections", extra.id)) != null, "a new Collection's Design appears in the station")


func case_s01_real_path() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := _zoo.get_node("Player") as Player
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand", 600)
	var st := _zoo.get_node("Stations/SockLooks") as SockLooksStation
	# The player stands 4 m in front of the station, facing it, and walks up to it.
	player.global_position = st.to_global(Vector3(0.0, 0.0, 4.0))
	player.velocity = Vector3.ZERO
	player.rotation.y = st.global_rotation.y
	(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-40.0)
	player.reset_physics_interpolation()
	await _physics_ticks(2)
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return st.to_local(player.global_position).z < 1.6, "the player to walk up to the station", 600)
	Input.action_release(&"move_forward")
	await _physics_ticks(10)
	var cam := get_viewport().get_camera_3d()
	_check(cam != null and player.is_ancestor_of(cam), "the player's camera is the view")
	if cam == null:
		return
	var cat := st.catalogue
	for group: StringName in [&"collections", &"patterns"]:
		var ids := st.lineup(group)
		var seen := 0
		for id in ids:
			var l := st.looks.get_node(SockLooksStation.looks_name(group, id)) as Node3D
			if cam.is_position_in_frustum(l.global_position):
				seen += 1
				var mi := l.get_node("Body").find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
				_check(mi.material_override == SockLook.material(cat.design(id), false), "%s %d is drawn as its Design" % [group, id])
		_check(seen >= mini(ids.size(), 9), "the player sees the %s (%d of %d)" % [group, seen, ids.size()])


func case_s02() -> void:
	for shape in SockLook.TABLE.shapes:
		var looks := _keep((load("res://game/sock/looks_%s.tscn" % shape) as PackedScene).instantiate()) as Node3D
		_contract(looks, String(shape))
		var skels := looks.find_children("*", "Skeleton3D", true, false)
		_check(skels.size() == 1, "%s has one skeleton" % shape)
		if skels.is_empty():
			continue
		var sk := skels[0] as Skeleton3D
		var names: Array[StringName] = []
		for b in sk.get_bone_count():
			names.append(StringName(sk.get_bone_name(b)))
		_same(names, BONES, "%s's bones" % shape)
		var cloth := sk.get_node_or_null("Cloth") as SpringBoneSimulator3D
		_check(cloth != null and cloth.get_root_bone_name(0) == "Leg" and cloth.get_end_bone_name(0) == "Toe", "%s has the cloth from Leg to Toe" % shape)
		var dressed := _keep(SockLook.make(_catalogue().design(0))) as Node3D
		SockLook.dress(looks, _catalogue().design(0))
		# The outline's copies (shown while aimed in _contract) are not the Looks' own meshes.
		var meshes := looks.get_node("Body").find_children("*", "MeshInstance3D", true, false).filter(
				func(n: Node) -> bool: return n.name != &"OutlineCopy")
		_check(dressed != null and meshes.size() == 1 and (meshes[0] as MeshInstance3D).skin != null, "%s draws one skinned mesh (%s)" % [shape, meshes])


func case_s03() -> void:
	var cat := _catalogue()
	for c: StringName in OLD_CUFFS:
		var probe := SockDesign.new()
		probe.collection = c
		_check(SockLook.TABLE.cuff_of(probe) == OLD_CUFFS[c], "Collection %s rolls into the %s ball" % [c, OLD_CUFFS[c]])
	var plain := SockDesign.new()
	plain.collection = &"lost"
	_check(SockLook.TABLE.cuff_of(plain) == &"crew_plain", "a Collection without its own ball rolls into the plain crew ball")
	for cuff in SockLook.TABLE.cuffs:
		var looks := _keep((load("res://game/sock/looks_ball_%s.tscn" % cuff) as PackedScene).instantiate()) as Node3D
		_contract(looks, "ball " + String(cuff))
		var mi := looks.get_node("Body").find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var box := (looks.get_node("Body") as Node3D).transform * mi.mesh.get_aabb()
		_check(box.get_center().length() < 0.002, "ball %s is centred on its origin (%s)" % [cuff, box.get_center()])
		_near(SockLook.ball_radius(cuff), box.size.y * 0.5, 0.0005, "ball %s's radius is half its height" % cuff)
	var d := cat.design(230)
	var ball := _keep(SockLook.make(d, SockDress.LYING, true)) as Node3D
	_check(ball.scene_file_path == "res://game/sock/looks_ball_tube_rib.tscn", "a Sport Pair is the tube rib ball")
	var bm := SockLook.material(d, true)
	_check(bm != SockLook.material(d), "the ball has its own material")
	_near(float(bm.get_shader_parameter(&"print_aspect")), SockLook.TABLE.ball_fit.print_aspect, 0.0001, "the ball's print fit")
	var size: Vector2 = bm.get_shader_parameter(&"cloth_size")
	_near(size.x, SockLook.TABLE.ball_fit.cloth_size.x * SockLook.ball_radius(&"tube_rib") / SockLook.TABLE.ball_radius, 0.0001, "the ball's knit scales with its radius")


func case_s04() -> void:
	var cat := _catalogue()
	for id: int in [0, 130, 230, 300, 355]:
		var d := cat.design(id)
		var single := SockLook.material(d)
		var inst := SockLook.instance_material(d.collection)
		_check(inst.shader == single.shader, "Design %d: one shader for the Mess and a single mesh" % id)
		_check(inst.get_shader_parameter(&"use_instance") == true, "the Mess's material reads the instance data")
		for p: StringName in [&"fabric", &"print_aspect", &"cloth_size", &"calf_body", &"patch_split", &"prints", &"prints_grid"]:
			_check(inst.get_shader_parameter(p) == single.get_shader_parameter(p), "Design %d: %s is the same lying and held" % [id, p])
		var lk := MessDrawing.look_data(d)
		_check(single.get_shader_parameter(&"look") == Vector4(lk.r, lk.g, lk.b, lk.a), "Design %d: the look uniform is the instance custom data" % id)
	var b := cat.design(230)
	_check(SockLook.instance_material(b.collection, true).get_shader_parameter(&"cloth_size") == SockLook.material(b, true).get_shader_parameter(&"cloth_size"), "a lying Pair's material fits its ball")


func case_s04_tiers() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var mess := _zoo.get_node("Socks/Mess") as Mess
	await _until(func() -> bool: return mess.count() > 0 and mess._drawing != null and mess._drawing.drawn_count() > 0, "the Socks to lie", 600)
	var drawing := mess._drawing
	var shapes := {}
	var checked := 0
	for sock: int in drawing._cell_of.keys():
		var design := mess.design_of(sock)
		var pair := mess.is_pair(sock)
		var shape := MessDrawing.shape_of(design, pair)
		if shapes.has(shape):
			continue
		shapes[shape] = true
		var c: Vector3i = drawing._cell_of[sock]
		var node := drawing._cells[c]
		var row := drawing.instance_of(sock)
		var placed := node.global_transform * (row[0] as Transform3D)
		_check(node.material_override == SockLook.instance_material(design.collection, pair), "%s: the lying tier draws with the sock shader's instance material" % shape)
		var looks := mess.looks_of(sock)
		if looks == null:
			_check(false, "%s: the Mess lends its Looks" % shape)
			continue
		await _frames(1)
		var body := looks.get_node("Body").find_children("*", "MeshInstance3D", true, false).filter(
				func(n: Node) -> bool: return not n.is_in_group(Outline.COPY))[0] as MeshInstance3D
		_check(body.mesh == node.multimesh.mesh, "%s: the instance and the Looks are one mesh" % shape)
		_check(body.material_override == SockLook.material(design, pair), "%s: the lent Looks draws its Design" % shape)
		_check(placed.origin.distance_to(body.global_transform.origin) < 0.001 \
				and placed.basis.x.distance_to(body.global_transform.basis.x) < 0.001, "%s: no change at rest (%s vs %s)" % [shape, placed.origin, body.global_transform.origin])
		mess.return_looks(sock)
		checked += 1
	_check(checked >= 3, "several shapes checked (%d)" % checked)
	var d := _catalogue().design(300)
	for state: StringName in [SockDress.HELD, SockDress.LYING]:
		var l := _keep(SockDress.make(d, state)) as Node3D
		var mi := l.get_node("Body").find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		_check(mi.material_override == SockLook.material(d) and l.scene_file_path == SockLook.scene(d).resource_path, "a %s Sock's Looks is its shape with its Design's material" % state)


func case_s05() -> void:
	var models: Array[String] = []
	for shape in SockLook.TABLE.shapes:
		models.append(String(shape))
	for cuff in SockLook.TABLE.cuffs:
		models.append("ball_" + String(cuff))
	for m in models:
		var root := _keep((load("res://assets/sock/%s.glb" % m) as PackedScene).instantiate())
		# The mirror the tests run in imports with default settings (no import script): fold here
		# as the import does.
		var before := 0
		var lods := 0
		for n: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			before += (n.mesh as ArrayMesh).surface_get_array_len(0)
			if String(n.name).contains("_lod"):
				lods += 1
		ModelLods.fold(root)
		var left := root.find_children("*", "MeshInstance3D", true, false)
		_check(left.size() == 1, "%s: one mesh left after the fold (%d)" % [m, left.size()])
		if left.is_empty():
			continue
		var mesh := (left[0] as MeshInstance3D).mesh as ArrayMesh
		_check(lods == (2 if not m.begins_with("ball_") else 1), "%s has the old LOD levels (%d)" % [m, lods])
		var tris := mesh.surface_get_array_index_len(0) / 3
		var budget := BALL_TRIS if m.begins_with("ball_") else SOCK_TRIS
		_check(tris <= budget, "%s: %d triangles within the old budget %d" % [m, tris, budget])
		_check(mesh.surface_get_array_len(0) >= before - 1, "%s: the levels' vertices are in the one mesh" % m)


func _contract(looks: Node3D, what: String) -> void:
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/sock/looks_contract.json"))
	for n: String in contract["nodes"]:
		_check(looks.get_node_or_null(n) != null, "%s has %s" % [what, n])
	var player := looks.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		return
	for a: String in contract["animations"]:
		_check(player.has_animation(a), "%s has the %s state" % [what, a])
	add_child(looks)
	SockDress.play(looks, SockDress.AIMED)
	_check((looks.get_node("Outline") as Node3D).get(&"shown") == true, "%s shows its outline when aimed" % what)
	SockDress.play(looks, SockDress.HELD)
	_check((looks.get_node("Outline") as Node3D).get(&"shown") == false, "%s hides it when held" % what)
	remove_child(looks)
