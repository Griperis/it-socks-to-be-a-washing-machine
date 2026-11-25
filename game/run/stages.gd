## The run's decided state (docs/architecture/stages.md "The shape"): which Stage is current, one
## phase instead of the old five counters, the Rows its bar counts, the Designs spawned and still
## due, and the World's Pairs per Drawer. A Part of the level's `Run`, Host authoritative, saved and in
## the join snapshot by its State group. It reads the level's StagePlan (`plan`) and the Cabinets of
## its level (the Run's parent) by group, never by path, and gives each of them itself (Cabinet.stages:
## the Row's capacity is the World's Pairs per Drawer).
##
## Its verbs are the Host's (none is a Guest's: `fit` is the MachinePartSlot's, core/79; the zoo's
## switches ask their own verb and answer with zoo_complete_answer() or zoo_fit_now_answer()). Every
## answer that moves the run carries `stage_events` and every machine emits them as the signals below
## when it applies the answer (never on a load or a join: a snapshot shows the state at once).
class_name Stages
extends Part

## The run's phases (docs/architecture/stages.md "Stages' state").
enum Phase {
	## The bar counts.
	PLAYING,
	## Complete: its Machine Part lies or is carried.
	PART_OUT,
	## The Part is in the machine; its Fix scene plays.
	FIXING,
	## The last Part's Fix is over: the Laundry day's (core/72).
	FIXED,
}

## Every Stages is in this group (Autosave reads the floor's title by it).
const GROUP := &"stages"
## The provider name the Stage bar's `stage_phase` reads (StageBarPhase.source).
const BAR_SOURCE := &"stage_rows"
## The key of an answer's signal list: [[name, args...], ...].
const EVENTS := "stage_events"
## A node in this group with `wants_first_wash() -> bool` (core/72's LaundryDay, core/94) says the level
## opens with the First wash: a New Game then holds Stage 1's Socks until it (docs/architecture/run-ends.md
## seam S1). No such node, or one that says no: they are laid at once.
const FIRST_WASH_GROUP := &"first_wash_wanters"
## The launch option that sets a New Game's Pairs per Drawer in a debug build (the Lobby's slider,
## core/91, rides the launch with it).
const PAIRS_ARG := "--pairs-per-drawer="

## A New Game began (core/72: the First wash begins).
signal run_started
## Stage `stage` completed; its last Pair went into `cabinet` (a Cabinet's Part id).
signal stage_completed(stage: int, cabinet: StringName)
## Stage `stage`'s Part went into the machine (core/73: the Fix scene).
signal part_fitted(stage: int)
## Stage `stage`'s floor opened; `grown` are the Cabinets whose Rows grew (their Part ids).
signal floor_opened(stage: int, grown: Array)
## The last Part's Fix is over (core/72: the Laundry day).
signal machine_fixed

## The level's run.
@export var plan: StagePlan

@export_group("State")
## The current Stage (0 is the basement's); -1 before a New Game's `start`.
@export var stage := -1
## A Phase.
@export var phase := Phase.PLAYING
## The Rows the Stage counts, fixed when it begins (Q633): [Cabinet id, drawer] each.
@export var bar := []
## Every Design spawned this run (each spawns once; core/77).
@export var spawned := PackedInt32Array()
## The Designs of a spawn not landed yet (laid again after a load; core/77).
@export var due := PackedInt32Array()
## Stage 1's Socks have landed in the Mess.
@export var first_laid := false
## A New Game holds Stage 1's Socks out of the Mess until `lay_first` (the First wash): laid, then kept in
## `held_designs` and `held_poses` (one Design and Mess.POSE floats per Sock), saved while held.
@export var holding := false
@export var held_designs := PackedInt32Array()
@export var held_poses := PackedFloat32Array()
## This World's Pairs per Drawer (25; the debug slider, Q668).
@export_range(1, 25, 1) var pairs_per_drawer := 25
@export_group("")

## The Cabinets of its level, in tree order (found once).
var _cabinets: Array[Cabinet] = []
## A `complete` is on its way to the Host's Parts (asked once).
var _completing := false
## The level's Mess (found once).
var _mess: Mess


func _enter_tree() -> void:
	add_to_group(GROUP)
	add_to_group(StageBarPhase.SOURCES)


func _ready() -> void:
	cabinets()


## The level the run belongs to: the Run's parent (a zoo station's root, the house).
func level() -> Node:
	var run := get_parent()
	return run.get_parent() if run != null and run.get_parent() != null else run


## The Cabinets of its level, in tree order; each is given this Stages.
func cabinets() -> Array[Cabinet]:
	if _cabinets.is_empty() and is_inside_tree():
		var root := level()
		for node in get_tree().get_nodes_in_group(Cabinet.GROUP):
			if root != null and root.is_ancestor_of(node):
				var cab := node as Cabinet
				cab.stages = self
				_cabinets.append(cab)
	return _cabinets


## The current Stage's data, or null.
func current() -> Stage:
	return plan.stage(stage) if plan != null else null


## The current Stage's title ("Basement"): the World's row names it; "" before the run starts.
func floor_title() -> String:
	var s := current()
	return s.title if s != null else ""


## Whether floor `floor` is open: a Stage up to the current one opens it.
func floor_open(floor: int) -> bool:
	if plan == null:
		return false
	for i in range(0, mini(stage + 1, plan.size())):
		if plan.stage(i).floor == floor:
			return true
	return false


## How many Parts are in the machine (core/73's mood: angriest at none).
func fitted_count() -> int:
	return maxi(stage, 0) + (1 if phase == Phase.FIXING or phase == Phase.FIXED else 0)


## The Mess its Socks join (found once in the level), or null.
func mess() -> Mess:
	if _mess == null and is_inside_tree():
		_mess = _find_mess(level())
	return _mess


func _find_mess(node: Node) -> Mess:
	if node == null:
		return null
	if node is Mess:
		return node as Mess
	for child in node.get_children():
		var found := _find_mess(child)
		if found != null:
			return found
	return null


## Whether a New Game holds Stage 1's Socks for the First wash (FIRST_WASH_GROUP).
func wants_first_wash() -> bool:
	if not is_inside_tree():
		return false
	var root := level()
	for node in get_tree().get_nodes_in_group(FIRST_WASH_GROUP):
		if node.has_method(&"wants_first_wash") and (root == null or root.is_ancestor_of(node)) and node.call(&"wants_first_wash"):
			return true
	return false


## The Designs Stage `index` spawns (the old rule, CA:197-270, Q619, Q637, Q660): for every unlocked
## Cabinet (`rows_by`: Cabinet -> its Rows, as the answer leaves them) enough of its Collection's Designs
## not spawned (`taken`) or shelved yet to fill all its Rows, the washer lesson's two first; then, until
## the Stage's Pairs at `per` Pairs per Drawer are reached, more Designs of the unlocked Cabinets (their
## later Rows'), a Cabinet at a time in catalogue order. A locked Cabinet's Designs never spawn; the rest
## of a Collection is spread evenly through it (a golden-ratio walk). In play: every Design (the pools
## are batch B's, Q2618). Every machine picks the same.
func stage_designs(index: int, rows_by: Dictionary, per: int, taken: PackedInt32Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	var m := mess()
	if m == null or m.catalogue == null or plan == null:
		return out
	var cat := m.catalogue
	var gone := {}
	for d in taken:
		gone[d] = true
	for cab in cabinets():
		for lead in cab.shelved():
			var design := m.design_of(lead)
			if design != null:
				gone[design.id] = true
	var lesson := lesson_designs(cat)
	var left: Array = []
	for col in cat.collections():
		for cab in cabinets():
			if cab.collection != col or not rows_by.has(cab):
				continue
			var first: Array[int] = []
			var rest: Array[int] = []
			var out_already := 0
			for id in cat.size():
				var d := cat.design(id)
				if d == null or d.collection != col:
					continue
				if gone.has(id):
					out_already += 1
				elif lesson.has(id):
					first.append(id)
				else:
					rest.append(id)
			var cands: Array[int] = first + _spread(rest)
			var need := -out_already
			for i in int(rows_by[cab]):
				need += cab.row_capacity_at(i, per)
			var take := clampi(need, 0, cands.size())
			for k in take:
				out.append(cands[k])
				gone[cands[k]] = true
			left.append(cands.slice(take))
	var target := plan.pairs_of(index, per)
	var more := true
	while out.size() < target and more:
		more = false
		for cands: Array in left:
			if out.size() < target and not cands.is_empty():
				out.append(int(cands.pop_front()))
				more = true
	return out


## The washer lesson's Designs (progression/04, with the campaign on): the first two common Designs of
## Simple.
static func lesson_designs(cat: DesignCatalogue) -> Array[int]:
	var out: Array[int] = []
	for id in cat.size():
		var d := cat.design(id)
		if d != null and d.collection == &"simple" and d.rarity == SockDesign.Rarity.COMMON:
			out.append(id)
			if out.size() == 2:
				break
	return out


## `ids` reordered so that any first part of it is spread evenly through the list (a golden-ratio walk).
static func _spread(ids: Array[int]) -> Array[int]:
	var keyed: Array = []
	for i in ids.size():
		keyed.append([fposmod(float(i) * 0.6180339887, 1.0), ids[i]])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array[int] = []
	for k: Array in keyed:
		out.append(int(k[1]))
	return out


# --- The bar -------------------------------------------------------------------------------------

## The Cabinet with Part id `cabinet_id` among its level's, or null.
func cabinet_of(cabinet_id: StringName) -> Cabinet:
	for cab in cabinets():
		if cab.id == cabinet_id:
			return cab
	return null


## Whether every Row of the bar is full (an empty bar is too).
func bar_full() -> bool:
	for row: Variant in bar:
		var cab := cabinet_of(StringName(str((row as Array)[0])))
		if cab != null and not cab.row_full(int((row as Array)[1])):
			return false
	return true


## The Stage bar's provider name (StageBarPhase.source).
func bar_source() -> StringName:
	return BAR_SOURCE


## The Stage bar's two numbers: the Pairs shelved in the bar's Rows and the Pairs they take.
func bar_numbers() -> Vector2i:
	var got := 0
	var takes := 0
	for row: Variant in bar:
		var cab := cabinet_of(StringName(str((row as Array)[0])))
		if cab == null:
			continue
		var index := int((row as Array)[1])
		var cap := cab.row_capacity(index)
		takes += cap
		got += mini(cab.contents(index).size(), cap)
	return Vector2i(got, takes)


## The words ahead of the two numbers in the `stage_phase` text: the Stage's number and title.
func bar_words() -> Array:
	var s := current()
	return [stage + 1, s.title if s != null else ""]


## The Collections of the bar's Cabinets, in catalogue order (the Stage bar's icons).
func bar_collections() -> Array[StringName]:
	var have: Dictionary[StringName, bool] = {}
	var catalogue: DesignCatalogue = null
	for row: Variant in bar:
		var cab := cabinet_of(StringName(str((row as Array)[0])))
		if cab == null:
			continue
		have[cab.collection] = true
		if catalogue == null and cab.mess_of() != null:
			catalogue = cab.mess_of().catalogue
	var out: Array[StringName] = []
	if catalogue != null:
		for c in catalogue.collections():
			if have.has(c):
				out.append(c)
	for c in have:
		if not out.has(c):
			out.append(c)
	return out


## The Rows a Cabinet of `cab` may have at `per` Pairs per Drawer: its full height, never more than its
## Drawers.
static func height_of(cab: Cabinet, per: int) -> int:
	return mini(cab.full_height_at(per), cab.drawer_count())


## The bar of Stage `index` from `rows_by` (Cabinet -> its Rows, unlocked ones only, as the answer
## leaves them) at `per` Pairs per Drawer: every Row not full now (Q633, Q648); a Stage that counts only
## its own Cabinets only theirs (Q2623).
func _bar_of(index: int, rows_by: Dictionary, per: int) -> Array:
	var only_own := plan.stage(index).counts_only_own
	var out := []
	for cab in cabinets():
		if not rows_by.has(cab):
			continue
		if only_own and cab.unlock_stage != index + 1:
			continue
		for i in int(rows_by[cab]):
			if cab.contents(i).size() < cab.row_capacity_at(i, per):
				out.append([String(cab.id), i])
	return out


# --- Verbs ---------------------------------------------------------------------------------------

func decide(cmd: Command) -> Dictionary:
	if cmd.by != Parts.HOST or plan == null or plan.size() == 0:
		return refuse("wrong")
	match cmd.kind:
		&"start":
			return start_answer(int(cmd.args.get("pairs_per_drawer", plan.pairs_per_drawer)))
		&"complete":
			if stage < 0 or phase != Phase.PLAYING or not bar_full():
				return refuse("already")
			return _complete_answer(StringName(str(cmd.args.get("cabinet", ""))), {})
		&"open_floor":
			if stage < 0 or phase != Phase.FIXING:
				return refuse("already")
			return _open_answer([])
		&"lay_first":
			return _lay_first_answer()
		&"land":
			return _land_answer(cmd.args)
		&"zoo_complete":
			return zoo_complete_answer()
		&"zoo_fit_now":
			return zoo_fit_now_answer()
	return refuse("wrong")


## The `start` answer: Stage 1, every Cabinet's lock and Rows (Stage 1's unlocked at `start_rows`, the
## rest locked showing them), the bar, the World's Pairs per Drawer. Refused once the run has begun.
func start_answer(per: int) -> Dictionary:
	if stage >= 0:
		return refuse("already")
	per = clampi(per, 1, StagePlan.PAIRS_AT)
	var changes := {}
	var rows_by := {}
	for cab in cabinets():
		var opens := cab.unlock_stage <= 1
		var rows := mini(plan.start_rows, height_of(cab, per))
		changes.merge(cab.lock_patch(not opens, rows), true)
		if opens:
			rows_by[cab] = rows
	var designs := stage_designs(0, rows_by, per, PackedInt32Array())
	changes[id] = {"stage": 0, "phase": Phase.PLAYING, "bar": _bar_of(0, rows_by, per),
			"spawned": designs, "due": designs, "first_laid": false, "pairs_per_drawer": per,
			"holding": wants_first_wash(), "held_designs": PackedInt32Array(), "held_poses": PackedFloat32Array()}
	return {"ok": true, "changes": changes, EVENTS: [[&"run_started"]]}


## `lay_first` (the First wash at its spit, core/72): Stage 1's Socks held at the New Game lie in the Mess
## now, where they were laid; if they are not laid yet they land in the Mess as soon as they are.
func _lay_first_answer() -> Dictionary:
	if stage != 0 or not holding:
		return refuse("already")
	var patch := {"holding": false}
	var changes := {id: patch}
	if not held_designs.is_empty():
		var m := mess()
		if m == null:
			return refuse("wrong")
		changes[m.id] = m.added_lying_patch(held_designs, held_poses)
		patch["first_laid"] = true
		patch["held_designs"] = PackedInt32Array()
		patch["held_poses"] = PackedFloat32Array()
	return {"ok": true, "changes": changes}


## `land` (the StageSpawner, Host): the laid records ("designs", "poses") of the Designs it was asked
## ("asked"), `stage`'s Socks. They join the Mess lying, or are held while a New Game waits for the First
## wash; every asked Design leaves `due` (one no place was found for is not laid again).
func _land_answer(args: Dictionary) -> Dictionary:
	var laid: Variant = args.get("designs", PackedInt32Array())
	var poses: Variant = args.get("poses", PackedFloat32Array())
	var asked: Variant = args.get("asked", laid)
	if not (laid is PackedInt32Array) or not (poses is PackedFloat32Array) or not (asked is PackedInt32Array) \
			or (poses as PackedFloat32Array).size() != (laid as PackedInt32Array).size() * Mess.POSE:
		return refuse("wrong")
	var left := PackedInt32Array()
	for d in due:
		if not (asked as PackedInt32Array).has(d):
			left.append(d)
	var patch := {"due": left}
	var changes := {id: patch}
	var designs: PackedInt32Array = laid
	if not designs.is_empty():
		var first_stage := int(args.get("stage", stage)) == 0
		if holding and first_stage:
			var more := held_designs.duplicate()
			more.append_array(designs)
			var more_poses := held_poses.duplicate()
			more_poses.append_array(poses as PackedFloat32Array)
			patch["held_designs"] = more
			patch["held_poses"] = more_poses
		else:
			var m := mess()
			if m == null:
				return refuse("wrong")
			changes[m.id] = m.added_lying_patch(designs, poses as PackedFloat32Array)
			if first_stage:
				patch["first_laid"] = true
	return {"ok": true, "changes": changes}


## The zoo's "Complete" switch: the Stage completes outright. Refused unless the bar counts.
func zoo_complete_answer() -> Dictionary:
	if stage < 0 or phase != Phase.PLAYING:
		return refuse("already")
	return _complete_answer(&"", {})


## The zoo's "Fit now" switch: the Stage completes if it has not, its Part is fitted and its floor opens
## at once. Refused before the run and once the machine is fixed.
func zoo_fit_now_answer() -> Dictionary:
	if stage < 0 or phase == Phase.FIXED:
		return refuse("already")
	var events := []
	if phase == Phase.PLAYING:
		events.append([&"stage_completed", stage, _last_cabinet(&"")])
	if phase != Phase.FIXING:
		events.append([&"part_fitted", stage])
	return _open_answer(events)


## Complete: `phase = PART_OUT` (core/79 adds its Machine Part at the pop spot to `changes`).
func _complete_answer(cabinet: StringName, changes: Dictionary) -> Dictionary:
	changes[id] = {"phase": Phase.PART_OUT}
	return {"ok": true, "changes": changes, "cabinet": _last_cabinet(cabinet),
			EVENTS: [[&"stage_completed", stage, _last_cabinet(cabinet)]]}


## `cabinet` when it is one of the level's, else the bar's last Row's Cabinet ("" with no bar).
func _last_cabinet(cabinet: StringName) -> StringName:
	if cabinet != &"" and cabinet_of(cabinet) != null:
		return cabinet
	return StringName(str((bar.back() as Array)[0])) if not bar.is_empty() else &""


## The floor opens: the next Stage, every unlocked Cabinet `rows_per_stage` Rows taller up to its full
## height, the new Stage's Cabinets unlocked at `start_rows`, the new bar (the floor's locks and its
## Socks: core/80 and core/77). On the last Stage the machine is fixed instead. `events` go first.
func _open_answer(events: Array, base_due := due) -> Dictionary:
	var next := stage + 1
	if next >= plan.size():
		events.append([&"machine_fixed"])
		return {"ok": true, "changes": {id: {"phase": Phase.FIXED}}, EVENTS: events}
	var per := pairs_per_drawer
	var changes := {}
	var rows_by := {}
	var grown := []
	for cab in cabinets():
		var height := height_of(cab, per)
		if not cab.locked:
			var rows := maxi(cab.rows, mini(cab.rows + plan.rows_per_stage, height))
			if rows != cab.rows:
				changes.merge(cab.lock_patch(false, rows), true)
				grown.append(cab.id)
			rows_by[cab] = rows
		elif cab.unlock_stage <= next + 1:
			var rows := mini(plan.start_rows, height)
			changes.merge(cab.lock_patch(false, rows), true)
			rows_by[cab] = rows
	var designs := stage_designs(next, rows_by, per, spawned)
	var now_due := base_due.duplicate()
	now_due.append_array(designs)
	var now_spawned := spawned.duplicate()
	now_spawned.append_array(designs)
	changes[id] = {"stage": next, "phase": Phase.PLAYING, "bar": _bar_of(next, rows_by, per),
			"due": now_due, "spawned": now_spawned}
	events.append([&"floor_opened", next, grown])
	return {"ok": true, "changes": changes, EVENTS: events}


## A load between the Fix and its floor's opening (the Fix scene cut short) opens the floor now, as
## the old step() did (CA:348-353). The Designs still due are laid again (old redo_due, CA:272-291): the
## ones now held, lying or shelved are not due any more.
func loaded(_host: String) -> Dictionary:
	if plan == null or stage < 0:
		return {}
	var still := _still_due()
	if phase == Phase.FIXING:
		return _open_answer([], still)
	if still.size() != due.size():
		return grant({"due": still})
	return {}


## `due` without the Designs the Mess already has as Socks (held in Hands, lying, shelved or in the air).
func _still_due() -> PackedInt32Array:
	var m := mess()
	var have := {}
	if m != null:
		for sock in m.count():
			if m.state_of(sock) != Mess.State.GONE:
				have[m.designs[sock]] = true
	for d in held_designs:
		have[d] = true
	var out := PackedInt32Array()
	for d in due:
		if not have.has(d):
			out.append(d)
	return out


# --- Every machine -------------------------------------------------------------------------------

## Bound: it hears every applied answer, and the Host starts a New Game's run once the level's World is
## loaded (a loaded World has begun already).
func _show(_now: bool) -> void:
	if parts == null:
		return
	if not parts.applied.is_connected(_on_applied):
		parts.applied.connect(_on_applied)
	if not parts.bound.is_connected(_on_bound):
		parts.bound.connect(_on_bound, CONNECT_ONE_SHOT)


## After everything the level starts with (LevelNet.start() loads the World first: it was deferred
## before this).
func _on_bound() -> void:
	_start_if_new.call_deferred()


## The Host of a run not begun asks `start` with the World's Pairs per Drawer.
func _start_if_new() -> void:
	if parts == null or not parts.is_host() or stage >= 0 or plan == null or plan.size() == 0:
		return
	parts.ask(Command.new(&"start", Parts.HOST, id, {"pairs_per_drawer": launch_pairs_per_drawer()}))


## The launch's Pairs per Drawer (a debug build's `--pairs-per-drawer=N`), else the plan's.
func launch_pairs_per_drawer() -> int:
	var runtime := LevelRuntime.of(self)
	if OS.is_debug_build() and runtime != null and runtime.from_title:
		for arg in runtime.launch:
			if arg.begins_with(PAIRS_ARG) and arg.trim_prefix(PAIRS_ARG).is_valid_int():
				return clampi(int(arg.trim_prefix(PAIRS_ARG)), 1, StagePlan.PAIRS_AT)
	return plan.pairs_per_drawer


## Every machine: the answer's Stage events become signals. The Host also asks `complete` once the
## bar is full after an answer (a shelve, a floor whose Rows were all full).
func _on_applied(ev: Dictionary) -> void:
	if ev.get("kind") == &"complete" and ev.get("to") == id:
		_completing = false
	if not ev.get("ok", false):
		return
	var events: Variant = ev.get(EVENTS)
	if events is Array:
		for e: Variant in (events as Array):
			_emit(e as Array)
	if parts.is_host() and not _completing and stage >= 0 and phase == Phase.PLAYING and bar_full():
		_completing = true
		var cabinet := StringName(str(ev.get("to", ""))) if ev.has("shelved") else &""
		parts.ask.call_deferred(Command.new(&"complete", Parts.HOST, id, {"cabinet": cabinet}))


func _emit(e: Array) -> void:
	match StringName(str(e[0])):
		&"run_started":
			run_started.emit()
		&"stage_completed":
			stage_completed.emit(int(e[1]), StringName(str(e[2])))
		&"part_fitted":
			part_fitted.emit(int(e[1]))
		&"floor_opened":
			floor_opened.emit(int(e[1]), e[2] as Array)
		&"machine_fixed":
			machine_fixed.emit()
