## The Laundry day (docs/architecture/run-ends.md "The Laundry bins" and "The Laundry day", core/93): after the last
## Fix the bins load the washing machine. One per house, a Part, Host authoritative, saved and in the join snapshot.
##
## **The draw** (a New Game; the Host asks `draw` once the level is bound): the `always` bins and, from the World's
## seed (`WorldRecord.seed`, so every machine and every reload draws the same), enough others to make
## `LaundryTuning.bins_per_world`, clamped to 1..spots; each bin's `used` and `drawn` here are written in one answer.
## **The First wash** (core/94, run-ends.md "The First wash"): a New Game is PENDING (`wants_first_wash()`, so
## the run holds Stage 1's Socks; `goal_pending()`, so the Stage bar reads its goal). A carried full bin used on the
## washer while PENDING starts it, refused only while the machine is busy: one answer sets PLAYING, lets the held
## Socks into the Mess (`Stages.lay_first_answer`) and starts `first_wash.tres` on the Cutscene frame; the bin
## stays full in the Hands. The Host ends it (DONE, `first_wash_done`) once the frame plays nothing; with the
## cutscene off (`cutscene`, a test) the start is DONE at once. Saved: it never plays again in the World.
## **The load** (`load`, a Command from the washing machine's use with a carried bin, `Washer.use`): `decide()`
## refuses in order: not carrying a bin, the last Fix not done ("Fix the washing
## machine first"), the bin empty ("That bin is empty"), the ending's wait running or the washer busy ("The washing
## machine is busy"). Granted: the bin is `full = false`, `loaded_bins` goes up, the last of the drawn bins starts the
## ending's wait (`ending_left`, the tip's length). Every machine's answer: the bin tips, the pile behind the
## porthole grows, `socks_pour` plays at the porthole; no Socks are seen going in (Q2627).
## **The wait**: the Host counts `ending_left` down (the live value is what a save and a snapshot carry) and at 0
## asks `final_wash` (Host only).
## **The Final wash** (core/96, run-ends.md "The Final wash and the end of the run"): that answer begins it
## (`final_started`; `ending_left` back to -1), shuts the door on every machine and starts `final_wash.tres` on the
## Cutscene frame (the happy wash, the push-in, cutscene_6 whole, hold black, no respawn). The Host ends the run
## (`ended`, `play_seconds`: the clock stops, the World's record is `finished`) once the frame plays nothing: its
## timeline, its skip, or a load or join after it began. Every machine then lets the cutscene's black go and opens the
## Final screen over the frozen game (`FinalSummary.of`) unless `opens_final_screen` is off. With the cutscene off (a
## test) it ends at once.
##
## It is the Stage bar's `laundry_bins` provider (`bar_numbers`, `bar_changed`; core/82) and its goal
## (`stage_bar_goal`). Looks only (the tip, the pile, the sound) never writes state. It reads its run (`stages`) for
## the last Fix and the held Socks.
class_name LaundryDay
extends Part

## The First wash's progress (core/94 moves it; run-ends.md "The First wash").
enum FirstWash { PENDING, PLAYING, DONE }

## Every LaundryDay is in this group; a thing finds its level's by `of()`.
const GROUP := &"laundry_day"
## The Stage bar's provider name (the plan's `after_phase`).
const BAR_SOURCE := &"laundry_bins"
const LOAD := &"load"
const DRAW := &"draw"
const FINAL_WASH := &"final_wash"
## The Host's end of the run (the Final wash's cutscene over, or none).
const FINAL_WASH_END := &"final_wash_end"
## Any player's Continue on the Final screen (core/97): everyone goes back to the Lobby.
const CONTINUE := &"continue"
## The Host's end of the First wash (its cutscene over, or none).
const FIRST_WASH_END := &"first_wash_end"
const NOT_CARRIED := "not_carried"
const UNFIXED := "unfixed"
const EMPTY := "empty"
const BUSY := "busy"
## What a refusal reads to the player who asked (the old words; Player reads it).
const SAYS := {
	UNFIXED: "Fix the washing machine first",
	EMPTY: "That bin is empty",
	BUSY: "The washing machine is busy",
}
const POUR_SOUND := &"socks_pour"
const PORTHOLE := ^"Porthole"
## The First wash's cutscene (beats as data; its numbers are FirstWashTuning's).
const FIRST_WASH_SCRIPT := "res://game/laundry/first_wash.tres"
## The Final wash's cutscene (the washer's numbers are WasherTuning's `happy_*`).
const FINAL_WASH_SCRIPT := "res://game/laundry/final_wash.tres"
## Links the wiring check lets stay empty: a level may have no run.
const WIRING_OPTIONAL := ["stages"]

## The node whose descendants are this level's bin spots (`LaundryBins` in the house).
@export var spots: Node
## The run whose last Fix and held Socks it reads (the house's `Run/Stages`): any Part with the Stages reads
## `is_fixed()` and `lay_first_answer()`. May be empty: then the machine is never fixed and nothing is held.
@export var stages: Part
@export var tuning: LaundryTuning
## How far from the washing machine a player may stand to load it, in metres.
@export var reach := 4.0
## The First wash and the Final wash play their cutscenes; off (a test) a start and its end are one answer.
@export var cutscene := true
## The run's end opens the Final screen on every machine (and its Continue takes everyone to the Lobby); off, the
## end shows only in the state.
@export var opens_final_screen := true

@export_group("State")
## The First wash (core/94): PENDING at a New Game, DONE once it has played (saved: never again).
@export var first_wash := FirstWash.PENDING
## The bins have been drawn for this World.
@export var drawn := false
## How many bins are in the machine.
@export var loaded_bins := 0
## Seconds of the ending's wait left when written, -1 for none; the Host's live value is what is saved.
@export var ending_left := -1.0
## The wait ran out and the Final wash began (core/96): its cutscene plays, then the run ends.
@export var final_started := false
## The run is over (the Final wash's cutscene ended): the Final screen is up on every machine, the play time stopped.
@export var ended := false
## The play time the run ended on, in seconds (the Final screen's total on a Guest too).
@export var play_seconds := 0
@export_group("")

## One signal for the Stage bar: the tally moved (or the First wash's goal).
signal bar_changed
## The First wash is over (DONE), on every machine that saw it end (not on a load or a join): B's Old Tree
## calls and C's Guide flip start here.
signal first_wash_done

## This machine's counting of the wait (the Host's decides).
var _wait_left := -1.0
var _asked := false
## The First wash as this machine last showed it, and whether the Host asked its end.
var _shown_wash := -1
var _end_asked := false
## The Final wash as this machine last showed it (the door shuts once), whether the Host asked the run's end, and
## whether this machine opened the Final screen.
var _shown_final := false
var _final_end_asked := false
var _screen_opened := false
## Whether this machine asked Continue (once).
var _continue_asked := false


func _enter_tree() -> void:
	add_to_group(GROUP)
	add_to_group(StageBarPhase.SOURCES)
	add_to_group(Stages.FIRST_WASH_GROUP)
	add_to_group(StageBar.GOAL_GROUP)


## A New Game opens with the First wash (Stages holds Stage 1's Socks until it; core/77's group).
func wants_first_wash() -> bool:
	return first_wash == FirstWash.PENDING


## The Stage bar shows its goal phase, "Wash the laundry", until the First wash is DONE (Q2625; core/82's group).
func goal_pending() -> bool:
	return first_wash != FirstWash.DONE


## Version 3 (core/96) adds `ended` and `play_seconds`: an older save has the run still going, which is what their
## defaults say. Version 4 (core/107) drops the fields versions 1 and 2 kept for a station (the last Fix's switch
## and the held Socks, now its run stand-in's): the step drops every field this version does not have.
func save_version() -> int:
	return 4


func upgrade_save(state: Dictionary, from: int) -> Dictionary:
	if from == 3:
		var names := state_names()
		for key: Variant in state.keys():
			if not String(key) in names:
				state.erase(key)
	return state


## The Laundry day of the level `node` is in, or null.
static func of(node: Node) -> LaundryDay:
	if node == null or not node.is_inside_tree():
		return null
	var runtime := LevelRuntime.of(node)
	for n in node.get_tree().get_nodes_in_group(GROUP):
		if n is LaundryDay and LevelRuntime.of(n) == runtime:
			return n as LaundryDay
	return null


# --- Reads ---------------------------------------------------------------------------------------

## The bins this level may use, in the order of their places in the scene.
func bins() -> Array[LaundryBin]:
	var out: Array[LaundryBin] = []
	if spots != null:
		for node in spots.find_children("*", "LaundryBin", true, false):
			out.append(node as LaundryBin)
	out.sort_custom(func(a: LaundryBin, b: LaundryBin) -> bool: return str(a.get_path()) < str(b.get_path()))
	return out


## The bins the World uses.
func used_bins() -> Array[LaundryBin]:
	return bins().filter(func(b: LaundryBin) -> bool: return b.used)


## How many bins the World uses (the tally's total).
func total() -> int:
	return used_bins().size()


## Whether the machine is fixed: the run's last Fix is done (S2).
func fixed() -> bool:
	return stages != null and bool(stages.call(&"is_fixed"))


## The bin player `by` carries, or null.
func carried_bin(by: int) -> LaundryBin:
	for bin in bins():
		if bin.carriable != null and bin.carriable.holder == by:
			return bin
	return null


## Whether the washing machine may be clicked with `carried` now ("Load the washing machine"): the bin is full
## and the First wash is pending (the old prompt) or the last Fix is done.
func offers(carried: Carriable) -> bool:
	for bin in bins():
		if bin.carriable == carried:
			return bin.full and (first_wash == FirstWash.PENDING or fixed())
	return false


## The washing machine of this level, or null.
func washer() -> Washer:
	return Washer.of_level(self)


## Someone is in the drum or a cutscene plays.
func busy() -> bool:
	for wash in WasherWash.in_level(self):
		if wash.busy():
			return true
	return false


## The washer's pile (0..1) with `n` bins in it of `of` (0, then `pile_min` evenly to 1).
func pile_of(n: int, of: int) -> float:
	if n <= 0:
		return 0.0
	var low := tuning.pile_min if tuning != null else 0.4
	if of <= 1:
		return 1.0
	return lerpf(low, 1.0, float(mini(n, of) - 1) / float(of - 1))


## The ending's wait still to run, in seconds (-1 for none).
func wait_left() -> float:
	return _wait_left


# --- The Stage bar's provider (core/82) ----------------------------------------------------------

func bar_source() -> StringName:
	return BAR_SOURCE


## "Wash clothes n/m": the bins loaded and the bins the World uses.
func bar_numbers() -> Vector2i:
	return Vector2i(loaded_bins, total())


# --- Verbs ---------------------------------------------------------------------------------------

func accepts() -> Dictionary[StringName, Dictionary]:
	return {LOAD: {"args": {}, "rate": 4}, CONTINUE: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		LOAD:
			return _load_answer(cmd.by)
		DRAW:
			return _draw_answer() if cmd.by == Parts.HOST else refuse("wrong")
		FINAL_WASH:
			if cmd.by != Parts.HOST or ending_left < 0.0 or final_started:
				return refuse("wrong")
			return _final_wash_answer()
		FINAL_WASH_END:
			if cmd.by != Parts.HOST or not final_started or ended:
				return refuse("already")
			return grant({"ended": true, "play_seconds": _play_seconds()})
		CONTINUE:
			return grant({}) if ended and opens_final_screen else refuse("wrong")
		FIRST_WASH_END:
			if cmd.by != Parts.HOST or first_wash != FirstWash.PLAYING:
				return refuse("already")
			return grant({"first_wash": FirstWash.DONE})
	return refuse("wrong")


## The Final wash begins: the wait is over, the cutscene starts on the frame; with the cutscene off the run ends in
## the same answer.
func _final_wash_answer() -> Dictionary:
	var patch := {"ending_left": -1.0, "final_started": true}
	var changes := {id: patch}
	var wash := washer()
	var frame := Cutscenes.of(self)
	if cutscene and frame != null and wash != null:
		var started := frame.start(FINAL_WASH_SCRIPT)
		if not started.get("ok", false):
			return refuse(BUSY)
		changes.merge(started["changes"], true)
	else:
		patch["ended"] = true
		patch["play_seconds"] = _play_seconds()
	return {"ok": true, "changes": changes}


## The World's play time so far, in whole seconds (the Host's clock; 0 with no World).
func _play_seconds() -> int:
	var runtime := LevelRuntime.of(self) if is_inside_tree() else null
	var autosave := runtime.autosave if runtime != null else null
	return int(autosave.world.record.play_time) if autosave != null and autosave.world != null else 0


## The `load` answer; see the top for the order of the refusals.
func _load_answer(by: int) -> Dictionary:
	var wash := washer()
	if wash != null and parts != null and not parts.near(by, wash.get_parent(), reach):
		return refuse("far")
	var bin := carried_bin(by)
	if bin == null:
		return refuse(NOT_CARRIED)
	if first_wash == FirstWash.PENDING:
		return _first_wash_answer(bin, wash)
	if first_wash == FirstWash.PLAYING:
		return refuse(BUSY)
	if not fixed():
		return refuse(UNFIXED)
	if not bin.full:
		return refuse(EMPTY)
	if ending_left >= 0.0 or final_started or busy():
		return refuse(BUSY)
	var patch := {"loaded_bins": loaded_bins + 1}
	if loaded_bins + 1 >= total():
		patch["ending_left"] = tuning.tip_seconds if tuning != null else 1.4
	return {"ok": true, "changes": {id: patch, bin.id: {"full": false}}, "bin": String(bin.id)}


## The First wash's start: refused only while the machine is busy (any bin, Q1848). One answer: PLAYING (or
## DONE with the cutscene off), the held Socks into the Mess, the cutscene started. The bin stays as it is.
func _first_wash_answer(bin: LaundryBin, wash: Washer) -> Dictionary:
	if not bin.full:
		return refuse(EMPTY)
	if busy() or (wash != null and wash.busy()):
		return refuse(BUSY)
	var changes := {}
	changes.merge(_let_socks_in(), true)
	var state := FirstWash.DONE
	var frame := Cutscenes.of(self)
	if cutscene and frame != null and wash != null:
		var started := frame.start(FIRST_WASH_SCRIPT)
		if not started.get("ok", false):
			return refuse(BUSY)
		changes.merge(started["changes"], true)
		state = FirstWash.PLAYING
	var own: Dictionary = changes.get(id, {})
	own["first_wash"] = state
	changes[id] = own
	return {"ok": true, "changes": changes, "first_wash": true}


## The changes that let the held Socks into the Mess: the run's (Stages.lay_first_answer; none when they are
## not held or there is no run).
func _let_socks_in() -> Dictionary:
	if stages == null:
		return {}
	var laid: Dictionary = stages.call(&"lay_first_answer")
	return laid["changes"] if laid.get("ok", false) else {}


## The draw: `bins_per_world` spots, the `always` ones first, the rest from the World's seed, clamped to 1..spots.
func _draw_answer() -> Dictionary:
	if drawn:
		return refuse("already")
	var all := bins()
	if all.is_empty():
		return refuse("wrong")
	var chosen := {}
	var rest: Array[LaundryBin] = []
	for bin in all:
		if bin.always:
			chosen[bin] = true
		else:
			rest.append(bin)
	var want := clampi(tuning.bins_per_world if tuning != null else 3, 1, all.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["laundry_bins", _world_seed()])
	for i in range(rest.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := rest[i]
		rest[i] = rest[j]
		rest[j] = swap
	for bin in rest:
		if chosen.size() >= want:
			break
		chosen[bin] = true
	var changes := {id: {"drawn": true}}
	for bin in all:
		changes[bin.id] = {"used": chosen.has(bin)}
	return {"ok": true, "changes": changes}


func _world_seed() -> int:
	var runtime := LevelRuntime.of(self)
	return runtime.world.record.seed if runtime != null and runtime.world != null else 0


# --- The Host's wait -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if parts == null or not parts.is_host():
		return
	_end_first_wash()
	_end_final_wash()
	if _wait_left < 0.0:
		return
	_wait_left -= delta
	if _wait_left <= 0.0:
		_wait_left = 0.0
		if not _asked:
			_asked = true
			parts.ask(Command.new(FINAL_WASH, Parts.HOST, id))


## The Host ends a First wash whose cutscene plays no more (its timeline, its skip, or a load mid-cutscene: the
## frame is not saved), once.
func _end_first_wash() -> void:
	if first_wash != FirstWash.PLAYING or _end_asked:
		return
	var frame := Cutscenes.of(self)
	if frame != null and frame.is_playing():
		return
	_end_asked = true
	parts.ask(Command.new(FIRST_WASH_END, Parts.HOST, id))


## The Host ends the run once the Final wash's cutscene plays no more (its timeline, its skip, or a load or join after
## it began: the frame is not saved), once.
func _end_final_wash() -> void:
	if not final_started or ended or _final_end_asked:
		return
	var frame := Cutscenes.of(self)
	if frame != null and frame.is_playing():
		return
	_final_end_asked = true
	parts.ask(Command.new(FINAL_WASH_END, Parts.HOST, id))


## A save and a late Guest get the wait as it stands on the Host's clock.
func whole_state() -> Dictionary:
	var out := state()
	if ending_left >= 0.0 and _wait_left >= 0.0:
		out["ending_left"] = _wait_left
	return out


# --- Every machine -------------------------------------------------------------------------------

## Bound or written: the wait restarts from the state, the pile follows the loaded bins, the bar is told, and the
## machine hears the answers (the tip and the pour). The Host of a New Game draws once the level is bound.
func _show(now: bool) -> void:
	_wait_left = ending_left
	_asked = false
	if first_wash != FirstWash.PLAYING:
		_end_asked = false
	if first_wash == FirstWash.DONE and _shown_wash >= 0 and _shown_wash != FirstWash.DONE and not now:
		first_wash_done.emit()
	_shown_wash = first_wash
	if not final_started:
		_final_end_asked = false
	var wash := washer() if is_inside_tree() else null
	if final_started and not _shown_final and not now and wash != null and wash.looks != null:
		wash.looks.door_close(0.3)  # the door shuts on the Final wash (W2)
	_shown_final = final_started
	if wash != null and wash.looks != null:
		wash.looks.pile = pile_of(loaded_bins, total())
	bar_changed.emit()
	if ended and not _screen_opened and opens_final_screen:
		_open_final_screen.call_deferred()
	if parts != null and not parts.applied.is_connected(_on_applied):
		parts.applied.connect(_on_applied)
		parts.bound.connect(_on_bound, CONNECT_ONE_SHOT)


## Every machine, once the run has ended: the cutscene's black lets go (the view and the HUD come back), the World's
## record is finished (play time stops, saved) and the Final screen opens over the frozen game. A load or a join after
## the end goes straight to it.
func _open_final_screen() -> void:
	if _screen_opened or not opens_final_screen or not ended or not is_inside_tree():
		return
	var runtime := LevelRuntime.of(self)
	if runtime == null:
		return
	_screen_opened = true
	if not runtime.final_screen.continue_pressed.is_connected(_on_continue):
		runtime.final_screen.continue_pressed.connect(_on_continue)
	runtime.cutscene_player.release()
	runtime.autosave.mark_finished()
	var summary := FinalSummary.of(runtime)
	if play_seconds > 0:
		summary.values[&"play_time"] = play_seconds
	runtime.final_screen.open(summary)


## Continue was pressed on this machine's Final screen: it asks the Host, once.
func _on_continue() -> void:
	if parts == null or _continue_asked:
		return
	_continue_asked = true
	var runtime := LevelRuntime.of(self)
	var me := runtime.session.me() if runtime != null and runtime.session != null else Parts.HOST
	parts.ask(Command.new(CONTINUE, me, id))


func _on_bound() -> void:
	_draw_if_new.call_deferred()


func _draw_if_new() -> void:
	if parts != null and parts.is_host() and not drawn and is_inside_tree():
		parts.ask(Command.new(DRAW, Parts.HOST, id))


## Looks only: a bin tips into the machine and the Socks pour, on every machine.
func _on_applied(ev: Dictionary) -> void:
	if not ev.get("ok", false) or ev.get("to") != id:
		return
	if StringName(ev.get("kind", &"")) == CONTINUE:
		var runtime := LevelRuntime.of(self)
		if runtime != null:
			LobbyReturn.go(runtime)
		return
	if StringName(ev.get("kind", &"")) != LOAD or ev.get("first_wash", false):
		return
	var bin := parts.of(StringName(ev.get("bin", &""))) as LaundryBin
	if bin != null:
		bin.tip()
	var wash := washer()
	var porthole := wash.get_parent().get_node_or_null(PORTHOLE) as Node3D if wash != null else null
	if porthole != null:
		Sounds.play_at(POUR_SOUND, porthole.global_position)
