## Decides this machine's player's Achievements (core/145, docs/architecture/wardrobe.md "Achievements", ADR9): a
## Node of the game link on every machine, for the local player only, with no Command, RPC or World field (each
## machine decides for its own player; earned once, never taken away). `check()` earns every Achievement whose
## condition the profile has reached and that it has not: for each, the profile records it with the time
## (`profile.earn`), its reward goes through `profile.unlock_piece` and the Roster's `own`, every backend's
## `unlock` runs and the toast on this machine's HUD queues it; one HUD line "Wardrobe: <names> unlocked" names the
## pieces given (the old profile_installer.gd:104-105). It runs at each Lifetime tally's count (TallyRecorder) and
## at the game link's start (a profile whose tallies already reached one, as the old).
##
## The list is every `.tres` in `folder` (FOLDER: none in batch B, Q2687), each one's id its file's name.
## Debug builds: F7 grants every one, F8 resets the earned ones (a reset never takes a piece away, Q1696);
## Achievements count in every build.
class_name Achievements
extends Node

## One or more Achievements were earned here just now, in the list's order.
signal earned(list: Array[Achievement])

const FOLDER := "res://game/profile/achievements/"
## Its node's name in the game link.
const NAME := &"Achievements"
## The debug actions (debug builds only).
const GRANT_ALL_ACTION := &"debug_achievement_grant_all"
const RESET_ACTION := &"debug_achievement_reset"
## The HUD line when Achievements gave pieces (the old message).
const UNLOCKED_SAYS := "Wardrobe: %s unlocked"
## The toasts that show this machine's Achievements (AchievementToast).
const TOAST_GROUP := &"achievement_toasts"

## Where the list is read from; a test points it at its fixtures (tests/hooks.gd puts it back).
static var folder := FOLDER

static var _read_from := ""
static var _all: Array[Achievement] = []

@export var tuning: AchievementTuning = preload("res://game/profile/achievement_tuning.tres")

## Decided for this profile; null reads `Worlds.profile()` (the one the Lifetime tallies count into).
var profile: PlayerProfile = null
## Stores beside the profile's own (always on): Steam's mirror later, a fake in tests.
var backends: Array[AchievementBackend] = []

## Earned and not shown yet: no toast of this machine was there (earned at the link's start, at the title).
var _unshown: Array[Achievement] = []
## The pieces the reward line has not named yet, for the same reason.
var _unsaid := PackedStringArray()


## Every Achievement of `folder`, by id, each one's id its file's name. Read once per folder.
static func all() -> Array[Achievement]:
	if _read_from == folder:
		return _all
	_read_from = folder
	_all = []
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	for f: String in files:
		if not f.ends_with(".tres"):
			continue
		var a := load(folder.path_join(f)) as Achievement
		if a == null:
			continue
		a.id = StringName(f.get_basename())
		_all.append(a)
	return _all


## The Achievement with id `id` in the list, or null.
static func of_id(id: StringName) -> Achievement:
	for a in all():
		if a.id == id:
			return a
	return null


## The Achievements of the game link `node` plays through, or null.
static func of(node: Node) -> Achievements:
	var link := GameLink.of(node)
	return link.get_node_or_null(NodePath(NAME)) as Achievements if link != null else null


## Whether profile `p` has reached the condition of `a` (batch B: a Lifetime tally reaching `at`).
static func reached(a: Achievement, p: PlayerProfile) -> bool:
	return a.tally != &"" and p.tally(String(a.tally)) >= a.at


## The id of the piece `a` gives (&"" for none): its file's name, as Wardrobe names its pieces.
static func reward_id(a: Achievement) -> StringName:
	if a.reward == null:
		return &""
	return StringName(a.reward.resource_path.get_file().get_basename()) if a.reward.resource_path != "" else a.reward.id


func _ready() -> void:
	check.call_deferred()


## Earns, for this machine's player, every Achievement reached and not yet earned (see the top). `for_profile`
## is the profile the caller counted into (TallyRecorder's), else `profile`. Returns those earned now.
func check(for_profile: PlayerProfile = null) -> Array[Achievement]:
	var p := _profile(for_profile)
	var got: Array[Achievement] = []
	for a in all():
		if reached(a, p) and p.earn(String(a.id)):
			got.append(a)
	_earned_now(got, p)
	return got


## Debug: earns every Achievement not yet earned, as if each was reached.
func grant_all(for_profile: PlayerProfile = null) -> Array[Achievement]:
	var p := _profile(for_profile)
	var got: Array[Achievement] = []
	for a in all():
		if p.earn(String(a.id)):
			got.append(a)
	_earned_now(got, p)
	return got


## Debug: clears the earned Achievements; the pieces they gave stay (Q1696).
func reset(for_profile: PlayerProfile = null) -> void:
	var p := _profile(for_profile)
	if p.achievements.is_empty():
		return
	p.achievements.clear()
	p.save_soon()


## The stores, the profile's own first.
func backends_of(p: PlayerProfile) -> Array[AchievementBackend]:
	var out: Array[AchievementBackend] = [LocalAchievementBackend.new(p)]
	out.append_array(backends)
	return out


## Hands what was earned to this machine's toast and its player's HUD line; what finds neither waits for the
## next call (a toast calls it as it enters: the level's HUD after the title).
func deliver() -> void:
	if not is_inside_tree():
		return
	if not _unshown.is_empty():
		for node in get_tree().get_nodes_in_group(TOAST_GROUP):
			if node.multiplayer == multiplayer and node.has_method(&"queue"):
				for a in _unshown:
					node.call(&"queue", a)
				_unshown.clear()
				break
	if not _unsaid.is_empty():
		for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
			var player := node as Player
			if player != null and player.multiplayer == multiplayer:
				player.notice(UNLOCKED_SAYS % ", ".join(_unsaid), tuning.message_seconds)
				_unsaid.clear()
				break


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or event.is_echo():
		return
	if event.is_action_pressed(GRANT_ALL_ACTION):
		grant_all()
	elif event.is_action_pressed(RESET_ACTION):
		reset()


## The profile decided for now: `profile`, else `Worlds.profile()`.
func current_profile() -> PlayerProfile:
	return _profile(null)


func _profile(for_profile: PlayerProfile) -> PlayerProfile:
	if for_profile != null:
		return for_profile
	return profile if profile != null else Worlds.profile_of(self)


## What follows each Achievement earned now: its reward, the stores, the toast; one HUD line for the pieces.
func _earned_now(got: Array[Achievement], p: PlayerProfile) -> void:
	if got.is_empty():
		return
	var names := PackedStringArray()
	for a in got:
		var piece := reward_id(a)
		# A piece already owned (a basic one, or one kept through a reset) is not given again nor named.
		if piece != &"" and not Wardrobe.owned(p.pieces).has(String(piece)) and p.unlock_piece(piece):
			_ask_own(piece)
			names.append(Wardrobe.piece_name(piece))
		for b in backends_of(p):
			b.unlock(a.id)
	for b in backends_of(p):
		b.flush()
	_unshown.append_array(got)
	_unsaid.append_array(names)
	deliver()
	earned.emit(got)


## The Roster's `own` for this machine's player, asked of the Host (the piece then reaches their entry, so they
## may wear it). Nothing when nobody of this machine is in a Roster yet.
func _ask_own(piece: StringName) -> void:
	var link := get_parent() as GameLink
	if link == null or not is_inside_tree():
		return
	var session := link.session
	var roster := link.roster
	if session == null or roster == null or roster.id == &"" or roster.parts == null:
		return
	var me := session.me()
	if roster.id_of(me) == "" or roster.owned_of(roster.id_of(me)).has(String(piece)):
		return
	session.parts.ask(Command.new(Roster.OWN, me, roster.id, {"piece": String(piece)}))
