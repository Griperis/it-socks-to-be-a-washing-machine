---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Stage, Cabinet, Row, Drawer, World]
---

# Stages: the run's state and Rows

The run's floor-by-floor frame starts here: one `Run` per level with the `Stages` Part (one phase instead of the
old five counters), the Stage Resources, the verbs and the signals every other batch A ticket plugs into. Build
`docs/architecture/stages.md` "The shape" (`Run`, `Stages`' state, its verbs `start`, `complete`, `open_floor`, `lay_first` and `land` as
stubs core/77 fills, the zoo verbs, `loaded()`), "Rows and Cabinets" without the drop (core/81), and the save and
Lobby parts of "Saves, joins and the Lobby" except the debug slider (core/91). The `fit` verb and `MachinePartSlot`
are core/79's; until then the station's "Fit now" switch is the way to open a floor.

Behaviour lines (`docs/migration/m4-lists/03-stages-and-floors.md`): "The run's Stages" (all; the pools stay out, Q2618), "Rows and Drawers" (all but the drop,
the dust and the slider), "Saves and co-op" (all). The `StageBarPhase` Resource and `StagePlan`'s three phases are
made here as data, and `Stages` answers the bar's `stage_rows` provider (`bar_source()`, `bar_numbers()`): core/82
only draws them.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`StagePlan` (`game/run/house_stage_plan.tres` and the zoo's `game/zoo/stages/mini_plan.tres`), `Stage`
(title, floor, pairs, part, `counts_only_own`, `comment_set`), `MachinePartKind` (one `.tres` per Part, Looks empty
until core/79), `StageBarPhase` (three in the plan), `Cabinet.unlock_stage` on each placed Cabinet: all edited in the
inspector, every number `# placeholder:` the old value. The Stages station (`game/zoo/stations/stages.tscn`, things
under `game/zoo/stages/`) lists the plan's Stages from the data at load (Q2337) and holds the mini run (Cabinet A,
Cabinet B sheeted, the platform with an empty spot for core/80's gate and core/79's slot box, a SockGenerator area on
each floor; Socks for now from the station's SockSpots).

## Acceptance
- Real path: in the Stages station the player clicks the last Pair into Cabinet A; the Stage completes (phase `PART_OUT`); the player presses E on the "Fit now" pillar; Cabinet B is unlocked at its starting Rows and Cabinet A is one Row taller.
- A Stage's bar is fixed when it begins (Q633); the attic's counts only its own Cabinets (`counts_only_own`, Q2623).
- Save and load mid-Stage and between `FIXING` and `open_floor` (the floor opens after the load); a Guest who joins sees the same Stage, Rows and phase.
- The World's row names its floor (`WorldRecord.floor_name` from the Stage's `title`).
- Placeholders: `start_rows` 2, `rows_per_stage` 1, `pairs` 50/160/150/130, `high_share`, `high_spot` (Q967).
- The save tests' `shape.json` and `house_ids.txt` updated (S11, S12).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Each Cabinet spot keeps its placed Collection in batch A (Q2618, 2026-11-24).
- No Stage Coins bonuses in batch A (Q2619, 2026-11-24).
- The bar stays full between completion and Fix; its text is a phase Resource (Q2621, 2026-11-24).
- Floor names "Basement", "Ground", "First", "Attic" (Q2622, 2026-11-24).
- The attic counts only its own Cabinets (Q2623, 2026-11-24).

## Open follow-ups

## Built log

### 2026-11-25
- Changed: a level with a `Run` keeps the run's state on its `Stages` Part (stage, one phase, the bar fixed when a
  Stage begins, spawned, due, first_laid, Pairs per Drawer). A New Game starts Stage 1 (only Stage 1's Cabinets
  unlocked at 2 Rows, the rest locked under their sheets); the last Pair of the bar completes the Stage (PART_OUT);
  `open_floor` (and the zoo's "Fit now") grows every unlocked Cabinet a Row, unlocks the next Stage's and begins its
  bar; the last Stage's Fix leaves the machine fixed. A Row holds the World's Pairs per Drawer, the Collection's last
  Row only the Designs left; the attic counts only its own Cabinets. A load in FIXING opens the floor; the World's
  row names its floor. The Stages station holds the plan list and the mini run. `lay_first`, `land`,
  `stage_designs()` are stubs for core/77; `fit` and the Part are core/79's.
- Files: game/run/ (stages.gd, run.tscn, stage.gd, stage_plan.gd, house_stage_plan.tres),
  game/ui/stage_bar_phase.gd, game/entities/machine_part/, game/entities/cabinet/cabinet.gd, game/save/autosave.gd,
  game/zoo/stations/stages.tscn, game/zoo/stages/, game/house/house.tscn (the Run), tests/stages_test.gd,
  tests/saves/shape.json, house_ids.txt
- Verified: `kit/tools/run.sh --touched`: PASS (586 cases) but for the zoo layout, fixed and rerun: `--only=zoo,every_sock,stages` PASS 5380 checks, 27 cases; grep_rules PASS
