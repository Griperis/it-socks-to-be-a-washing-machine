## core/141 (docs/architecture/wardrobe.md "What a player owns and wears, in co-op"): two zoos in one
## process, each a machine of its own, real ENet over 127.0.0.1 on a port the system picks, frames paced
## to 60 a second of wall time (tests/coop_hand_off_test.gd), only the Wardrobe station kept. The gate's
## word brings each profile's look, owned pieces, tallies and colour wish, clamped by the Host; the
## Roster's wear, colour and own are asked by a player for itself; every machine dresses each Avatar from
## the Roster; this machine's profile follows its own entry. Alone, the lone player has its entry too.
extends TestSuite

const ZOO := "res://game/zoo/zoo.tscn"
const KEEP := ["Wardrobe"]
const STATION := "Stations/Wardrobe"
const NET_WAIT_S := 20.0
const FPS := 60
## Where a player stands before the switches, in station space (tests/wardrobe_test.gd).
const BY_SWITCHES := Vector3(-0.8, 0.0, 4.1)
## Before the station's wardrobe (core/142), and one of its doors, in station space.
const BY_WARDROBE := Vector3(4.1, 0.0, 1.3)
const WARDROBE_DOOR := Vector3(5.2, 1.1, 1.3)
## Where the Host waits, out of the way.
const HOST_ASIDE := Vector3(4.0, 0.0, -4.0)

var _branches: Array[Node] = []
var _pace_next := 0


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path (co-op): the joiner sees the Host's Avatar in the Host's look; the Guest's word brings a forged look (an unknown hat), unknown owned ids and a huge tally: the Host cleans them at the gate and its Avatar of the Guest wears the owned Socks and Trail; the Guest presses E on the Hat switch: the real wear puts a basic hat on, on the Host's Avatar of the Guest; a wear of a piece the Guest does not own is refused and the Host still shows the old look; the Guest's own body shows only Socks and Trail, its mirror body the hat; its profile follows the look"},
		{"name": "colours", "method": "case_colours", "world": false,
				"title": "two players wishing the same colour: the Guest gets the next free one, its profile keeping the wish; colour of the Host's is refused taken; a free one is granted on both machines and the profile follows; own adds a known piece, refuses an unknown one"},
		{"name": "alone", "method": "case_alone", "world": false,
				"title": "alone (a Host of one) the lone player has its Roster entry with the profile's look: a fresh profile wears a basic hat by the Hat switch, its own body and mirror body dressed from its entry"},
		{"name": "station", "method": "case_station", "world": false,
				"title": "real path (co-op, core/142): the Guest presses E at the zoo's wardrobe: the doors swing open on both machines and the Guest's Wardrobe page opens (the Host's stays shut); a click on its Hats \">\" puts a basic hat on the Guest's preview and on the Host's Avatar of the Guest; its close key shuts the page and the doors close on both"},
		{"name": "save_merge", "method": "case_save_merge", "world": false,
				"title": "the Roster's save merge keeps a present player's live look, owned pieces and tallies over the save's, and brings an absent player's back from the save; owned_patch adds a won piece once"},
	]


func _before_case() -> void:
	wait_floor_s = NET_WAIT_S
	Input.action_release(&"interact")
	_drop_branches()


# --- The cases -----------------------------------------------------------------------------------

func case_real_path() -> void:
	var host_profile := PlayerProfile.fresh()
	host_profile.look = {"hat": "cap"}
	var guest_profile := PlayerProfile.fresh()
	guest_profile.look = {"hat": "no_such_hat", "clothes": "", "socks": "odd_pair", "trail": "lint_puffs"}
	guest_profile.pieces = PackedStringArray(["odd_pair", "lint_puffs", "nonsense"])
	guest_profile.tallies = {PlayerProfile.PAIRS_SHELVED: 1.0e12, PlayerProfile.COINS_EARNED: 40}
	var zoos := await _pair(host_profile, guest_profile)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gs := LevelRuntime.of(guest).session
	var g := gs.me()
	var roster := LevelRuntime.of(host).roster
	var entry: Dictionary = roster.players[guest_profile.id]
	# The gate cleaned the word.
	_same(entry["look"], {"hat": "", "clothes": "", "socks": "odd_pair", "trail": "lint_puffs"}, "the unknown hat is cleaned at the gate, the owned Socks and Trail kept")
	_same(Array(entry["owned"]), ["odd_pair", "lint_puffs"], "unknown owned ids are dropped at the gate")
	_check(int(entry["tallies"][PlayerProfile.PAIRS_SHELVED]) == PlayerProfile.TALLY_MAX and int(entry["tallies"][PlayerProfile.COINS_EARNED]) == 40,
			"the tallies are clamped (%s)" % str(entry["tallies"]))
	var seen := _avatar(host, g)
	await _wait(func() -> bool: return seen.looks.dresser().worn[&"socks"] == &"odd_pair" and seen.looks.dresser().worn[&"trail"] == &"lint_puffs",
			"the Host's Avatar of the Guest wears its Socks and Trail", FPS * 2)
	var host_seen := _avatar(guest, Parts.HOST)
	await _wait(func() -> bool: return host_seen.looks.dresser().worn[&"hat"] == &"cap", "the joiner is told the Host's look: its Avatar of the Host wears the cap", FPS * 2)
	# The Guest presses E on the Hat switch.
	await _aim(guest, _station_point(guest, BY_SWITCHES), _button(guest, "HatSwitch"))
	Input.action_press(&"interact")
	await _paced_ticks(2)
	Input.action_release(&"interact")
	var hat := _first_owned_hat()
	await _wait(func() -> bool: return seen.looks.dresser().worn[&"hat"] == hat, "on the Host the Guest's Avatar wears %s" % hat, FPS * 3)
	_check(seen.looks.dresser().hat != null, "its hat's Looks is on")
	var gp := LevelRuntime.of(guest).player
	await _wait(func() -> bool: return String(gp.mirror_body().look.get("hat", "")) == String(hat), "the Guest's mirror body takes the hat", FPS * 2)
	await _paced_ticks(1)
	var own := gp.own_body().dresser()
	_check(own.hat == null and own.clothes == null and own.socks.size() == 2 and own.worn[&"trail"] == &"lint_puffs",
			"the Guest's own body in first person shows only its Socks and Trail")
	_check(gp.mirror_body().dresser().hat != null, "its mirror body wears the hat")
	_check(String(gs.profile.look.get("hat", "")) == String(hat), "the Guest's profile follows its applied look")
	# A wear of a piece the Guest does not own (Simple's Sock hat) is refused: the Host keeps the old look.
	var refused := [false]
	var on_applied := func(ev: Dictionary) -> void:
		if ev.get("kind") == Roster.WEAR and not ev.get("ok", false):
			refused[0] = true
	LevelRuntime.of(guest).parts.applied.connect(on_applied)
	var forged := Roster.plain_look(roster.look_of(g))
	forged["hat"] = "sock_hat"
	LevelRuntime.of(guest).parts.ask(Command.new(Roster.WEAR, g, roster.id, forged))
	await _wait(func() -> bool: return refused[0], "the Guest hears its wear refused", FPS * 3)
	await _paced_ticks(3)
	_check(seen.looks.dresser().worn[&"hat"] == hat and String(roster.look_of(g)["hat"]) == String(hat), "the Host still shows the old look")
	_check(String(gs.profile.look.get("hat", "")) == String(hat), "the Guest's profile keeps the old look")
	_drop_branches()


func case_colours() -> void:
	var host_profile := PlayerProfile.fresh()
	var guest_profile := PlayerProfile.fresh()
	host_profile.colour = 2
	guest_profile.colour = 2
	var zoos := await _pair(host_profile, guest_profile)
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var gs := LevelRuntime.of(guest).session
	var g := gs.me()
	var roster := LevelRuntime.of(host).roster
	var groster := LevelRuntime.of(guest).roster
	_check(roster.colour_index_of(Parts.HOST) == 2, "the Host has its wish")
	_check(roster.colour_index_of(g) == 3, "the Guest wishing the same gets the next free one (%d)" % roster.colour_index_of(g))
	_check(gs.profile.colour == 2, "the Guest's profile keeps its wish")
	var answers: Array[Dictionary] = []
	LevelRuntime.of(guest).parts.applied.connect(func(ev: Dictionary) -> void:
		if ev.get("kind") in [Roster.COLOUR, Roster.OWN]:
			answers.append(ev))
	var parts := LevelRuntime.of(guest).parts
	parts.ask(Command.new(Roster.COLOUR, g, roster.id, {"index": 2}))
	await _wait(func() -> bool: return not answers.is_empty(), "the Guest hears its colour answer", FPS * 3)
	_check(not answers[0].get("ok", true) and answers[0].get("reason") == "taken", "the Host's colour is refused taken (%s)" % str(answers[0]))
	parts.ask(Command.new(Roster.COLOUR, g, roster.id, {"index": 5}))
	await _wait(func() -> bool: return roster.colour_index_of(g) == 5 and groster.colour_index_of(g) == 5, "a free colour is the Guest's on both", FPS * 3)
	var seen := _avatar(host, g)
	await _wait(func() -> bool: return seen.looks.colour == roster.tuning.colour(5), "the Host's Avatar of the Guest takes it", FPS)
	_check(gs.profile.colour == 5, "the Guest's profile follows its applied colour")
	_check(LevelRuntime.of(host).session.profile.colour == 2, "the Host's profile is untouched")
	# own: a known piece, then an unknown one.
	answers.clear()
	parts.ask(Command.new(Roster.OWN, g, roster.id, {"piece": "crown_of_socks_nope"}))
	await _wait(func() -> bool: return not answers.is_empty(), "the Guest hears its own answer", FPS * 3)
	_check(not answers[0].get("ok", true), "own of an unknown piece is refused")
	parts.ask(Command.new(Roster.OWN, g, roster.id, {"piece": "sock_hat"}))
	await _wait(func() -> bool: return roster.owned_of(guest_profile.id).has("sock_hat") and groster.owned_of(guest_profile.id).has("sock_hat"),
			"own: Sock hat is the Guest's on both", FPS * 3)
	_drop_branches()


func case_alone() -> void:
	var zoo := _branch("Alone")
	await _frames(2)
	var runtime := LevelRuntime.of(zoo)
	var profile := PlayerProfile.fresh()
	profile.look = {"socks": "odd_pair"}
	runtime.session.profile = profile
	_check(runtime.net.start([]) == OK, "the zoo plays alone")
	await _paced_ticks(2)
	var roster := runtime.roster
	_check(roster.id_of(Parts.HOST) == profile.id, "the lone player is in its own Roster")
	_same(roster.look_of(Parts.HOST)["socks"], "", "an unowned piece of the profile's look comes off at the start")
	await _aim(zoo, _station_point(zoo, BY_SWITCHES), _button(zoo, "HatSwitch"))
	Input.action_press(&"interact")
	await _paced_ticks(2)
	Input.action_release(&"interact")
	var hat := _first_owned_hat()
	await _wait(func() -> bool: return String(roster.look_of(Parts.HOST)["hat"]) == String(hat), "a fresh profile wears the basic hat %s" % hat, FPS * 2)
	var player := runtime.player
	await _paced_ticks(1)
	_check(String(player.own_body().look.get("hat", "")) == String(hat) and player.own_body().dresser().hat == null, "the own body has the look, but no hat in first person")
	_check(player.mirror_body().dresser().hat != null, "the mirror body wears it")
	_check(String(profile.look.get("hat", "")) == String(hat), "the profile follows")
	_drop_branches()


func case_station() -> void:
	var zoos := await _pair(PlayerProfile.fresh(), PlayerProfile.fresh())
	var host: Node3D = zoos[0]
	var guest: Node3D = zoos[1]
	var g := LevelRuntime.of(guest).session.me()
	var gid := LevelRuntime.of(guest).roster.id_of(g)
	var host_station := host.get_node("%s/WardrobeStation/WardrobeStation" % STATION) as WardrobeStation
	var guest_station := guest.get_node("%s/WardrobeStation/WardrobeStation" % STATION) as WardrobeStation
	await _aim(guest, _station_point(guest, BY_WARDROBE), _station_point(guest, WARDROBE_DOOR))
	_check(LevelRuntime.of(guest).player.aimed_part() == guest_station, "the Guest aims at the wardrobe")
	Input.action_press(&"interact")
	await _paced_ticks(2)
	Input.action_release(&"interact")
	await _wait(guest_station.menu.is_open, "the Guest's Wardrobe page to open", FPS * 3)
	await _wait(func() -> bool: return host_station.inside.has(gid), "the Host's station to have the Guest inside", FPS * 3)
	_check(not host_station.menu.is_open(), "the Host's own page stays shut")
	var host_door := host.get_node("%s/WardrobeStation/Looks/door_left" % STATION) as Node3D
	await _wait(func() -> bool: return absf(rad_to_deg(host_door.rotation.y)) > 79.0, "the doors to swing open on the Host", FPS * 2)
	var page := guest_station.menu.page()
	await _click(page.row(WardrobePiece.Slot.HAT).next_key())
	var hat := _first_owned_hat()
	_check(page.creature().dresser().worn[&"hat"] == hat, "the Guest's preview wears %s at once" % hat)
	var seen := _avatar(host, g)
	await _wait(func() -> bool: return seen.looks.dresser().worn[&"hat"] == hat, "the Host's Avatar of the Guest to wear %s" % hat, FPS * 3)
	await _click(page.close_key())
	_check(not guest_station.menu.is_open(), "the close key shuts the Guest's page")
	await _wait(func() -> bool: return host_station.inside.is_empty() and guest_station.inside.is_empty(), "the Guest to leave the station on both", FPS * 3)
	await _wait(func() -> bool: return absf(host_door.rotation.y) < 0.02, "the doors to swing shut on the Host", FPS * 2)
	_drop_branches()


## Clicks `control` in its own viewport (a branch's).
func _click(control: Control) -> void:
	await _paced_ticks(2)
	var at := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = pressed
		control.get_viewport().push_input(ev, true)
	await _paced_ticks(2)


func case_save_merge() -> void:
	var roster := Roster.new()
	roster.id = &"Roster"
	add_child(roster)
	var here := PlayerProfile.new_id()
	var away := PlayerProfile.new_id()
	roster.write(roster.joined(here, Parts.HOST, "Here", {"look": {"hat": "beanie"}, "owned": PackedStringArray(["sock_hat"]),
			"tallies": {PlayerProfile.PAIRS_SHELVED: 7}, "colour": 0})["changes"][roster.id], false)
	var saved := {"players": {
		here: {"peer": 0, "name": "Here", "colour": 0, "look": Roster.plain_look({"hat": "crown"}), "owned": PackedStringArray(), "tallies": {}},
		away: {"peer": 0, "name": "Away", "colour": 1, "look": Roster.plain_look({"hat": "cap"}), "owned": PackedStringArray(["peg_band"]), "tallies": {}},
	}}
	var merged: Dictionary = roster.restored(saved)["players"]
	_same(merged[here]["look"]["hat"], "beanie", "a present player keeps its live look")
	_same(Array(merged[here]["owned"]), ["sock_hat"], "and its live owned pieces")
	_same(int(merged[here]["tallies"][PlayerProfile.PAIRS_SHELVED]), 7, "and its live tallies")
	_same(merged[away]["look"]["hat"], "cap", "an absent player comes back in its saved look")
	var patch := roster.owned_patch(Parts.HOST, &"peg_band")
	_check(patch.has(roster.id) and Array(patch[roster.id]["players"][here]["owned"]).has("peg_band"), "owned_patch adds a won piece")
	_check(roster.owned_patch(Parts.HOST, &"sock_hat").is_empty() and roster.owned_patch(Parts.HOST, &"beanie").is_empty()
			and roster.owned_patch(Parts.HOST, &"nope").is_empty(), "owned_patch adds nothing owned, basic or unknown")
	roster.free()


# --- Helpers -------------------------------------------------------------------------------------

## The first hat of the row a fresh profile owns (a basic one).
func _first_owned_hat() -> StringName:
	var owned := Wardrobe.owned(PackedStringArray())
	for p in Wardrobe.row(WardrobePiece.Slot.HAT):
		if Wardrobe.shown(p) and owned.has(String(p.id)):
			return p.id
	return &""


func _pair(host_profile: PlayerProfile, guest_profile: PlayerProfile) -> Array[Node3D]:
	var host := _branch("Host")
	var guest := _branch("Guest")
	await _frames(2)
	var hs := LevelRuntime.of(host).session
	var gs := LevelRuntime.of(guest).session
	hs.port = 0
	hs.profile = host_profile
	gs.profile = guest_profile
	_check(LevelRuntime.of(host).net.start(["--host"]) == OK, "the host zoo hosts")
	_check(LevelRuntime.of(guest).net.start(["--join=127.0.0.1:%d" % hs.port]) == OK, "the other zoo joins it")
	await _wait(func() -> bool: return LevelRuntime.of(guest).net.mode_text().begins_with("Joined"), "the guest zoo to be welcomed", FPS * 10)
	await _wait(func() -> bool: return _avatar(host, gs.me()) != null and _avatar(guest, Parts.HOST) != null, "each machine's avatar of the other", FPS * 5)
	_place(host, _station_point(host, HOST_ASIDE), _station_point(host, Vector3.ZERO))
	return [host, guest]


func _station_point(zoo: Node3D, local: Vector3) -> Vector3:
	return (zoo.get_node(STATION) as Node3D).global_transform * local


func _button(zoo: Node3D, switch: String) -> Vector3:
	return (zoo.get_node("%s/%s/Looks/Button" % [STATION, switch]) as Node3D).global_position


## Stands `zoo`'s player at `feet` looking at `target`; only it has the mouse.
func _aim(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := LevelRuntime.of(zoo).player
	for other: Node in _branches:
		var p := _in_branch(other).player
		if p != null and p != player:
			p.set("_captured", false)
	player.capture_mouse()
	_place(zoo, feet, target)
	await _stands_still(player)
	_place(zoo, Vector3(feet.x, player.global_position.y, feet.z), target)
	await _paced_ticks(2)


func _stands_still(player: Player) -> void:
	var last := player.global_position
	for _i in FPS * 2:
		await _paced()
		var now := player.global_position
		if player.is_on_floor() and now.distance_to(last) < 0.0005:
			return
		last = now
	_check(false, "the player to stand still where it was put (within %d frames)" % (FPS * 2))


func _place(zoo: Node3D, feet: Vector3, target: Vector3) -> void:
	var player := LevelRuntime.of(zoo).player
	player.global_position = feet
	player.velocity = Vector3.ZERO
	var to := target - feet
	player.rotation.y = atan2(-to.x, -to.z)
	var head := player.get_node("Head") as Node3D
	var up := target - (feet + Vector3.UP * head.position.y)
	head.rotation.x = clampf(atan2(up.y, Vector2(up.x, up.z).length()), -1.5, 1.5)
	player.reset_physics_interpolation()


func _wait(cond: Callable, what: String, max_frames := FPS * 6) -> void:
	var frames := 0
	while frames < max_frames and not cond.call():
		await _paced()
		frames += 1
	_check(cond.call(), "%s (within %d frames)" % [what, max_frames])


func _paced_ticks(n: int) -> void:
	for _i in n:
		await _paced()


func _paced() -> void:
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	if _pace_next == 0 or now - _pace_next > 100000:
		_pace_next = now
	_pace_next += 1000000 / FPS
	if now < _pace_next:
		OS.delay_usec(_pace_next - now)


func _avatar(zoo: Node3D, peer: int) -> Avatar:
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and zoo.is_ancestor_of(a) and not a.is_queued_for_deletion():
			return a
	return null


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
