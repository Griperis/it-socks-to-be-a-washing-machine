## The picture of a level (core/18): puts a graphics preset on the level's WorldEnvironment, its Sun and the window's
## viewport, and shows or hides the vignette. The zoo has one (picture.tscn). It takes the preset the project setting
## names (GraphicsPreset.chosen()) unless a preset is set here, and works on its own copies of the Environment and the
## Sky, so one level's preset never edits the shared resource.
class_name Picture
extends Node

## The old grade at noon without the lookup table (room.gd _polish), used when the preset has no grade.
const PLAIN_CONTRAST := 1.06
const PLAIN_SATURATION := 1.12
## The grade with the table (ambient.gd _grade).
const GRADE_CONTRAST := 1.1
const GRADE_SATURATION := 1.2
## The old soft shadow edge of the sun (room.gd SUN_SHADOW_BLUR).
const SUN_BLUR := 1.5

@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
## The vignette's layer (a child in picture.tscn); shown while the preset has the grade.
@export var vignette: CanvasLayer
## A preset to use instead of the project setting's (a test, a station).
@export var preset: GraphicsPreset

## The preset in force now.
var applied: GraphicsPreset = null

var _grade_table: Texture2D = null


func _ready() -> void:
	if world_environment != null and world_environment.environment != null:
		var env := world_environment.environment.duplicate() as Environment
		if env.sky != null:
			env.sky = env.sky.duplicate() as Sky
		_grade_table = env.adjustment_color_correction
		world_environment.environment = env
	apply(preset if preset != null else GraphicsPreset.chosen())


## Puts `p` on the environment, the sun and the viewport.
func apply(p: GraphicsPreset) -> void:
	applied = p
	if world_environment != null and world_environment.environment != null:
		var env := world_environment.environment
		env.ssao_enabled = p.ssao
		env.glow_enabled = p.glow
		if env.sky != null:
			# Sky.RADIANCE_SIZE_32 is 0 and each step doubles the size.
			env.sky.radiance_size = clampi(roundi(log(float(p.sky_radiance) / 32.0) / log(2.0)), 0,
					Sky.RADIANCE_SIZE_2048) as Sky.RadianceSize
		env.adjustment_enabled = true
		env.adjustment_color_correction = _grade_table if p.grade else null
		env.adjustment_contrast = GRADE_CONTRAST if p.grade else PLAIN_CONTRAST
		env.adjustment_saturation = GRADE_SATURATION if p.grade else PLAIN_SATURATION
	if sun != null:
		match p.sun_splits:
			4:
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			1:
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			_:
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.shadow_blur = SUN_BLUR if p.sun_soft else 0.0
		sun.directional_shadow_max_distance = p.sun_distance
	if vignette != null:
		vignette.visible = p.grade
	RenderingServer.directional_shadow_atlas_set_size(p.sun_atlas, true)
	var vp := get_viewport()
	if vp != null:
		vp.msaa_3d = p.msaa as Viewport.MSAA
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if p.fxaa else Viewport.SCREEN_SPACE_AA_DISABLED
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if p.fsr else Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = p.render_scale
