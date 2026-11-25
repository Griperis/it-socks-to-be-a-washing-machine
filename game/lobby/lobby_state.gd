## What the Lobby shows and its rules (docs/architecture/lobby.md "Core/63", Q2582, Q2583): one Part of
## the game link's Parts, so it lives for the whole game, every Guest gets it in the link's snapshot at
## connect and only the Host's answers write it.
##
## - Ready: who is Ready, by player id. A Guest may ask `ready` for itself only (the id comes from the
##   sender, never from the args: a bool and nothing else, rate-limited); a leaver is forgotten
##   (left()); a joiner is not Ready; every change of the chosen World clears it. Never saved.
## - Start: the Host's only. Refused until every player in the Roster now is Ready (nobody present:
##   refused) and a house is named; once started it stays started.
## - The World: the house scene to load, the card's title and line, the chosen slot: the Host's only
##   (`world`), as it says them.
## - Pairs per Drawer: a New Game's Drawer size (the debug slider, Q668, core/91): the Host's only (`pairs`),
##   1 to 25; each change clears Ready, as the old; it rides the launch into the run's `start`.
## - Reopen: the Host's only, after a run ended (Continue on the Final screen, core/97): `started` is false and
##   nobody is Ready, so the Lobby is as it was before Start.
class_name LobbyState
extends Part

## The verbs.
const READY := &"ready"
const START := &"start"
const WORLD := &"world"
const WORLDS := &"worlds"
const PAIRS := &"pairs"
## The Host opens the Lobby again after a run ended (core/97): nobody is started or Ready.
const REOPEN := &"reopen"
## The most `ready` one Guest may ask in a second (a flood is dropped by the Session).
const READY_RATE := 5

## Shown on every machine whenever the state changed (an answer or a snapshot).
signal changed

## Who plays (the link's Roster; GameLink sets it). Without one nobody is present: Start is refused.
@export var roster: Roster

@export_group("State")
## The player ids that are Ready, in the order they readied (`ready` is Node's signal).
@export var readied := PackedStringArray()
## The Host started the game: every machine loads `level`.
@export var started := false
## The house scene every machine loads at Start.
@export var level := ""
## The World's card: its title and the line under it, as the Host says them.
@export var title := ""
@export var line := ""
## The chosen World's slot (the Host's own save; a Guest only shows it).
@export var world := ""
## The Host's Worlds as the drawer lists them: Worlds.rows() (slot, name, details, damaged, colours);
## the Host's only (`worlds`), so a Guest's drawer shows every World read-only (core/65, Q2587).
@export var worlds: Array = []
## A New Game's Pairs per Drawer (the debug slider; 25 otherwise).
@export_range(1, 25, 1) var pairs_per_drawer := StagePlan.PAIRS_AT
@export_group("")


func accepts() -> Dictionary[StringName, Dictionary]:
	return {READY: {"args": {"on": TYPE_BOOL}, "rate": READY_RATE}}


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		READY:
			return _decide_ready(cmd)
		START:
			if started:
				return refuse("already")
			if level == "" or not all_ready():
				return refuse("wrong")
			return grant({"started": true})
		WORLD:
			if started:
				return refuse("already")
			var a := cmd.args
			for k: String in ["level", "title", "line", "world"]:
				if not (a.get(k) is String):
					return refuse("wrong")
			return grant({"level": a["level"], "title": a["title"], "line": a["line"], "world": a["world"],
					"readied": PackedStringArray()})
		PAIRS:
			if started:
				return refuse("already")
			var n: Variant = cmd.args.get("pairs")
			if not (n is int) or int(n) < 1 or int(n) > StagePlan.PAIRS_AT:
				return refuse("wrong")
			if int(n) == pairs_per_drawer:
				return refuse("already")
			return grant({"pairs_per_drawer": int(n), "readied": PackedStringArray()})
		REOPEN:
			if cmd.by != Parts.HOST or not started:
				return refuse("already")
			return grant({"started": false, "readied": PackedStringArray()})
		WORLDS:
			var rows: Variant = cmd.args.get("rows")
			if not (rows is Array) or not (rows as Array).all(func(r: Variant) -> bool: return r is Dictionary):
				return refuse("wrong")
			return grant({"worlds": rows})
	return refuse("wrong")


func _decide_ready(cmd: Command) -> Dictionary:
	if started:
		return refuse("already")
	var on: Variant = cmd.args.get("on")
	var pid := roster.id_of(cmd.by) if roster != null else ""
	if not (on is bool) or pid == "":
		return refuse("wrong")
	if bool(on) == readied.has(pid):
		return refuse("already")
	var now := readied.duplicate()
	if bool(on):
		now.append(pid)
	else:
		now.remove_at(now.find(pid))
	return grant({"readied": now})


## A leaver is forgotten as Ready (the old keep()): only players live in the Roster stay, never `by`.
func left(by: int) -> Dictionary:
	var gone := roster.id_of(by) if roster != null else ""
	var now := PackedStringArray()
	for pid in readied:
		if pid != gone and roster != null and roster.is_live(pid):
			now.append(pid)
	return grant({"readied": now}) if now != readied else {}


## Ready is never saved.
func save_state() -> Dictionary:
	return {}


func _show(_now: bool) -> void:
	changed.emit()


# --- Reading -------------------------------------------------------------------------------------

## The player ids present now (the Roster's live players).
func present() -> PackedStringArray:
	var out := PackedStringArray()
	if roster == null:
		return out
	for peer in roster.peers():
		out.append(roster.id_of(peer))
	return out


## Whether every present player is Ready (nobody present: no).
func all_ready() -> bool:
	var here := present()
	if here.is_empty():
		return false
	for pid in here:
		if not readied.has(pid):
			return false
	return true


## Whether the player on `peer` is Ready.
func is_ready(peer: int) -> bool:
	return roster != null and readied.has(roster.id_of(peer))


## The Command for player `by` to ask Ready (`on`) or not.
func ready_command(by: int, on: bool) -> Command:
	return Command.new(READY, by, id, {"on": on})


## The Host's Command to start.
func start_command(by: int) -> Command:
	return Command.new(START, by, id)


## The Host's Command to choose a World: the house scene, the card's title and line, the slot.
func world_command(by: int, p_level: String, p_title: String, p_line: String, slot: String) -> Command:
	return Command.new(WORLD, by, id, {"level": p_level, "title": p_title, "line": p_line, "world": slot})


## The Host's Command to set a New Game's Pairs per Drawer.
func pairs_command(by: int, pairs: int) -> Command:
	return Command.new(PAIRS, by, id, {"pairs": pairs})


## The Host's Command to open the Lobby again once the run is over (Continue on the Final screen, core/97).
func reopen_command(by: int) -> Command:
	return Command.new(REOPEN, by, id)


## The Host's Command to say its Worlds (the rows the drawers list).
func worlds_command(by: int, rows: Array) -> Command:
	return Command.new(WORLDS, by, id, {"rows": rows})
