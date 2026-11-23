## The Sock generator (core/52, Q2518-Q2528): SockAreas lay their Pairs on open floor, tops, insides and
## under-gaps, a SockTrail up the stairs, nothing in a SockExclusion or in front of a Cabinet; the Socks
## lie where the preview shows, from the seed, the same on every machine; "New seed" lays them again.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const FOLDER := "Stations/SockGenerator"

var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the station's Socks lie at start where the preview shows; the player clicks New seed and the next seed's Socks replace them, lying, where its preview shows"},
		{"name": "g01_places", "method": "case_places", "world": false,
				"title": "G01: every Sock lies in an area (or on its trail) on a surface, of every kind (floor, top, inside, under, trail), the hidden share inside and under"},
		{"name": "g02_keep_out", "method": "case_keep_out", "world": false,
				"title": "G02: no Sock meets the house, an exclusion, the box in front of the Cabinet or another Sock (a Heap's press at most)"},
		{"name": "g03_pairs", "method": "case_pairs", "world": false,
				"title": "G03: both Socks of each Pair's Design are laid, about a Mate distance apart in a straight line"},
		{"name": "g04_seed", "method": "case_seed", "world": false,
				"title": "G04: the same seed lays the same Socks; another seed others; changing one area moves no other area's Socks"},
		{"name": "g05_heap_strips", "method": "case_heap_strips", "world": false,
				"title": "G05: a Heap area piles Socks on Socks, a flat area never; under furniture a Sock lies in a strip along an open edge"},
		{"name": "g06_coop", "method": "case_coop", "world": false,
				"title": "G06: the Host's regeneration reaches a Guest whole; a late joiner sees the Host's Socks; a Guest may not add Socks or regenerate from afar"},
		{"name": "g07_new_seed", "method": "case_new_seed", "world": false,
				"title": "G07: with a new seed each start the generator picks its own seed, kept in its state, and lays from it"},
		{"name": "g08_preview", "method": "case_preview", "world": false,
				"title": "G08: the preview draws a dot per landing point and the areas' boxes, only when asked in a game"},
	]


func _before_case() -> void:
	Input.action_release(&"pick")
	if _zoo != null:
		_zoo.free()
		_zoo = null


func case_real_path() -> void:
	await _zoo_up()
	var mess := _mess()
	var gen := _generated()
	var player := LevelRuntime.of(_zoo).player
	_check(gen.first >= 0 and gen.socks > 0, "the station's Socks were laid at start (%d from %d)" % [gen.socks, gen.first])
	_matches_preview(gen.seed, "at start")
	var seed_before := gen.seed
	var old_first := gen.first
	var button := _station().get_node("Regenerate") as Node3D
	_stand(button.global_position + Vector3(-1.5, -0.5, 0.0))
	await _aim(button.global_position)
	await _press(&"pick")
	await _until(func() -> bool: return gen.seed == seed_before + 1, "the click on New seed to lay the next seed's Socks")
	await _physics_ticks(2)
	_check(gen.socks > 0, "the next seed laid Socks (%d)" % gen.socks)
	_matches_preview(gen.seed, "after New seed")
	var old_left := 0
	for sock in range(old_first, mini(old_first + gen.socks, mess.count())):
		if sock < gen.first and mess.state_of(sock) == Mess.State.LYING:
			old_left += 1
	_check(old_left == 0, "the old seed's Socks are gone (%d still lie)" % old_left)


func case_places() -> void:
	await _zoo_up()
	var gen := _generator()
	var laying := gen.lay(_generated().seed, _before())
	var kinds: Dictionary[int, int] = {}
	var outside := 0
	var floating := 0
	var areas := _areas()
	for row: Dictionary in laying.rows:
		var pose: Transform3D = row["pose"]
		var kind := int(row["kind"])
		kinds[kind] = kinds.get(kind, 0) + 1
		if kind != SockArea.Kind.TRAIL and not areas.any(func(a: SockArea) -> bool: return a.has_point(pose.origin)):
			outside += 1
		if not _on_surface(pose, laying):
			floating += 1
	for k: int in SockArea.Kind.values():
		_check(kinds.get(k, 0) > 0, "Socks of kind %s are laid (%d)" % [SockArea.Kind.keys()[k], kinds.get(k, 0)])
	_check(outside == 0, "every Sock lies in an area or on its trail (%d outside)" % outside)
	_check(floating == 0, "every Sock rests on the house or on a Sock under it (%d floating)" % floating)
	_check(laying.left_out.is_empty() and laying.rows.size() == laying.asked, "every Sock asked found a place (%d of %d, %s)" % [laying.rows.size(), laying.asked, laying.left_out])
	# The hidden share: inside and under, of the areas' Socks (the trail's are no area's).
	var area_socks: int = laying.rows.size() - kinds.get(SockArea.Kind.TRAIL, 0)
	var hidden: int = kinds.get(SockArea.Kind.INSIDE, 0) + kinds.get(SockArea.Kind.UNDER, 0)
	var want := 0
	for a in areas:
		want += roundi(a.pairs * 2 * a.hidden_share)
	var moved := 0
	for area_name: String in laying.hidden_to_floor:
		moved += laying.hidden_to_floor[area_name]
	_check(hidden + moved == want and hidden * 2 >= want, "the hidden share lies inside and under furniture, the rest of it on open floor when every hidden place is full (%d hidden, %d moved, want %d of %d)" % [hidden, moved, want, area_socks])


func case_keep_out() -> void:
	await _zoo_up()
	var gen := _generator()
	var laying := gen.lay(_generated().seed, _before())
	var box := gen.tuning.place_box
	var probe := BoxShape3D.new()
	probe.size = box - Vector3(0.006, 0.006, 0.006)
	var in_house := 0
	var kept := 0
	var meets := 0
	var keep_out := _keep_out()
	for i in laying.rows.size():
		var a: Dictionary = laying.rows[i]
		var ca := _centre(a["pose"], box)
		var lifted := Transform3D(ca.basis, ca.origin + (a["pose"] as Transform3D).basis.y * 0.004)
		# A trail's Sock on a stair's tread lies under the stair's walking ramp (house/05, Q2530): that one body is not counted.
		var skip: Array[RID] = []
		var tread := PhysicsQueries.ray(gen, ca.origin, ca.origin + Vector3.DOWN * 0.1, SockTrail.LAYER_TREADS)
		if int(a["kind"]) == SockArea.Kind.TRAIL and not tread.is_empty():
			skip.append(((tread["collider"] as Node).get_parent().get_node("Body") as CollisionObject3D).get_rid())
		if not PhysicsQueries.overlap_colliders(gen, probe, lifted, Mess.LAYER_HOUSE, 1, skip).is_empty():
			in_house += 1
		for k: Array in keep_out:
			if MessBodies.boxes_meet(box, ca, k[0], k[1]):
				kept += 1
		for j in range(i + 1, laying.rows.size()):
			var b: Dictionary = laying.rows[j]
			var depth := MessBodies.overlap_depth(box, ca, box, _centre(b["pose"], box))
			if depth > SockLaying.HEAP_PRESS + 0.0001:
				meets += 1
	_check(keep_out.size() >= 2, "the station keeps a hand-placed box and the Cabinet's front clear (%d boxes)" % keep_out.size())
	_check(in_house == 0, "no Sock meets the house (%d do)" % in_house)
	_check(kept == 0, "no Sock touches an exclusion or the Cabinet's front (%d do)" % kept)
	_check(meets == 0, "no two Socks overlap more than a Heap's press (%d do)" % meets)
	# In the game: the records' own Socks meet none of the Mess's other lying Socks.
	var mess := _mess()
	var g := _generated()
	var others := mess.lying_boxes(g.first, g.first + g.socks)
	var touching := 0
	for sock in range(g.first, g.first + g.socks):
		var size := SockDress.box(mess.design_of(sock))
		var c := mess.pose_of(sock) * Transform3D(Basis.IDENTITY, Vector3(0.0, size.y * 0.5, 0.0))
		for o: Array in others:
			if MessBodies.boxes_meet(size, c, o[0], o[1]):
				touching += 1
	_check(touching == 0, "the generated Socks meet no other lying Sock of the Mess (%d do)" % touching)


func case_pairs() -> void:
	await _zoo_up()
	var mess := _mess()
	var g := _generated()
	var by_design: Dictionary[int, Array] = {}
	for sock in range(g.first, g.first + g.socks):
		if not by_design.has(mess.designs[sock]):
			by_design[mess.designs[sock]] = []
		by_design[mess.designs[sock]].append(sock)
	var odd := 0
	var dists: Array[float] = []
	for d: int in by_design:
		var socks: Array = by_design[d]
		if socks.size() != 2:
			odd += 1
			continue
		dists.append(mess.pose_of(socks[0]).origin.distance_to(mess.pose_of(socks[1]).origin))
	_check(g.socks % 2 == 0 and odd == 0, "every Design laid has both its Socks (%d Socks, %d Designs not two)" % [g.socks, odd])
	dists.sort()
	var t := _generator().tuning
	_check(not dists.is_empty() and dists[0] < t.mate_min + 1.0 and dists[-1] > t.mate_max * 0.5,
			"Mates lie from about %.1f to %.1f m apart (%.2f to %.2f)" % [t.mate_min, t.mate_max, dists[0] if not dists.is_empty() else -1.0, dists[-1] if not dists.is_empty() else -1.0])


func case_seed() -> void:
	await _zoo_up()
	var gen := _generator()
	var seed := _generated().seed
	var a := _origins(gen.lay(seed, _before()).rows)
	var b := _origins(gen.lay(seed, _before()).rows)
	_same(a, b, "the same seed lays the same Socks")
	var c := _origins(gen.lay(seed + 7, _before()).rows)
	_check(a != c, "another seed lays other Socks")
	var bedroom := gen.get_node("Bedroom") as SockArea
	var by_area := _by_area(gen.lay(seed, _before()).rows)
	bedroom.pairs = 5
	var changed := _by_area(gen.lay(seed, _before()).rows)
	_same(changed.get("Kitchen", []), by_area.get("Kitchen", []), "fewer Pairs in the bedroom move nothing in the kitchen")
	_same(changed.get("Living", []), by_area.get("Living", []), "fewer Pairs in the bedroom move nothing in the living room")
	_check(changed.get("Bedroom", []).size() < by_area.get("Bedroom", []).size(), "the bedroom lays fewer Socks")


func case_heap_strips() -> void:
	await _zoo_up()
	var gen := _generator()
	var laying := gen.lay(_generated().seed, _before())
	var living := gen.get_node("Living") as SockArea
	var stacked := 0
	var flat_stacked := 0
	var strips_off := 0
	var unders := 0
	for row: Dictionary in laying.rows:
		var pose: Transform3D = row["pose"]
		var floor_hit := PhysicsQueries.ray(gen, pose.origin + Vector3.UP * 0.01, pose.origin + Vector3.DOWN * 3.0, Mess.LAYER_HOUSE)
		var over := pose.origin.y - (floor_hit["position"] as Vector3).y if not floor_hit.is_empty() else 0.0
		if int(row["kind"]) == SockArea.Kind.FLOOR:
			if living.has_point(pose.origin):
				if over > 0.015:
					stacked += 1
			elif over > 0.015:
				flat_stacked += 1
		if int(row["kind"]) == SockArea.Kind.UNDER:
			unders += 1
			var piece := _piece_under(pose.origin)
			if piece == null:
				strips_off += 1
				continue
			var fp: Array = piece.get_meta(&"footprint")
			var local := piece.global_transform.affine_inverse() * pose.origin
			var to_edge := minf(float(fp[0]) * 0.5 - absf(local.x), float(fp[1]) * 0.5 - absf(local.z))
			if to_edge > SockPlaces.UNDER_INSET + gen.tuning.strip_high + gen.tuning.place_box.x * 0.5:
				strips_off += 1
	_check(stacked > 0, "the Heap area's floor Socks pile on each other (%d over the floor)" % stacked)
	_check(flat_stacked == 0, "a flat area's floor Socks never stack (%d do)" % flat_stacked)
	_check(unders > 0 and strips_off == 0, "under furniture every Sock lies near an open edge (%d of %d not)" % [strips_off, unders])


func case_coop() -> void:
	await _zoo_up()
	var mess := _mess()
	var parts := LevelRuntime.of(_zoo).parts
	var gen := _generated()
	var row := Mess.pack(Transform3D(Basis.IDENTITY, _station().global_position + Vector3.UP))
	var guest_add := parts.answer(Command.new(&"add", 2, mess.id, {"designs": PackedInt32Array([0]), "poses": row, "lying": true}))
	_check(not guest_add["ok"], "a Guest may not add lying Socks (%s)" % guest_add.get("reason"))
	_check(gen.accepts().has(&"regenerate") and not mess.accepts().has(&"add"), "a Guest may ask a regeneration, never an add")
	_stand(_station().to_global(Vector3(0.0, 0.0, 40.0)))
	var far := parts.answer(Command.new(&"regenerate", 1, gen.id, {}))
	_check(not far["ok"] and far.get("reason") == "far", "a regeneration is refused far from the station (%s)" % far.get("reason"))
	# A late joiner before the regeneration: it takes the snapshot, then the Host's answer.
	var late := (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(late)
	await _until(func() -> bool: return LevelRuntime.of(late).mess.body_count() > 0, "the late zoo to bind")
	var late_parts := LevelRuntime.of(late).parts
	late_parts.load_snapshot(parts.snapshot())
	await _physics_ticks(2)
	var late_mess := LevelRuntime.of(late).mess
	var late_gen := late_parts.of(gen.id) as GeneratedSocks
	_same(late_mess.state(), mess.state(), "the late joiner's Mess is the Host's")
	_same(late_gen.state(), gen.state(), "the late joiner's generator state is the Host's")
	_stand(_station().to_global(Vector3(0.0, 0.0, 6.0)))
	var ev := parts.answer(Command.new(&"regenerate", Parts.HOST, gen.id, {}))
	_check(ev["ok"], "the Host lays the next seed (%s)" % ev.get("reason"))
	parts.apply(ev)
	late_parts.apply(ev)
	await _physics_ticks(2)
	_same(late_mess.state(), mess.state(), "after the regeneration the Guest's Mess is the Host's")
	_same(late_gen.state(), gen.state(), "after the regeneration the Guest's generator state is the Host's")
	_check(late_mess.body_count() == mess.body_count(), "the Guest has a lying body for every Sock (%d, %d)" % [late_mess.body_count(), mess.body_count()])
	var flying := 0
	for sock in range(gen.first, gen.first + gen.socks):
		if mess.state_of(sock) != Mess.State.LYING or mess.throws.has(sock):
			flying += 1
	_check(flying == 0, "the new Socks lie at once, none falls (%d not lying)" % flying)
	late.free()


func case_new_seed() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	(_zoo.get_node(FOLDER + "/Generator") as SockGenerator).new_seed_each_start = true
	add_child(_zoo)
	await _settle_zoo()
	var gen := _generated()
	_check(gen.seed != _generator().seed or gen.seed == 0, "a seed of its own is picked (%d, the level's %d)" % [gen.seed, _generator().seed])
	_check(gen.state().get("seed") == gen.seed, "the seed is in the generator's state (it goes with a snapshot and a save)")
	_matches_preview(gen.seed, "from the picked seed")


func case_preview() -> void:
	await _zoo_up()
	var gen := _generator()
	var count_before := gen.get_child_count(true)
	_check(count_before == gen.get_child_count(), "a game draws no preview unless asked (%d internal children)" % (count_before - gen.get_child_count()))
	var rows := gen.lay(_generated().seed, _before()).rows
	gen.show_preview(true, _generated().seed, _before())
	var dots: MultiMeshInstance3D = null
	for child in gen.get_children(true):
		if child is MultiMeshInstance3D:
			dots = child
	_check(dots != null and dots.multimesh.instance_count == rows.size(), "a dot per landing point (%d, %d)" % [dots.multimesh.instance_count if dots != null else -1, rows.size()])
	var area := gen.get_node("Bedroom") as SockArea
	var boxes := area.get_children(true).filter(func(c: Node) -> bool: return c is MeshInstance3D and (c as MeshInstance3D).visible)
	_check(boxes.size() == 1, "an area draws its translucent box when asked")
	gen.show_preview(false, 0)
	await _frames(1)
	var left := gen.get_children(true).filter(func(c: Node) -> bool: return c is MultiMeshInstance3D and not c.is_queued_for_deletion())
	_check(left.is_empty(), "hiding the preview takes the dots away")


## The Mess's records of the generator equal its records for `seed` and lie on the preview's points.
func _matches_preview(seed: int, when: String) -> void:
	var mess := _mess()
	var g := _generated()
	var made := _generator().records(seed, mess.catalogue, mess.lying_boxes(g.first, g.first + g.socks))
	_same(mess.designs.slice(g.first, g.first + g.socks), made["designs"], "%s: the Socks' Designs are the seed's" % when)
	_same(mess.poses.slice(g.first * Mess.POSE, (g.first + g.socks) * Mess.POSE), made["poses"], "%s: the Socks lie where the seed lays them" % when)
	var preview := _origins(_generator().lay(seed, mess.lying_boxes(g.first, g.first + g.socks)).rows)
	var off := 0
	for sock in range(g.first, g.first + g.socks):
		if mess.state_of(sock) != Mess.State.LYING or not mess.is_drawn(sock):
			off += 1
		elif not preview.has(_key(mess.pose_of(sock).origin)):
			off += 1
	_check(off == 0, "%s: every Sock lies, drawn, on a point of the preview (%d not)" % [when, off])


func _origins(rows: Array[Dictionary]) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for r in rows:
		out.append(_key((r["pose"] as Transform3D).origin))
	out.sort()
	return out


func _by_area(rows: Array[Dictionary]) -> Dictionary:
	var out := {}
	for r in rows:
		var p := (r["pose"] as Transform3D).origin
		var name := "Trail"
		for a in _areas():
			if a.has_point(p):
				name = a.name
		if not out.has(name):
			out[name] = []
		(out[name] as Array).append(_key(p))
	for k: String in out:
		(out[k] as Array).sort()
	return out


static func _key(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 1000.0), roundi(p.y * 1000.0), roundi(p.z * 1000.0))


static func _centre(pose: Transform3D, box: Vector3) -> Transform3D:
	return pose * Transform3D(Basis.IDENTITY, Vector3(0.0, box.y * 0.5, 0.0))


## Whether a Sock at `pose` rests on the house, or on another Sock's top, within 1 cm under it.
func _on_surface(pose: Transform3D, laying: SockLaying) -> bool:
	var down := pose.basis.y.normalized()
	var hit := PhysicsQueries.ray(_generator(), pose.origin + down * 0.01, pose.origin - down * 0.02, Mess.LAYER_HOUSE)
	if not hit.is_empty():
		return true
	var box := laying.tuning.place_box
	for r: Dictionary in laying.rows:
		var o: Transform3D = r["pose"]
		var top := o.origin.y + box.y
		if absf(top - pose.origin.y) < 0.01 and MessBodies.boxes_meet(box, _centre(pose, box).translated(Vector3.DOWN * 0.01), box, _centre(o, box)):
			return true
	return false


func _piece_under(p: Vector3) -> Node3D:
	for node in _station().get_children():
		if node is Node3D and node.has_meta(&"crawl_gap"):
			var piece := node as Node3D
			var fp: Array = piece.get_meta(&"footprint")
			var local := piece.global_transform.affine_inverse() * p
			if absf(local.x) <= float(fp[0]) * 0.5 and absf(local.z) <= float(fp[1]) * 0.5 and local.y < float(piece.get_meta(&"crawl_gap")):
				return piece
	return null


func _keep_out() -> Array[Array]:
	var out: Array[Array] = []
	var gen := _generator()
	out.append((gen.get_node("Doorway") as SockExclusion).box())
	for a in _areas():
		var places := SockPlaces.new(a, gen.tuning, _station(), null, [])
		out.append_array(places.keep_out)
	return out


func _areas() -> Array[SockArea]:
	var out: Array[SockArea] = []
	for c in _generator().get_children():
		if c is SockArea:
			out.append(c as SockArea)
	return out


func _before() -> Array[Array]:
	var g := _generated()
	return _mess().lying_boxes(g.first, g.first + g.socks)


func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	await _settle_zoo()


func _settle_zoo() -> void:
	var mess := _mess()
	var player := LevelRuntime.of(_zoo).player
	await _until(func() -> bool: return player.is_on_floor() and mess.looks_of(mess.count() - 1) != null, "the player to stand and every Sock to lie", 600)
	mess.return_looks(mess.count() - 1)
	player.capture_mouse()


func _mess() -> Mess:
	return LevelRuntime.of(_zoo).mess


func _station() -> Node3D:
	return _zoo.get_node(FOLDER) as Node3D


func _generator() -> SockGenerator:
	return _station().get_node("Generator") as SockGenerator


func _generated() -> GeneratedSocks:
	return _station().get_node("Generator/Generated") as GeneratedSocks


func _stand(at: Vector3) -> void:
	var player := LevelRuntime.of(_zoo).player
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


func _aim(target: Vector3) -> void:
	var player := LevelRuntime.of(_zoo).player
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
