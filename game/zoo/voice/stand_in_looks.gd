## The Voice station's graybox face (core/85): the washer's Looks contract in the plainest boxes until the real
## washer (core/86, assets/14) stands in its place. A `Skeleton3D` named `face_rig` has the bones the baked acting
## keys (`lean`, and under it `door_hinge`, `brow_left_pivot`, `brow_right_pivot`), their rests the speaker's
## `VoiceActing` rests; a box body on `lean`, a disc door on `door_hinge`, a bar each brow, a drum glow driven by the
## `glow_colour` and `glow_energy` the acting keys. The take's acting plays on its AnimationPlayer.
class_name StandInLooks
extends VoiceSource

const BODY_SIZE := Vector3(0.7, 0.95, 0.7)
const DOOR_RADIUS := 0.24
const BROW_SIZE := Vector3(0.2, 0.03, 0.03)

var _skeleton: Skeleton3D
var _glow: StandardMaterial3D


func _ready() -> void:
	_build()
	super._ready()


func _process(_delta: float) -> void:
	if _glow != null:
		_glow.emission = glow_colour
		_glow.emission_energy_multiplier = glow_energy * 0.25
		_glow.albedo_color = Color(0.25, 0.25, 0.28).lerp(glow_colour, clampf(glow_energy * 0.25, 0.0, 1.0))


func _build() -> void:
	if speaker == null or speaker.acting == null:
		return
	var acting := speaker.acting
	_skeleton = Skeleton3D.new()
	_skeleton.name = "face_rig"
	add_child(_skeleton)
	var lean := _bone(acting.lean_bone, acting.lean_rest, -1)
	var door := _bone(acting.mouth_bone, acting.mouth_rest, lean)
	var left := _bone(acting.brow_left_bone, acting.brow_left_rest, lean)
	var right := _bone(acting.brow_right_bone, acting.brow_right_rest, lean)
	_skeleton.reset_bone_poses()
	var body := StandardMaterial3D.new()
	body.albedo_color = Color(0.6, 0.85, 0.75)
	_attach(lean, _box(BODY_SIZE, body), Vector3(0.0, BODY_SIZE.y * 0.5, 0.0))
	var door_mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = DOOR_RADIUS
	disc.bottom_radius = DOOR_RADIUS
	disc.height = 0.04
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.2, 0.25, 0.3)
	door_mesh.mesh = disc
	door_mesh.material_override = glass
	door_mesh.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_attach(door, door_mesh, Vector3(-acting.mouth_rest.origin.x, 0.0, 0.0))
	var brow := StandardMaterial3D.new()
	brow.albedo_color = Color(0.12, 0.1, 0.1)
	_attach(left, _box(BROW_SIZE, brow), Vector3.ZERO)
	_attach(right, _box(BROW_SIZE, brow), Vector3.ZERO)
	_glow = StandardMaterial3D.new()
	_glow.emission_enabled = true
	var drum := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.12
	ball.height = 0.24
	drum.mesh = ball
	drum.material_override = _glow
	_attach(lean, drum, Vector3(0.0, 0.42, 0.28))
	if find_child("AnimationPlayer", false, false) == null:
		var anim := AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		add_child(anim)
		player = anim


func _bone(bone: StringName, rest: Transform3D, parent: int) -> int:
	var i := _skeleton.get_bone_count()
	_skeleton.add_bone(String(bone))
	_skeleton.set_bone_parent(i, parent)
	_skeleton.set_bone_rest(i, rest)
	return i


func _attach(bone: int, mesh: MeshInstance3D, offset: Vector3) -> void:
	var holder := BoneAttachment3D.new()
	holder.name = "On_%s" % _skeleton.get_bone_name(bone)
	holder.bone_name = _skeleton.get_bone_name(bone)
	_skeleton.add_child(holder)
	mesh.position += offset
	holder.add_child(mesh)


func _box(size: Vector3, material: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	m.material_override = material
	return m
