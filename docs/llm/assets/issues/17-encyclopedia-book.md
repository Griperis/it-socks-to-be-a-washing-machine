---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 2", "suggested model: sonnet"]
terms: [Sock encyclopedia]
suites: []
---

# The encyclopedia book model

The old `assets/encyclopedia_book/encyclopedia_book.glb` (Q1267; its Blender record `assets/blender_assets/
encyclopedia_book.json` in the old game) imported by the asset port rules as a Looks scene
`game/entities/encyclopedia_book/looks_encyclopedia_book.tscn`, for core/139's book (which builds on a graybox Looks
with the same root name until this one swaps in).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604).

## How it is authored
An inherited scene of the imported glb; the shared materials where the port's rules swap them (Q2177).

## Acceptance
- Look work: a line-up (the old book beside the port's, on the workbench's height, closed) in
  `builds/review-assets-17/`, `ready-for-human`; it swaps in on the designer's yes.
- No real-path case (a look ticket, Q2421).

## Answers
- The encyclopedia book stands in the house in batch B (Q2676, 2026-11-25).

## Open follow-ups
