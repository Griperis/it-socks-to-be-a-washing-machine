## Co-op in the zoo, from the command line: `-- --host` opens the zoo for Guests, `-- --join=<where>`
## joins a zoo that hosts (ENet: "ip" or "ip:port"), and `--profile=<tag>` plays as another profile
## (two copies on one PC are two players). With neither --host nor --join the zoo is played alone
## exactly as before (a Host of one, no peer). The label in the corner says which it is; who joins and
## leaves, and why a join ended, show under the crosshair (the HUD's message line). No lobby, no menu:
## the zoo's Session, Roster and Avatars do the work; this only starts them and says what happened.
class_name ZooNet
extends Node

@export var session: Session
@export var avatars: Avatars

const JOINED := "joined"
const LEFT := "left"
## The joiner's line (Q2442).
const JOINED_ZOO := "Joined %s's zoo"

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
	return null


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
## whose zoo it joined.
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
	_tell_plain(JOINED_ZOO % host_name)
	_say("Joined %s's zoo as player %d" % [host_name, session.me()])


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
	Log.info("zoo", text)
