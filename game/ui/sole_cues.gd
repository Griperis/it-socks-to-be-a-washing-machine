## The Sole cues (core/131; the old SoleMatesView, progression/47, Q1115-Q1118, Q1130, Q1361), a view on each
## machine, on its HUD's layer; it asks nothing and decides nothing. For this machine's own player only.
##
## Sole Mates: while this player's active item is a loose Sock and a Teammate's active item is its mate
## (a loose Sock of the same Design), that Sock keeps the Highlight outline in the Teammate's Player
## colour, as wide as a Ping's, only while it is in line of sight (it lingers `los_linger` s once it is
## not). When a match starts (a new Teammate's active Sock matches), `match` plays once at that
## Teammate's Hands and this player's own Sock glows briefly. Without it there is no cue at all.
## Sole Hands: the whole Teammate is outlined, in their colour, while this player's active Sock's mate
## is in any of their slots, not only the active one.
## Mate Radar: both outlines show through walls, and a hint arrow at the screen's edge points to each
## Teammate holding a mate of the active Sock, in their colour (through HintArrows).
## Hidden in single player (the three Upgrades cannot be bought there).
##
## It reads the Hands, which every machine has for every player, so a match starts however the Socks got
## there: a pick, a catch, a Hand-off. The outline goes beside the Outline of the Teammate's drawn Sock
## (their worn HeldView) or of their Avatar, as a Ping's does, so it follows them.
class_name SoleCues
extends Node

## The numbers.
@export var tuning: SoleCuesTuning
@export_group("Upgrades")
@export var mates_stat: UpgradeStat = preload("res://game/economy/stats/sole_mates.tres")
@export var hands_stat: UpgradeStat = preload("res://game/economy/stats/sole_hands.tres")
@export var radar_stat: UpgradeStat = preload("res://game/economy/stats/mate_radar.tres")

## How many match sounds this view has played (a test reads it).
var sounds := 0

var _player: Player
var _cues: Dictionary[String, Dictionary] = {}
## The matches ("<Teammate>:<Design>") of the last refresh, so a new one is told from one going on.
var _known: Dictionary[String, Dictionary] = {}
var _unseen: Dictionary[String, float] = {}
## Each colour's outline style, made once.
var _styles: Dictionary[String, OutlineStyle] = {}


func _ready() -> void:
	if tuning == null:
		tuning = SoleCuesTuning.new()
	_player = get_parent().get_parent() as Player
	_join_arrows.call_deferred()


func _join_arrows() -> void:
	var hud := get_parent() as Hud
	if hud != null and hud.hint_arrows() != null:
		hud.hint_arrows().add_source(arrow_targets)


## The line-of-sight rays need the physics space: the cues are brought up to date in the tick.
func _physics_process(delta: float) -> void:
	refresh(delta)


# --- What is owned -------------------------------------------------------------------------------

func _levels() -> Upgrades:
	if _player == null or _player.hands() == null:
		return null
	var levels := _player.upgrades.levels if _player.upgrades != null else null
	return levels if levels != null and is_instance_valid(levels) else null


func _has(stat: UpgradeStat) -> bool:
	var levels := _levels()
	return levels != null and levels.is_coop() and levels.value(stat, _player.player_id()) >= 1.0


## Whether this player's team owns Sole Mates (and the game is co-op).
func owned() -> bool:
	return _has(mates_stat)


## Whether the team bought Sole Hands.
func hands_owned() -> bool:
	return _has(hands_stat)


## Whether the team bought Mate Radar.
func radar_owned() -> bool:
	return _has(radar_stat)


# --- What matches --------------------------------------------------------------------------------

## Every Sock a Teammate holds that is the mate of this player's active Sock: [{"by": their peer, "sock":
## its id, "active": whether it is their active item}]. Empty without Sole Mates or an active loose Sock.
func matches() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hands := _player.hands() if _player != null else null
	if hands == null or hands.mess == null or not owned():
		return out
	var mine := hands.active_of(_player.player_id())
	if mine < 0 or hands.mess.is_pair(mine):
		return out
	var design := hands.mess.design_of(mine)
	for avatar in _teammates():
		var by := avatar.peer()
		var active := hands.active_of(by)
		for sock in hands.items_of(by):
			if not hands.mess.is_pair(sock) and hands.mess.design_of(sock) == design:
				out.append({"by": by, "sock": sock, "active": sock == active})
	return out


## The Avatars of the other players in this player's level.
func _teammates() -> Array[Avatar]:
	var out: Array[Avatar] = []
	var level := LevelRuntime.level_of(_player)
	for node in get_tree().get_nodes_in_group(Avatar.GROUP):
		var a := node as Avatar
		if a != null and a.peer() != _player.player_id() and not a.is_queued_for_deletion() \
				and (level == null or level.is_ancestor_of(a)):
			out.append(a)
	return out


func _avatar_of(by: int) -> Avatar:
	for a in _teammates():
		if a.peer() == by:
			return a
	return null


## The colour of Teammate `by` (the Roster's).
func _colour_of(by: int) -> Color:
	var runtime := LevelRuntime.of(_player)
	var roster := runtime.roster if runtime != null else null
	if roster != null and not roster.entry_of(by).is_empty():
		return roster.colour_of(by)
	return Color.WHITE


# --- Each tick -----------------------------------------------------------------------------------

## Brings the outlines, the sound and the glow up to date; `delta` counts toward the line-of-sight linger.
func refresh(delta := 0.0) -> void:
	var now: Dictionary[String, Dictionary] = {}
	var found := matches()
	var radar := radar_owned()
	var hands_on := hands_owned()
	var socks: Dictionary[String, Dictionary] = {}
	for m in found:
		var by := int(m["by"])
		if bool(m["active"]):
			now["s%d" % by] = m
			socks["%d:%d" % [by, _player.hands().mess.designs[int(m["sock"])]]] = m
		if hands_on and not now.has("h%d" % by):
			now["h%d" % by] = {"by": by, "hands": true}
	for key: String in socks:
		if not _known.has(key):
			_started(socks[key])
	_known = socks
	for key: String in _cues.keys():
		if not now.has(key):
			_drop(key)
	for key: String in now:
		var m: Dictionary = now[key]
		var by := int(m["by"])
		var node: Node3D = null
		var own: Outline = null
		var lift := 0.0
		if m.has("hands"):
			var avatar := _avatar_of(by)
			node = avatar
			own = Outline.of(avatar) if avatar != null else null
			lift = tuning.hands_lift
		else:
			var looks := _held_of(by).looks_of(int(m["sock"])) if _held_of(by) != null else null
			node = looks
			own = Outline.of(looks) if looks != null else null
		if node == null or own == null:
			_drop(key)
			continue
		if radar or _in_sight(node, lift):
			_unseen[key] = 0.0
		else:
			_unseen[key] = float(_unseen.get(key, tuning.los_linger + 1.0)) + delta
		_show(key, by, own, float(_unseen[key]) <= tuning.los_linger)


## Whether this player can see `node` from their camera: nothing of the house between.
func _in_sight(node: Node3D, lift: float) -> bool:
	var cam := _player.camera()
	if cam == null or not node.is_inside_tree():
		return false
	var to := node.global_position + Vector3.UP * lift
	return PhysicsQueries.ray(self, cam.global_position, to, Mess.LAYER_HOUSE).is_empty()


## Teammate `by`'s worn HeldView, or null.
func _held_of(by: int) -> HeldView:
	var avatar := _avatar_of(by)
	return avatar.get_node_or_null(^"Held") as HeldView if avatar != null else null


## A match just started: the soft sound once at the Teammate's Hands, and this player's own matching Sock glows.
func _started(m: Dictionary) -> void:
	sounds += 1
	var hands := _player.hands()
	var view := _player.hud().held_view if _player.hud() != null else null
	if view != null and hands != null:
		view.glow(hands.active_of(_player.player_id()), tuning.glow_seconds, tuning.glow_strength)
	var held := _held_of(int(m["by"]))
	var at := Vector3.ZERO
	if held != null and held.anchor != null:
		at = held.anchor.global_position
	else:
		var avatar := _avatar_of(int(m["by"]))
		if avatar == null:
			return
		at = avatar.global_position
	Sounds.play_at(&"match", at)


# --- The outlines --------------------------------------------------------------------------------

## The outline of key `key` beside `own`, in Teammate `by`'s colour, shown or hidden.
func _show(key: String, by: int, own: Outline, shown: bool) -> void:
	var colour := _colour_of(by)
	var cue: Dictionary = _cues.get(key, {})
	var outline: Outline = cue.get("outline")
	if outline == null or not is_instance_valid(outline) or cue["beside"] != own or cue["colour"] != colour:
		_drop(key)
		outline = Outline.new()
		outline.name = "SoleOutline"
		outline.add_to_group(Outline.PING)
		outline.meshes = own.meshes
		outline.style = _style_of(colour)
		own.get_parent().add_child(outline)
		_cues[key] = {"outline": outline, "beside": own, "colour": colour, "by": by}
	outline.shown = shown


func _style_of(colour: Color) -> OutlineStyle:
	var id := colour.to_html()
	if not _styles.has(id):
		var style := OutlineStyle.new()
		style.colour = colour
		style.width = tuning.outline_width
		style.shells = Outline.AIM.shells.duplicate()
		style.priority = tuning.outline_priority
		_styles[id] = style
	return _styles[id]


func _drop(key: String) -> void:
	var cue: Dictionary = _cues.get(key, {})
	var outline: Outline = cue.get("outline")
	if outline != null and is_instance_valid(outline):
		if outline.get_parent() != null:
			outline.get_parent().remove_child(outline)
		outline.queue_free()
	_cues.erase(key)
	_unseen.erase(key)


## How many outlines show now (a Sock's or a whole Teammate's).
func sole_outline_count() -> int:
	var n := 0
	for key: String in _cues:
		if _shown(key) != null:
			n += 1
	return n


## The Outline round Teammate `by`'s matching Sock, while it shows; else null.
func sock_outline(by: int) -> Outline:
	return _shown("s%d" % by)


## The Outline round the whole of Teammate `by` (Sole Hands), while it shows; else null.
func hands_outline(by: int) -> Outline:
	return _shown("h%d" % by)


func _shown(key: String) -> Outline:
	var cue: Dictionary = _cues.get(key, {})
	var outline: Outline = cue.get("outline")
	return outline if outline != null and is_instance_valid(outline) and outline.shown else null


# --- The arrows ----------------------------------------------------------------------------------

## What the hint arrows point at: with Mate Radar, each Teammate holding a mate of this player's active
## Sock, in their colour, at their body.
func arrow_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not radar_owned():
		return out
	var seen: Dictionary[int, bool] = {}
	for m in matches():
		var by := int(m["by"])
		var avatar := _avatar_of(by)
		if seen.has(by) or avatar == null or not avatar.is_inside_tree():
			continue
		seen[by] = true
		var t := avatar.tuning if avatar.tuning != null else AvatarTuning.new()
		out.append({"at": avatar.global_position + Vector3.UP * t.stand_height * tuning.body_share,
				"colour": _colour_of(by), "priority": tuning.arrow_priority})
	return out
