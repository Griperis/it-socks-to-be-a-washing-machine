---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done:
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
- Real path: a house New Game from the title (Solo): only the basement holds Socks, the garage Cabinet is sheeted, the player walks up the stair and is stopped by the ground floor's door; a Pair clicked into the laundry Cabinet moves the Stage bar.
- Reachable in the main scene; the save tests' house shape updated.
- The slider is absent in a release build; its value scales `Stage.pairs` by size/25.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Each spot keeps its placed Collection (Q2618, 2026-11-24).

## Open follow-ups

## Built log
