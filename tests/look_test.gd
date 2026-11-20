## The picture and the theme (core/18, V01-V07): the zoo is lit as the old game at noon, the old post-processing and
## anti-aliasing are in force at the high preset, the three presets are chosen by a project setting, every 2D text takes
## the Patrick Hand theme and the crosshair is the old two bars. One real-path case: a player holds a Sock at the
## handling station and aims where it cannot drop, and the crosshair on screen turns red.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const THEME := "res://game/look/theme.tres"
const FONT := "res://assets/fonts/patrickhand/PatrickHand-Regular.ttf"
## The old picture's numbers (room.gd, day_cycle.gd, ambient.gd).
const SUN_COLOUR := Color(1.0, 0.93, 0.82)

var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "v01_light", "method": "case_v01", "world": false,
				"title": "V01: the zoo's sky is the day HDRI, it gives ambient light 0.7 and the reflections, and the sun is warm, 2.4, soft, 4 cascades to 18 m"},
		{"name": "v02_post", "method": "case_v02", "world": false,
				"title": "V02: AgX at exposure 1.1, the old grade, the vignette, SSAO and glow as the old game set them"},
		{"name": "v03_aa", "method": "case_v03", "world": false,
				"title": "V03: the window renders with MSAA 4x and FXAA at the high preset, and the project settings say so"},
		{"name": "v04_presets", "method": "case_v04", "world": false,
				"title": "V04: low, medium and high are the old presets; the project setting names one, high by default, and each applies its numbers"},
		{"name": "v05_theme", "method": "case_v05", "world": false,
				"title": "V05: the project's one Theme gives every 2D text Patrick Hand, the HUD's labels are outlined, a 3D sign keeps the plain font"},
		{"name": "v06_crosshair", "method": "case_v06", "world": false,
				"title": "V06: the crosshair is two bars 18 by 2 px around the screen centre, white at alpha 0.9"},
		{"name": "v06_real_path", "method": "case_real_path", "world": false,
				"title": "V06, real path: the player picks a Sock by the pick action, aims where it cannot drop, and the crosshair on screen turns the old red; aimed at the table it is white"},
	]


func _before_case() -> void:
	for a: StringName in [&"pick", &"drop_throw"]:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _zoo != null:
		_zoo.free()
		_zoo = null


func _zoo_up() -> Picture:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	await _frames(2)
	return _zoo.get_node("Picture") as Picture


func case_v01() -> void:
	var picture := await _zoo_up()
	var env := (_zoo.get_node("Environment") as WorldEnvironment).environment
	_check(env.background_mode == Environment.BG_SKY, "the sky is the background")
	var material := env.sky.sky_material as ShaderMaterial
	_check(material != null and (material.get_shader_parameter("day_panorama") as Texture2D) != null
			and (material.get_shader_parameter("day_panorama") as Texture2D).resource_path.ends_with("suburban_garden_2k.hdr"),
			"the sky shows the old day HDRI")
	_check(env.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "ambient light comes from the sky")
	_near(env.ambient_light_energy, 0.7, 0.0001, "ambient energy 0.7")
	_check(env.reflected_light_source == Environment.REFLECTION_SOURCE_SKY, "reflections come from the sky")
	var sun := _zoo.get_node("Sun") as DirectionalLight3D
	_check(sun.light_color.is_equal_approx(SUN_COLOUR), "the sun is warm (1.0, 0.93, 0.82)")
	_near(sun.light_energy, 2.4, 0.0001, "sun energy 2.4")
	_check(sun.shadow_enabled, "the sun casts shadows")
	_near(sun.shadow_blur, 1.5, 0.0001, "shadows are soft (blur 1.5)")
	_check(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "4 cascades")
	_near(sun.directional_shadow_max_distance, 18.0, 0.0001, "shadows reach 18 m")
	_check(sun.sky_mode == DirectionalLight3D.SKY_MODE_LIGHT_ONLY, "the sun lights only, it is not drawn in the sky")
	var elevation := rad_to_deg(asin(sun.global_basis.z.y))
	_near(elevation, 27.3, 0.2, "the sun stands at the old noon's elevation")
	_check(picture.applied != null, "the picture applied a preset")


func case_v02() -> void:
	var picture := await _zoo_up()
	var env := (_zoo.get_node("Environment") as WorldEnvironment).environment
	_check(env.tonemap_mode == Environment.TONE_MAPPER_AGX, "AgX tonemap")
	_near(env.tonemap_exposure, 1.1, 0.0001, "exposure 1.1")
	_check(env.adjustment_enabled and env.adjustment_color_correction != null, "the colour grade is on, with its table")
	_near(env.adjustment_contrast, 1.1, 0.0001, "grade contrast 1.1")
	_near(env.adjustment_saturation, 1.2, 0.0001, "grade saturation 1.2")
	var table := (env.adjustment_color_correction as GradientTexture1D).gradient
	_check(table.colors.size() == 3 and table.colors[1].is_equal_approx(Color(0.5, 0.5, 0.49)) and table.colors[2].is_equal_approx(Color(1.0, 0.975, 0.93)),
			"the noon table is the old one")
	_check(env.ssao_enabled, "SSAO on")
	_near(env.ssao_radius, 0.5, 0.0001, "SSAO radius 0.5")
	_near(env.ssao_intensity, 1.6, 0.0001, "SSAO intensity 1.6")
	_near(env.ssao_power, 1.4, 0.0001, "SSAO power 1.4")
	_check(env.glow_enabled, "glow on")
	_near(env.glow_intensity, 0.35, 0.0001, "glow intensity 0.35")
	_near(env.glow_bloom, 0.04, 0.0001, "glow bloom 0.04")
	_near(env.glow_hdr_threshold, 1.1, 0.0001, "glow HDR threshold 1.1")
	_check(env.glow_blend_mode == Environment.GLOW_BLEND_MODE_SOFTLIGHT, "soft-light glow")
	var rect := picture.get_node("Vignette/Rect") as ColorRect
	var material := rect.material as ShaderMaterial
	_check(picture.vignette.visible and picture.vignette.layer == -10, "the vignette shows, under the HUD")
	_near(float(material.get_shader_parameter("amount")), 0.5, 0.0001, "vignette amount 0.5")
	_check((material.get_shader_parameter("tint") as Vector3).is_equal_approx(Vector3(0.05, 0.03, 0.06)), "vignette tint (0.05, 0.03, 0.06)")
	_check(rect.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the vignette lets the mouse through")


func case_v03() -> void:
	await _zoo_up()
	var vp := get_viewport()
	_check(vp.msaa_3d == Viewport.MSAA_4X, "MSAA 4x on the window")
	_check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA, "FXAA on the window")
	_check(int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")) == Viewport.MSAA_4X, "the project setting is MSAA 4x")
	_check(int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa")) == Viewport.SCREEN_SPACE_AA_FXAA, "the project setting is FXAA")


func case_v04() -> void:
	var picture := await _zoo_up()
	_check(String(ProjectSettings.get_setting(GraphicsPreset.SETTING)) == "high", "the project setting names high")
	var high := GraphicsPreset.named("high")
	var medium := GraphicsPreset.named("medium")
	var low := GraphicsPreset.named("low")
	_check(GraphicsPreset.chosen().resource_path == high.resource_path, "high is the one chosen")
	_check(GraphicsPreset.named("no such preset").resource_path == high.resource_path, "an unknown name falls back to high")
	_check(high.msaa == 2 and high.fxaa and high.sun_splits == 4 and high.sun_soft and high.sun_atlas == 4096 and is_equal_approx(high.sun_distance, 18.0)
			and high.ssao and high.glow and high.sky_radiance == 256 and high.grade and is_equal_approx(high.render_scale, 1.0) and not high.fsr,
			"high is the old high preset")
	_check(medium.msaa == 0 and medium.fxaa and is_equal_approx(medium.render_scale, 0.85) and medium.fsr and medium.sun_splits == 2
			and medium.sun_soft and medium.sun_atlas == 2048 and is_equal_approx(medium.sun_distance, 18.0) and medium.ssao and medium.glow
			and medium.sky_radiance == 128 and medium.grade, "medium is the old medium preset")
	_check(low.msaa == 0 and low.fxaa and is_equal_approx(low.render_scale, 0.6) and low.fsr and low.sun_splits == 1 and not low.sun_soft
			and low.sun_atlas == 512 and is_equal_approx(low.sun_distance, 8.0) and not low.ssao and not low.glow and low.sky_radiance == 64
			and not low.grade, "low is the old low preset")
	var env := (_zoo.get_node("Environment") as WorldEnvironment).environment
	var sun := _zoo.get_node("Sun") as DirectionalLight3D
	var vp := get_viewport()
	picture.apply(low)
	_check(not env.ssao_enabled and not env.glow_enabled, "low: no SSAO, no glow")
	_check(sun.shadow_blur == 0.0 and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_ORTHOGONAL and is_equal_approx(sun.directional_shadow_max_distance, 8.0),
			"low: hard shadows, one cascade, 8 m")
	_check(env.adjustment_color_correction == null and not picture.vignette.visible, "low: no grade table, no vignette")
	_check(vp.msaa_3d == Viewport.MSAA_DISABLED and is_equal_approx(vp.scaling_3d_scale, 0.6) and vp.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR,
			"low: no MSAA, 0.6 render scale upscaled by FSR")
	picture.apply(medium)
	_check(env.ssao_enabled and env.glow_enabled and picture.vignette.visible and env.adjustment_color_correction != null, "medium: SSAO, glow, grade and vignette")
	_check(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and is_equal_approx(vp.scaling_3d_scale, 0.85), "medium: 2 cascades, 0.85 render scale")
	picture.apply(high)
	_check(env.ssao_enabled and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS and vp.msaa_3d == Viewport.MSAA_4X
			and is_equal_approx(vp.scaling_3d_scale, 1.0), "back at high everything is as it was")
	# The picture works on copies: the shared resource keeps the high look after low was applied here.
	var shared := load("res://game/look/noon_environment.tres") as Environment
	picture.apply(low)
	_check(shared.ssao_enabled and shared.glow_enabled, "the shared Environment resource is not edited by a preset")
	picture.apply(high)


func case_v05() -> void:
	await _zoo_up()
	_check(String(ProjectSettings.get_setting("gui/theme/custom")) == THEME, "the project's Theme is %s" % THEME)
	var font := load(FONT) as Font
	var theme := load(THEME) as Theme
	_check(theme.get_font("font", "Label") == font and theme.get_font("font", "Button") == font, "the Theme gives Label and Button Patrick Hand")
	_check(not theme.has_default_font(), "the Theme sets no default font, so a Label3D keeps the plain one")
	var label := Label.new()
	add_child(label)
	_check(label.get_theme_font("font") == font, "a plain Label takes Patrick Hand")
	var button := Button.new()
	add_child(button)
	_check(button.get_theme_font("font") == font, "a Button takes Patrick Hand")
	label.free()
	button.free()
	var player := _zoo.get_node("Player") as Player
	var texts := 0
	for node: Node in player.find_children("*", "Label", true, false):
		var l := node as Label
		texts += 1
		_check(l.get_theme_font("font") == font, "the HUD's %s is in Patrick Hand" % l.name)
	_check(texts >= 2, "the HUD has its labels (%d)" % texts)
	for name_: String in ["Message", "Size"]:
		var l := player.get_node("Hud/" + name_) as Label
		_check(l.theme_type_variation == &"OutlinedLabel" and l.get_theme_color("font_outline_color").is_equal_approx(Color(0.1, 0.07, 0.05))
				and l.get_theme_constant("outline_size") == 8, "%s is white text with the ink outline" % name_)
	var signs := _zoo.find_children("*", "Label3D", true, false)
	_check(not signs.is_empty(), "the zoo has 3D signs")
	for s: Node in signs:
		var sign := s as Label3D
		_check(sign.font == null, "the sign %s keeps the plain font (no theme font is forced on it)" % sign.name)


func case_v06() -> void:
	await _zoo_up()
	var cross := (_zoo.get_node("Player") as Player).get_node("Hud/Crosshair") as Crosshair
	_check(cross != null, "the HUD's crosshair is the Crosshair scene")
	if cross == null:
		return
	var bars := cross.bars()
	_check(bars.size() == 2, "two bars")
	_check(bars[0].size == Vector2(Crosshair.LENGTH, Crosshair.THICKNESS) and bars[1].size == Vector2(Crosshair.THICKNESS, Crosshair.LENGTH),
			"18 by 2 px (%s, %s)" % [bars[0].size, bars[1].size])
	_check(bars[0].get_center() == Vector2.ZERO and bars[1].get_center() == Vector2.ZERO, "both bars centre on the control, which sits on the screen centre")
	var vp_size := Vector2(get_viewport().get_visible_rect().size)
	_check(cross.get_global_rect().position.is_equal_approx(vp_size * 0.5), "the crosshair control sits at the exact centre of the screen")
	for bar: ColorRect in [cross.get_node("%Horizontal"), cross.get_node("%Vertical")]:
		_check(bar.color.is_equal_approx(Color(1, 1, 1, 0.9)), "%s is white at alpha 0.9" % bar.name)
		_check(bar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s lets the mouse through" % bar.name)
	_check(Player.CROSSHAIR_NO.is_equal_approx(Color(0.95, 0.25, 0.2)), "the blocked red is the old (0.95, 0.25, 0.2)")


func case_real_path() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	var mess := _zoo.get_node("Socks/Mess") as Mess
	var hands := _zoo.get_node("Socks/Hands") as Hands
	var handling := _zoo.get_node("Stations/Handling") as Node3D
	var cross := player.get_node("Hud/Crosshair") as Crosshair
	await _until(func() -> bool: return player.is_on_floor() and mess.looks_of(0) != null, "the player to stand and the Socks to lie")
	var sock := (handling.get_node("Spots/Floor") as SockSpot).sock
	player.global_position = handling.to_global(Vector3(0.0, 0.0, 1.5))
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	var aim_at := mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)
	await _aim(player, aim_at)
	_check(cross.modulate == Player.CROSSHAIR_OK, "with empty Hands the crosshair is white")
	await _press(&"pick")
	await _until(func() -> bool: return hands.active_of(1) == sock, "the Sock to be in the Hands")
	# Aim at the wall of the sky: far away, where a drop is refused.
	await _aim(player, player.global_position + Vector3(0.0, 1.6, -30.0))
	await _until(func() -> bool: return cross.modulate == Player.CROSSHAIR_NO, "the crosshair on screen to turn red")
	_check(cross.modulate.is_equal_approx(Color(0.95, 0.25, 0.2)), "it is the old red")
	await _press(&"drop_throw")
	await _physics_ticks(3)
	_check(player.message() == Player.CANT_DROP, "the refusal shows in the old words (%s)" % player.message())
	var message := player.get_node("Hud/Message") as Label
	_check(message.visible and message.get_theme_font("font") == load(FONT), "the message is on screen in Patrick Hand")
	await _aim(player, aim_at)
	await _until(func() -> bool: return cross.modulate == Player.CROSSHAIR_OK, "the crosshair to turn white again where a drop is allowed")


## Turns `player` to `target` and pitches its head at it, as the mouse would.
func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


## Presses an action for two physics ticks, then lets it go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)
