## The import script of the washing machine's model (assets/appliance/washing_machine.glb, its .import
## `import_script/path`; assets/14). It shapes the imported scene to what looks_washer.tscn inherits and
## looks_contract.json names:
## - the glTF armature arrives as a Node3D `face_rig` holding a Skeleton3D; the Skeleton3D takes its place
##   and its name, so the bones are at `face_rig:<bone>`;
## - the collider mesh (`body-convcolonly`) is dropped: the washer's collision is washer.tscn's own (Q2152);
## - Godot's glTF import gives every animation a track at the rest for each bone it does not key; those go,
##   so each animation moves only the bones its Blender action keys and the Looks' players never fight;
## - the animations go to the players the contract's `players` names (AnimationPlayer, Loops, Spin), and
##   the loops (talk, rumble, spin) loop;
## - the body's raised trims (`body_trim`: the worktop, the panel, the ring round the door, the gasket), the
##   dial and the detergent drawer cast no shadow: only the body's shell does (Q2655). Standing a
##   centimetre or two proud of the shell or the panel, they drew false stripes of the sun's coarse shadow
##   beside them. They still take shadow; the door and the brows still cast theirs.
@tool
extends EditorScenePostImport

const CONTRACT := "res://game/entities/washer/looks_contract.json"
const RIG := "face_rig"
const LOOPS: Array[StringName] = [&"talk", &"rumble", &"spin"]
## The meshes that take shadow but cast none (see the header).
const NO_SHADOW: Array[StringName] = [&"body_trim", &"dial", &"detergent_drawer"]


func _post_import(scene: Node) -> Object:
	var rig := _lift_skeleton(scene)
	for body in scene.find_children("*", "StaticBody3D", false, false):
		scene.remove_child(body)
		body.queue_free()
	var player := scene.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if rig == null or player == null:
		push_error("washer_model_import: no %s skeleton or AnimationPlayer in the glb" % RIG)
		return scene
	for mesh_name: StringName in NO_SHADOW:
		var trim := rig.get_node_or_null(NodePath(mesh_name)) as GeometryInstance3D
		if trim == null:
			push_error("washer_model_import: no mesh %s in the glb" % mesh_name)
		else:
			trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var all := {}
	for name in player.get_animation_list():
		all[StringName(name)] = _clean(player.get_animation(name), StringName(name), rig)
	for lib in player.get_animation_library_list():
		player.remove_animation_library(lib)
	var contract: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	var players: Dictionary = contract.get("players", {}) if contract is Dictionary else {}
	for p: String in players:
		var target := player
		if p != String(player.name):
			target = AnimationPlayer.new()
			target.name = p
			scene.add_child(target)
			target.owner = scene
		var library := AnimationLibrary.new()
		for a: String in players[p]:
			if all.has(StringName(a)):
				library.add_animation(a, all[StringName(a)])
			else:
				push_error("washer_model_import: the glb has no animation %s" % a)
		target.add_animation_library(&"", library)
	return scene


## Puts the Skeleton3D where its armature node was, under that node's name.
func _lift_skeleton(scene: Node) -> Skeleton3D:
	var holder := scene.get_node_or_null(RIG)
	if holder is Skeleton3D:
		return holder as Skeleton3D
	if holder == null:
		return null
	var found := holder.find_children("*", "Skeleton3D", false, false)
	if found.is_empty():
		return null
	var rig := found[0] as Skeleton3D
	var index := holder.get_index()
	rig.transform = (holder as Node3D).transform * rig.transform
	holder.remove_child(rig)
	scene.remove_child(holder)
	holder.queue_free()
	rig.name = RIG
	scene.add_child(rig)
	scene.move_child(rig, index)
	_own(rig, scene)
	return rig


func _own(node: Node, scene: Node) -> void:
	node.owner = scene
	for child in node.get_children():
		_own(child, scene)


## A copy with the tracks on face_rig, without the tracks that only hold a bone's rest.
func _clean(source: Animation, name: StringName, rig: Skeleton3D) -> Animation:
	var anim := source.duplicate(true) as Animation
	for t in range(anim.get_track_count() - 1, -1, -1):
		var path := anim.track_get_path(t)
		var bone := path.get_concatenated_subnames()
		anim.track_set_path(t, NodePath("%s:%s" % [RIG, bone]))
		var i := rig.find_bone(bone)
		if i >= 0 and _at_rest(anim, t, rig.get_bone_rest(i)):
			anim.remove_track(t)
	anim.loop_mode = Animation.LOOP_LINEAR if name in LOOPS else Animation.LOOP_NONE
	return anim


func _at_rest(anim: Animation, t: int, rest: Transform3D) -> bool:
	for k in anim.track_get_key_count(t):
		var v: Variant = anim.track_get_key_value(t, k)
		match anim.track_get_type(t):
			Animation.TYPE_POSITION_3D:
				if not (v as Vector3).is_equal_approx(rest.origin):
					return false
			Animation.TYPE_ROTATION_3D:
				if not (v as Quaternion).is_equal_approx(rest.basis.get_rotation_quaternion()):
					return false
			Animation.TYPE_SCALE_3D:
				if not (v as Vector3).is_equal_approx(rest.basis.get_scale()):
					return false
			_:
				return false
	return true
