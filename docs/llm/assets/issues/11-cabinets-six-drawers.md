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
