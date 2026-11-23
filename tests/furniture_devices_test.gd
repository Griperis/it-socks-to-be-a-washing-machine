## The furniture devices (assets/07, Q2502-Q2508): every opening's old open and shut sound by its
## container kind, the wall mirror's planar reflection, the dust sheet
## over a locked Cabinet and its pull-off, the Old Tree unchanged. One case per behaviour line of
## docs/llm/assets/issues/07-furniture-devices.md (the piano's: piano_test.gd); the real paths walk the zoo's player to the
## Furniture station and use the pieces with its own buttons.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const FOLDER := "res://game/furniture"
const MIRROR := "res://game/furniture/wall_mirror.tscn"
const STATION := "Stations/Furniture"
const LINE_UP := "Stations/Furniture/LineUp"
## The old clips by event (the old sounds.json picks, else the pool's first: Q2277).
const OLD_CLIPS := {
	&"drawer_open": "drawer_open__laleksic_drawer_open.ogg", &"drawer_close": "drawer_close__laleksic_drawer_close.ogg",
	&"cupboard_open": "cupboard_open__qubodup_door_open1.ogg", &"cupboard_close": "cupboard_close__qubodup_door_close1.ogg",
	&"fridge_open": "fridge_open__rubberduck_microwave_open.ogg", &"fridge_close": "fridge_close__rubberduck_microwave_close.ogg",
	&"oven_open": "oven_open__rubberduck_metal_open.ogg", &"oven_close": "oven_close__rubberduck_metal_close.ogg",
	&"basket_open": "basket_open__kenney_creak3.ogg", &"basket_close": "basket_close__rubberduck_wood_misc2.ogg",
	&"litter_flap_open": "cupboard_open__kenney_door_open1.ogg", &"litter_flap_close": "cupboard_close__kenney_door_close4.ogg",
	&"piano_lid_open": "cupboard_open__kenney_door_open1.ogg", &"piano_lid_close": "cupboard_close__kenney_door_close4.ogg",
	&"cabinet_reveal": "drawer_open__laleksic_drawer_open.ogg",
}
## The old container kinds of the 28 openings and how many of each (the old manifest).
const KINDS := {"drawer": 12, "cupboard": 10, "fridge": 2, "oven": 1, "basket": 1, "litter_flap": 1, "piano_lid": 1}
const ACTIONS: Array[StringName] = [&"move_forward", &"interact", &"pick"]

var _zoo: Node3D = null
var _level: Node = null
var _heard: Array[Dictionary] = []
## Game seconds (the runner's fixed frames), what the tweens count in.
var _clock := 0.0


func _process(delta: float) -> void:
	_clock += delta


func cases() -> Array[Dictionary]:
	return [
		{"name": "v01_kinds", "method": "case_v01_kinds", "world": false,
				"title": "V01a-g: every opening plays <kind>_open and <kind>_close, world sounds from the catalogue with the old clips (the litter flap 6 dB under)"},
		{"name": "v01_real_path", "method": "case_v01_real_path", "world": false,
				"title": "V01h, real path: the player uses the fridge's door in the Furniture station: fridge_open sounds at it as it swings, fridge_close as it shuts"},
		{"name": "v01_once", "method": "case_v01_once", "world": false,
				"title": "V01h: a granted open sounds once; a refused one and a state arriving whole sound nothing"},
		{"name": "m01_reflection", "method": "case_m01_reflection", "world": false,
				"title": "M01, M02, M09: the mirror's camera stands at the eye's image behind the glass, its frustum the glass (near 0.012 m past it, far 6 m), 256 px high, no MSAA or lamp shadows, the glass never in it"},
		{"name": "m03_on_screen", "method": "case_m03_on_screen", "world": false,
				"title": "M03: it renders only with the eye in front of it, within 4.5 m, the glass in view and no wall between"},
		{"name": "m04_every_third", "method": "case_m04_every_third", "world": false,
				"title": "M04: in view it draws its first frame at once and then every 3rd frame"},
		{"name": "m06_low", "method": "case_m06_low", "world": false,
				"title": "M05-M07: the glass shader cuts the oval, mirrors and tints the picture; on the Low preset or before its first picture it shows the gradient"},
		{"name": "m08_real_path", "method": "case_m08_real_path", "world": false,
				"title": "M08, real path: the player walks up to the wall mirror: it reflects, the player's full body shows only in it, the belly, held items and Mess Socks stay out, Teammates stay in"},
		{"name": "d01_drape", "method": "case_d01_drape", "world": false,
				"title": "D01, D02, D05: the locked Cabinet at the station wears an off-white sheet over its top, down its front and sides to the floor, no collision; its drawers stay shut"},
		{"name": "d05_unaimable", "method": "case_d05_unaimable", "world": false,
				"title": "D05 (Q2513), real path: under its sheet the Cabinet and its drawers cannot be aimed at (no outline, no prompt, a click asks nothing); unsheeted, a drawer aims as usual"},
		{"name": "d03_real_path", "method": "case_d03_real_path", "world": false,
				"title": "D03, D04, D07, real path: the player uses the station's switch: the Cabinet unlocks for everyone, the sheet slides forward, fades and is gone in 0.5 s, then the reveal sounds over it"},
		{"name": "d06_now", "method": "case_d06_now", "world": false,
				"title": "D06: a state arriving whole shows the sheet as it stands with no pull or sound; locked again, it drapes at once"},
		{"name": "v05_old_tree", "method": "case_v05_old_tree", "world": false,
				"title": "V05, D08: the Old Tree and the sheeted sofa stay models: no script, no motion of their own"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _zoo != null:
		_zoo.free()
		_zoo = null
	if _level != null and is_instance_valid(_level):
		_level.free()
	_level = null
	_heard.clear()
	if not Sounds.played.is_connected(_on_played):
		Sounds.played.connect(_on_played)


func _on_played(event: StringName, spatial: bool, at: Vector3, bus: StringName) -> void:
	_heard.append({"event": event, "spatial": spatial, "at": at, "bus": bus})


func _count(event: StringName) -> int:
	var n := 0
	for h in _heard:
		if h["event"] == event:
			n += 1
	return n


func _last(event: StringName) -> Dictionary:
	for i in range(_heard.size() - 1, -1, -1):
		if _heard[i]["event"] == event:
			return _heard[i]
	return {}


# --- Openings ------------------------------------------------------------------------------------


func case_v01_kinds() -> void:
	var counts := {}
	for path in FurnitureLineUp.pieces(FOLDER):
		var piece := (load(path) as PackedScene).instantiate()
		for o: Node in piece.find_children("Openable", "Node", true, false):
			var openable := o as Openable
			if openable == null:
				continue
			var kind := String(openable.get_meta(&"kind", ""))
			counts[kind] = int(counts.get(kind, 0)) + 1
			_check(openable.open_sound == StringName(kind + "_open") and openable.close_sound == StringName(kind + "_close"),
					"%s/%s (%s) sounds %s and %s" % [piece.name, o.get_parent().name, kind, openable.open_sound, openable.close_sound])
		piece.free()
	_same(counts, KINDS, "the openings' kinds are the old ones")
	for event: StringName in OLD_CLIPS:
		var e := Sounds.catalogue.find(event)
		_check(e != null, "the catalogue has %s" % event)
		if e == null:
			continue
		_check(e.spatial, "%s is a world sound" % event)
		_check(e.clips.size() == 1 and e.clips[0] != null and e.clips[0].resource_path.get_file() == OLD_CLIPS[event],
				"%s plays the old clip %s" % [event, OLD_CLIPS[event]])
		var want := -6.0 if String(event).begins_with("litter_flap") else 0.0
		_near(e.volume_db, want, 0.001, "%s at %.0f dB" % [event, want])


func case_v01_real_path() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	var fridge := _piece("fridge")
	var door := fridge.get_node("Door_Top") as Node3D
	var openable := door.get_node("Openable") as Openable
	_stand(player, fridge.to_global(Vector3(0.0, 0.0, 1.1)))
	await _physics_ticks(3)
	await _aim(player, fridge.to_global(Vector3(0.0, 1.4, 0.36)))
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return openable.open, "the fridge door to open")
	_check(_count(&"fridge_open") == 1, "fridge_open sounded once (%d)" % _count(&"fridge_open"))
	var h := _last(&"fridge_open")
	_check(not h.is_empty() and (h["at"] as Vector3).distance_to(door.global_position) < 0.01, "at the door's place")
	_check(openable.is_moving(), "while the door swings")
	await _until(func() -> bool: return not openable.is_moving(), "the swing to end", 120)
	var leaf := openable.movers()[0]
	await _aim(player, (leaf.get_child(leaf.get_child_count() - 1) as Node3D).global_position)
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return not openable.open, "the fridge door to shut")
	_check(_count(&"fridge_close") == 1, "fridge_close sounded once as it shuts")


func case_v01_once() -> void:
	_level = Node3D.new()
	var piece := (load(FOLDER.path_join("laundry_basket.tscn")) as PackedScene).instantiate() as Node3D
	_level.add_child(piece)
	var parts := Parts.new()
	parts.level = _level
	_level.add_child(parts)
	add_child(_level)
	await _frames(2)
	var openable := piece.get_node("Lid/Openable") as Openable
	_heard.clear()
	parts.ask(Command.new(&"open", 1, openable.id, {"open": true}))
	_check(openable.open and _count(&"basket_open") == 1, "a granted open sounds basket_open once")
	parts.ask(Command.new(&"open", 1, openable.id, {"open": true}))
	_check(_count(&"basket_open") == 1, "a refused one (already open) sounds nothing")
	parts.load_snapshot({openable.id: {"open": false}})
	_check(not openable.open and _count(&"basket_close") == 0, "a snapshot shutting it sounds nothing")


# --- The mirror ----------------------------------------------------------------------------------

## A level with the wall mirror lifted to eye height and a camera at `eye`; returns the Mirror.
func _mirror_level(eye: Vector3) -> Mirror:
	var level := Node3D.new()
	level.name = "Level"
	var piece := (load(MIRROR) as PackedScene).instantiate() as Node3D
	piece.position = Vector3(0.0, 1.0, 0.0)
	level.add_child(piece)
	var cam := Camera3D.new()
	cam.name = "Eye"
	level.add_child(cam)
	add_child(level)
	_level = level
	cam.global_position = eye
	cam.look_at(piece.get_node("Mirror").global_position)
	cam.make_current()
	return piece.get_node("Mirror") as Mirror


func case_m01_reflection() -> void:
	var mirror := _mirror_level(Vector3(0.4, 1.7, 2.0))
	await _physics_ticks(2)
	await _frames(2)
	_check(mirror.active, "in front of the eye it reflects")
	var eye := get_viewport().get_camera_3d()
	var n := mirror.global_basis.z
	var d := (eye.global_position - mirror.global_position).dot(n)
	_check(mirror.camera.global_position.is_equal_approx(mirror.image_of(eye.global_position)), "its camera stands at the eye's image behind the glass")
	_check(mirror.camera.global_basis.z.dot(n) < -0.99, "looking out through the glass")
	_check(mirror.camera.projection == Camera3D.PROJECTION_FRUSTUM, "a frustum cut to the glass")
	_near(mirror.camera.near, d + Mirror.NEAR_SKIP, 0.0001, "its near plane 0.012 m past the glass")
	_near(mirror.camera.far, 6.0, 0.0001, "it reflects 6 m")
	_near(mirror.camera.size, mirror.half.y * 2.0 * (d + Mirror.NEAR_SKIP) / d, 0.0001, "as tall as the glass at the near plane")
	_check(mirror.viewport.size == Vector2i(roundi(256 * mirror.half.x / mirror.half.y), 256), "256 px high, as wide as the glass's shape (%s)" % mirror.viewport.size)
	_check(mirror.viewport.msaa_3d == Viewport.MSAA_DISABLED and mirror.viewport.positional_shadow_atlas_size == 0, "no MSAA, no lamp shadows")
	_check(mirror.viewport.use_hdr_2d and not mirror.viewport.audio_listener_enable_3d, "linear HDR, no listener")
	_check(mirror.camera.cull_mask & Mirror.GLASS == 0 and mirror.glass.layers == Mirror.GLASS, "the glass is never in its own reflection")
	var env := mirror.camera.environment
	_check(env == null or (env.tonemap_mode == Environment.TONE_MAPPER_LINEAR and not env.glow_enabled and not env.ssao_enabled),
			"its picture is linear, ungraded (the eye's camera grades the glass)")


func case_m03_on_screen() -> void:
	var mirror := _mirror_level(Vector3(0.0, 1.6, 2.0))
	var eye := get_viewport().get_camera_3d()
	await _physics_ticks(2)
	await _frames(2)
	_check(mirror.active, "2 m in front, looking at it: it renders")
	eye.global_position = Vector3(0.0, 1.6, 5.0)
	eye.look_at(mirror.global_position)
	await _physics_ticks(2)
	await _frames(2)
	_check(not mirror.active, "beyond 4.5 m it does not")
	eye.global_position = Vector3(0.0, 1.6, 2.0)
	eye.look_at(mirror.global_position + Vector3(0.0, 0.0, 4.0))
	await _physics_ticks(2)
	await _frames(2)
	_check(not mirror.active, "looking away it does not")
	eye.global_position = Vector3(0.0, 1.6, -2.0)
	eye.look_at(mirror.global_position)
	await _physics_ticks(2)
	await _frames(2)
	_check(not mirror.active, "from behind it does not")
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 0.1)
	shape.shape = box
	wall.add_child(shape)
	_level.add_child(wall)
	wall.global_position = Vector3(0.0, 1.5, 1.0)
	eye.global_position = Vector3(0.0, 1.6, 2.0)
	eye.look_at(mirror.global_position)
	await _physics_ticks(2)
	await _frames(2)
	_check(not mirror.active, "with a wall between it does not")
	wall.free()
	await _physics_ticks(2)
	await _frames(2)
	_check(mirror.active, "the wall gone, it does again")


func case_m04_every_third() -> void:
	var mirror := _mirror_level(Vector3(0.0, 1.6, 5.0))
	await _physics_ticks(2)
	await _frames(2)
	_check(not mirror.active and mirror.rendered == 0, "out of reach it draws nothing")
	var eye := get_viewport().get_camera_3d()
	eye.global_position = Vector3(0.0, 1.6, 2.0)
	eye.look_at(mirror.global_position)
	await _physics_ticks(1)
	var counts: Array[int] = []
	for i in 7:
		await _frames(1)
		counts.append(mirror.rendered)
	var first := counts.find(1)
	_check(first >= 0, "it drew a picture once in view (%s)" % [counts])
	if first >= 0 and first + 6 < counts.size() + 1:
		var later := counts.slice(first)
		_check(later == [1, 1, 1, 2, 2, 2, 3].slice(0, later.size()), "then every 3rd frame (%s)" % [counts])


func case_m06_low() -> void:
	var shader := (load("res://game/devices/mirror.gdshader") as Shader).code
	_check(shader.contains("discard") and shader.contains("1.0 - UV.x") and shader.contains("vec3(0.93, 0.97, 1.0)"),
			"the shader cuts the inscribed oval, mirrors the picture left to right and tints it")
	_check(shader.contains("vec3(0.86, 0.92, 0.95)") and shader.contains("vec3(0.6, 0.68, 0.74)") and shader.contains("0.18"),
			"off, a gradient with a sheen")
	var before: Variant = ProjectSettings.get_setting(GraphicsPreset.SETTING, GraphicsPreset.DEFAULT_NAME)
	_check(not GraphicsPreset.named("low").mirror and GraphicsPreset.named("medium").mirror and GraphicsPreset.named("high").mirror,
			"Low turns the reflection off, Medium and High keep it")
	ProjectSettings.set_setting(GraphicsPreset.SETTING, "low")
	var mirror := _mirror_level(Vector3(0.0, 1.6, 2.0))
	await _physics_ticks(2)
	await _frames(2)
	ProjectSettings.set_setting(GraphicsPreset.SETTING, before)
	var mat := mirror.glass.material_override as ShaderMaterial
	_check(not mirror.reflect and not mirror.active and mirror.rendered == 0, "on Low nothing renders")
	_check(mat.get_shader_parameter(&"live") == false, "and the glass shows the gradient")
	mirror.set_reflect(true)
	_check(mat.get_shader_parameter(&"live") == false, "before its first picture too")
	await _physics_ticks(2)
	await _frames(2)
	_check(mirror.active and mat.get_shader_parameter(&"live") == true, "once it draws, the picture shows")


func case_m08_real_path() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	var piece := _piece("wall_mirror")
	var mirror := piece.get_node("Mirror") as Mirror
	_check(not mirror.active and not player.mirror_body().visible, "far off, no reflection and no mirror body")
	_check(player.camera().cull_mask & Mirror.MIRROR_ONLY == 0, "the player's camera never draws the mirror body")
	_stand(player, piece.to_global(Vector3(0.0, 0.0, 1.05)))
	await _physics_ticks(3)
	player.capture_mouse()
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return piece.to_local(player.global_position).z < 0.8, "the player to walk up to the mirror")
	Input.action_release(&"move_forward")
	await _aim(player, mirror.global_position)
	await _physics_ticks(2)
	await _frames(3)
	_check(mirror.active and mirror.rendered > 0, "it reflects")
	var body := player.mirror_body()
	_check(body.visible and _all_on(body, Mirror.MIRROR_ONLY), "the player's full body shows, on the mirror's layer alone")
	_check(_all_on(player.own_body(), Mirror.FIRST_PERSON) and _all_on(player.held_view(), Mirror.FIRST_PERSON), "the belly and held items on the eye's layer alone")
	var mask := mirror.camera.cull_mask
	_check(mask & Mirror.MIRROR_ONLY != 0 and mask & Mirror.FIRST_PERSON == 0, "the mirror draws the body, not the belly or held items")
	_check(mask & Mirror.MESS_SOCKS == 0 and mask & 1 != 0, "nor the Mess Socks; a Teammate's avatar (layer 1) it does")
	var socks := 0
	var off_layer := 0
	for mess: Mess in [_zoo.get_node("Socks/Mess") as Mess]:
		for n: Node in mess.lying.find_children("*", "MultiMeshInstance3D", true, false):
			socks += 1
			if (n as VisualInstance3D).layers != Mirror.MESS_SOCKS:
				off_layer += 1
	_check(socks > 0 and off_layer == 0, "the Mess draws its Socks on their own layer (%d, %d off it)" % [socks, off_layer])
	_stand(player, piece.to_global(Vector3(0.0, 0.0, 8.0)))
	await _physics_ticks(2)
	await _frames(2)
	_check(not mirror.active and not body.visible, "walked away, it stops and the mirror body hides")


static func _all_on(node: Node, layer: int) -> bool:
	for n: Node in [node] + node.find_children("*", "VisualInstance3D", true, false):
		if n is VisualInstance3D and (n as VisualInstance3D).layers != layer:
			return false
	return true


# --- The dust sheet ------------------------------------------------------------------------------


func case_d01_drape() -> void:
	await _zoo_up()
	var cabinet_root := _zoo.get_node(STATION + "/SheetedCabinet") as Node3D
	var cabinet := cabinet_root.get_node("Cabinet") as Cabinet
	var sheet := cabinet_root.get_node("DustSheet") as DustSheet
	_check(cabinet.locked and sheet.visible, "the locked Cabinet wears its sheet")
	var mat := sheet.material_override as StandardMaterial3D
	_check(mat.albedo_color.to_html(false) == "ece4d4" and is_equal_approx(mat.roughness, 1.0) and mat.cull_mode == BaseMaterial3D.CULL_DISABLED,
			"off-white #ece4d4, matt, both sides drawn (%s)" % mat.albedo_color.to_html(false))
	_check(sheet.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "it casts a shadow")
	_check(sheet.find_children("*", "CollisionObject3D", true, false).is_empty(), "no collision")
	var bounds := DustSheet.shown_bounds(cabinet_root, sheet)
	var cloth := sheet.get_aabb()
	_check(cloth.end.y > bounds.end.y and cloth.end.y < bounds.end.y + DustSheet.LOOSE + 0.01, "over its top, a little roomier (%.3f over %.3f)" % [cloth.end.y, bounds.end.y])
	_check(cloth.position.y < 0.01, "down to the floor")
	_check(cloth.position.x < bounds.position.x and cloth.end.x > bounds.end.x and cloth.end.z > bounds.end.z, "down its sides and front")
	_check(cloth.end.z - bounds.end.z < 0.3 + 0.1, "spilling a little onto the floor in front")
	var tris := (sheet.mesh as ArrayMesh).surface_get_array_len(0) / 3
	_check(tris == DustSheet.CELLS.x * DustSheet.CELLS.y * 2, "a %d x %d cell cloth" % [DustSheet.CELLS.x, DustSheet.CELLS.y])
	var drawer := cabinet_root.get_node("Drawer1/Openable") as Openable
	cabinet.click(1, 0)
	await _frames(1)
	_check(not drawer.open, "under it, the drawers stay shut")
	_check(cabinet.sheeted() and not cabinet.aimable(), "it says it is sheeted, not to be aimed at")


func case_d05_unaimable() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	var cabinet_root := _zoo.get_node(STATION + "/SheetedCabinet") as Node3D
	var cabinet := cabinet_root.get_node("Cabinet") as Cabinet
	var drawer := cabinet_root.get_node("Drawer1") as Node3D
	var asked: Array[Dictionary] = []
	cabinet.parts.applied.connect(func(ev: Dictionary) -> void: asked.append(ev))
	_stand(player, cabinet_root.to_global(Vector3(0.0, 0.0, 1.0)))
	await _physics_ticks(3)
	player.capture_mouse()
	await _aim(player, drawer.to_global(Vector3(0.0, 0.12, 0.25)))
	await _physics_ticks(2)
	var hit := Player.part_of((player.get_node("Head/Aim") as RayCast3D).get_collider() as Node)
	_check(hit != null and Cabinet.of(hit) == cabinet, "the aim ray meets the Cabinet (%s)" % hit)
	_check(cabinet.sheeted() and player.aimed_part() == null, "sheeted, the crosshair rests on nothing")
	_check(player.aimed_outline == null, "no outline")
	_check(Prompts.target(player.aimed_part()).is_empty(), "no prompt")
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _physics_ticks(2)
	_check(asked.is_empty(), "a click and the use key ask nothing (%d answers)" % asked.size())
	cabinet.parts.load_snapshot(cabinet.lock_patch(false, cabinet.rows))
	await _physics_ticks(3)
	var aimed := player.aimed_part()
	_check(not cabinet.sheeted() and aimed != null and Cabinet.of(aimed) == cabinet, "unsheeted, its drawer is aimed (%s)" % aimed)
	_check(player.aimed_outline != null and player.aimed_outline.shown, "with its outline")
	_check(not Prompts.target(aimed).is_empty(), "and its prompt")


func case_d03_real_path() -> void:
	await _zoo_up()
	var player := _zoo.get_node("Player") as Player
	var station := _zoo.get_node(STATION) as Node3D
	var cabinet_root := station.get_node("SheetedCabinet") as Node3D
	var cabinet := cabinet_root.get_node("Cabinet") as Cabinet
	var sheet := cabinet_root.get_node("DustSheet") as DustSheet
	var switch := station.get_node("SheetSwitch") as Node3D
	_stand(player, switch.to_global(Vector3(-0.3, 0.0, 0.9)))
	await _physics_ticks(3)
	await _aim(player, switch.to_global(Vector3(0.0, 1.15, 0.0)))
	_check((switch.get_node("Looks/Label") as Label3D).text == "Cabinet: locked", "the switch says the Cabinet is locked")
	var front_before := sheet.get_aabb().end.z
	_heard.clear()
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return not cabinet.locked, "the Cabinet to unlock")
	var t0 := _clock
	_check((switch.get_node("Looks/Label") as Label3D).text == "Cabinet: unlocked", "the switch says so")
	_check(sheet.pulling(), "the sheet is being pulled off")
	await _until(func() -> bool: return sheet.pull > 0.5, "half way", 60)
	_check(sheet.get_aabb().end.z > front_before + 0.05, "it slides forward over the front")
	var mat := sheet.material_override as StandardMaterial3D
	_check(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "and fades")
	_check(_count(&"cabinet_reveal") == 0, "the reveal waits for the pull")
	await _until(func() -> bool: return not sheet.visible, "the sheet to be gone", 120)
	var gone := _clock - t0
	_check(gone >= 0.4 and gone < 0.5 + 0.3, "gone in 0.5 s (%.2f)" % gone)
	await _until(func() -> bool: return _count(&"cabinet_reveal") == 1, "the reveal to sound", 120)
	var h := _last(&"cabinet_reveal")
	_check((h["at"] as Vector3).distance_to(cabinet_root.global_position + Vector3.UP) < 0.01, "1 m over the Cabinet")
	for i in cabinet.drawer_count():
		_check(not cabinet.drawer(i).locked or i >= cabinet.rows, "its drawers in use are free (%d)" % i)


func case_d06_now() -> void:
	await _zoo_up()
	var cabinet_root := _zoo.get_node(STATION + "/SheetedCabinet") as Node3D
	var cabinet := cabinet_root.get_node("Cabinet") as Cabinet
	var sheet := cabinet_root.get_node("DustSheet") as DustSheet
	var parts := cabinet.parts
	_heard.clear()
	parts.load_snapshot(cabinet.lock_patch(false, cabinet.rows))
	_check(not sheet.visible and not sheet.pulling(), "a snapshot unlocked: no sheet, at once")
	parts.apply({"ok": true, "changes": cabinet.lock_patch(true, cabinet.rows)})
	_check(sheet.visible and not sheet.pulling() and is_zero_approx(sheet.pull), "locked again, it drapes at once")
	await _frames(40)
	_check(_count(&"cabinet_reveal") == 0, "neither made the reveal's sound")


func case_v05_old_tree() -> void:
	for stem: String in ["old_tree", "sheeted_sofa"]:
		var piece := (load(FOLDER.path_join(stem + ".tscn")) as PackedScene).instantiate()
		var scripted := 0
		for n: Node in piece.find_children("*", "Node", true, false):
			if n.get_script() != null and not (n.get_script() as Script).resource_path.ends_with("outline.gd"):
				scripted += 1
		_check(piece.get_script() == null and scripted == 0, "%s has no code of its own" % stem)
		_check(piece.find_children("*", "AnimationPlayer", true, false).is_empty(), "%s has no motion of its own" % stem)
		if stem == "old_tree":
			_check(not piece.find_children("*", "OmniLight3D", true, false).is_empty(), "the Old Tree keeps its glowing bulbs' light")
		piece.free()


# --- Helpers -------------------------------------------------------------------------------------


func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := _zoo.get_node("Player") as Player
	await _until(func() -> bool: return player.is_on_floor(), "the zoo's player to stand")
	await _frames(2)
	_heard.clear()


func _piece(stem: String) -> Node3D:
	return (_zoo.get_node(LINE_UP) as FurnitureLineUp).piece(stem)


## Puts the player at `spot`, facing -Z, at rest.
func _stand(player: Player, spot: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = spot
	player.rotation = Vector3.ZERO
	player.reset_physics_interpolation()


## Turns the body to `target` and pitches the head at it, as the mouse would.
func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)
	(player.get_node("Head/Aim") as RayCast3D).force_raycast_update()
