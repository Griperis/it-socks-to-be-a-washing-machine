## The Laundry bin entity (core/90, run-ends.md "The Laundry bins (the entity)"), played alone: the zoo
## with its Laundry station (a full bin, an empty bin, the Bin pillar, the washer) and its Hand-off
## station (the stand-in Teammates: peer 6 holds a Brown Sock, peer 7 holds nothing), the game's player a
## Host of one. Lines are the behaviour list's (04 "The Laundry bins (the entity)"): the readout words,
## the pick, the carry, the put down, the Teammate, the heap, the tip, the unused spot and the cutscene.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Laundry", "HandOff"]
const LAUNDRY := "Stations/Laundry"
const HAND_OFF := "Stations/HandOff"
const FULL := LAUNDRY + "/BinFull"
const EMPTY := LAUNDRY + "/BinEmpty"
const PILLAR := LAUNDRY + "/BinPillar"
const HOLDER := 6
const OPEN := 7
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"move_forward", &"interact"]

var _holder_node: Node = null
var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: a left click on the full bin carries it, a right click on the floor lays it at the crosshair at the held turn; aimed, it reads Laundry bin, dirty"},
		{"name": "words_and_heap", "method": "case_words_and_heap", "world": false,
				"title": "a full and an empty bin read dirty and empty; the heap follows full, eased at 0.8 a second and hidden when empty; the Bin pillar empties the bin, which tips toward the washer, and fills it again"},
		{"name": "teammate", "method": "case_teammate", "world": false,
				"title": "core/42's Hand-off refuses a carried bin; a right click at a Teammate with empty Hands puts the bin in theirs, with full Hands at their feet"},
		{"name": "unused_and_cutscene", "method": "case_unused_and_cutscene", "world": false,
				"title": "an unused bin is hidden, has no collision and is not aimed; a cutscene hides every bin, carried or lying, and brings it back as it was"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _holder_node != null:
		_holder_node.free()
		_holder_node = null


func case_real_path() -> void:
	await _build()
	var bin := _bin(FULL)
	var thing := _thing(FULL)
	var player := _player()
	var start := thing.global_position
	await _stand_facing(start + Vector3(0.0, 0.0, 1.3), start + Vector3.UP * 0.26)
	_check(player.aimed_part() == _carriable(FULL), "the crosshair is on the bin")
	_check(player.hud().prompt_text().contains("Laundry bin, dirty"), "it reads Laundry bin, dirty (%s)" % player.hud().prompt_text())
	await _press(&"pick")
	await _until(func() -> bool: return _carriable(FULL).holder == 1, "line: a left click with empty Hands carries it", 30)
	await _frames(2)
	_check(not bin.used or thing.visible, "the carried bin is drawn")
	var want := player.global_position + Basis(Vector3.UP, player.rotation.y) * Vector3(0.0, 0.45, -0.72)
	_check(thing.global_position.distance_to(want) < 0.01, "it rides the bin's slot (%s, want %s)" % [thing.global_position, want])
	var yaw := player.rotation.y
	var feet := player.global_position
	var spot := feet + Basis(Vector3.UP, yaw) * Vector3(0.0, 0.0, -1.4)
	spot.y = 0.0
	await _look_at(spot)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _carriable(FULL).holder == 0, "a right click puts it down", 30)
	var lying := thing.global_position
	_check(Vector2(lying.x - spot.x, lying.z - spot.z).length() < 0.12, "it lies at the crosshair (%s, aimed %s)" % [lying, spot])
	_near(angle_difference(thing.global_rotation.y, wrapf(yaw, -PI, PI)), 0.0, 0.01, "turned as it was held")
	await _until(func() -> bool: return not _carriable(FULL).putting(), "the put to end", 30)
	await _stand_facing(lying + Vector3(0.0, 0.0, 1.3), lying + Vector3.UP * 0.26)
	_check(player.aimed_part() == _carriable(FULL), "lying, it is aimed again")
	_check(player.hud().prompt_text().contains("Laundry bin, dirty"), "and reads Laundry bin, dirty (%s)" % player.hud().prompt_text())


func case_words_and_heap() -> void:
	await _build()
	var full := _bin(FULL)
	var empty := _bin(EMPTY)
	var player := _player()
	_check(full.prompt_title() == "Laundry bin, dirty" and _carriable(FULL).title == "Laundry bin, dirty", "a full bin: dirty")
	_check(empty.prompt_title() == "Laundry bin, empty" and _carriable(EMPTY).title == "Laundry bin, empty", "an empty bin: empty")
	var at := _thing(EMPTY).global_position
	await _stand_facing(at + Vector3(0.0, 0.0, 1.3), at + Vector3.UP * 0.26)
	_check(player.hud().prompt_text().contains("Laundry bin, empty"), "aimed, the empty one reads Laundry bin, empty (%s)" % player.hud().prompt_text())
	_check(full.heap_visible() and is_equal_approx(full.shown_fill(), 1.0), "the full bin shows its heap")
	_check(not empty.heap_visible() and is_equal_approx(empty.shown_fill(), 0.0), "the empty bin shows none")
	# The Bin pillar empties the full one: it tips, the heap eases down at 0.8 a second.
	var pillar := _thing(PILLAR)
	await _stand_facing(pillar.global_position + Vector3(0.0, -0.5, 1.5), pillar.global_position)
	_check(player.aimed_part() == pillar.get_node("BinPillar"), "the crosshair is on the Bin pillar")
	await _press(&"interact")
	await _until(func() -> bool: return not full.full, "the pillar empties the bin", 30)
	_check(full.prompt_title() == "Laundry bin, empty", "it now reads empty")
	_check(full.tipping(), "it tips toward the washer")
	var after := full.shown_fill()
	_check(after < 1.0 and after > 0.0 and full.heap_visible(), "the heap is easing down, not gone (%.2f)" % after)
	var thing := _thing(FULL)
	var looks := thing.get_node("Looks") as Node3D
	var aim := looks.get_node("Aim") as Node3D
	var washer := _zoo.get_node(LAUNDRY + "/Washer") as Node3D
	var toward := thing.global_basis.inverse() * (washer.global_position - thing.global_position)
	_near(angle_difference(aim.rotation.y, atan2(-toward.x, -toward.z)), 0.0, 0.01, "its Looks turned toward the washer")
	var tip := looks.get_node("Aim/Tip") as Node3D
	var deepest := 0.0
	var seconds := 0.0
	while full.tipping() and seconds < 3.0:
		await _frames(1)
		deepest = maxf(deepest, absf(tip.rotation.x))
		seconds += get_process_delta_time()
	_check(deepest > deg_to_rad(90.0) and deepest <= deg_to_rad(105.5), "it leans out to about 105 degrees (%.0f)" % rad_to_deg(deepest))
	_check(absf(tip.rotation.x) < 0.001, "and back upright")
	await _until(func() -> bool: return not full.heap_visible(), "the emptied heap to be hidden", 180)
	_near(full.shown_fill(), 0.0, 0.001, "the heap is empty")
	# Filled again, the heap comes back.
	await _stand_facing(pillar.global_position + Vector3(0.0, -0.5, 1.5), pillar.global_position)
	await _press(&"interact")
	await _until(func() -> bool: return full.full, "the pillar fills it again", 30)
	await _until(func() -> bool: return is_equal_approx(full.shown_fill(), 1.0), "the heap to ease back", 180)
	_check(full.heap_visible() and full.prompt_title() == "Laundry bin, dirty", "full again: dirty with its heap")


func case_teammate() -> void:
	await _build()
	var player := _player()
	var thing := _thing(FULL)
	await _stand_facing(thing.global_position + Vector3(0.0, 0.0, 1.3), thing.global_position + Vector3.UP * 0.26)
	await _press(&"pick")
	await _until(func() -> bool: return _carriable(FULL).holder == 1, "the bin to be carried", 30)
	_check(_hands().hand_off_refusal(1, OPEN) == Hands.NOTHING, "core/42's Hand-off refuses the carried bin (it hands over Socks)")
	_check(_carriable(FULL).handable, "the bin is handed over by the right click at a Teammate (the old game)")
	var open := _avatar(OPEN)
	await _face_mate(open)
	await _until(func() -> bool: return player.aimed_mate == OPEN, "the empty-handed Teammate is aimed", 20)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _carriable(FULL).holder == OPEN, "into their empty Hands", 20)
	_check(_hands().carries(OPEN) == _carriable(FULL), "their Hands carry it")
	# Full Hands: at their feet.
	await _build()
	player = _player()
	thing = _thing(FULL)
	await _stand_facing(thing.global_position + Vector3(0.0, 0.0, 1.3), thing.global_position + Vector3.UP * 0.26)
	await _press(&"pick")
	await _until(func() -> bool: return _carriable(FULL).holder == 1, "the bin to be carried again", 30)
	var holder := _avatar(HOLDER)
	await _face_mate(holder)
	await _until(func() -> bool: return player.aimed_mate == HOLDER, "the full-handed Teammate is aimed", 20)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _carriable(FULL).holder == 0, "it goes down", 20)
	var feet := holder.global_position
	var lying := thing.global_position
	_check(Vector2(lying.x - feet.x, lying.z - feet.z).length() < 0.01, "it lies at their feet (%s, feet %s)" % [lying, feet])


func case_unused_and_cutscene() -> void:
	await _build()
	var full := _bin(FULL)
	var thing := _thing(FULL)
	var player := _player()
	var shape := thing.get_node("Shape") as CollisionShape3D
	# Hidden in a cutscene, lying and carried, and back as it was.
	for b: LaundryBin in get_tree().get_nodes_in_group(LaundryBin.GROUP):
		b.set_drawn(false)
	_check(not thing.visible and not _thing(EMPTY).visible, "a cutscene hides the lying bins")
	for b: LaundryBin in get_tree().get_nodes_in_group(LaundryBin.GROUP):
		b.set_drawn(true)
	_check(thing.visible and _thing(EMPTY).visible, "and brings them back")
	await _stand_facing(thing.global_position + Vector3(0.0, 0.0, 1.3), thing.global_position + Vector3.UP * 0.26)
	await _press(&"pick")
	await _until(func() -> bool: return _carriable(FULL).holder == 1, "the bin to be carried", 30)
	full.set_drawn(false)
	_check(not thing.visible, "a cutscene hides a carried bin")
	full.set_drawn(true)
	_check(thing.visible, "and brings it back")
	await _put_ahead()
	await _physics_ticks(5)
	# An unused spot: hidden, no collision, not aimed, even after a cutscene.
	var bin_id := full.id
	_parts().apply({"ok": true, "changes": {bin_id: {"used": false}}})
	await _physics_ticks(3)
	_check(not thing.visible, "an unused bin is hidden")
	_check(shape.disabled, "and has no collision")
	full.set_drawn(true)
	_check(not thing.visible, "a cutscene's end does not show it")
	var at := thing.global_position
	await _stand_facing(at + Vector3(0.0, 0.0, 1.3), at + Vector3.UP * 0.26)
	_check(player.aimed_part() != _carriable(FULL), "it is not aimed")
	_parts().apply({"ok": true, "changes": {bin_id: {"used": true}}})
	await _physics_ticks(3)
	_check(thing.visible and not shape.disabled, "used again, it is drawn and solid")


# --- Helpers -------------------------------------------------------------------------------------

func _build() -> void:
	if _holder_node != null:
		_holder_node.free()
	_holder_node = Node.new()
	_holder_node.name = "Alone"
	add_child(_holder_node)
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	for station in _zoo.get_node("Stations").get_children():
		if not KEEP.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	_holder_node.add_child(_zoo)
	# The stand-in takes its Sock once the camera comes near (HandOffStandIn.wake_range).
	_player().global_position = (_zoo.get_node(HAND_OFF) as Node3D).global_position + Vector3(0.0, 0.0, 3.0)
	await _until(func() -> bool: return _player().is_on_floor() and _avatar(HOLDER) != null and _hands().items_of(HOLDER).size() == 1,
			"the zoo to stand, the Teammate to hold its Sock", 300)
	_player().capture_mouse()


func _put_ahead() -> void:
	var player := _player()
	var spot := player.global_position + Basis(Vector3.UP, player.rotation.y) * Vector3(0.0, 0.0, -1.4)
	spot.y = 0.0
	await _look_at(spot)
	await _press(&"drop_throw")
	await _until(func() -> bool: return _carriable(FULL).holder == 0, "the bin to go down", 30)


func _face_mate(mate: Avatar, away := 1.5) -> void:
	var feet := mate.global_position
	await _stand_facing(Vector3(feet.x, 0.0, feet.z + away), feet + Vector3.UP * 1.1)


func _stand_facing(feet: Vector3, target: Vector3) -> void:
	var player := _player()
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	await _physics_ticks(1)
	await _look_at(target)


func _look_at(target: Vector3) -> void:
	var player := _player()
	var head := player.get_node("Head") as Node3D
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := target - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	player.reset_physics_interpolation()
	await _physics_ticks(2)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics_ticks(2)
	Input.action_release(action)
	await _physics_ticks(2)


func _avatar(peer: int) -> Avatar:
	return _zoo.get_node_or_null(HAND_OFF + ("/Holder/%d" if peer == HOLDER else "/Open/%d") % peer) as Avatar


func _bin(path: String) -> LaundryBin:
	return _zoo.get_node(path + "/LaundryBin") as LaundryBin


func _carriable(path: String) -> Carriable:
	return _zoo.get_node(path + "/Carriable") as Carriable


func _thing(path: String) -> Node3D:
	return _zoo.get_node(path) as Node3D


func _hands() -> Hands:
	return LevelRuntime.of(_zoo).hands


func _parts() -> Parts:
	return LevelRuntime.of(_zoo).parts


func _player() -> Player:
	return LevelRuntime.of(_zoo).player
