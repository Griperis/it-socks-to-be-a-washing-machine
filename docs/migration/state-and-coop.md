# State and co-op

A chapter of the new project's architecture, for the designer to read and decide on.
Draft, 2026-11-19. Binding answers: Q2143-Q2170 in `docs/llm/maintenance/issues/131-scenes-and-resources-plan.md`,
above all Q2147 (state lives on the scene part), Q2159 (design before, walkthrough after) and Q2160
(co-op from the first game code).

Every sketch below is a real file in a throwaway Godot 4.7.1 project
(`scratchpad/chapter-state/proj/`). All of them parse. A headless test there runs a Host, a Guest
and a late Guest in one process over real ENet and passes 19 checks (section 3.9).

A word on words: the glossary says "Guest", never "joiner" or "client". A Guest who arrives after
the game started is called **a late Guest** here.

---

## 1. The idea in ten lines

1. Each thing in the house is a scene. Its abilities are child nodes called **parts**: an `Openable`, a `Carriable`.
2. A part's **state** is a few plain fields under a "State" heading in the inspector. Nothing else is state.
3. Anyone may read a state field. Only the Host's answer writes it.
4. A player who wants a change sends a **Command**: "open this Door". A Command changes nothing by itself.
5. The Host's part **decides**: yes with the new field values, or no with a reason. Deciding writes nothing.
6. The answer goes to every machine, and one generic piece, **Parts**, writes the new values into the part.
7. Then the part **shows** the state: swings the Door, hides the carried Radio. Showing never changes state.
8. A late Guest gets a **snapshot**: every part's state fields, by id. It is the same dictionary on every machine.
9. A save is that same snapshot written to a file. No feature writes save or net code.
10. The Mess (up to 10,000 Socks) is too big for parts. It keeps its own data but takes the same Commands.

### A worked example: a Guest clicks the Door

The house has a Door at `Hall/Door`. Its scene is a `Node3D` root, a `Hinge`, and an `Openable` part.
Two machines play: the Host (player 1) and a Guest (player 7).

**The click.** On the Guest's machine, the crosshair hits the Door and calls `Openable.use(7)`.
`use` builds a Command and hands it to `Parts.ask`:

```
Command  kind = "open", to = "Hall/Door/Openable", args = {"open": true}
```

**What travels to the Host.** The Guest's `Parts` has a relay (set when it joined), so the Command
goes up through `Session._command`. On the wire it is a small array: `["open", "Hall/Door/Openable", {"open": true}]`.
The player id is not sent: the Host reads who sent it from the network, so nobody can act for someone else.

**The Guest's screen right now.** Nothing moved. The Door swings when the Host's answer comes back
(a round trip; see fork (e) on prediction).

**Who decides.** The Host's `Parts.answer` finds the part by id and calls `Openable.decide`.
It checks: is this an "open"? Is the Door locked? Is it already open? Here all is fine, so it returns

```
{"ok": true, "changes": {"Hall/Door/Openable": {"open": true}}, "kind": "open", "by": 7, "to": ...}
```

That dictionary is the **event**. Deciding changed nothing.

**What is written where.** The Host's `Parts.apply(event)` calls `write` on the part, which sets
`open = true` on the Host's `Openable` node. The same field you see ticked in the inspector.
The Host's `Session` then sends the same event to every Guest (`Session._event`), and each Guest's
`Parts.apply` writes `open = true` on its own copy of the node.

**What every machine shows.** After writing, `write` calls the part's `_show(false)`: a tween turns
the Hinge 90 degrees over the swing time. Every machine runs the same tween from the same event.
A sound or the HUD may listen to `Parts.applied`; they show, they never decide.

**If the Host says no.** A locked Door gives `{"ok": false, "reason": "locked"}`. Nothing is written
anywhere; the event still goes out, so the Guest's HUD can say "Locked".

**What a late Guest receives.** When a third player connects, the Host's `Session` sends one
message, `_welcome(snapshot)`:

```
{ "Hall/Cellar/Openable":  {"locked": true,  "open": false},
  "Hall/Door/Openable":    {"locked": false, "open": true},
  "Hall/Radio/Carriable":  {"at": Vector3(inf, inf, inf), "holder": 7, "yaw": 0.0} }
```

(This is the real snapshot printed by the test run, with the Guest's id shortened.) The late
Guest's `Parts.load_snapshot` writes each part's fields and calls `_show(true)`: the Door stands
open at once, with no swing.

**What a save contains.** The same dictionary, plus the Mess's own rows when the Mess exists. Saves
are not in the first core loop (Q2161), but nothing new is needed to write one.

---

## 2. The classes of this slice

Seven classes, each with its code in section 3. Each has to earn its place: "why" is the argument,
"called by" says who may use what. "Replaces" counts today's files with `wc -l` on `main` at 5fd3dbd7;
today's files do far more (15 carried kinds, the Mess, the Lobby, prediction), so the comparison shows
where each job goes, not a promised ratio. Kinds are those of `unify/code-shape.md` section 3, with one
change for shape B: a part is a Component that also holds its state and its rule.

| Class | Kind | Sketch lines | Replaces today (lines) |
|---|---|---|---|
| `Command` | Value | 34 | `command.gd` 119, `command_kind.gd` 149, `command_table.gd` 155 |
| `Part` | Base class (abstract) | 69 | no single class: `Station` 46, the `Carriable` base 68, each feature's encode/decode |
| `Openable` | Component (a part) | 45 | `openable.gd` 231, `room_door.gd` 75, `door_rules.gd` 93, `doors.gd` 178, toggle rules in `house_rules.gd` (372 in all) |
| `OpenFeel` | Def (Resource) | 6 | `Openable.SWING_TIME` |
| `Carriable` | Component (a part) | 50 | `carriable.gd` 68, `carriables.gd` 427, `radio_rules.gd` 161 |
| `Parts` | Service (the generic piece) | 106 | `saves.gd` 462, `command_seam.gd` 21, `command_host.gd` 23, `command_guest.gd` 81, `loopback.gd` 73 |
| `Session` | Service (the one RPC node) | 77 | `session.gd` 602, `join.gd` 78, `packet_guard.gd` 176 |
| `main.gd` | Service (the way in) | 18 | the Lobby's entrance (`lobby.gd` 799, not ported now) |

**`Command`.** Why: a wish must travel between machines, and RPCs carry only plain values, no
Objects (godot-rules M1). Fields: `kind: StringName`, `by: int`, `to: StringName`, `args: Dictionary`.
Called by: a part makes one; `Session` calls `to_wire` on a Guest and `from_wire` on the Host, which
takes `by` from the network, so nobody acts for someone else. What goes: today's kind table
(`CommandKind`, `CommandTable`). A Command names its target part by id, so routing is one lookup.

**`Part`.** Why: Openable and Carriable must be found, saved, sent and written the same way, and one
caller (`Parts`) treats them alike; that is when a base class is earned. Fields: `id: StringName`,
`parts: Parts` (both given by `Parts`). Functions: `decide(cmd) -> Dictionary` (abstract; only
`Parts.answer`, only on the Host), `_show(now)` (only `write`), `left(by)` (only `Parts.left`),
`state_names()` and `state()` (anyone, they read), `write(patch, now)` (only `Parts`), `grant`, `refuse`
(helpers for `decide`).

**`Openable`.** Why: the ability a Door has, and later a Drawer, a lid and a hatch, so it is a part,
not a Door script. A Door scene has **no script of its own**. Inspector: `hinge: Node3D`,
`open_degrees: float` (a number of one placed thing, Q2164), `feel: OpenFeel`. State: `open: bool`,
`locked: bool`. `use(by)` is called by the crosshair's click (the test calls it here).

**`OpenFeel`.** Why: Q2164, numbers are typed Resources per feature. The swing time is shared by every
Openable, so it lives in one `.tres` under `data/`. Its 0.35 s is today's `SWING_TIME`, not a new number.

**`Carriable`.** Why: the slice needs one carried thing (Q2160); the Radio is the natural one.
State: `holder: int` (0 is nobody), `at: Vector3`, `yaw: float`. `pick(by)` and `drop(by, where, turn)`
are called by the Hands' input. A pick is refused "gone" when someone holds it and "full" when the
asker carries something; only the holder drops. `left(by)` lets go when its holder leaves (glossary,
Carrying the Radio). `at` starts as `INF`, "where it stands in the scene", so the author places the
Radio by moving it in the editor and never types a position twice.

**`Parts`.** Why: Q2147 asks for one generic piece for saves, late join and sync. This is it, and it
names no feature. Inspector: `level: Node`. Field `relay: Callable` (set by `Session` on a Guest).
Signal `applied(ev)`. Called by: `bind` once at `_ready`; `of`, `find`, `is_host`, `snapshot` anyone;
`ask` by parts; `answer` only on the Host; `apply` on the Host after answering and on a Guest when an
event arrives (the only place state changes while playing); `left` by the Host's `Session`;
`load_snapshot` by a Guest's `Session`, or a save being loaded.

**`Session`.** Why: some node must hold the RPCs, and one node keeps Godot's RPC checksum and
NodePath rules small (today's Q1530 reasoning, still right). Inspector: `parts`. `host(port)`,
`join(address, port)`, `me()`. RPCs: `_command` (a Guest to the Host), `_event` (the Host to all),
`_welcome` (the Host to a late Guest).

**The plain way to host and join (`main.gd`).** No Lobby yet (Q2161). `main.gd` reads the command
line: `-- --host` opens, `-- --join=127.0.0.1` joins, nothing plays alone. Tests call `Session.host`
and `Session.join` directly. In the editor, "Customize Run Instances" can start two windows with
these arguments (from memory).

**Stable ids.** A part's id is its node path from the level: `Hall/Door/Openable`. No typing, no tool.
It is the same on every machine because every machine loads the same scene, and Godot keeps sibling
names unique, so ids never clash. The cost: renaming or moving a Door changes its id, which breaks
old saves. Saves are not in the first loop, so this is fork (d).

**Prediction on the Guest: left out on purpose.** Today a Guest predicts picks, drops, wheels, throws
and the pairing machine (`.predicted(...)` in `hands_rules.gd` and `pairing.gd`): `command_guest.gd`
(81 lines) plus 123 lines of `predict_*` and `settle_*`. Doors and the Radio are **not** predicted
today either. So the slice has none: a Guest's click shows after one round trip. Fork (e).

---

## 3. The code

All files parse with `Godot_v4.7.1 --headless --check-only` (a deliberately broken file was shown to
fail the same check). Paths are as they would be in the new repository. Here one blank line
separates functions to save room; the files keep the style guide's two.

### 3.1 `game/core/command.gd`

```gdscript
## A player's wish to change one thing ("open the Door Hall/Door/Openable"). It goes to the Host,
## who answers it; nothing changes until the answer comes back.
class_name Command
extends RefCounted

## What is asked: a verb the target part knows (&"open", &"pick", &"drop").
var kind: StringName
## Who asks: their peer id (the Host is 1). On the Host it is the sender's, never read off the wire.
var by: int
## The id of the part asked (Part.id).
var to: StringName
## Plain values only: bool, int, float, String, Vector3.
var args: Dictionary

func _init(p_kind: StringName, p_by: int, p_to: StringName, p_args: Dictionary = {}) -> void:
	kind = p_kind
	by = p_by
	to = p_to
	args = p_args

## What travels up to the Host. `by` is left out: the Host knows who sent it.
func to_wire() -> Array:
	return [String(kind), String(to), args]

## The Host's reading of a Guest's wire form, or null when it is malformed.
static func from_wire(wire: Variant, sender: int) -> Command:
	if not (wire is Array) or wire.size() != 3:
		return null
	if not (wire[0] is String and wire[1] is String and wire[2] is Dictionary):
		return null
	return Command.new(StringName(wire[0]), sender, StringName(wire[1]), wire[2])
```

### 3.2 `game/core/part.gd`

```gdscript
## One ability of a thing in the house (can be opened, can be carried), with its state.
## State is every field under `@export_group("State")`: the inspector shows it, the save and a
## joining Guest receive it, and only the Host's answer (Parts.apply) writes it.
@abstract
class_name Part
extends Node

const STATE_GROUP := "State"

## This part's name on the wire and in the save: its path from the level ("Hall/Door/Openable").
var id: StringName
## The level's Parts, which asks the Host for this part. Given by Parts.bind().
var parts: Parts

## The Host's answer to `cmd`. Reads, never writes: returns grant(...) or refuse(...).
@abstract func decide(cmd: Command) -> Dictionary

## Looks only: make the nodes show the state. `now`: it arrived whole (bind, join), so no swing.
func _show(_now: bool) -> void:
	pass

## The Host: what player `by` leaving does to this part. Nothing by default.
func left(_by: int) -> Dictionary:
	return {}

## The names of the state fields, read from the "State" group of the inspector.
func state_names() -> PackedStringArray:
	var names := PackedStringArray()
	var inside := false
	for p: Dictionary in get_property_list():
		if p["usage"] & PROPERTY_USAGE_GROUP:
			inside = p["name"] == STATE_GROUP
		elif inside and p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(p["name"])
	return names

## The state as plain values, by field name.
func state() -> Dictionary:
	var d := {}
	for n in state_names():
		d[n] = get(n)
	return d

## The one writer of state. Called only by Parts: with the Host's answer, or a whole snapshot.
func write(patch: Dictionary, now: bool) -> void:
	var names := state_names()
	for key: String in patch:
		if key in names:
			set(key, patch[key])
		else:
			push_error("%s has no state field %s" % [id, key])
	_show(now)

## A yes: these fields of this part take these values on every machine.
func grant(patch: Dictionary) -> Dictionary:
	return {"ok": true, "changes": {id: patch}}

## A no, and why ("locked", "gone", "full", "wrong").
func refuse(why: String) -> Dictionary:
	return {"ok": false, "reason": why}
```

Why `changes` is keyed by id, not just a patch for this part: later rules change two things at once
(a Sock pick changes the Mess and the player's Hands). One event can then carry both.

### 3.3 `game/house/openable.gd` and `game/house/open_feel.gd`

```gdscript
## The ability to be opened and shut: a room Door (later a Drawer, a lid). Put it on a thing's
## scene and point `hinge` at the piece that swings.
class_name Openable
extends Part

## The piece that turns about its own up axis.
@export var hinge: Node3D
## How far it turns when open, in degrees. A number of this one placed thing.
@export var open_degrees := 90.0
## Shared feel of every Openable (swing time). A typed Resource edited in the inspector.
@export var feel: OpenFeel

@export_group("State")
## Open or shut. Tick it to place the Door open at New Game; while playing only the Host's answer
## changes it.
@export var open := false
## A locked one refuses to open.
@export var locked := false
@export_group("")

## A player clicked it: ask to turn it the other way.
func use(by: int) -> void:
	parts.ask(Command.new(&"open", by, id, {"open": not open}))

func decide(cmd: Command) -> Dictionary:
	if cmd.kind != &"open":
		return refuse("wrong")
	if locked:
		return refuse("locked")
	var to := bool(cmd.args.get("open", not open))
	if to == open:
		return refuse("already")
	return grant({"open": to})

func _show(now: bool) -> void:
	if hinge == null:
		return
	var yaw := deg_to_rad(open_degrees) if open else 0.0
	if now or feel == null:
		hinge.rotation.y = yaw
	else:
		create_tween().tween_property(hinge, "rotation:y", yaw, feel.swing_time)
```

```gdscript
## How every Openable feels: one .tres in data/, edited in the inspector.
class_name OpenFeel
extends Resource

## Seconds one swing takes (today's Openable.SWING_TIME).
@export_range(0.05, 2.0, 0.05, "suffix:s") var swing_time := 0.35
```

The Door scene (`door.tscn`): `Door` (Node3D, no script), `Hinge` (Node3D), `Openable` (this script,
`hinge = ../Hinge`, `feel = data/open_feel.tres`). In the level, the Cellar Door is the same scene
with `locked` ticked on its Openable.

### 3.4 `game/house/carriable.gd`

```gdscript
## The ability to be picked up, carried and put down (the Radio first). A player carries one
## thing at a time. Put it on the thing's scene, as a child of the root that moves.
class_name Carriable
extends Part

@export_group("State")
## Who holds it: a player's id, or 0 when it lies at `at`.
@export var holder := 0
## Where it lies. INF means "where it stands in the scene", so placing it in the editor is enough.
@export var at := Vector3.INF
## Its turn about the up axis where it lies, in radians.
@export var yaw := 0.0
@export_group("")

func pick(by: int) -> void:
	parts.ask(Command.new(&"pick", by, id))

func drop(by: int, where: Vector3, turn: float) -> void:
	parts.ask(Command.new(&"drop", by, id, {"at": where, "yaw": turn}))

func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		&"pick":
			if holder != 0:
				return refuse("gone")
			if parts.find(func(p: Part) -> bool: return p is Carriable and p.holder == cmd.by):
				return refuse("full")
			return grant({"holder": cmd.by})
		&"drop":
			var where: Variant = cmd.args.get("at")
			if holder != cmd.by or not where is Vector3:
				return refuse("wrong")
			return grant({"holder": 0, "at": where, "yaw": float(cmd.args.get("yaw", 0.0))})
	return refuse("wrong")

## A player who leaves holding it lets it go where it last lay (no avatar in this slice).
func left(by: int) -> Dictionary:
	return grant({"holder": 0}) if holder == by else {}

func _show(_now: bool) -> void:
	var thing := get_parent() as Node3D
	thing.visible = holder == 0
	if at.is_finite():
		thing.position = at
		thing.rotation.y = yaw
```

Not in the slice and needed later: the Host checking that a drop point is within reach, and showing
the held Radio in the holder's hands (that needs the avatar).

### 3.5 `game/core/parts.gd`

```gdscript
## Every Part of one level, by id: the one generic piece behind sync, a joining Guest and saves.
## On the Host it answers Commands and applies the answers; on a Guest it sends Commands up
## (`relay`) and applies the answers that come down. No feature has save or net code of its own.
class_name Parts
extends Node

## An answer was applied here (granted or refused). The Host's Session sends it on to the Guests;
## sounds and the HUD may listen. Never decide anything in a handler of it.
signal applied(ev: Dictionary)

## The level whose Parts these are.
@export var level: Node

## A Guest's way up to the Host (Session sets it). Empty on the Host and when playing alone.
var relay: Callable
var _by_id: Dictionary[StringName, Part] = {}

func _ready() -> void:
	bind(level)

## Finds every Part under `root`, names it by its path and shows its starting state.
func bind(root: Node) -> void:
	_by_id.clear()
	for part in _walk(root, []):
		part.id = StringName(String(root.get_path_to(part)))
		part.parts = self
		_by_id[part.id] = part
		part._show(true)

## The part with this id, or null.
func of(id: StringName) -> Part:
	return _by_id.get(id)

## The first part for which `test` says true, or null (Carriable asks "what does player 2 hold").
func find(test: Callable) -> Part:
	for part: Part in _by_id.values():
		if test.call(part):
			return part
	return null

## Whether this machine decides (the Host, or alone).
func is_host() -> bool:
	return not relay.is_valid()

## A player asks for a change. The Host answers it here; a Guest sends it up and waits.
func ask(cmd: Command) -> void:
	if relay.is_valid():
		relay.call(cmd)
	else:
		apply(answer(cmd))

## The Host's answer to `cmd`. Changes nothing.
func answer(cmd: Command) -> Dictionary:
	var part := of(cmd.to)
	var ev := part.decide(cmd) if part != null else {"ok": false, "reason": "wrong"}
	ev.merge({"kind": cmd.kind, "by": cmd.by, "to": cmd.to})
	return ev

## Every machine: the only place state changes while playing.
func apply(ev: Dictionary) -> void:
	if ev.get("ok", false):
		var changes: Dictionary = ev["changes"]
		for id: StringName in changes:
			of(id).write(changes[id], false)
	applied.emit(ev)

## The Host: player `by` left; each part says what that does to it (a carried thing drops).
func left(by: int) -> void:
	for part: Part in _by_id.values():
		var ev := part.left(by)
		if not ev.is_empty():
			ev.merge({"kind": &"left", "by": by, "to": part.id})
			apply(ev)

## Every part's state by id: what a joining Guest receives and what a save keeps.
func snapshot() -> Dictionary:
	var d := {}
	for id: StringName in _by_id:
		d[id] = _by_id[id].state()
	return d

## A Guest joining, or a save loaded: every part takes its state whole.
func load_snapshot(snap: Dictionary) -> void:
	for id: StringName in snap:
		var part := of(id)
		if part != null:
			part.write(snap[id], true)

func _walk(node: Node, into: Array[Part]) -> Array[Part]:
	if node is Part:
		into.append(node)
	for child in node.get_children():
		_walk(child, into)
	return into
```

### 3.6 `game/core/session.gd`

```gdscript
## The co-op link of one machine: the only node with RPCs. The Host opens it; a Guest joins it by
## address. Commands go up, the Host's answers come down, and a joining Guest gets a snapshot.
class_name Session
extends Node

## A Guest has the Host's snapshot and is in the game.
signal welcomed

const PORT := 24565
const MAX_GUESTS := 3

## The level's Parts.
@export var parts: Parts

## Opens the game for Guests on `port`.
func host(port: int = PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_GUESTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_joined)
	multiplayer.peer_disconnected.connect(parts.left)
	parts.applied.connect(_on_applied)
	return OK

## Joins the Host at `address`. From now on this machine's Commands go up to the Host.
func join(address: String, port: int = PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	parts.relay = _send_up
	return OK

## This player's id: 1 on the Host, the peer id on a Guest.
func me() -> int:
	return multiplayer.get_unique_id()

func _send_up(cmd: Command) -> void:
	_command.rpc_id(1, cmd.to_wire())

## The Host: a Guest's Command, answered for the Guest who sent it.
@rpc("any_peer", "call_remote", "reliable")
func _command(wire: Array) -> void:
	if not multiplayer.is_server():
		return
	var cmd := Command.from_wire(wire, multiplayer.get_remote_sender_id())
	if cmd != null:
		parts.apply(parts.answer(cmd))

## A Guest: the Host's answer.
@rpc("authority", "call_remote", "reliable")
func _event(ev: Dictionary) -> void:
	parts.apply(ev)

## A Guest who just joined: the whole state.
@rpc("authority", "call_remote", "reliable")
func _welcome(snap: Dictionary) -> void:
	parts.load_snapshot(snap)
	welcomed.emit()

func _on_joined(peer: int) -> void:
	_welcome.rpc_id(peer, parts.snapshot())

func _on_applied(ev: Dictionary) -> void:
	_event.rpc(ev)
```

The 4 player limit is today's (ADR-0006), so `MAX_GUESTS` is 3; the port number is a placeholder.

### 3.7 `game/main.gd`

Eighteen lines: for each of `OS.get_cmdline_user_args()`, `--host` calls `session.host()` and
`--join=<address>` calls `session.join(address)`; a failure is a `push_error` with `error_string(err)`.
The file is in the scratch project and parses.

### 3.8 How a test sets up three machines

`tests/slice_test.gd` (114 lines, in the scratch project) builds each machine as its own subtree:
a `Node`, then `SceneTree.set_multiplayer(SceneMultiplayer.new(), machine_path)`, then the level,
`Parts` and `Session` as children. That is the same trick today's `tests/net_helpers.gd:79` uses.
In the new project it becomes a helper of the runner (`tools/run.sh` style, one verdict line).

### 3.9 What the headless run proved

Command: `Godot_v4.7.1 --headless --script res://tests/slice_test.gd`. Output: `PASS 19 checks, 0 failed`,
no engine errors or warnings. In order, it showed:

1. The Host listens on a localhost port; a Guest joins over real ENet and is welcomed.
2. The Cellar Door's `locked`, ticked in `level.tscn` on an instanced Door, is in the state.
3. The Guest clicks the Door: before the answer its own Door is still shut; then it opens on the Guest and the Host.
4. The Guest picks the Radio: both machines show the Guest as holder.
5. The Guest clicks the locked Cellar Door: the Guest receives a refusal "locked".
6. A late Guest joins: it sees the Door open, the Radio's holder, and the Hinge already at 90 degrees (no swing).
7. The late Guest tries to pick the held Radio: the Host keeps it with the first Guest.
8. All three snapshots are equal.
9. The first Guest disconnects holding the Radio: the Host lets go of it and the late Guest sees it.

It also proved two Godot points: `@abstract` on a class and a function parses and runs in 4.7.1, and
`get_property_list()` reports `@export_group("State")` as a group entry followed by its fields (the
snapshot holds exactly `open`, `locked`, `holder`, `at`, `yaw`, and none of `hinge`, `feel`, `open_degrees`).

Separately, `main.tscn` was started as two processes (`-- --host` and `-- --join=127.0.0.1`) for a few
hundred frames each: both exited cleanly with no errors. Their state was not inspected.

---

## 4. The forks

Each fork lists my recommendation first.

### (a) Who carries part state over the network

1. **Our own RPCs and the generic snapshot (the sketch).** Costs: about 180 lines (`Parts` + `Session`) we own and test. Gives: one path for sync, late join and saves; refusals and first-come-wins come free; the Mess can use the same path; tests run three machines in one process.
2. **`MultiplayerSynchronizer` per part**, with the state fields in its replication config (mode "On change", spawn flag). Costs: a synchronizer node and config resource per thing; Guests' clicks still need our own RPC to reach the Host; a late Guest is not promised On-change values of things that were placed in the scene rather than spawned (from the 4.7 docs fetched in `netcode.md` 1.4-1.5 and a secondary source; not tested here); saves still need our own walk. Gives: the engine's network profiler sees it; visibility filters per peer.
3. **Mix**: our Commands up, Synchronizers down. Costs: two systems for one job. Gives: little over 1 for a co-op game of 4.

The local 4.7.1 class reference (dumped with `--doctool`) confirms the API surface: `MultiplayerSynchronizer` has `replication_config`, `root_path`, `replication_interval`, `delta_interval`, visibility filters; `SceneReplicationConfig` has modes `NEVER`, `ALWAYS`, `ON_CHANGE` and a spawn flag. The dump has no descriptions, so behaviour claims are not from it.

### (b) How a field is marked as state

1. **An `@export_group("State")` heading (the sketch).** Costs: a field put outside the heading silently stops syncing (the "all machines agree" check after every test case catches it once a test changes that field). Gives: the inspector shows a "State" section; nothing to keep in step; proven by run.
2. **An explicit list per part** (`const STATE := [&"open", &"locked"]`). Costs: one more line per part and two places to edit. Gives: the list is plain to read and grep.
3. **A custom property list or naming prefix** (`_get_property_list` with a usage flag, or `s_open`). Costs: more code per part or ugly names. Gives: control over storage-only state that the inspector hides.

### (c) Where a part's rule lives

1. **On the part script (the sketch)**, for rules about that one thing. Costs: looks and rules share a file; a slip like `open = true` in `_show` is one line away. Gives: one file per ability, the inspector field and its rule side by side.
2. **A separate rules script per part** (`OpenableRules`, plain data in, answer out). Costs: two files per ability. Gives: rules testable without nodes.
3. **A per-feature System node** (`Doors` deciding for all Doors). Costs: the shape A pattern back for every feature. Gives: one place for rules across many things.

Whatever the choice, rules that span things (a Sock shelved into a Drawer, paid in Coins, moving the
Stage) will need a System-like home; the event's `changes` by id is ready for that.

### (d) Stable ids of placed things

1. **Derived from the node path (the sketch), for now.** Costs: renaming or moving a thing changes its id, which breaks saves; a committed id list in a test makes such a change visible. Gives: zero typing, never a duplicate, works today.
2. **Typed by hand on each thing** (`@export var id`). Costs: hundreds of ids to type; the part is a child of an instanced scene, so editing it needs "Editable Children" or a script on every root. Gives: ids that survive any rename.
3. **Assigned by an editor tool** (a plugin that fills a missing id when a scene is saved). Costs: a plugin to write and keep; ids are unreadable codes. Gives: rename-proof ids with no typing.

Since saves are not in the first loop, 1 now and 3 when saves arrive is cheap: the id is one
StringName made in one line of `Parts.bind`.

### (e) Guest prediction

1. **Later (the sketch).** Costs: a Guest's click shows after one round trip (small on a LAN, noticeable at 100 ms). Gives: half the moving parts; Doors and the Radio are not predicted today either.
2. **Now, for picks and drops.** Costs: a guess, an undo and a reconcile per kind (today about 200 lines). Gives: instant hands for the Guest.
3. **Never.** Costs: the Guest's Throws and picks always lag. Gives: the simplest code.

The shape has room for 2: `Part.write` can show a guess, and the Host's event either confirms it or
writes the true values over it.

### (f) How the Mess joins the Command path

1. **The Mess registers with `Parts` under the id `mess`**, answers Commands, and offers its own `snapshot`, `load_snapshot` and a `write` for its rows. Moving Socks keep their own unreliable stream (ADR-0008). Costs: `Parts` needs a small interface for "a big part" beside `Part`. Gives: one event shape; a Sock pick can change the Mess and the Hands in one event.
2. **A separate Command path for the Mess.** Costs: two routes, two snapshot formats, two sets of tests. Gives: no change to `Parts`.
3. **Every Sock a Part.** Rejected: 10,000 nodes, against ADR-0008.

---

## 5. Questions for the designer

For the dialog: at most four options each, the recommended one first.

1. **Network.** How should a Door's state get to the other players? (a) Our own messages and one snapshot (recommended) (b) Godot's MultiplayerSynchronizer on each thing (c) Ours up to the Host, Godot's back down
2. **Marking state.** How does a part say which fields are its state? (a) A "State" heading in the inspector (recommended) (b) A written list at the top of each part (c) A name prefix or custom code per part
3. **Where a rule lives.** Where is the rule "a locked Door won't open" written? (a) In the part's own script, beside its fields (recommended) (b) In a separate rules file next to each part (c) In one script per feature that decides for all its things
4. **Ids.** How does each placed thing get its name for saves and the network? (a) From where it sits in the house now, an editor tool when saves come (recommended) (b) From where it sits in the house, always (c) Typed by hand on each thing (d) Filled in by an editor tool from the start
5. **Prediction.** Should a Guest's click show before the Host answers? (a) Later, once the core loop runs (recommended) (b) Now, for picking up and putting down (c) Never
6. **The Mess.** How do Socks take Commands? (a) Through the same path, under one id "mess", with their own data (recommended) (b) Through a path of their own
7. **Inheritance.** How deep may classes inherit? (a) One step: Part, then Openable; nothing under Openable (recommended) (b) Two steps, so a Drawer can extend Openable
8. **One class per file.** May a file hold more than one class? (a) No: one class, one file, named alike (recommended) (b) Small helper classes may sit inside a file
9. **Things without a script.** May a thing like the Door be a scene with no script of its own, only parts? (a) Yes, a thing gets a script only when no part can do the job (recommended) (b) No, every thing's root gets a small script
10. **Who writes state.** How strictly is "only the Host's answer writes state" kept? (a) A test-suite check: no part script assigns its own state, and all machines must agree after every test (recommended) (b) That, plus a guard in the game that stops any other write while playing (c) Code review only

---

## 6. Verified / read in the code / judged / not verified

**Verified by run** (Godot 4.7.1 headless, in the scratch project):
- All eight sketch files parse (`--check-only`; a broken file fails the same check).
- `@abstract` on a class and on a function without a body parses and runs.
- `get_property_list()` gives `@export_group("State")` as a group entry, and `@export_group("")` ends it.
- `set(name, value)` and `get(name)` on those fields round-trip, including `Vector3(inf, inf, inf)`.
- `Dictionary[StringName, Part]` (typed dictionary) works.
- Three machines in one process with `SceneTree.set_multiplayer(SceneMultiplayer.new(), path)` per subtree, over real ENet on localhost: a Guest's Command reaches the Host, the field changes on both, a refusal reaches the Guest, a late Guest gets the current state, a first-come pick holds, all snapshots agree, and a leaving Guest's carried thing is let go. 19 checks, 0 failed.
- The snapshot and events (StringName ids, Vector3 values, including INF) cross an RPC and are used correctly on arrival.
- `multiplayer.get_remote_sender_id()` inside an `any_peer` RPC gives the Guest's id.
- An instanced scene's child property (`locked` on `Hall/Cellar/Openable`) overridden in the level's `.tscn` loads.
- `main.tscn` started as a host process and a join process: no errors (state not inspected).

**Verified by local docs** (`--doctool` dump of 4.7.1; signatures and defaults only, no descriptions):
- `MultiplayerSynchronizer` members, `SceneReplicationConfig` modes and spawn flag, `MultiplayerSpawner` members, `SceneMultiplayer` members, `SceneTree.set_multiplayer(api, root_path)`.
- Godot 4.7.1 `Node` has no built-in unique node id (only `unique_name_in_owner`), so stable ids are ours to make.

**From memory or earlier fetched docs** (not checked today):
- Late-join behaviour of `MultiplayerSynchronizer` "On change" for placed (not spawned) nodes: from `netcode.md` 1.4-1.5 (fetched docs plus a secondary source).
- The editor's "Customize Run Instances" dialog for starting a Host and a Guest window.
- That an "Editable Children" step is needed to edit a part inside an instanced scene in the editor.

**Read in the code** (`main` at 5fd3dbd7): today's command flow (`Game.run`, `Game.take_command`, `CommandKind`, `CommandTable`, `CommandGuest`), `DoorRules`, `Openable`, `Carriable`, `Saves.to_dict`/`snapshot`/`load_snapshot`, `Session._command`/`_event`/`_welcome`, `tests/net_helpers.gd`; which kinds predict today (`.predicted(...)`: picks, wheel, drop, throw, pairing; not Doors, not the Radio). All line counts are `wc -l`.

**Judged** (my reasoning, not tested):
- That a welcome is always sent before any event reaches a new Guest (same reliable channel, sent at connect).
- The rough "replaces" mapping in section 2; today's files do much more than the slice.
- That `changes` keyed by id is enough for rules across things, and that the Mess fits as "a big part".
- That deriving ids from paths is safe until saves exist.

**Not verified / known gaps in the sketch:**
- `holder` holds a network peer id (a large random number). That is fine for one session; a save needs stable player ids (today `Session.player_at`), and must lay down what Guests hold (today's rule: nothing is held offline, Q295).
- Both machines must run the same build, or ids and RPCs will not match; today's protocol check is not in the slice.
- No reach check on a drop, no rate limit on Commands (godot-rules M5).
- Not tested with physics, Jolt, the avatar, the crosshair or a real scene from the ported props.
- Not measured: bandwidth, latency, or a snapshot of a whole house.

