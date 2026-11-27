## The Old Tree's voice (core/132, docs/architecture/economy.md "The Old Tree talks"): the real path in the
## Economy station (the player walks up: a "first" line's subtitle; away and back after the away time: a
## "greet"), a purchase near it ("bought"), earshot and level band, the tree keeping quiet (cooldown, a cutscene,
## the washer), its Looks never moving, the calls after the First wash in the house until a player comes near,
## the save, and co-op: the Host picks, both machines play the same line.
extends TestSuite

const ECONOMY := "res://game/zoo/stations/economy.tscn"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const HOUSE := "res://game/house/house.tscn"
const ACTIONS: Array[StringName] = [&"interact", &"move_forward", &"move_back"]
## Where the player starts in the station (out of earshot, facing the tree down -z), and the tree's aim point.
const FAR := Vector3(4.69, 0.0, 4.0)
const BY_TREE := Vector3(4.7, 0.0, -1.2)
const TREE_AIM := Vector3(4.69, 1.0, -2.55)
const NET_WAIT_S := 20.0
const TAGS := ["old_tree_voice_test_a", "old_tree_voice_test_b"]

var _holder: Node = null
var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _parts: Parts = null
var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Economy station the player walks up to the Old Tree: a \"first\" line's subtitle shows and the player has met it; walking away and back after the away time gives a \"greet\" line; the tree's Looks never move"},
		{"name": "bought_and_earshot", "method": "case_bought_and_earshot", "world": false,
				"title": "buying an Upgrade at the tree gives a \"bought\" line; its subtitle shows only within the earshot (4.5 m) and level band (1.8 m) and hides when the player walks off"},
		{"name": "quiet", "method": "case_quiet", "world": false,
				"title": "the Host keeps the tree quiet within the cooldown, while a cutscene plays and while the washer talks (and the washer cuts it off); an Upgrade newly affordable is said in place of the greeting"},
		{"name": "calls", "method": "case_calls", "world": false,
				"title": "Q1864, Q1865: the Doors from the laundry to the garage start open at a New Game; after the First wash in the house the tree calls (heard from the laundry, within 16 m) until a player comes near, then says its \"first\" line"},
		{"name": "saved", "method": "case_saved", "world": false,
				"title": "a save keeps met, tips, calling, beat and said, not the last line; a load plays nothing; the data: the speaker with no acting, 142 lines, OldTreeTuning's old numbers"},
		{"name": "coop", "method": "case_coop", "world": false,
				"title": "Q2545: a Guest walking up to the tree asks, the Host picks the line; both machines play the same line and take, and the Host keeps the Guest as met"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_level()
	_drop_branches()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build(FAR)
	var tree := _tree()
	var looks := _station.get_node("OldTree/Looks") as Node3D
	var looks_before := _pose(looks)
	_check(not tree.near, "out of earshot at the start")
	await _aim(_station.to_global(TREE_AIM))
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return tree.near, "walking up to bring the player near the tree", 900)
	Input.action_release(&"move_forward")
	var first := await _said(tree, OldTree.FIRST)
	_check(tree.met.has(str(_bank_key(1))), "the player has met the tree (%s)" % [tree.met])
	await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") == _first_text(first), "the \"first\" subtitle to show (%s)" % _first_text(first))
	_check(_pose(looks) == looks_before, "nothing on the tree moves while it talks")
	# Away and back after the away time (shortened here), the cooldown passed.
	_short_tuning(tree)
	Input.action_press(&"move_back")
	await _until(func() -> bool: return not tree.near, "walking off to leave the tree", 900)
	Input.action_release(&"move_back")
	await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") == "", "the subtitle to hide out of earshot")
	await _physics_ticks(int(tree.tuning.away_seconds * 60.0) + 30)
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the first line to end", 900)
	_pass_cooldown(tree)
	Input.action_press(&"move_forward")
	await _until(func() -> bool: return tree.near, "walking back to the tree", 900)
	Input.action_release(&"move_forward")
	var greet := await _said(tree, OldTree.GREET)
	await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") == _first_text(greet), "the \"greet\" subtitle to show")
	_check(_pose(looks) == looks_before, "the Looks are as they were")


func case_bought_and_earshot() -> void:
	await _build(BY_TREE)
	var tree := _tree()
	await _until(func() -> bool: return tree.serial == 1, "the first visit's line")
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the first line to end", 900)
	_parts.apply(tree.grant({"tips": {str(_bank_key(1)): ["tree_tip_throw"]}}))  # core/133's tip is not this case's
	_pass_cooldown(tree)
	var bank := _station.get_node("Socks/Bank") as Bank
	_parts.apply(bank.grant({"coins": {bank.key_of(1): 30}, "recent": {}}))
	await _aim(_station.to_global(TREE_AIM))
	await _until(func() -> bool: return _player.aimed_part() is OldTree, "the crosshair on the Old Tree")
	await _press(&"interact")
	var menu := _station.get_node("OldTree/UpgradeMenu") as UpgradeMenu
	await _until(menu.is_open, "E to open the Upgrade menu")
	await _frames(2)
	await _click(menu.button(&"sock_smarts").key)
	var bought := await _said(tree, OldTree.BOUGHT)
	await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") == _first_text(bought), "the \"bought\" subtitle")
	menu.close()
	await _frames(2)
	# Out of earshot (walked off, the line still sounding) the subtitle hides.
	Input.action_press(&"move_back")
	await _until(func() -> bool: return not tree.near, "walking out of earshot", 900)
	Input.action_release(&"move_back")
	if Voices.talking(&"old_tree"):
		await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") == "", "the subtitle to hide out of earshot")
	var at := tree.voice.global_position
	_check(tree.is_near(at + Vector3(4.4, 0.0, 0.0)) and not tree.is_near(at + Vector3(4.6, 0.0, 0.0)), "the earshot is 4.5 m")
	_check(tree.is_near(at + Vector3(0.0, 1.7, 0.0)) and not tree.is_near(at + Vector3(0.0, 1.9, 0.0)), "the level band is 1.8 m")
	var channel := Voices.channel(&"old_tree")
	_check(channel != null and is_equal_approx(channel.volume_db(), 12.5), "the line plays at the old +12.5 dB, applied at playback (%s)" % (channel.volume_db() if channel != null else 0.0))


func case_quiet() -> void:
	await _build(BY_TREE)
	var tree := _tree()
	await _until(func() -> bool: return tree.serial == 1, "the first visit's line")
	var answer := _parts.answer(Command.new(OldTree.TALK, 1, tree.id, {"trigger": String(OldTree.IDLE)}))
	_check(not answer["ok"] and answer["reason"] == "quiet", "within the cooldown the Host says nothing")
	Voices.stop(&"old_tree")
	tree.last_at = -INF
	# The washer talking: the tree waits, and the washer cuts the tree off.
	var washer_line := Voices.book().find_line(&"washer", &"stage_1_voice_A")
	var washer_source := _washer_source()
	Voices.say(washer_line, 0, washer_source)
	answer = _parts.answer(Command.new(OldTree.TALK, 1, tree.id, {"trigger": String(OldTree.IDLE)}))
	_check(not answer["ok"], "while the washer talks the tree keeps quiet")
	Voices.stop(&"washer")
	_parts.apply(_parts.answer(Command.new(OldTree.TALK, 1, tree.id, {"trigger": String(OldTree.IDLE)})))
	await _until(func() -> bool: return Voices.talking(&"old_tree"), "the tree to muse once the washer is quiet")
	Voices.say(washer_line, 0, washer_source)
	_check(not Voices.talking(&"old_tree") and Voices.talking(&"washer"), "the washer cuts the tree off (V4)")
	Voices.stop(&"washer")
	tree.last_at = -INF
	# A cutscene playing.
	Voices.play_cutscene(Washer.trigger_of(&"cutscene_first_wash"))
	answer = _parts.answer(Command.new(OldTree.TALK, 1, tree.id, {"trigger": String(OldTree.IDLE)}))
	_check(not answer["ok"], "while a cutscene plays the tree keeps quiet")
	Voices.stop_cutscene()
	# An Upgrade newly affordable is said in place of the greeting, on the next visit.
	_short_tuning(tree)
	_player.global_position = _station.to_global(FAR)
	_player.reset_physics_interpolation()
	await _until(func() -> bool: return not tree.near, "the player away")
	_pass_cooldown(tree)
	var bank := _station.get_node("Socks/Bank") as Bank
	_parts.apply(bank.grant({"coins": {bank.key_of(1): 30}, "recent": {}}))
	await _physics_ticks(int(tree.tuning.away_seconds * 60.0) + 30)
	_check(not Voices.talking(&"old_tree"), "away from the tree, the affordable line waits")
	_player.global_position = _station.to_global(BY_TREE)
	_player.reset_physics_interpolation()
	await _said(tree, OldTree.AFFORDABLE)


# --- The calls -----------------------------------------------------------------------------------

func case_calls() -> void:
	await _house_up()
	var rt := LevelRuntime.of(_level)
	for door: String in ["LaundryLobby", "LobbyGarage"]:
		_check((_level.get_node("Doors/%s/Openable" % door) as Openable).open, "%s starts open at a New Game" % door)
	var tree := _level.get_node("Furniture/OldTree/OldTree") as OldTree
	var t := tree.tuning.duplicate() as OldTreeTuning
	t.call_first_delay = 0.5
	tree.tuning = t
	_check(not tree.calling, "the tree waits silent until the First wash is over")
	var day := _level.get_node("LaundryDay/Day") as LaundryDay
	day.cutscene = false
	rt.parts.apply({"ok": true, "changes": {day.id: {"first_wash": LaundryDay.FirstWash.PLAYING}}})
	await _until(func() -> bool: return day.first_wash == LaundryDay.FirstWash.DONE, "the First wash to end")
	await _until(func() -> bool: return tree.calling, "the tree to start calling")
	var heard := tree.voice.global_position.distance_to(rt.player.global_position)
	_check(not tree.near, "the player is not near the tree (%.1f m)" % heard)
	await _until(func() -> bool: return Voices.talking(&"old_tree"), "a call", 900)
	var call := Voices.line_of(&"old_tree")
	_check(call.has_trigger(OldTree.CALL), "it is a call (%s)" % call.id)
	_check(Voices.channel(&"old_tree").source == tree.call_voice and tree.call_voice.speaker.max_distance == 16.0
			and is_equal_approx(Voices.channel(&"old_tree").volume_db(), 12.5), "a call sounds from the tree at +12.5 dB and carries 16 m")
	var cam := rt.player.get_viewport().get_camera_3d().global_position
	if Voices.within_earshot(cam, tree.voice.global_position, 16.0, 16.0):
		await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") != "", "the call's subtitle within 16 m")
	# A player comes near: the calls end, the first line plays.
	rt.player.global_position = (_level.get_node("Furniture/OldTree") as Node3D).to_global(Vector3(-0.3, 0.0, 1.3))
	rt.player.reset_physics_interpolation()
	await _until(func() -> bool: return not tree.calling, "the calls to end once a player is near")
	await _said(tree, OldTree.FIRST)
	var count := tree.serial
	await _physics_ticks(int(t.call_gap.y * 60.0) + 60)
	_check(tree.serial == count, "no call after a player came near")


# --- Saves and data ------------------------------------------------------------------------------

func case_saved() -> void:
	await _build(BY_TREE)
	var tree := _tree()
	await _until(func() -> bool: return tree.serial == 1, "the first visit's line")
	var saved := _roundtrip(_parts.save_snapshot())
	var mine: Dictionary = saved[String(tree.id)]
	_check(mine.keys() == ["met", "tips", "calling", "beat", "said"], "a save keeps met, tips, calling, beat and said (%s)" % [mine.keys()])
	Voices.reset()
	_parts.load_save(saved, _parts.save_versions(), str(_bank_key(1)))
	await _frames(3)
	_check(not Voices.talking(&"old_tree"), "a load plays nothing")
	_check(tree.met.has(str(_bank_key(1))), "the player is still met after the load")
	var speaker := load("res://game/voice/speakers/old_tree.tres") as VoiceSpeaker
	_check(speaker.acting == null and speaker.priority == 10 and speaker.earshot == 4.5 and speaker.level_band == 1.8
			and speaker.unit_size == 2.5 and speaker.max_distance == 9.0 and speaker.cooldown == 120.0 and speaker.voice_db == 0.0,
			"the speaker: no acting, the old numbers")
	var lines := Voices.book().lines_of(&"old_tree")
	_check(lines.size() == 142 and Voices.book().errors.is_empty(), "142 lines load clean (%d, %s)" % [lines.size(), Voices.book().errors])
	for trigger: StringName in [OldTree.CALL, OldTree.FIRST, OldTree.GREET, OldTree.IDLE, OldTree.AFFORDABLE, OldTree.BOUGHT]:
		var want: int = {OldTree.CALL: 5, OldTree.FIRST: 3, OldTree.GREET: 5, OldTree.IDLE: 7, OldTree.AFFORDABLE: 5, OldTree.BOUGHT: 6}[trigger]
		_check(Voices.book().lines_for(&"old_tree", trigger).size() == want, "%s has %d lines" % [trigger, want])
	for l in lines:
		_check(l.takes.size() == 1 and l.takes[0].acting == null and l.takes[0].stream != null, "%s: one take, its recording, no acting" % l.id)
		_check(not String(l.id).contains("grotto") and not String(l.id).contains("tip_dirty") and not String(l.id).contains("tip_pairing"),
				"%s is of a ported feature" % l.id)
	var t := load("res://game/furniture/old_tree_tuning.tres") as OldTreeTuning
	_check(t.away_seconds == 45.0 and t.idle_seconds == 40.0 and t.check_seconds == 0.25 and t.call_first_delay == 20.0
			and t.call_gap == Vector2(25.0, 55.0) and t.call_reach == 16.0 and t.beat_gap == 20.0 and t.voice_db == 12.5
			and t.call_db == 12.5, "OldTreeTuning carries the old numbers, the +12.5 dB playback level among them")


# --- Co-op ---------------------------------------------------------------------------------------

func case_coop() -> void:
	wait_floor_s = NET_WAIT_S
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hr := LevelRuntime.of(host)
	var gr := LevelRuntime.of(guest)
	var ht := host.get_node("Stations/Economy/OldTree/OldTree") as OldTree
	var gt := guest.get_node("Stations/Economy/OldTree/OldTree") as OldTree
	_check(hr.net.start(["--host", "--profile=%s" % TAGS[0]]) == OK, "the zoo hosts")
	await _until(func() -> bool: return hr.roster.peers().size() == 1, "the Host to be in its Roster")
	_check(gr.net.start(["--join=127.0.0.1:%d" % hr.session.port, "--profile=%s" % TAGS[1]]) == OK, "the Guest joins")
	await _until(func() -> bool: return hr.roster.peers().size() == 2, "the Guest to be in", 900, 0.1)
	var gpeer := hr.roster.peers()[1]
	var serial := ht.serial
	# The Guest walks up (placed by the tree in its own zoo); the Host's player stays away.
	var at := (guest.get_node("Stations/Economy/OldTree") as Node3D).to_global(Vector3(-0.3, 0.0, 1.3))
	gr.player.global_position = at
	gr.player.reset_physics_interpolation()
	await _until(func() -> bool: return ht.serial > serial, "the Host to answer the Guest's ask", 900, 0.1)
	_check(ht.met.has(hr.roster.id_of(gpeer)) and not ht.met.has(hr.roster.id_of(Parts.HOST)), "the Host keeps the Guest as met (%s)" % [ht.met])
	_check(Voices.book().find_line(&"old_tree", ht.line).has_trigger(OldTree.FIRST), "it is a \"first\" line (%s)" % ht.line)
	await _until(func() -> bool: return gt.serial == ht.serial, "the Guest's machine to get the answer", 900, 0.1)
	_check(gt.line == ht.line and gt.take == ht.take, "both machines play the same line and take (%s/%d)" % [gt.line, gt.take])
	await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") == _first_text(Voices.book().find_line(&"old_tree", ht.line)),
			"the line's subtitle", 900, 0.1)


# --- Helpers -------------------------------------------------------------------------------------

## The station on a floor with the game's player at `at` (station space) and a Parts (a Host of one).
func _build(at: Vector3) -> void:
	_free_level()
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(ECONOMY) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = at
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_tree().picker.rng.seed = 132
	await _until(func() -> bool: return _player.is_on_floor() and _parts.is_bound, "the player to stand and the parts to bind")


func _house_up() -> void:
	_holder = Node.new()
	add_child(_holder)
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	_holder.add_child(_level)
	var runtime := LevelRuntime.of(_level)
	await _until(runtime.loading.is_lifted, "the house's Socks to be laid", 900, 20.0)
	await _until(func() -> bool: return runtime.player.is_on_floor() and runtime.parts.is_bound, "the player to stand in the house", 900)


func _free_level() -> void:
	if _level != null:
		var menu := _level.find_child("UpgradeMenu", true, false) as UpgradeMenu
		if menu != null:
			menu.close()
		var runtime := LevelRuntime.of(_level) if _level.is_inside_tree() else null
		if runtime != null and runtime.session != null:
			runtime.session.close()
		_level.get_parent().remove_child(_level)
		_level.free()
		_level = null
	if _holder != null:
		_holder.free()
		_holder = null


func _tree() -> OldTree:
	return _station.get_node("OldTree/OldTree") as OldTree


## Waits for the tree's next line and checks it is one of `trigger`'s (from now on, or already said).
func _said(tree: OldTree, trigger: StringName) -> VoiceLine:
	await _until(func() -> bool:
		var l := Voices.book().find_line(&"old_tree", tree.line)
		return l != null and l.has_trigger(trigger) and Voices.line_of(&"old_tree") == l, "a %s line" % trigger)
	var said := Voices.book().find_line(&"old_tree", tree.line)
	_check(said != null and said.has_trigger(trigger), "the tree says a %s line (%s)" % [trigger, tree.line])
	return said


func _first_text(l: VoiceLine) -> String:
	return tr(l.takes[0].segments[0].key) if l != null and not l.takes.is_empty() else "?"


## The away time and the idle time shortened for a case (a copy: the shared file stays as it is).
func _short_tuning(tree: OldTree) -> void:
	var t := tree.tuning.duplicate() as OldTreeTuning
	t.away_seconds = 1.0
	tree.tuning = t


## The cooldown has passed, on the Host and on this machine.
func _pass_cooldown(tree: OldTree) -> void:
	tree.last_at = -INF
	tree.heard_at = -INF


func _bank_key(by: int) -> Variant:
	var bank := _station.get_node("Socks/Bank") as Bank
	return bank.key_of(by)


## A VoiceSource standing for the washer (the station has none), placed by the tree.
func _washer_source() -> VoiceSource:
	var source := VoiceSource.new()
	source.speaker = load("res://game/voice/speakers/washer.tres") as VoiceSpeaker
	_level.add_child(source)
	source.global_position = _station.to_global(BY_TREE)
	return source


## Every transform under `node` (and its own), to see that nothing moved.
func _pose(node: Node) -> Array:
	var out: Array = []
	if node is Node3D:
		out.append((node as Node3D).transform)
	for child in node.get_children():
		out.append_array(_pose(child))
	return out


func _aim(target: Vector3) -> void:
	var head := _player.get_node("Head") as Node3D
	var to := target - _player.global_position
	_player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _click(control: Control) -> void:
	await _frames(2)
	var at := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = pressed
		control.get_viewport().push_input(ev, true)
	await _frames(2)


func _branch(label: String) -> Node3D:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var zoo := (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in zoo.get_node("Stations").get_children():
		if String(station.name) != "Economy":
			station.get_parent().remove_child(station)
			station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var zoo := node.get_node_or_null("View/Zoo")
		var runtime := LevelRuntime.of(zoo) if zoo != null else null
		if runtime != null and runtime.session != null:
			runtime.session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()
	for tag: String in TAGS:
		var path := PlayerProfile.file_of(tag)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
