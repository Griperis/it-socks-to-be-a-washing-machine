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
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 4", "suggested model: sonnet"]
terms: [Wardrobe Station]
suites: []
---

# The Wardrobe station's model

The old `assets/wardrobe_station/wardrobe_station.glb` (with its fabric palette) imported by the asset port rules as
the station's Looks scene, with `door_left` / `door_right` pivots on their hinges and the `open` (each leaf 80 degrees,
0.7 s, ease in-out) and `shut` (ease out) clips, to core/142's contract (`docs/architecture/wardrobe.md` "The station in
the house": the graybox Looks' node names). It swaps in for the graybox on the designer's yes.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "The Wardrobe in the house", the
station's look and doors.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604).

## How it is authored
An inherited scene of the imported glb; the doors as clips in the Looks; the shared materials where the port's rules
swap them (Q2177).

## Acceptance
- Look work: a line-up shut and open beside the old in `builds/review-assets-20/`, `ready-for-human`.
- No real-path case (a look ticket, Q2421).

## Answers
- None beyond the design's.

## Open follow-ups
