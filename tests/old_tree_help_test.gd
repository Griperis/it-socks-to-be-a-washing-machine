## The Old Tree's help (core/133, docs/architecture/economy.md "The Old Tree talks"): in the house, the player walks
## up to the tree and hears the Stage's progress; an idle spell names a Cabinet with a Row to fill; the Throw tip
## once per run and again after a New Game; the Fix comments and the story beats; the data.
extends TestSuite

const HOUSE := "res://game/house/house.tscn"
const TREE_AT := ^"Furniture/OldTree"
const STAGE_HALF := &"tree_stage_half"
const CABINET_LAUNDRY := &"tree_cabinet_laundry"
const TIP_THROW := &"tree_tip_throw"
const PEACE := &"tree_peace"

var _holder: Node = null
var _level: Node3D = null
var _rt: LevelRuntime = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path_stage_half", "method": "case_stage_half", "world": false,
				"title": "real path: in the house, with Stage 1's bar filled past half, the player walks to the Old Tree and its \"stage_half\" subtitle shows, said once for the Stage"},
		{"name": "hint_cabinet", "method": "case_hint_cabinet", "world": false,
				"title": "idle near the tree with a Cabinet's Row unfilled and hint_chance 1 gives that Cabinet's room line; with a loose Sock in the Hands the hint is the floor of its Mate"},
		{"name": "tips", "method": "case_tips", "world": false,
				"title": "the Throw tip is said once per player per run and again after a New Game; the Part tip waits until Stage 1 completes"},
		{"name": "beats", "method": "case_beats", "world": false,
				"title": "a Fix comment comes into the next Stage to a player near and lapses unheard; the peace beat skips the cooldown after the beat gap; grumbles only while the washer is broken"},
		{"name": "data", "method": "case_data", "world": false,
				"title": "every help trigger has its lines, the eight Cabinets and four Stages name theirs, and the story beats wait"},
	]


func _before_case() -> void:
	for a: StringName in [&"move_forward", &"move_back"]:
		Input.action_release(a)
	_free()


# --- Cases ---------------------------------------------------------------------------------------

func case_stage_half() -> void:
	await _house_up()
	var tree := _tree()
	_keep_throw_tip_said(tree)
	var stages := OldTreeHelp.stages_of(tree)
	await _until(func() -> bool: return int(tree.said.get("stage", -1)) == stages.stage, "the Host to mark Stage 1's bar")
	_check(int(tree.said.get("step", -2)) == -1, "an empty bar is marked below every threshold (%s)" % [tree.said])
	_fill(stages, 0.6)
	await _walk_up(tree)
	var first := await _said(tree, OldTree.FIRST)
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the first line to end", 900)
	_pass_cooldown(tree)
	var half := await _said(tree, STAGE_HALF)
	await _until(func() -> bool: return Voices.subtitle_text(&"old_tree") == _first_text(half), "the stage_half subtitle to show")
	_check(int(tree.said.get("step", -1)) == 0 and first != half, "the threshold is kept for the Stage (%s)" % [tree.said])
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the line to end", 900)
	_pass_cooldown(tree)
	var serial := tree.serial
	await _physics_ticks(240)
	_check(tree.serial == serial, "the same threshold is not said twice in a Stage")


func case_hint_cabinet() -> void:
	await _house_up()
	var tree := _tree()
	_keep_throw_tip_said(tree)
	var stages := OldTreeHelp.stages_of(tree)
	var rooms := OldTreeHelp.needy_cabinets(stages)
	_check(rooms.size() == 1 and rooms[0].id == CABINET_LAUNDRY, "Stage 1's bar has only the laundry's Row to fill (%s)" % [rooms.map(func(t: VoiceTrigger) -> StringName: return t.id)])
	var t := tree.tuning.duplicate() as OldTreeTuning
	t.hint_chance = 1.0
	t.grumble_chance = 0.0
	t.idle_seconds = 1.0
	tree.tuning = t
	var stages_node := stages
	_rt.parts.apply(stages_node.lay_first_answer())
	await _until(func() -> bool: return _hands().mess.count() > 0, "Stage 1's Socks to lie")
	var floors := OldTreeHelp.mate_hint(stages, _hands(), _lights(), 1, tree.roll)
	_check(floors != null and floors.id == &"tree_hint_basement", "a loose Sock of the bar's Collection lies in the basement: its floor, never a spot (%s)" % [floors.id if floors != null else null])
	await _hold_loose_sock(tree)
	floors = OldTreeHelp.mate_hint(stages, _hands(), _lights(), 1, tree.roll)
	_check(floors != null and floors.id == &"tree_hint_basement", "with a loose Sock in the Hands: its Mate's floor (%s)" % [floors.id if floors != null else null])
	# The idle spell's roll: a seed whose first pick is the Cabinet (it may be the Mate's floor, half the time).
	var seed_found := -1
	for s in range(1, 200):
		tree.roll.seed = s
		if tree.spell() == CABINET_LAUNDRY:
			seed_found = s
			break
	_check(seed_found > 0, "an idle spell can name the Cabinet's room")
	await _walk_up(tree)
	await _said(tree, OldTree.FIRST)
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the first line to end", 900)
	tree.roll.seed = seed_found
	_pass_cooldown(tree)
	await _said(tree, CABINET_LAUNDRY)
	var line := Voices.book().find_line(&"old_tree", tree.line)
	_check(line.id.begins_with("tree_cabinet_laundry"), "the laundry's room line (%s)" % line.id)


func case_tips() -> void:
	await _house_up()
	var tree := _tree()
	var stages := OldTreeHelp.stages_of(tree)
	var key := str(_key(tree))
	await _until(func() -> bool: return int(tree.said.get("stage", -1)) == stages.stage, "the Host to mark Stage 1's bar")
	await _walk_up(tree)
	await _said(tree, OldTree.FIRST)
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the first line to end", 900)
	_pass_cooldown(tree)
	await _said(tree, TIP_THROW)
	_check((tree.tips.get(key, []) as Array).has("tree_tip_throw"), "the tip is kept for the player (%s)" % [tree.tips])
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the tip to end", 900)
	_pass_cooldown(tree)
	var tip_part := _parts().answer(Command.new(OldTree.TALK, 1, tree.id, {"trigger": String(&"tree_tip_part")}))
	_check(not tip_part["ok"], "the Part tip waits until Stage 1 completes")
	var serial := tree.serial
	await _physics_ticks(120)
	var said := Voices.book().find_line(&"old_tree", tree.line)
	_check(tree.serial == serial or not said.has_trigger(TIP_THROW), "the Throw tip is not said again this run")
	# Stage 1 completes: its Part is out, the Part tip is due, once.
	_rt.parts.apply({"ok": true, "changes": {stages.id: {"phase": Stages.Phase.PART_OUT}}})
	await _said(tree, &"tree_tip_part")
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the tip to end", 900)
	# A New Game: what is once per run starts again.
	_rt.parts.ask(Command.new(&"new_run", Parts.HOST, stages.id, {"pairs_per_drawer": 25}))
	await _until(func() -> bool: return tree.tips.is_empty(), "a New Game to start the tips again")
	await _until(func() -> bool: return stages.stage == 0 and stages.phase == Stages.Phase.PLAYING, "the new run")
	_pass_cooldown(tree)
	await _until(func() -> bool: return int(tree.said.get("stage", -1)) == stages.stage, "the Host to mark the new bar")
	await _said(tree, TIP_THROW)


func case_beats() -> void:
	await _house_up()
	var tree := _tree()
	_keep_throw_tip_said(tree)
	var stages := OldTreeHelp.stages_of(tree)
	var t := tree.tuning.duplicate() as OldTreeTuning
	t.beat_chance = 1.0
	t.beat_delay = Vector2(0.5, 0.6)
	t.beat_hold = 3.0
	t.beat_gap = 0.5
	t.grumble_chance = 1.0
	t.hint_chance = 0.0
	tree.tuning = t
	# A grumble only while the washer is broken.
	var broken := _parts().answer(Command.new(OldTree.TALK, 1, tree.id, {"trigger": String(OldTreeHelp.GRUMBLE)}))
	tree.last_at = -INF
	_check(broken["ok"], "the washer broken: a grumble may be asked")
	await _until(func() -> bool: return int(tree.said.get("stage", -1)) == stages.stage, "the Host to mark Stage 1's bar")
	# A Fix opens the next floor: one comment, some time into it; unheard, it lapses.
	stages.floor_opened.emit(1, [])
	await _until(func() -> bool: return str(tree.beat.get("comment", "")) != "", "the Fix comment to come due")
	var comment := str(tree.beat["comment"])
	_check(comment in ["tree_part_basement", "tree_floor_ground"], "a Part or a floor comment (%s)" % comment)
	await _until(func() -> bool: return str(tree.beat.get("comment", "")) == "", "an unheard comment to lapse", 900, 3.0)
	# Again, heard: the player walks up and the comment is said.
	stages.floor_opened.emit(1, [])
	await _until(func() -> bool: return str(tree.beat.get("comment", "")) != "", "the Fix comment to come due again")
	var due := str(tree.beat["comment"])
	await _walk_up(tree)
	await _said(tree, StringName(due))  # a waiting comment comes before the greeting (the old order)
	_check(str(tree.beat.get("comment", "")) == "", "the comment is said once")
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the comment to end", 900)
	# The last Fix: the peace beat skips the cooldown once the beat gap has passed.
	stages.machine_fixed.emit()
	_check(true, "the last Fix arms the peace")
	await _until(func() -> bool: return (tree.beat.get("story", []) as Array).has("tree_peace"), "the peace beat to wait")
	tree.heard_at = tree.clock - 0.1
	tree.last_at = tree.clock - 0.1
	await _said(tree, PEACE)
	_check((tree.beat.get("story", []) as Array).is_empty(), "the peace is said once")
	await _until(func() -> bool: return not Voices.talking(&"old_tree"), "the peace line to end", 900)


func case_data() -> void:
	var book := Voices.book()
	var want := {
		"tree_grumble": 5, "tree_stage_half": 3, "tree_stage_most": 3, "tree_stage_last": 3,
		"tree_hint_basement": 4, "tree_hint_ground": 4, "tree_hint_first": 4, "tree_hint_attic": 4,
		"tree_part_basement": 4, "tree_part_ground": 4, "tree_part_first": 4, "tree_part_attic": 4,
		"tree_floor_ground": 4, "tree_floor_first": 4, "tree_floor_attic": 4,
		"tree_tip_throw": 1, "tree_tip_part": 2, "tree_peace": 3}
	for room: String in ["laundry", "garage", "kitchen", "living", "kids_north", "kids_east", "loft_west", "loft_east"]:
		want["tree_cabinet_" + room] = 4
	for trigger: String in want:
		_check(book.lines_for(&"old_tree", StringName(trigger)).size() == want[trigger], "%s has %d lines" % [trigger, want[trigger]])
	for trigger: StringName in [&"tree_peace"]:
		for l in book.lines_for(&"old_tree", trigger):
			_check(l.waits, "%s waits (a story beat)" % l.id)
		_check(load("res://game/voice/triggers/%s.tres" % trigger).ignores_cooldown, "%s skips the cooldown" % trigger)
	_check(book.errors.is_empty(), "the book loads clean (%s)" % [book.errors])
	var house := (load(HOUSE) as PackedScene).instantiate() as Node3D
	var named := 0
	for cab in house.find_children("*", "Cabinet", true, false):
		var c := cab as Cabinet
		_check(c.tree_hint != null and c.tree_hint.id == StringName("tree_cabinet_" + String(c.get_parent().name).to_snake_case()),
				"%s names its room line (%s)" % [c.get_parent().name, c.tree_hint.id if c.tree_hint != null else null])
		named += 1
	house.free()
	_check(named == 8, "the house's eight Cabinets (%d)" % named)
	var plan := load("res://game/run/house_stage_plan.tres") as StagePlan
	var hints: Array[StringName] = []
	for stage in plan.stages:
		hints.append(stage.tree_hint.id)
	_check(hints == [&"tree_hint_basement", &"tree_hint_ground", &"tree_hint_first", &"tree_hint_attic"], "each Stage names its floor's hint (%s)" % [hints])
	_check(OldTreeHelp.fix_pool(plan, 1).size() == 2 and OldTreeHelp.fix_pool(plan, 3).size() == 2, "a floor opening has the Part's comment and its own floor's")
	var t := load("res://game/furniture/old_tree_tuning.tres") as OldTreeTuning
	_check(t.beat_hold == 120.0 and t.beat_delay == Vector2(120.0, 420.0) and t.beat_chance == 0.75 and t.grumble_chance == 0.35
			and t.hint_chance == 0.35 and t.stage_thresholds == PackedFloat32Array([0.5, 0.8, 0.95]), "OldTreeTuning's help numbers are the old")


# --- Helpers -------------------------------------------------------------------------------------

func _house_up() -> void:
	_holder = Node.new()
	add_child(_holder)
	_level = (load(HOUSE) as PackedScene).instantiate() as Node3D
	_holder.add_child(_level)
	_rt = LevelRuntime.of(_level)
	await _until(_rt.loading.is_lifted, "the house's Socks to be laid", 900, 20.0)
	await _until(func() -> bool: return _rt.player.is_on_floor() and _rt.parts.is_bound, "the player to stand in the house", 900)
	_tree().picker.rng.seed = 133


func _free() -> void:
	if _level != null:
		if _rt != null and _rt.session != null:
			_rt.session.close()
		_level.get_parent().remove_child(_level)
		_level.free()
		_level = null
		_rt = null
	if _holder != null:
		_holder.free()
		_holder = null


func _tree() -> OldTree:
	return _level.get_node("Furniture/OldTree/OldTree") as OldTree


func _parts() -> Parts:
	return _rt.parts


func _hands() -> Hands:
	return _level.get_node("Runtime/Socks/Hands") as Hands


func _lights() -> HouseLights:
	return get_tree().get_nodes_in_group(HouseLights.GROUP)[0] as HouseLights


func _key(tree: OldTree) -> Variant:
	return Upgrades.of(tree).bank.key_of(1)


## The Throw tip said already (the cases that are not about it).
func _keep_throw_tip_said(tree: OldTree) -> void:
	_rt.parts.apply(tree.grant({"tips": {str(_key(tree)): ["tree_tip_throw"]}}))


## A test's fill: `share` of the bar's Pairs shelved in the Rows (any Sock ids: only the count is read).
func _fill(stages: Stages, share: float) -> void:
	var want := ceili(stages.bar_numbers().y * share)
	var changes := {}
	for row: Variant in stages.bar:
		var cab := stages.cabinet_of(StringName(str((row as Array)[0])))
		var index := int((row as Array)[1])
		var put := mini(want, cab.row_capacity(index))
		if put <= 0:
			continue
		var shelf: Array = (changes.get(cab.id, {"shelf": cab.shelf.duplicate()}) as Dictionary)["shelf"]
		while shelf.size() <= index:
			shelf.append(PackedInt32Array())
		var ids := PackedInt32Array()
		for i in put:
			ids.append(i)
		shelf[index] = ids
		changes[cab.id] = {"shelf": shelf}
		want -= put
	_rt.parts.apply({"ok": true, "changes": changes})
	_check(float(stages.bar_numbers().x) / stages.bar_numbers().y >= share, "the bar is filled to %s (%s)" % [share, stages.bar_numbers()])


## A loose lying Sock that has a loose lying Mate, taken into the Hands of player 1.
func _hold_loose_sock(_tree_node: OldTree) -> void:
	var mess := _hands().mess
	for sock in mess.count():
		if mess.state_of(sock) == Mess.State.LYING and mess.mate_of(sock) < 0:
			var key: Variant = _hands().key_of(1)
			_rt.parts.apply({"ok": true, "changes": {mess.id: mess.held_patch(sock),
					_hands().id: {"held": {key: PackedInt32Array([sock])}}}})
			await _frames(2)
			return
	_check(false, "a loose Sock lies in the house")


## The player at the house's spawn (beyond the tree's earshot) walks out of the laundry through its door to the
## stair lobby, where the tree is within earshot (the real path: the walk key only).
func _walk_up(tree: OldTree) -> void:
	var player := _rt.player
	await _until(func() -> bool: return player.is_on_floor() and not tree.near, "the player to stand at the spawn", 900)
	Input.action_press(&"move_forward")
	var door := (_level.get_node("Doors/LaundryLobby") as Node3D).global_position
	var way := door + Vector3(-1.0, 0.0, 0.0)
	await _until(func() -> bool:
		_face(player, way)
		return Vector2(player.global_position.x - way.x, player.global_position.z - way.z).length() < 0.3,
			"walking to the laundry's door", 900)
	await _until(func() -> bool:
		_face(player, door + Vector3(3.0, 0.0, 0.0))
		return tree.near, "walking up to bring the player near the tree", 900)
	Input.action_release(&"move_forward")


func _face(player: Player, point: Vector3) -> void:
	var to := point - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	(player.get_node("Head") as Node3D).rotation.x = 0.0


## Waits for the tree's next line and checks it is one of `trigger`'s.
func _said(tree: OldTree, trigger: StringName) -> VoiceLine:
	await _until(func() -> bool:
		var l := Voices.book().find_line(&"old_tree", tree.line)
		return l != null and l.has_trigger(trigger) and Voices.line_of(&"old_tree") == l, "a %s line" % trigger, 1800)
	var said := Voices.book().find_line(&"old_tree", tree.line)
	_check(said != null and said.has_trigger(trigger), "the tree says a %s line (%s)" % [trigger, tree.line])
	return said


func _first_text(l: VoiceLine) -> String:
	return tr(l.takes[0].segments[0].key) if l != null and not l.takes.is_empty() else "?"


## The cooldown has passed, on the Host and on this machine.
func _pass_cooldown(tree: OldTree) -> void:
	tree.last_at = -INF
	tree.heard_at = -INF
