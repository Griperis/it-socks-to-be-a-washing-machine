---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done:
blocked_by: [core/76, core/78]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Part, Fix, Stage, Hands]
---

# Machine Parts: pop, carry and fit

The washing machine's Parts as things. Build `docs/architecture/stages.md` "Machine Parts": `machine_part.tscn` (a `Carriable`, the
kind's Looks, the glow disc, the sparkle, `lying` in the Looks' AnimationPlayer), the pop from the Cabinet's top with
`part_pop` and the 18-spark burst, carry and put down through core/78, the hover readout, and `MachinePartSlot` with
the `fit` verb ("The washing machine is busy" through `busy`; the floor opens at once while the Stage names no `fix_cutscene`, core/92). Until assets/12
lands each kind has a graybox Looks (a coloured box per kind, the same node names).

Behaviour lines (`docs/migration/m4-lists/03-stages-and-floors.md`): "A Stage completes: the Part" (all but the washer's Fix scene, the presents, the Coins
bonuses and the Lifetime tally, named there as other tickets' or batches').

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

Each `MachinePartKind` names its Looks; `MachinePartTuning` (ahead 1.5 m, pop 0.7 s, arc 0.6 m, spin 1 rad/s, bob
3.5 cm at 2.2 Hz, glow colour), all placeholders; `part_pop` and `part_fit` in `sound_catalogue.tres` with the old
picks. The Stages station's mini run gets the slot box and the Parts lie beside the plan's labels from the data.

## Acceptance
- Real path: in the Stages station the player shelves the last Pair; the Part pops out of Cabinet A's top; the player clicks it (carried, the readout reads its name) and clicks the slot box; the platform's floor opens.
- With anything in the Hands the Part is refused "Hands full"; right click at a Teammate hands it over.
- Save and load with the Part lying or carried; a Guest sees the pop, the lying motion and the carrier.
- Placeholders: `MachinePartTuning` as above.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log
