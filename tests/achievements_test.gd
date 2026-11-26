## Achievements (core/145, docs/architecture/wardrobe.md "Achievements"): the system with test fixtures (batch B ships
## no list, Q2687). The real path is the Stages station's mini run with the game's player, a Parts and a game link:
## shelving a Pair by a left click earns the fixture "1 Pair shelved" on a fresh profile, the toast slides in with its
## title and the chime, and the profile records it with a time. A reward reaches the profile and the Roster with the
## HUD line; earned once; a reset keeps pieces; the toast queues and holds while the HUD is hidden; the id rules on
## every file; the zoo station built from the folder, its switches by the player's E.
extends TestSuite

const FakeBackend := preload("res://tests/support/fake_achievement_backend.gd")
const STAGES := "res://game/zoo/stations/stages.tscn"
const STATION := "res://game/zoo/stations/achievements.tscn"
const PLAYER := "res://game/player/player.tscn"
const FIXTURES := "res://tests/fixtures/achievements/"
const ONE := &"one_pair_shelved"
const HUNDRED := &"hundred_pairs_puffs"
## The Stages station's Socks, by id: Simple Pairs of Designs 0..5, then Sport.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
## Before the Achievements station's switches, in station space.
const BY_SWITCHES := Vector3(2.0, 0.0, 5.0)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _link: GameLink = null
var _profile: PlayerProfile = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: on the Stages station's mini run with the fixture \"1 Pair shelved\" on a fresh profile, the player shelves a Pair by a left click: the toast slides in with its title and the placeholder icon, the chime plays, and the profile records it with a time"},
		{"name": "reward", "method": "case_reward", "world": false,
				"title": "a fixture with a reward puts the piece in the profile and on the Roster (own), the HUD says \"Wardrobe: Lint puffs unlocked\", and every backend (the fake) is told"},
		{"name": "once_and_reset", "method": "case_once_and_reset", "world": false,
				"title": "earned once, never again; a reset clears the earned ones and keeps the pieces; checked again, they are earned again with no piece named twice"},
		{"name": "toast_queue_hold", "method": "case_toast_queue_hold", "world": false,
				"title": "the toast queues: the second slides in after the first slides out; it holds where it is while the HUD is hidden (a cutscene) and goes on after"},
		{"name": "ids", "method": "case_ids", "world": false,
				"title": "every file of game/profile/achievements/ and of the fixtures is an Achievement whose id (its file name) keeps Steam's rules and whose tally is a Lifetime tally"},
		{"name": "station", "method": "case_station", "world": false,
				"title": "the Achievements station: an empty board with no files; with the fixtures one pillar each; the player's E on +100 Pairs earns both (the reward on its pillar), on Reset clears them and keeps the piece"},
	]


func _before_case() -> void:
	for a: StringName in [&"pick", &"drop_throw", &"interact"]:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_link = null
	_profile = null


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	Achievements.folder = FIXTURES
	_profile = PlayerProfile.fresh()
	Worlds.use_profile(_profile)
	await _build_stages()
	var mess := _station.get_node("Socks/Mess") as Mess
	var hands := _station.get_node("Socks/Hands") as Hands
	var cabinet := _station.get_node("CabinetA/Cabinet") as Cabinet
	var toast := _toast()
	var sounds: Array[StringName] = []
	Sounds.played.connect(func(e: StringName, _s: bool, _at: Vector3, _b: StringName) -> void: sounds.append(e))
	_check(toast.phase == AchievementToast.Phase.IDLE and not toast.card_on_screen(), "the toast is idle before")
	_stand(BY_SOCKS)
	await _aim(_centre(mess, SIMPLE[3]))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return hands.active_of(1) == SIMPLE[3], "the Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_centre(mess, SIMPLE[3] + 1))
	await _press(&"pick")
	await _until(func() -> bool: return mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair")
	_check(_profile.achievements.is_empty(), "nothing earned before the Pair is shelved")
	_stand(BY_CABINET)
	await _aim(_drawer_front(cabinet, 0))
	var before := int(Time.get_unix_time_from_system())
	await _press(&"pick")
	await _until(func() -> bool: return cabinet.shelved().size() == 1, "the Pair to be shelved")
	_check(_profile.tally(PlayerProfile.PAIRS_SHELVED) == 1, "pairs_shelved reads 1")
	_check(_profile.achievements.has(String(ONE)), "the profile records 1 Pair shelved (%s)" % [_profile.achievements])
	var at := int(_profile.achievements.get(String(ONE), 0))
	_check(at >= before - 1 and at <= int(Time.get_unix_time_from_system()) + 1, "with the time it was earned (%d)" % at)
	_check(not _profile.achievements.has(String(HUNDRED)), "the 100 Pairs one is not earned")
	await _until(func() -> bool: return toast.card_on_screen() and toast.shown_title() == "1 Pair shelved", "the toast to slide in with its title")
	var card := toast.get_node("Slot/Card") as Control
	var from_x := card.position.x
	await _until(func() -> bool: return toast.phase == AchievementToast.Phase.STAY, "the slide in to end")
	_check(from_x > 1.0 and absf(card.position.x) < 0.5, "the card slid in from the right (%.1f -> %.1f)" % [from_x, card.position.x])
	_check(toast.shown_icon() == toast.tuning.placeholder_icon and toast.shown_icon() != null, "no icon of its own: the shared placeholder")
	_check(sounds.count(AchievementToast.SOUND) == 1, "the achievement chime played once (%s)" % [sounds])


# --- Reward, once, reset -------------------------------------------------------------------------

func case_reward() -> void:
	Achievements.folder = FIXTURES
	await _build_bare()
	var roster := _link.roster
	var me := _link.session.me()
	var achievements := _achievements()
	var fake := FakeBackend.new()
	achievements.backends.append(fake)
	_check(not Wardrobe.owned(_profile.pieces).has("lint_puffs") and not roster.owned_of(roster.id_of(me)).has("lint_puffs"), "Lint puffs is not owned before")
	_profile.count(PlayerProfile.PAIRS_SHELVED, 100)
	var got := achievements.check()
	_same(got.map(func(a: Achievement) -> StringName: return a.id), [HUNDRED, ONE], "both fixtures earned at 100 Pairs, in id order")
	_check(_profile.pieces.has("lint_puffs"), "the reward is in the profile")
	_check(roster.owned_of(roster.id_of(me)).has("lint_puffs"), "and on the player's Roster entry (own)")
	_check(_player.hud().message_text() == "Wardrobe: Lint puffs unlocked", "the HUD says it (%s)" % _player.hud().message_text())
	_same(fake.asked, [HUNDRED, ONE], "the fake backend was told each")
	_check(fake.flushes >= 1, "and flushed")


func case_once_and_reset() -> void:
	Achievements.folder = FIXTURES
	await _build_bare()
	var achievements := _achievements()
	var fake := FakeBackend.new()
	achievements.backends.append(fake)
	_profile.count(PlayerProfile.PAIRS_SHELVED, 150)
	_check(achievements.check().size() == 2, "both earned")
	var first := _profile.achievements.duplicate()
	_check(achievements.check().is_empty() and achievements.check().is_empty(), "earned once: a check again earns nothing")
	_check(_profile.achievements == first and fake.asked.size() == 2, "the times stay, no backend told twice")
	_player.hud().hide_message()
	achievements.reset()
	_check(_profile.achievements.is_empty(), "a reset clears the earned ones")
	_check(_profile.pieces.has("lint_puffs") and _link.roster.owned_of(_link.roster.id_of(_link.session.me())).has("lint_puffs"), "and keeps the piece")
	_check(achievements.check().size() == 2, "checked again, both are earned again")
	_check(_player.hud().message_text() == "", "no piece named again (it is owned)")
	achievements.reset()
	_check(achievements.grant_all().size() == 2 and _profile.achievements.size() == 2, "grant all earns every one")


# --- The toast -----------------------------------------------------------------------------------

func case_toast_queue_hold() -> void:
	Achievements.folder = FIXTURES
	await _build_bare()
	var toast := _toast()
	var t := AchievementTuning.new()
	t.toast_seconds = 0.4
	t.slide_seconds = 0.1
	t.placeholder_icon = toast.tuning.placeholder_icon
	toast.tuning = t
	toast.queue(Achievements.of_id(ONE))
	toast.queue(Achievements.of_id(HUNDRED))
	await _until(func() -> bool: return toast.shown_title() == "1 Pair shelved", "the first to show")
	_check(toast.waiting() == 1, "the second waits")
	await _until(func() -> bool: return toast.phase == AchievementToast.Phase.STAY, "the first to stay")
	_player.set_cutscene(true)
	await _frames(2)
	_check(toast.held() and not toast.card_on_screen(), "a cutscene hides the HUD: the toast is held")
	var t0 := Time.get_ticks_msec()
	await _until(func() -> bool: return Time.get_ticks_msec() - t0 > 700, "0.7 s to pass", 2000)
	_check(toast.phase == AchievementToast.Phase.STAY and toast.shown_title() == "1 Pair shelved", "held past its stay: still the first, staying")
	_player.set_cutscene(false)
	await _until(func() -> bool: return toast.shown_title() == "100 Pairs shelved", "the second to follow once the HUD is back", 900)
	await _until(func() -> bool: return toast.phase == AchievementToast.Phase.IDLE, "the second to slide out", 900)
	_check(not toast.card_on_screen() and toast.waiting() == 0, "the queue is empty and the card gone")


# --- The ids -------------------------------------------------------------------------------------

func case_ids() -> void:
	for bad: String in ["", "Upper", "has-dash", "space d", "x".repeat(41), "é"]:
		_check(not Achievement.is_id(bad), "'%s' is no id" % bad)
	_check(Achievement.is_id("x".repeat(40)) and Achievement.is_id("pairs_100"), "40 letters, digits and _ are")
	var n := 0
	for dir: String in [Achievements.FOLDER, FIXTURES]:
		for f: String in ResourceLoader.list_directory(dir):
			if not f.ends_with(".tres"):
				continue
			n += 1
			var id := f.get_basename()
			_check(Achievement.is_id(id), "%s%s: its id keeps Steam's rules" % [dir, f])
			var a := load(dir + f) as Achievement
			_check(a != null, "%s%s is an Achievement" % [dir, f])
			if a != null:
				_check(PlayerProfile.TALLIES.has(String(a.tally)) and a.at >= 1, "%s: its tally is a Lifetime tally (%s %d)" % [id, a.tally, a.at])
				_check(a.title != "", "%s has a title" % id)
	_check(n >= 2, "the fixtures were read (%d files)" % n)


# --- The station ---------------------------------------------------------------------------------

func case_station() -> void:
	await _build_bare(STATION)
	var board := _station.get_node("Board") as AchievementBoard
	_check(board.pillars().is_empty() and (board.get_node("EmptyNote") as Node3D).visible, "no files: an empty board, its note shown")
	_level.free()
	_level = null
	Achievements.folder = FIXTURES
	await _build_bare(STATION)
	board = _station.get_node("Board") as AchievementBoard
	var pillars := board.pillars()
	_same(pillars.map(func(p: AchievementPillar) -> StringName: return p.achievement.id), [HUNDRED, ONE], "one pillar per fixture")
	_check(not (board.get_node("EmptyNote") as Node3D).visible, "the note is hidden")
	_check(pillars.all(func(p: AchievementPillar) -> bool: return not p.earned), "none earned on the fresh profile")
	_check((pillars[0].get_node("RewardPoint") as Node3D).get_child_count() == 1, "the reward's preview stands on its pillar")
	await _aim(_button("AddPairsSwitch"))
	await _press(&"interact")
	_check(_profile.tally(PlayerProfile.PAIRS_SHELVED) == 100, "+100 Pairs added to the profile")
	await _until(func() -> bool: return pillars.all(func(p: AchievementPillar) -> bool: return p.earned), "both pillars to show earned")
	_check(_profile.pieces.has("lint_puffs"), "the reward is the player's")
	await _aim(_button("ResetSwitch"))
	await _press(&"interact")
	await _until(func() -> bool: return pillars.all(func(p: AchievementPillar) -> bool: return not p.earned), "Reset: both pillars to show not earned")
	_check(_profile.achievements.is_empty() and _profile.pieces.has("lint_puffs"), "Reset clears the earned ones, keeps the piece")
	await _aim(_button("GrantAllSwitch"))
	await _press(&"interact")
	await _until(func() -> bool: return pillars.all(func(p: AchievementPillar) -> bool: return p.earned), "Grant all: both pillars earned")


# --- Building ------------------------------------------------------------------------------------

## The Stages station's mini run with the game's player, a Parts and a game link (profile_tallies_test's).
func _build_stages() -> void:
	_level = Node3D.new()
	_level.name = "Level"
	_level.add_child(_floor())
	_station = (load(STAGES) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_add_player(BY_SOCKS)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	_add_link()
	add_child(_level)
	var mess := _station.get_node("Socks/Mess") as Mess
	var stages := _station.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return _player.is_on_floor() and mess.looks_of(0) != null and stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")
	await _until(func() -> bool: return stages.due.is_empty(), "Stage 1's Socks to be laid")


## A floor (or `station`), the game's player, a Parts and a game link whose Roster has the player (playing alone).
func _build_bare(station := "") -> void:
	_profile = PlayerProfile.fresh()
	Worlds.use_profile(_profile)
	_level = Node3D.new()
	_level.name = "Level"
	_level.add_child(_floor())
	_station = null
	if station != "":
		_station = (load(station) as PackedScene).instantiate() as Node3D
		_level.add_child(_station)
	_add_player(BY_SWITCHES if _station != null else Vector3.ZERO)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	_add_link()
	add_child(_level)
	if _station != null:
		_player.global_position = _station.to_global(BY_SWITCHES)
	await _until(func() -> bool: return _player.is_on_floor() and _link.parts.is_bound, "the player to stand and the link to bind")
	_link.session.profile = _profile
	_link.session.enter_alone()
	_check(_link.roster.id_of(_link.session.me()) == _profile.id, "the player is in the link's Roster")


func _floor() -> StaticBody3D:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	return floor_body


func _add_player(at: Vector3) -> void:
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = at
	_level.add_child(_player)
	_player.capture_mouse()


func _add_link() -> void:
	_link = GameLink.make()
	_level.add_child(_link)


func _achievements() -> Achievements:
	return _link.get_node("Achievements") as Achievements


func _toast() -> AchievementToast:
	return _player.hud().get_node("AchievementToast") as AchievementToast


func _stand(spot: Vector3) -> void:
	_player.global_position = _station.to_global(spot)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


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


func _button(switch: String) -> Vector3:
	return (_station.get_node("%s/Looks/Button" % switch) as Node3D).global_position


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(mess: Mess, sock: int) -> Vector3:
	if mess.is_pair(sock):
		return mess.pose_of(sock).origin
	return mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)
