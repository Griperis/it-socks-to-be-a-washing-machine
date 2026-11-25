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
## cutscene off (`cutscene`: the zoo, tests) the start is DONE at once. Saved: it never plays again in the World.
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
## Final screen over the frozen game (`FinalSummary.of`). With the cutscene off (the zoo, a test) it ends at once and
## the zoo opens no screen.
##
## It is the Stage bar's `laundry_bins` provider (`bar_numbers`, `bar_changed`; core/82) and its goal
## (`stage_bar_goal`). Looks only (the tip, the pile, the sound) never writes state.
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
const ZOO_LAST_FIX := &"zoo_last_fix"
const ZOO_FINAL := &"zoo_final"
## The Host's end of the First wash (its cutscene over, or none).
const FIRST_WASH_END := &"first_wash_end"
## The Laundry station's "First wash" pillar: PENDING again, a few Socks held.
const ZOO_FIRST_WASH := &"zoo_first_wash"
## How many Socks the zoo's pillar holds, and how far round the station's washer they lie (metres).
const ZOO_HELD := 6
const ZOO_HELD_RING := 1.4
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
## Links the wiring check lets stay empty: the zoo's station has no run, a level may have no spots node.
const WIRING_OPTIONAL := ["stages"]

## The node whose descendants are this level's bin spots (`LaundryBins` in the house).
@export var spots: Node
## The run whose last Fix it reads; none in the zoo's station (its pillar says it).
@export var stages: Stages
@export var tuning: LaundryTuning
## How far from the washing machine a player may stand to load it, in metres.
@export var reach := 4.0
## In the Laundry station: the zoo-only Commands are granted and no draw is made at a New Game.
@export var zoo := false
## The First wash plays its cutscene; off (the zoo's station, a test) its start and end are one answer.
@export var cutscene := true

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
## The zoo's stand-in for the last Fix (only read when there is no `stages`).
@export var zoo_fixed := false
## The zoo's held Socks (no run there): their Designs and Mess.POSE floats each, let in by the First wash.
@export var zoo_held_designs := PackedInt32Array()
@export var zoo_held_poses := PackedFloat32Array()
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


func _enter_tree() -> void:
	add_to_group(GROUP)
	add_to_group(StageBarPhase.SOURCES)
	add_to_group(Stages.FIRST_WASH_GROUP)
	add_to_group(StageBar.GOAL_GROUP)


## A New Game opens with the First wash (Stages holds Stage 1's Socks until it; core/77's group). Not the zoo's.
func wants_first_wash() -> bool:
	return not zoo and first_wash == FirstWash.PENDING


## The Stage bar shows its goal phase, "Wash the laundry", until the First wash is DONE (Q2625; core/82's group).
func goal_pending() -> bool:
	return not zoo and first_wash != FirstWash.DONE


## Version 2 (core/94) adds the zoo's held Socks; a version 1 save (core/93) lacks them and keeps the scene's
## empty lists, so nothing needs upgrading. Version 3 (core/96) adds `ended` and `play_seconds`: an older save
## has the run still going, which is what their defaults say.
func save_version() -> int:
	return 3


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


## Whether the machine is fixed: the run's last Fix is done (S2), or the zoo's switch.
func fixed() -> bool:
	if stages != null:
		return stages.stage >= 0 and stages.phase == Stages.Phase.FIXED
	return zoo_fixed


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
	var out: Dictionary[StringName, Dictionary] = {LOAD: {"args": {}, "rate": 4}}
	if zoo:
		out[ZOO_FIRST_WASH] = {"args": {}, "rate": 5}
		out[ZOO_LAST_FIX] = {"args": {"on": TYPE_BOOL}, "rate": 5}
		out[ZOO_FINAL] = {"args": {}, "rate": 5}
	return out


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
		ZOO_LAST_FIX:
			var on: Variant = cmd.args.get("on")
			if not zoo or not (on is bool) or on == zoo_fixed:
				return refuse("wrong")
			return grant({"zoo_fixed": on})
		ZOO_FINAL:
			return _zoo_final_answer() if zoo else refuse("wrong")
		FIRST_WASH_END:
			if cmd.by != Parts.HOST or first_wash != FirstWash.PLAYING:
				return refuse("already")
			return grant({"first_wash": FirstWash.DONE})
		ZOO_FIRST_WASH:
			return _zoo_first_wash_answer() if zoo else refuse("wrong")
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
## not held), or the zoo's own.
func _let_socks_in() -> Dictionary:
	if stages != null:
		var laid := stages.lay_first_answer()
		return laid["changes"] if laid.get("ok", false) else {}
	var mess := _mess()
	if zoo_held_designs.is_empty() or mess == null:
		return {}
	return {mess.id: mess.added_lying_patch(zoo_held_designs, zoo_held_poses),
			id: {"zoo_held_designs": PackedInt32Array(), "zoo_held_poses": PackedFloat32Array()}}


## The zoo's "First wash" pillar: PENDING again and `ZOO_HELD` Socks held round the station's washer, laid
## by the First wash. Refused while it plays.
func _zoo_first_wash_answer() -> Dictionary:
	if first_wash == FirstWash.PLAYING:
		return refuse("busy")
	var mess := _mess()
	var designs := PackedInt32Array()
	var poses := PackedFloat32Array()
	var thing := _washer_thing()
	if mess != null and mess.catalogue != null and mess.catalogue.size() > 0 and thing != null:
		var middle := thing.global_position
		if thing is VisualInstance3D:
			middle.y = (thing.global_transform * (thing as VisualInstance3D).get_aabb()).position.y
		for i in ZOO_HELD:
			designs.append(int(i / 2.0) % mess.catalogue.size())
			var a := TAU * float(i) / float(ZOO_HELD) + PI * 0.5
			var at := middle + Vector3(cos(a), 0.0, sin(a)) * ZOO_HELD_RING
			at.y = middle.y + 0.03
			poses.append_array(Mess.pack(Transform3D(Basis(Vector3.UP, a), at)))
	return grant({"first_wash": FirstWash.PENDING, "zoo_held_designs": designs, "zoo_held_poses": poses})


func _mess() -> Mess:
	var runtime := LevelRuntime.of(self) if is_inside_tree() else null
	return runtime.mess if runtime != null else null


## The washing machine's root: the real washer's, else the level's `washer` group node (the zoo's stand-in).
func _washer_thing() -> Node3D:
	var wash := washer()
	if wash != null:
		return wash.get_parent() as Node3D
	for node in get_tree().get_nodes_in_group(Washer.GROUP):
		if node is Node3D and LevelRuntime.of(node) == LevelRuntime.of(self):
			return node as Node3D
	return null


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


## The zoo's "Final wash": the first press loads every bin but one (the last Fix done), the next loads the last.
func _zoo_final_answer() -> Dictionary:
	var used := used_bins()
	if used.is_empty() or final_started or ending_left >= 0.0:
		return refuse("wrong")
	var patch := {"zoo_fixed": true}
	var changes := {id: patch}
	if loaded_bins < used.size() - 1:
		for i in used.size() - 1:
			changes[used[i].id] = {"full": false}
		patch["loaded_bins"] = used.size() - 1
	else:
		changes[used[used.size() - 1].id] = {"full": false}
		patch["loaded_bins"] = used.size()
		patch["ending_left"] = tuning.tip_seconds if tuning != null else 1.4
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
	if ended and not _screen_opened and not zoo:
		_open_final_screen.call_deferred()
	if parts != null and not parts.applied.is_connected(_on_applied):
		parts.applied.connect(_on_applied)
		if not zoo:
			parts.bound.connect(_on_bound, CONNECT_ONE_SHOT)


## Every machine, once the run has ended: the cutscene's black lets go (the view and the HUD come back), the World's
## record is finished (play time stops, saved) and the Final screen opens over the frozen game. A load or a join after
## the end goes straight to it. The zoo's Laundry day opens none.
func _open_final_screen() -> void:
	if _screen_opened or zoo or not ended or not is_inside_tree():
		return
	var runtime := LevelRuntime.of(self)
	if runtime == null:
		return
	_screen_opened = true
	runtime.cutscene_player.release()
	runtime.autosave.mark_finished()
	var summary := FinalSummary.of(runtime)
	if play_seconds > 0:
		summary.values[&"play_time"] = play_seconds
	runtime.final_screen.open(summary)


func _on_bound() -> void:
	_draw_if_new.call_deferred()


func _draw_if_new() -> void:
	if parts != null and parts.is_host() and not drawn and is_inside_tree():
		parts.ask(Command.new(DRAW, Parts.HOST, id))


## Looks only: a bin tips into the machine and the Socks pour, on every machine.
func _on_applied(ev: Dictionary) -> void:
	if not ev.get("ok", false) or ev.get("to") != id or StringName(ev.get("kind", &"")) != LOAD or ev.get("first_wash", false):
		return
	var bin := parts.of(StringName(ev.get("bin", &""))) as LaundryBin
	if bin != null:
		bin.tip()
	var wash := washer()
	var porthole := wash.get_parent().get_node_or_null(PORTHOLE) as Node3D if wash != null else null
	if porthole != null:
		Sounds.play_at(POUR_SOUND, porthole.global_position)
