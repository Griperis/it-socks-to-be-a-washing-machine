---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: [core/76]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Stage, Sock, Mess, Design]
---

# A Stage's Socks

A Stage's Socks: which Designs, where they lie, laid a slice a frame by the Host. Build `docs/architecture/stages.md` "A Stage's Socks":
`SockGenerator.floor`, `lays_at_start`, `records_for(designs, seed, before)`, the old Designs rule
(`Stages.stage_designs()`), `StageSpawner` (slices through `SockLayingJob`, `land`, `due` laid again after a load),
the even shares over every open floor (Q2617), high spots, Stage 1 at a New Game, and `lay_first` with the held
records core/72 needs (`docs/architecture/run-ends.md` seam S1: laid and kept out of the Mess, saved while held, until a patch reveals them). A New Game holds them only when the level's `LaundryDay` wants a First wash
(`wants_first_wash()`, true from core/94); until then it lays them at once.

Behaviour lines (`docs/migration/m4-lists/03-stages-and-floors.md`): "A Stage's Socks" (all).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`SockGenerator.floor` and `lays_at_start` are exports on each placed generator; the Designs rule and the shares
are code (the old rule); `high_share` and `high_spot` stay on `StagePlan`.

## Acceptance
- Real path: in the Stages station the player shelves the last Pair into Cabinet A and presses E on "Fit now"; the Stage 2 Socks land on both floors in even shares; the player walks up onto the platform and picks one by input.
- Every machine picks the same Designs and places from the World's seed and the Stage; each Design spawns once a run.
- A load with `due` not empty lays the rest (none held, lying or shelved twice).
- Held records (`lay_first` with a First wash waiting): no Sock lies until the reveal patch; then all of them, on every machine.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A Stage's Socks are spread in even shares over every open floor, as the old code (Q2617, 2026-11-24).
- The First wash's spray is decoration; the first Stage's Socks lie in their usual places (Q2626, 2026-11-24).

## Open follow-ups
- [later] The high-spot pass (`high_over`) is built but only checked for "the count never changes": no station has a
  furniture top over 1.7 m; a look in the house with two players would show it.
- [later] The Stages station sets no `floor` on its generators (the scene was not to be edited this wave); it reads
  Ground, Platform as floors 0, 1 by tree order. Setting `floor = 1` on `Generators/Platform` makes it explicit.

## Built log

### 2026-11-25
- Changed: `SockGenerator.floor`, `lays_at_start`, `records_for` (one Pair per Design given, areas weighted by `pairs`,
  high-spot pass); `Stages.stage_designs` (the old Designs rule, lesson first) written into `spawned`/`due` by `start`
  and `open_floor`; `StageSpawner` (Host, slices, even shares over open floors, `land`); `land`, `lay_first` and the held
  records (`holding`, `held_designs`, `held_poses`; group `first_wash_wanters` for core/94); a load lays what is still
  due; Stage 1 behind the loading screen through `Mess.layer`; the house's four generators set `floor`, `lays_at_start`
  off. Old choices are rows in `batch-a-review.md`.
- Files: game/run/ (stage_spawner.gd, stages.gd, run.tscn), game/mess/ (sock_generator.gd, sock_laying.gd,
  sock_laying_job.gd, mess.gd), game/level/loading_screen.gd, game/house/house.tscn, tests/stage_socks_test.gd,
  tests/stages_test.gd, docs/architecture/stages.md, docs/migration/batch-a-review.md
- Verified: `--only=stages,stage_socks` PASS 105 checks, 14 cases; `--touched` verdict below
- Merged: 3b935422 (2026-11-25, branch core/77-a-stages-socks)
