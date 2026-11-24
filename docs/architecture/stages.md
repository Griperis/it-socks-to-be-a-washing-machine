# Stages and floors

**Status: proposal (core/71), waiting for the designer.** Behaviour list: `docs/migration/m4-lists/03-stages-and-floors.md`.
The choices S1-S7 are core/71's Open follow-ups; each line below that depends on one says so and is written for its
recommended answer. Batch A (Q2606, Q2614): built unattended once approved, reviewed in play as a whole (Q2603, Q2605).

## What it owns

The run's floor-by-floor frame: the four Stages (basement, ground, first, attic; the Drum's fifth is batch D, Q2615),
which Cabinets are unlocked and how many Rows each has, the Stage's bar and its completion, a Stage's Socks, the
washing machine's Parts as things (pop, carry, put down, hand over, fit), the floors' locks and their opening, the
Cabinets' growth, the Stage bar on the HUD, the run's tallies with the Whiteboard and the Tab overlay, and what of all
that a World keeps. It does not own the washing machine or its Fix scene, mood, voice and spit (core/73), the First
wash, the Laundry day or the Final screen (core/72), Coins and Drawers as currencies, Stage presents, Collections
unlocking or the Profile's Lifetime tallies (batch B), or the Elevator (batch C). Where those meet it, it names the seam.

## The shape

One `Run` scene per level that has a run (`game/run/run.tscn`, instanced once by the house as `Run`, beside `Runtime`;
the zoo's Stages station has its own). It holds:

- **`Stages`** (`game/run/stages.gd`, a Part: the run's decided state, Host authoritative, saved and in the join
  snapshot because its State group is, `docs/architecture/saves.md`). It reads the level's `StagePlan` and the placed
  Cabinets, Locks, Machine Parts and generators by group, never by path.
- **`RunTallies`** (`game/run/run_tallies.gd`, a Part): per player this run's Pairs shelved, Pairs made, Socks picked and
  Coins earned (the Whiteboard's and Tab's three, and the Final screen's, core/72).
- **`StageSpawner`** (`game/run/stage_spawner.gd`, a Node, Host only): lays a Stage's Socks a slice per frame and asks
  `land` with them.

Everything else is a view of `Stages`' state or a placed thing with its own small Part: the Cabinets (exist), the
Machine Parts (`Carriable`, exists unused), the floor locks (`Openable` leaves, exist as the Door entity). Inheritance
stays one step (Q2251): nothing extends `Openable` or `Carriable`; the washer's Part is named `MachinePart` in code so it
never reads as the scene-parts `Part`.

### `Stages`' state: one phase instead of five counters

| Field | Meaning |
|---|---|
| `stage: int` | the current Stage (0 = the basement's) |
| `phase: int` | `PLAYING` (the bar counts), `PART_OUT` (complete; its Part lies or is carried), `FIXING` (the Part is in the machine; its Fix scene plays), `FIXED` (the last Part's Fix is over: the Laundry day's, core/72) |
| `bar: Array` | the Rows the Stage counts: `[cabinet id, drawer]` each, fixed when the Stage begins |
| `spawned: PackedInt32Array` | every Design spawned this run (each spawns once) |
| `due: PackedInt32Array` | the Designs of a spawn not landed yet (laid again after a load) |
| `first_laid: bool` | Stage 1's Socks have landed (with the First wash they wait for its spit) |
| `pairs_per_drawer: int` | this World's Drawer size (25; the debug slider, Q668) |

This replaces the old `stage`, `door_due`, `earned`, `fixes`, `fixed`, `fit_pending()` and `stage_open()` (weak point
1). Derived, never stored: a floor is open when its Stage index `<= stage` and (it is Stage 1, or `phase` is past
`FIXING` for the Stage before); the machine's anger is the Parts not fitted (core/73 reads `fitted_count()`); the
Elevator's stops (batch C) read `floor_open(floor)`.

### Its verbs (`Parts.ask`, decided on the Host)

| Verb | Who | What it decides |
|---|---|---|
| `start` | Host, at a New Game | Stage 1: every Cabinet's lock and Rows (`Cabinet.lock_patch`: Stage 1's unlocked at `start_rows`, the rest locked showing `start_rows`), the bar, `pairs_per_drawer` from the launch |
| `complete` | Host, after any applied answer that shelved (it listens to `Parts.applied`) | when `phase == PLAYING` and every bar Row is full: `phase = PART_OUT`, the Stage's Machine Part `{holder 0, at: the pop spot}` (in front of the Cabinet that took the last Pair, `ahead` m out, on the floor: one ray) |
| `fit` | the player carrying the Part, through the `MachinePartSlot` on the washer | the asker holds this Stage's Part and the washer is not busy (the slot's `busy` seam, core/73; refused "The washing machine is busy"): the Part is put away (`holder 0`, hidden), `phase = FIXING` |
| `open_floor` | Host: the washer at its Fix scene's fade (core/73), or the slot at once when its `waits_for_scene` is off (the zoo, tests, no washer) | the next Stage: `stage + 1`, `phase = PLAYING`, every unlocked Cabinet `+rows_per_stage` Rows to its full height, the new Stage's Cabinets unlocked at `start_rows`, the new bar, the floor's lock Openables `{open true, locked false}`, the new Stage's Designs into `due` and `spawned`. On the last Stage instead `phase = FIXED` |
| `lay_first` | Host: the First wash at its spit (core/72), or the run at a New Game's start when the level's `Run.first_waits_for_wash` is off | Stage 1's Designs into `due` |
| `land` | Host: the StageSpawner | the laid records join the Mess (`added_lying_patch`), their Designs leave `due`, `first_laid` |
| `zoo_complete`, `zoo_fit_now` | Host, the zoo station's switches only | complete the Stage outright; fit and open at once |

A load between `FIXING` and `open_floor` (the Fix scene cut short) opens the floor in the run's `loaded()`, as the old
`step()` did. A load with `due` not empty lays those Designs again (old `redo_due`: the ones now held, lying or shelved
are dropped from the list).

### Signals (every machine, from applied answers): the seams

| Signal | Who plugs in |
|---|---|
| `run_started` | core/72: the First wash begins (it asks `lay_first` at its spit) |
| `stage_completed(stage, cabinet)` | core/73: the washer's line; batch B: Stage presents (Q2612), the Lifetime "Floors" tally |
| `part_fitted(stage)` | core/73: the Fix scene at the new mood, the respawn by the washer, the spit (Q1937-Q1940); it asks `open_floor` at the fade, so the new Socks land under its black |
| `floor_opened(stage, grown)` | the views here: locks, lamps, sheets, Drawer drops, the bar's reset; batch C: the Elevator |
| `machine_fixed` | core/72: the Laundry day begins; the Stage bar steps aside for core/72's bins counter |

The washer is core/73's entity; core/71 owns only the `MachinePartSlot` Part placed on it (the `fit` verb, `busy` and
`waits_for_scene` exports). Until the washer exists, the house's `Washer` marker carries a slot with
`waits_for_scene` off.

## How it is authored

- **`StagePlan`** (Resource, `game/run/stage_plan.gd`; the house's is `game/run/house_stage_plan.tres`): `stages:
  Array[Stage]`, `start_rows` (2), `rows_per_stage` (1), `high_share` (0.05), `high_spot` (1.7 m), `# placeholder:` until
  the balance round (Q967). A level names its plan on its `Run`.
- **`Stage`** (Resource, `game/run/stage.gd`): `title` ("Basement", "Ground floor", "First floor", "Attic": S6),
  `floor` (the floor index it opens, as `HouseLights.floors` counts them; Stage 1's is open from the start), `pairs`
  (the fewest it spawns: 50, 160, 150, 130 placeholders, Q660), `part: MachinePartKind`. A fifth Stage is a fifth
  entry (the Drum's, batch D): no code change.
- **`MachinePartKind`** (Resource, `game/entities/machine_part/`): `id`, `name` ("New filter"), `looks: PackedScene`.
  One `.tres` per Part (filter, motor, drum belt, detergent; the softener's comes with the Drum).
- **On placed things** (exports, edited on the instance in the house):
  - `Cabinet.unlock_stage` (1-based; the garage's 2, the old `hidden_until`, Q1463). A Cabinet that should stand
    sheeted while locked has a `DustSheet` child, as it does today (assets/07): placed by hand, never guessed from
    where it stands (weak point 3).
  - `FloorLock.floor` (the floor it shuts). The house's three: the ground's door, the first floor's door, the attic's
    gate.
  - `SockGenerator.floor` and `lays_at_start` (off in the house: Stages lays instead; on in the zoo's other stations).
  - `MachinePart.kind` on each of the four Machine Part instances placed (hidden) under `Run/MachineParts`.
- **Numbers** (typed Resources, one per feature): `FloorLockTuning` (pop 0.6 s, swing delay 0.8 s, swing 1.4 s, lamps
  fade 0.6 s and hold 6 s), `CabinetTuning`'s new group "Drawer drop" (delay 0.8 s, time 0.35 s, height 0.8 m, gap
  0.25 s, dust colour `#cbbfa8`, 24 puffs), `MachinePartTuning` (ahead 1.5 m, pop 0.7 s, arc 0.6 m, spin 1 rad/s, bob
  3.5 cm at 2.2 Hz, glow colour), `StageBarTuning` (icon 44 px, overlap 26 px, track 300 x 16 px, reset 0.6 s, fill
  0.35 s), `WhiteboardTuning` (resolution 1024 x 768, overlay 0.8, glow 0.2). All `# placeholder:` the old values.
- **Sounds**: `padlock_pop`, `chain_drop`, `lock_door_open`, `drawer_thunk`, `part_pop`, `part_fit` join
  `sound_catalogue.tres` with the old picks or shares (device_click, oven_close, wardrobe_open, oven_close,
  rubberduck_plop1_pop, rubberduck_v2_lock_open_fit); `cabinet_reveal` is there already.
- **Zoo station** `game/zoo/stations/stages.tscn` (built from data at load, Q2337; its own things under
  `game/zoo/stages/`): the house's `StagePlan` as a row of labels per Stage (title, floor, Pairs, its Part's name) with
  each `MachinePartKind`'s Looks lying beside it (a new Stage or Part shows with no other change); a ground door and a
  gate `FloorLock` with an Open/Lock switch; a Cabinet with a Grow switch; a Whiteboard with a switch that adds a
  sample tally; and a **mini run**, the station's own `Run` with `game/zoo/stages/mini_plan.tres` (two Stages, Pairs per
  Drawer 2): Cabinet A (Stage 1), Cabinet B sheeted (Stage 2), a raised platform behind a `FloorLock` gate (its floor),
  a `SockGenerator` area on each, and a box with a `MachinePartSlot` (no washer: it opens at once). The real-path cases
  of the build tickets run there.

## The pieces

### Rows and Cabinets
`Cabinet` keeps `locked` and `rows` (its State today). New: `unlock_stage`; the Row's capacity is `pairs_per_drawer`
(from `Stages` when the level has a run, else `CabinetTuning.drawer_capacity`), the Collection's last Row only the
Designs left (Simple's sixth: 5); its full height is the Collection's Designs over the Pairs per Drawer, rounded up.
The Cabinet scene holds the most Drawers any Collection needs (Simple: 6) and shows `rows` of them (a locked one
`start_rows`), the rest hidden and out of reach (collision off, Openable locked). Each Collection's Looks gets
Segment1..6 (asset ticket AS2: the old models were a base, a segment, a top and a drawer stacked in code; the port's
Looks contract today is Segment1..3).

The drop: when `rows` grows in an answer (not on a load or a join), each new Drawer module falls in on top with the
old timings, a `drawer_thunk` at its seam and `dust_puff.tscn` (a one-shot particles scene) bursting from it: a Tween
in the Cabinet's `_show` (a one-shot effect, the native default). With S4 (b) the Host holds the drop until a player
sees the Cabinet: the Cabinet's State gains `shown` (Drawers dropped so far); the Host's `DrawerReveal` (in `Run`)
checks each tick, for every Cabinet with `shown < rows`, whether a player stands on its floor with it inside their view
(the Avatar's pose: yaw and pitch, a 70-degree cone, one ray for walls) and asks the Cabinet's Host-only `reveal`. A
Drawer not yet shown takes no Pair; the bar counts it.

### A Stage's Socks
`StageSpawner` (Host) picks up `due`, asks the target floor's generator for records of exactly those Designs
(`SockGenerator.records_for(designs, seed, before)`, a new entry beside `records()`: the same places and laying, the
Designs given instead of dealt from `collections`, no repeats), a slice per frame through `SockLayingJob`, then asks
`land`. The seed is `hash([the World's seed, stage])`. The Designs are chosen by the old rule (behaviour list "A
Stage's Socks", `Stages.stage_designs()`, every machine the same). High spots (Q664): with 2 or more players present
at the spawn, `high_share` of them go to the floor's top places at least `high_spot` over the floor (a filter on the
generator's existing top places); alone none. With S1 (a) all the Stage's Socks go to the floor just opened (its
generator); Stage 1's to the basement's. At a New Game Stage 1 lays behind the loading screen as house/09 does when no
First wash waits; with the First wash, after its spit (core/72).

### Machine Parts
`game/entities/machine_part/machine_part.tscn`: a root Node3D, a `Carriable` (exists), the kind's Looks (`looks_filter`,
`looks_motor`, `looks_drum_belt`, `looks_detergent`: the old glbs imported, AS3), a glow disc and a sparkle
(`GPUParticles3D` scene), and an AnimationPlayer in the Looks with `lying` (the spin and bob, looping). Hidden unless it
is the current Stage's and `phase == PART_OUT`. The pop: a Tween from the Cabinet's top to `at` (hop, arc, bounce, the
old `pop_pose`), `part_pop` at the top, an 18-spark burst on landing. Carried: in empty Hands only ("Hands full"),
held in front at the HoldPoint; right click puts it down where the crosshair is ("Can't drop there") or, aimed at a
Teammate with empty Hands, into theirs (else at their feet, they read "Hands full"). The hover readout names it.

**Shared seam with core/72**: carrying a thing in the Hands (the Laundry bin, B33) is the same `Carriable` plus
`Hands.carries()` (a carried thing fills the Hands; nothing else is picked). The first of core/71's Machine Part
ticket and core/72's bin ticket to be built adds it; the other reuses it. The bin refuses the Hand-off; a Part allows
it: `Carriable.handable` (export).

### The floor locks
`game/run/floor_lock.tscn`: the leaf is the Door entity (`Openable`, `locked` in its State) with its own Looks,
`looks_lock_door.tscn` (the plank door with ledges and a Z brace) or `looks_lock_gate.tscn` (the painted baby gate),
each with the chain and the brass padlock and two animations: `unlock` (the padlock springs off with its spin and
falls, the chain drops and swings, both shrink away: the old tween numbers as keys, `padlock_pop` and `chain_drop` as
method-track sounds) and `open` (a 0.8 s hold, then the 1.4 s sine swing back over the flight). `open_floor`'s answer
writes the leaf's `{open true, locked false}`; its `_show` plays `unlock` then `open` (on a load or a join, the end pose
at once). The gate has a blocker body up to the ceiling, off once open. While locked the leaf shows no prompt and no
outline (a `quiet_when_locked` export on `Openable`); the padlock is its own aim target: outlined, the hint "Please
the washing machine" with no key. A moving leaf sweeps Socks as the room Doors do (it is an Openable). The floor's
lamps: `HouseLights` gains `reveal(floor)` (fade in 0.6 s, lit 6 s, fade 1.2 s back to the day rule) and keeps a
locked floor's lamps off.

### The Stage bar
`game/ui/stage_bar.tscn`, a child of the HUD, hidden in a level with no run: the old panel and layout (behaviour list
"The Stage bar"), on the Theme's `StagePanel` variation. It reads `Stages` (by group) and the bar's Cabinets; it
redraws only on a change. With S5 (a) it stays full while the Part is out; at `machine_fixed` it hides and core/72's
counter takes its place (the old `RIG:636-647`).

### The tallies, the Whiteboard and Tab
`RunTallies`' State: player id -> `{pairs, made, socks, coins}`, written in the same answers that cause them (the
Cabinet's shelve adds `pairs` and `coins` beside its Coins patch; the Hands' pick adds `socks` for a Mess Sock and
`made` when it pairs), so it needs no events of its own; a leaver keeps their row. The board: a script on the
house's `CollectionBoard` instance (`whiteboard.gd`) puts `whiteboard_sheet.tscn` (one Control, the old drawing,
Patrick Hand, Q2331) in a SubViewport on the board's face, redrawn only when a tally changes. The overlay:
`tab_overlay.tscn` on the HUD, the same sheet at 80 % of the screen's height in its grey frame, while
`whiteboard_overlay` is held (Tab, the pad's Select: `python3 kit/tools/input_actions.py add`), never over a menu.

### Saves, joins and the Lobby
Nothing writes save code: `Stages`, `RunTallies`, the Cabinets, the Machine Parts' Carriables and the lock leaves'
Openables are saved and joined by their State groups. `Openable.loaded()` shuts every Openable today: the lock leaves
must keep `open` (a lock leaf's `loaded()` answers nothing: an export `keeps_open_on_load`). The World's row names its
floor: `Autosave` writes `WorldRecord.floor_name` from `Stages.floor_title()` (the current Stage's `title`). The save
tests' `shape.json` and `house_ids.txt` change (`save_test.gd` S11 and S12); no old save needs to load (save compatibility starts at the
first outside play-test). The Pairs per Drawer slider (Q668, Q2586): debug builds only, in the World drawer while "New
game" is chosen and on the Solo New Game page, 1 to 25, each step clearing everyone's Ready (the old rule); the value
rides the launch into `start`.

## What core/58-68's code is reused

As it is: `Parts`, `Command`, the Session and the snapshot, `Save`, `Autosave`, `WorldRecord` (its `floor_name` field
waits for this), `Worlds` (its row line already prints the floor), `SceneChanger` and the loading screen,
`Cabinet` (lock_patch, sheeted, aimable, the refusals), `DustSheet`, `Coins`, `Carriable`, `Openable`, `SockGenerator`
and `SockLayingJob`, `HouseLights`, `UiIcons`, the Theme and `KeycapStyle`, the Lobby's World drawer and Solo New Game
page (the slider's home). Changed: `Cabinet` (unlock_stage, shown Rows, Row capacity, the drop), its Looks (6 segments),
`SockGenerator` (`floor`, `lays_at_start`, `records_for`), `Openable` (`quiet_when_locked`, `keeps_open_on_load`),
`HouseLights` (`reveal`, locked floors dark), `Hands` (`carries()`, shared with core/72), `Autosave` (the floor name),
`LobbyState` (the slider's value).

## Tickets (drafts; the lead numbers and files them)

Build order: 71-A first; then 71-B, 71-C, 71-D, 71-E, 71-F, 71-G side by side (each its own files); 71-H last. The asset
tickets start at once beside 71-A. core/72's First wash needs 71-A and 71-B (`run_started`, `lay_first`); core/73's
washer needs 71-A and 71-C (`MachinePartSlot`, `part_fitted`, `open_floor`).

- **71-A Stages: the run's state and Rows** (ready-for-agent; blocked by none). `StagePlan`, `Stage`, `MachinePartKind`
  Resources; `Run` with `Stages` (phase, bar, start, complete, open_floor, the zoo verbs, loaded); Cabinet
  `unlock_stage`, Row capacity and `pairs_per_drawer`; signals; `WorldRecord.floor_name`; the Stages zoo station with
  its mini run (Socks laid by the station's SockSpots for now). Real path: in the station the player clicks the last
  Pair into Cabinet A; the Stage completes; the station's "Fit now" switch (a click) opens Stage 2: Cabinet B unlocked
  at its Rows, Cabinet A one Row taller.
- **71-B A Stage's Socks** (blocked by 71-A). `SockGenerator.floor`, `lays_at_start`, `records_for`; the Designs rule;
  `StageSpawner` (slices, `land`, `due` after a load); high spots; Stage 1 at a New Game and `lay_first`. Real path:
  station: shelve the last Pair, Fit now; the Stage 2 Socks land on the platform; the player walks up and picks one by
  input.
- **71-C Machine Parts** (blocked by 71-A, AS3). The entity, its pop, lying motion, glow and sparkle; carry, put down,
  hand over; `MachinePartSlot` and `fit` ("The washing machine is busy" through `busy`); `Hands.carries()` unless
  core/72's bin landed it first. Real path: station: shelve the last Pair; the Part pops; the player clicks it (carried,
  the readout names it) and clicks the slot box; the platform's floor opens.
- **71-D Floor locks** (blocked by 71-A, AS1). `FloorLock`, the two Looks and their animations, the hint, the gate's
  blocker, `Openable.quiet_when_locked` and `keeps_open_on_load`, `HouseLights.reveal`. Real path: station: the player
  aims at the padlock and reads "Please the washing machine"; Fit now; the gate opens; the player walks through onto the
  platform.
- **71-E The Cabinets grow** (blocked by 71-A, AS2). Six Drawers, shown Rows, the drop with thunk and dust; with S4 (b)
  `shown`, `DrawerReveal` and `reveal`. Real path: station: complete Stage 1 and fit; the player turns to Cabinet A; its
  third Drawer drops; the player clicks a Pair into it.
- **71-F The Stage bar** (blocked by 71-A). Real path: station: the player clicks a Pair into Cabinet A; the bar reads
  "Stage 1: <title>  1/4" and its fill moves; after Fit now it resets with Stage 2's icons.
- **71-G Tallies, the Whiteboard and Tab** (blocked by none). `RunTallies`, the patches in shelve and pick, the board,
  the overlay, the input action. Real path: in the zoo the player picks a Sock (input) and holds Tab; the overlay's row
  reads 1 under Socks picked; the board's picture was redrawn once.
- **71-H The house's run** (blocked by 71-A..71-F). `Run` in `house.tscn` with `house_stage_plan.tres`; each Cabinet's
  `unlock_stage`; the generators' `floor` and `lays_at_start` off; the three `FloorLock`s at the old places (the tops of
  the ground's and the first floor's flights, the foot of the attic's); the four Machine Parts; a `MachinePartSlot` on
  the `Washer` marker until core/73's washer replaces it; the debug slider in the Lobby. Real path: a house New Game
  (from the title, Solo): only the basement holds Socks, the garage Cabinet is sheeted, the player walks up the stair
  and is stopped by the ground floor's door; a Pair clicked into the laundry Cabinet moves the bar.
- **AS1 Floor lock models** (M1 asset; blocked by none). The plank door, the baby gate, the chain and the padlock ported
  by examination of `tools/blender/make_house.py`:1051-1310 (chain links, padlock, door, gate), fitted to the port's
  stair openings; `assets_src/` and the Blender skill.
- **AS2 Cabinets to six Drawers** (M1 asset; blocked by none). Every Collection's Cabinet Looks with Segment1..6 and the
  drawer Looks unchanged; the looks contract updated.
- **AS3 Machine Part models** (M1 asset; blocked by none). The four old Part glbs (`assets/parts/part_*.glb`, within
  0.22 m, bottom centre on the origin) imported with their Looks scenes.

## Gotchas for the build

- A Stage's bar is fixed when it begins: a Row full before then is not in it (the old rule, Q633).
- The old last-Stage patch (count only its own Cabinets, `ST:133-135`) is not ported for the attic (S7 (a)); the Drum's
  Stage in batch D sets it back for itself (a `Stage.counts_only_own` flag then).
- The Coins bonuses (+100 a floor, +50 a Cabinet's Rows) are not paid in batch A (S3 (a)); the Cabinet's per-Pair Coins
  stay as they are.
- Each spot keeps its placed Collection in batch A (S2 (a)); the pools come with batch B's Collections unlocking.
- The Pairs per Drawer slider is never in a release build; its value scales `Stage.pairs` by size/25.
