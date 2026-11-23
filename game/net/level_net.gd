## Co-op in a level (the house, the zoo), from the command line: `-- --host` opens the level for
## Guests, `-- --join=<where>` joins a level that hosts (ENet: "ip" or "ip:port"), and
## `--profile=<tag>` plays as another profile (two copies on one PC are two players). With neither
## --host nor --join the level is played alone (a Host of one, no peer). The label in the corner says
## which it is; who joins and leaves, and why a join ended, show under the crosshair (the HUD's
## message line). No lobby, no menu: the level's Session, Roster and Avatars do the work; this only
## starts them and says what happened. It is the Net of `level_runtime.tscn` in every level; the
## level's word comes from the runtime instance (`place`), and a body that places itself (the zoo's
## stand-in Teammate) joins the PLACES_ITSELF group, so the house needs nothing of game/zoo/.
class_name LevelNet
extends Node

@export var session: Session
@export var avatars: Avatars

const JOINED := "joined"
const LEFT := "left"
## The joiner's line (Q2442): the Host's name, then the level's word (place_name()).
const JOINED_LEVEL := "Joined %s's %s"
## The group of Avatars that pick where they stand themselves (the zoo's stand-in Teammates, Q2468):
## the reach rule asks them where they are.
const PLACES_ITSELF := &"stand_in_teammates"

## The level's word (place_name()); the runtime sets it from its instance.
## placeholder: the wording waits for the designer (house/04).
var place := "house"

@onready var _mode: Label = %Mode


func _ready() -> void:
	# Reach: the Host refuses a use, a pick or a drop from a player who stands too far away.
	session.parts.where = where
	if session.roster != null:
		session.roster.pose_of = pose_of
	session.welcomed.connect(_on_welcomed)
	session.ended.connect(_on_ended)
	session.parts.applied.connect(_on_applied)
	start.call_deferred(OS.get_cmdline_user_args())


## Hosts or joins as `args` say (the command line's user arguments); with neither, plays alone.
func start(args: PackedStringArray) -> Error:
	for arg in args:
		if arg.begins_with("--profile="):
			session.profile = PlayerProfile.load_or_make(arg.trim_prefix("--profile="))
	for arg in args:
		if arg == "--host":
			if session.profile == null:
				session.profile = PlayerProfile.load_or_make("")
			var err := session.host()
			if err != OK:
				_say("Could not host on port %d (%s): playing alone" % [session.port, error_string(err)])
				return err
			avatars.host()
			multiplayer.peer_connected.connect(_on_players_changed)
			multiplayer.peer_disconnected.connect(_on_players_changed)
			_on_players_changed(0)
			return OK
		if arg.begins_with("--join="):
			if session.profile == null:
				session.profile = PlayerProfile.load_or_make("")
			var where_to := arg.trim_prefix("--join=")
			var err := session.join(where_to)
			_say("Joining %s ..." % where_to if err == OK else "Could not join %s (%s)" % [where_to, error_string(err)])
			return err
	_say("Alone. Co-op: start with -- --host, or -- --join=<ip[:port]>; -- --profile=<tag> plays as another player")
	return OK


## Where player `by` stands, as this machine knows it: its avatar's newest pose in a session, the
## local body for this machine's own player, null for a player it cannot place.
func where(by: int) -> Variant:
	var avatar := avatars.of(by)
	if avatar != null and avatar.pose_position.is_finite():
		return avatar.pose_position
	if by == session.me() and avatars.local_body != null:
		return avatars.local_body.global_position
	return _where_else(by)


## Where a player of this level that places itself stands (the zoo's stand-in Teammate), or null.
func _where_else(by: int) -> Variant:
	var level := LevelRuntime.level_of(self)
	for node in get_tree().get_nodes_in_group(PLACES_ITSELF):
		var stand_in := node as Avatar
		if stand_in != null and stand_in.peer() == by and level != null and level.is_ancestor_of(stand_in):
			return stand_in.global_position
	return null


## The level's word in the corner and the joiner's line: "house" (the zoo's says "zoo").
func place_name() -> String:
	return place


## Where player `by` stands and which way they face (about the up axis), or null: what the Roster
## keeps for a joiner's place and a leaver's.
func pose_of(by: int) -> Variant:
	var avatar := avatars.of(by)
	if by == session.me() and avatars.local_body != null:
		return Transform3D(Basis(Vector3.UP, avatars.local_body.global_rotation.y), avatars.local_body.global_position)
	if avatar != null and avatar.pose_position.is_finite() and is_finite(avatar.pose_yaw):
		return Transform3D(Basis(Vector3.UP, avatar.pose_yaw), avatar.pose_position)
	return null


## What the corner says now.
func mode_text() -> String:
	return _mode.text


func _on_players_changed(_peer: int) -> void:
	_say("Hosting on port %d: %d player(s)" % [session.port, multiplayer.get_peers().size() + 1])


## A Guest is in: it stands where the Roster put it (beside the Host, or where it left) and is told
## whose level it joined.
func _on_welcomed() -> void:
	var roster := session.roster
	var body := avatars.local_body
	if roster != null and body != null:
		var mine := roster.entry_of(session.me())
		if not mine.is_empty():
			body.global_position = mine["at"]
			body.rotation.y = float(mine["yaw"])
			if body is CharacterBody3D:
				(body as CharacterBody3D).velocity = Vector3.ZERO
			body.reset_physics_interpolation()
	var host_name := roster.name_of(Roster.HOST) if roster != null else PlayerProfile.NAME
	_tell_plain(JOINED_LEVEL % [host_name, place_name()])
	_say("Joined %s's %s as player %d" % [host_name, place_name(), session.me()])


func _on_ended(text: String) -> void:
	avatars.clear()
	_tell_plain(text)
	_say("Alone: %s" % text)


## A teammate joined or left: "Player joined" / "Player left", their name in their colour. Not for
## this machine's own player.
func _on_applied(ev: Dictionary) -> void:
	var roster := session.roster
	if roster == null or not ev.get("ok", false) or StringName(ev.get("to", &"")) != roster.id:
		return
	var kind := StringName(ev.get("kind", &""))
	if kind != Roster.JOINED and kind != Roster.LEFT:
		return
	if int(ev.get("by", 0)) == session.me() and kind == Roster.JOINED:
		return
	var entry: Dictionary = roster.players.get(String(ev.get("player", "")), {})
	if entry.is_empty():
		return
	var player := avatars.local_body as Player
	if player != null:
		player.announce(String(entry["name"]), roster.tuning.colour(int(entry["colour"])),
				JOINED if kind == Roster.JOINED else LEFT, _toast_time())


func _tell_plain(text: String) -> void:
	var player := avatars.local_body as Player
	if player != null:
		player.notice(text, _toast_time())


func _toast_time() -> float:
	return session.tuning.toast_time if session.tuning != null else 2.0


## Shows it in the corner and prints it.
func _say(text: String) -> void:
	_mode.text = text
	Log.info(place_name(), text)
