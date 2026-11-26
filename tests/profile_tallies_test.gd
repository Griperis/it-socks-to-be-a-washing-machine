## The Profile file and the Lifetime tallies (core/127): the Stages station's mini run with the game's player;
## shelving a Pair by a left click counts pairs_shelved and coins_earned in the player's profile and the file
## has them within the save gap; a loaded or unsettled level counts nothing; a version 1 file loads with its
## name and id kept; many counts write the file once per save gap.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const FOLDER := "user://"
const GAP := 0.6
## The station's Socks, by id: Simple Pairs of Designs 0..5, then Sport.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _a: Cabinet = null
var _profile: PlayerProfile = null
var _was: ProfileTuning = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player shelves a Pair by a left click; the profile's pairs_shelved reads 1 and coins_earned the Coins paid, and the file has them within the save gap"},
		{"name": "not_counted", "method": "case_not_counted", "world": false,
				"title": "a loaded snapshot and an answer while the level is not settled count nothing"},
		{"name": "file", "method": "case_file", "world": false,
				"title": "a version 1 file loads with its name and id kept and the new fields empty; a damaged one is made anew; version 2 round-trips"},
		{"name": "gap", "method": "case_gap", "world": false,
				"title": "many counts in a second write the file once per save gap"},
	]


func _before_case() -> void:
	if _level != null:
		_level.free()
		_level = null
	for a: StringName in [&"pick", &"drop_throw"]:
		Input.action_release(a)
	_was = PlayerProfile.tuning
	var t := ProfileTuning.new()
	t.save_every = GAP
	PlayerProfile.tuning = t
	_clean()


func _after_case() -> void:
	PlayerProfile.tuning = _was
	_clean()


func _clean() -> void:
	for f: String in ["profile_ptest.json", "profile_ptest2.json"]:
		if FileAccess.file_exists(FOLDER + f):
			DirAccess.remove_absolute(FOLDER + f)


func _read(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data as Dictionary if data is Dictionary else {}


func _tally_in_file(path: String, tally: String) -> int:
	var t: Variant = _read(path).get("tallies", {})
	return int((t as Dictionary).get(tally, 0)) if t is Dictionary else 0


func case_real_path() -> void:
	_profile = PlayerProfile.load_or_make("ptest", FOLDER)
	await _build()
	_stand(BY_SOCKS)
	await _aim(_player, _centre(SIMPLE[3]))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == SIMPLE[3], "the Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_player, _centre(SIMPLE[3] + 1))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair")
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 0))
	await _press(&"pick")
	await _until(func() -> bool: return _a.shelved().size() == 1, "the Pair to be shelved")
	var coins := (_station.get_node("Socks/Bank") as Bank).of_player(1)
	_check(coins > 0, "shelving paid Coins (%d)" % coins)
	_check(_profile.tally(PlayerProfile.PAIRS_SHELVED) == 1, "the profile counts the Pair (%s)" % [_profile.tallies])
	_check(_profile.tally(PlayerProfile.COINS_EARNED) == coins, "coins_earned is the Pair's Coins (%d, %s)" % [coins, _profile.tallies])
	await _until(func() -> bool: return _tally_in_file(_profile.path, "pairs_shelved") == 1,
			"the file on disk to have the Pair within the save gap", 600)
	_check(_tally_in_file(_profile.path, "coins_earned") == coins, "the file has the Coins")


func case_not_counted() -> void:
	_profile = PlayerProfile.fresh()
	await _build()
	var snap := _parts.snapshot()
	_parts.load_snapshot(snap)
	_check(_profile.tally(PlayerProfile.PAIRS_SHELVED) == 0, "a loaded snapshot counts nothing")
	_parts.unsettle(self)
	_parts.apply({"ok": true, "shelved": PackedInt32Array([1]), "changes": {}})
	_check(_profile.tally(PlayerProfile.PAIRS_SHELVED) == 0, "an answer while the level is not settled counts nothing")
	_parts.settle(self)
	_parts.apply({"ok": true, "shelved": PackedInt32Array([1, 3]), "changes": {}})
	_check(_profile.tally(PlayerProfile.PAIRS_SHELVED) == 2, "a settled level counts each Pair shelved (%s)" % [_profile.tallies])


func case_file() -> void:
	var path := FOLDER + "profile_ptest2.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"id": "abc123", "name": "Ann", "address": "1.2.3.4"}))
	f.close()
	var p := PlayerProfile.load_or_make("ptest2", FOLDER)
	_check(p.id == "abc123" and p.name == "Ann" and p.address == "1.2.3.4", "version 1 keeps its id, name and address")
	_check(p.pieces.is_empty() and p.tallies.is_empty() and p.achievements.is_empty() and p.designs.is_empty()
			and p.collections.is_empty() and p.look.is_empty(), "version 1 has the new fields empty")
	var seen: Array[StringName] = []
	p.piece_unlocked.connect(func(id: StringName) -> void: seen.append(id))
	_check(p.unlock_piece(&"hat_x") and not p.unlock_piece(&"hat_x") and seen == [&"hat_x"], "unlock_piece appends once and signals")
	p.count(PlayerProfile.COINS_EARNED, 7)
	_check(p.earn("first") and not p.earn("first"), "earn works once")
	p.designs = PackedInt32Array([1, 4])
	p.look = {"hat": "hat_x"}
	p.save()
	var q := PlayerProfile.load_or_make("ptest2", FOLDER)
	_check(q.id == "abc123" and q.pieces == PackedStringArray(["hat_x"]) and q.tally(PlayerProfile.COINS_EARNED) == 7
			and q.achievements.has("first") and q.designs == PackedInt32Array([1, 4]) and q.look == {"hat": "hat_x"},
			"version 2 round-trips (%s)" % [q.to_dict()])
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var r := PlayerProfile.load_or_make("ptest2", FOLDER)
	_check(r.id != "abc123" and PlayerProfile.is_id(r.id) and r.name == PlayerProfile.NAME, "a damaged file is made anew")


func case_gap() -> void:
	var p := PlayerProfile.load_or_make("ptest", FOLDER)
	for i in 30:
		p.count(PlayerProfile.PAIRS_SHELVED, 1)
		await _frames(1)
	await _until(func() -> bool: return _tally_in_file(p.path, "pairs_shelved") == 30, "the file to hold 30", 600)
	var written := FileAccess.get_file_as_string(p.path)
	p.count(PlayerProfile.PAIRS_SHELVED, 1)
	await _physics_ticks(5)
	_check(FileAccess.get_file_as_string(p.path) == written, "a count right after a write waits for the gap")
	p.flush()
	_check(_tally_in_file(p.path, "pairs_shelved") == 31, "flush writes at once (quit)")


func _build() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	_level.add_child(floor_body)
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_a = _station.get_node("CabinetA/Cabinet") as Cabinet
	(_station.get_node("Run/TallyRecorder") as TallyRecorder).profile = _profile
	var stages := _station.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")
	await _until(func() -> bool: return stages.due.is_empty(), "Stage 1's Socks to be laid")


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
