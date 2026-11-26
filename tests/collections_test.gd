## Collections as data (core/125): each Collection a `SockCollection` file, the unlock rule a `CollectionUnlocks`
## file, and the Collections station built from the folder. The real path plays the Cabinet station: the drawer's
## prompt and the pairing sparkles read the Collection's file, so a changed file changes them with no code.
extends TestSuite

const CABINET_STATION := "res://game/zoo/stations/cabinet.tscn"
const COLLECTIONS_STATION := "res://game/zoo/stations/collections.tscn"
const UNLOCKS := "res://game/collections/collection_unlocks.tres"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact"]
## The Cabinet station's first Simple Pair, by id.
const S0 := 0
const S0_MATE := 1
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
const BY_DRAWERS := Vector3(-1.0, 0.0, -0.4)
const ALL_IDS: Array[StringName] = [&"simple", &"patterns", &"sport", &"winter", &"animals", &"superhero", &"food",
		&"space", &"lost", &"fruit", &"nature", &"vegetables", &"drinks", &"math", &"tech", &"transport", &"machinery"]
const NEW_COLOUR := Color(0.1, 0.9, 0.3, 1.0)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _cabinet: Cabinet = null
var _saved_colour := Color.WHITE


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Cabinet station the drawer's prompt reads the Collection file's Cabinet name, a Pair made by the pick key sparkles in the file's colour (a changed colour changes it) and a click shelves it"},
		{"name": "files", "method": "case_files", "world": false,
				"title": "17 Collection files in catalogue order, the old names, colours and wrapping, the Lost Socks alone held back and left out of shown()"},
		{"name": "unlocks", "method": "case_unlocks", "world": false,
				"title": "the unlock rule: the eight start Collections, the eight in order, one a finished game, none once all are unlocked"},
		{"name": "station", "method": "case_station", "world": false,
				"title": "the Collections station lists 17 rows from the folder, the Lost Socks marked held back and the place in the unlock rule on each"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_restore_colour()
	if _level != null:
		_level.free()
		_level = null


func case_real_path() -> void:
	await _build()
	var simple := Collections.of(&"simple")
	_saved_colour = simple.colour
	simple.colour = NEW_COLOUR
	_stand(BY_DRAWERS)
	await _aim(_drawer_front(0))
	var hud := _player.hud()
	await _until(func() -> bool: return hud.prompt_text() == "[E] Simple Cabinet Drawer", "the drawer's prompt (%s)" % hud.prompt_text())
	_stand(BY_SOCKS)
	await _aim(_centre(S0))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == S0, "the first Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_centre(S0_MATE))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(S0), "the mate to fuse into a Pair")
	var moment := _player.held_view().moment_of(S0)
	_check(moment != null, "the pairing moment plays")
	if moment != null:
		var burst := moment.get_node("Burst") as GPUParticles3D
		_check((burst.process_material as ParticleProcessMaterial).color == NEW_COLOUR, "the burst is in the file's changed colour")
	_stand(BY_DRAWERS)
	await _aim(_drawer_front(0))
	await _press(&"pick")
	await _until(func() -> bool: return _cabinet.contents(0) == PackedInt32Array([S0]), "the Pair to be shelved in the Simple Cabinet's drawer")
	var original := _saved_colour
	_restore_colour()
	_check(_mess.catalogue.collection_colour(&"simple") == original, "the colour is the file's again")


func case_files() -> void:
	var all := Collections.all()
	_check(all.size() == 17, "17 Collections (%d)" % all.size())
	var ids: Array[StringName] = []
	for c in all:
		ids.append(c.id)
	_check(ids == ALL_IDS, "in the catalogue's order (%s)" % [ids])
	var catalogue := load("res://game/sock/designs.tres") as DesignCatalogue
	_check(ids == catalogue.collections(), "the same order as DesignCatalogue.collections()")
	var simple := Collections.of(&"simple")
	_check(simple.name == "Simple" and simple.cabinet_name == "Simple cabinet", "Simple's names")
	_check(_close(simple.colour, Color("#8c8f94")), "Simple's colour is the old one")
	_check(_close(simple.paper, Color("#b4b6b9")) and _close(simple.ink, Color("#696b6f")) and _close(simple.bow, Color("#7b7e82")), "Simple's wrapping is the old one")
	_check(simple.icon != null, "Simple has its icon")
	_check(Collections.of(&"patterns").name == "Patterns", "the 2026-11-19 name Patterns")
	for c in all:
		_check(c.icon != null and c.cabinet_name != "" and c.name != "", "%s has icon, names" % c.id)
		_check(c.paper.a > 0.0 and c.ink.a > 0.0 and c.bow.a > 0.0, "%s has its wrapping" % c.id)
		_check(c.held_back == (c.id == &"lost"), "%s held back only if Lost Socks" % c.id)
	_check(Collections.shown().size() == 16 and not Collections.shown().has(Collections.of(&"lost")), "shown() leaves out the Lost Socks")
	_check(Collections.of(&"nope") == null, "an unknown id is null")
	_check(catalogue.collection_colour(&"sport") == Collections.of(&"sport").colour, "collection_colour() reads the file")
	_check(catalogue.cabinet_name(&"sport") == "Sport cabinet", "cabinet_name() reads the file")
	_check(catalogue.cabinet_name(&"nope") == "nope", "an unknown Collection's Cabinet is its id")
	var bare := SockCollection.new()
	bare.colour = Color(0.4, 0.4, 0.4, 1.0)
	_check(bare.paper_colour().is_equal_approx(bare.colour.lightened(0.35)) and bare.ink_colour().is_equal_approx(bare.colour.darkened(0.25)) and bare.bow_colour() == bare.colour, "an unset wrapping falls back to the colour's rule")


func case_unlocks() -> void:
	var rule := load(UNLOCKS) as CollectionUnlocks
	_check(rule.start == [&"simple", &"sport", &"patterns", &"animals", &"superhero", &"winter", &"nature", &"food"], "the start set (%s)" % [rule.start])
	_check(rule.order == [&"space", &"fruit", &"machinery", &"drinks", &"tech", &"vegetables", &"transport", &"math"], "the order (%s)" % [rule.order])
	_check(rule.per_finished_game == 1, "one a finished game")
	_check(not rule.start.has(&"lost") and not rule.order.has(&"lost"), "the Lost Socks are in neither")
	var unlocked: Array[StringName] = rule.start.duplicate()
	var got: Array[StringName] = []
	for i in 10:
		var next := rule.next_after(unlocked)
		if next.is_empty():
			break
		got.append_array(next)
		unlocked.append_array(next)
	_check(got == rule.order, "finished games unlock the order one at a time (%s)" % [got])
	_check(rule.next_after(unlocked).is_empty(), "none once all are unlocked")
	var some: Array[StringName] = rule.start.duplicate()
	some.append(&"fruit")
	_check(rule.next_after(some) == [&"space"], "the next one not yet held, in order")
	var two := rule.duplicate() as CollectionUnlocks
	two.per_finished_game = 2
	_check(two.next_after(rule.start) == [&"space", &"fruit"], "the count is the rule's")


func case_station() -> void:
	var station := (load(COLLECTIONS_STATION) as PackedScene).instantiate() as CollectionsStation
	add_child(station)
	var wall := station.wall
	_check(wall.get_child_count() == 17, "17 rows (%d)" % wall.get_child_count())
	for id in ALL_IDS:
		var row := station.row_of(id)
		_check(row != null, "a row for %s" % id)
		if row == null:
			continue
		var c := Collections.of(id)
		_check(row.name_label.text == c.name and row.cabinet_label.text == c.cabinet_name, "%s's names" % id)
		_check((row.colour_swatch.material_override as StandardMaterial3D).albedo_color == c.colour, "%s's colour swatch" % id)
		_check(row.held_label.visible == (id == &"lost"), "%s's held back mark" % id)
	_check(station.row_of(&"simple").place_label.text == "start", "Simple starts unlocked")
	_check(station.row_of(&"space").place_label.text == "unlock 1" and station.row_of(&"math").place_label.text == "unlock 8", "the order's places")
	_check(station.row_of(&"lost").place_label.text == "", "the Lost Socks have no place")
	var a := station.row_of(&"simple").paper_swatch.material_override
	_check(a != station.row_of(&"sport").paper_swatch.material_override, "each row has its own swatch material")
	station.free()


# --- Helpers -------------------------------------------------------------------------------------

## True when two colours agree to the four decimals the files keep.
func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.001 and absf(a.g - b.g) < 0.001 and absf(a.b - b.b) < 0.001


func _restore_colour() -> void:
	if _saved_colour != Color.WHITE:
		Collections.of(&"simple").colour = _saved_colour
		_saved_colour = Color.WHITE


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
	_station = (load(CABINET_STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = _station.position + BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_cabinet = _station.get_node("Cabinet/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null, "the player to stand and the Socks to lie")


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


func _drawer_front(index: int) -> Vector3:
	var front := _cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
