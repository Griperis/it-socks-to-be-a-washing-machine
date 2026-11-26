## Opening a present and the reveal (core/138, docs/architecture/gifts.md "Opening", "The Final screen"): the
## carrier's second left click opens their present; the Host removes it, gives the piece (or pays the refund into
## the Bank as a bonus once they owned every piece, Q2673) and counts it in the run's record; the opener sees the
## GiftReveal and their profile gets the piece; a Teammate's machine sees the box shake and pop where it is
## carried; the Final screen shows the piece and the two totals. The solo cases play the zoo holding the Gifts
## station (and the Stages station, whose run holds the RunRecord); the co-op case zoos holding only the Gifts
## station, each a machine of its own (tests/presents_test.gd's way).
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const GIFTS := "Stations/Gifts"
const KEEP := ["Gifts", "Stages"]
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact"]
const NET_WAIT_S := 20.0
const FPS := 60

var _holder: Node = null
var _zoo: Node3D = null
var _branches: Array[Node] = []
var _pace_next := 0
## Every sound played: [name, spatial].
var _heard: Array[Array] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player clicks Drop presents, picks up their present and left-clicks it: it goes, the rattle and the pick are heard, the reveal shows the box shaking (a click then does nothing and picks nothing up), then the piece on the turntable with its name, Rarity and \"New in your Wardrobe\"; a click closes it; the profile lists the piece, the record has the piece and one Gift opened; the Final screen shows the piece in the column and the two totals"},
		{"name": "refund", "method": "case_refund", "world": false,
				"title": "Q2673, Q2668: opening a present whose piece the player owns (they owned every piece) shows \"Already yours: +75 Coins\", the Bank pays 75 as a bonus and the HUD's Coins counter counts up by 75; no piece is won, one Gift is opened; the reveal closes by itself `preview` after the pop"},
		{"name": "coop", "method": "case_coop", "world": false,
				"title": "co-op (Gifts station, 0 ms): the Guest opens its present: the Host's machine plays the box's shake and pop where the Guest carries it (no reveal there), the Guest's machine shows the reveal; the Host's Roster owns the piece for the Guest"},
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
	if _holder != null:
		_holder.free()
		_holder = null
		_zoo = null
	_drop_branches()
	_heard.clear()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var present := await _carry_own_present()
	if present == null:
		return
	var piece := present.piece
	var collection := present.collection
	_check(not Worlds.profile().pieces.has(String(piece)), "the piece is new to the player (%s)" % piece)
	var record := _record()
	_check(record != null and record.gifts_opened == 0 and record.pieces.is_empty(), "nothing opened yet this run")
	var presents := _zoo.get_node(GIFTS + "/Presents") as Presents
	var spawned := _zoo.get_node(GIFTS + "/Spawned") as SpawnedParts
	var player := _player()
	_heard.clear()
	# The second left click opens it.
	await _press(&"pick")
	await _until(func() -> bool: return spawned.rows.is_empty(), "the present to be opened (its row gone)")
	await _physics_ticks(2)
	_check(spawned.node_of(1) == null, "its box is gone from the world")
	_check(_heard.any(func(h: Array) -> bool: return h[0] == &"gift_rattle"), "the rattle is heard (%s)" % [_heard])
	_check(_heard.any(func(h: Array) -> bool: return h[0] == &"pick"), "the pick cue is heard")
	_check(player.hands().carries(1) == null, "the Hands are empty")
	var reveal := presents.reveal()
	_check(reveal.is_open() and not reveal.revealed(), "the reveal shows the box shaking")
	_check(_find_opening() == null, "the opener's own world box does not shake as well")
	var box_anim := reveal.get_node("Root/Stage/Stage/Box/AnimationPlayer") as AnimationPlayer
	_check(box_anim.current_animation == &"open", "the reveal's box plays the open clip (%s)" % box_anim.current_animation)
	# A click during the shake does nothing and goes no further: aimed at Drop presents, it drops nothing.
	var button := (_zoo.get_node(GIFTS + "/Drop/Looks/Button") as Node3D).global_position
	await _stand_facing(Vector3(button.x, 0.0, button.z + 1.6), button)
	_check(player.aimed_part() is GiftSwitch, "the crosshair rests on Drop presents during the shake")
	await _press(&"pick")
	await _physics_ticks(2)
	_check(reveal.is_open() and not reveal.revealed(), "a click during the shake does not close it")
	_check(spawned.rows.is_empty(), "and goes no further: Drop presents dropped nothing (%d)" % spawned.rows.size())
	await _until(func() -> bool: return reveal.revealed(), "the box to pop")
	_check(reveal.piece_node() != null, "the piece stands on the turntable")
	var p := Wardrobe.of(piece)
	var lines := reveal.caption_lines()
	_check(lines[0] == Wardrobe.piece_name(piece), "the Caption names the piece (%s)" % [lines])
	_check(lines[1] == String(WardrobePiece.Rarity.keys()[p.rarity]).capitalize(), "and its Rarity (%s)" % lines[1])
	_check(lines[2] == "New in your Wardrobe", "and where it went (%s)" % lines[2])
	var outline := (reveal.get_node("Root/Caption/Name") as Label).get_theme_color(&"font_outline_color")
	_check(outline.is_equal_approx(Collections.of(collection).bow_colour().darkened(0.6)), "outlined in the bow colour darkened (%s)" % outline)
	_check(Worlds.profile().pieces.has(String(piece)), "the profile lists the piece")
	var key: Variant = RunTallies.of(record).key_of(1) if RunTallies.of(record) != null else 1
	_check(record.gifts_opened == 1 and record.pieces == [[key, String(piece)]], "the record has one Gift opened and the piece won (%s, %s)" % [record.gifts_opened, record.pieces])
	# A click closes it.
	await _physics_ticks(5)
	_check(player.aimed_part() is GiftSwitch, "the crosshair still rests on Drop presents")
	await _press(&"pick")
	await _physics_ticks(2)
	_check(not reveal.is_open(), "a click closes the reveal")
	_check(spawned.rows.is_empty(), "and goes no further: nothing dropped (%d)" % spawned.rows.size())
	# The Final screen: the piece in the opener's column, the two totals.
	var listing: Array[Dictionary] = [{"id": key, "name": "You", "colour": Color.WHITE}]
	var summary := FinalSummary.make([], listing, 60, 1, record.pieces, record.gifts_opened)
	var screen := LevelRuntime.of(_zoo).get_node("FinalScreen") as FinalScreen
	screen.open(summary)
	await _frames(2)
	screen.skip()
	await _until(func() -> bool: return screen.totals_shown() and screen.total_texts()[4].ends_with(" 1"), "the totals to count up")
	_check(screen.columns[0].pieces == PackedStringArray([String(piece)]) and screen.columns[0].piece_nodes().size() == 1,
			"the opener's column shows the piece (%s)" % [screen.columns[0].pieces])
	_check(screen.total_texts().has("Gifts opened 1") and screen.total_texts().has("Wardrobe pieces won 1"), "and the two totals (%s)" % [screen.total_texts()])
	screen.close()


func case_refund() -> void:
	await _build()
	var present := await _carry_own_present()
	if present == null:
		return
	# The player owns the piece already (as when they owned every piece, Q2673).
	Worlds.profile().unlock_piece(present.piece)
	var roster := LevelRuntime.of(_zoo).roster
	if roster != null and roster.id_of(1) != "":
		roster.parts.ask(Command.new(Roster.OWN, 1, roster.id, {"piece": present.piece}))
		await _until(func() -> bool: return roster.owned_of(roster.id_of(1)).has(String(present.piece)), "the Roster to own the piece")
	_check(present.owned_by(1).has(String(present.piece)), "the Host knows the player owns it")
	var bank := Bank.of(present)
	var before := bank.of_player(1)
	var counter := _player().get_node("Hud/MoneyCounters/Coins") as MoneyCounter
	var paid: Array = []
	bank.paid.connect(func(by: int, amount: int, _at: Node3D, bonus: bool) -> void: paid.append([by, amount, bonus]))
	var record := _record()
	await _press(&"pick")
	var reveal := (_zoo.get_node(GIFTS + "/Presents") as Presents).reveal()
	await _until(func() -> bool: return reveal.is_open(), "the reveal to open")
	_check(bank.of_player(1) == before + 75, "the Bank pays the refund, 75 (%d to %d)" % [before, bank.of_player(1)])
	_check(paid == [[1, 75, true]], "as a bonus: the counter counts up, no +N (%s)" % [paid])
	_check(counter.amount() < before + 75, "the counter has not shown it all at once (%d)" % counter.amount())
	await _until(func() -> bool: return counter.amount() == before + 75, "the Coins counter to count up by 75", 600)
	_check(reveal.caption_lines()[2] == "Already yours: +75 Coins", "the reveal says so (%s)" % reveal.caption_lines()[2])
	_check(record.gifts_opened == 1 and record.pieces.is_empty(), "one Gift opened, no piece won (%s)" % [record.pieces])
	var t := reveal.tuning
	await _until(func() -> bool: return reveal.revealed(), "the box to pop")
	# Measured on the reveal's own clock (seconds since it opened): the test's frames outrun the wall clock.
	await _until(func() -> bool: return float(reveal.get("_clock")) >= t.shake + t.preview - 0.3 or not reveal.is_open(), "the reveal to near its end", int((t.preview + 2.0) * FPS))
	_check(reveal.is_open(), "it still shows just before `preview` after the pop")
	await _until(func() -> bool: return not reveal.is_open(), "the reveal to close by itself", FPS)
	_check(float(reveal.get("_clock")) >= t.shake + t.preview, "`preview` after the pop (%.2f s)" % float(reveal.get("_clock")))


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
	var button := (host.get_node(GIFTS + "/Drop/Looks/Button") as Node3D).global_position
	await _aim_zoo(host, Vector3(button.x, 0.0, button.z + 1.6), button)
	await _wait(func() -> bool: return _zoo_player(host).aimed_part() is GiftSwitch, "the Host's crosshair on Drop presents")
	await _click(&"pick")
	await _wait(func() -> bool: return _spawned_of(host).rows.size() == 2 and _zoo_present(guest, 1) != null and _zoo_present(guest, 2) != null,
			"two presents on the Host and the Guest", FPS * 4)
	var roster := LevelRuntime.of(host).roster
	var guest_pid := roster.id_of(g)
	var mine := 0
	var theirs := 0
	for row: int in [1, 2]:
		var p := _zoo_present(guest, row).get_node("Present") as Present
		if p.for_player == guest_pid:
			mine = row
		else:
			theirs = row
	_check(mine != 0 and theirs != 0, "one for each player (%s, %s)" % [mine, theirs])
	if mine == 0 or theirs == 0:
		_drop_branches()
		return
	var piece := (_zoo_present(guest, mine).get_node("Present") as Present).piece
	_check(not roster.owned_of(guest_pid).has(String(piece)), "the Guest lacks the piece (%s)" % piece)
	var my_at := _zoo_present(guest, mine).global_position
	var their_at := _zoo_present(guest, theirs).global_position
	var tree := (host.get_node(GIFTS + "/OldTree") as Node3D).global_position
	await _aim_zoo(guest, _stand_by(my_at, their_at, tree), my_at + Vector3.UP * 0.17)
	await _wait(func() -> bool: return _zoo_player(guest).aimed_part() == _zoo_present(guest, mine).get_node("Carriable"), "the Guest's crosshair on its own present")
	await _click(&"pick")
	await _wait(func() -> bool: return (_zoo_present(host, mine).get_node("Carriable") as Carriable).holder == g, "the Guest carries its own", FPS * 3)
	await _paced_ticks(3)
	# The Guest's second left click opens it.
	await _click(&"pick")
	await _wait(func() -> bool: return _spawned_of(host).rows.size() == 1, "the Host to open the Guest's present", FPS * 3)
	_check(roster.owned_of(guest_pid).has(String(piece)), "the Host's Roster owns the piece for the Guest")
	await _wait(func() -> bool: return _opening_in(host) != null, "the Host's machine to show the box shaking", FPS * 2)
	var fx := _opening_in(host)
	var anim := fx.get_node("Looks/AnimationPlayer") as AnimationPlayer if fx != null else null
	_check(anim != null and anim.current_animation == &"open", "it plays the open clip")
	var avatar := _avatar(host, g)
	_check(fx != null and avatar != null and fx.global_position.distance_to(avatar.global_position) < 1.5,
			"where the Guest carries it (%s, avatar %s)" % [fx.global_position if fx != null else Vector3.ZERO, avatar.global_position if avatar != null else Vector3.ZERO])
	_check(fx != null and (fx.get_node("Looks/Pop") as GPUParticles3D).amount == 28, "its pop throws 28 specks")
	_check(not (host.get_node(GIFTS + "/Presents") as Presents).reveal().is_open(), "no reveal on the Host's machine")
	var guest_reveal := (guest.get_node(GIFTS + "/Presents") as Presents).reveal()
	await _wait(func() -> bool: return guest_reveal.is_open(), "the Guest's reveal to show", FPS * 2)
	_check(_opening_in(guest) == null, "the Guest's own world box does not shake")
	await _wait(func() -> bool: return _opening_in(host) == null, "the Host's shaking box to go once popped", FPS * 4)
	_drop_branches()


# --- Helpers: the solo zoo -----------------------------------------------------------------------

func _build() -> void:
	_holder = Node.new()
	_holder.name = "Holder"
	add_child(_holder)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder.add_child(_zoo)
	var button := (_zoo.get_node(GIFTS + "/Drop/Looks/Button") as Node3D).global_position
	_player().global_position = Vector3(button.x, 0.0, button.z + 1.6)
	await _until(func() -> bool: return _player().is_on_floor(), "the zoo to stand", 300)
	_player().capture_mouse()


## Clicks Drop presents, then picks up the player's own present by a left click; its Present, or null.
func _carry_own_present() -> Present:
	var button := (_zoo.get_node(GIFTS + "/Drop/Looks/Button") as Node3D).global_position
	await _stand_facing(Vector3(button.x, 0.0, button.z + 1.6), button)
	await _until(func() -> bool: return _player().aimed_part() is GiftSwitch, "the crosshair on Drop presents")
	await _press(&"pick")
	var spawned := _zoo.get_node(GIFTS + "/Spawned") as SpawnedParts
	await _until(func() -> bool: return spawned.node_of(1) != null, "a present to drop")
	var node := spawned.node_of(1) as Node3D
	var present := node.get_node("Present") as Present
	var carriable := node.get_node("Carriable") as Carriable
	await _physics_ticks(40)
	var at := node.global_position
	var tree := (_zoo.get_node(GIFTS + "/OldTree") as Node3D).global_position
	var away := Vector3(at.x - tree.x, 0.0, at.z - tree.z).normalized()
	await _stand_facing(at + away * 1.3, at + Vector3.UP * 0.17)
	await _until(func() -> bool: return _player().aimed_part() == carriable, "the crosshair on the present")
	await _press(&"pick")
	await _until(func() -> bool: return carriable.holder == 1, "the player to carry it")
	await _physics_ticks(3)
	_check(_player().hud().prompt_text().contains("Open"), "carried, the crosshair reads Open (%s)" % _player().hud().prompt_text())
	return present


func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	var head := player.get_node("Head") as Node3D
	var up := target - head.global_position
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _player() -> Player:
	return LevelRuntime.of(_zoo).player


func _record() -> RunRecord:
	return _zoo.get_tree().get_first_node_in_group(RunRecord.GROUP) as RunRecord


func _find_opening() -> PresentOpening:
	for node in _zoo.find_children("*", "Node3D", true, false):
		if node is PresentOpening and not node.is_queued_for_deletion():
			return node as PresentOpening
	return null


# --- Helpers: zoos holding only the Gifts station (tests/presents_test.gd's way) -----------------

func _opening_in(zoo: Node3D) -> PresentOpening:
	for node in zoo.get_node(GIFTS).get_children():
		if node is PresentOpening and not node.is_queued_for_deletion():
			return node as PresentOpening
	return null


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
## of sight, as far from the Old Tree stand-in `tree` as can be.
static func _stand_by(target: Vector3, other: Vector3, tree: Vector3) -> Vector3:
	var to_other := Vector2(other.x - target.x, other.z - target.z).normalized()
	var best := target + Vector3(0.0, 0.0, 1.3)
	var best_far := -1.0
	for k in 16:
		var d := Vector2.from_angle(TAU * k / 16.0)
		if d.dot(to_other) > 0.3:
			continue
		var at := target + Vector3(d.x, 0.0, d.y) * 1.3
		var far := Vector2(at.x - tree.x, at.z - tree.z).length()
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


func _spawned_of(zoo: Node3D) -> SpawnedParts:
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
