---
type: ticket
status: ready-for-human
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
- [blocking] For the designer, at the line-up (`builds/review-assets-16/present-box-lineup.png`, bow close-up
  `present-box-bow-closeup.png`): the model keeps the old sizes and places, with two changes a model invites: the
  edges are rounded a little, and the bow's two loops are ribbon loops (a flat band round an oval, at the old
  loops' place, size and lean) instead of the old tilted cubes. Keep them, or go back to the old's blocky bow?
- [later] The line-up's paper is a Blender stand-in for `gift_paper.gdshader` (core/137 has not ported it): the
  same mapping (object space, 2 tiles a face, half-drop, ink 0.85), but Blender's box projection may run the
  top's rows another way. The Looks scene (the glb under `Box`/`Box/Lid`, the shader and the bow colour) is built
  on the designer's yes, against core/137's graybox.
- [later] Kit: `kit/tools/blender/export.sh <asset> --check` refuses the Looks contract's node names (`Box`,
  `Lid`: "name must be snake_case"), as it already does for `laundry_bin`'s `Body`/`Shell`/`Contents`; the
  asset's own script exports it. The kit's rule and the Looks contracts' PascalCase names disagree.
