## coop/12: the Host's guards against a Guest's bad packets, on the game's own Parts. Two zoos (only
## their Handling station, to stay light), each a machine of its own in one process, joined over real
## ENet through the zoo's own wiring (coop_join_test). The Guest's machine stands in for a modified
## client: it sends the wire forms Session's `_command` RPC reads, floods one verb, and lets its own
## avatar copy take a pose the Host's area forbids. Each time the Host drops or refuses it, counts it,
## changes nothing, and the Guest stays in the game and can still play.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Handling"]
const NET_WAIT_S := 20.0
## Where the Guest stands to pick at the Handling station, in the station's space (coop_join_test).
const BY_HANDLING := Vector3(0.0, 0.0, 1.5)

var _branches: Array[Node] = []
## Every answer the Guest's machine applied: the events, in order.
var _guest_heard: Array[Dictionary] = []


func cases() -> Array[Dictionary]:
	return [
		{"name": "bad_shape", "method": "case_bad_shape", "world": false,
				"title": "a Guest's malformed Commands to the Hands (not a Command, a NaN, a wrong type, a missing or extra arg, an out-of-range charge, an undeclared verb, a path outside the level) are each dropped and counted by reason; the Host's Hands and Mess do not change; the Guest's next pick is answered"},
		{"name": "flood", "method": "case_flood", "world": false,
				"title": "a Guest's flood of picks over the verb's rate: those within the rate are answered (refused: too far), the rest dropped and counted as rate; another verb still passes, and a second later the Guest's pick is granted"},
		{"name": "forged", "method": "case_forged", "world": false,
				"title": "a forged write: a Guest whose own avatar takes a pose outside the area (its copy's tuning widened) is dropped on the Host's copy, which keeps the last good pose; a Guest's knock Command and a Guest's event RPC that writes a knockdown are refused; nobody is down"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_guest_heard.clear()
	_drop_branches()


# --- The cases -----------------------------------------------------------------------------------

func case_bad_shape() -> void:
	var pair := await _joined()
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var hs := _session(host)
	var gs := _session(guest)
	var g := gs.me()
	var hands := String(LevelRuntime.of(host).hands.id)
	var sock := _spot_sock(host, "Floor")
	await _until(func() -> bool: return LevelRuntime.of(host).hands.pick_refusal(g, sock) == "", "the Host to see the Guest by the Sock")
	var before := _shared(host)
	var bad: Array = [
		"pick",                                                                        # shape: not an Array
		["pick", hands],                                                               # shape: too short
		["drop", hands, {"point": Vector3(NAN, 0.0, 0.0), "normal": Vector3.UP}],      # shape: not finite
		["pick", hands, {"sock": float(sock)}],                                        # args: a float for an int
		["pick", hands, {}],                                                           # args: missing
		["pick", hands, {"sock": sock, "also": 1}],                                    # args: extra
		["throw", hands, {"dir": Vector3.FORWARD, "charge": 5.0}],                     # args: out of range
		["knock", hands, {}],                                                          # verb: the Hands take no knock
		["pick", "../Host/View/Zoo/" + hands, {"sock": sock}],                         # no part: outside the level
	]
	for wire: Variant in bad:
		gs._command.rpc_id(1, wire)
	# Commands from one Guest arrive in order: once this pick is answered, every packet above was read.
	LevelRuntime.of(guest).hands.pick(g, sock)
	await _until(func() -> bool: return LevelRuntime.of(host).hands.items_of(g).has(sock), "the Guest's good pick after the bad packets to be granted")
	var counts: Dictionary = hs.dropped.get(g, {})
	_check(counts == {"shape": 3, "args": 4, "verb": 1, "no part": 1}, "each bad Command is dropped and counted by reason (%s)" % counts)
	_check(int(hs.stats["bad_packets"]) == bad.size(), "the total counts every drop (%d)" % int(hs.stats["bad_packets"]))
	var after := _shared(host)
	after["hands"].erase(gs.profile.id)
	before["hands"].erase(gs.profile.id)
	_same(after["hands"], before["hands"], "no dropped Command changed anyone else's Hands")
	_check(LevelRuntime.of(host).mess.state_of(sock) == Mess.State.HELD, "the Mess changed only by the good pick")
	_check(gs.is_online() and not gs.is_joining(), "the Guest is still in the game")
	_drop_branches()


func case_flood() -> void:
	var pair := await _joined()
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var hs := _session(host)
	var gs := _session(guest)
	var g := gs.me()
	var hh := LevelRuntime.of(host).hands
	var hands := String(hh.id)
	# The Guest stands far from the Handling station's Socks: a pick there is refused "far".
	_stand(_player(guest), _station(guest).to_global(BY_HANDLING) + Vector3(0.0, 0.0, 12.0))
	var far := _spot_sock(host, "Floor")
	await _until(func() -> bool: return hh.pick_refusal(g, far) == Hands.FAR, "the Host to see the Guest out of reach")
	var rate := Session.RATE
	_check(not hh.accepts()[&"pick"].has("rate"), "pick has the Session's own rate (%d a second)" % rate)
	var flood := rate * 3
	var t0 := Time.get_ticks_msec()
	for i in flood:
		gs._command.rpc_id(1, ["pick", hands, {"sock": far}])
	gs._command.rpc_id(1, ["cycle", hands, {"step": 1}])
	await _until(func() -> bool: return _answers(&"cycle") >= 1, "another verb sent after the flood to be answered")
	var sent_in := Time.get_ticks_msec() - t0
	var counts: Dictionary = hs.dropped.get(g, {})
	var refused := _answers(&"pick")
	print("GUARD flood: %d picks sent in %d ms; %d answered, %d dropped over the rate" % [flood, sent_in, refused, int(counts.get("rate", 0))])
	_check(sent_in < 1000 and refused == rate, "the Host answers the first %d in the second (%d)" % [rate, refused])
	_check(int(counts.get("rate", 0)) == flood - rate, "and drops the rest as rate (%s)" % counts)
	_check(_reasons(&"pick").all(func(r: String) -> bool: return r == Hands.FAR), "the answered ones are refused: too far (%s)" % [_reasons(&"pick")])
	_check(hh.items_of(g).is_empty(), "no flooded pick was granted")
	# The rate is per second: a second on, the Guest walks up and picks.
	_stand(_player(guest), _station(guest).to_global(BY_HANDLING))
	await _until(func() -> bool: return hh.pick_refusal(g, far) == "" and Time.get_ticks_msec() - t0 > 1100, "a second to pass and the Guest to stand by the Sock")
	LevelRuntime.of(guest).hands.pick(g, far)
	await _until(func() -> bool: return hh.items_of(g).has(far), "the Guest's pick a second later to be granted")
	_check(gs.is_online(), "the Guest is still in the game")
	_drop_branches()


func case_forged() -> void:
	var pair := await _joined()
	var host: Node3D = pair[0]
	var guest: Node3D = pair[1]
	var hs := _session(host)
	var gs := _session(guest)
	var g := gs.me()
	var copy := _avatars(host).of(g)
	var own := _avatars(guest).of(g)
	var gp := _player(guest)
	var good := _station(guest).to_global(BY_HANDLING)
	_stand(gp, good)
	await _until(func() -> bool: return copy.pose_position.distance_to(good) < 0.05, "the Host to see the Guest where it stands")
	# A modified Guest: its own copy takes any pose, and its player walks out of the area.
	var wide := own.tuning.duplicate() as AvatarTuning
	wide.area = Rect2(-10000.0, -10000.0, 20000.0, 20000.0)
	own.tuning = wide
	var dropped := copy.dropped
	var outside := Vector3(copy.tuning.area.end.x + copy.tuning.margin + 50.0, 0.0, good.z)
	_stand(gp, outside)
	await _until(func() -> bool: return own.pose_position.distance_to(outside) < 0.05, "the Guest's own copy to take the forged pose")
	await _until(func() -> bool: return copy.dropped > dropped + 5, "the Host's copy to drop the forged poses as they come")
	_check(copy.pose_position.distance_to(good) < 0.05, "the Host's copy keeps the last good pose (%s)" % copy.pose_position)
	_check(copy.position.distance_to(good) < 0.1, "and is drawn there")
	# The knockdown: a Guest may not knock, nor write the Host's answer itself.
	var hk := LevelRuntime.of(host).knockdowns
	var kd := String(hk.id)
	gs._command.rpc_id(1, ["knock", kd, {"target": Parts.HOST, "thrower": g, "push": Vector3.FORWARD, "high": 0.5,
			"side": 0.0, "at": Vector3.ZERO}])
	_expect_error("_event")
	gs._event.rpc_id(1, {"ok": true, "kind": &"knock", "by": Parts.HOST, "to": hk.id,
			"changes": {hk.id: {"down": {Parts.HOST: {"serial": 99}}}}})
	gs._command.rpc_id(1, ["let_go", kd, {}])
	await _until(func() -> bool: return _answers(&"let_go") >= 1, "a Command sent after the forgeries to be answered")
	await _physics_ticks(10)
	_check(int(hs.dropped.get(g, {}).get("verb", 0)) == 1, "the forged knock is dropped as a verb the Guest may not ask (%s)" % hs.dropped.get(g, {}))
	_check(not hk.is_down(Parts.HOST) and not hk.is_down(g), "nobody is knocked down on the Host")
	_check(not LevelRuntime.of(guest).knockdowns.is_down(Parts.HOST), "nor on the Guest")
	_check(not _player(host).knocked, "the Host's player stands")
	_check(gs.is_online(), "the Guest is still in the game")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## The Host's Hands and the Mess records, to compare before and after.
func _shared(zoo: Node3D) -> Dictionary:
	var h := LevelRuntime.of(zoo).hands
	return {"hands": h.held.duplicate(true), "mess": var_to_str(LevelRuntime.of(zoo).mess.state())}


func _answers(kind: StringName) -> int:
	return _guest_heard.filter(func(ev: Dictionary) -> bool: return StringName(ev.get("kind", &"")) == kind).size()


func _reasons(kind: StringName) -> Array:
	return _guest_heard.filter(func(ev: Dictionary) -> bool: return StringName(ev.get("kind", &"")) == kind) \
			.map(func(ev: Dictionary) -> String: return String(ev.get("reason", "")))


func _on_guest_applied(ev: Dictionary) -> void:
	_guest_heard.append(ev)


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
	_stand(_player(guest), _station(guest).to_global(BY_HANDLING))
	LevelRuntime.of(guest).parts.applied.connect(_on_guest_applied)
	return [host, guest]


func _station(zoo: Node3D) -> Node3D:
	return zoo.get_node("Stations/Handling") as Node3D


func _spot_sock(zoo: Node3D, spot: String) -> int:
	return (_station(zoo).get_node("Spots/" + spot) as SockSpot).sock


func _stand(player: Player, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


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
	for node in _branches:
		var session := _in_branch(node).session
		if session != null:
			session.close()
		var path := node.get_path()
		remove_child(node)
		node.free()
		get_tree().set_multiplayer(null, path)
	_branches.clear()


func _session(zoo: Node3D) -> Session:
	return LevelRuntime.of(zoo).session


func _net(zoo: Node3D) -> LevelNet:
	return LevelRuntime.of(zoo).net


func _roster(zoo: Node3D) -> Roster:
	return LevelRuntime.of(zoo).roster


func _avatars(zoo: Node3D) -> Avatars:
	return LevelRuntime.of(zoo).avatars


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
