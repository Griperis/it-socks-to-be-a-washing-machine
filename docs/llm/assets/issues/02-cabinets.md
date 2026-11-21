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

# The 17 Cabinets

M1 (Q2378). Today one Cabinet entity (core/04) uses the old "simple" cabinet model for every Collection. The old game had
one Cabinet per Collection with its own front art: `assets/cabinet/<collection>.glb` (17), the loose front art png, the
`.blend` sources, `tools/blender/make_cabinets.py`, `cabinet_art.py`.

## Behaviour list
- K01 Each Collection's Cabinet looks as in the old game, as a Looks of the one Cabinet entity (`game/entities/cabinet/`),
  chosen by the Cabinet's Collection; the drawers, their slide, the outline (core/11) and the balls shown in a drawer
  work on every one (the folder's `looks_contract.json`).
- K02 The Cabinet station shows every Collection's Cabinet (built from the Collections at load, Q2337).
- K03 The drawers' collision and Sock spots as the old ones, in the Godot scene.

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
