---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-24
done:
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Stage, Floor]
---

# Floor lock models

The locked ways up, ported by examination: the plank door (ledges, Z brace), the painted baby gate, the steel chain
and the brass padlock from the old `tools/blender/make_house.py`:1051-1310, fitted to the port's stair openings, in
`assets_src/` by the Blender skill, built to core/80's Looks names (`looks_lock_door.tscn`, `looks_lock_gate.tscn`,
the chain and padlock nodes its `unlock` animation keys). Design: `docs/architecture/stages.md` "The floor locks".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

Models built by `tools/blender/` scripts (build() safe to re-run); the shared materials (Q2177).

## Acceptance
- Look work: stops at its first line-up (the old and the port side by side) in `builds/review-assets-10/`, `ready-for-human`; assets are approved per family batch.
- No real-path case (a look ticket, Q2421); core/80's Looks names and animations still play on the models.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log
