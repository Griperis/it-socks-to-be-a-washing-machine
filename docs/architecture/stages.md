# Stages and floors

**Status: build plan for batch A (designed in core/71; S1-S7 answered Q2617-Q2623; filed by core/74 as core/76-83,
core/91 and core/92, assets/10-12).** Behaviour list: `docs/migration/m4-lists/03-stages-and-floors.md`. Batch A
(Q2606, Q2614) is built unattended and reviewed in play as a whole (Q2603, Q2605); its order is
`docs/migration/milestones.md` "Batch A", its review sheet `docs/migration/batch-a-review.md`.

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
| `stage: int` | the current Stage (0 = the basement's; -1 before a New Game's `start`, which the Host asks once the level is bound and its World loaded) |
| `phase: int` | `PLAYING` (the bar counts), `PART_OUT` (complete; its Part lies or is carried), `FIXING` (the Part is in the machine; its Fix scene plays), `FIXED` (the last Part's Fix is over: the Laundry day's, core/72) |
| `bar: Array` | the Rows the Stage counts: `[cabinet id, drawer]` each, fixed when the Stage begins |
| `spawned: PackedInt32Array` | every Design spawned this run (each spawns once) |
| `due: PackedInt32Array` | the Designs of a spawn not landed yet (laid again after a load) |
| `first_laid: bool` | Stage 1's Socks have landed (with the First wash they wait for its spit) |
| `pairs_per_drawer: int` | this World's Drawer size (25; the debug slider, Q668) |

Every Cabinet's new Drawers appear in the answer that adds them, seen or not, as v0.1.1 played (Q2620, replacing Q824's
wait-until-seen): there is no "shown" count and no reveal check.

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
| `open_floor` | Host: the washer at its Fix scene's fade (core/73), or the slot at once when the Stage names no `fix_cutscene` (the zoo's mini plan, tests; core/92) | the next Stage: `stage + 1`, `phase = PLAYING`, every unlocked Cabinet `+rows_per_stage` Rows to its full height, the new Stage's Cabinets unlocked at `start_rows`, the new bar, the floor's lock Openables `{open true, locked false}`, the new Stage's Designs into `due` and `spawned`. On the last Stage instead `phase = FIXED` |
| `lay_first` | Host: the First wash at its spit (core/72) | releases the hold of a New Game that wanted a First wash: the held records join the Mess lying (`added_lying_patch`), `first_laid`; not yet laid, they land in the Mess when they are (core/77) |
| `land` | Host: the StageSpawner | the laid records of the asked Designs join the Mess (`added_lying_patch`), or are held (`held_designs`, `held_poses`) while a New Game holds Stage 1's; the asked Designs leave `due`; `first_laid` for Stage 1's |
| `zoo_complete`, `zoo_fit_now` | Host, the zoo station's switches only | complete the Stage outright; fit and open at once |

**Built (core/76).** `game/run/run.tscn` (`Run`, a Node3D, its child `Stages` naming the plan) is in the house and
in the Stages station. `Stages` finds the Cabinets under the Run's parent (group `cabinets`) and sets each one's
`Cabinet.stages`, so a Row's capacity is the World's `pairs_per_drawer` (`Cabinet.row_capacity()`, `full_height()`);
a Cabinet's Rows never pass its Drawers (`Stages.height_of`) until core/81 gives it six. Every answer that moves
the run carries `stage_events` (`[[name, args...]]`), which each machine emits as the signals below as it applies the
answer (never on a load or a join). The Host asks `complete` after any applied answer that leaves the bar full. The
zoo's switches (`game/zoo/stages/stages_switch.gd`) ask their own `switch` verb and answer with
`zoo_complete_answer()` / `zoo_fit_now_answer()`. a debug build's launch option `--pairs-per-drawer=N` sets a New Game's Drawer size (the slider, core/91, rides it).

**Built (core/92).** `Stage.fix_cutscene` (the CUTSCENE trigger, also the "waits for a scene" switch) and
`Stage.fix_script` (a `CutsceneScript` of `game/run/fix_scenes/`, its `voice` the same trigger: Fixes 1-3 carry the
`spray` beat and `after_voice_seconds` 3.6, Fix 4 none) are set on the house plan's four Stages. `fit_answer()` of a
Stage that names one is the `fit` answer plus `Cutscenes.start()`'s patch (phase `FIXING`, the scene playing; refused
"busy" while one plays). Every machine's `CutscenePlayer.fading` (the timeline's fade, or the Host's skip) makes the
Host's `Stages` ask `open_floor`; the washer's `busy()` (a cutscene plays or someone is in its drum) is the slot's.

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
| `machine_fixed` | core/72: the Laundry day begins; the Stage bar changes to its Laundry day phase (below) |

The washer is core/73's entity; core/71 owns only the `MachinePartSlot` Part placed on it (the `fit` verb, `busy` and
export). It waits for the Fix scene only when the Stage names a `fix_cutscene`, so no scene property switches it
(core/92).

## How it is authored

- **`StagePlan`** (Resource, `game/run/stage_plan.gd`; the house's is `game/run/house_stage_plan.tres`): `stages:
  Array[Stage]`, `start_rows` (2), `rows_per_stage` (1), `high_share` (0.05), `high_spot` (1.7 m), `# placeholder:` until
  the balance round (Q967). A level names its plan on its `Run`.
- **`Stage`** (Resource, `game/run/stage.gd`): `title` ("Basement", "Ground", "First", "Attic": the old names,
  Q2622), `floor` (the floor index it opens, as `HouseLights.floors` counts them; Stage 1's is open from the start),
  `pairs` (the fewest it spawns: 50, 160, 150, 130 placeholders, Q660), `part: MachinePartKind`, `counts_only_own:
  bool` (the bar counts only this Stage's own Cabinets: on for the attic, batch A's last Stage, as the old last-Stage
  code, Q2623; off for the rest), `comment_set: int` (the washer's comment set while this Stage is current; its number
  by default, `docs/architecture/voice.md`), and, added by the Fix scene ticket (core/92), `fix_cutscene: VoiceTrigger`
  (the cutscene its Part's Fix plays). A fifth Stage is a fifth entry (the Drum's, batch D): no code change.
- **`StageBarPhase`** (Resource, `game/ui/stage_bar_phase.gd`): the Stage bar's text per phase of the run, so a later
  phase plugs in with a Resource and no bar change (Q2621): `text` (a format string), `source: StringName` (the provider
  of its two numbers; empty for none), `track: bool`, `icons` (the bar's Cabinets' Collections, one given icon, or
  none). `StagePlan` holds the run's three: `goal_phase` ("Wash the laundry", no track, no numbers: before the First
  wash, Q2625; batch C's Guide card replaces it), `stage_phase` ("Stage %d: %s  %d/%d", source `stage_rows`, the bar's
  Collection icons) and `after_phase` (the Laundry day's, after the last Fix: "Wash clothes %d/%d", source
  `laundry_bins`, the bin icon; Q2621's wording, the lead's reading that batch A's Laundry day is that phase; batch D's
  Drum puts its own phase before it). `StagePlan.laundry_day_comment_set` (4, Q2635) is the washer's comment set in
  the Laundry day. A provider is a node in the group `stage_bar_source` with `bar_source() -> StringName` and
  `bar_numbers() -> Vector2i` (`Stages` answers `stage_rows`, core/72's `LaundryDay` answers `laundry_bins`).
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
  0.35 s; the phase change: fill 0.25 s, glow 0.25 s, back-ease shrink 0.3 s, pop in 0.2 s), `WhiteboardTuning`
  (resolution 1024 x 768, overlay 0.8, glow 0.2). All `# placeholder:` the old values.
- **Sounds**: `padlock_pop`, `chain_drop`, `lock_door_open`, `drawer_thunk`, `part_pop`, `part_fit` join
  `sound_catalogue.tres` with the old picks or shares (device_click, oven_close, wardrobe_open, oven_close,
  rubberduck_plop1_pop, rubberduck_v2_lock_open_fit); `cabinet_reveal` is there already.
- **Zoo station** `game/zoo/stations/stages.tscn` (built from data at load, Q2337; its own things under
  `game/zoo/stages/`): the house's `StagePlan` as a row of labels per Stage (title, floor, Pairs, its Part's name) with
  each `MachinePartKind`'s Looks lying beside it (a new Stage or Part shows with no other change); a ground door and a
  gate `FloorLock` with an Open/Lock switch; and a **mini run**, the station's own `Run` with
  `game/zoo/stages/mini_plan.tres` (two Stages, Pairs per Drawer 2, no `fix_cutscene`): Cabinet A (Stage 1), Cabinet B
  sheeted (Stage 2), a raised platform behind a `FloorLock` gate (its floor), a `SockGenerator` area on each, and a box
  with a `MachinePartSlot` (no washer: it opens at once). The real-path cases of the build tickets run there. Only
  core/76, core/79 and core/80 edit the station's scene (one per wave); the Drawer drop, the bar's phases and the tallies
  are checked on the mini run with no station change.

## The pieces

### Rows and Cabinets
`Cabinet` keeps `locked` and `rows` (its State today). New: `unlock_stage`; the Row's capacity is `pairs_per_drawer`
(from `Stages` when the level has a run, else `CabinetTuning.drawer_capacity`), the Collection's last Row only the
Designs left (Simple's sixth: 5); its full height is the Collection's Designs over the Pairs per Drawer, rounded up.
The Cabinet scene holds the most Drawers any Collection needs (Simple: 6) and shows `rows` of them (a locked one
`start_rows`), the rest hidden and out of reach (collision off, Openable locked). Each Collection's Looks gets
Segment1..6 (assets/11: the old models were a base, a segment, a top and a drawer stacked in code; Segment i stands at
the old `0.10 + (i - 1) * 0.30`). The Looks stands at 3 Rows as authored (Segment4..6 hidden, Top at 1.0); the Cabinet
shows Segment1..`rows` and puts Top at `0.10 + rows * 0.30` (core/81).

The drop: when `rows` grows in an answer (not on a load or a join), each new Drawer module falls in on top with the
old timings, a `drawer_thunk` at its seam and `dust_puff.tscn` (a one-shot particles scene) bursting from it: a Tween
in the Cabinet's `_show` (a one-shot effect, the native default). It drops at once on the opening, whether or not
anybody sees the Cabinet, and takes Pairs from that answer on (Q2620).

### A Stage's Socks
`StageSpawner` (Host) picks up `due`, asks the target floor's generator for records of exactly those Designs
(`SockGenerator.records_for(designs, seed, before)`, a new entry beside `records()`: the same places and laying, the
Designs given instead of dealt from `collections`, no repeats), a slice per frame through `SockLayingJob`, then asks
`land`. The seed is `hash([the World's seed, stage])`. The Designs are chosen by the old rule (behaviour list "A
Stage's Socks", `Stages.stage_designs()`, every machine the same). High spots (Q664): with 2 or more players present
at the spawn, `high_share` of them go to the floor's top places at least `high_spot` over the floor (a filter on the
generator's existing top places); alone none. The Stage's Socks are spread in even shares over every open floor, as
the old code (`mess.spill.level_shares`, Q2617): with n floors open each floor's generator lays 1/n of the Designs (the
remainder to the newest floor), dealt in the Designs' order so every machine splits them alike; Stage 1's all go to the
basement's. At a New Game Stage 1 lays behind the loading screen as house/09 does when no First wash waits; with the
First wash they are laid and held until its grant (core/72; the spray is decoration, Q2626).

**Built (core/77).** `SockGenerator` has `floor` (below 0: its place among its level's generators in tree order, so the
Stages station, which sets none, reads Ground, Platform as floors 0, 1) and `lays_at_start` (off on the house's four);
`records_for(designs, seed, catalogue, before, high, high_over)` lays one Pair for each Design given, over the
generator's areas by their `pairs` (equal when all are 0; the house's `Floor` pairs are only weights now), no trails;
the high ones in a separate pass of the area on tops at least `high_over` over its floor (no such top: the usual
places). `Stages.stage_designs(index, rows_by, per, taken)` is the old rule (lesson first, `Stages.lesson_designs`: the
first two common Simple Designs), and `start` and `open_floor` write its Designs into `spawned` and `due` in their own
answers. `StageSpawner` (`game/run/stage_spawner.gd`, in `run.tscn` beside `Stages`) lays `due` when it is not empty,
Host only. A New Game of a level with a loading screen registers it as the Mess's `layer`, so Stage 1's laying runs
behind the screen with the starting Socks (`Mess.layer`, `lay_progress()`); every other laying runs in `_process`.
Held Socks (seam S1): `Stages.holding` is set at `start` when a node in the group `first_wash_wanters` under the level
says `wants_first_wash()` (core/94's `LaundryDay` joins it; no node: laid at once); the laid records wait in
`held_designs` and `held_poses` (saved state) and `lay_first` releases them. A load keeps only the `due` Designs the
Mess has no Sock of (`_still_due`) and the spawner lays those.

### Machine Parts
`game/entities/machine_part/machine_part.tscn`: a root Node3D, a `Carriable` (exists), the kind's Looks (`looks_filter`,
`looks_motor`, `looks_drum_belt`, `looks_detergent`: the old glbs imported, assets/12), a glow disc and a sparkle
(`GPUParticles3D` scene), and an AnimationPlayer in the Looks with `lying` (the spin and bob, looping). Hidden unless it
is the current Stage's and `phase == PART_OUT`. The pop: a Tween from the Cabinet's top to `at` (hop, arc, bounce, the
old `pop_pose`), `part_pop` at the top, an 18-spark burst on landing. Carried: in empty Hands only ("Hands full"),
held in front at the HoldPoint; right click puts it down where the crosshair is ("Can't drop there") or, aimed at a
Teammate with empty Hands, into theirs (else at their feet, they read "Hands full"). The hover readout names it.

**Shared seam with core/72** (core/78): carrying a thing in the Hands (the Laundry bin, B33) is the same `Carriable` plus
`Hands.carries()` (a carried thing fills the Hands; nothing else is picked), built once by core/78 before either the
Part or the bin. Both go into a Teammate's empty Hands by a right click aimed at them (else at their feet, "Hands
full"), as the old. The bin refuses core/42's Hand-off; a Part allows it: `Carriable.handable` (export), as
core/71 proposed.

As built (core/78): `Carriable` (`game/parts/carriable.gd`) has the exports `slot` (a `HoldSlot`,
`game/hands/hold_slot.gd`: `at` from the feet in the body frame, `turn`, `floor_clearance`, `put_seconds`; the bin's is
`game/hands/hold_slot_bin.tres`), `handable` (on: the right click aimed at a Teammate is the verb `hand_off`, into their
empty Hands or at their feet with "full"; off: that click is a plain drop at the crosshair) and `title` (the crosshair's
name, aimed or carried). Its verbs: `pick` (the left click, `click_only()`; refused `full` while the Hands hold a Sock
or carry), `drop` (`at` in the thing's parent's space, `yaw`, `normal`: the place is checked by `Hands.spot_refusal()`,
the drop's own check) and `hand_off` (`to`; at their feet it keeps the turn it last lay, as the old). `Hands.carries(by)` names the carried thing (the `carriables`
group); while carrying, a Sock pick is refused `full` and a Sock handed or caught lies at the carrier's feet
(`can_take()`). Every machine draws a carried thing at its carrier's slot each frame (`Hands.body_frame()`: its own
player's drawn body, a Teammate's avatar), so it has no synchronizer; its shapes are off while carried. Put down, its
`Looks` child eases from the Hands to where it lies over `put_seconds`. `left()` lays it at the leaver's feet;
`loaded()` where it last lay. The zoo's stand-in is `game/zoo/handling/crate.tscn` on the Handling station. A thing that
is a Carriable plus another Part (the bin) declares the Carriable first, so the left click reaches it.

As built (core/79): `machine_part.tscn` (a StaticBody3D: `Looks`, `Glow`, `Sparkle`, `Burst`, a `Carriable` on
`hold_slot_part.tres`, and `MachinePart`, `game/entities/machine_part/machine_part.gd`). `MachinePart` keeps **no
state**: it is drawn and aimable only while `Stages.phase == PART_OUT` and its `kind` is the current Stage's Part
(read every frame, so a load, a join and an answer show alike); where it lies and who holds it are the Carriable's.
`Stages._complete_answer` adds the Part's `pop_changes(cabinet)` (`holder 0`, `at` `MachinePartTuning.ahead` m in
front of the Cabinet's root, one ray down on the house layer); every machine plays the pop on `stage_completed`
(`part_pop` at `top_of(cabinet)`, the Looks flown by `pop_pose()`, an 18-spark `Burst` on landing), a late Guest or a
load sees it lying with no pop. `lying` plays only while it lies; `RESET` otherwise. Each kind's Looks
(`MachinePartKind.looks`) takes the place of the scene's `Looks`; until assets/12 each is a graybox box
(`looks_<kind>_graybox.tscn`) with the same nodes. `MachinePartSlot` (`machine_part_slot.gd`, on a box in the zoo,
on the washer in the house) answers `fit` through `Stages.fit_answer()`: refused `not_carried`, or `busy`
("The washing machine is busy") while a node of the group `washer` answers `busy()`; the answer hides the Part (its
phase leaves PART_OUT), plays `part_fit`, and opens the floor at once while the Stage has no `fix_cutscene`
(else the phase is FIXING and the Fix scene asks `open_floor`). The player's click on the slot while carrying reads
"Fit the new filter" (`Prompts.fit_prompt`).

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

**Built (core/80).** `game/run/floor_lock.tscn` (the door) and `floor_lock_gate.tscn` (the gate, with its `Blocker`): the
root holds the leaf's `Openable` (`locked`, and the new exports `quiet_when_locked`, `keeps_open_on_load`, `one_way`),
the `Looks` (`looks_lock_door.tscn` / `looks_lock_gate.tscn`: graybox on the model's node names `frame`, `panel`, `leaf`
(an AnimatableBody3D itself: a body moves with the physics only when its own transform is keyed, not its parent's), `chain`, `padlock`; two AnimationPlayers, `AnimationPlayer` with `open` and
`UnlockPlayer` with `unlock`) and a `Padlock` node, the padlock's own entity: `FloorLock` (`floor_lock.gd`, a Part with no
state, `floor`, `FloorLockTuning`), an `Aim` body at the padlock's rest spot (layer 1, off once open) and its `Outline`
(the meshes under the Looks' `padlock`, found at ready). `Openable` emits `shown(locked, now, unlocked)` after every
show; `FloorLock` plays `unlock`, the three sounds (timed from the tuning, not method tracks, so a swapped Looks needs no
sound keys), `HouseLights.reveal(floor)`, and keeps the aim body, the blocker and `HouseLights.set_level_dark(floor,
locked)` as the lock stands. `Stages._open_answer` writes `{open true, locked false}` on the leaf of every `FloorLock`
whose `floor` is the new Stage's (`Stages.floor_locks()`); the dust sheet follows its Cabinet's own unlock. A swapped
Looks (assets/10) keeps the node names and the two animations, and puts the model's leaf mesh under a `leaf` body.
`LockSwitch` (the Stages station's Locks pillar) opens and re-locks the locks by answer.

### The Stage bar
`game/ui/stage_bar.tscn`, a child of the HUD, hidden in a level with no run: the old panel and layout (behaviour list
"The Stage bar"), on the Theme's `StagePanel` variation. It reads `Stages` (by group) and the bar's Cabinets; it
redraws only on a change. It shows one `StageBarPhase` at a time, picked from the run's state: `goal_phase` while
core/72's First wash is pending, `stage_phase` from then until `machine_fixed`, `after_phase` after; its numbers come
from the phase's provider. Between a Stage's completion and its Fix it stays full, as the old (Q2621). The change from
`stage_phase` to `after_phase` is the old fold (fill, glow, back-ease shrink, then the new phase pops in with `pop`;
`RIG:636-647`, `HUD:325-360`); from `goal_phase` to the first Stage the bar pops in. A level with a run but no First
wash (the zoo's mini run) starts at `stage_phase`.

Built by core/82 (`game/ui/stage_bar.gd`, `stage_bar_tuning.tres`; the bar is a child of the player's `Hud`). Its seams:
core/72's First wash joins the group `stage_bar_goal` (`StageBar.GOAL_GROUP`) with `goal_pending() -> bool` (true until the
First wash is over; no node in it means no goal phase). A provider (group `stage_bar_source`) may also give
`bar_words() -> Array` (the arguments before the two numbers in the text; `Stages` gives the Stage's number and title),
`bar_collections()` (a `CABINETS` phase's icons; `Stages`) and the signal `bar_changed` (core/93's `LaundryDay` emits it
when a bin is loaded). The fold plays `pop` (placeholder, Q1620) as it begins and emits `StageBar.folded`.

### The tallies, the Whiteboard and Tab
`RunTallies`' State: player id -> `{pairs, made, socks, coins}`, written in the same answers that cause them (the
Cabinet's shelve adds `pairs` and `coins` beside its Coins patch; the Hands' pick adds `socks` for a Mess Sock and
`made` when it pairs), so it needs no events of its own; a leaver keeps their row. The board: a script on the
board's own scene, `game/furniture/collection_board.tscn` (`whiteboard.gd`; there is one board, and so the house scene
is not touched by this ticket), puts `whiteboard_sheet.tscn` (one Control, the old drawing,
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

**Built (core/91): the house's run.** `house.tscn` holds `Run` (the house's plan), `Run/MachineParts` (Filter, Motor,
DrumBelt, Detergent, lying hidden under the house at y -8: a Part's shapes are on until its first physics frame, so none
may stand where Socks are laid), `FloorLocks/Ground` and `FloorLocks/First` (doors, floors 1 and 2, across the top of the
east flight at x 5.875, z 5.45) and `FloorLocks/Attic` (the gate, floor 3, at the foot of the attic flight, x 4.625,
z 5.4, turned to face the first floor), each Cabinet's `unlock_stage` (garage, kitchen, living 2; the kids' 3; the
loft's 4; the locked ones authored `locked`), a `DustSheet` on the garage, and `Washer/PartSlot`: a StaticBody3D a
centimetre larger than the washer with the `MachinePartSlot`, whose `aim_body` puts it on the house layer only while the
Part is out (the Washer, the washer's first Part, is aimed the rest of the time; the slot then reads "Washing machine"
with no key). The door's `open` swings toward its chain's side (back over the flight); the gate's pin is on its right
post (out onto the first floor). The Lobby's slider is `game/lobby/pairs_slider.tscn` (`PairsSlider`, debug builds
only): `LobbyState.pairs_per_drawer` and its Host verb `pairs` (1 to 25; clears Ready), shown in the World drawer while
New game is chosen (read-only on a Guest) and on Solo's New Game page (in a debug build New Game always opens it, the
question only over a save); the Lobby adds `--pairs-per-drawer=N` to a New Game's launch, which `Stages.start` reads.
House cases: `house_test.gd` r01-r03 and `real_path_new_game_from_title`; the old house cases open every floor first
(`_open_floors`) where they walk the stair or use a later Cabinet.

## What core/58-68's code is reused

As it is: `Parts`, `Command`, the Session and the snapshot, `Save`, `Autosave`, `WorldRecord` (its `floor_name` field
waits for this), `Worlds` (its row line already prints the floor), `SceneChanger` and the loading screen,
`Cabinet` (lock_patch, sheeted, aimable, the refusals), `DustSheet`, `Coins`, `Carriable`, `Openable`, `SockGenerator`
and `SockLayingJob`, `HouseLights`, `UiIcons`, the Theme and `KeycapStyle`, the Lobby's World drawer and Solo New Game
page (the slider's home). Changed: `Cabinet` (unlock_stage, shown Rows, Row capacity, the drop), its Looks (6 segments),
`SockGenerator` (`floor`, `lays_at_start`, `records_for`), `Openable` (`quiet_when_locked`, `keeps_open_on_load`),
`HouseLights` (`reveal`, locked floors dark), `Hands` (`carries()`, core/78), `Autosave` (the floor name),
`LobbyState` (the slider's value).

## Tickets (filed by core/74)

The drafts 71-A..71-H and AS1-AS3 are filed as below; the order and waves are `docs/migration/milestones.md` "Batch A".
Every core ticket builds on graybox Looks where its asset ticket has not landed; the asset ticket swaps the Looks.

| Draft | Ticket |
|---|---|
| 71-A Stages: the run's state and Rows | core/76 |
| 71-B A Stage's Socks | core/77 |
| 71-C Machine Parts | core/79 (its carrying seam is core/78, shared with core/72's Laundry bin) |
| 71-D Floor locks | core/80 |
| 71-E The Cabinets grow | core/81 (S4 (b)'s reveal dropped, Q2620) |
| 71-F The Stage bar | core/82 (with its phases, Q2621, Q2625) |
| 71-G Tallies, the Whiteboard and Tab | core/83 (with core/72's run record: one shelve answer, one ticket) |
| 71-H The house's run | core/91 |
| AS1 Floor lock models | assets/10 |
| AS2 Cabinets to six Drawers | assets/11 |
| AS3 Machine Part models | assets/12 |

The Fix of a Part as a cutscene (the washer's scene, `open_floor` at its fade, the spray after Fixes 1-3) is core/92.

## Gotchas for the build

- A Stage's bar is fixed when it begins: a Row full before then is not in it (the old rule, Q633).
- The old last-Stage rule is ported: the attic, batch A's last Stage, counts only its own Cabinets (Winter and Space)
  through `Stage.counts_only_own` (Q2623, `ST:133-135`); every other Stage counts every unlocked Cabinet's unfilled Rows
  (Q633, Q648). In batch D the Drum's Stage sets the flag for itself.
- The Coins bonuses (+100 a floor, +50 a Cabinet's Rows) are not paid in batch A; batch B's Coins and Drawers decides
  them (Q2619). The Cabinet's per-Pair Coins stay as they are.
- Each spot keeps its placed Collection in batch A (Q2618); the pools come with batch B's Collections unlocking.
- The Pairs per Drawer slider is never in a release build; its value scales `Stage.pairs` by size/25.
