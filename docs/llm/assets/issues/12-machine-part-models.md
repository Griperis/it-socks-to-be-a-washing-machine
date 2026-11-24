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
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Part]
---

# Machine Part models

The four old Part glbs (`reference/it-socks/assets/parts/part_*.glb`: filter, motor, drum belt, detergent; within
0.22 m, bottom centre on the origin) imported with their Looks scenes (`looks_filter` .. `looks_detergent`), each with
core/79's `lying` animation node names; each `MachinePartKind` points at its Looks. Design: `docs/architecture/stages.md` "Machine Parts".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

One Looks scene per kind; nothing else.

## Acceptance
- Look work: a line-up of the four Parts, old and port, in `builds/review-assets-12/`, `ready-for-human`.
- No real-path case (Q2421); the Parts still pop, lie and carry in the Stages station.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log
