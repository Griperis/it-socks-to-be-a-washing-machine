## The spray of Socks (core/89, run-ends.md "The spray"): out of the washing machine's door, real Sock meshes
## in Designs drawn from the catalogue with the seed, one MultiMesh per Collection, no physics, lying still
## by the end and gone when the effect ends; the Laundry station's Spray pillar plays it.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const FOLDER := "Stations/Laundry"
const SPRAY := preload("res://game/laundry/sock_spray.tscn")

var _zoo: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player presses E on the Spray pillar, Socks leave the porthole marker, lie still on the floor by the end and vanish; every Collection's MultiMesh is drawn"},
		{"name": "seed", "method": "case_seed", "world": false,
				"title": "two machines draw the same spray from the seed; another seed draws another"},
	]


func _before_case() -> void:
	Input.action_release(&"interact")
	if _zoo != null:
		_zoo.free()
		_zoo = null


func case_real_path() -> void:
	_zoo = (load(ZOO) as PackedScene).instantiate() as Node3D
	add_child(_zoo)
	var player := LevelRuntime.of(_zoo).player
	await _until(func() -> bool: return player.is_on_floor(), "the player to stand", 600)
	player.capture_mouse()
	var station := _zoo.get_node(FOLDER) as Node3D
	var pillar := station.get_node("SprayPillar") as Node3D
	var spray := station.get_node("Spray") as SockSpray
	var porthole := station.get_node("Washer/Porthole") as Marker3D
	player.global_position = pillar.global_position + Vector3(0.0, -0.5, 1.5)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	var head := player.get_node("Head") as Node3D
	var to := pillar.global_position - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var up := pillar.global_position - head.global_position
	head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
	await _physics_ticks(2)
	_check(not spray.playing, "nothing sprays before the press")
	Input.action_press(&"interact")
	await _physics_ticks(2)
	Input.action_release(&"interact")
	await _until(func() -> bool: return spray.playing and spray.flown() > 0, "the spray to start and Socks to leave", 300)
	# From here the test steps the spray by hand, so the real time does not matter.
	spray.set_process(false)
	var n := spray.tuning.count
	_check(spray.drawn() == n, "every Sock is drawn (%d of %d)" % [spray.drawn(), n])
	_check(spray.groups() == spray.catalogue.collections().size(), "one MultiMesh per Collection (%d)" % spray.groups())
	_check(spray.position_of(0).distance_to(porthole.global_position) < 0.5, "the first Sock leaves the porthole marker")
	for i in 40:
		spray.advance(0.05)
	var forward := -porthole.global_basis.z
	var out := 0
	for p in spray.positions():
		if (p - porthole.global_position).dot(forward) > 0.1:
			out += 1
	_check(out > n / 2, "the Socks fly out in front of the door (%d of %d)" % [out, n])
	while spray.elapsed < spray.tuning.length - 0.1:
		spray.advance(0.02)
	_check(spray.playing, "the spray is still on just before its length")
	_check(spray.landed() == n, "every Sock lies still by the end (%d of %d)" % [spray.landed(), n])
	var off := 0
	for p in spray.positions():
		if absf(p.y - station.global_position.y) > 0.01:
			off += 1
	_check(off == 0, "every Sock lies on the floor (%d off it)" % off)
	spray.advance(0.1)
	_check(not spray.playing and spray.groups() == 0 and spray.positions().is_empty(), "the Socks are gone when the effect ends")


func case_seed() -> void:
	var catalogue := load("res://game/sock/designs.tres") as DesignCatalogue
	var a := _machine(catalogue, 7)
	var b := _machine(catalogue, 7)
	for step in 30:
		a.advance(0.05)
		b.advance(0.05)
	_check(a.positions() == b.positions() and a.positions().size() == a.tuning.count, "two machines' Socks are in the same places")
	_check(a.groups() == b.groups() and a.groups() == catalogue.collections().size(), "and in the same MultiMeshes")
	var c := _machine(catalogue, 8)
	for step in 30:
		c.advance(0.05)
	_check(c.positions() != a.positions(), "another seed draws another spray")


func _machine(catalogue: DesignCatalogue, seed_value: int) -> SockSpray:
	var spray := SPRAY.instantiate() as SockSpray
	spray.tuning = spray.tuning.duplicate() as SockSprayTuning
	spray.tuning.seed = seed_value
	spray.catalogue = catalogue
	add_child(spray)
	spray.set_process(false)
	spray.play(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, 0.0)
	spray.set_process(false)
	return spray
