## Stage presents under the Old Tree (core/137, docs/architecture/gifts.md "A Collection completes", "Stage
## presents"): a Collection completing in a Stage, the Stage's end dropping each player a present wrapped in it at
## the level's PresentSpot, picked up and put down by its own player only, the G1 draw (Q2673), the Machine Part's
## pop clear of lying presents, a save and a late joiner. Most cases play the Stages station's mini run on a floor
## with the game's player and a Parts (a Host of one), as tests/stages_test.gd does, with a plan of 1 Pair a Drawer
## and six starting Rows so Cabinet A's whole Collection fits Stage 1; the co-op case plays zoos holding only the
## Gifts station, each a machine of its own (tests/spawned_parts_test.gd's way); the house case the house.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const MINI := "res://game/zoo/stages/mini_plan.tres"
const PLAYER := "res://game/player/player.tscn"
const ZOO := "res://game/zoo/zoo.tscn"
const HOUSE := "res://game/house/house.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward"]
## The station's Simple Socks, by id (the order of its SockSpots): Pairs of Designs 0..5.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)
const GIFTS := "Stations/Gifts"
const NET_WAIT_S := 20.0
const FPS := 60

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _stages: Stages = null
var _presents: Presents = null
var _spawned: SpawnedParts = null
var _a: Cabinet = null
var _branches: Array[Node] = []
var _pace_next := 0
## Every sound played: [name, spatial].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player clicks Cabinet A's last Pair in, its Collection completes (noted, tallied) and the Stage ends: a present wrapped in A's Collection drops at the PresentSpot for the player; aimed it reads \"[LMB] Pick up\", a left click carries it (\"[LMB] Open\", \"Drop [RMB]\", pick heard), a right click puts it down (drop heard)"},
		{"name": "no_collection", "method": "case_no_collection", "world": false,
				"title": "a Stage that completes no Collection (the mini run's 2 Pairs a Drawer: Cabinet A two Rows of six) drops nothing"},
		{"name": "owned_whole", "method": "case_owned_whole", "world": false,
				"title": "G1 (Q2673): a player who owns or has waiting every piece of the completed Collection gets a lacked piece of another unlocked one, the box wrapped in the completed one; lacking none at all, any piece of the completed one; a held-back Collection gives nothing"},
		{"name": "pop_clear", "method": "case_pop_clear", "world": false,
				"title": "batch A's carried item (CA:439-479): the Machine Part popped while a present lies on its spot lands on the nearest hex spot clear of it"},
		{"name": "save_load", "method": "case_save_load", "world": false,
				"title": "a save with a present lying and one carried loads both, the carried one laid where it last lay, each with its player, piece and Collection; the Stage's completed list is kept"},
		{"name": "coop", "method": "case_coop", "world": false,
				"title": "co-op (Gifts station, 0 ms): \"Drop presents\" gives one each; the Guest's crosshair skips the Host's present and a click on it does nothing; the Guest carries its own; each lying present is labelled with its player; a late joiner sees both"},
		{"name": "house", "method": "case_house", "world": false,
				"title": "reachable in the main scene: the house's PresentSpot stands at the Old Tree's foot on clear floor, and a house Stage that completed a Collection drops the present there"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _on_played(sound: StringName, spatial: bool, _at: Vector3, _bus: StringName) -> void:
	_heard.append([sound, spatial])


func _before_case() -> void:
	wait_floor_s = 0.0
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_drop_branches()
	_heard.clear()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build(_whole_plan())
	var noted: Array = []
	_stages.collection_completed.connect(func(c: StringName, by: int) -> void: noted.append([c, by]))
	var tally := Worlds.profile().tally(PlayerProfile.COLLECTIONS_COMPLETED)
	_check(_stages.bar_numbers() == Vector2i(0, 6), "Stage 1 counts Cabinet A's six Rows of one Pair (%s)" % _stages.bar_numbers())
	for i in 5:
		await _shelve_pair(SIMPLE[i], i)
	_check(_spawned.rows.is_empty() and _stages.completed.is_empty(), "nothing is complete before the last Pair")
	# The last Pair, paired in the Hands, goes in by the player's own click on the drawer.
	for sock: int in [SIMPLE[5], SIMPLE[5] + 1]:
		_hands.clock += 10.0
		_hands.pick(1, sock)
		await _physics_ticks(1)
	_check(_mess.is_pair(SIMPLE[5]), "the last Pair is in the Hands")
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 1))
	await _press(&"pick")
	await _until(func() -> bool: return _a.shelved().size() == 6, "the last Pair to be shelved")
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	_check(noted == [[_a.collection, 1]], "collection_completed(A's Collection, the shelver) fired once (%s)" % [noted])
	_check(_stages.completed.size() == 1 and _stages.completed[0] == _a.collection, "the Stage keeps it completed (%s)" % [_stages.completed])
	_check(Worlds.profile().tally(PlayerProfile.COLLECTIONS_COMPLETED) == tally + 1, "the Lifetime Collections completed tally counts it")
	await _until(func() -> bool: return _present_node(1) != null, "a present to drop")
	_check(_spawned.rows.size() == 1, "one present: one player, one Collection (%d)" % _spawned.rows.size())
	var node := _present_node(1)
	var present := node.get_node("Present") as Present
	var carriable := node.get_node("Carriable") as Carriable
	var spot := (_station.get_node("Run/PresentSpot") as Node3D).global_position
	_check(present.collection == _a.collection, "wrapped in A's Collection (%s)" % present.collection)
	_check(present.for_player == "1" and present.is_for(1), "for the player (%s)" % present.for_player)
	_check(PresentDraw.pieces_of(_a.collection).any(func(p: WardrobePiece) -> bool: return p.id == present.piece),
			"holding a piece of A's Collection the player lacks (%s)" % present.piece)
	_check(_flat(node.global_position).distance_to(_flat(spot)) < 0.05, "at the PresentSpot (%s, spot %s)" % [node.global_position, spot])
	var paper := (node.get_node("Looks/Box/Box") as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
	var col := Collections.of(_a.collection)
	_check(paper != null and (paper.get_shader_parameter(&"paper") as Color).is_equal_approx(col.paper_colour()),
			"its paper is the Collection's (%s)" % [paper.get_shader_parameter(&"paper") if paper != null else null])
	_check(paper != null and paper.get_shader_parameter(&"icon") == col.icon, "printed with the Collection's icon")
	var anim := node.get_node("Looks/AnimationPlayer") as AnimationPlayer
	_check(anim.current_animation == Present.DROP, "it drops in (%s)" % anim.current_animation)
	await _until(func() -> bool: return anim.current_animation == Present.LYING, "it to lie turning once it landed")
	_check((node.get_node("Looks/Glow") as Node3D).visible and (node.get_node("Looks/Sparkle") as GPUParticles3D).emitting, "lying, it glows and sparkles")
	_check(not (node.get_node("Looks/Tag") as Node3D).visible, "solo, no label")
	# Aimed with empty Hands: "[LMB] Pick up"; a left click carries it.
	_stand(_station.to_local(spot + Vector3(0.0, 0.0, 1.3)))
	await _aim(_player, node.global_position + Vector3.UP * 0.17)
	await _until(func() -> bool: return _player.aimed_part() == carriable, "the crosshair on the present")
	await _physics_ticks(2)
	_check(_player.hud().prompt_text().contains("Pick up"), "aimed, the crosshair reads Pick up (%s)" % _player.hud().prompt_text())
	_heard.clear()
	await _press(&"pick")
	await _until(func() -> bool: return carriable.holder == 1, "the player to carry it")
	await _physics_ticks(2)
	_check(_player.hud().prompt_text().contains("Open"), "carried, the crosshair reads Open (%s)" % _player.hud().prompt_text())
	_check(_player.hud().hints_text().contains(Prompts.DROP) and not _player.hud().hints_text().contains("Throw"), "the corner says Drop, never Throw (%s)" % _player.hud().hints_text())
	_check(_heard.any(func(h: Array) -> bool: return h[0] == &"pick"), "the pick is heard (%s)" % [_heard])
	_check(not (node.get_node("Looks/Glow") as Node3D).visible, "carried, its glow is off")
	# A right click puts it down at the crosshair.
	var down := spot + Vector3(0.6, 0.0, 0.6)
	await _aim(_player, down)
	_heard.clear()
	await _press(&"drop_throw")
	await _until(func() -> bool: return carriable.holder == 0, "the right click to put it down")
	_check(_flat(node.global_position).distance_to(_flat(down)) < 0.2, "where the crosshair was (%s, aimed %s)" % [node.global_position, down])
	_check(_heard.any(func(h: Array) -> bool: return h[0] == &"drop"), "the put down is heard (%s)" % [_heard])


# --- Rules ---------------------------------------------------------------------------------------

func case_no_collection() -> void:
	await _build()
	for i in 4:
		await _shelve_pair(SIMPLE[i], 0 if i < 2 else 1)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	await _physics_ticks(5)
	_check(_stages.completed.is_empty(), "no Collection completed (%s)" % [_stages.completed])
	_check(_spawned.rows.is_empty(), "no present dropped (%d)" % _spawned.rows.size())


func case_owned_whole() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var simple := _ids(PresentDraw.pieces_of(&"simple"))
	var sport := _ids(PresentDraw.pieces_of(&"sport"))
	_check(simple.size() == 6 and sport.size() == 6, "Simple and Sport have six pieces each (%d, %d)" % [simple.size(), sport.size()])
	var completed: Array[StringName] = [&"simple"]
	var unlocked: Array[StringName] = [&"simple", &"sport"]
	for n in 10:
		var got := PresentDraw.draw(completed, [{"id": "a", "owned": PackedStringArray()}], {}, unlocked, 0.25, rng)
		_check(got.size() == 1 and simple.has(String(got[0]["piece"])) and got[0]["collection"] == &"simple", "lacking pieces: one of Simple's (%s)" % [got])
	var whole := PresentDraw.draw(completed, [{"id": "a", "owned": simple}], {}, unlocked, 0.25, rng)
	_check(sport.has(String(whole[0]["piece"])), "owning Simple whole: a piece of Sport (%s)" % whole[0]["piece"])
	_check(whole[0]["collection"] == &"simple", "still wrapped in Simple")
	var waits := PresentDraw.draw(completed, [{"id": "a", "owned": PackedStringArray()}], {"a": simple}, unlocked, 0.25, rng)
	_check(sport.has(String(waits[0]["piece"])), "Simple all waiting in boxes counts as had: a piece of Sport (%s)" % waits[0]["piece"])
	var everything := simple.duplicate()
	everything.append_array(sport)
	var none := PresentDraw.draw(completed, [{"id": "a", "owned": everything}], {}, unlocked, 0.25, rng)
	_check(simple.has(String(none[0]["piece"])), "lacking nothing: any piece of Simple, its opening refunds (%s)" % none[0]["piece"])
	var two := PresentDraw.draw(completed, [{"id": "a", "owned": PackedStringArray()}, {"id": "b", "owned": simple}], {}, unlocked, 0.25, rng)
	_check(two.size() == 2 and two[0]["for"] == "a" and two[1]["for"] == "b", "one present per player, in their order (%s)" % [two])
	var lost: Array[StringName] = [&"lost"]
	_check(PresentDraw.draw(lost, [{"id": "a", "owned": PackedStringArray()}], {}, unlocked, 0.25, rng).is_empty(), "a held-back Collection gives no present (Q2675)")


func case_pop_clear() -> void:
	await _build(_whole_plan())
	for i in 5:
		await _shelve_pair(SIMPLE[i], i)
	# Where the Part would pop, a present lies already.
	var part := _stages.machine_part()
	var pop := part.pop_changes(_a)
	var base := part.get_parent().get_parent() as Node3D
	var would := base.global_transform * ((pop.values()[0] as Dictionary)["at"] as Vector3)
	var states := {"Carriable": {"holder": 0, "at": would, "yaw": 0.0}, "Present": {"for_player": "1", "piece": &"sock_hat", "collection": &"simple"}}
	_parts.apply({"ok": true, "changes": {_spawned.id: _spawned.add_patch(Presents.SCENE, states)}})
	await _physics_ticks(2)
	_check(_present_node(1) != null, "a present lies on the Part's spot")
	await _shelve_pair(SIMPLE[5], 5)
	await _until(func() -> bool: return _stages.phase == Stages.Phase.PART_OUT, "the Stage to complete")
	await _physics_ticks(2)
	var lies := (part.get_parent() as Node3D).global_position
	var apart := _presents.tuning.apart
	for spot in _presents.lying_spots():
		_check(_flat(lies).distance_to(_flat(spot)) >= apart * Presents.CLEAR - 0.001, "the Part lies clear of the present at %s (%s)" % [spot, lies])
	_check(_flat(lies).distance_to(_flat(would)) < apart * 1.2, "on the nearest hex spot (%.2f m from where it would have)" % _flat(lies).distance_to(_flat(would)))


func case_save_load() -> void:
	await _build(_whole_plan())
	for i in 6:
		await _shelve_pair(SIMPLE[i], i)
	await _until(func() -> bool: return _present_node(1) != null, "the Stage's present")
	# A second present, and the player carries the first.
	var more: Array[StringName] = [&"patterns"]
	var drop := _presents.drop(more)
	_parts.apply({"ok": true, "changes": drop["changes"]})
	await _until(func() -> bool: return _present_node(2) != null, "a second present")
	var first := _present_node(1).get_node("Carriable") as Carriable
	var lay := first.at
	first.pick(1)
	await _physics_ticks(2)
	_check(first.holder == 1, "the first is carried")
	var lying_at := _present_node(2).global_position
	var want := {1: (_present_node(1).get_node("Present") as Present).state(), 2: (_present_node(2).get_node("Present") as Present).state()}
	var saved := _roundtrip(_parts.save_snapshot())
	var versions := _parts.save_versions()
	_check(int(versions.get(String(_stages.id), 0)) == 2, "Stages saves at version 2 (%s)" % versions.get(String(_stages.id)))
	await _build(_whole_plan())
	_parts.load_save(saved, versions, "host")
	await _physics_ticks(3)
	for row: int in [1, 2]:
		var node := _present_node(row)
		_check(node != null, "present %d is spawned again" % row)
		if node == null:
			continue
		_check((node.get_node("Present") as Present).state() == want[row], "present %d keeps its player, piece and Collection (%s)" % [row, (node.get_node("Present") as Present).state()])
		_check((node.get_node("Carriable") as Carriable).holder == 0, "present %d lies (nothing is held offline)" % row)
	if _present_node(1) != null and _present_node(2) != null:
		_check(_present_node(1).global_position.distance_to(lay) < 0.01, "the carried one lies where it last lay (%s, %s)" % [_present_node(1).global_position, lay])
		_check(_present_node(2).global_position.distance_to(lying_at) < 0.01, "the lying one where it lay")
	_check(_stages.completed.size() == 1 and _stages.completed[0] == _a.collection, "the Stage's completed list is kept (%s)" % [_stages.completed])


# --- Co-op ---------------------------------------------------------------------------------------

func case_coop() -> void:
	wait_floor_s = NET_WAIT_S
	var host := _branch("Host")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	var guest := await _join()
	var g := _zoo_player(guest).player_id()
	# The Host clicks "Drop presents".
	var button := (host.get_node(GIFTS + "/Drop/Looks/Button") as Node3D).global_position
	await _aim_zoo(host, Vector3(button.x, 0.0, button.z + 1.6), button)
	await _wait(func() -> bool: return _zoo_player(host).aimed_part() is GiftSwitch, "the Host's crosshair on Drop presents")
	await _click(&"pick")
	await _wait(func() -> bool: return _gift_spawned(host).rows.size() == 2 and _zoo_present(guest, 1) != null and _zoo_present(guest, 2) != null,
			"two presents on the Host and the Guest", FPS * 4)
	var host_pid := LevelRuntime.of(host).roster.id_of(Parts.HOST)
	var guest_pid := LevelRuntime.of(host).roster.id_of(g)
	var mine := 0
	var theirs := 0
	for row: int in [1, 2]:
		var p := _zoo_present(guest, row).get_node("Present") as Present
		if p.for_player == guest_pid:
			mine = row
		elif p.for_player == host_pid:
			theirs = row
	_check(mine != 0 and theirs != 0, "one for each player (%s, %s)" % [mine, theirs])
	if mine == 0 or theirs == 0:
		_drop_branches()
		return
	await _paced_ticks(2)
	for row: int in [1, 2]:
		_check((_zoo_present(host, row).get_node("Carriable") as Carriable).holder == 0, "present %d lies untouched after the drop (holder %d, guest captured %s)" % [row, (_zoo_present(host, row).get_node("Carriable") as Carriable).holder, _zoo_player(guest).get("_captured")])
	var tag := _zoo_present(host, mine).get_node("Looks/Tag") as Label3D
	_check(tag.visible and tag.text == LevelRuntime.of(host).roster.name_of(g), "the Guest's present is labelled with its name (%s)" % tag.text)
	# The Guest aims at the Host's present: not aimed, a click does nothing.
	var their_at := _zoo_present(guest, theirs).global_position
	var my_at := _zoo_present(guest, mine).global_position
	var tree := (host.get_node(GIFTS + "/OldTree") as Node3D).global_position
	await _aim_zoo(guest, _stand_by(their_at, my_at, tree), their_at + Vector3.UP * 0.17)
	_check(_zoo_player(guest).aimed_part() == null, "the Guest's crosshair skips the Host's present (%s)" % _zoo_player(guest).aimed_part())
	_check(_zoo_player(guest).aimed_outline == null, "no outline on it")
	await _click(&"pick")
	await _paced_ticks(20)
	_check((_zoo_present(host, theirs).get_node("Carriable") as Carriable).holder == 0, "a click on it does nothing")
	_check(_zoo_player(guest).hud().prompt_text() == "", "and nothing on the crosshair's row (%s)" % _zoo_player(guest).hud().prompt_text())
	# Its own: carried.
	await _aim_zoo(guest, _stand_by(my_at, their_at, tree), my_at + Vector3.UP * 0.17)
	await _wait(func() -> bool: return _zoo_player(guest).aimed_part() == _zoo_present(guest, mine).get_node("Carriable"), "the Guest's crosshair on its own present")
	await _click(&"pick")
	await _wait(func() -> bool: return (_zoo_present(host, mine).get_node("Carriable") as Carriable).holder == g and (_zoo_present(guest, mine).get_node("Carriable") as Carriable).holder == g,
			"the Guest carries its own on both", FPS * 3)
	await _paced_ticks(2)
	_check(not (_zoo_present(host, mine).get_node("Looks/Tag") as Node3D).visible, "carried, its label hides")
	# A late joiner sees both.
	var late := await _join()
	await _wait(func() -> bool: return _zoo_present(late, 1) != null and _zoo_present(late, 2) != null, "the late joiner gets both presents", FPS * 5)
	_check(_gift_spawned(late).rows.size() == 2, "two rows on the late joiner")
	_drop_branches()


# --- The house -----------------------------------------------------------------------------------

func case_house() -> void:
	SockGenerator.start_all = true
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	add_child(_level)
	var rt := LevelRuntime.of(_level)
	var stages := _level.get_node("Run/Stages") as Stages
	await _until(rt.loading.is_lifted, "the house's Socks to be laid", 900, 20.0)
	await _until(func() -> bool: return stages.stage == 0, "the run to start", 3000, 20.0)
	var spot := (_level.get_node("Run/PresentSpot") as Node3D).global_position
	var tree := (_level.get_node("Furniture/OldTree") as Node3D).global_position
	_check(_flat(spot).distance_to(_flat(tree)) < 1.5, "the PresentSpot stands at the Old Tree's foot (%.2f m)" % _flat(spot).distance_to(_flat(tree)))
	# The old clear test (CA:118-133): a floor disc of 0.4 m, 0.6 m high, clear of every collider.
	var disc := BoxShape3D.new()
	disc.size = Vector3(0.8, 0.6, 0.8)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = disc
	query.transform = Transform3D(Basis.IDENTITY, spot + Vector3.UP * 0.33)
	query.collision_mask = Mess.LAYER_HOUSE
	var hits := _level.get_world_3d().direct_space_state.intersect_shape(query, 8)
	_check(hits.is_empty(), "on clear floor: nothing of the house within 0.4 m (%s)" % [hits.map(func(h: Dictionary) -> String: return str(h["collider"].get_path()))])
	var floor_hit := PhysicsQueries.ray(_level, spot + Vector3.UP * 0.5, spot + Vector3.DOWN * 0.5, Mess.LAYER_HOUSE)
	_check(not floor_hit.is_empty() and absf((floor_hit["position"] as Vector3).y - spot.y) < 0.05, "on the floor (%s)" % [floor_hit.get("position")])
	# A Stage that completed Simple ends: its present drops there.
	rt.parts.apply({"ok": true, "changes": {stages.id: {"completed": [&"simple"] as Array[StringName]}}})
	rt.parts.ask(Command.new(&"complete_now", Parts.HOST, stages.id, {}))
	var spawned := _level.get_node("Run/Spawned") as SpawnedParts
	await _until(func() -> bool: return spawned.node_of(1) != null, "the present to drop in the house")
	var node := spawned.node_of(1) as Node3D
	_check(_flat(node.global_position).distance_to(_flat(spot)) < 0.05, "under the Old Tree (%s, spot %s)" % [node.global_position, spot])
	_check((node.get_node("Present") as Present).collection == &"simple", "wrapped in Simple")


# --- Helpers: the Stages station ----------------------------------------------------------------

## The mini run with 1 Pair a Drawer and six starting Rows: Cabinet A's whole Collection is Stage 1's bar.
func _whole_plan() -> StagePlan:
	var plan := (load(MINI) as StagePlan).duplicate(true) as StagePlan
	plan.pairs_per_drawer = 1
	plan.start_rows = 6
	return plan


func _build(plan: StagePlan = null) -> void:
	if _level != null:
		_level.free()
		_level = null
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
	if plan != null:
		(_station.get_node("Run/Stages") as Stages).plan = plan
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
	_stages = _station.get_node("Run/Stages") as Stages
	_presents = _station.get_node("Run/Presents") as Presents
	_spawned = _station.get_node("Run/Spawned") as SpawnedParts
	_a = _station.get_node("CabinetA/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and _stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")
	await _until(func() -> bool: return _stages.due.is_empty(), "Stage 1's Socks to be laid")


## Pairs Sock `sock` with its mate by the Hands' Command and shelves the Pair by Cabinet A's click at `drawer`.
func _shelve_pair(sock: int, drawer: int) -> void:
	for s: int in [sock, sock + 1]:
		_hands.clock += 10.0
		_hands.pick(1, s)
		await _physics_ticks(1)
	_check(_mess.is_pair(sock), "Socks %d and %d fused into a Pair" % [sock, sock + 1])
	var before := _a.shelved().size()
	_a.click(1, drawer)
	await _until(func() -> bool: return _a.shelved().size() == before + 1, "the Pair %d to be shelved" % sock)
	await _physics_ticks(1)


func _present_node(row: int) -> Node3D:
	return _spawned.node_of(row) as Node3D if _spawned != null else null


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


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func _ids(pieces: Array[WardrobePiece]) -> PackedStringArray:
	var out := PackedStringArray()
	for p in pieces:
		out.append(String(p.id))
	return out


# --- Helpers: zoos holding only the Gifts station (tests/spawned_parts_test.gd's way) -------------

func _join() -> Node3D:
	var host := _in_branch(_branches[0])
	var label := "Guest%d" % _branches.size()
	var guest := _branch(label)
	await _frames(2)
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % host.session.port]) == OK, "%s joins" % label)
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined"), "%s to be welcomed" % label, FPS * 10)
	await _wait(func() -> bool: return _avatar(host.get_parent(), gs.me()) != null and _avatar(guest, Parts.HOST) != null, "the Host's and %s's avatars of each other" % label, FPS * 5)
	return guest


## Where to stand 1.3 m from the present at `target` to aim at it: the other present `other` not in the line
## of sight, as far from the Old Tree stand-in `tree` as can be (the heap turns at random).
static func _stand_by(target: Vector3, other: Vector3, tree: Vector3) -> Vector3:
	var to_other := _flat(other - target).normalized()
	var best := target + Vector3(0.0, 0.0, 1.3)
	var best_far := -1.0
	for k in 16:
		var d := Vector2.from_angle(TAU * k / 16.0)
		if d.dot(to_other) > 0.3:
			continue
		var at := target + Vector3(d.x, 0.0, d.y) * 1.3
		var far := _flat(at - tree).length()
		if far > best_far:
			best_far = far
			best = at
	return best


func _click(action: StringName) -> void:
	Input.action_press(action)
	await _paced_ticks(2)
	Input.action_release(action)
	await _paced_ticks(1)


## Stands `zoo`'s player at `feet` looking at `target`; only it has the mouse.
func _aim_zoo(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := _zoo_player(zoo)
	for other: Node in _branches:
		var p := _in_branch(other).player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	_place(zoo, feet, target)
	var last := player.global_position
	for _i in FPS * 2:
		await _paced()
		var now := player.global_position
		if player.is_on_floor() and now.distance_to(last) < 0.0005:
			break
		last = now
	_place(zoo, Vector3(feet.x, player.global_position.y, feet.z), target)
	await _paced_ticks(2)
	var host_net := _in_branch(_branches[0]).net
	var me := player.player_id()
	await _wait(func() -> bool:
		var at: Variant = host_net.where(me)
		return not (at is Vector3) or (at as Vector3).distance_to(player.global_position) < 0.1,
			"the Host to have the player where it stands", FPS * 2)


func _place(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := _zoo_player(zoo)
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	var head := player.get_node("Head") as Node3D
	var up := target - (feet + Vector3.UP * head.position.y)
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	player.reset_physics_interpolation()


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced_ticks(n: int) -> void:
	for _i in n:
		await _paced()


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _gift_spawned(zoo: Node3D) -> SpawnedParts:
	return zoo.get_node(GIFTS + "/Spawned") as SpawnedParts


func _zoo_present(zoo: Node3D, row: int) -> Node3D:
	return zoo.get_node_or_null(GIFTS + "/Spawned/Present%d" % row) as Node3D


func _zoo_player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


func _avatar(zoo: Node, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a) and not a.is_queued_for_deletion():
			return a
	return null


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
		if String(station.name) != "Gifts":
			station.get_parent().remove_child(station)
			station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	for node in _branches:
		var session := _in_branch(node).session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
