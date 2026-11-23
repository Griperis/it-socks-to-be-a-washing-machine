## coop/09: a Guest's Hands and Throw (list 03 sections D to M, Q2220, Q2221, Q2473-Q2479). Two zoos in
## one process, each a machine of its own (tests/coop_mess_test.gd), real ENet over 127.0.0.1 with
## tests/support/lag_peer.gd on both ends, frames paced to 60 a second of wall time (a ghost's times
## are game time, the answers come in real time). The Guest's own pick, drop, Throw and wheel show at
## once as looks-only ghosts (GuestGhosts); the Host decides; a Throw flies on the stamped stream
## (FlightRow) and lies equal on both. Numbers are printed as `HANDS` lines.
extends TestSuite

const LagPeer := preload("res://tests/support/lag_peer.gd")
const ZOO := "res://game/zoo/zoo.tscn"
const HEAP := "Stations/Heap"
const NET_WAIT_S := 20.0
const FPS := 60
const LAG_MS := 50
## The stations kept (the rest are taken out: smaller answers and joins).
const KEEP := ["Heap", "Cabinet", "Handling"]
## The Socks poured at the heap for the real path.
const POUR := 6
## How near a Guest's own Throw ghost flies to the Host's flight before its first touch (coop/11).
const GHOST_ON_FLIGHT := 0.02

var _branches: Array[Node] = []
var _pace_next := 0
## Every flat sound played, in order, with the frame it played in.
var _flat: Array[Array] = []
## While true, the Guest's Commands never reach the Host (an answer withheld, F09).
var _withhold := false
## While true, the Guest's Throws go up aimed wrong, so the Host refuses them.
var _spoil_throws := false


func cases() -> Array[Dictionary]:
	return [
		{"name": "guest_pick_throw_real_path", "method": "case_guest_pick_throw_real_path", "world": false,
				"title": "coop/09 real path, 50 ms: the Guest clicks a Sock at the heap: the ghost flies at once, pick sounds at the click, the Hands change on the answer; it throws: the ghost leaves at once, the Host's body flies, lies equal on both"},
		{"name": "guest_drop", "method": "case_guest_drop", "world": false,
				"title": "coop/09 E01-E03: a Guest's drop falls at once as a ghost and ends where the Host's did"},
		{"name": "refusals", "method": "case_refusals", "world": false,
				"title": "coop/09 F01, F08, F09: a refused pick flies back with Hands full; a refused Throw is back in the Hands at once; an answer withheld 2 s goes back with refuse"},
		{"name": "race_one_sock", "method": "case_race_one_sock", "world": false,
				"title": "coop/09 L01, L02, F03, F04: the Host and the Guest click one Sock: the Host gets it; the Guest's grab fizzles silently and flies to the Host's Hands"},
		{"name": "guest_pairs_and_shelves", "method": "case_guest_pairs_and_shelves", "world": false,
				"title": "coop/09 J01, K01, K04: a Guest pairs (the moment on the answer) and shelves into a Cabinet drawer, paid, seen by the Host"},
		{"name": "late_join_mid_throw", "method": "case_late_join_mid_throw", "world": false,
				"title": "coop/09 A/H02, Q2472: a Guest joining while a Throw is in the air sees it fly on and lie where the Host's did"},
		{"name": "guest_throw_ghost_on_host_flight", "method": "case_guest_throw_ghost_on_host_flight", "world": false,
				"title": "coop/11, Q2481, 0 and 50 ms: the Guest charges and releases a full and a half Throw: its ghost leaves with the Host's launch, flies the Host's flight as the Guest's stream shows it, and eases from the first-person hand onto it in 0.2 s with no jump"},
	]


func _enter_tree() -> void:
	Sounds.played.connect(_on_played)


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(&"pick")
	Input.action_release(&"drop_throw")
	_flat.clear()
	_withhold = false
	_spoil_throws = false
	_drop_branches()


func _on_played(name: StringName, spatial: bool, _at: Vector3, _bus: StringName) -> void:
	if not spatial:
		_flat.append([name, Engine.get_process_frames()])


# --- The cases -----------------------------------------------------------------------------------

func case_guest_pick_throw_real_path() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var spout := _spout(host, POUR)
	await _press_button(host, "More")
	await _wait(func() -> bool: return spout.first >= 0 and spout.pending() == 0 and _all_lie(hm, gm) \
			and hm.count() - spout.first >= POUR, "the heap's pour to rest on both machines", FPS * 40)
	var gp := _player(guest)
	var gh := _hands(guest)
	var hh := _hands(host)
	var me := gp.player_id()
	var sock := _loose_lying(gm, spout.first, gm.count())
	_check(sock >= 0, "a loose Sock lies at the heap")
	await _aim_at(guest, gm.box_of(sock).get_center())
	await _wait(func() -> bool: return gp.aimed_sock == sock, "the Guest's crosshair to rest on Sock %d" % sock, FPS * 2)
	_flat.clear()
	var clicked := Engine.get_process_frames()
	await _press(&"pick")
	var view := gp.held_view()
	_check(view.has_ghost(sock), "D01: the ghost flies at once")
	_check(_played_within(&"pick", clicked, 4), "Q2478: pick sounds at the click (%s)" % [_flat])
	_check(not gh.items_of(me).has(sock), "D03: the Guest's Hands have not changed before the answer")
	_check(gm.state_of(sock) == Mess.State.LYING, "D03: the Sock still lies in the Guest's Mess")
	_check(gm.is_held_back(sock), "the Mess does not draw the Sock while its ghost flies")
	await _wait(func() -> bool: return gh.items_of(me).has(sock), "the Hands to change on the Host's answer")
	_check(hh.items_of(me).has(sock), "the Host's Hands hold the Sock for the Guest")
	_check(_count(&"pick") == 1, "pick sounds once, at the click, not again at the answer (%d)" % _count(&"pick"))
	await _wait(func() -> bool: return view.settled(), "the ghost to land in its place", FPS * 2)
	_check(view.looks_of(sock) != null and view.looks_of(sock).visible, "D04: the ghost became the held item")

	# The Throw: hold past the tap, release.
	await _aim_at(guest, gp.global_position + gp.global_basis * Vector3(0.0, 1.0, -4.0))
	Input.action_press(&"drop_throw")
	await _paced_ticks(int(gp.hands_tuning.tap * FPS) + 20)
	var released := Engine.get_process_frames()
	Input.action_release(&"drop_throw")
	await _paced_ticks(2)
	var ghost := gp.ghosts().ghost_of(sock)
	_check(ghost != null, "G01: the Throw's ghost leaves at once")
	_check(view.is_hidden(sock) or not gh.items_of(me).has(sock), "G01: the Sock leaves the Hands at once")
	_check(_played_within(&"throw", released, 4), "G01: throw sounds at once")
	await _wait(func() -> bool: return hm.moving_body(sock) != null, "the Host's window to show the body in flight")
	await _wait(func() -> bool: return gm.moving_body(sock) != null and FlightRow.of(gm.moving_body(sock)) != null,
			"the Guest's stamped copy of the Host's body")
	var row := FlightRow.of(gm.moving_body(sock))
	var heard := 0
	var largest_step := 0.0
	var last := ghost.drawn().origin if ghost != null and is_instance_valid(ghost) else Vector3.ZERO
	var back := 0
	var largest_back := 0.0
	var last_step := Vector3.ZERO
	var largest_change := 0.0
	var last_body := ghost.body().global_position if ghost != null and is_instance_valid(ghost) else Vector3.ZERO
	var last_body_step := Vector3.ZERO
	var dir := Vector3.ZERO
	while hm.state_of(sock) == Mess.State.FLYING or (ghost != null and is_instance_valid(ghost) and not ghost.is_done()):
		await _paced()
		heard = row.heard if is_instance_valid(row) else heard
		if ghost == null or not is_instance_valid(ghost) or ghost.is_done():
			break
		var now := ghost.drawn().origin
		largest_step = maxf(largest_step, now.distance_to(last))
		var step := now - last
		var body_now := ghost.body().global_position
		var body_step := body_now - last_body
		if last_step != Vector3.ZERO and hm.state_of(sock) == Mess.State.FLYING:
			# What the drawing adds to the ghost body's own motion (its bounces are the Host's too).
			largest_change = maxf(largest_change, (step - last_step).distance_to(body_step - last_body_step))
		last_step = step
		last_body = body_now
		last_body_step = body_step
		if dir == Vector3.ZERO and step.length() > 0.01:
			dir = Vector3(step.x, 0.0, step.z).normalized()
		elif dir != Vector3.ZERO and Vector3(step.x, 0.0, step.z).dot(dir) < 0.0:
			back += 1
			largest_back = maxf(largest_back, -Vector3(step.x, 0.0, step.z).dot(dir))
		last = now
	await _wait(func() -> bool: return _all_lie(hm, gm) and gp.ghosts().ghost_of(sock) == null, "the Throw to lie on both machines", FPS * 15)
	print("HANDS throw: the ghost's largest step a frame %.3f m, largest change of step over the ghost body's own %.3f m; frames drawn going back %d, at most %.3f m" \
			% [largest_step, largest_change, back, largest_back])
	_check(largest_change < 0.08, "G18: the ghost never jumps: the drawing changes its step a frame by under 0.08 m more than its body's own motion (%.3f m)" % largest_change)
	_check(largest_back < 0.05, "G18: the ghost never goes back along the Throw more than the blend's ease (%.3f m)" % largest_back)
	_check(heard >= 1, "H07, M04: the Guest hears the Host's body bounce (%d)" % heard)
	_check(not gm.is_held_back(sock), "the Mess draws the Sock again once the ghost lies")
	_check(gm.state_of(sock) == Mess.State.LYING and gm.pose_of(sock).is_equal_approx(hm.pose_of(sock)), "it lies where the Host's lies")
	_same(gm.state(), hm.state(), "both Messes are equal")
	_drop_branches()


func case_guest_drop() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var gp := _player(guest)
	var sock := await _guest_holds(host, guest, _handling_sock(guest, "Floor"))
	# Aim at the floor a metre and a half ahead, and tap.
	await _aim_at(guest, gp.global_position + gp.global_basis * Vector3(0.0, 0.0, -1.5))
	await _wait(func() -> bool: return gp.drop_refusal(_hands(guest)) == "", "a white crosshair on the floor", FPS * 2)
	Input.action_press(&"drop_throw")
	await _paced_ticks(2)
	Input.action_release(&"drop_throw")
	await _paced_ticks(2)
	var ghost := gp.ghosts().ghost_of(sock)
	_check(ghost != null, "E01: the drop's ghost falls at once")
	var y0 := ghost.drawn().origin.y if ghost != null else 0.0
	await _paced_ticks(4)
	_check(ghost != null and is_instance_valid(ghost) and ghost.drawn().origin.y < y0, "E02: it falls from the hand at once")
	var last := Transform3D.IDENTITY
	var flat_at_hand_over := false
	var kept := 0
	while ghost != null and is_instance_valid(ghost) and not ghost.is_done():
		last = ghost.drawn()
		flat_at_hand_over = ghost.is_flat()
		await _paced()
	while ghost != null and is_instance_valid(ghost) and ghost.looks() != null and gm.is_drawn(sock):
		kept += 1
		await _paced()
	_check(flat_at_hand_over, "G08: the ghost's cloth lies flat before the Mess draws the Sock")
	_check(kept >= 1, "G08: the ghost's Looks stays a few frames over the Mess's drawing (%d)" % kept)
	await _wait(func() -> bool: return _all_lie(hm, gm), "the drop to lie on both machines", FPS * 10)
	var rest := gm.pose_of(sock)
	print("HANDS drop: the ghost ended %.4f m from where the Host's lies" % last.origin.distance_to(rest.origin))
	_check(gm.pose_of(sock).is_equal_approx(hm.pose_of(sock)), "E03: it ends where the Host's did")
	_check(last.origin.distance_to(rest.origin) < 0.02, "G07: the ghost eased onto the Host's rest (%.4f m)" % last.origin.distance_to(rest.origin))
	_same(gm.state(), hm.state(), "both Messes are equal")
	_drop_branches()


func case_refusals() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gm := _mess(guest)
	var gp := _player(guest)
	var gh := _hands(guest)
	var hh := _hands(host)
	var me := gp.player_id()
	var view := gp.held_view()
	# The Guest's own copy lets it hold 3; the Host clamps the Guest's numbers to its Upgrades: 1 here.
	var mine := gp.hands_tuning.duplicate() as HandsTuning
	mine.capacity = 3
	gp.hands_tuning = mine
	var held := await _guest_holds(host, guest, _handling_sock(guest, "Floor"))
	var host_t := hh.own_tuning().duplicate() as HandsTuning
	host_t.capacity_most = 1
	hh.tuning = host_t
	var other := _handling_sock(guest, "OnTable")
	await _aim_at(guest, gm.box_of(other).get_center())
	await _wait(func() -> bool: return gp.aimed_sock == other, "the crosshair on a second Sock", FPS * 2)
	await _paced_ticks(int(gp.hands_tuning.grab_interval * FPS) + 2)
	await _press(&"pick")
	_check(view.has_ghost(other), "the second pick's ghost flies")
	await _wait(func() -> bool: return view.flying_back(other), "F01: the refused pick to fly back")
	_check(gp.message() == Player.HANDS_FULL, "D05: Hands full shows (%s)" % gp.message())
	_check(_count(&"refuse") >= 1, "D05: refuse plays")
	await _wait(func() -> bool: return not view.flying_back(other) and not gm.is_held_back(other), "the ghost to land where the Sock lies")
	_check(gm.state_of(other) == Mess.State.LYING and not gh.items_of(me).has(other), "F05: nothing changed in the Guest's Hands")

	# A refused Throw: back in the Hands at once.
	_spoil_throws = true
	await _aim_at(guest, gp.global_position + gp.global_basis * Vector3(0.0, 1.0, -4.0))
	Input.action_press(&"drop_throw")
	await _paced_ticks(int(gp.hands_tuning.tap * FPS) + 10)
	Input.action_release(&"drop_throw")
	await _paced_ticks(2)
	_check(gp.ghosts().ghost_of(held) != null and view.is_hidden(held), "the Throw's ghost leaves")
	await _wait(func() -> bool: return gp.ghosts().ghost_of(held) == null, "F08: the refused Throw's ghost to go")
	_check(not view.is_hidden(held) and view.looks_of(held) != null and view.looks_of(held).visible, "F08: the item is back in the Hands at once")
	_check(gh.items_of(me).has(held) and not gm.is_held_back(held), "the Hands and the Mess as before")
	_spoil_throws = false

	# An answer withheld 2 s: back with refuse.
	_withhold = true
	_flat.clear()
	Input.action_press(&"drop_throw")
	await _paced_ticks(int(gp.hands_tuning.tap * FPS) + 10)
	Input.action_release(&"drop_throw")
	await _paced_ticks(2)
	var timed := gp.ghosts().timed_out
	_check(gp.ghosts().ghost_of(held) != null, "the withheld Throw's ghost leaves")
	await _paced_ticks(int(gp.ghosts().tuning.answer_timeout * FPS * 0.8))
	_check(gp.ghosts().ghost_of(held) != null, "it still flies before 2 s")
	await _wait(func() -> bool: return gp.ghosts().timed_out > timed, "F09: the guess to time out", FPS * 2)
	_check(gp.ghosts().ghost_of(held) == null and not view.is_hidden(held), "F09: the item is back in the Hands")
	_check(_count(&"refuse") == 1, "F09: refuse plays once (%s)" % [_flat])
	_withhold = false
	_drop_branches()


func case_race_one_sock() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var hp := _player(host)
	var gp := _player(guest)
	var sock := _handling_sock(guest, "Floor")
	var at := gm.box_of(sock).get_center()
	await _aim_at(host, at, Vector3(0.6, 0.0, 0.0))
	await _aim_at(guest, at, Vector3(-0.6, 0.0, 0.0))
	await _wait(func() -> bool: return hp.aimed_sock == sock and gp.aimed_sock == sock, "both crosshairs on Sock %d" % sock, FPS * 2)
	_flat.clear()
	hp.capture_mouse()
	await _press(&"pick")
	var view := gp.held_view()
	_check(view.has_ghost(sock), "the Guest's ghost flies")
	_check(_hands(host).items_of(Parts.HOST).has(sock), "L02: the Host's own click is answered at once: it holds the Sock")
	await _wait(func() -> bool: return not view.has_ghost(sock) and not gp.ghosts().pick_waiting(), "the Guest's answer")
	_check(view.flying_back(sock), "F03: the loser's ghost flies (to the winner's Hands)")
	await _wait(func() -> bool: return not view.flying_back(sock), "the ghost to arrive")
	_check(_count(&"refuse") == 0, "F04: no refuse")
	_check(gp.message() == "", "F04: no message (%s)" % gp.message())
	_check(gm.state_of(sock) == Mess.State.HELD and not _hands(guest).items_of(gp.player_id()).has(sock), "one got it, the other did not")
	_check(hm.state_of(sock) == Mess.State.HELD, "the Host holds it")
	_drop_branches()


func case_guest_pairs_and_shelves() -> void:
	var zoos := await _pair(LAG_MS)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var gp := _player(guest)
	var gh := _hands(guest)
	var me := gp.player_id()
	var cabinet := guest.get_node("Stations/Cabinet").find_children("*", "Cabinet", true, false)[0] as Cabinet
	var host_cab := host.get_node("Stations/Cabinet").find_children("*", "Cabinet", true, false)[0] as Cabinet
	var mates := _lying_mates(gm, cabinet.collection)
	_check(mates.size() == 2, "two lying mates of the Cabinet's Collection")
	if mates.size() < 2:
		return
	var mine := gp.hands_tuning.duplicate() as HandsTuning
	mine.capacity = 3
	gp.hands_tuning = mine
	await _guest_holds(host, guest, mates[0])
	var view := gp.held_view()
	var played := view.moments_played
	await _stand_by(guest, gm.box_of(mates[1]).get_center())
	await _paced_ticks(int(mine.grab_interval * FPS) + 2)
	gp.ghosts().pick(mates[1])
	await _paced_ticks(2)
	_check(view.moments_played == played, "Q2479: no pairing moment before the answer")
	await _wait(func() -> bool: return view.moments_played > played, "J02: the pairing moment on the answer")
	_check(gm.is_pair(mates[0]) and gh.items_of(me).has(mates[0]), "J01: the Pair is held, as on the Host")
	_check(hm.is_pair(mates[0]), "the Host's Mess has the Pair")
	await _stand_by(guest, (cabinet.drawer(0).get_parent() as Node3D).global_position)
	var coins := host_cab.coins_of()
	var before := coins.of_player(me) if coins != null else 0
	cabinet.click(me, 0)
	await _wait(func() -> bool: return host_cab.shelved().has(mates[0]), "K01: the Host shelves the Guest's Pair")
	await _wait(func() -> bool: return cabinet.shelved().has(mates[0]), "the Guest sees it shelved")
	if coins != null:
		await _wait(func() -> bool: return coins.of_player(me) > before, "K04: the Guest is paid")
		var gcoins := cabinet.coins_of()
		await _wait(func() -> bool: return gcoins.of_player(me) == coins.of_player(me), "the Guest's bank shows it")
	_drop_branches()


func case_late_join_mid_throw() -> void:
	var host := _branch("Host")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, LAG_MS)
	var hm := _mess(host)
	var sock := _handling_sock(host, "Floor")
	var from := Vector3(0.0, 1.5, 8.0)
	var parts := LevelRuntime.of(host).parts
	parts.apply({"ok": true, "kind": &"throw", "by": Parts.HOST, "to": hm.id,
			"changes": {hm.id: hm.thrown_patch(sock, Transform3D(Basis.IDENTITY, from), Vector3(0.0, 6.0, 1.5), Vector3(1.0, 2.0, 0.5), Parts.HOST)}})
	var guest := _branch("Guest")
	await _frames(2)
	var gs := LevelRuntime.of(guest).session
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, LAG_MS)
	var gm := _mess(guest)
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") and gm.count() == hm.count(),
			"the Guest to be welcomed", FPS * 10)
	_check(hm.state_of(sock) == Mess.State.FLYING, "the Throw is still in the air at the welcome")
	await _wait(func() -> bool: return gm.moving_body(sock) != null, "the late Guest's copy of the Throw", FPS * 2)
	var body := gm.moving_body(sock)
	var p0 := body.global_position if body != null else Vector3.ZERO
	await _paced_ticks(10)
	_check(body != null and is_instance_valid(body) and body.global_position.distance_to(p0) > 0.05, "it flies on")
	await _wait(func() -> bool: return _all_lie(hm, gm), "the Throw to lie on both", FPS * 10)
	_check(gm.pose_of(sock).is_equal_approx(hm.pose_of(sock)), "it lies where the Host's lies")
	_drop_branches()


# --- Helpers -------------------------------------------------------------------------------------

## A Host and a Guest `lag_ms` each way, the Guest welcomed; the Host's player does not act.
## coop/11: the Guest's own Throw, by its real input (hold past the tap, release at a charge), at 0
## and 50 ms, full and half: the ghost's body against the Host's body at the same moment of the
## flight as the Guest's stream shows it (FlightRow.sample()), until the first touch; the drawn ghost
## on that flight once the hand-over is done; no frame's step more than the Host's own frame.
func case_guest_throw_ghost_on_host_flight() -> void:
	for lag_ms: int in [0, LAG_MS]:
		for c: float in [1.0, 0.5]:
			await _ghost_against_host(lag_ms, c)


func _ghost_against_host(lag_ms: int, c: float) -> void:
	var zoos := await _pair(lag_ms)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var hm := _mess(host)
	var gm := _mess(guest)
	var gp := _player(guest)
	var gt := gp.ghosts().tuning
	var label := "%d ms, charge %.1f" % [lag_ms, c]
	var sock := await _guest_holds(host, guest, _handling_sock(guest, "Floor"))
	# A fixed point ahead, up, on what the crosshair meets.
	await _aim_at(guest, gp.global_position + gp.global_basis * Vector3(0.0, 1.2, -4.0))
	Input.action_press(&"drop_throw")
	await _paced_ticks(int(gp.hands_tuning.tap * FPS) + 1 + int(round(c * gp.hands_tuning.charge_time * FPS)))
	var charge := gp.charge
	Input.action_release(&"drop_throw")
	var ghost: ThrowGhost = null
	for _i in 4:
		await _paced()
		ghost = gp.ghosts().ghost_of(sock)
		if ghost != null:
			break
	_check(ghost != null, "%s: the Throw's ghost leaves at once" % label)
	if ghost == null:
		_drop_branches()
		return
	var hand := gp.hands().start_of(gp.player_id(), gp.aim_dir())
	var first_drawn := ghost.drawn().origin
	# Each tick before the first touch: [age, the ghost body's pose then, drawn then]; checked against
	# the stream once it has played that moment.
	var path: Array[Array] = []
	var pending: Array[Array] = []
	var touched := false
	var last_vel := ghost.body().linear_velocity
	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var worst_body := 0.0
	var worst_drawn := 0.0
	var compared := 0
	var worst_extra := 0.0
	var host_frame := 0.0
	var last_step := Vector3.ZERO
	var last_body_step := Vector3.ZERO
	var last_drawn := first_drawn
	var last_body := ghost.body().global_position
	var row: FlightRow = null
	while is_instance_valid(ghost) and not ghost.is_done():
		await _paced()
		if not is_instance_valid(ghost) or ghost.is_done():
			break
		var age := float(ghost.get("_age"))
		var body_at := ghost.body().global_position
		var drawn_at := ghost.drawn().origin
		var vel := ghost.body().linear_velocity
		# A touch: the velocity turned by more than gravity and drag explain in a tick.
		if not touched and (vel - last_vel).length() > g * 2.5 / FPS:
			touched = true
		last_vel = vel
		if not touched:
			# The ghost's own pose at its age (what it compares, G06) and what its drawing adds to it.
			var own: Variant = ghost.call("_pose_at", age)
			if own is Transform3D:
				pending.append([age, (own as Transform3D).origin, (own as Transform3D).origin + drawn_at - body_at])
		path.append([age, body_at, drawn_at])
		var step := drawn_at - last_drawn
		var body_step := body_at - last_body
		if hm.state_of(sock) == Mess.State.FLYING and path.size() > 1:
			worst_extra = maxf(worst_extra, (step - last_step).distance_to(body_step - last_body_step))
		last_step = step
		last_body_step = body_step
		last_drawn = drawn_at
		last_body = body_at
		var copy := gm.moving_body(sock)
		if row == null and copy != null:
			row = FlightRow.of(copy)
		var hb := hm.moving_body(sock)
		if hb != null:
			host_frame = maxf(host_frame, hb.linear_velocity.length() / FPS)
		if row == null or not is_instance_valid(row):
			continue
		var played := row.flight_time()
		while not pending.is_empty() and played >= float(pending[0][0]):
			var e: Array = pending.pop_front()
			var at: Variant = row.sample(float(e[0]))
			if not (at is Transform3D):
				continue
			var on := (at as Transform3D).origin
			compared += 1
			worst_body = maxf(worst_body, on.distance_to(e[1]))
			if float(e[0]) >= gt.hand_over_time:
				worst_drawn = maxf(worst_drawn, on.distance_to(e[2]))
	await _wait(func() -> bool: return _all_lie(hm, gm) and gp.ghosts().ghost_of(sock) == null, "%s: the Throw to lie on both machines" % label, FPS * 15)
	var lines: Array[String] = []
	for e: Array in path.slice(0, 48, 6):
		lines.append("%.2f body %s drawn %s" % [e[0], e[1], e[2]])
	print("HANDS ghost %s (charge %.3f): first drawn %.3f m from the hand; body vs the Host's flight at most %.4f m and drawn after the hand-over %.4f m over %d moments before the first touch; largest change of step over the body's own %.4f m, the Host's frame %.4f m\n  %s" \
			% [label, charge, first_drawn.distance_to(hand.origin), worst_body, worst_drawn, compared, worst_extra, host_frame, "\n  ".join(lines)])
	_check(compared >= 6, "%s: the ghost's flight was compared with the Host's at %d moments before its first touch" % [label, compared])
	_check(first_drawn.distance_to(hand.origin) < 0.1, "Q2481 %s: the ghost is drawn from the first-person hand (%.3f m)" % [label, first_drawn.distance_to(hand.origin)])
	_check(worst_body < GHOST_ON_FLIGHT, "coop/11 %s: the ghost's body flies the Host's flight within %.2f m (%.4f m)" % [label, GHOST_ON_FLIGHT, worst_body])
	_check(worst_drawn < GHOST_ON_FLIGHT, "Q2481 %s: after the %.1f s hand-over the drawn ghost is on the Host's flight within %.2f m (%.4f m)" % [label, gt.hand_over_time, GHOST_ON_FLIGHT, worst_drawn])
	_check(worst_extra <= host_frame, "Q2481 %s: no jump: the drawing changes its step by at most the Host's own motion in a frame (%.4f <= %.4f m)" % [label, worst_extra, host_frame])
	_drop_branches()


func _pair(lag_ms: int) -> Array[Node3D]:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = PlayerProfile.fresh()
	gs.profile = PlayerProfile.fresh()
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_lag(host, lag_ms)
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	_lag(guest, lag_ms)
	var hm := _mess(host)
	var gm := _mess(guest)
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined") and gm.count() == hm.count(),
			"the guest zoo to be welcomed with the Host's Mess", FPS * 10)
	var parts := LevelRuntime.of(guest).parts
	var up := parts.relay
	parts.relay = func(cmd: Command) -> void:
		if _withhold:
			return
		if _spoil_throws and cmd.kind == &"throw":
			cmd.args["dir"] = Vector3(1.0, 1.0, 0.0)
		up.call(cmd)
	# The Hands of each machine see the others' avatars (the Host decides a Guest's reach by it).
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null,
			"each machine's avatar of the other", FPS * 5)
	return [host, guest]


## The Guest picks lying Sock `sock` by its own click and holds it once answered. Returns the Sock.
func _guest_holds(_host: Node3D, guest: Node3D, sock: int) -> int:
	var gp := _player(guest)
	var gm := _mess(guest)
	await _aim_at(guest, gm.box_of(sock).get_center())
	await _wait(func() -> bool: return gp.aimed_sock == sock, "the Guest's crosshair on Sock %d" % sock, FPS * 2)
	await _press(&"pick")
	await _wait(func() -> bool: return _hands(guest).items_of(gp.player_id()).has(sock) and gp.held_view().settled(),
			"the Guest to hold Sock %d" % sock)
	return sock


## Stands `zoo`'s player 1.2 m from `target` (plus `aside`), looking at it, the mouse captured here only.
func _aim_at(zoo: Node3D, target: Vector3, aside := Vector3.ZERO) -> void:
	var player := _player(zoo)
	for other: Node in _branches:
		var p := _in_branch(other).player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	var flat := Vector3(target.x, 0.0, target.z)
	var feet := Vector3(player.global_position.x, 0.0, player.global_position.z)
	var away := feet - flat
	away = away.normalized() if away.length() > 0.3 else Vector3.BACK
	if flat.distance_to(feet) > 1.6 or aside != Vector3.ZERO:
		var stand := flat + away * 1.2 + aside
		player.global_position = Vector3(stand.x, player.global_position.y, stand.z)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	# Twice: a body pushed out of something as it lands looks again from where it stands.
	for _i in 2:
		await _paced_ticks(int(LAG_MS * 3 * FPS / 1000.0) + 4)
		var head := player.get_node("Head") as Node3D
		var to := target - player.global_position
		player.rotation.y = atan2(-to.x, -to.z)
		var up := target - head.global_position
		head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	await _paced_ticks(2)


func _stand_by(zoo: Node3D, target: Vector3) -> void:
	var player := _player(zoo)
	player.global_position = Vector3(target.x, 0.0, target.z) + Vector3(0.0, 0.0, 1.0)
	await _aim_at(zoo, target)


## Presses `action` for two paced ticks, then lets go.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _paced_ticks(2)
	Input.action_release(action)
	await _paced_ticks(1)


## Clicks a heap button on the Host's player, then lets the mouse go there.
func _press_button(zoo: Node3D, button: String) -> void:
	var station := zoo.get_node(HEAP) as Node3D
	var target := (station.get_node(button) as Node3D).global_position
	var player := _player(zoo)
	player.global_position = target + station.global_basis * Vector3(0.0, -0.5, -1.5)
	await _aim_at(zoo, target)
	await _press(&"pick")
	player.set("_captured", false)


## Whether a flat `name` played within `frames` of frame `from`.
func _played_within(name: StringName, from: int, frames: int) -> bool:
	for entry: Array in _flat:
		if StringName(entry[0]) == name and int(entry[1]) - from <= frames:
			return true
	return false


func _count(name: StringName) -> int:
	var n := 0
	for entry: Array in _flat:
		if StringName(entry[0]) == name:
			n += 1
	return n


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced_ticks(n: int) -> void:
	for _i in n:
		await _paced()


func _mess(zoo: Node3D) -> Mess:
	return LevelRuntime.of(zoo).mess


func _hands(zoo: Node3D) -> Hands:
	return LevelRuntime.of(zoo).hands


func _player(zoo: Node3D) -> Player:
	return LevelRuntime.of(zoo).player


func _avatar(zoo: Node3D, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a):
			return a
	return null


## The heap station's spout with a batch of `n`.
func _spout(zoo: Node3D, n: int) -> HeapSpout:
	var spout := zoo.get_node(HEAP + "/Spout/HeapSpout") as HeapSpout
	var t := spout.tuning.duplicate() as HeapTuning
	t.batch = n
	spout.tuning = t
	return spout


func _handling_sock(zoo: Node3D, spot: String) -> int:
	return (zoo.get_node("Stations/Handling/Spots/" + spot) as SockSpot).sock


func _all_lie(hm: Mess, gm: Mess) -> bool:
	return not hm.states.has(Mess.State.FLYING) and hm.waiting_count() == 0 and gm.count() == hm.count() \
			and not gm.states.has(Mess.State.FLYING) and gm.moving_count() == 0


func _loose_lying(mess: Mess, lo: int, hi: int) -> int:
	for sock in range(lo, hi):
		if mess.state_of(sock) == Mess.State.LYING and not mess.is_pair(sock):
			return sock
	return -1


## Two lying loose Socks of one Design of `collection`, or fewer.
func _lying_mates(mess: Mess, collection: StringName) -> PackedInt32Array:
	var by_design: Dictionary[int, PackedInt32Array] = {}
	for sock in mess.count():
		var design := mess.design_of(sock)
		if mess.state_of(sock) != Mess.State.LYING or mess.is_pair(sock) or design == null or design.collection != collection:
			continue
		var list: PackedInt32Array = by_design.get(mess.designs[sock], PackedInt32Array())
		list.append(sock)
		by_design[mess.designs[sock]] = list
		if list.size() == 2:
			return list
	return PackedInt32Array()


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _lag(zoo: Node3D, lag_ms: int) -> void:
	var mp := zoo.multiplayer
	mp.multiplayer_peer = LagPeer.new(mp.multiplayer_peer as ENetMultiplayerPeer, lag_ms, 0.0, _branches.size())


## A zoo in a machine of its own (its own MultiplayerAPI and 3D world), with only the KEEP stations.
func _branch(label: String) -> Node3D:
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
		if not KEEP.has(String(station.name)):
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


## The level runtime of the zoo in branch `node` (a machine of its own), or null.
func _in_branch(node: Node) -> LevelRuntime:
	var zoo := node.get_node_or_null("View/Zoo")
	return LevelRuntime.of(zoo) if zoo != null else null
