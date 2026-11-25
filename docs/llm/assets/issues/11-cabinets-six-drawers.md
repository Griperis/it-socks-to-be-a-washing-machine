---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Cabinet, Drawer, Row]
---

# Cabinets to six Drawers

Every Collection's Cabinet Looks gets Segment1..6 (today Segment1..3), the drawer Looks unchanged, the Looks
contract updated, so a Cabinet can stand at its full height (Simple's 6 Rows). The old models were a base, a segment, a
top and a drawer stacked in code (`docs/architecture/stages.md` "Rows and Cabinets"); this is the same geometry stacked in the Looks.
core/81 waits on it.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The Cabinet Looks scenes and their contract test; no new numbers.

## Acceptance
- A strip of each Collection's Cabinet at 2 and 6 Rows, old and port side by side, in `builds/review-assets-11/` for the review sheet. No look change is intended (a port of the old segments), so it does not stop at the strip unless the lead's prompt has a `Look work:` line.
- The Looks contract test passes on every Collection's Cabinet with six segments.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log

### 2026-11-25
- Changed: every Collection's Cabinet Looks has Segment1..6, Segment i at the old stack's `0.10 + (i - 1) * 0.30`
  (old cabinet.gd BASE_H, SEGMENT_H), the same segment mesh; Segment4..6 hidden and Top at 1.0, so the Looks stands
  at the Cabinet scene's 3 drawers as today (no look change in play); core/81 shows Segment1..`rows` and puts Top at
  `0.10 + rows * 0.30` (`docs/architecture/stages.md` "Rows and Cabinets"). The Looks contract names Segment1..6;
  a new case (k04_six_segments) checks the six segments' places and mesh and the standing at 3 Rows; the real path
  checks the shelved-into Cabinet still stands at 3. The shot hook `cabinet_rows` and the set `cabinet-rows`: each
  Collection at 2 and 6 Rows, the old stack (the old glb's meshes at the old code's positions) beside the port's
  Looks; every pair pixel-identical (png_strip --diff: 0 px on the six checked).
- Files: `game/entities/cabinet/looks_*.tscn`, `game/entities/cabinet/looks_contract.json`,
  `tests/cabinet_looks_test.gd`, `tests/cabinet_test.gd`, `tools/shot_hooks.gd`, `tools/shots/sets/cabinet-rows.txt`,
  `docs/architecture/stages.md`, this ticket.
- Review: `builds/review-assets-11/strip-2-rows.png`, `strip-6-rows.png` (before = old, after = port),
  `old-game-baseline-cab-simple.png` (the old game's own Simple Cabinet at 6).
- Verified: PASS 20103 checks, 578 cases (--touched); PASS rules; PASS asset_lint.
- Merged: 5f3667ea (2026-11-25, branch assets/11-cabinets-six-drawers)
