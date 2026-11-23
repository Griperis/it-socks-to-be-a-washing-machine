## The piano (assets/07 V03, Q2508; the old house/28 and house/33): 88 playable keys, each its sampled
## note on the catalogue's instrument, dipping when played, for every player. One case per P line of
## docs/llm/assets/issues/07-furniture-devices.md; the real path walks the zoo's player to the piano at
## the Furniture station, opens its lid and plays middle C with the left button.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const PIANO := "res://game/furniture/piano.tscn"
const LINE_UP := "Stations/Furniture/LineUp"
const ACTIONS: Array[StringName] = [&"move_forward", &"interact", &"pick"]
## Network waits give real time, which a busy machine stretches.
const NET_WAIT_S := 20.0

var _zoo: Node3D = null
var _level: Node = null
var _heard: Array[Dictionary] = []
## Every machine of a co-op case: {"node", "level", "parts", "session"}.
var _machines: Array[Dictionary] = []
## Game seconds (the runner's fixed frames), what the tweens count in.
var _clock := 0.0


func _process(delta: float) -> void:
	_clock += delta


func cases() -> Array[Dictionary]:
	return [
		{"name": "p01_keys", "method": "case_p01_keys", "world": false,
				"title": "P01: the piano has 88 keys, A0 to C8, each its own thing on its old hinge with its old box and the Looks' key mesh"},
		{"name": "p02_real_path", "method": "case_p02_real_path", "world": false,
				"title": "P01, P02, P09, real path: shut, the lid covers the keys; the player opens it (its sound), aims at middle C (outlined, 'Play C4' with the left button): E does nothing, a left click plays and dips it"},
		{"name": "p03_dip", "method": "case_p03_dip", "world": false,
				"title": "P03: a played key dips 3 degrees about its back in 0.04 s and rises back in 0.16 s; played again mid-dip it goes on from where it is"},
		{"name": "p04_note", "method": "case_p04_note", "world": false,
				"title": "P04: each note plays the instrument's nearest sample pitched to it, at the key, unit size 3 m, gone at 20 m, no jitter"},
		{"name": "p05_ring", "method": "case_p05_ring", "world": false,
				"title": "P05: a note rings at full for 1.6 s, then fades out over 1.2 s and stops"},
		{"name": "p06_restrike", "method": "case_p06_restrike", "world": false,
				"title": "P06: a note played again while it rings: the old one fades out in 0.08 s, the new one rings"},
		{"name": "p07_voices", "method": "case_p07_voices", "world": false,
				"title": "P07: 12 voices; a 13th note cuts the oldest"},
		{"name": "p08_coop", "method": "case_p08_coop", "world": false,
				"title": "P08, real ENet: a Guest's key sounds and dips at once and not again; the Host hears it once; too far is refused; a late Guest hears nothing old"},
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
	_done_now()
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


func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := LevelRuntime.of(_zoo).player
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


func case_p01_keys() -> void:
	var piano := (load(PIANO) as PackedScene).instantiate() as Node3D
	add_child(piano)
	var keys := piano.get_node("Keys").get_children()
	_check(keys.size() == 88, "88 keys (%d)" % keys.size())
	var notes: Array[int] = []
	for k: Node in keys:
		var part := k.get_node_or_null("Key") as PianoKey
		_check(part != null, "%s has its PianoKey" % k.name)
		if part == null:
			continue
		notes.append(part.note)
		_check(String(k.name) == "Key_%d" % part.note, "%s plays MIDI %d" % [k.name, part.note])
		var mesh := part.key_mesh()
		_check(mesh != null and int(mesh.get_meta(&"midi", -1)) == part.note, "%s dips the Looks' key mesh" % k.name)
		if mesh != null:
			_check((k as Node3D).position.distance_to(mesh.position) < 0.001, "%s stands on its mesh's hinge" % k.name)
		var body := k.get_node_or_null("Body") as StaticBody3D
		_check(body != null and body.collision_layer == Mess.LAYER_HOUSE and body.get_child_count() > 0, "%s has its collision on the house layer" % k.name)
		_near(part.dip_deg, 3.0, 0.001, "%s dips 3 degrees" % k.name)
		_check(part.axis == Vector3.RIGHT and part.click_only(), "%s turns about its back, used by the left click alone" % k.name)
	var want: Array[int] = []
	for n in range(21, 109):
		want.append(n)
	_same(notes, want, "A0 (21) to C8 (108), low to high")
	_check(PianoKey.note_name(60) == "C4" and PianoKey.note_name(21) == "A0" and PianoKey.note_name(108) == "C8"
			and PianoKey.note_name(70) == "A#4", "middle C is C4, the lowest A0, the highest C8, 70 is A#4")
	_check((piano.get_node("Keys/Key_60/Key") as PianoKey).prompt_title() == "Play C4", "its prompt: Play C4")
	piano.free()


func case_p02_real_path() -> void:
	await _zoo_up()
	var player := LevelRuntime.of(_zoo).player
	var piano := _piece("piano")
	var key := piano.get_node("Keys/Key_60/Key") as PianoKey
	var lid := piano.get_node("Lid/Openable") as Openable
	_stand(player, piano.to_global(Vector3(-0.06, 0.0, 0.95)))
	await _physics_ticks(3)
	var on_key := piano.to_global(Vector3(-0.0587, 0.735, 0.24))
	await _aim(player, on_key)
	_check(Player.part_of(player.get_node("Head/Aim").get_collider()) == lid, "shut, the crosshair meets the lid, not a key")
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return lid.open and not lid.is_moving(), "the lid to open", 120)
	_check(_count(&"piano_lid_open") == 1, "the lid opens with its sound")
	await _aim(player, on_key)
	var aimed := Player.part_of(player.get_node("Head/Aim").get_collider())
	_check(aimed == key, "open, the crosshair meets middle C (%s)" % aimed)
	player.capture_mouse()
	await _physics_ticks(2)
	var outline := key.get_parent().get_node("Outline") as Outline
	_check(player.aimed_outline == outline and outline.shown, "the aimed key shows its outline")
	var row := Prompts.target(aimed)
	_check(row.size() == 1 and row[0].title == "Play C4" and row[0].keys == Prompts.keys(Player.PICK),
			"its prompt reads Play C4 with the left button (%s)" % [row[0].keys if row.size() > 0 else []])
	_heard.clear()
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _physics_ticks(2)
	_check(key.strikes == 0 and _count(&"piano") == 0, "E does not play it")
	player.capture_mouse()
	await _physics_ticks(2)
	Input.action_press(&"pick")
	await _physics_ticks(2)
	Input.action_release(&"pick")
	await _until(func() -> bool: return key.strikes == 1, "the left click to play it")
	_check(_count(&"piano") == 1, "its note sounds once")
	var h := _last(&"piano")
	_check(not h.is_empty() and (h["at"] as Vector3).distance_to(key.get_parent().global_position) < 0.01, "at the key")
	await _until(func() -> bool: return key.dip() > 0.5, "the key to dip", 30)
	await _until(func() -> bool: return not key.moving() and key.dip() < 0.01, "the key to come back up", 60)


func case_p03_dip() -> void:
	var piano := (load(PIANO) as PackedScene).instantiate() as Node3D
	add_child(piano)
	_level = piano
	await _frames(1)
	var key := piano.get_node("Keys/Key_60/Key") as PianoKey
	var mesh := key.key_mesh()
	var home := mesh.transform
	var t0 := _clock
	key.press()
	await _until(func() -> bool: return key.dip() > 0.99, "the key to be fully down", 60)
	var down := _clock - t0
	_check(down < 0.04 + 0.1, "down in about 0.04 s (%.3f)" % down)
	# Down, the front is lower than at rest: it turned about its back (+X).
	var front := Vector3(0.0, 0.0, 0.2)
	_check((mesh.transform * front).y < (home * front).y - 0.005, "its front went down")
	_near(rad_to_deg((home.basis.inverse() * mesh.transform.basis).get_rotation_quaternion().get_angle()), 3.0, 0.2, "by 3 degrees")
	_check(mesh.transform.origin.distance_to(home.origin) < 0.0001, "about its hinge")
	await _until(func() -> bool: return not key.moving(), "the key to rise", 60)
	var whole := _clock - t0
	_check(whole >= 0.18 and whole < 0.2 + 0.2, "back up in 0.04 + 0.16 s (%.3f)" % whole)
	_check(mesh.transform.is_equal_approx(home), "at rest again")
	key.press()
	await _until(func() -> bool: return key.dip() > 0.99, "down again", 60)
	await _frames(3)
	var mid := key.dip()
	key.press()
	await _frames(1)
	_check(key.dip() >= mid - 0.05, "played again mid-rise it goes down from where it was (%.2f, %.2f)" % [mid, key.dip()])


func case_p04_note() -> void:
	var e := Sounds.catalogue.find(&"piano")
	_check(e != null and e.instrument != null and e.spatial, "the piano is a world instrument in the catalogue")
	if e == null or e.instrument == null:
		return
	_check(e.clips.size() == 23 and e.instrument.roots.size() == 23, "23 recorded notes, each with its root")
	_check(e.clips[10].resource_path.get_file() == "piano_remeau_60.ogg", "the old first instrument, the Remeau upright")
	var at := Vector3(1.0, 1.0, 1.0)
	for note: int in [21, 60, 61, 70, 108]:
		Sounds.play_note(&"piano", note, at)
		var voice := Sounds.note_voice(&"piano", note)
		_check(voice != null, "MIDI %d rings" % note)
		if voice == null:
			continue
		var best := e.instrument.nearest(note)
		_check(voice.stream == e.clips[best], "MIDI %d plays its nearest sample (%s)" % [note, voice.stream.resource_path.get_file()])
		_near(voice.pitch_scale, pow(2.0, (note - e.instrument.roots[best]) / 12.0), 0.0001, "pitched to the note, no jitter")
		_check(voice.global_position.is_equal_approx(at), "at the key")
		_near(voice.unit_size, 3.0, 0.001, "full within 3 m")
		_near(voice.max_distance, 20.0, 0.001, "gone at 20 m")
	_near(e.instrument.pitch_of(e.instrument.nearest(60), 60), pow(2.0, (60.0 - 59.9) / 12.0), 0.0001, "middle C from the C4 sample, its root 59.9")


func case_p05_ring() -> void:
	Sounds.play_note(&"piano", 64, Vector3.ZERO)
	var voice := Sounds.note_voice(&"piano", 64)
	var start := voice.volume_db
	var t0 := _clock
	await _until(func() -> bool: return _clock - t0 > 1.45, "1.45 s", 900)
	_check(voice.playing and is_equal_approx(voice.volume_db, start), "still at full after 1.45 s")
	await _until(func() -> bool: return voice.volume_db < start - 1.0, "the release to begin", 120)
	var released := _clock - t0
	_check(released >= 1.55 and released < 1.6 + 0.4, "let go at 1.6 s (%.2f)" % released)
	await _until(func() -> bool: return not voice.playing, "the note to stop", 300)
	var stopped := _clock - t0
	_check(stopped >= 2.7 and stopped < 2.8 + 0.5, "faded out over 1.2 s (%.2f)" % stopped)
	_check(Sounds.note_voice(&"piano", 64) == null, "its voice is free")


func case_p06_restrike() -> void:
	Sounds.play_note(&"piano", 67, Vector3.ZERO)
	var first := Sounds.note_voice(&"piano", 67)
	Sounds.play_note(&"piano", 67, Vector3.ZERO)
	var t0 := _clock
	await _until(func() -> bool: return not first.playing, "the first to fade", 60)
	var gone := _clock - t0
	_check(gone < 0.08 + 0.15, "the first faded in about 0.08 s (%.3f)" % gone)
	var second := Sounds.note_voice(&"piano", 67)
	_check(second != null and second != first and second.playing, "the second rings")


func case_p07_voices() -> void:
	var voices: Array[AudioStreamPlayer3D] = []
	for i in 12:
		Sounds.play_note(&"piano", 40 + i, Vector3.ZERO)
		voices.append(Sounds.note_voice(&"piano", 40 + i))
	var distinct := {}
	for v in voices:
		distinct[v] = true
	_check(distinct.size() == 12, "12 notes ring on 12 voices")
	Sounds.play_note(&"piano", 80, Vector3.ZERO)
	_check(Sounds.note_voice(&"piano", 40) == null, "a 13th cuts the oldest")
	_check(Sounds.note_voice(&"piano", 80) == voices[0], "on its voice")
	_check(Sounds.note_voice(&"piano", 41) != null, "the others ring on")


func case_p08_coop() -> void:
	var host := _machine("Host")
	_check((host["session"] as Session).host() == OK, "the Host listens")
	var guest := await _guest("Guest")
	var g_id := (guest["session"] as Session).me()
	var key_id := &"Piano/Keys/Key_60/Key"
	var hk := (host["parts"] as Parts).of(key_id) as PianoKey
	var gk := (guest["parts"] as Parts).of(key_id) as PianoKey
	_heard.clear()
	gk.use(g_id)
	_check(_count(&"piano") == 1 and gk.moving(), "the Guest's own key sounds and dips at once")
	await _until(func() -> bool: return gk.strikes == 1, "the Host's word to reach the Guest", 900, NET_WAIT_S)
	_check(hk.strikes == 1 and hk.by == g_id, "the Host counts it, by the Guest")
	await _frames(2)
	_check(_count(&"piano") == 2, "the Host heard it once and the Guest not again (%d)" % _count(&"piano"))
	hk.use(1)
	await _until(func() -> bool: return gk.strikes == 2, "the Host's own key to reach the Guest", 900, NET_WAIT_S)
	_check(_count(&"piano") == 4, "the Host's key sounds on both machines once each (%d)" % _count(&"piano"))
	var hp := host["parts"] as Parts
	hp.where = func(who: int) -> Variant: return Vector3(50.0, 0.0, 0.0) if who == 99 else Vector3.ZERO
	var far := hp.answer(Command.new(&"play", 99, key_id, {}))
	_check(far.get("ok", true) == false and far.get("reason", "") == "far", "a player 50 m off is refused (%s)" % far)
	_check(hp.answer(Command.new(&"play", 1, key_id, {})).get("ok", false), "one at the piano may play")
	hp.where = Callable()
	_heard.clear()
	var late := await _guest("Late")
	var lk := (late["parts"] as Parts).of(key_id) as PianoKey
	_check(lk.strikes == 2, "the late Guest gets the count")
	await _frames(3)
	_check(_count(&"piano") == 0 and not lk.moving(), "and hears and sees nothing of what was played before")
	await _done()


## A machine: a Node with its own MultiplayerAPI, the piano as its level, its Parts and its Session.
func _machine(label: String) -> Dictionary:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var level := Node3D.new()
	level.name = "Level"
	var piano := (load(PIANO) as PackedScene).instantiate() as Node3D
	piano.name = "Piano"
	level.add_child(piano)
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


func _done() -> void:
	for m in _machines:
		(m["session"] as Session).close()
	await _frames(2)
	_done_now()


func _done_now() -> void:
	for m in _machines:
		(m["session"] as Session).close()
		var path := (m["node"] as Node).get_path()
		remove_child(m["node"])
		(m["node"] as Node).free()
		get_tree().set_multiplayer(null, path)
	_machines.clear()
