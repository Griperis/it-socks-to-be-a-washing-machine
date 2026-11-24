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
terms: [Laundry bin]
---

# The Laundry bin model

The old hamper ported by the Blender skill as `tools/blender/laundry_bin.py` from the old
`make_laundry_bin.py`: white perforated plastic (0.44 x 0.52 x 0.34 m), the Sock-mesh heap with its blend shape
`empty`, built to core/90's Looks contract (`Contents`, the `tip` pivot). Design: `docs/architecture/run-ends.md` "Looks".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

Built by its script (build() safe to re-run); the shared materials (Q2177).

## Acceptance
- Look work: a line-up (old and port, full and empty) in `builds/review-assets-13/`, `ready-for-human`.
- No real-path case (Q2421); core/90's contract holds on the model.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log
