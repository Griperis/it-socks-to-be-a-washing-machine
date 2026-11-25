## The way back to the Lobby once a run ended (docs/architecture/run-ends.md "Continue", core/97, Q1836): any
## player's Continue asked the Host (`LaundryDay.CONTINUE`); its answer reached every machine and each one calls
## `go()`. The Host (or a player alone) saves the finished World and opens the Lobby again (`LobbyState.REOPEN`:
## not started, nobody Ready); a Guest waits until it has seen that. Then each machine loads `lobby.tscn` behind the
## loading screen, the link (Session, Roster) kept: the Host as Host with the finished World chosen as a record,
## Solo as Solo, a Guest as a Guest of the same Host (already joined, so the Lobby does not join again).
class_name LobbyReturn
extends RefCounted

## Marks a runtime that is already on its way.
const GOING := &"going_to_lobby"
## The longest the Host waits for its Guests to leave the house, in milliseconds.
const GUESTS_WAIT_MS := 8000


## Every machine, from the answer of Continue: saves (Host), waits for the Lobby to be open again, goes.
static func go(runtime: LevelRuntime) -> void:
	var link := runtime.link
	if link == null or not is_instance_valid(link) or runtime.has_meta(GOING):
		return
	runtime.set_meta(GOING, true)
	if runtime.parts.is_host():
		runtime.autosave.save_now()
		if link.lobby.started:
			link.parts.ask(link.lobby.reopen_command(Parts.HOST))
	while link.lobby.started:
		await link.lobby.changed
		if not is_instance_valid(link) or not is_instance_valid(runtime) or not runtime.is_inside_tree():
			return
	# The Host's house stays until its Guests have left theirs: a Guest's avatar still sends to a house that is gone.
	var until := Time.get_ticks_msec() + GUESTS_WAIT_MS
	while runtime.parts.is_host() and _guests_in(link) and Time.get_ticks_msec() < until:
		await runtime.get_tree().process_frame
		if not is_instance_valid(link) or not is_instance_valid(runtime) or not runtime.is_inside_tree():
			return
	_enter(runtime, link)


## Whether a Guest is still in the Host's house.
static func _guests_in(link: GameLink) -> bool:
	for peer in link.roster.peers():
		if peer != Roster.HOST and link.session.in_house(peer):
			return true
	return false


## The Lobby, as this machine is in the game.
static func _enter(runtime: LevelRuntime, link: GameLink) -> void:
	var mode := LobbyScreen.Mode.SOLO
	if link.session.is_online():
		mode = LobbyScreen.Mode.HOST if runtime.parts.is_host() else LobbyScreen.Mode.JOIN
	var address := ""
	var args := PackedStringArray()
	for arg in runtime.launch:
		if arg.begins_with("--join="):
			address = arg.trim_prefix("--join=")
		elif arg != "--host" and not arg.begins_with(Stages.PAIRS_ARG):
			args.append(arg)
	# The finished World as the file now says it (the record the Lobby shows), a Guest has none.
	var world: WorldSlot = null
	if mode != LobbyScreen.Mode.JOIN and runtime.world != null:
		world = Worlds.pick_slot(runtime.world.slot, mode == LobbyScreen.Mode.HOST)
	runtime.go_into_lobby.call(func(root: Node) -> void:
		var lobby := root as LobbyScreen
		if lobby != null:
			lobby.mode = mode
			lobby.world = world
			lobby.address = address
			lobby.launch = args)
