---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: []
---

# The Sock models and prints

M1, started beside M0.5 (designer, Q2378, 2026-11-21). The graybox Sock is the old `crew.glb`, tinted (Q2249). The old
look is four shape models with shared bones, nine ball models and one pattern shader with a prints atlas, not a model
per Design (2026-11-20). Old: `assets/sock/` (4 shapes ankle, crew, tube, chunky; 9 balls), `assets/sock/prints.png`
(3072x4608, 12x18 cells of 256 px, 206 motifs) and `prints.json`, the old pattern shader and how a Design picks its
shape, colours, pattern and print (`data/designs.json`, the old sock look code: grep `reference/it-socks/game/world/`
for the shader and `sock_look`/`dress`), `tools/blender/make_socks.py`.

## Behaviour list
- S01 Every Design is drawn as in the old game: its shape (by Size), its colours, its pattern (solid, dots, stripes,
  ...) and its print from the atlas, through one shader; the every-Sock station shows all of them.
- S02 The four shape models share one skeleton (Cuff, Leg, Heel, Foot, Toe as the stand-in), so the cloth (core/09)
  and the Looks contract work on every shape.
- S03 A Pair is drawn by its ball model as the old game picked it; the pairing moment shows the right ball.
- S04 The lying tier draws the same look: the MultiMesh instance data (colour plus INSTANCE_CUSTOM, core/13's layout,
  `MessDrawing.look_data()`) feeds the same shader, so a held, flying and lying Sock look alike (no change at rest).
- S05 LODs as the old models had, within the old budgets (sock 320 tris, ball 540).

## Design (draft)
New Looks scenes beside the graybox (`game/sock/looks_<shape>.tscn`, `looks_ball_<name>.tscn`, the shader in
`game/sock/`), the Design-to-look mapping in the Design data or a typed Resource. The swap of the Sock entity's Looks
waits until core/23 (which owns the flight scenes and the Mess) has merged: build and test the new Looks and the
shader on their own and in a zoo comparison, then swap in a last commit after merging main.

## Port rules (for every asset ticket)
- Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file size);
  a look change is its own ticket (Q2153). Blender scripts stay and build meshes only (`.glb`); placement, collision,
  spots and settings live in Godot scenes edited by hand (Q2151, Q2152). Each Looks passes `kit/tools/asset_lint.py`
  and its folder's `looks_contract.json`.
- Approved as a family: a before/after strip in `builds/review-<family>/`, old game beside new, stopped at the first
  still for the designer's go (Q2216). The old files: `reference/it-socks/` (see `docs/migration/assets-inventory.md`).

## Acceptance
- One test per behaviour line (the Looks contract, the station built from data, the real path where the player sees
  it); the strip in `builds/review-<family>/`, stopped at the first still for the designer's go.

## Answers
- Started beside M0.5 (Q2378, 2026-11-21).

## Open follow-ups

## Built log
