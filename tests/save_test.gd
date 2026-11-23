## Saves (core/58; docs/architecture/saves.md, Q2553-Q2567; behaviour list
## docs/migration/m4-lists/01-main-menu-and-saves.md, "Worlds and Groups", "Saves", "Steam Cloud"):
## the save is the join snapshot written to a file per World, through one SaveStore; autosave, the
## ways out, a failed write, the backup and the damaged file, versions and migrations with sample
## saves, the id list, the load's resets, things in the air laid where they land, the Host alone in its
## Roster by its player id, and the file names Steam Auto-Cloud syncs.
extends TestSuite

const TITLE := "res://game/ui/title/title.tscn"
const HOUSE := "res://game/house/house.tscn"
const ONE_BOX := "res://game/level/one_box_level.tscn"
## The committed sample saves, one per save version (Q2557): each must still load.
const SAMPLES := "res://tests/saves"
## The save's shape: every saved Part's script, its version and its State fields with their types.
const SHAPE := "res://tests/saves/shape.json"
## The house's saved Part ids (Q2558): a rename or a move shows here.
const IDS := "res://tests/saves/house_ids.txt"
const KITCHEN := Rect2(0.1, 0.1, 3.84, 8.3)
const PLAYER_BODY := 8
const FRIDGE := "Furniture/Fridge/Door_Top/Openable"

var _level: Node = null
var _levels: Array[Node] = []
var _title: TitleScreen = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "s01_real_path_round_trip", "method": "case_s01", "world": false,
				"title": "S01 real path: the title's Solo loads the house behind the loading screen; a picked Pair shelved for Coins, a Sock in the Hands and an open fridge; Esc, Back to title, Solo again: the Mess, Hands, Cabinets and Coins are as left, the fridge shut (Q2559) and the player where they stood"},
		{"name": "s02_host_alone_by_player_id", "method": "case_s02", "world": false,
				"title": "S02 (core/57 gap): alone the player is in its own Roster by its profile's player id, and its Hands and Coins are kept under that id, never the peer number"},
		{"name": "s03_coop_world_saves_guest_sees_it", "method": "case_s03", "world": false,
				"title": "S03: a Host's co-op World saves (only the Host: a Guest never saves) and a Guest joining after a reload sees it; the Guest's Coins wait under their player id"},
		{"name": "s04_solo_world_goes_coop", "method": "case_s04", "world": false,
				"title": "S04 (Q1646): the Solo World played with a Guest becomes a co-op World in a free slot and the Solo file goes"},
		{"name": "s05_autosave_within_2s", "method": "case_s05", "world": false,
				"title": "S05 (Q2555): a change is saved within autosave_seconds, not before, the text made and written on a worker thread; nothing is saved before the World is loaded"},
		{"name": "s06_failed_write", "method": "case_s06", "world": false,
				"title": "S06 (Q2556): a save that cannot be written keeps the old file, the HUD says \"Could not save the game\" once, and again only after a save worked"},
		{"name": "s07_backup", "method": "case_s07", "world": false,
				"title": "S07: a file that does not read falls back to its backup and the title says \"Loaded your previous save\" once; a broken file never replaces a good backup"},
		{"name": "s08_damaged", "method": "case_s08", "world": false,
				"title": "S08: a World that reads neither way is kept as <file>.damaged, a New Game starts and the title says \"Your laundry got lost in the wash. Starting fresh.\" once"},
		{"name": "s09_migration_v2", "method": "case_s09", "world": false,
				"title": "S09 (Q2557): the version-1 sample save loads after a made-up version 2 and its step are added; a Part's own version steps its state; a newer file is refused"},
		{"name": "s10_samples_load", "method": "case_s10", "world": false,
				"title": "S10 (Q2557): every committed sample save reads and loads into its level"},
		{"name": "s11_shape_fingerprint", "method": "case_s11", "world": false,
				"title": "S11 (Q2557): the save's shape (each saved Part's State fields and types) matches the committed one for its version: a changed shape needs a raised save_version()"},
		{"name": "s12_id_list", "method": "case_s12", "world": false,
				"title": "S12 (Q2558): the house's saved Part ids are the committed list: a renamed or moved placed thing shows here"},
		{"name": "s13_load_resets", "method": "case_s13", "world": false,
				"title": "S13 (Q2559): after a load every Door and drawer is shut, a lost Sock lies at the return spot, nobody is knocked down and an absent player's Socks lie where they stood"},
		{"name": "s14_in_air_laid", "method": "case_s14", "world": false,
				"title": "S14 (Q2560): a Sock in the air when the game saves is saved lying where it would land; the live game is untouched"},
		{"name": "s15_cloud_names", "method": "case_s15", "world": false,
				"title": "S15 (Q2564-Q2566): through the local-file SaveStore every World is worlds/<player id>/<slot>.json; every synced name matches the Auto-Cloud pattern in saves.md and every temp, backup and damaged name does not"},
		{"name": "s16_slots", "method": "case_s16", "world": false,
				"title": "S16 (Q2554, Q2561): one Solo World and five co-op slots; Solo continues the Solo World or starts one; Host the last-played co-op World or a New Game in a free slot; rows name and order them"},
		{"name": "s17_timing", "method": "case_s17", "world": false, "perf": true,
				"title": "S17: a save of 2,000 and of 10,000 Socks is measured (size, the main thread's snapshot, the worker's text) and stays within budget"},
		{"name": "s99_write_sample", "method": "case_s99", "world": false, "stress": true,
				"title": "S99 (a tool): writes the one-box level's save of this version to sample_v<version>.json in GAME_SAVES_OUT (else user://saves_check), to commit under tests/saves/"},
	]


## What a case before left behind goes first (a level still saving would write into this case's store).
func _before_case() -> void:
	_free_all()
	for child in get_children():
		child.queue_free()
	await _frames(2)
	_level = null
	_title = null


# --- S01 ------------------------------------------------------------------------------------------

func case_s01() -> void:
	_open_title()
	await _click(_title.get_node("%Solo") as Control)
	await _until(func() -> bool: return _level != null, "the title's Solo to load the house")
	var runtime := LevelRuntime.of(_level)
	await _until(func() -> bool: return runtime.autosave.saves() and runtime.player.is_on_floor(), "the Solo World to be loaded and the player to stand")
	_check(runtime.autosave.world.slot == Worlds.SOLO and runtime.autosave.world.is_new, "a New Game in the Solo slot")
	var mess := runtime.mess
	var hands := runtime.hands
	var player := runtime.player
	var me := player.player_id()
	var pair_of := _kitchen_pair(mess, _level)
	_check(not pair_of.is_empty(), "a Pair lies open in the kitchen")
	if pair_of.is_empty():
		return
	player.capture_mouse()
	_stand(player, pair_of["spots"][0])
	await _aim(player, _centre(mess, pair_of["socks"][0]))
	await _press(&"pick")
	await _until(func() -> bool: return hands.active_of(me) == pair_of["socks"][0], "the first Sock in the Hands")
	await _physics_ticks(25)
	_stand(player, pair_of["spots"][1])
	await _aim(player, _centre(mess, pair_of["socks"][1]))
	await _press(&"pick")
	await _until(func() -> bool: return mess.is_pair(pair_of["socks"][0]) or mess.is_pair(pair_of["socks"][1]), "the mate to pair")
	var pair: int = pair_of["socks"][0] if mess.is_pair(pair_of["socks"][0]) else pair_of["socks"][1]
	var root := _level.get_node("Cabinets/Kitchen") as Node3D
	var cab := root.get_node("Cabinet") as Cabinet
	_stand(player, root.global_transform * Vector3(0.0, 0.0, 1.2))
	await _aim(player, (root.get_node("Drawer1/Looks/Slide/Front") as Node3D).global_position + root.global_basis.z * 0.02)
	await _press(&"pick")
	await _until(func() -> bool: return cab.contents(0).has(pair), "the Pair to be shelved")
	var coins := runtime.coins.of_player(me)
	_check(coins > 0, "Coins earned (%d)" % coins)
	# One more Sock held, and the fridge open.
	var held := -1
	for sock in mess.count():
		if mess.state_of(sock) == Mess.State.LYING and not mess.is_moving(sock) and not mess.is_pair(sock):
			held = sock
			break
	await _physics_ticks(25)
	runtime.parts.apply({"ok": true, "changes": {mess.id: mess.held_patch(held),
			hands.id: {"held": {hands.key_of(me): PackedInt32Array([held])}, "active": {hands.key_of(me): 0}}}})
	_check(hands.items_of(me) == PackedInt32Array([held]), "a Sock held")
	var fridge := _level.get_node(FRIDGE) as Openable
	runtime.parts.apply(fridge.grant({"open": true}))
	await _until(func() -> bool: return not fridge.is_moving(), "the fridge open")
	await _until(func() -> bool: return mess.moving_count() == 0, "the Mess to settle", 1800)
	_stand(player, Vector3(1.6, 0.05, 6.0))
	await _physics_ticks(5)
	var stood := player.global_position
	var states := mess.states.duplicate()
	var shelved := cab.contents(0)
	# Esc, then Back to title: it saves first.
	var writes := (Save.store as MemoryStore).writes
	await _key(&"ui_cancel")
	var menu := runtime.esc_menu
	_check(menu.is_open() and not get_tree().paused, "Esc opens the ESC menu and nothing pauses")
	_check((menu.get_node("%BackToTitle") as Control).visible and (menu.get_node("%QuitGame") as Control).visible
			and not (menu.get_node("%EndSession") as Control).visible, "alone: Back to title and Quit game")
	await _click(menu.get_node("%BackToTitle") as Control)
	await _until(func() -> bool: return _title != null and _level == null, "Back to title to bring the title back")
	_check((Save.store as MemoryStore).writes > writes, "Back to title saved first")
	# Solo again.
	await _click(_title.get_node("%Solo") as Control)
	await _until(func() -> bool: return _level != null, "Solo to load the saved house")
	runtime = LevelRuntime.of(_level)
	await _until(func() -> bool: return runtime.autosave.saves(), "the saved World to be loaded")
	_check(not runtime.autosave.world.is_new, "Solo continues the Solo World")
	mess = runtime.mess
	await _until(func() -> bool: return mess.moving_count() == 0, "the loaded Mess to settle", 1800)
	_same(mess.states, states, "every Sock's state is as left")
	_check(runtime.hands.items_of(me) == PackedInt32Array([held]), "the Hands hold the held Sock (%s)" % runtime.hands.items_of(me))
	_check((_level.get_node("Cabinets/Kitchen/Cabinet") as Cabinet).contents(0) == shelved, "the Cabinet holds the shelved Pair")
	_check(runtime.coins.of_player(me) == coins, "the Coins are as left (%d)" % runtime.coins.of_player(me))
	_check(not (_level.get_node(FRIDGE) as Openable).open, "the fridge starts shut (Q2559)")
	_near(runtime.player.global_position.distance_to(stood), 0.0, 0.3, "the player stands where they quit")


# --- S02 ------------------------------------------------------------------------------------------

func case_s02() -> void:
	var level := await _one_box(null, [])
	var runtime := LevelRuntime.of(level)
	var pid := runtime.session.profile.id if runtime.session.profile != null else ""
	_check(PlayerProfile.is_id(pid), "alone the Session has a player id")
	_check(runtime.roster.id_of(1) == pid, "alone the player is in its own Roster by that id")
	runtime.parts.apply(runtime.coins.grant(runtime.coins.paid_patch(1, 5)))
	_check(runtime.coins.coins.keys() == [pid], "the Coins are kept under the player id (%s)" % runtime.coins.coins.keys())
	_check(runtime.hands.key_of(1) == pid, "the Hands key the player by its player id")


# --- S03 ------------------------------------------------------------------------------------------

func case_s03() -> void:
	var w := Worlds.pick_host()
	_check(w != null and w.slot == "coop1" and w.is_new, "Host with no co-op World: a New Game in coop1")
	var host := await _one_box(w, ["--host"])
	var hr := LevelRuntime.of(host)
	var guest := await _one_box(null, [])
	var gr := LevelRuntime.of(guest)
	gr.net.start(["--join=127.0.0.1:%d" % hr.session.port])
	await _until(func() -> bool: return gr.roster.peers().size() == 2, "the Guest to be welcomed", 900, 0.1)
	var gpeer := gr.session.me()
	var gpid := gr.session.profile.id
	hr.parts.apply(hr.coins.grant(hr.coins.paid_patch(1, 7)))
	hr.parts.apply(hr.coins.grant(hr.coins.paid_patch(gpeer, 3)))
	_check(not gr.autosave.saves(), "a Guest's runtime never saves")
	_check(hr.autosave.save_now()["ok"], "the Host saves")
	var gprofile := gr.session.profile
	_free(guest)
	_free(host)
	await _frames(3)
	var again := Worlds.pick_host()
	_check(again != null and again.slot == "coop1" and not again.is_new, "Host again continues coop1")
	var host2 := await _one_box(again, ["--host"])
	var h2 := LevelRuntime.of(host2)
	var guest2 := await _one_box(null, [])
	var g2 := LevelRuntime.of(guest2)
	g2.session.profile = gprofile
	g2.net.start(["--join=127.0.0.1:%d" % h2.session.port])
	await _until(func() -> bool: return g2.roster.peers().size() == 2, "the Guest to join the reloaded World", 900, 0.1)
	_check(g2.coins.of_player(1) == 7, "the Guest sees the Host's saved Coins (%d)" % g2.coins.of_player(1))
	_check(g2.coins.of_player(g2.session.me()) == 3, "the Guest's own Coins waited for them under %s" % gpid.left(8))
	_free_all()


# --- S04 ------------------------------------------------------------------------------------------

func case_s04() -> void:
	var w := Worlds.pick_solo()
	var host := await _one_box(w, ["--host"])
	var hr := LevelRuntime.of(host)
	_check(hr.autosave.save_now()["ok"] and Save.has(Worlds.file_of(Worlds.SOLO)), "played alone it is the Solo World")
	var guest := await _one_box(null, [])
	LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hr.session.port])
	await _until(func() -> bool: return hr.roster.peers().size() == 2, "a Guest to join", 900, 0.1)
	_check(hr.autosave.save_now()["ok"], "the Host saves")
	_check(Save.has(Worlds.file_of("coop1")) and not Save.has(Worlds.file_of(Worlds.SOLO)), "it became coop1 and the Solo file went")
	_check(hr.autosave.world.record.kind == WorldRecord.COOP, "its record says co-op")
	_free_all()


# --- S05 ------------------------------------------------------------------------------------------

func case_s05() -> void:
	var store := Save.store as MemoryStore
	var w := Worlds.pick_solo()
	var level := (load(ONE_BOX) as PackedScene).instantiate()
	LevelRuntime.of(level).world = w
	LevelRuntime.of(level).from_title = true
	_level = level
	add_child(level)
	var runtime := LevelRuntime.of(level)
	_check(not runtime.autosave.saves(), "before the World is loaded nothing saves")
	await _until(func() -> bool: return runtime.autosave.saves(), "the World to load")
	var before := store.writes
	await _until(func() -> bool: return store.writes > before, "the New Game's first save", 300)
	before = store.writes
	runtime.parts.apply(runtime.coins.grant(runtime.coins.paid_patch(1, 1)))
	await _physics_ticks(roundi(runtime.autosave.tuning.autosave_seconds * 60.0 * 0.5))
	_check(store.writes == before, "not saved before autosave_seconds")
	await _until(func() -> bool: return store.writes > before, "saved within autosave_seconds", roundi(runtime.autosave.tuning.autosave_seconds * 60.0) + 30)
	# The worker thread: a slow disk does not hold the main thread.
	store.write_ms = 300
	var t0 := Time.get_ticks_msec()
	runtime.autosave.save_later()
	var spent := Time.get_ticks_msec() - t0
	_check(Save.busy() and spent < 250, "the text is made and written on a worker thread (%d ms on the main thread)" % spent)
	Save.wait()
	store.write_ms = 0


# --- S06 ------------------------------------------------------------------------------------------

func case_s06() -> void:
	var store := Save.store as MemoryStore
	var level := await _one_box(Worlds.pick_solo(), [])
	var runtime := LevelRuntime.of(level)
	_check(runtime.autosave.save_now()["ok"], "a first save")
	var good: String = store.files[runtime.autosave.world.file]
	store.fail_writes = true
	runtime.parts.apply(runtime.coins.grant(runtime.coins.paid_patch(1, 4)))
	_check(not runtime.autosave.save_now()["ok"], "the write fails")
	_check(store.files[runtime.autosave.world.file] == good, "the old file stays")
	_check(_hud_line(runtime) == Autosave.FAILED, "the HUD says \"%s\"" % Autosave.FAILED)
	runtime.player.notice("", 0.01)
	await _physics_ticks(3)
	runtime.autosave.save_now()
	_check(_hud_line(runtime) != Autosave.FAILED, "a second failure says nothing more")
	store.fail_writes = false
	_check(runtime.autosave.save_now()["ok"] and not runtime.autosave.told_failed, "a save that works again")
	store.fail_writes = true
	runtime.autosave.save_now()
	_check(runtime.autosave.told_failed and _hud_line(runtime) == Autosave.FAILED, "after a save worked, a failure is told again")


# --- S07 / S08 ------------------------------------------------------------------------------------

func case_s07() -> void:
	var store := Save.store as MemoryStore
	var file := Worlds.file_of(Worlds.SOLO)
	_check(Save.write_now(file, {"world": {"kind": "solo"}, "parts": {"a": {"x": 1}}})["ok"], "a first save")
	_check(Save.write_now(file, {"world": {"kind": "solo"}, "parts": {"a": {"x": 2}}})["ok"], "a second one: the first is the backup")
	store.files[file] = "{\"version\": 1, \"data\": "  # cut off
	var got := Save.read(file)
	_check(got["ok"] and got["from_backup"] and int(got["data"]["parts"]["a"]["x"]) == 1, "the cut-off file falls back to the backup")
	var w := Worlds.pick_solo()
	_check(w != null and not w.is_new and Worlds.take_notice() == Worlds.FROM_BACKUP, "the title says \"%s\" once" % Worlds.FROM_BACKUP)
	_check(Worlds.take_notice() == "", "only once")
	# A broken file never replaces a good backup.
	_check(Save.write_now(file, {"world": {}, "parts": {"a": {"x": 3}}})["ok"], "a save over the broken file")
	_check(Save.decode(store.files[file + SaveStore.BACKUP])["data"]["parts"]["a"]["x"] == 1, "the backup is still the good one")


func case_s08() -> void:
	var store := Save.store as MemoryStore
	var file := Worlds.file_of(Worlds.SOLO)
	store.files[file] = "not a save"
	store.files[file + SaveStore.BACKUP] = "{}"
	var w := Worlds.pick_solo()
	_check(w != null and w.is_new, "a New Game starts")
	_check(Worlds.take_notice() == Worlds.DAMAGED, "the title says \"%s\"" % Worlds.DAMAGED)
	_check(store.files.has(file + SaveStore.DAMAGED) and not store.files.has(file), "the file is kept as .damaged")


# --- S09 / S10 / S11 / S12 ------------------------------------------------------------------------

func case_s09() -> void:
	var sample := _sample(1)
	_check(sample != "", "the version-1 sample is committed")
	if sample == "":
		return
	Save.version = 2
	Save.register_migration(1, func(data: Dictionary) -> Dictionary:
		var world: Dictionary = data["world"]
		world["floor"] = "Basement"
		return data)
	# The World belongs to the player who saved it: load it as them.
	var owner := PlayerProfile.fresh()
	owner.id = String((Save.decode(sample)["data"]["world"]["members"] as Dictionary).keys()[0])
	Worlds.use_profile(owner)
	var file := Worlds.file_of(Worlds.SOLO)
	(Save.store as MemoryStore).files[file] = sample
	var w := Worlds.pick_solo()
	_check(w != null and not w.is_new and w.record.floor_name == "Basement", "the version-1 file loads through the made-up step to version 2")
	if w == null:
		return
	var level := await _one_box(w, [])
	var runtime := LevelRuntime.of(level)
	_check(runtime.coins.of_player(1) == 12, "its Coins load (%d)" % runtime.coins.of_player(1))
	# A Part's own version: a saved state of version 1 is stepped to the Part's.
	var stepped := SaveStepPart.new()
	stepped.name = "StepPart"
	level.add_child(stepped)
	runtime.parts.bind(level)
	runtime.parts.load_save({"StepPart": {"old": 5}}, {"StepPart": 1}, "x")
	_check(stepped.count == 5, "a Part's state of version 1 is stepped to its version 2 (count %d)" % stepped.count)
	(Save.store as MemoryStore).files[file] = sample.replace("\"version\": 1", "\"version\": 9")
	_check(Worlds.pick_solo() == null and Worlds.take_notice() == Worlds.NEWER, "a newer build's file is refused, never guessed at")


func case_s10() -> void:
	var names := Array(DirAccess.get_files_at(SAMPLES)).filter(func(f: String) -> bool: return f.begins_with("sample_v"))
	_check(not names.is_empty(), "sample saves are committed")
	for f: String in names:
		var got := Save.decode(FileAccess.get_file_as_string(SAMPLES.path_join(f)))
		_check(got["ok"], "%s reads (%s)" % [f, got.get("reason", "")])
		if not got["ok"]:
			continue
		var w := WorldSlot.new()
		w.slot = Worlds.SOLO
		w.file = Worlds.file_of(Worlds.SOLO)
		w.profile = Worlds.profile()
		w.record = WorldRecord.from_dict(got["data"]["world"])
		w.parts = got["data"]["parts"]
		w.versions = got["data"].get("versions", {})
		w.is_new = false
		var level := await _one_box(w, [])
		_check(LevelRuntime.of(level).autosave.saves(), "%s loads into its level" % f)
		_free(level)


func case_s11() -> void:
	var house := await _house(null)
	var shape := {}
	for id in LevelRuntime.of(house).parts.ids():
		var part := LevelRuntime.of(house).parts.of(id)
		if part.save_state().is_empty():
			continue
		var script := (part.get_script() as Script).resource_path
		var fields := {}
		for p: Dictionary in part.get_property_list():
			if part.state_names().has(p["name"]):
				fields[p["name"]] = type_string(int(p["type"]))
		shape[script] = {"version": part.save_version(), "fields": fields}
	var text := JSON.stringify(shape, "\t", true) + "\n"
	_keep_for_commit("shape.json", text)
	var committed := FileAccess.get_file_as_string(SHAPE)
	_check(committed.strip_edges() == text.strip_edges(), "the save's shape is the committed one; if a Part's State changed, raise its save_version() (and its upgrade_save()) and commit:\n%s" % text)


func case_s12() -> void:
	var house := await _house(null)
	var ids := PackedStringArray()
	for id: Variant in LevelRuntime.of(house).parts.save_snapshot():
		ids.append(String(id))
	ids.sort()
	_keep_for_commit("house_ids.txt", "\n".join(ids) + "\n")
	var committed := FileAccess.get_file_as_string(IDS).strip_edges().split("\n")
	var gone := Array(committed).filter(func(i: String) -> bool: return not ids.has(i))
	var new := Array(ids).filter(func(i: String) -> bool: return not committed.has(i))
	_check(gone.is_empty() and new.is_empty(), "the house's saved ids are the committed list (gone, renamed or moved: %s; new: %s); commit the list when the change is meant:\n%s" % [gone, new, "\n".join(ids)])


# --- S13 / S14 ------------------------------------------------------------------------------------

func case_s13() -> void:
	var house := await _house(Worlds.pick_solo())
	var runtime := LevelRuntime.of(house)
	var mess := runtime.mess
	var fridge := house.get_node(FRIDGE) as Openable
	runtime.parts.apply(fridge.grant({"open": true}))
	# A lost Sock lying outside the house, an absent player holding two Socks where they stood.
	var lying: Array[int] = []
	for sock in mess.count():
		if mess.state_of(sock) == Mess.State.LYING and not mess.is_moving(sock):
			lying.append(sock)
		if lying.size() == 3:
			break
	var lost := lying[0]
	var away := Transform3D(Basis.IDENTITY, Vector3(80.0, 0.0, 80.0))
	runtime.parts.apply(mess.grant(mess.lying_patch(lost, away)))
	var spot := Vector3(2.0, 0.05, 6.0)
	var players := runtime.roster.players.duplicate(true)
	players["absent"] = {"peer": 0, "name": "Absent", "colour": 1, "at": spot, "yaw": 0.0}
	var held := runtime.hands.held.duplicate()
	held["absent"] = PackedInt32Array([lying[1], lying[2]])
	runtime.parts.apply(runtime.roster.grant({"players": players}))
	runtime.parts.apply({"ok": true, "changes": {mess.id: mess.held_patch(lying[2], mess.held_patch(lying[1])), runtime.hands.id: {"held": held}}})
	runtime.knockdowns.down = {1: {"at": 0.0}}
	var file := runtime.autosave.collect()
	_check(not file["parts"].has(String(runtime.knockdowns.id)), "who lies knocked down is not saved")
	_check(not file["parts"][String(runtime.hands.id)].has("grabbed_at"), "the Host's clock is not saved")
	_check(runtime.autosave.save_now()["ok"], "saved")
	_free(house)
	await _frames(3)
	var loaded := await _house(Worlds.pick_solo())
	var r2 := LevelRuntime.of(loaded)
	_check(not (loaded.get_node(FRIDGE) as Openable).open, "the fridge starts shut")
	_check(r2.mess.in_bounds(r2.mess.pose_of(lost).origin) and r2.mess.pose_of(lost).origin.distance_to(r2.mess.return_spot.global_position) < 2.0,
			"the lost Sock lies at the return spot")
	_check(not r2.hands.held.has("absent"), "the absent player holds nothing")
	await _until(func() -> bool: return r2.mess.state_of(lying[1]) == Mess.State.LYING and r2.mess.state_of(lying[2]) == Mess.State.LYING, "their Socks to come down", 900)
	_check(r2.mess.pose_of(lying[1]).origin.distance_to(spot) < 1.5, "their Socks lie where they stood")
	_check(r2.knockdowns.down.is_empty(), "nobody is knocked down")


func case_s14() -> void:
	var house := await _house(null)
	var runtime := LevelRuntime.of(house)
	var mess := runtime.mess
	var sock := -1
	for s in mess.count():
		if mess.state_of(s) == Mess.State.LYING and not mess.is_moving(s):
			sock = s
			break
	var from := Transform3D(Basis.IDENTITY, Vector3(1.6, 1.6, 6.0))
	runtime.parts.apply(mess.grant(mess.thrown_patch(sock, from, Vector3(0.5, 1.0, 0.0), Vector3.ZERO, 1)))
	await _physics_ticks(3)
	_check(mess.state_of(sock) == Mess.State.FLYING, "the Sock flies")
	var saved := Mess.unpacked(mess.save_state())
	_check(int((saved["states"] as PackedByteArray)[sock]) == Mess.State.LYING and not (saved["throws"] as Dictionary).has(sock), "it is saved lying, with no launch")
	var at := Mess.unpack(saved["poses"] as PackedFloat32Array, sock).origin
	_check(absf(at.y) < 0.15 and at.distance_to(from.origin) < 2.0, "where it would land on the floor (%s)" % at)
	_check(mess.state_of(sock) == Mess.State.FLYING, "the live game is untouched")


# --- S15 / S16 ------------------------------------------------------------------------------------

func case_s15() -> void:
	var folder := "user://test_saves_%d" % Time.get_ticks_usec()
	var store := LocalFileStore.new(folder)
	Save.store = store
	var file := Worlds.file_of(Worlds.SOLO)
	_check(file == "worlds/%s/solo.json" % Worlds.profile().id, "a World is worlds/<player id>/<slot>.json (%s)" % file)
	_check(Save.write_now(file, {"world": {}, "parts": {}})["ok"] and Save.write_now(file, {"world": {}, "parts": {"x": {}}})["ok"], "two saves through the local files")
	store.write(Worlds.file_of("coop1"), "{", false)
	Save.read(Worlds.file_of("coop1"))  # reads neither way: kept as .damaged
	var leftover := FileAccess.open(ProjectSettings.globalize_path(folder.path_join(file)) + SaveStore.TEMP, FileAccess.WRITE)
	leftover.store_string("half")
	leftover.close()
	var names := store.all_names()
	_check(names.has(file) and names.has(file + SaveStore.BACKUP) and names.has(Worlds.file_of("coop1") + SaveStore.DAMAGED),
			"the file, its backup and the damaged copy are there (%s)" % names)
	var pattern := _autocloud_pattern()
	_check(pattern != "", "saves.md names the Auto-Cloud pattern")
	for n in names:
		var synced := n.match(pattern)
		_check(synced == SaveStore.synced(n), "%s %s the Auto-Cloud pattern %s" % [n, "matches" if synced else "does not match", pattern])
		_check(synced == (n.ends_with(".json")), "%s: only a World's own file is synced" % n)
	_check(store.list("worlds/%s" % Worlds.profile().id) == PackedStringArray([file]), "the list shows only synced files")
	# Two players on one PC keep their own Worlds.
	var other := PlayerProfile.fresh()
	var mine := Worlds.file_of(Worlds.SOLO)
	Worlds.use_profile(other)
	_check(Worlds.file_of(Worlds.SOLO) != mine and not Save.has(Worlds.file_of(Worlds.SOLO)), "another player's folder is their own")
	_check(ProjectSettings.get_setting("application/config/use_custom_user_dir") == true
			and ProjectSettings.get_setting("application/config/custom_user_dir_name") == "It Socks", "the save folder is \"It Socks\" (Q2567)")
	_remove_tree(ProjectSettings.globalize_path(folder))


func case_s16() -> void:
	_check(Worlds.coop_slots() == PackedStringArray(["coop1", "coop2", "coop3", "coop4", "coop5"]), "five co-op slots")
	var solo := Worlds.pick_solo()
	_check(solo.slot == Worlds.SOLO and solo.is_new and not solo.hosting, "Solo with no save: a New Game, alone")
	var rec := {"kind": "coop", "members": {"a": {"name": "Ann", "colour": 0}}, "play_time": 3720.0, "last_played": 100}
	Save.write_now(Worlds.file_of("coop1"), {"world": rec, "parts": {}})
	var rec2 := rec.duplicate(true)
	rec2["last_played"] = 200
	rec2["members"] = {}
	Save.write_now(Worlds.file_of("coop3"), {"world": rec2, "parts": {}})
	var w := Worlds.pick_host()
	_check(w.slot == "coop3" and w.hosting and not w.is_new, "Host continues the last-played co-op World")
	_check(Worlds.free_coop_slot() == "coop2", "the first free slot is coop2")
	var rows := Worlds.rows()
	_check(rows.size() == 2 and rows[0]["slot"] == "coop3" and rows[0]["name"] == Worlds.NO_GROUP and rows[1]["name"] == "Ann",
			"co-op rows newest first, named by their players or \"No Group yet\" (%s)" % [rows])
	_check(String(rows[1]["details"]).contains("played 1h 02m"), "a row's details (%s)" % rows[1]["details"])
	Worlds.delete("coop3")
	_check(not Save.has(Worlds.file_of("coop3")), "a deleted World's files go")
	for i in 5:
		Save.write_now(Worlds.file_of("coop%d" % (i + 1)), {"world": rec, "parts": {}})
	_check(Worlds.free_coop_slot() == "", "five used: no free slot")
	Save.write_now(Worlds.file_of(Worlds.SOLO), {"world": {"kind": "solo"}, "parts": {}})
	Worlds.new_game = true
	_check(Worlds.pick_solo().is_new, "--new-game starts a New Game over the Solo World")


# --- S17 ------------------------------------------------------------------------------------------

func case_s17() -> void:
	var level := await _one_box(null, [])
	var mess := LevelRuntime.of(level).mess
	for n: int in [2000, 10000]:
		var designs := PackedInt32Array()
		var states := PackedByteArray()
		var mates := PackedInt32Array()
		var poses := PackedFloat32Array()
		for i in n:
			designs.append(i % 50)
			states.append(Mess.State.LYING)
			mates.append(-1)
			poses.append_array(Mess.pack(Transform3D(Basis(Vector3.UP, i * 0.37), Vector3(i % 100 * 0.1, 0.0, i / 100 * 0.1))))
		var mark := _cpu_mark()
		var t0 := Time.get_ticks_usec()
		var state := {"designs": designs, "states": states, "mates": mates, "poses": poses, "throws": {}}
		mess.designs = designs
		mess.states = states
		mess.mates = mates
		mess.poses = poses
		var saved := mess.save_state()
		var t1 := Time.get_ticks_usec()
		var text := Save.encode({"world": {}, "parts": {"Mess": saved}})
		var t2 := Time.get_ticks_usec()
		Log.info("save", "S17: %d Socks: %d bytes, snapshot %.1f ms (main thread), text %.1f ms (worker)" % [n, text.length(), (t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
		_budget((t1 - t0) < 60000 * (n / 2000), "the snapshot of %d Socks on the main thread (%.1f ms)" % [n, (t1 - t0) / 1000.0], mark)
		_check(text.length() < 120 * n, "the file of %d Socks is small (%d bytes)" % [n, text.length()])
		state.clear()


# --- S99 ------------------------------------------------------------------------------------------

func case_s99() -> void:
	var level := await _one_box(Worlds.pick_solo(), [])
	var runtime := LevelRuntime.of(level)
	runtime.parts.apply(runtime.coins.grant(runtime.coins.paid_patch(1, 12)))
	DirAccess.make_dir_recursive_absolute(_out_folder())
	var path := _out_folder().path_join("sample_v%d.json" % Save.version)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(Save.encode(runtime.autosave.collect()))
	f.close()
	Log.info("save", "S99: wrote %s" % ProjectSettings.globalize_path(path))
	_check(true, "wrote %s" % ProjectSettings.globalize_path(path))


# --- Helpers --------------------------------------------------------------------------------------

## The title in the tree, its way into the game and the ESC menu's way back kept in this case.
func _open_title() -> void:
	_title = (load(TITLE) as PackedScene).instantiate() as TitleScreen
	_title.go_into = func(path: String, _heading: String, setup: Callable) -> void:
		var root := (load(path) as PackedScene).instantiate()
		if setup.is_valid():
			setup.call(root)
		var runtime := LevelRuntime.of(root)
		if runtime != null:
			runtime.esc_menu.go_to_title = func(_notice: String) -> void:
				runtime.esc_menu.close()
				_free(root)
				_level = null
				_open_title.call_deferred()
		_level = root
		add_child(root)
		if _title != null:
			_title.queue_free()
		_title = null
	add_child(_title)


## The one-box level with `world` (null: none), started with `launch` (the Net's arguments), in a
## machine of its own (its own MultiplayerAPI and 3D world, as tests/level_test.gd's).
func _one_box(world: WorldSlot, launch: Array) -> Node:
	var node := Node.new()
	node.name = "Machine%d" % _levels.size()
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var view := SubViewport.new()
	view.name = "View"
	view.own_world_3d = true
	view.size = Vector2i(64, 64)
	node.add_child(view)
	var level := (load(ONE_BOX) as PackedScene).instantiate()
	var runtime := LevelRuntime.of(level)
	runtime.world = world
	runtime.from_title = true
	runtime.launch = PackedStringArray(launch)
	_levels.append(node)
	view.add_child(level)
	await _until(func() -> bool: return runtime.parts.is_bound and runtime.roster.id_of(1) != "", "the level to start")
	return level


func _house(world: WorldSlot) -> Node:
	var house := (load(HOUSE) as PackedScene).instantiate()
	var runtime := LevelRuntime.of(house)
	runtime.world = world
	runtime.from_title = world != null
	_levels.append(house)
	add_child(house)
	await _until(func() -> bool: return runtime.parts.is_bound and runtime.player.is_on_floor() and runtime.roster.id_of(1) != "", "the house to start")
	return house


## A level goes: its session closes; a machine of its own goes with its MultiplayerAPI.
func _free(level: Node) -> void:
	if not is_instance_valid(level):
		return
	var runtime := LevelRuntime.of(level)
	if runtime != null:
		runtime.session.close()
	var machine := level
	while machine.get_parent() != self and machine.get_parent() != null:
		machine = machine.get_parent()
	_levels.erase(machine)
	var path := machine.get_path()
	remove_child(machine)
	machine.free()
	if machine != level:
		get_tree().set_multiplayer(null, path)


## Every machine the case made goes.
func _free_all() -> void:
	for m: Node in _levels.duplicate():
		if is_instance_valid(m):
			var level: Node = m.find_child("OneBoxLevel", true, false)
			_free(level if level != null else m)
	_levels.clear()


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


func _key(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await _frames(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _stand(player: Player, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


func _aim(player: Player, target: Vector3) -> void:
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)


func _centre(mess: Mess, sock: int) -> Vector3:
	return mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)


func _hud_line(runtime: LevelRuntime) -> String:
	return runtime.player.hud().message_text()


## A loose Pair lying open in the kitchen, each Sock with a place to stand and see it: {"socks", "spots"}.
func _kitchen_pair(mess: Mess, house: Node) -> Dictionary:
	var made := house.get_node("SockGenerators/Ground/Generated") as GeneratedSocks
	for sock in range(made.first, made.first + made.socks):
		var at := mess.pose_of(sock).origin
		if not KITCHEN.has_point(Vector2(at.x, at.z)) or not _open_sock(mess, sock):
			continue
		for o in range(made.first, made.first + made.socks):
			if o == sock or mess.designs[o] != mess.designs[sock] or not _open_sock(mess, o):
				continue
			var s1 := _spot_seeing(mess, _centre(mess, sock))
			var s2 := _spot_seeing(mess, _centre(mess, o))
			if s1 != Vector3.INF and s2 != Vector3.INF:
				return {"socks": [sock, o], "spots": [s1, s2]}
	return {}


func _open_sock(mess: Mess, sock: int) -> bool:
	if mess.state_of(sock) != Mess.State.LYING:
		return false
	var at := mess.pose_of(sock).origin
	return PhysicsQueries.ray(mess, at + Vector3.UP * 0.06, at + Vector3.UP * 2.2, Mess.LAYER_HOUSE | Mess.LAYER_LYING).is_empty()


func _spot_seeing(mess: Mess, target: Vector3) -> Vector3:
	var probe := BoxShape3D.new()
	probe.size = Vector3(0.6, 1.5, 0.6)
	for r: float in [1.0, 1.3, 1.6]:
		for k in 12:
			var a := TAU * k / 12.0
			var at := Vector3(target.x + cos(a) * r, 0.0, target.z + sin(a) * r)
			var floor_hit := PhysicsQueries.ray(mess, at + Vector3.UP * 1.0, at + Vector3.DOWN * 0.3, Mess.LAYER_HOUSE)
			if floor_hit.is_empty() or absf((floor_hit["position"] as Vector3).y) > 0.05:
				continue
			if not PhysicsQueries.overlap_rids(mess, probe, Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.85), Mess.LAYER_HOUSE | PLAYER_BODY, 1).is_empty():
				continue
			if PhysicsQueries.ray(mess, at + Vector3.UP * 1.5, target, Mess.LAYER_HOUSE).is_empty():
				return at
	return Vector3.INF


## Where S99, S11 and S12 leave files to commit: GAME_SAVES_OUT, else user://saves_check.
func _out_folder() -> String:
	var env := OS.get_environment("GAME_SAVES_OUT")
	return env if env != "" else "user://saves_check"


## What S11 and S12 found, written to _out_folder() to commit under tests/saves/ when a change is meant.
func _keep_for_commit(file: String, text: String) -> void:
	var folder := _out_folder()
	DirAccess.make_dir_recursive_absolute(folder)
	var f := FileAccess.open(folder.path_join(file), FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()


func _sample(version: int) -> String:
	var path := SAMPLES.path_join("sample_v%d.json" % version)
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


## The Auto-Cloud pattern written in docs/architecture/saves.md ("Pattern: `...`"), as a match() pattern.
func _autocloud_pattern() -> String:
	var doc := FileAccess.get_file_as_string("res://docs/architecture/saves.md")
	var at := doc.find("Auto-Cloud pattern: `")
	if at < 0:
		return ""
	var start := at + "Auto-Cloud pattern: `".length()
	return doc.substr(start, doc.find("`", start) - start)


func _remove_tree(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_remove_tree(dir.path_join(d))
	DirAccess.remove_absolute(dir)
