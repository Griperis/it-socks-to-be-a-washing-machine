## Puts a look on its AvatarLooks (core/128, docs/architecture/wardrobe.md "The dressed Avatar"): the
## `Dresser` child of every AvatarLooks, which hands it each new look (`AvatarLooks.look`).
##
## - Hat: the piece's Looks under HatPoint; the name tag floats `tag_lift` over the hat's top (Q2462).
## - Clothes: its Looks under the Body, each skinned mesh bound to the Avatar's Skeleton3D, its "Crouch"
##   key following the body's (crouch()).
## - Socks: the pair's Looks under FootL (only `sock_l` drawn) and FootR (only `sock_r`), at identity, so
##   they waddle, stay planted and ride the ragdoll.
## - Trail: at each step over `step_walk` waddle (AvatarLooks.stepped) a mark of the Trail's scene,
##   `top_level`, at the foot `mark_lift` up, facing the heading; at most its `max_marks` alive (the oldest
##   freed first), each freeing itself after its `life`; a changed Trail frees them at once. With `demo`
##   (a creature that does not walk) it lays them beside the creature on a timer, already laid at first.
## - Swish: a hat or clothes mesh with "SwishL" and "SwishR" keys swings with the waddle (the old
##   avatar.gd), `swish_rate` times a waddle, and sways slowly standing.
## - First person (the own body, Q888): only Socks and Trail. `leaves_trail` off (the mirror body): no marks.
## Every machine dresses every creature from its look alone: nothing of this goes over the network.
class_name Dresser
extends Node

## The Wardrobe's numbers (none: Wardrobe.tuning()).
@export var tuning: WardrobeTuning
## Lays the Trail's marks beside the creature on a timer instead of at its steps (the Wardrobe's
## preview, the gift reveal, the zoo's stands).
@export var demo := false:
	set(value):
		demo = value
		if _looks != null:
			_restart_trail()

## The look it wears now (every slot, cleaned).
var worn: Dictionary[StringName, StringName] = WardrobeLook.empty()
## The pieces' nodes now (null for an empty slot): the hat's and clothes' Looks, the two Socks' Looks.
var hat: Node3D = null
var clothes: Node3D = null
var socks: Array[Node3D] = []

var _looks: AvatarLooks = null
var _skeleton: Skeleton3D = null
## [mesh, its SwishL, its SwishR, its swish rate] of each swinging mesh.
var _swishing: Array[Array] = []
## [mesh, its Crouch key] of each clothes mesh with one.
var _crouching: Array[Array] = []
var _marks: Array[TrailMark] = []
var _trail_scene: PackedScene = null
var _swish_clock := 0.0
var _demo_clock := 0.0
var _demo_step := 0


## Called by its AvatarLooks once that is ready.
func attach(looks: AvatarLooks) -> void:
	_looks = looks
	if tuning == null:
		tuning = Wardrobe.tuning()
	_skeleton = looks.body().get_parent() as Skeleton3D
	looks.stepped.connect(_on_stepped)


## Puts `look` on: only the slots that changed are redone.
func wear(look: Dictionary) -> void:
	if _looks == null:
		return
	var want := WardrobeLook.clean(look)
	var fp := _looks.first_person
	if want[&"hat"] != worn[&"hat"]:
		_free(hat)
		hat = null
		if not fp:
			hat = _put(want[&"hat"], _looks.swaying().get_node(^"HatPoint") as Node3D)
	if want[&"clothes"] != worn[&"clothes"]:
		_free(clothes)
		clothes = null
		if not fp:
			clothes = _put(want[&"clothes"], _looks.swaying())
			if clothes != null:
				for mi: MeshInstance3D in _meshes(clothes):
					if mi.skin != null:
						mi.skeleton = mi.get_path_to(_skeleton)  # bound in the tree, or it draws at rest
	if want[&"socks"] != worn[&"socks"]:
		for s in socks:
			_free(s)
		socks.clear()
		var feet := _looks.feet()
		for i: int in feet.size():
			var pair := _put(want[&"socks"], feet[i])
			if pair == null:
				continue
			var keep := &"sock_r" if i == 1 else &"sock_l"
			for mi: MeshInstance3D in _meshes(pair):
				mi.visible = mi.name == keep
				if mi.name == keep:
					mi.transform = Transform3D.IDENTITY
				if fp:
					mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			socks.append(pair)
	var trail_changed := want[&"trail"] != worn[&"trail"]
	worn = want
	_index()
	_lift_tag()
	crouch(_looks.crouch)
	if trail_changed:
		var piece := Wardrobe.of(worn[&"trail"])
		_trail_scene = piece.looks if piece != null else null
		_restart_trail()


## The clothes follow the body's Crouch key.
func crouch(weight: float) -> void:
	for c: Array in _crouching:
		(c[0] as MeshInstance3D).set_blend_shape_value(int(c[1]), weight)


## The Trail's marks alive now, oldest first.
func marks() -> Array[TrailMark]:
	var alive: Array[TrailMark] = []
	for m in _marks:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			alive.append(m)
	_marks = alive
	return _marks


func _process(delta: float) -> void:
	if _looks == null or not _looks.is_visible_in_tree():
		return
	_swish(delta)
	if demo and _trail_scene != null:
		_demo_clock += delta
		while _demo_clock >= tuning.demo_time:
			_demo_clock -= tuning.demo_time
			_demo_next(0.0)


# --- Pieces --------------------------------------------------------------------------------------

## A piece's Looks under `parent`, at identity; null for none.
func _put(id: StringName, parent: Node3D) -> Node3D:
	var piece := Wardrobe.of(id)
	if piece == null or piece.looks == null:
		return null
	var node := piece.looks.instantiate() as Node3D
	node.name = "Piece_%s" % id
	parent.add_child(node)
	return node


func _free(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.get_parent().remove_child(node)
		node.queue_free()


static func _meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		out.append(root as MeshInstance3D)
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		out.append(n as MeshInstance3D)
	return out


## The swinging and crouching meshes of the hat and clothes now.
func _index() -> void:
	_swishing.clear()
	_crouching.clear()
	for pair: Array in [[hat, worn[&"hat"]], [clothes, worn[&"clothes"]]]:
		var node := pair[0] as Node3D
		if node == null:
			continue
		var piece := Wardrobe.of(pair[1])
		for mi: MeshInstance3D in _meshes(node):
			if mi.mesh == null:
				continue
			var l := mi.find_blend_shape_by_name(&"SwishL")
			var r := mi.find_blend_shape_by_name(&"SwishR")
			if l >= 0 and r >= 0:
				_swishing.append([mi, l, r, piece.swish_rate if piece != null else 1])
			var c := mi.find_blend_shape_by_name(&"Crouch")
			if node == clothes and c >= 0:
				_crouching.append([mi, c])


## The name tag over the hat's top (or at `tag_lift` with none).
func _lift_tag() -> void:
	var tag := _looks.tag()
	if tag == null:
		return
	var top := 0.0
	if hat != null:
		var point := hat.get_parent() as Node3D
		var first := true
		for mi: MeshInstance3D in _meshes(hat):
			if mi.mesh == null:
				continue
			var box := (point.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
			top = box.end.y if first else maxf(top, box.end.y)
			first = false
	tag.position.y = tuning.tag_lift + top


# --- Swish ---------------------------------------------------------------------------------------

## Walking, with each step, `swish_lag` behind the body's sway, at full swing at a full waddle;
## standing, `swish_idle` of it at `swish_idle_speed`.
func _swish(delta: float) -> void:
	if _swishing.is_empty() or _looks.ragdolled:
		return
	_swish_clock += delta
	var walk := _looks.walk
	var idle := sin(_swish_clock * tuning.swish_idle_speed) * (1.0 - walk) * tuning.swish_idle
	for s: Array in _swishing:
		var mi := s[0] as MeshInstance3D
		var v := clampf(sin(_looks.walk_phase() * int(s[3]) - tuning.swish_lag) * walk * tuning.swish + idle, -1.0, 1.0)
		mi.set_blend_shape_value(int(s[1]), maxf(v, 0.0))
		mi.set_blend_shape_value(int(s[2]), maxf(-v, 0.0))


# --- The Trail -----------------------------------------------------------------------------------

## A foot came down: a mark there, when it walks enough and leaves a Trail.
func _on_stepped(foot: Node3D) -> void:
	if demo or _trail_scene == null or not _looks.leaves_trail or not is_inside_tree():
		return
	if _looks.walk <= tuning.step_walk:
		return
	var mark := _trail_scene.instantiate() as TrailMark
	if mark == null:
		return
	mark.top_level = true  # it stays where it was left
	_looks.add_child(mark)
	var at := foot.global_position
	mark.global_transform = Transform3D(Basis(Vector3.UP, _looks.global_rotation.y),
			Vector3(at.x, _looks.global_position.y + tuning.mark_lift, at.z))
	_keep(mark)


## Frees every mark; with `demo` and a Trail, lays the sample already walked.
func _restart_trail() -> void:
	for m in marks():
		m.queue_free()
	_marks.clear()
	_demo_clock = 0.0
	_demo_step = 0
	if demo and _trail_scene != null:
		for i: int in tuning.demo_steps:
			_demo_next(tuning.demo_time * float(tuning.demo_steps - i))


## The sample's next step, laid `ago` seconds back: from behind forward, left and right in turn, again.
func _demo_next(ago: float) -> void:
	var mark := _trail_scene.instantiate() as TrailMark
	if mark == null:
		return
	var k := _demo_step % tuning.demo_steps
	var side := tuning.demo_side if _demo_step % 2 == 0 else -tuning.demo_side
	_demo_step += 1
	mark.position = Vector3(tuning.demo_x + side, tuning.mark_lift, tuning.demo_back - tuning.demo_stride * float(k))
	if ago > 0.0:
		mark.laid_ago(ago)
	_looks.add_child(mark)
	_keep(mark)


func _keep(mark: TrailMark) -> void:
	var kept := marks()
	kept.append(mark)
	while kept.size() > mark.max_marks:
		kept.pop_front().queue_free()
