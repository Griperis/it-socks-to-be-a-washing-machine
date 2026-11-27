## Voices, Subtitles and the Voice station (core/85, docs/architecture/voice.md "Playing", "Cutscenes", "Co-op").
## The real path: in the Voice station of the zoo the player aims at a washer line's pillar and presses E; the
## Subtitles row shows the line's first segment with the speaker's disc, the stand-in's AnimationPlayer plays the
## take's acting; the same through a shut Door, on MuffledVoice. The rules (the picker, the priority, the earshot,
## the duck) are cases of their own on the washer's real lines; the co-op case uses real ENet.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const STATION := "res://game/zoo/stations/voice.tscn"
const SPEAKER := preload("res://game/voice/speakers/washer.tres")
const NET_WAIT_S := 20.0

var _zoo: Node3D = null
var _level: Node = null
var _node: Node3D = null
var _started: Array[Dictionary] = []
var _finished: Array[Dictionary] = []
var _machines: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Voice station the player presses E at a washer line's pillar: the Subtitles row shows the line's first segment with the washer's disc, the stand-in plays the take's acting; behind the shut Door the row still shows and the voice is on MuffledVoice"},
		{"name": "built_from_book", "method": "case_built_from_book", "world": false,
				"title": "the station has a pillar for every line of the VoiceBook (each with its label), every comment and cutscene trigger, and stands clear of the other stations"},
		{"name": "picker", "method": "case_picker", "world": false,
				"title": "the picker: a fitting line, never the last, each once before repeats, the fallback for a trigger no line has, seeded takes"},
		{"name": "priority", "method": "case_priority", "world": false,
				"title": "a higher speaker cuts a lower, a lower is dropped, a line that waits waits, the same speaker's new line replaces the old, a cutscene cuts a comment"},
		{"name": "earshot", "method": "case_earshot", "world": false,
				"title": "a subtitle shows within the earshot and level band, through the camera, and hides with display/subtitles off; the segment lingers 0.25 s"},
		{"name": "channels", "method": "case_channels", "world": false,
				"title": "a comment is in 3D at the speaker's voice_db on the Voice bus, a cutscene flat; the tails (0.27 s, 0.9 s); the signals; stop"},
		{"name": "cutscene_duck", "method": "case_cutscene_duck", "world": false,
				"title": "a cutscene plays its lines in order flat on the Voice bus with the music ducked to 0.25 and back; a skip ends it at once"},
		{"name": "coop", "method": "case_coop", "world": false,
				"title": "co-op, real ENet: a Guest's talk is decided on the Host; both machines play the same line and take"},
	]


func _before_case() -> void:
	for a: StringName in [&"interact", &"move_forward"]:
		Input.action_release(a)
	_done_now()
	_started.clear()
	_finished.clear()
	if not Voices.started.is_connected(_on_started):
		Voices.started.connect(_on_started)
		Voices.finished.connect(_on_finished)


func _on_started(line: VoiceLine, take: int) -> void:
	_started.append({"line": line, "take": take})


func _on_finished(line: VoiceLine, skipped: bool) -> void:
	_finished.append({"line": line, "skipped": skipped})


func _done_now() -> void:
	if _zoo != null:
		_zoo.free()
		_zoo = null
	if _level != null and is_instance_valid(_level):
		_level.free()
	_level = null
	if _node != null:
		_node.free()
		_node = null
	for m in _machines:
		(m["session"] as Session).close()
		var path := (m["node"] as Node).get_path()
		remove_child(m["node"])
		(m["node"] as Node).free()
		get_tree().set_multiplayer(null, path)
	_machines.clear()
	Voices.reset()


func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := LevelRuntime.of(_zoo).player
	await _until(func() -> bool: return player.is_on_floor(), "the zoo's player to stand")
	await _frames(2)


func _stand(player: Player, spot: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = spot
	player.rotation = Vector3.ZERO
	player.reset_physics_interpolation()


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)
	(player.get_node("Head/Aim") as RayCast3D).force_raycast_update()


## A washer line by id.
func _line(id: StringName) -> VoiceLine:
	return Voices.book().find_line(&"washer", id)


## A source of its own for a speaker, in a bare node (no camera: everything is heard).
func _source(speaker: VoiceSpeaker, at := Vector3.ZERO) -> VoiceSource:
	if _node == null:
		_node = Node3D.new()
		add_child(_node)
	var s := VoiceSource.new()
	s.speaker = speaker
	_node.add_child(s)
	s.position = at
	return s


func _speaker_like(id: StringName, priority: int) -> VoiceSpeaker:
	var s := SPEAKER.duplicate() as VoiceSpeaker
	s.id = id
	s.priority = priority
	return s


func case_real_path() -> void:
	await _zoo_up()
	var player := LevelRuntime.of(_zoo).player
	var station := _zoo.get_node("Stations/Voice") as VoiceStation
	var line := _line(&"stage_1_voice_A")
	var pillar := station.line_pillars["washer/stage_1_voice_A"]
	var stand_in := station.stand_ins[&"washer"]
	var looks := stand_in.looks
	var at := (pillar.get_parent() as Node3D).global_position
	_stand(player, at + Vector3(0.0, 0.0, 1.2))
	await _physics_ticks(3)
	await _aim(player, at + Vector3(0.0, 0.6, 0.0))
	var aimed := Player.part_of(player.get_node("Head/Aim").get_collider())
	_check(aimed == pillar, "the crosshair is on the line's pillar (%s)" % aimed)
	var row_prompt := Prompts.target(aimed)
	_check(row_prompt.size() == 1 and row_prompt[0].title == "Say stage_1_voice_A", "its prompt reads Say stage_1_voice_A")
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return Voices.talking(&"washer"), "the washer to talk")
	_check(Voices.line_of(&"washer") == line, "it says the pillar's line")
	var first := tr(line.takes[0].segments[0].key)
	await _until(func() -> bool: return Voices.subtitle_text(&"washer") == first, "the Subtitles row to show the first segment (%s)" % first)
	var row := Voices.subtitles().row_of(&"washer")
	_check(row != null and row.has_icon(), "with the washer's drawn icon (assets/15)")
	_check(first == "I don't wanna talk to you!", "the text is the line's, through tr (%s)" % first)
	await _until(func() -> bool: return looks.player.is_playing() and looks.player.current_animation == "voice/acting", "the stand-in's AnimationPlayer to play the acting")
	_check(looks.player.get_animation("voice/acting") == line.takes[Voices.channel(&"washer").take].acting, "it is the take's own acting")
	_check(Voices.channel(&"washer").bus == &"Voice", "in the open the voice is on the Voice bus")
	_check(is_equal_approx(Voices.channel(&"washer").volume_db(), SPEAKER.voice_db), "at the speaker's voice_db")
	# The line ends and the face rests.
	Voices.stop(&"washer")
	await _frames(2)
	_check(not Voices.talking(&"washer") and Voices.subtitle_text(&"washer") == "", "stopped, the row goes")
	# Behind the shut Door: the same, muffled.
	var behind := station.behind_pillars[&"washer"]
	var behind_at := (behind.get_parent() as Node3D).global_position
	_stand(player, behind_at + Vector3(0.0, 0.0, 1.2))
	await _physics_ticks(3)
	await _aim(player, behind_at + Vector3(0.0, 0.6, 0.0))
	_check(Player.part_of(player.get_node("Head/Aim").get_collider()) == behind, "the crosshair is on the pillar before the Door")
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return Voices.talking(&"washer"), "the speaker behind the Door to talk")
	var first_behind := tr(Voices.line_of(&"washer").takes[0].segments[0].key)
	await _until(func() -> bool: return Voices.subtitle_text(&"washer") == first_behind, "the row to show behind the shut Door too")
	_check(Voices.channel(&"washer").bus == &"MuffledVoice", "the voice is on MuffledVoice (%s)" % Voices.channel(&"washer").bus)


func case_built_from_book() -> void:
	var station := (load(STATION) as PackedScene).instantiate() as VoiceStation
	_level = station
	add_child(station)
	var book := Voices.book()
	_check(book.errors.is_empty(), "the book loads clean (%s)" % [book.errors])
	var lines := book.lines_of(&"washer")
	var every := 0
	for id in book.speakers():
		every += book.lines_of(id).size()
	_check(lines.size() == 21 and station.line_pillars.size() == every, "21 washer lines, and every speaker's line has a pillar (%d of %d)" % [station.line_pillars.size(), every])
	_check(book.lines_of(&"old_tree").size() == 145, "the Old Tree's 145 lines are in the book (%d)" % book.lines_of(&"old_tree").size())
	for l in lines:
		var p: VoicePillar = station.line_pillars.get("washer/%s" % l.id)
		_check(p != null and p.target == l.id, "line %s has its pillar" % l.id)
		if p != null:
			var text := (p.get_parent().get_parent().get_node("Label") as Label3D).text
			_check(text.begins_with(String(l.id)) and text.contains("take(s)"), "%s's label says the id and takes" % l.id)
	var comments := 0
	var cutscenes := 0
	for t in station._triggers():
		if t.kind == VoiceTrigger.Kind.COMMENT:
			comments += 1
			_check(station.comment_pillars.has(t.id), "comment trigger %s has a pillar" % t.id)
		else:
			cutscenes += 1
			_check(station.cutscene_pillars.has(t.id), "cutscene trigger %s has a pillar" % t.id)
	_check(comments == 37 and cutscenes == 6, "37 comment (the washer's 4, the Old Tree's 33) and 6 cutscene triggers (%d, %d)" % [comments, cutscenes])
	_check(station.radio != null and station.radio.hum != null, "the radio has its hum")
	var ground := station.get_node("Pad") as MeshInstance3D
	var box := ground.global_transform * ground.get_aabb()
	var here := Rect2(box.position.x + 78.0, box.position.z + 2.0, box.size.x, box.size.z)
	_check(here.position.x > 66.0 and not here.intersects(Rect2(50.0, -12.0, 16.0, 11.0)) and not here.intersects(Rect2(55.0, 2.0, 10.0, 10.0)),
			"placed at (78, 2) it is clear of Stages and Laundry (%s)" % here)


func case_picker() -> void:
	var lines := Voices.book().lines_of(&"washer")
	var picker := VoicePicker.new()
	picker.rng.seed = 7
	# Set 4's idle lines: A, B and C all fit.
	var seen: Array[VoiceLine] = []
	for i in 9:
		var pick := picker.pick(lines, &"washer_idle", 4)
		var line: VoiceLine = pick["line"]
		_check(line.has_trigger(&"washer_idle") and line.sets.has(4), "pick %d fits the trigger and the set (%s)" % [i, line.id])
		if not seen.is_empty():
			_check(line != seen.back(), "pick %d is never the last (%s)" % [i, line.id])
		seen.append(line)
	for round in 3:
		var ids := [seen[round * 3].id, seen[round * 3 + 1].id, seen[round * 3 + 2].id]
		ids.sort()
		_check(ids.size() == 3 and ids[0] != ids[1] and ids[1] != ids[2], "round %d said each fitting line once (%s)" % [round, ids])
	# A trigger no line of the set has: any line of the set.
	picker.forget()
	var any := picker.pick(lines, &"washer_hit", 1)
	_check(not any.is_empty() and (any["line"] as VoiceLine).sets.has(1) and not (any["line"] as VoiceLine).has_trigger(&"washer_hit"),
			"set 1 has no hit line: any line of the set plays (%s)" % [(any["line"] as VoiceLine).id if not any.is_empty() else "none"])
	_check(picker.pick(lines, &"washer_hit", 99).is_empty(), "a set with no line says nothing")
	# The only line there is may repeat (the old game's answer).
	var only: Array[VoiceLine] = [lines[0]]
	var one := VoicePicker.new()
	_check(one.pick(only, &"washer_stare")["line"] == lines[0] and one.pick(only, &"washer_stare")["line"] == lines[0], "a single line repeats")
	# Seeded: the same seed gives the same lines and takes.
	var a := VoicePicker.new()
	var b := VoicePicker.new()
	a.rng.seed = 99
	b.rng.seed = 99
	var same := true
	for i in 6:
		var pa := a.pick(lines, &"washer_progress", 3)
		var pb := b.pick(lines, &"washer_progress", 3)
		same = same and pa["line"] == pb["line"] and pa["take"] == pb["take"]
	_check(same, "a seeded picker repeats itself")
	# Takes: more than one take is picked at random.
	var many := (lines[0] as VoiceLine).duplicate() as VoiceLine
	many.takes = [lines[0].takes[0], lines[0].takes[0], lines[0].takes[0]]
	var takes := {}
	var t := VoicePicker.new()
	for i in 40:
		takes[t.take_of(many)] = true
	_check(takes.size() == 3, "every take of a line comes up (%s)" % [takes.keys()])


func case_priority() -> void:
	var washer := _source(SPEAKER)
	var tree := _source(_speaker_like(&"tree", 10))
	var line := _line(&"stage_4_voice_B")
	var other := _line(&"stage_3_voice_A")
	_check(Voices.say(line, 0, tree), "the lower speaker talks when alone")
	_check(Voices.talking(&"tree"), "it is talking")
	_finished.clear()
	_check(Voices.say(other, 0, washer), "a higher speaker is asked meanwhile and talks")
	_check(not Voices.talking(&"tree") and Voices.talking(&"washer"), "the higher cut the lower")
	_check(_finished.size() == 1 and _finished[0]["line"] == line and _finished[0]["skipped"], "the cut line finished, skipped")
	_check(tree.acting_take == null, "its speaker rests")
	var count := _started.size()
	_check(not Voices.say(line, 0, tree), "the lower is asked while the higher talks and is dropped")
	_check(_started.size() == count and not Voices.talking(&"tree"), "it never started")
	# A line that waits.
	var waiting := line.duplicate() as VoiceLine
	waiting.waits = true
	_check(not Voices.say(waiting, 0, tree) and not Voices.talking(&"tree"), "a waiting line is not played yet")
	Voices.stop(&"washer")
	await _until(func() -> bool: return Voices.talking(&"tree") and Voices.line_of(&"tree") == waiting, "the waiting line to start when the higher ends")
	# The same speaker: replaced.
	Voices.stop(&"tree")
	Voices.say(line, 0, washer)
	_finished.clear()
	Voices.say(other, 0, washer)
	_check(Voices.line_of(&"washer") == other and _finished.size() == 1 and _finished[0]["skipped"], "the same speaker's new line replaces the old")
	# A cutscene cuts a comment, and a comment is dropped during it.
	_finished.clear()
	var trigger := load("res://game/voice/triggers/cutscene_first_wash.tres") as VoiceTrigger
	_check(Voices.play_cutscene(trigger, [0], {&"washer": washer}), "the cutscene starts")
	_check(_finished.size() == 1 and _finished[0]["line"] == other and _finished[0]["skipped"], "it cut the washer's comment")
	_check(not Voices.say(line, 0, washer), "a comment asked during the cutscene is dropped")
	# A waiting line that waits too long is dropped.
	Voices.tuning = Voices.tuning.duplicate() as VoiceTuning
	Voices.tuning.wait_hold = 0.2
	var late := line.duplicate() as VoiceLine
	late.waits = true
	Voices.say(late, 0, washer)
	await _until(func() -> bool: return Voices._waiting.is_empty(), "the hold to run out")
	Voices.stop_cutscene()
	await _frames(3)
	_check(not Voices.talking(&"washer"), "the dropped line never plays")
	Voices.tuning = Voices.TUNING


func case_earshot() -> void:
	_check(Voices.within_earshot(Vector3(5, 1.6, 0), Vector3.ZERO, 12.0, 2.0), "5 m away on the same floor is within earshot")
	_check(not Voices.within_earshot(Vector3(13, 1.6, 0), Vector3.ZERO, 12.0, 2.0), "13 m away is not")
	_check(not Voices.within_earshot(Vector3(2, 3.1, 0), Vector3.ZERO, 12.0, 2.0), "3.1 m above is another floor")
	_check(Voices.within_earshot(Vector3(11.8, 1.9, 0), Vector3.ZERO, 12.0, 2.0), "just inside both limits is within")
	var camera := Camera3D.new()
	_node = Node3D.new()
	add_child(_node)
	_node.add_child(camera)
	camera.current = true
	camera.global_position = Vector3(5, 1.6, 0)
	var source := _source(SPEAKER)
	var line := _line(&"stage_1_voice_A")
	Voices.say(line, 0, source)
	var key := line.takes[0].segments[0].key
	await _until(func() -> bool: return Voices.subtitle_text(&"washer") == tr(key), "the row to show within earshot")
	camera.global_position = Vector3(30, 1.6, 0)
	await _until(func() -> bool: return Voices.subtitle_text(&"washer") == "", "the row to hide out of earshot")
	camera.global_position = Vector3(2, 5.0, 0)
	await _frames(2)
	_check(Voices.subtitle_text(&"washer") == "", "and on another floor")
	camera.global_position = Vector3(2, 1.6, 0)
	await _until(func() -> bool: return Voices.subtitle_text(&"washer") != "", "back in earshot it shows again")
	Settings.set_value(Settings.SUBTITLES, false)
	await _until(func() -> bool: return Voices.subtitle_text(&"washer") == "", "display/subtitles off hides every row")
	Settings.set_value(Settings.SUBTITLES, true)
	await _until(func() -> bool: return Voices.subtitle_text(&"washer") != "", "and on shows it again")
	# The segment lingers 0.25 s past its end and the next replaces it at its start.
	var channel := Voices.channel(&"washer")
	var seg := line.takes[0].segments[0]
	channel.elapsed = seg.end + 0.2
	_check(channel.shown_segment(0.25) == 0, "0.2 s past its end the segment still shows")
	channel.elapsed = seg.end + 0.3
	_check(channel.shown_segment(0.25) == -1 or channel.shown_segment(0.25) > 0, "0.3 s past its end it has gone")
	channel.elapsed = seg.start - 0.01
	_check(channel.shown_segment(0.25) == -1, "before it begins it is not shown")
	var many := _line(&"stage_4_voice_B")
	var take := many.takes[0]
	_check(take.segments.size() >= 2, "a long line has several segments (%d)" % take.segments.size())
	channel.begin(many, 0, SPEAKER, source, false, 20, 0.27)
	channel.elapsed = take.segments[1].start + 0.01
	_check(channel.begun_segment() == 1 and channel.shown_segment(0.25) == 1, "the segment begun and not ended shows, the latest one")


func case_channels() -> void:
	var source := _source(SPEAKER, Vector3(1, 0, 2))
	var line := _line(&"stage_1_voice_A")
	Voices.say(line, 0, source)
	var c := Voices.channel(&"washer")
	_check(c.is_positional() and c.sounding(), "a comment sounds in 3D")
	_check(c.bus == &"Voice" and is_equal_approx(c.volume_db(), 0.0), "on the Voice bus at 0 dB (Q2638)")
	_check(not _started.is_empty() and _started.back()["line"] == line, "started fired with the line")
	_check(AudioServer.get_bus_index("MuffledVoice") >= 0 and AudioServer.get_bus_send(AudioServer.get_bus_index("MuffledVoice")) == &"Voice", "MuffledVoice sends into Voice")
	var muffled := AudioServer.get_bus_index("MuffledVoice")
	_near(AudioServer.get_bus_volume_db(muffled), -9.0, 0.001, "MuffledVoice is 9 dB down")
	var segs: Array[int] = []
	var on := func(_l: VoiceLine, i: int) -> void: segs.append(i)
	Voices.segment_changed.connect(on)
	var take := line.takes[0]
	c.elapsed = take.duration + SPEAKER.tail - 0.05
	await _frames(1)
	_check(Voices.talking(&"washer"), "just before the tail has gone it is still talking")
	await _until(func() -> bool: return not Voices.talking(&"washer"), "the line to finish after its tail")
	_check(_finished.size() == 1 and not _finished[0]["skipped"], "finished fired, not skipped")
	_check(is_equal_approx(SPEAKER.tail, 0.27), "a comment's tail is 0.27 s")
	Voices.segment_changed.disconnect(on)
	# A cutscene line: flat, tail 0.9.
	var trigger := load("res://game/voice/triggers/cutscene_first_wash.tres") as VoiceTrigger
	Voices.play_cutscene(trigger, [0], {&"washer": source})
	var cc := Voices.channel(Voices.CUTSCENE)
	_check(not cc.is_positional() and cc.bus == &"Voice" and cc.sounding(), "a cutscene line is flat on the Voice bus")
	_check(is_equal_approx(cc.tail, 0.9), "its tail is 0.9 s")
	_check(Voices.subtitles().row_of(Voices.CUTSCENE) != null or cc.begun_segment() < 0, "its subtitle is for everyone")
	Voices.stop(&"washer")
	Voices.stop_cutscene()
	_check(not Voices.cutscene_playing(), "stopped")


func case_cutscene_duck() -> void:
	var source := _source(SPEAKER)
	var trigger := load("res://game/voice/triggers/cutscene_fix_1.tres") as VoiceTrigger
	var music := AudioServer.get_bus_index("Music")
	_check(Voices.duck() == 1.0, "the music is whole")
	_check(Voices.play_cutscene(trigger, [0], {&"washer": source}), "cutscene_2 plays")
	await _until(func() -> bool: return is_equal_approx(Voices.duck(), 0.25), "the music to duck to 0.25")
	var amp: AudioEffectAmplify = null
	for i in AudioServer.get_bus_effect_count(music):
		if AudioServer.get_bus_effect(music, i) is AudioEffectAmplify:
			amp = AudioServer.get_bus_effect(music, i) as AudioEffectAmplify
	_check(amp != null and absf(amp.volume_db - linear_to_db(0.25)) < 0.01, "the Music bus rides an amplify at 0.25 (%s)" % [amp.volume_db if amp != null else "none"])
	_check(Voices.subtitles().get_parent().layer == Voices.CUTSCENE_LAYER, "the subtitles are on top in a cutscene")
	# A comment does not duck it.
	Voices.stop_cutscene()
	await _until(func() -> bool: return is_equal_approx(Voices.duck(), 1.0), "the music to come back")
	Voices.say(_line(&"stage_1_voice_A"), 0, source)
	await _frames(20)
	_check(is_equal_approx(Voices.duck(), 1.0), "a comment does not duck the music")
	Voices.stop(&"washer")
	# Several lines play in order: the washer's cutscene_3 is one line in batch A.
	var all := Voices.book().cutscene_lines(&"cutscene_fix_2")
	_check(all.size() == 1, "cutscene_3 is the washer's line alone (%d)" % all.size())
	# A skip ends it at once and nothing is left to come.
	Voices.play_cutscene(trigger, [0], {&"washer": source})
	_finished.clear()
	Voices.stop_cutscene()
	_check(not Voices.cutscene_playing() and _finished.size() == 1 and _finished[0]["skipped"], "a skip ends the cutscene at once")
	_check(source.acting_take == null, "the face rests")


func case_coop() -> void:
	var host := _machine("Host")
	_check((host["session"] as Session).host() == OK, "the Host listens")
	var guest := await _guest("Guest")
	var hp := host["parts"] as Parts
	var gp := guest["parts"] as Parts
	var g_id := (guest["session"] as Session).me()
	var h_stand := hp.of(&"Voice/Built/Speaker_washer/Speaker") as VoiceStandIn
	var g_stand := gp.of(&"Voice/Built/Speaker_washer/Speaker") as VoiceStandIn
	_check(h_stand != null and g_stand != null, "both machines have the speaker's Part")
	_started.clear()
	gp.ask(Command.new(&"talk", g_id, g_stand.id, {"trigger": "washer_progress"}))
	await _until(func() -> bool: return g_stand.serial == 1 and h_stand.serial == 1, "the Host's answer to reach both", 900, NET_WAIT_S)
	_check(h_stand.last_at > -INF and g_stand.last_at == -INF, "the Host decided: its cooldown ran, the Guest's did not")
	_check(h_stand.line == g_stand.line and h_stand.take == g_stand.take and h_stand.line != &"", "both hold the same line and take (%s, %d)" % [h_stand.line, h_stand.take])
	await _until(func() -> bool: return _started.size() == 2, "both machines to play it", 900, NET_WAIT_S)
	_check(_started[0]["line"] == _started[1]["line"] and _started[0]["take"] == _started[1]["take"], "both played the same line and take")
	_check((_started[0]["line"] as VoiceLine).has_trigger(&"washer_progress"), "a line of the trigger")
	# The cooldown holds a second ask: a silent no.
	var count := _started.size()
	gp.ask(Command.new(&"talk", g_id, g_stand.id, {"trigger": "washer_progress"}))
	await _frames(30)
	_check(h_stand.serial == 1 and _started.size() == count, "a second talk inside the cooldown is a silent no")
	# A Guest's arg of the wrong shape never reaches decide().
	var bad := hp.answer(Command.new(&"say_line", g_id, h_stand.id, {"line": "no_such_line"}))
	_check(bad.get("ok", true) == false, "an unknown line is refused")
	# A late Guest plays nothing of what was said.
	_started.clear()
	var late := await _guest("Late")
	await _frames(5)
	_check(_started.is_empty() and (late["parts"] as Parts).of(h_stand.id).serial == 1, "a late Guest gets the state and plays nothing")
	for m in _machines:
		(m["session"] as Session).close()
	await _frames(2)


## A machine: a Node with its own MultiplayerAPI, the Voice station as its level, its Parts and its Session.
func _machine(label: String) -> Dictionary:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var level := Node3D.new()
	level.name = "Level"
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	level.add_child(station)
	node.add_child(level)
	var parts := Parts.new()
	parts.name = "Parts"
	parts.level = level
	node.add_child(parts)
	var session := Session.new()
	session.name = "Session"
	session.parts = parts
	session.port = 0
	node.add_child(session)
	var out := {"node": node, "level": level, "parts": parts, "session": session}
	_machines.append(out)
	return out


func _guest(label: String) -> Dictionary:
	var m := _machine(label)
	var s: Session = m["session"]
	var welcomed: Array[bool] = []
	s.welcomed.connect(func() -> void: welcomed.append(true))
	s.port = (_machines[0]["session"] as Session).port
	_check(s.join("127.0.0.1:%d" % s.port) == OK, "%s starts joining" % label)
	await _until(func() -> bool: return not welcomed.is_empty(), "%s to be welcomed" % label, 900, NET_WAIT_S)
	return m
