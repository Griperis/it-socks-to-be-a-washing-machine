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
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 1", "suggested model: opus (Blender)"]
terms: [Gift]
suites: []
---

# The present box model

The old Stage present's box (Q1591; the old `presents_tree.png` approved, Q1611) as a model, by the Blender skill as
`tools/blender/present_box.py`: the body, a separate lid, the ribbon cross and the bow; the paper surfaces take
`gift_paper.gdshader` (core/137 ports it; until then a plain material named for it). Built to core/137's Looks contract
(`docs/architecture/gifts.md` "The box's Looks": `Box`, `Box/Lid`, `Glow`, `Sparkle`, `Tag`, `Burst`, the clips `drop`,
`lying`, `RESET`, `open`): the model brings `Box` and `Box/Lid` with their pivots; the clips stay core/137's and
core/138's.

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "The presents under the Old Tree", the box's
look lines.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604).

## How it is authored
Built by its script (`build()` safe to re-run), the shared materials (Q2177); the wrapping's colours come from the
present's `SockCollection` at run time, not the model.

## Acceptance
- Look work: a line-up (the old box beside the port's, closed and lid off, wrapped in two Collections) in
  `builds/review-assets-16/`, `ready-for-human`; it swaps in on the designer's yes.
- No real-path case (a look ticket, Q2421); core/137's contract holds on the model.

## Answers
- Gifts come as Stage presents under the Old Tree (Q2612, 2026-11-24).

## Open follow-ups
