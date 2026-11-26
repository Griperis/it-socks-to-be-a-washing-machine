---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: ["[[155-elevator-car-calls-hatches]]", "[[133-old-tree-help]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 5", "suggested model: sonnet"]
terms: [Old Tree, Elevator Repair]
suites: [old_tree_voice, voice, furniture_devices]
---

# The Old Tree's Elevator tip

Once Elevator Repair is first bought in a Run, the Old Tree says its Elevator tip once to each player who comes near:
"The elevator. Slow, a bit shaky, but it still beats the stairs. Mind the doors." (Q1594, Q1606). Build
`docs/architecture/elevator.md` "Seams" (core/132 and core/133), draft 149-F: the trigger file
`game/voice/triggers/tree_tip_elevator.tres` (its recording copied by core/132) named in the Old Tree's tips by
core/133's mechanism (once per player per run), due from the first `Upgrades.bought` of `elevator_repair`.

Behaviour lines (`11-elevator.md`): "The Old Tree's tip" (1).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
A trigger file and its line's JSON entry: no code if core/133's tips are data, as its ticket says.

## Acceptance
- Real path: after the player's click on Elevator Repair in the Upgrade menu (the real `buy`), walking to the tree
  shows the tip's subtitle once this run; a second player hears it once too; a New Game resets it.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Elevator as the old (Q2702, 2026-11-26).

## Open follow-ups
