## Wardrobe pieces as data and the dressed Avatar (core/128, docs/architecture/wardrobe.md "The pieces as
## data", "The dressed Avatar"): the 112 piece files and Wardrobe's lists, the Dresser on an AvatarLooks
## (hat, clothes, Socks, Trail, swish, first person, the mirror body), the preview and the Wardrobe zoo
## station. The station case plays it on a floor with the game's player and a Parts (a Host of one), as
## economy_test does.
extends TestSuite

const STATION := "res://game/zoo/stations/wardrobe.tscn"
const PLAYER := "res://game/player/player.tscn"
const AVATAR := "res://game/parts/avatar/looks_avatar.tscn"
const STAGE := "res://game/wardrobe/ui/preview_stage.tscn"
const ACTIONS: Array[StringName] = [&"interact", &"pick", &"move_forward"]
## Where the player stands before the switches, in station space.
const BY_SWITCHES := Vector3(-0.8, 0.0, 4.1)
const BASIC: Array[String] = ["apron", "beanie", "bobble_hat", "bow_tie", "cap", "crown", "jumper", "party_hat", "scarf", "top_hat"]

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _nodes: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Wardrobe station the player presses E on the Hat switch: the walking stand-in Teammate wears the next hat and its name tag rises over it; with the Trail switch on Lint puffs it leaves puffs as it walks, gone after their life"},
		{"name": "pieces", "method": "case_pieces", "world": false,
				"title": "112 piece files with their Looks; owned([]) is the ten basic pieces; counted leaves out the Lost Socks' six (held back); rows go basic first, then by Collection; pieces_of and piece_name"},
		{"name": "looks", "method": "case_looks", "world": false,
				"title": "WardrobeLook.clean drops unknown ids and wrong slots; allowed takes off what is not owned"},
		{"name": "dressed", "method": "case_dressed", "world": false,
				"title": "a skinned clothes piece is bound to the Avatar's skeleton and crouches with the body; Socks go under FootL and FootR; Bee wings swish 4 times a waddle; a changed Trail frees its marks"},
		{"name": "own_and_mirror", "method": "case_own_and_mirror", "world": false,
				"title": "the player's own body (first person) wears only Socks and Trail, never the hat or clothes, its Socks casting no shadow; the mirror body wears the whole look and leaves no Trail"},
		{"name": "preview", "method": "case_preview", "world": false,
				"title": "Wardrobe.preview on the preview stage: a hat alone fitted to its size, Socks on bare feet in the tint, a Trail stepping its sample already laid"},
		{"name": "station_stands", "method": "case_station_stands", "world": false,
				"title": "the Wardrobe station has one stand per piece file, each worn by its own AvatarLooks and labelled with name, Collection and Rarity; the Trail stands step their sample"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	_free_all()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build()
	var walker := _station.get_node("Teammates/4") as Avatar
	var looks := walker.looks
	var tag_before := looks.tag().position.y
	_check(looks.dresser().hat == null, "the stand-in starts bare-headed")
	# The player presses E on the Hat switch.
	await _aim(_button("HatSwitch"))
	await _press(&"interact")
	var first_hat := _first_shown(WardrobePiece.Slot.HAT)
	await _until(func() -> bool: return looks.dresser().worn[&"hat"] == first_hat, "the stand-in to wear %s" % first_hat)
	var hat := looks.dresser().hat
	_check(hat != null and hat.get_parent() == looks.swaying().get_node(^"HatPoint"), "the hat's Looks sits under the HatPoint")
	_check(looks.tag().position.y > tag_before + 0.05, "the name tag rose over the hat (%.3f, was %.3f)" % [looks.tag().position.y, tag_before])
	_check((_station.get_node("HatSwitch/Looks/Label") as Label3D).text == "Hat: %s" % Wardrobe.piece_name(first_hat), "the switch names the hat")
	# Again: the next hat.
	await _press(&"interact")
	var second := (_station.get_node("HatSwitch/WardrobeSwitch") as WardrobeSwitch).next_after(first_hat)
	await _until(func() -> bool: return looks.dresser().worn[&"hat"] == second, "the stand-in to wear the next hat %s" % second)
	# The Trail switch, on Lint puffs (the first Trail of the row).
	_check(_first_shown(WardrobePiece.Slot.TRAIL) == &"lint_puffs", "Lint puffs is the Trail row's first")
	await _aim(_button("TrailSwitch"))
	await _press(&"interact")
	await _until(func() -> bool: return looks.dresser().worn[&"trail"] == &"lint_puffs", "the stand-in to wear Lint puffs")
	await _until(func() -> bool: return not looks.dresser().marks().is_empty(), "the walking stand-in to leave a puff", 1200, 10.0)
	var mark: TrailMark = looks.dresser().marks()[0]
	_check(mark.top_level and absf(mark.global_position.y - (walker.global_position.y + 0.006)) < 0.02, "the mark stays where it was laid, 0.006 m over the floor (%.3f)" % mark.global_position.y)
	var puffs := mark.get_node("Puffs") as GPUParticles3D
	_check(puffs.emitting and puffs.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "its puffs emit and cast no shadow")
	var left: WeakRef = weakref(mark)
	var at := mark.global_position
	await _frames(10)
	_check(is_instance_valid(mark) and mark.global_position.is_equal_approx(at), "the mark does not follow the walker")
	await _until(func() -> bool: return left.get_ref() == null, "the first puff to go after its life (%.1f s)" % mark.life, 1200, 8.0)
	_check(looks.dresser().marks().size() <= 36, "at most 36 Lint puffs marks kept (%d)" % looks.dresser().marks().size())


# --- Data ----------------------------------------------------------------------------------------

func case_pieces() -> void:
	var all := Wardrobe.all()
	_check(all.size() == 112, "112 pieces (%d)" % all.size())
	for p in all:
		_check(p.looks != null, "%s has its Looks" % p.id)
	var owned := Array(Wardrobe.owned(PackedStringArray()))
	owned.sort()
	_same(owned, BASIC, "owned([]) is the ten basic pieces")
	_check(Wardrobe.owned(PackedStringArray(["lint_puffs"])).size() == 11, "owned() keeps the given pieces")
	_check(Wardrobe.counted(WardrobePiece.Slot.HAT) == 38 and Wardrobe.counted(WardrobePiece.Slot.CLOTHES) == 36
			and Wardrobe.counted(WardrobePiece.Slot.SOCKS) == 16 and Wardrobe.counted(WardrobePiece.Slot.TRAIL) == 16,
			"counted leaves out the Lost Socks' six (%d, %d, %d, %d)" % [Wardrobe.counted(0), Wardrobe.counted(1), Wardrobe.counted(2), Wardrobe.counted(3)])
	_check(not Wardrobe.shown(Wardrobe.of(&"porthole_helmet")), "a Lost Socks piece is not shown (held back)")
	var hats := Wardrobe.row(WardrobePiece.Slot.HAT)
	_same([hats[0].id, hats[5].id, hats[6].id, hats[7].id], [&"beanie", &"crown", &"sock_hat", &"peg_band"], "the hat row: the basic six by order, then Simple's two")
	var simple := Wardrobe.pieces_of(&"simple")
	_same(simple.map(func(p: WardrobePiece) -> StringName: return p.id), [&"sock_hat", &"peg_band", &"laundry_sack", &"odd_sock_scarf", &"odd_pair", &"lint_puffs"], "Simple's six in order")
	_check(Wardrobe.of(&"bee_wings").swish_rate == 4 and Wardrobe.of(&"lint_puffs").rarity == WardrobePiece.Rarity.RARE, "Bee wings swish 4 a waddle; Lint puffs is rare")
	_check(Wardrobe.piece_name(&"top_hat") == "Top hat" and Wardrobe.piece_name(&"odd_sock_scarf") == "Odd-sock scarf" and Wardrobe.piece_name(&"no_such") == "No Such", "piece names")


func case_looks() -> void:
	var clean := WardrobeLook.clean({"hat": "top_hat", "clothes": "beanie", "socks": "nope", "extra": "x"})
	_same(clean, {&"hat": &"top_hat", &"clothes": &"", &"socks": &"", &"trail": &""}, "clean() keeps a known piece of its slot only")
	var allowed := WardrobeLook.allowed({&"hat": &"top_hat", &"trail": &"lint_puffs"}, Wardrobe.owned(PackedStringArray()))
	_same(allowed, {&"hat": &"top_hat", &"clothes": &"", &"socks": &"", &"trail": &""}, "allowed() takes off an unowned Trail")


# --- The dressed Avatar --------------------------------------------------------------------------

func case_dressed() -> void:
	var a := _avatar()
	a.look = {&"clothes": &"jumper", &"socks": &"odd_pair", &"trail": &"lint_puffs"}
	var d := a.dresser()
	var skeleton := a.body().get_parent() as Skeleton3D
	var mesh := d.clothes.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	_check(d.clothes.get_parent() == a.swaying(), "the clothes go under the Body")
	_check(mesh.get_node_or_null(mesh.skeleton) == skeleton, "the clothes are skinned to the Avatar's Skeleton3D")
	var key := mesh.find_blend_shape_by_name(&"Crouch")
	a.set_crouch(1.0)
	_near(mesh.get_blend_shape_value(key), 1.0, 0.001, "the clothes crouch with the body")
	a.set_crouch(0.0)
	_near(mesh.get_blend_shape_value(key), 0.0, 0.001, "and stand with it")
	_check(d.socks.size() == 2 and d.socks[0].get_parent() == a.feet()[0] and d.socks[1].get_parent() == a.feet()[1], "the Socks go under FootL and FootR")
	_check((d.socks[0].get_node("sock_l") as Node3D).visible and not (d.socks[0].get_node("sock_r") as Node3D).visible, "the left foot draws only sock_l")
	# Steps lay marks; a changed Trail frees them at once.
	for i in 3:
		a.walk = 1.0
		a.stepped.emit(a.feet()[i % 2])
	_check(d.marks().size() == 3, "three steps over 0.3 waddle laid three marks (%d)" % d.marks().size())
	a.walk = 0.2
	a.stepped.emit(a.feet()[0])
	_check(d.marks().size() == 3, "a step at 0.2 waddle laid none")
	a.look = {&"clothes": &"jumper", &"socks": &"odd_pair", &"trail": &"turf_prints"}
	_check(d.marks().is_empty(), "a changed Trail freed its marks at once")
	# Bee wings swing with the waddle, 4 times a waddle.
	a.look = {&"clothes": &"bee_wings"}
	var wings := d.clothes.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var l := wings.find_blend_shape_by_name(&"SwishL")
	var r := wings.find_blend_shape_by_name(&"SwishR")
	var moved := 0.0
	for i in 40:
		a.position.x += 0.05  # walking
		await _frames(1)
		moved = maxf(moved, wings.get_blend_shape_value(l) + wings.get_blend_shape_value(r))
	_check(moved > 0.3, "the wings swish as it walks (%.2f)" % moved)
	# Over a cap the oldest mark goes first.
	a.look = {&"trail": &"turf_prints"}
	var cap := (Wardrobe.of(&"turf_prints").looks.instantiate() as TrailMark)
	var most := cap.max_marks
	cap.free()
	a.walk = 1.0
	for i in most + 3:
		a.stepped.emit(a.feet()[0])
	_check(d.marks().size() == most, "at most max_marks (%d) marks kept (%d)" % [most, d.marks().size()])


func case_own_and_mirror() -> void:
	var player := (load(PLAYER) as PackedScene).instantiate() as Player
	add_child(player)
	_nodes.append(player)
	await _frames(1)
	var own := player.get_node("%OwnBody") as AvatarLooks
	var mirror := player.get_node("%MirrorBody") as AvatarLooks
	var look := {&"hat": &"top_hat", &"clothes": &"jumper", &"socks": &"odd_pair", &"trail": &"lint_puffs"}
	own.look = look
	mirror.look = look
	_check(own.dresser().hat == null and own.dresser().clothes == null, "the own body wears no hat or clothes")
	_check((own.swaying().get_node(^"HatPoint") as Node3D).get_child_count() == 0, "nothing is drawn at the own body's HatPoint")
	_check(own.dresser().socks.size() == 2, "the own body wears its Socks")
	var sock := own.dresser().socks[0].get_node("sock_l") as GeometryInstance3D
	_check(sock.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "its Socks cast no shadow in first person")
	_check(own.dresser().worn[&"trail"] == &"lint_puffs" and own.leaves_trail, "the own body leaves its Trail")
	_check(mirror.dresser().hat != null and mirror.dresser().clothes != null and mirror.dresser().socks.size() == 2, "the mirror body wears the whole look")
	mirror.walk = 1.0
	mirror.stepped.emit(mirror.feet()[0])
	_check(not mirror.leaves_trail and mirror.dresser().marks().is_empty(), "the mirror body leaves no Trail")


func case_preview() -> void:
	var stage := (load(STAGE) as PackedScene).instantiate() as PreviewStage
	add_child(stage)
	_nodes.append(stage)
	var fit := Wardrobe.tuning().preview_fit
	var hat := stage.show_piece(&"top_hat")
	await _frames(1)
	var box := Wardrobe.bounds(hat)
	_near(maxf(maxf(box.size.x, box.size.y), box.size.z), fit, 0.01, "the hat is fitted to %.2f m at its largest side" % fit)
	_check(box.get_center().length() < 0.01, "and centred on the preview")
	var tint := Color(0.3, 0.7, 0.6)
	var feet := stage.show_piece(&"odd_pair", tint)
	await _frames(1)
	var avatar := feet.find_children("*", "AvatarLooks", true, false)[0] as AvatarLooks
	_check(not avatar.body().is_visible_in_tree() and avatar.feet()[0].is_visible_in_tree(), "the Socks stand on bare feet, the body hidden")
	_check(avatar.colour == tint and avatar.dresser().socks.size() == 2, "in the tint, wearing the pair")
	var trail := stage.show_piece(&"lint_puffs")
	await _frames(1)
	var sample := trail.find_children("*", "AvatarLooks", true, false)[0] as AvatarLooks
	_check(sample.dresser().marks().size() == Wardrobe.tuning().demo_steps, "the Trail's sample is already laid (%d marks)" % sample.dresser().marks().size())
	_check(sample.dresser().marks()[0].age > sample.dresser().marks()[-1].age, "the first laid is the oldest")
	_check(stage.shown() == trail, "the stage shows one piece at a time")


func case_station_stands() -> void:
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	add_child(station)
	_nodes.append(station)
	await _frames(1)
	var stands := (station.get_node("Stands") as WardrobeStands).stands()
	_check(stands.size() == Wardrobe.all().size(), "one stand per piece file (%d, %d)" % [stands.size(), Wardrobe.all().size()])
	var top := stands.filter(func(s: PieceStand) -> bool: return s.piece.id == &"top_hat")[0] as PieceStand
	_check(((top.get_node("Label") as Label3D).text) == "Top hat\nBasic · Common", "a stand names its piece, Collection and Rarity")
	_check((top.get_node("Looks") as AvatarLooks).dresser().worn[&"hat"] == &"top_hat", "its own AvatarLooks wears it")
	var lint := stands.filter(func(s: PieceStand) -> bool: return s.piece.id == &"lint_puffs")[0] as PieceStand
	var dresser := (lint.get_node("Looks") as AvatarLooks).dresser()
	_check(dresser.demo and not dresser.marks().is_empty(), "a Trail stand steps its sample")


# --- Helpers -------------------------------------------------------------------------------------

func _avatar() -> AvatarLooks:
	var a := (load(AVATAR) as PackedScene).instantiate() as AvatarLooks
	add_child(a)
	_nodes.append(a)
	return a


func _first_shown(slot: WardrobePiece.Slot) -> StringName:
	for p in Wardrobe.row(slot):
		if Wardrobe.shown(p):
			return p.id
	return &""


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
	_player.position = BY_SWITCHES
	_level.add_child(_player)
	_player.capture_mouse()
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	await _until(func() -> bool: return _player.is_on_floor(), "the player to stand")


func _button(switch: String) -> Vector3:
	return (_station.get_node("%s/Looks/Button" % switch) as Node3D).global_position


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


func _free_all() -> void:
	if _level != null:
		_level.free()
		_level = null
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
