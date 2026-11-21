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

# House furniture and the shared material library

M1 for M2 (Q2378). Old: `assets/house/furniture/` (67 glb, `manifest.json`: moving parts, containers, colliders, Sock
spots), `tools/blender/house_furniture/build.py` and its group files; the old materials. One shared material library
for all models; where variants differ (oak: 9 in 39 models) the designer picks the one that stays from a strip
(Q2177). Things built by code become models or scenes (Q2178).

## Behaviour list
- F01 A shared material library (typed `.tres` materials) the furniture, the house kit (house/01-02) and later
  families use; a strip of each variant group (oak and the others) for the designer to pick the one that stays,
  **the first stop**.
- F02 Each piece is a scene with its model, its collision, its named moving parts (Door, Drawer_n, Lid, ...) as
  entities' Looks where they open (the cupboard pattern), and its Sock spots, from the old manifest (Q2151).
- F03 A furniture station in the zoo shows every piece, built from the folder at load (Q2337).
- F04 Origins at the floor centre of the bounding box, +Z front, as the old manifest says.

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
