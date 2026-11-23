## A wall mirror's glass (the old house/mirror.gd: flat/48, Q350; house/15; assets/07, Q2505): a real
## planar reflection. A second camera stands at the eye's mirror image behind the glass, looking out
## through it, its frustum cut to the glass (the near plane just past the mirror's plane), and renders
## into the SubViewport the glass shows (mirror.gdshader). It reflects the room and the Teammates, and
## the player's own creature: the local Player's full body drawn only for the mirror (its
## mirror_body(), render layer MIRROR_ONLY, which the eye's camera skips), while their first-person
## belly and held items (layer FIRST_PERSON) and the Mess Socks stay out of it.
##
## It renders only while the glass is on screen: the eye in front of it, within reach, some of the
## glass in the eye's view and no wall between (looked once a physics tick); then every
## `update_every`-th frame, the first one at once. With the reflection off (the graphics preset's
## `mirror`: Low) the glass shows a soft gradient and nothing extra renders. Looks of this machine
## only: it holds no state. The scene (mirror.tscn) stands at the glass's centre, facing +Z.
class_name Mirror
extends Node3D

## Render layers (bits): drawn by the eye's camera but not reflected; reflected but not drawn by the
## eye's camera; the glass itself (never reflected in itself); the Mess Socks (MessDrawing).
const FIRST_PERSON := 1 << 10
const MIRROR_ONLY := 1 << 11
const GLASS := 1 << 12
const MESS_SOCKS := 1 << 14
const ALL_LAYERS := 0xFFFFF
## How far (m) past the mirror's plane the reflection starts: clear of the modelled glass.
const NEAR_SKIP := 0.012
## Every Mirror is in this group (the own mirror body shows while any of them renders).
const GROUP := &"mirrors"

@export var tuning: MirrorTuning
## Half the glass's width and height (the shader cuts the inscribed oval out of it).
@export var half := Vector2(0.3, 0.55)
## How far (m) in front of the glass the piece round it stands out (the wall check aims past it).
@export var ahead := 0.035

## Whether a real reflection is drawn at all (false: the gradient).
var reflect := true
## Whether it renders this frame (reflect, and the glass on screen).
var active := false
## How many pictures it has drawn (tests).
var rendered := 0

@onready var glass: MeshInstance3D = $Glass
@onready var viewport: SubViewport = $Reflection
@onready var camera: Camera3D = $Reflection/MirrorCamera

var _material: ShaderMaterial
var _env: Environment
## Frames since the reflection came into view (update_every).
var _since := 0
## For each probe point, whether no wall stood between the eye and it at the last physics tick.
var _clear: Array[bool] = []
## The local Player whose own body the mirror shows, while it renders.
var _player: Player = null


func _ready() -> void:
	add_to_group(GROUP)
	var t := _tuning()
	reflect = GraphicsPreset.chosen().mirror
	var quad := QuadMesh.new()
	quad.size = half * 2.0
	glass.mesh = quad
	glass.layers = GLASS
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = (glass.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	glass.material_override = _material
	viewport.size = Vector2i(maxi(1, roundi(t.size * half.x / half.y)), t.size)
	viewport.use_hdr_2d = true
	viewport.msaa_3d = Viewport.MSAA_2X if t.msaa == 2 else Viewport.MSAA_DISABLED
	viewport.positional_shadow_atlas_size = 4096 if t.lamp_shadows else 0
	viewport.audio_listener_enable_3d = false
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	camera.projection = Camera3D.PROJECTION_FRUSTUM
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.cull_mask = ALL_LAYERS & ~(FIRST_PERSON | GLASS)
	if not t.mess_socks:
		camera.cull_mask &= ~MESS_SOCKS
	_material.set_shader_parameter(&"reflection", viewport.get_texture())
	_show(false)


## Turns the real reflection on or off (the graphics preset).
func set_reflect(on: bool) -> void:
	reflect = on
	if not on:
		_show(false)


## Where point `p` appears behind the glass (its mirror image through the mirror's plane).
func image_of(p: Vector3) -> Vector3:
	var n := global_basis.z.normalized()
	return p - 2.0 * (p - global_position).dot(n) * n


## The glass's centre and four points round its rim.
func probe_points() -> Array[Vector3]:
	var out: Array[Vector3] = [global_position]
	for a: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN]:
		out.append(global_position + global_basis * (a * Vector3(half.x, half.y, 0.0) * 0.9))
	return out


## The wall rays, once a physics tick (never in a render frame).
func _physics_process(_delta: float) -> void:
	_clear.clear()
	var eye := get_viewport().get_camera_3d()
	if not reflect or eye == null or eye == camera:
		return
	var n := global_basis.z
	for p in probe_points():
		_clear.append(PhysicsQueries.ray(self, eye.global_position, p + n * (ahead + 0.02), Mess.LAYER_HOUSE).is_empty())


## Whether the glass is on screen for `eye` with the walls as of the last physics tick: the eye in front
## of it and within reach, and a probe point clear and in the eye's view.
func on_screen(eye: Camera3D) -> bool:
	var reach := _tuning().reach
	var from := eye.global_position
	if (from - global_position).dot(global_basis.z) < 0.02 or (reach > 0.0 and from.distance_to(global_position) > reach):
		return false
	var points := probe_points()
	for i in mini(points.size(), _clear.size()):
		if _clear[i] and eye.is_position_in_frustum(points[i]):
			return true
	return false


func _process(_delta: float) -> void:
	var eye := get_viewport().get_camera_3d()
	var was := active
	_show(reflect and eye != null and eye != camera and on_screen(eye), eye)
	if not active:
		return
	if not was:
		_since = 0  # the first frame in view draws at once
	_follow(eye)
	var every := maxi(1, _tuning().update_every)
	var draw := _since % every == 0
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE if draw else SubViewport.UPDATE_DISABLED
	if draw:
		rendered += 1
	_since += 1


## Puts the reflection camera at the eye's mirror image, looking out through the glass, its frustum
## the glass itself (the near plane NEAR_SKIP past the glass, offset to the glass's centre), and the
## local player's own belly and held items out of it, their full body in it.
func _follow(eye: Camera3D) -> void:
	var b := global_basis.orthonormalized()
	var n := b.z
	var e := eye.global_position
	var d := (e - global_position).dot(n)
	var image := e - 2.0 * d * n
	var cam_basis := Basis(-b.x, b.y, -b.z)
	camera.global_transform = Transform3D(cam_basis, image)
	var rel := global_position - image
	var k := (d + NEAR_SKIP) / d
	camera.set_frustum(half.y * 2.0 * k, Vector2(rel.dot(cam_basis.x), rel.dot(cam_basis.y)) * k, d + NEAR_SKIP,
			maxf(d + 0.1, _tuning().far))
	eye.cull_mask &= ~MIRROR_ONLY
	if _env == null:
		_env = _reflection_environment()
		camera.environment = _env
	if _player != null:
		put_on_layer(_player.own_body(), FIRST_PERSON)
		put_on_layer(_player.held_view(), FIRST_PERSON)
		put_on_layer(_player.mirror_body(), MIRROR_ONLY)


## A copy of the world's environment for the reflection: linear, no grade, glow or SSAO (the eye's
## camera tonemaps and grades the glass with the rest of the room); null with none.
func _reflection_environment() -> Environment:
	var world := get_world_3d()
	var source := world.environment if world != null else null
	if source == null:
		return null
	var env := source.duplicate() as Environment
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = false
	env.glow_enabled = false
	env.ssao_enabled = false
	return env


## Starts or stops rendering; the own mirror body of the eye's player shows only while any mirror renders.
func _show(on: bool, eye: Camera3D = null) -> void:
	active = on
	if viewport != null and not on:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _material != null:
		# Until it has drawn once the picture is black: the gradient shows instead.
		_material.set_shader_parameter(&"live", reflect and (on or rendered > 0))
	var player := eye.owner as Player if eye != null else null
	if player != null:
		_player = player
	if _player == null or not is_instance_valid(_player):
		return
	var any := on
	if not any and is_inside_tree():
		for m in get_tree().get_nodes_in_group(GROUP):
			if m != self and (m as Mirror).active:
				any = true
	var body := _player.mirror_body()
	if body != null:
		body.visible = any


## Puts every mesh under `node` on render layer `layer` alone (held items come and go, so this runs
## every frame the mirror renders).
static func put_on_layer(node: Node, layer: int) -> void:
	if not is_instance_valid(node):
		return
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = layer
	for c in node.get_children():
		put_on_layer(c, layer)


func _tuning() -> MirrorTuning:
	if tuning == null:
		tuning = MirrorTuning.new()
	return tuning
