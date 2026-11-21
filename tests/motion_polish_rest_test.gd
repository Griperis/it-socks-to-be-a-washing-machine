## The rest of the core's motion polish (core/27, core/16's lines): the held readout following the
## cloth's sway (P03), a thrown Sock leaving with its held bend (P08), a shelved Pair's landing in its
## slot (P10), a Pair thrown at a drawer front flying on to its slot (P11), the fold's curl (P14),
## and the Door's and the cupboard's swings (P15). Every case plays a zoo station scene
## (cabinet.tscn, openables.tscn) on a floor with the game's player and a Parts (a Host of one),
## through the player's own input.
extends TestSuite

const CABINET_STATION := "res://game/zoo/stations/cabinet.tscn"
const OPENABLES_STATION := "res://game/zoo/stations/openables.tscn"
const PLAYER := "res://game/player/player.tscn"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward", &"move_back", &"jump", &"hands_next"]
## The Cabinet station's Socks, by id (as sound_wiring_test.gd): a Sock and its mate, a loose Sock.
const S0 := 0
const S0_MATE := 1
const S1 := 2
const LOOSE := 12
const BY_SOCKS := Vector3(-1.0, 0.0, 1.6)
const BY_DRAWERS := Vector3(-1.0, 0.0, -0.4)
const TOE := 4

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _cabinet: Cabinet = null
var _parts: Parts = null
var _bends: Dictionary[int, float] = {}


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: in the Cabinet station the player pairs two Socks (the fold curls), shelves the Pair by a click (it lands in its slot with the squash and hop), picks a Sock and walks (the held Size box sways with it) and throws it (it leaves bent)"},
		{"name": "p03_sway", "method": "case_p03", "world": false,
				"title": "P03: the held Size box moves on screen as far as the cloth's sway moves the held Sock's middle; a Pair adds no sway"},
		{"name": "p08_throw_bend", "method": "case_p08", "world": false,
				"title": "P08 (Q2315): a thrown Sock's flying Looks starts with the bend it had in the hand, easing out over the cloth's blend time; a drop does not carry it"},
		{"name": "p10_shelved_landing", "method": "case_p10", "world": false,
				"title": "P10 (Q2316): a shelved Pair lands short of its slot, squashes 0.28, hops 4 cm while rolling to its rest, squashes again, then the ball shows"},
		{"name": "p11_thrown_shelve", "method": "case_p11", "world": false,
				"title": "P11 (Q2316): a Pair thrown at a drawer front flies on from where it hit to its slot and lands there"},
		{"name": "p14_curl", "method": "case_p14", "world": false,
				"title": "P14 (Q2281): in the pairing moment the two Socks' cloth bones curl, half through the fold, 1.3 rad each by the roll's end"},
		{"name": "p15_swings", "method": "case_p15", "world": false,
				"title": "P15 (Q2368): the Door swings 0.6 s eased in and out; the cupboard 0.35 s eased out, both ways, opened by the player"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null
	_bends.clear()


# --- The real path -------------------------------------------------------------------------------

func case_real_path() -> void:
	await _build(CABINET_STATION)
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	var moment := _player.held_view().moment_of(S0) as PairMoment
	_check(moment != null, "the pairing moment plays")
	var curled := 0.0
	while is_instance_valid(moment) and moment.is_inside_tree():
		curled = maxf(curled, moment.rolled()[0])
		await get_tree().process_frame
	_near(curled, 1.3, 0.05, "its Socks curled 1.3 rad a bone")
	_stand(BY_DRAWERS)
	await _aim(_player, _drawer_front(0))
	await _press(&"pick")
	var landing := await _flight_landing(S0)
	_check(landing["landings"] == 1, "the shelved Pair landed once in its slot")
	_near(landing["deepest"], 0.28, 0.02, "with the squash")
	_check(_ball(0, 0).visible, "and its ball shows in the drawer")
	_stand(BY_SOCKS)
	await _repick(LOOSE)
	var view := _player.held_view()
	await _until(view.settled, "the fly-up to end")
	var swayed := await _walk_sway(12)
	_check(swayed["sway"] > 0.0005, "walking off, the held Sock sways (%.4f)" % swayed["sway"])
	_check(swayed["box"] >= 1.0, "and its Size box moves with it (%.1f px)" % swayed["box"])
	var held := view.looks_of(LOOSE)
	_watch(held)
	Input.action_press(&"move_forward")
	await _physics_ticks(10)
	var bend := await _throw_bend(LOOSE, held)
	Input.action_release(&"move_forward")
	_check(bend["held"] > 0.002, "the held Sock was bent (%.4f m at the toe)" % bend["held"])
	_near(bend["flying"], bend["held"], maxf(0.3 * bend["held"], 0.003), "thrown, it leaves with that bend")


# --- P03 -----------------------------------------------------------------------------------------

func case_p03() -> void:
	await _build(CABINET_STATION)
	_stand(BY_SOCKS)
	await _pick(LOOSE)
	var view := _player.held_view()
	await _until(view.settled, "the fly-up to end")
	await _physics_ticks(40)
	var swayed := await _walk_sway(30)
	_check(swayed["sway"] > 0.0005, "a start and a stop sway the held Sock (%.4f)" % swayed["sway"])
	_check(swayed["box"] >= 1.0, "the Size box moves with it (%.1f px)" % swayed["box"])
	_check(swayed["worst"] <= 1.01, "always where the sway puts it (worst %.2f px off)" % swayed["worst"])
	# A Pair: no cloth, no sway.
	_level.free()
	_level = null
	await _build(CABINET_STATION)
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	await _until(func() -> bool: return _player.held_view().moment_of(S0) == null, "the moment to end")
	var pair := await _walk_sway(20)
	_check(pair["sway"] == 0.0, "a held Pair adds no sway")


# --- P08 -----------------------------------------------------------------------------------------

func case_p08() -> void:
	await _build(CABINET_STATION)
	_stand(BY_SOCKS)
	await _pick(LOOSE)
	var view := _player.held_view()
	await _until(view.settled, "the fly-up to end")
	var held := view.looks_of(LOOSE)
	_watch(held)
	Input.action_press(&"move_forward")
	await _physics_ticks(10)
	var bend := await _throw_bend(LOOSE, held)
	Input.action_release(&"move_forward")
	_check(bend["held"] > 0.002, "the held Sock was bent (%.4f m at the toe)" % bend["held"])
	_near(bend["flying"], bend["held"], maxf(0.3 * bend["held"], 0.003), "the thrown Sock's first drawn bend is the held one")
	var cloth := bend["cloth"] as SockCloth
	_check(cloth.carrying(), "and eases out from there")
	await _until(func() -> bool: return not is_instance_valid(cloth) or not cloth.carrying(), "the carried bend to ease out",
			int(cloth.tuning.blend_time * 60.0 * 3.0) + 30)
	# A drop carries none.
	_stand(BY_SOCKS)
	await _pick(S1)
	await _until(view.settled, "the fly-up to end")
	Input.action_press(&"move_forward")
	await _physics_ticks(10)
	Input.action_release(&"move_forward")
	_stand(BY_SOCKS)
	await _aim(_player, _station.to_global(Vector3(-1.0, 0.0, 0.2)))
	await _press(&"drop_throw")
	await _until(func() -> bool: return _mess.moving_body(S1) != null and _mess.moving_body(S1).has_node(^"Looks"), "the dropped body's Looks")
	var dropped := _mess.moving_body(S1).get_node(^"Looks").find_children("*", "SockCloth", true, false)[0] as SockCloth
	_check(not dropped.carrying(), "a dropped Sock carries no bend")


# --- P10 -----------------------------------------------------------------------------------------

func case_p10() -> void:
	await _build(CABINET_STATION)
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	await _until(func() -> bool: return _player.held_view().moment_of(S0) == null, "the moment to end")
	_stand(BY_DRAWERS)
	await _aim(_player, _drawer_front(0))
	await _press(&"pick")
	var landing := await _flight_landing(S0)
	var t := Cabinet.BALL_LANDING
	_check(landing["landings"] == 1, "it lands once")
	_near(landing["deepest"], t.squash, 0.02, "squashing 0.28")
	_near(landing["highest"], t.bounce_height, 0.006, "hopping 4 cm")
	_near(landing["short"], minf(t.roll_distance, landing["way"] * 0.5), 0.02, "landing 12 cm short of its rest (or half a short way)")
	_check(landing["squashes"] == 2, "it squashes twice (%d)" % landing["squashes"])
	_check(landing["end"] < 0.005, "it rolls on to its rest (%.4f m off)" % landing["end"])
	_check(not landing["shown_early"], "the drawer's ball stays hidden until it lands")
	_check(_ball(0, 0).visible, "then the ball shows in its slot")


# --- P11 -----------------------------------------------------------------------------------------

func case_p11() -> void:
	await _build(CABINET_STATION)
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	await _until(func() -> bool: return _player.held_view().moment_of(S0) == null, "the moment to end")
	_stand(BY_DRAWERS + Vector3(0.0, 0.0, 1.0))
	await _aim(_player, _drawer_front(1))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "the charge")
	await _physics_ticks(5)
	Input.action_release(&"drop_throw")
	var last := Vector3.INF
	var flier: Node3D = null
	for i in 600:
		await get_tree().process_frame
		flier = _cabinet.get_parent().get_node_or_null("Flight%d" % S0) as Node3D
		if flier != null:
			break
		var body := _mess.moving_body(S0)
		if body != null:
			last = body.global_position
	_check(_mess.state_of(S0) == Mess.State.SHELVED, "the thrown Pair was shelved by the drawer front")
	_check(flier != null, "and flies on to its slot")
	if flier == null:
		return
	_check(last != Vector3.INF and flier.global_position.distance_to(last) < 0.25,
			"from where it hit (%.3f m from the body's last place)" % flier.global_position.distance_to(last))
	var landing := await _flight_landing(S0)
	_check(landing["landings"] == 1, "it lands in its slot")
	var index := -1
	for d in _cabinet.drawer_count():
		if _cabinet.contents(d).has(S0):
			index = d
	_check(index >= 0 and _ball(index, 0).visible, "and its ball shows there")


# --- P14 -----------------------------------------------------------------------------------------

func case_p14() -> void:
	await _build(CABINET_STATION)
	_capacity(2)
	_stand(BY_SOCKS)
	await _pick(S0)
	await _repick(S0_MATE)
	var moment := _player.held_view().moment_of(S0) as PairMoment
	_check(moment != null, "the moment plays")
	if moment == null:
		return
	_near(moment.curl, 1.3, 0.0001, "curl 1.3, the old paired.json")
	var player := moment.get_node(^"AnimationPlayer") as AnimationPlayer
	var anim := player.get_animation(HeldView.PAIR)
	var track := anim.find_track(^".:fold", Animation.TYPE_VALUE)
	_check(track >= 0, "the moment's animation keys the fold")
	_near(float(anim.value_track_interpolate(track, 0.2)), 0.0, 0.001, "straight as they line up")
	_near(float(anim.value_track_interpolate(track, 0.35)), 0.5, 0.001, "half curled by the fold's end")
	_near(float(anim.value_track_interpolate(track, 0.43)), 1.0, 0.001, "whole by the roll's end")
	var most: Array[float] = [0.0, 0.0]
	while is_instance_valid(moment) and moment.is_inside_tree():
		var r := moment.rolled()
		most[0] = maxf(most[0], r[0])
		most[1] = maxf(most[1], r[1])
		await get_tree().process_frame
	_near(most[0], 1.3, 0.05, "the held Sock's bones curled 1.3 rad")
	_near(most[1], 1.3, 0.05, "and its mate's")


# --- P15 -----------------------------------------------------------------------------------------

func case_p15() -> void:
	await _build(CABINET_STATION)
	var door := _station.get_node("Door/Openable") as Openable
	var anim := door.animator().get_animation(Openable.ANIMATION)
	_near(anim.length, 0.6, 0.001, "the Door's swing is 0.6 s")
	var turn := _share(anim, 0)
	_check(turn.call(0.25) < 0.2 and turn.call(0.75) > 0.8, "eased in and out (%.2f at a quarter, %.2f at three quarters)" % [turn.call(0.25), turn.call(0.75)])
	_near(turn.call(0.5), 0.5, 0.02, "half open half way")
	_check(not door.animator().has_animation(Openable.SHUT), "it shuts by the same swing backwards (eased the same)")
	_stand(Vector3(1.55, 0.0, 1.0))
	await _aim(_player, (door.get_node("../Looks/Hinge/PanelShape") as Node3D).global_position)
	var took := await _use_and_time(door)
	_check(door.open, "the player opened the Door")
	_near(took, 0.6, 0.1, "in about 0.6 s (%.2f)" % took)
	# The cupboard, in the openables station.
	_level.free()
	_level = null
	await _build(OPENABLES_STATION)
	var cupboard := _station.get_node("Cupboard/Openable") as Openable
	for path: String in ["res://game/entities/cupboard/looks_graybox.tscn", "res://game/entities/cupboard/looks_alt.tscn"]:
		var looks := (load(path) as PackedScene).instantiate()
		var player := looks.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		for name: StringName in [Openable.ANIMATION, Openable.SHUT]:
			_check(player.has_animation(name), "%s has %s" % [path.get_file(), name])
			if not player.has_animation(name):
				continue
			var a := player.get_animation(name)
			_near(a.length, 0.35, 0.001, "%s %s lasts 0.35 s" % [path.get_file(), name])
			var u := _share(a, 0)
			_check(u.call(0.5) > 0.7, "%s %s eases out (%.2f of the way half way)" % [path.get_file(), name, u.call(0.5)])
		looks.free()
	_stand(Vector3(-1.0, 0.0, 1.5))
	await _aim(_player, (cupboard.get_node("../Looks/DoorPivot/Door") as Node3D).global_position)
	var opened := await _use_and_time(cupboard)
	_check(cupboard.open, "the player opened the cupboard")
	_near(opened, 0.35, 0.1, "in about 0.35 s (%.2f)" % opened)
	await _physics_ticks(5)
	var shut := await _use_and_time(cupboard)
	_check(not cupboard.open, "and shut it")
	_near(shut, 0.35, 0.1, "in about 0.35 s (%.2f)" % shut)


# --- Helpers -------------------------------------------------------------------------------------

func _build(station: String) -> void:
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
	_station = (load(station) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = _station.position + Vector3(0.0, 0.0, 2.0)
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node_or_null("Socks/Mess") as Mess
	_hands = _station.get_node_or_null("Socks/Hands") as Hands
	_cabinet = _station.get_node_or_null("Cabinet/Cabinet") as Cabinet
	await _until(func() -> bool: return _player.is_on_floor() and (_mess == null or _mess.looks_of(0) != null), "the player to stand and the Socks to lie")


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


func _pick(sock: int) -> void:
	await _aim(_player, _centre(sock))
	await _press(&"pick")
	await _until(func() -> bool: return _hands.items_of(1).has(sock) or _mess.state_of(sock) == Mess.State.IN_PAIR, "Sock %d to be picked" % sock)


func _repick(sock: int) -> void:
	await _physics_ticks(25)
	await _pick(sock)


func _capacity(n: int) -> void:
	_player.hands_tuning = _player.hands_tuning.duplicate() as HandsTuning
	_player.hands_tuning.capacity = n
	_player.held_view().tuning = _player.hands_tuning


func _drawer_front(index: int) -> Vector3:
	var front := _cabinet.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)


## The drawn ball in slot `slot` of drawer `index`.
func _ball(index: int, slot: int) -> Node3D:
	var looks := _cabinet.get_parent().get_node("Drawer%d/Looks" % (index + 1))
	var point := looks.find_child(Cabinet.SLOT % (slot + 1), true, false) as Node3D
	return point.get_node_or_null(NodePath(Cabinet.BALL)) as Node3D


## Follows the shelving flight of Pair `sock` until it is gone, each frame: its landing's numbers,
## how far short of its rest it touched down, how far off its rest it ended, how often it squashed,
## and whether the drawer's own ball showed before it was over.
func _flight_landing(sock: int) -> Dictionary:
	var out := {"landings": 0, "deepest": 0.0, "highest": 0.0, "short": -1.0, "way": 0.0, "squashes": 0,
			"end": INF, "shown_early": false}
	var name := "Flight%d" % sock
	await _until(func() -> bool: return _cabinet.get_parent().has_node(name), "the shelving flight to start")
	var flier := _cabinet.get_parent().get_node_or_null(name) as Node3D
	if flier == null:
		return out
	var landing := flier.get_node("BallLanding") as BallLanding
	var start := flier.global_position
	var ball: Node3D = null
	var was_squashed := false
	while is_instance_valid(flier) and flier.is_inside_tree():
		if ball == null:
			for d in _cabinet.drawer_count():
				var j := _cabinet.contents(d).find(sock)
				if j >= 0:
					ball = _ball(d, j)
		var rest := ball.global_position if ball != null else Vector3.INF
		if ball != null and ball.visible:
			out["shown_early"] = true
		if landing.landings > 0 and out["short"] < 0.0 and ball != null:
			out["short"] = Vector2(flier.global_position.x - rest.x, flier.global_position.z - rest.z).length()
			out["way"] = Vector2(start.x - rest.x, start.z - rest.z).length()
		var squashed := landing.squash > 0.01
		if squashed and not was_squashed:
			out["squashes"] = int(out["squashes"]) + 1
		was_squashed = squashed
		out["landings"] = landing.landings
		out["deepest"] = landing.deepest
		out["highest"] = landing.highest
		if ball != null:
			out["end"] = flier.global_position.distance_to(rest)
		await get_tree().process_frame
	return out


## Walks the player forward `ticks` physics ticks and stops, then waits as long again: the largest
## sway of the active held item seen, the most its held Size box moved on screen from where it would
## be with no sway, and the worst distance of the box from where that sway puts it.
func _walk_sway(ticks: int) -> Dictionary:
	var view := _player.held_view()
	var hud := _player.hud()
	var row := hud.row("held")
	var out := {"sway": 0.0, "box": 0.0, "worst": 0.0}
	# process_frame comes before the frame's _process: the Hud has placed the box for the frame before,
	# so the box is checked against the sway read then.
	var before := Vector2.INF
	Input.action_press(&"move_forward")
	for i in ticks * 2:
		if i == ticks:
			Input.action_release(&"move_forward")
		await get_tree().process_frame
		if before != Vector2.INF:
			out["box"] = maxf(out["box"], row.position.distance_to(_box_at(Vector2.ZERO)))
			out["worst"] = maxf(out["worst"], row.position.distance_to(before))
		var sway := view.sway()
		out["sway"] = maxf(out["sway"], sway.length())
		before = _box_at(sway)
	Input.action_release(&"move_forward")
	return out


## Where the held Size box's top left goes for a `sway` (the Hud's own placing, unzoomed).
func _box_at(sway: Vector2) -> Vector2:
	var hud := _player.hud()
	var row := hud.row("held")
	var camera := hud.camera
	var rest := (hud.hands_tuning.active_pos + hud.tuning.info_offset) * hud.hands_tuning.depth
	var k := _player.held_view().zoom_factor()
	var p := Vector3(rest.x * k + sway.x * -rest.z, rest.y * k + sway.y * -rest.z, rest.z)
	var at := camera.unproject_position(camera.global_transform * p) - Vector2(0.0, row.size.y * 0.5)
	at.x = minf(at.x, row.get_viewport_rect().size.x - row.size.x - hud.tuning.edge_margin)
	return at.round()


## Throws held Sock `sock` (drawn as `held`) at the far floor with a short charge: its last drawn bend
## in the hand, the bend its flying Looks is first drawn with, and that Looks' cloth.
func _throw_bend(sock: int, held: Node3D) -> Dictionary:
	await _aim(_player, _station.to_global(Vector3(-1.0, 0.0, -3.0)))
	Input.action_press(&"drop_throw")
	await _until(func() -> bool: return _player.charging, "the charge")
	await _physics_ticks(3)
	var in_hand := {"bend": 0.0}
	Input.action_release(&"drop_throw")
	await _until(func() -> bool:
		if is_instance_valid(held):
			in_hand["bend"] = _bend(held)
		var body := _mess.moving_body(sock)
		return body != null and body.has_node(^"Looks"), "the thrown body's Looks")
	var looks := _mess.moving_body(sock).get_node(^"Looks") as Node3D
	_watch(looks)
	var key := looks.get_instance_id()
	await _until(func() -> bool: return _bends.has(key), "the flying Looks to be drawn")
	var cloth := looks.find_children("*", "SockCloth", true, false)[0] as SockCloth
	return {"held": in_hand["bend"], "flying": _bends[key], "cloth": cloth}


## Asks `openable` open or shut through the player's interact key and times its swing, in the game's
## seconds (physics ticks: the Looks' animation plays on them or on frames of the same length).
func _use_and_time(openable: Openable) -> float:
	var was := openable.open
	Input.action_press(&"interact")
	var ticks := 0
	while openable.open == was and ticks < 60:
		await get_tree().physics_frame
		ticks += 1
	Input.action_release(&"interact")
	ticks = 0
	while openable.is_moving() and ticks < 600:
		await get_tree().physics_frame
		ticks += 1
	return float(ticks) / float(Engine.physics_ticks_per_second)


## How far along its way `anim`'s track `track` is at a share of its length (0 at its start, 1 at its end).
static func _share(anim: Animation, track: int) -> Callable:
	var a: Vector3 = anim.value_track_interpolate(track, 0.0)
	var b: Vector3 = anim.value_track_interpolate(track, anim.length)
	return func(u: float) -> float:
		var v: Vector3 = anim.value_track_interpolate(track, u * anim.length)
		return (v - a).length() / maxf((b - a).length(), 0.0001)


## Reads `looks`' bend (its Toe from its rest place) each time its skeleton is drawn.
func _watch(looks: Node3D) -> void:
	var skeleton := looks.find_child("Skeleton3D", true, false) as Skeleton3D
	var key := looks.get_instance_id()
	skeleton.skeleton_updated.connect(func() -> void:
		_bends[key] = skeleton.get_bone_global_pose(TOE).origin.distance_to(skeleton.get_bone_global_rest(TOE).origin))


func _bend(looks: Node3D) -> float:
	return _bends.get(looks.get_instance_id(), 0.0)
