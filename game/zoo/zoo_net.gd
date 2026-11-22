## Co-op in the zoo, from the command line: `-- --host` opens the zoo for Guests, `-- --join=<ip>` or
## `-- --join=<ip:port>` joins a zoo that hosts. With neither, the zoo is played alone exactly as
## before (a Host of one, no peer). The label in the corner says which it is. No lobby, no menu: the
## zoo's Session and Avatars do the work; this only starts them.
class_name ZooNet
extends Node

@export var session: Session
@export var avatars: Avatars

@onready var _mode: Label = %Mode


func _ready() -> void:
	# Reach: the Host refuses a use, a pick or a drop from a player who stands too far away.
	session.parts.where = where
	session.welcomed.connect(_on_welcomed)
	session.ended.connect(_on_ended)
	start.call_deferred(OS.get_cmdline_user_args())


## Hosts or joins as `args` say (the command line's user arguments); with neither, plays alone.
func start(args: PackedStringArray) -> Error:
	for arg in args:
		if arg == "--host":
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
			var address := arg.trim_prefix("--join=")
			var err := session.join(address)
			_say("Joining %s ..." % address if err == OK else "Could not join %s (%s)" % [address, error_string(err)])
			return err
	_say("Alone. Co-op: start with -- --host, or -- --join=<ip[:port]>")
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


## What the corner says now.
func mode_text() -> String:
	return _mode.text


func _on_players_changed(_peer: int) -> void:
	_say("Hosting on port %d: %d player(s)" % [session.port, multiplayer.get_peers().size() + 1])


func _on_welcomed() -> void:
	_say("Joined as player %d" % session.me())


func _on_ended(text: String) -> void:
	avatars.clear()
	_say("Alone: %s" % text)


## Shows it in the corner and prints it.
func _say(text: String) -> void:
	_mode.text = text
	Log.info("zoo", text)
