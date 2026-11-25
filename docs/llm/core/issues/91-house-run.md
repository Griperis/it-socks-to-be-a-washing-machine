---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: [core/76, core/77, core/79, core/80, core/81, core/82, core/86]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Stage, Cabinet, Floor, World]
---

# The house's run

The run comes into the house: build what `docs/architecture/stages.md` "How it is authored" places: `Run` in `house.tscn` with `house_stage_plan.tres`,
each Cabinet's `unlock_stage` (the garage's 2), the generators' `floor` and `lays_at_start` off, the three
`FloorLock`s at the old places (the tops of the ground's and the first floor's flights, the foot of the attic's), the
four Machine Parts under `Run/MachineParts`, a `MachinePartSlot` on the washer,
the Stage bar on the HUD, and the debug "Pairs per Drawer" slider in the Lobby (debug builds only; the World drawer
while "New game" is chosen and the Solo New Game page; 1 to 25, each step clearing everyone's Ready; it rides the
launch into `start`). Until core/94 a New Game lays Stage 1 at once (no First wash is wanted yet).

Behaviour lines (`docs/migration/m4-lists/03-stages-and-floors.md`): everything the earlier tickets built, now in the house; "Rows and Drawers": the slider line.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

All placed things are edited on their instances in `house.tscn`; the plan is `house_stage_plan.tres`.

## Acceptance
- The floor locks are placed in the house, each with its `floor` set (core/80).
- The house's Cabinets get their `unlock_stage` values (until then core/77's Stage 1 lays about 400 Pairs there).
- A house case: a New Game lays Stage 1 behind the loading screen (core/77's `Mess.layer`, `lay_progress()`).
- A house case with two players: core/77's high-spot pass puts a few Socks on a top over 1.7 m (no station has one; never seen placing).
- Real path: a house New Game from the title (Solo): only the basement holds Socks, the garage Cabinet is sheeted, the player walks up the stair and is stopped by the ground floor's door; a Pair clicked into the laundry Cabinet moves the Stage bar.
- Reachable in the main scene; the save tests' house shape updated.
- The slider is absent in a release build; its value scales `Stage.pairs` by size/25.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Each spot keeps its placed Collection (Q2618, 2026-11-24).

## Open follow-ups

## Built log
- 2026-11-25
  - Changed: the house plays the run: `FloorLocks/Ground`, `First` (doors, floors 1, 2, top of the east flight) and
    `Attic` (the gate, floor 3, foot of the attic flight); the Cabinets' `unlock_stage` (garage, kitchen, living 2;
    kids 3; loft 4), the garage under a `DustSheet`; four Machine Parts under `Run/MachineParts`; `Washer/PartSlot`
    (a `MachinePartSlot` whose new `aim_body` takes the crosshair only while a Part is out). The door's `open` now
    swings toward its chain (over the flight) and the gate's pin moved to its other post (out onto the first floor).
    The debug "Pairs per Drawer" slider (`PairsSlider`): `LobbyState.pairs_per_drawer` and the Host verb `pairs`
    (clears Ready), in the World drawer while New game is chosen and on Solo's New Game page; it rides the launch
    (`--pairs-per-drawer=`). Old house cases open every floor first; save shape and ids updated; s14 allows a landing
    on a lying Sock. Choices settled by the old game: `batch-a-review.md`, five core/91 rows.
  - Files: `game/house/house.tscn`, `game/entities/machine_part/machine_part_slot.gd`, `game/run/looks_lock_*.tscn`,
    `game/lobby/pairs_slider.*`, `game/lobby/{lobby,lobby_state,lobby_words,world_drawer}.*`, `tests/house_test.gd`
    (r01-r03, `real_path_new_game_from_title`), `tests/lobby_test.gd` (k06, k15), `tests/save_test.gd`, `tests/saves/`, docs.
  - Verified: `kit/tools/run.sh --touched`: PASS 21976 checks, 675 cases; grep_rules PASS.
