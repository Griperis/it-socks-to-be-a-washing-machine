## The co-op pings (core/43, list 03 answered by Q2590) as one Part: one standing ping per player,
## keyed by peer, written only by the Host's answers. A ping marks what the pinger's crosshair pointed at
## for their Teammates: a tap highlights it, the wheel puts an emoji over it (PingMarks draws both on
## every machine; the Player's Pinger asks).
##
## `ping` (any player, alone too, Q2590): the Host names the target (line 16, C): a Mess Sock or Pair
## that still lies or flies (line 20: one picked up meanwhile is a spot), else a Teammate's body that is
## not the pinger (line 18), else a thing with an Outline by its path from the level (line 19, Q2590),
## else the spot on the surface; an emoji not one of the five is a highlight (line 21). The answer
## replaces the pinger's last ping (line 40), carries the spot for the blip everyone hears (line 41) and
## drops the pings whose time is up. A Guest predicts nothing: it sees its own ping on the answer (Q2590).
##
## Time (line 42): each ping counts down on every machine's own clock from `seconds` (left_of()), as a
## knockdown does; the Host's next answer leaves the ended ones out. Pings are not saved and not in the
## join snapshot (whole_state() is empty). A leaver's ping goes with them (left()).
class_name Pings
extends Part

## The verb.
const PING := &"ping"
## The five emojis, in the wheel's order from the top, clockwise (line 9): assets/ui/emoji_<name>.svg.
const EMOJIS: Array[String] = ["here", "help", "yes", "no", "nice"]
## A highlight's emoji.
const HIGHLIGHT := -1
## Why a ping is refused.
const FAR := "far"
const WRONG := "wrong"
## The group the level's Pings is in.
const GROUP := &"pings"

@export var tuning: PingTuning
## The level's Mess: a pinged Sock or Pair is one of its records.
@export var mess: Mess

@export_group("State")
## Each player's standing ping, by peer: {"sock": a Mess id or -1, "mate": a Teammate's peer or -1,
## "path": a thing's path from the level or "", "at": the spot (Vector3), "normal": the surface's
## normal there, "emoji": an index into EMOJIS or HIGHLIGHT, "seconds": how long it stands, "n": its
## serial}.
@export var pings := {}
## The last ping's serial.
@export var serial := 0
@export_group("")

## Every machine: each ping's time left on this machine's clock, and the serial last seen, by peer.
var _left: Dictionary[int, float] = {}
var _seen: Dictionary[int, int] = {}


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if tuning == null:
		tuning = PingTuning.new()


func _process(delta: float) -> void:
	for peer: int in _left.keys():
		_left[peer] = maxf(0.0, _left[peer] - delta)


# --- Questions anyone may ask --------------------------------------------------------------------

## How long player `peer`'s ping still stands on this machine's clock; 0 for none.
func left_of(peer: int) -> float:
	return float(_left.get(peer, 0.0)) if pings.has(peer) else 0.0


## Player `peer`'s standing ping, or {}.
func ping_of(peer: int) -> Dictionary:
	return pings.get(peer, {}) if left_of(peer) > 0.0 else {}


## The peers whose pings stand now.
func standing() -> Array[int]:
	var out: Array[int] = []
	for k: Variant in pings:
		if left_of(int(k)) > 0.0:
			out.append(int(k))
	return out


## The emoji's name of ping `entry` ("" for a highlight).
static func emoji_of(entry: Dictionary) -> String:
	var e := int(entry.get("emoji", HIGHLIGHT))
	return EMOJIS[e] if e >= 0 and e < EMOJIS.size() else ""


## Pings are not kept in a save (line 42).
func save_state() -> Dictionary:
	return {}


## Nor sent to a joiner (line 42): a late Guest sees none that stand.
func whole_state() -> Dictionary:
	return {}


# --- Asking --------------------------------------------------------------------------------------

## Player `by` pings: `aim` is PingAim.find()'s answer, `emoji` an index into EMOJIS or HIGHLIGHT.
func ping(by: int, aim: Dictionary, emoji: int) -> void:
	parts.ask(Command.new(PING, by, id, {"sock": int(aim.get("sock", -1)), "mate": int(aim.get("mate", -1)),
			"path": String(aim.get("path", "")), "at": aim.get("at", Vector3.ZERO) as Vector3,
			"normal": aim.get("normal", Vector3.UP) as Vector3, "emoji": emoji}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		PING: {"args": {
			"sock": {"type": TYPE_INT, "min": -1, "max": Command.SEQ_MAX},
			"mate": {"type": TYPE_INT, "min": -1, "max": 2147483647},
			"path": {"type": TYPE_STRING, "max": Command.TEXT_MAX},
			"at": {"type": TYPE_VECTOR3, "min": -100000.0, "max": 100000.0},
			"normal": {"type": TYPE_VECTOR3, "min": -1.01, "max": 1.01},
			"emoji": {"type": TYPE_INT, "min": -1, "max": 255},
		}},
	}


# --- The Host's answer ---------------------------------------------------------------------------

func decide(cmd: Command) -> Dictionary:
	if cmd.kind != PING:
		return refuse(WRONG)
	var a := cmd.args
	for key: String in ["sock", "mate", "emoji"]:
		if not (a.get(key) is int):
			return refuse(WRONG)
	if not (a.get("at") is Vector3) or not (a.get("normal") is Vector3) or not (a.get("path") is String or a.get("path") is StringName):
		return refuse(WRONG)
	var at := a["at"] as Vector3
	var normal := a["normal"] as Vector3
	if not at.is_finite() or not normal.is_finite():
		return refuse(WRONG)
	if not parts.near_point(cmd.by, at, tuning.reach + tuning.reach_slack):
		return refuse(FAR)
	var emoji := int(a["emoji"])
	var entry := {"sock": -1, "mate": -1, "path": "", "at": at,
			"normal": normal.normalized() if normal.length() > 0.001 else Vector3.UP,
			"emoji": emoji if emoji >= 0 and emoji < EMOJIS.size() else HIGHLIGHT,
			"seconds": tuning.seconds, "n": serial + 1}
	var sock := int(a["sock"])
	var mate := int(a["mate"])
	var path := String(a["path"])
	if sock >= 0 and lies_or_flies(sock):
		entry["sock"] = sock
	elif mate >= 0 and mate != cmd.by and avatar_of(mate) != null:
		entry["mate"] = mate
	elif path != "" and thing_at(path) != null:
		entry["path"] = path
	var now := _live()
	now[cmd.by] = entry
	var ev := grant({"pings": now, "serial": serial + 1})
	ev.merge({"pinger": cmd.by, "at": at, "emoji": entry["emoji"]})
	return ev


## Whether Mess Sock `sock` still lies or flies (not held, not shelved): what a ping on it follows.
func lies_or_flies(sock: int) -> bool:
	if mess == null or sock < 0 or sock >= mess.count():
		return false
	var s := mess.state_of(sock)
	return s == Mess.State.LYING or s == Mess.State.FLYING


## The thing with an Outline at `path` from the level (a ping's target), or null: none there, no
## Outline, or a path that leaves the level.
func thing_at(path: String) -> Node:
	var level := LevelRuntime.level_of(self)
	if level == null or path.begins_with("/") or path.contains(".."):
		return null
	var node := level.get_node_or_null(NodePath(path))
	return node if node != null and Outline.of(node) != null else null


## Player `peer`'s avatar in this level, or null.
func avatar_of(peer: int) -> Avatar:
	var level := LevelRuntime.level_of(self)
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() == peer and not a.is_queued_for_deletion() and (level == null or level.is_ancestor_of(a)):
			return a
	return null


## The pings still standing on the Host's clock (an ended one is left out of the next patch).
func _live() -> Dictionary:
	var out := {}
	for k: Variant in pings:
		if left_of(int(k)) > 0.0:
			out[k] = pings[k]
	return out


## The Host: player `by` left; their ping goes with them.
func left(by: int) -> Dictionary:
	if not pings.has(by):
		return {}
	var now := _live()
	now.erase(by)
	return grant({"pings": now})


# --- State shown, and the clocks -----------------------------------------------------------------

## A new ping (the answer's own serial) starts its clock here; one gone stops. A standing ping first
## seen in a later answer (a joiner who missed it) never shows (line 42).
func _show(_now: bool) -> void:
	for k: Variant in pings:
		var peer := int(k)
		var n := int((pings[k] as Dictionary).get("n", 0))
		if n != int(_seen.get(peer, -1)):
			_left[peer] = float((pings[k] as Dictionary).get("seconds", 0.0)) if n == serial else 0.0
			_seen[peer] = n
	for peer: int in _left.keys():
		if not pings.has(peer):
			_left.erase(peer)
			_seen.erase(peer)
