## coop/05: Teammates seen. Real zoos (only their Handling station, to stay light), each a machine of
## its own in one process, joined over real ENet through the zoo's own wiring, as coop_join_test does:
## the Host's input moves its player, and the Guest sees its avatar follow, waddle, crouch, hold. Plus
## the follow's numbers on one avatar alone. No case judges the look itself (Q2421): that is the strip.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const AVATAR := "res://game/parts/avatar/avatar.tscn"
const KEEP := ["Handling"]
const NET_WAIT_S := 20.0
## Where a player stands to pick at the Handling station, in the station's space.
const BY_HANDLING := Vector3(0.0, 0.0, 1.5)

var _branches: Array[Node] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "walk_crouch", "method": "case_walk_crouch", "world": false,
				"title": "real path: the Host walks forward: on the Guest its avatar follows close behind, faces its way, its feet rock while it walks and rest when it stops; the Host crouches: the avatar's Crouch goes to 1 and back to 0"},
		{"name": "colour_tag_late", "method": "case_colour_tag_late", "world": false,
				"title": "each avatar is tinted its player's Roster colour (the trim darker) with a \"Player\" tag in that colour lightened; a late joiner sees both others posed, tinted and tagged at once"},
		{"name": "held", "method": "case_held", "world": false,
				"title": "real path: the Host picks a Sock: on the Guest it hangs at the Host avatar's HoldPoint, true size, by its cuff; a second one clusters a worn step beside it; picking the mate shows the Pair as the ball"},
		{"name": "forged", "method": "case_forged", "world": false,
				"title": "on the Host, a Guest's pose that is out of the area, too high, not finite or an impossible pitch or crouch is dropped: the old pose stays"},
		{"name": "follow", "method": "case_follow", "world": true,
				"title": "a small move eases min(1, 12 * delta) of the way a frame, the crouch at 6 a second; a move over 1 m in one update stands there at once"},
		{"name": "station", "method": "case_station", "world": false,
				"title": "the Avatar station in the zoo, played alone: its stand-in Teammate walks its loop through its pose and takes the station's Sock; the other stands still"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_drop_branches()


func case_walk_crouch() -> void:
	var pair := await _joined()
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var hp := _player(host)
	var seen := _avatars(guest).of(1)
	var looks := seen.looks
	var start := hp.global_position
	var rocked := [0.0]
	var lag := [0.0]
	Input.action_press(Player.MOVE_FORWARD)
	await _until(func() -> bool:
		rocked[0] = maxf(rocked[0], absf(looks.feet()[0].rotation.x))
		if hp.global_position.distance_to(start) > 0.5:
			lag[0] = maxf(lag[0], seen.global_position.distance_to(hp.global_position))
		return hp.global_position.distance_to(start) > 3.0, "the Host's player to walk 3 m")
	Input.action_release(Player.MOVE_FORWARD)
	_check(rocked[0] > deg_to_rad(5.0), "the avatar's feet rocked while it walked (%.1f deg)" % rad_to_deg(rocked[0]))
	_check(lag[0] < 0.8, "it followed close behind, an eased lag (%.2f m at most)" % lag[0])
	_check(looks.walk > 0.3, "it waddles while walking (%.2f)" % looks.walk)
	await _until(func() -> bool: return seen.global_position.distance_to(hp.global_position) < 0.02 and looks.walk < 0.01,
			"the avatar to stand where the Host stopped and stop waddling")
	_check(absf(looks.feet()[0].rotation.x) < 0.01 and absf(looks.feet()[1].rotation.x) < 0.01, "its feet rest flat")
	_near(seen.rotation.y, hp.global_rotation.y, 0.05, "it faces the Host's way")
	Input.action_press(Player.CROUCH)
	await _until(func() -> bool: return is_equal_approx(looks.crouch, 1.0), "the avatar to crouch fully")
	var body := looks.body()
	_near(body.get_blend_shape_value(body.find_blend_shape_by_name(&"Crouch")), 1.0, 0.001, "its Crouch shape key is 1")
	Input.action_release(Player.CROUCH)
	await _until(func() -> bool: return looks.crouch == 0.0, "the avatar to stand again")
	_drop_branches()


func case_colour_tag_late() -> void:
	var pair := await _joined()
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var tuning := (_session(host).tuning as CoopTuning)
	var g_peer := _session(guest).me()
	_dressed(_avatars(host).of(g_peer), tuning.colours[1], "the Guest's avatar on the Host")
	_dressed(_avatars(guest).of(1), tuning.colours[0], "the Host's avatar on the Guest")
	# A third zoo joins late.
	var late := _branch("Late")
	await _frames(2)
	_session(late).profile = PlayerProfile.fresh()
	_net(late).start(["--join=127.0.0.1:%d" % _session(host).port])
	var la := _avatars(late)
	await _until(func() -> bool: return la.of(1) != null and la.of(g_peer) != null, "the late joiner to see both others")
	var h_at := _player(host).global_position
	var g_at := _player(guest).global_position
	_check(la.of(1).position.distance_to(h_at) < 0.05 and la.of(g_peer).position.distance_to(g_at) < 0.05,
			"both stand where their players stand at once, no glide from the origin")
	_dressed(la.of(1), tuning.colours[0], "the Host's avatar on the late joiner")
	_dressed(la.of(g_peer), tuning.colours[1], "the Guest's avatar on the late joiner")
	_drop_branches()


func case_held() -> void:
	var pair := await _joined()
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var handling := host.get_node("Stations/Handling") as Node3D
	var at := handling.to_global(BY_HANDLING)
	_stand(_player(host), at, 0.0)
	var seen := _avatars(guest).of(1)
	await _until(func() -> bool: return seen.position.distance_to(at) < 0.02, "the Guest to see the Host at the Handling station")
	var hh := host.get_node("Socks/Hands") as Hands
	var gh := guest.get_node("Socks/Hands") as Hands
	var socks: Dictionary[String, int] = {}
	for spot: String in ["Floor", "Under", "MateFloor"]:
		socks[spot] = (handling.get_node("Spots/" + spot) as SockSpot).sock
	var held := seen.held
	_check(held != null and held.worn and held.hands == gh, "the Host's avatar wears a HeldView of the Guest's Hands")
	# The Host's own pick, as its pick button asks it.
	hh.pick(1, socks["Floor"])
	await _until(func() -> bool: return held.looks_of(socks["Floor"]) != null and held.settled(), "the Sock to fly to the Host avatar's hand")
	var hold := seen.looks.hold_point()
	_check(held.global_position.distance_to(hold.global_position) < 0.001, "the worn Hands hang at the avatar's HoldPoint")
	var design := gh.mess.design_of(socks["Floor"])
	var s := design.size_scale()
	var sock_looks := held.looks_of(socks["Floor"])
	var half := SockDress.BOX.x * 0.5 * s
	_check(sock_looks.transform.origin.is_equal_approx(HeldView.WORN_HANG.x * half),
			"it hangs by its cuff right at the HoldPoint (%s)" % sock_looks.transform.origin)
	_near(sock_looks.transform.basis.get_scale().x, s, 0.001, "at true size")
	await _physics_ticks(25)  # the grab interval
	hh.pick(1, socks["Under"])
	await _until(func() -> bool: return held.looks_of(socks["Under"]) != null and held.settled(), "the second Sock to cluster")
	var items := gh.items_of(1)
	var active := gh.active_index(1)
	var tucked := items[1 - active]
	var t_s := gh.mess.design_of(tucked).size_scale()
	var want := held.worn_step * Vector3(-1.0, 1.0, 1.0) + HeldView.WORN_HANG.x * SockDress.BOX.x * 0.5 * t_s
	_check(held.looks_of(tucked).transform.origin.is_equal_approx(want),
			"the tucked one sits a worn step to the left (%s, wanted %s)" % [held.looks_of(tucked).transform.origin, want])
	await _physics_ticks(25)
	hh.pick(1, socks["MateFloor"])
	await _until(func() -> bool: return gh.mess.is_pair(socks["Floor"]) or gh.mess.is_pair(socks["MateFloor"]), "the mate to make a Pair")
	var lead: int = socks["Floor"] if gh.items_of(1).has(socks["Floor"]) else socks["MateFloor"]
	await _until(func() -> bool: return held.is_ball(lead) and held.settled(), "the Pair to show as the ball")
	_check(held.moment_of(lead) == null, "no pairing moment plays on a Teammate")
	_drop_branches()


func case_forged() -> void:
	var pair := await _joined()
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var copy := _avatars(host).of(_session(guest).me())
	var before := [copy.pose_position, copy.pose_yaw, copy.pose_pitch, copy.pose_crouch]
	var dropped := copy.dropped
	# As the synchronizer writes them on the Host's copy.
	copy.set(&"pose_position", Vector3(500.0, 0.0, 0.0))
	copy.set(&"pose_position", Vector3(0.0, 300.0, 0.0))
	copy.set(&"pose_position", Vector3(NAN, 0.0, 0.0))
	copy.set(&"pose_yaw", INF)
	copy.set(&"pose_pitch", 2.0)
	copy.set(&"pose_crouch", 3.0)
	_check(copy.dropped - dropped == 6, "six forged values dropped (%d)" % (copy.dropped - dropped))
	_same([copy.pose_position, copy.pose_yaw, copy.pose_pitch, copy.pose_crouch], before, "the old pose stays on the Host")
	_drop_branches()


func case_follow() -> void:
	var avatar := (load(AVATAR) as PackedScene).instantiate() as Avatar
	avatar.name = "2"  # another player's: a puppet here (this machine is peer 1)
	add_child(avatar)
	avatar.set_process(false)
	var dt := 1.0 / 60.0
	avatar.pose_position = Vector3(0.5, 0.0, 0.0)
	avatar.pose_crouch = 1.0
	avatar._process(dt)
	_check(avatar.position.is_equal_approx(Vector3(0.5 * 12.0 * dt, 0.0, 0.0)), "a 0.5 m move eases 12 * delta of the way (%s)" % avatar.position)
	_near(avatar.crouch, 6.0 * dt, 0.0001, "the crouch moves 6 a second")
	avatar._process(dt)
	_check(avatar.position.x < 0.5, "and is not there yet")
	avatar.pose_position = Vector3(2.5, 0.0, 0.0)
	avatar._process(dt)
	_check(avatar.position.is_equal_approx(Vector3(2.5, 0.0, 0.0)), "a move over 1 m in one update stands there at once (%s)" % avatar.position)
	avatar.free()


func case_station() -> void:
	var zoo := _branch("Alone", ["Avatar"])
	await _frames(2)
	var station := zoo.get_node("Stations/Avatar") as Node3D
	var stand_in := station.get_node("Teammates") as TeammateStandIn
	_check(not stand_in.awake(), "far from the camera it stands still")
	stand_in.wake_range = 1000.0
	var walker := stand_in.walker
	var still := stand_in.still
	var from := walker.pose_position
	var still_at := still.position
	await _frames(20)
	_check(walker.pose_position.distance_to(from) > 0.2, "the stand-in's pose moved round its loop (%s to %s)" % [from, walker.pose_position])
	_check(walker.position.distance_to(from) > 0.1, "and its body followed")
	_check(still.position == still_at, "the other stands still")
	var sock := (station.get_node("Spots/Sock") as SockSpot).sock
	await _until(func() -> bool: return walker.held.looks_of(sock) != null, "the stand-in to hold the station's Sock")
	_check(walker.looks.tag().text == "Player" and walker.looks.colour == stand_in.walker_colour, "it is tagged and coloured")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## The avatar `a` is tinted `colour` (its trim darker) and tagged "Player" in the colour lightened.
func _dressed(a: Avatar, colour: Color, who: String) -> void:
	var looks := a.looks
	var body := looks.body()
	var t := looks.tuning
	_check(_shown(body, 0).albedo_color == colour, "%s is tinted its player's colour (%s)" % [who, _shown(body, 0).albedo_color])
	_check(_shown(body, 1).albedo_color == colour.darkened(t.trim_darken), "%s has its trim darker" % who)
	_check(_shown(looks.feet()[0], 0).albedo_color == colour.darkened(t.trim_darken), "%s has its feet in the trim's shade" % who)
	var tag := looks.tag()
	_check(tag != null and tag.visible and tag.text == "Player" and tag.modulate == colour.lightened(t.tag_lighten),
			"%s carries a \"Player\" tag in its colour" % who)


func _shown(mi: MeshInstance3D, surface: int) -> BaseMaterial3D:
	var over := mi.get_surface_override_material(surface)
	return (over if over != null else mi.mesh.surface_get_material(surface)) as BaseMaterial3D


## A Host zoo and a Guest zoo, joined, each seeing the other's avatar: [host, guest].
func _joined() -> Array:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	_session(host).profile = PlayerProfile.fresh()
	_session(guest).profile = PlayerProfile.fresh()
	_check(_net(host).start(["--host"]) == OK, "the Host hosts")
	_net(guest).start(["--join=127.0.0.1:%d" % _session(host).port])
	await _until(func() -> bool: return _avatars(guest).of(1) != null and _avatars(host).of(_session(guest).me()) != null \
			and not _roster(guest).entry_of(1).is_empty(), "each to see the other's avatar")
	return [host, guest]


func _branch(label: String, keep: Array = KEEP) -> Node3D:
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
		if not keep.has(String(station.name)):
			station.get_parent().remove_child(station)
			station.free()
	view.add_child(zoo)
	_branches.append(node)
	return zoo


func _drop_branches() -> void:
	Input.action_release(Player.MOVE_FORWARD)
	Input.action_release(Player.CROUCH)
	for node in _branches:
		var session := node.get_node_or_null("View/Zoo/Session") as Session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


func _stand(player: Player, at: Vector3, yaw: float) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.rotation.y = yaw
	player.reset_physics_interpolation()


func _session(zoo: Node3D) -> Session:
	return zoo.get_node("Session") as Session


func _net(zoo: Node3D) -> ZooNet:
	return zoo.get_node("Net") as ZooNet


func _roster(zoo: Node3D) -> Roster:
	return zoo.get_node("Session/Roster") as Roster


func _avatars(zoo: Node3D) -> Avatars:
	return zoo.get_node("Avatars") as Avatars


func _player(zoo: Node3D) -> Player:
	return zoo.get_node("Player") as Player
