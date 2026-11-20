## The every-Sock station (core/12, E01-E06): the catalogue laid out on the ground in rows by
## Collection, each Design's two Socks side by side with its info in front, real Socks of the zoo's
## one Mess, never saved, off the grid at the end of the zoo, and made from the catalogue alone.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const STATION := "res://game/zoo/stations/every_sock.tscn"
const FOLDER := "Stations/EverySock"

var _zoo: Node3D = null
var _alone: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "e01", "method": "case_e01", "world": false,
				"title": "E01: both Socks of every Design lie in rows by Collection, the name at the start, Designs in id order, mates side by side"},
		{"name": "e02", "method": "case_e02", "world": false,
				"title": "E02: in front of each Design's Socks lies its id, name, Collection, Size and rarity"},
		{"name": "e03", "method": "case_e03", "world": false,
				"title": "E03, real path: the player walks to the station, picks a Sock and its mate, and they pair"},
		{"name": "e03_records", "method": "case_e03_records", "world": false,
				"title": "E03: every Sock of the station is a lying record of the zoo's one Mess, as its Design"},
		{"name": "e04", "method": "case_e04", "world": false,
				"title": "E04: a Sock moved in one zoo lies in its place in the next, and the zoo writes nothing to the user's folder"},
		{"name": "e05", "method": "case_e05", "world": false,
				"title": "E05: the station is off the grid, its pad inside the zoo's floor and every Sock inside the Mess's bounds"},
		{"name": "e06", "method": "case_e06", "world": false,
				"title": "E06: a Design added to the catalogue appears in the station with no other change, alone and in the zoo"},
	]


func _before_case() -> void:
	Input.action_release(&"pick")
	if _zoo != null:
		_zoo.free()
		_zoo = null
	if _alone != null:
		_alone.free()
		_alone = null


func case_e01() -> void:
	_zoo_node()
	var st := _station()
	var cat := st.catalogue
	var layout := st.layout
	_check(st.spots.get_child_count() == cat.size() * 2, "two SockSpots for each of the %d Designs (%d)" % [cat.size(), st.spots.get_child_count()])
	var order := st.collections()
	var last_z := 1.0
	var seen := 0
	for c in order:
		var ids := st.designs_of(c)
		var title := st.labels.get_node_or_null("Name_%s" % c) as Label3D
		_check(title != null and title.text == String(c).capitalize(), "Collection %s has its name" % c)
		if title == null:
			continue
		_check(title.position.z < last_z, "Collection %s starts further on than the one before" % c)
		_check(title.position.x < (st.spots.get_node("d%d_a" % ids[0]) as Node3D).position.x, "its name stands left of its first row")
		last_z = title.position.z
		var prev := Vector3(-INF, 0.0, 1.0)
		for id in ids:
			seen += 1
			var a := st.spots.get_node_or_null("d%d_a" % id) as SockSpot
			var b := st.spots.get_node_or_null("d%d_b" % id) as SockSpot
			if a == null or b == null:
				_check(false, "Design %d has both Socks" % id)
				continue
			if not (a.design == id and b.design == id and is_equal_approx(a.position.z, b.position.z)
					and is_equal_approx(b.position.x - a.position.x, layout.mate_gap)):
				_check(false, "Design %d: its two Socks lie side by side (%s, %s)" % [id, a.position, b.position])
			var after := a.position.z < prev.z or (is_equal_approx(a.position.z, prev.z) and a.position.x > prev.x)
			if not after:
				_check(false, "Design %d follows the one before it in the row order" % id)
			prev = a.position
	_check(seen == cat.size(), "every Design belongs to a block (%d of %d)" % [seen, cat.size()])
	_check(order.size() > 1, "there are several Collections (%d)" % order.size())


func case_e02() -> void:
	_zoo_node()
	var st := _station()
	var bad := 0
	for id in st.catalogue.size():
		var d := st.catalogue.design(id)
		var label := st.labels.get_node_or_null("d%d" % id) as Label3D
		var a := st.spots.get_node("d%d_a" % id) as Node3D
		var b := st.spots.get_node("d%d_b" % id) as Node3D
		var text := "" if label == null else label.text
		var ok := label != null and text.contains(str(d.id)) and text.contains(d.name) and text.contains(String(d.collection)) \
				and text.contains(SockDesign.Size.keys()[d.size].to_lower()) and text.contains(SockDesign.Rarity.keys()[d.rarity].to_lower())
		ok = ok and label.position.z > a.position.z and label.position.x > a.position.x and label.position.x < b.position.x \
				and label.global_transform.basis.z.dot(Vector3.UP) > 0.99
		if not ok:
			bad += 1
			if bad < 4:
				_check(false, "Design %d's info lies in front of its pair (%s)" % [id, text])
	_check(bad == 0, "every Design has its info in front of its Socks, lying face up (%d wrong)" % bad)
	var first := st.catalogue.design(0)
	_check(EverySockStation.info(first) == "%d %s\n%s\n%s, %s" % [first.id, first.name, first.collection,
			SockDesign.Size.keys()[first.size].to_lower(), SockDesign.Rarity.keys()[first.rarity].to_lower()],
			"the wording: id and name, Collection, then Size and rarity (%s)" % EverySockStation.info(first).replace("\n", " | "))


func case_e03() -> void:
	await _zoo_up()
	var st := _station()
	var mess := _zoo.get_node("Socks/Mess") as Mess
	var hands := _zoo.get_node("Socks/Hands") as Hands
	var first := st.spots.get_node("d40_a") as SockSpot
	var sock := first.sock
	var mate := (st.spots.get_node("d40_b") as SockSpot).sock
	_check(sock >= 0 and mate == sock + 1, "a Design's two Socks are neighbours in the Mess (%d, %d)" % [sock, mate])
	_stand(st, Vector3(first.position.x + 0.2, 0.0, first.position.z + 1.2))
	await _aim(_centre(mess, sock))
	await _press(&"pick")
	await _until(func() -> bool: return hands.active_of(1) == sock, "the first Sock to be in the Hands")
	await _physics_ticks(25)
	await _aim(_centre(mess, mate))
	await _press(&"pick")
	await _until(func() -> bool: return mess.is_pair(sock), "the mate to fuse into a Pair")


func case_e03_records() -> void:
	await _zoo_up()
	var st := _station()
	var mess := _zoo.get_node("Socks/Mess") as Mess
	_check(st.get_node_or_null(ZooStations.SOCKS) == null, "the station has no Socks of its own in the zoo")
	var bad := 0
	for node in st.spots.get_children():
		var spot := node as SockSpot
		if not (spot.sock >= 0 and mess.state_of(spot.sock) == Mess.State.LYING and mess.designs[spot.sock] == spot.design
				and mess.pose_of(spot.sock).origin.distance_to(spot.global_position) < 0.001):
			bad += 1
	_check(bad == 0, "every SockSpot is a lying record of the zoo's Mess, as its Design, where it was laid (%d wrong)" % bad)
	_check(mess.looks_of(mess.count() - 1) != null, "the last Sock is drawn")


func case_e04() -> void:
	var before := _user_files()
	await _zoo_up()
	var st := _station()
	var mess := _zoo.get_node("Socks/Mess") as Mess
	var hands := _zoo.get_node("Socks/Hands") as Hands
	var sock := (st.spots.get_node("d3_a") as SockSpot).sock
	var where := mess.pose_of(sock).origin
	_stand(st, Vector3(-12.0, 0.0, 1.2))
	await _physics_ticks(2)
	hands.clock += 10.0
	hands.pick(1, sock)
	await _physics_ticks(2)
	_check(mess.state_of(sock) == Mess.State.HELD, "the Sock was taken in the first zoo")
	_zoo.free()
	_zoo = null
	await _zoo_up()
	st = _station()
	mess = _zoo.get_node("Socks/Mess") as Mess
	var again := (st.spots.get_node("d3_a") as SockSpot).sock
	_check(again == sock and mess.state_of(again) == Mess.State.LYING and mess.pose_of(again).origin.is_equal_approx(where),
			"in the next zoo the Sock lies in its place again")
	_check(_user_files() == before, "the zoo wrote nothing to user:// (%s)" % [_user_files()])


func case_e05() -> void:
	await _zoo_up()
	var st := _station()
	var mess := _zoo.get_node("Socks/Mess") as Mess
	var on_grid := false
	for n in 40:
		if ZooStations.place(n).distance_to(st.position) < 1.0:
			on_grid = true
	_check(not on_grid, "its place %s is no place of the grid" % st.position)
	var ends := true
	for station in _zoo.get_node("Stations").get_children():
		if station != st:
			ends = ends and station.position.z > st.position.z
	_check(ends, "it lies further from the spawn than every other station")
	var pad := st.get_node("Pad") as MeshInstance3D
	var box := pad.global_transform * pad.get_aabb()
	var floor_mesh := _zoo.get_node("Floor/Mesh") as MeshInstance3D
	var floor_box := floor_mesh.global_transform * floor_mesh.get_aabb()
	_check(box.position.x >= floor_box.position.x and box.end.x <= floor_box.end.x
			and box.position.z >= floor_box.position.z and box.end.z <= floor_box.end.z,
			"its pad lies inside the zoo's floor (%s in %s)" % [box, floor_box])
	var outside := 0
	for node in st.spots.get_children():
		if not mess.in_bounds((node as Node3D).global_position + Vector3(0.0, 0.1, 0.0)):
			outside += 1
	_check(outside == 0, "every Sock lies inside the Mess's bounds (%d outside)" % outside)
	_check(st.scene_file_path == STATION and (st.get_node("Name") as Label3D).text != "", "it is one scene file, named")


func case_e06() -> void:
	var cat := (load("res://game/sock/designs.tres") as DesignCatalogue).duplicate() as DesignCatalogue
	var extra := SockDesign.new()
	extra.id = cat.size()
	extra.name = "Zebra"
	extra.collection = &"newcomers"
	extra.size = SockDesign.Size.LARGE
	extra.rarity = SockDesign.Rarity.RARE
	var list: Array[SockDesign] = cat.designs.duplicate()
	list.append(extra)
	cat.designs = list
	_alone = (load(STATION) as PackedScene).instantiate() as Node3D
	var st := _alone as EverySockStation
	st.catalogue = cat
	add_child(_alone)
	await _frames(2)
	_check(st.collections()[-1] == &"newcomers", "the new Design's Collection is a block of its own")
	_check(st.spots.get_node_or_null("d%d_a" % extra.id) != null and st.spots.get_node_or_null("d%d_b" % extra.id) != null,
			"both Socks of the new Design lie there")
	_check((st.labels.get_node("d%d" % extra.id) as Label3D).text.contains("Zebra"), "its info lies in front")
	_check(st.labels.get_node_or_null("Name_newcomers") != null, "its Collection has a name")
	var mess := st.get_node("Socks/Mess") as Mess
	_check(mess.count() == cat.size() * 2, "played alone the station's own Mess holds every Sock (%d of %d)" % [mess.count(), cat.size() * 2])


# --- helpers ------------------------------------------------------------------------------------

func _zoo_node() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)


func _station() -> EverySockStation:
	return _zoo.get_node(FOLDER) as EverySockStation


func _zoo_up() -> void:
	_zoo_node()
	var mess := _zoo.get_node("Socks/Mess") as Mess
	var player := _zoo.get_node("Player") as Player
	await _until(func() -> bool: return player.is_on_floor() and mess.looks_of(mess.count() - 1) != null, "the player to stand and every Sock to lie", 600)


func _user_files() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at("user://"):
		out.append(f)
	out.sort()
	return out


func _stand(station: Node3D, at: Vector3) -> void:
	var player := _zoo.get_node("Player") as Player
	player.global_position = station.to_global(at)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


func _aim(target: Vector3) -> void:
	var player := _zoo.get_node("Player") as Player
	player.capture_mouse()   # the mouse is the player's: buttons act (R01)
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


func _centre(mess: Mess, sock: int) -> Vector3:
	if mess.is_pair(sock):
		return mess.pose_of(sock).origin
	return mess.pose_of(sock) * Vector3(0.0, SockDress.box(mess.design_of(sock)).y * 0.5, 0.0)
