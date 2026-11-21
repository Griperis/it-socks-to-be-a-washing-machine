## How a Design looks (assets/01, S01-S04): its Sock is its Collection's shape model
## (looks_<shape>.tscn), its Pair its Collection's sock ball (looks_ball_<cuff>.tscn), both drawn by
## the one sock shader (sock_pattern.gdshader) with the Design's colour, pattern, print and cloth.
## Every Looks has the contract of looks_contract.json; the states play in its AnimationPlayer
## (SockDress.play). The old game's SockLook and SockBall.setup, ported.
class_name SockLook
extends RefCounted

const TABLE := preload("res://game/sock/sock_looks.tres")
const SHADER := preload("res://game/sock/sock_pattern.gdshader")
const PRINTS := preload("res://assets/sock/prints.png")

static var _scenes: Dictionary[String, PackedScene] = {}
## One material per Design, for its Socks and for its Pair's ball, shared by every Looks of it.
static var _materials: Dictionary[SockDesign, ShaderMaterial] = {}
static var _ball_materials: Dictionary[SockDesign, ShaderMaterial] = {}
## One MultiMesh material per Collection and kind (the look comes per instance).
static var _instance_materials: Dictionary[String, ShaderMaterial] = {}
## Each sock ball's radius at Size medium, by cuff (half its model's height, as the old SockBall).
static var _radii: Dictionary[StringName, float] = {}


## The Looks scene of a Design's Sock, or with `ball` its Pair's sock ball.
static func scene(design: SockDesign, ball := false) -> PackedScene:
	var path := ("res://game/sock/looks_ball_%s.tscn" % TABLE.cuff_of(design)) if ball \
			else ("res://game/sock/looks_%s.tscn" % TABLE.shape_of(design))
	var found: PackedScene = _scenes.get(path)
	if found == null:
		found = load(path) as PackedScene
		_scenes[path] = found
	return found


## A new Looks dressed as `design`, playing `state`: a Sock's, or with `ball` a Pair's sock ball.
static func make(design: SockDesign, state: StringName = SockDress.LYING, ball := false) -> Node3D:
	var looks := scene(design, ball).instantiate() as Node3D
	dress(looks, design, ball)
	SockDress.play(looks, state)
	return looks


## Scales the Looks by the Design's Size and draws its Body with the Design's material.
static func dress(looks: Node3D, design: SockDesign, ball := false) -> void:
	if design == null:
		return
	looks.scale = Vector3.ONE * design.size_scale()
	var body := looks.get_node_or_null(^"Body")
	if body == null:
		return
	# The import folds the models' LODs (model_lods_import.gd); where a .glb was imported without
	# its import settings (the test and shot mirrors) they are folded here, once per model.
	ModelLods.fold(body)
	var m := material(design, ball)
	for node in body.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = m


## The material of a single mesh showing `design` (the look as uniforms).
static func material(design: SockDesign, ball := false) -> ShaderMaterial:
	var cache := _ball_materials if ball else _materials
	var m: ShaderMaterial = cache.get(design)
	if m != null:
		return m
	m = _new_material(design.collection, ball)
	m.set_shader_parameter(&"use_instance", false)
	m.set_shader_parameter(&"base_color", design.colour)
	# A Vector4, not a Color: a Color handed to a vec4 uniform is converted to linear, which would
	# scramble the packed whole numbers.
	var lk := MessDrawing.look_data(design)
	m.set_shader_parameter(&"look", Vector4(lk.r, lk.g, lk.b, lk.a))
	if ball:
		_fit_ball(m, TABLE.cuff_of(design))
	cache[design] = m
	return m


## The material of a Collection's MultiMeshes (colour and look come per instance).
static func instance_material(collection: StringName, ball := false) -> ShaderMaterial:
	var key := "%s/%s" % [collection, "ball" if ball else "sock"]
	var m: ShaderMaterial = _instance_materials.get(key)
	if m == null:
		m = _new_material(collection, ball)
		m.set_shader_parameter(&"use_instance", true)
		if ball:
			var probe := SockDesign.new()
			probe.collection = collection
			_fit_ball(m, TABLE.cuff_of(probe))
		_instance_materials[key] = m
	return m


## A sock ball's radius at Size medium (half its model's height).
static func ball_radius(cuff: StringName) -> float:
	if _radii.has(cuff):
		return _radii[cuff]
	var r := TABLE.ball_radius
	var path := "res://game/sock/looks_ball_%s.tscn" % cuff
	if ResourceLoader.exists(path):
		var looks := (load(path) as PackedScene).instantiate() as Node3D
		var box := AABB()
		var first := true
		for node in looks.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if not mi.visible or mi.visibility_range_begin > 0.0:
				continue
			var a := mi.mesh.get_aabb()
			box = a if first else box.merge(a)
			first = false
		if not first:
			r = box.size.y * 0.5
		looks.free()
	_radii[cuff] = r
	return r


## The shared part of every sock material: the shader, the prints, the cloth and the shape's fit.
static func _new_material(collection: StringName, ball: bool) -> ShaderMaterial:
	var probe := SockDesign.new()
	probe.collection = collection
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter(&"prints", PRINTS)
	m.set_shader_parameter(&"prints_grid", TABLE.prints_grid)
	m.set_shader_parameter(&"fabric", float(TABLE.fabric_of(probe)))
	var f := TABLE.ball_fit if ball else TABLE.fit(TABLE.shape_of(probe))
	m.set_shader_parameter(&"print_aspect", f.print_aspect)
	m.set_shader_parameter(&"cloth_size", f.cloth_size)
	m.set_shader_parameter(&"calf_body", f.calf_body)
	m.set_shader_parameter(&"patch_split", f.patch_split)
	return m


## A ball's knit scales with its own radius (the old SockBall.setup).
static func _fit_ball(m: ShaderMaterial, cuff: StringName) -> void:
	m.set_shader_parameter(&"cloth_size", TABLE.ball_fit.cloth_size * (ball_radius(cuff) / TABLE.ball_radius))
