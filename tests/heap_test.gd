## The heap station (core/20, H01-H07): a spout pours real Mess Socks in waves under the moving
## budget; "More" pours another batch, "Respill" clears the heap and pours afresh; a counter sign
## shows moving, waiting and resting Socks and the tick; walls, a slope and a table hold the heap.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const FOLDER := "Stations/Heap"
## A small batch for the rule cases (the shipped 500 is the real path's and the timing's).
const SMALL := 60

var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "H02, H06, real path: the player clicks More, Socks pour and come to rest, the player picks one from under another and the one on top falls"},
		{"name": "h01", "method": "case_h01", "world": false,
				"title": "H01: the spout pours in waves, each Sock a moving body under the budget, and every one rests into the Mess"},
		{"name": "h02", "method": "case_h02", "world": false,
				"title": "H02: a batch is both Socks of each Design it picks; the next batch walks on, Designs may repeat"},
		{"name": "h03", "method": "case_h03", "world": false,
				"title": "H03: Respill clears the station's Socks and pours a fresh batch; a held one stays held"},
		{"name": "h04", "method": "case_h04", "world": false,
				"title": "H04: the counter sign shows moving, waiting and resting Socks and the physics tick"},
		{"name": "h05", "method": "case_h05", "world": false,
				"title": "H05: low walls round the pad keep the heap on it; a slope and a table stand in it"},
		{"name": "r4_no_designs", "method": "case_r4", "world": false,
				"title": "R4: when the catalogue gives no Design, queuing a batch gives up instead of spinning"},
		{"name": "h07", "method": "case_h07", "world": false,
				"title": "H07: new Socks come only through the Mess's Host-only add; a late joiner's snapshot holds the same heap; nothing is saved"},
		{"name": "ticks", "method": "case_ticks", "world": false, "stress": true,
				"title": "the physics tick while pouring and at rest, with 500 and with 2,000 poured Socks (printed for the report)"},
	]


func _before_case() -> void:
	Input.action_release(&"pick")
	if _zoo != null:
		_zoo.free()
		_zoo = null


func case_real_path() -> void:
	await _zoo_up()
	var mess := _mess()
	var player := LevelRuntime.of(_zoo).player
	var hands := LevelRuntime.of(_zoo).hands
	var spout := _spout()
	var before := mess.count()
	var more := _station().get_node("More") as Node3D
	_stand(more.global_position + _station().global_basis * Vector3(0.0, -0.5, -1.5))
	await _aim(more.global_position)
	await _press(&"pick")
	await _until(func() -> bool: return mess.count() > before, "the click on More to pour Socks")
	await _settled(spout.tuning.batch)
	_check(mess.count() - before == spout.tuning.batch, "one batch of %d Socks poured (%d)" % [spout.tuning.batch, mess.count() - before])
	# A heap Sock with another resting on it, its own part in sight from somewhere near.
	var under := -1
	var over := -1
	for found: Array in _under_and_over(player, spout.first):
		_stand(found[2])
		await _aim(found[3])
		if player.aimed_sock == found[0]:
			under = found[0]
			over = found[1]
			break
	_check(under >= 0, "a Sock of the heap lies under another and the crosshair rests on it")
	if under < 0:
		return
	await _press(&"pick")
	await _until(func() -> bool: return hands.active_of(1) == under, "the lower Sock to be in the Hands")
	await _until(func() -> bool: return mess.state_of(over) == Mess.State.FLYING, "the Sock on top of it to fall")


func case_h01() -> void:
	await _zoo_up()
	var mess := _mess()
	var spout := _small()
	var before := mess.count()
	_ask(&"more")
	var budget := mess.bodies_tuning().moving_budget - mess.bodies_tuning().throw_reserve
	var waves := 0
	var most_a_wave := 0
	var most_moving := 0
	var last := before
	for i in 600:
		await _physics_ticks(1)
		if mess.count() > last:
			waves += 1
			most_a_wave = maxi(most_a_wave, mess.count() - last)
			last = mess.count()
		most_moving = maxi(most_moving, mess.moving_count())
		if spout.pending() == 0 and _heap_flying(spout.first) == 0:
			break
	_check(mess.count() - before == SMALL, "the whole batch entered (%d of %d)" % [mess.count() - before, SMALL])
	_check(waves >= 2, "it poured in waves (%d)" % waves)
	_check(most_a_wave <= spout.tuning.per_tick, "at most %d a wave (%d)" % [spout.tuning.per_tick, most_a_wave])
	_check(most_moving <= budget, "never more moving than the budget's general share (%d of %d)" % [most_moving, budget])
	await _settled(SMALL)
	var lying := 0
	for sock in range(spout.first, mess.count()):
		if mess.state_of(sock) == Mess.State.LYING and mess.is_drawn(sock) and mess.box_of(sock).has_volume():
			lying += 1
	_check(lying == SMALL, "every poured Sock rests as a lying body, drawn (%d of %d)" % [lying, SMALL])


func case_h02() -> void:
	await _zoo_up()
	var mess := _mess()
	var spout := _small()
	_ask(&"more")
	await _settled(SMALL)
	_ask(&"more")
	await _settled(SMALL * 2)
	var per: Dictionary[int, int] = {}
	for sock in range(spout.first, mess.count()):
		per[mess.designs[sock]] = per.get(mess.designs[sock], 0) + 1
	var odd := 0
	for design: int in per:
		if per[design] % 2 != 0:
			odd += 1
	_check(odd == 0, "every Design poured has both its Socks (%d odd)" % odd)
	_check(per.size() == SMALL, "two batches of %d pour %d Designs, the second walking on (%d)" % [SMALL, SMALL, per.size()])
	_check(mess.count_of(mess.designs[spout.first]) > 2, "a Design may be in the zoo more than twice (%d records)" % mess.count_of(mess.designs[spout.first]))


func case_h03() -> void:
	await _zoo_up()
	var mess := _mess()
	var hands := LevelRuntime.of(_zoo).hands
	var spout := _small()
	var base := mess.count()
	_ask(&"more")
	await _settled(SMALL)
	# The player holds one of the heap's Socks (the last record) as Respill is pressed.
	var held := mess.count() - 1
	_stand(Vector3(mess.pose_of(held).origin.x, _station().global_position.y, mess.pose_of(held).origin.z + 1.0))
	LevelRuntime.of(_zoo).parts.ask(Command.new(&"pick", 1, hands.id, {"sock": held}))
	await _until(func() -> bool: return hands.active_of(1) == held, "a heap Sock to be held")
	var respill := _station().get_node("Respill") as Node3D
	_stand(respill.global_position + _station().global_basis * Vector3(0.0, -0.5, -1.5))
	await _aim(respill.global_position)
	await _press(&"pick")
	await _until(func() -> bool: return spout.respills == 1, "the click on Respill to be answered")
	await _until(func() -> bool: return mess.state_of(spout.first) != Mess.State.LYING, "the old heap to go")
	await _until(func() -> bool: return _rested(0) and _lying(base, mess.count()) >= SMALL, "the fresh batch to rest", 1200)
	var gone := 0
	for sock in range(base, held):
		if mess.state_of(sock) == Mess.State.GONE:
			gone += 1
	_check(gone == held - base, "every old heap Sock left the Mess (%d of %d)" % [gone, held - base])
	_check(mess.state_of(held) == Mess.State.HELD and hands.active_of(1) == held, "the held one stays held, its id the same")
	_check(mess.count() == held + 1 + SMALL, "a fresh batch poured after it (%d records past it)" % (mess.count() - held - 1))
	_check(mess.box_of(base) == AABB() and not mess.is_drawn(base), "a gone Sock has no body and is not drawn")


func case_h04() -> void:
	await _zoo_up()
	var mess := _mess()
	var spout := _small()
	var counter := _station().get_node("Counter") as HeapCounter
	_ask(&"more")
	await _until(func() -> bool: return not counter.text.contains("Moving 0\n"), "the sign to show Socks moving")
	var shown := _number(counter.text, "Moving")
	_check(shown > 0 and shown <= mess.bodies_tuning().moving_budget, "the sign says how many move (%s)" % counter.text.replace("\n", " | "))
	await _settled(SMALL)
	await _frames(40)
	_check(counter.text.contains("Moving 0"), "at rest none move (%s)" % counter.text.replace("\n", " | "))
	_check(counter.text.contains("Waiting 0"), "none wait (%s)" % counter.text.replace("\n", " | "))
	_check(counter.text.contains("Resting %d" % SMALL), "every poured Sock rests (%s)" % counter.text.replace("\n", " | "))
	var tick := RegEx.create_from_string("Tick (\\d+\\.\\d) ms").search(counter.text)
	_check(tick != null and float(tick.get_string(1)) > 0.0, "it shows the tick's time (%s)" % counter.text.replace("\n", " | "))


## The number after `word` on the sign.
static func _number(text: String, word: String) -> int:
	var m := RegEx.create_from_string(word + " (\\d+)").search(text)
	return int(m.get_string(1)) if m != null else -1


func case_h05() -> void:
	await _zoo_up()
	var mess := _mess()
	var spout := _small()
	var st := _station()
	for path: String in ["Walls", "Slope", "Table"]:
		var body := st.get_node(path) as StaticBody3D
		_check(body != null and body.collision_layer & Mess.LAYER_HOUSE, "%s is a solid of the house's layer" % path)
	_ask(&"more")
	await _settled(SMALL)
	var outside := 0
	for sock in range(spout.first, mess.count()):
		var at := st.to_local(mess.pose_of(sock).origin)
		if absf(at.x) > 3.0 or absf(at.z) > 3.0:
			outside += 1
	_check(outside == 0, "every poured Sock lies inside the walls (%d outside)" % outside)


func case_r4() -> void:
	await _zoo_up()
	var spout := _small()
	var cat := DesignCatalogue.new()
	var none: Array[SockDesign] = [null, null, null]
	cat.designs = none
	spout.mess.catalogue = cat
	spout._queue_batch()
	_check(spout._queue.is_empty(), "no Design came back: the queue stays empty and the call returns")

func case_h07() -> void:
	await _zoo_up()
	var mess := _mess()
	var parts := LevelRuntime.of(_zoo).parts
	var spout := _small()
	var row := Mess.pack(Transform3D(Basis.IDENTITY, _station().global_position + Vector3.UP))
	var args := {"designs": PackedInt32Array([0]), "poses": row, "vels": PackedVector3Array([Vector3.ZERO]), "spins": PackedVector3Array([Vector3.ZERO])}
	var guest := parts.answer(Command.new(&"add", 2, mess.id, args))
	_check(not guest["ok"], "a Guest may not add Socks (%s)" % guest.get("reason"))
	_check(not mess.accepts().has(&"add") and not mess.accepts().has(&"take_out"), "add and take_out are not Guest verbs")
	_check(spout.accepts().has(&"more") and spout.accepts().has(&"respill"), "a Guest may press More and Respill")
	_ask(&"more")
	await _settled(SMALL)
	var snap := parts.snapshot()
	# A late joiner: a fresh zoo takes the Host's snapshot whole.
	var late := (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(late)
	await _until(func() -> bool: return LevelRuntime.of(late).mess.body_count() > 0, "the late zoo to bind")
	var late_parts := LevelRuntime.of(late).parts
	late_parts.load_snapshot(snap)
	await _physics_ticks(2)
	var late_mess := LevelRuntime.of(late).mess
	_same(late_mess.state(), mess.state(), "the late joiner's Mess is the Host's")
	_check(late_mess.body_count() == mess.body_count(), "the late joiner has a lying body for every heap Sock (%d, %d)" % [late_mess.body_count(), mess.body_count()])
	var late_spout := late_parts.of(spout.id) as HeapSpout
	_check(late_spout.pending() == 0 and late_spout.first == spout.first, "the late joiner pours nothing of its own")
	late.free()
	_check(not DirAccess.dir_exists_absolute("user://saves") or DirAccess.get_files_at("user://saves").is_empty(), "the zoo writes no save")


func case_ticks() -> void:
	await _zoo_up()
	var mess := _mess()
	var spout := _spout()
	var counter := _station().get_node("Counter") as HeapCounter
	var lines: Array[String] = []
	var poured := 0
	for clicks: int in [1, 3]:
		var samples := PackedFloat32Array()
		var start := mess.count()
		for c in clicks:
			_ask(&"more")
		poured += clicks * spout.tuning.batch
		var frames := 0
		while frames < 6000 and not (spout.pending() == 0 and _heap_flying(spout.first) == 0):
			await _frames(1)
			frames += 1
			samples.append(counter.last_ms)
		var pouring := _stats(samples)
		samples = PackedFloat32Array()
		for i in 180:
			await _frames(1)
			samples.append(counter.last_ms)
		var resting := _stats(samples)
		lines.append("heap %d Socks (+%d, %d frames to rest): pouring median %.2f ms, worst %.2f ms; at rest median %.2f ms, worst %.2f ms; Mess %d records, %d bodies"
				% [poured, mess.count() - start, frames, pouring.x, pouring.y, resting.x, resting.y, mess.count(), mess.body_count()])
	for line in lines:
		print(line)
	_check(spout.pending() == 0, "every Sock poured")


## Median and worst of `s`.
static func _stats(s: PackedFloat32Array) -> Vector2:
	if s.is_empty():
		return Vector2.ZERO
	var sorted := s.duplicate()
	sorted.sort()
	return Vector2(sorted[sorted.size() / 2], sorted[sorted.size() - 1])


func _zoo_up() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var mess := _mess()
	var player := LevelRuntime.of(_zoo).player
	await _until(func() -> bool: return player.is_on_floor() and mess.looks_of(mess.count() - 1) != null, "the player to stand and every Sock to lie", 600)
	mess.return_looks(mess.count() - 1)
	player.capture_mouse()   # the mouse is the player's: buttons act (R01)


func _mess() -> Mess:
	return LevelRuntime.of(_zoo).mess


func _station() -> Node3D:
	return _zoo.get_node(FOLDER) as Node3D


func _spout() -> HeapSpout:
	return _station().get_node("Spout/HeapSpout") as HeapSpout


## The spout with a small batch, for the rule cases.
func _small() -> HeapSpout:
	var spout := _spout()
	var t := spout.tuning.duplicate() as HeapTuning
	t.batch = SMALL
	spout.tuning = t
	return spout


## The Host's own press of a button's verb (rule cases; the real path clicks).
func _ask(verb: StringName) -> void:
	var parts := LevelRuntime.of(_zoo).parts
	_stand(_station().to_global(Vector3(0.0, 0.0, -4.5)))
	parts.ask(Command.new(verb, 1, _spout().id, {}))


## Waits until `n` Socks have been poured and none of the heap moves or waits.
func _settled(n: int) -> void:
	await _until(_rested.bind(n), "%d poured Socks to come to rest" % n, 3000)


func _rested(n: int) -> bool:
	var spout := _spout()
	var mess := _mess()
	return spout.first >= 0 and mess.count() - spout.first >= n and spout.pending() == 0 \
			and _heap_flying(spout.first) == 0 and mess.waiting_count() == 0


func _heap_flying(first: int) -> int:
	var mess := _mess()
	if first < 0 or first >= mess.count():
		return 0
	return mess.states.slice(first).count(Mess.State.FLYING)


func _lying(from: int, to: int) -> int:
	var mess := _mess()
	return mess.states.slice(from, to).count(Mess.State.LYING)


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


## A heap Sock with another heap Sock resting on it, and where the player can stand to aim at a
## part of it the other leaves in sight: [under, over, the player's feet, the aim point] each, at most 12.
func _under_and_over(player: Player, first: int) -> Array[Array]:
	var out: Array[Array] = []
	var mess := _mess()
	var eye_up := (player.get_node("Head") as Node3D).global_position - player.global_position
	var floor_y := _station().global_position.y
	for under in range(first, mess.count()):
		if mess.state_of(under) != Mess.State.LYING or mess.is_pair(under):
			continue
		var over := -1
		for other in mess.resting_on(mess.box_of(under)):
			if other != under and not mess.is_pair(other):
				over = other
				break
		if over < 0:
			continue
		var pose := mess.pose_of(under)
		var half := SockDress.box(mess.design_of(under)) * 0.5
		for corner: Vector3 in [Vector3(0.8, 1.0, 0.0), Vector3(-0.8, 1.0, 0.0), Vector3(0.0, 1.0, 0.8), Vector3(0.0, 1.0, -0.8),
				Vector3(0.7, 1.0, 0.7), Vector3(-0.7, 1.0, -0.7), Vector3(0.7, 1.0, -0.7), Vector3(-0.7, 1.0, 0.7)]:
			var point := pose * Vector3(corner.x * half.x, half.y * (corner.y + 0.0), corner.z * half.z)
			for turn in 8:
				var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * turn / 8.0)
				var feet := Vector3(point.x, floor_y, point.z) + dir * 1.2
				var eye := feet + eye_up
				var hit := PhysicsQueries.ray(mess, eye, eye + (point - eye) * 1.05, Mess.AIM_MASK)
				if not hit.is_empty() and mess.sock_at(hit["rid"]) == under:
					out.append([under, over, feet, point])
					if out.size() >= 12:
						return out
					break
	return out
