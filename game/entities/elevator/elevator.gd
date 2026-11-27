## The house's Elevator (docs/architecture/elevator.md; the old Elevator, ElevatorRules and ElevatorView): one Part on
## the entity's root for the car and its riders, decided on the Host. The car stands at a floor behind its stop's
## hatch; a click on a stop's call button or its shut hatch calls it (`call`): its open hatch slides shut
## (`hatch_time`), it rides `floor_time` a floor (shortened by Fast Elevator) and the hatch there opens with the bell
## (`depart`, `arrive`: the Host's own timers). No car is seen moving (Q2702): it is drawn at `stop`, the floor it
## stands at, leaves (while its hatch shuts) or is bound for once it departs. The newest call wins (Q513); the call
## button only opens a shut hatch (Q2702); a click on the hatch the car stands behind opens or shuts it (`hatch`).
##
## In a Run (a `Stages` in its level) it is out of order until the House buys Elevator Repair, locked until the
## ground floor opens, then works for open floors only; a level with no `Stages` (the zoo) never refuses so, and a
## level with no `Upgrades` reads Elevator Repair as bought. Every stop shows its plaque and its padlock from that
## (ElevatorStop.show_signs()), every letter its clip.
##
## What lies in the car rides by one rule (Q2699): the Parts in the group `elevator_cargo` patch their own things in
## the `depart` answer (`rides_patch`), a call asks them `called_patch`, the Host tells them `car_opened` after an
## arrival, and `fills_car` will refuse a climb (core/157). No member yet: core/156 adds the Mess and `Carriable`.
class_name Elevator
extends Part

## Where the car is: standing with its hatch open or shut, its hatch shutting before it leaves, riding.
enum Phase { OPEN, SHUT, CLOSING, RIDING }

## Every Elevator is in this group.
const GROUP := &"elevators"
## The group of the Parts whose things ride the car (the one carry rule, Q2699).
const CARGO := &"elevator_cargo"
## The verbs.
const CALL := &"call"
const HATCH := &"hatch"
const SEND := &"send"
const DEPART := &"depart"
const ARRIVE := &"arrive"
const OPEN_HATCH := &"open_hatch"
## The refusals the asker reads, in the old words (G:248-250).
const BROKEN := "broken"
const LOCKED := "locked"
const SAYS := {BROKEN: "Out of order (needs the Elevator Repair upgrade)", LOCKED: "Elevator locked"}
## The floor whose opening opens the Elevator (Q643): the ground floor.
const ENTRY_FLOOR := 1
## How far from a stop a player may click it, in metres (an Openable's reach).
const USE_REACH := 4.0
## The Elevator's sounds (SoundEvents of core/154). The hatch's own are its Openable's.
const BELL := &"elevator_bell"
const CREAK := &"elevator_creak"
const BUTTON := &"elevator_button"
## The letters' clips (letter/looks_contract.json) and their glyphs by floor.
const LIT := &"lit"
const DARK := &"dark"
const LETTER_LOCKED := &"locked"
const LETTER_SCENE := preload("res://game/entities/elevator/elevator_letter.tscn")
## The keys an answer carries for the button's click: the floor clicked, and whether it was the button.
const AT := "elevator_at"
const PRESSED := "elevator_button"

## A stop's hatch opened or shut (every machine, from an applied answer; the Openable plays its clip and sounds).
signal hatch_moved(floor: int, open: bool)
## The car left floor `from` for floor `to` (its hatch is shut): the creak, the riders' view, the Cat.
signal departed(from: int, to: int)
## The car arrived at `floor` (its hatch opens): the bell, the Cat wakes.
signal arrived(floor: int)
## Player `player` climbed in (`into`) or out (core/157).
signal climbed(player: int, into: bool)
## The Host refused player `player`, who reads `words`.
signal refused(player: int, words: String)

@export var tuning: ElevatorTuning
## Elevator Repair's stat (FLAG) and Fast Elevator's (SCALE_DOWN, a share of `floor_time`).
@export var repair_stat: UpgradeStat
@export var floor_time_stat: UpgradeStat
## The car, moved from stop to stop (only its height).
@export var car: Node3D
## The car's inside: what lies in it rides.
@export var car_box: CollisionShape3D
## The floor letters' column on the car's +z wall, filled at ready (one per stop, B at the bottom).
@export var letters: Node3D

@export_group("State")
## The floor the car is drawn at: where it stands, the one it leaves while its hatch shuts, the one it is bound
## for once it departs (no car is seen moving, Q2702). A New Game: the ground floor (the kitchen).
@export var stop := 1
## The floor it is bound for; -1 while it stands.
@export var bound := -1
## A Phase.
@export var phase := Phase.OPEN
## Where the ride began and how many floors of it are done (a turn starts a new ride from where it got, Q513).
@export var from := 1
@export var progress := 0.0
## Seconds left of CLOSING or RIDING as of the answer (a save and a snapshot hold the live value: a load resumes).
@export var time_left := 0.0
## The riders' player ids in seat order (core/157).
@export var riders: Array[int] = []
## Dragger id -> the knocked-down body's player id riding with them (core/158).
@export var dragged := {}
@export_group("")

## The stops by floor (found once).
var _stops: Dictionary[int, ElevatorStop] = {}
## The letters by floor (built once).
var _letters: Dictionary[int, Node3D] = {}
## Seconds since `time_left` was last written.
var _since := 0.0
## The Host asked its timer's verb for this phase already.
var _asked := false
## The phase as last shown (null before the first show).
var _was_phase: Variant = null
var _creak_in := 0.0
var _listening := false


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	stops()
	_build_letters()
	if tuning != null:
		for s: ElevatorStop in _stops.values():
			var player := s.hatch.animator() if s.hatch != null else null
			if player != null:
				player.speed_scale = player.get_animation(Openable.ANIMATION).length / maxf(tuning.hatch_time, 0.01)


## The Elevator a node belongs to: the one beside it or beside an ancestor (a stop, a letter in the car), or null.
static func of(node: Node) -> Elevator:
	while node != null:
		for child in node.get_children():
			if child is Elevator:
				return child as Elevator
		node = node.get_parent()
	return null


## A box shape's space in the world (an axis-aligned box round it), or an empty box.
static func box_of(shape: CollisionShape3D) -> AABB:
	var box := shape.shape as BoxShape3D if shape != null else null
	if box == null or not shape.is_inside_tree():
		return AABB()
	return shape.global_transform * AABB(-box.size * 0.5, box.size)


## The stops by floor: every ElevatorStop under the entity's root.
func stops() -> Dictionary[int, ElevatorStop]:
	if _stops.is_empty() and get_parent() != null:
		var stack: Array[Node] = [get_parent()]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is ElevatorStop:
				_stops[(n as ElevatorStop).floor] = n as ElevatorStop
				continue
			stack.append_array(n.get_children())
	return _stops


## The floors it stops at, bottom up.
func floors() -> Array[int]:
	var out: Array[int] = []
	out.assign(stops().keys())
	out.sort()
	return out


# --- Reading (every machine) ---------------------------------------------------------------------

## Whether it is out of order: in a Run, until the House buys Elevator Repair.
func is_broken() -> bool:
	if _stages() == null:
		return false
	var ups := _upgrades()
	if ups == null or repair_stat == null:
		return false
	return ups.value(repair_stat, Parts.HOST) < 0.5


## Whether floor `floor` is closed to it: in a Run, until the ground floor opens, then while that floor is locked.
func is_locked(floor: int) -> bool:
	var stages := _stages()
	if stages == null:
		return false
	return not stages.floor_open(ENTRY_FLOOR) or not stages.floor_open(floor)


## Whether the car stands at `floor` (its hatch open or shut).
func stands_at(floor: int) -> bool:
	return stop == floor and (phase == Phase.OPEN or phase == Phase.SHUT)


## Whether the hatch of `floor` stands open.
func hatch_open(floor: int) -> bool:
	var s: ElevatorStop = stops().get(floor)
	return s != null and s.hatch != null and s.hatch.open


## Seconds left of the hatch's shutting or the ride now.
func left_now() -> float:
	return maxf(time_left - _since, 0.0)


## Seconds a floor takes now: `floor_time` shortened by Fast Elevator (read when it decides, never cached).
func floor_seconds() -> float:
	var t := tuning.floor_time if tuning != null else 2.0
	var ups := _upgrades()
	if ups != null and floor_time_stat != null:
		t *= ups.value(floor_time_stat, Parts.HOST)
	return maxf(t, 0.01)


## Where the ride has got to now, in floors (2.5 is half way from the first floor to the attic); `stop` while it
## stands or its hatch shuts.
func position_now() -> float:
	if phase != Phase.RIDING or bound < 0:
		return float(stop)
	var dir := signf(float(bound - from))
	var remaining := absf(float(bound - from)) - progress
	if time_left <= 0.0 or remaining <= 0.0:
		return float(bound)
	return float(bound) - dir * remaining * (left_now() / time_left)


## The height of the car's floor at `at` floors (between two stops, between their heights).
func height_at(at: float) -> float:
	var fl := floors()
	if fl.is_empty():
		return 0.0
	if at <= float(fl[0]):
		return _stops[fl[0]].car_height()
	for i in range(1, fl.size()):
		if at <= float(fl[i]):
			var a := fl[i - 1]
			var b := fl[i]
			return lerpf(_stops[a].car_height(), _stops[b].car_height(), (at - float(a)) / float(b - a))
	return _stops[fl[fl.size() - 1]].car_height()


## The car's inside, in the world, where it is drawn now.
func car_space() -> AABB:
	return box_of(car_box)


# --- The player's clicks -------------------------------------------------------------------------

## A click on `control` by player `by`: a BUTTON calls the car to its floor; a HATCH opens or shuts the hatch the car
## stands behind, else calls it there; a LETTER sends it (riders only, core/157).
func use_control(control: ElevatorControl, by: int) -> void:
	if parts == null:
		return
	var at := control.floor_of()
	match control.kind:
		ElevatorControl.Kind.BUTTON:
			parts.ask(Command.new(CALL, by, id, {"floor": at, "hatch": false}))
		ElevatorControl.Kind.HATCH:
			if stands_at(at):
				parts.ask(Command.new(HATCH, by, id, {"floor": at}))
			else:
				parts.ask(Command.new(CALL, by, id, {"floor": at, "hatch": true}))
		ElevatorControl.Kind.LETTER:
			parts.ask(Command.new(SEND, by, id, {"floor": at}))


# --- The Host ------------------------------------------------------------------------------------

## A Guest's clicks, at most 4 a second; the timers' verbs are the Host's alone.
func accepts() -> Dictionary[StringName, Dictionary]:
	var floor_arg := {"type": TYPE_INT, "min": 0, "max": 3}
	return {
		CALL: {"args": {"floor": floor_arg, "hatch": TYPE_BOOL}, "rate": 4},
		HATCH: {"args": {"floor": floor_arg}, "rate": 4},
		SEND: {"args": {"floor": floor_arg}, "rate": 4},
	}


func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		CALL:
			return _decide_call(cmd, bool(cmd.args.get("hatch", false)))
		SEND:
			if not riders.has(cmd.by):
				return refuse("out")  # a send from a non-rider is refused silently (Q988)
			return _decide_call(cmd, false, false)
		HATCH:
			return _decide_hatch(cmd)
		DEPART:
			return _decide_depart()
		ARRIVE:
			return _decide_arrive()
		OPEN_HATCH:
			var at := int(cmd.args.get("floor", -1))
			if cmd.by != Parts.HOST or not stands_at(at) or hatch_open(at):
				return refuse("already")
			return _with_hatch(grant({"phase": Phase.OPEN}), at, true)
	return refuse("wrong")


## A call to `floor` (the old ER:32-90 and EL:120-148): refused when the floor is wrong, the clicked stop far, the
## Elevator out of order, or the called floor locked; else it opens a shut hatch where it stands (and with `toggle`,
## a click on the hatch, shuts an open one), leaves for the floor (its hatch shutting first), or turns for it.
func _decide_call(cmd: Command, toggle: bool, at_stop := true) -> Dictionary:
	var to := int(cmd.args.get("floor", -1))
	var s: ElevatorStop = stops().get(to)
	if s == null:
		return refuse("wrong")
	if at_stop and not parts.near(cmd.by, s, USE_REACH):
		return refuse("far")
	if is_broken():
		return refuse(BROKEN)
	if is_locked(to):
		return refuse(LOCKED)
	var ev: Dictionary
	if phase == Phase.CLOSING or phase == Phase.RIDING:
		ev = grant({}) if to == bound else _turn(to)
	elif stop == to:
		if phase == Phase.SHUT:
			ev = _with_hatch(grant({"phase": Phase.OPEN}), to, true)
		elif toggle:
			ev = _with_hatch(grant({"phase": Phase.SHUT}), to, false)
		else:
			ev = grant({})  # the button never shuts it (Q2702)
	else:
		ev = grant({"phase": Phase.CLOSING, "bound": to, "from": stop, "progress": 0.0,
				"time_left": tuning.hatch_time if phase == Phase.OPEN and tuning != null else 0.0})
		if phase == Phase.OPEN:
			ev = _with_hatch(ev, stop, false)
	_cargo_called(ev)
	if at_stop:
		ev[AT] = to
		ev[PRESSED] = not toggle
	return ev


## A click on the hatch the car stands behind: it opens or shuts (Q533).
func _decide_hatch(cmd: Command) -> Dictionary:
	var at := int(cmd.args.get("floor", -1))
	var s: ElevatorStop = stops().get(at)
	if s == null:
		return refuse("wrong")
	if not parts.near(cmd.by, s, USE_REACH):
		return refuse("far")
	if is_broken():
		return refuse(BROKEN)
	if is_locked(at):
		return refuse(LOCKED)
	if not stands_at(at):
		return refuse("wrong")
	var opening := phase == Phase.SHUT
	var ev := _with_hatch(grant({"phase": Phase.OPEN if opening else Phase.SHUT}), at, opening)
	ev[AT] = at
	ev[PRESSED] = false
	return ev


## The newest call wins (Q513): bound for `to` from where the ride has got to; a hatch still shutting keeps shutting.
func _turn(to: int) -> Dictionary:
	if phase == Phase.CLOSING:
		return grant({"bound": to})
	var at := position_now()
	var start := floori(at) if float(to) > at else ceili(at)
	var done := absf(at - float(start))
	return grant({"bound": to, "from": start, "progress": done, "time_left": absf(float(to) - at) * floor_seconds()})


## The Host's timer: the hatch is shut; what lies in the car rides (the cargo's patches in the same answer) and the
## car is drawn at the floor it is bound for.
func _decide_depart() -> Dictionary:
	if phase != Phase.CLOSING or bound < 0:
		return refuse("already")
	var ev := grant({"phase": Phase.RIDING, "stop": bound, "from": stop, "progress": 0.0,
			"time_left": absf(float(bound - stop)) * floor_seconds()})
	var s: ElevatorStop = stops().get(stop)
	var delta := Vector3.UP * (height_at(float(bound)) - height_at(float(stop)))
	var box := car_space()
	var sill := s.sill_box() if s != null else AABB()
	var changes: Dictionary = ev["changes"]
	for member in _cargo():
		if member.has_method(&"rides_patch"):
			_merge(changes, member.call(&"rides_patch", box, sill, delta, changes) as Dictionary)
	return ev


## The Host's timer (the old `elevator_arrive`): it stands open at the floor, the hatch there opens, every rider
## climbs out (Q2702).
func _decide_arrive() -> Dictionary:
	if phase != Phase.RIDING:
		return refuse("already")
	var at := bound if bound >= 0 else stop
	return _with_hatch(grant({"phase": Phase.OPEN, "stop": at, "bound": -1, "from": at, "progress": 0.0, "time_left": 0.0,
			"riders": [] as Array[int], "dragged": {}}), at, true)


## `ev` with the hatch of `floor` opening or shutting in it.
func _with_hatch(ev: Dictionary, floor: int, open: bool) -> Dictionary:
	var s: ElevatorStop = stops().get(floor)
	if s != null and s.hatch != null and s.hatch.open != open:
		(ev["changes"] as Dictionary)[s.hatch.id] = {"open": open}
	return ev


## A call wakes what lies in the car (the Cat, core/151): every cargo Part's `called_patch` in the same answer.
func _cargo_called(ev: Dictionary) -> void:
	var changes: Dictionary = ev["changes"]
	for member in _cargo():
		if member.has_method(&"called_patch"):
			_merge(changes, member.call(&"called_patch", car_space(), changes) as Dictionary)


## The Parts of this level whose things ride the car.
func _cargo() -> Array[Node]:
	var out: Array[Node] = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group(CARGO):
		if node != self and (not (node is Part) or (node as Part).parts == parts):
			out.append(node)
	return out


static func _merge(into: Dictionary, patch: Dictionary) -> void:
	for key: Variant in patch:
		var have: Variant = into.get(key)
		if have is Dictionary and patch[key] is Dictionary:
			(have as Dictionary).merge(patch[key] as Dictionary, true)
		else:
			into[key] = patch[key]


## The Host's timers: when the hatch has shut it departs, when the ride is done it arrives.
func _physics_process(delta: float) -> void:
	_since += delta
	if phase == Phase.RIDING and tuning != null:
		_creak_in -= delta
		if _creak_in <= 0.0:
			_creak_in += tuning.creak_every
			_creak()
	if parts == null or not parts.is_bound or not parts.is_host() or _asked:
		return
	if (phase == Phase.CLOSING or phase == Phase.RIDING) and left_now() <= 0.0:
		_asked = true
		var arriving := phase == Phase.RIDING
		parts.ask(Command.new(ARRIVE if arriving else DEPART, Parts.HOST, id, {}))
		if arriving and phase == Phase.OPEN:
			var box := car_space()
			for member in _cargo():
				if member.has_method(&"car_opened"):
					member.call(&"car_opened", box)


## A save and a late Guest keep how far the ride got (Q991): the live seconds left and floors done.
func whole_state() -> Dictionary:
	var d := state()
	if phase == Phase.RIDING and time_left > 0.0:
		var remaining := absf(float(bound - from)) - progress
		d["progress"] = progress + remaining * (1.0 - left_now() / time_left)
	d["time_left"] = left_now()
	return d


func write(patch: Dictionary, now: bool) -> void:
	if patch.has("time_left") or patch.has("phase"):
		_since = 0.0
		_asked = false
	super.write(patch, now)


# --- Every machine: the looks --------------------------------------------------------------------

## The car at its floor, the signs and the letters; a change of phase from an answer departs or arrives (`now`: the
## state arrived whole, so no sound and no signal).
func _show(now: bool) -> void:
	_listen()
	if car != null and stops().has(stop):
		car.global_position.y = _stops[stop].car_height()
	if not now and _was_phase != null:
		var was := int(_was_phase)
		if was != Phase.RIDING and phase == Phase.RIDING:
			_creak_in = tuning.creak_every if tuning != null else 0.7
			departed.emit(from, stop)
		elif was == Phase.RIDING and phase != Phase.RIDING:
			if stops().has(stop):
				Sounds.play_at(BELL, _stops[stop].hatch_spot())
			arrived.emit(stop)
	_was_phase = phase
	_show_signs(now)


func _listen() -> void:
	if _listening or parts == null:
		return
	_listening = true
	parts.applied.connect(_on_applied)
	for s: ElevatorStop in stops().values():
		if s.hatch != null:
			var at := s.floor
			s.hatch.shown.connect(func(_locked: bool, shown_now: bool, _unlocked: bool) -> void:
				if not shown_now:
					hatch_moved.emit(at, s.hatch.open))


## Every applied answer: the signs follow the Upgrades and the floors (Elevator Repair bought, a floor opened); an
## answer to a click sounds the button there; a refusal of this Part is read by the asker.
func _on_applied(ev: Dictionary) -> void:
	_show_signs(false)
	if StringName(ev.get("to", &"")) != id:
		return
	if not ev.get("ok", false):
		var words := String(SAYS.get(String(ev.get("reason", "")), ""))
		if words != "":
			refused.emit(int(ev.get("by", 0)), words)
		return
	var at := int(ev.get(AT, -1))
	if at >= 0 and stops().has(at):
		Sounds.play_at(BUTTON, _stops[at].button_spot())
		if ev.get(PRESSED, false):
			_stops[at].press()


func _show_signs(now: bool) -> void:
	var broken := is_broken()
	for s: ElevatorStop in stops().values():
		s.show_signs(broken, not broken and is_locked(s.floor), now)
	for at: int in _letters:
		var clip := LETTER_LOCKED if not broken and is_locked(at) else (LIT if at == stop else DARK)
		var player := _letters[at].get_node_or_null(^"Looks/AnimationPlayer") as AnimationPlayer
		if player != null and player.has_animation(clip) and player.assigned_animation != clip:
			player.play(clip)
			player.seek(player.get_animation(clip).length, true)


## The creak at the shaft where the ride has got to.
func _creak() -> void:
	if car != null and car.is_inside_tree():
		var at := car.global_position
		at.y = height_at(position_now())
		Sounds.play_at(CREAK, at)


## One letter per stop on the car's side wall, B at the bottom, each showing its floor's glyph.
func _build_letters() -> void:
	if letters == null or not _letters.is_empty():
		return
	var step := tuning.letter_step if tuning != null else 0.12
	var i := 0
	for at in floors():
		var letter := LETTER_SCENE.instantiate() as Node3D
		letter.name = "Letter%s" % ElevatorStop.LETTERS[at].to_upper()
		letter.position = Vector3(0.0, step * float(i + 1), 0.0)
		letters.add_child(letter)
		var control := letter.get_node(^"Control") as ElevatorControl
		control.floor = at
		for l in ElevatorStop.LETTERS:
			var glyph := letter.find_child("glyph_" + l, true, false) as Node3D
			if glyph != null:
				glyph.visible = l == ElevatorStop.LETTERS[at]
		_letters[at] = letter
		i += 1


## The Stages of its level (a Run's whose level holds it), or null: no Run, never out of order or locked.
func _stages() -> Stages:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group(Stages.GROUP):
		var s := node as Stages
		if s != null and (parts == null or s.parts == parts) and s.level() != null and s.level().is_ancestor_of(self):
			return s
	return null


## The Upgrades nearest to it in the tree (its station's in the zoo, the level's in the house), or null.
func _upgrades() -> Upgrades:
	if not is_inside_tree():
		return null
	var best: Upgrades = null
	var best_depth := -1
	for node in get_tree().get_nodes_in_group(Upgrades.GROUP):
		var u := node as Upgrades
		if u == null or (parts != null and u.parts != null and u.parts != parts):
			continue
		var common := _common_depth(u)
		if common > best_depth:
			best_depth = common
			best = u
	return best


## How deep the deepest node holding both this and `other` is.
func _common_depth(other: Node) -> int:
	var node := get_parent()
	while node != null:
		if node.is_ancestor_of(other):
			return node.get_path().get_name_count()
		node = node.get_parent()
	return 0
