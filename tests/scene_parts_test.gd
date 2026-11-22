## The scene-parts templates' own cases (copy and rename with the templates): a Host of one with no
## network, the packet shapes, and real ENet machines in one process: a Host, a Guest and a late
## Guest; a refused Command; the Host's guard against a Guest's bad Commands; reach; two players
## racing for one thing; a save through text; the gate; avatars; a carried thing's motion, also
## with 50 ms of delay each way.
## Each machine is a Node with its own MultiplayerAPI (SceneTree.set_multiplayer()), its own copy of
## a small level, its Parts and its Session, and Players with the Avatars spawner beside them; the
## Host listens on port 0 (the system picks).
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const AVATAR := "res://game/parts/avatar/avatar.tscn"

## Network waits give real time, which a busy machine stretches.
const NET_WAIT_S := 20.0
const DOOR := &"Room/Door/Openable"
const CELLAR := &"Room/Cellar/Openable"
const BOX := &"Room/Box/Carriable"


## Counts the engine's errors (not script errors): the replication's "Ignoring ... non-authority"
## and "Node not found" lines are errors a case must see.
class EngineErrors extends Logger:
	var mutex := Mutex.new()
	var lines: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			mutex.lock()
			lines.append(rationale if not rationale.is_empty() else code)
			mutex.unlock()


## Every machine this case made: {"node", "level", "parts", "session", "heard", "avatars"}.
var _machines: Array[Dictionary] = []
var _errors := EngineErrors.new()


func _enter_tree() -> void:
	OS.add_logger(_errors)


func _exit_tree() -> void:
	OS.remove_logger(_errors)


func cases() -> Array[Dictionary]:
	return [
		{"name": "alone", "method": "case_alone", "world": false,
				"title": "a Host of one, no network: use opens, a locked one refuses, one thing carried at a time"},
		{"name": "shapes", "method": "case_shapes", "world": false,
				"title": "a Command's wire shape refuses wrong types, NaN, long text and Objects"},
		{"name": "save", "method": "case_save", "world": false,
				"title": "a snapshot written as text and loaded into a fresh level gives the same state"},
		{"name": "host_guest_late", "method": "case_host_guest_late", "world": false,
				"title": "real ENet: a Guest opens and picks, a late Guest gets it all at once, a leaver's thing drops"},
		{"name": "refused", "method": "case_refused", "world": false,
				"title": "a locked thing refuses a Guest everywhere; bad packets are dropped and counted"},
		{"name": "guard", "method": "case_guard", "world": false,
				"title": "real ENet: a Guest's wrong type, missing or extra arg, undeclared verb, outside path and flood are dropped and counted"},
		{"name": "reach", "method": "case_reach", "world": false,
				"title": "once the game says where players stand, a player too far from a door is refused: far"},
		{"name": "carry_reach", "method": "case_carry_reach", "world": false,
				"title": "a thing is picked up only from near it, and put down only near the player"},
		{"name": "race", "method": "case_race", "world": false,
				"title": "two Guests ask for one thing at once: the first to arrive wins, the other is refused, all agree"},
		{"name": "aim", "method": "case_aim", "world": false,
				"title": "the aim lookup finds the first part of the entity a node belongs to, and none for the floor"},
		{"name": "looks", "method": "case_looks", "world": false,
				"title": "an openable finds its Looks' animation once and follows a swapped Looks"},
		{"name": "gate", "method": "case_gate", "world": false,
				"title": "a Guest on another PROTOCOL is refused at the gate: it hears why, gets no spawn and no synchronized value"},
		{"name": "avatars", "method": "case_avatars", "world": false,
				"title": "real ENet: avatars move both ways, a late Guest sees every avatar at its place and the parts' state, a leaver's goes"},
		{"name": "carry", "method": "case_carry", "world": false,
				"title": "a carried thing follows its holder on every machine; hand-overs both ways agree with no engine error; a leaver's drops"},
		{"name": "loss", "method": "case_loss", "world": false,
				"title": "with most pose packets lost, every Command still arrives and the pose catches up"},
		{"name": "carry_lag", "method": "case_carry_lag", "world": false,
				"title": "with 50 ms each way: a late Guest gets avatars, state and the carried thing; the hand-overs end agreeing, no engine error"},
		{"name": "speed", "method": "case_speed", "world": false, "perf": true,
				"title": "2,000 parts and 5,000 plain nodes: bind, snapshot, load, 1,000 Commands, the aim lookup and find stay within budget"},
	]


## A case that died early never reached _done(): its machines go now.
func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	_done_now()


func case_alone() -> void:
	var m := _machine("Alone")
	var parts: Parts = m["parts"]
	var me := (m["session"] as Session).me()
	_check(me == Parts.HOST and parts.is_host(), "alone, this player is the Host (id %d)" % me)
	parts.of(DOOR).use(me)
	_check((parts.of(DOOR) as Openable).open, "use opens the door at once")
	var heard: Array[Dictionary] = m["heard"]
	parts.of(CELLAR).use(me)
	_check(not (parts.of(CELLAR) as Openable).open and _reason(heard) == "locked", "the locked one refuses: locked")
	parts.of(BOX).use(me)
	_check((parts.of(BOX) as Carriable).holder == me, "the player carries the box")
	var second := _carriable(m, "Crate")
	second.pick(me)
	_check(second.holder == 0 and _reason(heard) == "full", "a second thing is refused: full")
	(parts.of(BOX) as Carriable).drop(me, Vector3(1.0, 0.0, 2.0), 0.5)
	_check((parts.of(BOX) as Carriable).holder == 0, "the box is put down")
	_check(((parts.of(BOX) as Node).get_parent() as Node3D).position == Vector3(1.0, 0.0, 2.0), "it lies where it was put")
	_done_now()


func case_shapes() -> void:
	_check(EnetTransport.split_address("10.0.0.2", 24565) == ["10.0.0.2", 24565], "an address without a port takes the default")
	_check(EnetTransport.split_address("example.org:7000", 24565) == ["example.org", 7000], "host:port")
	_check(EnetTransport.split_address("::1", 24565) == ["::1", 24565], "a bare IPv6 address is not cut at its colons")
	_check(EnetTransport.split_address("[fe80::2]:7000", 24565) == ["fe80::2", 7000], "an IPv6 address in brackets with a port")
	_check(EnetTransport.split_address("[::1]", 24565) == ["::1", 24565], "brackets without a port")
	_check(Command.shape_error(["open", "Room/Door/Openable", {"open": true}]) == "", "a Command is fine")
	_check(Command.shape_error(["drop", "Room/Box/Carriable", {"at": Vector3(1, 0, 2), "yaw": 0.5}]) == "",
			"a Vector3 and a float are fine")
	var bad := {
		"not an Array": {"kind": "open"},
		"two members": ["open", "Room/Door/Openable"],
		"a number for a kind": [7, "Room/Door/Openable", {}],
		"an empty target": ["open", "", {}],
		"a long target": ["open", "R".repeat(Command.TEXT_MAX + 1), {}],
		"args an Array": ["open", "Room/Door/Openable", [true]],
		"a NaN arg": ["drop", "Room/Box/Carriable", {"yaw": NAN}],
		"an INF Vector3": ["drop", "Room/Box/Carriable", {"at": Vector3.INF}],
		"an Object arg": ["open", "Room/Door/Openable", {"who": self}],
		"a nested Dictionary": ["open", "Room/Door/Openable", {"open": {"really": true}}],
	}
	for what: String in bad:
		_check(Command.from_wire(bad[what], 7) == null, "%s is refused" % what)
	var cmd := Command.from_wire(["open", "Room/Door/Openable", {"open": true}], 7)
	_check(cmd != null and cmd.by == 7, "the Host takes the sender from the network, not the wire")
	var declared := {"n": {"type": TYPE_INT, "min": 0, "max": 9}, "name": {"type": TYPE_STRING, "max": 4},
			"to": {"type": TYPE_VECTOR2, "min": -1.0, "max": 1.0}, "on": TYPE_BOOL}
	_check(Command.args_error({"n": 9, "name": &"abcd", "to": Vector2(1, -1), "on": false}, declared) == "",
			"declared args match: an int in bounds, a StringName for a String, a Vector2 in bounds")
	var wrong := {
		"an int out of bounds": {"n": 10, "name": "a", "to": Vector2.ZERO, "on": true},
		"a float for an int": {"n": 1.0, "name": "a", "to": Vector2.ZERO, "on": true},
		"a long String": {"n": 1, "name": "abcde", "to": Vector2.ZERO, "on": true},
		"a Vector2 component out of bounds": {"n": 1, "name": "a", "to": Vector2(0, 2), "on": true},
		"a missing arg": {"n": 1, "name": "a", "to": Vector2.ZERO},
		"an extra arg": {"n": 1, "name": "a", "to": Vector2.ZERO, "on": true, "more": 1},
	}
	for what: String in wrong:
		_check(Command.args_error(wrong[what], declared) != "", "%s does not match" % what)
	_check(Command.args_error({"o": self}, {"o": TYPE_OBJECT}) != "", "an Object cannot be declared")


func case_save() -> void:
	var a := _machine("Before")
	var parts: Parts = a["parts"]
	parts.of(DOOR).use(Parts.HOST)
	(parts.of(BOX) as Carriable).pick(Parts.HOST)
	(parts.of(BOX) as Carriable).drop(Parts.HOST, Vector3(3.0, 0.0, -1.0), 1.25)
	# Through the text a save file holds (JSON of plain values: no object is ever built from it).
	var back := _roundtrip(parts.snapshot())
	var b := _machine("After")
	(b["parts"] as Parts).load_snapshot(back)
	_check(_agree([a, b]), "the loaded level has the saved state")
	_check(((b["parts"] as Parts).of(BOX).get_parent() as Node3D).position == Vector3(3.0, 0.0, -1.0), "the box lies where it was saved")
	_done_now()


func case_host_guest_late() -> void:
	var host := _host()
	var guest := await _guest("Guest")
	var g_id := (guest["session"] as Session).me()
	var hp: Parts = host["parts"]
	var gp: Parts = guest["parts"]
	_check((gp.of(CELLAR) as Openable).locked, "the Guest's snapshot carries the locked cellar")
	gp.of(DOOR).use(g_id)
	_check(not (gp.of(DOOR) as Openable).open, "the Guest's door is still shut before the Host answers")
	await _until(func() -> bool: return (gp.of(DOOR) as Openable).open, "the Guest's door to open")
	_check((hp.of(DOOR) as Openable).open, "the Host's door is open")
	gp.of(BOX).use(g_id)
	await _until(func() -> bool: return (gp.of(BOX) as Carriable).holder == g_id, "the Guest to hold the box")
	_check((hp.of(BOX) as Carriable).holder == g_id, "the Host sees the Guest holding it")
	var late := await _guest("Late")
	var lp: Parts = late["parts"]
	_check((lp.of(DOOR) as Openable).open and (lp.of(BOX) as Carriable).holder == g_id,
			"the late Guest gets the open door and the holder in its snapshot")
	_check(((lp.of(BOX) as Node).get_parent() as Node).get_multiplayer_authority() == g_id,
			"the late Guest's box moves as its holder moves it (the holder is its authority)")
	await _until(func() -> bool: return _agree([host, guest, late]), "all three machines to agree")
	(guest["session"] as Session).close()
	await _until(func() -> bool: return (lp.of(BOX) as Carriable).holder == 0, "the late Guest to see the leaver's box drop")
	_check((hp.of(BOX) as Carriable).holder == 0, "the Host let go of the leaver's box")
	await _done()


func case_refused() -> void:
	var host := _host()
	var guest := await _guest("Guest")
	var gs: Session = guest["session"]
	var hs: Session = host["session"]
	(guest["parts"] as Parts).of(CELLAR).use(gs.me())
	var heard: Array[Dictionary] = guest["heard"]
	await _until(func() -> bool: return _reason(heard) == "locked", "the Guest to hear: locked")
	_check(not ((host["parts"] as Parts).of(CELLAR) as Openable).open, "the Host's cellar stays shut")
	_check(not ((guest["parts"] as Parts).of(CELLAR) as Openable).open, "the Guest's cellar stays shut")
	gs._command.rpc_id(1, ["drop", String(BOX), {"at": Vector3(NAN, 0.0, 0.0)}])
	gs._command.rpc_id(1, {"kind": "open"})
	gs._command.rpc_id(1, ["open", "Nowhere/Openable", {"open": true}])
	await _until(func() -> bool: return int(hs.stats["bad_packets"]) >= 3, "three bad Commands to be counted")
	_check(hs.dropped[gs.me()] == {"shape": 2, "no part": 1}, "they are counted by reason: %s" % hs.dropped[gs.me()])
	await _done()


func case_guard() -> void:
	var host := _host()
	var guest := await _guest("Guest")
	var hs: Session = host["session"]
	var gs: Session = guest["session"]
	var g_id := gs.me()
	var hp: Parts = host["parts"]
	var gp: Parts = guest["parts"]
	for s: Session in [hs, gs]:
		_check(not (s.multiplayer as SceneMultiplayer).allow_object_decoding, "object decoding is off on %s" % s.get_parent().name)
	gp.of(DOOR).use(g_id)
	await _until(func() -> bool: return (gp.of(DOOR) as Openable).open, "a well-formed Command to open the Guest's door")
	var doors := func() -> String: return var_to_str([hp.of(DOOR).state(), hp.of(CELLAR).state()])
	var before: String = doors.call()
	var outside := String(hp.of(DOOR).get_path())
	var bad: Array = [
		["open", String(DOOR), {"open": 0}],
		["open", String(DOOR), {}],
		["open", String(DOOR), {"open": false, "also": true}],
		["pick", String(DOOR), {}],
		["open", "../Host/Level/" + String(DOOR), {"open": false}],
		["open", outside, {"open": false}],
	]
	for wire: Array in bad:
		gs._command.rpc_id(1, wire)
	var flood := int((hp.of(DOOR) as Openable).accepts()[&"open"]["rate"]) + 5
	for i in flood:
		gs._command.rpc_id(1, ["open", String(CELLAR), {"open": true}])
	gp.of(BOX).use(g_id)
	# Commands from one Guest arrive in order: once the box is held, every packet above was read.
	await _until(func() -> bool: return (gp.of(BOX) as Carriable).holder == g_id, "the Guest to hold the box after the bad packets")
	var counts: Dictionary = hs.dropped.get(g_id, {})
	_check(counts.get("args") == 3 and counts.get("verb") == 1 and counts.get("no part") == 2,
			"a wrong type, a missing and an extra arg, an undeclared verb and two outside paths are counted: %s" % counts)
	var locked := _reasons(guest["heard"]).count("locked")
	_check(int(counts.get("rate", 0)) >= 1 and locked + int(counts.get("rate", 0)) == flood,
			"the flood: %d refused locked within the rate, %d dropped over it" % [locked, int(counts.get("rate", 0))])
	_check(int(hs.stats["bad_packets"]) == 6 + int(counts.get("rate", 0)), "the total counts every drop")
	var host_door := hp.of(DOOR) as Openable
	_check(doors.call() == before and host_door.open and not (hp.of(CELLAR) as Openable).open,
			"no dropped Command changed the Host's doors")
	await _until(func() -> bool: return _agree([host, guest]), "the Host and the Guest to agree")
	hp.ask(Command.new(&"pick", Parts.HOST, DOOR))
	_check(_reason(host["heard"]) == "wrong" and not hs.dropped.has(Parts.HOST),
			"the Host's own Command skips the guard and reaches decide(): wrong")
	hp.of(DOOR).use(Parts.HOST)
	_check(not host_door.open, "the Host's own use still works")
	await _until(func() -> bool: return _agree([host, guest]), "the Guest to see the Host shut the door")
	await _done()


func case_reach() -> void:
	var m := _machine("Alone")
	var parts: Parts = m["parts"]
	var door := parts.of(DOOR) as Openable
	var stands := {Parts.HOST: Vector3(door.reach + 1.0, 0.0, 0.0)}
	parts.where = func(by: int) -> Variant: return stands.get(by)
	door.use(Parts.HOST)
	_check(not door.open and _reason(m["heard"]) == "far", "a player out of reach is refused: far")
	stands[Parts.HOST] = Vector3(door.reach - 1.0, 0.0, 0.0)
	door.use(Parts.HOST)
	_check(door.open, "within reach the door opens")
	parts.ask(Command.new(&"open", 9, DOOR, {"open": false}))
	_check(door.open and _reason(m["heard"]) == "far", "a player the game cannot place is out of reach")
	_done_now()


func case_carry_reach() -> void:
	var m := _machine("Alone")
	var parts: Parts = m["parts"]
	var box := parts.of(BOX) as Carriable
	var stands := {Parts.HOST: Vector3(box.reach + 1.0, 0.0, 0.0)}
	parts.where = func(by: int) -> Variant: return stands.get(by)
	box.pick(Parts.HOST)
	_check(box.holder == 0 and _reason(m["heard"]) == "far", "a pick from out of reach is refused: far")
	stands[Parts.HOST] = Vector3(1.0, 0.0, 0.0)
	box.pick(Parts.HOST)
	_check(box.holder == Parts.HOST, "from near it the box is picked up")
	box.drop(Parts.HOST, Vector3(50.0, 0.0, 0.0), 0.0)
	_check(box.holder == Parts.HOST and _reason(m["heard"]) == "far", "putting it down across the level is refused: far")
	box.drop(Parts.HOST, Vector3(2.0, 0.0, 0.0), 0.0)
	_check(box.holder == 0 and (box.get_parent() as Node3D).position == Vector3(2.0, 0.0, 0.0), "near the player it is put down")
	parts.ask(Command.new(&"pick", 9, BOX))
	_check(box.holder == 0 and _reason(m["heard"]) == "far", "a player the game cannot place picks nothing up")
	_done_now()


func case_loss() -> void:
	var host := _host(0, 0.7)
	var guest := await _guest("Guest", 0, 0.7)
	var g_id := (guest["session"] as Session).me()
	var hp: Parts = host["parts"]
	var gp: Parts = guest["parts"]
	await _until(func() -> bool: return _avatar(host, g_id) != null and _avatar(guest, 1) != null, "each to have the other's avatar")
	_take_errors()
	# The Guest walks (a new pose every frame) and uses things meanwhile. The pose goes out 20 times
	# a second of real time, so the walk is paced in real time too: about 0.6 s, a dozen poses each way.
	var asked := 0
	for step in 40:
		_avatar(guest, g_id).pose_position = Vector3(step * 0.1, 0.0, 0.0)
		_avatar(host, 1).pose_position = Vector3(0.0, 0.0, step * 0.1)
		if step % 10 == 0:
			gp.of(DOOR).use(g_id)
			asked += 1
			await _until(func() -> bool: return (guest["heard"] as Array).size() == asked,
					"the Guest to hear the answer to its Command %d" % asked)
		OS.delay_msec(15)
		await _frames(1)
	_check((host["heard"] as Array).size() == asked and _reasons(host["heard"]).is_empty() and _agree([host, guest]),
			"every Command arrived and was granted (%d of %d), both agree" % [(host["heard"] as Array).size(), asked])
	var caught_up := func() -> bool:
		return _avatar(host, g_id).pose_position == Vector3(3.9, 0.0, 0.0) and _avatar(guest, 1).pose_position == Vector3(0.0, 0.0, 3.9)
	await _until(caught_up, "the newest pose to arrive both ways although most were lost")
	var lost := ((host["node"] as Node).multiplayer.multiplayer_peer as LagPeer).lost \
			+ ((guest["node"] as Node).multiplayer.multiplayer_peer as LagPeer).lost
	_check(lost > 0, "pose packets were lost on the way (%d)" % lost)
	_check(_take_errors().is_empty(), "no engine error under loss")
	await _done()


func case_race() -> void:
	var host := _host()
	var a := await _guest("A")
	var b := await _guest("B")
	var a_id := (a["session"] as Session).me()
	var b_id := (b["session"] as Session).me()
	var ap: Parts = a["parts"]
	var bp: Parts = b["parts"]
	ap.of(BOX).use(a_id)
	bp.of(BOX).use(b_id)
	ap.of(DOOR).use(a_id)
	bp.of(DOOR).use(b_id)
	var hp: Parts = host["parts"]
	await _until(func() -> bool: return (hp.of(BOX) as Carriable).holder != 0 and _agree([host, a, b]),
			"the box to have one holder on every machine")
	var holder := (hp.of(BOX) as Carriable).holder
	_check(holder == a_id or holder == b_id, "one of the two holds it")
	var loser: Array[Dictionary] = (b["heard"] if holder == a_id else a["heard"])
	await _until(func() -> bool: return _reasons(loser).has("gone"), "the other to hear: gone")
	_check((hp.of(DOOR) as Openable).open, "the door is open: the first press opened it")
	await _until(func() -> bool: return _reasons(a["heard"]).has("already") or _reasons(b["heard"]).has("already"),
			"the second press to be refused: already")
	await _done()


func case_aim() -> void:
	var m := _machine("Aim")
	var level: Node = m["level"]
	var door := level.get_node("Room/Door") as Node
	var mesh := Node3D.new()
	mesh.name = "Mesh"
	var body := Node3D.new()
	body.name = "Body"
	body.add_child(mesh)
	door.add_child(body)
	_check(Parts.part_of(door) == (m["parts"] as Parts).of(DOOR), "the thing's own root gives its part")
	_check(Parts.part_of(mesh) == (m["parts"] as Parts).of(DOOR), "a node deep inside the thing gives its part")
	_check(Parts.part_of(level.get_node("Room")) == null, "a room that is no entity gives none")
	_check(Parts.part_of(null) == null, "no node gives none")
	var second := Carriable.new()
	second.name = "AlsoCarriable"
	var first := Openable.new()
	first.name = "FirstDeclared"
	var thing := Node3D.new()
	thing.name = "Two"
	thing.add_child(first)
	thing.add_child(second)
	level.get_node("Room").add_child(thing)
	(m["parts"] as Parts).bind(level)
	_check(Parts.part_of(thing) == first, "with several parts, the first declared is the one use means")
	level.get_node("Room").remove_child(thing)
	(m["parts"] as Parts).bind(level)
	_check(Parts.part_of(thing) == null, "a rebind forgets an entity that left the level")
	thing.free()
	_done_now()


func case_looks() -> void:
	var m := _machine("Looks")
	var door := (m["level"] as Node).get_node("Room/Door") as Node
	var openable := (m["parts"] as Parts).of(DOOR) as Openable
	_check(openable.animator() == null, "no Looks yet: no animator")
	var one := _looks()
	door.add_child(one)
	var player := one.get_node("AnimationPlayer") as AnimationPlayer
	_check(openable.animator() == player and openable.animator() == player, "the Looks' animator is found, again on a second ask")
	door.remove_child(one)
	one.free()
	_check(openable.animator() == null, "a Looks taken away leaves no animator")
	var two := _looks()
	door.add_child(two)
	_check(openable.animator() == two.get_node("AnimationPlayer"), "a swapped Looks is followed")
	openable.write({"open": true}, true)
	_check((two.get_node("AnimationPlayer") as AnimationPlayer).current_animation_position > 0.9, "and shows the state")
	_done_now()


## A Looks child scene: an AnimationPlayer with a one second "open" animation.
static func _looks() -> Node3D:
	var looks := Node3D.new()
	looks.name = "Looks"
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	var library := AnimationLibrary.new()
	var animation := Animation.new()
	animation.length = 1.0
	library.add_animation(Openable.ANIMATION, animation)
	player.add_animation_library("", library)
	looks.add_child(player)
	return looks


func case_gate() -> void:
	var host := _host()
	var hp: Parts = host["parts"]
	var hs: Session = host["session"]
	_box(host).position = Vector3(2.0, 0.0, 3.0)
	hp.of(DOOR).use(Parts.HOST)
	var other := _machine("OtherBuild")
	var os: Session = other["session"]
	var ended: Array[String] = []
	os.ended.connect(func(text: String) -> void: ended.append(text))
	var word := PackedByteArray()
	word.resize(4)
	word.encode_u32(0, Session.PROTOCOL + 1)
	os.port = hs.port
	_check(os.join("127.0.0.1:%d" % hs.port) == OK, "the other build starts joining")
	os.multiplayer.peer_authenticating.disconnect(os._on_authenticating)
	var say_other := func(_peer: int) -> void: (os.multiplayer as SceneMultiplayer).send_auth(1, word)
	os.multiplayer.peer_authenticating.connect(say_other, CONNECT_ONE_SHOT)
	await _until(func() -> bool: return not ended.is_empty(), "the other build to be refused")
	_check(ended[0] == Session.WRONG_BUILD, "it hears why: %s" % ended[0])
	var counted: Dictionary = hs.dropped.values()[0] if hs.dropped.size() == 1 else {}
	_check(counted == {"protocol": 1}, "the Host counts it once, as protocol: %s" % hs.dropped)
	# The Host keeps replicating; give anything that leaked time to arrive.
	_box(host).position = Vector3(4.0, 0.0, 1.0)
	var until := Time.get_ticks_msec() + 500
	await _until(func() -> bool: return Time.get_ticks_msec() >= until, "half a second to pass")
	_check((other["players"] as Node).get_child_count() == 0, "it got no avatar spawn (the Host has %d)" % (host["players"] as Node).get_child_count())
	_check(_box(other).position == Vector3.ZERO, "it got no synchronized value: its box is at %s" % _box(other).position)
	_check(not ((other["parts"] as Parts).of(DOOR) as Openable).open, "it got no snapshot: its door is shut")
	_check(hs._guests.is_empty() and os.multiplayer.multiplayer_peer is OfflineMultiplayerPeer,
			"it was never admitted, and it is alone again")
	var guest := await _guest("Guest")
	_check(((guest["parts"] as Parts).of(DOOR) as Openable).open, "a Guest on this build is still welcomed after it")
	await _done()


func case_avatars() -> void:
	var host := _host()
	var a := await _guest("A")
	var a_id := (a["session"] as Session).me()
	await _until(func() -> bool: return _avatar(a, 1) != null and _avatar(host, a_id) != null, "each to have the other's avatar")
	_check(not _avatar(a, a_id).visible and not _avatar(host, 1).visible and _avatar(a, 1).visible,
			"a player's own avatar is hidden on its own machine and shown on the others")
	_take_errors()
	_avatar(host, 1).pose_position = Vector3(1.0, 0.0, 1.0)
	_avatar(host, 1).pose_yaw = 1.0
	_avatar(a, a_id).pose_position = Vector3(2.0, 0.0, 2.0)
	_avatar(a, a_id).pose_yaw = 2.0
	(a["parts"] as Parts).of(DOOR).use(a_id)
	var moved := func() -> bool:
		return _avatar(a, 1).pose_position == Vector3(1.0, 0.0, 1.0) and _avatar(host, a_id).pose_position == Vector3(2.0, 0.0, 2.0)
	await _until(moved, "the avatars to move both ways")
	var glided := func() -> bool: return _avatar(a, 1).position.distance_to(Vector3(1.0, 0.0, 1.0)) < 0.01
	await _until(glided, "the Guest's copy of the Host to glide to its pose")
	await _until(func() -> bool: return ((host["parts"] as Parts).of(DOOR) as Openable).open, "the Guest's Command to open the door")
	var late := await _guest("Late")
	var l_id := (late["session"] as Session).me()
	_check(_agree([host, a, late]), "the late Guest has the parts' state at once")
	var host_placed := func() -> bool:
		var host_avatar := _avatar(late, 1)
		return host_avatar != null and host_avatar.position.distance_to(Vector3(1.0, 0.0, 1.0)) < 0.01 \
				and absf(host_avatar.rotation.y - 1.0) < 0.01
	await _until(host_placed, "the late Guest to have the Host's avatar at its place")
	var placed := func() -> bool:
		var other := _avatar(late, a_id)
		return other != null and other.pose_position == Vector3(2.0, 0.0, 2.0) and other.pose_yaw == 2.0 \
				and other.position.distance_to(Vector3(2.0, 0.0, 2.0)) < 0.01
	await _until(placed, "the late Guest to have the other Guest's avatar at its place")
	await _until(func() -> bool: return _avatar(host, l_id) != null and _avatar(a, l_id) != null, "the late Guest's avatar on every machine")
	_avatar(late, l_id).pose_position = Vector3(3.0, 0.0, 3.0)
	await _until(func() -> bool: return _avatar(a, l_id).pose_position == Vector3(3.0, 0.0, 3.0), "a Guest to see the late Guest move (through the Host)")
	_avatar(a, a_id).pose_position = Vector3(NAN, 0.0, 0.0)
	_check(_avatar(a, a_id).pose_position == Vector3(2.0, 0.0, 2.0), "the owner's copy keeps no pose that is not finite (coop/05)")
	# As the synchronizer would write a forged one on a copy that receives it.
	_avatar(late, a_id).set(&"pose_position", Vector3(NAN, 0.0, 0.0))
	await _frames(2)
	_check(_avatar(late, a_id).pose_position == Vector3(2.0, 0.0, 2.0) and _avatar(late, a_id).dropped > 0,
			"a copy drops a pose that is not finite")
	_check(_avatar(late, a_id).position.distance_to(Vector3(2.0, 0.0, 2.0)) < 0.01, "and stays where it was")
	_check(_take_errors().is_empty(), "no engine error while they moved and joined")
	(a["session"] as Session).close()
	(a["avatars"] as Avatars).clear()
	await _until(func() -> bool: return _avatar(host, a_id) == null and _avatar(late, a_id) == null, "the leaver's avatar to go everywhere")
	await _done()


func case_carry() -> void:
	await _carry_round(0)


func case_carry_lag() -> void:
	await _carry_round(50)


## The carried box with `lag_ms` of delay each way on every machine: Guest A picks and carries it,
## a late Guest joins while A carries it, A drops it, the Host carries it and drops it, the late
## Guest carries it and drops it, A picks it again and leaves holding it.
func _carry_round(lag_ms: int) -> void:
	var host := _host(lag_ms)
	var a := await _guest("A", lag_ms)
	var a_id := (a["session"] as Session).me()
	var hp: Parts = host["parts"]
	var ap: Parts = a["parts"]
	var all: Array[Dictionary] = [host, a]
	_take_errors()
	(ap.of(BOX) as Carriable).pick(a_id)
	await _until(func() -> bool: return _authorities(all) == [a_id, a_id], "A to hold the box and own its motion everywhere")
	await _move(a, Vector3(1.0, 1.0, 0.0), all, "A carries it: the Host follows")
	var late := await _guest("Late", lag_ms)
	var l_id := (late["session"] as Session).me()
	all.append(late)
	_check(_authorities(all) == [a_id, a_id, a_id], "the late Guest's snapshot makes A the box's mover there too")
	await _until(func() -> bool: return _box(late).position == Vector3(1.0, 1.0, 0.0), "the late Guest to have the box where A holds it")
	await _until(func() -> bool: return _avatar(late, a_id) != null and _avatar(late, 1) != null, "the late Guest to have both avatars")
	await _move(a, Vector3(2.0, 1.0, 0.0), all, "A carries it on: the Host and the late Guest follow")
	# A lets go in the frame it asks to drop: no move of A's is in flight when the Host takes it back.
	(ap.of(BOX) as Carriable).drop(a_id, Vector3(2.0, 0.0, 0.0), 0.5)
	await _settle(all, 1, Vector3(2.0, 0.0, 0.0), "A drops it (Guest to Host)")
	(hp.of(BOX) as Carriable).pick(Parts.HOST)
	await _until(func() -> bool: return _agree(all) and (hp.of(BOX) as Carriable).holder == Parts.HOST, "the Host to hold it")
	await _move(host, Vector3(3.0, 1.0, 0.0), all, "the Host carries it: both Guests follow")
	(hp.of(BOX) as Carriable).drop(Parts.HOST, Vector3(3.0, 0.0, 0.0), 0.0)
	await _settle(all, 1, Vector3(3.0, 0.0, 0.0), "the Host drops it")
	((late["parts"] as Parts).of(BOX) as Carriable).pick(l_id)
	await _until(func() -> bool: return _authorities(all) == [l_id, l_id, l_id], "the late Guest to hold it (Host to Guest)")
	await _move(late, Vector3(4.0, 1.0, 0.0), all, "the late Guest carries it: the Host and A follow")
	((late["parts"] as Parts).of(BOX) as Carriable).drop(l_id, Vector3(4.0, 0.0, 0.0), 0.0)
	await _settle(all, 1, Vector3(4.0, 0.0, 0.0), "the late Guest drops it")
	var errors := _take_errors()
	_check(errors.is_empty(), "no engine error in the hand-overs: %s" % ", ".join(errors.slice(0, 3)))
	(ap.of(BOX) as Carriable).pick(a_id)
	await _until(func() -> bool: return _authorities(all) == [a_id, a_id, a_id], "A to hold it again")
	await _move(a, Vector3(5.0, 1.0, 0.0), all, "A carries it once more")
	(a["session"] as Session).close()
	(a["avatars"] as Avatars).clear()
	all.erase(a)
	await _settle(all, 1, Vector3(4.0, 0.0, 0.0), "A leaves holding it: it lies where it last lay")
	_box(host).position = Vector3(6.0, 0.0, 0.0)
	await _until(func() -> bool: return _box(late).position == Vector3(6.0, 0.0, 0.0), "the late Guest to follow the Host's move after the leave")
	errors = _take_errors()
	_check(errors.is_empty(), "no engine error around the leave: %s" % ", ".join(errors.slice(0, 3)))
	await _done()


## Moves `m`'s box over 10 frames to `to`, as hands would, then waits for every machine to show it there.
func _move(m: Dictionary, to: Vector3, all: Array[Dictionary], what: String) -> void:
	var from := _box(m).position
	for i in 10:
		_box(m).position = from.lerp(to, (i + 1) / 10.0)
		await _frames(1)
	await _until(func() -> bool: return _all_at(all, to), what)


## Waits for every machine to agree that the box lies at `at` with `mover` owning its motion.
func _settle(all: Array[Dictionary], mover: int, at: Vector3, what: String) -> void:
	var movers: Array[int] = []
	for m in all:
		movers.append(mover)
	await _until(func() -> bool: return _agree(all) and _authorities(all) == movers and _all_at(all, at),
			what + ": every machine agrees")


## Whether the box is at `at` on every machine.
static func _all_at(ms: Array[Dictionary], at: Vector3) -> bool:
	for m in ms:
		if _box(m).position != at:
			return false
	return true


## The box's multiplayer authority on each machine.
func _authorities(ms: Array[Dictionary]) -> Array[int]:
	var out: Array[int] = []
	for m in ms:
		out.append(_box(m).get_multiplayer_authority())
	return out


static func _box(m: Dictionary) -> Node3D:
	return (m["level"] as Node).get_node("Room/Box") as Node3D


static func _avatar(m: Dictionary, id: int) -> Avatar:
	return (m["avatars"] as Avatars).of(id)


## The engine errors logged since the last call.
func _take_errors() -> Array[String]:
	_errors.mutex.lock()
	var out := _errors.lines.duplicate()
	_errors.lines.clear()
	_errors.mutex.unlock()
	return out


## Budgets in microseconds, about three times what a laptop took (the README's "Cost" lists them).
const SPEED_BUDGETS_US := {
	"bind": 25000, "snapshot": 15000, "load_snapshot": 20000, "1,000 Commands": 25000,
	"aim, inside an entity (1,000)": 2000, "aim, the floor (1,000)": 3000, "find, no match (100)": 120000,
}


func case_speed() -> void:
	var node := Node.new()
	node.name = "Speed"
	add_child(node)
	var level := Node3D.new()
	level.name = "Level"
	node.add_child(level)
	var inside: Node = null
	var floor_node: Node = null
	var entity_count := 400
	for i in entity_count:
		var parent: Node = level
		if i >= entity_count / 2:
			for depth_name: String in ["Wing%d" % (i % 7), "Floor%d" % (i % 5), "Room%d" % i]:
				var next := parent.get_node_or_null(depth_name)
				if next == null:
					next = Node3D.new()
					next.name = depth_name
					parent.add_child(next)
				parent = next
		var entity := Node3D.new()
		entity.name = "Thing%d" % i
		var mesh := Node3D.new()
		mesh.name = "Mesh"
		entity.add_child(mesh)
		inside = mesh
		for k in 5:
			var part: Part = Openable.new() if (i + k) % 5 < 3 else Carriable.new()
			part.name = "Part%d" % k
			entity.add_child(part)
		parent.add_child(entity)
	var clutter := Node3D.new()
	clutter.name = "Clutter"
	level.add_child(clutter)
	for g in 100:
		var group := Node3D.new()
		group.name = "Group%d" % g
		clutter.add_child(group)
		for n in 50:
			var plain := Node3D.new()
			plain.name = "Plain%d" % n
			group.add_child(plain)
			floor_node = plain
	var parts := Parts.new()
	parts.name = "Parts"
	parts.level = level
	node.add_child(parts)
	var mark := _cpu_mark()
	var us := {}
	var t := Time.get_ticks_usec()
	parts.bind(level)
	us["bind"] = Time.get_ticks_usec() - t
	t = Time.get_ticks_usec()
	var snap := parts.snapshot()
	us["snapshot"] = Time.get_ticks_usec() - t
	t = Time.get_ticks_usec()
	parts.load_snapshot(snap)
	us["load_snapshot"] = Time.get_ticks_usec() - t
	var openables: Array[Openable] = []
	for id: StringName in snap:
		if parts.of(id) is Openable:
			openables.append(parts.of(id) as Openable)
	var granted: Array[int] = [0]
	parts.applied.connect(func(ev: Dictionary) -> void: granted[0] += 1 if ev["ok"] else 0)
	t = Time.get_ticks_usec()
	for i in 1000:
		var door := openables[i]
		parts.ask(Command.new(&"open", Parts.HOST, door.id, {"open": not door.open}))
	us["1,000 Commands"] = Time.get_ticks_usec() - t
	var found: Part = null
	t = Time.get_ticks_usec()
	for i in 1000:
		found = Parts.part_of(inside)
	us["aim, inside an entity (1,000)"] = Time.get_ticks_usec() - t
	var missed: Part = found
	t = Time.get_ticks_usec()
	for i in 1000:
		missed = Parts.part_of(floor_node)
	us["aim, the floor (1,000)"] = Time.get_ticks_usec() - t
	var none := func(_p: Part) -> bool: return false
	var hit: Part = found
	t = Time.get_ticks_usec()
	for i in 100:
		hit = parts.find(none)
	us["find, no match (100)"] = Time.get_ticks_usec() - t
	_check(parts.snapshot().size() == 2000 and granted[0] == 1000, "2,000 parts bound and 1,000 Commands granted (%d)" % granted[0])
	_check(found != null and missed == null and hit == null, "the lookups answer right in the big level")
	var line := ""
	for what: String in us:
		line += "%s %.2f ms; " % [what, int(us[what]) / 1000.0]
	print("  speed: ", line)
	for what: String in SPEED_BUDGETS_US:
		_budget(int(us[what]) <= int(SPEED_BUDGETS_US[what]),
				"%s: %.2f ms, budget %.0f ms" % [what, int(us[what]) / 1000.0, int(SPEED_BUDGETS_US[what]) / 1000.0], mark)
	node.free()


# --- Machines ------------------------------------------------------------------------------------

## A small level: a door, a locked cellar door and a box, in a room.
static func _level() -> Node3D:
	var level := Node3D.new()
	level.name = "Level"
	var room := Node3D.new()
	room.name = "Room"
	level.add_child(room)
	for door_name: String in ["Door", "Cellar"]:
		var door := Node3D.new()
		door.name = door_name
		var openable := Openable.new()
		openable.name = "Openable"
		openable.locked = door_name == "Cellar"
		door.add_child(openable)
		room.add_child(door)
	var box := Node3D.new()
	box.name = "Box"
	var carriable := Carriable.new()
	carriable.name = "Carriable"
	box.add_child(carriable)
	var motion := MultiplayerSynchronizer.new()
	motion.name = "Motion"
	motion.replication_config = SceneReplicationConfig.new()
	motion.replication_config.add_property(^".:position")
	motion.replication_config.property_set_replication_mode(^".:position", SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	box.add_child(motion)
	room.add_child(box)
	return level


## A machine: a Node with its own MultiplayerAPI, a level, its Parts and its Session (not open).
func _machine(label: String) -> Dictionary:
	var node := Node.new()
	node.name = label
	add_child(node)
	get_tree().set_multiplayer(SceneMultiplayer.new(), node.get_path())
	var level := _level()
	node.add_child(level)
	var parts := Parts.new()
	parts.name = "Parts"
	parts.level = level
	node.add_child(parts)
	var session := Session.new()
	session.name = "Session"
	session.parts = parts
	session.port = 0
	node.add_child(session)
	var players := Node3D.new()
	players.name = "Players"
	node.add_child(players)
	var avatars := Avatars.new()
	avatars.name = "Avatars"
	avatars.avatar_scene = load(AVATAR) as PackedScene
	avatars.spawn_path = ^"../Players"
	node.add_child(avatars)
	var heard: Array[Dictionary] = []
	parts.applied.connect(func(ev: Dictionary) -> void: heard.append(ev))
	var out := {"node": node, "level": level, "parts": parts, "session": session, "heard": heard,
			"players": players, "avatars": avatars}
	_machines.append(out)
	return out


## One more Carriable in a machine's level, bound like the rest.
func _carriable(m: Dictionary, thing_name: String) -> Carriable:
	var thing := Node3D.new()
	thing.name = thing_name
	var c := Carriable.new()
	c.name = "Carriable"
	thing.add_child(c)
	((m["level"] as Node).get_node("Room") as Node).add_child(thing)
	(m["parts"] as Parts).bind(m["level"])
	return c


## The Host, listening, with its avatar; with `lag_ms`, every packet it receives is held that long,
## and with `loss` that share of the unreliable ones never arrives.
func _host(lag_ms := 0, loss := 0.0) -> Dictionary:
	var m := _machine("Host")
	_check((m["session"] as Session).host() == OK, "the Host listens")
	_lag(m, lag_ms, loss)
	(m["avatars"] as Avatars).host()
	return m


## A Guest that joined the Host and got its snapshot.
func _guest(label: String, lag_ms := 0, loss := 0.0) -> Dictionary:
	var m := _machine(label)
	var s: Session = m["session"]
	var welcomed: Array[bool] = []
	s.welcomed.connect(func() -> void: welcomed.append(true))
	s.port = (_machines[0]["session"] as Session).port
	_check(s.join("127.0.0.1:%d" % s.port) == OK, "%s starts joining" % label)
	_lag(m, lag_ms, loss)
	await _until(func() -> bool: return not welcomed.is_empty(), "%s to be welcomed" % label)
	return m


func _lag(m: Dictionary, lag_ms: int, loss := 0.0) -> void:
	if lag_ms > 0 or loss > 0.0:
		var mp := (m["node"] as Node).multiplayer
		mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, loss, _machines.size())


## Whether every machine's state is the same.
static func _agree(ms: Array[Dictionary]) -> bool:
	var first := var_to_str((ms[0]["parts"] as Parts).snapshot())
	for m in ms:
		if var_to_str((m["parts"] as Parts).snapshot()) != first:
			return false
	return true


static func _reason(heard: Array[Dictionary]) -> String:
	return String(heard[-1].get("reason", "")) if not heard.is_empty() else ""


static func _reasons(heard: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for ev in heard:
		if ev.has("reason"):
			out.append(String(ev["reason"]))
	return out


func _done() -> void:
	for m in _machines:
		(m["session"] as Session).close()
	await _frames(2)
	_done_now()


## Frees each machine before it loses its MultiplayerAPI: the other order makes the replication of
## its synchronizers and spawner print errors.
func _done_now() -> void:
	for m in _machines:
		(m["session"] as Session).close()
		var path := (m["node"] as Node).get_path()
		remove_child(m["node"])
		(m["node"] as Node).free()
		get_tree().set_multiplayer(null, path)
	_machines.clear()
