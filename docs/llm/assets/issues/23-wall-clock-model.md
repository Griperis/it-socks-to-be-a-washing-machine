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
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 2", "suggested model: opus"]
terms: [the house]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The wall clock's model

The old living room's wall clock (`tools/blender/make_clock.py`, `assets/clock/clock.glb`), kept by Q2709, ported by
the asset port rules, the old colours: the deep oak drum with its rounded back edge, the brass bezel, the paper dial with
a mustard chapter ring and dark minute ticks, terracotta batons at 12, 3, 6 and 9, dark dots for the other hours, the
little pink sock above 6, the two charcoal spade hands `hour_hand` and `minute_hand` (turning about z, as the old
`_show_time` turns them), the brass centre cap; its origin the centre of its back, on the wall. A Looks scene for
core/161's `wall_clock.tscn` (its two hand nodes by those names). `docs/architecture/day-and-exterior.md` "The wall
clock".

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script under `assets_src/generate/clock/` and its `assets/blender_assets.json` entry; no collider (the
old clock never collided).

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-clock/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `game/house/wall_clock/wall_clock.tscn` points its Looks at this scene; the graybox goes.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).
- The wall clock's hands are kept (Q2709, 2026-11-26).

## Open follow-ups
