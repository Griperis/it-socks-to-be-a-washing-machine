---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: ["[[162-exterior-view]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 8", "suggested model: opus"]
terms: [the house]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The exterior's model

The old outside (`tools/blender/make_exterior.py`, `assets/house/exterior.glb`) ported by the asset port rules, the old
vertex colours, refitted to the port's house (house-kit-plan: its footprint, the 22 windows' moves W1-W22, the light
wells moving with the basement windows, the ramp to the port's garage door, the front step at the port's front door):
the four side meshes `Exterior_North`, `_East`, `_South`, `_West` that replace core/162's graybox under the same names.
The old `exterior_glow` surface is left out (the night glow is dropped, Q2709: the windows and lamp heads keep their
day colours). `docs/architecture/day-and-exterior.md` "The exterior view", draft AS-E.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script under `assets_src/generate/exterior/` and its `assets/blender_assets.json` entry; no colliders,
cast shadows off.

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-exterior/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `game/house/exterior/exterior.tscn`'s graybox meshes are replaced by these under the same names.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).
- The exterior is a view only (Q2694, 2026-11-26); its night glow dropped (Q2709, 2026-11-26).

## Open follow-ups
