## The Cutscene frame on one machine (core/88, docs/architecture/run-ends.md "The Cutscene frame"). The real
## path: in the washer station the player presses E on "Play cutscene_fix_1"; the view cuts to the washer's
## wide shot, the input and the HUD go, the Socks, avatars and Laundry bins are not drawn, the subtitle shows
## cutscene_2's first segment on the wide shot and its second on the close one; the Host's Space ends it and
## the player stands at a washer spawn with input, HUD and drawing back. Without a voice line it holds the
## wide shot for its no-voice length, runs its beats on the clock, ends by the Host's timeline and ends every
## knockdown; the frame's refusals.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["WasherStation", "Laundry"]
const STATION := "Stations/WasherStation"
const SILENT := "res://tests/fixtures/cutscene_silent.tres"
const TRIGGER := &"cutscene_fix_1"

var _holder: Node = null
var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: E on Play cutscene_fix_1: the wide shot, input and HUD off, Socks, avatars and bins hidden, cutscene_2's first segment on the wide shot, its second on the close shot; the Host's Space: the player at a washer spawn, input, HUD and drawing back"},
		{"name": "no_voice", "method": "case_no_voice", "world": false,
				"title": "without a voice line it holds the wide shot for its no-voice length (2 s), its beats run on the clock, the ESC menu closes, the Host's timeline ends it and every knockdown is over"},
		{"name": "refusals", "method": "case_refusals", "world": false,
				"title": "the frame refuses a second start while one plays, a Guest's skip, a late timeline's end and a path that is no script; nothing is saved"},
	]


func _before_case() -> void:
	for a: StringName in [&"interact", &"move_forward", CutscenePlayer.SKIP]:
		if InputMap.has_action(a):
			Input.action_release(a)
	_done()


func _done() -> void:
	if _holder != null:
		_holder.free()
		_holder = null
	_zoo = null
	Voices.reset()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var rt := _runtime()
	var cp := rt.cutscene_player
	var cs := rt.cutscenes
	var player := rt.player
	var station := _zoo.get_node(STATION) as WasherStation
	_check(station.pillars.has("cutscene %s" % TRIGGER), "the station built a pillar for %s" % TRIGGER)
	await _press_pillar(station.pillars["cutscene %s" % TRIGGER])
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.PLAYING, "the pillar to start the cutscene", 120)
	_check(cs.playing.ends_with("%s.tres" % TRIGGER), "the Cutscenes Part plays the trigger (%s)" % cs.playing)
	_check(player.get_viewport().get_camera_3d() == cp.camera, "the cutscene's camera has the view")
	var wide := _shot(CutscenePlayer.WIDE)
	_check(cp.camera.global_transform.origin.distance_to(wide.global_position) < 0.001 and cp.shot == CutscenePlayer.WIDE, "the camera is at the washer's wide shot")
	_check(player.in_cutscene() and not player.hud().visible, "the input is off and the HUD hidden")
	_check(not rt.mess.drawn() and not rt.players.visible, "no Sock, Pair or avatar is drawn")
	var bins := _bins()
	_check(not bins.is_empty() and bins.all(func(b: LaundryBin) -> bool: return not b.drawn()), "every Laundry bin is hidden (%d)" % bins.size())
	_check(cp.skip_text() == "[SPACE] Skip", "the Host's screen shows the skip hint (%s)" % cp.skip_text())
	# The walk does nothing.
	var at := player.global_position
	Input.action_press(&"move_forward")
	await _physics_ticks(20)
	Input.action_release(&"move_forward")
	_check(player.global_position.distance_to(at) < 0.01, "the walk key moves nobody")
	# The line: its first segment on the wide shot, its second on the close shot.
	var line := Voices.book().cutscene_lines(TRIGGER)[0]
	var take := line.takes[clampi(cs.takes[0], 0, line.takes.size() - 1)]
	var first := tr(take.segments[0].key)
	await _until(func() -> bool: return Voices.subtitle_text(Voices.CUTSCENE) == first, "the subtitle to show cutscene_2's first segment (%s)" % first, 300)
	_check(cp.shot == CutscenePlayer.WIDE, "the first segment is on the wide shot")
	_check(take.segments.size() > 1, "cutscene_2 has a second segment")
	await _until(func() -> bool: return Voices.channel(Voices.CUTSCENE).segment >= 1, "the second segment", 900, 8.0)
	await _frames(1)
	var close := _shot(CutscenePlayer.CLOSE)
	_check(cp.shot == CutscenePlayer.CLOSE and cp.camera.global_transform.origin.distance_to(close.global_position) < 0.001, "the second segment is on the close shot")
	# The Host's Space.
	Input.action_press(CutscenePlayer.SKIP)
	await _frames(2)
	Input.action_release(CutscenePlayer.SKIP)
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.IDLE, "the skip to end it", 60)
	await _physics_ticks(2)
	_check(not cs.is_playing() and not Voices.cutscene_playing(), "nothing plays, the line stopped")
	_check(_at_a_spawn(player.global_position), "the player stands at a washer spawn (%s)" % player.global_position)
	_check(not player.in_cutscene() and player.hud().visible, "the input is back and the HUD shown")
	_check(player.get_viewport().get_camera_3d() == player.camera(), "the player's own camera has the view")
	_check(rt.mess.drawn() and rt.players.visible and bins.all(func(b: LaundryBin) -> bool: return b.drawn()), "the Socks, avatars and bins are drawn again")
	await _until(func() -> bool: return cp.black() == 0.0, "the view to fade back in", 120)
	at = player.global_position
	Input.action_press(&"move_forward")
	await _physics_ticks(20)
	Input.action_release(&"move_forward")
	_check(player.global_position.distance_to(at) > 0.2, "the walk key walks again")


# --- Without a voice -----------------------------------------------------------------------------

func case_no_voice() -> void:
	await _build()
	var rt := _runtime()
	var cp := rt.cutscene_player
	var cs := rt.cutscenes
	var kd := rt.knockdowns
	var looks := Washer.of_level(cp).looks
	rt.esc_menu.open()
	rt.parts.apply(kd.grant({"down": {7: {"left": 30.0, "at": Vector3.ZERO, "yaw": 0.0, "push": Vector3.FORWARD,
			"high": 0.0, "side": 0.0, "by": 1, "n": 1, "cut": 0}}, "serial": 1}))
	_check(kd.is_down(7), "a player lies knocked down")
	rt.parts.apply(cs.start(SILENT))
	_check(cp.phase == CutscenePlayer.Phase.PLAYING and not cp.voiced, "it plays with no line")
	_check(not rt.esc_menu.is_open(), "the ESC menu closed")
	_near(cp.length, 2.0, 0.001, "its length is its no-voice length")
	var left_at := -1.0
	var bubbled := false
	var cut_away := false
	while cp.phase == CutscenePlayer.Phase.PLAYING and cp.elapsed < 4.0:
		await _frames(1)
		bubbled = bubbled or looks.bubbling()
		cut_away = cut_away or cp.shot != CutscenePlayer.WIDE or cp.cuts != 1
		left_at = cp.elapsed
	_check(bubbled, "its beat at 0.5 s turned the bubbles on")
	_check(not cut_away, "it held the wide shot")
	_check(left_at >= 1.9 and left_at < 2.3, "its timeline ran 2 s (%.2f)" % left_at)
	await _until(func() -> bool: return cp.phase == CutscenePlayer.Phase.IDLE, "the Host's timeline to end it", 30)
	_check(not looks.bubbling(), "its after_voice beat turned them off")
	_check(not kd.is_down(7) and kd.down.is_empty(), "the end ended every knockdown")
	await _physics_ticks(2)
	_check(_at_a_spawn(rt.player.global_position), "the player stands at a washer spawn")


func case_refusals() -> void:
	await _build()
	var rt := _runtime()
	var cs := rt.cutscenes
	_check(not cs.start("res://game/voice/triggers/washer_stare.tres").get("ok", false), "a comment trigger is no cutscene")
	_check(not cs.start("res://nowhere.tres").get("ok", false), "a missing path is refused")
	rt.parts.apply(cs.start(SILENT))
	var serial := cs.serial
	_check(cs.start(SILENT).get("reason", "") == "busy", "a second start while one plays is refused")
	_check(not cs.decide(Command.new(Cutscenes.SKIP, 2, cs.id)).get("ok", false), "a Guest's skip is refused")
	_check(cs.accepts().is_empty(), "a Guest's Session accepts no verb of it")
	_check(not cs.decide(Command.new(Cutscenes.END, Parts.HOST, cs.id, {"serial": serial - 1})).get("ok", false), "a late timeline's end is refused")
	_check(cs.save_state().is_empty(), "nothing is saved")
	rt.parts.ask(Command.new(Cutscenes.SKIP, Parts.HOST, cs.id))
	_check(not cs.is_playing(), "the Host's skip ends it")
	_check(not cs.decide(Command.new(Cutscenes.SKIP, Parts.HOST, cs.id)).get("ok", false), "a skip with nothing playing is refused")


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
	_holder = Node.new()
	_holder.name = "Alone"
	add_child(_holder)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder.add_child(_zoo)
	var at := (_zoo.get_node(STATION) as Node3D).global_position
	_runtime().player.global_position = at + Vector3(0.0, 0.1, 5.0)
	await _until(func() -> bool: return _runtime().player.is_on_floor(), "the player to stand in the station", 600)
	_runtime().player.capture_mouse()


func _runtime() -> LevelRuntime:
	return LevelRuntime.of(_zoo)


func _shot(which: int) -> Node3D:
	return _zoo.get_node(STATION + "/Washer").get_node(CutscenePlayer.SHOTS[which]) as Node3D


func _at_a_spawn(feet: Vector3) -> bool:
	for m: Node in _zoo.get_node(STATION + "/Washer/Spawns").get_children():
		var spot := (m as Node3D).global_position
		if Vector2(feet.x - spot.x, feet.z - spot.z).length() < 0.05:
			return true
	return false


func _bins() -> Array[LaundryBin]:
	var out: Array[LaundryBin] = []
	for node in get_tree().get_nodes_in_group(LaundryBin.GROUP):
		if node is LaundryBin and _zoo.is_ancestor_of(node):
			out.append(node as LaundryBin)
	return out


func _press_pillar(pillar: WasherPillar) -> void:
	var player := _runtime().player
	var body := pillar.get_parent() as Node3D
	var target := body.global_position + Vector3.UP * 0.5
	var feet := body.global_position + Vector3(0.0, 0.0, 1.2)
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var head := player.get_node("Head") as Node3D
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _physics_ticks(2)
