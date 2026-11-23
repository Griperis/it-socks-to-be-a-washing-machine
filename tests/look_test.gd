## The picture settings (core/18, V03-V04, V06): the anti-aliasing is in force at the high preset and the three presets
## are chosen by a project setting. The look-only light, grade, Theme and crosshair-shape cases are gone (Q2429). One real-path case: a player holds a Sock at the
## handling station and aims where it cannot drop, and the crosshair on screen turns red.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"

var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "v03_aa", "method": "case_v03", "world": false,
				"title": "V03: the window renders with MSAA 4x and FXAA at the high preset, and the project settings say so"},
		{"name": "v04_presets", "method": "case_v04", "world": false,
				"title": "V04: low, medium and high are the old presets; the project setting names one, high by default, and each applies its numbers"},
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


func case_real_path() -> void:
	await _zoo_up()
	var player := LevelRuntime.of(_zoo).player
	var mess := LevelRuntime.of(_zoo).mess
	var hands := LevelRuntime.of(_zoo).hands
	var handling := _zoo.get_node("Stations/Handling") as Node3D
	var cross := player.get_node("Hud/Crosshair") as Crosshair
	player.capture_mouse()   # the mouse is the player's: buttons act (R01)
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
	await _press(&"drop_throw")
	await _physics_ticks(3)
	_check(player.message() == Player.CANT_DROP, "the refusal shows in the old words (%s)" % player.message())
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
