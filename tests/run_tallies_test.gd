## The run's tallies, record, Whiteboard and Tab (core/83). The Stages station's mini run with the
## game's player, a Parts (a Host of one) and a Whiteboard (the furniture scene, placed by the test: the
## station shows none): a pick and a shelve by the player's own input count in RunTallies and RunRecord,
## the held Tab shows the sheet on the HUD with the new number, the board's picture draws again once, no
## menu lets it open and one closes it, a leaver keeps their row, and the state rides a snapshot.
extends TestSuite

const STATION := "res://game/zoo/stations/stages.tscn"
const PLAYER := "res://game/player/player.tscn"
const BOARD := "res://game/furniture/collection_board.tscn"
const TAB := &"whiteboard_overlay"
const ACTIONS: Array[StringName] = [&"pick", &"drop_throw", &"interact", &"move_forward", TAB]
## The station's Socks, by id: Simple Pairs of Designs 0..5, then Sport.
const SIMPLE := [0, 2, 4, 6, 8, 10]
const BY_SOCKS := Vector3(-1.6, 0.0, 1.2)
const BY_CABINET := Vector3(-1.6, 0.0, -0.6)

var _level: Node3D = null
var _station: Node3D = null
var _player: Player = null
var _mess: Mess = null
var _hands: Hands = null
var _parts: Parts = null
var _a: Cabinet = null
var _board: Whiteboard = null
var _tallies: RunTallies = null
var _record: RunRecord = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "real_path", "method": "case_real_path", "world": false,
				"title": "real path: the player picks a Sock and holds Tab, the overlay's row reads 1 Socks picked and the board drew again once; picking its mate and shelving the Pair adds the Pairs, Pairs made, Coins and a RunRecord row [player, Design, Coins paid]"},
		{"name": "menu", "method": "case_menu", "world": false,
				"title": "Tab never opens over a menu (the player's input held) and closes when one opens; let go, it goes"},
		{"name": "kept", "method": "case_kept", "world": false,
				"title": "a player who left keeps their row and name; the tallies and the record ride a snapshot and a save"},
	]


func _before_case() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _level != null:
		_level.free()
		_level = null


func case_real_path() -> void:
	await _build()
	_check(InputMap.has_action(TAB), "the whiteboard_overlay action exists")
	var overlay := _overlay()
	_check(not overlay.is_shown(), "the overlay is shut while Tab is up")
	var renders := _board.renders
	_stand(BY_SOCKS)
	await _aim(_player, _centre(SIMPLE[3]))
	await _physics_ticks(25)
	await _press(&"pick")
	await _until(func() -> bool: return _hands.active_of(1) == SIMPLE[3], "the Sock to be in the Hands")
	Input.action_press(TAB)
	await _until(func() -> bool: return overlay.is_shown() and overlay.sheet().entries.size() == 1, "Tab to show the sheet with a row")
	var row: Dictionary = overlay.sheet().entries[0]
	_check(row["socks"] == 1 and row["pairs"] == 0 and row["coins"] == 0, "the row reads 1 Sock picked (%s)" % [row])
	_check(_tallies.tally(1, RunTallies.SOCKS) == 1 and _tallies.tally(1, RunTallies.MADE) == 0, "RunTallies counts the pick, no Pair made yet")
	await _physics_ticks(3)
	_check(_board.renders == renders + 1, "the board's picture was drawn again once (%d -> %d)" % [renders, _board.renders])
	Input.action_release(TAB)
	await _until(func() -> bool: return not overlay.is_shown(), "the overlay to go when Tab is let go")
	# The mate by input fuses a Pair, the click on the drawer shelves it.
	await _physics_ticks(25)
	await _aim(_player, _centre(SIMPLE[3] + 1))
	await _press(&"pick")
	await _until(func() -> bool: return _mess.is_pair(SIMPLE[3]), "the mate to fuse into a Pair")
	_stand(BY_CABINET)
	await _aim(_player, _drawer_front(_a, 0))
	await _press(&"pick")
	await _until(func() -> bool: return _a.shelved().size() == 1, "the Pair to be shelved")
	await _until(func() -> bool: return _record.shelved.size() == 1, "the record to hold the Pair")
	var coins := (_station.get_node("Socks/Bank") as Bank).of_player(1)
	_check(coins > 0, "shelving paid Coins (%d)" % coins)
	_check(_tallies.tally(1, RunTallies.PAIRS) == 1 and _tallies.tally(1, RunTallies.MADE) == 1 and _tallies.tally(1, RunTallies.SOCKS) == 2
			and _tallies.tally(1, RunTallies.COINS) == coins, "pairs 1, made 1, socks 2, coins %d (%s)" % [coins, _tallies.rows])
	var rec: Array = _record.shelved[0]
	_check(rec[0] == _tallies.key_of(1) and rec[1] == _mess.designs[SIMPLE[3]] and rec[2] == coins, "the record row is [player, Design, Coins paid] (%s)" % [rec])
	Input.action_press(TAB)
	await _until(func() -> bool: return overlay.is_shown() and overlay.sheet().team_total("pairs") == 1, "the overlay to show the Pair")
	_check(overlay.sheet().team_total("coins") == coins, "the Team row totals the Coins")
	Input.action_release(TAB)


func case_menu() -> void:
	await _build()
	var overlay := _overlay()
	_player.set_input_blocked(true)
	Input.action_press(TAB)
	await _physics_ticks(5)
	_check(not overlay.is_shown(), "Tab does not open over a menu")
	_player.set_input_blocked(false)
	await _until(func() -> bool: return overlay.is_shown(), "Tab held, no menu: the sheet shows")
	_player.set_input_blocked(true)
	await _until(func() -> bool: return not overlay.is_shown(), "a menu opening closes the sheet")
	_player.set_input_blocked(false)
	Input.action_release(TAB)


func case_kept() -> void:
	await _build()
	var roster := Roster.new()
	roster.name = "Roster"
	roster.players = {"ann": {"peer": 1, "name": "Ann", "colour": 0}, "bo": {"peer": 0, "name": "Bo", "colour": 1}}
	_level.add_child(roster)
	_parts.bind(_level)
	_tallies.rows = {"ann": {"pairs": 2, "made": 2, "socks": 5, "coins": 40}, "bo": {"pairs": 1, "made": 1, "socks": 3, "coins": 10}}
	var list := _tallies.listing()
	_check(list.size() == 2 and list[0]["name"] == "Ann" and not list[0]["left"], "the player here has a row (%s)" % [list])
	_check(list[1]["name"] == "Bo" and list[1]["left"] and list[1]["socks"] == 3, "the leaver keeps their name and row")
	_record.shelved = [["bo", 3, 10]]
	var snap := _parts.snapshot()
	var saved := _parts.save_snapshot()
	_tallies.rows = {}
	_record.shelved = []
	_parts.load_snapshot(snap)
	_check((_tallies.rows["bo"] as Dictionary)["socks"] == 3 and _record.shelved.size() == 1, "a join snapshot carries the tallies and the record")
	_check(saved.has(_tallies.id) and saved.has(_record.id), "a save holds both")


func _overlay() -> TabOverlay:
	return _player.get_node("Hud/TabOverlay") as TabOverlay


func _build() -> void:
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
	_station = (load(STATION) as PackedScene).instantiate() as Node3D
	_level.add_child(_station)
	_board = (load(BOARD) as PackedScene).instantiate() as Whiteboard
	_board.position = Vector3(6.0, 0.0, 6.0)
	_level.add_child(_board)
	_player = (load(PLAYER) as PackedScene).instantiate() as Player
	_player.position = BY_SOCKS
	_level.add_child(_player)
	_player.capture_mouse()
	_parts = Parts.new()
	_parts.name = "Parts"
	_level.add_child(_parts)
	add_child(_level)
	_mess = _station.get_node("Socks/Mess") as Mess
	_hands = _station.get_node("Socks/Hands") as Hands
	_a = _station.get_node("CabinetA/Cabinet") as Cabinet
	_tallies = _station.get_node("Run/RunTallies") as RunTallies
	_record = _station.get_node("Run/RunRecord") as RunRecord
	var stages := _station.get_node("Run/Stages") as Stages
	await _until(func() -> bool: return _player.is_on_floor() and _mess.looks_of(0) != null and stages.stage == 0,
			"the player to stand, the Socks to lie and the run to start")
	await _until(func() -> bool: return stages.due.is_empty(), "Stage 1's Socks to be laid")


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


func _drawer_front(cab: Cabinet, index: int) -> Vector3:
	var front := cab.get_parent().get_node("Drawer%d/Looks/Slide/Front" % (index + 1)) as Node3D
	return front.global_position + Vector3(0.3, 0.0, 0.0)


func _centre(sock: int) -> Vector3:
	if _mess.is_pair(sock):
		return _mess.pose_of(sock).origin
	return _mess.pose_of(sock) * Vector3(0.0, SockDress.box(_mess.design_of(sock)).y * 0.5, 0.0)
